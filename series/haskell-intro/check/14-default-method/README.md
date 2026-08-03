# デフォルト実装の検証（記事「デフォルト実装」の節）

GHC 9.6.6。実行は `runghc {ファイル名}`。

| ファイル | 内容 |
|---|---|
| `EqColor.hs` | `instance Eq Color` で `==` だけ実装し、`/=` がデフォルト実装で動くことを確認 |
| `EqNoMethod.hs` | どちらも実装しない場合。コンパイルは通るが実行すると無限ループ |

## 実行結果

`EqColor.hs`:

```
True
False
True
False
```

3行目の `Blue /= Red` は `/=` を定義していないがデフォルト実装 `not (x == y)` が働く。

`EqNoMethod.hs`: `runghc -Wall` で警告が出る（コンパイル自体は成功）。

```
EqNoMethod.hs:3:10: warning: [GHC-06201] [-Wmissing-methods]
    • No explicit implementation for
        either ‘==’ or ‘/=’
    • In the instance declaration for ‘Eq Color’
```

実行するとデフォルト実装同士が呼び合って停止しない（20秒で打ち切って確認）。

## 最小完全定義（GHCi）

```
ghci> :info Eq
type Eq :: * -> Constraint
class Eq a where
  (==) :: a -> a -> Bool
  (/=) :: a -> a -> Bool
  {-# MINIMAL (==) | (/=) #-}
（略）
```
