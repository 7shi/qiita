# check/19-profunctor

19 回の `## Profunctor` の掲載コード（2026-08-13）。

|ファイル|内容|
|---|---|
|`Profunctor.hs`|**掲載コード。** `Arrow` の `first`・`left` と `Strong` の `first'`・`Choice` の `left'` を並べて比べ、`dimap` も試す|

## 実行方法

`profunctors` は GHC に同梱されていないため、[Stack](https://docs.haskellstack.org/) で導入する。
**16〜18 回と同じ lts-24.53（`profunctors-5.6.3`）を使う。**
2026-08-13 時点の最新は lts-24.54 だが、`profunctors` のバージョンは同じで、
シリーズの表記を揃えるため 24.53 のままにしている（どちらでも実行して確認済み）。

```
stack script --resolver lts-24.53 --package profunctors Profunctor.hs
```

## 実行結果

```text:Profunctor.hs
(2,"a")
(2,"a")
Left 2
Left 2
"2"
```

## 確認したこと

- **`first` と `first'`、`left` と `left'` は関数に対して同じ結果を返す。** `(->)` は `Arrow`・
  `ArrowChoice` と `Strong`・`Choice` のどちらのインスタンスでもあるため、同じ操作が 2 つの
  語彙で書ける。
- **名前の衝突はない。** `Data.Profunctor` は `first`・`left` を export しないので、
  `Control.Arrow` と同時に import してもそのまま通る（`first'`・`left'` のように `'` が付く）。
- `dimap read show ((+ 1) :: Int -> Int) "1"` が `"2"`。`lmap`（入力側）と `rmap`（出力側）を
  まとめたもので、`read >>> (+ 1) >>> show` にあたる。

## 言語拡張の確認

`stack script --resolver lts-24.53 --package profunctors --ghc-options -XHaskell2010` でも通る。
**言語拡張は 1 つも必要ない。**
