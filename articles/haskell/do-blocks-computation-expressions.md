---
coediting: false
comments_count: 0
created_at: '2016-07-01T01:37:55+09:00'
id: 92139286a4e9b5620d69
likes_count: 22
private: false
reactions_count: 0
stocks_count: 20
tags:
- name: Haskell
  versions: []
- name: F#
  versions: []
title: doブロックとコンピュテーション式
updated_at: '2016-07-04T01:10:55+09:00'
url: https://qiita.com/7shi/items/92139286a4e9b5620d69
slide: false
---

Haskellでdoブロックを勉強したら、何となくコンピュテーション式の作り方が見えて来ました。現段階の理解を書いてみます。

※ 必ずしもHaskellを経由しないと理解できないわけではありません。個人的な経験として、コンピュテーション式は自由度が高過ぎて、うまく取っ掛かりがつかめなかったのだと思います。

この記事には続編があります。

* [コンピュテーション式でモナドを作ってみる](http://qiita.com/7shi/items/026c7daa5b0b24d02c0f) 2016.07.03

# Haskell

`do`ブロックにおける `変数 <- アクション` が基本的な構文です。アクションから値を取り出して変数に束縛することを表現しています。

## doブロック

関数モナドの例を示します。

```hs:Haskell
test = do
    a <- (+ 1)
    b <- (* 2)
    return (a, b)

main = do
    print (test 3)
    print (test 5)
```
```text:実行結果
(4,6)
(6,10)
```

`<-`を「取り出して束縛」と解釈すれば、割と直観的なコードに見えます。何を取り出しているかと言うと、この場合は`test`に引数として渡した値を適用した結果です。

* `(+ 1) 3` → `3 + 1 = 4`
* `(* 2) 3` → `3 * 2 = 6`
* `(+ 1) 5` → `5 + 1 = 6`
* `(* 2) 5` → `5 * 2 = 10`

## doを剥がす

`do`ブロックは糖衣構文で、剥がすと`>>=`で連結された式が出て来ます。

```hs:Haskell
test =
    (+ 1) >>= \a ->
    (* 2) >>= \b ->
    return (a, b)

main =
    print (test 3) >>= \_ ->
    print (test 5)
```
```text:実行結果
(4,6)
(6,10)
```

`a`と`(+ 1)`の位置が逆になっているのに注目してください。（後でまとめて比較します）

## 関数で書く

`test`はただの関数なので普通の書き方に直してみます。

※ `main`は追求しても仕方ないので`do`に戻します。

```hs:Haskell
test x =
    let a = (+ 1) x in
    let b = (* 2) x in
    (a, b)

main = do
    print (test 3)
    print (test 5)
```
```text:実行結果
(4,6)
(6,10)
```

このコードと比較すれば、`do`ブロックはポイントフリースタイルのようになって引数が省略されていると見なせます。（後でまとめて比較します）

# F♯

【注】F#ではアクションという呼び方はしませんが、ここでは便宜上Haskellに合わせています。

コンピュテーション式における `let! 変数 = アクション` が基本的な構文です。アクションから値を取り出して変数に束縛することを表現しています。

ビルダーを自前で定義するのは大変なので、Haskellを逆にたどります。

## 関数で書く

セクションがないので普通の中置記法で書きます。

```fsharp:F#
let test x =
    let a = x + 1
    let b = x * 2
    (a, b)

do
    printfn "%A" (test 3)
    printfn "%A" (test 5)
```
```text:実行結果
(4, 6)
(6, 10)
```

## ラムダ式で書く

引数を関数に適用していることを明示するため、セクションの代用としてラムダ式で書きます。

```fsharp:F#
let test x =
    let a = (fun x -> x + 1) x
    let b = (fun x -> x * 2) x
    (a, b)

do
    printfn "%A" (test 3)
    printfn "%A" (test 5)
```
```text:実行結果
(4, 6)
(6, 10)
```

強烈に無駄なことをしているように見えますが、次につながります。

## 自前定義

`>>=`と`ret`を自前定義してHaskellに似せます。

```fsharp:F#
let (>>=) m f = fun x -> f (m x) x
let ret   x   = fun _ -> x

let test =
    (fun x -> x + 1) >>= fun a ->
    (fun x -> x * 2) >>= fun b ->
    ret (a, b)

do
    printfn "%A" (test 3)
    printfn "%A" (test 5)
```
```text:実行結果
(4, 6)
(6, 10)
```

先ほどの例と比較して`a`と`(fun x -> x + 1)`の位置が逆転していることに注目してください。

## bind

`>>=`を`bind`という関数にして前置で呼びます。

```fsharp:F#
let bind m f = fun x -> f (m x) x
let ret  x   = fun _ -> x

let test =
    bind (fun x -> x + 1) (fun a ->
    bind (fun x -> x * 2) (fun b ->
    ret (a, b)))

do
    printfn "%A" (test 3)
    printfn "%A" (test 5)
```
```text:実行結果
(4, 6)
(6, 10)
```

## ビルダー

ビルダーを定義して直接使用します。

```fsharp:F#
type FuncBuilder() =
    member __.Bind(m, f) = fun x -> f (m x) x
    member __.Return(x)  = fun _ -> x
let func = FuncBuilder()

let test =
    func.Bind((fun x -> x + 1), fun a ->
    func.Bind((fun x -> x * 2), fun b ->
    func.Return(a, b)))

do
    printfn "%A" (test 3)
    printfn "%A" (test 5)
```
```text:実行結果
(4, 6)
(6, 10)
```

## コンピュテーション式

コンピュテーション式で使います。

```fsharp:F#
type FuncBuilder() =
    member __.Bind(m, f) = fun x -> f (m x) x
    member __.Return(x)  = fun _ -> x
let func = FuncBuilder()

let test = func {
    let! a = fun x -> x + 1
    let! b = fun x -> x * 2
    return (a, b) }

do
    printfn "%A" (test 3)
    printfn "%A" (test 5)
```
```text:実行結果
(4, 6)
(6, 10)
```

`a`と`fun x -> x + 1`の位置が逆転していることに注目してください。

# まとめ

HaskellとF#で、各種構文を比較します。

<table><tr><th></th><th>Haskell</th><th>F#</th></tr><tr><td>1.通常関数</td><td><pre>
test x =
    let a = (+ 1) x in
    let b = (* 2) x in
    (a, b)
</pre></td><td><pre>
let test x =
    let a = (fun x -> x + 1) x
    let b = (fun x -> x * 2) x
    (a, b)
</pre></td></tr><tr><td>2.糖衣構文</td><td><pre>
test = do
    a &lt;- (+ 1)
    b &lt;- (* 2)
    return (a, b)
</pre></td><td><pre>
let test = func {
    let! a = fun x -> x + 1
    let! b = fun x -> x * 2
    return (a, b) }
</pre></td></tr><tr><td>3.脱糖衣</td><td><pre>
test =
    (+ 1) >>= \a ->
    (* 2) >>= \b ->
    return (a, b)
</pre></td><td><pre>
let test =
    func.Bind((fun x -> x + 1), fun a ->
    func.Bind((fun x -> x * 2), fun b ->
    func.Return(a, b)))
</pre></td></tr></table>

特徴を押さえておくと、構文変換がイメージしやすくなると思われます。

* 1と2は構文的に似ている（特にF#）。2は引数を明示していない（ポイントフリースタイル）。
* 2と3は左辺 `a` と右辺 `(+ 1)` が逆になっている。3は変数束縛が引数によって実現されている。
* Haskellの方が構文がシンプル。F#の方が多機能。

`do`よりもコンピュテーション式の方が表現力は高いのですが、一度に覚えるのは困難です。`Bind`と`Return`だけでもかなりのことができるので、まずはそこを出発点にすると良いのではないでしょうか。（それはつまりモナドの勉強になってしまうかもしれませんが）
