# Tree の検証（記事「Tree」「Foldable」の節）

GHC 9.6.6。実行は `runghc {ファイル名}`。

| ファイル | 内容 |
|---|---|
| `Tree.hs` | 二分木を `Monad` にする。`>>=` は葉を部分木に差し替える（接ぎ木） |
| `TreeFoldable.hs` | `foldMap` の 2 行だけで `sum`・`length`・`elem`・`maximum`・`toList`・`mapM_` が動く |

## 実行結果

`Tree.hs`:

```
Node (Leaf 2) (Leaf 4)
Node (Node (Leaf 1) (Leaf 10)) (Node (Leaf 2) (Leaf 20))
Node (Node (Leaf 1) (Leaf 10)) (Node (Leaf 2) (Leaf 20))
```

2 行目が `>>=`、3 行目が同じものを `do` で書いたもの。結果が一致する。

`TreeFoldable.hs`:

```
6
3
True
3
[1,2,3]
1
2
3
```

## GHCi での確認

```
ghci> :i Foldable
type Foldable :: (* -> *) -> Constraint
class Foldable t where
（略）
  {-# MINIMAL foldMap | foldr #-}
ghci> :t sum
sum :: (Foldable t, Num a) => t a -> a
ghci> :t traverse
traverse
  :: (Traversable t, Applicative f) => (a -> f b) -> t a -> f (t b)
```

`traverse` の制約が `Applicative` で足りている点は記事で 1 行触れるに留めた
（`instance Traversable` は 16回以降へ）。
