---
coediting: false
comments_count: 0
created_at: '2014-11-28T11:14:32+09:00'
id: 82b1e074a360dd28fcbe
likes_count: 0
private: false
reactions_count: 0
stocks_count: 0
tags:
- name: Haskell
  versions: []
title: 再帰をfoldrで書き換えて確認
updated_at: '2015-05-07T12:03:07+09:00'
url: https://qiita.com/7shi/items/82b1e074a360dd28fcbe
slide: false
---

[Haskellの実験メモ](http://qiita.com/7shi/items/b6cbb7df2dd969c84f49)です。

再帰を`foldr`で書き換えた実装が同じ動きをするかどうか、ランダムデータで確認しました。

自前で乱数生成せずにQuickCheckを使うべき、というかそもそも定理証明支援系を使うべきなんでしょうけど。

```hs
import System.Random
import Control.Monad

shuffle [] = return []
shuffle xs = do
    n <- getStdRandom $ randomR (0, length xs - 1) :: IO Int
    xs' <- shuffle $ take n xs ++ drop (n + 1) xs
    return $ (xs !! n) : xs'

bswap [x] = [x]
bswap (x:xs)
    | x > y     = y:x:ys
    | otherwise = x:y:ys
    where
        (y:ys) = bswap xs

bswap' = foldr (\x xs -> case xs of
    [] -> [x]
    (y:ys) | x > y     -> y:x:ys
           | otherwise -> x:y:ys) []

main = do
    a <- forM [1..1000] $ \_ -> do
        len <- getStdRandom $ randomR (5, 200) :: IO Int
        xs <- shuffle [1..len]
        let a  = bswap  xs
            a' = bswap' xs
        --print (a == a', xs, a, a')
        return $ if a == a' then 1 else 0
    let ok = sum a
        ng = length a - ok
    putStrLn $ "OK: " ++ show ok ++ ", NG: " ++ show ng
```
```text:実行結果
OK: 1000, NG: 0
```
