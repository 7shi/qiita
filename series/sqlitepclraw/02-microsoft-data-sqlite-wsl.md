---
coediting: false
comments_count: 0
created_at: '2020-05-29T03:11:24+09:00'
id: 9fbb88786d8a5a6212ab
likes_count: 3
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
title: Microsoft.Data.SqliteをWindowsとWSLで共有する
updated_at: '2020-05-29T20:59:01+09:00'
url: https://qiita.com/7shi/items/9fbb88786d8a5a6212ab
slide: false
---

Microsoft.Data.Sqlite を Windows (.NET Framework) と WSL (Mono) で共有して動かすことを試みます。

シリーズの記事です。

1. [SQLitePCLRawが動作する組み合わせを探る](https://qiita.com/7shi/items/8846bf14b74a26e014a6)
2. Microsoft.Data.SqliteをWindowsとWSLで共有する ← この記事
3. [WindowsでMono.Data.Sqliteを使う](https://qiita.com/7shi/items/923b3a234eaecd7e8f1c)
4. [Mono.Data.SqliteでDapperを使う](https://qiita.com/7shi/items/f7ec381f5bac184e0b24)

# 概要

SQLite の .NET バインディングは色々あります。

* [Is there a .NET/C# wrapper for SQLite? - Stack Overflow](https://stackoverflow.com/questions/93654/is-there-a-net-c-wrapper-for-sqlite)

SQLite 本家では System.Data.SQLite がメンテナンスされています。

* [System.Data.SQLite: Home](http://system.data.sqlite.org/)

一方、Microsoft は O/R マッパーである Entity Framework の一部として、Microsoft.Data.Sqlite というバインディングを開発しています。

* [src/Microsoft.Data.Sqlite.Core](https://github.com/dotnet/efcore/tree/master/src/Microsoft.Data.Sqlite.Core)

別の実装を作った経緯は、以下で説明されています。

* [System.Data.SQLite との比較 - Microsoft.Data.Sqlite | Microsoft Docs](https://docs.microsoft.com/ja-jp/dotnet/standard/data/sqlite/compare)

Microsoft.Data.Sqlite は SQLitePCLRaw を通して SQLite とやり取りします。次のような 4 層構造になっています。

<table>
<tr><td>Entity Framework</td></tr>
<tr><td>Microsoft.Data.Sqlite</td></tr>
<tr><td>SQLitePCLRaw</td></tr>
<tr><td>SQLite</td></tr>
</table>

[前回の記事](https://qiita.com/7shi/items/8846bf14b74a26e014a6)で SQLitePCLRaw が Windows と WSL で共有できたので、今回は Microsoft.Data.Sqlite を試します。

# ターゲット

概要に記載されているサンプルコードを F# に移植して動作を目指します。

* [概要 - Microsoft.Data.Sqlite | Microsoft Docs](https://docs.microsoft.com/ja-jp/dotnet/standard/data/sqlite/)

```fsharp:移植版
#r "Microsoft.Data.Sqlite"
open Microsoft.Data.Sqlite
let id = 1
do
    use connection = new SqliteConnection("Data source=hello.db")
    connection.Open()

    let command = connection.CreateCommand()
    command.CommandText <- @"
        SELECT name
        FROM user
        WHERE id = $id"
    command.Parameters.AddWithValue("$id", id) |> ignore

    use reader = command.ExecuteReader()
    while reader.Read() do
        let name = reader.GetString 0
        printfn "Hello, %s!" name
```

* F# で `id` は恒等関数として定義済みのため、定義しなくてもコンパイルは通りますが、クエリに使える値ではないため実行時エラーになります。
* 元の C# コードでは文字列への変数埋め込みを使っています。F# では現在実装が進められている段階です。
    * [fslang-design/FS-1001-StringInterpolation.md at master · fsharp/fslang-design](https://github.com/fsharp/fslang-design/blob/master/RFCs/FS-1001-StringInterpolation.md)

読み込み対象の hello.db は事前に作っておきます。

```sql:hello.sql
CREATE TABLE user (id INT, name text);
INSERT INTO user VALUES (1,"Foo"),(2,"Bar");
```
```shell-session:作成
sqlite3 hello.db ".read hello.sql"
```

ターゲットのコードでは `id = 1` を指定しているため、実行結果は次のようになります。

```text:実行結果
Hello, Foo!
```

# 試す

ライブラリを NuGet で取得します。

```shell-session
nuget install Microsoft.Data.Sqlite
```

以下のライブラリがインストールされます。後で必要になるためバージョンも記載します。

* Microsoft.Data.Sqlite.3.1.4
* Microsoft.Data.Sqlite.Core.3.1.4
* SQLitePCLRaw.bundle_e_sqlite3.2.0.2
* SQLitePCLRaw.core.2.0.2
* SQLitePCLRaw.lib.e_sqlite3.2.0.2
* SQLitePCLRaw.provider.dynamic_cdecl.2.0.2
* System.Buffers.4.4.0
* System.Memory.4.5.3
* System.Numerics.Vectors.4.4.0
* System.Runtime.CompilerServices.Unsafe.4.5.2

プロジェクトを作らずに F# Interactive から試すため、ライブラリをコピーします。

```shell-session
cp */lib/netstandard2.0/*.dll .
cp SQLitePCLRaw.lib.e_sqlite3.2.0.2/runtimes/linux-x64/native/libe_sqlite3.so .
cp SQLitePCLRaw.lib.e_sqlite3.2.0.2/runtimes/win-x64/native/e_sqlite3.dll .
```

データベースに接続を試みます。

```shell-session
$ fsharpi

Microsoft (R) F# Interactive version 10.2.3 for F# 4.5
Copyright (c) Microsoft Corporation. All Rights Reserved.

For help type #help;;

> #r "Microsoft.Data.Sqlite";;

--> Referenced '/home/xxx/test/Microsoft.Data.Sqlite.dll' (file may be locked by F# Interactive process)

> open Microsoft.Data.Sqlite;;
> let connection = new SqliteConnection("Data Source=hello.db");;
System.TypeInitializationException: The type initializer for 'Microsoft.Data.Sqlite.SqliteConnection' threw an exception.
---> System.Reflection.TargetInvocationException: Exception has been thrown by the target of an invocation.
---> System.IO.FileNotFoundException: Could not load file or assembly 'SQLitePCLRaw.provider.e_sqlite3, Version=2.0.2.669, Culture=neutral, PublicKeyToken=9c301db686d0bd12' or one of its dependencies.
（略）
Stopped due to error
```

SQLitePCLRaw でエラーが起きますが、対処方法は[前回の記事](https://qiita.com/7shi/items/8846bf14b74a26e014a6)で調査済みです。

provider.e_sqlite3 をインストールします。記事執筆時点ではバージョンを指定しないと SQLitePCLRaw.core よりも新しいバージョンがダウンロードされました。バージョン不整合により問題が起きたため、バージョンを指定して合わせます。

※ さらっと書いていますが、SQLitePCLRaw のエラーが解消したと思ったらまた別の問題が発生して、心が折れそうになりました。

```shell-session
nuget install SQLitePCLRaw.provider.e_sqlite3 -Version 2.0.2
cp SQLitePCLRaw.provider.e_sqlite3.2.0.2/lib/netstandard2.0/*.dll .
```

これでデータベースが開けるようになります。

```fsharp
$ fsharpi
（略）
> #r "Microsoft.Data.Sqlite";;
（略）
> open Microsoft.Data.Sqlite;;
> let connection = new SqliteConnection("Data Source=hello.db");;
val connection : SqliteConnection = Microsoft.Data.Sqlite.SqliteConnection
```

ターゲットとしたコードも問題なく動きました。

# 整理を試みる

[前回の記事](https://qiita.com/7shi/items/8846bf14b74a26e014a6)で試したように、依存するライブラリを減らすことを試みます。

Microsoft.Data.Sqlite の初期化コードを見ると、自前で SQLitePCLRaw を初期化すれば動作には支障がないようです。

* [src/Microsoft.Data.Sqlite.Core/Utilities/BundleInitializer.cs](https://github.com/dotnet/efcore/blob/master/src/Microsoft.Data.Sqlite.Core/Utilities/BundleInitializer.cs)

まっさらな状態から core ライブラリのみをインストールして、必要なライブラリを追加します。

```shell-session
nuget install Microsoft.Data.Sqlite.core
nuget install SQLitePCLRaw.provider.sqlite3
```

記事執筆時点では、2 回の nuget で異なるバージョンの SQLitePCLRaw.core が取得されます。古い方のバージョンには provider.sqlite3 が存在しないため、バージョンを合わせることができません。

試したところ、Mono では新しい方に合わせておけば動きましたが、Windows ではバージョン不整合でエラーになりました。

```text
$ fsharpc test.fsx
（略）
$ mono test.exe
Hello, Foo!
$ ./test.exe
ハンドルされていない例外: System.IO.FileLoadException: ファイルまたはアセンブリ 'SQLitePCLRaw.core, 
Version=2.0.2.669, Culture=neutral, PublicKeyToken=1488e028ca7ab535'、またはその依存関係の 1 つが
読み込めませんでした。見つかったアセンブリのマニフェスト定義はアセンブリ参照に一致しません。 
(HRESULT からの例外:0x80131040)
```

記事執筆時点では、自分でライブラリをビルドしなければこの方法は使えないようです。既に別の方法で動いているので、そこまでは確認していません。
