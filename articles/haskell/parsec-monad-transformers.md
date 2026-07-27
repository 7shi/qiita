---
coediting: false
comments_count: 0
created_at: '2015-04-28T18:36:35+09:00'
id: 201f379443079736e18e
likes_count: 5
private: false
reactions_count: 0
stocks_count: 5
tags:
- name: Haskell
  versions: []
title: Parsecをモナド変換子で模倣
updated_at: '2015-09-03T20:06:36+09:00'
url: https://qiita.com/7shi/items/201f379443079736e18e
slide: false
---

[Haskellの実験メモ](http://qiita.com/7shi/items/b6cbb7df2dd969c84f49)です。

Parsecは挙動から動作原理が見えにくいと感じて敬遠していましたが、どうにか折り合いが付けられないかを試みました。

モナド変換子の知識を前提としています。

* [Haskell モナド変換子 超入門](http://qiita.com/7shi/items/4408b76624067c17e933) 2015.1.4

この記事は次の続編のようなものです。

* [MaybeとStateを合成](http://qiita.com/7shi/items/12036631dad1979a273b) 2015.4.24

この記事をベースに、学習用にまとめた記事があります。

* [Haskell 構文解析 超入門](http://qiita.com/7shi/items/b8c741e78a96ea2c10fe) 2015.7.31

# Parsecの初歩

最初の1文字が指定した文字種ならそれを表示して、そうでないならエラーになる例です。

```hs
import Text.Parsec

main = do
    print $ runParser anyChar () "test1" "abc"
    print $ runParser letter  () "test2" "abc"
    print $ runParser digit   () "test3" "abc"
    print $ runParser digit   () "test4" ""
```
```text:実行結果
Right 'a'
Right 'a'
Left "test3" (line 1, column 1):
unexpected "a"
expecting digit
Left "test4" (line 1, column 1):
unexpected end of input
expecting digit
```

[runParser](https://hackage.haskell.org/package/parsec-3.1.9/docs/Text-Parsec.html#v:runParser)はParsecのアクションを実行する関数です。Stateモナドでの`runState`に相当します。

* 引数: アクション ユーザー状態 ソース名 ソース
    * 第2引数（ユーザー状態）は使わないため`()`
    * 第3引数（ソース名）はデバッグ用のタグとして使用
* 戻り値（Eitherモナド）
    * `Right`: 正常終了
    * `Left`: エラー（文字が指定と異なる）

## parse

ユーザー状態が省略できる関数です。取っ掛かりとしては`runParser`よりも`parse`が紹介されることが多いようです。

```hs
import Text.Parsec

main = do
    print $ parse anyChar "test1" "abc"
    print $ parse letter  "test2" "abc"
    print $ parse digit   "test3" "abc"
    print $ parse digit   "test4" ""
```
```text:実行結果
Right 'a'
Right 'a'
Left "test3" (line 1, column 1):
unexpected "a"
expecting digit
Left "test4" (line 1, column 1):
unexpected end of input
expecting digit
```

## parseTest

`print`やソース名を省略できる関数です。

```hs
import Text.Parsec

main = do
    parseTest anyChar "abc"
    parseTest letter  "abc"
    parseTest digit   "abc"
    parseTest digit   ""
```
```text:実行結果
'a'
'a'
parse error at (line 1, column 1):
unexpected "a"
expecting digit
parse error at (line 1, column 1):
unexpected end of input
expecting digit
```

以後、主に`parseTest`を使用します。

## アクションの合成

IOアクションなどと同様に`>>`で合成できます。

```hs
import Text.Parsec

main = do
    parseTest (letter >> digit) "abc"
    parseTest (letter >> digit) "a12"
```
```text:実行結果
parse error at (line 1, column 2):
unexpected "b"
expecting digit
'1'
```

後の`digit`で指定した文字しか取得できていません。

## 文字を拾う

前の文字も取得するには結果を束縛して`return`で返します。

```hs
import Text.Parsec

letterDigit = do
    a <- letter
    b <- digit
    return [a, b]

main = do
    parseTest letterDigit "abc"
    parseTest letterDigit "a12"
```
```text:実行結果
parse error at (line 1, column 2):
unexpected "b"
expecting digit
"a1"
```

今回はParsec入門が目的ではないため、使用方法の確認はこの辺で止めます。

# 再実装

Parsecは中の動きが想像しにくいと感じて敬遠していましたが、いつまでも避けては通れません。しかしソースを軽く眺めても複雑で、先に原理を理解しないと読み解くのは困難だと感じました。

そこで同じような原理で動く簡略化したパーサーを再実装して、まずは動きが推測できることを目指します。

動作原理については『[プログラミングHaskell](http://shop.ohmsha.co.jp/shopdetail/000000000045/)』の『第8章 関数型パーサー』を参考にしました。今回はモナドやbindの実装を避けるため同書には準拠せず、モナド変換子を使ってParsecと同じ名前の関数を実装します。

## 取っ掛かり

最初の1文字だけを確認します。簡単のためエラーの詳細は省略します。

```hs
import Control.Monad
import Data.Char

evalParse f (c:_) = f c
evalParse _ _     = Nothing

parseTest f s = case evalParse f s of
    Just c  -> print c
    Nothing -> putStrLn "ERROR"

anyChar c = Just c
letter  c = guard (isLetter c) >> Just c
digit   c = guard (isDigit  c) >> Just c

main = do
    parseTest anyChar "abc"
    parseTest letter  "abc"
    parseTest digit   "abc"
    parseTest digit   ""
```
```text:実行結果
'a'
'a'
ERROR
ERROR
```

## 合成

`>>`でアクションを合成すると、2文字目を取得する仕組みがないため誤動作します。

```hs
import Control.Monad
import Data.Char

evalParse f (c:_) = f c
evalParse _ _     = Nothing

parseTest f s = case evalParse f s of
    Just c  -> print c
    Nothing -> putStrLn "ERROR"

anyChar c = Just c
letter  c = guard (isLetter c) >> Just c
digit   c = guard (isDigit  c) >> Just c

main = do
    parseTest (letter >> digit) "abc"
    parseTest (letter >> digit) "a12"
```
```text:実行結果
ERROR
ERROR
```

## StateT

合成したアクション間では「何文字目を見ているか」という状態が受け渡されます。状態をStateモナドで表現するため、既に使っているMaybeモナドをStateTモナド変換子で包みます。

```hs
import Control.Monad
import Control.Monad.State
import Data.Char

parseTest f s = case evalStateT f s of
    Just c  -> print c
    Nothing -> putStrLn "ERROR"

anyChar :: StateT String Maybe Char
anyChar = do
    (x:xs) <- get
    put xs
    return x

letter = do
    c <- anyChar
    guard $ isLetter c
    return c

digit = do
    c <- anyChar
    guard $ isDigit c
    return c

main = do
    parseTest (letter >> digit) "abc"
    parseTest (letter >> digit) "a12"
```
```text:実行結果
ERROR
'1'
```

うまく動いています。型注釈はややこしいですが、コードはシンプルです。

## 文字を拾う

前の文字が取得できるか確認します。

```hs
import Control.Monad
import Control.Monad.State
import Data.Char

parseTest f s = case evalStateT f s of
    Just c  -> print c
    Nothing -> putStrLn "ERROR"

anyChar :: StateT String Maybe Char
anyChar = do
    (x:xs) <- get
    put xs
    return x

letter = do
    c <- anyChar
    guard $ isLetter c
    return c

digit = do
    c <- anyChar
    guard $ isDigit c
    return c

letterDigit = do
    a <- letter
    b <- digit
    return [a, b]

main = do
    parseTest letterDigit "abc"
    parseTest letterDigit "a12"
```
```text:実行結果
ERROR
"a1"
```

成功しています。

# まとめ

再実装を通して、Parsecの内部はStateモナドとMaybeモナドの両方の性質を併せ持っていることが見えて来ました。

# 参考

Parsecの初歩について参考にした記事です。

* [@utotch](https://twitter.com/utotch): [Utotch Blog: Haskell で parser を書くには (初心者編)](http://utotch.blogspot.jp/2011/12/haskell-parser.html) 2011.12.18
* [Parsec 再入門 Parser と ParserCombinator : tnomuraのブログ](http://tnomura9.exblog.jp/17555312/) 2013.1.3
* [@sirocco_jp](https://twitter.com/sirocco_jp): [Parsecにちょっと触ってみる。 - sirocco の書いてもすぐに忘れるメモ](http://d.hatena.ne.jp/sirocco/20101024/1287870847) 2010.10.24
* [@esehara](https://twitter.com/esehara): [Parsecというパーサーライブラリで電卓を作る簡単な方法 - 蟲！虫！蟲！ - #!/usr/bin/bugrammer](http://bugrammer.g.hatena.ne.jp/nisemono_san/20111117/1321555610) 2011.11.17

再実装について参考にした記事です。

* [@nnabeyang](https://twitter.com/nnabeyang): [『プログラミングHaskell』の関数型パーサーをStateTを使って書き直す - Qiita](http://qiita.com/nnabeyang/items/97d67191758dabb50752) 2014.1.10
