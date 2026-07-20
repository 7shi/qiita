---
coediting: false
comments_count: 4
created_at: '2014-08-31T22:12:02+09:00'
id: 0ece8c3394e1328267ed
likes_count: 24
private: false
reactions_count: 0
stocks_count: 20
tags:
- name: Haskell
  versions: []
title: 【解答例】Haskell 超入門
updated_at: '2017-08-16T13:40:16+09:00'
url: https://qiita.com/7shi/items/0ece8c3394e1328267ed
slide: false
---

[Haskell 超入門](http://qiita.com/7shi/items/145f1234f8ec2af923ef)の解答例です。

# フィボナッチ数

## パターンマッチ

【問1】任意のn番目のフィボナッチ数を計算する関数`fib`をパターンマッチで実装してください。

初期値`0, 1`を基底部とします。

```hs:基底部
fib 0 = 0
fib 1 = 1
```

`0, 1, 1, 2, 3, 5, ...`より`fib 5`について考えます。

```hs:具体例
fib 5 = 2 + 3 = fib 3 + fib 4
```

これを`n`で一般化すれば再帰部となります。

```hs:再帰部
fib n = fib (n - 2) + fib (n - 1)
```

テストを追加して解答とします。

```hs:解答
fib 0 = 0
fib 1 = 1
fib n = fib (n - 2) + fib (n - 1)

main = do
    print $ fib 6
```
```text:実行結果
8
```

## ガード

【問2】問1で実装した関数をガードで書き直してください。

```hs
fib n
    | n == 0    = 0
    | n == 1    = 1
    | otherwise = fib (n - 2) + fib (n - 1)

main = do
    print $ fib 6
```
```text:実行結果
8
```

## case - of

【問3】問1で実装した関数を`case`-`of`で書き直してください。無限ループを防ぐためガードを追加してください。

```hs
fib n = case n of
    0 -> 0
    1 -> 1
    _ | n > 1 -> fib (n - 2) + fib (n - 1)

main = do
    print $ fib 6
```
```text:実行結果
8
```

# 再実装

【問4】`sum`, `product`, `take`, `drop`, `reverse`と同じ機能の関数を再実装してください。関数名には`'`を付けてください。

```hs
sum' []     = 0
sum' (x:xs) = x + sum' xs

product' []     = 1
product' (x:xs) = x * product' xs

take' _ []        = []
take' n _ | n < 1 = []
take' n (x:xs)    = x : take' (n - 1) xs

drop' _ []         = []
drop' n xs | n < 1 = xs
drop' n (_:xs)     = drop' (n - 1) xs

reverse' []     = []
reverse' (x:xs) = reverse' xs ++ [x]

main = do
    print $ sum' [1..5]
    print $ product' [1..5]
    print $ take' 2 [1, 2, 3]
    print $ drop' 2 [1, 2, 3]
    print $ reverse' [1..5]
```
```text:実行結果
15
120
[1,2]
[3]
[5,4,3,2,1]
```

* リストが空になるまで順番にたどるため、基底部として`[]`を定義します。

## 別解

※ 勉強会で出た意見を反映した項目です。

`++`を避けた実装です。本文では説明していませんが末尾再帰です。

```hs
reverse' xs = f xs []
    where
        f []     ys = ys
        f (x:xs) ys = f xs (x:ys)
```

# 階乗

【問5】`product`を使って`fact`（階乗）を実装してください。

```hs
fact n = product [1..n]

main = do
    print $ fact 5
```
```text:実行結果
120
```

# 垂線の交点

【問6】点 $(p, q)$ から直線 $ax + by = c$ に下した垂線の交点を求める関数`perpPoint`を作成してください。aとbが両方ゼロになると解なしですが、チェックせずに無視してください。

```math
ax + by = c \cdots (1)
```

(1)への垂線は

```math
bx - ay = d \cdots (2)
```

(2)に $(p,q)$ を代入します。

```math
d = bp - aq \cdots (3)
```

(1)と(2)の連立方程式を解いて(3)を代入すれば交点が求まります。

```math
x=\frac{ac+bd}{a^2+b^2}, y=\frac{bc-ad}{a^2+b^2}
```

これをコード化します。

```hs:解答
perpPoint (p, q) (a, b, c) = (x, y)
    where
        x = (a * c + b * d) / (a * a + b * b)
        y = (b * c - a * d) / (a * a + b * b)
        d = b * p - a * q

main = do
    print $ perpPoint (0, 2) (1, -1, 0)
```
```text:実行結果
(1.0,1.0)
```

# ROT13

【問7】[ROT13](http://ja.wikipedia.org/wiki/ROT13)を実装してください。

```hs
import Data.Char

rot13ch ch
    |  'A' <= ch && ch <= 'M'
    || 'a' <= ch && ch <= 'm' = chr $ ord ch + 13
    |  'N' <= ch && ch <= 'Z'
    || 'n' <= ch && ch <= 'z' = chr $ ord ch - 13
    | otherwise = ch

rot13 ""     = ""
rot13 (x:xs) = rot13ch x : rot13 xs

main = do
    let hello13 = rot13 "Hello, World!"
    print hello13
    print $ rot13 hello13
```
```text:実行結果
"Uryyb, Jbeyq!"
"Hello, World!"
```

# バブルソート

【問8】[バブルソート](http://www.ics.kagoshima-u.ac.jp/~fuchida/edu/algorithm/sort-algorithm/bubble-sort.html)を実装してください。

⇒ [詳細説明](http://qiita.com/7shi/items/1e2a66bf8e8c7f0bd70f)

```hs
bswap [x] = [x]
bswap (x:xs)
    | x > y     = y:x:ys
    | otherwise = x:y:ys
    where
        (y:ys) = bswap xs

bsort [] = []
bsort xs = y : bsort ys
    where
        (y:ys) = bswap xs

main = do
    print $ bswap [4, 3, 1, 5, 2]
    print $ bsort [4, 3, 1, 5, 2]
    print $ bsort [5, 4, 3, 2, 1]
    print $ bsort [4, 6, 9, 8, 3, 5, 1, 7, 2]
```
```text:実行結果
[1,4,3,2,5]
[1,2,3,4,5]
[1,2,3,4,5]
[1,2,3,4,5,6,7,8,9]
```

# マージソート

【問9】[マージソート](http://www.ics.kagoshima-u.ac.jp/~fuchida/edu/algorithm/sort-algorithm/merge-sort.html)を実装してください。

* ソートしながら2つのリストをマージする関数`merge`を作ります。
* 往路で分割、復路でマージを再帰関数で表現します。

```hs
merge xs [] = xs
merge [] ys = ys
merge (x:xs) (y:ys)
    | x < y     = x : merge xs (y:ys)
    | otherwise = y : merge (x:xs) ys

msort []  = []
msort [x] = [x]
msort xs  = merge (msort (take h xs)) (msort (drop h xs))
    where
        h = (length xs) `div` 2

main = do
    print $ msort [4, 6, 9, 8, 3, 5, 1, 7, 2]
```
```text:実行結果
[1,2,3,4,5,6,7,8,9]
```

# クイックソート

【問10】処理の流れを説明してください。

リスト`[4, 6, 9, 8, 3, 5, 1, 7, 2]`をソートします。

`(n:xs) = 4 : [6, 9, 8, 3, 5, 1, 7, 2]`

リストの最初の要素`4`を基準に3つの部分に分けます。

```hs
qsort (n:xs) = qsort lt ++ [n] ++ qsort gteq
    where
        lt   = [x | x <- xs, x <  n]
        gteq = [x | x <- xs, x >= n]
```

* 4未満: `lt   = [x | x <- xs, x <  n]` → `[3, 1, 2]`
* 4: `[x]` → `[4]`
* 4以上: `gteq = [x | x <- xs, x >= n]` → `[6, 9, 8, 5, 7]`

`lt`と`gteq`をソートして結合します。

```text:実行イメージ
qsort [3, 1, 2] ++ [4] ++ qsort [6, 9, 8, 5, 7]
          ↓                           ↓
      [1, 2, 3] ++ [4] ++       [5, 6, 7, 8, 9]
          ↓                           ↓
      [1, 2, 3,     4,           5, 6, 7, 8, 9]
```

`qsort [3, 1, 2]`と`qsort [6, 9, 8, 5, 7]`の内部では、同様の処理が繰り返されています。

# 直角三角形の三辺

【問11】三辺の長さが各20以下の整数で構成される直角三角形を列挙してください。並び順による重複を排除する必要はありません。

複数ソースのリスト内包表記に三平方の定理で条件付けします。

```hs
main = do
    print [(a, b, c)
          | a <- [1..20], b <- [1..20], c <- [1..20]
          , a * a + b * b == c * c
          ]
```
```text:実行結果
[(3,4,5),(4,3,5),(5,12,13),(6,8,10),(8,6,10),(8,15,17),(9,12,15),(12,5,13),(12,9,15),(12,16,20),(15,8,17),(16,12,20)]
```

## 重複排除

※ 勉強会で出た意見を反映した項目です。

条件 $a<b$ を追加すれば並び順による重複が排除できます。

```hs
main = do
    print [(a, b, c)
          | a <- [1..20], b <- [1..20], c <- [1..20]
          , a * a + b * b == c * c, a < b
          ]
```
```text:実行結果
[(3,4,5),(5,12,13),(6,8,10),(8,15,17),(9,12,15),(12,16,20)]
```

条件で制限するのではなく、ソースから抜けば計算量が削減できます。

```hs
main = do
    print [(a, b, c)
          | a <- [1..20], b <- [a..20], c <- [b..20]
          , a * a + b * b == c * c
          ]
```
```text:実行結果
[(3,4,5),(5,12,13),(6,8,10),(8,15,17),(9,12,15),(12,16,20)]
```
