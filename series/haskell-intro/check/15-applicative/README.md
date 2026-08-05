# Applicative の検証（記事「Applicative」の節）

GHC 9.6.6。実行は `runghc {ファイル名}`。

| ファイル | 内容 |
|---|---|
| `App.hs` | `<$>` と `<*>` の組み合わせ、`<*`・`*>` |
| `Style.hs` | Applicative スタイルの型クラス制約（07回の回収）。`Monad` ではなく `Functor`/`Applicative` で足りる |
| `PureReturn.hs` | `pure` と `return` が同じ結果になること |

## 実行結果

`App.hs`:

```
Just 3
Nothing
[(1,'a'),(1,'b'),(2,'a'),(2,'b')]
Just 1
Just 2
```

`Style.hs`:

```
[2,3]
Just 2
2
[3]
Just 3
```

`inc`・`add` は素の関数のままで、制約を負うのは `<$>`・`<*>` を使う側。

`PureReturn.hs`:

```
Just 1
Just 1
[1]
[1]
```

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
ghci> :t (+) <$> Just 1
(+) <$> Just 1 :: Num a => Maybe (a -> a)
```

`fmap` だけでは 2 引数の関数が `Maybe` の中の関数として止まる。ここが `<*>` の動機。

`liftA2` は最小完全定義に `(<*>) | liftA2` として現れるが、記事では扱わない
（`<*>` の説明で足りるため）。
