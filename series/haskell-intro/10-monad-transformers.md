---
coediting: false
comments_count: 0
created_at: '2015-01-04T22:32:37+09:00'
id: 4408b76624067c17e933
likes_count: 90
private: false
reactions_count: 0
stocks_count: 75
tags:
- name: Haskell
  versions: []
title: Haskell モナド変換子 超入門
updated_at: ''
url: https://qiita.com/7shi/items/4408b76624067c17e933
slide: false
---

Haskellではモナドと呼ばれる部品を組み合わせてプログラムを作ります。別種のモナドを組み合わせるためのモナド変換子の使い方の初歩を説明します。ライブラリで用意されたモナド変換子を手っ取り早く使うことを目的としているため、モナド変換子の作り方や圏論には言及しません。

シリーズの記事です。

1. [Haskell 超入門](http://qiita.com/7shi/items/145f1234f8ec2af923ef)
1. [Haskell 代数的データ型 超入門](http://qiita.com/7shi/items/1ce76bde464b4a55c143)
1. [Haskell アクション 超入門](http://qiita.com/7shi/items/85afd7bbd5d6c4115ad6)
1. [Haskell ラムダ 超入門](http://qiita.com/7shi/items/1345bf32003faff435cb)
1. [Haskell アクションとラムダ 超入門](http://qiita.com/7shi/items/4a8a2807bb5186576c61)
1. [Haskell IOモナド 超入門](http://qiita.com/7shi/items/d3d3492ddd90d47160f2)
1. [Haskell リストモナド 超入門](http://qiita.com/7shi/items/deb19c4cba933590ffbf)
1. [Haskell Maybeモナド 超入門](http://qiita.com/7shi/items/c7d7eec066af0fe0688d)
1. [Haskell 状態系モナド 超入門](http://qiita.com/7shi/items/2e9bff5d88302de1a9e9)
1. **Haskell モナド変換子 超入門** ← この記事
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

* [【解答例】Haskell モナド変換子 超入門](http://qiita.com/7shi/items/79fe0e4c77427368ae2d)

# モナド変換子

`do`の中では同じ種類のモナドしか使うことができません。

たとえば次のようにStateモナドとIOモナドを併用することはできません。

```hs:NG
import Control.Monad
import Control.Monad.State

sum' xs = (`execState` 0) $ do
    forM_ xs $ \i -> do
        modify (+ i)
        v <- get
        putStrLn $ "+" ++ show i ++ " -> " ++ show v  -- エラー

main = do
    print $ sum' [1..5]
```
```text:エラー内容
Couldn't match type `IO'
              with `StateT c transformers-0.3.0.0:Data.Functor.Identity.Identity'
Expected type: State c ()
  Actual type: IO ()
```

このような問題に対処するのがモナド変換子です。説明は後回しで例を示します。

```hs
import Control.Monad
import Control.Monad.State

sum' xs = (`execStateT` 0) $ do                              -- execStateT
    forM_ xs $ \i -> do
        modify (+ i)
        v <- get
        lift $ putStrLn $ "+" ++ show i ++ " -> " ++ show v  -- lift

main = do
    print =<< sum' [1..5]                                    -- $ → =<<
```
```text:実行結果
+1 -> 1
+2 -> 3
+3 -> 6
+4 -> 10
+5 -> 15
15
```

`execStateT`や`lift`などが新しく登場しています。`print`の次が`=<<`になっています。

これらを説明する前に必要なものから見て行きます。

# Identityモナド

```hs:型表記
Identity a
```

中に値が入っているだけの最も単純なモナドです。identityは[恒等式](http://ja.wikipedia.org/wiki/%E6%81%92%E7%AD%89%E5%BC%8F)という意味で、Identityモナドは恒等モナドとも呼ばれます。

※ [自己同一性](http://ja.wikipedia.org/wiki/%E8%87%AA%E5%B7%B1%E5%90%8C%E4%B8%80%E6%80%A7)などと訳されるアイデンティティと同じ単語です。

値は`runIdentity`で取り出せます。

```hs
import Control.Monad.Identity

main = do
    let a = return 1 :: Identity Int  -- 生成
    print $ runIdentity a             -- 値の取り出し（評価）
```
```text:実行結果
1
```

モナドには値だけが入っていて、関数や状態が隠されてはいません。リストモナドと違って要素数は1固定です。

特別な機能はなく、何もしないモナドです。

## id

```hs:型
id :: a -> a
```

引数をそのまま返す関数です。`id`はidentityに由来して恒等関数とも呼ばれます。

高階関数に何か関数を渡す際、何もして欲しくないときなどに使います。次の例での`f id`が該当します。

```hs
f g x = g x

main = do
    print 1
    print $ id 1
    print $ f id 1  -- 注目
```
```text:実行結果
1
1
1
```

この例での`f`はポイントフリースタイルを進めると引数が全部消えますが、このようなときに右辺を埋めるのにも`id`は使えます。

1. `f g x = g x`
2. `f g   = g`
3. `f     =` ← エラー
4. `f     = id`

`Identity`はモナド、`id`は関数での、似たような位置付けのものです。

※ [単位元](https://ja.wikipedia.org/wiki/%E5%8D%98%E4%BD%8D%E5%85%83)（掛け算における1）のようなものです。

# StateTモナド変換子

Stateモナドに対するモナド変換子です。

* Tは "transformer" の略で、モナド変換子を表す接尾辞です。
* モナド変換子はモナドの一種です。

## 型表記

```hs
StateT s m a
```

* `State s a`に対して`m`が増えています。
* `m`は任意のモナドを指定します。モナドの変換に関係します。

## Stateモナドとの関係

```hs:定義
type State s a = StateT s Identity a
```

StateモナドはStateTモナド変換子の`m`に`Identity`を指定したものです。何もしないIdentityモナドを指定することで、変換子を無効化して単なるモナドにしています。

StateTモナド変換子にIdentityモナドを指定することでStateモナドが作れることを確認します。

```hs
import Control.Monad.Identity
import Control.Monad.State

main = do
    let a = return 1 :: StateT s Identity Int  -- StateTとして生成
    print $ evalState a ()                     -- Stateとして評価
```
```text:実行結果
1
```

StateTモナド変換子を型指定しているのに`evalState`が適用できています。

Identity以外のモナドを指定すると破綻します。

```hs:NG
import Control.Monad.Identity
import Control.Monad.State

main = do
    let a = return 1 :: StateT s IO Int
    print $ evalState a ()               -- エラー
```
```text:エラー内容
Couldn't match type `IO' with `Identity'
Expected type: State () Int
  Actual type: StateT () IO Int
```

IOを指定するケースがモナド変換子の真骨頂ですが、詳細は後の方で取り上げます。

### 類似例

IOモナドがSTモナドの`s`に`RealWorld`を指定したものと相互変換できる関係と似ています。

* `IO a` ⇔ `ST RealWorld a`

IOモナドとSTモナドの関係は等価物として変換可能ということですが、Stateモナドは実体がStateTモナド変換子のため変換は介在しません。

* `State s a` == `StateT s Identity a`

STは "state-transformer" でモナド変換子のTと同じ単語ですが、STはモナド変換子ではありません。"transformer" の意味合いが異なるようです。

## 内部関数

```hs:型
s -> m (a, s)
```

Stateモナドでは`m`が`Identity`のため、内部関数は次のようになります。

```hs:型
s -> Identity (a, s)
```

Stateモナドでは`runState m`とすることで内部関数を取り出せますが、実際に入っている内部関数は戻り値がIdentityモナドで包まれています。実用上はIdentityモナドを見せる必要がないため、`runState`は内部関数をラップしてIdentityモナドを隠しています。

## runStateT

```hs:型
runStateT :: StateT s m a -> s -> m (a,s)
```

StateTモナド変換子から内部関数を取り出します。

※ runという表現に違和感があれば、rを無視してunStateTだと見立てると良いかもしれません。

`runState`のように関数を加工することはありません。両者を比較します。

```hs
import Control.Monad.Identity
import Control.Monad.State

st = return 1 :: State s Int     -- Stateを生成

f1 :: s -> (Int, s)
f1 = runState st                 -- 加工された内部関数を取り出し

f2 :: s -> Identity (Int, s)
f2 = runStateT st                -- 生の内部関数を取り出し

main = do
    print $ f1 ()                -- (値, 状態)
    print $ runIdentity $ f2 ()  -- Identityで包まれている
```
```text:実行結果
(1,())
(1,())
```

### 片方だけを取得する関数

`runState`と同じように、`runStateT`にも値や状態だけを返す関数があります。

* 値だけ: `evalStateT :: (Monad m) => StateT s m a -> s -> m a`
* 状態だけ: `execStateT :: (Monad m) => StateT s m a -> s -> m s`

比較します。

```hs
import Control.Monad.Identity
import Control.Monad.State

main = do
    let st = return 1 :: StateT s Identity Int
    print $ runIdentity $  runStateT st ()      -- (値, 状態)
    print $ runIdentity $ evalStateT st ()      --  値
    print $ runIdentity $ execStateT st ()      --      状態
```
```text:実行結果
(1,())
1
()
```

## StateT

```hs:型
StateT :: (s -> m (a,s)) -> StateT s m a
```

関数からStateTモナド変換子を生成します。`runStateT`の逆です。

応用として、Stateモナドを関数から自作してみます。

```hs
import Control.Monad.Identity
import Control.Monad.State

main = do
    let st = StateT $ \s -> Identity (1, s)  -- 関数から生成
    print $ runIdentity $ runStateT st ()    -- StateTとして評価
    print $ runState st ()                   -- Stateとして評価
```
```text:実行結果
(1,())
(1,())
```

StateTモナド変換子として作った`st`が`runState`で評価できています。

## IOモナドとの比較

内部関数を出し入れする関数をIOモナドと比較します。

![IO-StateT.png](https://qiita-image-store.s3.amazonaws.com/0/32057/af9f600f-8169-0bc1-9901-537b495a2aa2.png)

型    |取り出し |格納
------|---------|------
IO    |unIO     |IO
StateT|runStateT|StateT

## 練習

【問1】Stateモナドを扱う`return`を`StateT`を使って、`runState`を`runStateT`を使って再実装してください。

具体的には次のコードが動くようにしてください。

```hs
main = do
    let st = return' 1
    print $ runState' st ()
```
```text:実行結果
(1,())
```

⇒ [解答例](http://qiita.com/7shi/items/79fe0e4c77427368ae2d#state%E3%83%A2%E3%83%8A%E3%83%89)

# 持ち上げ

ここからはモナド変換子によって別種のモナドを合成する方法について見て行きます。

サンプルの一部を再掲します。

```hs
sum' xs = (`execStateT` 0) $ do
    forM_ xs $ \i -> do
        modify (+ i)
        v <- get
        lift $ putStrLn $ "+" ++ show i ++ " -> " ++ show v  -- 注目
```

`lift`の後にIOモナドを記述することで、StateモナドとIOモナドを混ぜています。`lift`は**持ち上げ**と訳されます。

※ ウェイトリフティング（[重量挙げ](http://ja.wikipedia.org/wiki/%E9%87%8D%E9%87%8F%E6%8C%99%E3%81%92)）のリフトです。

まずStateTモナド変換子の`m`に`IO`を指定すると何が起きるかを確認します。

## StateT s IO a

内部関数は次のようになります。

```hs:型
s -> IO (a, s)
```

これを入れたStateTモナド変換子を`runStateT`で初期値を指定して評価すると、IOモナドが返って来ます。StateTモナド変換子の中にIOモナドが入っていると見なせます。

※ `m`に`IO`を指定するとStateモナドとは互換性がなくなるため`runState`は使えません。

![runStateT.png](https://qiita-image-store.s3.amazonaws.com/0/32057/622eea6e-17dd-5402-2151-32bcad893e53.png)

```hs
import Control.Monad.State

f :: s -> IO (Int, s)         -- 内部関数
f s = return (1, s)

a :: StateT s IO Int
a = StateT f                  -- 関数から生成

main = do
    print =<< f ()            -- 関数を評価
    print =<< runStateT a ()  -- StateTを評価
```
```text:実行結果
(1,())
(1,())
```

`runStateT`は内部関数を取り出すだけです。内部関数を直接評価しても、StateTモナド変換子に入れて`runStateT`経由で評価しても、同じ結果です。後者はモナドが介在して追いにくいので、前者の動きに注目すると良いでしょう。

## print

内部関数の中で`print`を使用してみます。

```hs
import Control.Monad.State

f :: s -> IO ((), s)         -- StateTの内部関数
f s = do
    a <- print "hello"       -- printを使用
    return (a, s)            -- IOモナドを返す

a :: StateT s IO ()
a = StateT f                 -- 生成

main = do
    print =<< f 1            -- 関数を評価
    print =<< runStateT a 1  -- StateTを評価
```
```text:実行結果
"hello"
((),1)
"hello"
((),1)
```

## lift

```hs:型
lift :: (Monad m) => m a -> t m a
```

モナドからモナド変換子を生成する関数です。型注釈の`t`はモナド変換子を表します。

内部関数の自作と`lift`とを比較します。IOモナドをStateTモナド変換子の中に入れています。

![lift.png](https://qiita-image-store.s3.amazonaws.com/0/32057/ae3e8f54-1903-afa3-d6ec-77e69d34b0aa.png)

```hs
import Control.Monad.State

a1 :: StateT s IO ()
a1 = StateT $ \s -> do        -- 内部関数の自作
    a <- print "hello"
    return (a, s)

a2 :: StateT s IO ()
a2 = lift $ print "hello"     -- lift

main = do
    print =<< runStateT a1 1  -- 評価結果はIOで返る
    print =<< runStateT a2 1  -- 同上
```
```text:実行結果
"hello"
((),1)
"hello"
((),1)
```

### 捉え方

`lift`はモナド変換子版の`return`のようなものだと捉えられます。

![return-lift.png](https://qiita-image-store.s3.amazonaws.com/0/32057/8b54dce3-9e37-d565-8d8c-ef75f34a7c90.png)

* `return`: 値 → モナド
* `lift`: モナド → モナド変換子

## 組み合わせ

先の例のように単独で`lift`を使ってもあまり意味はありませんが、StateアクションとIOアクションとを併用するときに真価を発揮します。

状態を`get`で取得して`print`で表示する例です。

```hs
import Control.Monad.State

a :: StateT String IO ()
a = do
    v <- get        -- Stateアクション
    lift $ print v  -- IOアクション

main = do
    runStateT a "hello"
```
```text:実行結果
"hello"
```

`runStateT`の評価結果はIOモナドに包まれているため、IOモナドに関連した操作はすべて閉じ込められるという原則は守られています。

## モナドスタック

モナド変換子とモナドの関係を包含関係として表現しましたが、積み重ねとしても表現できます。後者を**モナドスタック**と呼びます。包むか積むかという表現方法だけの違いで、意味が変わるわけではありません。

![inner-bottom.png](https://qiita-image-store.s3.amazonaws.com/0/32057/612c3d4a-f8e5-5e27-d2ff-4c281e3fdafb.png)

`print`はIOアクションですが、StateTモナド変換子を積むことでStateTアクションに変換されます。モナドスタックの上方のアクションに変換される様子を**持ち上げ**と表現します。

![lifting.png](https://qiita-image-store.s3.amazonaws.com/0/32057/c0e8a98d-e369-09cb-7f52-bf923883a451.png)

## 練習

【問2】StateTモナド変換子を扱う`bind`, `get`, `modify`, `lift`を実装してください。`do`は使わないでください。`>>=`はStateTモナド変換子以外にのみ使ってください。

`import`の際にオリジナルを隠してください。

```hs
import Control.Monad.State hiding (get, modify, lift)
```

具体的には次のコードが動くようにしてください。

```hs
fact x = (`execStateT` 1) $
    forM_ [1..x] $ \i ->
        modify (* i) `bind` \_ ->
        get `bind` \v ->
        lift $ putStrLn $ "*" ++ show i ++ " -> " ++ show v

main = fact 5 >>= print
```
```text:実行結果
*1 -> 1
*2 -> 2
*3 -> 6
*4 -> 24
*5 -> 120
()
```

⇒ [解答例](http://qiita.com/7shi/items/79fe0e4c77427368ae2d#%E5%86%8D%E5%AE%9F%E8%A3%85)

【問3】問2の`fact`を`do`と`<-`で書き直してください。問2で再実装した関数は使わないでください。

⇒ [解答例](http://qiita.com/7shi/items/79fe0e4c77427368ae2d#%E6%9B%B8%E3%81%8D%E7%9B%B4%E3%81%97)

# Maybeモナドとの合成

今までの例ではStateTモナド変換子で合成するのはIOモナドばかりでしたが、もちろんそれ以外のモナドとも合成できます。

例としてMaybeモナドを取り上げます。

次の手順でサンプルを書き換える過程を示します。

* モナドなし
    * Stateモナド
    * Maybeモナド
* モナド変換子で合成

## モナドなし

`getch`で1文字ずつ取得して、`get3`で3文字分を返します。文字数が足らないとエラーが発生します。

```hs
getch (x:xs) = (x, xs)

get3 xs0 =
    let (x1, xs1) = getch xs0
        (x2, xs2) = getch xs1
        (x3, xs3) = getch xs2
    in [x1, x2, x3]

main = do
    print $ get3 "abcd"  -- OK
    print $ get3 "1234"  -- OK
    print $ get3 "a"     -- NG
```
```text:実行結果（エラー）
"abc"
"123"
xxx: Main.hs:1:1-22: Non-exhaustive patterns in function getch
```

### Stateモナド

状態の受け渡しが冗長なので、Stateモナドで抽象化します。依然としてエラーは発生します。

```hs
import Control.Monad.State

getch = state getch where   -- Stateモナドに関数を入れる
    getch (x:xs) = (x, xs)  -- 状態 -> (値, 状態)

get3 = evalState $ do
    x1 <- getch
    x2 <- getch
    x3 <- getch
    return [x1, x2, x3]

main = do
    print $ get3 "abcd"  -- OK
    print $ get3 "1234"  -- OK
    print $ get3 "a"     -- NG
```
```text:実行結果
"abc"
"123"
xxx: Pattern match failure in do expression at Main.hs:4:5-10
```

### Maybeモナド

最初のコードに戻って、エラーを避けるためにMaybeモナドで書き換えます。

```hs
getch (x:xs) = Just (x, xs)
getch _      = Nothing

get3 xs0 = do
    (x1, xs1) <- getch xs0
    (x2, xs2) <- getch xs1
    (x3, xs3) <- getch xs2
    return [x1, x2, x3]

main = do
    print $ get3 "abcd"  -- OK
    print $ get3 "1234"  -- OK
    print $ get3 "a"     -- NG
```
```text:実行結果
Just "abc"
Just "123"
Nothing
```

## モナド変換子で合成

StateTモナド変換子でMaybeモナドと合成すれば、StateモナドとMaybeモナドの両方の特徴が使えます。

```hs
import Control.Monad.State

getch = StateT getch where
    getch (x:xs) = Just (x, xs)
    getch _      = Nothing

get3 = evalStateT $ do
    x1 <- getch
    x2 <- getch
    x3 <- getch
    return [x1, x2, x3]

main = do
    print $ get3 "abcd"  -- OK
    print $ get3 "1234"  -- OK
    print $ get3 "a"     -- NG
```
```text:実行結果
Just "abc"
Just "123"
Nothing
```

`getch`はMaybeモナドを返す関数をそのままStateTモナド変換子の中に入れています。StateTモナド変換子の中からMaybeモナドが出て来る構造が表現されています。

![StateT-Maybe-1.png](https://qiita-image-store.s3.amazonaws.com/0/32057/0d125295-059f-cff6-19f2-c7ca473b2312.png)

型で考えると、`StateT s Maybe a`を評価すれば`Maybe a`となります。モナドスタックからStateTモナド変換子を取り除いて下のMaybeモナドが残るとイメージできます。

![StateT-Maybe-2.png](https://qiita-image-store.s3.amazonaws.com/0/32057/36f0c6f5-2cdf-2297-9836-6023fb2eebf4.png)

※ ここで取り上げたサンプルに少し手を加えたものを続編でも説明します。👉[](11#モナド変換子で合成)

## 練習

【問4】次のコードは種類を判別しながら文字列を読み進めることを意図しています。Maybeモナドを使ってエラーが起きないように修正してください。モナド変換子は使わないでください。

```hs
import Data.Char

getch f (x:xs) | f x = (x, xs)

test s0 =
    let (ch1, s1) = getch isUpper s0
        (ch2, s2) = getch isLower s1
        (ch3, s3) = getch isDigit s2
    in [ch1, ch2, ch3]

main = do
    print $ test "Aa0"  -- OK
    print $ test "abc"  -- エラー
```
```実行結果
"Aa0"
Main.hs:3:1-30: Non-exhaustive patterns in function getch
```

⇒ [解答例](http://qiita.com/7shi/items/79fe0e4c77427368ae2d#maybe%E3%83%A2%E3%83%8A%E3%83%89)

【問5】問4の解答をStateTモナド変換子を使って書き直してください。

⇒ [解答例](http://qiita.com/7shi/items/79fe0e4c77427368ae2d#statet%E3%83%A2%E3%83%8A%E3%83%89%E5%A4%89%E6%8F%9B%E5%AD%90-1)

# 他のモナド変換子

State以外のモナドにも対応するモナド変換子があります。

モナド      |モナド変換子   |評価関数
------------|---------------|------------
`Reader r a`|`ReaderT r m a`|`runReaderT`
`Writer w a`|`WriterT r m a`|`runWriterT`
`[]       a`|`ListT     m a`|`runListT`

## 練習

【問6】次のコードの`print`を`main`から各`test*`の`do`の中に移動してください。実行結果が同じになるように調整してください。

```hs
import Control.Monad.Reader
import Control.Monad.Writer
import Control.Monad.List

testR x = (`runReader` x) $ do
    a <- ask
    return $ a + 1

testW x = fst $ runWriter $ do
    tell ""
    return $ x + 1

testL x = do
    [x + 1]

main = do
    print $ testR 0
    print $ testW 0
    print $ testL 0
```
```text:実行結果
1
1
[1]
```

⇒ [解答例](http://qiita.com/7shi/items/79fe0e4c77427368ae2d#%E4%BB%96%E3%81%AE%E3%83%A2%E3%83%8A%E3%83%89%E5%A4%89%E6%8F%9B%E5%AD%90)

# 多重持ち上げ

モナドがネストしていると`lift`が最上位まで届かずにエラーになります。

![lift-2-NG.png](https://qiita-image-store.s3.amazonaws.com/0/32057/46164a6e-d8d9-1056-d4f7-34d1ea3ef65e.png)

```hs:NG
import Control.Monad.State
import Control.Monad.Reader

test1 x = (`runStateT` x) $ do  -- StateT
    modify (+ 1)
    a <- get
    lift $ print a              -- OK
    (`runReaderT` a) $ do       -- ReaderT（ネスト）
        b <- ask
        lift $ print $ b + 1    -- エラー

main = do
    test1 1
```
```text:エラー内容
Couldn't match type `IO' with `StateT b m'
Expected type: StateT b m ()
  Actual type: IO ()
```

ネストした回数だけ`lift`する必要があります。

![lift-2.png](https://qiita-image-store.s3.amazonaws.com/0/32057/fc559978-d547-3657-b562-1d7d79bbd925.png)

```hs:OK
import Control.Monad.State
import Control.Monad.Reader

test1 x = (`runStateT` x) $ do
    modify (+ 1)
    a <- get
    lift $ print a
    (`runReaderT` a) $ do
        b <- ask
        lift $ lift $ print $ b + 1  -- 修正

main = do
    test1 1
```
```text:実行結果
2
3
```

その時点でのモナドスタックの最上位まで持ち上げています。

## ネストの変動

先ほどの例では直接ネストさせていたのでネスト回数は明白ですが、ネスト対象が分離しているとややこしくなります。

分離して単独で呼ぶと`lift`し過ぎでエラーになります。

![lift-2-NG-2.png](https://qiita-image-store.s3.amazonaws.com/0/32057/ddfc195f-ac7e-55c2-6b48-25372f548663.png)

```hs:NG
import Control.Monad.State
import Control.Monad.Reader

test1 x = (`runStateT` x) $ do   -- StateT
    modify (+ 1)
    get >>= test2                -- StateTの中でReaderTを使用

test2 x = (`runReaderT` x) $ do  -- ReaderT
    b <- ask
    lift $ lift $ print $ b + 1  -- 2階層目を想定

main = do
    test1 1                      -- OK
    test2 1                      -- エラー（想定階層の相違）
```
```text:エラー内容
Couldn't match type `t0 IO' with `IO'
Expected type: IO ()
  Actual type: t0 IO ()
```

## liftIO

```hs:型
liftIO :: IO a -> m a
```

ネストの深さに関係なく最上位まで一気に持ち上げます。IOアクション専用です。

先ほどの例を修正します。

![liftIO.png](https://qiita-image-store.s3.amazonaws.com/0/32057/4ef83805-bca5-8789-747f-7defb036da01.png)

```hs
import Control.Monad.State
import Control.Monad.Reader

test1 x = (`runStateT` x) $ do
    modify (+ 1)
    get >>= test2

test2 x = (`runReaderT` x) $ do
    b <- ask
    liftIO $ print $ b + 1  -- 階層深度の影響を受けない

main = do
    test1 1
    test2 1
```
```text:実行結果
3
2
```

`test2`がネストの深さに関係なく実行できるようになりました。

このようにIOアクションを持ち上げるときは`liftIO`を使った方が無難です。

## 練習

【問7】問6を`liftIO`で解いてください。

⇒ [解答例](http://qiita.com/7shi/items/79fe0e4c77427368ae2d#liftio)

# 関数の持ち上げ

`lift`や`liftIO`はアクションを持ち上げていましたが、関数の持ち上げもあります。

※ 関数の持ち上げはモナド変換子とは関係ありませんが、持ち上げに関連して取り上げます。

以下、モナドを代表してリストで例を示します。

## 値とモナドスタック

モナドによる値の包含関係もモナドスタックとして表現することができます。

![value.png](https://qiita-image-store.s3.amazonaws.com/0/32057/a4425f3f-4daa-9ed5-6f07-587300e7f446.png)

## 適用不能

通常の関数はモナドに入っている値に対して適用できません。

![liftM-NG.png](https://qiita-image-store.s3.amazonaws.com/0/32057/d460d940-5638-dc0e-962e-d552241b1085.png)

```hs:NG
main = print $ (+ 1) [1]  -- エラー
```

このようなときに使うのが関数の持ち上げです。

## liftM

```hs:型
liftM :: Monad m => (a1 -> r) -> m a1 -> m r 
```

モナドに入っている値に対して、関数を持ち上げることで適用します。

![liftM-OK.png](https://qiita-image-store.s3.amazonaws.com/0/32057/526714f2-076d-ad9c-5c19-cd4f07a85c10.png)

```hs
import Control.Monad

main = print $ liftM (+ 1) [1]
```
```text:実行結果
[2]
```

対象となるモナドと同じ高さまで関数を持ち上げています。

## liftM2

```hs:型
liftM2 :: Monad m => (a1 -> a2 -> r) -> m a1 -> m a2 -> m r 
```

引数が2つある関数に対する持ち上げです。

```hs
import Control.Monad

main = print $ liftM2 (+) [1] [1]
```
```text:実行結果
[2]
```

同様に`liftM5`まで定義されています。

* [Control.Monad: Monadic lifting operators](http://hackage.haskell.org/package/base-4.7.0.2/docs/Control-Monad.html#g:7)

## Applicativeスタイル

関数の持ち上げは前編で取り上げたApplicativeスタイルと同じです。👉[](03#Applicativeスタイル)

※ そこでは「値の取り出し」という観点で統一するため、敢えて「持ち上げ」とは言わずに別の説明をしています。結果は同じなので、解釈で何かが変わるわけではありません。

1個目の引数は`<$>`、2個目以降の引数は`<*>`でつなぎます。

```hs
import Control.Applicative

main = do
    print $ (1 +) <$> [1]
    print $ (+)   <$> [1] <*> [1]
```
```text:実行結果
[2]
[2]
```

※ Applicativeを直訳すれば「適用可能」です。「複数の引数が**適用可能**」というような意味合いです。今回の範囲を超えるため詳細は省略します。

### <$>とliftM

`<$>`は`liftM`の演算子版で、同じ働きです。

交換してみます。

※ 確認が目的です。実用的なコードではありません。

```hs
import Control.Applicative
import Control.Monad

main = do
    print $ liftM (1 +) [1]
    print $ (<$>) (1 +) [1]          -- <$>を関数化

    print $ (1 +)   <$>   [1]
    print $ (1 +) `liftM` [1]        -- liftMを演算子化

    print $ (+)   <$>   [1] <*> [1]
    print $ (+) `liftM` [1] <*> [1]  -- liftMと<*>の組み合わせ

    print $ liftM (+) [1] <*> [1]    -- こんなこともできるが
    print $ (<$>) (+) [1] <*> [1]    -- あまり意味はない
```
```text:実行結果
[2]
[2]
[2]
[2]
[2]
[2]
[2]
[2]
```

## <$>と<*>

今までApplicativeスタイルは使い方しか示しませんでしたが、そもそも`<$>`と`<*>`の違いは何でしょうか。

再実装を通して、違いを探ります。

### <$>

`<$>`を再実装します。

```hs
f <$> m = do
    a <- m        -- モナドから値を取り出す
    return $ f a  -- 値を関数に適用してモナドに入れて返す

main = do
    print $ (1 +) <$> [1]
```
```text:実行結果
[2]
```

### 部分適用とモナド

`<$>`を引数が2つの関数に適用するとどうなるでしょうか。

例: `(+) <$> [1]`

1. モナド`[1]`から値を取り出し → `1`
2. 関数`(+)`に`1`を部分適用 → `(+) 1` == セクション `(1 +)`
3. 戻り値`(1 +)`がモナドに入れて返される → `[(1 +)]`

引数が足りないため部分適用となり、戻された関数がモナドに入れられます。

### <*>

2番目以降の引数はモナドに入った関数に適用します。

`<*>`を再実装します。

```hs
f <$> m = do
    a <- m
    return $ f a

mf <*> m = do
    f <- mf       -- モナドから関数を取り出す
    a <- m        -- モナドから値を取り出す
    return $ f a  -- 値を関数に適用してモナドに入れて返す

main = do
    print $ (+) <$> [1] <*> [1]
```
```text:実行結果
[2]
```

`<$>`と`<*>`の違いは、関数がモナドに入っているかどうかです。

### <*>だけで書く

最初から関数をモナドに入れれば`<*>`だけで書けます。

```hs
import Control.Applicative

main = do
    print $ return (1 +) <*> [1]
    print $ return   (+) <*> [1] <*> [1]
```
```text:実行結果
[2]
[2]
```

値として関数がモナドに入れられるのがポイントです。

## 第一級関数

値としてモナドに入れられる関数は、状態系モナドの内部関数とは別物です。内部関数の戻り値として生成される対象で、値と同じ扱いです。このように関数が値と同列に扱えることを[第一級関数](http://ja.wikipedia.org/wiki/%E7%AC%AC%E4%B8%80%E7%B4%9A%E9%96%A2%E6%95%B0)と呼びます。

Stateモナドとリストモナドで例を示します。

```hs
import Control.Monad.State

f1 :: State s (Int -> Int)
f1 = return (1 +)                -- 関数をStateモナドに入れる

f2 :: State s (Int -> Int)
f2 = state $ \s -> ((1 +), s)    -- 内部関数が戻すタプルの値が関数

f3 :: [Int -> Int]
f3 = return (1 +)                -- 関数をリストモナドに入れる

main = do
    print $ (evalState f1 ()) 1  -- Stateモナドから取り出した関数を評価
    print $ (evalState f2 ()) 1  -- Stateモナドから取り出した関数を評価
    print $ (f3 !! 0) 1          -- リストモナドから取り出した関数を評価
```
```text:実行結果
2
2
2
```

## liftMとreturn

`return (1 +)`で関数をモナドに入れるのと、`liftM`による持ち上げとの違いは何でしょうか。

`liftM`を部分適用すると、モナドを直接評価できる関数が得られます。

```hs
import Control.Monad

f = liftM (+ 1)    -- 関数の持ち上げ

main = do
    print $ f [1]  -- モナドを直接評価
```
```text:実行結果
[2]
```

このようにモナドを評価できるようにすることが**関数の持ち上げ**です。`f`の実体は部分適用された`liftM`です。

これに対して、関数をモナドに入れても関数としては使えません。

```hs:NG
f :: [Int -> Int]
f = return (+ 1)   -- 関数をモナドに入れる

main = do
    print $ f [1]  -- エラー
```
```text:エラー内容
Couldn't match expected type `[t0] -> a0'
            with actual type `[Int -> Int]'
The function `f' is applied to one argument,
but its type `[Int -> Int]' has none
```

`<*>`の助けが必要です。

```hs:OK
import Control.Applicative

f :: [Int -> Int]
f = return (+ 1)       -- 関数をモナドに入れる

main = do
    print $ f <*> [1]  -- OK
```
```text:実行結果
[2]
```

## 練習

【問8】次のリスト内包表記を`liftM`系の関数で書き直してください。

```hs
main = do
    print [(x , y) | x <- [0, 1], y <- [0, 2]]
    print [ x + y  | x <- [0, 1], y <- [0, 2]]
```

⇒ [解答例](http://qiita.com/7shi/items/79fe0e4c77427368ae2d#liftm)

# 参考

mtlでのStateモナドの定義は途中で変更されたそうです。

* [mtlが変わってる - [ pred x | x <- "Ibtlfmm!ojllj" ] - haskell](http://haskell.g.hatena.ne.jp/illillli/20120707/1341678109) 2012.7.7

`liftIO`は以下の記事を参考にしました。

* [@fmkz___](https://twitter.com/fmkz___): [fmapとliftMとliftそしてliftIO](http://blog.kzfmix.com/entry/1342394344) 2012.7.16
* [liftとliftIOの違い - [ pred x | x <- "Ibtlfmm!ojllj" ] - haskell](http://haskell.g.hatena.ne.jp/illillli/20090514/1242305123) 2009.5.14

# 謝辞

持ち上げやモナドスタックについては@ruicc先生よりご教示いただきました。

記事としてまとめていただきましたので、理解を深めたい方はご参照ください。

* [@ruicc](https://twitter.com/ruicc): [Haskell - モナドトランスフォーマーとその周辺 - Qiita](http://qiita.com/ruicc/items/7512c990a1835bba444a) 2015.2.4
