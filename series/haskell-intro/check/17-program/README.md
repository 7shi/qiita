# check/17-program

17 回「続きを外に出す」「GADTs で命令を並べる」「インタープリター」の検証コード。
すべて `runghc` で動く。

|ファイル|内容|
|---|---|
|`Gen.hs`|本文の掲載コード（`Program` の定義・インスタンス・`singleton`・`GenI`・`yield`・`toList` を連結）|
|`Teletype.hs`|本文の掲載コード（`TeletypeI`・`putLine`・`getLine'`・`greet`・`runPure`・`runIO`）|
|`Slow.hs`|左結合の `>>=` が遅くなることの確認（本文には数値を載せない）|

## 実行結果

```text:Gen.hs
[1,2,3]
[0,1,2,3,4]
```

16 回の `check/16-gen/Gen.hs` と同じ出力。手順書の表現が変わっても
インタープリターの結果は変わらない。

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

## 16 回との対応

|16 回（Free）|17 回（Operational）|
|---|---|
|`data GenF o next = Yield o next deriving Functor`|`data GenI o a where Yield :: o -> GenI o ()`|
|`liftF c = Free (fmap Pure c)`|`singleton i = i :>>= Return`|
|`Free (Yield o k)` をそのまま辿る|`Yield o :>>= k` の `k ()` を辿る|
