---
coediting: false
comments_count: 0
created_at: '2017-03-31T19:28:27+09:00'
id: 1275d2a15a25a75125d2
likes_count: 18
private: false
reactions_count: 0
stocks_count: 8
tags:
- name: Python
  versions: []
- name: numpy
  versions: []
- name: 数学
  versions: []
- name: 線形代数
  versions: []
title: 関数で考えるコベクトル
updated_at: '2017-06-07T18:45:34+09:00'
url: https://qiita.com/7shi/items/1275d2a15a25a75125d2
slide: false
---

ベクトルの内積を使って関数が実装できるというコンセプトを説明します。[双対ベクトル空間](https://ja.wikipedia.org/wiki/%E5%8F%8C%E5%AF%BE%E3%83%99%E3%82%AF%E3%83%88%E3%83%AB%E7%A9%BA%E9%96%93)のイメージを伝えることを目的としています。比較用のプログラミング言語にはPythonを使用して、内積の計算にはNumPyの結果を添えます。

シリーズの記事です。

1. [見積りで考える内積](http://qiita.com/7shi/items/03e9eb2c78360a5c1374)
1. 関数で考えるコベクトル ← この記事
1. [関数で考える行列](http://qiita.com/7shi/items/5515a49c86efb8d5102a)
1. [関数で考える双対性](http://qiita.com/7shi/items/c452e2946d1f58b5ff7f)
1. [コベクトルで考えるパーセプトロン](http://qiita.com/7shi/items/538504de453208be937e)

この記事には関連記事があります。

* [RGB値の合計が一定の画像変換](http://qiita.com/7shi/items/d223e347d67cc399f70c) 2016.11.17

# 内積

$\vec{a}\cdot\vec{b}$ という内積を、$\vec{b}$ に対して左から $\vec{a} \cdot$ が作用するという風に捉えます。$\vec{a}$ を転置すれば積として表現できます。

```math
\begin{align}
\underbrace{\vec{a}\cdot}_{作用}\vec{b}
&=\underbrace{\left(\begin{matrix}a_1 \\ a_2 \\ a_3\end{matrix}\right)\cdot}_{作用}
  \left(\begin{matrix}b_1 \\ b_2 \\ b_3\end{matrix}\right) \\
&=\underbrace{\left(\begin{matrix}a_1 \\ a_2 \\ a_3\end{matrix}\right)^{\top}}_{転置}
  \left(\begin{matrix}b_1 \\ b_2 \\ b_3\end{matrix}\right) \\
&=\underbrace{\left(\begin{matrix}a_1 &  a_2 &  a_3\end{matrix}\right)}_{横ベクトル}
  \underbrace{\left(\begin{matrix}b_1 \\ b_2 \\ b_3\end{matrix}\right)}_{縦ベクトル} \\
&=\underbrace{a_1b_1+a_2b_2+a_3b_3}_{内積}
\end{align}
```

「横ベクトル掛ける縦ベクトル」はベクトルの内積の別表現だと意識しておくと良いです。行列の積の方向が「横→縦」なのもこのパターンに由来します。

# コベクトル

縦ベクトルに左から掛かる横ベクトルは[コベクトル](http://d.hatena.ne.jp/keyword/%A5%B3%A5%D9%A5%AF%A5%C8%A5%EB)と呼びます。コベクトルに対して右にある縦ベクトルは単にベクトルと呼びます。縦ベクトルを基本として見て、転置した横ベクトルに双対を表す「コ（co-）」という接頭辞を付けた呼び名です。（サインに対する**コ**サインの**コ**と同様です）

```math
\underbrace{\left(\begin{matrix}a_1 &  a_2 &  a_3\end{matrix}\right)}_{コベクトル}
\underbrace{\left(\begin{matrix}b_1 \\ b_2 \\ b_3\end{matrix}\right)}_{ベクトル}
```

※ コベクトルは[1-形式](https://ja.wikipedia.org/wiki/1-%E5%BD%A2%E5%BC%8F)と呼ばれることもあります（呼び方が違うだけで同じ物を指します）。1-形式に対して右にある縦ベクトルは1-ベクトルと呼びます。

```math
\underbrace{\left(\begin{matrix}a_1 &  a_2 &  a_3\end{matrix}\right)}_{1-形式}
\underbrace{\left(\begin{matrix}b_1 \\ b_2 \\ b_3\end{matrix}\right)}_{1-ベクトル}
```

コベクトル（1-形式）には特別な意味付けがなされます。簡単に言えば、転置にはベクトル（行列）を関数に変換する働きがあります。

```math
\underbrace{\left(\begin{matrix}a_1 &  a_2 &  a_3\end{matrix}\right)}_{関数（実装）}
\underbrace{\left(\begin{matrix}b_1 \\ b_2 \\ b_3\end{matrix}\right)}_{引数}
=\underbrace{a_1b_1+a_2b_2+a_3b_3}_{戻り値}
```

# 関数

コベクトルは関数だと見なせると言っても、実装できる関数は内積で表現できるものに限られます。いくつか例を示します。

## getY

3つの引数から2番目を返します。

```py3
>>> def getY(x, y, z):
...     return y
...
>>> getY(1,2,3)
2
```

コベクトルで実装します。区別のため大文字で始めます。

※ 以後、`import`は省略します。`array`を明示しなくても`dot`が適切に処理します。

```py3
>>> from numpy import *
>>> GetY = [0, 1, 0]
>>> dot(GetY, [1, 2, 3])
2
```
```math
GetY
 \left(\begin{matrix}1 \\ 2 \\ 3\end{matrix}\right)
=\left(\begin{matrix}0 &  1 &  0\end{matrix}\right)
 \left(\begin{matrix}1 \\ 2 \\ 3\end{matrix}\right)
=2
```

コベクトルとの内積により、同じ結果が得られました。

同様に `GetX` や `GetZ` も実装できます。

```py3
>>> GetX = [1, 0, 0]
>>> GetZ = [0, 0, 1]
>>> dot(GetX, [1, 2, 3])
1
>>> dot(GetZ, [1, 2, 3])
3
```

## sum

3つの引数の合計を返します。

```py3
>>> def sum(x, y, z):
...     return x + y + z
...
>>> sum(1, 2, 3)
6
```

コベクトルで実装します。

```py3
>>> Sum = [1, 1, 1]
>>> dot(Sum, [1, 2, 3])
6
```
```math
Sum
 \left(\begin{matrix}1 \\ 2 \\ 3\end{matrix}\right)
=\left(\begin{matrix}1 &  1 &  1\end{matrix}\right)
 \left(\begin{matrix}1 \\ 2 \\ 3\end{matrix}\right)
=6
```

## average

3つの引数の平均値を返します。

```py3
>>> def average(x, y, z):
...     return (x + y + z) / 3
...
>>> average(1, 2, 3)
2.0
```

コベクトルで実装します。

※ 成分の割り算のため`array`を明示しています。

```py3
>>> Average = array([1, 1, 1]) / 3
>>> dot(Average, [1, 2, 3])
2.0
```
```math
Average
 \left(\begin{matrix}1 \\ 2 \\ 3\end{matrix}\right)
=\frac{1}{3}
 \left(\begin{matrix}1 &  1 &  1\end{matrix}\right)
 \left(\begin{matrix}1 \\ 2 \\ 3\end{matrix}\right)
=2
```

## gray

RGB 値からグレースケールに変換します。

```py3
>>> def gray(r, g, b):
...     return r * 0.299 + g * 0.587 + b * 0.114
...
>>> gray(64, 128, 192)
116.16
```


コベクトルで実装します。

```py3
>>> Gray = [0.299, 0.587, 0.114]
>>> dot(Gray, [64, 128, 192])
116.16
```
```math
Gray
 \left(\begin{matrix}64 \\ 128 \\ 192\end{matrix}\right)
=\left(\begin{matrix}0.299 & 0.587 & 0.114\end{matrix}\right)
 \left(\begin{matrix}64 \\ 128 \\ 192\end{matrix}\right)
=116.16
```

比率を指定して足し合わせるのは、内積本来の使い方です。

※ 比率に指定された数値の意味は[RGB値の合計が一定の画像変換](http://qiita.com/7shi/items/d223e347d67cc399f70c)からリンクされている記事を参照してください。

## ダメな例

内積は線形演算（定数倍と和）しか表現できません。

できないことの方が多いのですが、例えば次のような関数はコベクトルで実装できません。

```py3
>>> def product(x, y, z):
...     return x * y * z
...
>>> product(2, 3, 4)
24
```

# 複数の計算

表現力が限られるコベクトルによる関数ですが、複数の計算をまとめられるというメリットがあります。そのことについて確認します。

「関数：引数」の比率で分類して確認します。

## 一対多

1つの関数に異なる引数を渡して計算するのはよくあることです。

```py3
>>> sum(1,2,3)
6
>>> sum(4,5,6)
15
```

リスト内包表記を使えば、このような複数の計算を1つにまとめられます。

```py3
>>> [sum(x,y,z) for x,y,z in [(1,2,3),(4,5,6)]]
[6, 15]
```

コベクトルを使った計算では、引数のベクトルを横に並べた行列を渡せば、一度に計算できます。

```py3
>>> dot(Sum,[[1,4],[2,5],[3,6]])
array([ 6, 15])
```
```math
\begin{align}
Sum\left(\begin{array}{c|c}1 & 4 \\ 2 & 5 \\ 3 & 6\end{array}\right)
&=\left(\begin{matrix}
    Sum\left(\begin{matrix}1 \\ 2 \\ 3\end{matrix}\right) &
    Sum\left(\begin{matrix}4 \\ 5 \\ 6\end{matrix}\right)
  \end{matrix}\right) \\
&=\left(\begin{matrix}6 & 15\end{matrix}\right)
\end{align}
```

※ 区切り線は補助で、数式の要素ではありません。

こういう使い方をして初めて行列計算の嬉しさが出て来ます。しかしNumPyでの記述は2つの引数セットがごちゃまぜになっているため分かりにくいです。転置を使って記述した方が良いでしょう。

```py3
>>> dot(Sum,array([[1,2,3],[4,5,6]]).T)
array([ 6, 15])
```

※ ここでの転置は記述の便宜で行っているもので、コベクトルのような関数化の意味合いはありません。やりたいのは縦ベクトルを横に並べることです。

## 多対一

今度は、複数の関数に同じ引数を渡すことを考えます。

```py3
>>> sum(1,2,3)
6
>>> average(1,2,3)
2.0
```

これもリスト内包表記で書けます。

```py3
>>> [(sum(x,y,z),average(x,y,z)) for x,y,z in [(1,2,3)]]
[(6, 2.0)]
```

※ この例だとごちゃごちゃしているだけであまり嬉しさはありませんが、次で見る多対多の例を見れば、それなりに合理性が感じられると思います。

コベクトルを縦に並べることで、引数を共有することができます。

```py3
>>> dot([Sum,Average],[1,2,3])
array([ 6.,  2.])
```
```math
\begin{align}
\left(\begin{matrix}Sum \\ Average\end{matrix}\right)
\left(\begin{matrix}1 \\ 2 \\ 3\end{matrix}\right)
&=\left(\begin{array}{r}
    Sum    \left(\begin{matrix}1 \\ 2 \\ 3\end{matrix}\right) \\
    Average\left(\begin{matrix}1 \\ 2 \\ 3\end{matrix}\right)
  \end{array}\right) \\
&=\left(\begin{matrix}6 \\ 2\end{matrix}\right)
\end{align}
```

## 多対多

もう予想は付いていると思いますが、関数も引数の組も複数にすれば、すべての組み合わせを一度に計算することができます。

```py3:ベタ書き
>>> sum(1,2,3)
6
>>> average(1,2,3)
2.0
>>> sum(4,5,6)
15
>>> average(4,5,6)
5.0
```
```py3:リスト内包表記
>>> [(sum(x,y,z),average(x,y,z)) for x,y,z in [(1,2,3),(4,5,6)]]
[(6, 2.0), (15, 5.0)]
```

コベクトルと引数を縦に並べて、引数の方は転置します。

※ 引数については前述のように記述上の便宜です。

```py3
>>> dot([Sum,Average],array([[1,2,3],[4,5,6]]).T)
array([[  6.,  15.],
       [  2.,   5.]])
```
```math
\begin{align}
\left(\begin{matrix}Sum \\ Average\end{matrix}\right)
\left(\begin{array}{c|c}1 & 4 \\ 2 & 5 \\ 3 & 6\end{array}\right)
&=\left(\begin{array}{rr}
    Sum    \left(\begin{matrix}1 \\ 2 \\ 3\end{matrix}\right) &
    Sum    \left(\begin{matrix}4 \\ 5 \\ 6\end{matrix}\right) \\
    Average\left(\begin{matrix}1 \\ 2 \\ 3\end{matrix}\right) &
    Average\left(\begin{matrix}4 \\ 5 \\ 6\end{matrix}\right)
  \end{array}\right) \\
&=\left(\begin{matrix}6 & 15 \\ 2 & 5\end{matrix}\right)
\end{align}
```

コベクトルや双対空間は現実離れした抽象的な考え方のように感じるかもしれませんが、このように意味付けすれば具体的なイメージが湧くのではないでしょうか。

# 参考

Wikipediaの例に多少手を加えて使用しました。

* [1-形式 - Wikipedia](https://ja.wikipedia.org/wiki/1-%E5%BD%A2%E5%BC%8F)

コベクトルの考え方は双対ベクトル空間に由来します。

* [双対ベクトル空間 - Wikipedia](https://ja.wikipedia.org/wiki/%E5%8F%8C%E5%AF%BE%E3%83%99%E3%82%AF%E3%83%88%E3%83%AB%E7%A9%BA%E9%96%93)
