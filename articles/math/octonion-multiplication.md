---
coediting: false
comments_count: 0
created_at: '2016-12-13T19:11:43+09:00'
id: 8495b2d6b888e7b8703f
likes_count: 3
private: false
reactions_count: 0
stocks_count: 2
tags:
- name: F#
  versions: []
- name: 数学
  versions: []
- name: 四元数
  versions: []
- name: 八元数
  versions: []
title: 八元数の積をプログラムで確認
updated_at: '2017-12-05T12:40:18+09:00'
url: https://qiita.com/7shi/items/8495b2d6b888e7b8703f
slide: false
---

八元数は項が多くて積の計算が大変です。そこでプログラムを作って積・二乗・ノルムの二乗を確認してみました。

八元数の虚部を7次元ベクトルとして扱うことで、積から内積と外積が得られます。

```math
\vec{v}\vec{w}=-\underbrace{\vec{v}\cdot\vec{w}}_{内積}+\underbrace{\vec{v}×\vec{w}}_{外積}
```

シリーズの記事です。

1. [多項式の積を計算](http://qiita.com/7shi/items/4fb60dacad46cb8e63b3)
1. [外積と愉快な仲間たち](http://qiita.com/7shi/items/017d2d2c758f76071f23)
1. [ユークリッド空間のホッジ双対とバブルソート](http://qiita.com/7shi/items/f54302058149d07da592)
1. [四元数を作ろう](http://qiita.com/7shi/items/2036e7a739c2a9e04025)
1. [四元数と行列で見る内積と外積の「内」と「外」](http://qiita.com/7shi/items/a80988a32a0d706e9378)
1. [八元数を作ろう](http://qiita.com/7shi/items/b34fe724d36fb7d96456)
1. 八元数の積をプログラムで確認 ← この記事
1. [外積の成分をプログラムで確認](http://qiita.com/7shi/items/02c758c03d2fd7038912)
1. [多元数の積の構成](http://qiita.com/7shi/items/88be5203769e629df243)
1. [十六元数を作ろう](http://qiita.com/7shi/items/989d59d74a505a92c419)

この記事には関連記事があります。

* 2017.12.04 [八元数と7次元の外積](http://7shi.hateblo.jp/entry/2017/12/04/235635) ← お勧め

# プログラム

八元数に関連するプログラムを引用します。[Math7.fsx](https://bitbucket.org/7shi/math7/src/tip/Math7.fsx) と [Math7.Term.fsx](https://bitbucket.org/7shi/math7/src/tip/Math7.Term.fsx) に依存しています。全体は[リポジトリ](https://bitbucket.org/7shi/math7)を参照してください。

Math7 に八元数の計算方法を教えて計算させます。

```fsharp:Math7.Octonion.fsx
namespace Math7

#load "Math7.Term.fsx"

type octonion =
    E | I | J | K | H of octonion

    override x.ToString() =
        match x with
        |   E -> "1" | I -> "i" | J -> "j" | K -> "k"
        | H E -> "h"
        | H x -> string x + "_h"

    member x.N =
        match x with
        | E -> 0 | I -> 1 | J -> 2 | K -> 3
        | H x -> x.N + 4

    member x.Next =
        match x with
        |   I -> J
        |   J -> K
        |   K -> I
        | H x -> H x.Next
        |   x -> x

    static member (*)(a:octonion, b:octonion) =
        match a, b with
        |   x,   E            ->  1,   x  // i1 = i
        |   E,   y            ->  1,   y  // 1i = i
        |   x,   y when x = y -> -1,   E  // ii = -1
        | H x, H E            -> -1,   x  // i_hh = -i
        | H x, H y            -> y * x    // i_hj_h = ji
        |   x, H E            ->  1, H x  // ih = i_h
        |   x, H y when x = y -> -1, H E  // ii_h = -h
        |   x, H y -> let c, z = y * x    // ij_h = (ji)h
                      c, H z
        |   x,   y when x.Next = y        // ij = k
                   -> 1, y.Next
        |   x,   y -> let c, z = y * x    // ji = -ij
                      -c, z

module Octonion =
    let tests = testList()
    
    let octs = [| E; I; J; K; H E; H I; H J; H K |]
    let oct x = octs.[x]
    let ijkh = function
    | 0 -> ""
    | x -> string (oct x)

    let str es = es |> Seq.map ijkh |> Seq.filter ((<>) "") |> Term.strPower

    let prod es =
        let n, e = es |> Seq.fold (fun (n, x) y ->
            let m, z = oct x * oct y
            n * m, z.N) (1, E.N)
        term(n, [], if e = E.N then [] else [e])

    let conj = List.map <| fun (t:term) ->
        if t.E.IsEmpty then t else -1 * t

    let showProd title =
        Term.showProd title "" str prod id Term.byIndexSign
```
```fsharp:OctonionProduct.fsx
#load "Math7.Octonion.fsx"
open Math7

let a = [for i in [1..7] -> term(1, [sprintf "a_%d" i], [i])]
let b = [for i in [1..7] -> term(1, [sprintf "b_%d" i], [i])]
let aa = term(1, ["a_0"], [])::a
let bb = term(1, ["b_0"], [])::b
Octonion.showProd "## 積（虚部）" (fun _ -> true) a b
Octonion.showProd "## 積（実部＋虚部）" (fun _ -> true) aa bb
Octonion.showProd "## 二乗（虚部）" (fun _ -> true) a a
Octonion.showProd "## 二乗（実部＋虚部）" ((=) 1) aa aa
Octonion.showProd "## ノルムの二乗" (fun _ -> true) (Octonion.conj aa) aa
```

出力結果にコメントを付けて紹介します。

## 積（虚部）

冒頭で述べたように、内積と外積を計算することに相当します。

```math
\begin{align}
&(a_1i+a_2j+a_3k+a_4h+a_5i_h+a_6j_h+a_7k_h)(b_1i+b_2j+b_3k+b_4h+b_5i_h+b_6j_h+b_7k_h) \\
&=a_1i(b_1i+b_2j+b_3k+b_4h+b_5i_h+b_6j_h+b_7k_h) \\
&\quad +a_2j(b_1i+b_2j+b_3k+b_4h+b_5i_h+b_6j_h+b_7k_h) \\
&\quad +a_3k(b_1i+b_2j+b_3k+b_4h+b_5i_h+b_6j_h+b_7k_h) \\
&\quad +a_4h(b_1i+b_2j+b_3k+b_4h+b_5i_h+b_6j_h+b_7k_h) \\
&\quad +a_5i_h(b_1i+b_2j+b_3k+b_4h+b_5i_h+b_6j_h+b_7k_h) \\
&\quad +a_6j_h(b_1i+b_2j+b_3k+b_4h+b_5i_h+b_6j_h+b_7k_h) \\
&\quad +a_7k_h(b_1i+b_2j+b_3k+b_4h+b_5i_h+b_6j_h+b_7k_h) \\
&=a_1b_1\underbrace{i^2}_{-1}+a_1b_2\underbrace{ij}_{k}+a_1b_3\underbrace{ik}_{-j}+a_1b_4\underbrace{ih}_{i_h}+a_1b_5\underbrace{ii_h}_{-h}+a_1b_6\underbrace{ij_h}_{-k_h}+a_1b_7\underbrace{ik_h}_{j_h} \\
&\quad +a_2b_1\underbrace{ji}_{-k}+a_2b_2\underbrace{j^2}_{-1}+a_2b_3\underbrace{jk}_{i}+a_2b_4\underbrace{jh}_{j_h}+a_2b_5\underbrace{ji_h}_{k_h}+a_2b_6\underbrace{jj_h}_{-h}+a_2b_7\underbrace{jk_h}_{-i_h} \\
&\quad +a_3b_1\underbrace{ki}_{j}+a_3b_2\underbrace{kj}_{-i}+a_3b_3\underbrace{k^2}_{-1}+a_3b_4\underbrace{kh}_{k_h}+a_3b_5\underbrace{ki_h}_{-j_h}+a_3b_6\underbrace{kj_h}_{i_h}+a_3b_7\underbrace{kk_h}_{-h} \\
&\quad +a_4b_1\underbrace{hi}_{-i_h}+a_4b_2\underbrace{hj}_{-j_h}+a_4b_3\underbrace{hk}_{-k_h}+a_4b_4\underbrace{h^2}_{-1}+a_4b_5\underbrace{hi_h}_{i}+a_4b_6\underbrace{hj_h}_{j}+a_4b_7\underbrace{hk_h}_{k} \\
&\quad +a_5b_1\underbrace{i_hi}_{h}+a_5b_2\underbrace{i_hj}_{-k_h}+a_5b_3\underbrace{i_hk}_{j_h}+a_5b_4\underbrace{i_hh}_{-i}+a_5b_5\underbrace{i_h^2}_{-1}+a_5b_6\underbrace{i_hj_h}_{-k}+a_5b_7\underbrace{i_hk_h}_{j} \\
&\quad +a_6b_1\underbrace{j_hi}_{k_h}+a_6b_2\underbrace{j_hj}_{h}+a_6b_3\underbrace{j_hk}_{-i_h}+a_6b_4\underbrace{j_hh}_{-j}+a_6b_5\underbrace{j_hi_h}_{k}+a_6b_6\underbrace{j_h^2}_{-1}+a_6b_7\underbrace{j_hk_h}_{-i} \\
&\quad +a_7b_1\underbrace{k_hi}_{-j_h}+a_7b_2\underbrace{k_hj}_{i_h}+a_7b_3\underbrace{k_hk}_{h}+a_7b_4\underbrace{k_hh}_{-k}+a_7b_5\underbrace{k_hi_h}_{-j}+a_7b_6\underbrace{k_hj_h}_{i}+a_7b_7\underbrace{k_h^2}_{-1} \\
&=-(a_1b_1+a_2b_2+a_3b_3+a_4b_4+a_5b_5+a_6b_6+a_7b_7) \\
&\quad +(a_2b_3-a_3b_2+a_4b_5-a_5b_4+a_7b_6-a_6b_7)i \\
&\quad +(a_3b_1-a_1b_3+a_4b_6-a_6b_4+a_5b_7-a_7b_5)j \\
&\quad +(a_1b_2-a_2b_1+a_4b_7-a_7b_4+a_6b_5-a_5b_6)k \\
&\quad +(a_5b_1-a_1b_5+a_6b_2-a_2b_6+a_7b_3-a_3b_7)h \\
&\quad +(a_1b_4-a_4b_1+a_7b_2-a_2b_7+a_3b_6-a_6b_3)i_h \\
&\quad +(a_1b_7-a_7b_1+a_2b_4-a_4b_2+a_5b_3-a_3b_5)j_h \\
&\quad +(a_6b_1-a_1b_6+a_2b_5-a_5b_2+a_3b_4-a_4b_3)k_h \\
\end{align}
```

八元数の虚部で表される7次元空間はフラットなユークリッド空間ではなく、ファノ平面で表される7つの3次元の部分空間が重になった形をしており、部分空間を個別に見れば3次元空間のためベクトル積が定義できます。

$i$ の係数を $(a_2b_3-a_3b_2)+(a_4b_5-a_5b_4)+(a_7b_6-a_6b_7)$ のように三分割して見れば、3次元の外積が三重に入ったような形をしていることに気付きます。$i$ は3つの部分空間に属しているため、それぞれで外積としての成分を持つためです。

また、係数は基底（$i$ は1番目）を除いた添字（2,3,4,5,6,7）が使われており、相補的な関係にあることが分かります。他の項も同様です。これは3次元の外積と共通する特徴です。

比較として四元数の積（3次元の内積と外積を含む）を示します。成分を見れば、四元数が八元数のサブセットであることが見て取れます。

```math
\begin{align}
&(a_1i+a_2j+a_3k)(b_1i+b_2j+b_3k) \\
&=-(a_1b_1+a_2b_2+a_3b_3) \\
&\quad +(a_2b_3-a_3b_2)i+(a_3b_1-a_1b_3)j+(a_1b_2-a_2b_1)k \\
\end{align}
```

複素数にまで落とせば、1次元では内積しか現れないことが分かります。外積は常に0だとも解釈できます。

```math
(a_1i)(b_1i)=-(a_1b_1)
```

## 積（実部＋虚部）

虚部だけの計算と比べれば、実部が各項に絡みついているように見えます。

```math
\begin{align}
&(a_0+a_1i+a_2j+a_3k+a_4h+a_5i_h+a_6j_h+a_7k_h)(b_0+b_1i+b_2j+b_3k+b_4h+b_5i_h+b_6j_h+b_7k_h) \\
&=a_0(b_0+b_1i+b_2j+b_3k+b_4h+b_5i_h+b_6j_h+b_7k_h) \\
&\quad +a_1i(b_0+b_1i+b_2j+b_3k+b_4h+b_5i_h+b_6j_h+b_7k_h) \\
&\quad +a_2j(b_0+b_1i+b_2j+b_3k+b_4h+b_5i_h+b_6j_h+b_7k_h) \\
&\quad +a_3k(b_0+b_1i+b_2j+b_3k+b_4h+b_5i_h+b_6j_h+b_7k_h) \\
&\quad +a_4h(b_0+b_1i+b_2j+b_3k+b_4h+b_5i_h+b_6j_h+b_7k_h) \\
&\quad +a_5i_h(b_0+b_1i+b_2j+b_3k+b_4h+b_5i_h+b_6j_h+b_7k_h) \\
&\quad +a_6j_h(b_0+b_1i+b_2j+b_3k+b_4h+b_5i_h+b_6j_h+b_7k_h) \\
&\quad +a_7k_h(b_0+b_1i+b_2j+b_3k+b_4h+b_5i_h+b_6j_h+b_7k_h) \\
&=a_0b_0+a_0b_1i+a_0b_2j+a_0b_3k+a_0b_4h+a_0b_5i_h+a_0b_6j_h+a_0b_7k_h \\
&\quad +a_1b_0i+a_1b_1\underbrace{i^2}_{-1}+a_1b_2\underbrace{ij}_{k}+a_1b_3\underbrace{ik}_{-j}+a_1b_4\underbrace{ih}_{i_h}+a_1b_5\underbrace{ii_h}_{-h}+a_1b_6\underbrace{ij_h}_{-k_h}+a_1b_7\underbrace{ik_h}_{j_h} \\
&\quad +a_2b_0j+a_2b_1\underbrace{ji}_{-k}+a_2b_2\underbrace{j^2}_{-1}+a_2b_3\underbrace{jk}_{i}+a_2b_4\underbrace{jh}_{j_h}+a_2b_5\underbrace{ji_h}_{k_h}+a_2b_6\underbrace{jj_h}_{-h}+a_2b_7\underbrace{jk_h}_{-i_h} \\
&\quad +a_3b_0k+a_3b_1\underbrace{ki}_{j}+a_3b_2\underbrace{kj}_{-i}+a_3b_3\underbrace{k^2}_{-1}+a_3b_4\underbrace{kh}_{k_h}+a_3b_5\underbrace{ki_h}_{-j_h}+a_3b_6\underbrace{kj_h}_{i_h}+a_3b_7\underbrace{kk_h}_{-h} \\
&\quad +a_4b_0h+a_4b_1\underbrace{hi}_{-i_h}+a_4b_2\underbrace{hj}_{-j_h}+a_4b_3\underbrace{hk}_{-k_h}+a_4b_4\underbrace{h^2}_{-1}+a_4b_5\underbrace{hi_h}_{i}+a_4b_6\underbrace{hj_h}_{j}+a_4b_7\underbrace{hk_h}_{k} \\
&\quad +a_5b_0i_h+a_5b_1\underbrace{i_hi}_{h}+a_5b_2\underbrace{i_hj}_{-k_h}+a_5b_3\underbrace{i_hk}_{j_h}+a_5b_4\underbrace{i_hh}_{-i}+a_5b_5\underbrace{i_h^2}_{-1}+a_5b_6\underbrace{i_hj_h}_{-k}+a_5b_7\underbrace{i_hk_h}_{j} \\
&\quad +a_6b_0j_h+a_6b_1\underbrace{j_hi}_{k_h}+a_6b_2\underbrace{j_hj}_{h}+a_6b_3\underbrace{j_hk}_{-i_h}+a_6b_4\underbrace{j_hh}_{-j}+a_6b_5\underbrace{j_hi_h}_{k}+a_6b_6\underbrace{j_h^2}_{-1}+a_6b_7\underbrace{j_hk_h}_{-i} \\
&\quad +a_7b_0k_h+a_7b_1\underbrace{k_hi}_{-j_h}+a_7b_2\underbrace{k_hj}_{i_h}+a_7b_3\underbrace{k_hk}_{h}+a_7b_4\underbrace{k_hh}_{-k}+a_7b_5\underbrace{k_hi_h}_{-j}+a_7b_6\underbrace{k_hj_h}_{i}+a_7b_7\underbrace{k_h^2}_{-1} \\
&=(a_0b_0-a_1b_1-a_2b_2-a_3b_3-a_4b_4-a_5b_5-a_6b_6-a_7b_7) \\
&\quad +(a_0b_1+a_1b_0+a_2b_3-a_3b_2+a_4b_5-a_5b_4+a_7b_6-a_6b_7)i \\
&\quad +(a_0b_2+a_2b_0+a_3b_1-a_1b_3+a_4b_6-a_6b_4+a_5b_7-a_7b_5)j \\
&\quad +(a_0b_3+a_3b_0+a_1b_2-a_2b_1+a_4b_7-a_7b_4+a_6b_5-a_5b_6)k \\
&\quad +(a_0b_4+a_4b_0+a_5b_1-a_1b_5+a_6b_2-a_2b_6+a_7b_3-a_3b_7)h \\
&\quad +(a_0b_5+a_5b_0+a_1b_4-a_4b_1+a_7b_2-a_2b_7+a_3b_6-a_6b_3)i_h \\
&\quad +(a_0b_6+a_6b_0+a_1b_7-a_7b_1+a_2b_4-a_4b_2+a_5b_3-a_3b_5)j_h \\
&\quad +(a_0b_7+a_7b_0+a_6b_1-a_1b_6+a_2b_5-a_5b_2+a_3b_4-a_4b_3)k_h \\
\end{align}
```

この計算をスカラーとベクトルの和の積と見なせば、ごく普通の掛け算として構造が見えて来ます。

```math
\begin{align}
&(a_0+\vec{a})(b_0+\vec{b}) \\
&=a_0b_0+a_0\vec{b}+\vec{a}b_0+\vec{a}\vec{b} \\
&=\underbrace{a_0b_0}_{スカラー積}+\underbrace{a_0\vec{b}+b_0\vec{a}}_{スカラー倍}-\underbrace{\vec{a}\cdot\vec{b}}_{内積}+\underbrace{\vec{a}×\vec{b}}_{外積}
\end{align}
```

$i$ の項を $a_0(b_1)i+b_0(a_1)i+(a_2b_3-a_3b_2+a_4b_5-a_5b_4+a_7b_6-a_6b_7)i$ と分離すれば、ベクトルのスカラー倍と外積が重なっていることが確認できます。

この解釈では実部はベクトルの成分ではなく、ベクトルとして扱われるのは虚部の7次元です。実部まで含めた8次元ベクトルとしてうまく解釈できるかは不明です。

## 二乗（虚部）

自分自身との外積はゼロのため、計算結果は実部（内積）のみです。

```math
\begin{align}
&(a_1i+a_2j+a_3k+a_4h+a_5i_h+a_6j_h+a_7k_h)^2 \\
&=a_1i(a_1i+a_2j+a_3k+a_4h+a_5i_h+a_6j_h+a_7k_h) \\
&\quad +a_2j(a_1i+a_2j+a_3k+a_4h+a_5i_h+a_6j_h+a_7k_h) \\
&\quad +a_3k(a_1i+a_2j+a_3k+a_4h+a_5i_h+a_6j_h+a_7k_h) \\
&\quad +a_4h(a_1i+a_2j+a_3k+a_4h+a_5i_h+a_6j_h+a_7k_h) \\
&\quad +a_5i_h(a_1i+a_2j+a_3k+a_4h+a_5i_h+a_6j_h+a_7k_h) \\
&\quad +a_6j_h(a_1i+a_2j+a_3k+a_4h+a_5i_h+a_6j_h+a_7k_h) \\
&\quad +a_7k_h(a_1i+a_2j+a_3k+a_4h+a_5i_h+a_6j_h+a_7k_h) \\
&=a_1^2\underbrace{i^2}_{-1}+a_1a_2\underbrace{ij}_{k}+a_1a_3\underbrace{ik}_{-j}+a_1a_4\underbrace{ih}_{i_h}+a_1a_5\underbrace{ii_h}_{-h}+a_1a_6\underbrace{ij_h}_{-k_h}+a_1a_7\underbrace{ik_h}_{j_h} \\
&\quad +a_2a_1\underbrace{ji}_{-k}+a_2^2\underbrace{j^2}_{-1}+a_2a_3\underbrace{jk}_{i}+a_2a_4\underbrace{jh}_{j_h}+a_2a_5\underbrace{ji_h}_{k_h}+a_2a_6\underbrace{jj_h}_{-h}+a_2a_7\underbrace{jk_h}_{-i_h} \\
&\quad +a_3a_1\underbrace{ki}_{j}+a_3a_2\underbrace{kj}_{-i}+a_3^2\underbrace{k^2}_{-1}+a_3a_4\underbrace{kh}_{k_h}+a_3a_5\underbrace{ki_h}_{-j_h}+a_3a_6\underbrace{kj_h}_{i_h}+a_3a_7\underbrace{kk_h}_{-h} \\
&\quad +a_4a_1\underbrace{hi}_{-i_h}+a_4a_2\underbrace{hj}_{-j_h}+a_4a_3\underbrace{hk}_{-k_h}+a_4^2\underbrace{h^2}_{-1}+a_4a_5\underbrace{hi_h}_{i}+a_4a_6\underbrace{hj_h}_{j}+a_4a_7\underbrace{hk_h}_{k} \\
&\quad +a_5a_1\underbrace{i_hi}_{h}+a_5a_2\underbrace{i_hj}_{-k_h}+a_5a_3\underbrace{i_hk}_{j_h}+a_5a_4\underbrace{i_hh}_{-i}+a_5^2\underbrace{i_h^2}_{-1}+a_5a_6\underbrace{i_hj_h}_{-k}+a_5a_7\underbrace{i_hk_h}_{j} \\
&\quad +a_6a_1\underbrace{j_hi}_{k_h}+a_6a_2\underbrace{j_hj}_{h}+a_6a_3\underbrace{j_hk}_{-i_h}+a_6a_4\underbrace{j_hh}_{-j}+a_6a_5\underbrace{j_hi_h}_{k}+a_6^2\underbrace{j_h^2}_{-1}+a_6a_7\underbrace{j_hk_h}_{-i} \\
&\quad +a_7a_1\underbrace{k_hi}_{-j_h}+a_7a_2\underbrace{k_hj}_{i_h}+a_7a_3\underbrace{k_hk}_{h}+a_7a_4\underbrace{k_hh}_{-k}+a_7a_5\underbrace{k_hi_h}_{-j}+a_7a_6\underbrace{k_hj_h}_{i}+a_7^2\underbrace{k_h^2}_{-1} \\
&=-(a_1^2+a_2^2+a_3^2+a_4^2+a_5^2+a_6^2+a_7^2) \\
\end{align}
```

## 二乗（実部＋虚部）

積（実部＋虚部）との比較で見れば、虚部にはベクトルのスカラー倍が表れていると解釈できます。

```math
\begin{align}
&(a_0+a_1i+a_2j+a_3k+a_4h+a_5i_h+a_6j_h+a_7k_h)^2 \\
&=a_0(a_0+a_1i+a_2j+a_3k+a_4h+a_5i_h+a_6j_h+a_7k_h) \\
&\quad +a_1i(a_0+a_1i+a_2j+a_3k+a_4h+a_5i_h+a_6j_h+a_7k_h) \\
&\quad +a_2j(a_0+a_1i+a_2j+a_3k+a_4h+a_5i_h+a_6j_h+a_7k_h) \\
&\quad +a_3k(a_0+a_1i+a_2j+a_3k+a_4h+a_5i_h+a_6j_h+a_7k_h) \\
&\quad +a_4h(a_0+a_1i+a_2j+a_3k+a_4h+a_5i_h+a_6j_h+a_7k_h) \\
&\quad +a_5i_h(a_0+a_1i+a_2j+a_3k+a_4h+a_5i_h+a_6j_h+a_7k_h) \\
&\quad +a_6j_h(a_0+a_1i+a_2j+a_3k+a_4h+a_5i_h+a_6j_h+a_7k_h) \\
&\quad +a_7k_h(a_0+a_1i+a_2j+a_3k+a_4h+a_5i_h+a_6j_h+a_7k_h) \\
&=a_0^2+a_0a_1i+a_0a_2j+a_0a_3k+a_0a_4h+a_0a_5i_h+a_0a_6j_h+a_0a_7k_h \\
&\quad +a_1a_0i+a_1^2\underbrace{i^2}_{-1}+a_1a_2\underbrace{ij}_{k}+a_1a_3\underbrace{ik}_{-j}+a_1a_4\underbrace{ih}_{i_h}+a_1a_5\underbrace{ii_h}_{-h}+a_1a_6\underbrace{ij_h}_{-k_h}+a_1a_7\underbrace{ik_h}_{j_h} \\
&\quad +a_2a_0j+a_2a_1\underbrace{ji}_{-k}+a_2^2\underbrace{j^2}_{-1}+a_2a_3\underbrace{jk}_{i}+a_2a_4\underbrace{jh}_{j_h}+a_2a_5\underbrace{ji_h}_{k_h}+a_2a_6\underbrace{jj_h}_{-h}+a_2a_7\underbrace{jk_h}_{-i_h} \\
&\quad +a_3a_0k+a_3a_1\underbrace{ki}_{j}+a_3a_2\underbrace{kj}_{-i}+a_3^2\underbrace{k^2}_{-1}+a_3a_4\underbrace{kh}_{k_h}+a_3a_5\underbrace{ki_h}_{-j_h}+a_3a_6\underbrace{kj_h}_{i_h}+a_3a_7\underbrace{kk_h}_{-h} \\
&\quad +a_4a_0h+a_4a_1\underbrace{hi}_{-i_h}+a_4a_2\underbrace{hj}_{-j_h}+a_4a_3\underbrace{hk}_{-k_h}+a_4^2\underbrace{h^2}_{-1}+a_4a_5\underbrace{hi_h}_{i}+a_4a_6\underbrace{hj_h}_{j}+a_4a_7\underbrace{hk_h}_{k} \\
&\quad +a_5a_0i_h+a_5a_1\underbrace{i_hi}_{h}+a_5a_2\underbrace{i_hj}_{-k_h}+a_5a_3\underbrace{i_hk}_{j_h}+a_5a_4\underbrace{i_hh}_{-i}+a_5^2\underbrace{i_h^2}_{-1}+a_5a_6\underbrace{i_hj_h}_{-k}+a_5a_7\underbrace{i_hk_h}_{j} \\
&\quad +a_6a_0j_h+a_6a_1\underbrace{j_hi}_{k_h}+a_6a_2\underbrace{j_hj}_{h}+a_6a_3\underbrace{j_hk}_{-i_h}+a_6a_4\underbrace{j_hh}_{-j}+a_6a_5\underbrace{j_hi_h}_{k}+a_6^2\underbrace{j_h^2}_{-1}+a_6a_7\underbrace{j_hk_h}_{-i} \\
&\quad +a_7a_0k_h+a_7a_1\underbrace{k_hi}_{-j_h}+a_7a_2\underbrace{k_hj}_{i_h}+a_7a_3\underbrace{k_hk}_{h}+a_7a_4\underbrace{k_hh}_{-k}+a_7a_5\underbrace{k_hi_h}_{-j}+a_7a_6\underbrace{k_hj_h}_{i}+a_7^2\underbrace{k_h^2}_{-1} \\
&=(a_0^2-a_1^2-a_2^2-a_3^2-a_4^2-a_5^2-a_6^2-a_7^2) \\
&\quad +2a_0a_1i+2a_0a_2j+2a_0a_3k+2a_0a_4h+2a_0a_5i_h+2a_0a_6j_h+2a_0a_7k_h \\
\end{align}
```

## ノルムの二乗

ノルムだけ見れば、実部を含めてユークリッド空間の8次元ベクトルとして扱えます。

```math
\begin{align}
&(a_0-a_1i-a_2j-a_3k-a_4h-a_5i_h-a_6j_h-a_7k_h)(a_0+a_1i+a_2j+a_3k+a_4h+a_5i_h+a_6j_h+a_7k_h) \\
&=a_0(a_0+a_1i+a_2j+a_3k+a_4h+a_5i_h+a_6j_h+a_7k_h) \\
&\quad -a_1i(a_0+a_1i+a_2j+a_3k+a_4h+a_5i_h+a_6j_h+a_7k_h) \\
&\quad -a_2j(a_0+a_1i+a_2j+a_3k+a_4h+a_5i_h+a_6j_h+a_7k_h) \\
&\quad -a_3k(a_0+a_1i+a_2j+a_3k+a_4h+a_5i_h+a_6j_h+a_7k_h) \\
&\quad -a_4h(a_0+a_1i+a_2j+a_3k+a_4h+a_5i_h+a_6j_h+a_7k_h) \\
&\quad -a_5i_h(a_0+a_1i+a_2j+a_3k+a_4h+a_5i_h+a_6j_h+a_7k_h) \\
&\quad -a_6j_h(a_0+a_1i+a_2j+a_3k+a_4h+a_5i_h+a_6j_h+a_7k_h) \\
&\quad -a_7k_h(a_0+a_1i+a_2j+a_3k+a_4h+a_5i_h+a_6j_h+a_7k_h) \\
&=a_0^2+a_0a_1i+a_0a_2j+a_0a_3k+a_0a_4h+a_0a_5i_h+a_0a_6j_h+a_0a_7k_h \\
&\quad -a_1a_0i-a_1^2\underbrace{i^2}_{-1}-a_1a_2\underbrace{ij}_{k}-a_1a_3\underbrace{ik}_{-j}-a_1a_4\underbrace{ih}_{i_h}-a_1a_5\underbrace{ii_h}_{-h}-a_1a_6\underbrace{ij_h}_{-k_h}-a_1a_7\underbrace{ik_h}_{j_h} \\
&\quad -a_2a_0j-a_2a_1\underbrace{ji}_{-k}-a_2^2\underbrace{j^2}_{-1}-a_2a_3\underbrace{jk}_{i}-a_2a_4\underbrace{jh}_{j_h}-a_2a_5\underbrace{ji_h}_{k_h}-a_2a_6\underbrace{jj_h}_{-h}-a_2a_7\underbrace{jk_h}_{-i_h} \\
&\quad -a_3a_0k-a_3a_1\underbrace{ki}_{j}-a_3a_2\underbrace{kj}_{-i}-a_3^2\underbrace{k^2}_{-1}-a_3a_4\underbrace{kh}_{k_h}-a_3a_5\underbrace{ki_h}_{-j_h}-a_3a_6\underbrace{kj_h}_{i_h}-a_3a_7\underbrace{kk_h}_{-h} \\
&\quad -a_4a_0h-a_4a_1\underbrace{hi}_{-i_h}-a_4a_2\underbrace{hj}_{-j_h}-a_4a_3\underbrace{hk}_{-k_h}-a_4^2\underbrace{h^2}_{-1}-a_4a_5\underbrace{hi_h}_{i}-a_4a_6\underbrace{hj_h}_{j}-a_4a_7\underbrace{hk_h}_{k} \\
&\quad -a_5a_0i_h-a_5a_1\underbrace{i_hi}_{h}-a_5a_2\underbrace{i_hj}_{-k_h}-a_5a_3\underbrace{i_hk}_{j_h}-a_5a_4\underbrace{i_hh}_{-i}-a_5^2\underbrace{i_h^2}_{-1}-a_5a_6\underbrace{i_hj_h}_{-k}-a_5a_7\underbrace{i_hk_h}_{j} \\
&\quad -a_6a_0j_h-a_6a_1\underbrace{j_hi}_{k_h}-a_6a_2\underbrace{j_hj}_{h}-a_6a_3\underbrace{j_hk}_{-i_h}-a_6a_4\underbrace{j_hh}_{-j}-a_6a_5\underbrace{j_hi_h}_{k}-a_6^2\underbrace{j_h^2}_{-1}-a_6a_7\underbrace{j_hk_h}_{-i} \\
&\quad -a_7a_0k_h-a_7a_1\underbrace{k_hi}_{-j_h}-a_7a_2\underbrace{k_hj}_{i_h}-a_7a_3\underbrace{k_hk}_{h}-a_7a_4\underbrace{k_hh}_{-k}-a_7a_5\underbrace{k_hi_h}_{-j}-a_7a_6\underbrace{k_hj_h}_{i}-a_7^2\underbrace{k_h^2}_{-1} \\
&=a_0^2+a_1^2+a_2^2+a_3^2+a_4^2+a_5^2+a_6^2+a_7^2 \\
\end{align}
```
