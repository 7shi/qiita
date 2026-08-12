# check/20-kleisli

20 回 `# Kleisli 圏` の検証コード。`runghc` で動く。**外部パッケージは不要。**

|ファイル|本文の位置|内容|
|---|---|---|
|`Kleisli.hs`|`# Kleisli 圏`|`a -> [b]` の `>=>` 合成で圏の公理（結合律・単位律）を確認|

## 実行結果

```text:Kleisli.hs
[4,6]
[5,8,7,12]
[6,10,9,16,8,14,13,24]
True
True
True
[5,8,7,12]
```

## 確認したこと

- **題材は非決定性計算。** `step n = [n + 1, n * 2]` を `>=>` でつなぐと、
  何手で到達できる値がすべて並ぶ。19 回の `parse`／`half`（`Maybe`）と重ならない。
- **圏の公理が成り立つ。** `return >=> step == step`・`step >=> return == step`・
  `(step >=> step) >=> step == step >=> (step >=> step)` の 3 つがすべて `True`。
  これは 15 回で `>=>` に書き直したモナド則そのもの。
- **`Kleisli` の `>>>` は `>=>` と同じ結果を返す。**
  `runKleisli (Kleisli step >>> Kleisli step) 3` と `(step >=> step) 3` が
  どちらも `[5,8,7,12]`（19 回の確認の再掲）。

## 言語拡張の確認

`runghc -XHaskell2010` で通る。**言語拡張は不要。**
