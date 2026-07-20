---
coediting: false
comments_count: 0
created_at: '2016-11-02T12:07:44+09:00'
id: a80988a32a0d706e9378
likes_count: 23
private: false
reactions_count: 0
stocks_count: 15
tags:
- name: F#
  versions: []
- name: 数学
  versions: []
- name: 四元数
  versions: []
- name: 線形代数
  versions: []
title: 四元数と行列で見る内積と外積の「内」と「外」
updated_at: '2017-12-05T12:12:05+09:00'
url: https://qiita.com/7shi/items/a80988a32a0d706e9378
slide: false
---

四元数を行列で計算すれば内積や外積の「内」と「外」が視覚的に分かることに気付いたのでメモします。最後に行列を生成する簡単なプログラムを掲載します。

【注】歴史的な由来は未確認です。

シリーズの記事です。

1. [多項式の積を計算](http://qiita.com/7shi/items/4fb60dacad46cb8e63b3)
1. [外積と愉快な仲間たち](http://qiita.com/7shi/items/017d2d2c758f76071f23)
1. [ユークリッド空間のホッジ双対とバブルソート](http://qiita.com/7shi/items/f54302058149d07da592)
1. [四元数を作ろう](http://qiita.com/7shi/items/2036e7a739c2a9e04025)
1. 四元数と行列で見る内積と外積の「内」と「外」 ← この記事
1. [八元数を作ろう](http://qiita.com/7shi/items/b34fe724d36fb7d96456)
1. [八元数の積をプログラムで確認](http://qiita.com/7shi/items/8495b2d6b888e7b8703f)
1. [外積の成分をプログラムで確認](http://qiita.com/7shi/items/02c758c03d2fd7038912)
1. [多元数の積の構成](http://qiita.com/7shi/items/88be5203769e629df243)
1. [十六元数を作ろう](http://qiita.com/7shi/items/989d59d74a505a92c419)

関連するコードをまとめたリポジトリです。

* https://bitbucket.org/7shi/math7

この記事には関連記事があります。

* 2017.12.04 [八元数と7次元の外積](http://7shi.hateblo.jp/entry/2017/12/04/235635) ← お勧め
* 2017.03.06 [実ベクトルで考える複素ベクトル](http://qiita.com/7shi/items/4f313cb36cdd12c8d833)

# 四元数

複素数 $a+bi$ を二元数と捉えた場合、虚数の種類を増やして $a+bi+cj+dk$ としたのが四元数です。

$i, j, k$ はそれぞれ別の虚数で、以下の関係があります。

```math
i^2=j^2=k^2=ijk=-1 \\
ij=-ji=k,\ jk=-kj=i,\ ki=-ik=j
```

※ 詳細は[四元数を作ろう](http://qiita.com/7shi/items/2036e7a739c2a9e04025)を参照してください。

## 行列による乗積表

$i,j,k$ の積は乗積表として表形式にまとめられますが、ここでは行列で示します。

```math
\begin{align}
\left(\begin{matrix} i \\ j \\ k \end{matrix}\right)
\left(\begin{matrix} i &  j &  k \end{matrix}\right)
&=\left(\begin{matrix} ii & ij & ik \\ ji & jj & jk \\ ki & kj & kk \end{matrix}\right) \\
&=\left(\begin{matrix} -1 &  k & -j \\ -k & -1 &  i \\ j & -i & -1 \end{matrix}\right)
\end{align}
```

※ この種のベクトル計算を直積と呼びます。詳細は[外積と愉快な仲間たち](http://qiita.com/7shi/items/017d2d2c758f76071f23)を参照してください。

# 3次元ベクトル

虚数 $i,j,k$ を3次元ベクトル空間の基底だと考えれば、四元数の虚部 $ai+bj+ck$ は3次元ベクトルだと見なせます。

```math
ai+bj+ck\mapsto\left(\begin{matrix} a \\ b \\ c \end{matrix}\right)
```

※ 実部は無視します。

## 内積と外積

2本のベクトルを四元数で表して掛け算します。

```math
\begin{align}
&(ai+bj+ck)(di+ej+fk) \\
&=ai(di+ej+fk) \\
&\quad +bi(di+ej+fk) \\
&\quad +cj(di+ej+fk) \\
&=ad\underbrace{ii}_{-1}+ae\underbrace{ij}_{k}+af\underbrace{ik}_{-j} \\
&\quad +bd\underbrace{ji}_{-k}+be\underbrace{jj}_{-1}+bf\underbrace{jk}_{i} \\
&\quad +cd\underbrace{ki}_{j}+ce\underbrace{kj}_{-i}+cf\underbrace{kk}_{-1} \\
&=-\underbrace{(ad+be+cf)}_{内積} \\
&\quad +\underbrace{(bf-ce)i+(cd-af)j+(ae-bd)k}_{外積}
\end{align}
```

実部が内積のマイナス、虚部が外積となります。

```math
\begin{align}
内積 &\left(\begin{matrix}a\\b\\c\end{matrix}\right)\cdot\left(\begin{matrix}d\\e\\f\end{matrix}\right)=ad+be+cf \\
外積 &\left(\begin{matrix}a\\b\\c\end{matrix}\right)×\left(\begin{matrix}d\\e\\f\end{matrix}\right)=\left(\begin{matrix}bf-ce\\cd-af\\ae-bd\end{matrix}\right)
\end{align}
```

※ 内積がマイナスになっている点については、四元数が先にあって内積の概念が確立されたため、初期の内積は四元数と同じ符号で扱われていたそうです。符号にマイナスが付かないように修正したクリフォード代数というものがあります。詳細は[外積と愉快な仲間たち](http://qiita.com/7shi/items/017d2d2c758f76071f23)を参照してください。

ここまではよくある説明です。

## 行列で計算

同じ計算を行列の二次形式でやってみます。

```math
\begin{align}
&(ai+bj+ck)(di+ej+fk) \\
&=\left(\begin{matrix} i &  j &  k \end{matrix}\right)
  \left(\begin{matrix} a \\ b \\ c \end{matrix}\right)
  \left(\begin{matrix} d &  e &  f \end{matrix}\right)
  \left(\begin{matrix} i \\ j \\ k \end{matrix}\right) \\
&=\left(\begin{matrix} i &  j &  k \end{matrix}\right)
  \left(\begin{matrix} ad & ae & af \\ bd & be & bf \\ cd & ce & cf \end{matrix}\right)
  \left(\begin{matrix} i \\ j \\ k \end{matrix}\right) \\
&=-(ad+be+cf) \\
&\quad +(bf-ce)i+(cd-af)j+(ae-bd)k
\end{align}
```

ここで3行目中央の行列に注目します。

```math
\left(\begin{matrix}
  \underbrace{ad}_{内} & \underbrace{ae}_{外} & \underbrace{af}_{外} \\
  \underbrace{bd}_{外} & \underbrace{be}_{内} & \underbrace{bf}_{外} \\
  \underbrace{cd}_{外} & \underbrace{ce}_{外} & \underbrace{cf}_{内}
\end{matrix}\right)
```

内側が内積で、外側が外積の成分です！

# プログラム

行列を記述するのは大変なので、プログラムで生成してみました。（[リポジトリ](https://bitbucket.org/7shi/math7)）

```fsharp:QuaternionProduct.fsx
open System

let matrix m =
    printfn @"\left(\begin{matrix}"
    m |> Seq.map (String.concat " & ")
      |> String.concat (@" \\" + Environment.NewLine)
      |> printfn "%s"
    printfn @"\end{matrix}\right)"

let v = [["a"]; ["b"]; ["c"]]
let w = [["d" ;  "e" ;  "f"]]

matrix v
matrix w
printfn "="
v
|> Seq.mapi (fun i r ->
    w.[0] |> Seq.mapi (fun j c ->
        if i = j then "内" else "外"
        |> sprintf @"\underbrace{%s%s}_{%s}" r.[0] c))
|> matrix
```
```math
\left(\begin{matrix}
a \\
b \\
c
\end{matrix}\right)
\left(\begin{matrix}
d & e & f
\end{matrix}\right)
=
\left(\begin{matrix}
\underbrace{ad}_{内} & \underbrace{ae}_{外} & \underbrace{af}_{外} \\
\underbrace{bd}_{外} & \underbrace{be}_{内} & \underbrace{bf}_{外} \\
\underbrace{cd}_{外} & \underbrace{ce}_{外} & \underbrace{cf}_{内}
\end{matrix}\right)
```
