---
coediting: false
comments_count: 0
created_at: '2016-11-17T17:58:42+09:00'
id: 755c537f1a308d07484b
likes_count: 2
private: false
reactions_count: 0
stocks_count: 0
tags:
- name: F#
  versions: []
title: グレースケールで消える画像に変換
updated_at: '2016-11-18T10:47:08+09:00'
url: https://qiita.com/7shi/items/755c537f1a308d07484b
slide: false
---

グレースケールの変換式を逆算して変換した時に同じ値になるように調整すれば、どんな色合いになるのか確認してみます。

この記事は次の続編です。

* [RGB値の合計が一定の画像変換](http://qiita.com/7shi/items/d223e347d67cc399f70c) 2016.11.17

# 変換

グレースケールへの変換を行う関数です。

```fsharp
let grayF (r, g, b) =
    r * 0.299 + g * 0.587 + b * 0.114
```

`Color`から`float`のタプルに変換する関数です。

```fsharp
let toFloat (c:Color) =
    float c.R, float c.G, float c.B
```

グレースケールに変換したとき`1.0`になるような比例定数を求めて色を調整する関数です。

```fsharp
let adjust2 (c:Color) =
    let r, g, b = toFloat c
    let c = grayF (r, g, b)
    r / c, g / c, b / c
```

画像全体に対して`adjust2`を適用してRGB値の配列を生成する関数です。

```fsharp
let adjust2rgb (bmp:Bitmap) =
 [| for y = 0 to bmp.Height - 1 do
    for x = 0 to bmp.Width  - 1 do
    yield bmp.GetPixel(x, y) |> adjust2 |]
```

RGBの最大値を指定した値（`v`）に揃えた画像を生成する関数です。

```fsharp
let conv2 v (bmp:Bitmap) =
    let bmp = new Bitmap(bmp)
    let rgb = adjust2rgb bmp
    let conv =
        let max =
            rgb
            |> Seq.map (fun (r, g, b) -> r |> max g |> max b)
            |> Seq.max
        if max = 0. then
            let c = Color.FromArgb(v, v, v)
            fun _ -> c
        else
            let a = float v / max
            fun (r, g, b) ->
                Color.FromArgb(a * r |> int, a * g |> int, a * b |> int)
    let en = (rgb :> IEnumerable<float * float * float>).GetEnumerator()
    for y = 0 to bmp.Height - 1 do
        for x = 0 to bmp.Width - 1 do
            if en.MoveNext() then
                bmp.SetPixel(x, y, conv en.Current)
    bmp
```

次のように使います。

```fsharp
let bmp = new Bitmap("Lenna.bmp")
let adj2 = bmp |> conv2 255
adj2.Save("Lenna-adj2.png", Imaging.ImageFormat.Png)
```

結果は以下の通りです。

元画像|変換後
:--:|:--:
![Lenna.png](https://qiita-image-store.s3.amazonaws.com/0/32057/be5a592f-d179-4e4e-ea50-165a21078463.png)|![Lenna-adj2.png](https://qiita-image-store.s3.amazonaws.com/0/32057/c97f9661-73cd-d2e2-6b7f-c4194307d6d2.png)

かなり不自然な色合いになってしまいました。

RGB値の平均と、輝度ベース（`grayF`）とで、グレースケールに変換してみます。

平均|輝度ベース
:--:|:--:
![Lenna-adj2-avg.png](https://qiita-image-store.s3.amazonaws.com/0/32057/6dc62339-69a5-0ad7-37e3-4e10659ae9c6.png)|![Lenna-adj2-gray.png](https://qiita-image-store.s3.amazonaws.com/0/32057/978fb4d1-3a44-1f40-60db-8a1938b85275.png)

輝度ベースで画像が消えてしまうことが確認できました。

※ 消えるのは`grayF`の変換式に依存しています。別の変換式（平均など）を使用すれば消えません。

# まとめ

コードをまとめて整理したものを掲載します。

```fsharp:RGB2.fsx
#r "System.Drawing"

open System.Collections.Generic
open System.Drawing
open System.IO

let suffix fn sfx =
    let dir = Path.GetDirectoryName fn
    let fn2 = Path.GetFileNameWithoutExtension fn
    Path.Combine(dir, fn2 + sfx)

let average (c:Color) =
    let c = (int c.R + int c.G + int c.B) / 3
    Color.FromArgb(c, c, c)

let toFloat (c:Color) =
    float c.R, float c.G, float c.B

let grayF (r, g, b) =
    r * 0.299 + g * 0.587 + b * 0.114

let gray (c:Color) =
    let c = c |> toFloat |> grayF |> int
    Color.FromArgb(c, c, c)

let conv f (bmp:Bitmap) =
    let bmp = new Bitmap(bmp)
    for y = 0 to bmp.Height - 1 do
        for x = 0 to bmp.Width - 1 do
            bmp.SetPixel(x, y, f (bmp.GetPixel(x, y)))
    bmp

let adjust2 (c:Color) =
    let r, g, b = toFloat c
    let c = grayF (r, g, b)
    r / c, g / c, b / c

let adjust2rgb (bmp:Bitmap) =
 [| for y = 0 to bmp.Height - 1 do
    for x = 0 to bmp.Width  - 1 do
    yield bmp.GetPixel(x, y) |> adjust2 |]

let conv2 v (bmp:Bitmap) =
    let bmp = new Bitmap(bmp)
    let rgb = adjust2rgb bmp
    let conv =
        let max =
            rgb
            |> Seq.map (fun (r, g, b) -> r |> max g |> max b)
            |> Seq.max
        if max = 0. then
            let c = Color.FromArgb(v, v, v)
            fun _ -> c
        else
            let a = float v / max
            fun (r, g, b) ->
                Color.FromArgb(a * r |> int, a * g |> int, a * b |> int)
    let en = (rgb :> IEnumerable<float * float * float>).GetEnumerator()
    for y = 0 to bmp.Height - 1 do
        for x = 0 to bmp.Width - 1 do
            if en.MoveNext() then
                bmp.SetPixel(x, y, conv en.Current)
    bmp

let save fn (bmp:Bitmap) =
    bmp.Save(fn + ".png", Imaging.ImageFormat.Png)
    bmp.Dispose()

let src = "Lenna.bmp"

let bmp = new Bitmap(src)
let adj2 = bmp |> conv2 255
adj2 |> conv average |> save (suffix src "-adj2-avg" )
adj2 |> conv gray    |> save (suffix src "-adj2-gray")
adj2                 |> save (suffix src "-adj2")
```
