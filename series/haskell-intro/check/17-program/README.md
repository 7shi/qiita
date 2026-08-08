# check/17-program

17 回「続きを命令の型から外す」「命令の型を GADT で並べる」「インタープリター」の検証コード。
すべて `runghc` で動く。

|ファイル|内容|
|---|---|
|`Gen.hs`|本文の掲載コード（`Program` の定義・インスタンス・`singleton`・`GenI`・`yield`・`toList` を連結）|
|`Show.hs`|本文「`Show` は書けるのか」の掲載コード（`Gen.hs` に `instance Show (Gen o a)` を足したもの）|
|`Teletype.hs`|本文の掲載コード（`TeletypeI`・`putLine`・`getLine'`・`greet`・`runPure`・`runIO`）|
|`Slow.hs`|左結合の `>>=` が遅くなることの確認（本文には数値を載せない）|

## 実行結果

```text:Gen.hs
[1,2,3]
[0,1,2,3,4]
```

16 回の `check/16-gen/Gen.hs` と同じ出力。手順書の表現が変わっても
インタープリターの結果は変わらない。

```text:Show.hs
Yield 1 :>>= 
  Yield 2 :>>= 
  Yield 3 :>>= 
  Return ()
```

`Show` は書けるが、`k ()` を適用して辿る骨組みは `toList` と同じ
（本文でこれを「インタープリターである」と述べた）。

```text:Teletype.hs
name?
Hello, Haskell!
name?
Hello, 世界!
```

16 回の `check/16-teletype` と同じ出力。

## 言語拡張の確認

`{-# LANGUAGE GADTs #-}` を外して `runghc -XHaskell2010` に掛けると、
GADT 構文の `data ... where` だけがエラーになる。

```text
error:
    • Illegal generalised algebraic data declaration for ‘Program’
        (Enable the GADTs extension to allow this)
```

必要な拡張は GADTs のみ。`ExistentialQuantification` などは不要
（`:>>=` の `b` は GADT 構文の中で完結するため）。

ただし `Show.hs` だけは例外で、Haskell2010 では `TypeSynonymInstances` と
`FlexibleInstances` が追加で要る（`Gen o` が型シノニムのため）。
`runghc -XHaskell2010 -XGADTs -XTypeSynonymInstances -XFlexibleInstances Show.hs`
で通ることを確認済み。GHC2021 では両方とも既定で有効なので、本文の記述は正しい。

## 左結合の `>>=`（`Slow.hs`）

16 回の `check/16-gen/Slow.hs` と同じ形で実測。本文には現象と理由だけを書いた。

```
ghc -dynamic -O2 -o slow Slow.hs
./slow right N   # yield 1 >> (yield 2 >> (yield 3 >> ...))
./slow left  N   # ((yield 1 >> yield 2) >> yield 3) >> ...
```

|N|right|left|
|---|---|---|
|2000|0.016 s|0.026 s|
|4000|0.016 s|0.066 s|
|8000|0.016 s|0.246 s|
|16000|0.016 s|1.026 s|

right はほぼ一定、left は N を 2 倍にすると約 4 倍。Free と同じく二乗のオーダー。
`(i :>>= j) >>= k = i :>>= (\b -> j b >>= k)` が左側の構造を 1 段ずつ剥がすため、
左に積み上がった手順書に 1 つ足すたびに先頭から辿り直すことによる。

⚠ **これは自作版に限った話で、`operational` パッケージでは起きない**
（`check/17-package/Slow.hs` で計測。40 万要素でもほぼ線形）。
本文の `## 性能の注意` は初稿でこの区別を欠いていたので、推敲で書き分けた。

## 16 回との対応

|16 回（Free）|17 回（Operational）|
|---|---|
|`data GenF o next = Yield o next deriving Functor`|`data GenI o a where Yield :: o -> GenI o ()`|
|`liftF c = Free (fmap Pure c)`|`singleton i = i :>>= Return`|
|`Free (Yield o k)` をそのまま辿る|`Yield o :>>= k` の `k ()` を辿る|
