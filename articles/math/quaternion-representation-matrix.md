---
coediting: false
comments_count: 0
created_at: '2017-03-14T23:40:49+09:00'
id: e7364e1b2593f24427a5
likes_count: 16
private: false
reactions_count: 0
stocks_count: 9
tags:
- name: Python
  versions: []
- name: sympy
  versions: []
- name: 数学
  versions: []
- name: 四元数
  versions: []
- name: 線形代数
  versions: []
title: 表現行列で考える四元数
updated_at: '2017-04-12T11:32:46+09:00'
url: https://qiita.com/7shi/items/e7364e1b2593f24427a5
slide: false
---

複素数の表現行列の成分に複素数を入れても四元数の表現行列にはなりません。しかし似た形になることが予想されるため、それを手掛かりに四元数の表現行列を探ります。双四元数を取り入れれば見通しが良くなることにも触れます。SymPyによる計算を添えます。

シリーズの記事です。

1. [実ベクトルで考える複素ベクトル](http://qiita.com/7shi/items/4f313cb36cdd12c8d833)
1. [表現行列で考える双複素数](http://qiita.com/7shi/items/050f6615558c4c2b1d92)
1. 表現行列で考える四元数 ← この記事
1. [クリフォード代数で考えるパウリ行列と双四元数](http://qiita.com/7shi/items/fafe77f9a5ff2f9651ba)

この記事には関連記事があります。

* [四元数を作ろう](http://qiita.com/7shi/items/2036e7a739c2a9e04025) 2016.12.03
* [八元数を作ろう](http://qiita.com/7shi/items/b34fe724d36fb7d96456) 2016.12.06

# 双複素数

[前回の記事](http://qiita.com/7shi/items/050f6615558c4c2b1d92)で、双複素数の表現行列を求めました。

```math
\begin{align}
&a+bi+cj+dk \\
&=(a+bi)+(c+di)j \\
&↦\left(\begin{matrix}a+bi & -(c+di) \\ c+di & a+bi\end{matrix}\right) \\
&=a \underbrace{\left(\begin{matrix} 1& 0 \\ 0& 1 \end{matrix}\right)}_{1}
 +b \underbrace{\left(\begin{matrix} i& 0 \\ 0& i \end{matrix}\right)}_{i}
 +c \underbrace{\left(\begin{matrix} 0&-1 \\ 1& 0 \end{matrix}\right)}_{j}
 +d \underbrace{\left(\begin{matrix} 0&-i \\ i& 0 \end{matrix}\right)}_{ij=k}
\end{align}
```

この構造を参考にしながら、四元数の表現行列を考えます。

# 四元数

四元数では $i,j,k$ はどれも2乗すれば $-1$ になります。

```math
i^2=j^2=k^2=-1
```

双複素数では $k^2=1$ となり、四元数数とは異なります。しかし $ij=k$ という関係は四元数でも共通するため、$i$ と $j$ の定義を修正することで $k^2=-1$ に持ち込めないものでしょうか。

## 表現行列

$j$ は複素数の表現行列から引き継いでいるため、四元数でも共通した方が好都合です。$j$ はそのままにして、$i$ の成分を未知数 $x,y,z,w$ とします。SymPyで計算の準備をします。

```py3
>>> from sympy import *
>>> x,y,z,w=symbols("x y z w")
>>> i=Matrix([[x,y],[z,w]])
>>> j=Matrix([[0,-1],[1,0]])
```
```math
\begin{align}
i&↦\left(\begin{matrix} x& z \\ y& w \end{matrix}\right) \\
j&↦\left(\begin{matrix} 0&-1 \\ 1& 0 \end{matrix}\right)
\end{align}
```

$i^2=-1,\ k=ij,\ k^2=-1$ より

```py3
>>> i**2
Matrix([
[x**2 + y*z,  w*y + x*y],
[ w*z + x*z, w**2 + y*z]])
>>> k=i*j
>>> k
Matrix([
[y, -x],
[w, -z]])
>>> k**2
Matrix([
[-w*x + y**2,  -x*y + x*z],
[  w*y - w*z, -w*x + z**2]])
```
```math
\begin{align}
i^2&↦\left(\begin{matrix} x& y \\ z& w \end{matrix}\right)^2
=\left(\begin{matrix} x^2+yz & wy+xy \\ wz+xz & w^2+yz \end{matrix}\right)
=\left(\begin{matrix} -1 & 0 \\ 0 & -1 \end{matrix}\right) \\
k^2&↦\left(\begin{matrix} y & -x \\ w & -z \end{matrix}\right)^2
=\left(\begin{matrix} -wx+y^2 & -xy+xz \\ wy-wz & -wx+z^2 \end{matrix}\right)
=\left(\begin{matrix} -1 & 0 \\ 0 & -1 \end{matrix}\right)
\end{align}
```

成分を比較して関係を整理します。

```math
x^2+yz=w^2+yz=y^2-xw=z^2-xw=-1 \\
y(x+w)=z(x+w)=x(y-z)=w(y-z)=0
```

解は一意には求まりませんが、満たすべき関係は判明します。

```math
x=-w,\ y=z,\ x^2+y^2=-1
```

### iの選定

なるべく簡単な形が望ましいので $0$ が2つある解に絞ります。

```math
\begin{align}
(1)&\ x=0\ ⇒\ w=0,\ y^2=-1,\ y=z \\
(2)&\ y=0\ ⇒\ z=0,\ x^2=-1,\ x=-w
\end{align}
```

具体形で書けば、次の四択となります。

```math
\left(\begin{matrix} x & z \\ y & w \end{matrix}\right)
=\left(\begin{matrix} 0 & ±i \\ ±i & 0 \end{matrix}\right),
 \left(\begin{matrix} ±i & 0 \\ 0 & ∓i \end{matrix}\right)\ (複号同順)
```

後は決めの問題です。ここでは $i$ を掛けて虚数を取り除いた形を基準にします。

```math
i\left(\begin{matrix} 0 & ±i \\ ±i & 0 \end{matrix}\right),
i\left(\begin{matrix} ±i & 0 \\ 0 & ∓i \end{matrix}\right)
=\left(\begin{matrix} 0 & ∓1 \\ ∓1 & 0 \end{matrix}\right),
 \left(\begin{matrix} ∓1 & 0 \\ 0 & ±1 \end{matrix}\right)\ (複号同順)
```

※ 後述しますが、$i$ を掛けるのは双四元数の視点です。

右辺の4つの形の中で一番シンプルなのは、マイナス符号が付かない次の形ではないでしょうか。単位行列を上下（または左右）に鏡像反転（転置ではない）した行列です。

```math
i\left(\begin{matrix} 0 & -i \\ -i & 0 \end{matrix}\right)
=\left(\begin{matrix} 0 &  1 \\  1 & 0 \end{matrix}\right)
```

左辺から $i$ の表現行列を決めます。

```math
i↦\left(\begin{matrix} 0 & -i \\ -i & 0 \end{matrix}\right)
```

### kの確認

$i$ を決めれば $k$ は自動的に決まります。`I` はSymPyで定義された虚数 $i$ です。

```py3
>>> i=Matrix([[0,-I],[-I,0]])
>>> j=Matrix([[0,-1],[1,0]])
>>> k=i*j
>>> k
Matrix([
[-I, 0],
[ 0, I]])
```
```math
k=ij
↦\left(\begin{matrix} 0&-i \\-i& 0 \end{matrix}\right)
 \left(\begin{matrix} 0&-1 \\ 1& 0 \end{matrix}\right)
=\left(\begin{matrix}-i& 0 \\ 0& i \end{matrix}\right)
```

### まとめ

以上で、四元数の表現行列が得られました。まとめると次の通りです。

```math
\begin{align}
&a+bi+cj+dk \\
&↦a \underbrace{\left(\begin{matrix} 1& 0 \\ 0& 1 \end{matrix}\right)}_{1}
 +b \underbrace{\left(\begin{matrix} 0&-i \\-i& 0 \end{matrix}\right)}_{i}
 +c \underbrace{\left(\begin{matrix} 0&-1 \\ 1& 0 \end{matrix}\right)}_{j}
 +d \underbrace{\left(\begin{matrix}-i& 0 \\ 0& i \end{matrix}\right)}_{k} \\
&=\left(\begin{matrix}a-di & -(c+bi) \\ c-bi & a+di\end{matrix}\right) \\
&=\left(\begin{matrix}(a+di)^* & -(c+bi) \\ (c+bi)^* & a+di\end{matrix}\right)
\end{align}
```

あまりすっきりした形ではありませんが、後で説明する双四元数を見れば、このようにした理由が明らかになります。

※ 四元数だけに限定すれば、もっときれいな別表現があります。詳細は[八元数を作ろう](http://qiita.com/7shi/items/b34fe724d36fb7d96456)を参照してください。

## 行列式

表現行列の成分には複素共役が現れて、行列式がノルムの2乗になることを意識しておくと良いです。

```math
\begin{align}
&\det\left(\begin{matrix}(a+di)^* & -(c+bi) \\ (c+bi)^* & a+di\end{matrix}\right) \\
&=(a+di)^*(a+di)+(c+bi)^*(c+bi) \\
&=a^2+b^2+c^2+d^2 \\
&=||a+bi+cj+dk||^2
\end{align}
```

## 演算規則の確認

四元数の演算規則を満たしているか確認します。

### 元の2乗

元の2乗を確認します。

```py3
>>> i**2
Matrix([
[-1,  0],
[ 0, -1]])
>>> j**2
Matrix([
[-1,  0],
[ 0, -1]])
>>> k**2
Matrix([
[-1,  0],
[ 0, -1]])
```
```math
\begin{align}
i^2
&↦\left(\begin{matrix} 0&-i \\-i& 0 \end{matrix}\right)^2
 =\left(\begin{matrix}-1& 0 \\ 0&-1 \end{matrix}\right) \\
j^2
&↦\left(\begin{matrix} 0&-1 \\ 1& 0 \end{matrix}\right)^2
 =\left(\begin{matrix}-1& 0 \\ 0&-1 \end{matrix}\right) \\
k^2
&↦\left(\begin{matrix}-i& 0 \\ 0& i \end{matrix}\right)^2
 =\left(\begin{matrix}-1& 0 \\ 0&-1 \end{matrix}\right)
\end{align}
```

$i^2=j^2=k^2=-1$ となりました。

### 巡回性

四元数は元の因子と積の関係が巡回的（$i→j→k→i→j→\cdots$）に表れます。

```math
ij=k,\ jk=i,\ ki=j
```

巡回性を確認します。

```py3
>>> i*j
Matrix([
[-I, 0],
[ 0, I]])
>>> j*k
Matrix([
[ 0, -I],
[-I,  0]])
>>> k*i
Matrix([
[0, -1],
[1,  0]])
>>> i*j==k
True
>>> j*k==i
True
>>> k*i==j
True
```

### 反交換性

四元数の元には積の順番を入れ替えると符号が反転する性質があり、反交換性と呼びます。

```math
ij=-ji,\ jk=-kj,\ ki=-ik
```

$ij=k$ と $k^2=-1$ の関係も、反交換性により説明できます。反交換性により因子が自由に移動できないため、隣接した元を交換して同じ元を隣接させなければ $-1$ にできません。

```math
k^2=(ij)^2=i\underbrace{(ji)}_{交換}j=-i(ij)j=-\underbrace{(ii)}_{-1}\underbrace{(jj)}_{-1}=-1
```

反交換性を確認します。

```py3
>>> j*i
Matrix([
[I,  0],
[0, -I]])
>>> k*j
Matrix([
[0, I],
[I, 0]])
>>> i*k
Matrix([
[ 0, 1],
[-1, 0]])
>>> i*j==-j*i
True
>>> j*k==-k*j
True
>>> k*i==-i*k
True
```

※ 反交換性は元同士の積のルールですが、そのまま多項式には拡張できません。同じ元同士は $-1$ になってしまうためです。

```math
(i+2j)(3j+4k)=3ij+4ik+6jj+8jk=-6+8i-4j+3k \\
(3j+4k)(i+2j)=3ji+4ki+6jj+8kj=-6-8i+4j-3k \\
∴(i+2j)(3j+4k)≠-(3j+4k)(i+2j)
```

## 共役

表現行列のエルミート共役から、四元数の共役が得られます。

```math
\begin{align}
(a+bi+cj+dk)^*
↦&\left(\begin{matrix}(a+di)^* & -(c+bi) \\ (c+bi)^* & a+di\end{matrix}\right)^{\dagger} \\
=&\left(\begin{matrix}a+di & -(c+bi)^* \\ c+bi & (a+di)^*\end{matrix}\right)^{\top} \\
=&\left(\begin{matrix}a+di & c+bi \\ -(c+bi)^* & (a+di)^*\end{matrix}\right) \\
=&\left(\begin{matrix}(a-di)^* & c+bi \\ -(c+bi)^* & a-di\end{matrix}\right) \\
↦&(a-dk)-(cj+bi) \\
=&a-bi-cj-dk
\end{align}
```

虚部の符号がすべて反転しています。

# 双四元数

今回採用した $i,j,k$ の表現行列は次の基準で選定したものでした。

* $j$ は複素数における $i$ の表現行列を引き継ぐ
* $i$ の表現行列は、成分に $i$ を掛けてシンプルな形になるものを選ぶ

```math
i,j,k↦
\left(\begin{matrix} 0&-i \\-i& 0 \end{matrix}\right),
\left(\begin{matrix} 0&-1 \\ 1& 0 \end{matrix}\right),
\left(\begin{matrix}-i& 0 \\ 0& i \end{matrix}\right)
```

四元数の元としての $i$ と、表現行列に含まれる成分としての $i$ は別物です。元での表記では成分に掛ける虚数は区別のため $h$ と書きます。

```math
\begin{align}
hi,hj,hk
&↦\underbrace{i}_{h}\underbrace{\left(\begin{matrix} 0&-i \\-i& 0 \end{matrix}\right)}_{i},
  \underbrace{i}_{h}\underbrace{\left(\begin{matrix} 0&-1 \\ 1& 0 \end{matrix}\right)}_{j},
  \underbrace{i}_{h}\underbrace{\left(\begin{matrix}-i& 0 \\ 0& i \end{matrix}\right)}_{k} \\
&=\left(\begin{matrix} 0& 1 \\ 1& 0 \end{matrix}\right),
  \left(\begin{matrix} 0&-i \\ i& 0 \end{matrix}\right),
  \left(\begin{matrix} 1& 0 \\ 0&-1 \end{matrix}\right)
\end{align}
```

※ [前回の記事](http://qiita.com/7shi/items/050f6615558c4c2b1d92)で双複素数を得る際に、元としての $i$ と表現行列の成分の $i$ を区別するために $j$ を導入したのと同じ手法です。

四元数に $h$ を元として追加すれば、双四元数と呼ばれる四元数を拡張した数になります。

```math
\begin{align}
&(a_0+a_1i+a_2j+a_3k)+(a_4+a_5i+a_6j+a_7k)h \\
&=a_0+a_1i+a_2j+a_3k+a_4h+a_5hi+a_6hj+a_7hk
\end{align}
```

四元数から双四元数への拡張は、複素数から双複素数への拡張と同じ手法です。（[ケーリー=ディクソンの構成法](https://ja.wikipedia.org/wiki/%E3%82%B1%E3%83%BC%E3%83%AA%E3%83%BC%EF%BC%9D%E3%83%87%E3%82%A3%E3%82%AF%E3%82%BD%E3%83%B3%E3%81%AE%E6%A7%8B%E6%88%90%E6%B3%95)）

```math
【双複素数】\ (a_0+a_1i)+(a_2+a_3i)j=a_0+a_1i+a_2j+a_3k
```

$h$ を行列で表現するなら、単位行列に $i$ を掛けた行列になります。

```math
h↦iI
=i\left(\begin{matrix} 1& 0 \\ 0& 1 \end{matrix}\right)
= \left(\begin{matrix} i& 0 \\ 0& i \end{matrix}\right)
```

単位行列は他の行列と交換するため、双四元数では $h$ は反交換性の対象外です。

```math
【双四元数】\ hi=ih,\ hj=jh,\ hk=kh
```

双複素数が四元数とは別物なのと同様に、双四元数は八元数とは別物です。八元数では $h$ が他の元と同列に扱われ、反交換性を持ちます。

```math
【八元数】\ hi=-ih,\ hj=-jh,\ hk=-kh
```

※ 八元数についての詳細は[八元数を作ろう](http://qiita.com/7shi/items/b34fe724d36fb7d96456)を参照してください。

## 表現行列

双四元数の表現行列を確認します。

```math
\begin{align}
&a_0+a_1i+a_2j+a_3k+a_4h+a_5hi+a_6hj+a_7hk \\
&↦a_0\underbrace{\left(\begin{matrix} 1& 0 \\ 0& 1 \end{matrix}\right)}_{1}
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

※ 斜めに隣接した $1$ と $hi$、$j$ と $hk$ の表現行列が、上下反転した形で対応しているのに注目してください。そのように見れば、それなりにきれいな形をしています。

```math
\underbrace{\left(\begin{matrix} 1& 0 \\ 0& 1 \end{matrix}\right)}_{1}
\xrightarrow{上下反転}
\underbrace{\left(\begin{matrix} 0& 1 \\ 1& 0 \end{matrix}\right)}_{hi} \\
\underbrace{\left(\begin{matrix} 0&-1 \\ 1& 0 \end{matrix}\right)}_{j}
\xrightarrow{上下反転}
\underbrace{\left(\begin{matrix} 1& 0 \\ 0&-1 \end{matrix}\right)}_{hk}
```

ここまで来てようやく明らかになりましたが、四元数の表現行列を決める基準は、双四元数まで含めて考えていたわけです。

※ 双四元数はマイナーなため言及されることが少ない視点です。

## Python

Pythonで双四元数の表現行列を構築します。単位行列と $j$ から他の元を作ります。

```py3
>>> from sympy import *
>>> _1=eye(2)
>>> j=Matrix([[0,-1],[1,0]])
>>> hi=_1[[1,0],:]
>>> hk=j[[1,0],:]
>>> h=I*_1
>>> hj=I*j
>>> i=-I*hi
>>> k=-I*hk
>>> a=symbols("a0:8")
>>> a
(a0, a1, a2, a3, a4, a5, a6, a7)
>>> A=a[0]*_1+a[1]*i+a[2]*j+a[3]*k+a[4]*h+a[5]*hi+a[6]*hj+a[7]*hk
>>> A
Matrix([
[ a0 - I*a3 + I*a4 + a7, -I*a1 - a2 + a5 - I*a6],
[-I*a1 + a2 + a5 + I*a6,  a0 + I*a3 + I*a4 - a7]])
```
```math
A=\left(\begin{matrix} a_0-a_3i+a_4i+a_7 & -a_1i-a_2+a_5-a_6i \\ -a_1i+a_2+a_5+a_6i & a_0+a_3i+a_4i-a_7 \end{matrix}\right)
```

## 係数の分離

双四元数の表現行列は成分が入り組んでいます。表現行列の成分から双四元数の係数を分離するには、符号が反転した組み合わせを利用します。

```py3
>>> (A[0,0]+A[1,1])/2
a0 + I*a4
>>> (A[0,0]-A[1,1])/2
-I*a3 + a7
>>> (A[1,0]+A[0,1])/2
-I*a1 + a5
>>> (A[1,0]-A[0,1])/2
a2 + I*a6
```
```math
\begin{align}
\frac{1}{2}(A_{00}+A_{11})&=a_0+a_4i \\
\frac{1}{2}(A_{00}-A_{11})&=a_7-a_3i \\
\frac{1}{2}(A_{10}+A_{01})&=a_5-a_1i \\
\frac{1}{2}(A_{10}-A_{01})&=a_2+a_6i
\end{align}
```

例を挙げます。

```py3
>>> B=A.subs([(a[i], i+1) for i in range(8)])
>>> B
Matrix([
[  9 + I,  3 - 9*I],
[9 + 5*I, -7 + 9*I]])
>>> b=[0]*8
>>> b[0],b[4]=((B[0,0]+B[1,1])/2).as_real_imag()
>>> b[7],b[3]=((B[0,0]-B[1,1])/2).conjugate().as_real_imag()
>>> b[5],b[1]=((B[1,0]+B[0,1])/2).conjugate().as_real_imag()
>>> b[2],b[6]=((B[1,0]-B[0,1])/2).as_real_imag()
>>> b
[1, 2, 3, 4, 5, 6, 7, 8]
```
```math
\left(\begin{matrix} 9+i & 3-9i \\ 9+5i & -7+9i \end{matrix}\right) \\
↦1+2i+3j+4k+5h+6hi+7hj+8hk
```

表現行列を一瞥しただけでは双四元数の係数は分かりませんが、きちんと分離できています。

※ 行列の成分が4つで、それぞれに複素数が入っているので、表現行列には $ℝ^8$ の情報量があります。双四元数の表現行列はその情報量を使い切っています。

# パウリ行列

$hi,hj,hk$ の表現行列を[パウリ行列](https://ja.wikipedia.org/wiki/%E3%83%91%E3%82%A6%E3%83%AA%E8%A1%8C%E5%88%97)と呼びます。

```math
σ_1,σ_2,σ_3:=
\underbrace{\left(\begin{matrix} 0& 1 \\ 1& 0 \end{matrix}\right)}_{hi},
\underbrace{\left(\begin{matrix} 0&-i \\ i& 0 \end{matrix}\right)}_{hj},
\underbrace{\left(\begin{matrix} 1& 0 \\ 0&-1 \end{matrix}\right)}_{hk}
```

パウリ行列を出発点にすれば、双四元数をよりスマートに構築できます。それによれば $i,j,k$ よりも $hi,hj,hk$ の方がより根源的だと解釈できます。詳細は続編の[クリフォード代数で考えるパウリ行列と双四元数](http://qiita.com/7shi/items/fafe77f9a5ff2f9651ba)を参照してください。

# 関連記事

今回は四元数については表現行列の観点だけに留めます。その他の性質などについては、以下の記事を参照してください。

* [四元数を作ろう](http://qiita.com/7shi/items/2036e7a739c2a9e04025) 2016.12.03

四元数の別の表現行列や八元数については以下の記事を参照してください。

* [八元数を作ろう](http://qiita.com/7shi/items/b34fe724d36fb7d96456) 2016.12.06

# 参考

SymPyについて参考にさせていただきました。

* [3.2. Sympy : Python での代数計算 — Scipy lecture notes](http://www.turbare.net/transl/scipy-lecture-notes/packages/sympy.html)
* [Matrices (linear algebra) — SymPy 1.0.1.dev documentation](http://docs.sympy.org/dev/modules/matrices/matrices.html)
* [Simplification — SymPy 1.0 documentation](http://docs.sympy.org/latest/tutorial/simplification.html)

# 多元数

[多元数](https://ja.wikipedia.org/wiki/%E5%A4%9A%E5%85%83%E6%95%B0)のバリエーションをまとめました。

基本|双|分解型|分解型双|双曲|双対
----|----|----|----|----|----
[複素数](https://ja.wikipedia.org/wiki/%E8%A4%87%E7%B4%A0%E6%95%B0)|[双複素数](https://en.wikipedia.org/wiki/bicomplex_number)|[分解型複素数](https://ja.wikipedia.org/wiki/%E5%88%86%E8%A7%A3%E5%9E%8B%E8%A4%87%E7%B4%A0%E6%95%B0)|||
[四元数](https://ja.wikipedia.org/wiki/%E5%9B%9B%E5%85%83%E6%95%B0)|[双四元数](https://en.wikipedia.org/wiki/biquaternion)|[分解型四元数](https://en.wikipedia.org/wiki/Split-quaternion)|[分解型双四元数](https://en.wikipedia.org/wiki/split-biquaternion)|[双曲四元数](https://en.wikipedia.org/wiki/hyperbolic_quaternion)|[双対四元数](https://en.wikipedia.org/wiki/Dual_quaternion)
[八元数](https://ja.wikipedia.org/wiki/%E5%85%AB%E5%85%83%E6%95%B0)|[双八元数](https://en.wikipedia.org/wiki/Bioctonion)|[分解型八元数](https://en.wikipedia.org/wiki/split-octonion)||
[十六元数](https://ja.wikipedia.org/wiki/%E5%8D%81%E5%85%AD%E5%85%83%E6%95%B0)|||||
