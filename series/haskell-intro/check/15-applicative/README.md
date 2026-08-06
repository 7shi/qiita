# Applicative の検証（記事「Applicative」の節）

GHC 9.6.6。実行は `runghc {ファイル名}`。

| ファイル | 内容 |
|---|---|
| `IdentityApp.hs` | `Identity` で 2 引数の関数を持ち上げる。`Functor`・`Applicative` のインスタンスを並べたもの |
| `App.hs` | `Maybe`・リストでの `<$>` と `<*>`（Applicative スタイル）|
| `Discard.hs` | `<*`・`*>`（片方の結果だけを残す）|
| `PureReturn.hs` | `pure` と `return` が同じ結果になること |
| `Laws.hs` | アプリカティブ則（恒等・準同型・交換・合成）と `fmap f x == pure f <*> x` が `Maybe` で成り立つこと |
| `Interchange.hs` | 交換則をリストで確認（`pure` した側は左右どちらでも同じ）|
| `PairNG.hs` | アプリカティブ則を破る例。左右の位置を入れ替える `<*>` は恒等則を破る |
| `Style.hs` | Applicative スタイルの型クラス制約（07回の回収）。**本文からは削除済み**（決定事項 18）。書き直すときの材料として残置 |

## 実行結果

`IdentityApp.hs`:

```
3
```

`App.hs`:

```
Just 3
Nothing
[(1,'a'),(1,'b'),(2,'a'),(2,'b')]
```

`Discard.hs`:

```
Just 1
Just 2
```

`PureReturn.hs`:

```
Just 1
Just 1
[1]
[1]
```

`Laws.hs`:

```
True
True
True
True
True
```

`==` と `<*>` はどちらも優先順位 4 なので、両辺を括弧で囲まないと構文エラーになる。

`Interchange.hs`:

```
[11,20]
[11,20]
```

リストの `pure 10` は 1 要素なので、左右どちらに置いても組み合わせの結果は変わらない。

`PairNG.hs`:

```
Pair 2 1
```

型は通るが `pure id <*> Pair 1 2` が `Pair 1 2` にならず、恒等則が破れている。

`Style.hs`（本文からは削除済み）:

```
[2,3]
Just 2
2
[3]
Just 3
```

`inc`・`add` は素の関数のままで、制約を負うのは `<$>`・`<*>` を使う側。

## GHCi での確認

```
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
ghci> import Data.Functor.Identity
ghci> :t (+) <$> Identity 1
(+) <$> Identity 1 :: Num a => Identity (a -> a)
ghci> runIdentity ((+) <$> Identity 1 <*> Identity 2)
3
```

`fmap` だけでは 2 引数の関数が `Identity` の中の関数として止まる。ここが `<*>` の動機。

`fmap` と `<*>` の整合性（`fmap f x == pure f <*> x`）の確認。

```
ghci> (+) <$> Just 1 <*> Just 2
Just 3
ghci> pure (+) <*> Just 1 <*> Just 2
Just 3
```

`liftA2` は最小完全定義に `(<*>) | liftA2` として現れるが、記事では扱わない
（`<*>` の説明で足りるため）。
