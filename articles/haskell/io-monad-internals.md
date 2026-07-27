---
coediting: false
comments_count: 2
created_at: '2014-12-09T00:50:58+09:00'
id: 0a90d7ba31355e1c73aa
likes_count: 25
private: false
reactions_count: 0
stocks_count: 19
tags:
- name: Haskell
  versions: []
- name: Clean
  versions: []
title: IOモナドを素手で触ってみた
updated_at: '2015-05-07T12:03:46+09:00'
url: https://qiita.com/7shi/items/0a90d7ba31355e1c73aa
slide: false
---

[Haskellの実験メモ](http://qiita.com/7shi/items/b6cbb7df2dd969c84f49)です。

IOモナドはブラックボックスとして扱っていましたが、Cleanの一意型と比較するため、分解して素手で触ってみました。モナドと一意型は上に被せた皮の違いで、本質的な部分はほぼ同じようです。

この記事は次の続編のようなものです。

* [Clean 一意型 調査メモ](http://qiita.com/7shi/items/ab3b819871d7b0710949) 2014.12.5

この記事をベースに、学習用にまとめた記事があります。

* [Haskell IOモナド 超入門](http://qiita.com/7shi/items/d3d3492ddd90d47160f2) 2014.12.11

# IOモナドを分解

`GHC.Base`を参照すればIOモナドの中身はパターンマッチで取り出せます。

ghciの`:t`で型を確認してみます。

```hs
$ ghci
（略）
Prelude> import GHC.Base
Prelude GHC.Base> let (IO f) = print "a"
Prelude GHC.Base> :t f
f :: State# RealWorld -> (# State# RealWorld, () #)
```

何やら関数が入っていますが、`#`が付いてよく分からない記法です。

これには2種類の`#`が混ざっています。

1. 型に付く`#`
    * `State#`の`#`は名前の一部です。
    * これを指定することで何か特別な機能が付加されるわけではありませんが、どうやら実体がHaskellの外で定義されているものに使うようです。
    * デフォルトでは文法エラーとなるため、使用するにはGHC拡張`MagicHash`を有効にする必要があります。
2. タプルに付く`#`
    * `(#`～`#)`は値がアンボックス化される特殊なタプルです。タプルには式ではなく値が含まれます。
    * デフォルトでは文法エラーとなるため、使用するにはGHC拡張`UnboxedTuples`を有効にする必要があります。

段階的に追加すれば、構造が直感的に分かるかもしれません。

1. なし：`State RealWorld -> (State RealWorld, ())`
2. 型に付ける：`State# RealWorld -> (State# RealWorld, ())`
3. タプルに付ける：`State# RealWorld -> (# State# RealWorld, () #)`

GHC拡張は次の資料を参考にしました。

* [7.3. 構文的拡張](http://www.kotha.net/ghcguide_ja/7.6.2/syntax-extns.html)（[栄光のグラスゴーHaskellコンパイルシステム利用の手引き バージョン7.6.2](http://www.kotha.net/ghcguide_ja/7.6.2/)） 2013.2.11

## unIO

先ほどはパターンマッチでIOモナドの中身を取り出しましたが、専用の関数`unIO`があります。

[GHC/Base.lhs](http://downloads.haskell.org/~ghc/7.8.2/docs/html/libraries/base/src/GHC-Base.html)で`unIO`の定義を確認します。

```hs
unIO :: IO a -> (State# RealWorld -> (# State# RealWorld, a #))
unIO (IO a) = a
```

※ この関数は後で掲載する`bindIO`を見て存在を知りました。

ghciで使ってみます。

```hs
$ ghci
（略）
Prelude> import GHC.Base
Prelude GHC.Base> let f = unIO $ print "a"
Prelude GHC.Base> :t f
f :: State# RealWorld -> (# State# RealWorld, () #)
```

## realWorld# 

IOモナドから関数を取り出したのは良いですが、引数に何を渡せば良いのか分かりません。`State# RealWorld`型はコンストラクタもなく、勝手に作ることができません。

ヒントを得るため[GHC/IO.hs](https://downloads.haskell.org/~ghc/7.8.2/docs/html/libraries/base/src/GHC-IO.html)で`unsafePerformIO`の定義を確認します。

```hs
unsafePerformIO :: IO a -> a
unsafePerformIO m = unsafeDupablePerformIO (noDuplicate >> m)
```

`unsafeDupablePerformIO`を確認します。

```hs
unsafeDupablePerformIO  :: IO a -> a
unsafeDupablePerformIO (IO m) = lazy (case m realWorld# of (# _, r #) -> r)
```

`realWorld#`がお目当てのもののようです。

## MagicHash

早速IOモナドから取り出した`f`に渡してみます。GHC拡張`MagicHash`を有効にしてghciを起動します。

```hs
$ ghci -XMagicHash
（略）
Prelude> import GHC.Base
Prelude GHC.Base> let f = unIO $ print "a"
Prelude GHC.Base> f realWorld#

<interactive>:4:1:
    Couldn't match kind `*' against `#'
    Kind incompatibility when matching types:
      a0 :: *
      (# State# RealWorld, () #) :: #
    In the first argument of `print', namely `it'
    In a stmt of an interactive GHCi command: print it
```

アンボックス化タプルは表示できないようです。

束縛を試みます。

```hs
Prelude GHC.Base> let a = f realWorld#

Top level:
    GHCi can't bind a variable of unlifted type:
      a :: (# State# RealWorld, () #)
```

束縛もできないようです。

## UnboxedTuples

タプルの中身を個別に変数へ束縛してみます。GHC拡張`UnboxedTuples`も有効にしてghciを起動します。

```hs
$ ghci -XMagicHash -XUnboxedTuples
（略）
Prelude GHC.Base> let f = unIO $ print "a"
Prelude GHC.Base> let (# a, b #) = f realWorld#

Top level:
    GHCi can't bind a variable of unlifted type: a :: State# RealWorld
```

`State# RealWorld`は束縛できないようです。

`realWorld#`単体の束縛を試みます。

```hs
Prelude GHC.Base> let world = realWorld#

Top level:
    GHCi can't bind a variable of unlifted type:
      world :: State# RealWorld
```

同じエラーが出ます。

束縛は諦めて捨ててみます。

```hs
Prelude GHC.Base> let (# _, b #) = f realWorld#
"a"
Prelude GHC.Base> b
()
```

無事に副作用が発生して文字が表示されました。`b`も取得できました。

## 乱数

`()`を取得してもあまり面白くないので、乱数で試してみます。

```hs
Prelude GHC.Base> import System.Random
Prelude GHC.Base System.Random> let dice = unIO $ getStdRandom $ randomR (1, 6)
Loading package （略）
Prelude GHC.Base System.Random> :t dice
dice :: State# RealWorld -> (# State# RealWorld, Integer #)
Prelude GHC.Base System.Random> let (# _, b #) = dice realWorld# in b
4
Prelude GHC.Base System.Random> let (# _, b #) = dice realWorld# in b
1
Prelude GHC.Base System.Random> let (# _, b #) = dice realWorld# in b
2
```

問題なく動いています。

## ここまでのまとめ

* IOモナドから`unIO`で取り出した関数に`realWorld#`を渡すと特殊なタプルが得られます。
* タプルの第2要素はモナドに包まれていない生の評価結果です。

# IOモナドの実装を確認

[GHC/Base.lhs](http://downloads.haskell.org/~ghc/7.8.2/docs/html/libraries/base/src/GHC-Base.html)でIOモナドの実装を確認します。

```hs
instance  Monad IO  where
    {-# INLINE return #-}
    {-# INLINE (>>)   #-}
    {-# INLINE (>>=)  #-}
    m >> k    = m >>= \ _ -> k
    return    = returnIO
    (>>=)     = bindIO
    fail s    = failIO s

returnIO :: a -> IO a
returnIO x = IO $ \ s -> (# s, x #)

bindIO :: IO a -> (a -> IO b) -> IO b
bindIO (IO m) k = IO $ \ s -> case m s of (# new_s, a #) -> unIO (k a) new_s
```

* `returnIO`や`bindIO`ではIOモナドにラムダ式を入れています。
* ラムダ式の引数`s`（実体は`realWorld#`と思われる）がどこからか渡って来て、それをバケツリレーしています。

`bindIO`の細かい動きは実例で追ってみないとよく分かりませんが、とりあえずIOの中に関数が入っていて`RealWorld`を渡せば動くらしいことは確認できました。

# mainでworldを触る

ここまでの知識でIOモナドの触り方は分かったので、今度はプログラムで触ってみます。

まずは`main`に渡される`world`を触ってみます。

```hs
import GHC.Base

main = IO $ \world ->
    unIO (print "hello") world
```
```text:実行結果
"hello"
```

ここまでは特にGHC拡張文法を使わずに記述できました。

※ `GHC.Base`はGHC依存の実装ですが。

## printの連続

`print`を連続させてみます。GHC拡張が必要になります。

```hs
{-# LANGUAGE UnboxedTuples #-}

import GHC.Base

main = IO $ \world ->
    let (# world1, _  #) = unIO (print "hello") world
        (# world2, _  #) = unIO (print "world") world1
    in  (# world2, () #)
```
```text:実行結果
"hello"
"world"
```

Cleanの一意型を使ったコードとほとんど同じです。

## 一意性の無視

Haskellでは特に一意性は求められていません。試しに一意性を無視してみました。

```hs
{-# LANGUAGE UnboxedTuples #-}

import GHC.Base

main = IO $ \world ->
    let _ = unIO (print "hello") world
        _ = unIO (print "world") world
    in (# world, () #)
```
```text:実行結果
"world"
"hello"
```

Cleanでは絶対に許されないようなコードですが、とりあえず動きます。

ここで奇妙なことがあります。`_`はどこからも参照されていないのに、評価されて副作用が発生しています。IOモナドから取り出した関数は正格評価されるようです。よく見ると記述された順番と逆に実行されています。

試しに順番を入れ替えてみます。

```hs
{-# LANGUAGE UnboxedTuples #-}

import GHC.Base

main = IO $ \world ->
    let _ = unIO (print "world") world
        _ = unIO (print "hello") world
    in (# world, () #)
```
```text:実行結果
"hello"
"world"
```

実行結果も変わりました。やはり記述されたのと逆に実行されるようです。

## realWorld# 

引数の`world`を無視して`realWorld#`を使ってみます。

```hs
{-# LANGUAGE MagicHash, UnboxedTuples #-}

import GHC.Base

main = IO $ \_ ->
    let _ = unIO (print "hello") realWorld#
        _ = unIO (print "world") realWorld#
    in (# realWorld#, () #)
```
```text:実行結果
"world"
"hello"
```

逆順に実行される点は変わりませんでした。

## 評価順序

一意性を守ったコードでは意図した順に評価されていました。一意性を無視しても動くことは動きますが、評価順序を制御するには一意性を守る必要があるようです。もっともHaskellではその辺はモナドがうまくやってくれますから、本来こんなことは意識する必要のないことですが。

## メモ化

`unIO`で取り出した関数を取り回してみます。

```hs
{-# LANGUAGE MagicHash, UnboxedTuples #-}

import GHC.Base

main = IO $ \_ ->
    let f = unIO $ print "hello"
        _ = f realWorld#
        _ = f realWorld#
        _ = f realWorld#
    in (# realWorld#, () #)
```
```text:実行結果
"hello"
```

`f`に対する評価はメモ化されるらしく、同じことを繰り返しても評価は1度だけです。

## 別の世界

世界の一意性を守ったコードで試してみます。

```hs
{-# LANGUAGE UnboxedTuples #-}

import GHC.Base

main = IO $ \world ->
    let f = unIO $ print "hello"
        (# world1, _  #) = f world
        (# world2, _  #) = f world1
        (# world3, _  #) = f world2
    in  (# world3, () #)
```
```text:実行結果
"hello"
"hello"
"hello"
```

きちんと3回表示されます。このことから関数の戻り値として返される`RealWorld`は、実行前とは別の世界を表しているようです。

# まとめ

* HaskellとCleanではともに世界を取り回しています。
* 世界の一意性を守らないとおかしなことになります。
* Cleanでは世界の取り回しが表に出るため、一意型で保護しています。
* Haskellでは世界の取り回しがモナドによって隠されることで、保護しています。

# 参考

この記事は以下の資料を参考にさせていただきました。

* [IO inside - HaskellWiki](https://www.haskell.org/haskellwiki/IO_inside) 2013.5.22
* [haskell - Why can't I use IO constructor - Stack Overflow](http://stackoverflow.com/questions/19093016/why-cant-i-use-io-constructor) 2013.9.30
