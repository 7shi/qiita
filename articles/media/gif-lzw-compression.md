---
coediting: false
comments_count: 0
created_at: '2017-01-17T19:22:53+09:00'
id: cfe1c6e42aff78c06652
likes_count: 5
private: false
reactions_count: 0
stocks_count: 4
tags:
- name: F#
  versions: []
- name: GIF
  versions: []
title: GIFのLZW圧縮を調べてみた
updated_at: '2017-02-06T22:30:19+09:00'
url: https://qiita.com/7shi/items/cfe1c6e42aff78c06652
slide: false
---

GIFのLZW圧縮について、実装を通して調べてみました。

シリーズの記事です。

1. [GIFのバイナリを読んでみた](http://qiita.com/7shi/items/33117c6c369d37dc6cdd)
1. GIFのLZW圧縮を調べてみた ← この記事
1. [GIFのLZWを展開してみた](http://qiita.com/7shi/items/778f58d4647b10f0f403)

# 参考

Wikipediaには圧縮の具体例が載っています。

* [GIF - Wikipedia](https://en.wikipedia.org/wiki/GIF)

一読しただけで理解するのはなかなか難しいです。掲載されているログと同じように動作させるにはどうすれば良いか、ということを考えながら実装して調べました。

※ LZWは開発された当時のコンピュータ事情に合わせて、少ないリソースで圧縮・展開することに注力した仕様です。今回は調査が目的のためリソース効率などは気にせず実装しています。

# 実装

試行錯誤の過程を掲載してもあまり参考にはならないと思うので、完成したコードを説明します。

* [LZWCompress.fsx](https://bitbucket.org/snippets/7shi/gpBMo)

ピクセルデータをカラーインデックスの配列で定義します。

```fsharp
let src = [|
    0x28; 0xff; 0xff
    0xff; 0x28; 0xff
    0xff; 0xff; 0xff
    0xff; 0xff; 0xff
    0xff; 0xff; 0xff |]
```

インデックスは 0～0xff ですが、後続の数字に特殊コードを割り当てます。

* 0x100 clr テーブル初期化
* 0x101 end データ終了
* 0x102～ テーブルのインデックス

※ 具体的な値は LZW Minimum Code Size に依存しますが、今回は決め打ちで進めます。

clr のみ定義して、その他は計算で求めます。

```fsharp
let clr = 0x100
```

Wikipediaのログを4列に簡略化して模倣します。

1. 入力
1. テーブルに追加したタイミングでインデックスを出力
1. 圧縮結果が確定したタイミングでコードを出力
1. 説明

```fsharp
printfn "Input\tTable\tOutput\tDesc."
printfn "-----\t-----\t------\t-----"
```

ログ表示用にバイナリを16進数化する関数を定義します。

```fsharp
let hex (bin:int seq) =
    bin |> Seq.map (sprintf "%02x") |> String.concat " "
```

圧縮結果の出力先を定義します。出力するタイミングでログを出力するため、出力用の関数を定義します。

```fsharp
let data = System.Collections.Generic.List<int>()
let output v msg =
    printfn "\t\t0x%03x\t%s" v msg
    data.Add v
```

テーブルを定義します。テーブルに追加するタイミングでログを出力するため、テーブル追加用の関数を定義します。テーブルは上限がインデックス値`0xfff`のため、超過した場合は消去します。

```fsharp
let table = System.Collections.Generic.List<int[]>()
let add codes msg =
    let n = clr + 2 + table.Count
    printfn "\t0x%03x\t\t%s" n msg
    table.Add codes
    if n >= 0xfff then
        output clr "Clear"
        table.Clear()
```

最初にテーブル初期化（`clr`）を出力します。

```fsharp
output clr "Clear"
```

ピクセルデータを読み込みながら、結果が確定したタイミングで出力します。未確定領域の先頭インデックスを定義します。

```fsharp
let mutable j = 0
```

テーブルから一致が見付かっても、もっと長い一致があるかもしれないので、確定は保留して次に進めます。そのため確定候補を変数で保持します。

```fsharp
let mutable prev = -1
```

※ 常に1要素先読みするため、1つ前の要素を保持していると解釈できます。構文解析でもよく使う手法です。

ピクセルデータをループで読みます。

```fsharp
for i = 0 to src.Length - 1 do
```

未確定領域と同内容がテーブルに存在するかチェックします。存在してももっと長く一致する可能性があるため、すぐには確定せずに候補として記憶して先に進みます。

```fsharp
    let target = src.[j..i]
    let h = hex target
    printf "0x%02x\t\t\t'%s' " src.[i] h
    match table |> Seq.tryFindIndex ((=) target) with
    | Some n ->
        prev <- clr + 2 + n
        printfn "0x%03x found in table" prev
```

テーブルに存在しないときは、ループの先頭でなければテーブルに追加して、候補を確定させます。Wikipediaの例とは動作が前後しますが、結果には影響しません。

```fsharp
    | _ ->
        if i = 0 then
            printfn "1st pixel always to output"
        else
            printfn "not found in table"
            add target (sprintf "- add '%s' to table" h)
            output prev "- output code for previous string"
```

手前まで確定したため、現在見ている箇所を未確定領域の先頭として、値を候補とします。

```fsharp
        prev <- src.[i]
        printfn "\t\t\t'%02x' initialize local string" prev
        j <- i
```

ピクセルデータの最後まで行けばループから抜けて、未確定領域を確定させ、終了コードを出力します。

```fsharp
printfn "\t\t\tNo more pixels"
if prev >= 0 then output prev "- output code for last string"
output (clr + 1) "End"
```

単純なアルゴリズムですが、そこそこ圧縮できます。昔はこれが特許になって大金が動いたと思うと感慨深いです。

## 動作結果

Wikipediaのログは情報が多過ぎて分かりにくかったため改良したつもりです。これを眺めているだけでも動作原理が何となく伝われば良いのですが、いかがでしょうか。

```text
Input   Table   Output  Desc.
-----   -----   ------  -----
                0x100   Clear
0x28                    '28' 1st pixel always to output
                        '28' initialize local string
0xff                    '28 ff' not found in table
        0x102           - add '28 ff' to table
                0x028   - output code for previous string
                        'ff' initialize local string
0xff                    'ff ff' not found in table
        0x103           - add 'ff ff' to table
                0x0ff   - output code for previous string
                        'ff' initialize local string
0xff                    'ff ff' 0x103 found in table
0x28                    'ff ff 28' not found in table
        0x104           - add 'ff ff 28' to table
                0x103   - output code for previous string
                        '28' initialize local string
0xff                    '28 ff' 0x102 found in table
0xff                    '28 ff ff' not found in table
        0x105           - add '28 ff ff' to table
                0x102   - output code for previous string
                        'ff' initialize local string
0xff                    'ff ff' 0x103 found in table
0xff                    'ff ff ff' not found in table
        0x106           - add 'ff ff ff' to table
                0x103   - output code for previous string
                        'ff' initialize local string
0xff                    'ff ff' 0x103 found in table
0xff                    'ff ff ff' 0x106 found in table
0xff                    'ff ff ff ff' not found in table
        0x107           - add 'ff ff ff ff' to table
                0x106   - output code for previous string
                        'ff' initialize local string
0xff                    'ff ff' 0x103 found in table
0xff                    'ff ff ff' 0x106 found in table
0xff                    'ff ff ff ff' 0x107 found in table
                        No more pixels
                0x107   - output code for last string
                0x101   End
```

# ビットストリームへの格納

GIFにデータを格納するにはコード列をビットストリームに格納する必要があります。

完成したコードを説明します。

* [LZWEncode.fsx](https://bitbucket.org/snippets/7shi/BqaLo)

## 書き込み

指定したビット長さで値をビットストリームに書き込むクラスを実装します。

データは255バイトごとのブロックに分割されています。ビットストリームはビット単位でのリトルエンディアンのため下位からバッファに格納します。バッファの最大サイズまで到達すれば、ブロックサイズを添えてバイトストリームに書き込みます。ストリームを閉じればバッファをフラッシュしてブロックサイズ0を書き込みます。

※ ビットストリームの中にブロックサイズが割り込む形となります。

```fsharp
type BitWriter(s:Stream) =
    let buf = Array.zeroCreate<byte> 254
    let mutable i, b = 0, 0
    let flush() =
        s.WriteByte(byte i)  // block size
        s.Write(buf, 0, i)   // data bytes
        Array.Clear(buf, 0, buf.Length)
        i <- 0
    interface IDisposable with
        override x.Dispose() =
            if b > 0 then i <- i + 1
            flush()
            flush()  // Block Terminator
    member x.Write blen v =
        let left = 8 - b
        if i >= buf.Length then flush()
        buf.[i] <- buf.[i] ||| byte (v <<< b)
        if blen < left then b <- b + blen else
        i <- i + 1
        b <- 0
        let blen = blen - left
        if blen > 0 then x.Write blen (v >>> left)
```

### テスト

結果を確認するため16進数でダンプする関数を実装します。

```fsharp
let hexdump (bin:byte seq) =
    bin |> Seq.iteri (fun i b ->
        if i &&& 15 = 0 then
            if i > 0 then printfn ""
            printf "%04x:" i
        printf " %02x" b)
    printfn ""
```

Wikipediaに掲載されているサンプルのコード列をビットストリームに格納してみます。コード長はすべて9bitだと分かっているため決め打ちします。

```fsharp
let src1 = [| 0x100; 0x28; 0xff; 0x103; 0x102; 0x103; 0x106; 0x107; 0x101 |]
let dst1 =
    use ms = new MemoryStream()
    do  use bitw = new BitWriter(ms)
        for v in src1 do bitw.Write 9 v
    ms.ToArray()
hexdump dst1
```
```text:実行結果
0000: 0b 00 51 fc 1b 28 70 a0 c1 83 01 01 00
```

うまく格納できています。

## ビットサイズ

値を格納するのに必要なビットサイズを取得する関数を実装します。

```fsharp
let bitSize v =
    let rec f i n =
        if n > v then i else f (i + 1) (n <<< 1)
    f 1 2
```

## 格納

ビットストリームへ格納する際にコード長は可変です。出現する可能性があるコードをすべて格納できるだけのサイズとなるため、最大値は今から追加しようとしているテーブルのインデックスとなります。ただし12ビットの制限があるため、正常なデータであれば制限を超えた所でclrを発行してテーブルをクリアします。

先に実装した圧縮をベースに、`BitWriter`を使うように手直しした`encode`を実装します。アルゴリズムは変えないため、動作を信用してログ出力は除去します。

```fsharp
let encode (s:Stream) (src:byte[]) =
    let lzwMin = max 2 (Array.max src |> int |> bitSize)
    s.WriteByte(byte lzwMin)  // LZW Minimum Code Size
    use bitw = new BitWriter(s)
    let clr = 1 <<< lzwMin
    let table = List<byte[]>()
    let mutable blen, next, j, prev = lzwMin + 1, clr * 2, 0, -1
    bitw.Write blen clr
    for i = 0 to src.Length - 1 do
        let target = src.[j..i]
        match table |> Seq.tryFindIndex ((=) target) with
        | Some n ->
            prev <- clr + 2 + n
        | _ ->
            if prev >= 0 then
                let n = clr + 2 + table.Count
                bitw.Write blen prev
                table.Add target
                if n >= 0xfff then
                    bitw.Write blen clr
                    table.Clear()
                    blen <- lzwMin + 1
                    next <- clr * 2
                    prev <- -1
                elif n >= next then
                    blen <- blen + 1
                    next <- next * 2
            prev <- int src.[i]
            j <- i
    if prev >= 0 then bitw.Write blen prev
    bitw.Write blen (clr + 1)  // End
```

### テスト

インデックスデータと期待される出力を渡してテストする関数を実装します。

```fsharp
let test src expected =
    use ms = new MemoryStream()
    encode ms src
    let dst = ms.ToArray()
    printfn "[%s]" (if dst = expected then "OK" else "NG")
    hexdump dst
```

Wikipediaのデータでテストします。期待する結果の先頭バイトに`lzwMin`を付加します。データの符号長はすべて9bitのため、符号長を決め打ちしたテストと同じ結果です。

```fsharp
test (Array.map byte
    [|  0x28; 0xff; 0xff
        0xff; 0x28; 0xff
        0xff; 0xff; 0xff
        0xff; 0xff; 0xff
        0xff; 0xff; 0xff |])
    (Array.append [|8uy|] dst1)
```
```text:実行結果
[OK]
0000: 08 0b 00 51 fc 1b 28 70 a0 c1 83 01 01 00
```

一致しました。

[GIFのバイナリを読んでみた](http://qiita.com/7shi/items/33117c6c369d37dc6cdd)で使用した画像のインデックスデータでテストします。

```fsharp
test (Array.map byte
    [|  2;2;2;2;2;2;2;2;2;2;2;2;2;2;2;2
        2;2;2;2;2;2;2;1;0;2;2;2;2;2;2;2
        2;2;2;2;2;2;2;0;1;1;2;2;2;2;2;2
        2;2;2;2;2;2;0;2;2;0;2;2;2;2;2;2
        2;2;2;2;2;0;2;2;2;1;1;2;2;2;2;2
        2;2;2;2;1;1;2;2;2;2;0;2;2;2;2;2
        2;2;2;2;0;2;2;2;2;2;0;2;2;2;2;2
        2;2;2;0;2;2;2;2;2;2;1;1;2;2;2;2
        2;1;0;0;0;0;0;1;2;2;2;0;2;2;2;2
        2;2;0;2;2;2;2;1;1;1;1;0;1;1;1;1
        2;1;1;2;2;2;2;2;2;2;2;1;1;2;2;2
        2;0;2;2;2;2;2;2;2;2;2;2;0;2;2;2
        2;0;2;2;2;2;2;2;2;2;2;2;0;2;2;2
        1;1;2;2;2;2;2;2;2;2;2;2;1;1;2;2
        2;2;2;2;2;2;2;2;2;2;2;2;2;0;2;2
        2;2;2;2;2;2;2;2;2;2;2;2;2;2;2;2 |])
    [|  // 22. Table Based Image Data.
        2uy     // LZW Minimum Code Size
        0x2Buy  // block size
                // data bytes
        0x94uy; 0x8Fuy; 0xA9uy; 0x16uy; 0xB0uy; 0x0Buy; 0x42uy; 0x78uy
        0xC8uy; 0x09uy; 0x4Buy; 0xB1uy; 0xA4uy; 0xFBuy; 0x60uy; 0xF5uy
        0x5Duy; 0x4Fuy; 0x28uy; 0x74uy; 0x47uy; 0x03uy; 0xA4uy; 0x91uy
        0x07uy; 0x22uy; 0x92uy; 0x14uy; 0xBDuy; 0xE5uy; 0xB4uy; 0x98uy
        0x62uy; 0x56uy; 0x51uy; 0xF7uy; 0xACuy; 0xDBuy; 0xFAuy; 0xFEuy
        0x43uy; 0x14uy; 0x00uy
        0uy |]  // Block Terminator
```
```text:実行結果
[OK]
0000: 02 2b 94 8f a9 16 b0 0b 42 78 c8 09 4b b1 a4 fb
0010: 60 f5 5d 4f 28 74 47 03 a4 91 07 22 92 14 bd e5
0020: b4 98 62 56 51 f7 ac db fa fe 43 14 00 00
```

GIMPで生成したバイト列と一致しました。うまく格納できています。

# GIFファイルへの格納

いよいよGIFファイルを生成します。

完成したコードを説明します。

* [GIFEncode.fsx](https://bitbucket.org/snippets/7shi/dB5Rz)

## GIFコンテナ

サイズとカラーパレットとピクセルデータを渡してGIFファイルを生成する関数を実装します。

```fsharp
let createGIF (s:Stream) width height (ctable:int[]) (pixels:byte[]) =
    use bw = new BinaryWriter(s, Encoding.ASCII)

    // 17. Header.
    bw.Write("GIF87a".ToCharArray())

    // 18. Logical Screen Descriptor.
    bw.Write(uint16 width )  // Logical Screen Width
    bw.Write(uint16 height)  // Logical Screen Height
    // <Packed Fields>
    //   Global Color Table Flag
    //   | Color Resolution
    //   | |   Sort Flag
    //   | |   | Size of Global Color Table
    //   1 111 0 xxx
    let ctsize = (ctable.Length - 1 |> bitSize) - 1
    if ctsize > 7 then
        failwith <| sprintf "ctable.Length %d > 256" ctable.Length
    bw.Write(0b11110000 ||| ctsize |> byte)
    bw.Write(0uy)  // Background Color Index
    bw.Write(0uy)  // Pixel Aspect Ratio

    // 19. Global Color Table.
    for c in ctable do
        bw.Write(c >>> 16 |> byte)  // R
        bw.Write(c >>>  8 |> byte)  // G
        bw.Write(c        |> byte)  // B
    for i = 1 to (1 <<< (ctsize + 1)) - ctable.Length do
        bw.Write [|0uy; 0uy; 0uy|]  // RGB (padding)

    // 20. Image Descriptor.
    bw.Write(0x2Cuy)         // Image Separator
    bw.Write(0us)            // Image Left Position
    bw.Write(0us)            // Image Top Position
    bw.Write(uint16 width )  // Image Width
    bw.Write(uint16 height)  // Image Height
    bw.Write(0uy)            // <Packed Fields>
                             //   Local Color Table Flag
                             //   | Interlace Flag
                             //   | | Sort Flag
                             //   | | | Reserved
                             //   | | | |  Size of Local Color Table
                             //   0 0 0 00 000

    // 22. Table Based Image Data.
    encode bw pixels

    // 27. Trailer.
    bw.Write(0x3Buy)  // GIF Trailer
```

### テスト

[GIFのバイナリを読んでみた](http://qiita.com/7shi/items/33117c6c369d37dc6cdd)で使用した画像を生成してみます。

```fsharp
do  use fs = new FileStream("A.gif", FileMode.Create)
    createGIF fs 16 16
        [|  0x000000     // RGB #0
            0x808080     // RGB #1
            0xFFFFFF     // RGB #2
            0xFFFFFF |]  // RGB #3
        (Array.map byte
        [|  2;2;2;2;2;2;2;2;2;2;2;2;2;2;2;2
            2;2;2;2;2;2;2;1;0;2;2;2;2;2;2;2
            2;2;2;2;2;2;2;0;1;1;2;2;2;2;2;2
            2;2;2;2;2;2;0;2;2;0;2;2;2;2;2;2
            2;2;2;2;2;0;2;2;2;1;1;2;2;2;2;2
            2;2;2;2;1;1;2;2;2;2;0;2;2;2;2;2
            2;2;2;2;0;2;2;2;2;2;0;2;2;2;2;2
            2;2;2;0;2;2;2;2;2;2;1;1;2;2;2;2
            2;1;0;0;0;0;0;1;2;2;2;0;2;2;2;2
            2;2;0;2;2;2;2;1;1;1;1;0;1;1;1;1
            2;1;1;2;2;2;2;2;2;2;2;1;1;2;2;2
            2;0;2;2;2;2;2;2;2;2;2;2;0;2;2;2
            2;0;2;2;2;2;2;2;2;2;2;2;0;2;2;2
            1;1;2;2;2;2;2;2;2;2;2;2;1;1;2;2
            2;2;2;2;2;2;2;2;2;2;2;2;2;0;2;2
            2;2;2;2;2;2;2;2;2;2;2;2;2;2;2;2 |])
```

出力結果 ![A.gif](https://qiita-image-store.s3.amazonaws.com/0/32057/2f7db80e-9a12-fef7-753d-27ab3ddf86c0.gif)

うまく生成できました。

## ピクセルデータの取り出し

ここまではピクセルデータをハードコーディングしていましたが、今後はBitmapで処理します。

Bitmapからピクセルデータを配列で取り出す関数を実装します。

```fsharp
let getArgb (bmp:Bitmap) =
    let w, h = bmp.Width, bmp.Height
    let argb = Array.zeroCreate<int>(w * h)
    let bd = bmp.LockBits(Rectangle(0, 0, w, h),
                          ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb)
    Marshal.Copy(bd.Scan0, argb, 0, argb.Length)
    bmp.UnlockBits bd
    argb
```

## カラーパレットの生成

与えられた画像からGIFの生成を実装するには、カラーパレットの生成が必要です。

GIFのカラーパレットは256色に制限されています。

※ 複数の画像を重ねることで256色以上の画像を扱う手法もあり、フルカラーGIFと呼ばれています。詳細は次の記事を参照してください。

* [フルカラー GIF 作成 JavaScript の説明](http://www.kero2.org/fg_ex.cgi) 2016.02.24

今回は簡単のためグレースケールに変換します。RGBからグレースケールに変換する関数を実装します。比率などは次の記事を参照してください。

* [RGB値の合計が一定の画像変換](http://qiita.com/7shi/items/d223e347d67cc399f70c) 2016.11.17

```fsharp
let gray c =
    let r, g, b = c >>> 16 |> byte, c >>> 8 |> byte, c |> byte
    float r * 0.299 + float g * 0.587 + float b * 0.114 |> int
```

グレースケールのカラーパレットを生成します。

```fsharp
let grayTable = [| for i in 0..255 -> 0x010101 * i |]
```

### テスト

標準画像Lennaを読み込んでグレースケールのGIFに変換します。所要時間を計測します。

```fsharp
do  use bmp = new Bitmap("Lenna.png")
    use fs = new FileStream("Lenna-gray.gif", FileMode.Create)
    let start = DateTime.Now
    createGIF fs bmp.Width bmp.Height grayTable (getArgb bmp |> Array.map gray)
    printfn "%A" (DateTime.Now - start)
```
```text:実行結果
00:00:18.8136330
```

元画像|変換後
:--:|:--:
![Lenna.png](https://qiita-image-store.s3.amazonaws.com/0/32057/6d695d1a-a9ce-e695-bc03-75e003fb653b.png)|![Lenna-gray.gif](https://qiita-image-store.s3.amazonaws.com/0/32057/aae22d44-45e1-d45e-e782-cbecd38ee421.gif)

うまく変換できました。しかし圧縮には19秒近く掛かっています（i5-3320M 2.6GHz）。

## テーブル参照の最適化

圧縮があまりにも遅いのはテーブルをリニアサーチしているのが原因です。ハッシュを使用した最適化を試みます。

データの長さを初期値として、全バイトを8bitずつずらしながらXORしてハッシュ値を計算します。

```fsharp
let hash (src:byte[]) start length =
    let mutable ret = length
    for i = 0 to length - 1 do
        ret <- ret ^^^ (int src.[start + i] <<< ((i &&& 3) * 8))
    ret
```

※ 当初は長さと先頭2バイトから算出する単純なハッシュを使用しましたが、衝突が多発しました。全バイトから計算するとコストは掛かりますが、衝突が減るためトータルでは1.5倍程度高速化しました。

ハッシュテーブルを `Dictionary<int, List<int * int * int>>` で扱います。衝突したときはリニアサーチするためリストを使います。リスト内のタプルは (開始位置, 長さ, インデックス) です。

```fsharp
type HashTable = Dictionary<int, List<int * int * int>>
```

ハッシュテーブルへの追加を実装します。

```fsharp
let hashAdd (table:HashTable) src start length i =
    let h = hash src start length
    match table.TryGetValue h with
    | false, _ ->
        let list = List<int * int * int>()
        list.Add(start, length, i)
        table.[h] <- list
    | true, list ->
        list.Add(start, length, i)
```

ハッシュテーブルからの取得を実装します。リニアサーチで必要となる配列の比較も実装します。

```fsharp
let arrayCmp (src:byte[]) s1 length (s2, len2, _) =
    if length <> len2 then false else
    if s1 = s2 then true else
    seq {
        for i = 0 to length - 1 do
            if src.[s1 + i] <> src.[s2 + i] then yield false
        yield true }
    |> Seq.head

let hashGet (table:HashTable) src start length =
    let h = hash src start length
    match table.TryGetValue h with
    | false, _ -> None
    | true, list ->
        match list |> Seq.tryFind (arrayCmp src start length) with
        | Some (_, _, i) -> Some i
        | _ -> None
```

ハッシュテーブルを使うように`encode`を修正します。

```fsharp
let encode (bw:BinaryWriter) (src:byte[]) =
    let lzwMin = max 2 (Array.max src |> int |> bitSize)
    bw.Write(byte lzwMin)  // LZW Minimum Code Size
    use bitw = new BitWriter(bw)
    let clr = 1 <<< lzwMin
    let table = HashTable()
    let mutable blen, next, j, prev = lzwMin + 1, clr * 2, 0, -1
    let mutable cur = clr + 2
    bitw.Write blen clr
    for i = 0 to src.Length - 1 do
        let length = (i + 1) - j
        match hashGet table src j length with
        | Some n ->
            prev <- n
        | _ ->
            if prev >= 0 then
                bitw.Write blen prev
                hashAdd table src j length cur
                cur <- cur + 1
                if cur > 0xfff then
                    bitw.Write blen clr
                    table.Clear()
                    blen <- lzwMin + 1
                    next <- clr * 2
                    prev <- -1
                    cur  <- clr + 2
                elif cur > next then
                    blen <- blen + 1
                    next <- next * 2
            prev <- int src.[i]
            j <- i
    if prev >= 0 then bitw.Write blen prev
    bitw.Write blen (clr + 1)  // End
```

### テスト

先ほどと同じ標準画像Lennaの変換を試します。コードは同じなので結果のみ掲載します。出力されるGIFファイルも同一です。

```text:実行結果
00:00:00.0312001
```

劇的に高速化しました。まだ工夫の余地はありそうですが、実用上はこれで充分でしょう。

### 参考

参考までにGDI+での保存も計測してみます。

```fsharp
do  use bmp = new Bitmap("Lenna.png")
    let start = DateTime.Now
    bmp.Save("Lenna.gif", ImageFormat.Gif)
    printfn "%A" (DateTime.Now - start)
```
```text:実行結果
00:00:00.0156001
```

グレースケールではなく減色を行っているため単純な比較はできませんが、それでも圧倒的に速いです。

機会があれば減色を実装して、また比較してみたいです。
