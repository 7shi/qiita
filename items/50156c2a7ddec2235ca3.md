---
coediting: false
comments_count: 0
created_at: '2023-09-27T03:56:16+09:00'
id: 50156c2a7ddec2235ca3
likes_count: 0
private: false
reactions_count: 0
stocks_count: 0
tags:
- name: Python
  versions: []
- name: sympy
  versions: []
- name: 統計学
  versions: []
- name: 不偏分散
  versions: []
- name: BingAI
  versions: []
title: 不偏分散を具体例で確認
updated_at: '2023-11-19T22:23:07+09:00'
url: https://qiita.com/7shi/items/50156c2a7ddec2235ca3
slide: false
---

不偏分散は期待値が母分散と一致するように定義されます。具体例で確認しようとしてハマりました。Bing AI と相談しながら解決した経緯を残しておきます。

# 不偏推定量

母集団からサンプリングした標本によって、母集団の特徴を調べることを考えます。

複数の標本から計算した値の平均が、母集団全体を計算した値と等しくなるように定義された量を**不偏推定量**と呼びます。

標本の平均値は不偏推定量です。複数回サンプリングして、各標本の平均値の平均を取れば、サンプリング回数が増えるほど母集団の平均値に近付きます。

## 分散

データのばらつきを示す量が**分散**です。

対象となるデータを $\\{x_1,x_2,\cdots,x_n\\}$ とすれば、分散は各値と平均値 $\bar x$ との差の 2 乗の平均から計算されます。

```math
\text{分散:}\ \frac{(x_1-\bar x)^2+(x_2-\bar x)^2+\cdots+(x_n-\bar x)^2}n
```

※ 詳細は以下の記事を参照してください。

https://math-journal.bear-fruit.online/variance/

https://math.nakaken88.com/textbook/master-variance-definition/

母集団の分散を**母分散**、標本の分散を**標本分散**と呼びます。

## 不偏分散

複数の標本から分散を計算して平均しても、母分散には近付きません。つまり標本分散は不偏推定量ではありません。しかし分散の分母から 1 を引いて補正することで不偏推定量となります。これを**不偏分散**と呼びます。

```math
\text{不偏分散:}\ \frac{(x_1-\bar x)^2+(x_2-\bar x)^2+\cdots+(x_n-\bar x)^2}{n-1}
```

※ 詳細は以下の記事を参照してください。

https://qiita.com/ydclab_P002/items/b3b76905421d5d09c9e4

# 小さい母集団

平均値と不偏分散が不偏推定量であることを、小さい母集団 $\\{a,b,c,d\\}$ で確認します。

母集団全体をカバーする標本から不偏推定量を計算すれば、直接計算で一致を確認できるはずという目論見です。

## 平均

```math
\text{平均}\ \mu=\frac{a+b+c+d}4
```

母集団を分割して 2 つの標本 $\\{a,b\\},\\{c,d\\}$ を作り、それぞれ平均を計算します。

```math
\begin{aligned}
\mu_1&=\frac{a+b}2 \\
\mu_2&=\frac{c+d}2 \\
\end{aligned}
```

平均の平均を求めます。

```math
\frac{\mu_1+\mu_2}2=\frac{a+b+c+d}4=\mu
```

母集団の平均に一致しました！

### 注意点

標本のデータ数が一致している必要があります。

例えば母集団 $\\{a,b,c,d,e\\}$ を 2 つの標本 $\\{a,b,c\\},\\{d,e\\}$ に分割して平均の平均を計算しても、母集団の平均とは一致しません。

```math
\begin{aligned}
\frac{\frac{a+b+c}3+\frac{d+e}2}2
&=\frac{2a+2b+2c+3d+3e}{12} \\
&\ne\frac{a+b+c+d+e}5
\end{aligned}
```

母集団全体をデータ数 2 の標本でカバーするには、各データを二重にサンプリングする必要があります。

```math
\{a,b\},\{c,d\},\{e,a\},\{b,c\},\{d,e\}
```
```math
\begin{aligned}
\frac{\frac{a+b}2+\frac{c+d}2+\frac{e+a}2+\frac{b+c}2+\frac{d+e}2}5
&=\frac{2(a+b+c+d+e)}{10} \\
&=\frac{a+b+c+d+e}5
\end{aligned}
```

## 母分散

```math
\text{母分散}\ \sigma^2=\frac{(a-\mu)^2+(b-\mu)^2+(c-\mu)^2+(d-\mu)^2}4
```

計算を進めれば、各値の 2 乗の平均から平均の 2 乗を引いたものであることが分かります。

```math
\begin{aligned}
\sigma^2
&=\frac{(a-\mu)^2+(b-\mu)^2+(c-\mu)^2+(d-\mu)^2}4 \\
&=\frac{a^2-2a\mu+\mu^2+b^2-2b\mu+\mu^2+c^2-2c\mu+\mu^2+d^2-2d\mu+\mu^2}4 \\
&=\frac{a^2+b^2+c^2+d^2-2\mu(a+b+c+d)+4\mu^2}4 \\
&=\frac{a^2+b^2+c^2+d^2}4-2\mu\underbrace{\left(\frac{a+b+c+d}4\right)}_{=\mu}+\mu^2 \\
&=\frac{a^2+b^2+c^2+d^2}4-\mu^2
\end{aligned}
```

$\mu$ を代入して更に計算を進めます。

```math
\begin{aligned}
\sigma^2
&=\frac{a^2+b^2+c^2+d^2}4-\mu^2 \\
&=\frac{a^2+b^2+c^2+d^2}4-\left(\frac{a+b+c+d}4\right)^2 \\
&=\frac{4(a^2+b^2+c^2+d^2)-(a^2+b^2+c^2+d^2+2ab+2ac+2ad+2bc+2bd+2cd)}{16} \\
&=\frac{3(a^2+b^2+c^2+d^2)-2(ab+ac+ad+bc+bd+cd)}{16}
\end{aligned}
```

## 不偏分散

母集団を分割して 2 つの標本 $\\{a,b\\},\\{c,d\\}$ から不偏分散の平均を求めても、母分散とは一致しません。

```math
\begin{aligned}
&\frac{\frac{a^2+b^2}2-\left(\frac{a+b}2\right)^2+\frac{c^2+d^2}2-\left(\frac{c+d}2\right)^2}2 \\
&=\frac{2a^2+2b^2+2c^2+2d^2-(a^2+2ab+b^2+c^2+2cd+d^2)}8 \\
&=\frac{a^2+b^2+c^2+d^2-2(ab+cd)}4 \\
\end{aligned}
```

すべての組み合わせ（順列）から標本を作っても分母が一致しません。（計算過程は省略）

```math
\{a,b\},\{a,c\},\{a,d\},\{b,c\},\{b,d\},\{c,d\}
```
```math
\frac{3(a^2+b^2+c^2+d^2)-2(ab+ac+ad+bc+bd+cd)}{12}
```

ここでハマったことが今回のメインテーマで、ここから先はそのことについて書きます。

※ 結論から言えば、データの重複を含めて組み合わせ（直積）を考える必要がありました。

```math
\begin{alignedat}{4}
&\{a,a\},&&\{a,b\},&&\{a,c\},&&\{a,d\}, \\
&\{b,a\},&&\{b,b\},&&\{b,c\},&&\{b,d\}, \\
&\{c,a\},&&\{c,b\},&&\{c,c\},&&\{c,d\}, \\
&\{d,a\},&&\{d,b\},&&\{d,c\},&&\{d,d\}
\end{alignedat}
```

# 数値計算

いくら 4 要素とはいえ代数計算の試行錯誤は辛いので、プログラムによる数値計算に切り替えます。

ちょうど Bing AI で GPT-4 が使えるという記事を見掛けました。

https://qiita.com/takao-takass/items/16a7052a4a0e857b7c90

今回は ChatGPT ではなく Bing AI にコードを書いてもらいます。

## ランダム

巨大な母集団からサンプリングを繰り返すことで不偏分散の平均が母分散に近付くのかを確かめます。

Python で 100 要素の母集団から 5 個ずつサンプリングして不偏分散の平均を計算してください、と指示して得られたコードを手直ししました。

```python
import numpy as np

# 母集団を生成
population = np.random.rand(100)

# 母集団の標本分散を計算
population_variance = np.var(population)
print(population_variance, "母分散")

for i in range(3, 9):
    # 不偏分散を格納するリスト
    variances = []

    # 1000回サンプリングを行う
    for _ in range(4 ** i):
        # 母集団から5つランダムにサンプルを抽出
        sample = np.random.choice(population, 5)
        # 不偏分散を計算
        variance = np.var(sample, ddof=1)
        # リストに追加
        variances.append(variance)

    # 不偏分散の平均を計算
    average_variance = np.mean(variances)
    print(average_variance, len(variances))
```
```text:実行結果（毎回変わる）
0.07240982873176978 母分散
0.07320038610063394 64
0.07373119019648693 256
0.07519586627347338 1024
0.07223140666501196 4096
0.07251055888050797 16384
0.07250046420441993 65536
```

試行回数を増やせば母分散に近付きます。

※ 必ずしも直線的に近付くわけではなく、ブレて振動します。

## 固定値

`[1,2,3,4]` という小さな母集団で試しました。

```python:変更箇所1
# 母集団を生成
population = [1,2,3,4]
```
```python:変更箇所2
        # 母集団から2つランダムにサンプルを抽出
        sample = np.random.choice(population, 2)
```
```text:実行結果（毎回変わる）
1.25 母分散
1.53125 64
1.24609375 256
1.18994140625 1024
1.2646484375 4096
1.249176025390625 16384
1.2490310668945312 65536
```

この規模だと総当たりができるので、この結果を手掛かりに進めます。

## 組み合わせ

サンプリングでどのような組み合わせが選ばれているのかを探りました。

```python
import numpy as np

# 母集団を生成
population = [1, 2, 3, 4]

for _ in range(10):
    print(np.random.choice(population, 2))
```
```text:実行結果（毎回変わる）
[4 4]
[3 3]
[3 4]
[1 2]
[3 1]
[4 1]
[2 1]
[1 1]
[1 1]
[2 2]
```

注目するのは `[1 1]` のように同じ値が含まれているものと、`[1 2]` と `[2 1]` のように順番が逆になっているペアです。これらは「組み合わせは順列」という先入観で排除してしまった組み合わせです。

## 直積

総当たりで得られた不偏分散の平均を母分散に一致させるには、重複や逆順も含めて標本を作る必要があります。これは直積として得られます。

Python で直積を求めるコードです。

```python
from itertools import product
data = [1, 2, 3, 4]
print(list(product(data, data)))
```
```text:実行結果
[(1, 1), (1, 2), (1, 3), (1, 4), (2, 1), (2, 2), (2, 3), (2, 4), (3, 1), (3, 2), (3, 3), (3, 4), (4, 1), (4, 2), (4, 3), (4, 4)]
```

不偏分散の平均が母分散と一致することを確認します。

```python
from itertools import product

def average(xs, d = 0):
    return sum(xs) / (len(xs) - d)

def v(xs, d = 0):
    m = average(xs)
    return average([(x - m)**2 for x in xs], d)

data = [1, 2, 3, 4]
print(a := v(data, 0), "母分散")
print(b := average([v(xs, 1) for xs in product(data, data)]))
print(a == b)
```
```text:実行結果
1.25 母分散
1.25
True
```

sympy を使えば、ほぼ同じコードで数式が計算できます。母集団 $\\{a,b,c,d\\}$ について計算します。

```python
from sympy import var
from itertools import product

def average(xs, d = 0):
    return sum(xs) / (len(xs) - d)

def v(xs, d = 0):
    m = average(xs)
    return average([(x - m)**2 for x in xs], d)

data = var("a b c d")
print(a := v(data, 0).expand(), "母分散")
print(b := average([v(xs, 1) for xs in product(data, data)]).expand())
print(a == b)
```
```text:実行結果
3*a**2/16 - a*b/8 - a*c/8 - a*d/8 + 3*b**2/16 - b*c/8 - b*d/8 + 3*c**2/16 - c*d/8 + 3*d**2/16 母分散
3*a**2/16 - a*b/8 - a*c/8 - a*d/8 + 3*b**2/16 - b*c/8 - b*d/8 + 3*c**2/16 - c*d/8 + 3*d**2/16
True
```

一致しました！

通分して数式で表現します。

```math
\frac{3(a^2+b^2+c^2+d^2)-2(ab+ac+ad+bc+bd+cd)}{16}
```

# ログ

Bing AI のログです。

* https://github.com/7shi/ai-log/blob/main/bingai/20230926-variance.md

数式で計算するように指示すればやってくれるのには感動しましたが、よく見ると間違っている個所があります。今後に期待ですが、ポテンシャルは感じます。

このログは以下の方法で Markdown 化しました。

https://qiita.com/7shi/items/7f9c8ea1a4e380c02af1
