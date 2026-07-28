---
coediting: false
comments_count: 0
created_at: '2016-12-03T15:28:57+09:00'
id: 2036e7a739c2a9e04025
likes_count: 25
private: false
reactions_count: 0
stocks_count: 28
tags:
- name: F#
  versions: []
- name: 数学
  versions: []
- name: 四元数
  versions: []
title: 四元数を作ろう
updated_at: '2020-10-13T21:05:21+09:00'
url: https://qiita.com/7shi/items/2036e7a739c2a9e04025
slide: false
---

四元数の計算規則は複雑に見えます。規則として覚えるのではなく、作り方からのアプローチを紹介します。複素数の知識を前提とします。プログラムで計算を確認しながら進めます。

数を作るという観点から、四元数の定義を一部変えた亜種も紹介します。

* [双複素数（テッサリン）](https://en.wikipedia.org/wiki/Bicomplex_number)
* [分解型複素数（実テッサリン）](https://ja.wikipedia.org/wiki/%E5%88%86%E8%A7%A3%E5%9E%8B%E8%A4%87%E7%B4%A0%E6%95%B0)
* [双曲四元数](https://en.wikipedia.org/wiki/Hyperbolic_quaternion)

シリーズの記事です。

1. [多項式の積を計算](http://qiita.com/7shi/items/4fb60dacad46cb8e63b3)
1. [外積と愉快な仲間たち](http://qiita.com/7shi/items/017d2d2c758f76071f23)
1. [ユークリッド空間のホッジ双対とバブルソート](http://qiita.com/7shi/items/f54302058149d07da592)
1. 四元数を作ろう ← この記事
1. [四元数と行列で見る内積と外積の「内」と「外」](http://qiita.com/7shi/items/a80988a32a0d706e9378)
1. [八元数を作ろう](http://qiita.com/7shi/items/b34fe724d36fb7d96456)
1. [八元数の積をプログラムで確認](http://qiita.com/7shi/items/8495b2d6b888e7b8703f)
1. [外積の成分をプログラムで確認](http://qiita.com/7shi/items/02c758c03d2fd7038912)
1. [多元数の積の構成](http://qiita.com/7shi/items/88be5203769e629df243)
1. [十六元数を作ろう](http://qiita.com/7shi/items/989d59d74a505a92c419)

プログラムは [Math7.Quaternion.fsx](https://github.com/7shi/math7/blob/main/Math7.Quaternion.fsx) から抜粋して引用します。[Math7.fsx](https://github.com/7shi/math7/blob/main/Math7.fsx) など個別の依存ファイルについてはリポジトリを参照してください。

* https://github.com/7shi/math7

この記事には関連記事があります。

* 2017.12.04 [八元数と7次元の外積](http://7shi.hateblo.jp/entry/2017/12/04/235635) ← お勧め
* 2017.03.06 [実ベクトルで考える複素ベクトル](http://qiita.com/7shi/items/4f313cb36cdd12c8d833)
* 2017.03.14 [表現行列で考える双複素数](http://qiita.com/7shi/items/050f6615558c4c2b1d92)
* 2017.03.14 [表現行列で考える四元数](http://qiita.com/7shi/items/e7364e1b2593f24427a5)

# 複素数

$\sqrt{-1}$ を $i$ と表記して虚数と呼びます。

```math
i=\sqrt{-1} \\
i^2=-1
```

実数と虚数の形式的な和を**複素数**と呼びます。複素数は $a,b$ という2つの実数により $a+bi$ と一般化できます。$b$ は $i$ の係数です。

## 積

$i^2=-1$ にだけ注意すれば、通常の代数式と同じです。

```fsharp
let compStr = Seq.map (fun e -> [| ""; "i" |].[e]) >> Term.strPower
let compProd title =
    Term.showProd title "" compStr
        (function
        | [x; y] when x = y -> term -1
        | es -> Term.fromE es)
        id Term.byIndexSign (fun _ -> true)
let ca = [term(1, ["a_0"], []); term(1, ["a_1"], [1])]
let cb = [term(1, ["b_0"], []); term(1, ["b_1"], [1])]
compProd "## 積" ca cb
```
```math
\begin{align}
&(a_0+a_1i)(b_0+b_1i) \\
&=a_0(b_0+b_1i) \\
&\quad +a_1i(b_0+b_1i) \\
&=a_0b_0+a_0b_1i \\
&\quad +a_1b_0i+a_1b_1\underbrace{i^2}_{-1} \\
&=(a_0b_0-a_1b_1) \\
&\quad +(a_0b_1+a_1b_0)i \\
\end{align}
```

※ この計算は平面上の回転を表しますが、詳細は省略します。

## 共役

複素数 $a+bi$ の虚数の符号を反転した $a-bi$ を**共役複素数**（複素共役）と呼びます。

共役は ${}^*$ で表します。

```fsharp
let conj (ts:term list) =
    ts |> List.map (fun t -> if t.E = [] then t else -1 * t)
printfn "(%s)^*=%s" (Term.strs compStr ca) (conj ca |> Term.strs compStr)
```
```math
(a_0+a_1i)^*=a_0-a_1i
```

## 共役との積

共役との積を計算すれば、積の実部が内積、虚部が外積となります。

```math
\underbrace{(a_1+a_2i)^*}_{共役}(b_1+b_2i)
=\underbrace{(a_1b_1+a_2b_2)}_{内積}+\underbrace{(a_1b_2-a_2b_1)}_{外積}i
```

※ 私見ですが、これは複素数と線形代数をつなぐ美しい式だと感心します。

外積はベクトル積ではなくウェッジ積に相当します。複素数が表す $(a_1,a_2)$ と $(b_1,b_2)$ という2本のベクトルが張る平行四辺形の符号付き面積を表します。

### 反交換性

後ろの複素数を共役にすると外積の符号が反転します。これは外積が因子の順番に依存しており、共役を付ける複素数を変えることは、順番を入れ替えることに相当するためです。外積のこのような性質を**反交換性**（順番を**交換**すれば符号が**反**転）と呼びます。

```math
\begin{align}
(a_1+a_2i)\underbrace{(b_1+b_2i)^*}_{後ろが共役}
&=\underbrace{(b_1+b_2i)^*(a_1+a_2i)}_{順番入れ替えに相当} \\
&=(a_1b_1+a_2b_2)\underbrace{-(a_1b_2-a_2b_1)}_{符号反転}i
\end{align}
```

※ 複素数の積は可換のため順番を入れ替えても計算結果は変化しませんが、共役を前に揃えることで順番の入れ替えだと解釈できることを強調しています。

反交換性を利用すれば、計算結果から内積（実部）または外積（虚部）だけを残すことができます。

```math
\begin{align}
\frac{1}{2}\{(a_1+a_2i)^*(b_1+b_2i)+(b_1+b_2i)^*(a_1+a_2i)\}
&=\underbrace{a_1b_1+a_2b_2}_{内積（実部）} \\
\frac{1}{2}\{(a_1+a_2i)^*(b_1+b_2i)-(b_1+b_2i)^*(a_1+a_2i)\}
&=\underbrace{(a_1b_2-a_2b_1)}_{外積（虚部）}i
\end{align}
```

※ 反交換性を意識して、順番の入れ替えを強調するため、共役を前に揃えています。

このテクニックは複素数に限らず、対称成分・反対称成分を分離する方法としてよく用いられます。

### 幾何学積

※ 複素数からははみ出しますが、参考事項として紹介します。

内積・外積が目的であれば、より洗練されたクリフォード代数の幾何学積という計算方法があります。ベクトルと内積（スカラー）と外積（面積）の基底が区別されます。

```math
\underbrace{(a_1\mathbf{e}_1+a_2\mathbf{e}_2)}_{ベクトル}
\underbrace{(b_1\mathbf{e}_1+b_2\mathbf{e}_2)}_{ベクトル}
=\underbrace{(a_1b_1+a_2b_2)}_{内積}
+\underbrace{(a_1b_2-a_2b_1)\mathbf{e}_1\mathbf{e}_2}_{外積} \\
\underbrace{
  (b_1\mathbf{e}_1+b_2\mathbf{e}_2)
  (a_1\mathbf{e}_1+a_2\mathbf{e}_2)}_{交換}
=(a_1b_1+a_2b_2)
\underbrace{-(a_1b_2-a_2b_1)\mathbf{e}_1\mathbf{e}_2}_{符号反転}
```

幾何学積はルールとして反交換性を持っているため、共役を明示する必要がありません。言い換えれば、共役の役割を反交換性に置き替えています。

内積または外積だけを残す計算は以下の通りです。

```math
\begin{align}
\frac{1}{2}\{
  (a_1\mathbf{e}_1+a_2\mathbf{e}_2)(b_1\mathbf{e}_1+b_2\mathbf{e}_2)
 +(b_1\mathbf{e}_1+b_2\mathbf{e}_2)(a_1\mathbf{e}_1+a_2\mathbf{e}_2)\}
&=\underbrace{a_1b_1+a_2b_2}_{内積} \\
\frac{1}{2}\{
  (a_1\mathbf{e}_1+a_2\mathbf{e}_2)(b_1\mathbf{e}_1+b_2\mathbf{e}_2)
 -(b_1\mathbf{e}_1+b_2\mathbf{e}_2)(a_1\mathbf{e}_1+a_2\mathbf{e}_2)\}
&=\underbrace{(a_1b_2-a_2b_1)\mathbf{e}_1\mathbf{e}_2}_{外積}
\end{align}
```

詳細は[外積と愉快な仲間たち](http://qiita.com/7shi/items/017d2d2c758f76071f23)を参照してください。

## ノルム

外積は2本のベクトルが張る面積のため、同一のベクトルでは間の空間がなく外積は0になり、内積だけが残ります。

共役に元の複素数を掛ければ、係数の2乗を足した値が内積として得られます。

```fsharp
compProd "## ノルム" (conj ca) ca
```
```math
\begin{align}
&(a_0-a_1i)(a_0+a_1i) \\
&=a_0(a_0+a_1i) \\
&\quad -a_1i(a_0+a_1i) \\
&=a_0^2+a_0a_1i \\
&\quad -a_1a_0i-a_1^2\underbrace{i^2}_{-1} \\
&=a_0^2+a_1^2 \\
\end{align}
```

ピタゴラスの定理 $a^2+b^2=c^2$ より、上で計算した内積 $a_0^2+a_1^2$ の平方根 $\sqrt{a_0^2+a_1^2}$ は長さを表すと考えられ**ノルム**と呼ばれます。

# ケーリー=ディクソンの構成法

今まで複素数の係数は実数に制限していましたが、これを複素数にすることを考えます。

2つの複素数 $z,w$ を定義します。

```math
\left\{
\begin{align}
z &= a+bi \\
w &= c+di
\end{align}
\right.
```

これを $z+wi$ に入れてみると、結果は複素数に収まります。

```math
\begin{align}
z+wi
&=(a+bi)+(c+di)i \\
&=a+bi+ci-d \\
&=(a-d)+(b+c)i
\end{align}
```

内側（係数）の複素数単位 $i$ と区別するため、外側の複素数単位を $j$ とおいて再度計算します。

```math
\begin{align}
z+wj
&=(a+bi)+(c+di)j \\
&=a+bi+cj+dij
\end{align}
```

$ij$ をまた別の虚数単位 $k$ とすれば、四元数（とその亜種）が得られます。

```math
(a+bi)+(c+di)j=a+bi+cj+dk
```

このように複素数をネスト（入れ子）にして新しい数体系を作り出す方法を**ケーリー=ディクソンの構成法**と呼びます。

## 三元数

【注】三元数がうまく定義できないことについての紹介です。

$i$ とは別に、虚数単位 $j$ を導入します。$j$ は $i$ とは異なる虚数単位ですが、虚数としての共通性から2乗すれば $-1$ になると定義します。

```math
i^2=j^2=-1
```

$i$ と $j$ を使えば三元数 $a+bi+cj$ になりそうです。しかしこのように構成した三元数の積を計算すると、組み合わせから $ij$ が出て来てしまいます。$ij$ は $i$ とも $j$ とも異なり、三元数の枠からはみ出した存在です。

```fsharp
Term.showProd "## 積" ""
    (Seq.map (fun e -> [""; "i"; "j"].[e]) >> Term.strPower)
    (function
    | [x; y] when x = y -> term -1
    | [2; 1] -> term(1, [], [1; 2])
    | es -> Term.fromE es)
    id Term.byIndexSign (fun _ -> true)
    (term(1, ["a_0"], [])::[for i in [1..2] -> term(1, [sprintf "a_%d" i], [i])])
    (term(1, ["b_0"], [])::[for i in [1..2] -> term(1, [sprintf "b_%d" i], [i])])
```
```math
\begin{align}
&(a_0+a_1i+a_2j)(b_0+b_1i+b_2j) \\
&=a_0(b_0+b_1i+b_2j) \\
&\quad +a_1i(b_0+b_1i+b_2j) \\
&\quad +a_2j(b_0+b_1i+b_2j) \\
&=a_0b_0+a_0b_1i+a_0b_2j \\
&\quad +a_1b_0i+a_1b_1\underbrace{i^2}_{-1}+a_1b_2ij \\
&\quad +a_2b_0j+a_2b_1\underbrace{ji}_{ij}+a_2b_2\underbrace{j^2}_{-1} \\
&=(a_0b_0-a_1b_1-a_2b_2) \\
&\quad +(a_0b_1+a_1b_0)i \\
&\quad +(a_1b_2+a_2b_1)ij \\
&\quad +(a_0b_2+a_2b_0)j \\
\end{align}
```

これは三元数の積は三元数で表現できないことを意味しており、「三元数は積について閉じていない」と表現します。

※ $ij=i,\ ji=j$ のようなアドホックな割り付けで無理やり閉じさせても、得られた計算結果には意味がありません。

$ij$ は別の虚数単位で四元数へとつながります。四元数を発見したハミルトンも初めは三元数を研究していましたが、積がうまく定義できずに相当悩んだそうです。そして最終的には三元数は断念して四元数の発見へと至ります。

# 双複素数

【注】四元数ではありませんが、分かりやすさから最初に紹介します。

$i$ とは別に、虚数単位 $j$ を導入します。$j$ は $i$ とは異なる虚数単位ですが、虚数としての共通性から2乗すれば $-1$ になると定義します。

```math
i^2=j^2=-1
```

$i$ と $j$ を使って複素数をネストさせ $ij=k$ とします。（ケーリー=ディクソンの構成法）

```math
\begin{align}
&(a+bi)+(c+di)j \\
&=a+bi+cj+dij \\
&=a+bi+cj+dk
\end{align}
```

$i^2=j^2=-1$ と $ij=k$ から $k^2$ が求まります。

```math
\underbrace{ij=k}_{両辺を2乗} \\
\underbrace{i^2}_{-1}\underbrace{j^2}_{-1}=k^2 \\
k^2=1
```

※ 後で出て来る四元数とは異なり、積は可換です。通常の文字と同じように扱っても大丈夫です。

この結果を受け入れれば、$k$ は2乗すれば $1$ になる虚数だということになります。このようにして構成した数を**双複素数**と呼びます。これはハミルトンが発見した四元数とは別物で、1892年にセグレによって導入されました。

※ この記事では四元数と対応させるため文字の割り当てを $i,j,ij=k$ としていますが、セグレは $h,i,hi$ を使用しました。

ここまでに出て来た関係から、他の組み合わせも導けます。

```math
\begin{align}
j\underbrace{k}_{ij}&=\underbrace{j^2}_{-1}i=-i \\
\underbrace{k}_{ij}i&=\underbrace{i^2}_{-1}j=-j \\
\underbrace{ij}_{k}k&=k^2=1
\end{align}
```

まとめれば次の通りです。

```math
i^2=j^2=-1,\ k^2=1,\ ijk=1 \\
ij=ji=k,\ jk=kj=-i,\ ki=ik=-j
```

## 積

双複素数の積は双複素数で表すことができます。

```fsharp
let ijk = Seq.map (fun e -> [""; "i"; "j"; "k"].[e]) >> Term.strPower
let dcompProdE = function
| [1; 1] | [2; 2] -> term -1            // ii=jj=-1
| [3; 3] -> term.One                    // kk=1
| [1; 2] | [2; 1] -> term( 1, [], [3])  // ij=ji=k
| [2; 3] | [3; 2] -> term(-1, [], [1])  // jk=kj=-i
| [3; 1] | [1; 3] -> term(-1, [], [2])  // ki=ik=-j
| es -> Term.fromE es
let dcompProd title =
    Term.showProd title "" ijk dcompProdE id Term.byIndexSign (fun _ -> true)
let qa = term(1, ["a_0"], [])::[for i in [1..3] -> term(1, [sprintf "a_%d" i], [i])]
let qb = term(1, ["b_0"], [])::[for i in [1..3] -> term(1, [sprintf "b_%d" i], [i])]
dcompProd "## 積" qa qb
```
```math
\begin{align}
&(a_0+a_1i+a_2j+a_3k)(b_0+b_1i+b_2j+b_3k) \\
&=a_0(b_0+b_1i+b_2j+b_3k) \\
&\quad +a_1i(b_0+b_1i+b_2j+b_3k) \\
&\quad +a_2j(b_0+b_1i+b_2j+b_3k) \\
&\quad +a_3k(b_0+b_1i+b_2j+b_3k) \\
&=a_0b_0+a_0b_1i+a_0b_2j+a_0b_3k \\
&\quad +a_1b_0i+a_1b_1\underbrace{i^2}_{-1}+a_1b_2\underbrace{ij}_{k}+a_1b_3\underbrace{ik}_{-j} \\
&\quad +a_2b_0j+a_2b_1\underbrace{ji}_{k}+a_2b_2\underbrace{j^2}_{-1}+a_2b_3\underbrace{jk}_{-i} \\
&\quad +a_3b_0k+a_3b_1\underbrace{ki}_{-j}+a_3b_2\underbrace{kj}_{-i}+a_3b_3\underbrace{k^2}_{1} \\
&=(a_0b_0-a_1b_1-a_2b_2+a_3b_3) \\
&\quad +(a_0b_1+a_1b_0-a_2b_3-a_3b_2)i \\
&\quad +(a_0b_2+a_2b_0-a_1b_3-a_3b_1)j \\
&\quad +(a_0b_3+a_3b_0+a_1b_2+a_2b_1)k \\
\end{align}
```

## 共役

ケーリー=ディクソン構成では係数の $i$ とそれを包む $j$ とで2重に複素数がありますが、その両方で共役を取ります。

```math
(a-bi)-(c-di)j=a-bi-cj+dk
```

※ 次の節で見ますが、このように定義すればノルムの2乗の実部が内積になります。表現行列を考えることでこの定義の由来が分かりますが、詳細は以下の記事を参照してください。

* [表現行列で考える双複素数](http://qiita.com/7shi/items/050f6615558c4c2b1d92) 2017.03.14

結果だけ見れば $i$ と $j$ の符号が反転しているので、そのように実装します。

```fsharp
let dcompConj (ts:term list) =
    ts |> List.map (fun t -> match t.E with [1] | [2] -> -1 * t | _ -> t)
printfn "(%s)^*=%s" (Term.strs ijk qa) (dcompConj qa |> Term.strs ijk)
```
```math
(a_0+a_1i+a_2j+a_3k)^*=a_0-a_1i-a_2j+a_3k
```

※ [Wikipedia](https://en.wikipedia.org/wiki/bicomplex_number)では共役の定義が異なり、外側を包む $j$ しか符号を反転しません。

* Wikipedia: $(a+bi)-(c+di)j=a+bi-cj-dk$

## ノルム

共役との積でノルムの2乗を計算します。

```fsharp
dcompProd "## ノルム" (dcompConj qa) qa
```
```math
\begin{align}
&(a_0-a_1i-a_2j+a_3k)(a_0+a_1i+a_2j+a_3k) \\
&=a_0(a_0+a_1i+a_2j+a_3k) \\
&\quad -a_1i(a_0+a_1i+a_2j+a_3k) \\
&\quad -a_2j(a_0+a_1i+a_2j+a_3k) \\
&\quad +a_3k(a_0+a_1i+a_2j+a_3k) \\
&=a_0^2+a_0a_1i+a_0a_2j+a_0a_3k \\
&\quad -a_1a_0i-a_1^2\underbrace{i^2}_{-1}-a_1a_2\underbrace{ij}_{k}-a_1a_3\underbrace{ik}_{-j} \\
&\quad -a_2a_0j-a_2a_1\underbrace{ji}_{k}-a_2^2\underbrace{j^2}_{-1}-a_2a_3\underbrace{jk}_{-i} \\
&\quad +a_3a_0k+a_3a_1\underbrace{ki}_{-j}+a_3a_2\underbrace{kj}_{-i}+a_3^2\underbrace{k^2}_{1} \\
&=(a_0^2+a_1^2+a_2^2+a_3^2) \\
&\quad +2(a_0a_3-a_1a_2)k \\
\end{align}
```

他の数ではノルムの2乗は実数ですが、双複素数では虚数 $i$ が残ります。実部だけを見ればユークリッドノルムです。

共役の作り方を変えてみても、実数だけにすることはできません。

```fsharp
let showProd f g a b =
    let sa = Term.strs f a |> Term.bracket
    let sb = Term.strs f b |> Term.bracket
    if sa = sb then printf @"&%s^2=" sa else printf @"&%s%s=" sa sb
    let d =
        Term.prods g a b
        |> Term.simplify
        |> Term.sort id Term.byIndexSign
    d |> List.iteri (fun i d1 ->
        let s = Term.str3 f d1
        let s = if d.Length = 1 then Term.unbracket s else s
        printf "%s" <| if i = 0 then s else Term.addSign s)
    printfn @" \\"
for x in [1; -1] do
    for y in [1; -1] do
        for z in [1; -1] do
            let a = [term(1, ["a_0"], [ ])
                     term(x, ["a_1"], [1])
                     term(y, ["a_2"], [2])
                     term(z, ["a_3"], [3])]
            showProd ijk dcompProdE a qa
```
```math
\begin{align}
&(a_0+a_1i+a_2j+a_3k)^2=(a_0^2-a_1^2-a_2^2+a_3^2)+2(a_0a_1-a_2a_3)i+2(a_0a_2-a_1a_3)j+2(a_0a_3+a_1a_2)k \\
&(a_0+a_1i+a_2j-a_3k)(a_0+a_1i+a_2j+a_3k)=(a_0^2-a_1^2-a_2^2-a_3^2)+2a_0a_1i+2a_0a_2j+2a_1a_2k \\
&(a_0+a_1i-a_2j+a_3k)(a_0+a_1i+a_2j+a_3k)=(a_0^2-a_1^2+a_2^2+a_3^2)+2a_0a_1i-2a_1a_3j+2a_0a_3k \\
&(a_0+a_1i-a_2j-a_3k)(a_0+a_1i+a_2j+a_3k)=(a_0^2-a_1^2+a_2^2-a_3^2)+2(a_0a_1+a_2a_3)i \\
&(a_0-a_1i+a_2j+a_3k)(a_0+a_1i+a_2j+a_3k)=(a_0^2+a_1^2-a_2^2+a_3^2)-2a_2a_3i+2a_0a_2j+2a_0a_3k \\
&(a_0-a_1i+a_2j-a_3k)(a_0+a_1i+a_2j+a_3k)=(a_0^2+a_1^2-a_2^2-a_3^2)+2(a_0a_2+a_1a_3)j \\
&(a_0-a_1i-a_2j+a_3k)(a_0+a_1i+a_2j+a_3k)=(a_0^2+a_1^2+a_2^2+a_3^2)+2(a_0a_3-a_1a_2)k \\
&(a_0-a_1i-a_2j-a_3k)(a_0+a_1i+a_2j+a_3k)=(a_0^2+a_1^2+a_2^2-a_3^2)+2a_2a_3i+2a_1a_3j-2a_1a_2k \\
\end{align}
```

こういう手計算だと手間が掛かることでも簡単に確認できるのがプログラムの良い所です。

## テッサリン

双複素数の亜種で、数学的には同型（できることは同じ）です。

双複素数では $i^2=j^2=-1$ と定義しましたが、$j$ より先に $k$ について $i^2=k^2=-1$ と定義したのが**テッサリン**です。歴史的には双複素数より先で、1848年にコックルによって導入されました。

$i^2=k^2=-1$ と $ij=k$ から $j^2$ が求まります。

```math
\underbrace{ij=k}_{両辺を2乗} \\
\underbrace{i^2}_{-1}j^2=\underbrace{k^2}_{-1} \\
j^2=1
```

ここまでに出て来た関係から、他の組み合わせも導けます。

```math
\begin{align}
j\underbrace{k}_{ij}&=\underbrace{j^2}_{1}i=i \\
\underbrace{k}_{ij}i&=\underbrace{i^2}_{-1}j=-j \\
\underbrace{ij}_{k}k&=k^2=-1
\end{align}
```

まとめれば次の通りです。

```math
i^2=k^2=-1,\ j^2=1,\ ijk=-1 \\
ij=ji=k,\ jk=kj=i,\ ki=ik=-j
```

このような定義にした理由は以下の2つではないかと推測します。

1. 元 $1,i,j,k$ をそれぞれ2乗すれば $1,-1,1,-1$ となる。これは $1,-1$ の繰り返しで、$1,i$ と $j,k$ を対として見なせる。
2. 可換であることを除いては $ijk=-1,ij=k,jk=i$ など四元数に似ている。

### 双複素数との対応関係

テッサリンを小文字（$ijk$）、双複素数を大文字（$IJK$）で示します。

```math
i=I,j=K,k=-J \\
i^2=I^2=-1,j^2=K^2=1,k^2=(-J)^2=-1,ijk=-IKJ=-IIJJ=-1 \\
ij=IK=IIJ=-J=k,jk=-KJ=-IJJ=I=i,ki=-JI=-K=-j
```

ケーリー=ディクソン構成と共役の対応関係は次の通りです。

```math
(a+bI)+(c+dI)J=(a+bi)+(d-ci)j=a+bi+dj-ck \\
(a-bI)-(c-dI)J=(a-bi)+(d+ci)j=a-bi+dj+ck
```

### 積とノルム

積とノルムを確認します。

```fsharp
let tessProdE = function
| [1; 1] | [3; 3] -> term -1            // ii=kk=-1
| [2; 2] -> term.One                    // jj=1
| [1; 2] | [2; 1] -> term( 1, [], [3])  // ij=ji=k
| [2; 3] | [3; 2] -> term( 1, [], [1])  // jk=kj=i
| [3; 1] | [1; 3] -> term(-1, [], [2])  // ki=ik=-j
| es -> Term.fromE es
let tessProd title =
    Term.showProd title "" ijk tessProdE id Term.byIndexSign (fun _ -> true)
tessProd "## 積" qa qb
```
```math
\begin{align}
&(a_0+a_1i+a_2j+a_3k)(b_0+b_1i+b_2j+b_3k) \\
&=a_0(b_0+b_1i+b_2j+b_3k) \\
&\quad +a_1i(b_0+b_1i+b_2j+b_3k) \\
&\quad +a_2j(b_0+b_1i+b_2j+b_3k) \\
&\quad +a_3k(b_0+b_1i+b_2j+b_3k) \\
&=a_0b_0+a_0b_1i+a_0b_2j+a_0b_3k \\
&\quad +a_1b_0i+a_1b_1\underbrace{i^2}_{-1}+a_1b_2\underbrace{ij}_{k}+a_1b_3\underbrace{ik}_{-j} \\
&\quad +a_2b_0j+a_2b_1\underbrace{ji}_{k}+a_2b_2\underbrace{j^2}_{1}+a_2b_3\underbrace{jk}_{i} \\
&\quad +a_3b_0k+a_3b_1\underbrace{ki}_{-j}+a_3b_2\underbrace{kj}_{i}+a_3b_3\underbrace{k^2}_{-1} \\
&=(a_0b_0-a_1b_1+a_2b_2-a_3b_3) \\
&\quad +(a_0b_1+a_1b_0+a_2b_3+a_3b_2)i \\
&\quad +(a_0b_2+a_2b_0-a_1b_3-a_3b_1)j \\
&\quad +(a_0b_3+a_3b_0+a_1b_2+a_2b_1)k \\
\end{align}
```

```fsharp
let tessConj (ts:term list) =
    ts |> List.map (fun t -> match t.E with [1] | [3] -> -1 * t | _ -> t)
tessProd "## ノルム" (tessConj qa) qa
```
```math
\begin{align}
&(a_0-a_1i+a_2j-a_3k)(a_0+a_1i+a_2j+a_3k) \\
&=a_0(a_0+a_1i+a_2j+a_3k) \\
&\quad -a_1i(a_0+a_1i+a_2j+a_3k) \\
&\quad +a_2j(a_0+a_1i+a_2j+a_3k) \\
&\quad -a_3k(a_0+a_1i+a_2j+a_3k) \\
&=a_0^2+a_0a_1i+a_0a_2j+a_0a_3k \\
&\quad -a_1a_0i-a_1^2\underbrace{i^2}_{-1}-a_1a_2\underbrace{ij}_{k}-a_1a_3\underbrace{ik}_{-j} \\
&\quad +a_2a_0j+a_2a_1\underbrace{ji}_{k}+a_2^2\underbrace{j^2}_{1}+a_2a_3\underbrace{jk}_{i} \\
&\quad -a_3a_0k-a_3a_1\underbrace{ki}_{-j}-a_3a_2\underbrace{kj}_{i}-a_3^2\underbrace{k^2}_{-1} \\
&=(a_0^2+a_1^2+a_2^2+a_3^2) \\
&\quad +2(a_0a_2+a_1a_3)j \\
\end{align}
```

双複素数と同様に実部はユークリッドノルムで、虚部が残ります。

## 可換四元数

双複素数やテッサリンは四元数と同じ記号 $i,j,k$ を使っていることから**可換四元数**と呼ばれることがあります。

※ 後で見ますが、四元数では交換法則が成り立たない（非可換）ことと対比した名称です。

次の論文ではテッサリンを可換四元数と呼んでいます。

* [Commutative Quaternion Matrices](https://arxiv.org/abs/1306.6009)

少し違う定義で再発明されることもあるようですが、これも同型です。

* [Commutative Quaternion](http://xelf.info/knowledge/quaternion.html)

## 資料

双複素数やテッサリンはあまり研究が進んでいませんが、いくつか紹介します。

### 無料

東北数学雑誌に掲載された双複素数の論文です。

* [Contributions to the theory of functions of a bicomplex variable](https://projecteuclid.org/euclid.tmj/1178245302)

テッサリンをデジタル信号処理に使う研究があります。

* 【PDF】 [On Families of 2^N-dimensional Hypercomplex Algebras Suitable for Digital Signal Processing](http://www.eurasip.org/Proceedings/Eusipco/Eusipco2006/papers/1568981962.pdf)
* [On Hyperbolic Complex LTI Digital Systems](https://www.researchgate.net/publication/228565818_On_hyperbolic_complex_LTI_digital_systems)

### 有料

双複素数を特殊相対論に使う研究があります。

* [A Commutative Hypercomplex Algebra with Associated Function Theory](http://link.springer.com/chapter/10.1007%2F978-1-4615-8157-4_14)（[プレビュー](https://books.google.co.jp/books?id=UqbwBwAAQBAJ&lpg=PP1&hl=ja&pg=PA213#v=onepage&q&f=false)）
* [The Mathematics of Minkowski Space-Time: With an Introduction to Commutative Hypercomplex Numbers](http://link.springer.com/book/10.1007%2F978-3-7643-8614-6)
    * 目次を見る限りでは、双複素数をベースにN次元に一般化しているようです。同著者による関連論文もありますが有料です。
    * [Commutative hypercomplex numbers and functions of hypercomplex variable: a matrix study](http://link.springer.com/article/10.1007/s00006-005-0011-2)

ニューラルネットワークに使う研究があります。有料記事のため詳細は不明ですが、[複素ニューラルネットワーク](https://staff.aist.go.jp/tohru-nitta/jCNN.html)の応用だと思われます。

* [CiNii 論文 -  可換クォータニオンに基づく多値ホップフィールドニューラルネットワーク(知的システム,一般)](http://ci.nii.ac.jp/naid/110008800912)

# 分解型複素数

テッサリンから $j$ だけを残したのが**分解型複素数**です。

```math
a+bj\quad(j^2=1)
```

テッサリンの亜種として**実テッサリン**と呼ばれることもあります。それ以外にも**双曲複素数**など多くの別称があります。興味があれば[Wikipedia](https://ja.wikipedia.org/wiki/%E5%88%86%E8%A7%A3%E5%9E%8B%E8%A4%87%E7%B4%A0%E6%95%B0#.E5.88.A5.E7.A7.B0)を参照してください。

## 積

積が閉じていることを確認します。プログラムはテッサリンの関数が流用できます。

```fsharp
let spca = [term(1, ["a_0"], []); term(1, ["a_1"], [2])]
let spcb = [term(1, ["b_0"], []); term(1, ["b_1"], [2])]
tessProd "## 積" spca spcb
```
```math
\begin{align}
&(a_0+a_1j)(b_0+b_1j) \\
&=a_0(b_0+b_1j) \\
&\quad +a_1j(b_0+b_1j) \\
&=a_0b_0+a_0b_1j \\
&\quad +a_1b_0j+a_1b_1\underbrace{j^2}_{1} \\
&=(a_0b_0+a_1b_1) \\
&\quad +(a_0b_1+a_1b_0)j \\
\end{align}
```

## 共役

共役は虚部の符号反転です。

```math
(a+bj)^*=a-bj
```

## ノルム

共役との積でノルムの2乗を求めます。

```fsharp
tessProd "## ノルム" (dcompConj spca) spca
```
```math
\begin{align}
&(a_0-a_1j)(a_0+a_1j) \\
&=a_0(a_0+a_1j) \\
&\quad -a_1j(a_0+a_1j) \\
&=a_0^2+a_0a_1j \\
&\quad -a_1a_0j-a_1^2\underbrace{j^2}_{1} \\
&=a_0^2-a_1^2 \\
\end{align}
```

これは $(+,−)$ 型のミンコフスキーノルムです。このようにノルムの符号が真ん中で別れることが**分解型**と呼ばれる由来です。空間を1次元に制限したローレンツ変換などに使われたようです。

# 四元数

この節では、1843年にハミルトンが発見した通常の四元数を紹介します。何年もの研究の末、ダブリンのブルーム橋を渡っているときに閃いたという逸話があります。

$i$ と $j$ を使って複素数をネストさせ $ij=k$ とします。（ケーリー=ディクソンの構成法）

```math
\begin{align}
&(a+bi)+(c+di)j \\
&=a+bi+cj+dij \\
&=a+bi+cj+dk
\end{align}
```

$i,j,k$ を対等な虚数とするため $i^2=j^2=k^2=-1$ と定義します。

定義から $ijk=kk=-1$ となります。

## 反交換性

双複素数では $k^2=1$ ですが、四元数では $k^2=-1$ となるため、どこか計算方法を変える必要があります。

まず $k=ij$ の両辺を2乗して $k^2=(ij)^2$ とします。双複素数では交換法則が成り立っているため、右辺を $(ij)(ij)=i^2j^2$ と変形できます。$i^2=j^2=-1$ より $k^2=1$ となります。

```math
【双複素数】\ k^2=(i\underbrace{j)(i}_{ij}j)=\underbrace{i^2}_{-1}\underbrace{j^2}_{-1}=1
```

それに対して四元数では交換法則を諦めて $ij=-ji$ とすることで $k^2=-1$ が成立します。

```math
【四元数】\ k^2=(i\underbrace{j)(i}_{-ij}j)=-\underbrace{i^2}_{-1}\underbrace{j^2}_{-1}=-1
```

$ij=-ji$ は「積の因子を**交換**すれば符号が**反**転する」と解釈して**反交換性**と呼びます。

※ 途中に出て来たマイナス符号を前に動かしていますが、反交換性を持つのは $i,j,k$ だけで係数には影響しません。

## 巡回性

$ij$ 以外の組み合わせも確認します。

```math
\begin{align}
jk&=j\underbrace{(ij)}_{-ji}=-\underbrace{(jj)}_{-1}i=i \\
ki&=\underbrace{(ij)}_{-ji}i=-j\underbrace{(ii)}_{-1}=j
\end{align}
```

まとめれば $ij=k,\ jk=i,\ ki=j$ となります。

この組み合わせをよく見ると、式の要素を順番に回していることが分かります。

* ①②=③ → ②③=① → ③①=②

このような性質を**巡回性**と呼びます。

$jk, ki$ は反交換性を持ちます。

```math
\begin{align}
kj=(ij)j=i\underbrace{(jj)}_{-1}=-i \\
ik=i(ij)=\underbrace{(ii)}_{-1}j=-j
\end{align}
```

次のようにまとめれば巡回性と反交換性の両方を示せます。

```math
ij=-ji=k,\ jk=-kj=i,\ ki=-ik=j
```

## 覚え方

実用上は巡回性と反交換性を覚えておけば、他の関係は作れます。

1. 2乗すれば $-1$ となる虚数が3つある： $i^2=j^2=k^2=-1$
2. $i,j,k$ には $ij=k$ の関係がある： $ijk=kk=-1$
3. 巡回性より： $ij=k\ →\ jk=i\ →\ ki=j$
4. 反交換性より： $ij=-ji,\ jk=-kj,\ ki=-ik$

まとめれば次のようになります。

```math
i^2=j^2=k^2=ijk=-1 \\
ij=-ji=k,\ jk=-kj=i,\ ki=-ik=j
```

この結果だけ覚えるよりも、上記の手順でいつでも作れるようにしておくと良いでしょう。

### 乗積表

考え方をプログラムで表現して乗積表を生成してみます。

```fsharp
let quatProdE n = function
| [x; y] when x = y -> term n
| [x; y] when x % 3 + 1 = y -> term( 1, [], [y % 3 + 1])
| [y; x] when x % 3 + 1 = y -> term(-1, [], [y % 3 + 1])
| es -> Term.fromE es
for x in {0..3} do
    seq {for y in {0..3} -> [x; y] |> List.filter ((<>) 0)}
    |> Seq.map (quatProdE -1 >> Term.str ijk >> sprintf "%2s")
    |> String.concat " "
    |> printfn "%s"
```
```text:実行結果
 1  i  j  k
 i -1  k -j
 j -k -1  i
 k  j -i -1
```

## 3次元ベクトル

四元数の虚部は3次元ベクトルと同一視できます。実部と虚部で2次元を表す複素平面とは異なり、実部はベクトルの成分には割り当てません。

```math
\vec{a}=\left(\begin{matrix}a_1\\a_2\\a_3\end{matrix}\right)=a_1i+a_2j+a_3k
```

四元数で表した3次元ベクトルの積を計算すれば、内積と外積（ベクトル積スタイル）が得られます。このような幾何学的な性質は双複素数では得られないものです。

※ ベクトル積が得られる理由は $ij=k,\ jk=i,\ ki=j$ がベクトル積と同じ計算で、左辺と右辺がホッジ双対の関係になっているためです。

プログラムで確認します。

```fsharp
let quatProd title =
    Term.showProd title "" ijk (quatProdE -1) id Term.byIndexSign (fun _ -> true)
quatProd "## 積（ベクトル）" (List.tail qa) (List.tail qb)
```
```math
\begin{align}
\vec{a}\vec{b}
&=(a_1i+a_2j+a_3k)(b_1i+b_2j+b_3k) \\
&=a_1i(b_1i+b_2j+b_3k) \\
&\quad +a_2j(b_1i+b_2j+b_3k) \\
&\quad +a_3k(b_1i+b_2j+b_3k) \\
&=a_1b_1\underbrace{i^2}_{-1}+a_1b_2\underbrace{ij}_{k}+a_1b_3\underbrace{ik}_{-j} \\
&\quad +a_2b_1\underbrace{ji}_{-k}+a_2b_2\underbrace{j^2}_{-1}+a_2b_3\underbrace{jk}_{i} \\
&\quad +a_3b_1\underbrace{ki}_{j}+a_3b_2\underbrace{kj}_{-i}+a_3b_3\underbrace{k^2}_{-1} \\
&=-(\underbrace{a_1b_1+a_2b_2+a_3b_3}_{内積}) \\
&\quad +\underbrace{(a_2b_3-a_3b_2)i+(a_3b_1-a_1b_3)j+(a_1b_2-a_2b_1)k}_{外積} \\
&=-\underbrace{\vec{a}\cdot\vec{b}}_{内積}+\underbrace{\vec{a}×\vec{b}}_{外積}
\end{align}
```

※ ベクトルとの対応関係は手作業で追記しています。

実部に内積が現れることから、実部をスカラー、虚部をベクトルと呼ぶことの正当性が得られます。スカラーという用語には単なる数値としてだけでなく、不変量としての意味があります。

スカラーとベクトルを分離すれば都合が良いですし、空間を扱うのにベクトルは3次元で充分なことから、複素平面と違って実部をベクトルの成分として扱う必要がないと考えられます。もし三元数がうまく定義できれば実部と虚部で3次元ベクトルを表せたでしょうし、それがハミルトンの狙いでもありましたが、うまくいかなかったのは前述の通りです。

※ 実部と虚部で4次元を扱えないかについては、双曲四元数で後述します。

## 積

積を確認します。

```fsharp
quatProd "## 積" qa qb
```
```math
\begin{align}
&(a_0+a_1i+a_2j+a_3k)(b_0+b_1i+b_2j+b_3k) \\
&=a_0(b_0+b_1i+b_2j+b_3k) \\
&\quad +a_1i(b_0+b_1i+b_2j+b_3k) \\
&\quad +a_2j(b_0+b_1i+b_2j+b_3k) \\
&\quad +a_3k(b_0+b_1i+b_2j+b_3k) \\
&=a_0b_0+a_0b_1i+a_0b_2j+a_0b_3k \\
&\quad +a_1b_0i+a_1b_1\underbrace{i^2}_{-1}+a_1b_2\underbrace{ij}_{k}+a_1b_3\underbrace{ik}_{-j} \\
&\quad +a_2b_0j+a_2b_1\underbrace{ji}_{-k}+a_2b_2\underbrace{j^2}_{-1}+a_2b_3\underbrace{jk}_{i} \\
&\quad +a_3b_0k+a_3b_1\underbrace{ki}_{j}+a_3b_2\underbrace{kj}_{-i}+a_3b_3\underbrace{k^2}_{-1} \\
&=(a_0b_0-a_1b_1-a_2b_2-a_3b_3) \\
&\quad +(a_0b_1+a_1b_0+a_2b_3-a_3b_2)i \\
&\quad +(a_0b_2+a_2b_0+a_3b_1-a_1b_3)j \\
&\quad +(a_0b_3+a_3b_0+a_1b_2-a_2b_1)k \\
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

$i$ の項を $a_0(b_1)i+b_0(a_1)i+(a_2b_3-a_3b_2)i$ と分離すれば、ベクトルのスカラー倍と外積が重なっていることが確認できます。

この解釈では実部はベクトルの成分ではなく、ベクトルとして扱われるのは虚部の3次元です。実部まで含めた4次元ベクトルとしてうまく解釈できるかは不明です。

## 共役

虚部の符号を反転します。

```math
(a+bi+cj+dk)^*=a-bi-cj-dk
```

※ 双複素数とは異なり虚部はすべて符号反転します。

## ノルム

共役四元数と四元数の積からノルムの2乗を計算します。

```fsharp
quatProd "## ノルム" (conj qa) qa
```
```math
\begin{align}
&(a_0-a_1i-a_2j-a_3k)(a_0+a_1i+a_2j+a_3k) \\
&=a_0(a_0+a_1i+a_2j+a_3k) \\
&\quad -a_1i(a_0+a_1i+a_2j+a_3k) \\
&\quad -a_2j(a_0+a_1i+a_2j+a_3k) \\
&\quad -a_3k(a_0+a_1i+a_2j+a_3k) \\
&=a_0^2+a_0a_1i+a_0a_2j+a_0a_3k \\
&\quad -a_1a_0i-a_1^2\underbrace{i^2}_{-1}-a_1a_2\underbrace{ij}_{k}-a_1a_3\underbrace{ik}_{-j} \\
&\quad -a_2a_0j-a_2a_1\underbrace{ji}_{-k}-a_2^2\underbrace{j^2}_{-1}-a_2a_3\underbrace{jk}_{i} \\
&\quad -a_3a_0k-a_3a_1\underbrace{ki}_{j}-a_3a_2\underbrace{kj}_{-i}-a_3^2\underbrace{k^2}_{-1} \\
&=a_0^2+a_1^2+a_2^2+a_3^2 \\
\end{align}
```

4次元のユークリッド距離の2乗が出て来ました。双複素数と違い虚部は消えています。

# 双曲四元数

四元数は3次元空間を扱えると述べましたが、時間軸を加えた4次元時空を扱えないかというのは自然な流れです。しかし4次元時空は単に座標軸を1つ増やしたものではなく、ノルムの定義そのものが異なります。それに合わせて四元数をカスタマイズする必要があります。

双複素数では $i^2=j^2=-1,\ k^2=1$ です。それを $-1$ に揃えて $i^2=j^2=k^2=-1$ としたのが通常の四元数です。それとは逆に $1$ に揃えて $i^2=j^2=k^2=1$ としたのが**双曲四元数**です。

※ これは定義で、何か別のものから導出されたわけではありません。位置付けについての詳細は続編の[八元数を作ろう](http://qiita.com/7shi/items/b34fe724d36fb7d96456)で説明します。

双曲四元数における $i,j,k$ の関係は通常の四元数と同じで、巡回性・反交換性を持ちます。

```math
ij=-ji=k,\ jk=-kj=i,\ ki=-ik=j
```

## 結合法則

双曲四元数では一部の組み合わせは結合法則を満たしません。

満たす: $(ij)k=i(jk)$

```math
\begin{align}
(ij)k&=kk=1 \\
i(jk)&=ii=1
\end{align}
```

満たさない: $(ii)j≠i(ij)$

```math
\begin{align}
(ii)j&=j \\
i(ij)&=ik=-j
\end{align}
```

$iij$ のような表記は結合法則を前提としているため、結合法則が成り立たない双曲四元数では括弧を省略できません。

※ 八元数でも結合法則は成り立ちません。先に進むごとにどんどん不自由になります。

## 積

積を確認します。

```fsharp
let hquatProd title =
    Term.showProd title "" ijk (quatProdE 1) id Term.byIndexSign (fun _ -> true)
hquatProd "## 積" qa qb
```
```math
\begin{align}
&(a_0+a_1i+a_2j+a_3k)(b_0+b_1i+b_2j+b_3k) \\
&=a_0(b_0+b_1i+b_2j+b_3k) \\
&\quad +a_1i(b_0+b_1i+b_2j+b_3k) \\
&\quad +a_2j(b_0+b_1i+b_2j+b_3k) \\
&\quad +a_3k(b_0+b_1i+b_2j+b_3k) \\
&=a_0b_0+a_0b_1i+a_0b_2j+a_0b_3k \\
&\quad +a_1b_0i+a_1b_1\underbrace{i^2}_{1}+a_1b_2\underbrace{ij}_{k}+a_1b_3\underbrace{ik}_{-j} \\
&\quad +a_2b_0j+a_2b_1\underbrace{ji}_{-k}+a_2b_2\underbrace{j^2}_{1}+a_2b_3\underbrace{jk}_{i} \\
&\quad +a_3b_0k+a_3b_1\underbrace{ki}_{j}+a_3b_2\underbrace{kj}_{-i}+a_3b_3\underbrace{k^2}_{1} \\
&=(a_0b_0+a_1b_1+a_2b_2+a_3b_3) \\
&\quad +(a_0b_1+a_1b_0+a_2b_3-a_3b_2)i \\
&\quad +(a_0b_2+a_2b_0+a_3b_1-a_1b_3)j \\
&\quad +(a_0b_3+a_3b_0+a_1b_2-a_2b_1)k \\
\end{align}
```

※ 以下の説明は共役を考慮していないため、論点がずれています。後で修正します。

積の実部 $a_0b_0+a_1b_1+a_2b_2+a_3b_3$ の第2項以降を符号反転するとミンコフスキー内積となります。これは無理矢理な感がありますが、四元数の積の実部 $a_0b_0-a_1b_1-a_2b_2-a_3b_3$ の第2項以降を符号反転してユークリッド内積が得られたのと同じ操作をしています。

四元数と双曲四元数で符号反転しない形が逆なら美しいのですが、なかなかうまくいきません。符号の一致を実現するには、クリフォード代数を応用した時空代数が必要となります。

[Wikipediaのミンコフスキー空間](https://ja.wikipedia.org/wiki/%E3%83%9F%E3%83%B3%E3%82%B3%E3%83%95%E3%82%B9%E3%82%AD%E3%83%BC%E7%A9%BA%E9%96%93)には次のようにあり、乗法についてはあまり気にしなくても良いのかもしれません。

> 1890年代における双曲四元数の発展によりミンコフスキー空間への道が開かれることになった。実際のところ、数学的にはミンコフスキー空間とは双曲四元数の空間から乗法の情報を忘れて双線形形式
> $η(p,q) = −(pq^* + (pq^* )^* )/2$
> （これは双曲四元数の積 $pq^* $ によって定まる）のみを残したものと考えることができる。

## 共役

通常の四元数と同様です。

```math
(a+bi+cj+dk)^*=a-bi-cj-dk
```

## ノルム

ノルムの2乗を計算します。

```fsharp
hquatProd "## ノルム" (conj qa) qa
```
```math
\begin{align}
&(a_0-a_1i-a_2j-a_3k)(a_0+a_1i+a_2j+a_3k) \\
&=a_0(a_0+a_1i+a_2j+a_3k) \\
&\quad -a_1i(a_0+a_1i+a_2j+a_3k) \\
&\quad -a_2j(a_0+a_1i+a_2j+a_3k) \\
&\quad -a_3k(a_0+a_1i+a_2j+a_3k) \\
&=a_0^2+a_0a_1i+a_0a_2j+a_0a_3k \\
&\quad -a_1a_0i-a_1^2\underbrace{i^2}_{1}-a_1a_2\underbrace{ij}_{k}-a_1a_3\underbrace{ik}_{-j} \\
&\quad -a_2a_0j-a_2a_1\underbrace{ji}_{-k}-a_2^2\underbrace{j^2}_{1}-a_2a_3\underbrace{jk}_{i} \\
&\quad -a_3a_0k-a_3a_1\underbrace{ki}_{j}-a_3a_2\underbrace{kj}_{-i}-a_3^2\underbrace{k^2}_{1} \\
&=a_0^2-a_1^2-a_2^2-a_3^2 \\
\end{align}
```

$(+,-,-,-)$ 型のミンコフスキーノルムが出て来ました。通常の四元数はユークリッド空間、双曲四元数はミンコフスキー時空に対応します。

# 多元数

[多元数](https://ja.wikipedia.org/wiki/%E5%A4%9A%E5%85%83%E6%95%B0)のバリエーションをまとめました。

基本|双|分解型|分解型双|双曲|双対
----|----|----|----|----|----
[複素数](https://ja.wikipedia.org/wiki/%E8%A4%87%E7%B4%A0%E6%95%B0)|[双複素数](https://en.wikipedia.org/wiki/bicomplex_number)|[分解型複素数](https://ja.wikipedia.org/wiki/%E5%88%86%E8%A7%A3%E5%9E%8B%E8%A4%87%E7%B4%A0%E6%95%B0)|||
[四元数](https://ja.wikipedia.org/wiki/%E5%9B%9B%E5%85%83%E6%95%B0)|[双四元数](https://en.wikipedia.org/wiki/biquaternion)|[分解型四元数](https://en.wikipedia.org/wiki/Split-quaternion)|[分解型双四元数](https://en.wikipedia.org/wiki/split-biquaternion)|[双曲四元数](https://en.wikipedia.org/wiki/hyperbolic_quaternion)|[双対四元数](https://en.wikipedia.org/wiki/Dual_quaternion)
[八元数](https://ja.wikipedia.org/wiki/%E5%85%AB%E5%85%83%E6%95%B0)|[双八元数](https://en.wikipedia.org/wiki/Bioctonion)|[分解型八元数](https://en.wikipedia.org/wiki/split-octonion)||
[十六元数](https://ja.wikipedia.org/wiki/%E5%8D%81%E5%85%AD%E5%85%83%E6%95%B0)|||||
