# check/16-teletype

16 回「テレタイプ」（本文と練習【問3】【問4】）の検証コード。すべて `runghc` で動く。

|ファイル|内容|
|---|---|
|`Teletype.hs`|`deriving Functor` 版。【問3】のスマートコンストラクタと【問4】の `runPure`（`Free` の定義を先頭に補ってある）|
|`Manual.hs`|`instance Functor TeletypeF` を手書きした版|
|`GetLength.hs`|本文「続きが関数のときの `liftF`」の `getLength`|

## 実行結果

両方とも同じ出力になる。

```text
name?
Hello, Haskell!
name?
Hello, 世界!
```

手書きの

```hs
instance Functor TeletypeF where
    fmap f (PutLine s next) = PutLine s (f next)
    fmap f (GetLine k)      = GetLine (f . k)
```

と `deriving Functor` が一致することの確認。`GetLine` は続きが関数なので、
`fmap` が関数合成 `f . k` になるところが `PutLine`（および `GenF` の `Yield`）と違う。

## 確認したこと

- `GetLength.hs`: 続きの位置に `length` を置いた `getLength = liftF (GetLine length)` が
  `Teletype Int` になり、`do` の中で `n <- getLength` として受け取れる。展開形
  `Free (GetLine (\s -> Pure (length s)))` と同じ結果になることも確認した。
  `length` を `id` に替えると `getLine'`（結果が `String`）になる、という対応。

```text
name?
length = 7
name?
Hello, Haskell!
7
7
Haskell
```

- `getLine' = liftF (GetLine id)` で `Teletype String` になり、`do` の中で
  `name <- getLine'` として受け取れる。`liftF` が `GetLine id` を
  `GetLine (\s -> Pure s)` に変えるため。
- `runPure` は `IO` を一切使わずに `greet` の振る舞いを検査できる。
  入力をリストで与え、出力をリストで受け取る。
- `Teletype.hs` には `IO` 版インタプリタ `runIO` も置いてあるが、標準入力が要るため
  `main` からは呼んでいない（本文でも解答例の中で示すだけ）。
