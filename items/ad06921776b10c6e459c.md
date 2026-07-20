---
coediting: false
comments_count: 0
created_at: '2016-06-30T10:38:53+09:00'
id: ad06921776b10c6e459c
likes_count: 3
private: false
reactions_count: 0
stocks_count: 4
tags:
- name: F#
  versions: []
title: XMLスプレッドシートの読み込み
updated_at: '2016-07-06T17:58:08+09:00'
url: https://qiita.com/7shi/items/ad06921776b10c6e459c
slide: false
---

ExcelではCSVとXLSXの中間的なファイルフォーマットとしてXMLスプレッドシートがサポートされています。これをF#で読み取ってみます。

この記事の方法の使用例です。

* [不揃いなデータをコンピュテーション式で処理](http://qiita.com/7shi/items/567e92474681a38de86a) 2016.06.30

# XMLスプレッドシート

スプレッドシートをデータソースとして、専用ライブラリ（[ClosedXML](http://closedxml.codeplex.com/)など）を使わないで読み込むことを考えます。Excelでよく使われるファイル形式を検討します。

* CSV: 改行やエスケープを考慮しないケースでは処理が簡単ですが、装飾を加えることはできません。
* XLS: 複雑なバイナリ形式のためパースが困難です。
* XLSX: ZIPの中にXMLが入っています。XMLだけ処理する分にはあまり難しくはありませんが、ZIPから展開する手間があります。

XLSXのうちセルのデータが格納されているXMLだけを単独で抜き出せば、扱いやすさでは理想的に思えます。それに近いファイル形式がXMLスプレッドシートです。

※ スキーマ（XMLタグなど）はXLSXとは異なります。あくまでイメージです。

XMLスプレッドーシートにはオートシェイプが格納できないなどの制限がありますが、今回はオートシェイプは扱わないため不問とします。

# サンプル

次のようなデータがあったとします。

社名|会長|社長|副社長|専務
----|----|----|------|----
A社|山田|佐藤|鈴木|小林
B社||伊藤||池田
C社|山本|高橋||

これをExcelで「XML スプレッドシート 2003」形式を指定して保存します。そのままだと複雑なので、プロパティなどを削って単純化したものを示します。

```Book1.xml
<?xml version="1.0"?>
<?mso-application progid="Excel.Sheet"?>
<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"
 xmlns:o="urn:schemas-microsoft-com:office:office"
 xmlns:x="urn:schemas-microsoft-com:office:excel"
 xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet"
 xmlns:html="http://www.w3.org/TR/REC-html40">
 <Worksheet ss:Name="Sheet1">
  <Table>
   <Row>
    <Cell><Data ss:Type="String">社名</Data></Cell>
    <Cell><Data ss:Type="String">会長</Data></Cell>
    <Cell><Data ss:Type="String">社長</Data></Cell>
    <Cell><Data ss:Type="String">副社長</Data></Cell>
    <Cell><Data ss:Type="String">専務</Data></Cell>
   </Row>
   <Row>
    <Cell><Data ss:Type="String">A社</Data></Cell>
    <Cell><Data ss:Type="String">山田</Data></Cell>
    <Cell><Data ss:Type="String">佐藤</Data></Cell>
    <Cell><Data ss:Type="String">鈴木</Data></Cell>
    <Cell><Data ss:Type="String">小林</Data></Cell>
   </Row>
   <Row>
    <Cell><Data ss:Type="String">B社</Data></Cell>
    <Cell ss:Index="3"><Data ss:Type="String">伊藤</Data></Cell>
    <Cell ss:Index="5"><Data ss:Type="String">池田</Data></Cell>
   </Row>
   <Row>
    <Cell><Data ss:Type="String">C社</Data></Cell>
    <Cell><Data ss:Type="String">山本</Data></Cell>
    <Cell><Data ss:Type="String">高橋</Data></Cell>
   </Row>
  </Table>
 </Worksheet>
</Workbook>
```

実際のパースのときには不要なタグは無視すれば良いので、単純化したものを想定してプログラムを組んでも問題ありません。

# パース

XmlReaderで読み込みます。XmlReaderはプル型パーサーで、特徴については以下の記事を参照してください。

* [XmlReader と SAX リーダーの比較](https://msdn.microsoft.com/ja-jp/library/sbw89de7%28v=vs.110%29.aspx)

必要なタグを頭出しして、閉じられるまで内部のタグを繰り返し読みます。`<Cell>`タグでは空白セルをスキップするため`ss:Index`が指定されていることに注意します。要素を`for`で処理するため、シーケンスを返します。

```fsharp:XmlSpreadsheetReader.fsx
#r "System.Xml"

open System
open System.IO
open System.Text
open System.Xml

let startElement (xr:XmlReader) (n:string) =
    xr.NodeType = XmlNodeType.Element && xr.Name = n

let endElement (xr:XmlReader) (n:string) =
    xr.NodeType = XmlNodeType.EndElement && xr.Name = n

let each (xr:XmlReader) (n:string) = seq {
    let parent = xr.Name
    while xr.Read() && not (endElement xr parent) do
        if startElement xr n then yield xr }

let find (xr:XmlReader) (n:string) =
    each xr n |> Seq.isEmpty |> not

let openXml (xml:string) =
    let fs = new FileStream(xml, FileMode.Open, FileAccess.Read, FileShare.ReadWrite)
    let sr = new StreamReader(fs, Encoding.UTF8)
    let xr = new XmlTextReader(sr)
    find xr "Workbook" |> ignore
    xr

let cells xr = seq {
    let col = ref 1
    for _ in each xr "Cell" do
        let i = xr.GetAttribute "ss:Index"
        if i <> null then
            let i' = Convert.ToInt32 i
            while !col < i' do
                yield ""
                col := !col + 1
        yield if find xr "Data" then xr.ReadString() else ""
        col := !col + 1 }

let rows xr = seq {
    for _ in each xr "Row" do
        yield cells xr |> Seq.toList }

let worksheets xr = seq {
    for _ in each xr "Worksheet" do
        yield xr.GetAttribute "ss:Name" }
```

これを使ってサンプルを読み込みます。

```fsharp:Test.fsx
#load "XmlSpreadsheetReader.fsx"

open XmlSpreadsheetReader

[<EntryPoint>] do
use xr = openXml "Book1.xml"
for sheet in worksheets xr do
    printfn "%s" sheet
    for row in rows xr do
        printfn "%A" row
```
```text:実行結果
Sheet1
["社名"; "会長"; "社長"; "副社長"; "専務"]
["A社"; "山田"; "佐藤"; "鈴木"; "小林"]
["B社"; ""; "伊藤"; ""; "池田"]
["C社"; "山本"; "高橋"]
```

セルの幅を修正したり、色や罫線を加えたりしても、データはそのまま読めます。印刷用に整形を施した状態でデータを保守できるというのがミソです。
