---
coediting: false
comments_count: 0
created_at: '2014-08-26T07:27:57+09:00'
id: 29d10e74c8df30df04af
likes_count: 2
private: false
reactions_count: 0
stocks_count: 3
tags:
- name: F#
  versions: []
title: F#のシーケンスでコルーチン
updated_at: '2019-02-10T21:50:38+09:00'
url: https://qiita.com/7shi/items/29d10e74c8df30df04af
slide: false
---

ドラッグ＆ドロップをイベントドリブンで書くと処理が分断されます。コルーチンを使うことでシーケンシャルに書くテクニックがあります。今回はシーケンスで実装してみます。

この記事には続編があります。

* [F#のシーケンスでコルーチン(2)](http://qiita.com/7shi/items/78fa1d02730c7cd11786)

この記事をベースにJavaScript版を作成しました。

* [ECMAScript 6のyieldでコルーチン](http://qiita.com/7shi/items/622c322bd482b340038c)
* [ECMAScript 6のyieldでコルーチン(2)](http://qiita.com/7shi/items/e9d65db80bfaa6adaa16)

# コルーチンを使わない書き方

コルーチンを使わずにイベントドリブンで書いてみます。

```fsharp:DnDCoroutine.fsx
#r "System"
#r "System.Drawing"
#r "System.Windows.Forms"

open System
open System.Drawing
open System.Windows.Forms

let mutable r = Rectangle(10, 10, 40, 40)
let mutable startX, startY, startR, dragging = 0, 0, r, false

[<EntryPoint; STAThread>] do
let f = new Form(Text = "DnD Coroutine")

f.Paint.Add <| fun e ->
    e.Graphics.FillRectangle(Brushes.Red, r)

f.MouseDown.Add <| fun e ->
    if r.Contains(e.X, e.Y) then
        startX <- e.X
        startY <- e.Y
        startR <- r
        dragging <- true

f.MouseMove.Add <| fun e ->
    if dragging then
        r.X <- startR.X + e.X - startX
        r.Y <- startR.Y + e.Y - startY
        f.Invalidate()

f.MouseUp.Add <| fun e ->
    dragging <- false

Application.Run f
```

状態を変数に入れてMouseDown, MouseMove, MouseUpを別々に処理します。

# コルーチンをサポートするクラス

イベントが発生するたびにシーケンスを読み取ることで処理を継続することができます。このように中断されることを前提とした関数のようなものをコルーチンと呼びます。

ドラッグ＆ドロップに特化したサポートクラスを作ります。

```fsharp
type DnDCoroutine(target:Control) =
    let mutable x, y, isDragging = 0, 0, false
    let mutable en = Unchecked.defaultof<Collections.Generic.IEnumerator<unit>>
    let mutable coroutine = Seq.empty<unit>
    do
        target.MouseDown.Add <| fun e ->
            x <- e.X
            y <- e.Y
            en <- coroutine.GetEnumerator()
            isDragging <- en.MoveNext()
        target.MouseMove.Add <| fun e ->
            x <- e.X
            y <- e.Y
            if isDragging then
                isDragging <- en.MoveNext()
        target.MouseUp.Add <| fun e ->
            x <- e.X
            y <- e.Y
            if isDragging then
                isDragging <- false
                en.MoveNext() |> ignore
    member this.Coroutine with set(c) = coroutine <- c
    member this.X = x
    member this.Y = y
    member this.IsDragging = isDragging
```

これを使って書き直すと次のようになります。

```fsharp
let mutable r = Rectangle(10, 10, 40, 40)

[<EntryPoint; STAThread>] do
let f = new Form(Text = "DnD Coroutine")

f.Paint.Add <| fun e ->
    e.Graphics.FillRectangle(Brushes.Red, r)

let dndc = DnDCoroutine(f)
dndc.Coroutine <- seq {
    if r.Contains(dndc.X, dndc.Y) then
        let startX, startY, startR = dndc.X, dndc.Y, r
        yield ()
        while dndc.IsDragging do
            r.X <- startR.X + dndc.X - startX
            r.Y <- startR.Y + dndc.Y - startY
            f.Invalidate()
            yield ()
}

Application.Run f
```

マウスを押し下げてから離すまでの処理が一連の流れで書けるようになりました。

`yield ()`の役割は`Application.DoEvents()`とほぼ同じですが、後者のように副流（サブのイベントループ）を作らない点が異なります。その代償としてコルーチンは自身のシーケンスの打ち切りを自身で管理できません（【追記】`yield`したまま戻って来ない可能性があるという意味です）。つまり受動的な存在です。
