# check/20-functor

20 回 `# 関手` の検証コード。`runghc` で動く。**外部パッケージは不要。**

|ファイル|本文の位置|内容|
|---|---|---|
|`Functor.hs`|`# 関手`|射の対応としての `fmap`、ファンクター則の確認|

## 実行結果

```text:Functor.hs
Just 4
[2,3,4]
Right 4
True
True
True
True
```

## 確認したこと

- **`fmap` は射 `a -> b` を射 `f a -> f b` に移す。** `Maybe`・`[]`・`Either String` の
  3 つで同じ関数 `(+1)` が持ち上がる。対象の対応（型構築子の適用）は型に現れ、
  射の対応は `fmap` に現れる。
- **ファンクター則が成り立つ。** `fmap id == id` と
  `fmap (f . g) == fmap f . fmap g` の両辺を評価して一致を確認した。
  ただし bottom を含めると `(->)` で破れる（`check/20-category/Bottom.hs`）。

## 言語拡張の確認

`runghc -XHaskell2010` で通る。**言語拡張は不要。**
