# check/16-gen

16 回「手順書を組み立てる」「インタプリタ」の検証コード。すべて `runghc` で動く。

|ファイル|内容|
|---|---|
|`Gen.hs`|本文の掲載コード（`Free` の定義を先頭に補って連結）。`GenF`・`liftF`・`yield`・`toList`|
|`GenIO.hs`|【問2】`IO` 版インタプリタ|
|`Slow.hs`|左結合の `>>=` が遅くなることの確認（本文には載せない）|

## 実行結果

```text:Gen.hs
[1,2,3]
[1,2,3]
[0,1,2,3,4]
```

- 1 行目が `do` で組んだ `count`、2 行目が手で組んだ
  `Free (Yield 1 (Free (Yield 2 (Free (Yield 3 (Pure ()))))))`。
  一致するので、`do` が組み立てているデータの形が確認できた。
- 3 行目は無限の手順書 `mapM_ yield [0 ..]` に `take 5` を掛けたもの。
  遅延評価により先頭から必要な分だけ辿られる。

```text:GenIO.hs
[1,2,3]
1
2
3
```

同じ `count` から `toList`（リスト）と `runIO`（`IO`）の 2 つの結果が得られている。

## `DeriveFunctor` の確認

手書きの

```hs
instance Functor (GenF o) where
    fmap f (Yield o next) = Yield o (f next)
```

と `deriving Functor` は同じ結果になる。GHCi での確認:

```text:GHCi
ghci> let Yield o n = fmap (+ 1) (Yield 'a' (10 :: Int)) in (o, n)
('a',11)
```

出力値 `o` は触られず、続き `next` にだけ関数が適用される。

## 左結合の `>>=`（`Slow.hs`）

本文では `:::message` で数行触れるだけだが、実測して裏を取った。

```
ghc -dynamic -O2 -o slow Slow.hs
./slow right N   # yield 1 >> (yield 2 >> (yield 3 >> ...))
./slow left  N   # ((yield 1 >> yield 2) >> yield 3) >> ...
```

|N|right|left|
|---|---|---|
|2000|0.016 s|0.046 s|
|4000|0.015 s|0.146 s|
|8000|0.016 s|0.606 s|
|16000|0.016 s|2.626 s|

right は N に対してほぼ一定（出力の `sum` を取るだけの時間）、left は N を 2 倍にすると
時間が約 4 倍になっており、二乗のオーダーになっている。`Free g >>= k` が枝を `fmap` で
辿るため、左に積み上がった木を後ろに 1 つ足すたびに先頭から辿り直すことによる。

なお `ghc` でコンパイルする場合、この環境では `-dynamic` が必要。付けないと
「There are files missing in the `base-4.18.2.1` package」というエラーになる。
`runghc` は `-dynamic` なしでも動く。
