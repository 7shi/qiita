---
coediting: false
comments_count: 2
created_at: '2016-10-26T02:13:51+09:00'
id: 017d2d2c758f76071f23
likes_count: 118
private: false
reactions_count: 0
stocks_count: 97
tags:
- name: F#
  versions: []
- name: 数学
  versions: []
- name: テンソル
  versions: []
- name: 外積代数
  versions: []
- name: クリフォード代数
  versions: []
title: 外積と愉快な仲間たち
updated_at: '2024-06-22T18:11:54+09:00'
url: https://qiita.com/7shi/items/017d2d2c758f76071f23
slide: false
---

ベクトルの外積と呼ばれる演算には3種類あります。

1. テンソル積 $\otimes$
2. ウェッジ積 $\wedge$（楔積）
3. ベクトル積 $\times$（クロス積）

これらについて簡単に紹介します。

※ 外積と言えばベクトル積を指すことが一般的です。ここでは使用頻度ではなく、説明の都合で番号を振っています。

内積と外積を同時に扱えるクリフォード代数の幾何積も紹介します。

最後に、代数式・テンソル積・ウェッジ積・ベクトル積・幾何積・四元数を計算するプログラムを掲載します。

シリーズの記事です。

1. [多項式の積を計算](http://qiita.com/7shi/items/4fb60dacad46cb8e63b3)
1. 外積と愉快な仲間たち ← この記事
1. [ユークリッド空間のホッジ双対とバブルソート](http://qiita.com/7shi/items/f54302058149d07da592)
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

* 2017.12.04 [八元数と7次元の外積](http://7shi.hateblo.jp/entry/2017/12/04/235635) ← お勧め
* 2017.03.06 [実ベクトルで考える複素ベクトル](http://qiita.com/7shi/items/4f313cb36cdd12c8d833)
* 2017.03.14 [表現行列で考える双複素数](http://qiita.com/7shi/items/050f6615558c4c2b1d92)
* 2017.03.25 [クリフォード代数で考えるパウリ行列と双四元数](http://qiita.com/7shi/items/fafe77f9a5ff2f9651ba)

# 基底ベクトル表示

座標軸を表すベクトルを基底ベクトルと呼びます。

ここでは一般論には立ち入らず、通常の2次元$xy$座標で、$x$軸方向の基底ベクトルを$\vec{e_1}$、$y$軸方向の基底ベクトルを$\vec{e_2}$とします。

```math
\vec{e_1}=\left(\begin{matrix}1\\0\end{matrix}\right),
\ \vec{e_2}=\left(\begin{matrix}0\\1\end{matrix}\right)
```

基底ベクトルを使えば、ベクトルを代数式のスタイルで記述できます。

```math
\left(\begin{matrix}x\\y\end{matrix}\right)
=\left(\begin{matrix}x\\0\end{matrix}\right)+
 \left(\begin{matrix}0\\y\end{matrix}\right)
=x\left(\begin{matrix}1\\0\end{matrix}\right)+
 y\left(\begin{matrix}0\\1\end{matrix}\right)
=x\vec{e_1}+y\vec{e_2}
```

具体例を示します。

```math
\left(\begin{matrix}2\\3\end{matrix}\right)
=2\vec{e_1}+3\vec{e_2}
```

3次元の場合は$\vec{e_3}$も使います。

```math
\vec{e_1}=\left(\begin{matrix}1\\0\\0\end{matrix}\right),
\vec{e_2}=\left(\begin{matrix}0\\1\\0\end{matrix}\right),
\vec{e_3}=\left(\begin{matrix}0\\0\\1\end{matrix}\right)
```
```math
\left(\begin{matrix}x\\y\\z\end{matrix}\right)
=x\vec{e_1}+y\vec{e_2}+z\vec{e_3}
```

今回は扱いませんが、同様に任意の次元に拡張できます。

# 式の展開

代数式のスタイルで記述すれば、ベクトルの掛け算を普通の代数式のように考えて扱うことができます。

比較対象として、ベクトルを使わない通常の式の展開を考えます。

```math
\begin{align}
&(ax+by+cz)(dx+ey+fz) \\
&=ax(dx+ey+fz)+by(dx+ey+fz)+cz(dx+ey+fz) \\
&=adx^2+aexy+afxz+bdyx+bey^2+bfyz+cdzx+cezy+cfz^2 \\
&=adx^2+bey^2+cfz^2+(ae+bd)xy+(bf+ce)yz+(af+cd)zx
\end{align}
```

交換法則（$xy=yx$ など）を使って同類項をまとめていることに注意してください。

# テンソル積

先ほどの式の展開と同じようなことを考えます。

最も簡単なベクトル同士の掛け算として、単純に結合するだけの積を考えます。これを**テンソル積**と呼んで、専用の演算子 $\otimes$ を使用します。

交換法則は成り立たないため、順番の入れ替えはできません。

```math
\vec{e_1}\otimes\vec{e_2}\neq\vec{e_2}\otimes\vec{e_1}
```

基底ベクトル表示したベクトル同士のテンソル積を計算してみます。矢印が付いていない $a$ などは交換法則の成り立つ通常の掛け算として扱います。

```math
\begin{align}
&(a\,\vec{e_1}+b\,\vec{e_2}+c\,\vec{e_3})\otimes(d\,\vec{e_1}+e\,\vec{e_2}+f\,\vec{e_3}) \\
&=a\,\vec{e_1}\otimes(d\,\vec{e_1}+e\,\vec{e_2}+f\,\vec{e_3}) \\
&\quad +b\,\vec{e_2}\otimes(d\,\vec{e_1}+e\,\vec{e_2}+f\,\vec{e_3}) \\
&\quad +c\,\vec{e_3}\otimes(d\,\vec{e_1}+e\,\vec{e_2}+f\vec{e_3}) \\
&=ad\,\vec{e_1}\otimes\vec{e_1}+ae\,\vec{e_1}\otimes\vec{e_2}+af\,\vec{e_1}\otimes\vec{e_3} \\
&\quad +bd\,\vec{e_2}\otimes\vec{e_1}+be\,\vec{e_2}\otimes\vec{e_2}+bf\,\vec{e_2}\otimes\vec{e_3} \\
&\quad +cd\,\vec{e_3}\otimes\vec{e_1}+ce\,\vec{e_3}\otimes\vec{e_2}+cf\,\vec{e_3}\otimes\vec{e_3}
\end{align}
```

※ 矢印の付いていない $e$ は基底とは無関係です。

交換法則が成り立たないため同類項は存在せず、式はこれ以上整理できません。

## 行列表現

テンソル積を行列で表現します。左側のベクトルの各成分に対して、右側のベクトルを掛けます。

```math
\begin{pmatrix}a\\b\\c\end{pmatrix}\otimes\begin{pmatrix}d\\e\\f\end{pmatrix}
=\begin{pmatrix}
  a\begin{pmatrix}d\\e\\f\end{pmatrix}\\
  b\begin{pmatrix}d\\e\\f\end{pmatrix}\\
  c\begin{pmatrix}d\\e\\f\end{pmatrix}
 \end{pmatrix}
=\begin{pmatrix}ad\\ae\\af\\bd\\be\\bf\\cd\\ce\\cf\end{pmatrix}
```

テンソル積が何を計算しているのか、イメージが湧いたでしょうか。ベクトルや行列で書くことで、背後にある考え方の見通しが良くなります。

交換法則が成り立たないため順番の入れ替えはできないと前述しましたが、実際に計算してみれば異なる結果になることが確認できます。

### テンソル積の特殊な場合

右側が横ベクトルであれば、テンソル積は行列の積と一致します。

```math
\begin{pmatrix}a\\b\\c\end{pmatrix}
\otimes\begin{pmatrix}d&e&f\end{pmatrix}
=\begin{pmatrix}a\\b\\c\end{pmatrix}
 \begin{pmatrix}d&e&f\end{pmatrix}
=\begin{pmatrix}ad&ae&af\\bd&be&bf\\cd&ce&cf\end{pmatrix}
```

※ 量子情報関係ではこの種の積を外積と呼ぶことがあります。英語表記は [outer product](https://en.wikipedia.org/wiki/Outer_product) です。

この行列とテンソル積の基底の添え字を見比べると、$i$ 行 $j$ 列の成分が $e_i\otimes e_j$ の係数に対応することが分かります。

```math
\begin{align}
&(a\,\vec{e_1}+b\,\vec{e_2}+c\,\vec{e_3})\otimes(d\,\vec{e_1}+e\,\vec{e_2}+f\,\vec{e_3}) \\
&=ad\,\vec{e_1}\otimes\vec{e_1}+ae\,\vec{e_1}\otimes\vec{e_2}+af\,\vec{e_1}\otimes\vec{e_3} \\
&\quad +bd\,\vec{e_2}\otimes\vec{e_1}+be\,\vec{e_2}\otimes\vec{e_2}+bf\,\vec{e_2}\otimes\vec{e_3} \\
&\quad +cd\,\vec{e_3}\otimes\vec{e_1}+ce\,\vec{e_3}\otimes\vec{e_2}+cf\,\vec{e_3}\otimes\vec{e_3}
\end{align}
```

## 直積

計算結果をよく見ると、オペランドの成分を組み合わせていることが分かります。

集合論では類似の演算を直積と呼びます。

```math
\begin{align}
&\{a,b,c\}\times\{d,e,f\} \\
&=\{(a,d),(a,e),(a,f),(b,d),(b,e),(b,f),(c,d),(c,e),(c,f)\}
\end{align}
```

このアナロジーでベクトル同士のテンソル積を**直積**と呼ぶことがあります。

# ウェッジ積

テンソル積は同類項の整理が進まずに煩雑でしたが、**ウェッジ積** $\wedge$ と呼ばれる演算を定義することでもう少し単純な結果を得ることができます。

```math
\vec{a}\wedge\vec{b}:=\vec{a}\otimes\vec{b}-\vec{b}\otimes\vec{a}
```

数値計算での $ab-ba$ は常にゼロですが、これは積に交換法則が成り立つからです。テンソル積で得られたテンソルの一部には交換法則が成り立つ成分（可換成分）があり、ウェッジ積はテンソル積から可換成分を取り除いています。

ウェッジ積は一般化した外積とされ、専門に扱う分野を外積代数と呼びます。

※ 一般化する前の外積は後述のベクトル積を指します。

ウェッジ積を指す「外積（exterior product）」は、直積を指す「外積（outer product）」とは別物で、英語では区別されています。日本語に訳すときにどちらも「外積」を当ててしまったようです。

wedge は楔の意味です。**楔（くさび）積**と呼ぶこともあります。

## 反交換性

オペランドの順番を入れ替えると符号が反転します。これを**反交換性**と呼びます。

```math
\begin{align}
\vec{a}\wedge\vec{b}
&=\vec{a}\otimes\vec{b}-\vec{b}\otimes\vec{a} \\
&=-(\vec{b}\otimes\vec{a}-\vec{a}\otimes\vec{b}) \\
&=-\vec{b}\wedge\vec{a}
\end{align}
```

同じベクトル同士のウェッジ積はゼロになります。

```math
\vec{a}\wedge\vec{a}=\vec{a}\otimes\vec{a}-\vec{a}\otimes\vec{a}=0
```

これらを毎回テンソル積から導出するのは大変なので、ルールとして覚えておく方が良いでしょう。

なお、反交換性を使ってもゼロになる結果を導けます。

```math
\vec{a}\wedge\vec{a}=-(\vec{a}\wedge\vec{a})=0
```

符号を変えても一致するということは、ゼロしかあり得ないことを意味します。反対称行列の対角成分がゼロになったり、奇関数が原点を通ったりするのと同様の考え方です。

## 面積

ウェッジ積は面積と関係があります。

日常では次のように単位を考えます。

* 長さ（m）×長さ（m）＝面積（㎡）

これを基底に適用すれば、次のように考えられます。

* 長さ（$\vec{e_1}$）∧長さ（$\vec{e_2}$）＝面積（$\vec{e_1}\wedge\vec{e_2}$）

$\vec{e_1}\wedge\vec{e_2}$ が面を意味する基底で、係数が面積の値を表します。

簡単な例を示します。

```math
(2\vec{e_1})\wedge(3\vec{e_2})=6(\vec{e_1}\wedge\vec{e_2})
```

左辺は辺が2と3の長方形を表して、右辺の $6$ は面積を表します。

### 平行四辺形

斜めを向いた2成分のベクトルではどうなるでしょうか。計算の際に、反交換性によって成分が消えたり同類項が整理できるのに注意します。

```math
\begin{align}
&(a\vec{e_1}+b\vec{e_2})∧(c\vec{e_1}+d\vec{e_2}) \\
&=ac\underbrace{\vec{e_1}\wedge\vec{e_1}}_{0}+ad\vec{e_1}\wedge\vec{e_2} \\
&\quad +bc\underbrace{\vec{e_2}\wedge\vec{e_1}}_{-\vec{e_1}\wedge\vec{e_2}}+bd\underbrace{\vec{e_2}\wedge\vec{e_2}}_{0} \\
&=(ad-bc)\vec{e_1}∧\vec{e_2}
\end{align}
```

$ad-bc$ は2本のベクトルで表される平行四辺形の面積です。行列式を思い浮かべた人は鋭いです。今回は触れませんが、この関係は留意しておいてください。

```math
\left|\begin{matrix}a&b\\c&d\end{matrix}\right|=ad-bc
```

## 3成分のウェッジ積

テンソル積でやったのと同じ計算をウェッジ積でもやってみます。

```math
\begin{align}
&(a\vec{e_1}+b\vec{e_2}+c\vec{e_3})\wedge(d\vec{e_1}+e\vec{e_2}+f\vec{e_3}) \\
&=a\vec{e_1}\wedge(d\vec{e_1}+e\vec{e_2}+f\vec{e_3}) \\
&\quad +b\vec{e_2}\wedge(d\vec{e_1}+e\vec{e_2}+f\vec{e_3}) \\
&\quad +c\vec{e_3}\wedge(d\vec{e_1}+e\vec{e_2}+f\vec{e_3}) \\
&=ad\underbrace{\vec{e_1}\wedge\vec{e_1}}_{0}+ae\vec{e_1}\wedge\vec{e_2}+af\underbrace{\vec{e_1}\wedge\vec{e_3}}_{-\vec{e_3}\wedge\vec{e_1}} \\
&\quad +bd\underbrace{\vec{e_2}\wedge\vec{e_1}}_{-\vec{e_1}\wedge\vec{e_2}}+be\underbrace{\vec{e_2}\wedge\vec{e_2}}_{0}+bf\vec{e_2}\wedge\vec{e_3} \\
&\quad +cd\vec{e_3}\wedge\vec{e_1}+ce\underbrace{\vec{e_3}\wedge\vec{e_2}}_{-\vec{e_2}\wedge\vec{e_3}}+cf\underbrace{\vec{e_3}\wedge\vec{e_3}}_{0} \\
&=(ae-bd)\vec{e_1}\wedge\vec{e_2}+(bf-ce)\vec{e_2}\wedge\vec{e_3}+(cd-af)\vec{e_3}\wedge\vec{e_1}
\end{align}
```

最後の行で、巡回的（サイクリック）に基底を並べています。

### 射影

テンソル積よりは計算が進みましたが、何やら複雑な結果が出て来ました。

これは2本のベクトルが表す平行四辺形を、基底が張る3つの平面に射影した面積成分で表現しています。

### 内積

ゼロになって消えた項の係数は $ad+be+cf$ ですが、これは**内積**を表します。内積は交換法則が成り立つ可換成分のため、ウェッジ積では消えてしまいます。

※ 内積が残るように改良した幾何積というものがあり、後述します。

## 行列表現

ウェッジ積の計算は代数スタイルで行いますが、計算結果をテンソル積に戻して行列で表現することがあります。符号を反転した成分が影のように現れることに注意してください。

```math
\begin{align}
&(ae-bd)\vec{e_1}\wedge\vec{e_2} \\
&\quad +(bf-ce)\vec{e_2}\wedge\vec{e_3} \\
&\quad +(cd-af)\vec{e_3}\wedge\vec{e_1} \\
&=(ae-bd)(\vec{e_1}\otimes\vec{e_2}-\vec{e_2}\otimes\vec{e_1}) \\
&\quad +(bf-ce)(\vec{e_2}\otimes\vec{e_3}-\vec{e_3}\otimes\vec{e_2}) \\
&\quad +(cd-af)(\vec{e_3}\otimes\vec{e_1}-\vec{e_1}\otimes\vec{e_3}) \\
&=\left(\begin{matrix}\underbrace{0}_{対角}&\underbrace{ae-bd}_{独立}&\underbrace{-(cd-af)}_{影}\\\underbrace{-(ae-bd)}_{影}&\underbrace{0}_{対角}&\underbrace{bf-ce}_{独立}\\\underbrace{cd-af}_{独立}&\underbrace{-(bf-ce)}_{影}&\underbrace{0}_{対角}\end{matrix}\right)
\end{align}
```

これは反対称行列です。反対称行列の対角成分は常にゼロです。

## ホッジ双対

独立成分が3つしかないので、行列表現は冗長です。独立成分だけをベクトルとして表現することを考えます。

3次元では平面に対して法線ベクトルが一意に定まります。「面と面積」と「法線と長さ」の関係を**ホッジ双対**と呼びます。ホッジ双対の相互変換を単項演算子 $\star$（ホッジスター）で表します。

※ 実際の定義はもっと一般化されていますが、今回は省略します。

面から法線への変換を見ます。巡回的な組み合わせ（1→2→3→1→2→…）を正とします。

```math
\begin{align}
\star(\vec{e_1}\wedge\vec{e_2})&=\vec{e_3} \\
\star(\vec{e_2}\wedge\vec{e_3})&=\vec{e_1} \\
\star(\vec{e_3}\wedge\vec{e_1})&=\vec{e_2}
\end{align}
```

巡回的でなければ負になります。

```math
\begin{align}
\star(\vec{e_2}\wedge\vec{e_1})=\star(-\vec{e_1}\wedge\vec{e_2})&=-\vec{e_3} \\
\star(\vec{e_3}\wedge\vec{e_2})=\star(-\vec{e_2}\wedge\vec{e_3})&=-\vec{e_1} \\
\star(\vec{e_1}\wedge\vec{e_3})=\star(-\vec{e_3}\wedge\vec{e_1})&=-\vec{e_2}
\end{align}
```

逆に変換すれば、法線から面に戻ります。

```math
\begin{align}
\star\vec{e_1}&=\vec{e_2}\wedge\vec{e_3} \\
\star\vec{e_2}&=\vec{e_3}\wedge\vec{e_1} \\
\star\vec{e_3}&=\vec{e_1}\wedge\vec{e_2}
\end{align}
```

### 擬ベクトル

先ほどの計算結果をホッジ双対で表せば、独立成分だけで表せてすっきりします。

```math
\begin{align}
&(ae-bd)\vec{e_1}\wedge\vec{e_2}+(bf-ce)\vec{e_2}\wedge\vec{e_3}+(cd-af)\vec{e_3}\wedge\vec{e_1} \\
&=\star\{(ae-bd)\vec{e_3}+(bf-ce)\vec{e_1}+(cd-af)\vec{e_2}\} \\
&=\star\{(bf-ce)\vec{e_1}+(cd-af)\vec{e_2}+(ae-bd)\vec{e_3}\} \\
&=\star\left(\begin{matrix}bf-ce\\cd-af\\ae-bd\end{matrix}\right)
\end{align}
```

ホッジスターが示しているように、これは実際には反対称行列であってベクトルそのものではありません。このような見かけ上のベクトルを**擬ベクトル**と呼びます。

# ベクトル積

先ほどホッジ双対により面を法線ベクトルに変換しましたが、最初から計算結果を法線ベクトルで表すのが**ベクトル積**です。名前は計算結果がベクトルになることを表します。演算子は $\times$ を使うため**クロス積**とも呼ばれます。

```math
\vec{a}\times\vec{b}:=\star(\vec{a}\wedge\vec{b})
```

普通はベクトル積を「外積」として習い、「2本のベクトルで表される平行四辺形の面積を長さとする法線ベクトル」と説明されます。

基底同士のベクトル積を確認します。

```math
\begin{align}
\vec{e_1}\times\vec{e_2}&=\star(\vec{e_1}\wedge\vec{e_2})=\vec{e_3} \\
\vec{e_2}\times\vec{e_3}&=\star(\vec{e_2}\wedge\vec{e_3})=\vec{e_1} \\
\vec{e_3}\times\vec{e_1}&=\star(\vec{e_3}\wedge\vec{e_1})=\vec{e_2}
\end{align}
```

ウェッジ積と同様に反交換性があります。

```math
\begin{align}
\vec{e_1}\times\vec{e_1}&=0 \\
\underbrace{\vec{e_1}\times\vec{e_2}}_{\vec{e_3}}&=\underbrace{-\vec{e_2}\times\vec{e_1}}_{-(-\vec{e_3})}
\end{align}
```

少し慣れれば、ウェッジ積を経由しなくても直に計算できるでしょう。

## 3成分のベクトル積

テンソル積やウェッジ積でやったのと同じ計算をベクトル積でもやってみます。

```math
\begin{align}
&\left(\begin{matrix}a\\b\\c\end{matrix}\right)\times\left(\begin{matrix}d\\e\\f\end{matrix}\right) \\
&=(a\vec{e_1}+b\vec{e_2}+c\vec{e_3})\times(d\vec{e_1}+e\vec{e_2}+f\vec{e_3}) \\
&=a\vec{e_1}\times(d\vec{e_1}+e\vec{e_2}+f\vec{e_3}) \\
&\quad +b\vec{e_2}\times(d\vec{e_1}+e\vec{e_2}+f\vec{e_3}) \\
&\quad +c\vec{e_3}\times(d\vec{e_1}+e\vec{e_2}+f\vec{e_3}) \\
&=ad\underbrace{\vec{e_1}\times\vec{e_1}}_{0}+ae\underbrace{\vec{e_1}\times\vec{e_2}}_{\vec{e_3}}+af\underbrace{\vec{e_1}\times\vec{e_3}}_{-\vec{e_2}} \\
&\quad +bd\underbrace{\vec{e_2}\times\vec{e_1}}_{-\vec{e_3}}+be\underbrace{\vec{e_2}\times\vec{e_2}}_{0}+bf\underbrace{\vec{e_2}\times\vec{e_3}}_{\vec{e_1}} \\
&\quad +cd\underbrace{\vec{e_3}\times\vec{e_1}}_{\vec{e_2}}+ce\underbrace{\vec{e_3}\times\vec{e_2}}_{-\vec{e_1}}+cf\underbrace{\vec{e_3}\times\vec{e_3}}_{0} \\
&=(bf-ce)\vec{e_1}+(cd-af)\vec{e_2}+(ae-bd)\vec{e_3} \\
&=\left(\begin{matrix}bf-ce\\cd-af\\ae-bd\end{matrix}\right)
\end{align}
```

これはベクトル積（外積）の定義として紹介されますが、個々の基底の直交性から決まることを理解していれば、必要に応じて導けます。得られるのは2本のベクトルで表される面の法線ですが、面という概念を省略して、2本のベクトルに直交するベクトルを求めるという解釈が一般的です。

## 次元

2次元では1本のベクトルに直交するベクトルは一意に定まりますが、3次元では角度が定まらずに1回転分の自由度があります。3次元では直交するベクトルを一意に定めるには2本のベクトルが必要となり、これが前述のベクトル積の図形的解釈となります。

同様に次元を増やして直交するベクトルを一意に定めるには、4次元では3本のベクトル、5次元では4本のベクトルが必要になります。このため4次元以上では二項演算としてのベクトル積は定義できません。これは面に対する垂線が一意に定まらないことを意味します。

※ 例外的に7次元のベクトル積を考えることは可能です。3次元のベクトル積は四元数の積として計算できますが（[四元数を作ろう](http://qiita.com/7shi/items/2036e7a739c2a9e04025)を参照）、7次元のベクトル積は八元数の積として計算できるためです（[八元数を作ろう](http://qiita.com/7shi/items/b34fe724d36fb7d96456)を参照）。ただしこれは八元数の計算に依存した定義で、原理的には2本のベクトルに直交するベクトルが一意に定まるわけではありません。

ベクトル積は法線ベクトルを表現するため次元に依存するのに対して、ウェッジ積は面を表現しているため次元に依存しません。このことを指して、ウェッジ積は外積（ベクトル積）の一般化だと言われます。

ベクトル積の方が先に普及してしまったため、テキストではベクトル積を法線や軸として説明していることが多いです。もしベクトル積の説明が分かりにくければ、ウェッジ積に読み替えて考えるというのも一つの手です。

# 幾何積

ウェッジ積では同じ基底があると $0$ になりましたが、それを $1$ として計算するのが幾何積（幾何学積とも）です。それ以外の反交換性はウェッジ積と同じです。演算子は使わずに基底を連続して書きます。

```math
\begin{align}
\vec{e_1}\vec{e_1}&=1 \\
\vec{e_1}\vec{e_2}&=-\vec{e_2}\vec{e_1}
\end{align}
```

後で見ますが幾何積は内積と外積の両方を含むため、幾何積が外積と呼ばれることは**ありません**。専門に扱う分野をクリフォード代数や幾何代数（幾何学的代数とも）と呼びます。日本ではあまり馴染みのない分野ですが、ある種の計算がきれいに書けるため、今後は物理やコンピュータビジョンでの普及が期待されます。

## ウェッジ積との関係

ウェッジ積は幾何積と以下の関係があります。幾何積には可換成分が定数項として含まれるため、それを取り除くことでウェッジ積と対応させます。

```math
\vec{a}\wedge\vec{b}=\frac{1}{2}(\vec{a}\vec{b}-\vec{b}\vec{a})
```

可換成分（同じ基底の積）を含まない場合に限り、ウェッジ積は幾何積に置き換えられます。

```math
\vec{e_1}∧\vec{e_2}=\frac{1}{2}(\vec{e_1}\vec{e_2}-\underbrace{\vec{e_2}\vec{e_1}}_{-\vec{e_1}\vec{e_2}})=\vec{e_1}\vec{e_2}
```

反交換性により同類項となるため $1/2$ で調整しています。

それに対してテンソル積は同類項とはならずにそこで計算が終わります。定義を再掲するので、比較しながら意味を考えてみてください。

```math
\vec{a}\wedge\vec{b}:=\vec{a}\otimes\vec{b}-\vec{b}\otimes\vec{a}
```

## 内積と外積

幾何積と呼ばれる理由は、2本のベクトルの幾何積が内積と外積（ウェッジ積スタイル）を含むためのようです。

成分計算で確認します。

```math
\begin{align}
\vec{a}\vec{b}
&=(a\vec{e_1}+b\vec{e_2}+c\vec{e_3})(d\vec{e_1}+e\vec{e_2}+f\vec{e_3}) \\
&=a\vec{e_1}(d\vec{e_1}+e\vec{e_2}+f\vec{e_3}) \\
&\quad +b\vec{e_1}(d\vec{e_1}+e\vec{e_2}+f\vec{e_3}) \\
&\quad +c\vec{e_2}(d\vec{e_1}+e\vec{e_2}+f\vec{e_3}) \\
&=ad\underbrace{\vec{e_1}\vec{e_1}}_{1}+ae\vec{e_1}\vec{e_2}+af\underbrace{\vec{e_1}\vec{e_3}}_{-\vec{e_3}\vec{e_1}} \\
&\quad +bd\underbrace{\vec{e_2}\vec{e_1}}_{-\vec{e_1}\vec{e_2}}+be\underbrace{\vec{e_2}\vec{e_2}}_{1}+bf\vec{e_2}\vec{e_3} \\
&\quad +cd\vec{e_3}\vec{e_1}+ce\underbrace{\vec{e_3}\vec{e_2}}_{-\vec{e_2}\vec{e_3}}+cf\underbrace{\vec{e_3}\vec{e_3}}_{1} \\
&=\underbrace{(ad+be+cf)}_{内積} \\
&\quad +\underbrace{(ae-bd)\vec{e_1}\vec{e_2}+(bf-ce)\vec{e_2}\vec{e_3}+(cd-af)\vec{e_3}\vec{e_1}}_{外積} \\
&=\underbrace{\vec{a}\cdot\vec{b}}_{内積}+\underbrace{\vec{a}∧\vec{b}}_{外積}
\end{align}
```

定数項が内積、それ以外が外積となります。

四元数でもほぼ同様の計算ができますが、内積にマイナスが付き、外積がベクトル積スタイルなのが異なります。

```math
\vec{a}\vec{b}=-\underbrace{\vec{a}\cdot\vec{b}}_{内積}+\underbrace{\vec{a}×\vec{b}}_{外積}
```

詳細は[四元数と行列で見る内積と外積の「内」と「外」](http://qiita.com/7shi/items/a80988a32a0d706e9378)を参照してください。次の行列もこちらが元ネタです。

### 行列で計算

同じ計算を行列の二次形式でやってみます。

```math
\begin{align}
&(a\vec{e_1}+b\vec{e_2}+c\vec{e_3})(d\vec{e_1}+e\vec{e_2}+f\vec{e_3}) \\
&=\left(\begin{matrix} \vec{e_1} &  \vec{e_2} &  \vec{e_3} \end{matrix}\right)
  \left(\begin{matrix} a \\ b \\ c \end{matrix}\right)
  \left(\begin{matrix} d &  e &  f \end{matrix}\right)
  \left(\begin{matrix} \vec{e_1} \\ \vec{e_2} \\ \vec{e_3} \end{matrix}\right) \\
&=\left(\begin{matrix} \vec{e_1} &  \vec{e_2} &  \vec{e_3} \end{matrix}\right)
  \left(\begin{matrix} ad & ae & af \\ bd & be & bf \\ cd & ce & cf \end{matrix}\right)
  \left(\begin{matrix} \vec{e_1} \\ \vec{e_2} \\ \vec{e_3} \end{matrix}\right) \\
&=(ad+be+cf) \\
&\quad +(ae-bd)\vec{e_1}\vec{e_2}+(bf-ce)\vec{e_2}\vec{e_3}+(cd-af)\vec{e_3}\vec{e_1}
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

### 関係式

関係式を移項してウェッジ積の定義を代入すれば、内積の関係式が得られます。

```math
\begin{align}
\vec{a}\vec{b}&=\vec{a}\cdot\vec{b}+\vec{a}∧\vec{b} \\
\vec{a}\cdot\vec{b}&=\vec{a}\vec{b}-\vec{a}∧\vec{b} \\
&=\vec{a}\vec{b}-\frac{1}{2}(\vec{a}\vec{b}-\vec{b}\vec{a}) \\
&=\frac{1}{2}(\vec{a}\vec{b}+\vec{b}\vec{a})
\end{align}
```

幾何積からウェッジ積を引けば内積（可換成分）が残ると解釈できます。幾何積とウェッジ積が一致するのは内積がゼロのときだけです。

関係式をまとめます。

```math
\begin{align}
\vec{a}\cdot\vec{b}&=\frac{1}{2}(\vec{a}\vec{b}+\vec{b}\vec{a}) \\
\vec{a}\wedge\vec{b}&=\frac{1}{2}(\vec{a}\vec{b}-\vec{b}\vec{a}) \\
\vec{a}\vec{b}&=\vec{a}\cdot\vec{b}+\vec{a}∧\vec{b} \\
&=\frac{1}{2}(\vec{a}\vec{b}+\vec{b}\vec{a})+\frac{1}{2}(\vec{a}\vec{b}-\vec{b}\vec{a})
\end{align}
```

## ホッジ双対

幾何積を使えばホッジ双対が簡単に導出できます。詳細は続編の[ユークリッド空間のホッジ双対とバブルソート](http://qiita.com/7shi/items/f54302058149d07da592)を参照してください。

# プログラム

代数式・テンソル積・ウェッジ積・ベクトル積・幾何積・四元数を比較するため、プログラムで計算してみます。

[ExtProduct.fsx](https://bitbucket.org/7shi/math7/src/tip/ExtProduct.fsx) を分割して引用します。[Math7.fsx](https://bitbucket.org/7shi/math7/src/tip/Math7.fsx) と [Math7.Term.fsx](https://bitbucket.org/7shi/math7/src/tip/Math7.Term.fsx) に依存しています。全体は[リポジトリ](https://bitbucket.org/7shi/math7)を参照してください。

係数と基底の関係を見るため、係数は $a,b,c$ ではなく添字を用いた $a_1,a_2,a_3$ を使用します。

## 代数式

いわゆる普通の数式です。これを基本に他の積との違いを比較すると良いでしょう。

```fsharp:ExtProduct.fsx
#load "Math7.Term.fsx"
open Math7

Term.showProd "## 代数式" ""
    (Seq.map (fun e -> [""; "x"; "y"; "z"].[e]) >> Term.strPower)
    (function
    | [x; y] when y % 3 + 1 = x -> Term.fromE [y; x]
    | es -> Term.fromE es)
    (function
    | [x; y] as xs when x = y -> (-2, xs)
    |           xs            -> (-1, xs))
    Term.byIndexSign ((=) 3)
    [for i in [1..3] -> term(1, [sprintf "a_%d" i], [i])]
    [for i in [1..3] -> term(1, [sprintf "b_%d" i], [i])]
```
```math
\begin{align}
&(a_1x+a_2y+a_3z)(b_1x+b_2y+b_3z) \\
&=a_1x(b_1x+b_2y+b_3z) \\
&\quad +a_2y(b_1x+b_2y+b_3z) \\
&\quad +a_3z(b_1x+b_2y+b_3z) \\
&=a_1b_1x^2+a_1b_2xy+a_1b_3\underbrace{xz}_{zx} \\
&\quad +a_2b_1\underbrace{yx}_{xy}+a_2b_2y^2+a_2b_3yz \\
&\quad +a_3b_1zx+a_3b_2\underbrace{zy}_{yz}+a_3b_3z^2 \\
&=a_1b_1x^2+a_2b_2y^2+a_3b_3z^2 \\
&\quad +(a_1b_2+a_2b_1)xy+(a_2b_3+a_3b_2)yz+(a_1b_3+a_3b_1)zx \\
\end{align}
```

## テンソル積

同類項の整理がないため簡単です。

```fsharp:ExtProduct.fsx（続き）
Term.showProd "## テンソル積" @"\otimes "
    (Term.vec @"\otimes ")
    Term.fromE id Term.byIndexSign (fun _ -> false)
    [for i in [1..3] -> term(1, [sprintf "a_%d" i], [i])]
    [for i in [1..3] -> term(1, [sprintf "b_%d" i], [i])]
```
```math
\begin{align}
&(a_1\vec{e_1}+a_2\vec{e_2}+a_3\vec{e_3})\otimes (b_1\vec{e_1}+b_2\vec{e_2}+b_3\vec{e_3}) \\
&=a_1\vec{e_1}\otimes (b_1\vec{e_1}+b_2\vec{e_2}+b_3\vec{e_3}) \\
&\quad +a_2\vec{e_2}\otimes (b_1\vec{e_1}+b_2\vec{e_2}+b_3\vec{e_3}) \\
&\quad +a_3\vec{e_3}\otimes (b_1\vec{e_1}+b_2\vec{e_2}+b_3\vec{e_3}) \\
&=a_1b_1\vec{e_1}\otimes \vec{e_1}+a_1b_2\vec{e_1}\otimes \vec{e_2}+a_1b_3\vec{e_1}\otimes \vec{e_3} \\
&\quad +a_2b_1\vec{e_2}\otimes \vec{e_1}+a_2b_2\vec{e_2}\otimes \vec{e_2}+a_2b_3\vec{e_2}\otimes \vec{e_3} \\
&\quad +a_3b_1\vec{e_3}\otimes \vec{e_1}+a_3b_2\vec{e_3}\otimes \vec{e_2}+a_3b_3\vec{e_3}\otimes \vec{e_3} \\
\end{align}
```

## ウェッジ積

Math7に反交換性を教えます。

```fsharp:ExtProduct.fsx（続き）
Term.showProd "## ウェッジ積" "∧"
    (Term.vec "∧")
    (function
    | [x; y] when x = y -> term.Zero
    | [x; y] when y % 3 + 1 = x -> term(-1, [], [y; x])
    | es -> Term.fromE es)
    id Term.byIndexSign (fun _ -> false)
    [for i in [1..3] -> term(1, [sprintf "a_%d" i], [i])]
    [for i in [1..3] -> term(1, [sprintf "b_%d" i], [i])]
```
```math
\begin{align}
&(a_1\vec{e_1}+a_2\vec{e_2}+a_3\vec{e_3})∧(b_1\vec{e_1}+b_2\vec{e_2}+b_3\vec{e_3}) \\
&=a_1\vec{e_1}∧(b_1\vec{e_1}+b_2\vec{e_2}+b_3\vec{e_3}) \\
&\quad +a_2\vec{e_2}∧(b_1\vec{e_1}+b_2\vec{e_2}+b_3\vec{e_3}) \\
&\quad +a_3\vec{e_3}∧(b_1\vec{e_1}+b_2\vec{e_2}+b_3\vec{e_3}) \\
&=a_1b_1\underbrace{\vec{e_1}∧\vec{e_1}}_{0}+a_1b_2\vec{e_1}∧\vec{e_2}+a_1b_3\underbrace{\vec{e_1}∧\vec{e_3}}_{-\vec{e_3}∧\vec{e_1}} \\
&\quad +a_2b_1\underbrace{\vec{e_2}∧\vec{e_1}}_{-\vec{e_1}∧\vec{e_2}}+a_2b_2\underbrace{\vec{e_2}∧\vec{e_2}}_{0}+a_2b_3\vec{e_2}∧\vec{e_3} \\
&\quad +a_3b_1\vec{e_3}∧\vec{e_1}+a_3b_2\underbrace{\vec{e_3}∧\vec{e_2}}_{-\vec{e_2}∧\vec{e_3}}+a_3b_3\underbrace{\vec{e_3}∧\vec{e_3}}_{0} \\
&=(a_1b_2-a_2b_1)\vec{e_1}∧\vec{e_2}+(a_2b_3-a_3b_2)\vec{e_2}∧\vec{e_3}+(a_3b_1-a_1b_3)\vec{e_3}∧\vec{e_1} \\
\end{align}
```

$(a_1b_2-a_2b_1)\vec{e_1}∧\vec{e_2}$ より、係数と基底ともに添字は1と2が使われており、特定の面に関係する量であることが直観的にも分かります。他の項も同様です。

## ベクトル積

Math7に反交換性と巡回性を教えます。

```fsharp:ExtProduct.fsx（続き）
Term.showProd "## ベクトル積" "×"
    (Term.vec "×")
    (function
    | [x; y] when x = y -> term.Zero
    | [x; y] when x % 3 + 1 = y -> term( 1, [], [y % 3 + 1])
    | [x; y] when y % 3 + 1 = x -> term(-1, [], [x % 3 + 1])
    | es -> Term.fromE es)
    id Term.byIndexSign (fun _ -> false)
    [for i in [1..3] -> term(1, [sprintf "a_%d" i], [i])]
    [for i in [1..3] -> term(1, [sprintf "b_%d" i], [i])]
```
```math
\begin{align}
&(a_1\vec{e_1}+a_2\vec{e_2}+a_3\vec{e_3})×(b_1\vec{e_1}+b_2\vec{e_2}+b_3\vec{e_3}) \\
&=a_1\vec{e_1}×(b_1\vec{e_1}+b_2\vec{e_2}+b_3\vec{e_3}) \\
&\quad +a_2\vec{e_2}×(b_1\vec{e_1}+b_2\vec{e_2}+b_3\vec{e_3}) \\
&\quad +a_3\vec{e_3}×(b_1\vec{e_1}+b_2\vec{e_2}+b_3\vec{e_3}) \\
&=a_1b_1\underbrace{\vec{e_1}×\vec{e_1}}_{0}+a_1b_2\underbrace{\vec{e_1}×\vec{e_2}}_{\vec{e_3}}+a_1b_3\underbrace{\vec{e_1}×\vec{e_3}}_{-\vec{e_2}} \\
&\quad +a_2b_1\underbrace{\vec{e_2}×\vec{e_1}}_{-\vec{e_3}}+a_2b_2\underbrace{\vec{e_2}×\vec{e_2}}_{0}+a_2b_3\underbrace{\vec{e_2}×\vec{e_3}}_{\vec{e_1}} \\
&\quad +a_3b_1\underbrace{\vec{e_3}×\vec{e_1}}_{\vec{e_2}}+a_3b_2\underbrace{\vec{e_3}×\vec{e_2}}_{-\vec{e_1}}+a_3b_3\underbrace{\vec{e_3}×\vec{e_3}}_{0} \\
&=(a_2b_3-a_3b_2)\vec{e_1}+(a_3b_1-a_1b_3)\vec{e_2}+(a_1b_2-a_2b_1)\vec{e_3} \\
\end{align}
```

$(a_2b_3-a_3b_2)\vec{e_1}$ より、係数は基底（1）を除いた添字（2,3）が使われており、相補的な関係にあることが分かります。他の項も同様です。

## 幾何積

Math7に内積と反交換性を教えます。ウェッジ積に似ていますが内積が残ります。

```fsharp:ExtProduct.fsx（続き）
Term.showProd "## 幾何積" ""
    (Term.vec "")
    (function
    | [x; y] when x = y -> term.One
    | [x; y] when y % 3 + 1 = x -> term(-1, [], [y; x])
    | es -> Term.fromE es)
    id Term.byIndexSign ((=) 1)
    [for i in [1..3] -> term(1, [sprintf "a_%d" i], [i])]
    [for i in [1..3] -> term(1, [sprintf "b_%d" i], [i])]
```
```math
\begin{align}
&(a_1\vec{e_1}+a_2\vec{e_2}+a_3\vec{e_3})(b_1\vec{e_1}+b_2\vec{e_2}+b_3\vec{e_3}) \\
&=a_1\vec{e_1}(b_1\vec{e_1}+b_2\vec{e_2}+b_3\vec{e_3}) \\
&\quad +a_2\vec{e_2}(b_1\vec{e_1}+b_2\vec{e_2}+b_3\vec{e_3}) \\
&\quad +a_3\vec{e_3}(b_1\vec{e_1}+b_2\vec{e_2}+b_3\vec{e_3}) \\
&=a_1b_1\underbrace{\vec{e_1}\vec{e_1}}_{1}+a_1b_2\vec{e_1}\vec{e_2}+a_1b_3\underbrace{\vec{e_1}\vec{e_3}}_{-\vec{e_3}\vec{e_1}} \\
&\quad +a_2b_1\underbrace{\vec{e_2}\vec{e_1}}_{-\vec{e_1}\vec{e_2}}+a_2b_2\underbrace{\vec{e_2}\vec{e_2}}_{1}+a_2b_3\vec{e_2}\vec{e_3} \\
&\quad +a_3b_1\vec{e_3}\vec{e_1}+a_3b_2\underbrace{\vec{e_3}\vec{e_2}}_{-\vec{e_2}\vec{e_3}}+a_3b_3\underbrace{\vec{e_3}\vec{e_3}}_{1} \\
&=(a_1b_1+a_2b_2+a_3b_3) \\
&\quad +(a_1b_2-a_2b_1)\vec{e_1}\vec{e_2}+(a_2b_3-a_3b_2)\vec{e_2}\vec{e_3}+(a_3b_1-a_1b_3)\vec{e_3}\vec{e_1} \\
\end{align}
```

係数と基底の関係はウェッジ積と同様です。

## 四元数

Math7に内積と反交換性と巡回性を教えます。ベクトル積に似ていますが内積が残ります。

```fsharp:ExtProduct.fsx（続き）
Term.showProd "## 四元数" ""
    (Seq.map (fun e -> [""; "i"; "j"; "k"].[e]) >> Term.strPower)
    (function
    | [x; y] when x = y -> term -1
    | [x; y] when x % 3 + 1 = y -> term( 1, [], [y % 3 + 1])
    | [y; x] when x % 3 + 1 = y -> term(-1, [], [y % 3 + 1])
    | es -> Term.fromE es)
    id Term.byIndexSign ((=) 1)
    [for i in [1..3] -> term(1, [sprintf "a_%d" i], [i])]
    [for i in [1..3] -> term(1, [sprintf "b_%d" i], [i])]
```
```math
\begin{align}
&(a_1i+a_2j+a_3k)(b_1i+b_2j+b_3k) \\
&=a_1i(b_1i+b_2j+b_3k) \\
&\quad +a_2j(b_1i+b_2j+b_3k) \\
&\quad +a_3k(b_1i+b_2j+b_3k) \\
&=a_1b_1\underbrace{i^2}_{-1}+a_1b_2\underbrace{ij}_{k}+a_1b_3\underbrace{ik}_{-j} \\
&\quad +a_2b_1\underbrace{ji}_{-k}+a_2b_2\underbrace{j^2}_{-1}+a_2b_3\underbrace{jk}_{i} \\
&\quad +a_3b_1\underbrace{ki}_{j}+a_3b_2\underbrace{kj}_{-i}+a_3b_3\underbrace{k^2}_{-1} \\
&=-(a_1b_1+a_2b_2+a_3b_3) \\
&\quad +(a_2b_3-a_3b_2)i+(a_3b_1-a_1b_3)j+(a_1b_2-a_2b_1)k \\
\end{align}
```

係数と基底の関係はベクトル積と同様です。

# 参考

* [テンソルの概念 [物理のかぎしっぽ]](http://hooktail.sub.jp/vectoranalysis/TensorConcept/)
* [外積代数 [物理のかぎしっぽ]](http://hooktail.sub.jp/differentialforms/ExteriorAlgebra/)
* [七次元の外積 [物理のかぎしっぽ]](http://hooktail.sub.jp/vectoranalysis/SevenDCrossProd/)
* [直積 (ベクトル) - Wikipedia](https://ja.wikipedia.org/wiki/%E7%9B%B4%E7%A9%8D_(%E3%83%99%E3%82%AF%E3%83%88%E3%83%AB))
* 【PDF】[幾何学的代数の要旨](http://www.iim.cs.tut.ac.jp/~kanatani/papers/essence.pdf)
* [外積代数入門　 クロス積　ウェッジ積　テンソル](http://www.osssme.com/doc/funto105-no260.html)
