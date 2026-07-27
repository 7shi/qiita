---
coediting: false
comments_count: 0
created_at: '2016-12-20T18:15:07+09:00'
id: 02c758c03d2fd7038912
likes_count: 2
private: false
reactions_count: 0
stocks_count: 2
tags:
- name: F#
  versions: []
- name: 数学
  versions: []
- name: 外積代数
  versions: []
- name: 八元数
  versions: []
title: 外積の成分をプログラムで確認
updated_at: '2017-03-12T21:29:40+09:00'
url: https://qiita.com/7shi/items/02c758c03d2fd7038912
slide: false
---

ベクトル積（外積）は3次元と7次元でしか定義されませんが、外積を一般化したウェッジ積は任意の次元で定義されます。成分について、プログラムで計算しながら具体的に比較します。

シリーズの記事です。

1. [多項式の積を計算](http://qiita.com/7shi/items/4fb60dacad46cb8e63b3)
1. [外積と愉快な仲間たち](http://qiita.com/7shi/items/017d2d2c758f76071f23)
1. [ユークリッド空間のホッジ双対とバブルソート](http://qiita.com/7shi/items/f54302058149d07da592)
1. [四元数を作ろう](http://qiita.com/7shi/items/2036e7a739c2a9e04025)
1. [四元数と行列で見る内積と外積の「内」と「外」](http://qiita.com/7shi/items/a80988a32a0d706e9378)
1. [八元数を作ろう](http://qiita.com/7shi/items/b34fe724d36fb7d96456)
1. [八元数の積をプログラムで確認](http://qiita.com/7shi/items/8495b2d6b888e7b8703f)
1. 外積の成分をプログラムで確認 ← この記事
1. [多元数の積の構成](http://qiita.com/7shi/items/88be5203769e629df243)
1. [十六元数を作ろう](http://qiita.com/7shi/items/989d59d74a505a92c419)

関連するコードをまとめたリポジトリです。

* https://bitbucket.org/7shi/math7

# 概要

2本のベクトルに直交するベクトルを一意に定められるのは3次元だけのため、ベクトル積は3次元に依存しています。一般の次元では定義できません。

四元数の虚部を3次元ベクトルに見立てて積を計算すれば、虚部から外積（ベクトル積）が得られます。

```math
\vec{v}\vec{w}=-\underbrace{\vec{v}\cdot\vec{w}}_{内積}+\underbrace{\vec{v}×\vec{w}}_{外積}
```

同様に八元数の虚部を7次元ベクトルに見立てることで、7次元でのベクトル積を定義できます。7次元でも2本のベクトルに直交するベクトルが一意に定まらないという事情は同じですが、八元数の次元モデルでは局所的に3次元に押し込めることで曲芸的に実現しています。詳細は機会があればまとめる予定です。

それに対して2本のベクトルのウェッジ積は、それらで張られる面として表現されます。これは次元に依存しないため、任意の次元で定義可能です。

少しずつ次元を増やしながらウェッジ積と八元数によるベクトル積を計算して、両者がどのように異なるのかを比較してみます。

# プログラム

今まで作って来たプログラムを応用します。[Math7.fsx](https://bitbucket.org/7shi/math7/src/tip/Math7.fsx)など個別の依存ファイルについては[リポジトリ](https://bitbucket.org/7shi/math7)を参照してください。

ウェッジ積と八元数によるベクトル積を比較するため、次元を増やしながら両方計算します。

* 今まで過剰に計算過程を表示していましたが、今回は結果だけを表示します。
* 比較の便宜上、八元数の基底も $\vec{e_1}$ のように添字で表します。
* 3次元と7次元以外ではベクトル積は定義されていません。積を計算する前は次元を落としているだけで、計算結果は次元の外にはみ出してしまいます。

```fsharp:WedgeOct.fsx
#load "Math7.Term.fsx"
#load "Math7.Octonion.fsx"
#load "Math7.Exterior.fsx"
open Math7

let showProd op f g sort1 sort2 filter nl a b =
    let sa = Term.strs f a |> Term.bracket
    let sb = Term.strs f b |> Term.bracket
    printfn @"&%s%s%s \\" sa op sb
    Term.prods g a b
    |> Term.simplify
    |> Term.sort sort1 sort2
    |> List.filter filter
    |> Term.showProd3 f nl

for n = 1 to 7 do
    Math7.prologue (sprintf "## %d次元" n)
    let a = [for i in [1..n] -> term(1, [sprintf "a_%d" i], [i])]
    let b = [for i in [1..n] -> term(1, [sprintf "b_%d" i], [i])]
    showProd "∧" (Term.vec "∧") (Term.fromE >> Exterior.simplify)
        id Term.byIndexSign (fun _ -> true) (fun x -> x % 3 = 0) a b
    showProd "×" (Term.vec "×") Octonion.prod id Term.byIndexSign
        (fun (e, _) -> e.E <> []) (fun _ -> true) a b
    Math7.epilogue()
```

出力結果にコメントを付けて紹介します。

## 1次元

どちらもゼロです。

```math
\begin{align}
(a_1\vec{e_1})∧(b_1\vec{e_1})&=0 \\
(a_1\vec{e_1})×(b_1\vec{e_1})&=0 \\
\end{align}
```

八元数は $\vec{e_1}=i$ だけを使っているため、実質的に複素数の計算です。

```math
Im(a_1ib_1i)=Im(-a_1b_1)=0
```

## 2次元

係数は同じですが、八元数では未使用の基底 $\vec{e_3}=k$ が表れ、2次元からはみ出しています。これは三元数が積で閉じていないため、実質的に四元数の計算になっているためです。

```math
\begin{align}
(a_1\vec{e_1}+a_2\vec{e_2})∧(b_1\vec{e_1}+b_2\vec{e_2})&=(a_1b_2-a_2b_1)\vec{e_1}∧\vec{e_2} \\
(a_1\vec{e_1}+a_2\vec{e_2})×(b_1\vec{e_1}+b_2\vec{e_2})&=(a_1b_2-a_2b_1)\vec{e_3} \\
\end{align}
```

ウェッジ積では $(a_1b_2-a_2b_1)\vec{e_1}∧\vec{e_2}$ のように、係数と基底の添字の組が同じです（1と2）。それに対して八元数では $(a_1b_2-a_2b_1)\vec{e_3}$ のように、基底に表れる添字（3）は係数（1と2）には現れません。この特徴は他の次元でも現れる一般的な性質のため、意識してください。

## 3次元

ウェッジ積とベクトル積は、面と法線の関係にあります。

```math
\begin{align}
&(a_1\vec{e_1}+a_2\vec{e_2}+a_3\vec{e_3})∧(b_1\vec{e_1}+b_2\vec{e_2}+b_3\vec{e_3}) \\
&=(a_1b_2-a_2b_1)\vec{e_1}∧\vec{e_2}+(a_1b_3-a_3b_1)\vec{e_1}∧\vec{e_3}+(a_2b_3-a_3b_2)\vec{e_2}∧\vec{e_3} \\
&(a_1\vec{e_1}+a_2\vec{e_2}+a_3\vec{e_3})×(b_1\vec{e_1}+b_2\vec{e_2}+b_3\vec{e_3}) \\
&=(a_2b_3-a_3b_2)\vec{e_1} \\
&\quad +(a_3b_1-a_1b_3)\vec{e_2} \\
&\quad +(a_1b_2-a_2b_1)\vec{e_3} \\
\end{align}
```

ウェッジ積の基底を巡回的には並べていないため、$\vec{e_1}∧\vec{e_3}$ と $\vec{e_2}$ の係数が逆符号になっています。

八元数は $e_1=i,e_2=j,e_3=k$ だけを使っているため、実質的に四元数の計算です。

## 4次元

係数は1対1で対応しています。

八元数では未使用の基底 $\vec{e_5},\vec{e_6},\vec{e_7}$ が表れています。これは四元数の次が八元数で間がなく、実質的に八元数の計算になっているためです。

```math
\begin{align}
&(a_1\vec{e_1}+a_2\vec{e_2}+a_3\vec{e_3}+a_4\vec{e_4})∧(b_1\vec{e_1}+b_2\vec{e_2}+b_3\vec{e_3}+b_4\vec{e_4}) \\
&=(a_1b_2-a_2b_1)\vec{e_1}∧\vec{e_2}+(a_1b_3-a_3b_1)\vec{e_1}∧\vec{e_3}+(a_1b_4-a_4b_1)\vec{e_1}∧\vec{e_4} \\
&\quad +(a_2b_3-a_3b_2)\vec{e_2}∧\vec{e_3}+(a_2b_4-a_4b_2)\vec{e_2}∧\vec{e_4}+(a_3b_4-a_4b_3)\vec{e_3}∧\vec{e_4} \\
&(a_1\vec{e_1}+a_2\vec{e_2}+a_3\vec{e_3}+a_4\vec{e_4})×(b_1\vec{e_1}+b_2\vec{e_2}+b_3\vec{e_3}+b_4\vec{e_4}) \\
&=(a_2b_3-a_3b_2)\vec{e_1} \\
&\quad +(a_3b_1-a_1b_3)\vec{e_2} \\
&\quad +(a_1b_2-a_2b_1)\vec{e_3} \\
&\quad +(a_1b_4-a_4b_1)\vec{e_5} \\
&\quad +(a_2b_4-a_4b_2)\vec{e_6} \\
&\quad +(a_3b_4-a_4b_3)\vec{e_7} \\
\end{align}
```

ウェッジ積に含まれる基底の組を八元数として積を計算すれば、対応する八元数の基底が得られます。第4基底が絡む計算は特別に簡単で、添字の足し算になっています。

【例】 $\vec{e_2}∧\vec{e_4} \to jh=j_h \to \vec{e_6}$

## 5次元

八元数の係数が長くなり始めます。ウェッジ積と八元数の基底の関係は4次元のときと同じで、積を計算した時に八元数では同じ基底になったものが長くなります。5次元からはみ出した $\vec{e_6},\vec{e_7}$ の係数が長いのは興味深いです。

```math
\begin{align}
&(a_1\vec{e_1}+a_2\vec{e_2}+a_3\vec{e_3}+a_4\vec{e_4}+a_5\vec{e_5})∧(b_1\vec{e_1}+b_2\vec{e_2}+b_3\vec{e_3}+b_4\vec{e_4}+b_5\vec{e_5}) \\
&=(a_1b_2-a_2b_1)\vec{e_1}∧\vec{e_2}+(a_1b_3-a_3b_1)\vec{e_1}∧\vec{e_3}+(a_1b_4-a_4b_1)\vec{e_1}∧\vec{e_4} \\
&\quad +(a_1b_5-a_5b_1)\vec{e_1}∧\vec{e_5}+(a_2b_3-a_3b_2)\vec{e_2}∧\vec{e_3}+(a_2b_4-a_4b_2)\vec{e_2}∧\vec{e_4} \\
&\quad +(a_2b_5-a_5b_2)\vec{e_2}∧\vec{e_5}+(a_3b_4-a_4b_3)\vec{e_3}∧\vec{e_4}+(a_3b_5-a_5b_3)\vec{e_3}∧\vec{e_5} \\
&\quad +(a_4b_5-a_5b_4)\vec{e_4}∧\vec{e_5} \\
&(a_1\vec{e_1}+a_2\vec{e_2}+a_3\vec{e_3}+a_4\vec{e_4}+a_5\vec{e_5})×(b_1\vec{e_1}+b_2\vec{e_2}+b_3\vec{e_3}+b_4\vec{e_4}+b_5\vec{e_5}) \\
&=(a_2b_3-a_3b_2+a_4b_5-a_5b_4)\vec{e_1} \\
&\quad +(a_3b_1-a_1b_3)\vec{e_2} \\
&\quad +(a_1b_2-a_2b_1)\vec{e_3} \\
&\quad +(a_5b_1-a_1b_5)\vec{e_4} \\
&\quad +(a_1b_4-a_4b_1)\vec{e_5} \\
&\quad +(a_2b_4-a_4b_2+a_5b_3-a_3b_5)\vec{e_6} \\
&\quad +(a_2b_5-a_5b_2+a_3b_4-a_4b_3)\vec{e_7} \\
\end{align}
```

## 6次元

八元数では、6次元からはみ出した $\vec{e_7}$ の係数が長いです。

```math
\begin{align}
&(a_1\vec{e_1}+a_2\vec{e_2}+a_3\vec{e_3}+a_4\vec{e_4}+a_5\vec{e_5}+a_6\vec{e_6})∧(b_1\vec{e_1}+b_2\vec{e_2}+b_3\vec{e_3}+b_4\vec{e_4}+b_5\vec{e_5}+b_6\vec{e_6}) \\
&=(a_1b_2-a_2b_1)\vec{e_1}∧\vec{e_2}+(a_1b_3-a_3b_1)\vec{e_1}∧\vec{e_3}+(a_1b_4-a_4b_1)\vec{e_1}∧\vec{e_4} \\
&\quad +(a_1b_5-a_5b_1)\vec{e_1}∧\vec{e_5}+(a_1b_6-a_6b_1)\vec{e_1}∧\vec{e_6}+(a_2b_3-a_3b_2)\vec{e_2}∧\vec{e_3} \\
&\quad +(a_2b_4-a_4b_2)\vec{e_2}∧\vec{e_4}+(a_2b_5-a_5b_2)\vec{e_2}∧\vec{e_5}+(a_2b_6-a_6b_2)\vec{e_2}∧\vec{e_6} \\
&\quad +(a_3b_4-a_4b_3)\vec{e_3}∧\vec{e_4}+(a_3b_5-a_5b_3)\vec{e_3}∧\vec{e_5}+(a_3b_6-a_6b_3)\vec{e_3}∧\vec{e_6} \\
&\quad +(a_4b_5-a_5b_4)\vec{e_4}∧\vec{e_5}+(a_4b_6-a_6b_4)\vec{e_4}∧\vec{e_6}+(a_5b_6-a_6b_5)\vec{e_5}∧\vec{e_6} \\
&(a_1\vec{e_1}+a_2\vec{e_2}+a_3\vec{e_3}+a_4\vec{e_4}+a_5\vec{e_5}+a_6\vec{e_6})×(b_1\vec{e_1}+b_2\vec{e_2}+b_3\vec{e_3}+b_4\vec{e_4}+b_5\vec{e_5}+b_6\vec{e_6}) \\
&=(a_2b_3-a_3b_2+a_4b_5-a_5b_4)\vec{e_1} \\
&\quad +(a_3b_1-a_1b_3+a_4b_6-a_6b_4)\vec{e_2} \\
&\quad +(a_1b_2-a_2b_1+a_6b_5-a_5b_6)\vec{e_3} \\
&\quad +(a_5b_1-a_1b_5+a_6b_2-a_2b_6)\vec{e_4} \\
&\quad +(a_1b_4-a_4b_1+a_3b_6-a_6b_3)\vec{e_5} \\
&\quad +(a_2b_4-a_4b_2+a_5b_3-a_3b_5)\vec{e_6} \\
&\quad +(a_6b_1-a_1b_6+a_2b_5-a_5b_2+a_3b_4-a_4b_3)\vec{e_7} \\
\end{align}
```

八元数が物理的な意味を持つのかは不明ですが、こういった次元からはみ出す成分は、その次元の住人には消えたように観察されるのかも、などと想像してしまいます。

## 7次元

順を追って見て来たので、対応関係は今までの知識で追えると思います。

```math
\begin{align}
&(a_1\vec{e_1}+a_2\vec{e_2}+a_3\vec{e_3}+a_4\vec{e_4}+a_5\vec{e_5}+a_6\vec{e_6}+a_7\vec{e_7})∧(b_1\vec{e_1}+b_2\vec{e_2}+b_3\vec{e_3}+b_4\vec{e_4}+b_5\vec{e_5}+b_6\vec{e_6}+b_7\vec{e_7}) \\
&=(a_1b_2-a_2b_1)\vec{e_1}∧\vec{e_2}+(a_1b_3-a_3b_1)\vec{e_1}∧\vec{e_3}+(a_1b_4-a_4b_1)\vec{e_1}∧\vec{e_4} \\
&\quad +(a_1b_5-a_5b_1)\vec{e_1}∧\vec{e_5}+(a_1b_6-a_6b_1)\vec{e_1}∧\vec{e_6}+(a_1b_7-a_7b_1)\vec{e_1}∧\vec{e_7} \\
&\quad +(a_2b_3-a_3b_2)\vec{e_2}∧\vec{e_3}+(a_2b_4-a_4b_2)\vec{e_2}∧\vec{e_4}+(a_2b_5-a_5b_2)\vec{e_2}∧\vec{e_5} \\
&\quad +(a_2b_6-a_6b_2)\vec{e_2}∧\vec{e_6}+(a_2b_7-a_7b_2)\vec{e_2}∧\vec{e_7}+(a_3b_4-a_4b_3)\vec{e_3}∧\vec{e_4} \\
&\quad +(a_3b_5-a_5b_3)\vec{e_3}∧\vec{e_5}+(a_3b_6-a_6b_3)\vec{e_3}∧\vec{e_6}+(a_3b_7-a_7b_3)\vec{e_3}∧\vec{e_7} \\
&\quad +(a_4b_5-a_5b_4)\vec{e_4}∧\vec{e_5}+(a_4b_6-a_6b_4)\vec{e_4}∧\vec{e_6}+(a_4b_7-a_7b_4)\vec{e_4}∧\vec{e_7} \\
&\quad +(a_5b_6-a_6b_5)\vec{e_5}∧\vec{e_6}+(a_5b_7-a_7b_5)\vec{e_5}∧\vec{e_7}+(a_6b_7-a_7b_6)\vec{e_6}∧\vec{e_7} \\
&(a_1\vec{e_1}+a_2\vec{e_2}+a_3\vec{e_3}+a_4\vec{e_4}+a_5\vec{e_5}+a_6\vec{e_6}+a_7\vec{e_7})×(b_1\vec{e_1}+b_2\vec{e_2}+b_3\vec{e_3}+b_4\vec{e_4}+b_5\vec{e_5}+b_6\vec{e_6}+b_7\vec{e_7}) \\
&=(a_2b_3-a_3b_2+a_4b_5-a_5b_4+a_7b_6-a_6b_7)\vec{e_1} \\
&\quad +(a_3b_1-a_1b_3+a_4b_6-a_6b_4+a_5b_7-a_7b_5)\vec{e_2} \\
&\quad +(a_1b_2-a_2b_1+a_4b_7-a_7b_4+a_6b_5-a_5b_6)\vec{e_3} \\
&\quad +(a_5b_1-a_1b_5+a_6b_2-a_2b_6+a_7b_3-a_3b_7)\vec{e_4} \\
&\quad +(a_1b_4-a_4b_1+a_7b_2-a_2b_7+a_3b_6-a_6b_3)\vec{e_5} \\
&\quad +(a_1b_7-a_7b_1+a_2b_4-a_4b_2+a_5b_3-a_3b_5)\vec{e_6} \\
&\quad +(a_6b_1-a_1b_6+a_2b_5-a_5b_2+a_3b_4-a_4b_3)\vec{e_7} \\
\end{align}
```

# おわりに

具体例を集めれば規則性が分かりやすくなります。今回のように式がやたらに長いと手計算では大変ですが、プログラムを作ってしまえば簡単です。まだ扱える計算の種類は少ないですが、少しずつ増やしていきたいです。
