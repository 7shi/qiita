---
coediting: false
comments_count: 0
created_at: '2014-12-03T15:14:48+09:00'
id: cb99bb70ee103408bf51
likes_count: 4
private: false
reactions_count: 0
stocks_count: 1
tags:
- name: Haskell
  versions: []
title: 【解答例】Haskell アクションとラムダ 超入門
updated_at: '2015-01-19T09:34:08+09:00'
url: https://qiita.com/7shi/items/cb99bb70ee103408bf51
slide: false
---

[Haskell アクションとラムダ 超入門](http://qiita.com/7shi/items/4a8a2807bb5186576c61)の解答例です。

# シャッフル

【問1】次のコードから`do`を取り除いて、`>>=`でつないでください。

```hs
import System.Random

shuffle [] = return []
shuffle xs =
    (getStdRandom $ randomR (0, length xs - 1) :: IO Int) >>= \n ->
    (shuffle $ take n xs ++ drop (n + 1) xs) >>= \xs' ->
    return $ (xs !! n) : xs'

main =
    shuffle [1..9] >>=
    print
```
```text:実行結果（毎回異なる）
[3,5,4,9,2,7,8,6,1]
```

# 配列の更新

【問2】配列には`modifyIORef`に相当する関数がありません。`modifyArray`を実装してください。

```hs
import Data.Array.IO
import Control.Applicative

modifyArray a i f = writeArray a i =<< f <$> readArray a i

main = do
    a <- newArray (0, 2) 0 :: IO (IOUArray Int Int)
    print =<< getElems a
    modifyArray a 1 (+ 5)
    print =<< getElems a
```
```text:実行結果
[0,0,0]
[0,5,0]
```

# 再実装

【問3】`replicateM`, `replicateM_`, `forM`, `forM_`, `when`, `unless`を再実装してください。関数名には`'`を付けてください。

```hs
import Control.Applicative
import System.Random

replicateM' 0 _ = return []
replicateM' n a | n > 0 = (:) <$> a <*> replicateM' (n - 1) a

replicateM_' 0 _ = return []
replicateM_' n a | n > 0 = a >> replicateM_' (n - 1) a

forM' [] _ = return []
forM' (x:xs) f = (:) <$> f x <*> forM' xs f

forM_' [] _ = return []
forM_' (x:xs) f = f x >> forM_' xs f

when' b a = if b then a else return ()
unless' b = when' $ not b

main = do
    let dice = getStdRandom $ randomR (1, 6) :: IO Int
    print =<< replicateM' 5 dice
    putStrLn "---"
    replicateM_' 3 $ do
        print =<< dice
    putStrLn "---"
    a <- forM' [1..3] $ \i -> do
        print i
        return i
    print a
    putStrLn "---"
    forM_' [1..3] $ \i -> do
        print i
    putStrLn "---"
    let y f = f (y f)
    y $ \f -> do
        r <- dice
        print r
        when' (r /= 1) f
    putStrLn "---"
    y $ \f -> do
        r <- dice
        print r
        unless' (r == 6) f
```
```text:実行結果（毎回異なる）
[4,3,2,5,1]
---
2
6
2
---
1
2
3
[1,2,3]
---
1
2
3
---
3
2
1
---
6
```

# 正規乱数

【問4】0.0～1.0までのDouble型の乱数を12個足したものを四捨五入して6を引いた整数値について、100回の分布を求めてください。四捨五入には[round](http://hackage.haskell.org/package/base-4.7.0.1/docs/Prelude.html#v:round)ではなく、切り捨て関数[truncate](http://hackage.haskell.org/package/base-4.7.0.1/docs/Prelude.html#v:truncate)を工夫して使用してください。

```hs
import Control.Monad
import System.Random

rand :: IO Double
rand = getStdRandom $ randomR (0.0, 1.0)

main = do
    r <- replicateM 100 $ do
        rands <- replicateM 12 rand
        return $ truncate (sum rands + 0.5) - 6
    forM_ [-3 .. 3] $ \i -> do
        let c = length $ filter (== i) r
            i' = show i
            n = replicate (2 - length i') ' ' ++ i'
        putStrLn $ n ++ ": " ++ replicate c '*'
```
```text:実行結果（毎回異なる）
-3: *
-2: ******
-1: ****************************
 0: **********************************
 1: ***********************
 2: *******
 3: *
```

[中心極限定理](http://ja.wikipedia.org/wiki/%E4%B8%AD%E5%BF%83%E6%A5%B5%E9%99%90%E5%AE%9A%E7%90%86)により[正規乱数](http://ja.wikipedia.org/wiki/%E4%B9%B1%E6%95%B0%E5%88%97#.E6.AD.A3.E8.A6.8F.E4.B9.B1.E6.95.B0)を生成しています。
