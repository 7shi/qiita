# Functor の検証（記事「Functor」の節）

GHC 9.6.6。実行は `runghc {ファイル名}`。

| ファイル | 内容 |
|---|---|
| `Fmap.hs` | `Maybe`・`IO`・リストで同じ `fmap` が使えること |
| `FmapViaBind.hs` | 10回の `<$>` 再実装（bind による）と `fmap`・`liftM` が一致すること |
| `Instance.hs` | `instance Functor Maybe` の形（型名を変えて再定義） |
| `InstanceNG.hs` | Functor 則を破るインスタンスも型は通ること |

## 実行結果

`Fmap.hs`:

```
Just 6
Nothing
6
[2,4,6]
Just 6
```

`FmapViaBind.hs`:

```
[2,4,6]
[2,4,6]
[2,4,6]
```

`Instance.hs`:

```
Just' 6
Nothing'
```

`InstanceNG.hs`（型は通り、警告もなく実行できてしまう）:

```
Nothing'
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

再実装（`<$$>`）の推論される型も `Monad` 制約になる。本物の `<$>` は `Functor` 制約なので、`Monad` インスタンスを持たない `ZipList` では両者に差が出る。

```
ghci> :t (<$$>)
(<$$>) :: Monad m => (t -> b) -> m t -> m b
ghci> getZipList $ (* 2) <$> ZipList [1, 2, 3]   -- Control.Applicative
[2,4,6]
```
