# 練習問題の解答例（記事の練習4問）

GHC 9.6.6 / mtl 2.3.1。実行は `runghc {ファイル名}`。

| ファイル | 対応 | 内容 |
|---|---|---|
| `Q1Shape.hs` | 【問1】 | デフォルト実装を持つ型クラスの自作。`Circle` は `name` を上書き、`Rect` はデフォルトのまま |
| `Q2MaxInt.hs` | 【問2】 | `Semigroup`/`Monoid` の自作（最大値）と Writer への適用 |
| `Q3ShowColor.hs` | 【問3】 | `instance Show` の手書き。`../14-deriving/ShowDeriving.hs` と同じ出力 |
| `Q4Vec.hs` | 【問4】 | `instance Num` の自作。使わないメソッドは `undefined` |
| `Q4VecFromInteger.hs` | 【問4】発展 | `fromInteger` も実装した場合。数値リテラルが `Vec` になり `sum` も動く |

## 実行結果

`Q1Shape.hs`:

```
円: 3.141592653589793
図形: 6.0
```

`Q2MaxInt.hs`:

```
MaxInt 4
((),MaxInt 9)
```

`Q3ShowColor.hs`:

```
Blue
[Blue,Red]
Just White
```

`Q4Vec.hs`:

```
Vec 4.0 6.0
Vec (-2.0) (-2.0)
Vec (-1.0) (-2.0)
Vec 3.0 5.0
```

`Q4VecFromInteger.hs`:

```
Vec 2.0 3.0
Vec 6.0 6.0
```

`sum` は初期値の `0` が `fromInteger` を通るため、`Q4Vec.hs` の方（`fromInteger = undefined`）
では実行時エラーになる。記事では `Q4Vec.hs` を解答例、`Q4VecFromInteger.hs` を発展として扱った。

## 補足

`Q4Vec.hs` で `undefined` を並べずに省略した場合、次の警告が出る（`-Wmissing-methods` は
デフォルトで有効なので `-Wall` は不要）。

```
warning: [GHC-06201] [-Wmissing-methods]
    • No explicit implementation for
        ‘*’, ‘abs’, ‘signum’, and ‘fromInteger’
```

さらに `-` と `negate` も省略すると、次のように `(either ‘negate’ or ‘-’)` が加わる。

```
warning: [GHC-06201] [-Wmissing-methods]
    • No explicit implementation for
        ‘*’, ‘abs’, ‘signum’, ‘fromInteger’, and (either ‘negate’ or ‘-’)
```

`either ‘negate’ or ‘-’` は互いにデフォルト実装になっている組。
