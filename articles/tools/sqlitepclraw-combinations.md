---
coediting: false
comments_count: 0
created_at: '2020-05-28T21:12:39+09:00'
id: 8846bf14b74a26e014a6
likes_count: 4
private: false
reactions_count: 0
stocks_count: 2
tags:
- name: F#
  versions: []
- name: SQLite3
  versions: []
- name: mono
  versions: []
- name: nuget
  versions: []
title: SQLitePCLRawが動作する組み合わせを探る
updated_at: '2020-05-29T20:59:16+09:00'
url: https://qiita.com/7shi/items/8846bf14b74a26e014a6
slide: false
---

SQLitePCLRaw は NuGet パッケージが細かく分かれています。Windows (.NET Framework) と WSL (Mono) で共通して動作する組み合わせを探ります。

シリーズの記事です。

1. SQLitePCLRawが動作する組み合わせを探る ← この記事
2. [Microsoft.Data.SqliteをWindowsとWSLで共有する](https://qiita.com/7shi/items/9fbb88786d8a5a6212ab)
3. [WindowsでMono.Data.Sqliteを使う](https://qiita.com/7shi/items/923b3a234eaecd7e8f1c)
4. [Mono.Data.SqliteでDapperを使う](https://qiita.com/7shi/items/f7ec381f5bac184e0b24)

# 概要

README の末尾に掲載されているサンプルから分かるように、SQLitePCLRaw は他のライブラリの下請けを想定した作りになっており、直接コードを書くのには適していません。

* [ericsink/SQLitePCL.raw: A Portable Class Library (PCL) for low-level (raw) access to SQLite](https://github.com/ericsink/SQLitePCL.raw)

> ```csharp
> int rc;
> 
> sqlite3 db;
> rc = raw.sqlite3_open(":memory:", out db);
> if (rc != raw.SQLITE_OK)
> {
>     error
> }
> sqlite3_stmt stmt;
> rc = raw.sqlite3_prepare(db, "CREATE TABLE foo (x int)", out stmt);
> if (rc != raw.SQLITE_OK)
> {
>     error
> }
> rc = raw.sqlite3_step(stmt);
> if (rc == raw.SQLITE_DONE)
> {
>     whatever
> }
> else
> {
>     error
> }
> raw.sqlite3_finalize(stmt);
> ```

今回はデータベースを開くことだけを目標にします。

core パッケージはプラットフォーム独立なコードだけで構成されているため、適切なパッケージと組み合わせなければ動作しません。

```shell-session
$ nuget install SQLitePCLRaw.core
（略）
$ cp */lib/netstandard2.0/*.dll .
$ fsharpi

Microsoft (R) F# Interactive version 10.2.3 for F# 4.5
Copyright (c) Microsoft Corporation. All Rights Reserved.

For help type #help;;

> #r "SQLitePCLRaw.core.dll";;

--> Referenced '/home/xxx/test/SQLitePCLRaw.core.dll' (file may be locked by F# Interactive process)

> SQLitePCL.raw.sqlite3_open("test.db");;
System.Exception: You need to call SQLitePCL.raw.SetProvider().  If you are using a bundle package, this is done by calling SQLitePCL.Batteries.Init().
（略）
Stopped due to error
```

エラー内容は、`SQLitePCL.raw.SetProvider()` によってネイティブライブラリとの橋渡しをする provider を登録するか、bundle パッケージを利用して `SQLitePCL.Batteries.Init()` を呼ぶようにとのことです。

# NuGet

NuGet には大量の関連パッケージが登録されているため、いきなり見てもどれが適切なのか判断できません。

* [NuGet Gallery | SQLitePCLRaw](https://www.nuget.org/profiles/SQLitePCLRaw)

SQLitePCLRaw の README にある説明はあっさりしているため、Microsoft.Data.Sqlite のドキュメントから引用します。

* [カスタム SQLite のバージョン - Microsoft.Data.Sqlite | Microsoft Docs](https://docs.microsoft.com/ja-jp/dotnet/standard/data/sqlite/custom-versions)

> バンドル|説明
> ----|----
> SQLitePCLRaw.bundle_e_sqlite3|すべてのプラットフォームで同じバージョンの SQLite を提供します。 FTS4、FTS5、JSON1、R*Tree 拡張機能を含みます。 既定値です。
> SQLitePCLRaw.bundle_green|Bundle_e_sqlite3 と同じですが、iOS の場合は例外で、システム SQLite ライブラリを使用します。
> SQLitePCLRaw.bundle_zetetic|Zetetic の公式の SQLCipher ビルドを使用します (含まれていません)。
> SQLitePCLRaw.bundle_winsqlite3|Windows 10 のシステム SQLite ライブラリである winsqlite3.dll を使用します。
> SQLitePCLRaw.bundle_e_sqlcipher|オープン ソースの非公式の SQLCipher ビルドを提供します。

# bundle_e_sqlite3

今回は暗号化はしないため、無難そうな bundle_e_sqlite3 を利用します。

```shell-session
nuget install SQLitePCLRaw.bundle_e_sqlite3
```

先ほどの core に加えて 3 つのパッケージが追加されます。

* SQLitePCLRaw.bundle_e_sqlite3
* SQLitePCLRaw.lib.e_sqlite3
* SQLitePCLRaw.provider.dynamic_cdecl

bundle は、先ほどのエラーにもあった `SQLitePCL.Batteries.Init()` を提供するパッケージです。lib はネイティブライブラリ、provider はネイティブライブラリを P/Invoke するパッケージのようです。

ライブラリを取り出します。

```shell-session
cp SQLitePCLRaw.bundle_e_sqlite3.2.0.3/lib/netstandard2.0/*.dll .
cp SQLitePCLRaw.lib.e_sqlite3.2.0.3/runtimes/win-x64/native/e_sqlite3.dll .
cp SQLitePCLRaw.lib.e_sqlite3.2.0.3/runtimes/linux-x64/native/libe_sqlite3.so .
cp SQLitePCLRaw.provider.dynamic_cdecl.2.0.3/lib/netstandard2.0/*.dll .
```

利用を試みます。

```shell-session
$ fsharpi
（略）
> #r "SQLitePCLRaw.batteries_v2.dll";;
（略）
> SQLitePCL.Batteries.Init();;
System.IO.FileNotFoundException: Could not load file or assembly 'SQLitePCLRaw.provider.e_sqlite3, Version=2.0.3.851, Culture=neutral, PublicKeyToken=9c301db686d0bd12' or one of its dependencies.
（略）
Stopped due to error
```

何やら想定と違う provider を呼ぼうとしてエラーになっているようです。

bundle の別のライブラリを使用してみます。

```shell-session
$ cp SQLitePCLRaw.bundle_e_sqlite3.2.0.3/lib/net461/*.dll .
$ fsharpi
（略）
> #r "SQLitePCLRaw.batteries_v2.dll";;
（略）
> SQLitePCL.Batteries.Init();;
System.Exception: Library e_sqlite3 not found
  at SQLitePCL.NativeLibrary.Load (System.String libraryName, System.Reflection.Assembly assy, System.Int32 flags) [0x00044] in <e8dc4c5119404b27ae2008c2faf281e0>:0
（略）
Stopped due to error
```

エラーメッセージが変わって、ネイティブライブラリが見付からないというエラーになっています。

bundle を元に戻して、provider.e_sqlite3 を追加してみます。

```shell-session
$ cp SQLitePCLRaw.bundle_e_sqlite3.2.0.3/lib/netstandard2.0/*.dll .
$ nuget install SQLitePCLRaw.provider.e_sqlite3
（略）
$ cp SQLitePCLRaw.provider.e_sqlite3.2.0.3/lib/netstandard2.0/*.dll .
$ fsharpi
（略）
> #r "SQLitePCLRaw.batteries_v2.dll";;
（略）
> SQLitePCL.Batteries.Init();;
val it : unit = ()

> #r "SQLitePCLRaw.core.dll";;
（略）
> SQLitePCL.raw.sqlite3_open("test.db");;
val it : int * SQLitePCL.sqlite3 = (0, SQLitePCL.sqlite3 {IsClosed = false;
                                                          IsInvalid = false;})

> #q;;

- Exit...
$ ls test.db
test.db
```

うまく動きました。

よく分かりませんが、.NET Standard 2.0 を想定した構成では、依存関係で入る provider.dynamic_cdecl ではなく、provider.e_sqlite3 を利用すると良いようです。

## 初期化

`SQLitePCL.Batteries.Init()` のソースコードを見ると、環境別の provider を設定しているだけのようです。

* <https://github.com/ericsink/SQLitePCL.raw/blob/master/src/common/batteries_v2.cs>

```csharp
	    public static void Init()
	    {
#if EMBEDDED_INIT
            SQLitePCL.lib.embedded.Init();
#endif

#if PROVIDER_sqlite3
		    SQLitePCL.raw.SetProvider(new SQLitePCL.SQLite3Provider_sqlite3());
#elif PROVIDER_e_sqlite3
		    SQLitePCL.raw.SetProvider(new SQLitePCL.SQLite3Provider_e_sqlite3());
```

`SQLitePCL.Batteries.Init()` は環境依存の初期化コードを隠すために挟んでいるようです。

# 整理

環境別の provider を直接 `SetProvider` するなら bundle_e_sqlite3 は不要です。今回は Windows (.NET Framework) と WSL (Mono) での動作を想定していますが、どちらでも動くことを確認しました。

```fsharp
$ fsharpi
（略）
> #r "SQLitePCLRaw.core.dll";;
（略）
> #r "SQLitePCLRaw.provider.e_sqlite3.dll";;
（略）
> SQLitePCL.raw.SetProvider(new SQLitePCL.SQLite3Provider_e_sqlite3());;
val it : unit = ()

> SQLitePCL.raw.sqlite3_open("test.db");;
val it : int * SQLitePCL.sqlite3 = (0, SQLitePCL.sqlite3 {IsClosed = false;
                                                          IsInvalid = false;})
```

整理すると、まっさらな状態からは provider.e_sqlite3 と lib.e_sqlite3 を追加すれば良いようです。

```shell-session
$ nuget install SQLitePCLRaw.provider.e_sqlite3
（略）
$ nuget install SQLitePCLRaw.lib.e_sqlite3
（略）
$ cp */lib/netstandard2.0/*.dll .
$ cp SQLitePCLRaw.lib.e_sqlite3.2.0.3/runtimes/win-x64/native/e_sqlite3.dll .
$ cp SQLitePCLRaw.lib.e_sqlite3.2.0.3/runtimes/linux-x64/native/libe_sqlite3.so .
```

# provider.sqlite3

WSL には既に SQLite が入っているため、そちらを使うようにすれば nuget で入れるネイティブライブラリは不要です。

まっさらな状態から provider.sqlite3 を追加すれば、その環境になります。

```shell-session
$ nuget install SQLitePCLRaw.provider.sqlite3
（略）
$ cp */lib/netstandard2.0/*.dll .
$ fsharpi
（略）
> #r "SQLitePCLRaw.core.dll";;
（略）
> #r "SQLitePCLRaw.provider.sqlite3.dll";;
（略）
> SQLitePCL.raw.SetProvider(new SQLitePCL.SQLite3Provider_sqlite3());;
val it : unit = ()

> SQLitePCL.raw.sqlite3_open("test.db");;
val it : int * SQLitePCL.sqlite3 = (0, SQLitePCL.sqlite3 {IsClosed = false;
                                                          IsInvalid = false;})
```

[SQLite の公式サイト](https://www.sqlite.org/)から Windows 用の DLL をダウンロードして置けば、Windows の .NET Framework からも使えるようになります。

<font color="red">**【注意】**</font> fsi.exe は 32bit で動くため、64bit の DLL を使用するには fsiAnyCpu.exe を使用する必要があります。

```fsharp:fsi.exe
> #r "SQLitePCLRaw.core.dll";;
（略）
> #r "SQLitePCLRaw.provider.sqlite3.dll";;
（略）
> SQLitePCL.raw.SetProvider(new SQLitePCL.SQLite3Provider_sqlite3());;
System.BadImageFormatException: 間違ったフォーマットのプログラムを読み込もうとしました。 (HRESULT からの例
外:0x8007000B)
（略）
エラーのため停止しました
```
```fsharp:fsiAnyCpu.exe
> #r "SQLitePCLRaw.core.dll";;
（略）
> #r "SQLitePCLRaw.provider.sqlite3.dll";;
（略）
> SQLitePCL.raw.SetProvider(new SQLitePCL.SQLite3Provider_sqlite3());;
val it : unit = ()
```
