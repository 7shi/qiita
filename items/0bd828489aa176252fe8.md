---
coediting: false
comments_count: 0
created_at: '2014-11-08T11:26:13+09:00'
id: 0bd828489aa176252fe8
likes_count: 3
private: false
reactions_count: 0
stocks_count: 2
tags:
- name: Haskell
  versions: []
title: Haskellで空間を実装してみた
updated_at: '2015-05-07T12:01:04+09:00'
url: https://qiita.com/7shi/items/0bd828489aa176252fe8
slide: false
---

[Haskellの実験メモ](http://qiita.com/7shi/items/b6cbb7df2dd969c84f49)です。

空間について勉強したらHaskellで実装してみたくなりました。

※ 遊びなので厳密さは考慮していません。Vectorとか名前が微妙ですが、割り切っています。

* 型クラスのインスタンスに型シノニムを使えるようにするため`FlexibleInstances`拡張を使用しています。
* 空間の拡張を型クラスの継承で表現しています。

```hs
{-# LANGUAGE FlexibleInstances #-}

class VectorSpace a where
    (@+) :: a -> a -> a
    (@*) :: Double -> a -> a

class VectorSpace a => NormedSpace a where
    norm :: a -> Double

class NormedSpace a => UnitarySpace a where
    innerProduct :: a -> a -> Double

type Vector = (Double, Double)

instance VectorSpace Vector where
    (x1, y1) @+ (x2, y2) = (x1 + x2, y1 + y2)
    a @* (x, y) = (a * x, a * y)

instance NormedSpace Vector where
    norm (x, y) = sqrt (x ^ 2 + y ^ 2)

instance UnitarySpace Vector where
    innerProduct (x1, y1) (x2, y2) = x1 * x2 + y1 * y2

print2 a b = do
    putStr a
    print b

main = do
    let a = (1.0, 2.0) :: Vector
        b = (3.0, 4.0) :: Vector
    print2 "a = " a
    print2 "b = " b
    print2 "a @+ b = " $ a @+ b
    print2 "3 @* a = " $ 3 @* a
    print2 "3 @* b = " $ 3 @* b
    print2 "norm a = " $ norm a
    print2 "norm b = " $ norm b
    print2 "innerProduct a b = " $ innerProduct a b
```
```text:実行結果
a = (1.0,2.0)
b = (3.0,4.0)
a @+ b = (4.0,6.0)
3 @* a = (3.0,6.0)
3 @* b = (9.0,12.0)
norm a = 2.23606797749979
norm b = 5.0
innerProduct a b = 11.0
```

# 参考

* Wikipedia
    * [ベクトル空間](http://ja.wikipedia.org/wiki/%E3%83%99%E3%82%AF%E3%83%88%E3%83%AB%E7%A9%BA%E9%96%93)
    * [ノルム線型空間](http://ja.wikipedia.org/wiki/%E3%83%8E%E3%83%AB%E3%83%A0%E7%B7%9A%E5%9E%8B%E7%A9%BA%E9%96%93)
    * [計量ベクトル空間](http://ja.wikipedia.org/wiki/%E8%A8%88%E9%87%8F%E3%83%99%E3%82%AF%E3%83%88%E3%83%AB%E7%A9%BA%E9%96%93)
* [型クラス - ウォークスルー Haskell](http://walk.wgag.net/haskell/typeclass.html)
* [Haskellで関数のオーバーロード](http://qiita.com/7shi/items/17a1567a635af17fc83f)
