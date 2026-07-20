---
coediting: false
comments_count: 0
created_at: '2016-12-26T22:38:03+09:00'
id: 04c2991239894687ef2f
likes_count: 10
private: false
reactions_count: 0
stocks_count: 12
tags:
- name: F#
  versions: []
- name: JSON
  versions: []
title: JSONパーサーを作る
updated_at: '2016-12-28T04:20:07+09:00'
url: https://qiita.com/7shi/items/04c2991239894687ef2f
slide: false
---

パーサー作りの練習としてF#でJSONパーサーを作ってみます。

※ 練習として作るのが目的のため既存のパーサーは使用しません。

この記事で作ったパーサーを利用した記事です。

* [HARからファイルを抽出する](http://qiita.com/7shi/items/2e08418eeb448a343723) 2016.12.27

この記事ではパーサコンビネータを意識した再帰下降パーサーを手書きします。詳細は以下の記事を参照してください。

* [Java 再帰下降構文解析 超入門](http://qiita.com/7shi/items/64261a67081d49f941e3) 2016.05.16
* [Java パーサコンビネータ 超入門](http://qiita.com/7shi/items/68228e19552c271bea81) 2016.05.12
* [Java パーサコンビネータ 超入門 2](http://qiita.com/7shi/items/39a9ddffcc5bdf2c0142) 2016.05.14
* [C++11 パーサコンビネータ 超入門](http://qiita.com/7shi/items/6a12160276a8db358e34) 2015.11.27
* [C++11 パーサコンビネータ 超入門 2](http://qiita.com/7shi/items/f86f2f7ad68cfff1b399) 2015.11.30
* [Haskell 構文解析 超入門](http://qiita.com/7shi/items/b8c741e78a96ea2c10fe) 2015.07.31

# 簡易パーサー

汎用の簡易パーサーを作ります。関数名は Parsec に似せていますが、オリジナルの関数もあります。

## 1文字読み取り

任意の文字を1文字読み取ります。終端なら例外を発生させます。

```fsharp:JSONParser.fsx
open System
open System.IO

let parseTest parser src =
    use sr = new StringReader(src)
    try
        printfn "%A" (parser sr)
    with e ->
        printfn "%s" e.Message

let anyChar (tr:TextReader) =
    let ch = tr.Read()
    if ch >= 0 then char ch else
    failwith "anyChar: unexpected end of input"

parseTest anyChar "abc"
parseTest anyChar ""
```
```text:実行結果
'a'
anyChar: unexpected end of input
```

## 連続読み取り

複数のパーサーをリストで表して連続実行します。

```fsharp:JSONParser.fsx（続き）
let plist list tr = [for p in list -> p tr]

parseTest (plist [anyChar; anyChar]) "abc"
parseTest (plist [anyChar; anyChar]) "a"
```
```text:実行結果
['a'; 'b']
anyChar: unexpected end of input
```

## 文字確認

現在位置を移動せずに文字を確認します。終端なら例外を発生させます。

```fsharp:JSONParser.fsx（続き）
let peek (tr:TextReader) =
    let ch = tr.Peek()
    if ch >= 0 then char ch else
    failwith "peek: unexpected end of input"

parseTest (plist [anyChar; peek; anyChar]) "abc"
```
```text:実行結果
['a'; 'b'; 'b']
```

## 指定した文字か確認

指定した文字のどれかに該当すれば現在位置を進めて `true` を返し、そうでなければ `false` を返します。

```fsharp:JSONParser.fsx（続き）
let isOneOf (s:string) (tr:TextReader) =
    let ch = tr.Peek()
    if ch = -1 || s.IndexOf(char ch) < 0 then false else
    tr.Read() |> ignore
    true

parseTest (isOneOf "ab") "abc"
parseTest (isOneOf "ab") "def"
```
```text:実行結果
true
false
```

## 指定した文字の読み取り

指定した文字のどれかに該当すれば読み取って、そうでなければ例外を発生させます。

```fsharp:JSONParser.fsx（続き）
let oneOf (s:string) (tr:TextReader) =
    let ch = tr.Peek()
    if isOneOf s tr then char ch else
    failwith <| sprintf "oneOf: '%c' is not in \"%s\"" (char ch) s

parseTest (oneOf "ab") "abc"
parseTest (oneOf "ab") "def"
```
```text:実行結果
'a'
oneOf: 'd' is not in "ab"
```

## 条件に合う限り読み続ける

指定した条件に合う限り文字列を読み続けます。1文字も合致しなければ空白が返るため例外は発生しません。

```fsharp:JSONParser.fsx（続き）
let many f (tr:TextReader) =
    use sw = new StringWriter()
    let rec g() =
        let ch = tr.Peek()
        if ch >= 0 && f (char ch) then
            sw.Write(char ch)
            tr.Read() |> ignore
            g()
    g()
    sw.ToString()

parseTest (many Char.IsDigit) "123abc"
```
```text:実行結果
"123"
```

## 空白の読み飛ばし

空白を読み飛ばします。パーサーを結合する演算子を定義します。

```fsharp:JSONParser.fsx（続き）
let isSpace (ch:char) = " \r\n\t".IndexOf ch >= 0

let rec spaces (tr:TextReader) =
    let ch = tr.Peek()
    if ch >= 0 && isSpace (char ch) then
        tr.Read() |> ignore
        spaces tr

let (@>>) a b = fun tr -> a tr |> ignore; b tr
let (@<<) a b = fun tr -> let r = a tr in b tr |> ignore; r

parseTest (spaces @>> anyChar) "   123"
parseTest (plist [anyChar @<< spaces; anyChar]) "1   23"
```
```text:実行結果
'1'
['1'; '2']
```

`@>>` や `@<<` は評価順を表しているわけではなく、評価順はどちらも「左→右」です。片方の戻り値は捨てて、片方の戻り値だけを残します（演算子を矢印と見なした時の指す先の関数が残す対象）。

# JSONパーサー

基礎的なパーサーができたので、後はこれを利用してJSONパーサーを作ります。

## 文字列の読み取り

シングルクォートまたはダブルクォートで囲まれた文字列を読み取ります。エスケープシーケンスの処理がやや複雑です。

```fsharp:JSONParser.fsx（続き）
let jsonHex tr =
    match anyChar tr with
    | ch when '0' <= ch && ch <= '9' -> int ch - int '0'
    | ch when 'A' <= ch && ch <= 'F' -> int ch - int 'A' + 10
    | ch when 'a' <= ch && ch <= 'f' -> int ch - int 'a' + 10
    | ch -> failwith <| sprintf "hexChar: '%c' is not hex char" ch

let jsonUnescape tr =
    match anyChar tr with
    | 'b' -> '\b'
    | 't' -> '\t'
    | 'n' -> '\n'
    | 'v' -> char 11
    | 'f' -> char 12
    | 'r' -> '\r'
    | 'x' -> (jsonHex tr <<<  4) ||| (jsonHex tr) |> char
    | 'u' -> (jsonHex tr <<< 12) ||| (jsonHex tr <<< 8) |||
             (jsonHex tr <<<  4) ||| (jsonHex tr) |> char
    | ch  -> ch

let jsonString tr =
    let start = oneOf "'\"" tr
    use sw = new StringWriter()
    let rec f() =
        match anyChar tr with
        | ch when ch = start -> ()
        | '\\' -> sw.Write (jsonUnescape tr); f()
        | ch -> sw.Write ch; f()
    f()
    sw.ToString()

parseTest jsonString "\"abc\""
parseTest jsonString @"'a\\b\\c'"
parseTest jsonString @"'A\x42\u0043'"
```
```text:実行結果
"abc"
"a\b\c"
"ABC"
```

## 数値の読み取り

数値を読み取ります。マイナスや小数点もサポートします。

```fsharp:JSONParser.fsx（続き）
let rec jsonNumber tr =
    if isOneOf "-" tr then "-" + jsonNumber tr else
    let n1 = many Char.IsDigit tr
    if not <| isOneOf "." tr then n1 else
    n1 + "." + many Char.IsDigit tr

parseTest jsonNumber "123"
parseTest jsonNumber "-3.14"
```
```text:実行結果
"123"
"-3.14"
```

## 値の読み取り

文字列または数値またはシンボルを読み取ります。

```fsharp:JSONParser.fsx（続き）
let jsonValue tr =
    match peek tr with
    | '\'' | '"' -> jsonString tr
    | '-'        -> jsonNumber tr
    | ch when Char.IsDigit  ch -> jsonNumber tr
    | ch when Char.IsLetter ch -> many Char.IsLetterOrDigit tr
    | ch -> failwith <| sprintf "jsonValue: unknown '%c'" ch

parseTest jsonValue "abc 456"
parseTest jsonValue "-1,2"
```
```text:実行結果
"abc"
"-1"
```

## 本体

本体を実装します。先に必要な部品を揃えたので、割とあっさり実装できました。

シーケンスでJSONをパースしながら、項目に当たれば `yield` します。シーケンスの中で再帰するとシーケンスがネストしますが、`yield!` を使えば外からはフラットに見えます。

```fsharp:JSONParser.fsx（続き）
let jsonParser (tr:TextReader) =
    let rec value stack = seq {
        match (spaces @>> peek) tr with
        | '{' ->
            while isOneOf "{," tr && (spaces @>> peek) tr <> '}' do
                match peek tr with
                | '\'' | '"' ->
                    let name = (jsonString @<< spaces @<< oneOf ":") tr
                    let ch = (spaces @>> peek) tr
                    match ch with
                    | '{' | '[' ->
                        yield name, ch, "", stack
                        yield! value (name::stack)
                        yield name, (if ch = '{' then '}' else ']'), "", stack
                    | _ ->
                        yield name, ':', jsonValue tr, stack
                | ch ->
                    failwith <| sprintf "jsonParser: unknown '%c'" ch
            (spaces @<< oneOf "}") tr
        | '[' ->
            while isOneOf "[," tr && (spaces @>> peek) tr <> ']' do
                let ch = peek tr
                match ch with
                | '{' | '[' ->
                    yield "", ch, "", stack
                    yield! value (""::stack)
                    yield "", (if ch = '{' then '}' else ']'), "", stack
                | _ ->
                    yield "", ':', jsonValue tr, stack
            (spaces @<< oneOf "]") tr
        | ch ->
            failwith <| sprintf "jsonParser: unknown '%c'" ch }
    value []

let test = """
{
  "log": {
    "version": "1.1",
    "creator": {
      "name": "Foo",
      "version": "1.0" },
    "pages": [
      { "id": "page_1", "title": "Test1" },
      { "id": "page_2", "title": "Test2" }
    ],
    "test": [-1.23, null, [1, 2, 3]]
  }
}
"""

try
    use sr = new StringReader(test)
    for (n, t, v, st) in jsonParser sr do
        let v = if v.Length < 20 then v else v.[..19] + ".."
        printfn "%A %A %c %A" (List.rev st) n t v
with e ->
    printf "%A" e
```
```text:実行結果
[] "log" { ""
["log"] "version" : "1.1"
["log"] "creator" { ""
["log"; "creator"] "name" : "Foo"
["log"; "creator"] "version" : "1.0"
["log"] "creator" } ""
["log"] "pages" [ ""
["log"; "pages"] "" { ""
["log"; "pages"; ""] "id" : "page_1"
["log"; "pages"; ""] "title" : "Test1"
["log"; "pages"] "" } ""
["log"; "pages"] "" { ""
["log"; "pages"; ""] "id" : "page_2"
["log"; "pages"; ""] "title" : "Test2"
["log"; "pages"] "" } ""
["log"] "pages" ] ""
["log"] "test" [ ""
["log"; "test"] "" : "-1.23"
["log"; "test"] "" : "null"
["log"; "test"] "" [ ""
["log"; "test"; ""] "" : "1"
["log"; "test"; ""] "" : "2"
["log"; "test"; ""] "" : "3"
["log"; "test"] "" ] ""
["log"] "test" ] ""
[] "log" } ""
```

ネストを把握しやすいように、閉じタグに相当するものを出力しています。

## クラスでラップ

このままだと荒削りで使いにくいので、クラスでラップして検索と子要素の列挙を実装します。

```fsharp:JSONParser.fsx（続き）
type JSONParser(tr:TextReader) =
    let en = (jsonParser tr).GetEnumerator()
    member x.Dispose() = tr.Dispose()
    interface IDisposable with
        member x.Dispose() = x.Dispose()
    member x.Current = en.Current
    member x.Name  = let (n, _, _, _) = en.Current in n
    member x.Type  = let (_, t, _, _) = en.Current in t
    member x.Value = let (_, _, v, _) = en.Current in v
    member x.Stack = let (_, _, _, s) = en.Current in s
    member x.Read() = en.MoveNext()
    member x.Find(name:string) =
        let rec f() =
            if not <| x.Read() then false
            elif x.Name = name then true else f()
        f()
    member x.Each() =
        let len = x.Stack.Length
        let num = ref 0
        seq {
            while x.Read() && x.Stack.Length <> len do
                yield !num
                num := !num + 1 }

try
    use jp = new JSONParser(new StringReader(test))
    if jp.Find "pages" then
        for i in jp.Each() do
        for j in jp.Each() do
        printfn "%d:%d. %s = %s" i j jp.Name jp.Value
with e ->
    printf "%A" e
```
```text:実行結果
0:0. id = page_1
0:1. title = Test1
1:0. id = page_2
1:1. title = Test2
```

手っ取り早くデータの一部を取り出すには、これだけあれば大抵の用は足りるのではないでしょうか。

このインターフェースは以前作ったXMLパーサーを参考にしています。

* [Pythonでスクレイピング](http://7shi.hateblo.jp/entry/2012/07/01/223222) 2012.07.01

# まとめ

コード全体は以下に掲載します。

* http://ideone.com/4V8oNB
