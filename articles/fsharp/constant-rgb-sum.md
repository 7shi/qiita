---
coediting: false
comments_count: 0
created_at: '2016-11-17T15:07:41+09:00'
id: d223e347d67cc399f70c
likes_count: 3
private: false
reactions_count: 0
stocks_count: 0
tags:
- name: F#
  versions: []
title: RGB値の合計が一定の画像変換
updated_at: '2017-03-31T19:29:33+09:00'
url: https://qiita.com/7shi/items/d223e347d67cc399f70c
slide: false
---

明度と輝度に関する記事を見て、RGB値の合計が一定になるような画像変換を確認したくなったので、実験してみました。

参考にした記事です。

* [画像のモノクロ化は輝度で変換しないとヒドイことになる - 知らなきゃ絶対損するPCマル秘ワザ](http://daredemopc.blog51.fc2.com/blog-entry-877.html) 2013.05.10

この記事には続編があります。

* [グレースケールで消える画像に変換](http://qiita.com/7shi/items/755c537f1a308d07484b) 2016.11.17

この記事には関連記事があります。

* [関数で考えるコベクトル](http://qiita.com/7shi/items/1275d2a15a25a75125d2) 2017.03.31

# 色の変換

RGBの合計が常に一定になるように変換する関数を定義します。

```fsharp
let adjust v (c:Color) =
    let r, g, b = int c.R, int c.G, int c.B
    let sum = r + g + b
    let r2, g2, b2 =
        if sum = 0 then
            v / 3, v / 3, v / 3
        else
            r * v / sum, g * v / sum, b * v / sum
    Color.FromArgb(r2, g2, b2 + (v - (r2 + g2 + b2)))
```

※ 誤差を青成分に押し付けています。

これを受け取って全ピクセルに適用する関数を定義します。

```fsharp
let conv f (bmp:Bitmap) =
    let bmp = new Bitmap(bmp)
    for y = 0 to bmp.Height - 1 do
        for x = 0 to bmp.Width - 1 do
            bmp.SetPixel(x, y, f (bmp.GetPixel(x, y)))
    bmp
```

次のように使います。

```fsharp
let bmp = new Bitmap("Lenna.bmp")
let adj = bmp |> conv (adjust 255)
adj.Save("Lenna-adj.png", Imaging.ImageFormat.Png)
```

※ BMPファイルはQiitaに貼れませんが、可逆圧縮するためJPEGではなくPNGにしています。

結果は以下の通りです。

元画像|変換後
:--:|:--:
![Lenna.png](https://qiita-image-store.s3.amazonaws.com/0/32057/6d695d1a-a9ce-e695-bc03-75e003fb653b.png)|![Lenna-adj.png](https://qiita-image-store.s3.amazonaws.com/0/32057/57e7956a-2a36-ddf1-61f8-ec9458d19784.png)

かなり見づらいですが、痕跡は残っています。

# グレースケール

単純に平均を取る方法でのグレースケール変換を実装します。

```fsharp
let average (c:Color) =
    let c = (int c.R + int c.G + int c.B) / 3
    Color.FromArgb(c, c, c)
```

比較対象として、輝度を考慮した変換も実装します。

```fsharp
let gray (c:Color) =
    let c = float c.R * 0.299 + float c.G * 0.587 + float c.B * 0.114 |> int
    Color.FromArgb(c, c, c)
```

これらを使って先ほど生成した画像を処理します。

```fsharp
(adj |> conv average).Save("Lenna-adj-avg.png" , Imaging.ImageFormat.Png)
(adj |> conv gray   ).Save("Lenna-adj-gray.png", Imaging.ImageFormat.Png)
```

平均|輝度ベース
:--:|:--:
![Lenna-adj-avg.png](https://qiita-image-store.s3.amazonaws.com/0/32057/3fc6e65c-cc00-29d8-628d-400f90b885e8.png)|![Lenna-adj-gray.png](https://qiita-image-store.s3.amazonaws.com/0/32057/4b273565-9e67-5232-c8ba-ccd1dff4ac1c.png)

平均を取ると画像が消えてしまうことが確認できました。

比較として元画像にも適用してみます。

```fsharp
(bmp |> conv average).Save("Lenna-avg.png" , Imaging.ImageFormat.Png)
(bmp |> conv gray   ).Save("Lenna-gray.png", Imaging.ImageFormat.Png)
```

平均|輝度ベース
:--:|:--:
![Lenna-avg.png](https://qiita-image-store.s3.amazonaws.com/0/32057/c3d28ba0-88f3-ca72-a7f3-8be91301fa0a.png)|![Lenna-gray.png](https://qiita-image-store.s3.amazonaws.com/0/32057/1d66e8c2-e804-cbb3-1ef6-aa995fa9f43c.png)

平均でもそれほど悪くないように見えますが、輝度ベースに比べてのっぺりした印象です。

# まとめ

コードをまとめて整理したものを掲載します。

```fsharp:RGB.fsx
#r "System.Drawing"

open System.Drawing
open System.IO

let suffix fn sfx =
    let dir = Path.GetDirectoryName fn
    let fn2 = Path.GetFileNameWithoutExtension fn
    Path.Combine(dir, fn2 + sfx)

let adjust v (c:Color) =
    let r, g, b = int c.R, int c.G, int c.B
    let sum = r + g + b
    let r2, g2, b2 =
        if sum = 0 then
            v / 3, v / 3, v / 3
        else
            r * v / sum, g * v / sum, b * v / sum
    Color.FromArgb(r2, g2, b2 + (v - (r2 + g2 + b2)))

let average (c:Color) =
    let c = (int c.R + int c.G + int c.B) / 3
    Color.FromArgb(c, c, c)

let gray (c:Color) =
    let c = float c.R * 0.299 + float c.G * 0.587 + float c.B * 0.114 |> int
    Color.FromArgb(c, c, c)

let conv f (bmp:Bitmap) =
    let bmp = new Bitmap(bmp)
    for y = 0 to bmp.Height - 1 do
        for x = 0 to bmp.Width - 1 do
            bmp.SetPixel(x, y, f (bmp.GetPixel(x, y)))
    bmp

let save fn (bmp:Bitmap) =
    bmp.Save(fn + ".png", Imaging.ImageFormat.Png)
    bmp.Dispose()

let src = "Lenna.bmp"

let bmp = new Bitmap(src)
bmp |> conv average |> save (suffix src "-avg" )
bmp |> conv gray    |> save (suffix src "-gray")

let adj = bmp |> conv (adjust 255)
adj |> conv average |> save (suffix src "-adj-avg" )
adj |> conv gray    |> save (suffix src "-adj-gray")

bmp |> save (suffix src ""    )
adj |> save (suffix src "-adj")
```
