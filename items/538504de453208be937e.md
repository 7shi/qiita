---
coediting: false
comments_count: 0
created_at: '2017-04-26T18:01:51+09:00'
id: 538504de453208be937e
likes_count: 9
private: false
reactions_count: 0
stocks_count: 6
tags:
- name: Python
  versions: []
- name: numpy
  versions: []
- name: 数学
  versions: []
- name: 線形代数
  versions: []
title: コベクトルで考えるパーセプトロン
updated_at: '2017-06-07T18:43:49+09:00'
url: https://qiita.com/7shi/items/538504de453208be937e
slide: false
---

表計算による内積と、関数によるコベクトルの考え方を復習して、その観点からパーセプトロンによる論理演算を見ます。NumPyによる計算を添えます。

シリーズの記事です。

1. [見積りで考える内積](http://qiita.com/7shi/items/03e9eb2c78360a5c1374)
1. [関数で考えるコベクトル](http://qiita.com/7shi/items/1275d2a15a25a75125d2)
1. [関数で考える行列](http://qiita.com/7shi/items/5515a49c86efb8d5102a)
1. [関数で考える双対性](http://qiita.com/7shi/items/c452e2946d1f58b5ff7f)
1. コベクトルで考えるパーセプトロン ← この記事

この記事は以下の書籍の補助となることを意図して書きました。

* [斎藤康毅(2016)『ゼロから作るDeep Learning』オライリー・ジャパン](https://www.oreilly.co.jp/books/9784873117584/)

# 見積り計算

以前の例を再掲します。

品名|単価(A社)|個数|小計
----|---:|---:|---:
鉛筆|30|12|360
消しゴム|50|10|500
ノート|150|5|750
総計|||1,610

単価と数量をベクトルで書き直せば、これは内積の計算です。

```math
\overbrace{\left(\begin{matrix}30 \\ 50 \\150\end{matrix}\right)}^{単価}\cdot
\overbrace{\left(\begin{matrix}12 \\ 10 \\ 5\end{matrix}\right)}^{個数}
=\overbrace{30×12}^{小計}+\overbrace{50×10}^{小計}+\overbrace{150×5}^{小計}
=\overbrace{1610}^{総計}
```

## NumPy

NumPyでの計算を示します。

```py3
>>> from numpy import *
>>> dot([30,50,150],[12,10,5])
1610
```

※ 以後 `import` は省略します。

一気に総計を求めないで、アダマール積により小計を求めます。

```py3
>>> array([30,50,150])*[12,10,5]
array([360, 500, 750])
```

小計の合計により総計が得られます。

```py3
>>> sum(array([30,50,150])*[12,10,5])
1610
```

## コベクトルによる関数化

A社の単価を `A` という横ベクトル（コベクトル）に割り当てれば、内積を取ることが関数を評価することと同一視できます。

```py3
>>> A=[30,50,150]
>>> dot(A,[12,10,5])
1610
```
```math
A
 \left(\begin{matrix}12 \\ 10 \\ 5\end{matrix}\right)
=\left(\begin{matrix}30 &  50 &  150\end{matrix}\right)
 \left(\begin{matrix}12 \\ 10 \\ 5\end{matrix}\right)
=1610
```

## 個数の比較

個数を変えて比較するケースを考えます。

品名|単価|個数①|個数②|小計①|小計②
----|---:|---:|---:|---:|---:
鉛筆|30|12|9|360|270
消しゴム|50|10|13|500|650
ノート|150|5|4|750|600
総計||||1,610|1,520

コベクトルを使った計算では、引数のベクトルを横に並べた行列を渡せば、一度に計算できます。

```py3
>>> dot(A,array([[12,10,5],[9,13,4]]).T)
array([1610, 1520])
```
```math
\begin{align}
A\left(\begin{array}{c|c}12 & 9 \\ 10 & 13 \\ 5 & 4\end{array}\right)
&=\left(\begin{matrix}
    A\left(\begin{matrix}12 \\ 10 \\ 5\end{matrix}\right) &
    A\left(\begin{matrix} 9 \\ 13 \\ 4\end{matrix}\right)
  \end{matrix}\right) \\
&=\left(\begin{matrix}1610 & 1520\end{matrix}\right)
\end{align}
```

ここまでが復習です。

# AND

論理演算として `AND` を考えます。乗積表を示します。

A|B|A&B
:--:|:--:|:--:
0|0|0
0|1|0
1|0|0
1|1|1

これはコベクトルでは表せない類の計算です。そのため後処理を加えます。

考え方としては、AとBを足して、それが1より大きいかを調べ、真なら1とします。

A|B|A+B|>1|A&B
:--:|:--:|:--:|:--:|:--:
0|0|0|F|0
0|1|1|F|0
1|0|1|F|0
1|1|2|T|1

AとBを足す部分をコベクトル `And0` で表し、大小比較を加え、数値化するためゼロを足します。

```py3
>>> And0=[1,1]
>>> (dot(And0,array([[0,0],[0,1],[1,0],[1,1]]).T)>1)+0
array([0, 0, 0, 1])
```

このコベクトル $(1\ 1)$ を**重み** $w$、`>1` の $1$ を閾値 $θ$ と呼びます。

※ θはthに相当する文字です。英語で閾値を意味するthresholdの頭文字を表しています。

## パーセプトロン

重みと閾値による計算をパーセプトロンと呼びます。パーセプトロンの関数を定義します。

```py3
>>> def perceptron(w, th, x):
...     return (dot(w, x) > th) + 0
...
```

これを使って `AND` を計算します。

```py3
>>> perceptron(And0, 1, [0,1])
0
```

コベクトルと同じように、引数を複数受け付けます。

```py3
>>> perceptron(And0, 1, array([[0,0],[0,1],[1,0],[1,1]]).T)
array([0, 0, 0, 1])
```
