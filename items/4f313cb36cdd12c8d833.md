---
coediting: false
comments_count: 0
created_at: '2017-03-06T16:25:47+09:00'
id: 4f313cb36cdd12c8d833
likes_count: 25
private: false
reactions_count: 0
stocks_count: 21
tags:
- name: Python
  versions: []
- name: sympy
  versions: []
- name: 数学
  versions: []
- name: 線形代数
  versions: []
title: 実ベクトルで考える複素ベクトル
updated_at: '2017-04-12T10:57:16+09:00'
url: https://qiita.com/7shi/items/4f313cb36cdd12c8d833
slide: false
---

複素ベクトルの取っ掛かりとして、実ベクトルとの対応関係を調べます。SymPyによる計算を添えます。

次のような内容を扱います。

* 2次元の実ベクトルを複素数で代用
* 4次元の実ベクトルを四元数で代用（双複素数の紹介）
* 複素数の表現行列より
    * 複素共役と転置が対応
    * 複素ベクトルでは転置と複素共役が連動（エルミート共役）

量子コンピュータや複素ニューラルネットワークなどで必要となる知識です。

シリーズの記事です。

1. 実ベクトルで考える複素ベクトル ← この記事
1. [表現行列で考える双複素数](http://qiita.com/7shi/items/050f6615558c4c2b1d92)
1. [表現行列で考える四元数](http://qiita.com/7shi/items/e7364e1b2593f24427a5)
1. [クリフォード代数で考えるパウリ行列と双四元数](http://qiita.com/7shi/items/fafe77f9a5ff2f9651ba)

この記事には関連記事があります。

* [外積と愉快な仲間たち](http://qiita.com/7shi/items/017d2d2c758f76071f23) 2016.10.26
* [四元数を作ろう](http://qiita.com/7shi/items/2036e7a739c2a9e04025) 2016.12.03
* [四元数と行列で見る内積と外積の「内」と「外」](http://qiita.com/7shi/items/a80988a32a0d706e9378) 2016.11.02

# 実ベクトルと複素数

2次元の実ベクトルでの内積は次のように計算されます。（詳細は[前回の記事](http://qiita.com/7shi/items/03e9eb2c78360a5c1374)を参照）

```py3
>>> from sympy import *
>>> a1,a2,b1,b2=symbols("a1:3 b1:3",real=True)
>>> Matrix([a1,a2]).dot(Matrix([b1,b2]))
a1*b1 + a2*b2
>>> Matrix([a1,a2]).T * Matrix([b1,b2])
Matrix([[a1*b1 + a2*b2]])
>>> Matrix([[a1,a2]]) * Matrix([b1,b2])
Matrix([[a1*b1 + a2*b2]])
```
```math
\begin{align}
\left(\begin{matrix}a_1 \\ a_2\end{matrix}\right)\cdot
\left(\begin{matrix}b_1 \\ b_2\end{matrix}\right)
&=\left(\begin{matrix}a_1 \\ a_2\end{matrix}\right)^{\top}
  \left(\begin{matrix}b_1 \\ b_2\end{matrix}\right) \\
&=\left(\begin{matrix}a_1 &  a_2\end{matrix}\right)
  \left(\begin{matrix}b_1 \\ b_2\end{matrix}\right) \\
&=a_1b_1+a_2b_2
\end{align}
```

※ SymPyではドット積 `.dot()` ではスカラーが返りますが、転置との積では1行1列の行列が返ります。以後は両者を同一視します。

簡単な例を計算します。

```py3
>>> Matrix([1,2]).dot(Matrix([3,4]))
11
>>> Matrix([1,2]).T*Matrix([3,4])
Matrix([[11]])
```
```math
\left(\begin{matrix}1 \\ 2\end{matrix}\right)\cdot
\left(\begin{matrix}3 \\ 4\end{matrix}\right)
=\left(\begin{matrix}1 \\ 2\end{matrix}\right)^{\top}
 \left(\begin{matrix}3 \\ 4\end{matrix}\right)
=11
```

※ 以後、ドット積（$\cdot$）ではなく転置表記（$^{\top}$）を使用します。

## 複素数

実ベクトルの内積を複素数で計算することを考えます。

複素数は2つの実数で構成されているため、2次元の実ベクトルは複素数に対応付けられます。

```math
\left(\begin{matrix}a \\ b\end{matrix}\right) \mapsto a+bi
```

複素数の積は次のように計算します。SymPyで虚数は `I` です。

```py3
>>> expand((a1+a2*I)*(b1+b2*I)).collect(I)
a1*b1 - a2*b2 + I*(a1*b2 + a2*b1)
```
```math
(a_1+a_2i)(b_1+b_2i)=(a_1b_1-a_2b_2)+(a_1b_2+a_2b_1)i
```

これと実ベクトルの内積 $a_1b_1+a_2b_2$ を比較すれば、次のことが分かります。

* $a_2b_2$ の符号が異なる
* 虚部が余分

片方の複素数を共役にすれば、積の実部が内積、虚部が外積となります。どちらを共役にするかで外積の符号が変わります（反交換性）。

```py3
>>> expand((a1+a2*I).conjugate()*(b1+b2*I)).collect(I)
a1*b1 + a2*b2 + I*(a1*b2 - a2*b1)
>>> expand((a1+a2*I)*(b1+b2*I).conjugate()).collect(I)
a1*b1 + a2*b2 + I*(-a1*b2 + a2*b1)
```
```math
\begin{align}
\underbrace{(a_1+a_2i)^*}_{共役}(b_1+b_2i)&=(\underbrace{a_1b_1+a_2b_2}_{内積})+(\underbrace{a_1b_2-a_2b_1}_{外積})i \tag{1}\\
(a_1+a_2i)\underbrace{(b_1+b_2i)^*}_{共役}&=(a_1b_1+a_2b_2)\underbrace{-(a_1b_2-a_2b_1)}_{符号反転}i \tag{2}
\end{align}
```

複素数で内積や外積を求める際には(1)が標準です。詳細は後で考察しますが、行列計算での転置と複素共役が対応します。

※ 私見ですが、(1)は複素数と線形代数をつなぐ美しい式だと感心します。左辺と右辺で実部と虚部の意味が異なる（左辺は座標だが、右辺は座標ではない）のが気になりますが、それらが区別できるクリフォード代数の幾何学積という計算方法があります。共役も不要です。

```math
(a_1\mathbf{e}_1+a_2\mathbf{e}_2)(b_1\mathbf{e}_1+b_2\mathbf{e}_2)=(a_1b_1+a_2b_2)+(a_1b_2-a_2b_1)\mathbf{e}_1\mathbf{e}_2
```

今回は内積の値だけが必要なため、外積（虚部）は無視します。

※ ここでの外積はベクトル積ではなくウェッジ積です。ウェッジ積は2本のベクトルの張る平行四辺形の面積を表します。2本のベクトルを横に並べた行列の行列式とも一致します。（区切り線は補助です）

```py3
>>> Matrix([a1,a2]).row_join(Matrix([b1,b2]))
Matrix([
[a1, b1],
[a2, b2]])
>>> Matrix([a1,a2]).row_join(Matrix([b1,b2])).det()
a1*b2 - a2*b1
```
```math
\det\left(\begin{array}{c|c}a_1 & b_1 \\ a_2 & b_2\end{array}\right)=a_1b_2-a_2b_1
```

SymPyとPython組み込みの機能とで、簡単な例を計算します。後者では複素数は`j`で、共役は`.conjugate()`、実部は`.real`です。

```py3:SymPy
>>> re(expand(((1+2*I).conjugate()*(3+4*I))))
11
```
```py3:組み込み
>>> ((1+2j).conjugate()*(3+4j)).real
11.0
```
```math
\Re\{(1+2i)^*(3+4i)\}=11
```

※ Pythonでの`*`は掛け算を意味しますが、数式での$^*$は複素共役を意味します。数式では掛け算の演算子は省略されています。

実ベクトルの内積と同じような計算ができました。並べてみれば、複素共役（$^*$）が転置（$^{\top}$）と同じような働きをしていることが分かります。

```py3
>>> Matrix([1,2]).T*Matrix([3,4])
Matrix([[11]])
>>> expand((1+2*I).conjugate()*(3+4*I))
11 - 2*I
>>> (1+2j).conjugate()*(3+4j)
(11-2j)
```
```math
\left(\begin{matrix}1 \\ 2\end{matrix}\right)^{\top}
\left(\begin{matrix}3 \\ 4\end{matrix}\right)
=11 \\
(1+2i)^*(3+4i)=11-2i
```

※ 虚部を無視する前提で、実部を取る操作を省略しています。念のため、虚部が外積で行列式に一致することを確認します。

```py3
>>> Matrix([1,2]).row_join(Matrix([3,4])).det()
-2
```
```math
\det\left(\begin{array}{c|c}1 & 3 \\ 2 & 4\end{array}\right)=4-6=-2
```

## 表現行列

複素共役が転置に相当する理由を考えます。

複素数を2次元の実ベクトルで表現して、内積と計算結果を比較します。

```py3
>>> (a1+a2*I).conjugate()*(b1+b2*I)
(a1 - I*a2)*(b1 + I*b2)
>>> expand((a1+a2*I).conjugate()*(b1+b2*I)).collect(I)
a1*b1 + a2*b2 + I*(a1*b2 - a2*b1)
>>> Matrix([a1,a2]).T*Matrix([b1,b2])
Matrix([[a1*b1 + a2*b2]])
```
```math
\begin{align}
(a_1+a_2i)^*(b_1+b_2i)
&=(a_1-a_2i)(b_1+b_2i) \\
&=(a_1b_1+a_2b_2)+(a_1b_2-a_2b_1)i \\
\left(\begin{matrix}a_1 \\ a_2\end{matrix}\right)^{\top}
\left(\begin{matrix}b_1 \\ b_2\end{matrix}\right)
&=a_1b_1+a_2b_2
\end{align}
```

実ベクトルの内積には虚部が含まれません（虚部は外積なので当たり前と言えば当たり前ですが）。虚部まで含めるため、列を増やすことを試します。

### 虚数単位

まず虚数単位 $i$ を考えます。増やした列は未知数 $x,y$ とします。

```py3
>>> x,y=symbols("x y")
>>> i=Matrix([0,1]).row_join(Matrix([x,y]))
>>> i
Matrix([
[0, x],
[1, y]])
```
```math
i \mapsto
\left(\begin{matrix}0 \\ 1 \end{matrix}\right)
\xrightarrow{列を増やす}
\left(\begin{matrix}0 & x \\ 1 & y\end{matrix}\right)
```

$i^2=-1$ になるように $x,y$ を決めます。2乗した後の2列目は自動的に決まるため、計算を省略します。

```py3
>>> i**2
Matrix([
[x,      x*y],
[y, x + y**2]])
```
```math
i^2 \mapsto
\left(\begin{matrix}0 & x \\ 1 & y\end{matrix}\right)^2
=\left(\begin{matrix}x & * \\ y & *\end{matrix}\right)
=\left(\begin{matrix}-1 & * \\0 & *\end{matrix}\right) \\
∴(x,y)=(-1,0)
```

これで $i^2=-1$ を満たす $i$ に相当する2次の正方行列が求まりました。これを $i$ の**表現行列**と呼びます。

```py3
>>> i=Matrix([[0,-1],[1,0]])
```
```math
i \mapsto \left(\begin{matrix}0 & -1 \\ 1 & 0\end{matrix}\right)
```

※ 導出過程を見ると、$i$ の2列目には2乗した後の1列目が来ることが分かります。これを $i^2=-1$ に関連付ければ簡単に覚えられます。

```math
i \mapsto
\left(\begin{array}{c|c}
\underbrace{\begin{matrix} 0 \\ 1 \end{matrix}}_{i} &
\underbrace{\begin{matrix}-1 \\ 0 \end{matrix}}_{-1}
\end{array}\right)
```

### 複素数

$1$ の表現行列は、掛けても値が変化しない単位元ということから、単位行列となります。

```py3
>>> _1=eye(2)
>>> _1
Matrix([
[1, 0],
[0, 1]])
```
```math
1 \mapsto
I=\left(\begin{matrix}1 & 0 \\ 0 & 1\end{matrix}\right)
```

$1$ と $i$ の表現行列を組み合わせれば、複素数の表現行列が得られます。

```py3
>>> a,b=symbols("a b",real=True)
>>> a*_1+b*i
Matrix([
[a, -b],
[b,  a]])
```
```math
a+bi \mapsto
 a\underbrace{\left(\begin{matrix}1 &  0 \\ 0 & 1\end{matrix}\right)}_{1}
+b\underbrace{\left(\begin{matrix}0 & -1 \\ 1 & 0\end{matrix}\right)}_{i}
=\left(\begin{matrix}a & -b \\ b & a\end{matrix}\right)
```

まとめると次のようになります。

```math
a+bi \mapsto
\left(\begin{matrix}a \\ b \end{matrix}\right)
\xrightarrow{列を増やす}
\left(\begin{matrix}a & -b \\ b & a\end{matrix}\right)
```

※ 複素数の表現行列を認識するには、1列目が成分をベクトル化したもので、2列目は行列式が絶対値の2乗（自己内積）になるように組み合わされていることを意識しておくと良いです。

```py3
>>> Matrix([[a,-b],[b,a]]).det()
a**2 + b**2
>>> Matrix([a,b]).T*Matrix([a,b])
Matrix([[a**2 + b**2]])
>>> abs(a+b*I)**2
a**2 + b**2
```
```math
\det\left(\begin{array}{c|c}a & -b \\ b & a\end{array}\right)
=\left(\begin{matrix}a \\ b\end{matrix}\right)^{\top}
 \left(\begin{matrix}a \\ b\end{matrix}\right)
=a^2+b^2=|a+bi|^2
```

※ 以前見たように異なるベクトルを横に並べた行列の行列式は外積となりますが、表現行列の行列式は内積となります。これについて解釈できなくもありませんが、混乱を招きそうなので省略します。

### 確認

複素数を表現行列に置き換えて積を計算してみます。

```py3
>>> (a1+a2*I).conjugate()*(b1+b2*I)
(a1 - I*a2)*(b1 + I*b2)
>>> a1*_1-a2*i
Matrix([
[ a1, a2],
[-a2, a1]])
>>> b1*_1+b2*i
Matrix([
[b1, -b2],
[b2,  b1]])
>>> (a1*_1-a2*i)*(b1*_1+b2*i)
Matrix([
[a1*b1 + a2*b2, -a1*b2 + a2*b1],
[a1*b2 - a2*b1,  a1*b1 + a2*b2]])
>>> expand((a1+a2*I).conjugate()*(b1+b2*I)).collect(I)
a1*b1 + a2*b2 + I*(a1*b2 - a2*b1)
```
```math
\begin{align}
(a_1+a_2i)^*(b_1+b_2i)
=&(a_1-a_2i)(b_1+b_2i) \\
\mapsto
&\left(\begin{matrix}a_1 &  a_2 \\ -a_2 & a_1\end{matrix}\right)
 \left(\begin{matrix}b_1 & -b_2 \\  b_2 & b_1\end{matrix}\right) \\
=&\left(\begin{matrix}
    a_1b_1+a_2b_2 & -(a_1b_2-a_2b_1) \\
    a_1b_2-a_2b_1 &   a_1b_1+a_2b_2
  \end{matrix}\right) \\
\mapsto
&(a_1b_1+a_2b_2)+(a_1b_2-a_2b_1)i
\end{align}
```

複素数のままの計算と結果が一致しました。複素数の振る舞いが**行列で表現**できています。

### 複素共役

表現行列を転置すれば、表現される複素数は共役になります。これが複素数では転置が共役に対応する理由です。

```py3
>>> (a*_1+b*i).T
Matrix([
[ a, b],
[-b, a]])
```
```math
\left(\begin{matrix}a & -b \\ b & a\end{matrix}\right)^{\top}
=\left(\begin{matrix}a & b \\ -b & a\end{matrix}\right)
\mapsto a-bi=(a+bi)^*
```

先ほど確認した計算例は、複素共役を転置に置き換えても同じ結果になります。

```py3
>>> (a1*_1+a2*i).T*(b1*_1+b2*i)
Matrix([
[a1*b1 + a2*b2, -a1*b2 + a2*b1],
[a1*b2 - a2*b1,  a1*b1 + a2*b2]])
```
```math
\begin{align}
(a_1+a_2i)^*(b_1+b_2i)
\mapsto
&\left(\begin{matrix}a_1 & -a_2 \\ a_2 & a_1\end{matrix}\right)^{\top}
 \left(\begin{matrix}b_1 & -b_2 \\ b_2 & b_1\end{matrix}\right) \\
=&\left(\begin{matrix}
    a_1b_1+a_2b_2 & -(a_1b_2-a_2b_1) \\
    a_1b_2-a_2b_1 &   a_1b_1+a_2b_2
  \end{matrix}\right) \\
\end{align}
```

# 実ベクトルと複素ベクトル

計算結果の虚部を無視するという前提で、4次元の実ベクトルは2次元の複素ベクトルに対応付けられます。

```math
\left(\begin{matrix}a \\ b \\ c \\ d\end{matrix}\right) \mapsto
\left(\begin{matrix}a+bi \\ c+di\end{matrix}\right)
```

成分に複素数が入ったベクトル（複素ベクトル）は転置に特別な注意が必要のため、それを確認します。

## エルミート共役

複素ベクトルに含まれる各複素数を表現行列に置き換えます。

```math
\left(\begin{matrix}a+bi \\ \hline c+di\end{matrix}\right) \mapsto
\left(\begin{matrix}a & -b \\ b & a \\ \hline c & -d \\ d & c\end{matrix}\right)
```

表現行列を転置して複素数に戻せば、転置と同時に複素共役が現れることが分かります。

```math
\begin{align}
\left(\begin{matrix}a & -b \\ b & a \\ \hline c & -d \\ d & c\end{matrix}\right)^{\top}
=&\left(\begin{array}{cc|cc}a & b & c & d \\ -b & a & -d & c\end{array}\right) \\
\mapsto &\left(\begin{array}{c|c}a-bi & c-di\end{array}\right) \\
=&\left(\begin{array}{c|c}a+bi & c+di\end{array}\right)^* \\
=&\left\{\left(\begin{matrix}a+bi \\ \hline c+di\end{matrix}\right)^{\top}\right\}^*
\end{align}
```

このように複素ベクトルや複素行列では、転置と複素共役が連動しています。転置と複素共役の両方を取った行列はエルミート共役（[随伴行列](https://ja.wikipedia.org/wiki/%E9%9A%8F%E4%BC%B4%E8%A1%8C%E5%88%97)）と呼ばれ、この記事ではダガー（$^{\dagger}$）で表します。SymPyではエルミート（Hermite）の頭文字から `.H` となります（フランス語ではHを発音しません）。操作の順番を逆（共役→転置）にしても結果は同じです。

```py3
>>> a,b,c,d=symbols("a b c d",real=True)
>>> Matrix([a+b*I,c+d*I]).H
Matrix([[a - I*b, c - I*d]])
>>> Matrix([a+b*I,c+d*I]).T.conjugate()
Matrix([[a - I*b, c - I*d]])
>>> Matrix([a+b*I,c+d*I]).conjugate().T
Matrix([[a - I*b, c - I*d]])
```
```math
\left(\begin{matrix}a+bi \\ c+di\end{matrix}\right)^{\dagger}
:=\left\{\left(\begin{matrix}a+bi \\ c+di\end{matrix}\right)^{\top}\right\}^*
=\left\{\left(\begin{matrix}a+bi \\ c+di\end{matrix}\right)^*\right\}^{\top}
=\left(\begin{matrix}a-bi & c-di\end{matrix}\right)
```

※ 資料によってはアスタリスク（$^{ * }$）がエルミート共役を表すことがあります。どの定義を採用しているのか確認が必要です。この記事ではベクトルや行列に対するアスタリスク（$^{ * }$）は常に複素共役を表します。

※ エルミート共役と[エルミート行列](https://ja.wikipedia.org/wiki/%E3%82%A8%E3%83%AB%E3%83%9F%E3%83%BC%E3%83%88%E8%A1%8C%E5%88%97)は意味が違うため注意が必要です。エルミート行列とは、エルミート共役が元の行列と一致する行列のことで、自己随伴行列とも呼ばれます。（表現行列では実対称行列）

* 参考: [随伴行列 - 動機付け - Wikipedia](https://ja.wikipedia.org/wiki/%E9%9A%8F%E4%BC%B4%E8%A1%8C%E5%88%97#.E5.8B.95.E6.A9.9F.E4.BB.98.E3.81.91)

## 確認

簡単な計算で、実ベクトルの転置と複素ベクトルのエルミート共役を確認します。

```py3
>>> Matrix([1,2,3,4]).T*Matrix([5,6,7,8])
Matrix([[70]])
>>> expand(Matrix([1+2j,3+4j]).H*Matrix([5+6j,7+8j]))
Matrix([[70.0 - 8.0*I]])
```
```math
\left(\begin{matrix}1 \\ 2 \\ 3 \\ 4\end{matrix}\right)^{\top}
\left(\begin{matrix}5 \\ 6 \\ 7 \\ 8\end{matrix}\right)
=70 \\
\left(\begin{matrix}1+2i \\ 3+4i\end{matrix}\right)^{\dagger}
\left(\begin{matrix}5+6i \\ 7+8i\end{matrix}\right)
=70-8i
```

虚部を無視すれば同じ結果が得られました。

※ [前回の記事](http://qiita.com/7shi/items/03e9eb2c78360a5c1374)で転置した行列を横から刺すとイメージしましたが、ダガー（$\dagger$）は短剣を表すため、まさに刺すイメージです。

## 四元数・双複素数

4次元の実ベクトルは四元数に対応付けられます。

```math
\left(\begin{matrix}a \\ b \\ c \\ d\end{matrix}\right) \mapsto a+bi+cj+dk
```

共役との積を計算すれば、実部から内積が得られます。

```math
【四元数】\ (1-2i-3j-4k)(5+6i+7j+8k)=70-16j-8k
```

※ 虚部は3次元の外積です。$i$ が消えているのは偶然です。$k$ の係数 $8$ が、複素ベクトルでの計算結果の $i$ の係数と一致しています。

虚部を捨てるのであれば、四元数ではなく双複素数を使うという選択肢もあります。四元数とは異なり双複素数は積が可換のため、用途によっては四元数より便利なことがあります（可換四元数と呼ばれることがあります）。双複素数の構造上、共役の形が四元数とは異なるため注意が必要です。

```math
【双複素数】\ (1-2i-3j+4k)(5+6i+7j+8k)=70-8i-16j-4k
```

※ $j,k$を取り除いた$70-8i$は複素ベクトルでの計算結果と一致しています。$j$の係数は四元数と一致しています。

ここでは四元数や双複素数は紹介程度に留めますが、詳細は続編の記事で説明します。

# 実行列と複素行列

これまで見てきたように、実ベクトルを複素ベクトルに対応付けると行数が半分になります。実行列を複素行列に対応付ければ、同様に行数が半分になります。

※ この節では複素数の表現行列は使わず、2次の実ベクトルを複素数に対応させて計算結果を比較します。列を増やして複素数の表現行列に拡張していることに相当します。明示的に表現行列は示しませんが、裏でそのような構造になっているということは意識しておくと良いでしょう。

## 実行列（2×2）

2次の実正方行列は2次元の複素横ベクトル（1×2行列）に対応付けられます。

```math
\left(\begin{matrix}a & c \\ b & d\end{matrix}\right) \mapsto
\left(\begin{matrix}a+bi & c+di\end{matrix}\right)
```

計算例を示します。

```py3
>>> Matrix([[1,3],[2,4]]).T*Matrix([[5,7],[6,8]])
Matrix([
[17, 23],
[39, 53]])
>>> expand(Matrix([[1+2j,3+4j]]).H*Matrix([[5+6j,7+8j]]))
Matrix([
[17.0 - 4.0*I, 23.0 - 6.0*I],
[39.0 - 2.0*I, 53.0 - 4.0*I]])
```
```math
\left(\begin{matrix}1 & 3 \\ 2 & 4\end{matrix}\right)^{\top}
\left(\begin{matrix}5 & 7 \\ 6 & 8\end{matrix}\right)
=\left(\begin{matrix}17 & 23 \\ 39 & 53\end{matrix}\right) \\
\left(\begin{matrix}1+2i & 3+4i\end{matrix}\right)^{\dagger}
\left(\begin{matrix}5+6i & 7+8i\end{matrix}\right)
=\left(\begin{matrix}17-4i & 23-6i \\ 39-2i & 53-4i\end{matrix}\right)
```

虚部を無視すれば同じ結果です。結果の行列は実行列と同じサイズになることに注目してください。直観的には、虚部を含むため2行を1行にまとめられないと解釈できます。

※ 今回は実ベクトルをベースに複素ベクトルを見たため虚部は単純に無視しましたが、実際の応用では虚部に意味が出て来ます。

## 実行列（4×2）

4×2の実行列は2次の複素正方行列に対応付けられます。

```math
\left(\begin{matrix}a & e \\ b & f \\ c & g \\ d & h\end{matrix}\right) \mapsto
\left(\begin{matrix}a+bi & e+fi \\ c+di & g+hi\end{matrix}\right)
```

計算例を示します。

```py3
>>> Matrix([[1,5],[2,6],[3,7],[4,8]]).T*Matrix([[9,13],[10,14],[11,15],[12,16]])
Matrix([
[110, 150],
[278, 382]])
>>> expand(Matrix([[1+2j,5+6j],[3+4j,7+8j]]).H*Matrix([[9+10j,13+14j],[11+12j,15+16j]]))
Matrix([
[110.0 - 16.0*I, 150.0 - 24.0*I],
[ 278.0 - 8.0*I, 382.0 - 16.0*I]])
```
```math
\left(\begin{matrix}1 & 5 \\ 2 & 6 \\ 3 & 7 \\ 4 & 8\end{matrix}\right)^{\top}
\left(\begin{matrix}9 & 13 \\ 10 & 14 \\ 11 & 15 \\ 12 & 16\end{matrix}\right)
=\left(\begin{matrix}110 & 150 \\ 278 & 382\end{matrix}\right) \\
\left(\begin{matrix}1+2i & 5+6i \\ 3+4i & 7+8i\end{matrix}\right)^{\dagger}
\left(\begin{matrix}9+10i & 13+14i \\ 11+12i & 15+16i\end{matrix}\right)
=\left(\begin{matrix}110-16i & 150-24i \\ 278-8i & 382-16i\end{matrix}\right)
```

参考までに四元数行列での計算結果を示します。

```math
\begin{align}
&\left(\begin{matrix}1+2i+3j+4k & 5+6i+7j+8k\end{matrix}\right)^{\dagger}
 \left(\begin{matrix}9+10i+11j+12k & 13+14i+15j+16k\end{matrix}\right) \\
&=\left(\begin{matrix}
    110-32j-16k & 150-48j-24k \\
    278-16j- 8k & 382-32j-16k
  \end{matrix}\right)
\end{align}
```

※ $i$ が消えているのは偶然です。$k$ の係数が、複素行列での計算結果の $i$ の係数と一致しています。

以上で比較は終了です。

# 関連記事

今回は内積に重点を置いたため外積についてはあまり言及しませんでした。外積やクリフォード代数については以下の記事を参照してください。

* [外積と愉快な仲間たち](http://qiita.com/7shi/items/017d2d2c758f76071f23) 2016.10.26

双複素数と四元数については、以下の記事で作り方の観点から説明しています。

* [四元数を作ろう](http://qiita.com/7shi/items/2036e7a739c2a9e04025) 2016.12.03

四元数の係数を表現行列とは異なる形で扱って計算すると、内積と外積が「内」「外」と呼ばれるイメージが見えて来ます。

* [四元数と行列で見る内積と外積の「内」と「外」](http://qiita.com/7shi/items/a80988a32a0d706e9378) 2016.11.02

# 参考

エルミート共役について参考にさせていただきました。

* [ＥＭＡＮの物理学・物理数学・ブラケット記法](http://eman-physics.net/math/linear14.html) 2016.10.02

SymPyについて参考にさせていただきました。

* [3.2. Sympy : Python での代数計算 — Scipy lecture notes](http://www.turbare.net/transl/scipy-lecture-notes/packages/sympy.html)
* [Matrices (linear algebra) — SymPy 1.0.1.dev documentation](http://docs.sympy.org/dev/modules/matrices/matrices.html)
* [Simplification — SymPy 1.0 documentation](http://docs.sympy.org/latest/tutorial/simplification.html)
