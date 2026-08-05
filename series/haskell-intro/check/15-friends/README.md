# 周辺の型クラスの検証（記事「ゆかいな仲間たち」の節）

GHC 9.6.6。実行は `runghc {ファイル名}`。

| ファイル | 内容 |
|---|---|
| `Alt.hs` | `Alternative` の `<\|>`・`empty`。`Monoid` の `<>` との対比 |
| `Fail.hs` | `do` のパターンマッチ失敗が `Maybe` では `Nothing`、リストでは要素の脱落になる |
| `FailIO.hs` | `IO` では `fail` が例外になる |

## 実行結果

`Alt.hs`:

```
Just 1
Just 2
Nothing
Nothing
[1,2,3]
[]
Just [1,2]
[1,2,3]
```

末尾 2 行は `Monoid` の `<>`。`Maybe [Int]` の `<>` は中身の `Monoid` を使って結合するので、
`<|>`（左優先の選択）とは結果が違う。記事では対応表だけを示し、この差分には踏み込まない。

`Fail.hs`:

```
Just 1
Nothing
[10,30]
```

`FailIO.hs`（実行時エラー）:

```
FailIO.hs: user error (Pattern match failure in 'do' block at FailIO.hs:2:5-9)
```

## GHCi での確認

```
ghci> :i Alternative
type Alternative :: (* -> *) -> Constraint
class Applicative f => Alternative f where
  empty :: f a
  (<|>) :: f a -> f a -> f a
  some :: f a -> f [a]
  many :: f a -> f [a]
  {-# MINIMAL empty, (<|>) #-}
（略）
ghci> :i MonadFail
type MonadFail :: (* -> *) -> Constraint
class Monad m => MonadFail m where
  fail :: String -> m a
  {-# MINIMAL fail #-}
instance MonadFail IO
instance MonadFail []
instance MonadFail Maybe
（略）
```

`some`・`many` は最小完全定義に含まれないため記事では扱わない。
