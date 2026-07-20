---
coediting: false
comments_count: 0
created_at: '2020-05-29T20:57:23+09:00'
id: f7ec381f5bac184e0b24
likes_count: 1
private: false
reactions_count: 0
stocks_count: 1
tags:
- name: F#
  versions: []
- name: SQLite3
  versions: []
- name: mono
  versions: []
- name: Dapper
  versions: []
title: Mono.Data.SqliteでDapperを使う
updated_at: '2020-05-30T05:37:21+09:00'
url: https://qiita.com/7shi/items/f7ec381f5bac184e0b24
slide: false
---

Dapper というライブラリを教えてもらったので、Mono.Data.Sqlite で使えるか試してみました。

シリーズの記事です。

1. [SQLitePCLRawが動作する組み合わせを探る](https://qiita.com/7shi/items/8846bf14b74a26e014a6)
2. [Microsoft.Data.SqliteをWindowsとWSLで共有する](https://qiita.com/7shi/items/9fbb88786d8a5a6212ab)
3. [WindowsでMono.Data.Sqliteを使う](https://qiita.com/7shi/items/923b3a234eaecd7e8f1c)
4. Mono.Data.SqliteでDapperを使う ← この記事

# Dapper

公式サイト: [Dapper - a simple object mapper for .Net](https://stackexchange.github.io/Dapper/)

チュートリアルサイトから特徴を拾います。

* [Dapper Dapper Tutorial | Dapper Tutorial and Documentation](https://dapper-tutorial.net/ja/home)

> Dapperは私のデータベースプロバイダをサポートしていますか？
> 
> DapperがIDbConnectionインターフェースへの拡張を提供しているのでおそらくそうでしょう。データベースプロバイダと互換性のあるSQLを書くのはあなたの仕事です。 

* <https://dapper-tutorial.net/ja/tutorial/1000167/>

<blockquote>データベースを照会するための便利な拡張メソッドを提供することで、IDbConnectionを拡張します。</blockquote>
<blockquote>DB固有の実装はないため、Dapperは任意のデータベースプロバイダと連携します。</blockquote>

要するに ADO.NET を便利にするライブラリということのようです。

# インストール

プロジェクトを作らずに運用しているので、NuGet で取得して DLL を取り出します。

```shell-session
nuget install Dapper
cp Dapper.2.0.35/lib/net461/Dapper.dll .
```

# サンプルコード

[前回の記事](https://qiita.com/7shi/items/923b3a234eaecd7e8f1c)で使用したサンプルの DB とコードを引用します。冗長な個所を一部修正しています。

```sql:hello.sql
CREATE TABLE user (id INT, name text);
INSERT INTO user VALUES (1,"Foo"),(2,"Bar");
```
```shell-session:作成
sqlite3 hello.db ".read hello.sql"
```
```fsharp:test.fsx
#r "Mono.Data.Sqlite.dll"
open Mono.Data.Sqlite
do
    use connection = new SqliteConnection("URI=file:hello.db")
    connection.Open()

    let command = connection.CreateCommand()
    command.CommandText <- "SELECT name FROM user WHERE id = @id"
    command.Parameters.AddWithValue("@id", 1) |> ignore

    use reader = command.ExecuteReader()
    while reader.Read() do
        let name = reader.GetString 0
        printfn "Hello, %s!" name
```

# 書き換え

Dapper を使うように書き換えます。

```fsharp:test.fsx
#r "Mono.Data.Sqlite.dll"
#r "Dapper.dll"
open Mono.Data.Sqlite
open Dapper
do
    use connection = new SqliteConnection("URI=file:hello.db")
    connection.Open()
    connection.Query<string>(
        "SELECT name FROM user WHERE id = @id", {| id = 1 |})
    |> Seq.iter (printfn "Hello, %s!")
```

パラメータの埋め込みや結果の取り出しなどの泥臭い部分がすっきりしました。書きやすくて読みやすいです。

Windows (.NET Framework) と WSL (Mono) の両方で、問題なく動きました。

```shell-session
$ fsi.exe test.fsx  # Windows
Hello, Foo!
$ fsharpi test.fsx  # Mono
Hello, Foo!
$ fsc.exe test.fsx
Microsoft (R) F# Compiler バージョン 10.6.0.0 for F# 4.7
Copyright (C) Microsoft Corporation. All rights reserved.
$ ./test.exe        # Windows
Hello, Foo!
$ mono test.exe     # Mono
Hello, Foo!
```

ちょっとしたスクリプトに Entity Framework は大き過ぎますが、ADO.NET は書き方が冗長だと感じていました。Dapper はちょうど良いレベル感です。仕組みが分かると、ADO.NET を直接使うのとパフォーマンス的にはほぼ差がないという意味も分かりました。

# 匿名型の代替

コンパイラが古くて匿名型が使えない場合、クエリ用の型を用意すると良さそうです。

```fsharp
#r "Mono.Data.Sqlite.dll"
#r "Dapper.dll"
open Mono.Data.Sqlite
open Dapper
type Q1<'t1> = { _1: 't1 }
do
    use connection = new SqliteConnection("URI=file:hello.db")
    connection.Open()
    connection.Query<string>(
        "SELECT name FROM user WHERE id = @_1", { _1 = 1 })
    |> Seq.iter (printfn "Hello, %s!")
```

# 参考

以下の記事では具体的なコードで ADO.NET からの書き換えが説明されており、分かりやすかったです。

* [Dapperを使ったデータマッピングのはじめ方 │ Web備忘録](https://webbibouroku.com/Blog/Article/dapper)

Dapper の SQL Injection 防止策について説明した記事です。

* [Working With Parameters When Using Dapper | Learn Dapper](https://www.learndapper.com/parameters)

その他、参考にさせていただいた記事です。

* [F# Npgsql+Dapper でPostgreSQLを操作](https://qiita.com/dyoshikawa/items/e705f0b27ca16f699b95)
* [Dapper のクエリ](https://qiita.com/masakura/items/3409a766e46580a5ad99)
* [SQLiteにDapperで読み書きする - マコーの日記](http://hkou.hatenablog.com/entry/2015/07/19/090930)
