---
coediting: false
comments_count: 0
created_at: '2014-12-11T16:11:19+09:00'
id: dfc114f133580ee85686
likes_count: 2
private: false
reactions_count: 0
stocks_count: 0
tags:
- name: Haskell
  versions: []
title: 【解答例】Haskell IOモナド 超入門
updated_at: '2014-12-14T09:14:39+09:00'
url: https://qiita.com/7shi/items/dfc114f133580ee85686
slide: false
---

[Haskell IOモナド 超入門](http://qiita.com/7shi/items/d3d3492ddd90d47160f2)の解答例です。

# シャッフル

【問1】次のコードから`do`を取り除いて、bindや`return`は使わずに`unIO`や`IO`で書き換えてください。

```hs
{-# LANGUAGE UnboxedTuples #-}

import GHC.Base
import System.Random

shuffle [] = IO $ \s -> (# s, [] #)
shuffle xs = IO $ \s ->
    let (# s1, n   #) = unIO (getStdRandom $ randomR (0, length xs - 1) :: IO Int) s
        (# s2, xs' #) = unIO (shuffle $ take n xs ++ drop (n + 1) xs) s1
    in  (# s2, (xs !! n) : xs' #)

main = IO $ \s ->
    let (# s1, xs #) = unIO (shuffle [1..9]) s
        (# s2, r  #) = unIO (print xs) s1
    in  (# s2, r  #)
```
```text:実行結果（毎回異なる）
[3,5,4,9,2,7,8,6,1]
```

# 再実装

【問2】IOモナドを扱う`bind`と`return'`を実装してください。`>>=`, `<<=`, `<-`, `return`は使わないでください。

```hs
{-# LANGUAGE UnboxedTuples #-}

import GHC.Base

a `bind` b = IO $ \s ->
    let (# s1, r1 #) = unIO a s
        (# s2, r2 #) = unIO (b r1) s1
    in  (# s2, r2 #)

return' x = IO $ \s -> (# s, x #)

main = return' "hello" `bind` putStr `bind` print
```
```text:実行結果
hello()
```
