---
coediting: false
comments_count: 0
created_at: '2015-04-24T18:54:10+09:00'
id: 12036631dad1979a273b
likes_count: 8
private: false
reactions_count: 0
stocks_count: 5
tags:
- name: Haskell
  versions: []
title: MaybeとStateを合成
updated_at: '2015-09-03T20:07:06+09:00'
url: https://qiita.com/7shi/items/12036631dad1979a273b
slide: false
---

[Haskellの実験メモ](http://qiita.com/7shi/items/b6cbb7df2dd969c84f49)です。

MaybeとStateをモナド変換子で合成してみました。積む順番を変えた2パターンを試しました。

モナド変換子の知識を前提としています。

* [Haskell モナド変換子 超入門](http://qiita.com/7shi/items/4408b76624067c17e933) 2015.1.4

この記事には続編のようなものがあります。

* [Parsecをモナド変換子で模倣](http://qiita.com/7shi/items/201f379443079736e18e) 2015.4.28

# 発端

『[プログラミングHaskell](http://shop.ohmsha.co.jp/shopdetail/000000000045/)』の『第8章 関数型パーサー』で説明されているParserは、MaybeとStateの両方の特徴を併せ持っています。モナド変換子で合成して同じことができないかと思いました。

```hs
import Control.Monad
import Control.Monad.State
import Control.Monad.Maybe

stateOnMaybe :: StateT Int Maybe ()
stateOnMaybe = do
    a <- get
    guard $ a == 1
    modify (+ 10)

maybeOnState :: MaybeT (State Int) ()
maybeOnState = do
    a <- lift get
    guard $ a == 1
    lift $ modify (+ 10)

main = do
    print $ runStateT stateOnMaybe 1
    print $ runStateT stateOnMaybe 2
    print $ runState (runMaybeT maybeOnState) 1
    print $ runState (runMaybeT maybeOnState) 2
```
```text:実行結果
Just ((),11)
Nothing
(Just (),11)
(Nothing,2)
```

Maybeの性質は失敗による脱出に使っています。

モナドスタックの積み方によって最終的に出て来る型が異なります。

* `stateOnMaybe`: 全体がMaybeに包まれて出て来る
* `maybeOnState`: Stateの値のみMaybeに包まれて出て来る

全体がMaybeに包まれていることや、Stateアクションを持ち上げずにそのまま使えることから、`stateOnMaybe`の方が便利だと思いました。

【追記】失敗時の状態を取得する必要があれば`maybeOnState`を使います。

ここまで試してから、同じ方法でパーサーの動作まで確認した記事があることに気付きました。

* [@nnabeyang](https://twitter.com/nnabeyang): [『プログラミングHaskell』の関数型パーサーをStateTを使って書き直す - Qiita](http://qiita.com/nnabeyang/items/97d67191758dabb50752) 2014.1.10

この書き換えを見て、`item = do x:xs <- get`で`x:xs`へのパターンマッチが失敗してもエラーにならないのを不思議に思いました。

# パターンマッチの失敗

確認すると`do`ではエラーになりませんが、`>>=`で書き替えるとエラーになります。

```hs
main = do
    print $ do (x:xs) <- Just ""; Just (x,xs)    -- OK
    print $ Just "" >>= \(x:xs) -> Just (x, xs)  -- NG
```
```text:実行結果（エラー）
Nothing
Main.hs:5:34-56: Non-exhaustive patterns in lambda
```

この件に関する質問と回答を探しました。

* [haskell - Non-exhaustive Pattern exception, for bind but not for do - Stack Overflow](http://stackoverflow.com/questions/16492299/non-exhaustive-pattern-exception-for-bind-but-not-for-do)

要約すると`<-`から`>>=`への書き替えでは失敗を受け止めるパターンが追加されるとのことです。

* [3.14 Do Expressions - The Haskell 98 Report: Expressions](https://www.haskell.org/onlinereport/exps.html#sect3.14)

先ほどの例に当てはめると次のようになります。

```hs
main = do
    print $ do (x:xs) <- Just ""; Just (x,xs)
    print $ let ok (x:xs) = Just (x, xs)
                ok _      = fail "..."
            in Just "" >>= ok
```
```text:実行結果
Nothing
Nothing
```

# 追加テスト

モナド変換子で合成しても、パターンマッチが失敗すれば脱出として処理されるのを確認します。

```hs
import Control.Monad
import Control.Monad.State
import Control.Monad.Maybe

maybeOnly :: String -> Maybe (Char, String)
maybeOnly s = do
    x:xs <- Just s
    return (x, xs)

stateOnMaybe :: String -> Maybe (Char, String)
stateOnMaybe = runStateT $ do
    x:xs <- get
    put xs
    return x

maybeOnState :: String -> (Maybe Char, String)
maybeOnState = runState $ runMaybeT $ do
    x:xs <- lift get
    lift $ put xs
    return x

main = do
    print $ maybeOnly "abc"
    print $ maybeOnly ""
    print $ stateOnMaybe "abc"
    print $ stateOnMaybe ""
    print $ maybeOnState "abc"
    print $ maybeOnState ""
```
```text:実行結果
Just ('a',"bc")
Nothing
Just ('a',"bc")
Nothing
(Just 'a',"bc")
(Nothing,"")
```

# リンク

当該書籍に関係する記事です。

* [@ruicc](https://twitter.com/ruicc): [Programming Haskell Chapter8 - SlideShare](http://www.slideshare.net/RuiccRail/programming-haskell-chapter8) 2011.11.12
* [Haskellのモナドまでの12ステップ - GPソフト Wiki](http://gpsoft.dip.jp/hiki/?Haskell%E3%81%AE%E3%83%A2%E3%83%8A%E3%83%89%E3%81%BE%E3%81%A7%E3%81%AE12%E3%82%B9%E3%83%86%E3%83%83%E3%83%97) 2014.1.2

StateTとリストによるパーサーを解説した記事です。

* [電卓プログラムの作成 (4) - お気楽 Haskell プログラミング入門](http://www.geocities.jp/m_hiroi/func/haskell32.html) 2013
