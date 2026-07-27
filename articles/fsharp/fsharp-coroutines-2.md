---
coediting: false
comments_count: 0
created_at: '2014-09-03T07:43:06+09:00'
id: 78fa1d02730c7cd11786
likes_count: 2
private: false
reactions_count: 0
stocks_count: 2
tags:
- name: F#
  versions: []
title: F#のシーケンスでコルーチン(2)
updated_at: '2019-02-10T21:51:20+09:00'
url: https://qiita.com/7shi/items/78fa1d02730c7cd11786
slide: false
---

ドラッグ＆ドロップをイベントドリブンで書くと処理が分断されます。コルーチンを使うことでシーケンシャルに書くテクニックがあります。今回はシーケンスで実装してみます。

この記事は以下の続編です。

* [F#のシーケンスでコルーチン](http://qiita.com/7shi/items/29d10e74c8df30df04af)

今回は表示されている四角形をリサイズできるように拡張します。

この記事の実装をベースに複数画像を同じ範囲で切り抜くツールを作成しました。実際のアプリケーションに応用する際の参考として紹介します。

* https://gist.github.com/7shi/62f5945a9fb3cb2e1d06

この記事をベースにJavaScript版を作成しました。

* [ECMAScript 6のyieldでコルーチン](http://qiita.com/7shi/items/622c322bd482b340038c)
* [ECMAScript 6のyieldでコルーチン(2)](http://qiita.com/7shi/items/e9d65db80bfaa6adaa16)

# コルーチンを使わない書き方

コルーチンを使わずにイベントドリブンで書いてみます。

```fsharp:DnDCoroutine2.fsx
#r "System"
#r "System.Drawing"
#r "System.Windows.Forms"

open System
open System.Drawing
open System.Windows.Forms

type Pos = Out | Low | In | High
let thres = 3
let getpos v l h =
    if   abs(l - v) < thres then Low
    elif abs(h - v) < thres then High
    elif l < v && v < h     then In
    else                         Out

let mutable r = Rectangle(10, 10, 40, 40)
let mutable startX, startY, startR, dragging = 0, 0, r, false
let mutable horz, vert = Out, Out

[<EntryPoint; STAThread>] do
let f = new Form(Text = "DnD Coroutine 2")

f.Paint.Add <| fun e ->
    e.Graphics.FillRectangle(Brushes.Red, r)

f.MouseDown.Add <| fun e ->
    if horz <> Out && vert <> Out then
        startX <- e.X
        startY <- e.Y
        startR <- r
        dragging <- true

f.MouseMove.Add <| fun e ->
    if not dragging then
        horz <- getpos e.X r.Left r.Right
        vert <- getpos e.Y r.Top  r.Bottom
        let cur = match horz, vert with
                  | Low, Low  | High, High -> Cursors.SizeNWSE
                  | Low, High | High, Low  -> Cursors.SizeNESW
                  | Low, In   | High, In   -> Cursors.SizeWE
                  | In , Low  | In  , High -> Cursors.SizeNS
                  | In , In                -> Cursors.SizeAll
                  | _                      -> Cursors.Default
        if f.Cursor <> cur then f.Cursor <- cur
    else
        let inside = horz = In && vert = In
        let dx = e.X - startX
        let dy = e.Y - startY
        let x = if horz = Low || inside then startR.X + dx else startR.X
        let y = if vert = Low || inside then startR.Y + dy else startR.Y
        let w = if   horz = Low  then startR.Width  - dx
                elif horz = High then startR.Width  + dx else startR.Width
        let h = if   vert = Low  then startR.Height - dy
                elif vert = High then startR.Height + dy else startR.Height
        let x, w = if w > 0 then x, w else x + w, max 1 -w
        let y, h = if h > 0 then y, h else y + h, max 1 -h
        r <- Rectangle(x, y, w, h)
        f.Invalidate()

f.MouseUp.Add <| fun e ->
    dragging <- false

Application.Run f
```

状態を変数に入れてMouseDown, MouseMove, MouseUpを別々に処理します。

リサイズ中にサイズがマイナスになった場合、位置を調整してサイズがプラスになるように細工しています。

# コルーチンをサポートするクラス

イベントが発生するたびにシーケンスを読み取ることで処理を継続することができます。このように中断されることを前提とした関数のようなものをコルーチンと呼びます。

ドラッグ＆ドロップに特化したサポートクラスを作ります。ボタンを押す前と押した後のMouseMoveを別枠で扱えるようにしています。

```fsharp
type DnDCoroutine(target:Control) =
    let mutable x, y, isDragging = 0, 0, false
    let mutable en = Unchecked.defaultof<Collections.Generic.IEnumerator<unit>>
    let mutable coroutine = Seq.empty<unit>
    let next (e:MouseEventArgs) =
        x <- e.X
        y <- e.Y
        if en <> null && not <| en.MoveNext() then
            en <- null
    do
        target.MouseDown.Add <| fun e ->
            isDragging <- true
            next e
        target.MouseMove.Add <| fun e ->
            if not isDragging && en = null then
                en <- coroutine.GetEnumerator()
            next e
        target.MouseUp.Add <| fun e ->
            isDragging <- false
            next e
    member this.Coroutine with set(c) = coroutine <- c
    member this.X = x
    member this.Y = y
    member this.IsDragging = isDragging
```

これを使って書き直すと次のようになります。

```fsharp
type Pos = Out | Low | In | High
let thres = 3
let getpos v l h =
    if   abs(l - v) < thres then Low
    elif abs(h - v) < thres then High
    elif l < v && v < h     then In
    else                         Out

let mutable r = Rectangle(10, 10, 40, 40)

[<EntryPoint; STAThread>] do
let f = new Form(Text = "DnD Coroutine 2")

f.Paint.Add <| fun e ->
    e.Graphics.FillRectangle(Brushes.Red, r)

let dndc = DnDCoroutine(f)
dndc.Coroutine <- seq {
    let horz, vert = ref Out, ref Out
    while not dndc.IsDragging do
        horz := getpos dndc.X r.Left r.Right
        vert := getpos dndc.Y r.Top  r.Bottom
        let cur = match !horz, !vert with
                  | Low, Low  | High, High -> Cursors.SizeNWSE
                  | Low, High | High, Low  -> Cursors.SizeNESW
                  | Low, In   | High, In   -> Cursors.SizeWE
                  | In , Low  | In  , High -> Cursors.SizeNS
                  | In , In                -> Cursors.SizeAll
                  | _                      -> Cursors.Default
        if f.Cursor <> cur then f.Cursor <- cur
        yield ()
    if !horz = Out || !vert = Out then () else
    let inside = !horz = In && !vert = In
    let startX, startY, startR = dndc.X, dndc.Y, r
    while dndc.IsDragging do
        let dx = dndc.X - startX
        let dy = dndc.Y - startY
        let x = if !horz = Low || inside then startR.X + dx else startR.X
        let y = if !vert = Low || inside then startR.Y + dy else startR.Y
        let w = if   !horz = Low  then startR.Width  - dx
                elif !horz = High then startR.Width  + dx else startR.Width
        let h = if   !vert = Low  then startR.Height - dy
                elif !vert = High then startR.Height + dy else startR.Height
        let x, w = if w > 0 then x, w else x + w, max 1 -w
        let y, h = if h > 0 then y, h else y + h, max 1 -h
        r <- Rectangle(x, y, w, h)
        f.Invalidate()
        yield ()
}

Application.Run f
```

`yield ()`の役割は`Application.DoEvents()`とほぼ同じですが、後者のように副流（サブのイベントループ）を作らない点が異なります。ただし`yield`したまま戻って来ない可能性があります。つまり受動的な存在です。

以下の3つの状態が一連の流れで書けるようになりました。

1. ボタンが押されていない状態。マウスの位置に応じてカーソルの形を変える。
2. ボタンが押された瞬間。ドラッグ開始の初期設定をする。
3. ボタンを押されている状態。リサイズや移動を行う。

一応作ってはみたものの、1と2,3を分離した方が良いような気もします。値を書き替えるために参照を使っているのも微妙です。まだ工夫の余地があります。
