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

Haskell ではモナドと呼ばれる部品を組み合わせてプログラムを作ります。自作した型を `do` で使うには `Monad` 型クラスのインスタンスを実装する必要があり、そのためにスーパークラスの `Functor`・`Applicative` も求められます。この階層を順にたどってモナドを自作します。

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

# do を使うための型クラス

このシリーズは、モナドを説明するたびに bind を書く練習問題を出題してきました。👉[Haskell 状態系モナド 超入門](http://qiita.com/7shi/items/2e9bff5d88302de1a9e9)

State を扱う `bind` の解答例です。

```hs
a `bind` b = state $ \s ->
    let (r1, s1) = runState a s
        (r2, s2) = runState (b r1) s1
    in  (r2, s2)
return' x  = state $ \s -> (x , s)
```

きちんと動きますが、この `bind` は `do` ブロックで使うことはできないため、バッククォートで演算子にした `bind` を並べて書く必要がありました。

```hs
fib x = (`evalState` (0, 1)) $
    (replicateM_ (x - 1) $
        get' `bind` \(a, b) ->
        put' (b, a + b)) `bind` \_ ->
    get' `bind` \v ->
    return' $ snd v
```

`do` ブロック内のコードは `>>=` の連鎖に置き換えられますが、その `>>=` は `Monad` 型クラスのメソッドです。自作の型で `do` を使うには、`instance Monad` としてその型のインスタンスを宣言し、その中で `>>=` を実装する必要があります。

ただし `Monad` のインスタンスは単独では書けず、土台となる型クラスを先に実装しなければなりません。準備するものが多いため、まずは何が必要になるのかを `Monad` の宣言から確認します。

:::message
練習問題で `bind` を関数として自作してきたのは、その時点では型クラスを説明しておらず、インスタンスとして実装しようがなかったためです。
:::

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

最小完全定義が `(>>=)` だけなので、実装するのは bind ひとつで済みます。シリーズでずっと使ってきた `>>=` は、このように `class` のメソッドとして宣言されています。

問題は 1 行目の `class Applicative m => Monad m` です。`Applicative` がスーパークラスに指定されています。つまり `Monad` のインスタンスを実装するには、先に `Applicative` のインスタンスを実装しなければなりません。

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

`<$>` と `<*>` は、シリーズの早い段階から Applicative スタイルとして使ってきたものです。👉[Haskell アクション 超入門](http://qiita.com/7shi/items/85afd7bbd5d6c4115ad6)

それが `Functor`・`Applicative` という型クラスのメソッドであることは、これまで説明を先送りにしてきました。モナドを自作しようとすると、この 2 つを否応なく実装することになります。

:::message
タイトルの「ゆかいな仲間たち」は、`Functor` と `Applicative` を指しています。
:::

階層を下から順に見ていきます。

# Functor

```hs:定義（抜粋）
class Functor f where
    fmap :: (a -> b) -> f a -> f b
```

:::message
`Functor` は数学の**関手**（functor）に由来する名前です。今回の範囲を超えるため、詳細は省略します。
:::

メソッドは `fmap` ひとつです。使う側から見た型には型クラス制約が付きます。

```hs:型
fmap :: Functor f => (a -> b) -> f a -> f b
```

`f a` の中身に関数 `a -> b` を適用して `f b` にします。

ここで渡す `a -> b` は、`f` のことを何も知らない普通の関数です。`(* 2)` は `Maybe` も `IO` も知りませんし、知る必要もありません。`fmap` はその関数を `f` の中まで運び込んで、中身に作用させます。コンテナは `f` のままで、中身の型だけが `a` から `b` に変わります。

## 持ち上げ

中に値が 1 つ入っているだけの `Identity` で `fmap` を試します。👉[Haskell モナド変換子 超入門](http://qiita.com/7shi/items/4408b76624067c17e933)

```text:GHCi
ghci> import Data.Functor.Identity
ghci> double = (* 2) :: Int -> Int
ghci> double 3
6
ghci> fmap double (Identity 3)
Identity 6
```

`double` は `Identity` を知りませんが、`fmap` によって `Identity` の中で働いています。コンテナはそのままで、中身が `3` から `6` に変わりました。

関数だけを渡すと、このことが型にも表れます。

```text:GHCi
ghci> :t double
double :: Int -> Int
ghci> :t fmap double
fmap double :: Functor f => f Int -> f Int
```

`Int -> Int` だったものが `f Int -> f Int` になりました。数値を扱うだけだった関数が、`Functor` を扱う関数に変わっています。関数の方が `Functor` の世界へ引き上げられたわけです。これを**持ち上げ**（lift）と表現します。

`Identity` のインスタンスを自分で定義してみれば、持ち上げの様子がそのまま書き下せることが分かります。

```hs
instance Functor Identity where
    fmap f (Identity x) = Identity (f x)
```

左辺では関数 `f` が `Identity` の外にありますが、右辺では `Identity` の中に入っています。`fmap` は関数 `f` を持ち上げて、コンテナの中で作用させているわけです。

## アドホック多相

他のコンテナでも `fmap` を使ってみます。

```hs
main = do
    print $ fmap (* 2) (Just 3)
    print $ fmap (* 2) (Nothing :: Maybe Int)
    print =<< fmap (* 2) (return 3 :: IO Int)
    print $ fmap (* 2) [1, 2, 3]
    print $ (* 2) <$> Just 3
```
```text:実行結果
Just 6
Nothing
6
[2,4,6]
Just 6
```

`Maybe` では `Just` の中身にだけ適用され、`Nothing` は中身がないのでそのままです。`IO` ではアクションの結果に適用されます。どちらも `Just` は `Just` のまま、アクションはアクションのままで、中身の型だけが `a` から `b` に変わっています。アドホック多相により、同じ `fmap` が型ごとに違う実装を選んでいます。

リストの場合は中身が複数あるため、結果的に全要素へ適用されます。

```hs:型
fmap :: Functor f => (a -> b) -> f a -> f b
map  ::              (a -> b) -> [a] -> [b]
```

`f` を `[]` に固定すると `map` の型と一致します。つまり `map` は `fmap` をリストに特殊化したものです。ただし「多数の要素へ一斉に適用する」のはリストという構造から出てくる性質であって、`fmap` 自体の意味ではないことに注意してください。

`<$>` は `fmap` の演算子版で、`f <$> m` は `fmap f m` と同じです。

## liftM

「持ち上げ」は、モナド変換子で `lift` や `liftM` を扱ったときと同じ言い回しです。👉[Haskell モナド変換子 超入門](http://qiita.com/7shi/items/4408b76624067c17e933)

その `liftM` は標準ライブラリにある関数で、名前のとおりモナド（M）への持ち上げ（lift）です。

```hs
liftM :: Monad m => (a -> b) -> m a -> m b
liftM f m = do
    x <- m        -- モナドから値を取り出す
    return $ f x  -- 関数を適用してモナドに入れて返す
```

型クラス制約が `Functor` ではなく `Monad` になっていますが、`Monad` に対しては `fmap` と同じ結果が得られます。

```hs
import Control.Monad (liftM)

main = do
    print $ fmap  (* 2) [1, 2, 3]
    print $ liftM (* 2) [1, 2, 3]
```
```text:実行結果
[2,4,6]
[2,4,6]
```

同じ働きのものを `Monad` 専用として `>>=` と `return` で実装したということです。

:::message
`liftM` は制約が `Monad` であるため、`Monad` のインスタンスを持たない `Functor` には使えません。
:::

`liftM` は型クラスのメソッドではないため、型ごとに実装するものではなく、1 つの実装が `Monad` のインスタンスすべてに適用できます。

## Functor 則

`Functor` のインスタンスが守るべき規則が 2 つあります。

```hs
fmap id      == id               -- 単位元
fmap (f . g) == fmap f . fmap g  -- 準同型
```

式を == で区切り、両辺が等しくなることを要求しています。実際に評価する式ではありません。以降に出て来る規則もすべて同じ読み方です。

「何もしない関数を適用すれば何も変わらない」「関数を合成してから適用しても、適用してから合成しても同じ」という意味です。要するに `fmap` は中身に関数を適用するだけで、構造をいじってはいけない、ということです。

:::message
関数合成 `.` の側から見ると、`id` はその単位元です。1 つ目は単位元が単位元のまま持ち上がること、2 つ目は持ち上げても合成が崩れないことを要求しています。つまり `fmap` は、関数合成という構造を保つ**準同型**になっています。
:::

コンパイラはこれを検査してくれません。`Semigroup` の結合法則と同じく、インスタンスを書く側が守るべき約束です。

たとえば `Maybe` の `fmap` を次のように書いても、型は通ります。

```hs:NG
instance Functor Maybe where
    fmap _ (Just _) = Nothing
    fmap _ Nothing  = Nothing
```

しかしこれでは `fmap id (Just 1)` が `Nothing` になり、`fmap id == id` を破ります。コンパイラが検査しない以上こういうインスタンスも書けてしまいますが、これは Functor ではありません。

:::message
GHC が検査しないのは、関数が等しいかどうかの判定が一般には不可能で、証明を書く仕組みも言語に用意されていないためです。

検査させる試みはあります。Liquid Haskell は、法則を証明として書いて SMT ソルバで検査します。`quickcheck-classes` のように、法則を性質テストとして回すライブラリもあります。
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

`fmap` は 1 引数の関数を `f` の世界へ持ち上げました。引数が 2 つある関数を同じように持ち上げようとすると、途中で止まってしまいます。

```text:GHCi
ghci> :t (+) <$> Just 1
(+) <$> Just 1 :: Num a => Maybe (a -> a)
```

`Maybe` の中身 `1` を `(+)` に部分適用した結果、`Maybe` の中に関数 `a -> a` が入った状態になります。ここから先へ進むには「`f` に入った関数を、`f` に入った値に適用する」道具が要ります。それが `<*>` です。

```hs:型
fmap  :: Functor f     =>   (a -> b) -> f a -> f b
(<*>) :: Applicative f => f (a -> b) -> f a -> f b
```

違いは、関数が `f` に入っているかどうかだけです。`fmap` は外にある関数を持ち上げますが、`<*>` は既に `f` に入っている関数をそのまま使います。

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

リストモナドの説明で、Applicative スタイルでは型クラス制約を意識する必要がない、と述べたことがあります。👉[Haskell リストモナド 超入門](http://qiita.com/7shi/items/deb19c4cba933590ffbf)

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

`inc`・`add` は素の関数のままで、`f` のことを何も知りません。制約を負うのは `<$>`・`<*>` を使う `viaFmap`・`viaAp` の側です。`Monad f =>` ではなく `Functor f =>`・`Applicative f =>` で足りている点にも注目してください。必要な機能だけを要求できるのが、階層が分かれていることの実用上の利点です。

:::message
Applicative を直訳すれば「適用可能」で、「複数の引数が適用可能」という意味合いです。以前は詳細を省略していましたが、その中身が `<*>` を持つ型クラスというわけです。👉[Haskell モナド変換子 超入門](http://qiita.com/7shi/items/4408b76624067c17e933)

この書き方については次の記事が参考になります。

* [@kazu_yamamoto](https://twitter.com/kazu_yamamoto): [Applicativeのススメ - あどけない話](http://d.hatena.ne.jp/kazu-yamamoto/20101211/1292021817) 2010.12.11
:::

## return と pure

`Applicative` のもう一つのメソッド `pure` は、値を `f` に入れる関数です。

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
  (>>) :: m a -> m b -> m b
  return :: a -> m a
  {-# MINIMAL (>>=) #-}
```

`return` は `Monad` のメソッドとして残ってはいますが、最小完全定義は `(>>=)` だけです。つまり `return` にはデフォルト実装があり、その中身が `pure` です。歴史的な事情で `Monad` 側に残っているだけの別名だと思えば大きく外れません。

したがって自作の型で実装すべきは `pure` の方で、`return` は書きません。これは後でモナドを自作するときに直接効いてきます。

:::message
このシリーズは一貫して `return` 表記で通してきましたが、書き換える必要はありません。使う分にはどちらでも動きます。実装するときだけ `pure` を書く、と覚えておけば十分です。
:::

:::message
`Maybe` と `[]` を同じ形で扱うために自作した型クラス `Container` は、`wrap :: a -> f a` がこの `pure` と同じ形をしています。あれは今回の階層の縮小版でした。👉[Haskell 型クラス 超入門](https://zenn.dev/7shi/articles/20260805-haskell-type-classes)
:::

## Applicative 則

`Functor` 則と同じように、`Applicative` のインスタンスが守るべき規則もあります。こちらは 4 つです。

```hs
pure id <*> v              == v                  -- 恒等
pure f <*> pure x          == pure (f x)         -- 準同型
u <*> pure y               == pure ($ y) <*> u   -- 交換
pure (.) <*> u <*> v <*> w == u <*> (v <*> w)    -- 合成
```

恒等は「何もしない関数を適用しても変わらない」、準同型は「両方が `pure` なら、外で適用してから包んでも同じ」、交換は「値の側だけが `pure` なら左右を入れ替えても同じ」（`($ y)` は関数を受け取って `y` に適用する関数）、合成は「`<*>` を繋ぐ順序を変えても同じ」という意味です。要するに `<*>` は関数適用を `f` の中へ持ち込むだけで、順序や構造を勝手にいじってはいけない、ということです。

下の段との辻褄も要求されます。

```hs
fmap f x == pure f <*> x
```

`fmap` と `<*>` がばらばらの動きをしてはいけない、ということです。`Functor` 則と同じく、コンパイラはどれも検査してくれません。

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

# Monad

```hs:定義（抜粋）
class Applicative m => Monad m where
    (>>=) :: m a -> (a -> m b) -> m b
```

メソッドは実質 `>>=` ひとつです。では、階層が `Applicative` と `Monad` の 2 段に分かれているのはなぜでしょうか。両者の決定的な違いは、前の結果を見て次の計算を決められるかどうかです。

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

`fmap` と同じ働きの `liftM` が `>>=` と `return` で書けたように、`<*>` と同じ働きの関数も同じ道具立てで書けます。それが標準ライブラリの `ap` です。

```hs
ap :: Monad m => m (a -> b) -> m a -> m b
ap mf m = do
    f <- mf       -- モナドから関数を取り出す
    a <- m        -- モナドから値を取り出す
    return $ f a  -- 値を関数に適用してモナドに入れて返す
```

型クラス制約が `Applicative` ではなく `Monad` になっていますが、`Monad` に対しては `<*>` と同じ結果が得られます。`liftM` と `fmap` の関係がそのまま 1 段上でも成り立っています。

## モナド則

自作した型が「本当にモナドか」を決めるのは、`instance Monad` が書けたことではなく、次の 3 つの規則を満たしていることです。

```hs
return x >>= f   == f x                      -- 左単位元
m >>= return     == m                        -- 右単位元
(m >>= f) >>= g  == m >>= (\x -> f x >>= g)  -- 結合法則
```

`Functor` 則や `Semigroup` の結合法則と同じく、コンパイラは検査してくれません。規則を満たさないインスタンスも書けてしまいます。

### >=> で書き直す

上の 3 行にはコメントで左単位元・右単位元・結合法則と名前を付けましたが、`>>=` のままでは形が揃っておらず、特に 3 つ目は結合法則には見えません。演算子を替えると見え方が変わります。

`>=>` はモナドを返す関数同士を合成する演算子です。`Control.Monad` にあります。

```hs
(>=>) :: Monad m => (a -> m b) -> (b -> m c) -> a -> m c
(f >=> g) x = f x >>= g
```

`f` の結果はモナドに包まれているので、そのまま `g` に渡すことはできません。間に `>>=` を挟んで中身を取り出してから渡す、というのを 1 つの演算子にまとめたのが `>=>` です。普通の関数合成 `.` のモナド版で、向きが逆の `<=<` もあります。

これでモナド則を書き直します。先にモナド則を再掲します。3 つ目の関数名は後の都合で `g`・`h` に変え、ラムダ式の引数も `y` に変えます（意味は変わりません）。

```hs
return x >>= f  == f x
m >>= return    == m
(m >>= g) >>= h == m >>= (\y -> g y >>= h)
```

`>=>` は関数同士をつなぐ演算子なので、モナド `m` があると使えません。そこで `m` を「何らかの関数 `f` が値 `x` から作ったもの」と考えて `m = f x` と置きます。

```hs
return x >>= f    == f x
f x >>= return    == f x
(f x >>= g) >>= h == f x >>= (\y -> g y >>= h)
```

`関数 引数 >>= 関数` という形があちこちに現れました。これはちょうど `>=>` の定義の右辺です。左辺の形 `(f >=> g) x` に合わせます。

* `return x >>= f` → `(return >=> f) x`
* `f x >>= return` → `(f >=> return) x`
* `f x >>= g` → `(f >=> g) x`
* `\y -> g y >>= h` → `\y -> (g >=> h) y` → `g >=> h`（ポイントフリースタイル）

```hs
(return >=> f) x  == f x
(f >=> return) x  == f x
(f >=> g) x >>= h == f x >>= (g >=> h)
```

3 つ目は `(f >=> g)` と `(g >=> h)` をそれぞれ 1 つの関数と見れば、両辺にもう一度同じ書き換えが使えます。

```hs
((f >=> g) >=> h) x == (f >=> (g >=> h)) x
```

これで 3 つとも両辺が「`x` を引数に取る形」になったため、ポイントフリースタイルの要領で `x` を取り除きます。

```hs
return >=> f    == f                -- 左単位元
f >=> return    == f                -- 右単位元
(f >=> g) >=> h == f >=> (g >=> h)  -- 結合法則
```

`>=>` を掛け算だと思えば、`return` は `1` に当たります。モナド則は「`return` を単位元として、モナドを返す関数が `>=>` で結合的に合成できる」という要求だったことになります。

単位元を持ち結合法則を満たす構造は**モノイド**です。前回 `Semigroup` と `Monoid` で見たのと同じ形が、`<>` と `mempty` の代わりに `>=>` と `return` で現れています。👉[Haskell 型クラス 超入門](https://zenn.dev/7shi/articles/20260805-haskell-type-classes)

## ZipList

`Applicative` 則に `fmap f x == pure f <*> x` が付いていたのと同じように、`Monad` も `Applicative` と整合性を持つために `<*>` は `ap` と結果が一致する必要があります。

この約束を守れないために、「`Applicative` にはなれるが `Monad` にはなれない」型が存在します。標準ライブラリの `ZipList` がその代表です。

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

前節で見たとおり、`<*>` と `ap` が一致することはモナドが守るべき規則の 1 つです。この `Zip` は `>>=` を書けてはいますが、`<*>` と整合する `>>=` にはなっていないわけです。`ZipList` に `Monad` インスタンスが用意されていないのは、そういう `>>=` がそもそも存在しないからです。

:::message
`pure = Zip . repeat` が無限リストなのは、`ZipList` でも同じです。`<*>` は `zipWith` なので結果は短い方の長さになります。`pure x <*> ys` が `ys` と同じ長さになるには、`pure x` が `ys` の長さによらず足りている必要があるためです。
:::

# モナドを自作する

3 段の型クラスが揃ったので、実際にインスタンスを書いていきます。

## 階層は書かされる

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

`liftM` と `ap` の制約は `Monad` なので、この書き方ができるのは `Monad` のインスタンスでもある型に限られます。`Functor` や `Applicative` だけを実装したい型には使えません。

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

## Identity

最小の `Identity` モナドから始めます。`Functor` のインスタンスは持ち上げの説明で先に書きましたが、改めて全体を実装します。

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

どのメソッドも `Identity` の世界で関数を適用しています。

|メソッド|やっていること|
|---|---|
|`fmap`|外にある関数を持ち上げて適用する|
|`pure`|値を `Identity` の世界へ持ち上げる|
|`<*>`|既に持ち上がっている関数を適用する|
|`>>=`|中身を、`Identity` を返す関数 `f` に渡す|

`fmap` と `<*>` の違いは、適用する関数が持ち上がる前か後かだけです。`>>=` の右辺に `Identity` が現れないのは、渡される関数 `f` が最初から `Identity a` を返すためです。この型の違いが `<*>` と `>>=` を分けています。

そして注目すべきは `calc` です。自分で書いたのは上の 3 つの `instance` だけですが、`do` と `return` がそのまま動いています。冒頭で見た `bind` を並べ書きする問題は、`instance Monad` を書くことで解決しました。

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

以前に書いた `bind`・`return'` を `>>=`・`pure` として `instance` に書き直しただけですが、それによって `do` と `<-` が使えるようになり、`fib` が普通のコードとして書けています。「再実装した関数は使わないでください」という制限は、もう必要ありません。
:::

## Tree

`Identity` と State は、どちらも「中に値と文脈を持つ入れ物」でした。データ構造そのものがモナドになる例も見ておきます。二分木です。

```hs
data Tree a = Leaf a | Node (Tree a) (Tree a) deriving Show
```

葉に値が入っています。`>>=` は「それぞれの葉を、別の木に差し替える」操作にします。接ぎ木だと思ってください。

ここでは `liftM`・`ap` による定型を使います。

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

# まとめ

`Monad` は 3 段の階層の一番上にあります。

|型クラス|メソッド|できること|
|---|---|---|
|`Functor`|`fmap` (`<$>`)|中身に関数を適用する|
|`Applicative`|`pure`, `<*>`|引数が複数ある関数を適用する|
|`Monad`|`>>=`|前の結果を見て次を決める|

下から順に強くなり、上の段は下の段を包含します。`>>=` があれば `fmap` は `liftM`、`<*>` は `ap` で埋まりますが、逆はできません。`ZipList` はその境界にいる実例でした。

`instance Monad` を書くのに必要なのは、実質 `pure` と `>>=` の 2 つだけです。そして書いた瞬間から `do`・`<-`・`return` に加え、`mapM_` や `forM` のような `Monad` を要求する既存の関数がすべて使えるようになります。

シリーズを通して手で書いてきた bind は、こうして `do` の中へ収まりました。自作した型を `instance` で登録して既存の道具に繋ぐ、というのが型クラスの働きです。

# 関連記事

モナド則については、このシリーズの番外編で図を使って説明しています。

https://qiita.com/7shi/items/547b6137d7a3c482fe68

モナドを自作するという同じことを F# のコンピュテーション式で行った記事です。`Bind` と `Return` を書けば `let!` が使えるようになる、という構図は、`>>=` と `pure` を書けば `do` が使えるようになるのと同じです。

http://qiita.com/7shi/items/026c7daa5b0b24d02c0f

# 参考

モナド則の `>=>` での書き換えは、以下の記事を参考にしました。

https://qiita.com/tezca686/items/78d099987894ac7bec48

https://qiita.com/tezca686/items/73d135e372d547ad7266
