# deriving の検証（記事「deriving」の節）

GHC 9.6.6。実行は `runghc {ファイル名}`。

| ファイル | 内容 |
|---|---|
| `Deriving.hs` | `deriving (Show, Read)` を使った場合 |

手で `instance Read Color` を書いた版は練習【問2】の解答例として
`../14-exercises/Q2ReadColor.hs` にある。

## 実行結果

```
Blue
Red
```

## 補足: showsPrec

引数を持つコンストラクタでは `show` だけの手書きと `deriving` で結果が異なる。

```hs
data Shape = Circle Double

instance Show Shape where
    show (Circle r) = "Circle " ++ show r
```

`print (Just (Circle 1))` は `Just Circle 1.0` となり括弧が付かない。
`deriving Show` は優先順位を考慮する `showsPrec` の方を生成するため
`Just (Circle 1.0)` のように括弧が付く。

練習を `Show` の手書きから `Read` の手書きに差し替えたため、この注記は
記事本文からは落とした（記録として残す）。
