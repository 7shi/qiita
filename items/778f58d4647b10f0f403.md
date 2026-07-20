---
coediting: false
comments_count: 0
created_at: '2017-01-18T18:23:10+09:00'
id: 778f58d4647b10f0f403
likes_count: 4
private: false
reactions_count: 0
stocks_count: 2
tags:
- name: F#
  versions: []
- name: GIF
  versions: []
title: GIFのLZWを展開してみた
updated_at: '2017-02-04T14:55:09+09:00'
url: https://qiita.com/7shi/items/778f58d4647b10f0f403
slide: false
---

GIFのLZWを展開してみます。トリッキーなことをするため、圧縮よりも展開の方が難しいです。

シリーズの記事です。

1. [GIFのバイナリを読んでみた](http://qiita.com/7shi/items/33117c6c369d37dc6cdd)
1. [GIFのLZW圧縮を調べてみた](http://qiita.com/7shi/items/cfe1c6e42aff78c06652)
1. GIFのLZWを展開してみた ← この記事

# テーブルの構築

展開しながらテーブルを作ります。これがなかなかトリッキーで、[圧縮のログ](http://qiita.com/7shi/items/cfe1c6e42aff78c06652#%E5%8B%95%E4%BD%9C%E7%B5%90%E6%9E%9C)を見ながら考えます。

圧縮での入力値が展開での出力値となるため、ログから入力値を隠して、出力値からテーブルの値を再現する方法を考えます。

```text:ログから抜粋
Table   Output  Desc.
-----   ------  -----
0x104           - add 'ff ff 28' to table
        0x103   - output code for previous string
                '28' initialize local string
                '28 ff' 0x102 found in table
                '28 ff ff' not found in table
0x105           - add '28 ff ff' to table
        0x102   - output code for previous string
```

`0x103: ff ff` と `0x102: 28 ff` が定義済みです。`0x104: ff ff 28` を求めるには `0x103` に `0x102` の最初の1バイトをくっ付けます。

まとめると次のようになります。Dが確定してからAをテーブルに追加するという処理順です。

```text
A       ← A = B + D[0] テーブルに追加
    B

C       ← 無関係
    D
```

次のケースはもう少し複雑です。

```text:ログから抜粋
Table   Output  Desc.
-----   ------  -----
0x106           - add 'ff ff ff' to table
        0x103   - output code for previous string
                'ff' initialize local string
                'ff ff' 0x103 found in table
                'ff ff ff' 0x106 found in table
                'ff ff ff ff' not found in table
0x107           - add 'ff ff ff ff' to table
        0x106   - output code for previous string
```

直前の `0x103` と 後続の `0x106` の最初の1バイトから `0x106` を作ろうとしても、そもそも `0x106` が未定義です。しかし `A = B + D[0]` の関係から `0x106`（A）と `0x103`（B）の前半は一致するため、`0x103` の最初の1バイトで代用できることが分かります。

このことがWikipediaでは結果だけ説明されています。

[GIF - Wikipedia](https://en.wikipedia.org/wiki/GIF)

> Is incoming code found in table?
> YES: add string for local code followed by first byte of string for incoming code
> NO: add string for local code followed by copy of its own first byte

# コード列からの展開

まずビットストリームから取り出されたコード列からの展開を実装します。

試行錯誤の過程を掲載してもあまり参考にはならないと思うので、完成したコードを説明します。

* [LZWExtract.fsx](https://bitbucket.org/snippets/7shi/nBxp8)

前回の出力結果を入力とします。

```fsharp
let src = [| 0x100; 0x28; 0xff; 0x103; 0x102; 0x103; 0x106; 0x107; 0x101 |]
```

コマンド類は clr のみ定義して、その他は計算で求めます。

```fsharp
let clr = 0x100
```

ログを4列で出力します。

1. 入力（圧縮データ）
1. テーブルに追加したタイミングでインデックスを出力、テーブルに追加したデータは説明に出力
1. 展開結果が確定したタイミングでデータを出力
1. 説明

```fsharp
printfn "Input\tTable\tOutput\tDesc."
printfn "-----\t-----\t------\t-----"
```

ログ表示用にバイナリを16進数化する関数を定義します。

```fsharp
let hex (bin:byte seq) =
    bin |> Seq.map (sprintf "%02x") |> String.concat " "
```

展開結果の出力先を定義します。出力するタイミングでログを出力するため、出力用の関数を定義します。

```fsharp
let data = System.Collections.Generic.List<byte>()
let output (vs:byte[]) =
    printfn "\t\t%s" (hex vs)
    data.AddRange vs
```

テーブルを定義します。テーブルに追加するタイミングでログを出力するため、テーブル追加用の関数を定義します。

```fsharp
let table = System.Collections.Generic.List<byte[]>()
let add codes =
    let n = clr + 2 + table.Count
    printfn "\t0x%03x\t\t%s" n (hex codes)
    table.Add codes
```

ループで入力データを読みます。終了コードが来れば抜ける必要がありますが、F#には`break`がないため`for`では書けません。そのため再帰関数で実装します。ループのパラメータ（現在位置と直前に出力したデータ）を引数で受け取り、先頭で終了条件を確認します。

```fsharp
let rec extract i prev =
    if i >= src.Length then () else
```

現在の入力値を読み、ログを出力します。

```fsharp
    let d = src.[i]
    printf "0x%03x" d
```

clr が来ればテーブルを消去して、再帰呼び出しによりループを次に進めます。直前データもクリアします。

```fsharp
    if d = clr then
        printfn "\t\t\tClear"
        table.Clear()
        extract (i + 1) [||]
```

終了コードが来れば抜けます。再帰呼び出しをしないことがループから抜けることを意味します。

```fsharp
    elif d = clr + 1 then
        printfn "\t\t\tEnd"
```

値またはテーブル参照の処理です。出力データを `vs` に束縛します。値であれば配列で包んで（`[|d|]`）、テーブル参照であれば中身を取得します。その際に前述のトリッキーなケース（`A = D`）に該当する条件が `table.Count = n` です。

```fsharp
    else
        let vs =
            if d < clr then [|byte d|] else
                let n = d - clr - 2
                if n < table.Count then table.[n] else
                    Array.append prev [|prev.[0]|]
```

データを出力して、直前のデータがあれば（ないのは初回時のみ）テーブルにデータ（`B + D[0]`）を追加して、ループを次に進めます。`<>`は不等号、`[||]`は空の配列です。

```fsharp
        output vs
        if prev <> [||] then
            add (Array.append prev [|vs.[0]|])
        extract (i + 1) vs
```

再帰関数で定義したループは、初期値を与えて関数を呼び出すことで開始します。入力値の正当性はチェックしていないため、例外ハンドラを書いておきます（エラーを出力するだけですが）。

```fsharp
try extract 0 [||] with e -> printfn "%A" e
```

## 動作結果

入力値が圧縮されていて小さいため、圧縮のときよりもステップ数が少ないです。`0x103`と`0x106`と`0x107`が前方参照されているのがトリッキーな点です。

```text
Input	Table	Output	Desc.
-----	-----	------	-----
0x100			Clear
0x028		28
0x0ff		ff
	0x102		28 ff
0x103		ff ff
	0x103		ff ff
0x102		28 ff
	0x104		ff ff 28
0x103		ff ff
	0x105		28 ff ff
0x106		ff ff ff
	0x106		ff ff ff
0x107		ff ff ff ff
	0x107		ff ff ff ff
0x101			End
```

# ビットストリームからの展開

GIFからデータを展開するにはビットストリームからコード列を取り出す必要があります。

完成したコードを説明します。

* [LZWDecode.fsx](https://bitbucket.org/snippets/7shi/nBkj9)

## 読み込み

バイトストリームから指定したビットずつ読み込むクラスを実装します。

データは255バイトごとのブロックに分割されています。ブロックサイズを先頭バイトから読み込みます。その後のデータはビット単位でのリトルエンディアンのため下位から読み込みます。ブロックの終わりまで到達すれば次のブロックのサイズを取得します。ブロックサイズが0であれば終了します。

※ ビットストリームの中にブロックサイズが割り込む形となります。

```fsharp
open System.IO

type BitReader(s:Stream) =
    let mutable i, max = 0, -1
    let next() =
        if max = 0 then -1 else
        if i >= max then
            i <- 0
            max <- s.ReadByte()
        if max = 0 then -1 else
        i <- i + 1
        s.ReadByte()
    let mutable cur = next()
    let mutable b = 0
    let mutable v = -1
    member x.Value = v
    member x.Read n =
        let rec f v sh n =
            if cur < 0 then -1 else
            let d = cur >>> b
            let left = 8 - b
            if n < left then
                b <- b + n
                v ||| ((d &&& ((1 <<< n) - 1)) <<< sh)
            else
                b <- 0
                cur <- next()
                let v = v ||| (d <<< sh)
                if n = left then v else f v (sh + left) (n - left)
        v <- f 0 0 n
        v >= 0
```

### テスト

Wikipediaに掲載されているサンプルからコード列を取り出してみます。コード長はすべて9bitだと分かっているため決め打ちします。

```fsharp
let src1 = [|
    // block size
    11uy
    // data bytes
    0x00uy; 0x51uy; 0xFCuy; 0x1Buy; 0x28uy; 0x70uy; 0xA0uy; 0xC1uy
    0x83uy; 0x01uy; 0x01uy
    // Block Terminator
    0uy |]

seq {
    use ms = new MemoryStream(src1)
    let br = BitReader(ms)
    while br.Read(9) do yield br.Value }
|> Seq.map (sprintf "%03x")
|> String.concat " "
|> printfn "%s"
```
```text:実行結果
100 028 0ff 103 102 103 106 107 101
```

うまく取り出せています。

## 展開

ビットストリームから展開する際にコード長は可変です。出現する可能性があるコードをすべて格納できるだけのサイズとなるため、最大値は今から追加しようとしているテーブルのインデックスとなります。ただし12ビットの制限があるため、正常なデータであれば制限を超えた所でclrが来てテーブルをクリアします。

先に実装した`extract`をベースに、`BitReader`を使うように手直しした`decode`を実装します。アルゴリズムは変えないため、動作を信用してログ出力は除去します。

```fsharp
let decode (br:BitReader) (data:List<byte>) lzwMin =
    let table = List<byte[]>()
    let clr = 1 <<< lzwMin
    let rec f blen next prev =
        let i = clr + 2 + table.Count
        if i >= next then f (blen + 1) (next <<< 1) prev
        elif not <| br.Read (min 12 blen) then () else
        let d = br.Value
        if d = clr then
            table.Clear()
            f 1 2 [||]
        elif d = clr + 1 then () else
        let vs =
            if d < clr then [|byte d|] else
                let n = d - clr - 2
                if n < table.Count then table.[n] else
                    Array.append prev [|prev.[0]|]
        data.AddRange vs
        if prev <> [||] then
            table.Add(Array.append prev [|vs.[0]|])
        f blen next vs
    f 1 2 [||]
```

### テスト

テスト用に画像のサイズと最短ビット長と圧縮データを渡して展開結果を表示する関数を実装します。

```fsharp
let test w h lzwMin f (src:byte[]) =
    use ms = new MemoryStream(src)
    let data = List<byte>()
    decode (BitReader(ms)) data lzwMin
    printfn "%d * %d = %d (%d)" w h (w * h) data.Count
    let mutable en = data.GetEnumerator()
    for y = 0 to h - 1 do
        for x = 0 to w - 1 do
            if en.MoveNext() then
                printf "%s" (f en.Current)
        printfn ""
```

Wikipediaのデータを展開すると、うまく画像の形が取り出せました。

```fsharp
test 3 5 8 (sprintf "%02x ") src1
```
```text:実行結果
3 * 5 = 15 (15)
28 ff ff 
ff 28 ff 
ff ff ff 
ff ff ff 
ff ff ff 
```

[GIFのバイナリを読んでみた](http://qiita.com/7shi/items/33117c6c369d37dc6cdd)で使用した画像の圧縮データを読み込んでみます。

```fsharp
test 16 16 2 (fun b -> string "#* ?".[int b]) [|
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
16 * 16 = 256 (256)
                
       *#       
       #**      
      #  #      
     #   **     
    **    #     
    #     #     
   #      **    
 *#####*   #    
  #    ****#****
 **        **   
 #          #   
 #          #   
**          **  
             #  
                
```

元画像 ![gif1.gif](https://qiita-image-store.s3.amazonaws.com/0/32057/d6692680-9082-986f-a486-a8e4c2156ce0.gif)

きちんと形が取り出せていることが分かります。

# GIFファイルからの展開

ヘッダやカラーパレットを読み込めばGIFファイルから画像が得られます。

完成したコードを説明します。

* [GIFDecode.fsx](https://bitbucket.org/snippets/7shi/M7Eer)

## ヘッダ

BinaryReader を使用します。

```fsharp
let decodeGIF (s:Stream) =
    use br = new BinaryReader(s, Encoding.ASCII)
```

シグネチャとバージョンを確認します。

```fsharp:データ
    // 17. Header.
    'G'B; 'I'B; 'F'B  // Signature
    '8'B; '7'B; 'a'B  // Version
```
```fsharp:読み込み
    match String(br.ReadChars 6) with
    | "GIF87a" | "GIF89a" -> ()
    | _ -> failwith "not gif file"
```

サイズを読み込みます。

```fsharp:データ
    // 18. Logical Screen Descriptor.
    16uy; 0uy  // Logical Screen Width
    16uy; 0uy  // Logical Screen Height
```
```fsharp:読み込み
    let width  = br.ReadUInt16() |> int
    let height = br.ReadUInt16() |> int
```

フラグを読み込みます。

```fsharp:データ
    0xA1uy     // <Packed Fields>
               //   Global Color Table Flag
               //   | Color Resolution
               //   | |   Sort Flag
               //   | |   | Size of Global Color Table
               //   1 010 0 001
```
```fsharp:読み込み
    let b = br.ReadByte() |> int
    let hasGCT  = (b &&& 0x80) <> 0
    let colRes  = (b >>> 4) &&& 7
    let sorted  = (b &&& 8) <> 0
    let sizeGCT =  b &&& 7
```

この要領でカラーパレットなども読み込んで、展開したインデックスデータをRGB値に変換すれば、画像が得られます。

## 実行結果

標準画像Lennaを256色に減色したGIFを用意します。

![Lenna.gif](https://qiita-image-store.s3.amazonaws.com/0/32057/7e5af99b-232d-196a-feae-aa3259abadbb.gif)

この記事で作ったデコーダーで読み込んで表示します。

```fsharp
[<EntryPoint; STAThread>] do
let f = new Form(Text = "GIF")
let p = new PictureBox(Dock = DockStyle.Fill,
                       SizeMode = PictureBoxSizeMode.CenterImage)
f.Controls.Add p
f.Load.Add <| fun _ ->
    use fs = new FileStream("Lenna.gif", FileMode.Open)
    let bmp = decodeGIF fs
    f.ClientSize <- bmp.Size
    p.Image <- bmp
Application.EnableVisualStyles()
Application.Run f
```

![Lenna.png](https://qiita-image-store.s3.amazonaws.com/0/32057/a5f29307-c95e-fd83-afee-ef4be7cab0cd.png)

うまく表示できました。

アニメーションに対応するにはまだ作業が必要ですが、今回は実装を見送ります。
