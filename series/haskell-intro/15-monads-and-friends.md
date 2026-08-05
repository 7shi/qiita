---
coediting: false
comments_count: 0
created_at: '2026-08-05T00:00:00+09:00'
id: ''
likes_count: 0
private: false
reactions_count: 0
stocks_count: 0
tags:
- name: Haskell
  versions: []
- name: モナド
  versions: []
- name: Functor
  versions: []
- name: Applicative
  versions: []
title: Haskell モナドとゆかいな仲間たち
updated_at: ''
url: ''
slide: false
---

Haskell ではモナドと呼ばれる部品を組み合わせてプログラムを作ります。今まで何度も手で書いてきた bind を `do` で使えるようにするのが `instance Monad` です。それを書こうとすると `Functor`・`Applicative` を先に書かされます。この階層をたどりながら、最後にモナドを自作します。

:::message
本記事の執筆には Claude Code (Opus 5) を利用しました。
:::

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
1. [Haskell モナド変換子 超入門](http://qiita.com/7shi/items/4408b76624067c17e933)
1. [Haskell 例外処理 超入門](http://qiita.com/7shi/items/73e534c47bbebc71b37e)
1. [Haskell 構文解析 超入門](http://qiita.com/7shi/items/b8c741e78a96ea2c10fe)
1. [Haskell 継続モナド 超入門](https://zenn.dev/7shi/articles/20260803-haskell-continuation-monad)
1. [Haskell 型クラス 超入門](https://zenn.dev/7shi/articles/20260805-haskell-type-classes)
1. **Haskell モナドとゆかいな仲間たち** ← この記事
1. 【予定】Haskell Freeモナド 超入門
1. 【予定】Haskell Operationalモナド 超入門
1. 【予定】Haskell Effモナド 超入門
1. 【予定】Haskell アロー 超入門

# 手で書いた bind の行き先

このシリーズは、モナドを説明するたびに読者へ bind を手で書かせてきました。リスト・`Maybe`・ST・State・Reader・Writer と、練習問題で `bind` と `return'` を実装した記憶があるかもしれません。👉[Haskell 状態系モナド 超入門](http://qiita.com/7shi/items/2e9bff5d88302de1a9e9)

State を扱う `bind` の解答例です。

```hs
a `bind` b = state $ \s ->
    let (r1, s1) = runState a s
        (r2, s2) = runState (b r1) s1
    in  (r2, s2)
return' x  = state $ \s -> (x , s)
```

きちんと動きますが、この `bind` を使うコードはバッククォートで演算子にした `bind` を並べて書く必要がありました。

```hs
fib x = (`evalState` (0, 1)) $
    (replicateM_ (x - 1) $
        get' `bind` \(a, b) -> put' (b, a + b)) `bind` \_ ->
    get' `bind` \v -> return' $ snd v
```

そして続く練習問題は「これを `do` と `<-` で書き直してください。ただし**再実装した関数は使わないでください**」という指示になっていました。自作した `bind` では `do` が使えないため、書き直すには標準の State モナドに戻るしかなかったのです。

`do` は `>>=` の糖衣構文です。自作の `bind` が `do` で使えないのは、`bind` という名前が `>>=` と違うからではなく、**その型に対して `>>=` の実装を登録していない**からです。その登録手続きが `instance Monad` です。

> 読者は bind を何度も自分で書いてきた。足りなかったのは、それを `do` で使えるようにする登録の仕組み、つまり `instance Monad` だった。

これが今回の記事の主張です。ゴールは自分の型に `instance Monad` を書いて、`do` で動かすことです。

## Monad のスーパークラス

型クラスは `class` で宣言し、`instance` で型ごとに実装します。`Monad` は標準ライブラリで宣言済みなので、書くのは `instance` だけです。👉[Haskell 型クラス 超入門](https://zenn.dev/7shi/articles/20260805-haskell-type-classes)

まず宣言を見ます。

```text:GHCi
ghci> :i Monad
type Monad :: (* -> *) -> Constraint
class Applicative m => Monad m where
  (>>=) :: m a -> (a -> m b) -> m b
  (>>) :: m a -> m b -> m b
  return :: a -> m a
  {-# MINIMAL (>>=) #-}
（略）
```

最小完全定義が `(>>=)` だけなので、実装するのは bind ひとつで済みます。シリーズでずっと使ってきた `>>=` が、こうして `class` のメソッドとして宣言されている姿は今回が初めてです。

問題は 1 行目の `class Applicative m => Monad m` です。`Applicative` がスーパークラスに指定されています。つまり `Monad` のインスタンスにするには、先に `Applicative` のインスタンスでなければなりません。

その `Applicative` も同じ形をしています。

```text:GHCi
ghci> :i Applicative
type Applicative :: (* -> *) -> Constraint
class Functor f => Applicative f where
  pure :: a -> f a
  (<*>) :: f (a -> b) -> f a -> f b
  liftA2 :: (a -> b -> c) -> f a -> f b -> f c
  (*>) :: f a -> f b -> f b
  (<*) :: f a -> f b -> f a
  {-# MINIMAL pure, ((<*>) | liftA2) #-}
（略）
ghci> :i Functor
type Functor :: (* -> *) -> Constraint
class Functor f where
  fmap :: (a -> b) -> f a -> f b
  (<$) :: a -> f b -> f a
  {-# MINIMAL fmap #-}
（略）
```

3 つ並べると階層になっています。

```hs:3つの宣言を並べたもの
class                  Functor f     where fmap  :: (a -> b) -> f a -> f b
class Functor f     => Applicative f where pure  :: a -> f a
                                           (<*>) :: f (a -> b) -> f a -> f b
class Applicative m => Monad m       where (>>=) :: m a -> (a -> m b) -> m b
```

どれも種が `* -> *` の型クラスです。`Maybe`・`[]`・`IO` のように型を 1 つ受け取る型でなければインスタンスにできません。

|型クラス|メソッド|できること|
|---|---|---|
|`Functor`|`fmap` (`<$>`)|中身に関数を適用する|
|`Applicative`|`pure`, `<*>`|引数が複数ある関数を適用する|
|`Monad`|`>>=`|前の結果を見て次を決める|

`<$>` と `<*>` は、シリーズの早い段階から Applicative スタイルとして**使って**きたものです。👉[Haskell アクション 超入門](http://qiita.com/7shi/items/85afd7bbd5d6c4115ad6)

それが `Functor`・`Applicative` という型クラスのメソッドであることは、これまで説明を先送りにしてきました。モナドを自作しようとすると、この 2 つを書かされることで否応なく回収されます。まず階層を下から順に見ていきます。

:::message
型クラスを自作した際の `Container` は、`wrap :: a -> f a` が `Applicative` の `pure`、`empty :: f a` が後述する `Alternative` の `empty` と同じ形をしています。あれは今回の階層の縮小版でした。
:::

# Functor

```hs:型
fmap :: Functor f => (a -> b) -> f a -> f b
```

`f a` の中身に関数 `a -> b` を適用して `f b` にします。`f` の構造そのものは変わりません。

一番分かりやすい入口はリストの `map` です。

```hs:型
map :: (a -> b) -> [a] -> [b]
```

`f` を `[]` に固定すると `fmap` の型と一致します。つまり `map` は `fmap` をリストに特殊化したものです。

```hs
main = do
    print $ map  (* 2) [1, 2, 3]
    print $ fmap (* 2) [1, 2, 3]
    print $ fmap (* 2) (Just 3)
    print $ fmap (* 2) (Nothing :: Maybe Int)
    print $ (* 2) <$> Just 3
    print =<< fmap (* 2) (return 3 :: IO Int)
```
```text:実行結果
[2,4,6]
[2,4,6]
Just 6
Nothing
Just 6
6
```

`Maybe` では `Just` の中身にだけ適用され、`Nothing` はそのままです。`IO` ではアクションの結果に適用されます。同じ `fmap` が型ごとに違う実装を選んでいるのがアドホック多相です。

`<$>` は `fmap` の演算子版で、`f <$> m` は `fmap f m` と同じです。

## liftM の正体

`<$>` は bind による再実装で説明したことがあります。👉[Haskell モナド変換子 超入門](http://qiita.com/7shi/items/4408b76624067c17e933)

```hs
f <$> m = do
    a <- m        -- モナドから値を取り出す
    return $ f a  -- 値を関数に適用してモナドに入れて返す
```

これは `Monad` の道具（`>>=` と `return`）だけを使って `Functor` の機能を書いたものです。標準ライブラリではこれが `liftM` という名前で用意されています。

```hs:型
liftM :: Monad m => (a -> b) -> m a -> m b
```

型クラス制約が `Functor` ではなく `Monad` になっているだけで、型も働きも `fmap` と同じです。実際に並べても結果は変わりません。

```hs
import Control.Monad (liftM)

f <$$> m = m >>= \a -> return (f a)  -- 上の再実装（<$> の名前を変えたもの）

main = do
    print $ (* 2) <$$> [1, 2, 3]
    print $ (* 2) <$>  [1, 2, 3]
    print $ liftM (* 2)  [1, 2, 3]
```
```text:実行結果
[2,4,6]
[2,4,6]
[2,4,6]
```

「`<$>` は `liftM` の演算子版で、同じ働き」と以前に述べた理由がこれです。`liftM` は `>>=` があれば機械的に書けるため、後でモナドを自作するときにそのまま使えます。

## Functor 則

`Functor` のインスタンスが守るべき規則が 2 つあります。

```hs
fmap id      == id
fmap (f . g) == fmap f . fmap g
```

「何もしない関数を適用すれば何も変わらない」「関数を合成してから適用しても、順に適用しても同じ」という意味です。要するに `fmap` は中身に関数を適用するだけで、構造をいじってはいけない、ということです。

コンパイラはこれを検査してくれません。`Semigroup` の結合法則と同じく、インスタンスを書く側が守るべき約束です。

:::message
`Functor` は数学の**関手**（functor）に由来する名前です。このシリーズは一貫して圏論には言及しない方針なので、名前の由来として触れるに留めます。
:::

## 練習

【問1】次の `main` が実行結果の通りになるように、`Pair` を `Functor` のインスタンスにしてください。

```hs
data Pair a = Pair a a deriving Show

-- ここに instance Functor Pair を書く

main = do
    print $ fmap (* 2) (Pair 1 2)
    print $ show <$> Pair 1 2
```
```text:実行結果
Pair 2 4
Pair "1" "2"
```

:::details 解答例
```hs
instance Functor Pair where
    fmap f (Pair x y) = Pair (f x) (f y)
```

2 つの要素それぞれに関数を適用します。`Pair` という構造自体は変わりません。`show <$> Pair 1 2` のように、適用する関数によって中身の型が `Int` から `String` へ変わる点にも注目してください。
:::

# Applicative

`fmap` で足りない場面から入ります。引数が 2 つある関数を `fmap` すると、途中で止まってしまいます。

```text:GHCi
ghci> :t (+) <$> Just 1
(+) <$> Just 1 :: Num a => Maybe (a -> a)
```

`Maybe` の中身 `1` を `(+)` に部分適用した結果、`Maybe` の中に関数 `a -> a` が入った状態になります。ここから先へ進むには「`f` に入った関数を、`f` に入った値に適用する」道具が要ります。それが `<*>` です。

```hs:型
(<*>) :: Applicative f => f (a -> b) -> f a -> f b
```

`fmap` との違いは、関数が `f` に入っているかどうかだけです。

```hs
main = do
    print $ (+) <$> Just 1 <*> Just 2
    print $ (+) <$> Just 1 <*> Nothing
    print $ (,) <$> [1, 2] <*> "ab"
    print $ Just 1 <* Just 2
    print $ Just 1 *> Just 2
```
```text:実行結果
Just 3
Nothing
[(1,'a'),(1,'b'),(2,'a'),(2,'b')]
Just 1
Just 2
```

最初の引数を `<$>` で渡し、2 番目以降を `<*>` で繋いでいくのが Applicative スタイルの形です。片方が `Nothing` なら全体が `Nothing` になり、リストなら全組み合わせが作られます。

末尾 2 行の `<*`・`*>` は、左右の両方を評価しながら、結果としては不等号が向いている側だけを残す演算子です。`<*` なら左の値、`*>` なら右の値が残ります。構文解析で括弧を読み飛ばすのに使いました。👉[Haskell 構文解析 超入門](http://qiita.com/7shi/items/b8c741e78a96ea2c10fe)

## Applicative スタイルの正体

リストモナドの説明で、Applicative スタイルには型クラス制約が要らないと述べたことがあります。👉[Haskell リストモナド 超入門](http://qiita.com/7shi/items/deb19c4cba933590ffbf)

これは「関数に渡されるのはモナドではなく素の値なので、関数側に `Monad m =>` を書かなくてよい」という意味でした。関数側には要りませんが、`<$>`・`<*>` を使う側には制約が付きます。それが `Functor f =>`・`Applicative f =>` です。

```hs
inc :: Int -> Int
inc = (+ 1)

add :: Int -> Int -> Int
add = (+)

viaFmap :: Functor f => f Int -> f Int
viaFmap m = inc <$> m

viaAp :: Applicative f => f Int -> f Int -> f Int
viaAp m n = add <$> m <*> n

main = do
    print $ viaFmap [1, 2]
    print $ viaFmap (Just 1)
    print =<< viaFmap (return 1)
    print $ viaAp [1] [2]
    print $ viaAp (Just 1) (Just 2)
```
```text:実行結果
[2,3]
Just 2
2
[3]
Just 3
```

`inc`・`add` は素の関数のままで、モナドのことを何も知りません。制約を負うのは `<$>`・`<*>` を使う `viaFmap`・`viaAp` の側です。`Monad f =>` ではなく `Functor f =>`・`Applicative f =>` で足りている点にも注目してください。必要な機能だけを要求できるのが、階層が分かれていることの実用上の利点です。

:::message
Applicative を直訳すれば「適用可能」で、「複数の引数が適用可能」という意味合いです。以前は詳細を省略していましたが、その中身が `<*>` を持つ型クラスというわけです。

この書き方については次の記事が参考になります。

* [@kazu_yamamoto](https://twitter.com/kazu_yamamoto): [Applicativeのススメ - あどけない話](http://d.hatena.ne.jp/kazu-yamamoto/20101211/1292021817) 2010.12.11
:::

## return と pure

`Applicative` のもう一つのメソッド `pure` は、値をモナドに入れる関数です。

```hs:型
pure   :: Applicative f => a -> f a
return :: Monad m       => a -> m a
```

シリーズでは `return` を使い倒してきました。この 2 つは制約が違うだけで、現在の GHC ではやることが同じです。

```hs
main = do
    print (pure   1 :: Maybe Int)
    print (return 1 :: Maybe Int)
    print (pure   1 :: [Int])
    print (return 1 :: [Int])
```
```text:実行結果
Just 1
Just 1
[1]
[1]
```

同じなら、なぜ 2 つあるのでしょうか。`:i Monad` をもう一度見ると答えが書いてあります。

```text:GHCi
class Applicative m => Monad m where
  (>>=) :: m a -> (a -> m b) -> m b
  return :: a -> m a
  {-# MINIMAL (>>=) #-}
```

`return` は `Monad` のメソッドとして残ってはいますが、最小完全定義は `(>>=)` だけです。つまり `return` にはデフォルト実装があり、その中身が `pure` です。歴史的な事情で `Monad` 側に残っているだけの別名だと思えば大きく外れません。

したがって**自作の型で実装すべきは `pure` の方**で、`return` は書きません。これは後でモナドを自作するときに直接効いてきます。

:::message
このシリーズは一貫して `return` 表記で通してきましたが、書き換える必要はありません。使う分にはどちらでも動きます。実装するときだけ `pure` を書く、と覚えておけば十分です。
:::

## 練習

【問2】問1 の `Pair` を `Applicative` のインスタンスにしてください。

```hs
data Pair a = Pair a a deriving Show

instance Functor Pair where
    fmap f (Pair x y) = Pair (f x) (f y)

-- ここに instance Applicative Pair を書く

main = do
    print $ (+) <$> Pair 1 2 <*> Pair 10 20
    print (pure 0 :: Pair Int)
```
```text:実行結果
Pair 11 22
Pair 0 0
```

`<*>` は左右の同じ位置どうしを組み合わせます。

:::details 解答例
```hs
instance Applicative Pair where
    pure x = Pair x x
    Pair f g <*> Pair x y = Pair (f x) (g y)
```

`<*>` は左の 1 番目の関数を右の 1 番目の値に、2 番目を 2 番目に適用します。`pure` は同じ値を 2 つ並べます。`Pair` は要素数が必ず 2 なので、リストのように長さが食い違う心配がありません。

`Functor` を書いた型に `Applicative` を足す、という手順そのものが、この記事で階層を下から積み上げていく流れの縮小版になっています。
:::

# Applicative と Monad の違い

階層が `Applicative` と `Monad` の 2 段に分かれているのはなぜでしょうか。両者の決定的な違いは、**前の結果を見て次の計算を決められるかどうか**です。

```hs
main = do
    print $ [1, 2, 3] >>= \x -> replicate x x
    print $ (,) <$> [1, 2] <*> [10, 20]
    print $ Just 1 >>= \x -> if x > 0 then Just (x * 2) else Nothing
```
```text:実行結果
[1,2,2,3,3,3]
[(1,10),(1,20),(2,10),(2,20)]
Just 2
```

1 行目の `>>=` では、`replicate x x` が作るリストの長さが `x` に依存しています。前の結果を受け取ってから次の計算を組み立てているので、結果の形は実行してみないと分かりません。

2 行目の `<*>` では、左右のリストの長さが 2 と 2 なので、結果が 4 要素になることが実行前に決まっています。`<*>` に渡す時点で両辺は完成しており、片方の中身を見てもう片方を作り替えることはできません。

3 行目の `Maybe` も同じです。`<*>` は「両方が `Just` なら適用する」だけですが、`>>=` は前の結果 `x` を見て `Just` を返すか `Nothing` を返すかを決めています。

この非対称は型に現れています。

```hs
(<*>) :: f (a -> b) -> f a -> f b
(>>=) :: m a -> (a -> m b) -> m b
```

`<*>` の第 2 引数は `f a` という完成した値ですが、`>>=` の第 2 引数は `a -> m b` という関数です。値を受け取ってから次を作る、という構造が型に書かれています。

## ap

`>>=` があれば `<*>` は書けます。`<$>` を `liftM` として書けたのと同じ要領です。👉[Haskell モナド変換子 超入門](http://qiita.com/7shi/items/4408b76624067c17e933)

```hs
mf <*> m = do
    f <- mf       -- モナドから関数を取り出す
    a <- m        -- モナドから値を取り出す
    return $ f a  -- 値を関数に適用してモナドに入れて返す
```

これが標準ライブラリの `ap` です。

```hs:型
ap :: Monad m => m (a -> b) -> m a -> m b
```

逆に `<*>` から `>>=` を作ることはできません。`<*>` が受け取れるのは `f (a -> b)`、つまり中身が既に決まった関数だけなのに対し、`>>=` が必要とするのは `a -> m b`、値を受け取ってから中身を組み立てる関数です。後者を前者の形に押し込む方法がありません。

作れる向きが一方通行であることが、`class Applicative m => Monad m` という階層の向きの根拠です。**モナドはアプリカティブより強い**わけです。

## ZipList

「`Applicative` にはなれるが `Monad` にはなれない」型が実際に存在します。標準ライブラリの `ZipList` がその代表です。

リストの `<*>` は全組み合わせを作りますが、`ZipList` は同じ位置どうしを組み合わせます。

```hs
import Control.Applicative

main = do
    print $ (+) <$> [1, 2, 3] <*> [10, 20, 30]
    print $ getZipList $ (+) <$> ZipList [1, 2, 3] <*> ZipList [10, 20, 30]
```
```text:実行結果
[11,21,31,12,22,32,13,23,33]
[11,22,33]
```

同じリストという型に対して 2 通りの `Applicative` の入れ方があるため、片方を `newtype` で包んで区別しているわけです。問2 の `Pair` の `<*>` と同じ形です。

この `ZipList` に `instance Monad` はありません。`<*>` と辻褄の合う `>>=` が書けないためです。試しにリストと同じ `>>=` を書いてみます。

```hs
import Control.Monad (ap)

newtype Zip a = Zip { getZip :: [a] }

instance Functor Zip where
    fmap f (Zip xs) = Zip (map f xs)

instance Applicative Zip where
    pure = Zip . repeat
    Zip fs <*> Zip xs = Zip (zipWith ($) fs xs)

-- リストと同じ >>= を書いてみる
instance Monad Zip where
    Zip xs >>= f = Zip (concatMap (getZip . f) xs)

main = do
    print          (getZip $ ((,) <$> Zip [1, 2])  <*>  Zip [10, 20])
    print $ take 4 (getZip $ ((,) <$> Zip [1, 2]) `ap` Zip [10, 20])
```
```text:実行結果
[(1,10),(2,20)]
[(1,10),(1,10),(1,10),(1,10)]
```

コンパイルは通りますが、`<*>` が返す `[(1,10),(2,20)]` と、同じ `>>=` から組み立てた `ap` の結果が食い違っています。しかも後者は無限リストになるため `take` で打ち切らないと止まりません。

`<*>` と `ap` が一致することはモナドが守るべき規則の 1 つです。この `Zip` は `>>=` を書けてはいますが、**`<*>` と整合する `>>=` にはなっていない**わけです。`ZipList` に `Monad` インスタンスが用意されていないのは、そういう `>>=` がそもそも存在しないからです。

:::message
`pure = Zip . repeat` が無限リストなのは、`ZipList` でも同じです。`pure x <*> ys` が `ys` と同じ長さになるためには、左辺が相手に合わせて伸びられる必要があるためです。
:::

# 階層は書かされる

準備が済んだので `instance Monad` を書きます。まず `Monad` だけを書いてみます。

```hs:NG
data Tree a = Leaf a | Node (Tree a) (Tree a) deriving Show

instance Monad Tree where
    Leaf x   >>= f = f x
    Node l r >>= f = Node (l >>= f) (r >>= f)
```
```text:エラー内容
    • No instance for ‘Applicative Tree’
        arising from the superclasses of an instance declaration
    • In the instance declaration for ‘Monad Tree’
```

`arising from the superclasses` と出ています。`Monoid` だけを書いて `Semigroup` を書き忘れたときと同じエラーです。`Monad` を名乗るには `Applicative`、ひいては `Functor` のインスタンスでなければなりません。

とはいえ `>>=` さえあれば `fmap` は `liftM`、`<*>` は `ap` で書けることは既に見ました。そこで次の定型が使えます。

```hs
import Control.Monad (liftM, ap)

instance Functor     Foo where fmap  = liftM
instance Applicative Foo where pure  = ...
                               (<*>) = ap
instance Monad       Foo where (>>=) = ...
```

自分で中身を書くのは `pure` と `>>=` の 2 つだけで、残りの 2 行は機械的に埋まります。本来は `Functor` から順に下から積み上げるべきところを、一番上の `>>=` さえあれば下の段は自動的に埋まる、という関係です。

:::message
ここで `return` を書いて `pure` を省略すると警告が出ます。

```text:警告
warning: [GHC-06201] [-Wmissing-methods]
    • No explicit implementation for
        ‘pure’
    • In the instance declaration for ‘Applicative Foo’

warning: [-Wnoncanonical-monad-instances]
    Noncanonical ‘return’ definition detected
    in the instance declaration for ‘Monad Foo’.
    ‘return’ will eventually be removed in favour of ‘pure’
    Either remove definition for ‘return’ (recommended) or define as ‘return = pure’
```

`return` は将来 `Monad` から取り除かれる予定だと書かれています。実装するのは `pure` の方だと述べたのはこのためです。
:::

継続モナドで `Cont` の bind を実装しましたが、あれもここで言う `>>=` の中身そのものです。👉[Haskell 継続モナド 超入門](https://zenn.dev/7shi/articles/20260803-haskell-continuation-monad)

:::message
`Monad` が `Applicative` をスーパークラスに持つようになったのは GHC 7.10（2015 年）からで、AMP（Applicative Monad Proposal）と呼ばれます。それ以前は `Monad` を `Applicative` と無関係に定義でき、`return` も `Monad` 自身のメソッドでした。

このシリーズの初期の回は AMP より前に書かれたもので、`Monad` と `Applicative` を別々のものとして扱っています。古い記事や書籍で両者の関係が説明されていないことがあるのは、多くがこの変更以前のものだからです。
:::

# モナドを自作する

## Identity

最小のモナドから始めます。`Identity` は中に値が入っているだけのモナドとして紹介済みです。👉[Haskell モナド変換子 超入門](http://qiita.com/7shi/items/4408b76624067c17e933)

既に知っている型に、初めて自分で `instance` を書くことになります。定型は使わず、3 つとも手で書きます。

```hs
newtype Identity a = Identity { runIdentity :: a }

instance Functor Identity where
    fmap f (Identity x) = Identity (f x)

instance Applicative Identity where
    pure = Identity
    Identity f <*> Identity x = Identity (f x)

instance Monad Identity where
    Identity x >>= f = f x

calc = do
    x <- return 3
    return (x * 2)

main = do
    print $ runIdentity (fmap (* 2) (Identity 3))
    print $ runIdentity ((+) <$> Identity 1 <*> Identity 2)
    print $ runIdentity calc
```
```text:実行結果
6
3
6
```

どのメソッドも `Identity` を剥がして中身を触り、また包み直しているだけです。

|メソッド|やっていること|
|---|---|
|`fmap`|中身に関数を適用して包み直す|
|`pure`|値を包む|
|`<*>`|関数と値を両方取り出して適用し、包み直す|
|`>>=`|中身を取り出して `f` に渡す（`f` の戻り値が既に `Identity`）|

`>>=` だけ包み直していないのは、渡される関数 `f` の戻り値が `Identity a` だからです。この型の違いが `<*>` と `>>=` を分けているものでした。

そして注目すべきは `calc` です。自分で書いたのは上の 3 つの `instance` だけですが、`do` と `return` がそのまま動いています。冒頭に挙げた「手で書いた `bind` では `do` が使えなかった」という問題は、これで解けました。

:::message
標準ライブラリにも `Data.Functor.Identity` として同じものがありますが、`Prelude` には入っていないため、import しない限り名前は衝突しません。
:::

## 練習

【問3】State モナドを自作してください。内部で持つ関数の型は `s -> (a, s)` です。

```hs
import Control.Monad (replicateM_)

newtype State s a = State { runState :: s -> (a, s) }

-- ここに instance Functor / Applicative / Monad を書く
-- get' と put' も書く

evalState m s = fst (runState m s)

fib x = (`evalState` (0, 1)) $ do
    replicateM_ (x - 1) $ do
        (a, b) <- get'
        put' (b, a + b)
    (_, b) <- get'
    return b

main = print $ fib 10
```
```text:実行結果
55
```

`>>=` は次の形になります。状態系モナドの練習で書いたものと同じです。

```hs
    m >>= k = State $ \s ->
        let (a, s1) = runState m s
        in  runState (k a) s1
```

`instance` の宣言では、型変数 `s` を残した `State s` の形で書きます。種が `* -> *` になっている必要があるためです。

:::details 解答例
```hs
instance Functor (State s) where
    fmap f m = State $ \s ->
        let (a, s1) = runState m s
        in  (f a, s1)

instance Applicative (State s) where
    pure x = State $ \s -> (x, s)
    mf <*> m = State $ \s ->
        let (f, s1) = runState mf s
            (a, s2) = runState m  s1
        in  (f a, s2)

instance Monad (State s) where
    m >>= k = State $ \s ->
        let (a, s1) = runState m s
        in  runState (k a) s1

get'   = State $ \s -> (s , s)
put' x = State $ \_ -> ((), x)
```

どのメソッドも「状態 `s` を受け取って、結果と新しい状態の組を返す関数」を組み立てています。状態を次へ次へと渡していくところが共通で、`fmap` は結果だけを加工し、`<*>` は左右を順に走らせてから適用し、`>>=` は左の結果を `k` に渡して右を組み立てます。

以前に書いた `bind`・`return'` を `>>=`・`pure` として登録し直しただけですが、それによって `do` と `<-` が使えるようになり、`fib` が普通のコードとして書けています。「再実装した関数は使わないでください」という制限は、もう必要ありません。
:::

## Tree

`Identity` と State は、どちらも「中に値と文脈を持つ入れ物」でした。データ構造そのものがモナドになる例も見ておきます。二分木です。

```hs
data Tree a = Leaf a | Node (Tree a) (Tree a) deriving Show
```

葉に値が入っています。`>>=` は「それぞれの葉を、別の木に差し替える」操作にします。接ぎ木だと思ってください。

ここでは前節の定型を使います。

```hs
import Control.Monad (liftM, ap)

data Tree a = Leaf a | Node (Tree a) (Tree a) deriving Show

instance Functor     Tree where fmap  = liftM
instance Applicative Tree where pure  = Leaf
                                (<*>) = ap
instance Monad       Tree where
    Leaf x   >>= f = f x
    Node l r >>= f = Node (l >>= f) (r >>= f)

grow x = Node (Leaf x) (Leaf (x * 10))

main = do
    let t = Node (Leaf 1) (Leaf 2)
    print $ fmap (* 2) t
    print $ t >>= grow
    print $ do { x <- t; grow x }
```
```text:実行結果
Node (Leaf 2) (Leaf 4)
Node (Node (Leaf 1) (Leaf 10)) (Node (Leaf 2) (Leaf 20))
Node (Node (Leaf 1) (Leaf 10)) (Node (Leaf 2) (Leaf 20))
```

`>>=` の中身は 2 行だけです。

* `Leaf x >>= f = f x` — 葉に来たら、その値を `f` に渡して得られた木で置き換える
* `Node l r >>= f = Node (l >>= f) (r >>= f)` — 枝は左右をそれぞれ辿る

`pure = Leaf` は「値 1 つだけの木」です。`fmap` と `<*>` は定型に任せましたが、`fmap (* 2) t` はちゃんと葉の値を 2 倍にしています。`liftM` が `>>=` と `return` から `fmap` を組み立てているためです。

最後の行は `>>=` を `do` で書いたものです。木というデータ構造が `do` で書けるようになりました。

## 練習

【問4】多分岐の木 `Rose` を `Monad` のインスタンスにしてください。枝が 2 本固定ではなくリストになっています。

```hs
import Control.Monad (liftM, ap)

data Rose a = Leaf a | Node [Rose a] deriving Show

-- ここに instance Functor / Applicative / Monad を書く

grow x = Node [Leaf x, Leaf (x * 10)]

main = do
    let r = Node [Leaf 1, Node [Leaf 2, Leaf 3]]
    print $ fmap (* 2) r
    print $ r >>= grow
```
```text:実行結果
Node [Leaf 2,Node [Leaf 4,Leaf 6]]
Node [Node [Leaf 1,Leaf 10],Node [Node [Leaf 2,Leaf 20],Node [Leaf 3,Leaf 30]]]
```

:::details 解答例
```hs
instance Functor     Rose where fmap  = liftM
instance Applicative Rose where pure  = Leaf
                                (<*>) = ap
instance Monad       Rose where
    Leaf x  >>= f = f x
    Node ts >>= f = Node (map (>>= f) ts)
```

`Tree` では左右の枝に個別に `>>=` を掛けていましたが、枝がリストになったので `map` でまとめて掛けます。`(>>= f)` はセクションで、「各枝に `>>= f` を適用する」と読めます。

定型を使わずに `fmap` を手で書くなら次のようになります。枝を辿るのに `map` が要るところが `>>=` と同じ形です。

```hs
instance Functor Rose where
    fmap f (Leaf x)  = Leaf (f x)
    fmap f (Node ts) = Node (map (fmap f) ts)
```
:::

# モナド則

自作した型が「本当にモナドか」を決めるのは、`instance Monad` が書けたことではなく、次の 3 つの規則を満たしていることです。

```hs
return x >>= f   == f x            -- 左単位元
m >>= return     == m              -- 右単位元
(m >>= f) >>= g  == m >>= (\x -> f x >>= g)  -- 結合法則
```

`Functor` 則や `Semigroup` の結合法則と同じく、コンパイラは検査してくれません。`ZipList` のところで見たように、規則を満たさないインスタンスも書けてしまいます。

モナド則については、このシリーズの番外編で図を使って説明しています。以前に「今回の範囲を超える」として先送りにした先がここです。

https://qiita.com/7shi/items/547b6137d7a3c482fe68

`Functor` や `Applicative` にも同じように規則があります。加えて、`Monad` のインスタンスには下の段と辻褄を合わせる約束もあり、その 1 つが「`<*>` は `ap` と一致すること」です。`Zip` の `>>=` が失格だった根拠がこれです。

# ゆかいな仲間たち

`Monad` の周りには、同じように `Functor`・`Applicative` を土台にした型クラスが並んでいます。よく目にするものを 3 つ取り上げます。

## Alternative

`<|>` は `Maybe` やパーサで使ってきました。「左が失敗したら右を試す」演算子です。👉[Haskell Maybeモナド 超入門](http://qiita.com/7shi/items/c7d7eec066af0fe0688d)

```text:GHCi
ghci> :i Alternative
type Alternative :: (* -> *) -> Constraint
class Applicative f => Alternative f where
  empty :: f a
  (<|>) :: f a -> f a -> f a
  some :: f a -> f [a]
  many :: f a -> f [a]
  {-# MINIMAL empty, (<|>) #-}
（略）
```

`Applicative` をスーパークラスに持ち、`empty` と `<|>` の 2 つが最小完全定義です。

```hs
import Control.Applicative

main = do
    print $ Just 1  <|> Just 2
    print $ Nothing <|> Just 2
    print $ (Nothing :: Maybe Int) <|> Nothing
    print (empty :: Maybe Int)
    print $ [1, 2] <|> [3]
    print (empty :: [Int])
```
```text:実行結果
Just 1
Just 2
Nothing
Nothing
[1,2,3]
[]
```

この 2 つの並びには見覚えがあるはずです。`Monoid` の `mempty` と `<>` です。

|`Monoid`|`Alternative`|
|---|---|
|`mempty :: a`|`empty :: f a`|
|`<>`（結合）|`<\|>`（選択）|

`Monoid` が `Int` や `String` のような型に対する「結合と単位元」だったのに対し、`Alternative` は `Maybe a` やパーサのような `f a` に対する「結合と単位元」です。以前 `Alternative` の説明で「正確には `Monoid` の知識が必要ですが、今回の範囲を超えるため詳細は省略します」と断ったのは、この対応のことでした。

`empty` が引数を持たず型注釈だけで実装が選ばれるところも `mempty` と同じです。型クラスを自作した際の `Container` の `empty` と同名なのは偶然ではありません。

:::message
古いコードでは同じ役割を `MonadPlus` の `mzero`・`mplus` が担っています。`MonadPlus` は `Monad` を要求するぶん制限が強く、現在は `Alternative` を使うのが標準です。パーサの記事で引用したツイートが述べていた通りです。👉[Haskell 構文解析 超入門](http://qiita.com/7shi/items/b8c741e78a96ea2c10fe)
:::

## Foldable

`sum`・`length`・`elem`・`mapM_` は、リスト専用の関数だと思っていたかもしれません。実際の型を見ると違います。

```hs:型
sum     :: (Foldable t, Num a) => t a -> a
length  :: Foldable t => t a -> Int
foldMap :: (Foldable t, Monoid m) => (a -> m) -> t a -> m
```

`Foldable` は「中身を順に取り出して畳み込める」型クラスです。最小完全定義は `foldMap` か `foldr` のどちらかで、`foldMap` の方は各要素を `Monoid` に変換して `<>` で繋ぐ、という形をしています。

自作の `Tree` に書いてみます。

```hs
import Data.Foldable (toList)

data Tree a = Leaf a | Node (Tree a) (Tree a) deriving Show

instance Foldable Tree where
    foldMap f (Leaf x)   = f x
    foldMap f (Node l r) = foldMap f l <> foldMap f r

t :: Tree Int
t = Node (Node (Leaf 1) (Leaf 2)) (Leaf 3)

main = do
    print $ sum t
    print $ length t
    print $ elem 2 t
    print $ maximum t
    print $ toList t
    mapM_ print t
```
```text:実行結果
6
3
True
3
[1,2,3]
1
2
3
```

書いたのは 2 行だけです。それだけで `sum`・`length`・`elem`・`maximum`・`toList`・`mapM_` が自作の木で動きます。左右を `<>` で繋ぐところで `Monoid` が効いており、どの `Monoid` になるかは `sum` なら和、`toList` ならリストの連結、と呼び出し側が決めます。

自作した型が標準関数の群に一気に繋がるところが、`instance` を書くことの一番分かりやすい見返りです。

:::message
`Foldable` の親戚に `Traversable` があります。`mapM` の正体で、`Foldable` が中身を取り出すだけなのに対し、構造を保ったまま各要素に計算を掛けて全体を組み直します。

```hs:型
traverse :: (Traversable t, Applicative f) => (a -> f b) -> t a -> f (t b)
mapM     :: (Traversable t, Monad m)       => (a -> m b) -> t a -> m (t b)
```

`traverse` の制約が `Applicative` で足りている点が要点です。要素ごとの計算が互いに依存しないため、`Monad` の力は要りません。
:::

## MonadFail

`do` の中では `<-` の左辺にパターンを書けます。そのパターンが失敗したときに呼ばれるのが `fail` です。

```text:GHCi
ghci> :i MonadFail
type MonadFail :: (* -> *) -> Constraint
class Monad m => MonadFail m where
  fail :: String -> m a
  {-# MINIMAL fail #-}
（略）
```

`Maybe` では `Nothing`、リストでは `[]` になります。

```hs
maybeHead :: [a] -> Maybe a
maybeHead xs = do
    (x:_) <- Just xs   -- 失敗すると fail が呼ばれる
    return x

listPairs :: [(Int, Int)] -> [Int]
listPairs ps = do
    (1, y) <- ps       -- 1 で始まる組だけ通る
    return y

main = do
    print $ maybeHead [1, 2, 3]
    print $ maybeHead ([] :: [Int])
    print $ listPairs [(1, 10), (2, 20), (1, 30)]
```
```text:実行結果
Just 1
Nothing
[10,30]
```

リストモナドで「パターンに合わない要素は落ちる」という書き方をしていたのは、`fail` が `[]` を返しているからです。`IO` では例外になります。

```hs:NG
main = do
    (x:_) <- return ([] :: [Int])
    print x
```
```text:実行結果（エラー）
FailIO.hs: user error (Pattern match failure in 'do' block at FailIO.hs:2:5-9)
```

かつて `fail` は `Monad` のメソッドでしたが、失敗の概念を持たないモナドにまで `fail` を強いることになるため、`MonadFail` として分離されました。自作のモナドでパターンマッチが失敗し得る `do` を書きたい場合だけ、追加でこのインスタンスを書きます。

# まとめ

`Monad` は 3 段の階層の一番上にあります。

|型クラス|メソッド|できること|
|---|---|---|
|`Functor`|`fmap` (`<$>`)|中身に関数を適用する|
|`Applicative`|`pure`, `<*>`|引数が複数ある関数を適用する|
|`Monad`|`>>=`|前の結果を見て次を決める|

下から順に強くなり、上の段は下の段を包含します。`>>=` があれば `fmap` は `liftM`、`<*>` は `ap` で埋まりますが、逆はできません。`ZipList` はその境界にいる実例でした。

`instance Monad` を書くのに必要なのは、実質 `pure` と `>>=` の 2 つだけです。そして書いた瞬間から `do`・`<-`・`return` に加え、`mapM_` や `forM` のような `Monad` を要求する既存の関数がすべて使えるようになります。`instance Foldable` を 2 行足せば `sum` や `length` まで繋がります。

シリーズを通して手で書いてきた bind は、こうして `do` の中へ収まりました。`Alternative`・`Foldable`・`MonadFail` といった仲間たちも、同じ「`instance` を書いて既存の道具に繋ぐ」という仕組みの上に載っています。

# 関連記事

モナドを自作するという同じことを F# のコンピュテーション式で行った記事です。`Bind` と `Return` を書けば `let!` が使えるようになる、という構図は、`>>=` と `pure` を書けば `do` が使えるようになるのと同じです。

http://qiita.com/7shi/items/026c7daa5b0b24d02c0f
