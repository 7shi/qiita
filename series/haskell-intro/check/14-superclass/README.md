# スーパークラスの検証（記事「スーパークラス」の節）

GHC 9.6.6 / mtl 2.3.1。実行は `runghc {ファイル名}`。

| ファイル | 内容 |
|---|---|
| `Count.hs` | 自作型 `Count` に `Semigroup`/`Monoid` を実装。標準のリスト・文字列の `<>`・`mempty` も確認 |
| `CountWriter.hs` | その `Count` を Writer モナドの `w` に載せる。09回の `Monoid w =>` の回収 |
| `NoSemigroup.hs` | `Semigroup` を書かずに `Monoid` だけ書くとコンパイルエラー |

## 実行結果

`Count.hs`:

```
Count 3
Count 0
Count 6
"abcdef"
[1,2,3]
```

`CountWriter.hs`:

```
((),Count 6)
```

`tell` の追記が `<>`（ここでは足し算）になるため、ログを溜めずに合計だけが残る。
Writer 側は何も変えていない。

`NoSemigroup.hs`（コンパイルエラー）:

```
NoSemigroup.hs:3:10: error: [GHC-39999]
    • No instance for ‘Semigroup Count’
        arising from the superclasses of an instance declaration
    • In the instance declaration for ‘Monoid Count’
```

`arising from the superclasses` とスーパークラスであることが明示される。

## GHCi での確認

```
ghci> :info Monoid
type Monoid :: * -> Constraint
class Semigroup a => Monoid a where
  mempty :: a
  mappend :: a -> a -> a
  mconcat :: [a] -> a
  {-# MINIMAL mempty | mconcat #-}
（略）
ghci> :info Ord
type Ord :: * -> Constraint
class Eq a => Ord a where
  compare :: a -> a -> Ordering
（略）
```
