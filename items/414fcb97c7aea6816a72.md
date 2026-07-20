---
coediting: false
comments_count: 0
created_at: '2017-11-29T17:20:13+09:00'
id: 414fcb97c7aea6816a72
likes_count: 9
private: false
reactions_count: 0
stocks_count: 8
tags:
- name: F#
  versions: []
- name: 数学
  versions: []
title: ディラック作用素の代数計算
updated_at: '2018-07-26T08:11:59+09:00'
url: https://qiita.com/7shi/items/414fcb97c7aea6816a72
slide: false
---

微分作用素の一種であるディラック作用素を実装します。代数計算に必要な要素を確認するのが狙いです。

ディラック作用素については以下の記事を参照してください。

* 2018.07.22 [ディラック作用素と外微分・余微分](http://7shi.hateblo.jp/entry/2017/10/04/183857)
* 2018.07.25 [ディラック作用素とラプラシアン](http://7shi.hateblo.jp/entry/2017/10/07/115237)
* 2018.07.26 [ディラック作用素とマクスウェル方程式](http://7shi.hateblo.jp/entry/2017/12/07/183102)

この記事で作ったプログラムによる計算結果を使った記事です。

* 2018.07.25 [ディラック作用素で2次元と4次元を計算](http://7shi.hateblo.jp/entry/2017/12/06/161234)

実装には F# を使用します。

以下の記事で紹介した手法で開発しました。

* 2016.12.30 [F#開発環境の紹介](http://qiita.com/7shi/items/5fc7d6477d96bbd7a71d)

F#の入門記事を書いています。

* 2017.01.04 [C#/JavaScriptで学ぶF#入門](http://qiita.com/7shi/items/ff746903680ae8d0d7ce)
* 2017.01.11 [Haskellで学ぶF#入門](http://qiita.com/7shi/items/1d3750ba17f5a88b8405)

この記事には関連記事があります。

* 2016.12.15 [Haskellによる代数計算入門](https://qiita.com/7shi/items/096396f0007857676515)
* 2016.12.14 [多項式の積を計算](https://qiita.com/7shi/items/4fb60dacad46cb8e63b3)

# 概要

ベクトル解析ではスカラー場の微分をgrad、ベクトル場の微分をrot/divと呼びます。

```math
\begin{align*}
\mathrm{grad}F&=\left(\begin{matrix}F_x\\F_y\\F_z\end{matrix}\right)\\
\mathrm{rot}\left(\begin{matrix}X\\Y\\Z\end{matrix}\right)&=\left(\begin{matrix}Z_y-Y_z\\X_z-Z_x\\Y_x-X_y\end{matrix}\right)\\
\mathrm{div}\left(\begin{matrix}X\\Y\\Z\end{matrix}\right)&=X_x+Y_y+Z_z
\end{align*}
```

ディラック作用素を使えば、これらを算出して関係を体系的に整理できます。

```math
\begin{align*}
DF
&=\underbrace{F_x\,dx+F_y\,dy+F_z\,dz}_{\mathrm{grad}}\\
D(X\,dx+Y\,dy+Z\,dz)
&=\underbrace{X_x+Y_y+Z_z}_{\mathrm{div}}\\
&\quad+\underbrace{(Z_y-Y_z)dy\,dz+(X_z-Z_x)dz\,dx+(Y_x-X_y)dx\,dy}_{\mathrm{rot}}\\
D(X\,dy\,dz+Y\,dz\,dx+Z\,dx\,dy)
&=\underbrace{(Y_z-Z_y)dx+(Z_x-X_z)dy+(X_y-Y_x)dz}_{-\mathrm{rot}}\\
&\quad+\underbrace{(X_x+Y_y+Z_z)dx\,dy\,dz}_{\mathrm{div}}\\
DF\,dx\,dy\,dz
&=\underbrace{F_x\,dy\,dz+F_y\,dz\,dx+F_z\,dx\,dy}_{\mathrm{grad}}
\end{align*}
```

関係を図示します。右向きの矢印と左向きの矢印はほぼ左右対称となっています。rot の符号反転は係数配置の左右反転に由来すると解釈できます。例: $(Z_y-Y_z)$ → $(Y_z-Z_y)$

![図1.png](https://qiita-image-store.s3.amazonaws.com/0/32057/a223214e-bf11-5654-9c63-b26d78d6d8a4.png)

この計算を実装します。先に、完成したコード全体を示します。

* [Dirac.fsx](https://bitbucket.org/snippets/7shi/kek8LA)

# 項

計算で必要となる項の構造をタプルで表現します。

```math
-X_{yz}\,dx\,dy
```
```fsharp
(-1, "X", ["y"; "z"], ["x"; "y"])
```

エイリアスを定義します。

```fsharp
type Term = int * string * string list * string list
```

表示用に文字列に変換する関数を実装します。

## 基底

簡単のため微分形式に決め打ちします。

```fsharp
let t, w, x, y, z = "t", "w", "x", "y", "z"

let tostrb (tb:string list) =
    if tb.IsEmpty then "" else
    @"d" + String.concat @"\,d" tb
```
```fsharp:動作確認
do
    let test xs =
        printfn "tostrb: %A -> %s" xs (tostrb xs)
    test [x;y]
```
```text:実行結果
tostrb: ["x"; "y"] -> dx\,dy
```

## 一項

1つの項を変換します。

```fsharp
let tostr1 ((ts, tf, tp, tb):Term) =
    if ts = 0 then "0" else
    let s = match ts with 1 -> "" | -1 -> "-" | _ -> ts.ToString()
    let p =
        if tp.IsEmpty then "" else
        sprintf "_{%s}" (String.concat "" tp)
    match tf, p, tostrb tb with
    | "", "", "" -> ts.ToString()
    | "", "", tb -> s + tb
    | _ , _ , "" -> s + tf + p
    | _ , _ , tb -> s + tf + p + @"\," + tb
```
```fsharp:動作確認
do
    let test t =
        printfn "tostr1: %A -> %s" t (tostr1 t)
    test( 1,"X",[]   ,[x])
    test(-1,"Y",[x;x],[y])
    test( 2,"Y",[z]  ,[z;x])
```
```text:実行結果
tostr1: (1, "X", [], ["x"]) -> X\,dx
tostr1: (-1, "Y", ["x"; "x"], ["y"]) -> -Y_{xx}\,dy
tostr1: (2, "Y", ["z"], ["z"; "x"]) -> 2Y_{z}\,dz\,dx
```

## 多項式

項のリストで多項式を表現して、多項式を変換します。

```fsharp
let tostr (xs:Term list) =
    xs
    |> Seq.zip (Seq.init xs.Length id)
    |> Seq.map (fun (i, t) ->
        let s = tostr1 t
        if i = 0 || s.StartsWith "-" then s else "+" + s)
    |> String.concat ""
```
```fsharp:動作確認
do
    let test xs = printfn "tostr: %A -> %s" xs (tostr xs)
    test [1,"X",[],[x]; -1,"Y",[x;x],[y;z]]
```
```text:実行結果
tostr: [(1, "X", [], ["x"]); (-1, "Y", ["x"; "x"], ["y"; "z"])] -> X\,dx-Y_{xx}\,dy\,dz
```

# ディラック作用素

スカラー関数にディラック作用素を適用します。

```math
DF=F_x\,dx+F_y\,dy+F_z\,dz
```

空間の全基底を偏微分と基底に付加して多項式を出力します。

```fsharp
let r2b1, r3b1, r4b1 = [x;y], [x;y;z], [w;x;y;z]
let m2b1, m3b1, m4b1 = [t;x], [t;x;y], [t;x;y;z]

let dirac0 f b1 = [for b in b1 -> 1, f, [b], [b]]
```
```fsharp:動作確認
do
    let test b1 f = printfn @"\mathrm{dirac0}&: %s\ →\ %s\\" f (dirac0 f b1 |> tostr)
    test r3b1 "F"
```
```text:実行結果
\mathrm{dirac0}&: F\ →\ F_{x}\,dx+F_{y}\,dy+F_{z}\,dz\\
```

以後、実行結果は数式で示します。

```math
\mathrm{dirac0}: F\ →\ F_{x}\,dx+F_{y}\,dy+F_{z}\,dz\\
```

## 項

項への作用を実装します。

```fsharp
let dirac1 b1 ((ts, tf, tp, tb):Term) =
    [for b in b1 -> ts, tf, List.append tp [b], List.append [b] tb]
```
```fsharp:動作確認
do
    let test t =
        for b1 in [r2b1; r3b1; r4b1] do
        printfn @"\mathrm{dirac1}&: %s\ →\ %s\\"
            (tostr1 t) (dirac1 b1 t |> tostr)
    test (1,"F",[],[])
    test (1,"F",[],[x])
```
```math
\begin{align*}
\mathrm{dirac1}&: F\ →\ F_{x}\,dx+F_{y}\,dy\\
\mathrm{dirac1}&: F\ →\ F_{x}\,dx+F_{y}\,dy+F_{z}\,dz\\
\mathrm{dirac1}&: F\ →\ F_{w}\,dw+F_{x}\,dx+F_{y}\,dy+F_{z}\,dz\\
\mathrm{dirac1}&: F\,dx\ →\ F_{x}\,dx\,dx+F_{y}\,dy\,dx\\
\mathrm{dirac1}&: F\,dx\ →\ F_{x}\,dx\,dx+F_{y}\,dy\,dx+F_{z}\,dz\,dx\\
\mathrm{dirac1}&: F\,dx\ →\ F_{w}\,dw\,dx+F_{x}\,dx\,dx+F_{y}\,dy\,dx+F_{z}\,dz\,dx\\
\end{align*}
```

次元を変えてテストしています。

## 多項式

多項式への作用を実装します。

```fsharp
let f = [1,"F",[],[]]

let dirac b1 xs = List.collect (dirac1 b1) xs
```
```fsharp:動作確認
do
    let test b1 xs =
        let dxs = dirac b1 xs
        printfn @"\mathrm{dirac}&: %s\ →\ %s\\"
            (tostr dxs) (dirac b1 dxs |> tostr)
    test r2b1 f
    test m2b1 f
```
```math
\begin{align*}
\mathrm{dirac}&: F_{x}\,dx+F_{y}\,dy\ →\ F_{xx}\,dx\,dx+F_{xy}\,dy\,dx+F_{yx}\,dx\,dy+F_{yy}\,dy\,dy\\
\mathrm{dirac}&: F_{t}\,dt+F_{x}\,dx\ →\ F_{tt}\,dt\,dt+F_{tx}\,dx\,dt+F_{xt}\,dt\,dx+F_{xx}\,dx\,dx\\
\end{align*}
```

スカラー関数に作用させて作った多項式に、再度作用させてテストしています。

## ラプラシアン

2回の作用を関数化します。これはいわゆるラプラシアン（ラプラス作用素）です。

```fsharp
let laplace sp = dirac sp >> dirac sp
```
```fsharp:動作確認
do
    let test sp xs =
        printfn @"\mathrm{laplace}&: %s\ →\ %s\\"
            (tostr xs) (laplace sp xs |> tostr)
    test r2b1 f
    test m2b1 f
```
```math
\begin{align*}
\mathrm{laplace}&: F\ →\ F_{xx}\,dx\,dx+F_{xy}\,dy\,dx+F_{yx}\,dx\,dy+F_{yy}\,dy\,dy\\
\mathrm{laplace}&: F\ →\ F_{tt}\,dt\,dt+F_{tx}\,dx\,dt+F_{xt}\,dt\,dx+F_{xx}\,dx\,dx\\
\end{align*}
```

# 式の整理

単に計算しただけでは式が複雑なままです。更に計算を進めて式を整理します。

## 縮約

簡単のため今回は正規直交基底に限定します。同じ基底同士の幾何積はスカラーに縮約します（内積）。値は空間の計量に依存しますが、ユークリッド空間では 1 です。

```math
\underbrace{dx\,dx}_{縮約}=1
```

縮約するには基底が隣接している必要があります。隣接していない場合、バブルソートのように基底を交換して隣接させます。交換の際に符号が反転しますが、これを反交換性と呼びます。

```math
dx\,\underbrace{dy\,dx}_{交換}=-\underbrace{dx\,dx}_{縮約}\,dy=-dy
```

※ このようなルールで交換と縮約を行う代数系を**クリフォード代数**と呼びます。

### 交換回数

交換回数を数えることで符号が決まります。偶数なら正、奇数なら負です。

```fsharp
let acom i = if i &&& 1 = 1 then -1 else 1
```
```fsharp:動作確認
do
    let test i =
        printfn @"\mathrm{acom}&: %d\ →\ %d\\" i (acom i)
    test 0
    test 1
    test 2
    test 3
```
```math
\begin{align*}
\mathrm{acom}&: 0\ →\ 1\\
\mathrm{acom}&: 1\ →\ -1\\
\mathrm{acom}&: 2\ →\ 1\\
\mathrm{acom}&: 3\ →\ -1\\
\end{align*}
```

### 基底

基底の交換と縮約を実装します。計量を指定します。

```fsharp
let r2g = Map.ofList [x,1; y,1]
let r3g = Map.ofList [x,1; y,1; z,1]
let r4g = Map.ofList [w,1; x,1; y,1; z,1]
let m2g = Map.ofList [t,1; x,-1]
let m3g = Map.ofList [t,1; x,-1; y,-1]
let m4g = Map.ofList [t,1; x,-1; y,-1; z,-1]

let rec pair0 g = function
| [] -> 1, []
| x::xs ->
    match List.tryFindIndex ((=) x) xs with
    | None ->
        let i, ys = pair0 g xs
        i, x::ys
    | Some i ->
        let xa = List.toArray xs
        let j, ys = pair0 g (Array.append xa.[.. i - 1] xa.[i + 1 ..] |> Array.toList)
        acom i * Map.find x g * j, ys
```
```fsharp:動作確認
do
    let test g xs =
        printfn @"\mathrm{pair0}&: %A\ →\ %A\\" xs (pair0 g xs)
    test r2g [x;x]
    test r2g [x;y]
    test r2g [x;y;x]
    test m2g [x;t;x]
```
```math
\begin{align*}
\mathrm{pair0}&: ["x"; "x"]\ →\ (1, [])\\
\mathrm{pair0}&: ["x"; "y"]\ →\ (1, ["x"; "y"])\\
\mathrm{pair0}&: ["x"; "y"; "x"]\ →\ (-1, ["y"])\\
\mathrm{pair0}&: ["x"; "t"; "x"]\ →\ (1, ["t"])\\
\end{align*}
```

### 項

項に対して適用します。

```fsharp
let pair1 g ((ts, tf, tp, tb):Term) =
    let s, b = pair0 g tb
    s * ts, tf, tp, b
```
```fsharp:動作確認
do
    let test g x =
        let t = 1, "", [], x
        printfn @"\mathrm{pair1}&: %s\ →\ %s\\" (tostr1 t) (pair1 g t |> tostr1)
    test r2g [x;x]
    test r2g [x;y]
    test r2g [x;y;x]
    test m2g [x;t;x]
```
```math
\begin{align*}
\mathrm{pair1}&: dx\,dx\ →\ 1\\
\mathrm{pair1}&: dx\,dy\ →\ dx\,dy\\
\mathrm{pair1}&: dx\,dy\,dx\ →\ -dy\\
\mathrm{pair1}&: dx\,dt\,dx\ →\ dt\\
\end{align*}
```

### 多項式

多項式に対して適用します。

```fsharp
let pair g = List.map (pair1 g)
```
```fsharp:動作確認
do
    let test b1 g xs =
        let lxs = laplace b1 xs
        printfn @"\mathrm{pair}&: %s\ →\ %s\\"
            (tostr lxs) (pair g lxs |> tostr)
    test r2b1 r2g f
    test m2b1 m2g f
```
```math
\begin{align*}
\mathrm{pair}&: F_{xx}\,dx\,dx+F_{xy}\,dy\,dx+F_{yx}\,dx\,dy+F_{yy}\,dy\,dy\ →\ F_{xx}+F_{xy}\,dy\,dx+F_{yx}\,dx\,dy+F_{yy}\\
\mathrm{pair}&: F_{tt}\,dt\,dt+F_{tx}\,dx\,dt+F_{xt}\,dt\,dx+F_{xx}\,dx\,dx\ →\ F_{tt}+F_{tx}\,dx\,dt+F_{xt}\,dt\,dx-F_{xx}\\
\end{align*}
```

## 基底の並べ替え

反交換性を利用すれば、並びが異なる基底を同類項として整理できます。

```math
a\,dx\,dy+b\,\underbrace{dy\,dx}_{交換}=a\,dx\,dy-b\,dx\,dy=(a-b)dx\,dy
```

### 回数

並びを指定して並べ替えます。符号を決めるのに必要な回数を返します。要素が合わなければ `None` を返します。

```fsharp
let rec bsortc = function
| [], [] -> Some 0
| [], _  -> None
| b::bs, xs ->
    match List.tryFindIndex ((=) b) xs with
    | None -> None
    | Some i ->
        match bsortc (bs, List.filter ((<>) b) xs) with
        | None -> None
        | Some j -> Some (i + j)
```
```fsharp:動作確認
do
    let test bs xs =
        printfn @"\mathrm{bsortc}&: %s\ →\ %A\\" (tostrb xs) (bsortc(bs, xs))
    test [z;x]   [x;z]
    test [x;y]   [x;z]
    test [x;y;z] [z;y;x]
```
```math
\begin{align*}
\mathrm{bsortc}&: dx\,dz\ →\ Some 1\\
\mathrm{bsortc}&: dx\,dz\ →\ <null>\\
\mathrm{bsortc}&: dz\,dy\,dx\ →\ Some 3\\
\end{align*}
```

### 標準化

標準的な並びを定義します。

```fsharp
let r2b = [[x];[y]
           [x;y]]
let r3b = [[x];[y];[z]
           [y;z];[z;x];[x;y]
           [x;y;z]]
let r4b = [[w];[x];[y];[z]
           [w;x];[w;y];[w;z];[y;z];[z;x];[x;y]
           [x;y;z];[w;y;z];[w;z;x];[w;x;y]
           [w;x;y;z]]

let m2b = [[t];[x]
           [t;x]]
let m3b = [[t];[x];[y]
           [x;y];[t;x];[t;y]
           [t;x;y]]
let m4b = [[t];[x];[y];[z]
           [t;x];[t;y];[t;z];[y;z];[z;x];[x;y]
           [x;y;z];[t;y;z];[t;z;x];[t;x;y]
           [t;x;y;z]]
```

この中から合致する組み合わせを探して、符号を添えて返します。

```fsharp
let bsort0 b list =
    let len = List.length list
    let f bb =
        if List.length bb <> len then None else
        match bsortc (bb, list) with
        | None   -> None
        | Some i -> Some (acom i, bb)
    match List.tryPick f b with
    | None   -> 1, list
    | Some x -> x
```
```fsharp:動作確認
do
    let test b xs =
        let s, ys = bsort0 b xs
        printfn @"\mathrm{bsort0}&: %s\ →\ %d, %s\\" (tostrb xs) s (tostrb ys)
    test r3b [x;z]
    test r3b [z;x]
    test r3b [y;x]
    test r3b [z;y;x]
```
```math
\begin{align*}
\mathrm{bsort0}&: dx\,dz\ →\ -1, dz\,dx\\
\mathrm{bsort0}&: dz\,dx\ →\ 1, dz\,dx\\
\mathrm{bsort0}&: dy\,dx\ →\ -1, dx\,dy\\
\mathrm{bsort0}&: dz\,dy\,dx\ →\ -1, dx\,dy\,dz\\
\end{align*}
```

### 項

項の基底を並べ替えます。

```fsharp
let bsort1 b ((ts, tf, tp, tb):Term) =
    let ts2, tb2 = bsort0 b tb
    ts2 * ts, tf, tp, tb2
```
```fsharp:動作確認
do
    let test b tb =
        let x = 1, "", [], tb
        printfn @"\mathrm{bsort1}&: %s\ →\ %s\\" (tostr1 x) (bsort1 b x |> tostr1)
    test r3b [x;z]
    test r3b [z;x]
    test r3b [y;x]
    test r3b [z;y;x]
```
```math
\begin{align*}
\mathrm{bsort1}&: dx\,dz\ →\ -dz\,dx\\
\mathrm{bsort1}&: dz\,dx\ →\ dz\,dx\\
\mathrm{bsort1}&: dy\,dx\ →\ -dx\,dy\\
\mathrm{bsort1}&: dz\,dy\,dx\ →\ -dx\,dy\,dz\\
\end{align*}
```

### 空間の属性

空間の属性として基底、基底の並び、計量が出て来ました。使い分けると面倒なため、まとめてセットにします。

```fsharp
let r2, r3, r4 = (r2b1, r2b, r2g), (r3b1, r3b, r3g), (r4b1, r4b, r4g)
let m2, m3, m4 = (m2b1, m2b, m2g), (m3b1, m3b, m3g), (m4b1, m4b, m4g)
```

### 多項式

多項式の基底を並べ替えます。

```fsharp
let bsort (_, b, _) = List.map (bsort1 b)
```
```fsharp:動作確認
do
    let test ((b1, _, g) as sp) xs =
        let lxs = laplace b1 xs |> pair g
        printfn @"\mathrm{bsort}&: %s\ →\ %s\\"
            (tostr lxs) (bsort sp lxs |> tostr)
    test r2 f
    test m2 f
```
```math
\begin{align*}
\mathrm{bsort}&: F_{xx}+F_{xy}\,dy\,dx+F_{yx}\,dx\,dy+F_{yy}\ →\ F_{xx}-F_{xy}\,dx\,dy+F_{yx}\,dx\,dy+F_{yy}\\
\mathrm{bsort}&: F_{tt}+F_{tx}\,dx\,dt+F_{xt}\,dt\,dx-F_{xx}\ →\ F_{tt}-F_{tx}\,dt\,dx+F_{xt}\,dt\,dx-F_{xx}\\
\end{align*}
```

基底の縮約と並べ替えにより、かなり整理されて来ました。

## 偏微分の並べ替え

簡単のため偏微分の順序は交換可能だとします。基底とは異なる組み合わせが現れます（縮約しないため）。単独の基底として与えられたリストの順番で並べ替えます。

```fsharp
let psort (b1, _, _) =
    List.map <| fun ((s, tf, tp, tb):Term) ->
        let f x = List.findIndex ((=) x) b1
        s, tf, List.sortBy f tp, tb
```
```fsharp:動作確認
do
    let test ((b1, _, g) as sp) xs =
        let lxs = laplace b1 xs |> pair g |> bsort sp
        printfn @"\mathrm{psort}&: %s\ →\ %s\\"
            (tostr lxs) (psort sp lxs |> tostr)
    test r2 f
    test m2 f
```
```math
\begin{align*}
\mathrm{psort}&: F_{xx}-F_{xy}\,dx\,dy+F_{yx}\,dx\,dy+F_{yy}\ →\ F_{xx}-F_{xy}\,dx\,dy+F_{xy}\,dx\,dy+F_{yy}\\
\mathrm{psort}&: F_{tt}-F_{tx}\,dt\,dx+F_{xt}\,dt\,dx-F_{xx}\ →\ F_{tt}-F_{tx}\,dt\,dx+F_{tx}\,dt\,dx-F_{xx}\\
\end{align*}
```

## 項の並べ替え

基底を基準にして項を並べ替えます。同じ基底では符号や係数を見ます。

```fsharp
let sort (_, b, _) =
    List.filter (fun (ts, _, _, _) -> ts <> 0)
    >> List.sortBy (fun (ts, tf, tp, tb) ->
        (match tb with [] -> 0 | x  -> 1 + List.findIndex ((=) x) b),
        -sign ts, tf, tp)
```
```fsharp:動作確認
do
    let test ((b1, _, g) as sp) xs =
        let lxs = laplace b1 xs |> pair g |> bsort sp |> psort sp
        printfn @"\mathrm{sort}&: %s\ →\ %s\\"
            (tostr lxs) (sort sp lxs |> tostr)
    test r2 f
    test m2 f
```
```math
\begin{align*}
\mathrm{sort}&: F_{xx}-F_{xy}\,dx\,dy+F_{xy}\,dx\,dy+F_{yy}\ →\ F_{xx}+F_{yy}+F_{xy}\,dx\,dy-F_{xy}\,dx\,dy\\
\mathrm{sort}&: F_{tt}-F_{tx}\,dt\,dx+F_{tx}\,dt\,dx-F_{xx}\ →\ F_{tt}-F_{xx}+F_{tx}\,dt\,dx-F_{tx}\,dt\,dx\\
\end{align*}
```

## 同類項のグループ化

同類項をグループ化して表示します。`Seq.groupBy` を活用します。

```fsharp
let tostrg = function
| [ ] -> "0"
| [x] -> tostr1 x
| xs  ->
    xs
    |> Seq.groupBy (fun ((_, _, _, tb):Term) -> tb)
    |> Seq.zip (Seq.init xs.Length id)
    |> Seq.map (fun (i, (tb, xs)) ->
        let s =
            if tb = [] then Seq.toList xs |> tostr else
            match Seq.map (fun (ts, tf, tp, _) -> ts, tf, tp, []) xs |> Seq.toList with
            | [x] -> tostr1 x + @"\," + tostrb tb
            | xs  -> "(" + tostr xs + ")" + tostrb tb
        if i = 0 || s.StartsWith "-" then s else "+" + s)
    |> String.concat ""
```
```fsharp:動作確認
do
    let test ((b1, _, g) as sp) xs =
        let lxs = laplace b1 xs |> pair g |> bsort sp |> psort sp |> sort sp
        printfn @"\mathrm{tostrg}&: %s\ →\ %s\\"
            (tostr lxs) (tostrg lxs)
    test r2 f
    test m2 f
```
```math
\begin{align*}
\mathrm{tostrg}&: F_{xx}+F_{yy}+F_{xy}\,dx\,dy-F_{xy}\,dx\,dy\ →\ F_{xx}+F_{yy}+(F_{xy}-F_{xy})dx\,dy\\
\mathrm{tostrg}&: F_{tt}-F_{xx}+F_{tx}\,dt\,dx-F_{tx}\,dt\,dx\ →\ F_{tt}-F_{xx}+(F_{tx}-F_{tx})dt\,dx\\
\end{align*}
```

表示の際にグループ化しているだけで、データ構造の変更（ネスト等）は行っていません。

## 同類項の整理

同類項を整理します。`List.partition` を活用します。

```fsharp
let rec simplify = function
| [] -> []
| (ts1, tf1, tp1, tb1)::xs ->
    let t1 = tostr1 (1, tf1, tp1, tb1)
    let xs1, xs2 =
        xs
        |> List.partition (fun (_, tf2, tp2, tb2) ->
            t1 = tostr1 (1, tf2, tp2, tb2))
    match ts1 + (Seq.map (fun (ts, _, _, _) -> ts) xs1 |> Seq.sum) with
    | 0  -> simplify xs2
    | ts -> (ts, tf1, tp1, tb1)::simplify xs2
```
```fsharp:動作確認
do
    let test ((b1, _, g) as sp) xs =
        let lxs = laplace b1 xs |> pair g |> bsort sp |> psort sp |> sort sp
        printfn @"\mathrm{simplify}&: %s\ →\ %s\\"
            (tostrg lxs) (simplify lxs |> tostrg)
    test r2 f
    test m2 f
```
```math
\begin{align*}
\mathrm{simplify}&: F_{xx}+F_{yy}+(F_{xy}-F_{xy})dx\,dy\ →\ F_{xx}+F_{yy}\\
\mathrm{simplify}&: F_{tt}-F_{xx}+(F_{tx}-F_{tx})dt\,dx\ →\ F_{tt}-F_{xx}\\
\end{align*}
```

これで今回の目的だった形になりました。

# まとめ関数

工程を細かく分割したため関数が多くなりました。利便性のため、まとめ関数を用意します。

```fsharp
let doDirac ((b1, _, g) as sp) =
    dirac b1 >> pair g >> bsort sp >> psort sp >> sort sp >> simplify
```

# テスト

冒頭に挙げた3次元のユークリッド空間を計算します。

```fsharp
let test sp f =
    let df = doDirac sp f
    printfn @"D(%s)&=%s\\" (tostr f) (tostrg df)

test r3 [1,"F",[],[]]
test r3 [1,"X",[],[x]; 1,"Y",[],[y]; 1,"Z",[],[z]]
test r3 [1,"X",[],[y;z]; 1,"Y",[],[z;x]; 1,"Z",[],[x;y]]
test r3 [1,"F",[],[x;y;z]]
```
```math
\begin{align*}
D(F)&=F_{x}\,dx+F_{y}\,dy+F_{z}\,dz\\
D(X\,dx+Y\,dy+Z\,dz)&=X_{x}+Y_{y}+Z_{z}+(Z_{y}-Y_{z})dy\,dz+(X_{z}-Z_{x})dz\,dx+(Y_{x}-X_{y})dx\,dy\\
D(X\,dy\,dz+Y\,dz\,dx+Z\,dx\,dy)&=(Y_{z}-Z_{y})dx+(Z_{x}-X_{z})dy+(X_{y}-Y_{x})dz+(X_{x}+Y_{y}+Z_{z})dx\,dy\,dz\\
D(F\,dx\,dy\,dz)&=F_{x}\,dy\,dz+F_{y}\,dz\,dx+F_{z}\,dx\,dy\\
\end{align*}
```

うまく計算できています。

少し手を加えれば、他の次元やミンコフスキー空間も計算できます。計算結果については[こちらの記事](http://7shi.hateblo.jp/entry/2017/12/06/161234)を参照してください。
