# check/17-package

17 回「operational パッケージ」の検証コード。

|ファイル|内容|
|---|---|
|`Package.hs`|本文の掲載コード（`TeletypeI`・`greet`・`view` を使う `run`・`interpretWithMonad`）|
|`Slow.hs`|左結合の `>>=` の計測。**パッケージ版では二乗にならない**ことの確認（本文には数値を載せない）|
|`Forall.hs`|`interpretWithMonad` の第 1 引数が `forall a.` を要求することの確認|

## 実行方法

`operational` は GHC に同梱されていないため、stack でパッケージを指定する
（lts-22.28 に `operational-0.2.4.2` が収録されている）。

```
stack script --resolver lts-22.28 --package operational Package.hs
```

## 実行結果（標準入力: alice、carol）

```text
name?
Hello, alice!
name?
Hello, carol!
```

## 確認したこと

- `Control.Monad.Operational` の `Program`・`singleton`・`view`・`ProgramView`
  （`Return`・`:>>=`）・`interpretWithMonad` が本文の記述どおりに動く。
- `view` の戻り値 `ProgramView` は `Show` インスタンスを持たない
  （`print (view prog)` は型エラー）。パターンマッチで 1 段ずつ剥がす用途。
- `view` を使う `run` と `interpretWithMonad` で同じ結果になる。

## 左結合の `>>=`（`Slow.hs`）

**自作版と違い、パッケージ版は左結合でも二乗にならない。**

```
stack script --resolver lts-22.28 --package operational --optimize Slow.hs
```

|N|right|left|
|---|---|---|
|50000|0.007 s|0.006 s|
|100000|0.008 s|0.022 s|
|200000|0.019 s|0.043 s|
|400000|0.060 s|0.084 s|

N を 2 倍にすると時間もおおむね 2 倍で、ほぼ線形。**40 万要素でも 0.084 s** で、
自作版が 1.6 万要素に 1.026 s かかるのと桁違い（`check/17-program/README.md` の表）。

理由は内部表現の違い。`ghci` で確認すると `Program instr` は
`ProgramT instr Identity` の型シノニムで、`ProgramT` のコンストラクターは
`Lift`・`Bind`・`Instr` の 3 つ。

```
Bind :: ProgramT instr m b -> (b -> ProgramT instr m a) -> ProgramT instr m a
```

`>>=` はその場で関数を合成せず `Bind` として溜め、`view` が 1 段求められるたびに
必要な分だけ右結合へ組み替える。組み替えを後回しにするので辿り直しが起きない。
**`## Freer モナド` の `FTCQueue` と同じ「再結合を遅らせる」解法を、キューではなく
木で実現している。**

⚠ 初稿では本文の `## 性能の注意` が `# operational パッケージ` の小見出しでありながら、
自作版の実測値（`check/17-program/Slow.hs`）で「パッケージも遅い」と読める記述だった。
この計測で誤りと分かり、推敲で修正した（17-PLAN「推敲時の変更点」）。

## その他の確認（`ghci`）

- `Program instr = ProgramT instr Identity`、`ProgramView instr = ProgramViewT instr Identity`
  の型シノニム。本文の `data ProgramView instr a where ...` は `ProgramViewT` を
  `Identity` で固定した形を示した簡略表記だが、コンストラクター `Return`・`:>>=` は
  実際に存在し、パターンマッチできるので齟齬はない。
- `interpretWithMonad` の実際の型はランク 2。

  ```
  interpretWithMonad
    :: forall (instr :: * -> *) (m :: * -> *) b.
       Monad m => (forall a. instr a -> m a) -> Program instr b -> m b
  ```

## `forall` の確認（`Forall.hs`）

**利用する側に `RankNTypes` は不要。** `forall` はライブラリの型の中にあり、
`Package.hs`・`Forall.hs` とも `GADTs` だけで動く。

|渡し方|可否|
|---|---|
|型を書いた名前付き関数（`interp :: TeletypeI a -> IO a`）|**OK**|
|その場のラムダ式|**OK**（期待される型が伝播する）|
|型を書かない `let` 束縛|**NG**（下記）|

```text
error: [GHC-25897]
    • Could not deduce ‘p ~ IO ()’ … f :: TeletypeI a -> p
```

⚠ 推敲の途中で「ラムダで書こうとすると詰まる」と述べたが、**実測すると通る**。
GHC が期待される型をラムダへ伝播させるため。本文は「型を書かずに `let` で定義して
渡すと型が合わない」という正しい方の記述にした。
