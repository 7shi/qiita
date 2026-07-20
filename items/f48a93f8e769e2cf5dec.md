---
coediting: false
comments_count: 0
created_at: '2017-07-14T17:47:54+09:00'
id: f48a93f8e769e2cf5dec
likes_count: 8
private: false
reactions_count: 0
stocks_count: 8
tags:
- name: F#
  versions: []
- name: PDF
  versions: []
title: PDFファイルのチェック
updated_at: '2017-10-24T14:18:51+09:00'
url: https://qiita.com/7shi/items/f48a93f8e769e2cf5dec
slide: false
---

PDFファイルの末尾には決まった構造があります。これを確認することで、ファイルが途中で切れていないかを簡単にチェックできます。

必要最低限の構造だけを説明します。これだけではPDFの仕様を理解するには不足ですが、取っ掛かりにはなるかもしれません。

# 構造

PDFファイルの基本的な部分はテキストで記述されます。

※ ストリームという構造があり、その中にバイナリが直接埋め込まれます。今回の範囲を超えるため詳細は省略します。

最低限の構造を持った白紙のPDFファイルを示します。テキストエディタで打ち込んで改行コードをCRLFで保存すれば、PDFファイルとして開けます。

```text:blank.pdf
%PDF-1.2
1 0 obj <</Type/Catalog/Pages 2 0 R>> endobj
2 0 obj <</Type/Pages/Count 1/Kids [3 0 R]>> endobj
3 0 obj <</Type/Page/Parent 2 0 R>> endobj
xref
0 4
0000000000 65535 f
0000000010 00000 n
0000000056 00000 n
0000000109 00000 n
trailer <</Root 1 0 R/Size 4>>
startxref
153
%%EOF
```

次の構造になっていることが分かります。

1. シグネチャ `%PDF-1.2`
2. オブジェクトの羅列 `番号 0 obj ... endobj`
3. クロスリファレンス `xref`
4. トレイラー `trailer`
5. クロスリファレンスのオフセット `startxref`
6. 番兵 `%%EOF`

`xref` と `trailer` はオブジェクトの1つとして埋め込まれている場合がありますが、`startxref` と `%%EOF` は必ず末尾に存在します。

※ 編集時に差分が追記されることがあり、`%%EOF` などがファイルの途中にも存在することがあります。今回の範囲を超えるため詳細は省略します。

# チェック

ファイルの末尾の `startxref` を確認することで、ファイルが途中で切れていないかを簡単にチェックできます。

F# で `startxref` の値を取得する例を示します。

```fsharp
open System
open System.IO
open System.Text

let readStartXref f =
    use fs = new FileStream(f, FileMode.Open)
    let bytes = Array.zeroCreate<byte> 64
    let pos = max 0L (fs.Length - int64 bytes.Length)
    fs.Position <- pos
    let size = fs.Read(bytes, 0, bytes.Length)
    let text = Encoding.ASCII.GetString(bytes, 0, size)
    let p = text.LastIndexOf "startxref" |> int64
    if p < 0L then p else
    fs.Position <- pos + p
    use sr = new StreamReader(fs, Encoding.ASCII)
    try
        ignore <| sr.ReadLine()
        Int64.Parse(sr.ReadLine())
    with _ -> -1L
```

とりあえずファイルが途中で切れていないかを確認するだけなら、これで用は足ります。

しかし正確には `startxref` のオフセットを取得するだけでは不足で、

* オフセットが正常な範囲内か
* 指す先にクロスリファレンスが存在しているか
* クロスリファレンスが正常な形式か

などをチェックする必要があります。そのためにはクロスリファレンスのパーサーを実装する必要があります。

※ クロスリファレンスがオブジェクトに埋め込まれている場合、圧縮データを展開する必要があります。今回の範囲を超えるため詳細は省略します。

# GUI

手軽にチェックするための簡易GUIです。

* [CheckPDF.fsx](https://bitbucket.org/snippets/7shi/q474By)

# 参考

- [手書きPDF入門](http://www.kobu.com/docs/pdf/pdfxhand.htm)
