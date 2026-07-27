---
coediting: false
comments_count: 0
created_at: '2014-09-18T11:38:40+09:00'
id: 1e2a66bf8e8c7f0bd70f
likes_count: 19
private: false
reactions_count: 0
stocks_count: 13
tags:
- name: Haskell
  versions: []
title: Haskellでバブルソート
updated_at: '2014-11-02T08:58:24+09:00'
url: https://qiita.com/7shi/items/1e2a66bf8e8c7f0bd70f
slide: false
---

バブルソートは隣接した値を交換することでソートするアルゴリズムです。これをHaskellで実装してみます。

以下の練習問題の補足説明を兼ねています。

* [Haskell 超入門](http://qiita.com/7shi/items/145f1234f8ec2af923ef)

# アルゴリズム

右から2つずつ比較して、左が小さくなるように交換します。比較対象を`()`で囲んで示します。

1. `[ 4 , 3 , 1 ,(5),(2)]` → 交換
1. `[ 4 , 3 ,(1),(2), 5 ]` → 何もしない
1. `[ 4 ,(3),(1), 2 , 5 ]` → 交換
1. `[(4),(1), 3 , 2 , 5 ]` → 交換
1. `[(1), 4 , 3 , 2 , 5 ]` → 左端が最小値となる

この様子を縦に並べると、小さい数が上に移動している様子が分かります。この小さい数を「泡」に見立てたのがバブルソートの名前の由来です。

  1. |  2. |  3. |  4. |  5.
-----|-----|-----|-----|-----
  4  |  4  |  4  |  4  |**1**
  3  |  3  |  3  |**1**|  4
  1  |  1  |**1**|  3  |  3
  5  |**2**|  2  |  2  |  2
**2**|  5  |  5  |  5  |  5

左端まで来た最小値を除いて、再度交換を行います。これを繰り返すことでソートできます。

1. `1 : [ 4 , 3 ,(2),(5)]` → 何もしない
1. `1 : [ 4 ,(3),(2), 5 ]` → 交換
1. `1 : [(4),(2), 3 , 5 ]` → 交換
1. `1 : [(2), 4 , 3 , 5 ]` → 左端の最小値を分離
1. `1 : 2 : [ 4 ,(3),(5)]` → 何もしない
1. `1 : 2 : [(4),(3), 5 ]` → 交換
1. `1 : 2 : [(3), 4 , 5 ]` → 左端の最小値を分離
1. `1 : 2 : 3 : [(4),(5)]` → 何もしない
1. `1 : 2 : 3 : [(4), 5 ]` → 左端の最小値を分離
1. `1 : 2 : 3 : 4 : [ 5 ]` → ソート完了

# 実装

Haskellで実装してみます。

## 右へ移動（往路）

まず交換する関数を実装します。

再帰でリストを処理するときに左から見ていく都合上、最小値を右端に移動させます。

```hs
bswap [x] = [x]
bswap (x:y:zs)
    | x < y     = y : bswap (x:zs)
    | otherwise = x : bswap (y:zs)

main = do
    print $ bswap [4, 3, 1, 5, 2]
```
```text:実行結果
[4,3,5,2,1]
```

ここから右端とそれ以外を分離する必要があります。いくつか方法を示します。

```hs
bswap [x] = [x]
bswap (x:y:zs)
    | x < y     = y : bswap (x:zs)
    | otherwise = x : bswap (y:zs)

main = do
    let a = bswap [4, 3, 1, 5, 2]
    print a

    let (x:xs) = reverse a
    print (x, xs)

    let i  = length a - 1
        x  = a !! i
        xs = take i a
    print (x, xs)

    let x  = last a
        xs = init a
    print (x, xs)
```
```text:実行結果
[4,3,5,2,1]
(1,[2,5,3,4])
(1,[4,3,5,2])
(1,[4,3,5,2])
```

### 本体

`bswap`の結果を分離して再帰すれば完成です。上で示した各種分離方法を使ったものを示します。

```hs
bsort1 [] = []
bsort1 xs = y : bsort1 ys
    where
        (y:ys) = reverse $ bswap xs

bsort2 [] = []
bsort2 xs = y : bsort2 ys
    where
        a  = bswap xs
        i  = length a - 1
        y  = a !! i
        ys = take i a

bsort3 [] = []
bsort3 xs = y : bsort3 ys
    where
        a  = bswap xs
        y  = last a
        ys = init a

main = do
    print $ bsort1 [4, 3, 1, 5, 2]
    print $ bsort2 [4, 3, 1, 5, 2]
    print $ bsort3 [4, 3, 1, 5, 2]
```
```text:実行結果
[1,2,3,4,5]
[1,2,3,4,5]
[1,2,3,4,5]
```

## 左へ移動（復路）

復路で交換すれば左端に移動することが可能です。

再帰前に処理していたものを再帰後に処理するように変更します。

```hs
bswap [x] = [x]
bswap (x:xs)
    | x > y     = y:x:ys
    | otherwise = x:y:ys
    where
        (y:ys) = bswap xs

main = do
    let a = bswap [4, 3, 1, 5, 2]
    print a

    let (x:xs) = a
    print (x, xs)
```
```text:実行結果
[1,4,3,2,5]
(1,[4,3,2,5])
```

※ このテクニックで後ろから処理できるアルゴリズムは限られています。汎用的に逆転できるわけではありません。

### 本体

`bswap`の結果から左端を分離して再帰すれば完成です。

```hs
bsort [] = []
bsort xs = y : bsort ys
    where
        (y:ys) = bswap xs

main = do
    print $ bsort [4, 3, 1, 5, 2]
```
```text:実行結果
[1,2,3,4,5]
```

# まとめ

* ソート本体を実装する前に、交換する関数を作り込む。
* いきなり復路で実装しようとすると混乱するので、まず往路で実装して変形する。

```hs:コード全体
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

# 注意

以下のように一関数で実装すると一見動いているように見えます。しかし計算量が爆発します。

```hs
bsort []  = []
bsort [x] = [x]
bsort (x:xs)
    | x < y     = x : bsort (y:ys)
    | otherwise = y : bsort (x:ys)
    where
        (y:ys) = bsort xs

main = do
    print $ bsort [4, 3, 1, 5, 2]
```
```text:実行結果
[1,2,3,4,5]
```

大き目のリストでソートしたり、`trace`で過程を表示すると、無駄に処理が増えていることが分かります。

# 参考

* [バブルソート - Wikipedia](http://ja.wikipedia.org/wiki/%E3%83%90%E3%83%96%E3%83%AB%E3%82%BD%E3%83%BC%E3%83%88)
* [バブルソート](http://www.ics.kagoshima-u.ac.jp/~fuchida/edu/algorithm/sort-algorithm/bubble-sort.html)
