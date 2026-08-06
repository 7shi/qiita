---
coediting: false
comments_count: 0
created_at: '2014-12-03T15:12:36+09:00'
id: 4a8a2807bb5186576c61
likes_count: 48
private: false
reactions_count: 0
stocks_count: 33
tags:
- name: Haskell
  versions: []
title: Haskell アクションとラムダ 超入門
updated_at: ''
url: https://qiita.com/7shi/items/4a8a2807bb5186576c61
slide: false
---

Haskellの`do`ブロックの中はbindで結ばれています。アクションとラムダを組み合わせることで仕組みを探ります。アクションをもっと便利に使うことを目的としているため、モナドや圏論には言及しません。

シリーズの記事です。

1. [Haskell 超入門](http://qiita.com/7shi/items/145f1234f8ec2af923ef)
1. [Haskell 代数的データ型 超入門](http://qiita.com/7shi/items/1ce76bde464b4a55c143)
1. [Haskell アクション 超入門](http://qiita.com/7shi/items/85afd7bbd5d6c4115ad6)
1. [Haskell ラムダ 超入門](http://qiita.com/7shi/items/1345bf32003faff435cb)
1. **Haskell アクションとラムダ 超入門** ← この記事
1. [Haskell IOモナド 超入門](http://qiita.com/7shi/items/d3d3492ddd90d47160f2)
1. [Haskell リストモナド 超入門](http://qiita.com/7shi/items/deb19c4cba933590ffbf)
1. [Haskell Maybeモナド 超入門](http://qiita.com/7shi/items/c7d7eec066af0fe0688d)
1. [Haskell 状態系モナド 超入門](http://qiita.com/7shi/items/2e9bff5d88302de1a9e9)
1. [Haskell モナド変換子 超入門](http://qiita.com/7shi/items/4408b76624067c17e933)
1. [Haskell 例外処理 超入門](http://qiita.com/7shi/items/73e534c47bbebc71b37e)
1. [Haskell 構文解析 超入門](http://qiita.com/7shi/items/b8c741e78a96ea2c10fe)
1. [Haskell 継続モナド 超入門](https://zenn.dev/7shi/articles/20260803-haskell-continuation-monad)
1. [Haskell 型クラス 超入門](https://zenn.dev/7shi/articles/20260805-haskell-type-classes)
1. 【予定】Haskell モナドとゆかいな仲間たち
1. 【予定】Haskell Freeモナド 超入門
1. 【予定】Haskell Operationalモナド 超入門
1. 【予定】Haskell Effモナド 超入門
1. 【予定】Haskell アロー 超入門

練習の解答例は別記事に掲載します。

* [【解答例】Haskell アクションとラムダ 超入門](http://qiita.com/7shi/items/cb99bb70ee103408bf51)

# bind

`do`ブロックの各行はbindで結ばれています。

簡単な例で確認します。まず`do`を使った例です、

```hs
main = do
    print "hello"
    print "world"
```
```text:実行結果
"hello"
"world"
```

`do`を外して明示的に`>>=`を記述します。

```hs
main =
    print "hello" >>= \_ ->
        print "world"
```
```text:実行結果
"hello"
"world"
```

同じように動くことが確認できました。

## 行を増やす

行を増やして確認します。

```hs:doあり
main = do
    print "abc"
    print "def"
    print "ghi"
    print "jkl"
    print "mno"
```
```hs:doなし
main =
    print "abc" >>= \_ ->
        print "def" >>= \_ ->
            print "ghi" >>= \_ ->
                print "jkl" >>= \_ ->
                    print "mno"
```
```text:実行結果
"abc"
"def"
"ghi"
"jkl"
"mno"
```

`do`によって自動的に`>>= \_ ->`の部分が補われているため、複数行が記述できているわけです。

### インデント

ラムダ式のインデントがどんどん深くなって読みにくいため、便宜上フラットに記述します。

```hs
main =
    print "abc" >>= \_ ->
    print "def" >>= \_ ->
    print "ghi" >>= \_ ->
    print "jkl" >>= \_ ->
    print "mno"
```

## 暗黙の取り出し

ラムダ式の引数`_`は、`do`で行われる暗黙の取り出しを表しています。

```hs:暗黙
main = do
    print "abc"
    print "def"
    print "ghi"
```
```hs:明示
main = do
    _ <- print "abc"
    _ <- print "def"
    print "ghi"
```
```hs:doなし
main =
    print "abc" >>= \_ ->
    print "def" >>= \_ ->
    print "ghi"
```

ラムダ式の引数は、アクションから取り出された値を束縛する変数に相当します。

## <-

変数に束縛されるケースで確認します。

```hs:doあり
main = do
    a <- return "hello"
    print a
```
```hs:doなし
main =
    return "hello" >>= \a ->
    print a
```
```text:実行結果
"hello"
```

### ポイントフリースタイル

`print`にそのまま渡している引数は、ポイントフリースタイルの要領で省略できます。

```hs
main =
    return "hello" >>=
    print
```
```text:実行結果
"hello"
```

## 練習

【問1】次のコードから`do`を取り除いて、`>>=`でつないでください。

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

⇒ [解答例](http://qiita.com/7shi/items/cb99bb70ee103408bf51#%E3%82%B7%E3%83%A3%E3%83%83%E3%83%95%E3%83%AB)

# ここまでのまとめ

* `do`ブロックの実体：各行がラムダ式化されて`>>=`で連結

`do`を使わなくても同じ処理を書くことができます。しかし表記が煩雑になるため、以後は特別な事情がない限り`do`を付けたコードを掲載します。重要なのは仕組みを認識していることです。

※ その先には`>>=`の仕組みも待ち構えています。詳細は続編で説明します。👉[IOモナド](https://qiita.com/7shi/items/d3d3492ddd90d47160f2#bind)

# IORef

アクション超入門で紹介した`IORef`ですが、ラムダ超入門の知識があれば便利になります。👉[アクション](https://qiita.com/7shi/items/85afd7bbd5d6c4115ad6#ioref) 👉[ラムダ](https://qiita.com/7shi/items/1345bf32003faff435cb#%E3%83%A9%E3%83%A0%E3%83%80%E5%BC%8F)

まず比較として、今までの知識で`IORef`の値に1を足してみます。

```hs
import System.Random
import Data.IORef

main = do
    a <- newIORef =<< (getStdRandom $ randomR (0, 9) :: IO Int)
    a' <- readIORef a
    writeIORef a (a' + 1)
    print =<< readIORef a
```
```text:実行結果（毎回異なる）
5
```

## modifyIORef

IORefには値の更新を行う関数`modifyIORef`が用意されています。

```hs
main = do
    a <- newIORef =<< (getStdRandom $ randomR (0, 9) :: IO Int)
    modifyIORef a (+ 1)
    print =<< readIORef a
```

アクション超入門で`modifyIORef`を紹介しなかったのは、ラムダ式やセクションの知識がないと有効活用できないためです。👉[アクション](https://qiita.com/7shi/items/85afd7bbd5d6c4115ad6#ioref)

## 練習

【問2】配列には`modifyIORef`に相当する関数がありません。`modifyArray`を実装してください。

具体的には以下のコードが動くようにしてください。

```hs
main = do
    a <- newArray (0, 2) 0 :: IO (IOUArray Int Int)
    print =<< getElems a
    modifyArray a 1 (+ 5)
    print =<< getElems a
```
```text:実行結果
[0,0,0]
[0,5,0]
```

⇒ [解答例](http://qiita.com/7shi/items/cb99bb70ee103408bf51#%E9%85%8D%E5%88%97%E3%81%AE%E6%9B%B4%E6%96%B0)

# 色々な関数や演算子

アクションはモナドと呼ばれるものの一種です。ここではモナドが何かということは説明しませんが、とりあえずアクションのこととして先に進みます。

[Control.Monad](http://hackage.haskell.org/package/base-4.7.0.1/docs/Control-Monad.html)モジュールにはアクションと組み合わせて使える関数が用意されています。その中のいくつかを紹介します。

## replicateM

アクションに対して使う`replicate`です。指定された回数だけアクションから値を取り出してリスト化します。

※ 関数の接尾辞`M`はモナド用であることを意味しています。アクションはモナドの一種のため、ここではアクション用と読み替えます。

乱数で試すとその都度値が取り出されていることが確認できます。

```hs
import Control.Monad
import System.Random

dice :: IO Int
dice = getStdRandom $ randomR (1, 6)

main = do
    print $   replicate  5 1
    print =<< replicateM 5 (return 1)
    print =<< replicateM 5 dice
```
```text:実行結果（毎回異なる）
[1,1,1,1,1]
[1,1,1,1,1]
[4,6,2,1,2]
```
## replicateM_

アクションから取り出した値を捨てるタイプの`replicateM`です。戻り値は`()`が入ったアクションです。副作用を繰り返すのに使えます。

※ 関数の接尾辞`_`は値を捨てることを意味しています。引数などを無視するための変数名`_`と関係があります。

```hs
import Control.Monad
import System.Random

dice :: IO Int
dice = getStdRandom $ randomR (1, 6)

main = do
    replicateM_ 3 $ do
        print =<< dice
```
```text:実行結果（毎回異なる）
6
1
5
```

`do`ブロックに対する指定回数ループだと捉えれば良いでしょう。

## forM

C#などにある`foreach`に似た処理を行う関数です。リストを渡すと値を1つずつ取り出して、指定した関数に引数として渡します。引数はラムダ式で受け取るのが手軽です。戻り値としてリストを返します。

```hs
import Control.Monad

main = do
    a <- forM [1..3] $ \i -> do
        print i
        return i
    print a
```
```text:実行結果
1
2
3
[1,2,3]
```

## forM_

`forM`の戻り値を捨てる版です。単なるループとして使うにはこちらが手軽です。

```hs
import Control.Monad

main = do
    forM_ [1..3] $ \i -> do
        print i
```
```text:実行結果
1
2
3
```

## when と unless

`if`では`else`を省略できませんが、それに相当する関数が`when`です。

* `when 条件 アクション`

サイコロで3が出るまで繰り返す例です。

```hs
import Control.Monad
import System.Random

dice :: IO Int
dice = getStdRandom $ randomR (1, 6)

main = do
    r <- dice
    print r
    when (r /= 3) main
```
```text:実行結果（毎回異なる）
1
5
3
```

`else`だけに相当するのが`unless`です。

```hs
main = do
    r <- dice
    print r
    unless (r == 3) main
```

## >>

アクションから値を取り出して捨て、次のアクションに移るための演算子です。

暗黙で取り出して捨てる動作を一行で書くようなイメージです。

```hs
test1 = do
    print 1
    print 2

test2 = print 1 >> print 2

main = test1 >> test2
```
```text:実行結果
1
2
1
2
```

## >=> と <=<

アクションを返す関数を合成します。奇妙な見た目で、初めて見るとびっくりします。

同じ処理を別の記法で記述して比較します。

```hs
import Control.Monad

f1 x = putStr x >>= print
f2 = \x -> putStr x >>= print
f3 = putStr >=> print
f4 = print <=< putStr
f5 = (>>= print) . putStr

main = f1 "1" >> f2 "2" >> f3 "3" >> f4 "4" >> f5 "5"
```
```text:実行結果
1()
2()
3()
4()
5()
```

* `f1`: 普通の関数です。
* `f2`: `f1`をラムダ式化したものです。モナド則に出て来る書き方ですが、今回の範囲を超えるため説明を省略します。
* `f3`: `>=>`で関数を合成しました。
* `f4`: 逆向きの演算子`<=<`で合成しました。
* `f5`: `.`で関数とセクションを合成しました。パズルみたいな書き方です。

`f5`の書き換えについては、興味があれば次の記事を参照してください。

* [@7shi](https://twitter.com/7shi): [Haskell - 関数合成を機械的に扱う試み - Qiita](http://qiita.com/7shi/items/f2c1365b792aa6046a49) 2015.2.9

`>=>`については次の記事が参考になります。

* [@CyLomw](https://twitter.com/CyLomw): [Haskell - (>>=) を (>=>) に書き換える - Qiita](http://qiita.com/CyLomw/items/a874cee33c69653f53c6) 2014.12.30

## 練習

【問3】`replicateM`, `replicateM_`, `forM`, `forM_`, `when`, `unless`を再実装してください。関数名には`'`を付けてください。

具体的には以下のコードが動くようにしてください。

```hs
main = do
    let dice = getStdRandom $ randomR (1, 6) :: IO Int
    print =<< replicateM' 5 dice
    putStrLn "---"
    replicateM_' 3 $ do
        print =<< dice
    putStrLn "---"
    a <- forM' [1..3] $ \i -> do
        print i
        return i
    print a
    putStrLn "---"
    forM_' [1..3] $ \i -> do
        print i
    putStrLn "---"
    let y f = f (y f)
    y $ \f -> do
        r <- dice
        print r
        when' (r /= 1) f
    putStrLn "---"
    y $ \f -> do
        r <- dice
        print r
        unless' (r == 6) f
```

⇒ [解答例](http://qiita.com/7shi/items/cb99bb70ee103408bf51#%E5%86%8D%E5%AE%9F%E8%A3%85)

【問4】0.0～1.0までのDouble型の乱数を12個足したものを四捨五入して6を引いた整数値について、100回の分布を求めてください。四捨五入には[round](http://hackage.haskell.org/package/base-4.7.0.1/docs/Prelude.html#v:round)ではなく、切り捨て関数[truncate](http://hackage.haskell.org/package/base-4.7.0.1/docs/Prelude.html#v:truncate)を工夫して使用してください。

具体的には以下のように出力してください。

```text:実行結果（毎回異なる）
-3: *
-2: ******
-1: ****************************
 0: **********************************
 1: ***********************
 2: *******
 3: *
```

⇒ [解答例](http://qiita.com/7shi/items/cb99bb70ee103408bf51#%E6%AD%A3%E8%A6%8F%E4%B9%B1%E6%95%B0)
