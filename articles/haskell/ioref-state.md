---
coediting: false
comments_count: 4
created_at: '2014-11-21T17:52:21+09:00'
id: 3722f0a677d6763eb395
likes_count: 3
private: false
reactions_count: 0
stocks_count: 4
tags:
- name: Haskell
  versions: []
title: IORefとState
updated_at: '2015-05-07T12:01:57+09:00'
url: https://qiita.com/7shi/items/3722f0a677d6763eb395
slide: false
---

[Haskellの実験メモ](http://qiita.com/7shi/items/b6cbb7df2dd969c84f49)です。

IORefからStateに話を繋げられないかと考えています。

IORefとStateで変数を書き換える動作を模倣してみました。

```hs
import Data.IORef
import Control.Monad.State

test1 n = do
    a <- newIORef n
    if n == 1
        then writeIORef a $ n + 10
        else writeIORef a $ n + 1
    modifyIORef a (+ 5)
    readIORef a

test2 = execState $ do
    n <- get
    if n == 1
        then put $ n + 10
        else put $ n + 1
    modify (+ 5)

main = do
    print =<< test1 1
    print  $  test2 1
```
```text:実行結果
16
16
```

Stateは処理後に外せるのが便利だと思いました。

※ `unsafePerformIO`はナシです。
