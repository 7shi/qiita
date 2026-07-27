---
coediting: false
comments_count: 0
created_at: '2015-01-22T17:14:26+09:00'
id: 5a8b25d8db772bc27a71
likes_count: 1
private: false
reactions_count: 0
stocks_count: 0
tags:
- name: Haskell
  versions: []
title: 【解答例】Haskell Maybeモナド 超入門
updated_at: '2015-01-22T21:46:10+09:00'
url: https://qiita.com/7shi/items/5a8b25d8db772bc27a71
slide: false
---

[Haskell Maybeモナド 超入門](http://qiita.com/7shi/items/c7d7eec066af0fe0688d)の解答例です。

# フィボナッチ数

【問1】次の関数`fib`でエラーを回避するためMaybeモナドで書き換えてください。

```hs
import Control.Applicative

fib 0 = Just 0
fib 1 = Just 1
fib n | n > 1     = (+) <$> fib (n - 2) <*> fib (n - 1)
      | otherwise = Nothing

main = do
    print $ fib (-1)
    print $ fib 6
```
```text:実行結果
Nothing
Just 8
```

# 再実装

## bind

【問2】Maybeモナドを扱う`bind`を実装してください。

```hs
(Just a) `bind` b = b a
Nothing  `bind` _ = Nothing

main = do
    print $ Just 1 `bind` \a -> Just $ a * 2
    print $ Just 1 `bind` \a -> Nothing `bind` \b -> Just $ a * b
```
```text:実行結果
Just 2
Nothing
```

## mapMaybe

### 再帰

【問3】`mapMaybe`を再帰で再実装して、先ほどのサンプルで検証してください。

```hs
import Control.Applicative

mapMaybe _ []     = []
mapMaybe f (x:xs) = case f x of
    Just y  -> y : mapMaybe f xs
    Nothing ->     mapMaybe f xs

fact 0 = Just 1
fact n | n > 0     = (n *) <$> fact (n - 1)
       | otherwise = Nothing

facts n = ( map      fact [n, n - 1, n - 2]
          , mapMaybe fact [n, n - 1, n - 2]
          )

main = do
    print $ facts 3
    print $ facts 2
    print $ facts 1  -- cで失敗
    print $ facts 0  -- bで失敗
```
```text:実行結果
([Just 6,Just 2,Just 1],[6,2,1])
([Just 2,Just 1,Just 1],[2,1,1])
([Just 1,Just 1,Nothing],[1,1])
([Just 1,Nothing,Nothing],[1])
```

### foldr

【問4】問3の解答を`foldr`で書き換えてください。

```hs
import Control.Applicative

mapMaybe f = (`foldr` []) $ \x xs -> case f x of
    Just x' -> x':xs
    Nothing ->    xs

fact 0 = Just 1
fact n | n > 0     = (n *) <$> fact (n - 1)
       | otherwise = Nothing

facts n = ( map      fact [n, n - 1, n - 2]
          , mapMaybe fact [n, n - 1, n - 2]
          )

main = do
    print $ facts 3
    print $ facts 2
    print $ facts 1  -- cで失敗
    print $ facts 0  -- bで失敗
```
```text:実行結果
([Just 6,Just 2,Just 1],[6,2,1])
([Just 2,Just 1,Just 1],[2,1,1])
([Just 1,Just 1,Nothing],[1,1])
([Just 1,Nothing,Nothing],[1])
```

# 文字列チェック

【問5】文字列`s`が「`x`文字の連続した数字＋`y`文字の連続した大文字」で構成されるか判定する関数`numUpper x y s`を実装してください。成功した場合は`Just s`、失敗した場合は`Nothing`を返してください。余計な文字は含まないものとします。

```hs
import Data.Char
import Control.Monad

numUpper x y s = do
    guard $ length s == x + y
    guard $ length (filter isDigit $ take x s) == x
    guard $ length (filter isUpper $ drop x s) == y
    Just s

main = do
    print $ numUpper 3 2 "123AB"
    print $ numUpper 3 2 "123ABC"
    print $ numUpper 3 2 "12ABC"
```
```text:実行結果
Just "123AB"
Nothing
Nothing
```

# Alternative

【問6】文字列`s`の先頭3文字が「数字＋大文字＋小文字」または「大文字＋小文字＋小文字」で構成されるかを判定する関数`check s`を実装してください。`<|>`を使って、成功した場合は`Just s`、失敗した場合は`Nothing`を返してください。後続の文字は判定に影響しないものとします。

```hs
import Data.Char
import Control.Applicative
import Control.Monad

check s = do
    guard $ length s >= 3
    do
        guard $ isDigit $ s !! 0
        guard $ isUpper $ s !! 1
        <|> do
        guard $ isUpper $ s !! 0
        guard $ isLower $ s !! 1
    guard $ isLower $ s !! 2
    Just s

main = do
    print $ check "1"
    print $ check "2Ab"
    print $ check "Abc"
    print $ check "Ab1"
    print $ check "1AB"
```
```text:実行結果
Nothing
Just "2Ab"
Just "Abc"
Nothing
Nothing
```
