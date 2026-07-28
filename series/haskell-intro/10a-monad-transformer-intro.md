---
coediting: false
comments_count: 0
created_at: '2015-01-04T22:33:58+09:00'
id: 79fe0e4c77427368ae2d
likes_count: 3
private: false
reactions_count: 0
stocks_count: 2
tags:
- name: Haskell
  versions: []
title: 【解答例】Haskell モナド変換子 超入門
updated_at: '2016-01-04T23:12:21+09:00'
url: https://qiita.com/7shi/items/79fe0e4c77427368ae2d
slide: false
---

[Haskell モナド変換子 超入門](http://qiita.com/7shi/items/4408b76624067c17e933)の解答例です。

# Stateモナド

【問1】Stateモナドを扱う`return`を`StateT`を使って、`runState`を`runStateT`を使って再実装してください。

```hs
import Control.Monad.Identity
import Control.Monad.State hiding (return, runState)

return' x = StateT $ \s -> Identity (x, s)
runState' st = runIdentity . runStateT st

main = do
    let st = return' 1
    print $ runState' st ()
```
```text:実行結果
(1,())
```

Identityモナドが挟まっていることを意識します。

# StateTモナド変換子

## 再実装

【問2】StateTモナド変換子を扱う`bind`, `get`, `modify`, `lift`を実装してください。`do`は使わないでください。`>>=`はStateTモナド変換子以外にのみ使ってください。

```hs
import Control.Monad
import Control.Monad.State hiding (get, modify, lift)

a `bind` b = StateT $ \s ->
    runStateT  a    s >>= \(r, s1) ->
    runStateT (b r) s1

get = StateT $ \s -> return (s, s)
modify f = StateT $ \s -> return ((), f s)
lift m = StateT $ \s -> m >>= \a -> return (a, s)

fact x = (`execStateT` 1) $
    forM_ [1..x] $ \i ->
        modify (* i) `bind` \_ ->
        get `bind` \v ->
        lift $ putStrLn $ "*" ++ show i ++ " -> " ++ show v

main = fact 5 >>= print
```
```text:実行結果
*1 -> 1
*2 -> 2
*3 -> 6
*4 -> 24
*5 -> 120
()
```

## 書き直し

【問3】問2の`fact`を`do`と`<-`で書き直してください。問2で再実装した関数は使わないでください。

```hs
import Control.Monad
import Control.Monad.State

fact x = (`execStateT` 1) $ do
    forM_ [1..x] $ \i -> do
        modify (* i)
        v <- get
        lift $ putStrLn $ "*" ++ show i ++ " -> " ++ show v

main = fact 5 >>= print
```
```text:実行結果
*1 -> 1
*2 -> 2
*3 -> 6
*4 -> 24
*5 -> 120
()
```

# モナド変換子で合成

## Maybeモナド

【問4】次のコードは種類を判別しながら文字列を読み進めることを意図しています。Maybeモナドを使ってエラーが起きないように修正してください。モナド変換子は使わないでください。

```hs
import Data.Char

getch f (x:xs) | f x = Just (x, xs)
getch _ _            = Nothing

test s0 = do
    (ch1, s1) <- getch isUpper s0
    (ch2, s2) <- getch isLower s1
    (ch3, s3) <- getch isDigit s2
    return [ch1, ch2, ch3]

main = do
    print $ test "Aa0"
    print $ test "abc"
```
```実行結果
Just "Aa0"
Nothing
```

## StateTモナド変換子

【問5】問4の解答をStateTモナド変換子を使って書き直してください。

```hs
import Data.Char
import Control.Monad.State

getch f = StateT getch where
    getch (x:xs) | f x = Just (x, xs)
    getch _            = Nothing

test = evalStateT $ do
    ch1 <- getch isUpper
    ch2 <- getch isLower
    ch3 <- getch isDigit
    return [ch1, ch2, ch3]

main = do
    print $ test "Aa0"
    print $ test "abc"
```
```実行結果
Just "Aa0"
Nothing
```

# 他のモナド変換子

【問6】次のコードの`print`を`main`から各`test*`の`do`の中に移動してください。実行結果が同じになるように調整してください。

```hs
import Control.Monad.Reader
import Control.Monad.Writer
import Control.Monad.List

testR x = (`runReaderT` x) $ do
    a <- ask
    lift $ print $ a + 1

testW x = runWriterT $ do
    tell $ show x
    lift $ print $ x + 1

testL x = runListT $ do
    lift $ print [x + 1]

main = do
    testR 0
    testW 0
    testL 0
```
```text:実行結果
1
1
[1]
```

モナド変換子の評価結果がIOモナドで返ってくるため、`main`の中に直接記述できます。

# liftIO

【問7】問6を`liftIO`で解いてください。

```hs
import Control.Monad.Reader
import Control.Monad.Writer
import Control.Monad.List

testR x = (`runReaderT` x) $ do
    a <- ask
    liftIO $ print $ a + 1

testW x = runWriterT $ do
    tell $ show x
    liftIO $ print $ x + 1

testL x = runListT $ do
    liftIO $ print [x + 1]

main = do
    testR 0
    testW 0
    testL 0
```
```text:実行結果
1
1
[1]
```

# liftM

【問8】次のリスト内包表記を`liftM`系の関数で書き直してください。

```hs
import Control.Monad

main = do
    print $ liftM2 (,) [0, 1] [0, 2]
    print $ liftM2 (+) [0, 1] [0, 2]
```
```text:実行結果
[(0,0),(0,2),(1,0),(1,2)]
[0,2,1,3]
```

`(+)`だけだと動きが分かりにくいので、`(,)`と比較してみてください。
