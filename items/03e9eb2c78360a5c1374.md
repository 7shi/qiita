---
coediting: false
comments_count: 0
created_at: '2017-03-02T16:25:31+09:00'
id: 03e9eb2c78360a5c1374
likes_count: 47
private: false
reactions_count: 0
stocks_count: 48
tags:
- name: Python
  versions: []
- name: numpy
  versions: []
- name: 数学
  versions: []
- name: 線形代数
  versions: []
title: 見積りで考える内積
updated_at: '2017-06-07T18:45:51+09:00'
url: https://qiita.com/7shi/items/03e9eb2c78360a5c1374
slide: false
---

内積は計算方法としてはそれほど難しいものではありませんが、色々な応用があるためイメージしにくい計算です。幾何学的な意味付けがありますが、そのようには解釈しにくい計算にも応用されます。例として、日常的にも触れる機会の多い計算書（見積りなど）を取り上げます。NumPyによる計算を添えます。

行列で何を計算しているのかいまいち実感が湧かないという方へのヒントになることを目指しています。

シリーズの記事です。

1. 見積りで考える内積 ← この記事
1. [関数で考えるコベクトル](http://qiita.com/7shi/items/1275d2a15a25a75125d2)
1. [関数で考える行列](http://qiita.com/7shi/items/5515a49c86efb8d5102a)
1. [関数で考える双対性](http://qiita.com/7shi/items/c452e2946d1f58b5ff7f)
1. [コベクトルで考えるパーセプトロン](http://qiita.com/7shi/items/538504de453208be937e)

# 見積り

文房具を調達するケースを考えます。

※ 消費税は無視します。

品名|単価|個数|小計
----|---:|---:|---:
鉛筆|30|12|360
消しゴム|50|10|500
ノート|150|5|750
総計|||1,610

このような計算書は日常的によく見掛けるものです。計算を式で書き直してみます。

```math
30×12+50×10+150×5=360+500+750=1610
```

単価と数量をベクトルで書き直せば、これは内積の計算です。

```math
\overbrace{\left(\begin{matrix}30 \\ 50 \\150\end{matrix}\right)}^{単価}\cdot
\overbrace{\left(\begin{matrix}12 \\ 10 \\ 5\end{matrix}\right)}^{個数}
=\overbrace{30×12}^{小計}+\overbrace{50×10}^{小計}+\overbrace{150×5}^{小計}
=\overbrace{1610}^{総計}
```

このように表計算をベクトルで書き直したと捉えることが可能です。このような用途で使われるベクトルや内積を幾何学的に解釈することにはあまり意味がありません。

## NumPy

NumPyでの計算を示します。2種類の書き方ができます。

```py3
>>> from numpy import *
>>> dot(array([30,50,150]),array([12,10,5]))
1610
>>> array([30,50,150]).dot(array([12,10,5]))
1610
```
```math
\left(\begin{matrix}30 \\ 50 \\ 150\end{matrix}\right)\cdot
\left(\begin{matrix}12 \\ 10 \\ 5\end{matrix}\right)
=1610
```

※ 以後、`import`は省略して、`dot`は前者を使用します。

NumPyでは演算子`*`は小計に相当します。

```py3
>>> array([30,50,150])*array([12,10,5])
array([360, 500, 750])
```
```math
\left(\begin{matrix}30 \\ 50 \\ 150\end{matrix}\right)\circ
\left(\begin{matrix}12 \\ 10 \\ 5\end{matrix}\right)
=\left(\begin{matrix}360 \\ 500 \\ 750\end{matrix}\right)
```

※ 数学でこのような形の積はあまり見掛けませんが、[アダマール積](https://ja.wikipedia.org/wiki/%E3%82%A2%E3%83%80%E3%83%9E%E3%83%BC%E3%83%AB%E7%A9%8D)という名前が付いています。

小計を足せば総計が得られます。これは内積と同じ計算です。

```py3
>>> sum(array([30,50,150])*array([12,10,5]))
1610
```
```math
\sum_i\left\{
\left(\begin{matrix}30 \\ 50 \\ 150\end{matrix}\right)\circ
\left(\begin{matrix}12 \\ 10 \\ 5\end{matrix}\right)\right\}_i
=1610
```

※ Excelでこのような表計算をした経験があれば、`SUM`は見慣れているでしょう。

## 横ベクトル（コベクトル）

$\vec{a}\cdot\vec{b}$ という内積を、$\vec{b}$ に対して左から $\vec{a} \cdot$ が作用するという風に捉えます。$\vec{a}$ を転置すれば積として表現できます。ここで言う作用（働きかけ）のイメージは、転置したベクトルによる「横から串刺し」です。（後でこのイメージがはっきりします）

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

「横ベクトル掛ける縦ベクトル」はベクトルの内積の別表現だと意識しておくと良いです。行列の積の方向が「横→縦」なのもこのパターンに由来します。（後で見ますが行列の積は複数の内積から構成されます）

※ 縦ベクトルに左から掛かる横ベクトルは[コベクトル](http://d.hatena.ne.jp/keyword/%A5%B3%A5%D9%A5%AF%A5%C8%A5%EB)や[1-形式](https://ja.wikipedia.org/wiki/1-%E5%BD%A2%E5%BC%8F)と呼んで特別な意味付けがなされます。簡単に言えば、転置にはベクトル（行列）を関数に変換する働きがあります。これが分からなくても構いませんが、興味がある方は続編の[関数で考えるコベクトル](http://qiita.com/7shi/items/1275d2a15a25a75125d2)を参照してください。

```math
\underbrace{\left(\begin{matrix}a_1 &  a_2 &  a_3\end{matrix}\right)}_{関数（実装）}
\underbrace{\left(\begin{matrix}b_1 \\ b_2 \\ b_3\end{matrix}\right)}_{引数}
=\underbrace{a_1b_1+a_2b_2+a_3b_3}_{戻り値}
```

# 相見積り

複数の仕入れ先（A社・B社）から相見積りを取るケースを考えます。

品名|単価(A社)|単価(B社)|個数|小計(A社)|小計(B社)
----|---:|---:|---:|---:|---:
鉛筆|30|25|12|360|300
消しゴム|50|60|10|500|600
ノート|150|120|5|750|600
総計||||1,610|1,500

これは2つの内積計算で表せます。

```math
\begin{align}
\overbrace{\left(\begin{matrix}30 \\ 50 \\ 150\end{matrix}\right)}^{単価(A社)}\cdot
\overbrace{\left(\begin{matrix}12 \\ 10 \\ 5\end{matrix}\right)}^{個数}
&=\overbrace{30×12}^{小計(A社)}+\overbrace{50×10}^{小計(A社)}+\overbrace{150×5}^{小計(A社)}
 =\overbrace{1610}^{総計(A社)} \\
\overbrace{\left(\begin{matrix}25 \\ 60 \\ 120\end{matrix}\right)}^{単価(B社)}\cdot
\overbrace{\left(\begin{matrix}12 \\ 10 \\ 5\end{matrix}\right)}^{個数}
&=\overbrace{25×12}^{小計(B社)}+\overbrace{60×10}^{小計(B社)}+\overbrace{120×5}^{小計(B社)}
 =\overbrace{1500}^{総計(B社)}
\end{align}
```

個数のベクトルが共通していることに注目して、これらを1つの式にくっ付けることを考えます。単価のベクトルを束ねて行列にしますが、行列とベクトルとの内積はないため、横ベクトルで考えたのと同じ要領で転置します。

```math
\begin{align}
&\left(\begin{array}{c|c}\overbrace{30}^{A社} & \overbrace{25}^{B社} \\ 50 & 60 \\ 150 & 120\end{array}\right)^{\top}
 \left(\begin{matrix}12 \\ 10 \\ 5\end{matrix}\right) \\
&=\left(\begin{matrix}\scriptsize{A社}\normalsize{\{} & 30 & 50 & 150 \\ \hline \scriptsize{B社}\normalsize{\{} & 25 & 60 & 120\end{matrix}\right)
  \left(\begin{matrix}12 \\ 10 \\ 5\end{matrix}\right) \\
&=\left(\begin{matrix}\scriptsize{A社}\normalsize{\{} & 30×12+50×10+150×5 \\ \hline \scriptsize{B社}\normalsize{\{} & 25×12+60×10+120×5\end{matrix}\right) \\
&=\left(\begin{matrix}\scriptsize{A社}\normalsize{\{} & 1610 \\ \hline \scriptsize{B社}\normalsize{\{} & 1500\end{matrix}\right)
\end{align}
```

※ 社名や区切り線は補助（コメント）で、数式の要素ではありません。最初の行列は縦ベクトルを横に並べて構成されているため、縦に区切られています。それを転置すれば区切りも横になります。

行列とベクトルの積では複数の内積を計算しています。行列計算と表計算とを見比べれば、同じものを表現していることが分かるでしょう。社名の分類が最後まで残ることに注目してください。

※ 縦ベクトルに左から掛かる転置した行列は[2-形式](https://ja.wikipedia.org/wiki/2-%E5%BD%A2%E5%BC%8F)と呼ばれることがあります（1-形式との対比）。

## NumPy

行列は配列の配列（2次元配列）として記述します。

```py3
>>> array([[30,25],[50,60],[150,120]])
array([[ 30,  25],
       [ 50,  60],
       [150, 120]])
```
```math
\left(\begin{matrix}30 & 25 \\ 50 & 60 \\ 150 & 120\end{matrix}\right)
```

行列の積も`dot`で計算できます。転置は`.T`です。

```py3
>>> dot(array([[30,25],[50,60],[150,120]]).T,array([12,10,5]))
array([1610, 1500])
```
```math
\left(\begin{matrix}30 & 25 \\ 50 & 60 \\ 150 & 120\end{matrix}\right)^{\top}
\left(\begin{matrix}12 \\ 10 \\ 5\end{matrix}\right)
=\left(\begin{matrix}1610 \\ 1500\end{matrix}\right)
```

業者ごとに単価を記述すると考えれば、最初から**転置済みの形**でダイレクトに記述できます。

```py3
>>> dot(array([[30,50,150],[25,60,120]]),array([12,10,5]))
array([1610, 1500])
```
```math
\left(\begin{matrix}30 & 50 & 150 \\ 25 & 60 & 120\end{matrix}\right)
\left(\begin{matrix}12 \\ 10 \\ 5\end{matrix}\right)
=\left(\begin{matrix}1610 \\ 1500\end{matrix}\right)
```

どちらが良いかはケースバイケースですが、表計算ベースで考えるなら転置を使った方が分かりやすいでしょう。

# 個数の比較

個数を変えて比較するケースを考えます。

品名|単価|個数①|個数②|小計①|小計②
----|---:|---:|---:|---:|---:
鉛筆|30|12|9|360|270
消しゴム|50|10|13|500|650
ノート|150|5|4|750|600
総計||||1,610|1,520

これは2つの内積計算で表せます。

```math
\begin{align}
\overbrace{\left(\begin{matrix}30 \\ 50 \\ 150\end{matrix}\right)}^{単価}\cdot
\overbrace{\left(\begin{matrix}12 \\ 10 \\ 5\end{matrix}\right)}^{個数①}
&=\overbrace{30×12}^{小計①}+\overbrace{50×10}^{小計①}+\overbrace{150×5}^{小計①}
 =\overbrace{1610}^{総計①} \\
\overbrace{\left(\begin{matrix}30 \\ 50 \\ 150\end{matrix}\right)}^{単価}\cdot
\overbrace{\left(\begin{matrix} 9 \\ 13 \\ 4\end{matrix}\right)}^{個数②}
&=\overbrace{30×9}^{小計②}+\overbrace{50×13}^{小計②}+\overbrace{150×4}^{小計②}
 =\overbrace{1520}^{総計②}
\end{align}
```

単価のベクトルが共通していることに注目して、これらを1つの式にくっ付けることを考えます。個数のベクトルを束ねて行列にします。ベクトルと行列との内積はありませんが、左のベクトルを転置すれば自然と計算できます。

```math
\begin{align}
&\left(\begin{matrix}30 \\ 50 \\ 150\end{matrix}\right)^{\top}
 \left(\begin{array}{c|c}\overbrace{12}^① & \overbrace{9}^② \\ 10 & 13 \\ 5 & 4\end{array}\right) \\
&=\left(\begin{matrix}30 & 50 & 150\end{matrix}\right)
  \left(\begin{array}{c|c}\overbrace{12}^① & \overbrace{9}^② \\ 10 & 13 \\ 5 & 4\end{array}\right) \\
&=\left(\begin{array}{c|c}\overbrace{30×12+50×10+150×5}^① & \overbrace{30×9+50×13+150×4}^②\end{array}\right) \\
&=\left(\begin{array}{c|c}\overbrace{1610}^① & \overbrace{1520}^②\end{array}\right)
\end{align}
```

①や②の分類が最後まで残ることに注目してください。

## NumPy

NumPyのベクトルには縦横の区別がなく、ケースバイケースで適切に処理されます。`dot`の第1引数にベクトルを与えれば、横ベクトルと見なして積が計算されます。

※ 内積と積とを区別せずに`dot`に統合されているのは、自動で区別すれば楽だという意図だと思われます。内積を意味する`inner`や行列の積を意味する`matmul`という関数もありますが、挙動は`dot`と同じです。

```py3
>>> dot(array([30,50,150]),array([[12,9],[10,13],[5,4]]))
array([1610, 1520])
```
```math
\left(\begin{matrix}30 & 50 & 150\end{matrix}\right)
\left(\begin{matrix}12 & 9 \\ 10 & 13 \\ 5 & 4\end{matrix}\right)
=\left(\begin{matrix}1610 & 1520\end{matrix}\right)
```

NumPyの計算結果が縦横不明な単なるベクトルなのに注意が必要です。明示的に横ベクトル（1行2列の行列）を与えれば計算結果も横ベクトルとなります。

```py3
>>> dot(array([[30,50,150]]), array([[12,9],[10,13],[5,4]]))
array([[1610, 1520]])
```

# 相見積りで個数の比較

相見積りで個数も比較してみましょう。

品名|単価<br>(A社)|単価<br>(B社)|個数①|個数②|小計①<br>(A社)|小計②<br>(A社)|小計①<br>(B社)|小計②<br>(B社)
----|---:|---:|---:|---:|---:|---:|---:|---:
鉛筆|30|25|12|9|360|270|300|225
消しゴム|50|60|10|13|500|650|600|780
ノート|150|120|5|4|750|600|600|480
総計|||||1,610|1,520|1,500|1,485

これは4つの内積計算で表せます。

```math
\begin{align}
\overbrace{\left(\begin{matrix}30 \\ 50 \\ 150\end{matrix}\right)}^{単価(A社)}\cdot
\overbrace{\left(\begin{matrix}12 \\ 10 \\ 5\end{matrix}\right)}^{個数①}
&=\overbrace{30×12}^{小計①(A社)}+\overbrace{50×10}^{小計①(A社)}+\overbrace{150×5}^{小計①(A社)}
 =\overbrace{1610}^{総計①(A社)} \\
\overbrace{\left(\begin{matrix}30 \\ 50 \\ 150\end{matrix}\right)}^{単価(A社)}\cdot
\overbrace{\left(\begin{matrix} 9 \\ 13 \\ 4\end{matrix}\right)}^{個数②}
&=\overbrace{30×9}^{小計②(A社)}+\overbrace{50×13}^{小計②(A社)}+\overbrace{150×4}^{小計②(A社)}
 =\overbrace{1520}^{総計②(A社)} \\
\overbrace{\left(\begin{matrix}25 \\ 60 \\ 120\end{matrix}\right)}^{単価(B社)}\cdot
\overbrace{\left(\begin{matrix}12 \\ 10 \\ 5\end{matrix}\right)}^{個数①}
&=\overbrace{25×12}^{小計①(B社)}+\overbrace{60×10}^{小計①(B社)}+\overbrace{120×5}^{小計①(B社)}
 =\overbrace{1500}^{総計①(B社)} \\
\overbrace{\left(\begin{matrix}25 \\ 60 \\ 120\end{matrix}\right)}^{単価(B社)}\cdot
\overbrace{\left(\begin{matrix} 9 \\ 13 \\ 4\end{matrix}\right)}^{個数②}
&=\overbrace{25×9}^{小計②(B社)}+\overbrace{60×13}^{小計②(B社)}+\overbrace{120×4}^{小計②(B社)}
 =\overbrace{1485}^{総計②(B社)}
\end{align}
```

単価や個数のベクトルが共通していることに注目して、これらを1つの式にくっ付けることを考えます。ベクトルを束ねて行列にします。行列と行列との内積はありませんが、左の行列を転置すれば自然と計算できます。

```math
\begin{align}
&\left(\begin{array}{c|c}\overbrace{30}^{A社} & \overbrace{25}^{B社} \\ 50 & 60 \\ 150 & 120\end{array}\right)^{\top}
 \left(\begin{array}{c|c}\overbrace{12}^① & \overbrace{9}^② \\ 10 & 13 \\ 5 & 4\end{array}\right) \\
&=\left(\begin{matrix}\scriptsize{A社}\normalsize{\{} & 30 & 50 & 150 \\ \hline \scriptsize{B社}\normalsize{\{} & 25 & 60 & 120\end{matrix}\right)
  \left(\begin{array}{c|c}\overbrace{12}^① & \overbrace{9}^② \\ 10 & 13 \\ 5 & 4\end{array}\right) \\
&=\left(\begin{array}{cc|c}
    \scriptsize{A社}\normalsize{\{} & \overbrace{30×12+50×10+150×5}^① & \overbrace{30×9+50×13+150×4}^② \\
    \hline \scriptsize{B社}\normalsize{\{} & 25×12+60×10+120×5 & 25×9+60×13+120×4
  \end{array}\right) \\
&=\left(\begin{array}{cc|c}
    \scriptsize{A社}\normalsize{\{} & \overbrace{1610}^① & \overbrace{1520}^② \\
    \hline \scriptsize{B社}\normalsize{\{} & 1500 & 1485
  \end{array}\right)
\end{align}
```

分類が最後まで残り、交差して組み合わせ表のようになっていることに注目してください。これが前に述べた、転置した行列で横から串刺しにするイメージです。

## NumPy

特に新出事項はありません。

```py3
>>> dot(array([[30,25],[50,60],[150,120]]).T,array([[12,9],[10,13],[5,4]]))
array([[1610, 1520],
       [1500, 1485]])
```
```math
\left(\begin{matrix}30 & 25 \\ 50 & 60 \\ 150 & 120\end{matrix}\right)^{\top}
\left(\begin{matrix}12 &  9 \\ 10 & 13 \\ 5 & 4\end{matrix}\right)
=\left(\begin{matrix}1610 & 1520 \\ 1500 & 1485\end{matrix}\right)
```

計算書を行列計算に見立てる説明は以上です。

# あとがき

日常的に経験する内積（で表せる計算）は何だろうかと考えました。最初に思い付いたのはコインの計算です。

* 10円玉×5枚+100円玉×3枚=350円

しかしコインだと単価を変化させることに無理があるため、品物で表すことを思い付きました。

コンセプトに理解を示して頂けたのも嬉しかったです。

<blockquote class="twitter-tweet" data-cards="hidden" data-lang="ja"><p lang="ja" dir="ltr">これわりと双対空間の良い例なんじゃないだろうか。<br>数ベクトル空間だと双対空間が元の空間と同じになるからイメージしにくいけど、この場合意味がついてるおかげで見分けやすい<br><br>見積りで考える内積 by <a href="https://twitter.com/7shi">@7shi</a> on <a href="https://twitter.com/Qiita">@Qiita</a> <a href="https://t.co/RcRBegGijc">https://t.co/RcRBegGijc</a></p>&mdash; てらむ (@termoshtt) <a href="https://twitter.com/termoshtt/status/837258939112833024">2017年3月2日</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

# 関連記事

コベクトルの考え方は双対ベクトル空間に由来します。

* [双対ベクトル空間 - Wikipedia](https://ja.wikipedia.org/wiki/%E5%8F%8C%E5%AF%BE%E3%83%99%E3%82%AF%E3%83%88%E3%83%AB%E7%A9%BA%E9%96%93)

# 参考

NumPyについて参考にさせていただきました。

* @keisuke-nakata: [numpyの1d-arrayを2d-arrayに変換 - keisukeのブログ](http://kaisk.hatenadiary.com/entry/2014/09/20/185553) 2014.09.20
* @Yunosuke21: [numpyで行列の転置と、行列同士の掛け算をしよう。](http://qiita.com/Yunosuke21/items/025e1b1a56e9988e8cb1) 2016.09.20
* [numpyやchainerでのベクトル、行列、テンソルの積関連演算まとめ - verilog書く人](http://segafreder.hatenablog.com/entry/2017/01/09/203811) 2017.01.09

MathJaxについて参考にさせていただきました。

* [Easy Copy MathJax](http://easy-copy-mathjax.xxxx7.com/)
