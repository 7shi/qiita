---
coediting: false
comments_count: 0
created_at: '2014-12-19T02:37:57+09:00'
id: 4a24fd9395f5a60d811d
likes_count: 1
private: false
reactions_count: 0
stocks_count: 2
tags:
- name: Haskell
  versions: []
title: 【解答例】Haskell リストモナド 超入門
updated_at: '2014-12-19T02:39:56+09:00'
url: https://qiita.com/7shi/items/4a24fd9395f5a60d811d
slide: false
---

[Haskell リストモナド 超入門](http://qiita.com/7shi/items/deb19c4cba933590ffbf)の解答例です。

# リストの作成

【問1】`return`を使って`[1, 2, 3]`を作ってください。

```hs
main = do
    print $ 1 : 2 : return 3
```
```text:実行結果
[1,2,3]
```

# 型クラス制約

【問2】次に示す関数`join`の型から仕様を推定して、コードで検証してください。

二重にネストしたモナドを一重にします。

```hs
import Control.Monad

main = print $ join [[1, 2], [3]]
```
```text:実行結果
[1,2,3]
```

# ループ

【問3】次のコードを`join`と`forM`で書き替えてください。

```hs
import Control.Monad

main = do
    print $ join $ join $
        forM [1..3] $ \x ->
            forM "abc" $ \y ->
                return (x, y)
```
```text:実行結果
[(1,'a'),(1,'b'),(1,'c'),(2,'a'),(2,'b'),(2,'c'),(3,'a'),(3,'b'),(3,'c')]
```

# 再実装

【問4】リストモナドを扱う`bind`と`return'`を実装してください。`bind`には`foldr`を使ってください。

```hs
bind xs f = foldr ((++) . f) [] xs
return' x = [x]

main = do
    print $ [1..3] `bind` \x -> "abc" `bind` \y -> return' (x, y)
```
```text:実行結果
[(1,'a'),(1,'b'),(1,'c'),(2,'a'),(2,'b'),(2,'c'),(3,'a'),(3,'b'),(3,'c')]
```

# リスト内包表記

## 書き換え

【問5】次のリスト内包表記を`do`で書き換えてください。

```hs
main = do
    print $ do
        x <- [1..5]
        y <- [1..5]
        if x + y == 6
            then return (x, y)
            else []
```
```text:実行結果
[(1,5),(2,4),(3,3),(4,2),(5,1)]
```

## テスト

【問6】問5のコードを問4で実装した`bind`と`return'`に対応させてテストしてください。

```hs
bind xs f = foldr ((++) . f) [] xs
return' x = [x]

main = do
    print $ do
        [1..5] `bind` \x -> [1..5] `bind` \y ->
            if x + y == 6 then return' (x, y) else []
```
```text:実行結果
[(1,5),(2,4),(3,3),(4,2),(5,1)]
```
