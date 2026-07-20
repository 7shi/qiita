---
coediting: false
comments_count: 0
created_at: '2020-05-29T05:17:40+09:00'
id: 923b3a234eaecd7e8f1c
likes_count: 0
private: false
reactions_count: 0
stocks_count: 0
tags:
- name: F#
  versions: []
- name: SQLite3
  versions: []
- name: mono
  versions: []
title: WindowsでMono.Data.Sqliteを使う
updated_at: '2020-05-30T03:23:20+09:00'
url: https://qiita.com/7shi/items/923b3a234eaecd7e8f1c
slide: false
---

Mono には SQLite のバインディングが付属しています。それを Windows の .NET Framework から使ってみます。

シリーズの記事です。

1. [SQLitePCLRawが動作する組み合わせを探る](https://qiita.com/7shi/items/8846bf14b74a26e014a6)
2. [Microsoft.Data.SqliteをWindowsとWSLで共有する](https://qiita.com/7shi/items/9fbb88786d8a5a6212ab)
3. WindowsでMono.Data.Sqliteを使う ← この記事
4. [Mono.Data.SqliteでDapperを使う](https://qiita.com/7shi/items/f7ec381f5bac184e0b24)

# 概要

これまで SQLitePCLRaw と Microsoft.Data.Sqlite を試して来ました。

パッケージの依存関係やバージョンなど、細かいことを気にしないとうまく動きませんでした。依存するライブラリも多く、ちょっとしたスクリプトから気軽に使えるという感じではありません。

Mono には System.Data.SQLite からフォークした Mono.Data.Sqlite が付属します。

* [System.Data.SQLite との比較 - Microsoft.Data.Sqlite | Microsoft Docs](https://docs.microsoft.com/ja-jp/dotnet/standard/data/sqlite/compare)

> 2005 年に、Robert Simpson は ADO.NET 2.0 用の SQLite プロバイダーである System.Data.SQLite を作成しました。 2010 年に、SQLite チームがプロジェクトのメンテナンスと開発を引き継ぎました。 また、2007 年に Mono チームがコードを Mono.Data.Sqlite としてフォークしたことも注目すべき点です。

* 紹介：[SQLite | Mono](https://www.mono-project.com/docs/database-access/providers/sqlite/)
* ソース：[mcs/class/Mono.Data.Sqlite](https://github.com/mono/mono/tree/master/mcs/class/Mono.Data.Sqlite)

これが Windows でも動けば、環境構築が楽そうです。

# テスト

[前回の記事](https://qiita.com/7shi/items/9fbb88786d8a5a6212ab)と同じテスト DB を使用します。

```sql:hello.sql
CREATE TABLE user (id INT, name text);
INSERT INTO user VALUES (1,"Foo"),(2,"Bar");
```
```shell-session:作成
sqlite3 hello.db ".read hello.sql"
```

テストコードを移植します。どちらも ADO.NET に準拠しているため基本的な使い方は同じです。ライブラリの参照とファイルの指定を書き換えただけです。

```fsharp:test.fsx
#r "Mono.Data.Sqlite.dll"
open Mono.Data.Sqlite
let id = 1
do
    use connection = new SqliteConnection("URI=file:hello.db")
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

Mono で実行します。バンドルされているので環境構築の手間がありません。

```text:実行結果
$ fsharpi test.fsx
Hello, Foo!
$ fsharpc test.fsx
Microsoft (R) F# Compiler version 10.2.3 for F# 4.5
Copyright (c) Microsoft Corporation. All Rights Reserved.
$ mono test.exe
Hello, Foo!
```

# Windows で使う

Windows の .NET Framework から使おうとすると、ライブラリが見付からないためエラーになります。

```text
$ ./test.exe

ハンドルされていない例外: System.IO.FileNotFoundException: ファイルまたはアセンブリ 'Mono.Data.Sqlite, Vers
ion=4.0.0.0, Culture=neutral, PublicKeyToken=0738eb9f132ed756'、またはその依存関係の 1 つが読み込めませんで
した。指定されたファイルが見つかりません。
   場所 <StartupCode$test>.$Test$fsx.main@()
```

[SQLite の公式サイト](https://www.sqlite.org/)から Windows 用の DLL をダウンロードして置きます。

Mono のライブラリをコピーします。

```text
cp /usr/lib/mono/4.5/Mono.Data.Sqlite.dll .
```

これで無事に動きます。

```text
$ fsiAnyCpu.exe test.fsx
Hello, Foo!
$ ./test.exe
Hello, Foo!
```

ファイルを 2 つコピーするだけなので、お手軽に使うには良さそうです。
