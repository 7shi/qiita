---
coediting: false
comments_count: 0
created_at: '2015-07-21T15:13:05+09:00'
id: 8bed38f45272f194631a
likes_count: 8
private: false
reactions_count: 0
stocks_count: 8
tags:
- name: Haskell
  versions: []
title: Stateモナドによるポーランド記法の処理
updated_at: '2015-08-03T10:46:34+09:00'
url: https://qiita.com/7shi/items/8bed38f45272f194631a
slide: false
---

ポーランド記法の処理を例に、状態の取り扱い方を示します。初めにStateモナドを使わないで書いてから、Stateモナドを使って書き換えます。コードの変化を比較するのが狙いです。

この記事は[Haskell 超入門](http://qiita.com/7shi/items/145f1234f8ec2af923ef)シリーズの番外編です。特に以下の記事と関連しています。

* [Haskell 状態系モナド 超入門](http://qiita.com/7shi/items/2e9bff5d88302de1a9e9)

この記事には姉妹編があります。

* [Stateモナドによる逆ポーランド記法の処理](http://qiita.com/7shi/items/0494704d00396687458f)
* [Stateモナドによる中置記法の処理](http://qiita.com/7shi/items/ee5afe4f088f0a1fc8c2)

# [ポーランド記法](https://ja.wikipedia.org/wiki/%E3%83%9D%E3%83%BC%E3%83%A9%E3%83%B3%E3%83%89%E8%A8%98%E6%B3%95)

演算子を前置する記法です。演算子を関数化して括弧を取り払ったものだと見立てられます。

[中置記法](https://ja.wikipedia.org/wiki/%E4%B8%AD%E7%BD%AE%E8%A8%98%E6%B3%95)と比較します。

中置記法|ポーランド記法|演算子の関数化
--------|--------------|--------------
`1+2`   |`+ 1 2`       |`(+) 1 2`
`2+3*4` |`+ 2 * 3 4`   |`(+) 2 ((*) 3 4)`
`2*3+4` |`+ * 2 3 4`   |`(+) ((*) 2 3) 4`

ポーランド記法では括弧を使わなくても優先順位が表現できます。

# 実装

ポーランド記法を文字列で渡して計算する処理を実装します。

## 分割

文字列をスペースで分割します。簡単のため、オペランドと演算子はスペースで区切られていることを前提とします。

```hs
eval src = words src

main = do
    print $ eval "+ 1 2"
```
```text:実行結果
["+","1","2"]
```

## 計算

演算子が来れば後ろの2つを見て計算します。

```hs
eval src = pn $ words src

pn ("+":x:y:_) = read x + read y
pn ("*":x:y:_) = read x * read y

main = do
    print $ eval "+ 1 2"
    print $ eval "* 1 2"
```
```text:実行結果
3
2
```

## 再帰

複数の演算子を組み合わせた計算に対応するため、後ろのオペランドを再帰で処理します。単体の数字を評価するパターンを追加します。

```hs
eval src = pn $ words src

pn ("+":x:ys) = read x + pn ys  -- 後ろのオペランドで再帰
pn ("*":x:ys) = read x * pn ys  -- 後ろのオペランドで再帰
pn (    x:_ ) = read x          -- 追加

main = do
    print $ eval "+ 1 2"
    print $ eval "* 1 2"
    print $ eval "1"
    print $ eval "+ 2 * 3 4"
```
```text:実行結果
3
2
1
14
```

## 状態

後ろのオペランドはやりっ放しにできるので簡単ですが、前のオペランドだとどこまで処理したかを知る必要があります。未評価のまま残っているリストを返すように修正します。

```hs
eval src = fst $ pn $ words src

pn ("+":src1) =
    let (x, src2) = pn src1
        (y, src3) = pn src2
    in (x + y, src3)
pn ("*":src1) =
    let (x, src2) = pn src1
        (y, src3) = pn src2
    in (x * y, src3)
pn (x:src) = (read x, src)

main = do
    print $ eval "+ 1 2"
    print $ eval "* 1 2"
    print $ eval "1"
    print $ eval "+ 2 * 3 4"
    print $ eval "+ * 2 3 4"
```
```text:実行結果
3
2
1
14
10
```

評価するごとにリストが消費され、残りが後続の処理に渡されます。処理対象のリストを**状態**と見なせば、状態が `src1 -> src2 -> src3` のように変化していると解釈できます。

![uniqness.png](https://qiita-image-store.s3.amazonaws.com/0/32057/5393a448-5368-7ff5-85f8-1998c527a874.png)

参考までに、このようなパターンはHaskellでは使われない一意型で顕著に表れます。

* [Clean 一意型 調査メモ](http://qiita.com/7shi/items/ab3b819871d7b0710949) 2014.12.05

## 共通化

`+` と `*` で同じ処理が重複しているため共通化します。

```hs
eval src = fst $ pn $ words src

op src1 f =                  -- 演算子処理の共通化
    let (x, src2) = pn src1
        (y, src3) = pn src2
    in (f x y, src3)

pn ("+":src) = op src (+)
pn ("*":src) = op src (*)
pn (  x:src) = (read x, src)

main = do
    print $ eval "+ 1 2"
    print $ eval "* 1 2"
    print $ eval "1"
    print $ eval "+ 2 * 3 4"
    print $ eval "+ * 2 3 4"
```
```text:実行結果
3
2
1
14
10
```

# Stateモナド

Stateモナドは状態を受け取って、値と更新された状態を返します。

* 状態 → (値, 状態)

処理対象のリストを状態に見立て、Stateモナドを使って書き換えます。

```hs
import Control.Monad.State

eval src = evalState pn $ words src

op f = do
    x <- pn
    y <- pn
    return $ f x y

pn = do
    (x:xs) <- get
    put xs
    case x of
        "+" -> op (+)
        "*" -> op (*)
        _   -> return $ read x

main = do
    print $ eval "+ 1 2"
    print $ eval "* 1 2"
    print $ eval "1"
    print $ eval "+ 2 * 3 4"
    print $ eval "+ * 2 3 4"
```
```text:実行結果
3
2
1
14
10
```

状態（`src`など）の受け渡しが明示的には記述されなくなります。裏で状態が受け渡されているため、本質的には書き換え前のコードと同じです。
