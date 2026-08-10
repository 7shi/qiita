---
coediting: false
comments_count: 3
created_at: '2014-12-11T16:10:57+09:00'
id: d3d3492ddd90d47160f2
likes_count: 74
private: false
reactions_count: 0
stocks_count: 60
tags:
- name: Haskell
  versions: []
title: Haskell IOモナド 超入門
updated_at: '2026-08-11T05:23:49+09:00'
url: https://qiita.com/7shi/items/d3d3492ddd90d47160f2
slide: false
---

Haskellではモナドと呼ばれる部品を組み合わせてプログラムを作ります。今までアクションとして取り扱っていたのはIOモナドというモナドの一種です。IOモナドの仕組みを調べることで、IOモナドを組み合わせることの具体的なイメージを説明します。モナドについての一般論へ進む前の準備を目的としているため、IO以外のモナドや圏論には言及しません。

シリーズの記事です。

1. [Haskell 超入門](http://qiita.com/7shi/items/145f1234f8ec2af923ef)
1. [Haskell 代数的データ型 超入門](http://qiita.com/7shi/items/1ce76bde464b4a55c143)
1. [Haskell アクション 超入門](http://qiita.com/7shi/items/85afd7bbd5d6c4115ad6)
1. [Haskell ラムダ 超入門](http://qiita.com/7shi/items/1345bf32003faff435cb)
1. [Haskell アクションとラムダ 超入門](http://qiita.com/7shi/items/4a8a2807bb5186576c61)
1. **Haskell IOモナド 超入門** ← この記事
1. [Haskell リストモナド 超入門](http://qiita.com/7shi/items/deb19c4cba933590ffbf)
1. [Haskell Maybeモナド 超入門](http://qiita.com/7shi/items/c7d7eec066af0fe0688d)
1. [Haskell 状態系モナド 超入門](http://qiita.com/7shi/items/2e9bff5d88302de1a9e9)
1. [Haskell モナド変換子 超入門](http://qiita.com/7shi/items/4408b76624067c17e933)
1. [Haskell 例外処理 超入門](http://qiita.com/7shi/items/73e534c47bbebc71b37e)
1. [Haskell 構文解析 超入門](http://qiita.com/7shi/items/b8c741e78a96ea2c10fe)
1. [Haskell 継続モナド 超入門](https://zenn.dev/7shi/articles/20260803-haskell-continuation-monad)
1. [Haskell 型クラス 超入門](https://zenn.dev/7shi/articles/20260805-haskell-type-classes)
1. [Haskell モナドとゆかいな仲間たち](https://zenn.dev/7shi/articles/20260807-haskell-monads-and-friends)
1. [Haskell Freeモナド 超入門](https://zenn.dev/7shi/articles/20260808-haskell-free-monad)
1. [Haskell Operationalモナド 超入門](https://zenn.dev/7shi/articles/20260809-haskell-operational-monad)
1. [Haskell Effモナド 超入門](https://zenn.dev/7shi/articles/20260811-haskell-eff-monad)
1. 【予定】Haskell アロー 超入門

練習の解答例は別記事に掲載します。

* [【解答例】Haskell IOモナド 超入門](http://qiita.com/7shi/items/dfc114f133580ee85686)

# IOモナド

今まで出て来たアクションはIO型です。

```hs
dice :: IO Int
dice = getStdRandom $ randomR (1, 6)
```

このIO型はIOモナドと呼ばれます。今までアクションと呼んでいたものの実体がIOモナドです。

※ 正確にはIOモナドによるアクションはIOアクションと呼びます。

モナドへの取っ掛かりとして、IOモナドの内部構造を見て行きます。

※ IOモナドの実装は処理系依存ですが、今回はGHCを前提とします。

## 値の取り出し

IOモナドは値を取り出すことができます。挙動にいくつか種類がありますが、復習がてら振り返ります。

![m_value.png](https://qiita-image-store.s3.amazonaws.com/0/32057/42e54acd-7595-ba82-1dfe-efc76ef7dffc.png)

単純に値が入っている例です。

```hs
main = do
    let a = return 1
    print =<< a
    print =<< a
```
```text:実行結果
1
1
```

このようなケースではモナドの中に静的に値が入っているようにイメージできます。

しかし、取り出すたびに値が変わるものもあります。

```hs
import System.Random

dice :: IO Int
dice = getStdRandom $ randomR (1, 6)

main = do
    print =<< dice
    print =<< dice
```
```text:実行結果（毎回異なる）
5
3
```

このようなケースでは、取り出す際に何か処理が行われているため、単純に値が入っているわけではないということが分かります。

値を取り出す以外の影響もあります。

```hs
main = do
    let hello = putStr "hello"
    print =<< hello
    print =<< hello
```
```text:実行結果
hello()
hello()
```

取り出されるのは`()`という意味のない値ですが、取り出す際に文字が表示されるという副作用が発生しています。

## 内部構造

IOモナドから値を取り出す際の挙動は、IOモナドの中に参照透過性が保証されない特殊な関数が隠されていることで実現されています。

![mfunc.png](https://qiita-image-store.s3.amazonaws.com/0/32057/0db1a648-69db-89cb-0f9f-4bd58041ee79.png)

※ 通常はIOモナド内の関数は隠されています。

## 関数の取り出し

IOモナドから隠された関数を取り出してみます。

※ ここで行うのは通常のプログラミングでは一切行わない特殊な処理です。IOモナドの仕組みを説明することが目的で、実用に供することは意図していません。

`GHC.Base.unIO`関数によりIOモナドの中に隠された関数を取り出せます。

![unIO.png](https://qiita-image-store.s3.amazonaws.com/0/32057/4fab8b51-6ae7-f752-9290-75be63203da0.png)

```hs
import GHC.Base

hello1 = unIO $ return 1
```

ここで注意しないといけないのは、取り出したのは`1`という値を返す**関数**で、`1`という**値**ではないということです。

※ 取り出した関数は非常に特殊な仕様のため、簡単には呼び出せません。詳細は後述します。

## 関数の格納

取り出した関数を`IO`の中に入れれば、IOモナドを再構築できます。

![IO.png](https://qiita-image-store.s3.amazonaws.com/0/32057/3d992696-f563-60f2-c2e3-555ae54e7647.png)

```hs
hello2 = IO hello1
```

※ `IO`はコンストラクタ（構築子）です。今回の範囲では型を構築する特殊な関数だと捉えれば十分です。👉[代数的データ型](https://qiita.com/7shi/items/1ce76bde464b4a55c143#列挙型)

## 関数と値

関数と値で出し入れの方法をまとめました。

![IO_funcs.png](https://qiita-image-store.s3.amazonaws.com/0/32057/58a98a91-3819-1d38-fd98-da6d52d110d2.png)

※ 図中の矢印の向きは`<-`に合わせました。

種類|取り出し|格納
----|--------|----
関数|`unIO`  |`IO`
値  |`<-`    |`return`

ここで注目するのは`return`です。コンストラクタ`IO`を直接使うと、通常は存在を意識する必要のない内部関数が表に出てしまいます。`return`により指定された値を返す関数を自動的に作ることで、IOモナドの内部構造を意識させずに利用できるようにしています。オブジェクト指向での[ファクトリメソッド](http://ja.wikipedia.org/wiki/Factory_Method_%E3%83%91%E3%82%BF%E3%83%BC%E3%83%B3)に近い考え方です。

関数や値の出し入れを行う例です。

```hs
import GHC.Base

main = do
    let m  = return 1
    print =<< m

    let f  = unIO m
    let m1 = IO f
    print =<< m1

    v <- m
    let m2 = return v
    print =<< m2
```
```text:実行結果
1
1
1
```

この例では既存のモナドから関数や値を抜き出して、再度入れることでIOモナドを再構築しています。ただ出し入れしただけなので、元と同じIOモナドが出来るのは当たり前です。

※ 当たり前で済ませていますが、値に関しては出し入れで変化しないことがモナド則というルールによって保証されています。今回の範囲を超えるため詳細は省略しますが、興味があれば次の記事を参照してください。

* [@7shi](https://twitter.com/7shi): [モナド則がちょっと分かった？](http://qiita.com/7shi/items/547b6137d7a3c482fe68) 2015.3.9（改訂）

## 自作関数

関数を出し入れするだけではブラックボックスのままです。関数の仕様を調べるため、自作関数でIOモナドを構築してみます。

IOモナドの中にある関数は通常は触るようなものではなく、仕様も特殊です。戻り値はアンボックス化タプルと呼ばれる特殊なタプルです。まずそれについて説明します。

## アンボックス化タプル

内部的な処理が違うタプルです。違いは表面上分かりません。

通常のタプルは計算結果ではなく式を保持しますが、アンボックス化タプルでは計算結果が含まれます。そのためタプルを大量に使うような用途ではメモリ効率が向上するようです。それによって計算結果が変わるわけではないため、違いが簡単に分かるような例は示せません。

* 通常のタプルは`(`～`)`で囲むのに対して、アンボックス化タプルは`(#`～`#)`で囲みます。
* アンボックス化タプルを扱うには`UnboxedTuples`という言語拡張が必要です。
    * 言語拡張はソースの先頭に`{-# LANGUAGE`～`#-}`と記述します。
* アンボックス化タプルは`print`が受け付けないため、確認するには中身を個別に取り出す必要があります。

例を示します。

```hs
{-# LANGUAGE UnboxedTuples #-}

addsub x y = (# x + y, x - y #)

main = do
    let (# a, b #) = addsub 1 2
    print (a, b)
```
```text:実行結果
(3,-1)
```

取扱い方法自体は通常のタプルと大差ないため、これ以上は特に説明することはありません。興味があれば次の資料を参照してください（この資料では非ボックス化と訳されています）。

* [7.2.2. 非ボックス化タプル](http://www.kotha.net/ghcguide_ja/7.6.2/primitives.html#unboxed-tuples)（[栄光のグラスゴーHaskellコンパイルシステム利用の手引き バージョン7.6.2](http://www.kotha.net/ghcguide_ja/7.6.2/)） 2013.2.11

※ ちなみに`IOUArray`のUもアンボックス化の意味です。

## return

`let a = return 1`相当のIOモナドを自作します。先ほど述べたように`return`はファクトリメソッドのようなもので、指定された値を返す関数を作ってIOモナドの中に入れますが、それを手動で行います。

![return.png](https://qiita-image-store.s3.amazonaws.com/0/32057/a5516986-62e8-6ccf-57fa-2b9f0357c0e2.png)

```hs
{-# LANGUAGE UnboxedTuples #-}

import GHC.Base

main = do
    let a = IO $ \s -> (# s, 1 #)
    print =<< a
```
```text:実行結果
1
```

ここで見られるIOモナド内の関数の仕様をまとめます。

* 戻り値は2要素のアンボックス化タプルです。
* 第1要素は引数を素通ししたものです。
* 第2要素は今まで「アクションから取り出した値」と言っていた値です。
* アンボックス化タプルを使うことで、タプルに格納する際に式が評価されるようにしています。

引数はどこから来るのでしょうか。

## main

mainの実体もIOモナドのため、関数から自作することが可能です。

![main.png](https://qiita-image-store.s3.amazonaws.com/0/32057/78abf5a6-679d-c0dc-0953-2a450a410e5f.png)

```hs
{-# LANGUAGE UnboxedTuples #-}

import GHC.Base

main = IO $ \s -> (# s, () #)
```
```text:実行結果
（出力なし）
```

引数`s`はHaskellの処理系によって渡されたもので、自分で作ることはできません。これを取り回すことでIOモナドは実行されていきます。その様子を見ます。

## print

`main`に渡された引数を`print`に渡してみます。

![main_print.png](https://qiita-image-store.s3.amazonaws.com/0/32057/c17ad7b2-8caa-c7e0-62d9-a378bc097d42.png)

```hs
{-# LANGUAGE UnboxedTuples #-}

import GHC.Base

main = IO $ \s ->
    let (# s1, r #) = unIO (print "hello") s
    in  (# s1, r #)
```
```text:実行結果
"hello"
```

引数`s`が`print`を通ることで`s1`に変化して最終的な戻り値となります。

## State# RealWorld

IOモナド内の関数に渡される引数の型は`State# RealWorld`です。`#`は`'`と同じように名前の一部ですが、扱うには言語拡張`MagicHash`が必要です。あまり触られたくない型や変数に`#`が付けられているようです。

処理を連続させるには`s`をバケツリレーします。型注釈を明記します。

![main_print3.png](https://qiita-image-store.s3.amazonaws.com/0/32057/0d3e7602-83c9-b076-9ab4-c55c05b94a75.png)

```hs
{-# LANGUAGE UnboxedTuples, MagicHash #-}

import GHC.Base

main' :: State# RealWorld -> (# State# RealWorld, () #)
main' s =
    let (# s1, _ #) = unIO (print "hello") s
        (# s2, _ #) = unIO (print "world") s1
        (# s3, r #) = unIO (print "!!") s2
    in  (# s3, r #)

main :: IO ()
main =  IO main'
```
```text:実行結果
"hello"
"world"
"!!"
```

これは次のように解釈できます。

* `State# RealWorld`は**ある時点の実世界の状態**を表す型です。
    * 状態が具体的にどんなデータなのかは不明ですが、識別ID以上の意味はないようです。
* その型を持つ変数がバケツリレーされている様子は、副作用のある関数を通ることで**状態が変化している**ことを表現しています。
* 最後の状態が関数の戻り値の1つとして返されます。

実世界という表現は大袈裟に感じますが、プログラムは入出力（I/O）により外部とやり取りしているため、実世界と切り離されてはいないという意味合いです。そしてI/Oを取り扱うためのモナドということでIOモナドと呼ばれます。

状態の受け渡しについては、もっと簡単なコードでの例がヒントになるかもしれません。

* [@7shi](https://twitter.com/7shi): [Haskell - リストとIOUArray - Qiita](http://qiita.com/7shi/items/1e6b5899db3ab6b6a8fc) 2015.1.11

※ 状態はきちんと順番に受け渡す必要がありますが、言語的に保護されているわけではありません。通常はbindが適切に処理するため、bindによって保護されているとは言えます。他の言語での保護状況や、順番を守らなかったときのことなどに興味があれば、次の記事を参照してください。

* [@7shi](https://twitter.com/7shi): [Clean 一意型 調査メモ](http://qiita.com/7shi/items/ab3b819871d7b0710949) 2014.12.5
* [@7shi](https://twitter.com/7shi): [IOモナドを素手で触ってみた](http://qiita.com/7shi/items/0a90d7ba31355e1c73aa) 2014.12.9

### ループとの比較

ループを再帰で実装する際に、ループカウンターを引数で表現することで変数の書き換えを避けることができます。

```hs
main = do
    let loop i | i <= 3 = do
            print i
            loop $ i + 1
        loop _ = return ()
    loop 1
```
```text:実行結果
1
2
3
```

IOモナド内の関数が受け取る状態は、このループカウンターのようなものだと見なせます。更新されたループカウンターが再帰で渡されるように、更新された状態が後続のIOモナドに受け渡されて行きます。

## do

3種類の書き方を比較してみます。

```hs
{-# LANGUAGE UnboxedTuples #-}

import GHC.Base

test1 = do
    a <- return 1
    print a

test2 =
    return 2 >>= \a ->
    print a

test3 = IO $ \s ->
    let (# s1, a #) = unIO (return 3) s
        (# s2, r #) = unIO (print  a) s1
    in  (# s2, r #)

main = test1 >> test2 >> test3
```
```text:実行結果
1
2
3
```

隠された仕組みを2段階で明らかにしています。

1. `test1`→`test2`：値の受け渡しを明らかにします。
2. `test2`→`test3`：状態の受け渡しを明らかにします。

値と状態の受け渡しを明示的に書くのは面倒です。見せる必要のない仕組みを隠すことで、使いやすくしているわけです。

## ここまでのまとめ

* IOモナドの中には関数が入っています。
* 関数は状態を受け取って、更新された状態と値を返します。
    * 状態の受け渡しを隠せば、IOモナドから値だけを取り出しているように見えます。
* 状態をバケツリレーすることでコンテキストが構成されます。
    * `do`ブロックは独自のコンテキストを持つと見なせます。
* このモデルで入出力（I/O）による状態変化を取り扱えるため、IOモナドと呼ばれます。

## 練習

【問1】次のコードから`do`を取り除いて、bindや`return`は使わずに`unIO`や`IO`で書き換えてください。

```hs
import System.Random

shuffle [] = return []
shuffle xs = do
    n <- getStdRandom $ randomR (0, length xs - 1) :: IO Int
    xs' <- shuffle $ take n xs ++ drop (n + 1) xs
    return $ (xs !! n) : xs'

main = do
    xs <- shuffle [1..9]
    print xs
```

⇒ [解答例](http://qiita.com/7shi/items/dfc114f133580ee85686#シャッフル)

# bind

bind（`>>=`）はIOモナドと関数をつなぎます。IOモナドから取り出した値を関数に渡します。関数はIOモナドを返すという縛りがあるため、つないだものは1つの大きなIOモナドになります。

`m' = m >>= f`のイメージを示します。

![m_bind_f.png](https://qiita-image-store.s3.amazonaws.com/0/32057/19c5dde4-2b4a-f40c-6ca1-bab6d75001df.png)

複数bindした`m' = m >>= f1 >>= f2`のイメージを示します。

![m_bind_f1_bind_f2.png](https://qiita-image-store.s3.amazonaws.com/0/32057/4171934d-af61-548a-65de-330b6763255a.png)

IOモナドはbindすることでどんどん大きく成長して行きます。これが冒頭で言及した「IOモナドを組み合わせることの具体的なイメージ」です。

コードでも括弧で囲めばIOモナドの階層構造が見えて来ます。

```hs
test1 = ((return "1" >>= putStr) >>= print)
test2 = return "2" >>= putStr >>= print

main = test1 >> test2
```
```text:実行結果
1()
2()
```

`test2`のようにフラットに書いても左から結合されるため、結果的に`test1`と同じ構造が形成されます。

## 値の動き

`m' = m >>= f`と定義される`m'`から値を取り出す動きを示します。

![m_bind_f_value.png](https://qiita-image-store.s3.amazonaws.com/0/32057/71f0f6a1-2c1e-414a-5404-9081b74a8f81.png)

1. `m`から値が取り出されて`f`に渡されます。
2. `f`からIOモナドが返されます。
3. 2のIOモナドから値を取り出します。
4. 3の値が`m'`から取り出した値となります。

## 詳細な動き

これをIOモナド内の関数を含めた形で細かく見ます。

![m_bind_f_func.png](https://qiita-image-store.s3.amazonaws.com/0/32057/b3fd6746-bb75-f57c-22a2-a410b145cce1.png)

1. `m'`内の関数（`>>=`によって作成）に外部から状態が渡されます。
2. 1で渡された状態は`m`内の関数に渡されます。
3. `m`内の関数から状態と値が返されます。
4. 3の値が`f`に渡されます。
5. `f`からIOモナドが返されます。
6. 5のIOモナド内の関数に3の状態が渡されます。
7. 関数から状態と値が返されます。
8. 7の状態と値が`m'`内の関数からの戻り値となります。

## カプセル化

`>>=`の役割は、適切に状態を受け渡す関数を生成することです。IOモナドの中に関数があることも、状態が受け渡されていることも、普通は意識することはありません。`>>=`が内々に処理しています。

オブジェクト指向での[カプセル化](http://ja.wikipedia.org/wiki/%E3%82%AB%E3%83%97%E3%82%BB%E3%83%AB%E5%8C%96)に近い考え方です。

`>>=`の他に、`return`もIOモナドの内部構造を前提に実装されています。

## まとめ

* IOモナドの内部には関数があり、状態の受け渡しを行っています。
* IOモナドの内部構造を知っているのは`>>=`と`return`だけです。
* `>>=`と`return`の使い方さえ知っていれば、内部構造を知らなくてもIOモナドは利用できます。
* `>>=`によって、状態は適切に受け渡されることが保証されます。
* 結果をアンボックス化タプルに入れることで、順番に評価されることが保証されます。

## 練習

【問2】IOモナドを扱う`bind`と`return'`を実装してください。`>>=`, `<<=`, `<-`, `return`は使わないでください。

具体的には次のコードが動くようにしてください。

```hs
main = return' "hello" `bind` putStr `bind` print
```
```text:実行結果
hello()
```

⇒ [解答例](http://qiita.com/7shi/items/dfc114f133580ee85686#再実装)

# 参考

IOモナドについての詳細は次の記事が参考になります。

* [IO inside - HaskellWiki](https://www.haskell.org/haskellwiki/IO_inside) 2013.5.22
