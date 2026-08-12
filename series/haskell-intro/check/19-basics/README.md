# check/19-basics

19 回「関数合成を一般化する」「アローの部品」「モナドにはできない」の検証コード。
すべて `runghc` で動く。**外部パッケージは不要**（`Control.Arrow` は base 同梱）。

|ファイル|本文の位置|内容|
|---|---|---|
|`Compose.hs`|`# 関数合成を一般化する`|`.` と `>>>`、`Kleisli` の `>>>` と `>=>` の一致|
|`Parts.hs`|`# アローの部品`|`arr`・`&&&`・`***`・`first`・`second`|
|`Mean.hs`|〃・練習【問1】|配線の例（`mean`）と `spread`|
|`Kleisli.hs`|練習【問4】|`Kleisli` のパイプラインと `app`|

## 実行結果

```text:Compose.hs
3
3
Just 5
Nothing
Just 5
Nothing
```

```text:Parts.hs
(4,6)
(4,"4")
(2,"x")
("x",2)
2
```

```text:Mean.hs
2.5
4
```

```text:Kleisli.hs
Just 50
Nothing
Just 4
Just 8
Nothing
```

## 確認したこと

- **`Kleisli` の `>>>` は `>=>` と同じ。** `runKleisli (Kleisli parse >>> Kleisli half) "10"` と
  `(parse >=> half) "10"` がどちらも `Just 5`。15 回の `>=>` がそのままアローの合成になる。
- **`Kleisli Maybe` は `ArrowApply`。** `Kleisli.hs` の `choose` が `app` で
  値によって次のアローを選んでいる（`-8` → `Just 8` は `half` を通らず `negate` だけ）。
  モナドから作ったアローは動的な側にいる、という主張の裏付け。
  静的パーサ側の実験は `check/19-parser/Apply.hs`。
- `first` は Prelude ではなく `Control.Arrow` のもの（`Data.Bifunctor` の `first` とは別）。

## 言語拡張の確認

4 ファイルとも `runghc -XHaskell2010` で通る。**この節の範囲では言語拡張は 1 つも要らない。**
