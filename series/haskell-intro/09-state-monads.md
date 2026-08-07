---
coediting: false
comments_count: 0
created_at: '2014-12-27T10:47:02+09:00'
id: 2e9bff5d88302de1a9e9
likes_count: 123
private: false
reactions_count: 0
stocks_count: 98
tags:
- name: JavaScript
  versions: []
- name: Haskell
  versions: []
title: Haskell 状態系モナド 超入門
updated_at: '2026-08-08T06:17:27+09:00'
url: https://qiita.com/7shi/items/2e9bff5d88302de1a9e9
slide: false
---

Haskellではモナドと呼ばれる部品を組み合わせてプログラムを作ります。状態を受け渡すタイプのモナドの使い方の初歩を説明します。ライブラリで用意されたモナドを手っ取り早く使うことを目的としているため、モナドの作り方や圏論には言及しません。

シリーズの記事です。

1. [Haskell 超入門](http://qiita.com/7shi/items/145f1234f8ec2af923ef)
1. [Haskell 代数的データ型 超入門](http://qiita.com/7shi/items/1ce76bde464b4a55c143)
1. [Haskell アクション 超入門](http://qiita.com/7shi/items/85afd7bbd5d6c4115ad6)
1. [Haskell ラムダ 超入門](http://qiita.com/7shi/items/1345bf32003faff435cb)
1. [Haskell アクションとラムダ 超入門](http://qiita.com/7shi/items/4a8a2807bb5186576c61)
1. [Haskell IOモナド 超入門](http://qiita.com/7shi/items/d3d3492ddd90d47160f2)
1. [Haskell リストモナド 超入門](http://qiita.com/7shi/items/deb19c4cba933590ffbf)
1. [Haskell Maybeモナド 超入門](http://qiita.com/7shi/items/c7d7eec066af0fe0688d)
1. **Haskell 状態系モナド 超入門** ← この記事
1. [Haskell モナド変換子 超入門](http://qiita.com/7shi/items/4408b76624067c17e933)
1. [Haskell 例外処理 超入門](http://qiita.com/7shi/items/73e534c47bbebc71b37e)
1. [Haskell 構文解析 超入門](http://qiita.com/7shi/items/b8c741e78a96ea2c10fe)
1. [Haskell 継続モナド 超入門](https://zenn.dev/7shi/articles/20260803-haskell-continuation-monad)
1. [Haskell 型クラス 超入門](https://zenn.dev/7shi/articles/20260805-haskell-type-classes)
1. [Haskell モナドとゆかいな仲間たち](https://zenn.dev/7shi/articles/20260807-haskell-monads-and-friends)
1. [Haskell Freeモナド 超入門](https://zenn.dev/7shi/articles/20260808-haskell-free-monad)
1. 【予定】Haskell Operationalモナド 超入門
1. 【予定】Haskell Effモナド 超入門
1. 【予定】Haskell アロー 超入門

練習の解答例は別記事に掲載します。

* [【解答例】Haskell 状態系モナド 超入門](http://qiita.com/7shi/items/fe978f1bd2d52760419d)

この記事には関連記事があります。

* [Stateモナドによるポーランド記法の処理](http://qiita.com/7shi/items/8bed38f45272f194631a)
* [Stateモナドによる逆ポーランド記法の処理](http://qiita.com/7shi/items/0494704d00396687458f)
* [Stateモナドによる中置記法の処理](http://qiita.com/7shi/items/ee5afe4f088f0a1fc8c2)

他の言語に応用した記事があります。

* [コンピュテーション式でモナドを作ってみる](http://qiita.com/7shi/items/026c7daa5b0b24d02c0f)
* [ジェネレーターで関数モナドとStateモナドを模倣してみた](https://qiita.com/7shi/items/e5365885fb53c015630c)
* [Pythonでもジェネレーターで関数モナドとStateモナドを模倣してみた](https://qiita.com/7shi/items/b3aba035c45868ab34e9)

# 状態系モナド

IOモナドは内部に隠された関数で状態を受け渡しています。他にも同様の構造を持つモナドがあり**状態系モナド**と呼ばれることがあります。

今回取り上げる状態系モナドは次の5つです。

* [STモナド](#st%E3%83%A2%E3%83%8A%E3%83%89)
* [Stateモナド](#state%E3%83%A2%E3%83%8A%E3%83%89)
* [Readerモナド](#reader%E3%83%A2%E3%83%8A%E3%83%89)
* [Writerモナド](#writer%E3%83%A2%E3%83%8A%E3%83%89)
* [関数モナド](#%E9%96%A2%E6%95%B0%E3%83%A2%E3%83%8A%E3%83%89)

※ 厳密な分類ではないため、人によって別の分類に含めるモナドもあります。

* [モナドの六つの系統[Functor x Functor] - モナドとわたしとコモナド](http://fumieval.hatenablog.com/entry/2013/06/05/182316)

# 破壊的代入

変数の値を変更することを**破壊的代入**と呼びます。`IORef`を使うことで破壊的代入を行うことができます。

```hs
import Data.IORef

main = do
    a <- newIORef 1
    writeIORef a 2         -- 破壊的代入
    print =<< readIORef a
```
```text:実行結果
2
```

`IORef`を使ってループで`sum`を再実装してみます。

```hs
import Control.Monad
import Data.IORef

sum' xs = do
    v <- newIORef 0          -- 初期値
    forM_ xs $ \i ->
        modifyIORef v (+ i)  -- 更新
    readIORef v

main = do
    print =<< sum' [1..100]
```
```text:実行結果
5050
```

IOモナドは正規の方法では外せないため、`IORef`を使うとIOモナドが付きまといます。これは破壊的代入が副作用として扱われるためです。

ここでの`sum'`はローカル変数に対して破壊的代入を行っていますが、その影響は関数の外部には及びませんし、戻り値は引数だけで決まっています。破壊的代入を関数の中に閉じ込めれば、関数の外での参照透過性は保てるのではないでしょうか。

# STモナド

STモナドは破壊的代入に特化したようなモナドです。STモナドを使えば破壊的代入を内部に閉じ込めて、計算結果だけを取り出すことができます。STは "state-transformer" の略です。

IOモナドの破壊的代入系の実装（`IORef`や`IOUArray`）に対応したSTモナド版の実装があります。

## STRef

`IORef`のSTモナド版です。

先ほどの`IORef`を使った例を`STRef`に書き換えてみます。

```hs
import Control.Monad
import Control.Monad.ST
import Data.STRef            -- ⇔ Data.IORef

sum' xs = runST $ do         -- runSTでSTモナドから値を取り出す
    v <- newSTRef 0          -- ⇔ newIORef
    forM_ xs $ \i ->
        modifySTRef v (+ i)  -- ⇔ modifyIORef
    readSTRef v              -- ⇔ readIORef

main = do
    print $ sum' [1..100]    -- 戻り値がモナドに包まれていない
```
```text:実行結果
5050
```

IOモナドを使った例とほとんど同じですが、最後に`runST`でSTモナドを外しています。これができることがIOモナドとの決定的な違いです。

## runST

```hs:型
runST :: (forall s. ST s a) -> a
```

STモナドから値を取り出す関数です。`forall s.`は`s`が具体的な型ではなく型変数のままであることを要求しています。詳細は後述します。

IOモナドでの`unsafePerformIO`に相当します。`unsafePerformIO`は使ってはいけないのに対して、`runST`は普通に使える関数です。

```hs
import Control.Monad.ST
import Data.STRef

main = do
    let a = do
        b <- newSTRef 1
        modifySTRef b (+1)
        readSTRef b
    print $ runST a         -- STモナドを外す
```
```text:実行結果
2
```

## 型表記

```hs
ST s a
```

* `s`: 状態を表す型です。通常は型変数のまま、具体的な型は指定しません。
* `a`: STモナドの中に含まれる値の型です。

IOモナドと同じように状態を受け渡しますが、それが型にも表れています。ただし何か具体的な型を指定しなくても、型変数のままで使えます。

```hs
import Control.Monad.ST

main = do
    let a = return 1 :: ST s Int  -- sは型変数のまま
    print $ runST a
```
```text:実行結果
1
```

### forall

`ST s a`の`s`に具体的な型を指定してしまうと`runST`が使えなくなります。

```hs:NG
import Control.Monad.ST
import Data.STRef

main = do
    let a = return 1 :: ST Int Int  -- ST s IntならOK
    print $ runST a                 -- エラー
```
```text:エラー内容
Couldn't match type `s' with `Int'
  `s' is a rigid type variable bound by
      a type expected by the context: ST s Int at src\Main.hs:6:13
Expected type: ST s Int
  Actual type: ST Int Int
（略）
```

※ `forall`は数学記号の∀に相当します。`forall`を指定することを[明示的な全称量化](http://www.kotha.net/ghcguide_ja/7.6.2/other-type-extensions.html)と呼びます。

## IOモナドとの関係

STモナドの`s`を`RealWorld`に固定すればIOモナドと相互変換できます。

* `ST RealWorld a` ⇔ `IO a`

つまりSTモナドを特殊化したものがIOモナドだと見なせます。

### 内部関数

STモナドもIOモナドと同じように内部に値を生成するための関数を持っています。それぞれの型を示します。
* `ST s a`の内部関数: `State# s         -> (# State# s        , a #)`
* `IO   a`の内部関数: `State# RealWorld -> (# State# RealWorld, a #)`

IOモナドが`s`に`RealWorld`を指定したSTモナドだということが分かります。

しかし型を明記していないだけで、実際はSTモナドも`State# RealWorld`で動きます。

```hs
{-# LANGUAGE UnboxedTuples #-}

import GHC.Base
import GHC.ST

unST (ST f) = f               -- STモナドからパターンマッチで内部関数を取り出す

main = IO $ \s ->
    let f1 = unST $ return 1  -- STモナドから内部関数を取り出す
        f2 = unIO $ print r1  -- IOモナドから内部関数を取り出す
        (# s1, r1 #) = f1 s   -- STモナドから取り出した内部関数を評価
        (# s2, r2 #) = f2 s1  -- IOモナドから取り出した内部関数を評価
    in  (# s2, r2 #)
```
```text:実行結果
1
```

`unIO`に相当する`unST`が用意されていないため自前で実装しています。

### realWorld# 

```hs:型
realWorld# :: State# RealWorld
```

任意の場所で使える`State# RealWorld`型の変数です。`runST`はIOモナドから状態を受け取っているわけではなく、`realWorld#`を使っています。

これを使って先の例を書き換えます。

```hs
{-# LANGUAGE MagicHash, UnboxedTuples #-}

import GHC.Base
import GHC.ST

unST (ST f) = f

main = do
    let f = unST $ return 1        -- STモナドから内部関数を取り出す
        (# _, a #) = f realWorld#  -- 内部関数をrealWorld#で評価
    print a                        -- 内部関数レベルの操作は不要
```
```text:実行結果
1
```

`main`を`do`で記述して`print`が普通に使えるようになりました。

### stToIO

```hs:型
stToIO :: ST RealWorld a -> IO a
```

STモナドからIOモナドに変換する関数です。

```hs
import Control.Monad.ST
import Data.STRef

main = do
    let a = return 1 :: ST s Int
    print =<< stToIO a            -- IOモナドに変換して値を取り出す
```
```text:実行結果
1
```

### ioToST

```hs:型
ioToST :: IO a -> ST RealWorld a
```

逆向きの変換関数`ioToST`もあります。

変換先は`ST RealWorld a`で`s`に具体的な型が指定されており`runST`は使えないため、STモナド経由でIOモナドを外すような抜け道は塞がれています。

## STUArray

`IOUArray`のSTモナド版です。

```hs
import Control.Monad
import Control.Monad.ST
import Data.Array.ST

main = do
    let arr = runST $ do
        a <- newArray (0, 5) 0 :: ST s (STUArray s Int Int)
        forM_ [0..5] $ \i ->
            writeArray a i i
        getElems a
    print arr
```
```text:実行結果
[0,1,2,3,4,5]
```

`arr`の作成過程で破壊的代入を使用していますが、何事もなかったかのように普通のリストとして取得できています。

## 練習

【問1】次のJavaScriptによるBrainf*ckの前処理をSTモナドで書き直してください。

```js:JavaScript
var bf = "+++++++++[>++++++++<-]>.";

var jmp = [];
for (var i = 0, loops = []; i < bf.length; ++i) {
    jmp[i] = 0;
    switch (bf[i]) {
    case '[':
        loops.push(i);
        break;
    case ']':
        var start = loops.pop();
        jmp[start] = i;
        jmp[i] = start;
        break;
    }
}
console.log(jmp);
```
```text:実行結果
[ 0, 0, 0, 0, 0, 0, 0, 0, 0, 21, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9, 0, 0 ]
```

⇒ [解答例](http://qiita.com/7shi/items/fe978f1bd2d52760419d#brainfck%E3%81%AE%E5%89%8D%E5%87%A6%E7%90%86)

【問2】STモナドを扱う`bind`と`return'`を実装してください。

具体的には次のコードが動くようにしてください。

```hs
main = do
    print $ runST $
        return' 1 `bind` newSTRef `bind` \a ->
        modifySTRef a (+1) `bind` \_ ->
        readSTRef a `bind` return'
```
```text:実行結果
2
```

⇒ [解答例](http://qiita.com/7shi/items/fe978f1bd2d52760419d#%E5%86%8D%E5%AE%9F%E8%A3%85)

# Stateモナド

IOモナドやSTモナドは内部に特殊な関数を持っており、関数に状態を渡すと更新後の状態と値がアンボックス化タプルで返って来ます。しかし通常の使い方ではその仕組みが表に出てくることはありませんし、積極的に触るようなものでもありません。

それに対してこれから紹介するStateモナドは次のような特徴を持っています。

* モナド内部に「状態を受け取って、値と更新後の状態を返す」関数があります。
* 状態は通常の型で、戻り値も通常のタプルです。
* 内部関数や状態の存在が隠されていません。

このようにStateモナドはSTモナドと同じような構造ですが、特殊な型は使わずに実装されており、内部仕様がオープンになっています。

※ これは普通とは逆の導入です。Stateモナドを先に説明して、その発展形としてSTモナドやIOモナドを導入するのが普通です。しかし今まで使ったことがないもので説明されても位置付けが分かりにくいと判断したため、この超入門シリーズではStateモナドより先にIOモナドやSTモナドを説明しました。

Stateモナドを見ることで、IOモナドやSTモナドを平易な実装で復習してみましょう。

## 型表記

```hs
State s a
```

* `s`: 状態を表す型です。型変数のままでも、具体的な型でも構いません。
* `a`: Stateモナドの中に含まれる値の型です。

使用するにはmtlパッケージが必要です。

```hs
import Control.Monad.State

a :: State s Int
a = return 1

main = return ()
```
```text:実行結果
（出力なし）
```

STモナドとよく似ています。

## runState

```hs:型
runState :: State s a -> s -> (a, s)
```

Stateモナドから値を取り出す関数です。

STモナドの`runST`に相当しますが、いくつか異なる点があります。

* 明示的に状態を渡す必要があります。
* 戻り値には状態が含まれます。
* タプル内の順番がSTモナドと逆です。（後述）

`return`で入れた値を取り出すだけであれば、状態は`()`でも構いません。

```hs
import Control.Monad.State

main = do
    let a = return 1 :: State s Int
    print $ runState a ()  -- ()は初期状態（必須）
```
```text:実行結果
(1,())
```

戻り値が普通のタプルで返されて、状態が含まれているのに注目してください。このように状態がオープンに扱われるのがSTモナドとの決定的な違いです。

### タプル

StateモナドとSTモナドでは値と状態を扱うタプルの仕様が異なります。

* Stateモナド: `(値, 状態)`（通常のタプル）
* STモナド: `(# 状態, 値 #)`（アンボックス化タプル）

タプル内の要素の順番が異なるのに注意が必要です。

### 片方だけを取得する関数

値だけ、状態だけ、を取得する関数もあります。

* 値だけ: `evalState :: State s a -> s -> a`
* 状態だけ: `execState :: State s a -> s -> s`

`runState`から片方を捨てているだけなので、やはり明示的に状態を渡す必要があります。

```hs
import Control.Monad.State

main = do
    let a = return 1 :: State s Int
    print $  runState a ()  -- (値, 状態)
    print $ evalState a ()  --  値
    print $ execState a ()  --      状態
```
```text:実行結果
(1,())
1
()
```

## 内部関数

```hs:型
s -> (a, s)
```

`runState`に状態を渡さずに部分適用したものが内部関数です。

※ 実際の内部関数はIdentityという別のモナドの中に入っています。詳細は続編で説明します。👉[モナド変換子](https://qiita.com/7shi/items/4408b76624067c17e933#identity%E3%83%A2%E3%83%8A%E3%83%89)

```hs
import Control.Monad.State

f :: () -> (Int, ())     -- 状態 → (値, 状態)
f = runState $ return 1  -- 部分適用により内部関数を取り出す

main = do
    let (a, _) = f ()    -- evalState相当
    print a
```
```text:実行結果
1
```

### IOモナドとの比較

StateモナドとIOモナドは基本的な構造が同じで、Stateモナドは一般的な型だけを使って実装されているのを確認してください。

```hs
{-# LANGUAGE MagicHash, UnboxedTuples #-}

import GHC.Base

f :: State# RealWorld -> (# State# RealWorld, Int #)
f = unIO $ return 1

main = do
    let (# _, a #) = f realWorld#
    print a
```
```text:実行結果
1
```

## state

```hs:型
state :: (s -> (a, s)) -> State s a
```

内部関数からStateモナドを作る関数です。

中に`1`を含むStateモナドを自作してみます。

```hs
import Control.Monad.State

main = do
    let m1 = return 1              -- 1が入ったモナド
        m2 = state $ \s -> (1, s)  -- m1と等価: 状態 -> (値, 状態)
    print $ runState m1 ()
    print $ runState m2 ()
```
```text:実行結果
(1,())
(1,())
```

タプルの順序が逆ですが、それ以外はIOモナドやSTモナドとほとんど同じです。

## Stateアクション

Stateモナドが受け渡している状態を、1つの破壊的代入が可能な変数だと見なして使うことが可能です。

そのためにStateモナド専用のアクションが用意されています。これをIOアクションと区別してStateアクションと呼びます。

* `get :: State s s`: 状態を読み取ります。
* `put :: s -> State s ()`: 状態を書き換えます。
* `modify :: (s -> s) -> State s ()`: 関数で状態を更新します。

簡単な例を示します。

```hs
import Control.Monad.State

test = do         -- 状態 -> (値, 状態)
    a <- get      -- runStateで渡された状態を取得
    put $ a + 1   -- 先に取得した状態+1を新しい状態に設定
    modify (* 2)  -- 状態に2を掛ける
    return a      -- 最初の状態を値として返す

main = do
    print $ runState test 5
```
```text:実行結果
(5,12)
```

空中から値を出し入れしているように見えますが、モナドがコンテキストを構成しています。

### sum

`modify`を使って`sum`を再実装してみます。ラムダ式を後に回すためセクションで引数の記述順をいじっています。

※ ``execState a b`` ⇔ ``a `execState` b`` ⇔ ``(`execState` b) a``

```hs
import Control.Monad
import Control.Monad.State

sum' xs = (`execState` 0) $ do  -- セクションで初期状態`0`を先に指定
    forM_ xs $ \i ->
        modify (+ i)            -- 状態を更新

main = do
    print $ sum' [1..100]
```
```text:実行結果
5050
```

先に示した`STRef`を使った実装よりシンプルですが、`do`のコンテキストとして状態が受け渡されていることを認識していないと、理解するのは困難です。

状態は破壊的代入が可能な1個の変数だと見なせますが、変数が複数必要な場合はタプルを使うなどの工夫が必要になります。そこまでするよりも、実用上は`STRef`を使った方が簡単です。

## アクションの定義

先頭の要素を取り出すアクション`getch`を定義して、それを使って3つの要素を取り出すアクション`get3`を定義する例です。

```hs
import Control.Monad.State

getch = do               -- 1文字取得するアクション
    x:xs <- get          -- 状態（リスト）を取得して分割
    put xs               -- 状態を更新
    return x             -- 先頭の要素を返す

get3 = do                -- 3文字取得するアクション
    x1 <- getch          -- 1番目の要素を取得
    x2 <- getch          -- 2番目の要素を取得
    x3 <- getch          -- 3番目の要素を取得
    return [x1, x2, x3]  -- 取得した要素を連結

main = do
    print $ evalState get3 "abcd"
```
```text:実行結果
"abc"
```

※ 文字が足りないとエラーになります。エラー処理は今回の範囲を超えるため、詳細は続編で説明します。👉[モナド変換子](https://qiita.com/7shi/items/4408b76624067c17e933#%E3%83%A2%E3%83%8A%E3%83%89%E3%82%B9%E3%82%BF%E3%83%83%E3%82%AF) 👉[例外処理](https://qiita.com/7shi/items/73e534c47bbebc71b37e#either%E3%83%A2%E3%83%8A%E3%83%89)

### モナドなしと比較

先ほどの例をStateモナドを使わずに定義します。

```hs
getch (x:xs) = (x, xs)       -- 状態 -> (値, 状態)

get3 s0 =                    -- 最初の状態
    let (x1, s1) = getch s0  -- 値と更新された状態
        (x2, s2) = getch s1  -- 値と更新された状態
        (x3, s3) = getch s2  -- 値と更新された状態
    in ([x1, x2, x3], s3)    -- (値, 状態)

main = do
    print $ fst $ get3 "abcd"
```
```text:実行結果
"abc"
```

明示的に状態を受け渡しています。アクションを使えば状態の受け渡しが暗黙的に行われるのと比較してください。

### 内部関数によるモナド化

`getch`をそのままStateモナドの中に入れてモナドを構築すれば、アクションを使って定義するよりも短くなります。`get3`はその手法でモナド化するよりも、アクションを使って記述した方が直感的でしょう。

```hs
import Control.Monad.State

getch = state getch where   -- 次の行で定義したgetchでモナドを構成
    getch (x:xs) = (x, xs)  -- モナドなしで定義したのと同じ関数

get3 = do                   -- 状態は自動処理されるので表に出ない
    x1 <- getch
    x2 <- getch
    x3 <- getch
    return [x1, x2, x3]

main = do
    print $ evalState get3 "abcd"
```
```text:実行結果
"abc"
```

この例が分かりやすいかは判断の分かれるところですが、`getch`のようなリーフ関数（アクション）は内部関数を直接記述した方が便利なこともあります。

## 練習

【問3】Stateモナドを扱う`bind`, `return'`, `get'`, `put'`を実装してください。

具体的には次のコードが動くようにしてください。

```hs
fib x = (`evalState` (0, 1)) $
    (replicateM_ (x - 1) $
        get' `bind` \(a, b) -> put' (b, a + b)) `bind` \_ ->
    get' `bind` \v -> return' $ snd v

main = do
    print $ fib 10
```
```text:実行結果
55
```

⇒ [解答例](http://qiita.com/7shi/items/fe978f1bd2d52760419d#%E5%86%8D%E5%AE%9F%E8%A3%85-1)

【問4】問3の`fib`を`do`と`<-`で書き直してください。問3で再実装した関数は使わないでください。

⇒ [解答例](http://qiita.com/7shi/items/fe978f1bd2d52760419d#%E6%9B%B8%E3%81%8D%E7%9B%B4%E3%81%97)

# Readerモナド

```hs:型表記
Reader r a
```

読み取り専用のStateモナドに相当します。明示的に状態の変更を禁止したいときに使います。

型変数`r`はReaderの頭文字ですが、状態を表します。

## ask

```hs:型
ask :: Reader r r
```

状態を読み取るReaderアクションです。

Stateアクションの`get`に相当します。アクションはモナドと紐付けられているため、`get`はReaderモナドでは使用できません。

## runReader

```hs:型
runReader :: Reader r a -> r -> a
```

Stateモナドの`runState`に相当する関数です。Readerモナドは状態が変更されないため、値しか返しません。

両者を並べて比較します。

```hs
import Control.Monad.State
import Control.Monad.Reader

main = do
    print $ (`runState` 1) $ do   -- State
        a <- get
        return $ a + 1
    print $ (`runReader` 1) $ do  -- Reader
        a <- ask                  -- getと同じ（モナドによる使い分け）
        return $ a + 1
```
```text:実行結果
(2,1)
2
```

## reader

```hs:型
reader :: (r -> a) -> Reader r a
```

関数からReaderモナドを作成します。Readerモナドでは状態は変化しないため、値だけを返す関数を渡します。

中に`1`を含むReaderモナドを自作してみます。

```hs
import Control.Monad.Reader

main = do
    let a = reader $ \_ -> 1  -- 状態は返さないため無視
    print $ runReader a ()
```
```text:実行結果
1
```

## local

```hs:型
local :: (r -> r) -> Reader r a -> Reader r a
```

別のReaderモナドに変更された状態を渡す関数です。元のReaderモナドのコンテキストには影響を与えません。Stateモナドの`modify`を限定的に行うのに相当します。

ネストで考えると分かりやすいです。

```hs
import Control.Monad.Reader

main = do
    print $ (`runReader` 1) $ do
        a <- ask                  -- 状態を確認
        b <- local (+ 1) $ do     -- ネスト
            b' <- ask             -- localによる(+ 1)が影響
            return b'
        c <- ask                  -- ネスト外では状態に変化はない
        return (a, b, c)
```
```text:実行結果
(1,2,1)
```

* `a`: 状態として1が渡されます。
* `b`: ネストしたモナドから結果を受け取ります。
    * `local`で状態に1を足して、ネストしたモナドに渡します。
    * `b'`: 状態を取得して、そのまま`return`で結果として渡します。
* `c`: 状態が変わっていないことを確認します。

## 練習

【問5】Readerモナドを扱う`bind`, `return'`, `ask'`, `local'`を実装してください。

具体的には次のコードが動くようにしてください。

```hs
test x = (`runReader` x) $
    ask' `bind` \a ->
    (local' (+ 1) $
        ask' `bind` \b' ->
        return' b') `bind` \b ->
    ask' `bind` \c ->
    return' (a, b, c)

main = print $ test 1
```
```text:実行結果
(1,2,1)
```

⇒ [解答例](http://qiita.com/7shi/items/fe978f1bd2d52760419d#%E5%86%8D%E5%AE%9F%E8%A3%85-2)

【問6】問5の`test`を`do`と`<-`で書き直してください。問5で再実装した関数は使わないでください。

⇒ [解答例](http://qiita.com/7shi/items/fe978f1bd2d52760419d#%E6%9B%B8%E3%81%8D%E7%9B%B4%E3%81%97-1)

# Writerモナド

```hs:型表記
Writer w a
```

追記専用のStateモナドに相当します。ログを取るのに便利です。

単なる書き込みではなく追記なのがポイントです。主にリストに追加して使います。

型変数`w`はWriterの頭文字で、状態を表します。

※ `w`には`Monoid`型クラス制約が掛かっていますが、今回の範囲を超えるため省略します。

## tell

```hs:型
tell :: w -> Writer w ()
```

状態に追記するWriterアクションです。

Stateアクションの`modify`に近いです。アクションはモナドと紐付けられているため、`put`や`modify`はWriterモナドでは使用できません。

## runWriter

```hs:型
runWriter :: Writer w a -> (a, w)
```

Stateモナドの`runState`に相当する関数です。初期状態は**空**だと決まっているため渡す必要はありません。

両者を並べて比較します。

```hs
import Control.Monad.State
import Control.Monad.Writer

main = do
    print $ (`runState` "") $ do  -- State
        modify (++ "a")           -- 追記
        modify (++ "b")           -- 追記
        modify (++ "c")           -- 追記
        return ()
    print $ runWriter $ do        -- Writer
        tell "a"                  -- 追記
        tell "b"                  -- 追記
        tell "c"                  -- 追記
        return ()
```
```text:実行結果
((),"abc")
((),"abc")
```

状態だけを返す`execWriter :: Writer w a -> w`もあります。

### 階乗

もう少し実用的な例を示します。

階乗を計算する過程のログを取ります。1つの文字列に追記するのではなく、文字列のリストに追記しているのがポイントです。

```hs
import Control.Monad.Writer

fact 0 = do
    tell ["fact 0 = 1"]
    return 1
fact n | n > 0 = do
    let dbg = "fact " ++ show n ++ " = " ++
              show n ++ " * fact " ++ show (n - 1)
    tell [dbg]
    n' <- fact (n - 1)
    let ret = n * n'
    tell [dbg ++ " = " ++ show n ++ " * " ++ show n' ++ " = " ++ show ret]
    return ret

main = do
    let (a, w) = runWriter $ fact 5
    putStr $ unlines w
    print a
```
```text:実行結果
fact 5 = 5 * fact 4
fact 4 = 4 * fact 3
fact 3 = 3 * fact 2
fact 2 = 2 * fact 1
fact 1 = 1 * fact 0
fact 0 = 1
fact 1 = 1 * fact 0 = 1 * 1 = 1
fact 2 = 2 * fact 1 = 2 * 1 = 2
fact 3 = 3 * fact 2 = 3 * 2 = 6
fact 4 = 4 * fact 3 = 4 * 6 = 24
fact 5 = 5 * fact 4 = 5 * 24 = 120
120
```

比較としてIOモナドによるデバッグを再掲します。👉[アクション](https://qiita.com/7shi/items/85afd7bbd5d6c4115ad6#%E3%83%87%E3%83%90%E3%83%83%E3%82%B0)

```hs
fact 0 = do
    putStrLn "fact 0 = 1"
    return 1
fact n | n > 0 = do
    let dbg = "fact " ++ show n ++ " = " ++
              show n ++ " * fact " ++ show (n - 1)
    putStrLn dbg
    n' <- fact (n - 1)
    let ret = n * n'
    putStrLn $ dbg ++ " = " ++ show n ++ " * " ++ show n' ++ " = " ++ show ret
    return ret

main = do
    print =<< fact 5
```

実行結果は同じです。

## writer

```hs:型
writer :: (a, w) -> Writer w a
```

タプルからWriterモナドを作成します。Writerモナドでは既存の状態を参照しないため、関数ではなくタプルとなっています。

中に`1`を含むWriterモナドを自作してみます。

```hs
import Control.Monad.Writer

main = do
    let a = writer (1, "")  -- 状態は使わないので何でも良い
    print $ runWriter a
```
```text:実行結果
(1,"")
```

※ 状態は文字列ではなくモノイドを対象とするため、この実装は本来の`return 1`とは異なります。モノイドについては今回の範囲を超えるため詳細は省略します。

## 練習

【問7】Writerモナドを扱う`bind`, `return'`, `tell'`を実装してください。

具体的には次のコードが動くようにしてください。

```hs
test = execWriter $
    tell' "Hello" `bind` \_ ->
    tell' ", "    `bind` \_ ->
    tell' "World" `bind` \_ ->
    tell' "!!"    `bind` \_ ->
    return' ()

main = print test
```
```text:実行結果
"Hello, World!!"
```

⇒ [解答例](http://qiita.com/7shi/items/fe978f1bd2d52760419d#%E5%86%8D%E5%AE%9F%E8%A3%85-3)

【問8】問7の`test`を`do`と`<-`で書き直してください。問7で再実装した関数は使わないでください。

⇒ [解答例](http://qiita.com/7shi/items/fe978f1bd2d52760419d#%E6%9B%B8%E3%81%8D%E7%9B%B4%E3%81%97-2)

# 関数モナド

関数もモナドとして扱えます。引数を状態として受け渡します。考え方はReaderモナドに似ています。

※ `a -> b`は`->`が関数モナドの型として定義されているため（`(->) a b`）、モナドとして扱えるようになっています。リストの`[]`が型としても使える（`[] a`）のと似ています。今回の範囲を超えるため詳細は省略します。

## 例

関数をbindしたものも関数のため、`do`ブロック全体で1つの関数が形成されます。そこに渡した引数が状態として受け渡され、含まれる関数に対して引数として渡されます。

```hs
test = do
    a <- (+ 1)     -- (+ 1) 5
    b <- (* 2)     -- (* 2) 5
    return (a, b)

main = do
    print $ test 5
```
```text:実行結果
(6,10)
```

## 練習

【問9】先ほどの例の`test`を通常の関数として書き直してください。

⇒ [解答例](http://qiita.com/7shi/items/fe978f1bd2d52760419d#%E9%96%A2%E6%95%B0%E3%83%A2%E3%83%8A%E3%83%89)

# まとめ

関数やアクションは主要なものを紹介しています。詳細はリンク先のリファレンスを参照してください。

* [STモナド](https://hackage.haskell.org/package/base-4.7.0.2/docs/Control-Monad-ST.html)
    * 関数
        * `runST`: → 値
        * `stToIO`: STモナド → IOモナド
        * `ioToST`: IOモナド → STモナド
    * アクション
        * [STRef](https://hackage.haskell.org/package/base-4.7.0.2/docs/Data-STRef.html): 破壊的代入が可能な変数
        * [STUArray](https://hackage.haskell.org/package/array-0.5.0.0/docs/Data-Array-ST.html): 破壊的代入が可能な配列
* [Stateモナド](https://hackage.haskell.org/package/mtl-2.2.1/docs/Control-Monad-State-Lazy.html)（読み書き）
    * 関数
        * `runState`: 状態 → (値, 状態)
            * `evalState`: 状態 → 値
            * `execState`: 状態 → 状態
        * `state`: 関数`s -> (a, s)` → Stateモナド
    * アクション
        * `get`: 読み
        * `put`: 書き
        * `modify`: 更新
* [Readerモナド](https://hackage.haskell.org/package/mtl-2.2.1/docs/Control-Monad-Reader.html)（読み）
    * 関数
        * `runReader`: 状態 → 値
        * `reader`: 関数`r -> a` → Readerモナド
    * アクション
        * `ask`: 読み
        * `local`: 別のReaderモナドに更新した状態を渡して評価
* [Writerモナド](https://hackage.haskell.org/package/mtl-2.2.1/docs/Control-Monad-Writer-Lazy.html)（追記）
    * 関数
        * `runWriter`: → (値, 状態)
            * `execWriter`: → 状態
        * `writer`: タプル`(a, w)` → Writerモナド
    * アクション
        * `tell`: 追記
* [関数モナド](https://hackage.haskell.org/package/base-4.7.0.2/docs/Control-Monad-Instances.html)

## オブジェクト指向との比較

状態系モナドにおける状態は、モナド内部の関数を直接触らないで`do`ブロックを書いているだけだとコードには表面上現れません。そのため状態の受け渡しでコンテキストが構成されているという感覚は、初めのうちは分かりにくいです。

Javaなどのオブジェクト指向言語では、明示的に定義しなくても`this`がインスタンスメソッドの中で使えます。インスタンスメンバへのアクセスには`this`が省略できるため、暗黙的なコンテキストであるとも見なせます。

状態系モナドの`do`ブロックに流れるコンテキストは、オブジェクト指向言語での`this`のようなものだと考えればイメージしやすいかもしれません。
