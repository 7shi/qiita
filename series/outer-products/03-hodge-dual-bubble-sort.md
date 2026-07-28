---
coediting: false
comments_count: 0
created_at: '2016-10-31T02:34:53+09:00'
id: f54302058149d07da592
likes_count: 10
private: false
reactions_count: 0
stocks_count: 9
tags:
- name: F#
  versions: []
- name: 数学
  versions: []
- name: 外積代数
  versions: []
- name: クリフォード代数
  versions: []
title: ユークリッド空間のホッジ双対とバブルソート
updated_at: '2018-07-29T12:38:10+09:00'
url: https://qiita.com/7shi/items/f54302058149d07da592
slide: false
---

幾何学積によるバブルソートを応用したホッジ双対の作り方と、内積との関係を紹介します。幾何学積・ウェッジ積やホッジ双対の基本的な扱い方に慣れるのが目的のため、説明をユークリッド空間に限定します。説明した事項をF#で実装しながら、最後にホッジ双対による4次元の内積を求めます。

シリーズの記事です。

1. [多項式の積を計算](http://qiita.com/7shi/items/4fb60dacad46cb8e63b3)
1. [外積と愉快な仲間たち](http://qiita.com/7shi/items/017d2d2c758f76071f23)
1. ユークリッド空間のホッジ双対とバブルソート ← この記事
1. [四元数を作ろう](http://qiita.com/7shi/items/2036e7a739c2a9e04025)
1. [四元数と行列で見る内積と外積の「内」と「外」](http://qiita.com/7shi/items/a80988a32a0d706e9378)
1. [八元数を作ろう](http://qiita.com/7shi/items/b34fe724d36fb7d96456)
1. [八元数の積をプログラムで確認](http://qiita.com/7shi/items/8495b2d6b888e7b8703f)
1. [外積の成分をプログラムで確認](http://qiita.com/7shi/items/02c758c03d2fd7038912)
1. [多元数の積の構成](http://qiita.com/7shi/items/88be5203769e629df243)
1. [十六元数を作ろう](http://qiita.com/7shi/items/989d59d74a505a92c419)

関連するコードをまとめたリポジトリです。

* https://bitbucket.org/7shi/math7

この記事には関連記事があります。

* [クリフォード代数で考えるパウリ行列と双四元数](http://qiita.com/7shi/items/fafe77f9a5ff2f9651ba) 2017.03.25

この記事を読んでクリフォード代数に興味を持った方には、次の記事がお勧めです。

* 【PDF】[クリフォード代数](http://www.geocities.jp/nososnd/field/cliff.pdf)
* 【英語】[Introduction to Clifford Algebra](https://www.av8n.com/physics/clifford-intro.htm)

# 互換

隣接した因子を交換することを**互換**と呼びます。「互いに入れ換える」というニュアンスです。今回考える互換は等価性を保持するため、その意味で「互換性」と通じる点があります。

※ 後で見るように偶奇性だけが問題となります。互換に隣接の制限を掛けない場合もありますが、偶奇性は保持されるため結果は同じです。

普通の掛け算の例です。

```math
a\underbrace{bc}_{互換}d=acbd
```

3因子以上の互換は結合法則を前提とします。ベクトル積は結合法則を満たさないため、互換の対象からは除外します。

ウェッジ積や幾何学積では、互換の際に符号が反転します。

```math
\begin{align}
\vec{a}∧\underbrace{\vec{b}∧\vec{c}}_{-\vec{c}∧\vec{b}}∧\vec{d}&=-\vec{a}∧\vec{c}∧\vec{b}∧\vec{d} \\
\vec{a}\underbrace{\vec{b}\vec{c}}_{-\vec{c}\vec{b}}\vec{d}&=-\vec{a}\vec{c}\vec{b}\vec{d}
\end{align}
```

## ゼロ

ウェッジ積の連結の中で同じ基底が表れたものはゼロになります。

```math
\underbrace{\vec{e_1}∧\vec{e_1}}_{0}∧\vec{e_2}=0
```

位置が離れていても互換を繰り返せば、横隣りになってゼロになります。

```math
\begin{align}
\vec{e_1}∧\underbrace{\vec{e_3}∧\vec{e_1}}_{-\vec{e_1}∧\vec{e_3}}&=-\underbrace{\vec{e_1}∧\vec{e_1}}_{0}∧\vec{e_3}=0
\end{align}
```

ウェッジ積では、同じ基底が含まれていれば互換を飛ばして即ゼロになると考えても問題ありません。しかし幾何学積や四元数のように同じ基底同士の積がゼロにならないものでは、きちんと互換を追う必要があります。

```math
\begin{align}
\vec{e_1}\underbrace{\vec{e_2}\vec{e_1}}_{-\vec{e_1}\vec{e_2}}\vec{e_2}&=-\underbrace{\vec{e_1}\vec{e_1}}_{1}\underbrace{\vec{e_2}\vec{e_2}}_{1}=-1 \\
i\underbrace{ji}_{-ij}j&=-\underbrace{ii}_{-1}\underbrace{jj}_{-1}=-1
\end{align}
```

# 幾何学積

幾何学積を使えばホッジ双対が簡単に導出できます。そのために必要な幾何学積の性質について説明します。

## ソート

互換により基底をソートできます。互換の回数に応じて符号が決まります。

```math
\vec{e_2}\underbrace{\vec{e_3}\vec{e_1}}_{-\vec{e_1}\vec{e_3}}=-\underbrace{\vec{e_2}\vec{e_1}}_{-\vec{e_1}\vec{e_2}}\vec{e_3}=\vec{e_1}\vec{e_2}\vec{e_3}
```

符号を除けばバブルソートと同じです。詳細は次の記事の前半を参照してください。

* [Haskellでバブルソート](http://qiita.com/7shi/items/1e2a66bf8e8c7f0bd70f) 2014.09.18

※ 後半のHaskellでの実装は飛ばしても構いません。

手計算の場合、ソートの過程で同じ基底が隣接すれば、その場で $1$ にした方が簡単でしょう。

### 実装

[Math7.Exterior.fsx](https://bitbucket.org/7shi/math7/src/tip/Math7.Exterior.fsx) から引用します。[Math7.fsx](https://bitbucket.org/7shi/math7/src/tip/Math7.fsx) と [Math7.Term.fsx](https://bitbucket.org/7shi/math7/src/tip/Math7.Term.fsx) に依存しています。全体は[リポジトリ](https://bitbucket.org/7shi/math7)を参照してください。

バブルソートをF#で実装します。符号を決めるため互換の回数を数えます。

```fsharp
let bsortE xs =
    let rec bswap n = function
        | []    -> n, []
        | x::xs ->
            match bswap n xs with
            | n, [] -> n, [x]
            | n, y::ys when x > y -> n + 1, y::x::ys
            | n, y::ys            -> n    , x::y::ys
    let rec bsort n xs =
        match bswap n xs with
        | n, []    -> n, []
        | n, y::ys -> let n, ys = bsort n ys
                      n, y::ys
    bsort 0 xs

let e = [3; 2; 1]
let n, es = bsortE e
printfn "%A -> %d, %A" e n es
```
```text:出力結果
[3; 2; 1] -> 3, [1; 2; 3]
```

回数に応じて符号を変えれば実装は完了です。

```fsharp
let sort (t:term) =
    let n, e = bsortE t.E
    let s = if n % 2 = 0 then 1 else -1
    term(s * t.N, t.A, e)

let t = Term.fromE [3; 2; 1]
printfn @"%s \to %s" (str t) (sort t |> str)
```
```math
\vec{e_3}∧\vec{e_2}∧\vec{e_1} \to -\vec{e_1}∧\vec{e_2}∧\vec{e_3}
```

## 逆元

変数 $a$ に掛けて $1$ になる変数を $a^{-1}$ と表記して逆元と呼びます。

```math
aa^{-1}=a^{-1}a=1
```

幾何学積では同じ基底同士を計算すれば $1$ になることから、基底の逆元は自分自身です。

```math
\begin{align}
&\vec{e_1}\vec{e_1}=1 \\
&∴ (\vec{e_1})^{-1}=\vec{e_1}
\end{align}
```

複数の基底が連結されていれば、逆に並べたものが逆元となります。逆元とは交換するため左右どちらから掛けても構いません。

```math
\begin{align}
&(\vec{e_3}\vec{e_2}\vec{e_1})(\vec{e_1}\vec{e_2}\vec{e_3})=1 \\
&(\vec{e_1}\vec{e_2}\vec{e_3})(\vec{e_3}\vec{e_2}\vec{e_1})=1 \\
&∴ (\vec{e_1}\vec{e_2}\vec{e_3})^{-1}=\vec{e_3}\vec{e_2}\vec{e_1}
\end{align}
```

マイナスが付いていれば、逆元にもマイナスを付けることで相殺します。

```math
\begin{align}
&(-\vec{e_1}\vec{e_2}\vec{e_3})(-\vec{e_3}\vec{e_2}\vec{e_1})=1 \\
&∴ (-\vec{e_1}\vec{e_2}\vec{e_3})^{-1}=-\vec{e_3}\vec{e_2}\vec{e_1}
\end{align}
```

### 実装

今回の範囲では係数は符号以外無視できるので、実装は簡単です。

```fsharp
let inv (t:term) = term(t.N, [], List.rev t.E)

let t = Term.fromE [1..3]
printfn @"%s \to %s" (str t) (inv t |> str)
```
```math
\vec{e_1}∧\vec{e_2}∧\vec{e_3} \to \vec{e_3}∧\vec{e_2}∧\vec{e_1}
```

## 虚数

複数の基底を連結した幾何学積を2乗すれば $-1$ になります。同じ基底を隣接させて消すためソートを行います。

```math
\begin{align}
(\vec{e_1}\vec{e_2})^2&=\vec{e_1}\underbrace{\vec{e_2}\vec{e_1}}_{-\vec{e_1}\vec{e_2}}\vec{e_2} \\
&=-\underbrace{\vec{e_1}\vec{e_1}}_{1}\underbrace{\vec{e_2}\vec{e_2}}_{1} \\
&=-1 \\
(\vec{e_1}\vec{e_2}\vec{e_3})^2&=\vec{e_1}\vec{e_2}\underbrace{\vec{e_3}\vec{e_1}}_{-\vec{e_1}\vec{e_3}}\vec{e_2}\vec{e_3} \\
&=-\vec{e_1}\underbrace{\vec{e_2}\vec{e_1}}_{-\vec{e_1}\vec{e_2}}\vec{e_3}\vec{e_2}\vec{e_3} \\
&=\underbrace{\vec{e_1}\vec{e_1}}_{1}\vec{e_2}\underbrace{\vec{e_3}\vec{e_2}}_{-\vec{e_2}\vec{e_3}}\vec{e_3} \\
&=-\underbrace{\vec{e_2}\vec{e_2}}_{1}\underbrace{\vec{e_3}\vec{e_3}}_{1} \\
&=-1
\end{align}
```

※ 隣接させて消すパズルのように捉えるのがコツです。

2乗すれば $-1$ になることから、虚数 $i$ と同一視できます。ただし含まれる基底が異なることから分かるように、2次元と3次元では別々の虚数（四元数の $i,j,k$ のような）のため、ここでは添え字で区別しておきます。

* 2次元 $i_2=\vec{e_1}\vec{e_2}$
* 3次元 $i_3=\vec{e_1}\vec{e_2}\vec{e_3}$

### 実装

隣接した同じ基底を除去する関数 `rmPairE` を実装します。

```fsharp
let rec rmPairE = function
| [] -> []
| x::y::xs when x = y -> rmPairE xs
| x::xs -> x::rmPairE xs

let vecg = Term.vec ""
let e = [1; 1; 1; 2; 3; 3; 4]
printfn @"%s \to %s" (vecg e) (rmPairE e |> vecg)
```
```math
\vec{e_1}\vec{e_1}\vec{e_1}\vec{e_2}\vec{e_3}\vec{e_3}\vec{e_4} \to \vec{e_1}\vec{e_2}\vec{e_4}
```

`sort` と組み合わせれば2乗が計算できます。

```fsharp
let strg = Term.str vecg
printfn @"\begin{align}"
for n = 2 to 10 do
    let e1 = [1..n]
    let e2 = List.append e1 e1 |> Term.fromE
    let e3 = sort e2
    let e4 = term(e3.N, e3.A, rmPairE e3.E)
    printfn @"i_{%d}^2&=%s \\" n (strg e4)
printfn @"\end{align}"
```
```math
\begin{align}
i_{2}^2&=-1 \\
i_{3}^2&=-1 \\
i_{4}^2&=1 \\
i_{5}^2&=1 \\
i_{6}^2&=-1 \\
i_{7}^2&=-1 \\
i_{8}^2&=1 \\
i_{9}^2&=1 \\
i_{10}^2&=-1 \\
\end{align}
```

必ずしもすべての次元で $-1$ にならないことが確認できます。

※ 2乗して $-1$ にならない虚数は続編の[四元数を作ろう](http://qiita.com/7shi/items/2036e7a739c2a9e04025)で扱います。

# ユークリッド空間のホッジ双対

以前の記事では3次元に特化して法線でホッジ双対を説明しましたが、ユークリッド空間でのホッジ双対は以下の性質を満たします。

```math
ξ(\star ξ)=i
```

※ 後で見ますが、右辺は内積が求まるように定義されています。非ユークリッド空間（相対性理論のミンコフスキー空間など）では右辺 $i$ に計量に応じた係数が付きますが、詳細は省略します。

両辺に逆元 $ξ^{-1}$ を掛ければ、ホッジ双対を求める式が得られます。

```math
\begin{align}
\star ξ=ξ^{-1}i
\end{align}
```

5次元で例を示します。係数は符号以外は変化ないため、基底だけを対象とします。

```math
\begin{align}
ξ&=\vec{e_3}\vec{e_2} \\
\star ξ&=ξ^{-1}i_5 \\
&=\vec{e_2}\underbrace{\vec{e_3}\vec{e_1}}_{-\vec{e_1}\vec{e_3}}\vec{e_2}\vec{e_3}\vec{e_4}\vec{e_5} \\
&=-\underbrace{\vec{e_2}\vec{e_1}}_{-\vec{e_1}\vec{e_2}}\vec{e_3}\vec{e_2}\vec{e_3}\vec{e_4}\vec{e_5} \\
&=\vec{e_1}\vec{e_2}\underbrace{\vec{e_3}\vec{e_2}}_{-\vec{e_2}\vec{e_3}}\vec{e_3}\vec{e_4}\vec{e_5} \\
&=-\vec{e_1}\underbrace{\vec{e_2}\vec{e_2}}_{1}\underbrace{\vec{e_3}\vec{e_3}}_{1}\vec{e_4}\vec{e_5} \\
&=-\vec{e_1}\vec{e_4}\vec{e_5}
\end{align}
```

念のため $ξ(\star ξ)=i$ となるか確認します。

```math
ξ(\star ξ)=\vec{e_3}\vec{e_2}(-\vec{e_1}\vec{e_4}\vec{e_5})=\vec{e_1}\vec{e_2}\vec{e_3}\vec{e_4}\vec{e_5}=i_5
```

## 実装

基底を反転して虚数を掛けてソートしてから隣接した同じ基底を除去します。

```fsharp
let hodge n (t:term) =
    let e = List.append (List.rev t.E) [1..n]
    let t = term(t.N, t.A, e) |> sort
    term(t.N, t.A, rmPairE t.E)
```

実例を確認するための関数を実装します。基底の組み合わせを列挙しています。

```fsharp
let testHodge n =
    Math7.prologue (sprintf "## %d次元" n)
    for i = 0 to n do
        for e in Math7.combination n i do
            let t = Term.fromE e
            printfn @"\star(%s)&=%s \\" (str t) (hodge n t |> str)
    Math7.epilogue()
```

※ `combination` の詳細は[組み合わせの列挙](http://qiita.com/7shi/items/b627930944df6495165e)を参照してください。

以下、この関数を使って実例を確認します。余力があれば $ξ(\star ξ)=i$ が成立しているかどうかを確認すれば面白いかもしれません。

## 2次元

```fsharp
Exterior.testHodge 2
```
```math
\begin{align}
\star(1)&=\vec{e_1}∧\vec{e_2} \\
\star(\vec{e_1})&=\vec{e_2} \\
\star(\vec{e_2})&=-\vec{e_1} \\
\star(\vec{e_1}∧\vec{e_2})&=1 \\
\end{align}
```

ベクトルにホッジスターを複数回適用すると、4回で元に戻ります。よく見ると90°ずつの回転になっています。

```math
\begin{align}
\star\vec{e_1}&=\vec{e_2} \\
\star\star\vec{e_1}&=\star\vec{e_2}=-\vec{e_1} \\
\star\star\star\vec{e_1}&=-\star\vec{e_1}=-\vec{e_2} \\
\star\star\star\star\vec{e_1}&=-\star\vec{e_2}=\vec{e_1}
\end{align}
```

## 3次元

```fsharp
Exterior.testHodge 3
```
```math
\begin{align}
\star(1)&=\vec{e_1}∧\vec{e_2}∧\vec{e_3} \\
\star(\vec{e_1})&=\vec{e_2}∧\vec{e_3} \\
\star(\vec{e_2})&=-\vec{e_1}∧\vec{e_3} \\
\star(\vec{e_3})&=\vec{e_1}∧\vec{e_2} \\
\star(\vec{e_1}∧\vec{e_2})&=\vec{e_3} \\
\star(\vec{e_1}∧\vec{e_3})&=-\vec{e_2} \\
\star(\vec{e_2}∧\vec{e_3})&=\vec{e_1} \\
\star(\vec{e_1}∧\vec{e_2}∧\vec{e_3})&=1 \\
\end{align}
```

ベクトルにホッジスターを複数回適用すると、2回で元に戻ります。

```math
\begin{align}
\star\vec{e_1}&=\vec{e_2}\vec{e_3} \\
\star\star\vec{e_1}&=\star(\vec{e_2}\vec{e_3})=\vec{e_1}
\end{align}
```

## 4次元

【注意】ここで示すのはユークリッド空間の4次元です。相対性理論で使う4次元はミンコフスキー空間で内積の定義が異なるため、ホッジ双対も異なります。

```fsharp
Exterior.testHodge 4
```
```math
\begin{align}
\star(1)&=\vec{e_1}∧\vec{e_2}∧\vec{e_3}∧\vec{e_4} \\
\star(\vec{e_1})&=\vec{e_2}∧\vec{e_3}∧\vec{e_4} \\
\star(\vec{e_2})&=-\vec{e_1}∧\vec{e_3}∧\vec{e_4} \\
\star(\vec{e_3})&=\vec{e_1}∧\vec{e_2}∧\vec{e_4} \\
\star(\vec{e_4})&=-\vec{e_1}∧\vec{e_2}∧\vec{e_3} \\
\star(\vec{e_1}∧\vec{e_2})&=\vec{e_3}∧\vec{e_4} \\
\star(\vec{e_1}∧\vec{e_3})&=-\vec{e_2}∧\vec{e_4} \\
\star(\vec{e_1}∧\vec{e_4})&=\vec{e_2}∧\vec{e_3} \\
\star(\vec{e_2}∧\vec{e_3})&=\vec{e_1}∧\vec{e_4} \\
\star(\vec{e_2}∧\vec{e_4})&=-\vec{e_1}∧\vec{e_3} \\
\star(\vec{e_3}∧\vec{e_4})&=\vec{e_1}∧\vec{e_2} \\
\star(\vec{e_1}∧\vec{e_2}∧\vec{e_3})&=\vec{e_4} \\
\star(\vec{e_1}∧\vec{e_2}∧\vec{e_4})&=-\vec{e_3} \\
\star(\vec{e_1}∧\vec{e_3}∧\vec{e_4})&=\vec{e_2} \\
\star(\vec{e_2}∧\vec{e_3}∧\vec{e_4})&=-\vec{e_1} \\
\star(\vec{e_1}∧\vec{e_2}∧\vec{e_3}∧\vec{e_4})&=1 \\
\end{align}
```

ベクトルにホッジスターを複数回適用すると、4回で元に戻ります。

```math
\begin{align}
\star\vec{e_1}&=\vec{e_2}\vec{e_3}\vec{e_4} \\
\star\star\vec{e_1}&=\star(\vec{e_2}\vec{e_3}\vec{e_4})=-\vec{e_1} \\
\star\star\star\vec{e_1}&=-\star\vec{e_1}=-\vec{e_2}\vec{e_3}\vec{e_4} \\
\star\star\star\star\vec{e_1}&=-\star(\vec{e_2}\vec{e_3}\vec{e_4})=\vec{e_1}
\end{align}
```

# 内積

ベクトルと、ベクトルのホッジ双対とのウェッジ積は、内積のホッジ双対となります。

```math
\vec{a}∧\star\vec{b}=\star(\vec{a}\cdot\vec{b})
```

$ξ(\star ξ)=i$ をベクトルに拡張した形です。ベクトルが複数の基底の和で構成されていれば、その幾何学積には外積まで含まれます。それを消すため幾何学積ではなくウェッジ積を使います。ホッジ双対の絡まないウェッジ積では内積の方が消えますが、それと逆の結果になっています。後の計算例を見て確認してください。

※ ホッジ双対の性質を示すことが狙いのため、幾何学積の定数項として得られる内積との使い分けは追求しません。

## 擬スカラー

ベクトルのホッジ双対を擬ベクトルと呼んだように、スカラーのホッジ双対を**擬スカラー**と呼びます。

$\vec{a}∧\star\vec{b}=\star(\vec{a}\cdot\vec{b})$ の右辺が見た目で擬スカラーと分かりますし、イコールなので左辺も擬スカラーとなります。

## 実装

ホッジ双対による内積の計算過程を生成する関数を実装します。

```fsharp
let showProd title n =
    Math7.prologue title
    printfn @"&\vec{a}∧\star\vec{b} \\"
    let a = [for i in [1..n] -> term(1, [sprintf "a_%d" i], [i])]
    let b = [for i in [1..n] -> term(1, [sprintf "b_%d" i], [i])]
    let sa, sb = strs a |> Term.bracket, strs b |> Term.bracket
    printfn @"&=%s∧\star%s \\" sa sb
    let al = Term.splits a
    let bl = Term.splits b |> List.map (fun (a, e) -> (a, hodge n e))
    printfn @"&=%s∧%s \\" sa (Term.strs2 vec bl |> Term.bracket)
    Term.showProd1 op vec al bl
    let d = Term.showProd2 op vec (Term.fromE >> simplify) al bl
         |> Term.simplify
         |> Term.sort id Term.byIndexSign
    let sp4 = Term.showProd3 vec ((=) 1)
    sp4 d
    d
    |> List.map (fun (e, al) ->
        let h = hodge n e
        term(h.N, @"\star"::h.A, h.E), al)
    |> sp4
    printfn @"&=\star(\vec{a}\cdot\vec{b})"
    Math7.epilogue()
```

以下、この関数を使って実例を確認します。

## 2次元

ホッジ双対は内積が求まるように定義されています。その条件が $ξ(\star ξ)=i$ です。それが分かりやすいように、敢えて $\star ξ$ の符号を分離せずに内積を計算しています。

```fsharp
Exterior.showProd "## 2次元" 2
```
```math
\begin{align}
&\vec{a}∧\star\vec{b} \\
&=(a_1\vec{e_1}+a_2\vec{e_2})∧\star(b_1\vec{e_1}+b_2\vec{e_2}) \\
&=(a_1\vec{e_1}+a_2\vec{e_2})∧\{b_1\vec{e_2}+b_2(-\vec{e_1})\} \\
&=a_1\vec{e_1}∧\{b_1\vec{e_2}+b_2(-\vec{e_1})\} \\
&\quad +a_2\vec{e_2}∧\{b_1\vec{e_2}+b_2(-\vec{e_1})\} \\
&=a_1b_1\vec{e_1}∧\vec{e_2}+a_1b_2\underbrace{\vec{e_1}∧(-\vec{e_1})}_{0} \\
&\quad +a_2b_1\underbrace{\vec{e_2}∧\vec{e_2}}_{0}+a_2b_2\underbrace{\vec{e_2}∧(-\vec{e_1})}_{\vec{e_1}∧\vec{e_2}} \\
&=(a_1b_1+a_2b_2)\vec{e_1}∧\vec{e_2} \\
&=\star(a_1b_1+a_2b_2) \\
&=\star(\vec{a}\cdot\vec{b})
\end{align}
```

ホッジ双対同士の $ξ(\star ξ)$ 以外の組み合わせは同じ基底が含まれるため消えてしまいます。結局 $ξ(\star ξ)=i$ となる基底だけが残り、その係数を足したものが内積になります。

## 3次元

```fsharp
Exterior.showProd "## 3次元" 3
```
```math
\begin{align}
&\vec{a}∧\star\vec{b} \\
&=(a_1\vec{e_1}+a_2\vec{e_2}+a_3\vec{e_3})∧\star(b_1\vec{e_1}+b_2\vec{e_2}+b_3\vec{e_3}) \\
&=(a_1\vec{e_1}+a_2\vec{e_2}+a_3\vec{e_3})∧\{b_1\vec{e_2}∧\vec{e_3}+b_2(-\vec{e_1}∧\vec{e_3})+b_3\vec{e_1}∧\vec{e_2}\} \\
&=a_1\vec{e_1}∧\{b_1\vec{e_2}∧\vec{e_3}+b_2(-\vec{e_1}∧\vec{e_3})+b_3\vec{e_1}∧\vec{e_2}\} \\
&\quad +a_2\vec{e_2}∧\{b_1\vec{e_2}∧\vec{e_3}+b_2(-\vec{e_1}∧\vec{e_3})+b_3\vec{e_1}∧\vec{e_2}\} \\
&\quad +a_3\vec{e_3}∧\{b_1\vec{e_2}∧\vec{e_3}+b_2(-\vec{e_1}∧\vec{e_3})+b_3\vec{e_1}∧\vec{e_2}\} \\
&=a_1b_1\vec{e_1}∧\vec{e_2}∧\vec{e_3}+a_1b_2\underbrace{\vec{e_1}∧(-\vec{e_1}∧\vec{e_3})}_{0}+a_1b_3\underbrace{\vec{e_1}∧\vec{e_1}∧\vec{e_2}}_{0} \\
&\quad +a_2b_1\underbrace{\vec{e_2}∧\vec{e_2}∧\vec{e_3}}_{0}+a_2b_2\underbrace{\vec{e_2}∧(-\vec{e_1}∧\vec{e_3})}_{\vec{e_1}∧\vec{e_2}∧\vec{e_3}}+a_2b_3\underbrace{\vec{e_2}∧\vec{e_1}∧\vec{e_2}}_{0} \\
&\quad +a_3b_1\underbrace{\vec{e_3}∧\vec{e_2}∧\vec{e_3}}_{0}+a_3b_2\underbrace{\vec{e_3}∧(-\vec{e_1}∧\vec{e_3})}_{0}+a_3b_3\underbrace{\vec{e_3}∧\vec{e_1}∧\vec{e_2}}_{\vec{e_1}∧\vec{e_2}∧\vec{e_3}} \\
&=(a_1b_1+a_2b_2+a_3b_3)\vec{e_1}∧\vec{e_2}∧\vec{e_3} \\
&=\star(a_1b_1+a_2b_2+a_3b_3) \\
&=\star(\vec{a}\cdot\vec{b})
\end{align}
```

## 4次元

```fsharp
Exterior.showProd "## 4次元" 4
```
```math
\begin{align}
&\vec{a}∧\star\vec{b} \\
&=(a_1\vec{e_1}+a_2\vec{e_2}+a_3\vec{e_3}+a_4\vec{e_4})∧\star(b_1\vec{e_1}+b_2\vec{e_2}+b_3\vec{e_3}+b_4\vec{e_4}) \\
&=(a_1\vec{e_1}+a_2\vec{e_2}+a_3\vec{e_3}+a_4\vec{e_4})∧\{b_1\vec{e_2}∧\vec{e_3}∧\vec{e_4}+b_2(-\vec{e_1}∧\vec{e_3}∧\vec{e_4})+b_3\vec{e_1}∧\vec{e_2}∧\vec{e_4}+b_4(-\vec{e_1}∧\vec{e_2}∧\vec{e_3})\} \\
&=a_1\vec{e_1}∧\{b_1\vec{e_2}∧\vec{e_3}∧\vec{e_4}+b_2(-\vec{e_1}∧\vec{e_3}∧\vec{e_4})+b_3\vec{e_1}∧\vec{e_2}∧\vec{e_4}+b_4(-\vec{e_1}∧\vec{e_2}∧\vec{e_3})\} \\
&\quad +a_2\vec{e_2}∧\{b_1\vec{e_2}∧\vec{e_3}∧\vec{e_4}+b_2(-\vec{e_1}∧\vec{e_3}∧\vec{e_4})+b_3\vec{e_1}∧\vec{e_2}∧\vec{e_4}+b_4(-\vec{e_1}∧\vec{e_2}∧\vec{e_3})\} \\
&\quad +a_3\vec{e_3}∧\{b_1\vec{e_2}∧\vec{e_3}∧\vec{e_4}+b_2(-\vec{e_1}∧\vec{e_3}∧\vec{e_4})+b_3\vec{e_1}∧\vec{e_2}∧\vec{e_4}+b_4(-\vec{e_1}∧\vec{e_2}∧\vec{e_3})\} \\
&\quad +a_4\vec{e_4}∧\{b_1\vec{e_2}∧\vec{e_3}∧\vec{e_4}+b_2(-\vec{e_1}∧\vec{e_3}∧\vec{e_4})+b_3\vec{e_1}∧\vec{e_2}∧\vec{e_4}+b_4(-\vec{e_1}∧\vec{e_2}∧\vec{e_3})\} \\
&=a_1b_1\vec{e_1}∧\vec{e_2}∧\vec{e_3}∧\vec{e_4}+a_1b_2\underbrace{\vec{e_1}∧(-\vec{e_1}∧\vec{e_3}∧\vec{e_4})}_{0}+a_1b_3\underbrace{\vec{e_1}∧\vec{e_1}∧\vec{e_2}∧\vec{e_4}}_{0}+a_1b_4\underbrace{\vec{e_1}∧(-\vec{e_1}∧\vec{e_2}∧\vec{e_3})}_{0} \\
&\quad +a_2b_1\underbrace{\vec{e_2}∧\vec{e_2}∧\vec{e_3}∧\vec{e_4}}_{0}+a_2b_2\underbrace{\vec{e_2}∧(-\vec{e_1}∧\vec{e_3}∧\vec{e_4})}_{\vec{e_1}∧\vec{e_2}∧\vec{e_3}∧\vec{e_4}}+a_2b_3\underbrace{\vec{e_2}∧\vec{e_1}∧\vec{e_2}∧\vec{e_4}}_{0}+a_2b_4\underbrace{\vec{e_2}∧(-\vec{e_1}∧\vec{e_2}∧\vec{e_3})}_{0} \\
&\quad +a_3b_1\underbrace{\vec{e_3}∧\vec{e_2}∧\vec{e_3}∧\vec{e_4}}_{0}+a_3b_2\underbrace{\vec{e_3}∧(-\vec{e_1}∧\vec{e_3}∧\vec{e_4})}_{0}+a_3b_3\underbrace{\vec{e_3}∧\vec{e_1}∧\vec{e_2}∧\vec{e_4}}_{\vec{e_1}∧\vec{e_2}∧\vec{e_3}∧\vec{e_4}}+a_3b_4\underbrace{\vec{e_3}∧(-\vec{e_1}∧\vec{e_2}∧\vec{e_3})}_{0} \\
&\quad +a_4b_1\underbrace{\vec{e_4}∧\vec{e_2}∧\vec{e_3}∧\vec{e_4}}_{0}+a_4b_2\underbrace{\vec{e_4}∧(-\vec{e_1}∧\vec{e_3}∧\vec{e_4})}_{0}+a_4b_3\underbrace{\vec{e_4}∧\vec{e_1}∧\vec{e_2}∧\vec{e_4}}_{0}+a_4b_4\underbrace{\vec{e_4}∧(-\vec{e_1}∧\vec{e_2}∧\vec{e_3})}_{\vec{e_1}∧\vec{e_2}∧\vec{e_3}∧\vec{e_4}} \\
&=(a_1b_1+a_2b_2+a_3b_3+a_4b_4)\vec{e_1}∧\vec{e_2}∧\vec{e_3}∧\vec{e_4} \\
&=\star(a_1b_1+a_2b_2+a_3b_3+a_4b_4) \\
&=\star(\vec{a}\cdot\vec{b})
\end{align}
```

手計算ではやる気にならないような計算ですが、プログラムではパラメータを変えるだけで生成されるのが面白い所です。

# 参考

* [ホッジ双対 - Wikipedia](https://ja.wikipedia.org/wiki/%E3%83%9B%E3%83%83%E3%82%B8%E5%8F%8C%E5%AF%BE)
