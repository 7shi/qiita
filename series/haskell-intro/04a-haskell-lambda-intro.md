---
coediting: false
comments_count: 0
created_at: '2014-11-27T23:53:55+09:00'
id: bfa4c282c504c24578d2
likes_count: 6
private: false
reactions_count: 0
stocks_count: 3
tags:
- name: Haskell
  versions: []
title: 【解答例】Haskell ラムダ 超入門
updated_at: '2015-01-23T15:47:53+09:00'
url: https://qiita.com/7shi/items/bfa4c282c504c24578d2
slide: false
---

[Haskell ラムダ 超入門](http://qiita.com/7shi/items/1345bf32003faff435cb)の解答例です。

# 階乗

【問1】次に示す関数`fact`をラムダ式と`case`～`of`で書き換えてください。

```hs
fact = \n -> case n of
    0         -> 1
    _ | n > 0 -> n * fact (n - 1)

main = do
    print $ fact 5
```
```text:実行結果
120
```

# 複数の引数

【問2】次に示す関数`add`をラムダ式で書き換えてください。

```hs
add :: Int -> Int -> Int
add =  \x  -> \y  -> x + y

main = do
    print $ add 2 3
```
```text:実行結果
5
```

# 無名関数

【問3】次に示す関数`add`を定義せずに、呼び出し側で無名関数にインライン展開してください。

```hs
main = do
    print $ (\x y -> x + y) 2 3
```
```text:実行結果
5
```

# 高階関数

## 引数

【問4】次に示す関数`f`と`add`を定義せずに、呼び出し側で無名関数にインライン展開してください。

```hs
main = do
    print $ (\g -> g 1 2) $ \x y -> x + y
```
```text:実行結果
3
```

## 戻り値

【問5】次に示す関数`add`を定義せずに、呼び出し側で無名関数にインライン展開してください。

```hs
main = do
    print $ (\x -> \y -> x + y) 1 2
```
```text:実行結果
3
```

# カリー化

【問6】次に示す関数`combine`を、引数1つずつに分割してネストさせたラムダ式で書き換えてください。

```hs
combine = \a -> \b -> \c -> a:b:[c]

main = do
    let a = combine 1
        b = a 2
        c = b 3
    print c
    print $ combine 'a' 'b' 'c'
```
```text:実行結果
[1,2,3]
"abc"
```

# 部分適用

【問7】次のコードから関数`double`を除去してください。ラムダ式は使わないでください。

```hs
f xs g = [g x | x <- xs]

main = do
    print $ f [1..5] $ (*) 2
```
```text:実行結果
[2,4,6,8,10]
```

# 演算子

【問8】次のコードからラムダ式を排除してください。

```hs
f1 g = g 1
f2 g = g 2 3

main = do
    print $ f1 $ subtract 3
    print $ f1 (3 -)
    print $ f2 (+)
```
```text:実行結果
-2
2
5
```

# 再実装

## 再帰

【問9】`map`, `filter`, `flip`, `foldl`, `foldr`を再帰で再実装してください。関数名には`'`を付けてください。

```hs
map' _ []     = []
map' f (x:xs) = f x : map' f xs

filter' _ [] = []
filter' f (x:xs)
    | f x       = x : filter' f xs
    | otherwise =     filter' f xs

flip' f x y = f y x 

foldl' _ v []     = v
foldl' f v (x:xs) = foldl' f (f v x) xs 

foldr' _ v []     = v
foldr' f v (x:xs) = f x $ foldr' f v xs 

main = do
    print $ map' (* 2) [1..5]
    print $ filter' (< 5) [1..9]
    print $ flip' map' [1..5] (* 2)
    print $ foldl' (+) 0 [1..100]
    print $ foldl' (-) 0 [1..5]
    print $ foldr' (-) 0 [1..5]
```
```text:実行結果
[2,4,6,8,10]
[1,2,3,4]
[2,4,6,8,10]
5050
-15
3
```

## foldl

【問10】`foldl`で`reverse`と`maximum`と`minimum`を再実装してください。関数名には`'`を付けてください。

```hs
reverse' = foldl (flip (:)) []
maximum' (x:xs) = foldl max x xs
minimum' (x:xs) = foldl min x xs

main = do
    let src = [-5..5]
    print $ reverse' src
    print $ maximum' src
    print $ minimum' src
```
```text:実行結果
[5,4,3,2,1,0,-1,-2,-3,-4,-5]
5
-5
```

# クイックソート

【問11】次に示す関数`qsort`を`filter`で書き替えてください。

```hs
qsort []     = []
qsort (n:xs) = qsort lt ++ [n] ++ qsort gteq
    where
        lt   = filter (<  n) xs
        gteq = filter (>= n) xs

main = do
    print $ qsort [4, 6, 9, 8, 3, 5, 1, 7, 2]
```
```text:実行結果
[1,2,3,4,5,6,7,8,9]
```

# バブル

【問12】次に示す関数`bswap`を`foldr`で書き替えてください。

```hs
bswap = foldr (\x xs -> case xs of
    [] -> [x]
    (y:ys) | x > y     -> y:x:ys
           | otherwise -> x:y:ys) []

main = do
    print $ bswap [4, 3, 1, 5, 2]
```
```text:実行結果
[1,4,3,2,5]
```

# フィボナッチ数

【問13】Yコンビネータを使って10番目のフィボナッチ数を計算してください。

```hs
y f = f (y f)

main = do
    print $ flip y 10 $
        \fib n -> case n of
            0 -> 0
            1 -> 1
            n | n > 1 -> fib (n - 2) + fib (n - 1)
```
```text:実行結果
55
```
