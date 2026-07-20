---
coediting: false
comments_count: 0
created_at: '2020-06-09T07:02:16+09:00'
id: 1d6b97c657c6fffdbd70
likes_count: 4
private: false
reactions_count: 0
stocks_count: 0
tags:
- name: Python
  versions: []
- name: F#
  versions: []
- name: Wiktionary
  versions: []
title: Wiktionaryの全文処理をF#とPythonで速度比較
updated_at: '2020-06-27T04:54:43+09:00'
url: https://qiita.com/7shi/items/1d6b97c657c6fffdbd70
slide: false
---

Wiktionary のダンプから全文を読み込む処理を Python で書きましたが、F# に移植して処理速度を比べます。

シリーズの記事です。

1. [Wiktionaryの効率的な処理方法を探る](https://qiita.com/7shi/items/e8091f6ac72491ad45a6)
1. Wiktionaryの処理速度をF#とPythonで比較 ← この記事
1. [Wiktionaryの言語コードを取得](https://qiita.com/7shi/items/4e3c614aac19d645fd1d)
1. [Wiktionaryから特定の言語を抽出](https://qiita.com/7shi/items/449e1aeaee3a25ca5a05)
1. [Wiktionaryで英語の不規則動詞を調査](https://qiita.com/7shi/items/2a945c346f74ca54552f)
1. [Wiktionaryのスクリプトをローカルで動かす](https://qiita.com/7shi/items/6d1e8466b7586e5d0e90)

この記事のスクリプトは以下のリポジトリに掲載しています。

* <https://github.com/7shi/wiktionary-tools/tree/master/fsharp/research>

# 概要

Wiktionary のダンプに手を出した当初、F# を使おうかとは思ったのですが、.NET Framework はデフォルトで bzip2 が扱えなかったので Python で実装を始めました。並列化すれば 1 分ちょっとで処理が終わるようになったので、速度的には Python でも十分だと感じました。

それでもやはり F# ではどれくらいの速度が出るのだろうかと気になったので、不足しているライブラリを補って試します。

※ さらっと書きましたが、調査にかなり手間が掛かりました。

計測に使用した環境は以下の通りです。

* OS: Windows 10 1909
* CPU: AMD Ryzen 5 2500U with Radeon Vega Mobile Gfx (4 cores)
* .NET Framework 4.8.03752
* Python 3.8.2 (WSL1)

# 行数

.NET Framework で bzip2 を扱うには外部ライブラリが必要です。

* [.NET Frameworkのbzip2ライブラリを調査](https://qiita.com/7shi/items/235328dbdc5c0c85edcb)

手始めにダンプを全行読み込んで行数を数えます。対応する Python のコードと所要時間を並べます。

言語|コード|所要時間
----|----|---:
Python|[python/research/countlines.py](https://github.com/7shi/wiktionary-tools/blob/master/python/research/countlines.py)|3m34.911s
F#|[fsharp/research/countlines.fsx](https://github.com/7shi/wiktionary-tools/blob/master/fsharp/research/countlines.fsx)|2m40.270s
コマンド|<code>bzcat FILE.xml.bz2 &#x7c; wc -l</code>|2m32.203s

F# はコマンドに迫るスピードです。

```fsharp
#r "AR.Compression.BZip2.dll"
open System
open System.IO
open System.IO.Compression

let target = "enwiktionary-20200501-pages-articles-multistream.xml.bz2"
let mutable lines = 0
do
    use fs = new FileStream(target, FileMode.Open)
    use bs = new BZip2Stream(fs, CompressionMode.Decompress)
    use sr = new StreamReader(bs)
    while not (isNull (sr.ReadLine())) do
        lines <- lines + 1
Console.WriteLine("lines: {0:#,0}", lines)
```

# ストリーム分割

bzip2 ファイルをストリームごとに分割して読み込みます。

バイト列を経由するオーバーヘッドを回避するため、`FileStream` をマスクして読み取ります。以下の記事で作成した `SubStream` を使用します。

* [ストリームの抜き出しと結合](https://qiita.com/7shi/items/0ac50e3816dca212a52e) → [fsharp/research/StreamUtils.fsx](https://github.com/7shi/wiktionary-tools/blob/master/fsharp/research/StreamUtils.fsx)

[前回の記事](https://qiita.com/7shi/items/e8091f6ac72491ad45a6)で生成したストリーム長のデータ（`streamlen.tsv`）を使用します。

言語|コード|所要時間
----|----|---:
Python|[python/research/countlines-BytesIO.py](https://github.com/7shi/wiktionary-tools/blob/master/python/research/countlines-BytesIO.py)|3m37.827s
F#|[fsharp/research/countlines-split.fsx](https://github.com/7shi/wiktionary-tools/blob/master/fsharp/research/countlines-split.fsx)|5m23.122s

どうやら BZip2Stream の読み取り開始に無視できないオーバーヘッドがあるようで、かなり遅いです。少しでもオーバーヘッドを減らすために `SubStream` を使用しましたが、全然追い付きません。

```fsharp
#r "AR.Compression.BZip2.dll"
#load "StreamUtils.fsx"
open System
open System.IO
open System.IO.Compression
open StreamUtils

let target, slen =
    use sr = new StreamReader("streamlen.tsv")
    sr.ReadLine(),
    [|  while not <| sr.EndOfStream do
        yield sr.ReadLine() |> Convert.ToInt32 |]

let mutable lines = 0
do
    use fs = new FileStream(target, FileMode.Open)
    for length in slen do
        use ss = new SubStream(fs, length)
        use bs = new BZip2Stream(ss, CompressionMode.Decompress)
        use sr = new StreamReader(bs)
        while not (isNull (sr.ReadLine())) do
            lines <- lines + 1
Console.WriteLine("lines: {0:#,0}", lines)
```

## オーバーヘッド回避

Python で並列化したとき、プロセス間通信のオーバーヘッドを抑えるため 10 ストリームごとに読み取りましたが、同様の措置を取ります。比較のため 100 ストリームごとの読み取りも試します。

言語|コード|所要時間|備考
----|----|---:|----
F#|[fsharp/research/countlines-split-10.fsx](https://github.com/7shi/wiktionary-tools/blob/master/fsharp/research/countlines-split-10.fsx)|2m50.913s|10 ストリームごと
F#|[fsharp/research/countlines-split-100.fsx](https://github.com/7shi/wiktionary-tools/blob/master/fsharp/research/countlines-split-100.fsx)|2m40.727s|100 ストリームごと

かなり高速化しました。100 ストリームごとの方が速いため、この先のステップでは 100 ストリームごとの分割を採用します。

```fsharp
let mutable lines = 0
do
    use fs = new FileStream(target, FileMode.Open)
    for lengths in Seq.chunkBySize 100 slen do
        use ss = new SubStream(fs, Array.sum lengths)
        use bs = new BZip2Stream(ss, CompressionMode.Decompress)
        use sr = new StreamReader(bs)
        while not (isNull (sr.ReadLine())) do
            lines <- lines + 1
Console.WriteLine("lines: {0:#,0}", lines)
```

`Seq.chunkBySize` で 100 要素ごとに分割して、`Array.sum` で合計します。

## 文字列変換

Python では文字列に変換して `StringIO` を使用した方が高速でした。F# でも同様の処理を試します。

言語|コード|所要時間|備考
----|----|---:|----
Python|[python/research/countlines-StringIO.py](https://github.com/7shi/wiktionary-tools/blob/master/python/research/countlines-StringIO.py)|3m18.568s|1 ストリームごと
F#|[fsharp/research/countlines-split-string.fsx](https://github.com/7shi/wiktionary-tools/blob/master/fsharp/research/countlines-split-string.fsx)|7m50.915s|1 ストリームごと
F#|[fsharp/research/countlines-split-string-10.fsx](https://github.com/7shi/wiktionary-tools/blob/master/fsharp/research/countlines-split-string-10.fsx)|3m55.453s|10 ストリームごと
F#|[fsharp/research/countlines-split-string-100.fsx](https://github.com/7shi/wiktionary-tools/blob/master/fsharp/research/countlines-split-string-100.fsx)|3m23.417s|100 ストリームごと

F# ではあまり速くないため、この方式は却下します。

```fsharp
let mutable lines = 0
do
    use fs = new FileStream(target, FileMode.Open)
    for length in slen do
        let text =
            use ss = new SubStream(fs, length)
            use bs = new BZip2Stream(ss, CompressionMode.Decompress)
            use ms = new MemoryStream()
            bs.CopyTo(ms)
            Encoding.UTF8.GetString(ms.ToArray())
        use sr = new StringReader(text)
        while not (isNull (sr.ReadLine())) do
            lines <- lines + 1
Console.WriteLine("lines: {0:#,0}", lines)
```

# テキスト抽出

XML の `<text>` タグの中身を抽出して、行数を数えます。

```fsharp:共通部分
let mutable lines = 0
do
    use fs = new FileStream(target, FileMode.Open)
    fs.Seek(int64 slen.[0], SeekOrigin.Begin) |> ignore
    for lengths in Seq.chunkBySize 100 slen.[1 .. slen.Length - 2] do
        for _, text in getPages(fs, Array.sum lengths) do
            for _ in text do
                lines <- lines + 1
Console.WriteLine("lines: {0:#,0}", lines)
```

各種方式を試します。方式によって `getPages` を置き換えます。

## 文字列処理

行ごとに文字列処理でタグをパースします。

言語|コード|所要時間|備考
----|----|---:|----
Python|[python/research/countlines-text.py](https://github.com/7shi/wiktionary-tools/blob/master/python/research/countlines-text.py)|4m06.555s|startswith
F#|[fsharp/research/countlines-text-split-StartsWith.fsx](https://github.com/7shi/wiktionary-tools/blob/master/fsharp/research/countlines-text-split-StartsWith.fsx)|4m42.877s|StartsWith
F#|[fsharp/research/countlines-text-split-slice.fsx](https://github.com/7shi/wiktionary-tools/blob/master/fsharp/research/countlines-text-split-slice.fsx)|4m14.069s|スライス
F#|[fsharp/research/countlines-text-split.fsx](https://github.com/7shi/wiktionary-tools/blob/master/fsharp/research/countlines-text-split.fsx)|4m05.507s|Substring

.NET Framework の `StartsWith` が遅いのは、Unicode 正規化などの処理を行っているためのようです。

* [.NET FrameworkとPythonで合成文字の前方一致を比較](https://qiita.com/7shi/items/07bfbc87956be6e1960d)

`Substring` を使って `StartsWith` 相当の処理をして、ようやく Python と同じくらいの処理速度になります。

```fsharp:StartsWith
let getPages(stream, length) = seq {
    use ss = new SubStream(stream, length)
    use bs = new BZip2Stream(ss, CompressionMode.Decompress)
    use sr = new StreamReader(bs)
    let mutable ns, id = 0, 0
    while sr.Peek() <> -1 do
        let mutable line = sr.ReadLine().TrimStart()
        if line.StartsWith "<ns>" then
            ns <- Convert.ToInt32 line.[4 .. line.IndexOf('<', 4) - 1]
            id <- 0
        elif id = 0 && line.StartsWith "<id>" then
            id <- Convert.ToInt32 line.[4 .. line.IndexOf('<', 4) - 1]
        elif line.StartsWith "<text " then
            let p = line.IndexOf '>'
            if line.[p - 1] = '/' then () else
            if ns <> 0 then
                while not <| line.EndsWith "</text>" do
                line <- sr.ReadLine()
            else
                line <- line.[p + 1 ..]
                yield id, seq {
                    while not <| isNull line do
                    if line.EndsWith "</text>" then
                        if line.Length > 7 then yield line.[.. line.Length - 8]
                        line <- null
                    else
                        yield line
                        line <- sr.ReadLine() }}
```

`StartsWith` の代わりの関数を作って置き換えます。

```fsharp:スライス
let inline startsWith (target:string) (value:string) =
    target.Length >= value.Length && target.[.. value.Length - 1] = value
```
```fsharp:Substring
let inline startsWith (target:string) (value:string) =
    target.Length >= value.Length && target.Substring(0, value.Length) = value
```

## XML パーサー

XML パーサーによってツリーを作る方法と、ツリーを作らないでパースだけを行う方法を比較します。

XML のパースにはルート要素が必要です。既に見たように F# では文字列を経由すると遅くなることから、`Stream` を結合して処理します。以下の記事で作成した `ConcatStream` を使用します。

* [ストリームの抜き出しと結合](https://qiita.com/7shi/items/0ac50e3816dca212a52e) → [fsharp/research/StreamUtils.fsx](https://github.com/7shi/wiktionary-tools/blob/master/fsharp/research/StreamUtils.fsx)

### ツリーあり

言語|コード|所要時間|備考
----|----|---:|----
Python|[python/research/countlines-text-xml.py](https://github.com/7shi/wiktionary-tools/blob/master/python/research/countlines-text-xml.py)|5m50.826s|ElementTree.fromstring
F#|[fsharp/research/countlines-text-split-doc.fsx](https://github.com/7shi/wiktionary-tools/blob/master/fsharp/research/countlines-text-split-doc.fsx)|6m21.588s|XmlDocument

Python に比べて F# は遅いです。

```fsharp
let getPages(stream, length) = seq {
    use ss = new SubStream(stream, length)
    use cs = new ConcatStream([
        new MemoryStream("<pages>"B)
        new BZip2Stream(ss, CompressionMode.Decompress)
        new MemoryStream("</pages>"B) ])
    use xr = XmlReader.Create(cs)
    let doc = XmlDocument()
    doc.Load(xr)
    for page in doc.ChildNodes.[0].ChildNodes do
        let ns = Convert.ToInt32(page.SelectSingleNode("ns").InnerText)
        if ns = 0 then
            let id = Convert.ToInt32(page.SelectSingleNode("id").InnerText)
            let text = page.SelectSingleNode("revision/text").InnerText
            use sr = new StringReader(text)
            yield id, seq {
                while sr.Peek() <> -1 do
                    yield sr.ReadLine() }}
```

### ツリーなし

Python の各種パーサーについては以下の記事を参照してください。

* [PythonのXMLパースを速度比較](https://qiita.com/7shi/items/c7608db7a097ddd16be6)

F# ではプル型の XmlReader を使用します。

言語|コード|所要時間|備考
----|----|---:|----
Python|[python/research/countlines-text-xmlparser.py](https://github.com/7shi/wiktionary-tools/blob/master/python/research/countlines-text-xmlparser.py)|6m46.163s|XMLParser
Python|[python/research/countlines-text-xmlpull.py](https://github.com/7shi/wiktionary-tools/blob/master/python/research/countlines-text-xmlpull.py)|6m04.553s|XMLPullParser
Python|[python/research/countlines-text-xmliter.py](https://github.com/7shi/wiktionary-tools/blob/master/python/research/countlines-text-xmliter.py)|6m29.298s|ElementTree.iterparse
F#|[fsharp/research/countlines-text-split-reader.fsx](https://github.com/7shi/wiktionary-tools/blob/master/fsharp/research/countlines-text-split-reader.fsx)|3m17.916s|XmlReader
F#|[fsharp/research/countlines-text-reader.fsx](https://github.com/7shi/wiktionary-tools/blob/master/fsharp/research/countlines-text-reader.fsx)|3m16.122s|XmlReader（未分割）

※ 「未分割」はストリームのことです。結果を見ると、分割によるオーバーヘッドはほとんどないようです。

.NET Framework の `XmlDocument` は `XmlReader` を利用して組み立てられます。`XmlReader` 単体で使った方が圧倒的に速いです。この先のステップでは `XmlReader` による方式のみを使用します。

Python でも事情は同じはずですが、ツリーの作成が相当に効率化されているようで、ツリーを作った方が高速です。

```fsharp
let getPages(stream, length) = seq {
    use ss = new SubStream(stream, length)
    use cs = new ConcatStream([
        new MemoryStream("<pages>"B)
        new BZip2Stream(ss, CompressionMode.Decompress)
        new MemoryStream("</pages>"B) ])
    use xr = XmlReader.Create(cs)
    let mutable ns, id = 0, 0
    while xr.Read() do
        if xr.NodeType = XmlNodeType.Element then
            match xr.Name with
            | "ns" ->
                if xr.Read() then ns <- Convert.ToInt32 xr.Value
                id <- 0
            | "id" ->
                if id = 0 && xr.Read() then id <- Convert.ToInt32 xr.Value
            | "text" ->
                if ns = 0 && not xr.IsEmptyElement && xr.Read() then
                    yield id, seq {
                        use sr = new StringReader(xr.Value)
                        while sr.Peek() <> -1 do
                            yield sr.ReadLine() }
            | _ -> () }
```

# 言語テーブル

今までのコードから、共通部分を括り出します。

* [fsharp/research/MediaWikiParse.fsx](https://github.com/7shi/wiktionary-tools/blob/master/fsharp/research/MediaWikiParse.fsx)

どの項目にどの言語のデータが含まれるかのテーブルを作成します（`output1.tsv`）。言語名は別テーブルに正規化します（`output2.tsv`）。

```fsharp
do
    use sw = new StreamWriter("output1.tsv")
    sw.NewLine <- "\n"
    for id, lid in results do
        fprintfn sw "%d\t%d" id lid
do
    use sw = new StreamWriter("output2.tsv")
    sw.NewLine <- "\n"
    for kv in langs do
        fprintfn sw "%d\t%s" kv.Value kv.Key
```

1 つの記事は `==言語名==` という行で区切られているため、それを検出して id と紐付けます。下位の見出しで `===項目名===` が使用されるため区別します。

既に見たように `StartsWith` は遅いです。行頭から 1 文字ずつ調べる方法と、正規表現とを比較します。

XML のパースは、Python では文字列処理、F# では `XmlReader` を使用します。

言語|コード|所要時間|備考
----|----|---:|----
Python|[python/research/checklang.py](https://github.com/7shi/wiktionary-tools/blob/master/python/research/checklang.py)|4m35.440s|startswith
F#|[fsharp/research/checklang-StartsWith.fsx](https://github.com/7shi/wiktionary-tools/blob/master/fsharp/research/checklang-StartsWith.fsx)|3m43.965s|StartsWith
Python|[python/research/checklang-ch.py](https://github.com/7shi/wiktionary-tools/blob/master/python/research/checklang-ch.py)|4m37.771s|1文字ずつ
F#|[fsharp/research/checklang.fsx](https://github.com/7shi/wiktionary-tools/blob/master/fsharp/research/checklang.fsx)|3m24.302s|1文字ずつ
Python|[python/research/checklang-re.py](https://github.com/7shi/wiktionary-tools/blob/master/python/research/checklang-re.py)|4m31.855s|正規表現
F#|[fsharp/research/checklang-re.fsx](https://github.com/7shi/wiktionary-tools/blob/master/fsharp/research/checklang-re.fsx)|3m46.270s|正規表現

F# では 1 文字ずつ調べると速いですが、実装が面倒で汎用性もありません。正規表現は `StartsWith` と速度がほとんど変わりません。汎用性を考えれば正規表現を使うのが無難そうです。

```fsharp:StartsWith
            for line in text do
                if line.StartsWith "==" && not <| line.StartsWith "===" then
                    let lang = line.[2..].Trim()
                    let mutable e = lang.Length - 1
                    while e > 0 && lang.[e] = '=' do e <- e - 1
                    let lang = lang.[..e].Trim()
```
```fsharp:1文字ずつ
            for line in text do
                if line.Length >= 3 && line.[0] = '=' && line.[1] = '=' && line.[2] <> '=' then
```
```fsharp:正規表現
    let r = Regex "^==([^=].*)=="
（略）
            for line in text do
                let m = r.Match line
                if m.Success then
                    let lang = m.Groups.[1].Value.Trim()
```

## 並列化

F# ではマルチスレッド、Python ではマルチプロセスを利用して並列化します。

* [Pythonの並列計算サンプルをF#に移植](https://qiita.com/7shi/items/b5121bb3a94e691cd1c5)

言語|コード|所要時間|備考
----|----|---:|----
Python|[python/research/checklang-parallel.py](https://github.com/7shi/wiktionary-tools/blob/master/python/research/checklang-parallel.py)|1m16.566s|startswith
F#|[fsharp/research/checklang-parallel.fsx](https://github.com/7shi/wiktionary-tools/blob/master/fsharp/research/checklang-parallel.fsx)|1m03.941s|1文字ずつ
Python|[python/research/checklang-parallel-re.py](https://github.com/7shi/wiktionary-tools/blob/master/python/research/checklang-parallel-re.py)|1m07.106s|正規表現
F#|[fsharp/research/checklang-parallel-re.fsx](https://github.com/7shi/wiktionary-tools/blob/master/fsharp/research/checklang-parallel-re.fsx)|1m07.009s|正規表現

ほぼ同じです。並列化による伸び幅は Python の方が大きいです。

```fsharp:1文字ずつ
let getlangs(pos, length) = async { return [
    use fs = new FileStream(target, FileMode.Open, FileAccess.Read)
    fs.Seek(pos, SeekOrigin.Begin) |> ignore
    for id, text in MediaWikiParse.getPages(fs, length) do
        for line in text do
            if line.Length >= 3 && line.[0] = '=' && line.[1] = '=' && line.[2] <> '=' then
                let lang = line.[2..].Trim()
                let mutable e = lang.Length - 1
                while e > 0 && lang.[e] = '=' do e <- e - 1
                yield id, lang.[..e].Trim() ]}
```
```fsharp:正規表現
let getlangs(pos, length) = async { return [
    let r = Regex "^==([^=].*)=="
    use fs = new FileStream(target, FileMode.Open, FileAccess.Read)
    fs.Seek(pos, SeekOrigin.Begin) |> ignore
    for id, text in MediaWikiParse.getPages(fs, length) do
        for line in text do
            let m = r.Match line
            if m.Success then
                yield id, m.Groups.[1].Value.Trim() ]}

let results =
    sposlen.[1 .. sposlen.Length - 2]
    |> Seq.chunkBySize 100
    |> Seq.map Array.unzip
    |> Seq.map (fun (ps, ls) -> Array.min ps, Array.sum ls)
    |> Seq.map getlangs
    |> Async.Parallel
    |> Async.RunSynchronously
    |> List.concat
let langs = Dictionary<string, int>()
do
    use sw = new StreamWriter("output1.tsv")
    sw.NewLine <- "\n"
    for id, lang in results do
        let lid =
            if langs.ContainsKey lang then langs.[lang] else
            let lid = langs.Count + 1
            langs.[lang] <- lid
            lid
        fprintfn sw "%d\t%d" id lid
do
    use sw = new StreamWriter("output2.tsv")
    sw.NewLine <- "\n"
    for kv in langs do
        fprintfn sw "%d\t%s" kv.Value kv.Key
```

# .NET Core と Mono

WSL1 上の .NET Core と Mono で計測しました。Windows 上の .NET Framework の結果と比較します。

略称との対応は以下の通りです。

* Framework: .NET Framework 4.8.03752 (Windows 10)
* Core: .NET Core 3.1.103 (WSL1)
* Mono: Mono 6.4.0 (WSL1)

コード|Framework|Core|Mono|備考
----|---:|---:|---:|----
[fsharp/research/checklang.fsx](https://github.com/7shi/wiktionary-tools/blob/master/fsharp/research/checklang.fsx)|3m24.302s|3m25.545s|4m22.330s|
[fsharp/research/checklang-re.fsx](https://github.com/7shi/wiktionary-tools/blob/master/fsharp/research/checklang-re.fsx)|3m46.270s|3m42.882s|4m51.236s|正規表現
[fsharp/research/checklang-parallel.fsx](https://github.com/7shi/wiktionary-tools/blob/master/fsharp/research/checklang-parallel.fsx)|1m03.941s|0m59.014s|2m39.716s|並列
[fsharp/research/checklang-parallel-re.fsx](https://github.com/7shi/wiktionary-tools/blob/master/fsharp/research/checklang-parallel-re.fsx)|1m07.009s|1m06.136s|3m28.074s|並列、正規表現

.NET Core は .NET Framework と同じか少し速いようです。

.NET Core はプロジェクトを作るのが基本ですが、実行ファイルが複数あって面倒だったので、以下の方法でコンフィグを書いて対応しました。

* [.NET CoreでプロジェクトなしにF#を使う](https://qiita.com/7shi/items/6bc57ddde5a06e526496)

# 感想

最速の方法では F# と Python はほぼ同じという結果になりました。同じ処理内容で移植すると Python の方が速いこともあったのが印象的でした。

以下の記事で試したように、文字単位の処理では圧倒的な差が出ます。

* [MySQLのダンプをTSVに変換するスクリプトを書く](https://qiita.com/7shi/items/c296a168d53c7af28942)
