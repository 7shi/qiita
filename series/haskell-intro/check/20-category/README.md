# check/20-category

20 回 `# 圏` の検証コード。すべて `runghc` で動く。**外部パッケージは不要。**

|ファイル|本文の位置|内容|
|---|---|---|
|`Mono.hs`|`## 一点圏`|モノイドを「対象が 1 つの圏」とみなす `Category` インスタンス|
|`Bottom.hs`|`## bottom`|すべての型に bottom があること、`seq` でファンクター則が破れること|

## 実行結果

```text:Mono.hs
Mono ["a","b","c"]
Mono ["a"]
Mono ["a"]
True
Mono (Sum {getSum = 7})
```

```text:Bottom.hs
Int の undefined も型としては通る
\_ -> undefined は WHNF
fmap id bot は id . bot なのでラムダ
Bottom.hs: Prelude.undefined
CallStack (from HasCallStack):
  undefined, called at Bottom.hs:11:11 in main:Main
```

## 確認したこと

- **関係の圏 `newtype Rel a b = Rel (a -> b -> Bool)` は `Category` のインスタンスにできない。**
  `id = Rel (==)` に `Eq a`、合成の全探索に `Bounded b`・`Enum b` が必要になるが、
  `Category` のメソッドには型クラス制約を足せない。

  ```text
  error: [GHC-39999] No instance for 'Eq a' arising from a use of '=='
  error: [GHC-39999] No instance for 'Enum b'
  ```

  代わりに一点圏（モノイド）を採用した。射がモノイドの要素で関数ですらないため、
  「`id` は恒等関数ではなく単位元」という 19 回の指摘が一段はっきりする。
- **`Mono` の `.` は `<>` の引数の順を入れ替えたもの。** `Mono g . Mono f = Mono (f <> g)`。
  `.` は右から左へ合成するので、モノイドの並びとしては `f` が先に来る。
- **対象が 1 つであることは型では強制していない。** `a`・`b` は使われない型引数（phantom）で、
  `Mono [String] () ()` のように `()` に固定して「対象が 1 つ」とみなす約束にしている。
- **恒等射はモノイド次第。** `m` を `[String]` から `Sum Int` に替えるだけで `id` は
  `Mono []` から `Mono (Sum 0)` に変わる（`step` と `cost` を同じファイルで並べて確認）。
  `Int` 自体は `Monoid` ではない（加算とも乗算とも取れるため）ので、`Sum` で包む必要がある。
  本文ではこれに先立ち、リスト・`Sum`・`Product` の `<>` と `mempty` を GHCi で並べて示す。
- **`seq` で `fmap id == id` が破れる。** `(->) r` の `fmap` は `.` なので
  `fmap id bot` は `id . bot`、つまりラムダ式であり WHNF に達する。
  一方 `id bot` は `bot` そのものなので `seq` で停止しない。
  引数を与えればどちらも同じ結果になるにもかかわらず、`seq` は両者を区別する。

## 言語拡張の確認

2 ファイルとも `runghc -XHaskell2010` で通る。**言語拡張は不要。**
`Mono.hs` は `Control.Category` を import して Prelude の `id`・`.` を隠している
（19 回と同じ）。
