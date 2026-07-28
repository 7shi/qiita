---
coediting: false
comments_count: 0
created_at: '2020-05-24T06:03:28+09:00'
id: 022c58cf9a86ced595ef
likes_count: 1
private: false
reactions_count: 0
stocks_count: 0
tags:
- name: F#
  versions: []
- name: XML
  versions: []
title: XMLのタグの構造と出現数を調べる
updated_at: '2020-06-05T15:14:11+09:00'
url: https://qiita.com/7shi/items/022c58cf9a86ced595ef
slide: false
---

構造が良く分からない巨大な XML を処理するため、F# でタグの構造と出現数を調べました。

# XmlReader

.NET Framework の System.Xml.XmlReader を使用します。

* [XmlReader クラス (System.Xml) | Microsoft Docs](https://docs.microsoft.com/ja-jp/dotnet/api/system.xml.xmlreader)

XmlReader は DOM を作らないプル型のパーサーです。今回のように巨大な XML のタグだけ見るような用途に適しています。

# コード

タグの構造を知るため、DOM の代わりのツリーを作ります。同じタグは 1 つにまとめて、出現回数を数えます。

コンパイルして EXE にした場合と、コンパイルせずに F# Interactive に引数で渡した場合のどちらでも使えるように、最後の引数が XML かどうかだけを見ます。

```fsharp:CheckTag.fsx
open System
open System.Collections.Generic
open System.IO
open System.Xml

let args = Environment.GetCommandLineArgs()
let xml = args.[args.Length - 1]
if Path.GetExtension xml <> ".xml" then
    printfn "usage: CheckTag xml"
    exit 1

type Node(name:string) =
    let mutable count = 0
    let children = Dictionary<string, Node>()
    let getChild name =
        if children.ContainsKey name then
            children.[name]
        else
            let node = Node name
            children.[name] <- node
            node
    let isEnd (xr:XmlReader) =
        xr.NodeType = XmlNodeType.EndElement && xr.Name = name
    member __.Parse (xr:XmlReader) =
        count <- count + 1
        if xr.IsEmptyElement then () else
        while xr.Read() && not <| isEnd xr do
            if xr.NodeType = XmlNodeType.Element then
                (getChild xr.Name).Parse xr
    member __.Show() =
        for kv in children do kv.Value.Show("")
    member __.Show(indent) =
        Console.WriteLine("{0}{1} {2:#,0}", indent, name, count)
        for kv in children do kv.Value.Show(indent + "| ")

do
    use sr = new StreamReader(xml)
    use xr = XmlReader.Create(sr)
    let root = Node ""
    root.Parse xr
    printfn "%s" xml
    printfn ""
    root.Show()
```

このコードで実際に巨大な XML を分析してみます。

# Wikipedia

Wikipedia は XML でダンプデータを提供しています。注意書きがあります。

* [Wikipedia:データベースダウンロード - Wikipedia](https://ja.wikipedia.org/wiki/Wikipedia:%E3%83%87%E3%83%BC%E3%82%BF%E3%83%99%E3%83%BC%E3%82%B9%E3%83%80%E3%82%A6%E3%83%B3%E3%83%AD%E3%83%BC%E3%83%89)

>  ファイルサイズが巨大なため、解凍したXMLを通常のエディタやブラウザで開かないようにご注意ください。

日本語版だとあまりにも巨大過ぎるため、サイズが 1/10 ほどのエスペラント版を使用します。

* https://dumps.wikimedia.org/eowiki/

```text:実行結果
eowiki-20200501-pages-articles-multistream.xml

mediawiki 1
| siteinfo 1
| | sitename 1
| | dbname 1
| | base 1
| | generator 1
| | case 1
| | namespaces 1
| | | namespace 29
| page 579,678
| | title 579,678
| | ns 579,678
| | id 579,678
| | revision 579,678
| | | id 579,678
| | | parentid 375,094
| | | timestamp 579,678
| | | contributor 579,678
| | | | username 573,158
| | | | id 573,158
| | | | ip 6,520
| | | minor 211,655
| | | comment 499,900
| | | model 579,678
| | | format 579,678
| | | text 579,678
| | | sha1 579,678
| | redirect 187,022
| | restrictions 50
```

約58万ページあることが分かりました。

※ 2週間ほどのずれがあるとは言え、統計ページの数字とは異なりますが、詳細は不明です。

* [Wikipedia:全言語版の統計 - Wikipedia](https://ja.wikipedia.org/wiki/Wikipedia:%E5%85%A8%E8%A8%80%E8%AA%9E%E7%89%88%E3%81%AE%E7%B5%B1%E8%A8%88) (2020年5月15日時点)

> 順位|言語|原語表記 / 英語記事|WP|純記事数|総項目数|⋯
> ---:|----|----|----|---:|---:|----
> 34|エスペラント語|Esperanto|eo|280,004|621,813|⋯

なお、Wikipedia の実運用ではデータは MySQL に格納しているそうです。

# 関連記事

Wikipedia のダンプデータは圧縮したままデータが取り出せます。詳細は以下を参照してください。

* [Wikipediaのダンプからページを取り出す](https://qiita.com/7shi/items/7a4aa381ec3dc97bd0f2)

多言語辞書 Wiktionary のダンプからデータを抽出する記事です。Wikipedia の関連プロジェクトでダンプの形式は同じです。

* [Wiktionaryの効率的な処理方法を探る](https://qiita.com/7shi/items/e8091f6ac72491ad45a6)
