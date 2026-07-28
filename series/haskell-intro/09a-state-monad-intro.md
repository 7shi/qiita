---
coediting: false
comments_count: 0
created_at: '2014-12-27T10:47:30+09:00'
id: fe978f1bd2d52760419d
likes_count: 4
private: false
reactions_count: 0
stocks_count: 2
tags:
- name: Haskell
  versions: []
title: 【解答例】Haskell 状態系モナド 超入門
updated_at: '2015-01-06T14:20:21+09:00'
url: https://qiita.com/7shi/items/fe978f1bd2d52760419d
slide: false
---

[Haskell 状態系モナド 超入門](http://qiita.com/7shi/items/2e9bff5d88302de1a9e9)の解答例です。

# STモナド

## Brainf*ckの前処理

【問1】次のJavaScriptによるBrainf*ckの前処理をSTモナドで書き直してください。

```hs
import Control.Monad
import Control.Monad.ST
import Data.Array.ST
import Data.STRef

bf = "+++++++++[>++++++++<-]>."

main = do
    let jmp = runST $ do
        jmp <- newArray (0, length bf - 1) 0 :: ST s (STUArray s Int Int)
        loops <- newSTRef []
        forM_ [0 .. length bf - 1] $ \i -> do
            case bf !! i of
                '[' -> modifySTRef loops (i:)
                ']' -> do
                    start <- do
                        (h:t) <- readSTRef loops
                        writeSTRef loops t
                        return h
                    writeArray jmp start i
                    writeArray jmp i start
                _ -> return ()
        getElems jmp
    print jmp
```
```text:実行結果
[0,0,0,0,0,0,0,0,0,21,0,0,0,0,0,0,0,0,0,0,0,9,0,0]
```

## 再実装

【問2】STモナドを扱う`bind`と`return'`を実装してください。

```hs
{-# LANGUAGE UnboxedTuples #-}

import GHC.ST
import Data.STRef

unST (ST f) = f

a `bind` b = ST $ \s ->
    let (# s1, r1 #) = unST a s
        (# s2, r2 #) = unST (b r1) s1
    in  (# s2, r2 #)

return' x = ST $ \s -> (# s, x #)

main = do
    print $ runST $
        return' 1 `bind` newSTRef `bind` \a ->
        modifySTRef a (+1) `bind` \_ ->
        readSTRef a `bind` return'
```
```text:実行結果
2
```

# Stateモナド

## 再実装

【問3】Stateモナドを扱う`bind`, `return'`, `get'`, `put'`を実装してください。

```hs
import Control.Monad
import Control.Monad.State

a `bind` b = state $ \s ->
    let (r1, s1) = runState a s
        (r2, s2) = runState (b r1) s1
    in  (r2, s2)
return' x  = state $ \s -> (x , s)
get'       = state $ \s -> (s , s)
put'    x  = state $ \_ -> ((), x)

fib x = (`evalState` (0, 1)) $
    (replicateM_ (x - 1) $
        get' `bind` \(a, b) -> put' (b, a + b)) `bind` \_ ->
    get' `bind` \v -> return' $ snd v

main = do
    print $ fib 10
```
```text:実行結果
55
```

## 書き直し

【問4】問3の`fib`を`do`と`<-`で書き直してください。問3で再実装した関数は使わないでください。

```hs
import Control.Monad
import Control.Monad.State

fib x = (`evalState` (0, 1)) $ do
    replicateM_ (x - 1) $ do
        (a, b) <- get
        put (b, a + b)
    v <- get
    return $ snd v

main = do
    print $ fib 10
```
```text:実行結果
55
```

[動的計画法](http://ja.wikipedia.org/wiki/%E5%8B%95%E7%9A%84%E8%A8%88%E7%94%BB%E6%B3%95)によるフィボナッチ数の計算です。

# Readerモナド

## 再実装

【問5】Readerモナドを扱う`bind`, `return'`, `ask'`, `local'`を実装してください。

```hs
import Control.Monad.Reader

a `bind` b = reader $ \r ->
    runReader (b (runReader a r)) r

return' x = reader $ \_ -> x
ask' = reader $ \r -> r
local' f m = reader $ \r -> runReader m $ f r

test x = (`runReader` x) $
    ask' `bind` \a ->
    (local' (+ 1) $
        ask' `bind` \b' ->
        return' b') `bind` \b ->
    ask' `bind` \c ->
    return' (a, b, c)

main = print $ test 1
```
```text:実行結果
(1,2,1)
```

## 書き直し

【問6】問5の`test`を`do`と`<-`で書き直してください。問5で再実装した関数は使わないでください。

```hs
import Control.Monad.Reader

test x = (`runReader` x) $ do
    a <- ask
    b <- local (+ 1) $ do
        b' <- ask
        return b'
    c <- ask
    return (a, b, c)

main = print $ test 1
```
```text:実行結果
(1,2,1)
```

# Writerモナド

## 再実装

【問7】Writerモナドを扱う`bind`, `return'`, `tell'`を実装してください。

```hs
import Control.Monad.Writer

a `bind` b = writer $
    let (r1, w1) = runWriter  a
        (r2, w2) = runWriter (b r1)
    in  (r2, w1 ++ w2)

return' x = writer (x, [])
tell' x = writer ((), x)

test = execWriter $
    tell' "Hello" `bind` \_ ->
    tell' ", "    `bind` \_ ->
    tell' "World" `bind` \_ ->
    tell' "!!"    `bind` \_ ->
    return' ()

main = print test
```
```text:実行結果
"Hello, World!!"
```

`bind`のポイントは、状態を追記するだけなら引数としてバケツリレーする必要がないという点です。

## 書き直し

【問8】問7の`test`を`do`と`<-`で書き直してください。問7で再実装した関数は使わないでください。

```hs
import Control.Monad.Writer

test = execWriter $ do
    tell "Hello"
    tell ", "
    tell "World"
    tell "!!"
    return ()

main = print test
```
```text:実行結果
"Hello, World!!"
```

# 関数モナド

【問9】先ほどの例の`test`を通常の関数として書き直してください。

```hs
test x =
    let a = (+ 1) x  -- x + 1
        b = (* 2) x  -- x * 2
    in (a, b)

main = do
    print $ test 5
```
```text:実行結果
(6,10)
```
