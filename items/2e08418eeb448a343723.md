---
coediting: false
comments_count: 0
created_at: '2016-12-27T16:50:08+09:00'
id: 2e08418eeb448a343723
likes_count: 5
private: false
reactions_count: 0
stocks_count: 3
tags:
- name: F#
  versions: []
- name: JSON
  versions: []
title: HARからファイルを抽出する
updated_at: '2016-12-29T17:48:09+09:00'
url: https://qiita.com/7shi/items/2e08418eeb448a343723
slide: false
---

HARファイル（ブラウザの通信状況をダンプしたJSONファイル）からファイルを抽出します。

この記事では次の記事で作ったJSONパーサーを使用します。

* [JSONパーサーを作る](http://qiita.com/7shi/items/04c2991239894687ef2f) 2016.12.26

# 調査

ある程度巨大なHARファイルは全容を把握しにくいので、項目を列挙して眺めます。

```fsharp
try
    use sr = new StreamReader("Test.har", Text.Encoding.UTF8)
    use jp = new JSONParser(sr)
    while jp.Read() do
    let v = jp.Value
    let v = if v.Length < 20 then v else v.[..19] + ".."
    printfn "%A %A %c %A" (List.rev jp.Stack) jp.Name jp.Type v
with e ->
    printf "%A" e
```
```text:実行結果
[] "log" { ""
["log"] "version" : "1.1"
["log"] "creator" { ""
["log"; "creator"] "name" : "Firefox"
["log"; "creator"] "version" : "50.0"
["log"] "creator" } ""
["log"] "browser" { ""
["log"; "browser"] "name" : "Firefox"
["log"; "browser"] "version" : "50.0"
["log"] "browser" } ""
["log"] "pages" [ ""
["log"; "pages"] "" { ""
（略）
```

これを眺めてみると、主要部は以下の構造になっていることが分かりました。

```text
log
+ creator
+ browser
+ pages
+ entries
  + (entry)
  | + request
  | | + url
  | + response
  |   + headers
  |   + cookies
  |   + content
  + (entry)
  + ...
```

## contentの項目

ファイルの実体が入っているのは `content` です。すべてに同じ項目が存在するわけではないようなので、全部の項目をチェックして列挙します。

```fsharp
try
    use sr = new StreamReader("Test.har", Text.Encoding.UTF8)
    use jp = new JSONParser(sr)
    seq {
        while jp.Find "content" do
        for _ in jp.Each() -> jp.Name }
    |> Seq.distinct
    |> Seq.sort
    |> Seq.iter (printfn "%s")
with e ->
    printf "%A" e
```
```text:実行結果
comment
encoding
mimeType
size
text
```

`comment` はオプショナルなようで、ほとんど存在しません。

### パーサーの実装

エントリーを格納するレコード型を用意します。`request` の `url` と `response` の `content` を読み込みます。

```fsharp
type Entry = { url:string; size:int; mimeType:string; encoding:string; text:string }

let entry (jp:JSONParser) =
    let mutable url, size, mimeType, encoding, text = "", 0, "", "", ""
    for _ in jp.Each() do
        match jp.Name with
        | "request" ->
            for _ in jp.Each() do
            if jp.Name = "url" then url <- jp.Value
        | "response" ->
            for _ in jp.Each() do
            if jp.Name = "content" then
                for _ in jp.Each() do
                match jp.Name with
                | "size"     -> size <- Convert.ToInt32 jp.Value
                | "mimeType" -> mimeType <- jp.Value
                | "encoding" -> encoding <- jp.Value
                | "text"     -> text     <- jp.Value
                | _          -> ()
        | _ -> ()
    { url = url; size = size; mimeType = mimeType; encoding = encoding; text = text }
```

JSONの構造と同じようにパーサーを書きます。階層ごとに `jp.Each()` でループを回しているのがポイントです。

## 値の調査

`encoding` と `mimeType` の値を調べます。

```fsharp
try
    use sr = new StreamReader("Test.har", Text.Encoding.UTF8)
    use jp = new JSONParser(sr)
    seq {
        while jp.Find "content" do
        for _ in jp.Each() do
        match jp.Name with
        | "encoding" | "mimeType" -> yield jp.Name, jp.Value
        | _ -> () }
    |> Seq.groupBy fst
    |> Seq.iter (fun (n, vs) ->
        printfn "%s:" n
        vs
        |> Seq.map snd
        |> Seq.distinct
        |> Seq.sort
        |> Seq.iter (printfn "  %s"))
with e ->
    printf "%A" e
```
```text:実行結果
mimeType:
  image/jpeg
  image/png
  text/css; charset=UTF-8
  text/html
  text/html; charset=UTF-8
  text/javascript
  text/javascript; charset=UTF-8
encoding:
  base64
```

サーバーによって `charset` が付いたり付かなかったりします。今回は簡単のため無視して UTF-8 で統一します。

### 拡張子の変換

MIMEタイプから拡張子に変換します。網羅しきれないため代表的なものだけです。

```fsharp
let mimeToExt (mime:string) =
    match (mime.Split ';').[0].Trim().ToLower() with
    | "application/javascript"   -> ".js"
    | "application/json"         -> ".json"
    | "application/octet-stream" -> ".bin"
    | "application/x-javascript" -> ".js"
    | "binary/octet-stream"      -> ".bin"
    | "image/gif"                -> ".gif"
    | "image/jpeg"               -> ".jpg"
    | "image/png"                -> ".png"
    | "image/x-win-bitmap"       -> ".bmp"
    | "text/css"                 -> ".css"
    | "text/html"                -> ".html"
    | "text/javascript"          -> ".js"
    | "text/plain"               -> ".txt"
    | "text/xml"                 -> ".xml"
    | _                          -> ""
```

# ファイルの抽出

ここまで調べればファイルが抽出できます。

```fsharp
let extractHar (har:string) (outdir:string) =
    if not <| Directory.Exists outdir then
        Directory.CreateDirectory outdir |> ignore
    use sr = new StreamReader(har, Text.Encoding.UTF8)
    let jp = JSONParser sr
    if not <| jp.Find "entries" then () else
    use sw = new StreamWriter(Path.Combine(outdir, "_index.tsv"), false, Text.Encoding.UTF8)
    seq {for _ in jp.Each() -> entry jp}
    |> Seq.filter (fun e -> e.url.Length > 0 && e.text.Length > 0 && e.size > 0)
    |> Seq.iteri (fun i e ->
        let fn = string (i + 1) + mimeToExt e.mimeType
        fprintfn sw "%s\t%d\t%s\t%s\t%s" fn e.size e.mimeType e.encoding e.url
        let fn = Path.Combine(outdir, fn)
        match e.encoding with
        | "base64" ->
            File.WriteAllBytes(fn, Convert.FromBase64String e.text)
        | _ ->
            File.WriteAllText(fn, e.text, Text.Encoding.UTF8))
```

次のように使用します。

```fsharp
extractHar "入力.har" "出力先フォルダ"
```

出力先フォルダには `_index.tsv` というファイル一覧が出力されます。

# まとめ

コード全体は以下に掲載します。

* https://bitbucket.org/snippets/7shi/z4KKK
