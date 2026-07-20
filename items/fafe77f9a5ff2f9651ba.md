---
coediting: false
comments_count: 0
created_at: '2017-03-25T07:54:26+09:00'
id: fafe77f9a5ff2f9651ba
likes_count: 40
private: false
reactions_count: 0
stocks_count: 20
tags:
- name: Python
  versions: []
- name: sympy
  versions: []
- name: 数学
  versions: []
- name: 四元数
  versions: []
- name: クリフォード代数
  versions: []
title: クリフォード代数で考えるパウリ行列と双四元数
updated_at: '2019-03-22T21:13:07+09:00'
url: https://qiita.com/7shi/items/fafe77f9a5ff2f9651ba
slide: false
---

ベクトルで向きを伴った長さが表現できます。ベクトルを複合させることで面積や体積も扱えるようにしたのがクリフォード代数です。3次元のクリフォード代数の表現行列としてパウリ行列を導入して、双四元数と同型であることを確認します。SymPyによる計算を添えます。

シリーズの記事です。

1. [実ベクトルで考える複素ベクトル](http://qiita.com/7shi/items/4f313cb36cdd12c8d833)
1. [表現行列で考える双複素数](http://qiita.com/7shi/items/050f6615558c4c2b1d92)
1. [表現行列で考える四元数](http://qiita.com/7shi/items/e7364e1b2593f24427a5)
1. クリフォード代数で考えるパウリ行列と双四元数 ← この記事

この記事には関連記事があります。

* [外積と愉快な仲間たち](http://qiita.com/7shi/items/017d2d2c758f76071f23) 2016.10.26
* [ユークリッド空間のホッジ双対とバブルソート](http://qiita.com/7shi/items/f54302058149d07da592) 2016.10.31
* [八元数を作ろう](http://qiita.com/7shi/items/b34fe724d36fb7d96456) 2016.12.06

この記事を読んでクリフォード代数に興味を持った方には、次の記事がお勧めです。

* 【PDF】[クリフォード代数](http://physnd.html.xdomain.jp/field/cliff.pdf)
* 【英語】[Introduction to Clifford Algebra](https://www.av8n.com/physics/clifford-intro.htm)

# クリフォード代数

幾何学的な対象（長さ・面積・体積など）を代数的に扱えるようにした計算方法です。

今回必要となる範囲で、簡単に説明します。

## 基底ベクトル

座標軸を表すベクトルを基底ベクトルと呼びます。3次元 $xyz$ 座標で、$x$ 軸方向の基底ベクトルを $\mathbf{e_1}$、$y$ 軸方向の基底ベクトルを $\mathbf{e_2}$、$z$ 軸方向の基底ベクトルを $\mathbf{e_3}$ とします。

```math
\mathbf{e_1},\mathbf{e_2},\mathbf{e_3}=
\left(\begin{matrix} 1 \\ 0 \\ 0 \end{matrix}\right),
\left(\begin{matrix} 0 \\ 1 \\ 0 \end{matrix}\right),
\left(\begin{matrix} 0 \\ 0 \\ 1 \end{matrix}\right)
```

## 1-ベクトル

基底ベクトルを使えば、ベクトルを代数式のスタイルで記述できます。

```math
\begin{align}
   \left(\begin{matrix} x \\ y \\ z \end{matrix}\right)
&= \left(\begin{matrix} x \\ 0 \\ 0 \end{matrix}\right)
 + \left(\begin{matrix} 0 \\ y \\ 0 \end{matrix}\right)
 + \left(\begin{matrix} 0 \\ 0 \\ z \end{matrix}\right) \\
&=x\left(\begin{matrix} 1 \\ 0 \\ 0 \end{matrix}\right)
 +y\left(\begin{matrix} 0 \\ 1 \\ 0 \end{matrix}\right)
 +z\left(\begin{matrix} 0 \\ 0 \\ 1 \end{matrix}\right) \\
&=x\mathbf{e_1}+y\mathbf{e_2}+z\mathbf{e_3}
\end{align}
```

具体例を示します。

```math
\left(\begin{matrix} 2 \\ 3 \\ 4 \end{matrix}\right)
=2\mathbf{e_1}+3\mathbf{e_2}+4\mathbf{e_3}
```

このように基底ベクトルの線形結合（定数倍と和）で表されるベクトルを、クリフォード代数の用語では**1-ベクトル**と呼びます。

## 2-ベクトル

日常では次のように単位を考えます。

* 長さ（m）×長さ（m）＝面積（㎡）

これを基底に適用すれば、次のように考えられます。

* 長さ（$\mathbf{e_1}$）×長さ（$\mathbf{e_2}$）＝面積（$\mathbf{e_1e_2}$）

$\mathbf{e_1e_2}$ が面積を意味する基底で、係数が面積の値を表します。

簡単な例を示します。

```math
(2\mathbf{e_1})(3\mathbf{e_2})=6\mathbf{e_1e_2}
```

左辺は辺が2と3の長方形を表して、右辺の $6$ は面積を表します。

このように基底を2つ組み合わせて表した面積を、クリフォード代数の用語では**2-ベクトル**と呼びます。1-ベクトルが線分の大きさ（長さ）を表しているのと同様、2-ベクトルは面の大きさ（面積）を表します。

互いに斜交している2本の1-ベクトルの外積は、それらが張る平行四辺形の面積を表します。

### 向き

1-ベクトルが向きを伴った長さであるのと同様、2-ベクトルも向きを伴った面積です。向きは次元により表現の幅が変わります。

#### 2次元

平行四辺形は常に $xy$ 平面上に存在するため、向きは符号で表現されます。符号は基底の取り方に影響を受けます。面を張る2本の1-ベクトルが基底と同じ位置関係（右手系では反時計回り）なら正となります。

※ 具体的な形は、後で2成分の幾何積として掲載します。

#### 3次元

平行四辺形が載っている面は様々な方向を向きます。向きは座標面に対する成分の比率で表現されます。

※ 具体的な形は、後で3成分の幾何積として掲載します。

## 3-ベクトル

同様の考え方で体積を表す**3-ベクトル**が定義できます。今回は4次元以上は対象外のため、3次元を前提とします。

簡単な例を示します。

```math
(2\mathbf{e_1})(3\mathbf{e_2})(4\mathbf{e_3})=24\mathbf{e_1e_2e_3}
```

左辺は辺が2と3と4の直方体を表して、右辺の $24$ は体積を表します。

互いに斜交している3本の1-ベクトルの外積は、それらが張る平行六面体の体積を表します。

※ ベクトル解析でのスカラー三重積や、3次正方行列の行列式に相当します。今回の範囲を超えるため詳細は省略します。

3-ベクトルでは向きが符号で表現されます。符号は基底の取り方に影響を受けます。面を張る3本の1-ベクトルが基底と同じ位置関係なら正となります。ややイメージが難しいのですが、鏡像反転で符号が反転するという振る舞いを意識しておけば良いでしょう。

※ 2次元の2-ベクトルと同じような振る舞いですが、どちらも後で述べる擬スカラーだからです。一般に、n次元のn-ベクトルは擬スカラーです。1次元の1-ベクトルも、数直線上の矢印をイメージすれば、向きが符号で表現されることが分かるでしょう。

## 式の展開

代数式のスタイルで記述すれば、ベクトルの掛け算を普通の代数式のように考えて扱うことができます。

比較対象として、ベクトルを使わない通常の式の展開を考えます。

#### 2変数

```py3
>>> from sympy import *
>>> x,y=symbols("x y")
>>> a,b,c,d=symbols("a b c d")
>>> (a*x+b*y)*(c*x+d*y)
(a*x + b*y)*(c*x + d*y)
>>> expand((a*x+b*y)*(c*x+d*y))
a*c*x**2 + a*d*x*y + b*c*x*y + b*d*y**2
>>> expand((a*x+b*y)*(c*x+d*y)).collect(x*y)
a*c*x**2 + b*d*y**2 + x*y*(a*d + b*c)
```
```math
\begin{align}
&(ax+by)(cx+dy) \\
&=ax(cx+dy) \\
&\quad +by(cx+dy) \\
&=acx^2+adxy \\
&\quad +bc\underbrace{yx}_{xy}+bdy^2 \\
&=acx^2+bdy^2+\underbrace{(ad+bc)xy}_{クロスターム}
\end{align}
```

可換性 $xy=yx$ を使って同類項をまとめていることに注意してください。

#### 3変数

```py3
>>> x,y,z=symbols("x y z")
>>> a1,a2,a3,b1,b2,b3=symbols("a1:4 b1:4")
>>> (a1*x+a2*y+a3*z)*(b1*x+b2*y+b3*z)
(a1*x + a2*y + a3*z)*(b1*x + b2*y + b3*z)
>>> expand((a1*x+a2*y+a3*z)*(b1*x+b2*y+b3*z))
a1*b1*x**2 + a1*b2*x*y + a1*b3*x*z + a2*b1*x*y + a2*b2*y**2 + a2*b3*y*z + a3*b1*x*z + a3*b2*y*z + a3*b3*z**2
>>> expand((a1*x+a2*y+a3*z)*(b1*x+b2*y+b3*z)).collect([x*y,y*z,z*x])
a1*b1*x**2 + a2*b2*y**2 + a3*b3*z**2 + x*y*(a1*b2 + a2*b1) + x*z*(a1*b3 + a3*b1) + y*z*(a2*b3 + a3*b2)
```
```math
\begin{align}
&(a_1+a_2y+a_3z)(b_1x+b_2y+b_3z) \\
&=a_1x(b_1x+b_2y+b_3z) \\
&\quad +a_2y(b_1x+b_2y+b_3z) \\
&\quad +a_3z(b_1x+b_2y+b_3z) \\
&=a_1b_1x^2+a_1b_2xy+a_1b_3\underbrace{xz}_{zx} \\
&\quad +a_2b_1\underbrace{yx}_{xy}+a_2b_2y^2+a_3b_3yz \\
&\quad +a_3b_1zx+a_3b_2\underbrace{zy}_{yz}+a_3b_3z^2 \\
&=a_1b_1x^2+a_2b_2y^2+a_3b_3z^2 \\
&\quad +\underbrace{(a_1b_2+a_2b_1)xy+(a_2b_3+a_3b_2)yz+(a_3b_1+a_1b_3)zx}_{クロスターム} \\
\end{align}
```

クロスタームの変数は巡回的（$x→y→z→x→\cdots$）に並べています。

## 幾何積

クリフォード代数ではベクトルの掛け算として**幾何積**が用意されています。これにより2本のベクトルから内積と外積を同時に計算できます。

異なる基底の積は結合します。

```math
【例】\ \mathbf{e_1e_2}
```

同じ基底の積は $1$ となります。これは内積を計算するためのルールです。

```math
【例】\ \mathbf{e_1e_1}=1
```

結合した基底の順番を入れ替えると符号が反転します。これを**反交換性**と呼びます。これは外積を計算するためのルールです。

```math
【例】\ \mathbf{e_1e_2}=-\mathbf{e_2e_1}
```

※ ここでの外積はウェッジ積と呼ばれるタイプと同じものです。

### 2成分

2次元の1-ベクトルは2成分で表現されます。それらの幾何積を計算します。先ほどの2変数の式の展開と比較してみてください。

```math
\begin{align}
&(a\mathbf{e_1}+b\mathbf{e_2})(c\mathbf{e_1}+d\mathbf{e_2}) \\
&=a\mathbf{e_1}(c\mathbf{e_1}+d\mathbf{e_2}) \\
&\quad +b\mathbf{e_2}(c\mathbf{e_1}+d\mathbf{e_2}) \\
&=ac\underbrace{\mathbf{e_1e_1}}_{1}+ad\mathbf{e_1e_2} \\
&\quad +bc\underbrace{\mathbf{e_2e_1}}_{-\mathbf{e_1e_2}}+bd\underbrace{\mathbf{e_2e_2}}_{1} \\
&=\underbrace{(ac+bd)}_{内積}+\underbrace{(ad-bc)\mathbf{e_1e_2}}_{外積} \\
\end{align}
```

同じ基底が $1$ になるルールから内積が、反交換性から外積が求まることが確認できます。外積はクロスタームの部分です。

外積の係数 $ad-bc$ は2本の1-ベクトルで張られる平行四辺形の面積です。これは2本の1-ベクトルを横に並べた行列の行列式と一致します。

```math
\det\left(\begin{array}{c|c}a&c\\b&d\end{array}\right)=ad-bc
```

### 3成分

3次元の1-ベクトルは3成分で表現されます。それらの幾何積を計算します。先ほどの3変数の式の展開と比較してみてください。

```math
\begin{align}
&(a_1\mathbf{e_1}+a_2\mathbf{e_2}+a_3\mathbf{e_3})(b_1\mathbf{e_1}+b_2\mathbf{e_2}+b_3\mathbf{e_3}) \\
&=a_1\mathbf{e_1}(b_1\mathbf{e_1}+b_2\mathbf{e_2}+b_3\mathbf{e_3}) \\
&\quad +a_2\mathbf{e_2}(b_1\mathbf{e_1}+b_2\mathbf{e_2}+b_3\mathbf{e_3}) \\
&\quad +a_3\mathbf{e_3}(b_1\mathbf{e_1}+b_2\mathbf{e_2}+b_3\mathbf{e_3}) \\
&=a_1b_1\underbrace{\mathbf{e_1e_1}}_{1}+a_1b_2\mathbf{e_1e_2}+a_1b_3\underbrace{\mathbf{e_1e_3}}_{-\mathbf{e_3e_1}} \\
&\quad +a_2b_1\underbrace{\mathbf{e_2e_1}}_{-\mathbf{e_1e_2}}+a_2b_2\underbrace{\mathbf{e_2e_2}}_{1}+a_2b_3\mathbf{e_2e_3} \\
&\quad +a_3b_1\mathbf{e_3e_1}+a_3b_2\underbrace{\mathbf{e_3e_2}}_{-\mathbf{e_2e_3}}+a_3b_3\underbrace{\mathbf{e_3e_3}}_{1} \\
&=\underbrace{(a_1b_1+a_2b_2+a_3b_3)}_{内積} \\
&\quad +\underbrace{(a_1b_2-a_2b_1)\mathbf{e_1e_2}+(a_2b_3-a_3b_2)\mathbf{e_2e_3}+(a_3b_1-a_1b_3)\mathbf{e_3e_1}}_{外積} \\
\end{align}
```

外積が3成分あるのは、2本のベクトルで張られる平行四辺形を、2-ベクトルの基底が表す $xy,yz,zx$ の座標軸上の面に射影して表しているためです。3成分により面の向きが表現されます。

平行四辺形の面積は3成分を2乗した和の平方根として得られます。

```math
\sqrt{(a_1b_2-a_2b_1)^2+(a_2b_3-a_3b_2)^2+(a_3b_1-a_1b_3)^2}
```

※ 直線の長さ $\sqrt{x^2+y^2+z^2}$ と同じ計算方法です。後述の擬ベクトルによって表されるベクトル積では長さが面積を表しますが、同じ考え方に基づきます。

## 形式和

3次元でのすべての基底は、無標示のスカラーを合わせると8種類です。形式的にすべてを多項式の形で並べます。（このような多項式を**形式和**と呼びます）

```math
\underbrace{a_0}_{スカラー}+\underbrace{a_1\mathbf{e_1}+a_2\mathbf{e_2}+a_3\mathbf{e_3}}_{1-ベクトル}+\underbrace{a_4\mathbf{e_1e_2}+a_5\mathbf{e_2e_3}+a_6\mathbf{e_3e_1}}_{2-ベクトル}+\underbrace{a_7\mathbf{e_1e_2e_3}}_{3-ベクトル}
```

## 擬ベクトル・擬スカラー

項の数に注目すると、スカラーと3-ベクトルが1項ずつ、1-ベクトルと2-ベクトルが3項ずつで同数です。

項の数が同じことから、2-ベクトルを擬似的に1-ベクトルとして扱うことがあります。そのような2-ベクトルに由来する1-ベクトルを**擬ベクトル**と呼びます。代表的な擬ベクトルは、ベクトル積と呼ばれるタイプの外積として現れます。

※ 1-ベクトルと2-ベクトルの対応関係は、後でホッジ双対として説明します。

同様に、3-ベクトルを擬似的にスカラーとして扱うことがあります。そのような3-ベクトルに由来するスカラーを**擬スカラー**と呼びます。

```math
\underbrace{a_0}_{スカラー}+\underbrace{a_1\mathbf{e_1}+a_2\mathbf{e_2}+a_3\mathbf{e_3}}_{ベクトル}+\underbrace{a_4\mathbf{e_1e_2}+a_5\mathbf{e_2e_3}+a_6\mathbf{e_3e_1}}_{擬ベクトル}+\underbrace{a_7\mathbf{e_1e_2e_3}}_{擬スカラー}
```

3次元の擬ベクトルは、2-ベクトルが表す面に対する法線に相当します。

※ 法線による面の表現は、3次元では1-ベクトルと2-ベクトルの成分の数が同じだという性質に依存しているため、一般の次元では成り立ちません。詳細は[外積と愉快な仲間たち](http://qiita.com/7shi/items/017d2d2c758f76071f23)を参照してください。

# パウリ行列

ここまでの説明では1-ベクトルをベクトルで表現しましたが、2-ベクトルや3-ベクトルは代数式のままで示しました。これらをまとめて同じサイズの行列で表して、幾何積もそのまま行列の積で計算できないでしょうか。言い換えれば、クリフォード代数は行列で表現できないでしょうか。

形式和は8項のため、すべての係数を格納するためには $ℝ^8$ の情報量が必要です。行列の積を計算するのには正方行列だと取り扱いが簡単なので、2次の複素正方行列にすれば、ちょうど収まります。

そのような行列を求めます。そしてそれが**パウリ行列**と呼ばれていることを見ます。

## スカラー

スカラーの基底は $1$ です。掛け算の単位元であることから、単位行列を割り当てます。

```math
1↦I=\left(\begin{matrix} 1 & 0 \\ 0 & 1 \end{matrix}\right)
```

## 1-ベクトル

それぞれの基底を複素化して、列を増やして未知数で埋めます。

```math
\begin{align}
\left(\begin{matrix} 1 \\ 0 \\ 0 \end{matrix}\right),
\left(\begin{matrix} 0 \\ 1 \\ 0 \end{matrix}\right),
\left(\begin{matrix} 0 \\ 0 \\ 1 \end{matrix}\right)
&\xrightarrow{複素化}
\left(\begin{matrix} 1 \\ 0 \end{matrix}\right),
\left(\begin{matrix} i \\ 0 \end{matrix}\right),
\left(\begin{matrix} 0 \\ 1 \end{matrix}\right) \\
&\xrightarrow{列を増やす}
\left(\begin{matrix} 1 & x_1 \\ 0 & y_1 \end{matrix}\right),
\left(\begin{matrix} i & x_2 \\ 0 & y_2 \end{matrix}\right),
\left(\begin{matrix} 0 & x_3 \\ 1 & y_3 \end{matrix}\right)
\end{align}
```

基底の2乗が $1$ になることから、解を求めます。`solve` は $=0$ となる方程式を指定するため、右辺の単位行列 `_1` を左辺に移項して `-_1` の形にしています。

```py3
>>> x1,x2,x3,y1,y2,y3=symbols("x1:4 y1:4")
>>> _1=eye(2)
>>> solve(Matrix([[1,x1],[0,y1]])**2-_1,[x1,y1])
[(0, -1), (0, 1)]
>>> solve(Matrix([[I,x2],[0,y2]])**2-_1,[x2,y2])
[]
>>> solve(Matrix([[0,x3],[1,y3]])**2-_1,[x3,y3])
[(1, 0)]
```
```math
\begin{align}
\left(\begin{matrix} 1 & x_1 \\ 0 & y_1 \end{matrix}\right)^2&=I&
∴(x_1,y_1)&=(0,-1),(0,1) \\
\left(\begin{matrix} i & x_2 \\ 0 & y_2 \end{matrix}\right)^2&=I&
∴(x_2,y_2)&=解なし \\
\left(\begin{matrix} 0 & x_3 \\ 1 & y_3 \end{matrix}\right)^2&=I&
∴(x_3,y_3)&=(1,0)
\end{align}
```

$(x_1,y_1)$ は解が2つありますが、$(0,1)$ は単位行列となり既にスカラーに割り当てられているため、$(0,-1)$ を採用します。

$(x_2,y_2)$ は解なしです。行列の成分を確認すれば、定数成分が異なるため未知数を求める以前に不成立となっていることが分かります。

```py3
>>> Matrix([[I,x2],[0,y2]])**2
Matrix([
[-1, x2*y2 + I*x2],
[ 0,        y2**2]])
```
```math
\left(\begin{matrix} i & x_2 \\ 0 & y_2 \end{matrix}\right)^2
=\left(\begin{matrix} -1 & x_2y_2+x_2i \\ 0 & y_2^2 \end{matrix}\right)
≠\left(\begin{matrix} 1 & 0 \\ 0 & 1 \end{matrix}\right)
```

これでは基底が揃わないため、代わりに $i$ を2行目に移してみます。

```py3
>>> x4,y4=symbols("x4 y4")
>>> solve(Matrix([[0,x4],[I,y4]])**2-_1,[x4,y4])
[(-I, 0)]
```
```math
\begin{align}
\left(\begin{matrix} 0 & x_4 \\ i & y_4 \end{matrix}\right)^2&=I&
∴(x_4,y_4)&=(-i,0)
\end{align}
```

これで基底が3つ揃いました。仮に $E$ とおきます。

```py3
>>> E=[Matrix([[1,0],[0,-1]]),Matrix([[0,1],[1,0]]),Matrix([[0,-I],[I,0]])]
```
```math
E_0,E_1,E_2:=
\left(\begin{matrix} 1 & 0 \\ 0 &-1 \end{matrix}\right),
\left(\begin{matrix} 0 & 1 \\ 1 & 0 \end{matrix}\right),
\left(\begin{matrix} 0 &-i \\ i & 0 \end{matrix}\right)
```

当初の想定からずれてしまったため、どれを $\mathbf{e_1},\mathbf{e_2},\mathbf{e_3}$ に割り当てるかを検討する必要があります。

## 3-ベクトル

1-ベクトルの基底の表現行列を決めるため、3-ベクトルの基底について考えます。

クリフォード代数では3-ベクトルの基底 $\mathbf{e_1e_2e_3}$ を2乗すると $-1$ になります。バブルソートの要領で交換を繰り返すことで確認できます。

```math
\begin{align}
(\mathbf{e_1e_2e_3})^2
&=\mathbf{e_1e_2}\underbrace{\mathbf{e_3e_1}}_{交換}\mathbf{e_2e_3} \\
&=-\mathbf{e_1}\underbrace{\mathbf{e_2e_1}}_{交換}\mathbf{e_3e_2e_3} \\
&=\mathbf{e_1e_1e_2}\underbrace{\mathbf{e_3e_2}}_{交換}\mathbf{e_3} \\
&=-\underbrace{\mathbf{e_1e_1}}_{1}\underbrace{\mathbf{e_2e_2}}_{1}\underbrace{\mathbf{e_3e_3}}_{1} \\
&=-1
\end{align}
```

$\mathbf{e_1e_2e_3}$ は2乗すれば $-1$ になることから虚数 $i$ と同一視されます（$\mathbf{e_1e_2e_3}=i$）。

※ 詳細は[ユークリッド空間のホッジ双対とバブルソート](http://qiita.com/7shi/items/f54302058149d07da592)を参照してください。

### 積の順番

先ほど求めた $E$ の順番を並べ替えて積を確認します。

```py3
>>> import itertools
>>> r=list(range(3))
>>> r
[0, 1, 2]
>>> p=list(itertools.permutations(r))
>>> p
[(0, 1, 2), (0, 2, 1), (1, 0, 2), (1, 2, 0), (2, 0, 1), (2, 1, 0)]
>>> for i,j,k in p: print(i,j,k,E[i]*E[j]*E[k])
...
0 1 2 Matrix([[I, 0], [0, I]])
0 2 1 Matrix([[-I, 0], [0, -I]])
1 0 2 Matrix([[-I, 0], [0, -I]])
1 2 0 Matrix([[I, 0], [0, I]])
2 0 1 Matrix([[I, 0], [0, I]])
2 1 0 Matrix([[-I, 0], [0, -I]])
```
```math
\begin{align}
E_0E_1E_2
&=\left(\begin{matrix} 1 & 0 \\ 0 &-1 \end{matrix}\right)
  \left(\begin{matrix} 0 & 1 \\ 1 & 0 \end{matrix}\right)
  \left(\begin{matrix} 0 &-i \\ i & 0 \end{matrix}\right)
 =\left(\begin{matrix} i & 0 \\ 0 & i \end{matrix}\right)=iI \\
E_0E_2E_1
&=\left(\begin{matrix} 1 & 0 \\ 0 &-1 \end{matrix}\right)
  \left(\begin{matrix} 0 &-i \\ i & 0 \end{matrix}\right)
  \left(\begin{matrix} 0 & 1 \\ 1 & 0 \end{matrix}\right)
 =\left(\begin{matrix}-i & 0 \\ 0 &-i \end{matrix}\right)=-iI \\
E_1E_0E_2
&=\left(\begin{matrix} 0 & 1 \\ 1 & 0 \end{matrix}\right)
  \left(\begin{matrix} 1 & 0 \\ 0 &-1 \end{matrix}\right)
  \left(\begin{matrix} 0 &-i \\ i & 0 \end{matrix}\right)
 =\left(\begin{matrix}-i & 0 \\ 0 &-i \end{matrix}\right)=-iI \\
E_1E_2E_0
&=\left(\begin{matrix} 0 & 1 \\ 1 & 0 \end{matrix}\right)
  \left(\begin{matrix} 0 &-i \\ i & 0 \end{matrix}\right)
  \left(\begin{matrix} 1 & 0 \\ 0 &-1 \end{matrix}\right)
 =\left(\begin{matrix} i & 0 \\ 0 & i \end{matrix}\right)=iI \\
E_2E_0E_1
&=\left(\begin{matrix} 0 &-i \\ i & 0 \end{matrix}\right)
  \left(\begin{matrix} 1 & 0 \\ 0 &-1 \end{matrix}\right)
  \left(\begin{matrix} 0 & 1 \\ 1 & 0 \end{matrix}\right)
 =\left(\begin{matrix} i & 0 \\ 0 & i \end{matrix}\right)=iI \\
E_2E_1E_0
&=\left(\begin{matrix} 0 &-i \\ i & 0 \end{matrix}\right)
  \left(\begin{matrix} 0 & 1 \\ 1 & 0 \end{matrix}\right)
  \left(\begin{matrix} 1 & 0 \\ 0 &-1 \end{matrix}\right)
 =\left(\begin{matrix}-i & 0 \\ 0 &-i \end{matrix}\right)=-iI
\end{align}
```

$E_0E_1E_2,E_1E_2E_0,E_2E_0E_1$ の3つの組み合わせで、単位行列の $i$ 倍となることが分かりました。

※ $iI$ となる組み合わせは右手系を成しています。また、並べ方が巡回的（$0→1→2→0→1→\cdots$）になっています。どの組み合わせを選んでも同型の表現が得られます。

### 選定

後は決めの問題です。見た目から $E_1$ が簡単な形（符号が付かず、単位行列を鏡像反転）をしているため、これを $\mathbf{e_1}$ の表現行列として選びます。$\mathbf{e_1}$ が決まれば後の組み合わせは自動的に決まります。この組み合わせは**パウリ行列**と呼ばれ、$σ_1,σ_2,σ_3$ と表記します。

```py3
>>> s1,s2,s3=Matrix([[0,1],[1,0]]),Matrix([[0,-I],[I,0]]),Matrix([[1,0],[0,-1]])
```
```math
\mathbf{e_1},\mathbf{e_2},\mathbf{e_3} \mapsto σ_1,σ_2,σ_3 :=
\left(\begin{matrix} 0 & 1 \\ 1 & 0 \end{matrix}\right),
\left(\begin{matrix} 0 &-i \\ i & 0 \end{matrix}\right),
\left(\begin{matrix} 1 & 0 \\ 0 &-1 \end{matrix}\right)
```

3-ベクトルの基底の表現を改めて確認します。

```math
\mathbf{e_1e_2e_3}=i \quad\cong\quad σ_1σ_2σ_3=iI
```

この記事では $\mathbf{e_n}$ と $σ_n$ を以下のように使い分けます。

* $\mathbf{e_n}$: クリフォード代数での計算
* $σ_n$: 表現行列での計算

## 2-ベクトル

表現行列が決まったので、機械的な計算となります。

すべての組み合わせの表現行列を確認します。

```py3
>>> s1*s2
Matrix([
[I,  0],
[0, -I]])
>>> s2*s1
Matrix([
[-I, 0],
[ 0, I]])
>>> s2*s3
Matrix([
[0, I],
[I, 0]])
>>> s3*s2
Matrix([
[ 0, -I],
[-I,  0]])
>>> s3*s1
Matrix([
[ 0, 1],
[-1, 0]])
>>> s1*s3
Matrix([
[0, -1],
[1,  0]])
```
```math
\begin{align}
\mathbf{e_1e_2}&\mapsto σ_1σ_2=\left(\begin{matrix} i & 0 \\ 0 &-i \end{matrix}\right) \\
\mathbf{e_2e_1}&\mapsto σ_2σ_1=\left(\begin{matrix}-i & 0 \\ 0 & i \end{matrix}\right) \\
\mathbf{e_2e_3}&\mapsto σ_2σ_3=\left(\begin{matrix} 0 & i \\ i & 0 \end{matrix}\right) \\
\mathbf{e_3e_2}&\mapsto σ_3σ_2=\left(\begin{matrix} 0 &-i \\-i & 0 \end{matrix}\right) \\
\mathbf{e_3e_1}&\mapsto σ_3σ_1=\left(\begin{matrix} 0 & 1 \\-1 & 0 \end{matrix}\right) \\
\mathbf{e_1e_3}&\mapsto σ_1σ_3=\left(\begin{matrix} 0 &-1 \\ 1 & 0 \end{matrix}\right)
\end{align}
```

反交換性を確認します。

```py3
>>> s1*s2==-s2*s1
True
>>> s2*s3==-s3*s2
True
>>> s3*s1==-s1*s3
True
```

### ホッジ双対

同じ基底の幾何積が $1$ になる性質を使えば、3-ベクトルの基底 $i=\mathbf{e_1e_2e_3}$ を崩して2-ベクトルの基底にできます。

```math
\begin{align}
i\mathbf{e_1}&=\mathbf{e_1e_2e_3e_1}=\mathbf{e_1e_1e_2e_3}=\mathbf{e_2e_3} \\
i\mathbf{e_2}&=\mathbf{e_1e_2e_3e_2}=-\mathbf{e_1e_2e_2e_3}=-\mathbf{e_1e_3}=\mathbf{e_3e_1} \\
i\mathbf{e_3}&=\mathbf{e_1e_2e_3e_3}=\mathbf{e_1e_2}
\end{align}
```

$i$ に掛けた基底が相殺するため、後に残るのはそれ以外の基底です。このような相補的な関係を**ホッジ双対**と呼びます。

```math
\mathbf{e_1} \overset{ホッジ双対}{\longleftrightarrow} \mathbf{e_2e_3} \\
\mathbf{e_2} \overset{ホッジ双対}{\longleftrightarrow} \mathbf{e_3e_1} \\
\mathbf{e_3} \overset{ホッジ双対}{\longleftrightarrow} \mathbf{e_1e_2}
```

※ 2-ベクトルのホッジ双対として1-ベクトルを得る操作は、単純に虚数を掛けるだけではありません。詳細は[ユークリッド空間のホッジ双対とバブルソート](http://qiita.com/7shi/items/f54302058149d07da592)を参照してください。

パウリ行列で同じ計算をしてみます。

```py3
>>> I*s1
Matrix([
[0, I],
[I, 0]])
>>> I*s2
Matrix([
[ 0, 1],
[-1, 0]])
>>> I*s3
Matrix([
[I,  0],
[0, -I]])
>>> I*s1==s2*s3
True
>>> I*s2==s3*s1
True
>>> I*s3==s1*s2
True
```
```math
iσ_1,iσ_2,iσ_3=
\left(\begin{matrix} 0 & i \\ i & 0 \end{matrix}\right),
\left(\begin{matrix} 0 & 1 \\-1 & 0 \end{matrix}\right),
\left(\begin{matrix} i & 0 \\ 0 &-i \end{matrix}\right) \\
iσ_1=σ_2σ_3,\ iσ_2=σ_3σ_1,\ iσ_3=σ_1σ_2
```

クリフォード代数は基底を交換して消しますが、パウリ行列は成分に虚数を掛けているだけです。算出方法がまったく異なるのに同じ結果になるのが面白い所です。パウリ行列の計算だけを見ていると3-ベクトルの基底を崩していることが分からないため、クリフォード代数の視点と合わせることで解釈できるようになります。

## まとめ

クリフォード代数では基底を並べる形（例: $\mathbf{e_1e_2}$）が標準的な記法です。それに対してパウリ行列の計算では、成分を計算して共通因子として $i$ を括り出した形が標準的です。

基底の対応関係を示します。

```math
\begin{align}
1                  &\mapsto  I   =\left(\begin{matrix} 1 & 0 \\ 0 & 1 \end{matrix}\right) \\
\mathbf{e_1}       &\mapsto  σ_1=\left(\begin{matrix} 0 & 1 \\ 1 & 0 \end{matrix}\right) \\
\mathbf{e_2}       &\mapsto  σ_2=\left(\begin{matrix} 0 &-i \\ i & 0 \end{matrix}\right) \\
\mathbf{e_3}       &\mapsto  σ_3=\left(\begin{matrix} 1 & 0 \\ 0 &-1 \end{matrix}\right) \\
\mathbf{e_1e_2}    &\mapsto iσ_3=\left(\begin{matrix} i & 0 \\ 0 &-i \end{matrix}\right) \\
\mathbf{e_2e_3}    &\mapsto iσ_1=\left(\begin{matrix} 0 & i \\ i & 0 \end{matrix}\right) \\
\mathbf{e_3e_1}    &\mapsto iσ_2=\left(\begin{matrix} 0 & 1 \\-1 & 0 \end{matrix}\right) \\
\mathbf{e_1e_2e_3} &\mapsto iI   =\left(\begin{matrix} i & 0 \\ 0 & i \end{matrix}\right)
\end{align}
```

形式和の表現を比較します。

```math
\begin{align}
&\underbrace{a_0}_{スカラー}+\underbrace{a_1\mathbf{e_1}+a_2\mathbf{e_2}+a_3\mathbf{e_3}}_{1-ベクトル}+\underbrace{a_4\mathbf{e_1e_2}+a_5\mathbf{e_2e_3}+a_6\mathbf{e_3e_1}}_{2-ベクトル}+\underbrace{a_7\mathbf{e_1e_2e_3}}_{3-ベクトル} \\
&\mapsto \underbrace{a_0I}_{スカラー}+\underbrace{a_1σ_1+a_2σ_2+a_3σ_3}_{1-ベクトル}+\underbrace{a_4iσ_3+a_5iσ_1+a_6iσ_2}_{2-ベクトル}+\underbrace{a_7iI}_{3-ベクトル} \\
&=a_0\underbrace{\left(\begin{matrix} 1 & 0 \\ 0 & 1 \end{matrix}\right)}_{I}
 +a_1\underbrace{\left(\begin{matrix} 0 & 1 \\ 1 & 0 \end{matrix}\right)}_{σ_1}
 +a_2\underbrace{\left(\begin{matrix} 0 &-i \\ i & 0 \end{matrix}\right)}_{σ_2}
 +a_3\underbrace{\left(\begin{matrix} 1 & 0 \\ 0 &-1 \end{matrix}\right)}_{σ_3} \\
&\quad
 +a_4\underbrace{\left(\begin{matrix} i & 0 \\ 0 &-i \end{matrix}\right)}_{iσ_3}
 +a_5\underbrace{\left(\begin{matrix} 0 & i \\ i & 0 \end{matrix}\right)}_{iσ_1}
 +a_6\underbrace{\left(\begin{matrix} 0 & 1 \\-1 & 0 \end{matrix}\right)}_{iσ_2}
 +a_7\underbrace{\left(\begin{matrix} i & 0 \\ 0 & i \end{matrix}\right)}_{iI} \\
&=\left(\begin{matrix} a_0+a_3+a_4i+a_7i & a_1-a_2i+a_5i+a_6 \\ a_1+a_2i+a_5i-a_6 & a_0-a_3-a_4i+a_7i \end{matrix}\right)
\end{align}
```

パウリ行列の表現では、スカラーと1-ベクトルの基底にホッジ双対を表す $i$ を掛けたもので擬スカラーや擬ベクトルが表現されています。対応関係が分かりやすいように項を並べ替えて示します。

```math
\begin{align}
&\underbrace{a_0I}_{スカラー}+\underbrace{a_1σ_1+a_2σ_2+a_3σ_3}_{ベクトル} \\
&+\underbrace{i}_{ホッジ双対}
(\underbrace{a_7I}_{擬スカラー}+\underbrace{a_5σ_1+a_6σ_2+a_4σ_3}_{擬ベクトル})
\end{align}
```

※ 擬ベクトルとホッジ双対の関係が式で直接的に表現されています。

# 四元数

2-ベクトルの基底は2乗すれば $-1$ になります。パウリ行列で計算する方が分かりやすいかもしれません。

```math
(\mathbf{e_1e_2})^2=\mathbf{e_1e_2e_1e_2}=-\mathbf{\underbrace{e_1e_1}_{1}\underbrace{e_2e_2}_{1}}=-1 \\
(iσ_3)^2=\underbrace{i^2}_{-1}\underbrace{σ_3^2}_{1}=-1
```

2-ベクトルの基底は3種類あるので、四元数の $i,j,k$ に対応させられそうです。

## 符号

$ij=k$ の再現を試みます。しかし単純に掛けるとマイナスが付いてしまいます。

```math
(\mathbf{e_2e_3})(\mathbf{e_3e_1})=\mathbf{e_2e_3e_3e_1}=-\mathbf{e_1e_2} \\
(iσ_1)(iσ_2)=i^2σ_1σ_2=-iσ_3
```

それなら逆転の発想で、$i,j,k$ に対応する基底に最初からマイナスを付けてしまいます。

```math
\begin{align}
i,j,k
&\mapsto -\mathbf{e_2e_3},-\mathbf{e_3e_1},-\mathbf{e_1e_2} \\
&\mapsto -iσ_1,-iσ_2,-iσ_3
\end{align}
```

こうしておけば $ij=k$ もうまく再現できます。

```math
\underbrace{(-\mathbf{e_2e_3})}_{i}\underbrace{(-\mathbf{e_3e_1})}_{j}=\underbrace{-\mathbf{e_1e_2}}_{k} \\
\underbrace{(-iσ_1)}_{i}\underbrace{(-iσ_2)}_{j}=\underbrace{-iσ_3}_{k} \\
```

## まとめ

四元数はスカラー（符号そのまま）と2-ベクトル（符号反転）に相当します。

```math
\begin{align}
&\underbrace{a}_{スカラー}+\underbrace{bi+cj+dk}_{2-ベクトル} \\
&\mapsto a-b\mathbf{e_2e_3}-c\mathbf{e_3e_1}-d\mathbf{e_1e_2} \\
&\mapsto aI-biσ_1-ciσ_2-diσ_3 \\
&=a\left(\begin{matrix} 1 & 0 \\ 0 & 1 \end{matrix}\right)
 -b\left(\begin{matrix} 0 & i \\ i & 0 \end{matrix}\right)
 -c\left(\begin{matrix} 0 & 1 \\-1 & 0 \end{matrix}\right)
 -d\left(\begin{matrix} i & 0 \\ 0 &-i \end{matrix}\right) \\
&=a \underbrace{\left(\begin{matrix} 1& 0 \\ 0& 1 \end{matrix}\right)}_{1}
 +b \underbrace{\left(\begin{matrix} 0&-i \\-i& 0 \end{matrix}\right)}_{i}
 +c \underbrace{\left(\begin{matrix} 0&-1 \\ 1& 0 \end{matrix}\right)}_{j}
 +d \underbrace{\left(\begin{matrix}-i& 0 \\ 0& i \end{matrix}\right)}_{k} \\
&=\left(\begin{matrix}a-di & -bi-c \\ -bi+c & a+di\end{matrix}\right) \\
&=\left(\begin{matrix}(a+di)^* & -(c+bi) \\ (c+bi)^* & a+di\end{matrix}\right)
\end{align}
```

クリフォード代数を基準にしてみます。

```math
\begin{align}
&a+b\mathbf{e_1e_2}+c\mathbf{e_2e_3}+d\mathbf{e_3e_1} \\
&\mapsto aI+biσ_3+ciσ_1+diσ_2 \\
&\mapsto a-bk-ci-dj
\end{align}
```

# 双四元数

四元数をクリフォード代数で解釈すればスカラーと2-ベクトルに相当することが分かりました。しかしそれではクリフォード代数としては不完全なため、四元数を拡張して1-ベクトルを扱う方法を考えます。

2-ベクトルに虚数（3-ベクトルの基底）を掛ければ1-ベクトルに変換できます。

```math
i(\mathbf{e_2e_3})=\mathbf{e_1e_2e_3e_2e_3}=-\mathbf{e_1e_2e_2e_3e_3}=-\mathbf{e_1} \\
i(iσ_1)=-σ_1
```

※ 符号が反転していますが、これはホッジ双対ではありません。詳細は[ユークリッド空間のホッジ双対とバブルソート](http://qiita.com/7shi/items/f54302058149d07da592)を参照してください。

四元数に3-ベクトルの基底となる新しい虚数 $h$ を追加すれば、既存の元 $i,j,k$ との複合によりクリフォード代数と同型になります。そのように拡張された四元数を**双四元数**と呼びます。

```math
\begin{align}
&(a_0+a_1i+a_2j+a_3k)+\underbrace{(a_4+a_5i+a_6j+a_7k)}_{複合}\underbrace{h}_{追加} \\
&=\underbrace{a_0}_{スカラー}+\underbrace{a_1i+a_2j+a_3k}_{2-ベクトル}+\underbrace{a_4h}_{3-ベクトル}+\underbrace{a_5hi+a_6hj+a_7hk}_{1-ベクトル}
\end{align}
```

$hi,hj,hk$ とパウリ行列の対応を確認します。

```math
\begin{align}
hi &\mapsto \underbrace{i}_{h}\underbrace{(-iσ_1)}_{i}=σ_1 \\
hj &\mapsto \underbrace{i}_{h}\underbrace{(-iσ_2)}_{j}=σ_2 \\
hk &\mapsto \underbrace{i}_{h}\underbrace{(-iσ_3)}_{k}=σ_3 \\
∴hi,hj,hk &\mapsto σ_1,σ_2,σ_3
\end{align}
```

双四元数を基準にしたクリフォード代数やパウリ行列との対応は以下の通りです。

```math
\begin{align}
&\underbrace{a_0}_{スカラー}+\underbrace{a_1i+a_2j+a_3k}_{2-ベクトル}+\underbrace{a_4h}_{3-ベクトル}+\underbrace{a_5hi+a_6hj+a_7hk}_{1-ベクトル} \\
&\mapsto a_0-a_1\mathbf{e_2e_3}-a_2\mathbf{e_3e_1}-a_3\mathbf{e_1e_2}+a_4\mathbf{e_1e_2e_3}+a_5\mathbf{e_1}+a_6\mathbf{e_2}+a_7\mathbf{e_3} \\
&\mapsto a_0I-a_1iσ_1-a_2iσ_2-a_3iσ_3+a_4iI+a_5σ_1+a_6σ_2+a_7σ_3 \\
&=a_0\left(\begin{matrix} 1 & 0 \\ 0 & 1 \end{matrix}\right)
 -a_1\left(\begin{matrix} 0 & i \\ i & 0 \end{matrix}\right)
 -a_2\left(\begin{matrix} 0 & 1 \\-1 & 0 \end{matrix}\right)
 -a_3\left(\begin{matrix} i & 0 \\ 0 &-i \end{matrix}\right) \\
&\quad
 +a_4\left(\begin{matrix} i & 0 \\ 0 & i \end{matrix}\right)
 +a_5\left(\begin{matrix} 0 & 1 \\ 1 & 0 \end{matrix}\right)
 +a_6\left(\begin{matrix} 0 &-i \\ i & 0 \end{matrix}\right)
 +a_7\left(\begin{matrix} 1 & 0 \\ 0 &-1 \end{matrix}\right) \\
&=a_0\underbrace{\left(\begin{matrix} 1& 0 \\ 0& 1 \end{matrix}\right)}_{1}
 +a_1\underbrace{\left(\begin{matrix} 0&-i \\-i& 0 \end{matrix}\right)}_{i}
 +a_2\underbrace{\left(\begin{matrix} 0&-1 \\ 1& 0 \end{matrix}\right)}_{j}
 +a_3\underbrace{\left(\begin{matrix}-i& 0 \\ 0& i \end{matrix}\right)}_{k} \\
&\quad
 +a_4\underbrace{\left(\begin{matrix} i& 0 \\ 0& i \end{matrix}\right)}_{h}
 +a_5\underbrace{\left(\begin{matrix} 0& 1 \\ 1& 0 \end{matrix}\right)}_{hi}
 +a_6\underbrace{\left(\begin{matrix} 0&-i \\ i& 0 \end{matrix}\right)}_{hj}
 +a_7\underbrace{\left(\begin{matrix} 1& 0 \\ 0&-1 \end{matrix}\right)}_{hk} \\
&=\left(\begin{matrix} a_0-a_3i+a_4i+a_7 & -a_1i-a_2+a_5-a_6i \\ -a_1i+a_2+a_5+a_6i & a_0+a_3i+a_4i-a_7 \end{matrix}\right) \\
&=\left(\begin{matrix} (a_0+a_7)-(a_3-a_4)i & -\{(a_2-a_5)+(a_1+a_6)i\} \\ (a_2+a_5)-(a_1-a_6)i & (a_0-a_7)+(a_3+a_4)i \end{matrix}\right) \\
&=\left(\begin{matrix} \{(a_0+a_7)+(a_3-a_4)i\}^* & -\{(a_2-a_5)+(a_1+a_6)i\} \\ \{(a_2+a_5)+(a_1-a_6)i\}^* & (a_0-a_7)+(a_3+a_4)i \end{matrix}\right)
\end{align}
```

クリフォード代数を基準にしてみます。

```math
\begin{align}
&a_0+a_1\mathbf{e_1}+a_2\mathbf{e_2}+a_3\mathbf{e_3}+a_4\mathbf{e_1e_2}+a_5\mathbf{e_2e_3}+a_6\mathbf{e_3e_1}+a_7\mathbf{e_1e_2e_3} \\
&\mapsto a_0I+a_1σ_1+a_2σ_2+a_3σ_3+a_4iσ_3+a_5iσ_1+a_6iσ_2+a_7iI \\
&\mapsto a_0+a_1hi+a_2hj+a_3hk-a_4k-a_5i-a_6j+a_7h
\end{align}
```

このように双四元数と3次元のクリフォード代数とパウリ行列は同型です。この観点から、四元数が扱う対象は3次元のユークリッド空間で、四元数は双四元数の形にして完成されたと言えます。

双四元数では2次形式の $hi,hj,hk$ がクリフォード代数では1次形式 $\mathbf{e_1},\mathbf{e_2},\mathbf{e_3}$ で、逆に、双四元数では1次形式の $i,j,k$ がクリフォード代数では2次形式 $\mathbf{e_3e_2},\mathbf{e_1e_3},\mathbf{e_2e_1}$ なのが興味深い点です（四元数とクリフォード代数の2-ベクトルでは符号が異なりますが、反交換性により順序の入れ替えで表現しています）。概念として何が原子的で何が複合的なのか混乱しそうですが、幾何学的な意味を持たせるのであれば、クリフォード代数の解釈に従う方が無難だと感じます。

# 分解型四元数

前々回の記事（[表現行列で考える双複素数](http://qiita.com/7shi/items/050f6615558c4c2b1d92)）では双複素数と2次元のクリフォード代数がほぼ対応していることを見ましたが、一部の計算結果に違いがありました。それに対して、双四元数を2次元に制限すれば完全な同型対応が得られます。

2次元での1-ベクトルは $hj,hk$ だけで扱えます。その複合によって得られる2-ベクトルは $i$ だけです。2次元では2-ベクトルが擬スカラーとなるため、3-ベクトルはありません。

```math
\underbrace{a}_{スカラー}+\underbrace{bi}_{2-ベクトル}+\underbrace{chj+dhk}_{1-ベクトル}
```

※ 1-ベクトルに使う元の選択には任意性があります。別の組み合わせ（$hi,hj$ など）にしても問題はありませんが、次に見るように文字の付け替えで対応関係が分かりにくくなります。

便宜上、文字を付け替えます。このように双四元数を2次元に制限して文字を付け替えた数を**分解型四元数**と呼びます。

```math
a+bi+chj+dhk\ \mapsto\ a+bi+cj+dk
```

※ 歴史的な事情で $j,k$ を1-ベクトルに割り当てるため、ここでは対応関係が分かりやすい $hj,hk$ を選びました。

分解型四元数を基準にしたクリフォード代数やパウリ行列との対応は以下の通りです。双複素数とは異なり完全な同型対応です。

※ 3次元での $hj,hk$ やパウリ行列と対比するため、以下の数式では意図的に $\mathbf{e_2},\mathbf{e_3}$ を使用しています。本来、2次元では $\mathbf{e_1},\mathbf{e_2}$ と表記すべきものです。

```math
\begin{align}
&\underbrace{a}_{スカラー}+\underbrace{bi}_{2-ベクトル}+\underbrace{cj+dk}_{1-ベクトル} \\
&\mapsto a-b\mathbf{e_2e_3}+c\mathbf{e_2}+d\mathbf{e_3} \\
&\mapsto aI-biσ_1+cσ_2+dσ_3 \\
&=a\left(\begin{matrix} 1 & 0 \\ 0 & 1 \end{matrix}\right)
 -b\left(\begin{matrix} 0 & i \\ i & 0 \end{matrix}\right)
 +c\left(\begin{matrix} 0 &-i \\ i & 0 \end{matrix}\right)
 +d\left(\begin{matrix} 1 & 0 \\ 0 &-1 \end{matrix}\right) \\
&=a\underbrace{\left(\begin{matrix} 1& 0 \\ 0& 1 \end{matrix}\right)}_{1}
 +b\underbrace{\left(\begin{matrix} 0&-i \\-i& 0 \end{matrix}\right)}_{i}
 +c\underbrace{\left(\begin{matrix} 0&-i \\ i& 0 \end{matrix}\right)}_{j}
 +d\underbrace{\left(\begin{matrix} 1& 0 \\ 0&-1 \end{matrix}\right)}_{k} \\
&=\left(\begin{matrix} a+d & -bi-ci \\ -bi+ci & a-d \end{matrix}\right)
\end{align}
```

※ 基底の選択に任意性があると言いましたが、$hk,hi$ （巡回的な並べ方による）を採用すれば表現行列の成分がすべて実数になります。

クリフォード代数を基準にしてみます。

```math
\begin{align}
&a+b\mathbf{e_2}+c\mathbf{e_3}+d\mathbf{e_2e_3} \\
&\mapsto aI+bσ_2+cσ_3+diσ_1 \\
&\mapsto a+bi+cj-dk
\end{align}
```

※ 分解型四元数は双複素数による伏線の回収という意味で紹介しました。実用上は素直にクリフォード代数を使った方が簡単だと思います。

# 関連記事

この記事のクリフォード代数についての記述は、以下の記事をベースに再構成しました。

* [外積と愉快な仲間たち](http://qiita.com/7shi/items/017d2d2c758f76071f23) 2016.10.26

ホッジ双対やバブルソートについては以下の記事を参照してください。

* [ユークリッド空間のホッジ双対とバブルソート](http://qiita.com/7shi/items/f54302058149d07da592) 2016.10.31

双四元数や分解型四元数については以下の記事を参照してください。

* [八元数を作ろう](http://qiita.com/7shi/items/b34fe724d36fb7d96456) 2016.12.06

# 参考

双四元数とクリフォード代数の関係について参考にさせていただきました。この記事のお陰で、最後のピースを埋めることができました。

* [Martin Erik Horn (2007) "Quaternionen and Geometric Algebra (Quaternionen und Geometrische Algebra)"](https://arxiv.org/abs/0709.2238)

四元数とパウリ行列によって8次元空間（双四元数によって表されるのと同じ空間）が構成されることや、表現行列の求め方が詳しく説明されています。

* 【PDF】 [吉井洋二・上林一彦(2009)『パウリ行列と4元数』](http://akita-nct.jp/libra/report/45/45107.pdf)

SymPyで方程式を解く方法や数式の出力形式について参考にさせていただきました。

* [Solvers — SymPy 1.0.1.dev documentation](http://docs.sympy.org/dev/modules/solvers/solvers.html)
* [Printing — SymPy 1.0.1.dev documentation](http://docs.sympy.org/dev/tutorial/printing.html)

Pythonでの順列について参考にさせていただきました。

* @zaburo: [Pythonで順列と組み合わせ](http://qiita.com/zaburo/items/9a8564edfb81e02599ce) 2015.12.26

# 多元数

[多元数](https://ja.wikipedia.org/wiki/%E5%A4%9A%E5%85%83%E6%95%B0)のバリエーションをまとめました。

基本|双|分解型|分解型双|双曲|二重（双対）|多重
----|----|----|----|----|----|----
[実数](https://ja.wikipedia.org/wiki/%E5%AE%9F%E6%95%B0)|||||[二重数](https://ja.wikipedia.org/wiki/%E4%BA%8C%E9%87%8D%E6%95%B0)|
[複素数](https://ja.wikipedia.org/wiki/%E8%A4%87%E7%B4%A0%E6%95%B0)|[双複素数](https://en.wikipedia.org/wiki/bicomplex_number)|[分解型複素数](https://ja.wikipedia.org/wiki/%E5%88%86%E8%A7%A3%E5%9E%8B%E8%A4%87%E7%B4%A0%E6%95%B0)|||[二重複素数](https://qiita.com/skitaoka/items/c05d0ea04a3b6269563a)|[多重複素数](https://ja.wikipedia.org/wiki/%E5%A4%9A%E9%87%8D%E8%A4%87%E7%B4%A0%E6%95%B0)
[四元数](https://ja.wikipedia.org/wiki/%E5%9B%9B%E5%85%83%E6%95%B0)|[双四元数](https://en.wikipedia.org/wiki/biquaternion)|[分解型四元数](https://en.wikipedia.org/wiki/Split-quaternion)|[分解型双四元数](https://en.wikipedia.org/wiki/split-biquaternion)|[双曲四元数](https://en.wikipedia.org/wiki/hyperbolic_quaternion)|[二重四元数](https://en.wikipedia.org/wiki/Dual_quaternion)|
[八元数](https://ja.wikipedia.org/wiki/%E5%85%AB%E5%85%83%E6%95%B0)|[双八元数](https://en.wikipedia.org/wiki/Bioctonion)|[分解型八元数](https://en.wikipedia.org/wiki/split-octonion)|||
[十六元数](https://ja.wikipedia.org/wiki/%E5%8D%81%E5%85%AD%E5%85%83%E6%95%B0)||||||
