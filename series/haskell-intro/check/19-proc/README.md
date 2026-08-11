# check/19-proc

19 回「proc 記法」の検証コード。`runghc` で動く。

|ファイル|内容|
|---|---|
|`Proc.hs`|`proc x -> do y <- f -< x` の形。本文の `mean` と練習【問2】の `spread`|

## 実行結果

```text:Proc.hs
2.5
4
```

`check/19-basics/Mean.hs` と同じ `2.5`・`4`。同じ配線が `&&&` と `proc` の
2 通りで書けることの確認。

## 言語拡張の確認

**`Arrows` は GHC2021 に含まれない。** pragma を外すと構文エラーになる。

```text
error: [GHC-58481] parse error on input ‘->’
  |
4 | mean = proc xs -> do
  |                ^^
```

pragma があれば `runghc -XHaskell2010` でも通る。**必要な拡張は `Arrows` だけ。**

- 16 回の `DeriveFunctor`（便利のため）・17 回の `GADTs`（表現力のため）に対して、
  `Arrows` は**構文のための拡張**。書き方が変わるだけで、書けるものは増えない
  （`proc` で書いたものは `arr`・`>>>`・`&&&` に展開される）。

## proc の中の `if`

`proc` の中で `if` を使うと `ArrowChoice` が要る。関数アロー（`(->)`）は
`ArrowChoice` のインスタンスなのでそのまま通るが、自作アローでは自分で書く必要がある
（`check/19-parser/Parser.hs` の `ab`）。
