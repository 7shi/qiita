# Functor の検証（記事「Functor」の節）

GHC 9.6.6。実行は `runghc {ファイル名}`。

| ファイル | 内容 |
|---|---|
| `Fmap.hs` | `map` と `fmap` の対応。リスト・`Maybe`・`IO` で同じ `fmap` が使えること |
| `FmapViaBind.hs` | 10回の `<$>` 再実装（bind による）と `fmap`・`liftM` が一致すること |

## 実行結果

`Fmap.hs`:

```
[2,4,6]
[2,4,6]
Just 6
Nothing
Just 6
6
```

`FmapViaBind.hs`:

```
[2,4,6]
[2,4,6]
[2,4,6]
```

記事では `<$>` を再定義できないため、10回の再実装を `<$$>` という別名に変えて併記した。

## GHCi での確認

```
ghci> :i Functor
type Functor :: (* -> *) -> Constraint
class Functor f where
  fmap :: (a -> b) -> f a -> f b
  (<$) :: a -> f b -> f a
  {-# MINIMAL fmap #-}
（略）
ghci> :t liftM
liftM :: Monad m => (a1 -> r) -> m a1 -> m r
```

`liftM` の制約が `Monad` である以外は `fmap` と同じ型。
