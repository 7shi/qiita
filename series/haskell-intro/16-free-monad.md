---
coediting: false
comments_count: 0
created_at: '2026-08-07T00:00:00+09:00'
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
- name: Freeモナド
  versions: []
- name: DSL
  versions: []
title: Haskell Freeモナド 超入門
updated_at: ''
url: ''
slide: false
---

Haskell ではモナドと呼ばれる部品を組み合わせてプログラムを作ります。**Free モナド**は `>>=` に意味を与えず、命令をデータとしてつなぐだけのモナドです。組み立てた手順書は後からインタプリタで解釈します。木構造の一般化として導入し、ジェネレーターを作って継続モナドと比較します。

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
1. [Haskell モナドとゆかいな仲間たち](https://zenn.dev/7shi/articles/20260807-haskell-monads-and-friends)
1. **Haskell Freeモナド 超入門** ← この記事
1. 【予定】Haskell Operationalモナド 超入門
1. 【予定】Haskell Effモナド 超入門
1. 【予定】Haskell アロー 超入門

# 木を一般化する

Free モナドは、既に書いたことのあるコードの中に隠れています。まずそれを見つけるところから始めます。

データ構造そのものをモナドにすることができます。葉に値が入っている二分木です。👉[モナドとゆかいな仲間たち](https://zenn.dev/7shi/articles/20260807-haskell-monads-and-friends#tree)

```hs
data Tree a = Leaf a | Node (Tree a) (Tree a)

instance Monad Tree where
    Leaf x   >>= f = f x
    Node l r >>= f = Node (l >>= f) (r >>= f)
```

`>>=` は「それぞれの葉を、別の木に差し替える」操作です。接ぎ木だと思ってください。

枝が 2 本固定ではなくリストになった多分岐の木でも、同じことができます。

```hs
data Rose a = Leaf a | Node [Rose a]

instance Monad Rose where
    Leaf x  >>= f = f x
    Node ts >>= f = Node (map (>>= f) ts)
```

2 つの `>>=` を並べます。

```hs
Leaf x   >>= f = f x                        -- Tree
Node l r >>= f = Node (l >>= f) (r >>= f)

Leaf x  >>= f = f x                         -- Rose
Node ts >>= f = Node (map (>>= f) ts)
```

葉の行は完全に同じです。違うのは枝の行だけで、それも「枝が抱えている木のそれぞれに `>>= f` を適用して、元の形に戻す」という同じことを、2 つ組とリストという別の入れ物に対して書いているだけです。

そして「中身のそれぞれに関数を適用して、元の形に戻す」のは `fmap` の仕事です。

## 枝の形をくくり出す

枝が木を抱える形だけを、型として抜き出します。`Tree` の枝は木を 2 つ持つので、次の型になります。

```hs
data Two x = Two x x
```

`Rose` の枝は木をリストで持ちます。リスト `[]` は最初から「型を 1 つ受け取る入れ物」なので、`Two` にあたる型を新しく定義する必要はなく、そのまま使えます。

これを使って 2 つの木を書き直すと、枝が「入れ物 1 つ」に揃います。

```hs
data Tree a = Leaf a | Node (Two (Tree a))
data Rose a = Leaf a | Node [Rose a]
```

`[Rose a]` は `[]` に `Rose a` を入れた形で、`Two (Tree a)` と同じ構造です。リストだけは `[] (Rose a)` とは書けない決まりなので見た目が揃いませんが、やっていることは同じです。

違いは `Two` と `[]` だけになりました。抜き出した「枝の形」を型引数 `f` にして、木を定義し直します。

```hs
data Free f a = Pure a | Free (f (Free f a))
```

コンストラクタが 2 つあるところは元の木と同じです。`Pure` が値を 1 つ持つ葉、`Free` が `f` という形で木を抱える枝です。`f` に `Two` や `[]` を入れると、元の木の枝に戻ります。

||`Free`|`f = Two`|`f = []`|
|---|---|---|---|
|葉|`Pure a`|`Pure a`|`Pure a`|
|枝|`Free (f (Free f a))`|`Free (Two (Free Two a))`|`Free [Free [] a]`|

値の側も含めて対応をまとめます。

|元の型|`Free` での書き方|
|---|---|
|`Tree a`|`Free Two a`|
|`Rose a`|`Free [] a`|
|`Leaf x`|`Pure x`|
|`Node l r`|`Free (Two l r)`|
|`Node ts`|`Free ts`|

枝の形が違うだけで、木としての骨組みは同じでした。その「枝の形」を型引数にくくり出したものが `Free` です。これが Free モナドの正体です。

## 種

`f` に入るのは `Two` や `[]` で、単独では型にならず、型を 1 つ受け取って初めて型になります。この「型の型」を**種**（kind）と呼びます。👉[型クラス](https://zenn.dev/7shi/articles/20260805-haskell-type-classes#%E5%9E%8B%E5%BC%95%E6%95%B0%E3%82%92%E5%8F%96%E3%82%8B%E5%9E%8B%E3%82%AF%E3%83%A9%E3%82%B9)

GHCi の `:k` で確認します。

```text:GHCi
ghci> :k Two
Two :: * -> *
ghci> :k Free
Free :: (* -> *) -> * -> *
ghci> :k Free Two
Free Two :: * -> *
ghci> :k Free Two Int
Free Two Int :: *
```

`Free` は `(* -> *)` を 1 つと `*` を 1 つ受け取ります。1 つ目が枝の形、2 つ目が葉に入る値の型です。`Free Two` まで与えると `* -> *` になり、`Monad` のインスタンスにできる種になります。

:::message
`Two` はタプルで済ませられそうにも見えますが、タプルは左右で別々の型が指定できるため、型変数を 2 つ取ります。

```text:GHCi
ghci> :k (,)
(,) :: * -> * -> *
```

`Two` に求められる `* -> *` とは種が違うので、そのままでは `f` に入りません。「左右が同じ型」という制約はタプルには書けないため、自分で定義する必要があります。
:::

## インスタンス

`Monad` を実装します。`>>=` さえ書けば `fmap` は `liftM`、`<*>` は `ap` で埋まる定型が使えます。👉[モナドとゆかいな仲間たち](https://zenn.dev/7shi/articles/20260807-haskell-monads-and-friends#3-%E6%AE%B5%E3%81%BE%E3%81%A8%E3%82%81%E3%81%A6%E6%9B%B8%E3%81%8F%E5%AE%9A%E5%9E%8B)

```hs
import Control.Monad (liftM, ap)

data Free f a = Pure a | Free (f (Free f a))

instance Functor f => Functor (Free f) where
    fmap = liftM

instance Functor f => Applicative (Free f) where
    pure  = Pure
    (<*>) = ap

instance Functor f => Monad (Free f) where
    Pure a >>= k = k a
    Free g >>= k = Free (fmap (>>= k) g)
```

`>>=` は 2 行です。元の木の `>>=` と見比べてください。

* `Pure a >>= k = k a` — 葉に来たら、その値を `k` に渡して得られた木で置き換える
* `Free g >>= k = Free (fmap (>>= k) g)` — 枝は `fmap` で中の木それぞれを辿る

`Tree` では左右を個別に書き、`Rose` では `map` で書いていたところが、`fmap` の 1 行にまとまりました。

その `fmap` は、枝の形 `f` に対して呼んでいます。つまり `f` が `Functor` のインスタンスでなければ、この行は書けません。そのため `instance` に `Functor f =>` という制約が付いています。`instance` 側に型クラス制約を書けることは既に見た通りです。👉[型クラス](https://zenn.dev/7shi/articles/20260805-haskell-type-classes#instance-%E5%81%B4%E3%81%AE%E5%88%B6%E7%B4%84)

逆に言えば、`Functor` が必要になるのはこの 1 か所だけです。Free モナドが枝の形に求めるのは「辿れること」だけで、それが `Functor` という形で現れています。

## 動かす

`Free Two` で木を組み立てて、元の `Tree` と同じことができるのを確認します。

`Two` の `Functor` インスタンスを書き、葉と枝を作る関数に名前を付けます。木の形を見るために、葉を値、枝を括弧で表示する `Show` インスタンスも書きます。上の `Free` の定義に続けて書きます。

```hs
data Two x = Two x x

instance Functor Two where
    fmap f (Two l r) = Two (f l) (f r)

type Tree = Free Two

instance Show a => Show (Tree a) where
    show (Pure a)         = show a
    show (Free (Two l r)) = "(" ++ show l ++ " " ++ show r ++ ")"

leaf :: a -> Tree a
leaf = Pure

node :: Tree a -> Tree a -> Tree a
node l r = Free (Two l r)

grow x = node (leaf x) (leaf (x * 10))

main = do
    let t = node (leaf 1) (leaf 2)
    print t
    print $ fmap (* 2) t
    print $ t >>= grow
```
```text:実行結果
(1 2)
(2 4)
((1 10) (2 20))
```

`grow` は葉の値 `x` を `x` と `x * 10` の 2 枚の葉に育てる関数です。`t >>= grow` で 2 枚の葉がそれぞれ育ち、その場所に小さな木が挿さっています。接ぎ木がそのまま動いています。

表示は `Show` インスタンスを手で書きました。`Free f a` に `deriving Show` は付けられません。中身を表示するには `f (Free f a)` が `Show` であることが必要ですが、`f` が型変数のままなので、その条件を `deriving` で書けないためです。`Free Two` のように `f` を固定すれば条件が決まるので、上のように `instance` を書けます。

`show` は本来、`read` で読み戻せる Haskell の式を返すのが建前です。`(1 2)` はそうなっていません。ここでは木の形が見やすいことを優先して、表示専用の形式にしています。

:::message
`Free Two a` のように型を固定した `instance` は、GHC2021 では書けますが、それ以前の標準（Haskell2010）では `FlexibleInstances` という言語拡張が必要となります。言語拡張はソースの先頭に `{-# LANGUAGE ~ #-}` と書きます。👉[IOモナド](https://qiita.com/7shi/items/d3d3492ddd90d47160f2#%E3%82%A2%E3%83%B3%E3%83%9C%E3%83%83%E3%82%AF%E3%82%B9%E5%8C%96%E3%82%BF%E3%83%97%E3%83%AB)

```hs
{-# LANGUAGE FlexibleInstances #-}
```
:::

`f` を `[]` に替えれば多分岐の木になります。`Free` と `Pure` をそのまま使うので、専用のコンストラクタは要りません。

```hs
type Rose = Free []

instance Show a => Show (Rose a) where
    show (Pure a)  = show a
    show (Free ts) = "[" ++ unwords (map show ts) ++ "]"

grow x = Free [Pure x, Pure (x * 10)]

main = do
    let r = Free [Pure 1, Free [Pure 2, Pure 3]]
    print r
    print $ r >>= grow
```
```text:実行結果
[1 [2 3]]
[[1 10] [[2 20] [3 30]]]
```

`Functor` インスタンスは 1 行も書き足していません。`[]` は最初から `Functor` なので、`Free []` はそれだけでモナドになります。書き足したのは表示のための `Show` だけです。

## 練習

【問1】自作した `Tree`（`Leaf`・`Node`）と `Free Two` が本当に同じものか、両方で同じ木を組み立てて `>>=` と `fmap` の結果を見比べてください。`Tree` の `Show` インスタンスを本文の `Free Two` 版と同じ形式で書けば、表示が揃って直接比べられます。

```hs
data Tree a = Leaf a | Node (Tree a) (Tree a)

instance Show a => Show (Tree a) where
    show = undefined  -- ここを書く

-- Tree 側
grow :: Int -> Tree Int
grow x = Node (Leaf x) (Leaf (x * 10))

-- Free Two 側
grow' :: Int -> Free Two Int
grow' x = Free (Two (Pure x) (Pure (x * 10)))

main = do
    let t  = Node (Leaf 1) (Leaf 2)
        t' = Free (Two (Pure 1) (Pure 2))
    print $ t  >>= grow
    print $ t' >>= grow'
    print $ fmap (* 2) t
    print $ fmap (* 2) t'
```
```text:実行結果
((1 10) (2 20))
((1 10) (2 20))
(2 4)
(2 4)
```

:::details 解答例
```hs
instance Show a => Show (Tree a) where
    show (Leaf a)   = show a
    show (Node l r) = "(" ++ show l ++ " " ++ show r ++ ")"
```

本文の `Free Two` 版と見比べてください。`Pure a` が `Leaf a` に、`Free (Two l r)` が `Node l r` に変わっただけで、右辺は同じです。パターンの名前が違うだけで、書くことがありません。

表示が一致するということは、`>>=` も `fmap` も同じ木を組み立てているということです。`Free Two` は `Tree` の別名でした。
:::

# 手順書を組み立てる

ここまで `f` は「枝の形」でした。ここで読み替えを行います。

`f` を命令の型だと思うと、`Free f a` は命令を並べたデータになります。枝が抱えていたのは「子の木」でしたが、命令だと思えば、それは「その命令の後に続く手順」です。木を辿ることが、手順を順に実行することに対応します。

この読み替えが Free モナドの使いどころです。題材としてジェネレーターを作ります。

## 命令の型

ジェネレーターは、値を 1 つ出してその場で中断し、呼び出し元が次を要求したら中断した位置から再開する仕組みです。継続モナドでは、中断した時点の「続き」を継続として捕まえ、出力する値と組にして持ち出すことで実現しました。👉[継続モナド](https://zenn.dev/7shi/articles/20260803-haskell-continuation-monad#%E3%82%B8%E3%82%A7%E3%83%8D%E3%83%AC%E3%83%BC%E3%82%BF%E3%83%BC)

Free モナドでは、続きを捕まえる仕掛けは要りません。命令の型に「続き」を置く場所を作っておけば、そこに続きが入ります。

```hs
data GenF o next = Yield o next
```

`Yield` は値を 1 つ出す命令です。`o` が出力する値の型、`next` が続きです。`Free (GenF o) a` の形で使うと、`next` の位置に後続の手順が入ります。

## Functor インスタンス

`Free` の `>>=` が `fmap` を使うので、`GenF o` を `Functor` にします。

```hs
instance Functor (GenF o) where
    fmap f (Yield o next) = Yield o (f next)
```

`fmap` が触るのは `next` だけです。出力する値 `o` は型引数の位置が違うので、そのまま残ります。

この実装は型の構造から機械的に決まります。「続きの位置に関数を適用する」以外に書きようがないからです。`deriving` が使えるのは型の構造から機械的に実装が決まるものだけでした。👉[型クラス](https://zenn.dev/7shi/articles/20260805-haskell-type-classes#deriving)

`Functor` はまさにそれに当てはまるため、`deriving` に書けます。

```hs
data GenF o next = Yield o next deriving Functor
```

これで `instance Functor` の 2 行が消えます。標準の `deriving` は 6 種類に限られていましたが、言語拡張で対象を増やせるということです。`Functor` を対象に加えるのは `DeriveFunctor` という言語拡張で、GHC2021 では既定で有効になっています。

:::message
Haskell2010 で試すときは `DeriveFunctor` を明示的に有効にします。

```hs
{-# LANGUAGE DeriveFunctor #-}
```
:::

## liftF

命令 1 つを `Free` の値に持ち上げる関数を用意します。

```hs
liftF :: Functor f => f a -> Free f a
liftF c = Free (fmap Pure c)
```

命令 `c` の続きの位置には、まだ `Free` ではない値が入っています。それを `fmap Pure` で `Pure` に包み、全体を `Free` で 1 段の木にします。「この命令 1 つを実行して終わり」という手順書ができます。

これを使ってスマートコンストラクタを書きます。

```hs
type Gen o = Free (GenF o)

yield :: o -> Gen o ()
yield x = liftF (Yield x ())
```

`Yield x ()` の `()` は続きの位置に置いた仮の値です。`liftF` がこれを `Pure ()` に変えるので、`yield x` は「`x` を出して終わり」という 1 命令の手順書になります。`Gen o ()` の `()` は、`do` で `<-` しても意味のある値は返らないことを表しています。

## 手順書を書く

ここまで来ると `do` が使えます。

```hs
count :: Gen Int ()
count = do
    yield 1
    yield 2
    yield 3
```

この `count` は何もしません。`do` で書いてあっても実行されるわけではなく、`count` の正体は次のデータです。

```hs
Free (Yield 1 (Free (Yield 2 (Free (Yield 3 (Pure ()))))))
```

`>>=` が命令をつないだ結果、`Yield` が 3 つ数珠つなぎになり、最後が `Pure ()` で終わっています。手順書がそのまま木として組み上がっています。

無限の手順書も組めます。組むだけなら終わらないということはありません。

```hs
nats :: Gen Int ()
nats = mapM_ yield [0 ..]
```

`mapM_` が使えるのは、`Gen o` が `Monad` のインスタンスだからです。モナドを自作すると `Monad` を要求する既存の関数がそのまま使えます。

ここまでで組み立ては完了ですが、まだ何の意味も与えていません。意味を与えるのは次の節です。

# インタプリタ

組み上がった手順書を辿って、実際の処理に変換する関数を**インタプリタ**と呼びます。

`Yield` の値を集めてリストにするインタプリタを書きます。

```hs
toList :: Gen o a -> [o]
toList (Pure _)           = []
toList (Free (Yield o k)) = o : toList k
```

* `Pure _` は手順書の終わりなので、空リスト
* `Free (Yield o k)` は「`o` を出して、続きは `k`」なので、`o` を先頭に付けて `k` を辿る

この形は初めてではありません。木を表示するために書いた `Show` インスタンスも、`Pure` と `Free` で場合分けし、`Free` の中を辿って 1 つの値にまとめていました。

```hs
show   (Pure a)           = show a                                 -- Free Two
show   (Free (Two l r))   = "(" ++ show l ++ " " ++ show r ++ ")"

toList (Pure _)           = []                                     -- Gen o
toList (Free (Yield o k)) = o : toList k
```

違うのは枝の形と、まとめ方だけです。インタプリタは特別な仕組みではなく、木を辿る関数に意味づけを載せたものです。

`Free` の定義に続けて、ここまでを通すと次のようになります。

```hs
liftF :: Functor f => f a -> Free f a
liftF c = Free (fmap Pure c)

data GenF o next = Yield o next deriving Functor

type Gen o = Free (GenF o)

yield :: o -> Gen o ()
yield x = liftF (Yield x ())

count :: Gen Int ()
count = do
    yield 1
    yield 2
    yield 3

count' :: Gen Int ()
count' = Free (Yield 1 (Free (Yield 2 (Free (Yield 3 (Pure ()))))))

nats :: Gen Int ()
nats = mapM_ yield [0 ..]

toList :: Gen o a -> [o]
toList (Pure _)           = []
toList (Free (Yield o k)) = o : toList k

main = do
    print $ toList count
    print $ toList count'
    print $ take 5 $ toList nats
```
```text:実行結果
[1,2,3]
[1,2,3]
[0,1,2,3,4]
```

`count` を手で組んだ `count'` と結果が一致しています。`do` が組み立てていたものが、確かにあのデータだったということです。

無限の手順書 `nats` にも `take 5` が効いています。`toList` は先頭から必要な分だけ木を辿るので、遅延評価がそのまま働きます。

## 継続で作った場合との違い

継続モナドで同じものを作ったときは、中断した位置から再開するために、取り出しておいた継続を `evalCont` で評価する必要がありました。

```hs:継続モナド版
loop (Yield v next) = print v >> loop (evalCont next)
loop Done = return ()
```

`next` に入っているのは継続、つまり呼び出して初めて先へ進む関数です。そのため取り出す側にも「評価して駆動する」という仕事がありました。

Free 版の `next` はデータです。既に組み上がっている木の続きがそこに入っているだけなので、インタプリタはパターンマッチで辿るだけで済みます。続きを作るのは `>>=` の仕事で、それが済んだ後の形を受け取っている、という違いです。

## `IO` と何が違うのか

`toList` は手順書を辿るだけで、`Yield` をどう扱うかを決めているのはインタプリタ側です。ということは、同じ `count` に別のインタプリタを当てれば、別のことが起きます。値を集める代わりに `print` すれば、`IO` で走らせるインタプリタになります（練習【問2】）。

ここが `IO` で直接書くのとの違いです。アクションは実行するためのものなので、`mapM_ print [1, 2, 3]` と書いてしまえば、あとは実行するしかありません。中身を覗くことも、別の意味に読み替えることもできません。👉[アクション](https://qiita.com/7shi/items/85afd7bbd5d6c4115ad6)

Free モナドで書いた `count` は、`do` の見た目こそアクションと同じですが、実体は検査できるデータです。

|やりたいこと|`IO` で書いた場合|Free で書いた場合|
|---|---|---|
|実行する|そのまま実行|`IO` 版インタプリタを当てる|
|結果を検査する|実行しないと分からない|`toList` で純粋な値として取れる|
|テスト用に差し替える|できない|モック用インタプリタを書く|
|ログを取る|処理に埋め込む|記録するインタプリタを書く|

手順書は 1 つ、解釈は複数。これが Free モナドの「組み立てと解釈の分離」です。

## 練習

【問2】上の `count` をそのまま使って、`Yield` の値を `print` していく `IO` 版のインタプリタ `runIO` を書いてください。手順書には手を触れないこと。

```hs
runIO :: Show o => Gen o a -> IO ()
runIO = undefined  -- ここを書く

main = do
    print $ toList count
    runIO count
```
```text:実行結果
[1,2,3]
1
2
3
```

:::details 解答例
```hs
runIO :: Show o => Gen o a -> IO ()
runIO (Pure _)           = return ()
runIO (Free (Yield o k)) = print o >> runIO k
```

`toList` と形がそっくりです。`[]` が `return ()` に、`o :` が `print o >>` に変わっただけで、木を辿る骨組みは同じです。

同じ `count` から、リストと `IO` という 2 つの結果が得られました。手順書を書き換えていないことが重要です。
:::

# テレタイプ

命令の種類を増やすと、DSL らしくなってきます。行の入出力を表す命令を作ります。

```hs
data TeletypeF next
    = PutLine String next
    | GetLine (String -> next)
```

`PutLine` は `Yield` と同じ形で、出力する文字列と続きを持ちます。`GetLine` は続きが関数になっています。読み込んだ文字列が決まらないと続きが決まらないためです。「文字列を受け取ったら続きを返す」という形で、続きを保留しています。

`Functor` インスタンスを手で書くと、この違いがはっきりします。

```hs
instance Functor TeletypeF where
    fmap f (PutLine s next) = PutLine s (f next)
    fmap f (GetLine k)      = GetLine (f . k)
```

`PutLine` は続きに `f` を適用するだけですが、`GetLine` は続きが関数なので、その結果に `f` を適用する形、つまり関数合成 `f . k` になります。`DeriveFunctor` はここも機械的に導出してくれます。

## 練習

【問3】`TeletypeF` を使って、`putLine`・`getLine'` のスマートコンストラクタと、次の `greet` が書けるようにしてください。`getLine'` の名前に `'` が付いているのは、標準の `getLine` と衝突を避けるためです。

```hs
data TeletypeF next
    = PutLine String next
    | GetLine (String -> next)
    deriving Functor

type Teletype = Free TeletypeF

putLine :: String -> Teletype ()
putLine = undefined  -- ここを書く

getLine' :: Teletype String
getLine' = undefined  -- ここを書く

greet :: Teletype ()
greet = do
    putLine "name?"
    name <- getLine'
    putLine ("Hello, " ++ name ++ "!")
```

:::details 解答例
```hs
putLine :: String -> Teletype ()
putLine s = liftF (PutLine s ())

getLine' :: Teletype String
getLine' = liftF (GetLine id)
```

`putLine` は `yield` と同じ形です。続きの位置に `()` を置いて `liftF` に渡します。

`getLine'` の `id` が要点です。`liftF` は続きの位置にある値を `Pure` で包むので、`GetLine id` は `GetLine (\s -> s)` を経て `GetLine (\s -> Pure s)` になります。読み込んだ文字列がそのまま `do` の結果になる、という意味です。型が `Teletype String` になっているのはこのためで、`greet` では `name <- getLine'` で受け取れます。
:::

【問4】【問3】の `greet` を `IO` を使わずに走らせる純粋インタプリタ `runPure` を書いてください。入力をリストで与え、出力をリストで集めます。入力が尽きたら空文字列を返すことにします。

```hs
runPure :: [String] -> Teletype a -> [String]
runPure = undefined  -- ここを書く

main = do
    mapM_ putStrLn $ runPure ["Haskell"] greet
    mapM_ putStrLn $ runPure ["世界"] greet
```
```text:実行結果
name?
Hello, Haskell!
name?
Hello, 世界!
```

:::details 解答例
```hs
runPure :: [String] -> Teletype a -> [String]
runPure _        (Pure _)             = []
runPure ins      (Free (PutLine s k)) = s : runPure ins k
runPure []       (Free (GetLine k))   = runPure [] (k "")
runPure (i : is) (Free (GetLine k))   = runPure is (k i)
```

第 1 引数が残りの入力です。`PutLine` は出力を先頭に付けて入力はそのまま渡し、`GetLine` は入力を 1 つ取り出して関数 `k` に渡します。`k i` を評価すると続きの手順書が得られるので、それを辿ります。

`IO` は一度も出てきません。それでも `greet` の振る舞いを、入力を与えて出力を確かめるという形で検査できています。テスト用のモックが、特別な仕掛けなしに書けるということです。

本物の `IO` で走らせたければ、同じ `greet` に別のインタプリタを当てます。

```hs
runIO :: Teletype a -> IO ()
runIO (Pure _)             = return ()
runIO (Free (PutLine s k)) = putStrLn s >> runIO k
runIO (Free (GetLine k))   = getLine >>= runIO . k
```
:::

# 「自由」とは何か

なぜ「Free」（自由）と呼ぶのかを説明します。

リストはモノイドです。`<>` で結合でき、単位元が `[]` です。👉[型クラス](https://zenn.dev/7shi/articles/20260805-haskell-type-classes#semigroup-%E3%81%A8-monoid)

```text:GHCi
ghci> [1, 2] <> [3]
[1,2,3]
```

このとき `[1] <> [2]` は `[1,2]` になるだけで、`3` にも `2` にもなりません。足し算や掛け算のような意味を持っていないからです。要素を並べて保持しているだけで、どう畳むかは後から `foldr` などで決められます。

このように「モノイド則だけを満たし、それ以上の性質を持たない」構造を**自由モノイド**と呼びます。リストがそれです。

Free モナドはこれのモナド版です。`>>=` は命令をつなぐだけで、何の意味も与えません。モナド則だけを満たし、それ以上の意味づけを持たないので、意味を後から選べます。意味を後から決められるのは、意味を持っていないからです。

|自由モノイド（リスト）|Free モナド|
|---|---|
|`<>` は要素を並べるだけ|`>>=` は命令をつなぐだけ|
|畳み方は `foldr` などで後から決める|意味はインタプリタで後から決める|
|`[1] <> [2]` は `3` にならない|`yield 1 >> yield 2` は何も出力しない|

比べてみると、これまでのモナドは意味を持っていました。`IO` なら実行され、`Maybe` なら失敗が伝播し、`State` なら状態が流れます。`>>=` でつないだ時点で何が起きるかが決まっていました。Free モナドはその決定を手放したモナドです。

こうした「ある性質だけを満たし、余計なものを持たない構造」を作ることを**自由生成**（free construction）と呼び、`Free` の名前はここから来ています。

# free パッケージ

ここまで `Free` を自分で定義してきましたが、実用では [free](https://hackage.haskell.org/package/free) パッケージを使います。`Control.Monad.Free` の定義は、本記事で書いたものとコンストラクタ名まで同じです。

```hs
data Free f a = Pure a | Free (f (Free f a))
```

`>>=` の実装も同じです。`Functor`・`Applicative` はパッケージ側では `liftM`・`ap` に頼らず直接書かれていますが、結果は変わりません。

インタプリタを書くための関数も用意されています。

|関数|型|用途|
|---|---|---|
|`liftF`|`f a -> Free f a`|命令 1 つを手順書にする|
|`foldFree`|`(forall x. f x -> m x) -> Free f a -> m a`|命令を 1 つずつ別のモナドへ変換する|
|`iterM`|`(f (m a) -> m a) -> Free f a -> m a`|続きが解釈済みの状態で 1 段ずつ潰す|

`foldFree` と `iterM` を使うと、`IO` 版インタプリタが 1 行で書けます。木を辿る再帰の部分をパッケージが持っているので、命令 1 つの扱い方だけを渡せば済みます。

```hs
import Control.Monad.Free

data GenF o next = Yield o next deriving Functor

type Gen o = Free (GenF o)

yield :: o -> Gen o ()
yield x = liftF (Yield x ())

count :: Gen Int ()
count = do
    yield 1
    yield 2
    yield 3

toList :: Gen o a -> [o]
toList (Pure _)           = []
toList (Free (Yield o k)) = o : toList k

runIO :: Show o => Gen o a -> IO a
runIO = foldFree $ \(Yield o next) -> print o >> return next

runIterM :: Show o => Gen o a -> IO a
runIterM = iterM $ \(Yield o next) -> print o >> next

main = do
    print $ toList count
    runIO count
    runIterM count
```
```text:実行結果
[1,2,3]
1
2
3
1
2
3
```

`foldFree` に渡す関数は `Yield o next` の `next` をそのまま返しているのに対し、`iterM` に渡す関数は `next` を `IO` として実行しています。`iterM` は続きを先に解釈してから渡すためで、この違いが型に出ています。

:::message
`free` は GHC に同梱されていないため、実行には導入が必要です。[Stack](https://docs.haskellstack.org/) を使う場合は次のように起動できます。

```
stack script --resolver lts-22.28 --package free ファイル名.hs
```
:::

## 性能の注意

`>>=` を左結合で重ねると遅くなります。

```hs
((yield 1 >> yield 2) >> yield 3) >> yield 4
```

`Free g >>= k` は枝を `fmap` で辿るので、左側に木が積み上がっていると、後ろに 1 つ足すたびに先頭から辿り直すことになります。リストの `++` を左結合で重ねると遅くなるのと同じ現象です。`do` で素直に並べれば右結合になるので、通常は問題になりません。

# まとめ

Free モナドは、木の枝の形を型引数にくくり出したものでした。

|木|`Free`|
|---|---|
|`Tree a`（枝は 2 つ組）|`Free Two a`|
|`Rose a`（枝はリスト）|`Free [] a`|
|`Leaf x`|`Pure x`|
|枝を辿る|`fmap` で辿る（だから `Functor` が要る）|

そして枝の形を命令の型と読み替えると、`Free f a` は命令を並べた手順書になります。

|段階|やっていること|
|---|---|
|命令の型|`data GenF o next = Yield o next`。`next` が続き|
|持ち上げ|`liftF` で命令 1 つを手順書にする|
|組み立て|`do` と `>>=` で命令をつなぐ。まだ何も起きない|
|解釈|インタプリタが手順書を辿って意味を与える|

`>>=` が意味を持たないので、意味を後から選べます。同じ手順書に別のインタプリタを当てれば、リストにも `IO` にもテスト用のモックにもなります。これが「組み立てと解釈の分離」です。

これまで扱ってきたモナドは、`>>=` でつないだ時点で何が起きるかが決まっていました。Free モナドはそこを空けておくことで、モナドを自作するのではなくモナドを作る型になっています。命令の型を書けば、その分だけ新しいモナドが手に入ります。

# 参考

* [free](https://hackage.haskell.org/package/free) — Free モナドのパッケージ
* [Control.Monad.Free](https://hackage.haskell.org/package/free/docs/Control-Monad-Free.html) — 本記事で書いた `Free` に対応するモジュール
