---
coediting: false
comments_count: 0
created_at: '2017-03-14T12:03:01+09:00'
id: 050f6615558c4c2b1d92
likes_count: 8
private: false
reactions_count: 0
stocks_count: 10
tags:
- name: Python
  versions: []
- name: sympy
  versions: []
- name: 数学
  versions: []
- name: 線形代数
  versions: []
title: 表現行列で考える双複素数
updated_at: '2017-04-12T11:31:19+09:00'
url: https://qiita.com/7shi/items/050f6615558c4c2b1d92
slide: false
---

複素数の表現行列の成分に複素数を入れれば双複素数と呼ばれる数が得られます。双複素数は四元数とは似て非なるものですが、表現行列からその性質を探ります。2次元のクリフォード代数と同一視できることにも言及します。SymPyによる計算を添えます。

シリーズの記事です。

1. [実ベクトルで考える複素ベクトル](http://qiita.com/7shi/items/4f313cb36cdd12c8d833)
1. 表現行列で考える双複素数 ← この記事
1. [表現行列で考える四元数](http://qiita.com/7shi/items/e7364e1b2593f24427a5)
1. [クリフォード代数で考えるパウリ行列と双四元数](http://qiita.com/7shi/items/fafe77f9a5ff2f9651ba)

この記事には関連記事があります。

* [外積と愉快な仲間たち](http://qiita.com/7shi/items/017d2d2c758f76071f23) 2016.10.26
* [四元数を作ろう](http://qiita.com/7shi/items/2036e7a739c2a9e04025) 2016.12.03

# 複素数の複素数

[前回の記事](http://qiita.com/7shi/items/4f313cb36cdd12c8d833)で、複素数の表現行列を求めました。

```py3
>>> a,b=symbols("a b",real=True)
>>> _1=eye(2)
>>> i=Matrix([[0,-1],[1,0]])
>>> a*_1+b*i
Matrix([
[a, -b],
[b,  a]])
```
```math
a+bi
↦a\underbrace{\left(\begin{matrix}1 &  0 \\ 0 & 1\end{matrix}\right)}_{1}
+b\underbrace{\left(\begin{matrix}0 & -1 \\ 1 & 0\end{matrix}\right)}_{i}
=\left(\begin{matrix}a & -b \\ b & a\end{matrix}\right)
```

表現行列の成分に複素数を入れてみます。

```py3
>>> c,d=symbols("c d",real=True)
>>> (a+b*I)*_1+(c+d*I)*i
Matrix([
[a + I*b, -c - I*d],
[c + I*d,  a + I*b]])
```
```math
 (a+bi)\left(\begin{matrix}1 &  0 \\ 0 & 1\end{matrix}\right)
+(c+di)\left(\begin{matrix}0 & -1 \\ 1 & 0\end{matrix}\right)
=\left(\begin{matrix}a+bi & -(c+di) \\ c+di & a+bi\end{matrix}\right)
```

これをどのように数式に戻せば良いでしょうか。単純に考えると次のようになりそうですが、おかしなことになります。

```py3
>>> expand((a+b*I)+(c+d*I)*I).collect(I)
a - d + I*(b + c)
```
```math
\begin{align}
\left(\begin{matrix}a+bi & -(c+di) \\ c+di & a+bi\end{matrix}\right)
↦&(a+bi)+(c+di)i \\
=&a+bi+ci-d \\
=&(a-d)+(b+c)i \\
↦&\left(\begin{matrix}a-d & -(b+c) \\ b+c & a-d\end{matrix}\right) ?
\end{align}
```

$i$ が1種類しかなく、結合したり同類項になったりするのが、おかしくなった原因です。それを防ぐには、係数 $c+di$ の $i$ と、その外側にある $i$ は別物として扱う必要があります。外側の $i$ を区別のため $j$ とします。

```math
\begin{align}
\left(\begin{matrix}a+bi & -(c+di) \\ c+di & a+bi\end{matrix}\right)
↦&(a+bi)+(c+di)j \\
=&a+bi+cj+dij
\end{align}
```

$i,j,ij$ の表現行列を分離します。便宜上 $ij=k$ とします。

```math
\begin{align}
&\left(\begin{matrix}a+bi & -(c+di) \\ c+di & a+bi\end{matrix}\right) \\
&=a \underbrace{\left(\begin{matrix} 1& 0 \\ 0& 1 \end{matrix}\right)}_{1}
 +b \underbrace{\left(\begin{matrix} i& 0 \\ 0& i \end{matrix}\right)}_{i}
 +c \underbrace{\left(\begin{matrix} 0&-1 \\ 1& 0 \end{matrix}\right)}_{j}
 +d \underbrace{\left(\begin{matrix} 0&-i \\ i& 0 \end{matrix}\right)}_{ij=k} \\
&↦a+bi+cj+dk
\end{align}
```

何やら四元数っぽいものが出て来ました。結論から言うとこれは四元数ではなく、[前回の記事](http://qiita.com/7shi/items/4f313cb36cdd12c8d833)にも少し出て来た**双複素数**と呼ばれる別物です。

※ [Wikipedia](https://en.wikipedia.org/wiki/bicomplex_number)の表現行列とは異なりますが、基本的な性質は同じです。以下の記事では同じ定義を採用しています。

* Davenport, Clyde M. (2008). ["Commutative Hypercomplex Mathematics"](http://web.archive.org/web/20151002102049id_/http://home.comcast.net/~cmdaven/hyprcplx.htm). Archived from the [original](http://home.comcast.net/~cmdaven/hyprcplx.htm) on 2 October 2015.

# 双複素数

双複素数の性質を見て行きます。

## ij=k

$i$ の表現行列は単位行列の虚数倍なので、それが掛かった行列の成分を虚数倍します。$ij=k$ は $j$ の成分を虚数倍したものだと理解できます。

```py3
>>> _1=eye(2)
>>> i=I*_1
>>> j=Matrix([[0,-1],[1,0]])
>>> i*j
Matrix([
[0, -I],
[I,  0]])
>>> I*j
Matrix([
[0, -I],
[I,  0]])
```
```math
\begin{align}
i&↦iI=\left(\begin{matrix} i& 0 \\ 0& i \end{matrix}\right) \\
j&↦\left(\begin{matrix} 0&-1 \\ 1& 0 \end{matrix}\right) \\
k=ij&↦i\left(\begin{matrix} 0&-1 \\ 1& 0 \end{matrix}\right)
      =\left(\begin{matrix} 0&-i \\ i& 0 \end{matrix}\right)
\end{align}
```

## 元の2乗

虚数単位 $i,j,k$ を**元**と呼びます。元の2乗を確認します。

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
[1, 0],
[0, 1]])
```
```math
\begin{align}
i^2
&↦\left(\begin{matrix} i& 0 \\ 0& i \end{matrix}\right)^2
 =\left(\begin{matrix}-1& 0 \\ 0&-1 \end{matrix}\right) \\
j^2
&↦\left(\begin{matrix} 0&-1 \\ 1& 0 \end{matrix}\right)^2
 =\left(\begin{matrix}-1& 0 \\ 0&-1 \end{matrix}\right) \\
k^2
&↦\left(\begin{matrix} 0&-i \\ i& 0 \end{matrix}\right)^2
 =\left(\begin{matrix} 1& 0 \\ 0& 1 \end{matrix}\right)
\end{align}
```

$i^2=j^2=-1,\ k^2=1$ となりました。

$i$ と $j$ は2乗すると $-1$ になる虚数ですが、表現行列を見れば別物だということが分かります。$k$ は2乗すると $1$ になりますが、$k$ の表現行列は単位行列ではなく、やはり虚数の一種だということが分かります。

このように虚数は一種類ではなく、また2乗の値も $-1$ だけでなく $1$ になることもあり得るわけです。

$k^2$ は代数的な計算とも辻褄が合います。

```math
k^2=(ij)^2=i^2j^2=(-1)(-1)=1
```

※ 四元数ではこの計算は成り立ちません。

## 可換性

単位行列は可換で、その虚数倍の $i$ も可換です。つまり $ij=ji$ です。

```py3
>>> i*j==j*i
True
```
```math
ji↦\left(\begin{matrix} 0&-1 \\ 1& 0 \end{matrix}\right)i
  =\left(\begin{matrix} 0&-i \\ i& 0 \end{matrix}\right)
```

同様に $ki=ik$ です。

```py3
>>> k*i==i*k
True
```

$jk=kj$ は、$k=ij$ より $i$ と $j$ だけの計算に還元できるため、やはり可換です。

```py3
>>> k*i==i*k
True
```
```math
j\underbrace{k}_{ij}=\underbrace{ji}_{交換}j=\underbrace{ij}_{k}j=kj
```

つまり双複素数の元 $i,j,k$ は可換です。

※ 非可換な四元数に比べて計算が簡単です。

### 表現行列

双複素数が可換（commutative）であることを表現行列で確認します。

```py3
>>> a,b,c,d=symbols("a b c d",commutative=True)
>>> A=Matrix([[a,-b],[b,a]])
>>> B=Matrix([[c,-d],[d,c]])
>>> A*B
Matrix([
[a*c - b*d, -a*d - b*c],
[a*d + b*c,  a*c - b*d]])
>>> B*A
Matrix([
[a*c - b*d, -a*d - b*c],
[a*d + b*c,  a*c - b*d]])
>>> A*B==B*A
True
```
```math
a,b,c,d∈\mathbb{C} \\
A=\left(\begin{matrix} a & -b \\ b & a \end{matrix}\right),
B=\left(\begin{matrix} c & -d \\ d & c \end{matrix}\right) \\
AB=\left(\begin{matrix} ac-bd & -ad-bc \\ ad+bc & ac-bd \end{matrix}\right) \\
BA=\left(\begin{matrix} ac-bd & -ad-bc \\ ad+bc & ac-bd \end{matrix}\right) \\
∴AB=BA
```

成分 $a,b,c,d$ の和や積が可換であれば、行列の積も可換になることが確認できました。

## 元の積

別種の元の積は、1つの別の元になります。

```math
\begin{align}
ij&=k\ (定義) \\
jk&=jij=ij^2=-i \\
ki&=iji=i^2j=-j
\end{align}
```

まとめると次のようになります。

```math
ij=ji=k,\ jk=kj=-i,\ ki=ik=-j
```

* $i,j,k$ のうちの2つを掛けると、残りの1つが出て来ます。
* 因子に $k$ が含まれると積はマイナスになります。

元の積が別の元に変換されることから、3つ以上の積でも常にどれか1つの元に収まり、新しい元が生まれることはありません。この性質を**乗法に関して閉じている**と表現します。

## 共役

表現行列のエルミート共役から、双複素数の共役が得られます。

```py3
>>> a,b,c,d=symbols("a b c d",real=True)
>>> a*_1+b*i+c*j+d*k
Matrix([
[a + I*b, -c - I*d],
[c + I*d,  a + I*b]])
>>> (a*_1+b*i+c*j+d*k).H
Matrix([
[ a - I*b, c - I*d],
[-c + I*d, a - I*b]])
```
```math
\begin{align}
(a+bi+cj+dk)^*
↦&\left(\begin{matrix}a+bi & -(c+di) \\ c+di & a+bi\end{matrix}\right)^{\dagger} \\
=&\left(\begin{matrix}a-bi & c-di \\ -(c-di) & a-bi\end{matrix}\right) \\
↦&(a-bi)-(c-di)j \\
=&a-bi-cj+dk
\end{align}
```

$i,j$ の符号が反転します。$k$ が反転しないのは、$k=ij$ により二重に反転することで相殺されたと解釈できます。

※ この結果は[Wikipedia](https://en.wikipedia.org/wiki/bicomplex_number)の定義とは異なります。

## 共役との積

$j,k$ で2次元ベクトルを表して共役との積を計算すれば、実部が内積、$i$ の項が外積となります。

```py3
>>> _1=eye(2)
>>> i=I*_1
>>> j=Matrix([[0,-1],[1,0]])
>>> k=i*j
>>> a=symbols("a0:4",real=True)
>>> b=symbols("b0:4",real=True)
>>> A=a[1]*i+a[2]*k
>>> B=b[1]*i+b[2]*k
>>> A=a[1]*j+a[2]*k
>>> B=b[1]*j+b[2]*k
>>> A.H*B
Matrix([
[(a1 - I*a2)*(b1 + I*b2),                         0],
[                      0, (-a1 + I*a2)*(-b1 - I*b2)]])
>>> expand(A.H*B)[0,0].collect(I)
a1*b1 + a2*b2 + I*(a1*b2 - a2*b1)
```
```math
\underbrace{(a_1j+a_2k)^*}_{共役}(b_1j+b_2k)
=\underbrace{(a_1b_1+a_2b_2)}_{内積}+\underbrace{(a_1b_2-a_2b_1)i}_{外積}
```

これは複素数でも同じような計算ができます。つまり双複素数の計算能力自体は複素数と同じです。

```math
【複素数】\ (a_1+a_2i)^*(b_1+b_2i)=(a_1b_1+a_2b_2)+(a_1b_2-a_2b_1)i
```

複素数ではベクトルも実部と虚部で表すため意味が状況依存ですが、双複素数では増えた元によって区別することができます。

※ 複素数と双複素数の対応関係は次の節で表にまとめます。

### クリフォード代数

内積・外積が目的であれば、より洗練されたクリフォード代数の幾何学積という計算方法があります。ベクトルと内積（スカラー）と外積（面積）の基底が区別されます。

```math
\underbrace{(a_1\mathbf{e}_1+a_2\mathbf{e}_2)}_{ベクトル}
\underbrace{(b_1\mathbf{e}_1+b_2\mathbf{e}_2)}_{ベクトル}
=\underbrace{(a_1b_1+a_2b_2)}_{内積}
+\underbrace{(a_1b_2-a_2b_1)\mathbf{e}_1\mathbf{e}_2}_{外積} \\
```

複素数や双複素数とクリフォード代数の対応関係は以下の通りです。

複素数|双複素数|クリフォード代数|解釈
------|--------|----------------|----
実部  |$j$     |$\mathbf{e}_ 1$ |$x$ 軸方向の単位ベクトル（基底）
$i$   |$k$     |$\mathbf{e}_ 2$ |$y$ 軸方向の単位ベクトル（基底）
実部  |実部    |スカラー        |内積
$i$   |$i$     |$\mathbf{e}_ 1\mathbf{e}_ 2$|外積（2本のベクトルが張る平行四辺形の面積）

※ 基底ベクトルに $i,k$ を割り当てても計算結果は同じになります。ここでは続編の[クリフォード代数で考えるパウリ行列と双四元数](http://qiita.com/7shi/items/fafe77f9a5ff2f9651ba)で説明する分解型四元数に合わせて $j,k$ を割り当てています。

複素数や双複素数とは異なる点として、幾何学積はルールとして反交換性（$\mathbf{e}_ 1\mathbf{e}_ 2=-\mathbf{e}_ 2\mathbf{e}_ 1$）を持っているため、クリフォード代数では共役を明示する必要がありません。言い換えれば、共役の役割を反交換性に置き替えています。

### 積と共役

双複素数とクリフォード代数を対応付ける際に、積は前の因子を共役にします。しかし共役によって反交換性が表せるのは、因子の片方が共役で変化しないときだけです。そのため $i,j$ の組み合わせでは反交換性が現れず、クリフォード代数と双複素数とは完全には一致しません。

```math
\begin{align}
i^*i&=-i^2=1& &\not\cong& (e_1e_2)(e_1e_2)&=-e_1e_1e_2e_2=-1 \\
j^*j&=-j^2=1& &\cong&     e_1e_1&=1 \\
k^*k&=k^2=1&  &\cong&     e_2e_2&=1 \\
i^*j&=-ij=-k& &\cong&     (e_1e_2)e_1&=-e_1e_1e_2=-e_2 \\
j^*i&=-ji=-k& &\not\cong& e_1(e_1e_2)&=e_2 \\
j^*k&=-jk=i&  &\cong&     e_1e_2& \\
k^*j&=kj=-i&  &\cong&     e_2e_1&=-e_1e_2 \\
k^*i&=ki=-j&  &\cong&     e_2(e_1e_2)&=-e_1e_2e_2=-e_1 \\
i^*k&=-ik=j&  &\cong&     (e_1e_2)e_2&=e_1
\end{align}
```

※ クリフォード代数と同型にするためには元に反交換性を持たせることが必要です。そのようにした数として、続編の[クリフォード代数で考えるパウリ行列と双四元数](http://qiita.com/7shi/items/fafe77f9a5ff2f9651ba)では分解型四元数を紹介します。

このように双複素数をクリフォード代数から解釈することには問題があるため、双複素数の応用には別の観点からの解釈が必要です。例えば双複素数のデジタル信号処理への応用では、フーリエ変換の観点から解釈されています。

* Alfsmann, Daniel (4–8 September 2006). [On families of 2^N dimensional hypercomplex algebras suitable for digital signal processing](http://www.eurasip.org/proceedings/eusipco/eusipco2006/papers/1568981962.pdf) (PDF). 14th European Signal Processing Conference, Florence, Italy: EURASIP.

### 3次元

$i,j,k$ を使えば3次元のベクトルが扱えそうな気がしますが、うまくいきません。

```py3
>>> A=a[1]*i+a[2]*j+a[3]*k
>>> B=b[1]*i+b[2]*j+b[3]*k
>>> A.H*B
Matrix([
[      a1*b1 + (a2 - I*a3)*(b2 + I*b3), -I*a1*(-b2 - I*b3) + I*b1*(a2 - I*a3)],
[-I*a1*(b2 + I*b3) + I*b1*(-a2 + I*a3),     a1*b1 + (-a2 + I*a3)*(-b2 - I*b3)]])
>>> list(map(lambda z:z.collect(I),expand(A.H*B)[:,0]))
[a1*b1 + a2*b2 + a3*b3 + I*(a2*b3 - a3*b2), a1*b3 - a3*b1 + I*(-a1*b2 - a2*b1)]
```
```math
\begin{align}
&(a_1i+a_2j+a_3k)^*(b_1i+b_2j+b_3k) \\
&=(a_1b_1+a_2b_2+a_3b_3) \\
&\quad +(a_2b_3-a_3b_2)i \\
&\quad +(a_1b_3-a_3b_1)j \\
&\quad -(a_1b_2+a_2b_1)k
\end{align}
```

$j,k$ の係数は外積になりきれていません。双複素数は、外積に関しては複素数と同じ表現能力しか持たないことが分かります。3次元の外積を扱うには四元数が必要となります。

### 4次元

実部と合わせれば4次元のベクトルが扱えそうな気がしますが、うまくいきません。

```py3
>>> A=a[0]*_1+a[1]*i+a[2]*j+a[3]*k
>>> B=b[0]*_1+b[1]*i+b[2]*j+b[3]*k
>>> A.H*B
Matrix([
[ (a0 - I*a1)*(b0 + I*b1) + (a2 - I*a3)*(b2 + I*b3),  (a0 - I*a1)*(-b2 - I*b3) + (a2 - I*a3)*(b0 + I*b1)],
[(a0 - I*a1)*(b2 + I*b3) + (-a2 + I*a3)*(b0 + I*b1), (a0 - I*a1)*(b0 + I*b1) + (-a2 + I*a3)*(-b2 - I*b3)]])
>>> list(map(lambda z:z.collect(I),expand(A.H*B)[:,0]))
[a0*b0 + a1*b1 + a2*b2 + a3*b3 + I*(a0*b1 - a1*b0 + a2*b3 - a3*b2), a0*b2 + a1*b3 - a2*b0 - a3*b1 + I*(a0*b3 - a1*b2 - a2*b1 + a3*b0)]
```
```math
\begin{align}
&(a_0+a_1i+a_2j+a_3k)^*(b_0+b_1i+b_2j+b_3k) \\
&=(a_0b_0+a_1b_1+a_2b_2+a_3b_3) \\
&\quad +(a_0b_1-a_1b_0+a_2b_3-a_3b_2)i \\
&\quad +(a_0b_2-a_2b_0+a_1b_3-a_3b_1)j \\
&\quad +(a_0b_3+a_3b_0-a_1b_2-a_2b_1)k
\end{align}
```

4次元の外積（ウェッジ積）に表れる基底の2次形式（2ベクトル）は6種類あり、それが2つずつ $i,j,k$ に割り振られているような形にはなっていますが、3次元同様に外積にはなりきれていません。

※ 4次元の外積を扱うには八元数が必要になると予想されますが、未確認です。

# 関連記事

今回は双複素数については表現行列の観点だけに留めます。その他の性質などについては、以下の記事を参照してください。

* [四元数を作ろう](http://qiita.com/7shi/items/2036e7a739c2a9e04025) 2016.12.03

外積やクリフォード代数については以下の記事を参照してください。

* [外積と愉快な仲間たち](http://qiita.com/7shi/items/017d2d2c758f76071f23) 2016.10.26

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
