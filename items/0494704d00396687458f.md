---
coediting: false
comments_count: 0
created_at: '2015-07-21T18:06:47+09:00'
id: 0494704d00396687458f
likes_count: 4
private: false
reactions_count: 0
stocks_count: 2
tags:
- name: Haskell
  versions: []
title: Stateモナドによる逆ポーランド記法の処理
updated_at: '2015-08-03T10:53:08+09:00'
url: https://qiita.com/7shi/items/0494704d00396687458f
slide: false
---

逆ポーランド記法の処理を例に、状態の取り扱い方を示します。初めにStateモナドを使わないで書いてから、Stateモナドを使って書き換えます。コードの変化を比較することで、モナドのDSL的な側面を示すのが狙いです。

この記事は[Haskell 超入門](http://qiita.com/7shi/items/145f1234f8ec2af923ef)シリーズの番外編です。特に以下の記事と関連しています。

* [Haskell 状態系モナド 超入門](http://qiita.com/7shi/items/2e9bff5d88302de1a9e9)

この記事には姉妹編があります。

* [Stateモナドによるポーランド記法の処理](http://qiita.com/7shi/items/8bed38f45272f194631a)
* [Stateモナドによる中置記法の処理](http://qiita.com/7shi/items/ee5afe4f088f0a1fc8c2)

# [逆ポーランド記法](https://ja.wikipedia.org/wiki/%E9%80%86%E3%83%9D%E3%83%BC%E3%83%A9%E3%83%B3%E3%83%89%E8%A8%98%E6%B3%95)

演算子を後置する記法です。日本語の語順に似ていると言われます。

[中置記法](https://ja.wikipedia.org/wiki/%E4%B8%AD%E7%BD%AE%E8%A8%98%E6%B3%95)と比較します。

中置記法|逆ポーランド記法|日本語
--------|----------------|------
`1+2`   |`1 2 +`         |1と2を足す
`2+3*4` |`2 3 4 * +`     |2に3と4を掛けたものを足す
`2*3+4` |`2 3 * 4 +`     |2と3を掛けたものに4を足す

逆ポーランド記法では括弧を使わなくても優先順位が表現できます。

# 実装

逆ポーランド記法を文字列で渡して計算する処理を実装します。

## 分割

文字列をスペースで分割します。簡単のため、オペランドと演算子はスペースで区切られていることを前提とします。

```hs
eval src = words src

main = do
    print $ eval "1 2 +"
```
```text:実行結果
["1","2","+"]
```

## 数字

逆ポーランド記法はスタックで処理します。

数字が来ればスタックに積みます。ソースが空になればスタックから値を取り出して返します。

```hs
eval src = rpn (words src) []

rpn :: [String] -> [Int] -> Int
rpn (x:src) stack = rpn src $ read x : stack  -- 数字を積む
rpn []      (x:_) = x                         -- 値を返す

main = do
    print $ eval "1"
```
```text:実行結果
1
```

## 計算

演算子が来ればスタックから値を2つ取り出して、計算結果をスタックに積みます。

* `y:x:stack` → `(x + y):stack`

```hs
eval src = rpn (words src) []

rpn :: [String] -> [Int] -> Int
rpn ("+":src) (y:x:stack) = rpn src $ x + y  : stack -- 追加
rpn ("*":src) (y:x:stack) = rpn src $ x * y  : stack -- 追加
rpn (  x:src)      stack  = rpn src $ read x : stack
rpn []        (  x:_    ) = x

main = do
    print $ eval "1"
    print $ eval "1 2 +"
    print $ eval "1 2 *"
    print $ eval "2 3 4 * +"
    print $ eval "2 3 * 4 +"
```
```text:実行結果
1
3
2
14
10
```

ネストした計算にも対応できます。状態の受け渡しを細かく管理しなくて済むため、ポーランド記法よりも楽です。

# Stateモナド

スタックを状態として見なせばStateモナドで表現できます。

## アクション

Stateモナドで表現されたスタックを直感的に使用するため、スタックを操作するStateアクションを実装します。

今までのコードとは切り離した単独実装として示します。

```hs
import Control.Monad.State

push x = modify (x:)
pop = do
    (x:xs) <- get
    put xs
    return x

test = do
    push 3
    push 5
    push 4
    pop

main = do
    print $ runState test []
```
```text:実行結果
(4,[5,3])
```

## 修正

逆ポーランド記法の処理を、Stateモナドによるスタック操作を使って書き換えます。

```hs
import Control.Monad.State

push x = modify (x:)
pop = do
    (x:xs) <- get
    put xs
    return x

eval src = evalState (rpn (words src)) []

rpn ("+":src) = do
    y <- pop
    x <- pop
    push $ x + y
    rpn src

rpn ("*":src) = do
    y <- pop
    x <- pop
    push $ x * y
    rpn src

rpn (x:src) = do
    push $ read x
    rpn src

rpn [] = pop

main = do
    print $ eval "1"
    print $ eval "1 2 +"
    print $ eval "1 2 *"
    print $ eval "2 3 4 * +"
    print $ eval "2 3 * 4 +"
```
```text:実行結果
1
3
2
14
10
```

状態（スタック）の受け渡しが明示的には記述されなくなります。裏で状態が受け渡されているため、本質的には書き換え前のコードと同じです。

## 共通化

`+` と `*` で同じ処理が重複しているため共通化します。

```hs
import Control.Monad.State

push x = modify (x:)
pop = do
    (x:xs) <- get
    put xs
    return x

eval src = evalState (rpn (words src)) []

op f = do
    y <- pop
    x <- pop
    push $ f x y

rpn ("+":src) = op (+)        >> rpn src
rpn ("*":src) = op (*)        >> rpn src
rpn (  x:src) = push (read x) >> rpn src
rpn []        = pop

main = do
    print $ eval "1"
    print $ eval "1 2 +"
    print $ eval "1 2 *"
    print $ eval "2 3 4 * +"
    print $ eval "2 3 * 4 +"
```
```text:実行結果
1
3
2
14
10
```

`rpn`はStateモナド使用前よりもかなりシンプルです。`op`と合わせて見れば、スタック操作を抽象化して手続的に書くことによる、モナドのDSL的な側面が見えて来るのではないでしょうか。
