---
coediting: false
comments_count: 0
created_at: '2026-08-13T00:00:00+09:00'
id: ''
likes_count: 0
private: false
reactions_count: 0
stocks_count: 0
tags:
- name: Haskell
  versions: []
- name: 圏論
  versions: []
- name: CategoryTheory
  versions: []
- name: モナド
  versions: []
title: Haskell 圏論 超入門
updated_at: ''
url: ''
slide: false
---

Haskell の解説で圏論の名前を見かけることがありますが、このシリーズは一貫して圏論に言及せずに進めてきました。最終回となる今回では、コードから圏論の概念を眺めます。圏・関手・自然変換から「モナドは自己関手の圏におけるモノイド対象」まで、既に実装として通ってきたものに後から名前を与えていきます。

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
1. [Haskell Freeモナド 超入門](https://zenn.dev/7shi/articles/20260808-haskell-free-monad)
1. [Haskell Operationalモナド 超入門](https://zenn.dev/7shi/articles/20260809-haskell-operational-monad)
1. [Haskell Effモナド 超入門](https://zenn.dev/7shi/articles/20260811-haskell-eff-monad)
1. [Haskell アロー 超入門](https://zenn.dev/7shi/articles/20260813-haskell-arrow)
1. **Haskell 圏論 超入門** ← この記事

# 概要

このシリーズは「圏論には言及しない」という方針で書いてきました。理由は、既にあるモナドは圏論の知識がなくても使えるためです。通常のプログラミング言語と同様のアプローチで、書いて動かすことを優先しました。

最終回となる今回、初めて圏論に言及します。Haskell のコードから圏論の概念を眺めます。

|シリーズで書いたコード|圏論の名前|
|---|---|
|`class Category cat` の `id`・`.`|圏|
|`(->)` のインスタンス|Hask 圏|
|`Functor` とファンクター則|（自己）関手|
|`forall a. f a -> g a` の形のハンドラー|自然変換|
|`instance Category (Kleisli m)`|Kleisli 圏|
|`join` と `return`、モナド則|モノイド対象|
|`Free` の「モナド則だけを満たす」|自由生成・随伴|
|`instr :>>= k` に `Functor` が不要|Coyoneda・米田の補題|

どれも既に動かしたものです。新しく覚えることは、コードに付ける用語と、その用語が表す概念だけです。

Haskell のコードで書けるものはコードで書き、対象と射のレベルの話や同型のように、コードにすると不自然になるものだけを数式にします。

:::message
本記事は圏論の入門の入門です。数学的な厳密さより、Haskell との対応を優先します。圏論の一般論（極限や随伴の一般定義など）には立ち入らず、詳細は数学書に譲ります。
:::

# 圏

前回、`>>>` の土台にある `Category` 型クラスを見ました。👉[アロー](https://zenn.dev/7shi/articles/20260813-haskell-arrow#category)

```hs
class Category cat where
    id  :: cat a a
    (.) :: cat b c -> cat a b -> cat a c
```

これが圏の定義そのものです。

**圏**（category）は、対象と射の集まりに、射の合成と恒等射を備えたものです。`Category` の各部分がそのまま対応します。

|`Category`|圏論|
|---|---|
|型 `a`・`b`|**対象**（object）|
|`cat a b`|`a` から `b` への**射**（morphism, arrow）|
|`.`|射の**合成**（composition）|
|`id`|**恒等射**（identity morphism）|

対象は「点」、射は「点から点への矢印」だと思ってください。

一番イメージしやすいのは `(->)` です。対象が型、射が関数になります。`Int` から `Int` への射は `(+ 3)` のような関数で、合成は関数合成、恒等射は恒等関数です。次節で Hask として扱います。

ここで注意が必要なのは、射は関数とは限らないことです。`cat a b` が何であるかはインスタンスが決めます。

要求される性質は 2 つだけです。合成が結合的であること。

$$
(f \circ g) \circ h = f \circ (g \circ h)
$$

そして恒等射が合成の単位元であること。

$$
\mathrm{id} \circ f = f = f \circ \mathrm{id}
$$

前回、`(->)` について `id >>> f = f`・`f >>> id = f` を確認し、こう書きました。

> `Category` が `id` に求めているのはこの性質です。恒等関数であることが求められているわけではありません。

圏の言葉では、これが恒等射の定義です。恒等射とは、合成しても相手を変えない射のことであって、「何もしない関数」のことではありません。

## Hask 圏

Haskell そのものを圏とみなしたものを Hask と呼びます。対象は Haskell の型、射は関数です。

```hs
instance Category (->) where
    id x = x
    g . f = \x -> g (f x)
```

このインスタンスが Hask にあたります。合成は関数合成、恒等射は恒等関数です。`Int` から `String` への射とは `Int -> String` という型の関数のことで、その関数が何本あってもすべて別の射です。

シリーズで書いてきた関数はすべて Hask の射です。これから出てくる関手も自然変換も、Hask の上で考えます。

## bottom

Hask には避けて通れない問題があります。Haskell のすべての型は `undefined` と、停止しない計算を要素として持ちます。これらをまとめて **bottom**（$\bot$）と呼びます。

```hs
undefined :: Int
```

これは型検査を通ります。`Int` の値のつもりで扱えますが、評価すると停止しません。同じことが `Bool` でも `String` でも `Int -> Int` でも成り立ちます。

bottom があるだけなら「そういう値がある」で済みますが、`seq` があると話が変わります。`seq` は第 1 引数を弱頭正規形（WHNF）まで評価してから第 2 引数を返す関数で、bottom かどうかを外から観測できてしまいます。

```hs:Bottom.hs
main :: IO ()
main = do
    -- どの型にも undefined がある
    putStrLn (const "Int の undefined も型としては通る" (undefined :: Int))
    -- seq は「常に停止しない関数」と「停止しない値」を区別する
    seq (\_ -> undefined :: Int) (putStrLn "\\_ -> undefined は WHNF")
    -- fmap id == id が (->) で破れる
    seq (fmap id bot) (putStrLn "fmap id bot は id . bot なのでラムダ")
    seq (id bot) (putStrLn "ここには来ない")
  where
    bot = undefined :: Int -> Int
```

```text:実行結果
Int の undefined も型としては通る
\_ -> undefined は WHNF
fmap id bot は id . bot なのでラムダ
Bottom.hs: Prelude.undefined
CallStack (from HasCallStack):
  undefined, called at Bottom.hs:11:11 in main:Main
```

最後の 2 行が問題です。関数の `fmap` は `.` なので、`fmap id bot` は `id . bot` になります。これはラムダ式なので、中身を呼ばない限り停止します。一方 `id bot` は `bot` そのものなので停止しません。

どんな引数を与えても両者の結果は同じです。それでも `seq` は両者を区別します。つまり `fmap id` と `id` は、関数としては同じでも `seq` の下では別物です。後で見るファンクター則の 1 つ目が、この意味で破れています。

圏を作るには「2 つの射が等しい」ことがはっきり決まる必要がありますが、`seq` はその判定を壊します。そのため Hask は、厳密には圏になりません。

:::message
これは知られた問題で、Hask を圏として扱う議論はたいてい「bottom と `seq` を無視する」という前提を置いています。無視すれば対応はきれいに取れますし、実際のコードでも `seq` を使わなければ困りません。

無視してよい理由には裏付けもあります。「甘い推論は道徳的に正しい」（Fast and Loose Reasoning is Morally Correct）という標語で知られる結果があり、bottom を無視して導いた等式は、条件を満たせば bottom がある世界でも成り立つことが示されています。
:::

以降、bottom は無視します。ただし、無視していることは覚えておいてください。

## 一点圏

Hask の射は関数でしたが、圏一般では射が関数とは限りません。関数でない例を作ってみます。

出発点は Hask です。`(+ 3)` と `(+ 4)` を合成すると、7 を足す関数になります。

```hs:GHCi
ghci> ((+ 3) . (+ 4)) 0
7
ghci> ((+ 3) . (+ 4)) 10
17
```

合成の結果を決めているのは 3 と 4 という数だけです。関数の形を捨てて数だけを残しても、同じことができそうに見えます。

型クラスの回で扱ったモノイドは、単位元 `mempty` を持ち、`<>` で結合でき、結合法則を満たす型でした。👉[型クラス](https://zenn.dev/7shi/articles/20260805-haskell-type-classes#semigroup-と-monoid)

`Int` そのものは `Monoid` ではありません。加算も乗算もモノイドですが、一方に決められないためです。`Data.Monoid` には、ラッパーが用意されています。加算にあたるのが `Sum` です。

```hs:GHCi
ghci> import Data.Monoid
ghci> Sum 3 <> Sum 4
Sum {getSum = 7}
ghci> mempty :: Sum Int
Sum {getSum = 0}
```

`Sum 3 <> Sum 4` が `Sum 7` になるのは、`(+ 3) . (+ 4)` が 7 を足す関数になるのに対応します。関数だったものが `Sum Int` というただの値に、合成が `<>` に置き換わっています。単位元 `Sum 0` が、何も足さない関数にあたります。

圏に求められるのも単位元と結合法則でした。モノイドはそれを満たすので、そのまま `Category` のインスタンスとして書けます。既存の `Monoid` との名前衝突を回避するため、ここでは型名を `Mono` とします。

```hs:Mono.hs
import Control.Category
import Data.Monoid (Sum(..))
import Prelude hiding ((.), id)

newtype Mono m a b = Mono m deriving (Show, Eq)

instance Monoid m => Category (Mono m) where
    id = Mono mempty
    Mono g . Mono f = Mono (f <> g)
```

`id` の実体が `mempty`、`.` の実体が `<>` です。インスタンスになっているのは `Mono` ではなく `Mono m` で、モノイドを 1 つ決めて初めて圏になります。

`Mono m a b` の `a`・`b` は右辺に現れません。このように使われない型引数を**幽霊型**（phantom type）と呼びます。射の中身は `m` の値だけで、数を扱う `Int` も `m` に入れる `Sum Int` が持っているため、`a`・`b` が持つものは何もありません。`(+ 3)` を `Sum 3` に置き換えたぶん、関数の面影が消えています。

その `a`・`b` が対象にあたります。持つものが何も無いので、ここでは空であることを表す `()` を入れます。どの射も `()` から `()` へ向かうことになり、結果として対象が 1 つの圏になります。加算のモノイドなら射の型は `Mono (Sum Int) () ()` で、`(->)` の型と並べてみます。

```hs
--              cat            a   b
     (+   3) :: (->)           Int Int
Mono (Sum 3) :: Mono (Sum Int) ()  ()
```

`Int` の位置が動いていることに注意してください。`(->)` の側では対象でしたが、`Mono` の側では `cat` が指す `Mono (Sum Int)` の中にあります。同じ `Int` が、`(->)` の側では対象、`Mono` の側では射を決める型の一部として働いています。

|`cat a b`|`(->) Int Int`|`Mono (Sum Int) () ()`|
|---|---|---|
|対象|`Int`|`()`|
|射（例）|`(+ 3)`|`Mono (Sum 3)`|
|合成|関数合成|`<>`|
|恒等射|恒等関数|`Mono (Sum 0)`|

射はどちらも矢印の両端が同じ対象なので、どの射とどの射でも合成できます。違いは射の集まりで、左は `Int -> Int` の関数すべて、右はそのうち「n を足す」ものだけにあたります。

:::message
`()` を入れるのはここでの取り決めです。`a`・`b` には何でも入るので、`Mono (Sum Int) Bool Char` のような型も通ります。それでも射の中身は `Sum Int` の値のままで変わりません。
:::

これで `Mono (Sum Int)` という圏が 1 つできました。単位元と結合法則は、モノイド則がそのまま保証します。`Mono` の定義が使っているのは `mempty` と `<>` だけで、`Sum` に固有のものは何もありません。

制約が `Monoid m =>` なので、`Sum` 以外のモノイドからも同じように圏が作れます。

まず、乗算にあたる `Product` で、モノイドとしての動作を確認します。

```hs:GHCi
ghci> Product 3 <> Product 4
Product {getProduct = 12}
ghci> mempty :: Product Int
Product {getProduct = 1}
```

結合の結果も単位元も `Sum` とは異なりますが、どれも `<>` と `mempty` という同じ形に収まっています。

シリーズで使い続けてきたリストも `Monoid` のインスタンスです。

```hs:GHCi
ghci> ["a"] <> ["b"] <> ["c"]
["a","b","c"]
ghci> mempty :: [String]
[]
```

`Mono` が射として扱っているのは `m` の要素そのものです。`Mono [String] () ()` では文字列のリスト `[String]` が射になります。`Sum 3` や `Product 3` は `(+ 3)` や `(* 3)` のような関数と対応していましたが、リストにはそのような対応物がありません。

「射」や「矢印」という言葉は写像を連想させますが、圏が射に求めているのは、合成できることと恒等射があることだけです。`Category` にも射に値を渡すメソッドはなく、`cat a b` の `a`・`b` はどれとどれを合成できるかを決めるラベルとして働いています。`<>` で合成できて `mempty` という単位元がある以上、リストも射としての条件を満たしています。

操作を 1 つずつ 1 要素のリストで表せば、合成はその操作の並びです。`Mono (Sum Int)` とは別の圏で、射も恒等射も違うものになります。

`Mono.hs` を GHCi に読み込んで、`Sum Int` とリストを並べて試します。

```hs:GHCi
ghci> :load Mono.hs
[1 of 2] Compiling Main             ( Mono.hs, interpreted )
Ok, one module loaded.
ghci> Mono (Sum 3) >>> Mono (Sum 4) :: Mono (Sum Int) () ()
Mono (Sum {getSum = 7})
ghci> Mono ["a"] >>> Mono ["b"] >>> Mono ["c"] :: Mono [String] () ()
Mono ["a","b","c"]
ghci> id :: Mono (Sum Int) () ()
Mono (Sum {getSum = 0})
ghci> id :: Mono [String] () ()
Mono []
```

`a`・`b` は幽霊型で値から決まらないため、型注釈で `()` を指定しています。

合成は `Sum Int` なら加算、リストなら連結です。`id` と書いているのは同じですが、型注釈で指定したモノイドによって `Mono (Sum 0)` にも `Mono []` にもなります。実体は `mempty` なので当然で、射も恒等射もモノイドごとに違います。

ここでの射は `Sum 3` や `["a"]` といったただの値で、関数ではありません。恒等射も `[]` や `Sum 0` であって、恒等関数とは無関係です。`Category` が `id` に求めるのが単位元という性質だけだったことが、ここではっきりします。

対象が 1 つしかない圏を**一点圏**（one-object category）と呼びます。逆向きに読むこともできます。モノイドとは一点圏のことです。圏の方が広く、対象を 1 つに絞るとモノイドになります。この見方は後で効いてきます。

# 関手

`Functor` は `fmap` を持つ型クラスでした。👉[モナドとゆかいな仲間たち](https://zenn.dev/7shi/articles/20260807-haskell-monads-and-friends#ファンクター則)

```hs
class Functor f where
    fmap :: (a -> b) -> f a -> f b
```

名前のとおり、これが**関手**（functor）です。

関手は圏から圏への対応で、2 つの対応の組になっています。

- **対象の対応**: 対象 $a$ を対象 $F a$ に移す
- **射の対応**: 射 $f : a \to b$ を射 $F(f) : F a \to F b$ に移す

`Functor` インスタンスは、この 2 つを 1 つの型構築子で兼ねています。

|関手|Haskell|
|---|---|
|対象の対応 $a \mapsto F a$|型構築子の適用 `a` → `f a`|
|射の対応 $f \mapsto F(f)$|`fmap`|

`Maybe` なら、型 `Int` を型 `Maybe Int` に移すのが対象の対応、関数 `Int -> String` を関数 `Maybe Int -> Maybe String` に移すのが射の対応です。前者は型構築子を書くだけ、後者が `fmap` です。

```hs:Functor.hs
f, g :: Int -> Int
f = (* 2)
g = (+ 1)

main :: IO ()
main = do
    -- 射の対応: a -> b を f a -> f b に移す
    print (fmap g (Just 3))
    print (fmap g [1, 2, 3])
    print (fmap g (Right 3 :: Either String Int))
    -- fmap id == id
    print (fmap id (Just 3)  == id (Just 3))
    print (fmap id [1, 2, 3] == id [1, 2, 3])
    -- fmap (f . g) == fmap f . fmap g
    print (fmap (f . g) (Just 3)  == (fmap f . fmap g) (Just 3))
    print (fmap (f . g) [1, 2, 3] == (fmap f . fmap g) [1, 2, 3])
```

```text:実行結果
Just 4
[2,3,4]
Right 4
True
True
True
True
```

同じ関数 `(+1)` が `Maybe`・リスト・`Either String` の 3 つに持ち上がっています。どの持ち上げ方をするかを決めているのが `fmap` で、対象の対応だけでは決まりません。関手が 2 つの対応の組だというのは、この意味です。

後半 4 行はファンクター則です。

```hs
fmap id      == id               -- 単位元
fmap (f . g) == fmap f . fmap g  -- 準同型
```

これは圏の言葉では関手が恒等射と合成を保つことの要求です。

$$
F(\mathrm{id}) = \mathrm{id} \qquad F(f \circ g) = F(f) \circ F(g)
$$

モナドを自作する回では、`fmap` を「関数合成という構造を保つ準同型」と説明しました。関手の定義は、まさにこの 2 本です。ファンクター則を満たさない `Functor` インスタンスは関手ではありません。

## 自己関手

関手は一般には圏 $\mathcal{C}$ から別の圏 $\mathcal{D}$ への対応ですが、`Functor` のインスタンスはすべて Hask から Hask への対応です。`Maybe Int` も `[Int]` も Haskell の型なので、行き先は Hask の中に留まります。

このように出発点と行き先が同じ圏である関手を**自己関手**（endofunctor）と呼びます。

型で見ると `f :: * -> *` という種がその現れです。型を受け取って型を返すので、Hask の対象から Hask の対象への対応になります。👉[Freeモナド](https://zenn.dev/7shi/articles/20260808-haskell-free-monad#種)

Haskell の `Functor` インスタンスは、すべて自己関手です。「自己関手の圏」という言い方が後で出てきますが、その「自己関手」はこれのことです。

# 自然変換

Free モナドの回で、手順書を別のモナドへ移す `foldFree` を使いました。👉[Freeモナド](https://zenn.dev/7shi/articles/20260808-haskell-free-monad#free-パッケージ)

```hs
foldFree :: Monad m => (forall x. f x -> m x) -> Free f a -> m a
```

Eff モナドの回のハンドラーも同じ形でした。命令の型 `f` を、実際に動くモナド `m` へ翻訳する関数です。👉[Effモナド](https://zenn.dev/7shi/articles/20260811-haskell-eff-monad#ハンドラー)

この `forall x. f x -> m x` という形に名前が付いています。**自然変換**（natural transformation）です。関手から関手への対応で、圏論では射・関手に続く 3 段目の概念にあたります。

型シノニムにすると読みやすくなります。

```hs
type f ~> g = forall a. f a -> g a
```

`~>` は base には入っていないので自作します。この名前はライブラリでもよく使われます。

実例は身近なところにあります。

```hs:Natural.hs
import Data.Maybe (listToMaybe, maybeToList)

type f ~> g = forall a. f a -> g a

alpha :: [] ~> Maybe
alpha = listToMaybe

beta :: Maybe ~> []
beta = maybeToList
```

`listToMaybe` はリストの先頭を取り出す関数、`maybeToList` は `Maybe` をリストにする関数です。型を `~>` で書き直すと、リストという関手から `Maybe` という関手への対応、あるいはその逆になっていることが見えます。

中身の型 `a` が何であっても同じように働く、というのが `forall a.` の意味です。`listToMaybe` は要素が `Int` でも `String` でも先頭を取るだけで、中身を見ません。自然変換とは、容れ物だけを取り替えて中身に触らない対応のことです。

## 自然性

「中身に触らない」を式にしたものが**自然性条件**（naturality condition）です。

```hs
fmap h . alpha == alpha . fmap h
```

左辺は「容れ物を移してから中身を書き換える」、右辺は「中身を書き換えてから容れ物を移す」です。どちらの順でも同じ結果になることを要求しています。

図にすると分かりやすくなります。$\alpha$ を関手 $F$ から関手 $G$ への自然変換、$h : a \to b$ を射とします。

$$
\begin{CD}
F a @>{\alpha_a}>> G a \\
@V{F h}VV @VV{G h}V \\
F b @>{\alpha_b}>> G b
\end{CD}
$$

左上から右下へ行く道が 2 本あります。右へ行ってから下へ降りる道と、下へ降りてから右へ行く道です。この 2 本が同じところに着くというのが自然性です。このように「どの道を通っても同じ」ことを表す図を**可換図式**（commutative diagram）と呼びます。

$\alpha_a$ の添字は、対象 $a$ ごとに用意された射という意味です。自然変換は 1 本の射ではなく、対象ごとに 1 本ずつ用意された射の族として定義されます。Haskell では `forall a.` がその役割を果たすので、添字は表に出てきません。

:::message
図の中の矢印には 2 種類あります。$a \to b$ のような射の矢印と、関手から関手への自然変換です。後者は $\Rightarrow$ で書き分けます。Haskell ではどちらも `->` になってしまうので、記事の中では記号で区別します。
:::

実際に両辺を評価します。

```hs:Natural.hs
h :: Int -> String
h = show

main :: IO ()
main = do
    -- 自然性: fmap h . alpha == alpha . fmap h
    print ((fmap h . alpha) [1, 2, 3])
    print ((alpha . fmap h) [1, 2, 3])
    print ((fmap h . alpha) ([] :: [Int]))
    print ((alpha . fmap h) ([] :: [Int]))
    print ((fmap h . beta) (Just 1))
    print ((beta . fmap h) (Just 1))
    print ((fmap h . beta) (Nothing :: Maybe Int))
    print ((beta . fmap h) (Nothing :: Maybe Int))
```

```text:実行結果
Just "1"
Just "1"
Nothing
Nothing
["1"]
["1"]
[]
[]
```

上から 2 行ずつが対になっています。空の場合も含めて、どちらの順でも一致しています。

:::message
Haskell では、`forall a.` の形をした関数は自然性条件を自動的に満たします。型の中で `a` について何も分かっていない以上、`a` の値に応じて動作を変えることができないためです。

型だけから等式が導ける、という性質を**パラメトリシティ**（parametricity）と呼び、そこから得られる等式を**自由定理**（free theorem）と呼びます。自然性条件はその一例です。

ただし bottom を無視した場合の話です。`seq` や `undefined` を持ち込むと成り立たなくなります。
:::

# Kleisli 圏

前回、モナドを返す関数 `a -> m b` をつなぐために `Kleisli` を使いました。👉[アロー](https://zenn.dev/7shi/articles/20260813-haskell-arrow#kleisli)

```hs
newtype Kleisli m a b = Kleisli { runKleisli :: a -> m b }

instance Monad m => Category (Kleisli m) where
    id = Kleisli return
    Kleisli g . Kleisli f = Kleisli (\x -> f x >>= g)
```

`Category` のインスタンスなので、これも圏です。名前が付いています。**Kleisli 圏**（Kleisli category）です。

|Kleisli 圏|中身|
|---|---|
|対象|Haskell の型（Hask と同じ）|
|射 `a` → `b`|`a -> m b`|
|合成|`>=>`|
|恒等射|`return`|

対象は Hask と同じですが、射が違います。Hask で `a` から `b` への射は `a -> b` でしたが、Kleisli 圏では `a -> m b` です。同じ対象の上に別の射を敷いた圏ということになります。

ここでも「`a` から `b` への射」は `b` を返す関数ではありません。返ってくるのは `m b` です。`b` は合成の辻褄を合わせるための名前として働いています。

モナド `m` ごとに Kleisli 圏が 1 つ決まります。`Kleisli Maybe` なら失敗する計算の圏、`Kleisli []` なら非決定性計算の圏です。

ここでモナド則を思い出します。`>=>` で書き直したものでした。👉[モナドとゆかいな仲間たち](https://zenn.dev/7shi/articles/20260807-haskell-monads-and-friends#-で書き直す)

```hs
return >=> f    == f                -- 左単位元
f >=> return    == f                -- 右単位元
(f >=> g) >=> h == f >=> (g >=> h)  -- 結合法則
```

これは圏の公理そのものです。単位律が 2 本と結合律が 1 本、恒等射が `return`、合成が `>=>`。最初の節で書いた圏の要求と一字一句同じ形をしています。

つまりモナド則とは「Kleisli 圏が圏であること」の要求でした。モナドが満たすべき性質として天下り式に与えられていたものが、圏の側から見ると当たり前の要求だったことになります。

リストで確かめます。非決定性計算にあたるモナドです。👉[リストモナド](https://qiita.com/7shi/items/deb19c4cba933590ffbf)

```hs:Kleisli.hs
import Control.Arrow (Kleisli(..))
import Control.Category ((>>>))
import Control.Monad ((>=>))

-- 1 手で「1 を足す」か「2 倍する」（非決定性計算）
step :: Int -> [Int]
step n = [n + 1, n * 2]

main :: IO ()
main = do
    print (step 3)
    print ((step >=> step) 3)
    print ((step >=> step >=> step) 3)
    -- 左単位元・右単位元
    print ((return >=> step) 3 == step 3)
    print ((step >=> return) 3 == step 3)
    -- 結合法則
    print (((step >=> step) >=> step) 3 == (step >=> (step >=> step)) 3)
    -- Kleisli の >>> でも同じ
    print (runKleisli (Kleisli step >>> Kleisli step) 3)
```

```text:実行結果
[4,6]
[5,8,7,12]
[6,10,9,16,8,14,13,24]
True
True
True
[5,8,7,12]
```

`step` を `>=>` でつなぐたびに、到達できる値が倍に増えていきます。この合成が結合的で、`return` が単位元になっていることが 3 つの `True` です。

新しいコードは何もありません。前回書いた `Kleisli` のインスタンスに、Kleisli 圏という名前が付いただけです。

# モナドはモノイド対象

「モナドは自己関手の圏におけるモノイド対象である」という一文があります。分からない例として引き合いに出されることの多い文ですが、ここまでの材料が揃っていれば読み解けます。語ごとに分解していきます。

## join

まず主役を `>>=` から `join` に取り替えます。`Control.Monad` にある関数です。

```hs
join :: Monad m => m (m a) -> m a
```

2 重に包まれたモナドを 1 枚剥がして平らにします。リストなら `[[1,2],[3]]` を `[1,2,3]` にする関数です。

`>>=` と `join` は相互に定義できます。

```hs:Join.hs
import Control.Monad (join)

bind :: Monad m => m a -> (a -> m b) -> m b
bind m k = join (fmap k m)

join' :: Monad m => m (m a) -> m a
join' mm = mm >>= id

main :: IO ()
main = do
    print (bind [1, 2, 3] (\x -> [x, x * 10]))
    print ([1, 2, 3] >>= \x -> [x, x * 10])
    print (join' [[1, 2], [3]])
    print (join  [[1, 2], [3]])
    print (bind (Just 3) (\x -> Just (x * 2)))
    print (join' (Just (Just 3)))
```

```text:実行結果
[1,10,2,20,3,30]
[1,10,2,20,3,30]
[1,2,3]
[1,2,3]
Just 6
Just 3
```

`bind m k = join (fmap k m)` は「`fmap` で中身に関数を適用すると 2 重になるので `join` で潰す」という定義です。逆に `join mm = mm >>= id` は「取り出したものをそのまま返す」だけです。

どちらを基本に取っても同じモナドになります。Haskell は `>>=` を基本に選んでいますが、圏論では `join` を基本に選びます。`join` の方が圏論の道具立てに乗せやすいためです。

## μ と η

`join` と `return` を、前節の自然変換として読み直します。

```hs
join   :: m (m a) -> m a
return :: a -> m a
```

`join` は 2 重に重ねた `m` から `m` への対応です。関手を並べて書くと $T \circ T$ から $T$ への自然変換になります。$T$ はモナドを表す自己関手で、Haskell の `m` にあたります。

`return` の方は少し細工が必要です。`a -> m a` の左辺には関手がありません。ここで `Identity` を持ち出します。中身をそのまま持つだけの関手でした。👉[モナドとゆかいな仲間たち](https://zenn.dev/7shi/articles/20260807-haskell-monads-and-friends#identity)

`a` を `Identity a` と読み替えれば、`return` は `Identity a -> m a`、つまり恒等関手 $\mathrm{Id}$ から $T$ への自然変換になります。

伝統的にこの 2 本には $\mu$（ミュー）と $\eta$（イータ）という名前が付いています。

$$
\mu : T \circ T \Rightarrow T \qquad \eta : \mathrm{Id} \Rightarrow T
$$

|圏論|Haskell|
|---|---|
|$T$|`m`（自己関手）|
|$\mu$|`join`|
|$\eta$|`return`|
|$\mathrm{Id}$|`Identity`|

矢印が $\Rightarrow$ になっているのは、射ではなく自然変換だからです。

## モノイド則

ここで型を並べてみます。左が `Monoid`、右がモナドです。👉[型クラス](https://zenn.dev/7shi/articles/20260805-haskell-type-classes#semigroup-と-monoid)

|`Monoid`|モナド|
|---|---|
|`(<>) :: a -> a -> a`|`join :: m (m a) -> m a`|
|`mempty :: a`|`return :: a -> m a`|

`<>` は同じ型のものを 2 つ受け取って 1 つにします。`join` は同じ関手を 2 つ重ねたものを 1 つにします。「2 つ並んだものを 1 つにする」という形が共通しています。`mempty` と `return` も、どこからともなく 1 つ作るという点で同じ位置にいます。

満たすべき法則も対応します。

|`Monoid`|モナド|
|---|---|
|`(x <> y) <> z == x <> (y <> z)`|`join . join == join . fmap join`|
|`mempty <> x == x`|`join . return == id`|
|`x <> mempty == x`|`join . fmap return == id`|

`join . join` と `join . fmap join` は、3 重のモナドを潰す 2 通りの順序です。外側 2 枚を先に潰すか、内側 2 枚を先に潰すかの違いで、どちらでも同じところに着きます。

$$
\begin{CD}
T^3 @>{T\mu}>> T^2 \\
@V{\mu T}VV @VV{\mu}V \\
T^2 @>{\mu}>> T
\end{CD}
$$

`fmap join` が $T\mu$（内側に作用）、`join` が $\mu T$（外側に作用）です。前節の自然性の図と同じ読み方で、2 本の道が同じところに着きます。

単位律の方も図にできます。

$$
\begin{CD}
T @>{\eta T}>> T^2 @<{T\eta}<< T \\
@| @V{\mu}VV @| \\
T @= T @= T
\end{CD}
$$

外から包んでから潰しても、内から包んでから潰しても、元に戻ります。

実際に評価します。

```hs:Laws.hs
import Control.Monad (join)

mmm :: [[[Int]]]
mmm = [[[1, 2], [3]], [[4]]]

m :: [Int]
m = [1, 2, 3]

main :: IO ()
main = do
    -- Monoid の結合律・単位律
    print ((([1, 2] <> [3]) <> [4]) == ([1, 2] <> ([3] <> [4]) :: [Int]))
    print ((mempty <> m) == m && (m <> mempty) == m)
    -- モナドの結合律 join . join == join . fmap join
    print (join (join mmm))
    print (join (fmap join mmm))
    print (join (join mmm) == join (fmap join mmm))
    -- モナドの単位律 join . return == id, join . fmap return == id
    print (join (return m) == m)
    print (join (fmap return m) == m)
    -- Maybe でも同じ
    print (join (join (Just (Just (Just 'a')))))
    print (join (fmap join (Just (Just (Just 'a')))))
```

```text:実行結果
True
True
[1,2,3,4]
[1,2,3,4]
True
True
True
Just 'a'
Just 'a'
```

`Monoid` の法則とモナドの法則が、同じ形で並んで成り立っています。

## 一文を読み解く

材料が揃ったので、最初の一文に戻ります。

> モナドは自己関手の圏におけるモノイド対象である

**「自己関手の圏」** から読みます。圏は対象と射でできていました。ここでの対象は自己関手、射は自然変換です。`Maybe` や `[]` が点になり、`listToMaybe` のような自然変換がその間の矢印になる圏を考えます。これを $\mathbf{End}(\mathbf{Hask})$ などと書きます。

**「モノイド対象」** は、圏の中でモノイドのように振る舞う対象のことです。一点圏の節でモノイドを圏とみなしましたが、今度は逆に、圏の中の 1 つの対象がモノイドの構造を持つ、という話になります。

普通のモノイドは、集合 $M$ と、掛け算 $M \times M \to M$ と、単位元 $1 \to M$ の組でした。これを別の圏に移植します。$\mathbf{End}(\mathbf{Hask})$ で移植先を探すと次のようになります。

|モノイド|$\mathbf{End}(\mathbf{Hask})$ での対応|Haskell|
|---|---|---|
|集合 $M$|自己関手 $T$|`m`|
|直積 $M \times M$|関手の合成 $T \circ T$|`m (m a)`|
|掛け算 $M \times M \to M$|$\mu : T \circ T \Rightarrow T$|`join`|
|単位元の集合 $1$|恒等関手 $\mathrm{Id}$|`Identity`|
|単位元 $1 \to M$|$\eta : \mathrm{Id} \Rightarrow T$|`return`|

直積が関手の合成に、単位元の置き場所が恒等関手に置き換わっています。あとは結合律と単位律を課せば、モノイドの定義がそのまま移植できます。前節で確かめた 3 本がそれです。

これが「自己関手の圏におけるモノイド対象」の中身です。モナドとは、$\mathbf{End}(\mathbf{Hask})$ という圏の中でモノイドの形をしている対象のことでした。

この一文の出所は Mac Lane の *Categories for the Working Mathematician* で、モナドの定義の直後に置かれた説明の締めくくりです。原文でも直前で「集合 $M$ を自己関手 $T$ に、直積を関手の合成に、掛け算を $\mu$ に、単位元を $\eta$ に置き換える」と対応表そのものを述べています。唐突な宣言ではなく、対応表の要約として書かれた一文です。

:::message
モナド則には別の読み方もあります。前節の Kleisli 圏で見たように、`>=>` と `return` で書き直せばモノイドの形が出てきました。

- `>=>` の側: Kleisli 圏の射がモノイドをなす
- `join` の側: 自己関手の圏でモナドがモノイド対象になる

同じモナド則を、射の側から見るか関手の側から見るかの違いです。どちらも「単位元と結合律」に行き着きます。`>=>` の側からの説明は番外編にも書いてあります。👉[モナド則がちょっと分かった？](https://qiita.com/7shi/items/547b6137d7a3c482fe68#モノイド対象)
:::

# 随伴と自由生成

Free モナドの回で「自由」の意味を説明しました。リストが自由モノイドであるのと同じように、Free モナドは「モナド則だけを満たし、それ以上の意味づけを持たない」構造だ、という説明です。👉[Freeモナド](https://zenn.dev/7shi/articles/20260808-haskell-free-monad#自由とは何か)

あの節の末尾には、圏論での定義として「忘却関手の左随伴」と書いてあります。ここでその中身を見ます。

## 忘却関手

モノイドは、集合に `<>` と `mempty` を備えたものでした。ここから構造だけを取り去って、要素の集合に戻す対応を考えます。`Sum Int` から `Int` の集合へ、`[a]` から要素の並びの集合へ、といった具合です。

構造を忘れるので**忘却関手**（forgetful functor）と呼びます。$U$ と書きます。

$$
U : \mathbf{Mon} \to \mathbf{Set}
$$

$\mathbf{Mon}$ はモノイドの圏（対象がモノイド、射がモノイド準同型）、$\mathbf{Set}$ は集合の圏です。$U$ は何もしないように見えますが、行き先の圏が違うので情報が落ちています。

## 自由関手

逆向きの対応も考えられます。集合 $a$ からモノイドを作る、いちばん素直な方法はリストです。

要素を並べるだけで、それ以上何もしません。`[1] <> [2]` は `[1,2]` になるだけで `3` にはなりません。モノイド則を満たすのに必要な最低限しか持っていない構造で、これを自由モノイドと呼びました。

この対応を**自由関手**（free functor）と呼び、$F$ と書きます。

$$
F : \mathbf{Set} \to \mathbf{Mon}
$$

この $F$ と $U$ の関係が**随伴**（adjunction）です。$F \dashv U$ と書き、「$F$ は $U$ の左随伴」と読みます。「自由」とはこの位置にいることを指しています。

## 普遍性

随伴が持つ性質のうち、Haskell で直接見えるものが 1 つあります。「1 つ与えると一意に決まる」という形です。

集合 `a` からモノイド `m` への関数を 1 つ与えると、`[a]` から `m` への準同型が一意に決まります。それが `foldMap` です。

```hs
foldMap :: Monoid m => (a -> m) -> [a] -> m
```

要素 1 つの移し方さえ決めれば、並び全体の移し方は決まります。`<>` でつなぐしかないからです。他の決め方はありません。

Free モナドでも同じことが起きています。命令の型 `f` からモナド `m` への自然変換を 1 つ与えると、`Free f a` から `m a` への解釈が一意に決まります。それが `foldFree` です。

```hs
foldFree :: Monad m => (f ~> m) -> Free f a -> m a
```

この 2 つを並べると、同じ形をしています。

```hs
foldMap  :: Monoid m => (a -> m)  -> [a]      -> m
foldFree :: Monad  m => (f ~> m)  -> Free f a -> m a
```

`[a]` が `Free f a` に、`Monoid` が `Monad` に、関数が自然変換に置き換わっているだけです。リストが集合に対する自由モノイドであるように、`Free f` は `f` に対する自由モナドである、というのがこの並びの意味です。

このように「1 つ与えると一意に決まる」性質を**普遍性**（universal property）と呼びます。Free モナドの回で「余計な性質を持たない」と表現したのは、この普遍性のことでした。

実際に書いて動かします。

```hs:Free.hs
import Control.Monad (ap, liftM)

data Free f a = Pure a | Free (f (Free f a))

instance Functor f => Functor (Free f) where
    fmap = liftM

instance Functor f => Applicative (Free f) where
    pure  = Pure
    (<*>) = ap

instance Functor f => Monad (Free f) where
    Pure a >>= k = k a
    Free g >>= k = Free (fmap (>>= k) g)

type f ~> g = forall a. f a -> g a

foldFree :: Monad m => (f ~> m) -> Free f a -> m a
foldFree _   (Pure a) = return a
foldFree phi (Free g) = phi g >>= foldFree phi
```

命令は 1 つだけ用意します。文字列を出力する `Say` です。

```hs:Free.hs
data Say next = Say String next

instance Functor Say where
    fmap k (Say s next) = Say s (k next)

say :: String -> Free Say ()
say s = Free (Say s (Pure ()))

prog :: Free Say ()
prog = do
    say "hello"
    say "world"
```

解釈を 2 つ与えます。標準出力に書くものと、リストに集めるものです。

```hs:Free.hs
toIO :: Say ~> IO
toIO (Say s next) = putStrLn s >> return next

toLog :: Say ~> ((,) [String])
toLog (Say s next) = ([s], next)

main :: IO ()
main = do
    -- (a -> m) を 1 つ与えると [a] -> m が決まる
    print (foldMap (\x -> [show x]) [1, 2, 3 :: Int])
    print (sum [1, 2, 3 :: Int])
    -- (f ~> m) を 1 つ与えると Free f a -> m a が決まる
    foldFree toIO prog
    print (foldFree toLog prog)
```

```text:実行結果
["1","2","3"]
6
hello
world
(["hello","world"],())
```

`toLog` の解釈先が `((,) [String])` になっているのは、base に `Monoid w => Monad ((,) w)` があるためです。ログを集めるだけの簡易な Writer として使えます。

与えているのは命令 1 つの翻訳だけで、`prog` 全体をどう辿るかは `foldFree` が持っています。手順書と解釈が分けられるのは、この普遍性のおかげです。

:::message
`foldFree` は `Functor f` を要求しません。命令を `phi` で `m` に移してから `>>=` でつなぐだけで、`f` 側の `fmap` を使わないためです。`Functor f` が必要になるのは `Free f` を `Monad` のインスタンスにする側だけです。
:::

随伴の一般的な定義には立ち入りません。`foldMap` と `foldFree` の型が並ぶこと、そこに「1 つ与えると一意に決まる」が現れていること、それが「自由」の内容だということ。ここまでが Haskell から見える範囲です。

# 米田の補題

Operational モナドの回で、継続を命令の型から外しました。👉[Operationalモナド](https://zenn.dev/7shi/articles/20260809-haskell-operational-monad#継続を命令の型から外す)

```hs
data Program instr a where
    Return :: a -> Program instr a
    (:>>=) :: instr b -> (b -> Program instr a) -> Program instr a
```

このとき `Functor instr =>` という制約が不要になりました。Free モナドでは命令の型ごとに `Functor` インスタンスを書く必要があったのに、Operational では書かずに済みます。

なぜ済むのかを、ここで説明します。

## Coyoneda

`:>>=` の形だけを取り出した型を作ります。

```hs:Coyoneda.hs
data Coyoneda f a = forall b. Coyoneda (f b) (b -> a)
```

「容れ物 `f b` と、中身を `a` に変換する関数 `b -> a` の組」です。`:>>=` と見比べてください。

```hs
(:>>=) :: instr b -> (b -> Program instr a) -> Program instr a  -- Operational
Coyoneda :: f b -> (b -> a) -> Coyoneda f a                     -- 今回
```

`b` が型全体に現れない存在型になっているところまで同じです。この型を **Coyoneda**（コ米田）と呼びます。

`Functor` インスタンスを書きます。

```hs:Coyoneda.hs
instance Functor (Coyoneda f) where
    fmap h (Coyoneda fb g) = Coyoneda fb (h . g)
```

`f` に何も要求していません。容れ物 `f b` には手を触れず、後ろの関数を `h . g` と合成するだけだからです。`instance Functor f =>` が付いていないことを確認してください。

包むのと取り出すのを用意します。

```hs:Coyoneda.hs
liftCoyoneda :: f a -> Coyoneda f a
liftCoyoneda fa = Coyoneda fa id

lowerCoyoneda :: Functor f => Coyoneda f a -> f a
lowerCoyoneda (Coyoneda fb g) = fmap g fb
```

非対称になっています。包む `liftCoyoneda` は無制約ですが、取り出す `lowerCoyoneda` には `Functor f` が必要です。溜め込んだ関数を実際に容れ物へ適用する段になって初めて `fmap` が要求されます。

`Functor` インスタンスを持たない型で試します。

```hs:Coyoneda.hs
data Box a = Box a

unBox :: Coyoneda Box a -> a
unBox (Coyoneda (Box b) g) = g b

main :: IO ()
main = do
    -- Box は Functor ではないが Coyoneda Box は Functor
    print (unBox (fmap (* 2) (liftCoyoneda (Box 3))))
    print (unBox (fmap show (fmap (+ 1) (liftCoyoneda (Box 3)))))
    -- Functor がある型なら取り出せる
    print (lowerCoyoneda (fmap (* 2) (liftCoyoneda [1, 2, 3])))
```

```text:実行結果
6
"4"
[2,4,6]
```

`Box` には `Functor` インスタンスがありません。それでも `Coyoneda Box` に対しては `fmap` が書けています。2 行目では `fmap` を 2 回重ねていますが、`Box` の中身は 1 度も動かず、関数が `show . (+1)` と合成されただけです。

任意の型構築子を `Functor` にしてしまう構成になっています。これが Operational モナドで `Functor` インスタンスが不要だった理由です。あの `instr :>>= k` は、命令を Coyoneda で包んだ形をしていました。

## Yoneda

向きを逆にした型もあります。

```hs:Yoneda.hs
newtype Yoneda f a = Yoneda (forall b. (a -> b) -> f b)
```

**Yoneda**（米田）です。Coyoneda が「容れ物と関数の組」だったのに対し、こちらは「関数を受け取ると容れ物を返す関数」です。

```hs:Yoneda.hs
instance Functor (Yoneda f) where
    fmap h (Yoneda y) = Yoneda (\k -> y (k . h))

liftYoneda :: Functor f => f a -> Yoneda f a
liftYoneda fa = Yoneda (\k -> fmap k fa)

lowerYoneda :: Yoneda f a -> f a
lowerYoneda (Yoneda y) = y id
```

`lowerYoneda` は `id` を渡すだけです。「`a -> b` を渡せば `f b` を返す」という約束の `b` に `a` を選び、何もしない関数を渡すと `f a` が出てきます。

この 2 つが互いに逆になります。

```hs:Yoneda.hs
main :: IO ()
main = do
    -- 往復すると元に戻る
    print (lowerYoneda (liftYoneda [1, 2, 3]))
    print (lowerYoneda (liftYoneda (Just 'a')))
    print (lowerYoneda (liftYoneda (Right 3 :: Either String Int)))
    -- fmap は関数の合成に変わる
    print (lowerYoneda (fmap (* 2) (liftYoneda [1, 2, 3])))
    print (lowerYoneda (fmap show (fmap (+ 1) (liftYoneda (Just 3)))))
```

```text:実行結果
[1,2,3]
Just 'a'
Right 3
[2,4,6]
Just "4"
```

往復しても元に戻ります。つまり `forall b. (a -> b) -> f b` と `f a` は同じ情報を持っています。見た目はまるで違うのに、片方からもう片方が復元できます。

これが**米田の補題**（Yoneda lemma）の Haskell 版です。一般形は次のように書かれます。

$$
\mathrm{Nat}(\mathrm{Hom}(a, -), F) \cong F a
$$

$\mathrm{Hom}(a, -)$ は「$a$ から出る射を集めたもの」で、Haskell では `(a -> )` にあたります。$\mathrm{Nat}$ は自然変換全体、$\cong$ は同型を表します。左辺は `forall b. (a -> b) -> f b`、右辺は `f a` で、上で確かめた往復がこの $\cong$ です。

なぜこれが成り立つのかには立ち入りません。「対象そのものと、その対象から出る射の全体は同じ情報を持つ」という主張で、圏論の基本定理の 1 つに数えられます。証明は本格的な本に譲ります。

:::message
`Coyoneda`・`Yoneda` は [kan-extensions](https://hackage.haskell.org/package/kan-extensions) パッケージの `Data.Functor.Coyoneda`・`Data.Functor.Yoneda` にあります。本記事では base だけで完結させるため自作しました。

Yoneda は性能の改善にも使われます。`fmap` を重ねても関数の合成にしかならないので、`fmap` を何回も適用するコードで容れ物を作り直す手間が省けます。同じ発想で Free モナドの左結合 `>>=` を高速化する Codensity という道具もあります。
:::

# 補遺

シリーズで扱わなかった話題を並べておきます。ここから先へ進むための地図です。

外した基準は一貫しています。入門として準備が重すぎるものを外してきました。知らなくても Haskell は書けるが、知っていると見通しが良くなる、という位置にあるものが多く残っています。

|話題|扱わなかった理由|どこから始めるか|
|---|---|---|
|`Foldable`・`Traversable`|`Functor`・`Applicative`・`Monad` の 3 段で止めたため。`traverse` は `Applicative` の最大の実用例|`foldMap`・`traverse`|
|`Alternative`・`MonadFail`|`Maybe`・状態系・構文解析の各回で先送りしたまま|`empty` と選択の演算子|
|遅延評価の理論|専用の回を設けなかった。知らないとコードが壊れる唯一の項目|`foldl` と `foldl'`・`seq`・`BangPatterns`|
|パラメトリシティと自由定理|型が仕様になるという主張の裏付け。自然変換の節と地続き|`id :: a -> a` は恒等関数しかありえない|
|カリー＝ハワード同型対応|型と命題、プログラムと証明の対応|代数的データ型（直積・直和・関数型）|
|ヒンドリー・ミルナー型推論|型推論の結果は使い続けたが裏側に触れなかった|単一化と let 多相|
|F 代数と再帰スキーム|Free モナドの親戚だが分量の都合で見送った|`Free f` から「変数」を取ると `Fix f`|
|`ArrowLoop`・FRP|遅延評価の理解が前提になる|Yampa|
|Codensity による Free の高速化|性能の話は別筋|左結合 `>>=` の二乗問題|
|`Comonad`|実用場面が限られる|`extract`・`duplicate`|
|STM など並行処理|シリーズの範囲外と定めた||

圏論側で扱わなかったものもあります。極限と余極限、デカルト閉圏、随伴の一般定義、モナドの代数（Eilenberg-Moore 圏）などです。本記事は Haskell に対応物があるものだけを扱いました。

# 総括

20 回に渡って続けてきたシリーズは、この回で完結します。

## この回で見たこと

|シリーズで書いたコード|圏論の名前|
|---|---|
|`class Category cat`|圏。公理は結合律と単位律の 2 つだけ|
|`instance Category (->)`|Hask 圏。ただし bottom があるので厳密には圏でない|
|`instance Monoid m => Category (Mono m)`|一点圏。モノイドは対象が 1 つの圏|
|`Functor` とファンクター則|自己関手。対象の対応と射の対応の組|
|`forall a. f a -> g a`|自然変換。中身に触らず容れ物を移す|
|`instance Category (Kleisli m)`|Kleisli 圏。モナド則は圏の公理だった|
|`join` と `return`|$\mu$ と $\eta$。自己関手の圏におけるモノイド対象|
|`foldMap` と `foldFree`|随伴の普遍性。これが「自由」の意味|
|`Coyoneda` の `Functor` インスタンス|米田の補題。`Functor` が不要だった理由|

どれも新しいコードではありません。名前が付いただけです。

## シリーズが辿った道のり

6 つの段階に分かれます。

|段階|回|内容|
|---|---|---|
|言語の基礎|01〜05|型・代数的データ型・アクション・ラムダ|
|モナドを使う|06〜12|IO・リスト・Maybe・状態系・変換子・例外・構文解析|
|モナドの仕組み|13〜15|継続・型クラス・自作|
|組み立てと解釈の分離|16〜18|Free・Operational・Eff|
|モナドを離れる|19|アロー|
|後から名前を与える|20|圏論|

最初の段階では言語の書き方を覚え、次の段階で既にあるモナドを使い、その次で仕組みを開けて自作できるようにしました。そこから先は、`>>=` に意味を与えないという発想で組み立てと解釈を分け、さらに `>>=` を持たない枠組みへ移り、最後に全体を圏論の言葉で眺め直しました。

## なぜ圏論を最後に置いたのか

シリーズの方針は「あまり数学に寄せず、他のプログラミング言語と同じような接し方をする」でした。Haskell の入門記事は数学的な背景から入るものが多いのですが、このシリーズは言語の機能として説明し、書いて動かすことを優先しました。

その方針の具体的な現れが「圏論には言及しない」です。これは圏論が不要だという主張ではありません。順序の問題です。

圏論から入ると、モナドを 1 つも書かないうちに関手と自然変換を覚えることになります。逆に、19 回分のコードを書いてから圏論の名前を聞けば、既に手が知っているものに名前が付くだけです。この回で `Category` が圏の定義そのものだったこと、モナド則が圏の公理だったことを見ましたが、どちらも「言われてみればそうだ」という感触だったはずです。そう感じられる状態を作るのに 19 回掛けた、というのがこのシリーズの構成でした。

圏論を学ぶかどうかは読者の自由です。既にあるモナドを使うだけなら、この回の内容を忘れても困りません。それでも、自分でモナドを設計する側に回ったときには、圏論の語彙が地図として効きます。Free モナドの「自由」も、Operational モナドで `Functor` が不要だったことも、この回で見たとおり圏論の側に理由がありました。理由を知らなくても書けますが、知っていれば次に何が書けるかが見えます。

# 関連記事

モナド則を図で説明した番外編です。本記事の Kleisli 圏とモノイド対象の節と重なります。

https://qiita.com/7shi/items/539c2c46edfb5313cbc6

https://qiita.com/7shi/items/547b6137d7a3c482fe68

# 参考

「モナドは自己関手の圏におけるモノイド対象」の原文は、次の本にあります。第 VI 章 §1、モナドの定義の直後です。

1. Mac Lane, S. (1998). *Categories for the Working Mathematician* (2nd ed.). Springer. Graduate Texts in Mathematics 5.

この一文が広く知られるようになったきっかけは、次の記事です。1990 年の項に、Haskell の説明としてこの一文が出てきます。記事全体がジョークなので、発言者の設定も含めて史実ではありません。

https://james-iry.blogspot.com/2009/05/brief-incomplete-and-mostly-wrong.html
