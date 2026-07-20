---
coediting: false
comments_count: 0
created_at: '2015-01-05T21:14:12+09:00'
id: 60f787149673b4d4775f
likes_count: 2
private: false
reactions_count: 0
stocks_count: 1
tags:
- name: Haskell
  versions: []
title: アンボックス化タプルの挙動を確認（微妙）
updated_at: '2015-05-07T12:04:28+09:00'
url: https://qiita.com/7shi/items/60f787149673b4d4775f
slide: false
---

[Haskellの実験メモ](http://qiita.com/7shi/items/b6cbb7df2dd969c84f49)です。

普通のタプルとアンボックス化タプルの違いを、簡単なパターンマッチで検出できるかどうか試しました。1要素のタプルはないので1要素のデータ型で代用しました。結論から言うと**この方法では違いを検出できません**。代用がこれで良いのか微妙ですが。

# ネタ元

`data`と`newtype`の違いというのはよく話題になって、`undefined`に対するパターンマッチで検出するのが定石です。

以下に正格性注釈も交えた比較が載っています。

* [Newtype - HaskellWiki](https://www.haskell.org/haskellwiki/Newtype) 2014.11.22

これを元に`undefined`でアンボックス化タプル特有の挙動が見られるかどうかを確認しました。

# テストコード

ghciで確認すると再現が面倒なので、HUnitでテストしました。

`u`は`undefined`が返って来ることを示しています。

```hs
{-# LANGUAGE UnboxedTuples #-}

import Test.HUnit
import System.IO
import Control.Exception

undef :: Int -> ErrorCall -> IO Int
undef x _ = return x

t :: String -> Int -> Int -> Test
t s x t = s ~: (~? s) $ do
    v <- catch (evaluate t) $ undef u
    return $ x == v

u = 0

data Foo1 = Foo1 Int
data Foo2 = Foo2 !Int
newtype Foo3 = Foo3 Int
data Foo4 = Foo4 (# Int #)

tests = TestList
    [ t "a1" 1 $ case Foo1 undefined of Foo1 _ -> 1
    , t "a2" u $ case Foo2 undefined of Foo2 _ -> 1
    , t "a3" 1 $ case Foo3 undefined of Foo3 _ -> 1
    , t "a4" u $ case Foo4 undefined of Foo4 _ -> 1
    , t "a5" u $ case Foo4 undefined of Foo4 (# _ #) -> 1

    , t "b1" u $ case undefined of Foo1 _ -> 1
    , t "b2" u $ case undefined of Foo2 _ -> 1
    , t "b3" 1 $ case undefined of Foo3 _ -> 1
    , t "b4" u $ case undefined of Foo4 _ -> 1
    , t "b5" u $ case undefined of Foo4 (# _ #) -> 1
    , t "b6" u $ case undefined of      (# _ #) -> 1
    , t "b7" 1 $ case undefined of         _    -> 1

    , t "c1" 1 $ case    undefined    of    _    -> 1
    , t "c2" 1 $ case (  undefined  ) of (  _  ) -> 1
    , t "c3" 1 $ case (# undefined #) of (# _ #) -> 1
    , t "c4" 1 $ case (  undefined, undefined  ) of (  _, _  ) -> 1
    , t "c5" 1 $ case (# undefined, undefined #) of (# _, _ #) -> 1

    , t "d1" 1 $ case undefined of    _    -> 1
    , t "d2" 1 $ case undefined of (  _  ) -> 1
    , t "d3" u $ case undefined of (# _ #) -> 1
    , t "d4" u $ case undefined of (  _, _  ) -> 1
    , t "d5" u $ case undefined of (# _, _ #) -> 1
    ]

main = do
    runTestText (putTextToHandle stderr False) tests
```
```text:実行結果
Cases: 22  Tried: 22  Errors: 0  Failures: 0
```

* a2, a4, b2, b4: データ型で包んだ場合、正格性注釈を加えたものとアンボックス化タプルの挙動は同じです。
* b5, b6: データ型で包んだものと単独のアンボックス化タプルでは、挙動に違いは見られません。
* c1, c2, d1, d2: `_`と`(_)`は同じものです。単独の値を1要素のタプルだと見なすのはおかしいので、以下では1要素のデータ型`Foo1`で代用します。
* a1, c3, b1, d3: 1要素のデータ型と1要素のアンボックス化タプルの挙動に違いは見られません。
* c4, c5, d4, d5: 2要素の通常のタプルとアンボックス化タプルの挙動に違いは見られません。

# 参考

例外を`catch`するのに`evaluate`で正格評価しないとすり抜けることがあるのを知らずにハマりました。次の記事に明記されています。

* [@shelarcy](https://twitter.com/shelarcy): [本物のプログラマはHaskellを使う - 第25回　Haskell流の例外処理を学ぶ：ITpro](http://itpro.nikkeibp.co.jp/article/COLUMN/20081104/318426/) 2008.11.5

次の記事では、`data`と`newtype`の違いをタプルを交えて図解しています。

* [types - Difference between `data` and `newtype` in Haskell - Stack Overflow](http://stackoverflow.com/questions/5889696/difference-between-data-and-newtype-in-haskell) 2011.5.4
