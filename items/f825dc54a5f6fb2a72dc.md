---
coediting: false
comments_count: 0
created_at: '2015-07-28T18:21:31+09:00'
id: f825dc54a5f6fb2a72dc
likes_count: 0
private: false
reactions_count: 0
stocks_count: 0
tags:
- name: Haskell
  versions: []
title: 【解答例】Haskell 例外処理 超入門
updated_at: '2015-09-29T12:00:02+09:00'
url: https://qiita.com/7shi/items/f825dc54a5f6fb2a72dc
slide: false
---

[Haskell 例外処理 超入門](http://qiita.com/7shi/items/73e534c47bbebc71b37e)の解答例です。

# エラーの理由

【問1】次のコードで脱出の理由（`out of range`, `not xxx: 'X'`）を返すように修正してください。

```hs
import Data.Char
import Control.Monad

getch s n
    | n < length s = Right $ s !! n
    | otherwise    = Left "out of range"

test s = do
    ch0 <- getch s 0
    ch1 <- getch s 1
    ch2 <- getch s 2
    unless (isUpper ch0) $ Left $ "not upper: " ++ show ch0
    unless (isLower ch1) $ Left $ "not lower: " ++ show ch1
    unless (isDigit ch2) $ Left $ "not digit: " ++ show ch2
    return [ch0, ch1, ch2]

main = do
    print $ test "Aa0"
    print $ test "A"
    print $ test "aa0"
    print $ test "AA0"
    print $ test "Aaa"
```
```text:実行結果
Right "Aa0"
Left "out of range"
Left "not upper: 'a'"
Left "not lower: 'A'"
Left "not digit: 'a'"
```

# Fizz Buzz

【問2】次のJavaScriptのコードを移植してください。Eitherモナドを使ってなるべく同じ構造にしてください。

```hs
import Control.Monad
import Data.Either

fizzBuzz x = either id id $ do
    when (x `mod` 3 == 0 && x `mod` 5 == 0) $ Left "FizzBuzz"
    when (x `mod` 3 == 0) $ Left "Fizz"
    when (x `mod` 5 == 0) $ Left "Buzz"
    return $ show x

main = do
    forM_ [1..15] $ \i ->
        putStrLn $ fizzBuzz i
```
```text:実行結果
1
2
Fizz
4
Buzz
Fizz
7
8
Fizz
Buzz
11
Fizz
13
14
FizzBuzz
```

# 例外

【問3】次のコードは例外が発生して途中で止まってしまいます。例外が発生したら元の文字列を表示して続行するように修正してください。

```hs
import Control.Monad
import Control.Exception

main =
    forM_ ["1", "a", "3"] $ \s ->
        print (read s :: Int)
        `catch` \(SomeException _) ->
            print s
```
```text:実行結果
1
"a"
3
```

# try

【問4】`try`は例外を`Left`に変換する関数です。次のコードはうまく動きませんが、`try`の動作を確認できるように修正してください。

```hs
import Control.Exception
import Control.Monad

main = do
    forM_ [0..3] $ \i -> do
        a <- try $ evaluate $ 6 `div` i
        print (a :: Either SomeException Int)
```
```text:実行結果
Left divide by zero
Right 6
Right 3
Right 2
```

# モナド変換子

【問5】問1の解答をStateTモナド変換子を使って書き直してください。

```hs
import Data.Char
import Control.Monad.State

getch f s = StateT getch where
    getch (x:xs)
        | f x       = Right (x, xs)
        | otherwise = Left $ "not " ++ s ++ ": " ++ show x
    getch _         = Left "out of range"

test = evalStateT $ do
    ch0 <- getch isUpper "upper"
    ch1 <- getch isLower "lower"
    ch2 <- getch isDigit "digit"
    return [ch0, ch1, ch2]

main = do
    print $ test "Aa0"
    print $ test "A"
    print $ test "aa0"
    print $ test "AA0"
    print $ test "Aaa"
```
```text:実行結果
Right "Aa0"
Left "out of range"
Left "not upper: 'a'"
Left "not lower: 'A'"
Left "not digit: 'a'"
```
