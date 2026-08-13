# check/20-category

20 回 `# 圏` の検証コード。**外部パッケージは不要。**
`Mono.hs` は定義だけなので GHCi で読み込んで使う。`Bottom.hs` は `runghc` で動く。

|ファイル|本文の位置|内容|
|---|---|---|
|`Mono.hs`|`## 一点圏`|モノイドを「対象が 1 つの圏」とみなす `Category` インスタンス（`main` なし）|
|`Bottom.hs`|`## Hask 圏`|`seq` でファンクター則が破れること（本文は GHCi 版に差し替え済み。ここは残置）|

`## Hask 圏` の `undefined :: Int`・WHNF の例・`fmap id` と `id` の比較は、
いずれも GHCi で直接確認する（下記「実行結果」）。

## 実行結果

```text:Mono.hs（GHCi）
ghci> :load Mono.hs
[1 of 2] Compiling Main             ( Mono.hs, interpreted )
Ok, one module loaded.
ghci> Mono (Sum 3) >>> Mono (Sum 4) :: Mono (Sum Int) () ()
Mono (Sum {getSum = 7})
ghci> Mono ["a"] >>> Mono ["b"] >>> Mono ["c"] :: Mono [String] () ()
Mono ["a","b","c"]
ghci> id :: Mono (Sum Int) () ()
Mono (Sum {getSum = 0})
ghci> id :: Mono [String] () ()
Mono []
```

```text:bottom（GHCi）
ghci> undefined :: Int
*** Exception: Prelude.undefined
CallStack (from HasCallStack):
  undefined, called at <interactive>:1:1 in interactive:Ghci1
```

```text:fmap id と id（GHCi）
ghci> bot = undefined :: Int -> Int
ghci> seq (fmap id bot) 0
0
ghci> seq (id bot) 0
*** Exception: Prelude.undefined
CallStack (from HasCallStack):
  undefined, called at <interactive>:1:7 in interactive:Ghci1
ghci> fmap id bot 5
*** Exception: Prelude.undefined
CallStack (from HasCallStack):
  undefined, called at <interactive>:1:7 in interactive:Ghci1
ghci> id bot 5
*** Exception: Prelude.undefined
CallStack (from HasCallStack):
  undefined, called at <interactive>:1:7 in interactive:Ghci1
```

```text:WHNF（GHCi）
ghci> seq (1+1, 2+2) 0
0
ghci> seq (\_ -> undefined) 0
0
ghci> seq (undefined, undefined) 0
0
ghci> seq (undefined :: Int) 0
*** Exception: Prelude.undefined
CallStack (from HasCallStack):
  undefined, called at <interactive>:4:6 in interactive:Ghci4
ghci> length [undefined, undefined]
2
```

```text:Bottom.hs
\_ -> undefined は WHNF
fmap id bot は id . bot なのでラムダ
Bottom.hs: Prelude.undefined
CallStack (from HasCallStack):
  undefined, called at Bottom.hs:9:11 in main:Main
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
  値からは決まらないので、GHCi で評価する式には型注釈が必要（付けないと曖昧な型変数でエラー）。
- **恒等射はモノイド次第。** `m` を `[String]` から `Sum Int` に替えるだけで `id` は
  `Mono []` から `Mono (Sum 0)` に変わる（`id :: ...` を型注釈違いで 2 つ並べて確認）。
  `Int` 自体は `Monoid` ではない（加算とも乗算とも取れるため）ので、`Sum` で包む必要がある。
  本文ではこれに先立ち、リスト・`Sum`・`Product` の `<>` と `mempty` を GHCi で並べて示す。
- **停止しない計算（`loop = loop`）は GHCi で実演できない。** 評価すると固まり、Ctrl+C
  で中断するしかない。GHC が `<<loop>>` を検出して例外にする場合もあるが、この形では
  検出されなかった（`let loop = loop :: Int` を評価してタイムアウトを確認）。
  そのため本文では出力を載せず、コードと文章で示している。
- **WHNF は「一番外側に構築子かラムダが現れた時点」で止まる。** `(undefined, undefined)` は
  構築子 `(,)` が見えているので `seq` が通り、`undefined :: Int` は構築子が現れないので停止しない。
  `length [undefined, undefined]` が `2` を返せるのも同じ理由（構造だけを辿り要素に触れない）。
- **`seq` で `fmap id == id` が破れる。** `(->) r` の `fmap` は `.` なので
  `fmap id bot` は `id . bot`、つまりラムダ式であり WHNF に達する。
  一方 `id bot` は `bot` そのものなので `seq` で停止しない。
  引数を与えればどちらも同じ結果になるにもかかわらず、`seq` は両者を区別する。

## 言語拡張の確認

`Mono.hs` は `ghci -XHaskell2010`、`Bottom.hs` は `runghc -XHaskell2010` で通る。**言語拡張は不要。**
`Mono.hs` は `Control.Category` を import して Prelude の `id`・`.` を隠している
（19 回と同じ）。
