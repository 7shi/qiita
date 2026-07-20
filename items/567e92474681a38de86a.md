---
coediting: false
comments_count: 0
created_at: '2016-06-30T17:10:23+09:00'
id: 567e92474681a38de86a
likes_count: 3
private: false
reactions_count: 0
stocks_count: 4
tags:
- name: F#
  versions: []
title: 不揃いなデータをコンピュテーション式で処理
updated_at: '2016-11-12T19:36:04+09:00'
url: https://qiita.com/7shi/items/567e92474681a38de86a
slide: false
---

表形式のデータで必ずしも全部のセルが埋まっていないものの処理を、コンピュテーション式の練習として実装してみました。

#### 編集履歴

* 2016.06.30 改良版の記事へのリンクを貼りました。
* 2016.07.04 この記事で作ったコンピュテーション式ビルダーの作成過程を記事にしました。
    * [試作したコンピュテーション式と関数モナド](http://qiita.com/7shi/items
/6635d6bea5c455cbb4da)
* 2016.07.06 コンピュテーション式を使わない方法を追記しました。
* 2016.07.07 `Map`を使う方法を追記しました。

# サンプル

データソースとして扱う表はXMLスプレッドシート形式のファイルで提供されると想定します。読み込みには以下の記事で作成した`XmlSpreadsheetReader`を使用します。

* [XMLスプレッドシートの読み込み](http://qiita.com/7shi/items/ad06921776b10c6e459c) 2016.06.30

上の記事のサンプルと同じものを使用します。

社名|会長|社長|副社長|専務
----|----|----|------|----
A社|山田|佐藤|鈴木|小林
B社||伊藤||池田
C社|山本|高橋||

`XmlSpreadsheetReader`が返すデータは以下のように長さが不揃いです。

```text
["社名"; "会長"; "社長"; "副社長"; "専務"]
["A社"; "山田"; "佐藤"; "鈴木"; "小林"]
["B社"; ""; "伊藤"; ""; "池田"]
["C社"; "山本"; "高橋"]
```

今回の目的はこのデータから名前をキーにしたハッシュテーブルを作ることです。

# 実装

特に工夫もせずベタ書きで実装してみます。

```fsharp
#load "XmlSpreadsheetReader.fsx"

open XmlSpreadsheetReader

let persons = new System.Collections.Generic.Dictionary<string, string * string>()
let addPerson name data = if name <> "" then persons.[name] <- data

try
    use xr = openXml "Book1.xml"
    worksheets xr |> Seq.head |> ignore
    for row in rows xr |> Seq.skip 1 do
        let company = row.Item 0
        if row.Length <= 1 then () else
        addPerson (row.Item 1) (company, "会長")
        if row.Length <= 2 then () else
        addPerson (row.Item 2) (company, "社長")
        if row.Length <= 3 then () else
        addPerson (row.Item 3) (company, "副社長")
        if row.Length <= 4 then () else
        addPerson (row.Item 4) (company, "専務")
    for p in persons do
        printfn "%s: %A" p.Key p.Value
with e ->
    printfn "%A" e
```
```text:実行結果
山田: ("A社", "会長")
佐藤: ("A社", "社長")
鈴木: ("A社", "副社長")
小林: ("A社", "専務")
伊藤: ("B社", "社長")
池田: ("B社", "専務")
山本: ("C社", "会長")
高橋: ("C社", "社長")
```

このコードではたまたま同姓の別人がいたときに上書きされてしまいますが、本題ではないため不問とします。

## コンピュテーション式

長さチェックが冗長で、インデックスを即値で指定しているのも微妙です。これらをコンピュテーション式で簡略化してみます。汎用性は考えずに用途を限定します。モナド化は考慮しません。

```fsharp
#load "XmlSpreadsheetReader.fsx"

open XmlSpreadsheetReader

type ListReaderBuilder() =
    member this.Bind(_, f) = function x::xs -> f x xs | _ -> ()
    member this.Zero() = fun _ -> ()
let listReader = ListReaderBuilder()

let persons = new System.Collections.Generic.Dictionary<string, string * string>()
let addPerson name data = if name <> "" then persons.[name] <- data

try
    use xr = openXml "Book1.xml"
    worksheets xr |> Seq.head |> ignore
    for row in rows xr |> Seq.skip 1 do
        row |> listReader {
            let! company = ()
            let! name = () in addPerson name (company, "会長")
            let! name = () in addPerson name (company, "社長")
            let! name = () in addPerson name (company, "副社長")
            let! name = () in addPerson name (company, "専務")
        }
    for p in persons do
        printfn "%s: %A" p.Key p.Value
with e ->
    printfn "%A" e
```

実行結果は同じです。

もうちょっと整理できそうな雰囲気ですが、ひとまずコンピュテーション式の練習という目的は達成できたため、ここで一区切りとします。

【追記】[@pocketberserker](https://twitter.com/pocketberserker)さんに改良していただきました。

* [Twitterで流れてきたListReaderコンピュテーション式の解説 - pocketberserkerの爆走](http://pocketberserker.hatenablog.com/entry/2016/06/30/200042) 2016.06.30

## コンピュテーション式なし

ここまで引っ張って来ましたが、コンピュテーション式を使わない方法に落ち着きそうです。

```fsharp
#load "XmlSpreadsheetReader.fsx"

open XmlSpreadsheetReader

let persons = new System.Collections.Generic.Dictionary<string, string * string>()
let addPerson data name = if name <> "" then persons.[name] <- data

try
    use xr = openXml "Book1.xml"
    worksheets xr |> Seq.head |> ignore
    let en = (rows xr).GetEnumerator()
    if en.MoveNext() then
        let h = en.Current |> List.tail |> List.toArray
        while en.MoveNext() do
            match en.Current with
            | company::cells ->
                cells |> List.iteri (fun i -> addPerson (company, h.[i]))
            | _ -> ()
    for p in persons do
        printfn "%s: %A" p.Key p.Value
with e ->
    printfn "%A" e
```

コンピュテーション式について考える機会にはなったような気がします。

## Map

あまりにも手続べったりなので、もうちょっと宣言的に書けないかを試しました。

```fsharp
#load "XmlSpreadsheetReader.fsx"

open XmlSpreadsheetReader

let cutZip list1 list2 =
    let len = min (List.length list1) (List.length list2)
    Seq.zip (Seq.take len list1) (Seq.take len list2)

try
    use xr = openXml "Book1.xml"
    worksheets xr |> Seq.head |> ignore
    let persons =
        Map.ofList [
            match rows xr |> Seq.toList with
            | (_::h)::data ->
                for d in data do
                match d with
                | company::cells ->
                    for p, n in cutZip h cells do
                    if n <> "" then yield n, (company, p)
                | _ -> ()
            | _ -> ()]
    persons |> Map.iter (printfn "%s: %A")
with e ->
    printfn "%A" e
```
```text:実行結果
伊藤: ("B社", "社長")
佐藤: ("A社", "社長")
小林: ("A社", "専務")
山本: ("C社", "会長")
山田: ("A社", "会長")
池田: ("B社", "専務")
鈴木: ("A社", "副社長")
高橋: ("C社", "社長")
```

`Dictionary`と違って追加順は保持されません。
