# 型クラス制約の検証（記事「型クラス制約」の節）

GHC 9.6.6。実行は `runghc {ファイル名}`。

| ファイル | 内容 |
|---|---|
| `Constraint.hs` | `Eq a =>` と複数制約 `(Eq a, Show a) =>` |
| `ShowList.hs` | `instance Show a => Show [a]` により `[Color]`・`[[Color]]`・`Maybe [Color]` が表示できる |

## 実行結果

`Constraint.hs`:

```
same
different
1 == 1
'a' /= 'b'
```

`ShowList.hs`:

```
[Blue,Red]
[[Blue],[Red,Green]]
Just [Blue,Red]
```

`deriving Show` で `Show Color` を用意しただけで、制約付きインスタンスが再帰的に
組み立てられて入れ子も表示できる。
