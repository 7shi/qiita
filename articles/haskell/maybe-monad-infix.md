---
coediting: false
comments_count: 0
created_at: '2015-07-24T13:47:15+09:00'
id: cda901af6abb732f9c64
likes_count: 2
private: false
reactions_count: 0
stocks_count: 2
tags:
- name: Haskell
  versions: []
title: Maybeモナドによる中置記法の処理
updated_at: '2015-09-28T21:28:42+09:00'
url: https://qiita.com/7shi/items/cda901af6abb732f9c64
slide: false
---

[Haskellの実験メモ](http://qiita.com/7shi/items/b6cbb7df2dd969c84f49)です。

パターンマッチをMaybeモナドで表現して、状態の受け渡しをStateTモナド変換子で合成してみました。コードを書き換える過程を残しておきます。

元ネタとなる記事があります。

* [Stateモナドによる中置記法の処理](http://qiita.com/7shi/items/ee5afe4f088f0a1fc8c2) 2015.7.22

元記事ではState→Maybeの順番ですが、今回の記事はその逆（Maybe→State）です。

今回の手順は途中過程が複雑なため、実験メモ扱いとします。

# 準備

元記事からStateモナドを適用する前のコードを持って来て改造します。

関数レベルのパターンマッチを`case`で書き換えます。EBNFのコメントを付け、テストは削ります。

```hs
eval src = fst $ expr $ words src

-- expr = term, [expr']
expr src = let (y, src') = term src in expr' y src'
-- expr' = ("+", term, [expr']) | ("-", term, [expr'])
expr' x src = case src of
    ("+":src') -> let (y, src'') = term src' in expr' (x + y) src''
    ("-":src') -> let (y, src'') = term src' in expr' (x - y) src''
    _          -> (x, src)

-- term = factor, [term']
term src = let (y, src') = factor src in term' y src'
-- term' = ("*", factor, [term']) | ("/", factor, [term'])
term' x src = case src of
    ("*":src') -> let (y, src'') = factor src' in term' (x * y) src''
    ("/":src') -> let (y, src'') = factor src' in term' (x / y) src''
    _          -> (x, src)

-- factor = ("(", expr, ")") | number
factor (x:src) = case x of
    "(" -> case expr src of
        (y, (")":src')) -> (y, src')
    _   -> (read x, src)

main = do
    print $ eval "2 * 3 + 4"
    print $ eval "2 + 3 * 4"
    print $ eval "( 2 + 3 ) * 4"
    print $ eval "100 / 10 / 2"
```
```text:実行結果
10.0
14.0
20.0
5.0
```

# Maybeモナド

Maybeモナドを使って書き換えます。

## Just

`expr`などをMaybeモナドで返すようにします。`Nothing`は使わないため、戻り値に`Just`を付けて、受け取った側でパターンマッチにより外します。

```hs
import Data.Maybe

eval src = fst $ fromJust $ expr $ words src

-- expr = term, [expr']
expr src = let Just (y, src') = term src in expr' y src'
-- expr' = ("+", term, [expr']) | ("-", term, [expr'])
expr' x src = case src of
    ("+":src') -> let Just (y, src'') = term src' in expr' (x + y) src''
    ("-":src') -> let Just (y, src'') = term src' in expr' (x - y) src''
    _          -> return (x, src)

-- term = factor, [term']
term src = let Just (y, src') = factor src in term' y src'
-- term' = ("*", factor, [term']) | ("/", factor, [term'])
term' x src = case src of
    ("*":src') -> let Just (y, src'') = factor src' in term' (x * y) src''
    ("/":src') -> let Just (y, src'') = factor src' in term' (x / y) src''
    _          -> return (x, src)

-- factor = ("(", expr, ")") | number
factor (x:src) = case x of
    "(" -> case expr src of
        Just (y, (")":src')) -> return (y, src')
    _   -> return (read x, src)

main = do
    print $ eval "2 * 3 + 4"
    print $ eval "2 + 3 * 4"
    print $ eval "( 2 + 3 ) * 4"
    print $ eval "100 / 10 / 2"
```
```text:実行結果
10.0
14.0
20.0
5.0
```

## do

Maybeモナドの戻り値を`do`の中の`<-`で受け取ります。

```hs
import Data.Maybe

eval src = fst $ fromJust $ expr $ words src

-- expr = term, [expr']
expr src = do
    (y, src') <- term src
    expr' y src'
-- expr' = ("+", term, [expr']) | ("-", term, [expr'])
expr' x src = case src of
    ("+":src') -> do
        (y, src'') <- term src'
        expr' (x + y) src''
    ("-":src') -> do
        (y, src'') <- term src'
        expr' (x - y) src''
    _ -> return (x, src)

-- term = factor, [term']
term src = do
    (y, src') <- factor src
    term' y src'
-- term' = ("*", factor, [term']) | ("/", factor, [term'])
term' x src = case src of
    ("*":src') -> do
        (y, src'') <- factor src'
        term' (x * y) src''
    ("/":src') -> do
        (y, src'') <- factor src'
        term' (x / y) src''
    _ -> return (x, src)

-- factor = ("(", expr, ")") | number
factor (x:src) = case x of
    "(" -> do
        (y, (")":src')) <- expr src
        return (y, src')
    _ -> return (read x, src)

main = do
    print $ eval "2 * 3 + 4"
    print $ eval "2 + 3 * 4"
    print $ eval "( 2 + 3 ) * 4"
    print $ eval "100 / 10 / 2"
```
```text:実行結果
10.0
14.0
20.0
5.0
```

## Alternative

`case`でのパターンマッチをやめて`<|>`（Alternative）で書き換えます。

```hs
import Data.Maybe
import Control.Applicative

eval src = fst $ fromJust $ expr $ words src

-- expr = term, [expr']
expr src = term src >>= uncurry expr'
-- expr' = ("+", term, [expr']) | ("-", term, [expr'])
expr' x src =
    do
        ("+":src') <- Just src
        (y, src'') <- term src'
        expr' (x + y) src''
    <|> do
        ("-":src') <- Just src
        (y, src'') <- term src'
        expr' (x - y) src''
    <|> do
        return (x, src)

-- term = factor, [term']
term src = factor src >>= uncurry term'
-- term' = ("*", factor, [term']) | ("/", factor, [term'])
term' x src =
    do
        ("*":src') <- Just src
        (y, src'') <- factor src'
        term' (x * y) src''
    <|> do
        ("/":src') <- Just src
        (y, src'') <- factor src'
        term' (x / y) src''
    <|> do
        return (x, src)

-- factor = ("(", expr, ")") | number
factor (x:src) =
    do
        "(" <- Just x
        (y, (")":src')) <- expr src
        return (y, src')
    <|> do
        return (read x, src)

main = do
    print $ eval "2 * 3 + 4"
    print $ eval "2 + 3 * 4"
    print $ eval "( 2 + 3 ) * 4"
    print $ eval "100 / 10 / 2"
```
```text:実行結果
10.0
14.0
20.0
5.0
```

次のステップでStateTモナド変換子を導入しやすくするため、状態（`src`など）の受け渡しが目立つように最後の引数に固めています。

# モナド変換子

StateTモナド変換子でMaybeモナドと合成します。

## 状態

状態（`src`など）の受け渡しをStateTモナド変換子に押し付けます。いくつかアクションを定義します。冗長に書いていますが、次で整理します。

```hs
import Data.Maybe
import Control.Applicative
import Control.Monad.State

is x = StateT is where
    is (y:ys) | x == y = Just (y, ys)
    is _               = Nothing

pop = StateT pop where
    pop (x:xs) = Just (x, xs)
    pop _      = Nothing

eval src = fromJust $ evalStateT expr $ words src

-- expr = term, [expr']
expr = term >>= expr'
-- expr' = ("+", term, [expr']) | ("-", term, [expr'])
expr' x =
    do
        is "+"
        y <- term
        expr' $ x + y
    <|> do
        is "-"
        y <- term
        expr' $ x - y
    <|> do
        return x

-- term = factor, [term']
term = factor >>= term'
-- term' = ("*", factor, [term']) | ("/", factor, [term'])
term' x =
    do
        is "*"
        y <- factor
        term' $ x * y
    <|> do
        is "/"
        y <- factor
        term' $ x / y
    <|> do
        return x

-- factor = ("(", expr, ")") | number
factor =
    do
        is "("
        x <- expr
        is ")"
        return x
    <|> do
        x <- pop
        return $ read x

main = do
    print $ eval "2 * 3 + 4"
    print $ eval "2 + 3 * 4"
    print $ eval "( 2 + 3 ) * 4"
    print $ eval "100 / 10 / 2"
```
```text:実行結果
10.0
14.0
20.0
5.0
```

## 整理

形式的な見た目を意識して、`>>=`やApplicativeスタイルでコードを整理します。処理の流れは同じです。

```hs
import Data.Maybe
import Control.Monad.State
import Control.Applicative

is x = StateT is where
    is (y:ys) | x == y = Just (y, ys)
    is _               = Nothing

pop = StateT pop where
    pop (x:xs) = Just (x, xs)
    pop _      = Nothing

eval src = fromJust $ evalStateT expr $ words src

-- expr = term, [expr']
expr = term >>= expr'
-- expr' = ("+", term, [expr']) | ("-", term, [expr'])
expr' x = do is "+"; (x +) <$> term >>= expr'
      <|> do is "-"; (x -) <$> term >>= expr'
      <|> return x

-- term = factor, [term']
term = factor >>= term'
-- term' = ("*", factor, [term']) | ("/", factor, [term'])
term' x = do is "*"; (x *) <$> factor >>= term'
      <|> do is "/"; (x /) <$> factor >>= term'
      <|> return x

-- factor = ("(", expr, ")") | number
factor  = do is "("; x <- expr; is ")"; return x
      <|> read <$> pop

main = do
    print $ eval "2 * 3 + 4"
    print $ eval "2 + 3 * 4"
    print $ eval "( 2 + 3 ) * 4"
    print $ eval "100 / 10 / 2"
```
```text:実行結果
10.0
14.0
20.0
5.0
```

別ルートで元記事と同じコードが得られました。
