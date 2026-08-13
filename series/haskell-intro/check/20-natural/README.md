# check/20-natural

20 回 `# 自然変換` の検証コード。`runghc` で動く。**外部パッケージは不要。**

|ファイル|本文の位置|内容|
|---|---|---|
|`Natural.hs`|`# 自然変換`・`## 自然性`|`~>` の自作、`listToMaybe`・`maybeToList` を自前定義して自然性条件を両辺評価|

## 実行結果

```text:Natural.hs
Just "1"
Just "1"
Nothing
Nothing
["1"]
["1"]
[]
[]
```

## 確認したこと

- **自然性条件 `fmap h . alpha == alpha . fmap h` が成り立つ。**
  `listToMaybe`（`[] ~> Maybe`）と `maybeToList`（`Maybe ~> []`）の
  どちらでも、空の場合を含めて両辺が一致する。
- **`type f ~> g = forall a. f a -> g a` は型シノニムとして書ける。**
  `listToMaybe :: [] ~> Maybe` のように、型構築子を直接並べて書ける。
- **`Data.Maybe` を import せずに自前定義しても衝突しない。**
  `listToMaybe`・`maybeToList` は `Prelude` に入っていないため。

## 言語拡張の確認

|拡張|要否|
|---|---|
|`RankNTypes`|**必要**（型シノニムの右辺に `forall` を書くため）|
|`TypeOperators`|**必要**（`~>` を型の演算子として使うため）|

**どちらも GHC2021 に含まれるのでプラグマは不要。**
`runghc -XHaskell2010` では両方を明示しないと通らないことを確認した
（片方だけではエラー）。
