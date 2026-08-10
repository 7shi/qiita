# check/18-effectful

18 回の `# effectful パッケージ`・`# モナド変換子との比較` の掲載コード（2026-08-09）。

|ファイル|内容|
|---|---|
|`Teletype.hs`|17 回の `TeletypeI` を効果にし、`State` を `greet` から直接使う（**記事には載せていない**。既製の効果の節を `Counter` 版に差し替えたため）|
|`Counter.hs`|`Counter` のハンドラーを `IORef` で書いた版（**記事には載せていない**。`State` 版に一本化したため）|
|`CounterState.hs`|**掲載コード（`## 状態を持つ効果`・`## 全体を動かす`）。** `Teletype` に加えて `Counter` も効果にし、ハンドラーは `reinterpret_` + 既製の `State`|
|`StateWriter.hs`|`State` と `Writer` を混ぜ、**ハンドラーの適用順を入れ替えて結果を比べる**|
|`Sum.hs`|**10 回（モナド変換子）の `sum'` を `Eff` で書き直したもの**|
|`SumWriter.hs`|**練習【問2】の解答例。** `Sum.hs` に `Writer` を足し、`IO` を使わない形にする|

## 実行方法

`effectful` は GHC に同梱されていないため、[Stack](https://docs.haskellstack.org/) で導入する。
**現行 LTS（lts-24.53、`effectful-2.6.1.0`）をそのまま使う。**

```
echo alice | stack script --resolver lts-24.53 --package effectful Teletype.hs
echo alice | stack script --resolver lts-24.53 --package effectful Counter.hs
echo alice | stack script --resolver lts-24.53 --package effectful CounterState.hs
stack script --resolver lts-24.53 --package effectful StateWriter.hs
stack script --resolver lts-24.53 --package effectful Sum.hs
stack script --resolver lts-24.53 --package effectful SumWriter.hs
```

⚠ この環境の stack は次の警告を出す。**動作には影響しない。**

```text
Stack has not been tested with GHC versions above 9.4, and using 9.10.3, this may fail
Stack has not been tested with Cabal versions above 3.8, but version 3.12.1.0 was found, this may fail
```

## 実行結果

```text:Teletype.hs（標準入力: alice）
name?
Hello, alice! (0)
1
```

```text:Counter.hs・CounterState.hs（標準入力: alice。両者とも同じ）
name?
Hello, alice! 0
```

```text:StateWriter.hs
(((),1),["n = 0"])
(((),["n = 0"]),1)
```

```text:Sum.hs・SumWriter.hs（両者とも同じ）
+1 -> 1
+2 -> 3
+3 -> 6
+4 -> 10
+5 -> 15
15
```

## 確認したこと

- **17 回の `TeletypeI` は、2 点足すだけで効果になる。** 命令の型に `m` 引数を付けることと、
  ディスパッチ方式の宣言。

  ```hs
  data Teletype :: Effect where
      PutLine :: String -> Teletype m ()
      GetLine ::           Teletype m String

  type instance DispatchOf Teletype = Dynamic
  ```

  `m` は高階効果（ハンドラーが `Eff` の計算を受け取る効果。`local`・`catch` など）の
  ための引数で、今回のような一階の効果では使わない。
- **`Member` 制約は `:>` で書く。** `Teletype :> es` は `check/18-union`・`check/18-env` で
  自作したものと同じ形。
- **ハンドラーは `interpret_`。** 効果を 1 つ剥がす関数を作る。

  ```hs
  runTeletypeIO :: IOE :> es => Eff (Teletype : es) a -> Eff es a
  runTeletypeIO = interpret_ $ \op -> case op of
      PutLine s -> liftIO $ putStrLn s
      GetLine   -> liftIO getLine
  ```

  - `interpret` の方は第 1 引数に `LocalEnv` を取る（高階効果でのみ使う）。
    一階の効果では `interpret_` を使えばこの引数が出てこない。
  - **`interpret_` は `effectful-2.5.1.0` 以降。** lts-22.28 の 2.3.1.0 には無く、
    `interpret $ \_ op -> case op of ...` と書く必要がある。
- **状態を持つハンドラーは 2 通り書ける**（`Counter.hs`・`CounterState.hs`。出力は同じ）。
  **記事は後者だけを載せる**（`IORef` 版は自作実装で既に見せているため、繰り返さない）。
  - `IORef` を `interpret_` の外側で作ってキャプチャする（`check/18-env` の自作版と同じ形。
    `Eff $ \_ -> ...` が `liftIO` に変わるだけ）。`IO` を使うので `IOE :> es` が付く。
  - `reinterpret_ (evalState n0)` で既製の `State` に委ねる。`reinterpret_` は剥がした効果を
    別の効果で実装するための関数で、`IOE` が不要になる。`greet` の型は両者で変わらない。
- **ハンドラーの適用順はどちらでも通る**（`runEff $ runTeletypeIO $ runCounter 0 greet` と
  `runEff $ runCounter 0 $ runTeletypeIO greet` の両方を確認）。記事は自作版の
  `run (runTeletype (runCounter 0 greet))` に合わせて前者にした。
- **`lift` が要らない**（`Sum.hs`）。10 回では `lift $ putStrLn ...` だったところが
  `liftIO $ putStrLn ...` になる。持ち上げの回数を数える必要が無い。
  - `runEff :: Eff '[IOE] a -> IO a` で最後に `IO` を取り出す。
  - 純粋な計算は `runPureEff :: Eff '[] a -> a`。
- **ハンドラーの適用順は自由**（`StateWriter.hs`）。`:>` 制約で書いておけば、
  `runWriter . runState` でも `runState . runWriter` でも通り、結果のタプルの入れ子が
  変わる。モナド変換子でスタックの順序を決め打ちするのとの対比になる。
  - `runWriter @[String]` の型適用が要るのは、`w` が `es` から一意に決まらないため。
- **既製の効果は `mtl` の型ではなく `Eff` 用の互換実装。** `Effectful.State.Static.Local` の
  `State` に対して `Control.Monad.State` の `modify` を使うとエラーになる（2026-08-11 確認）。

  ```text
  Could not deduce ‘effectful-core-2.6.1.0:Effectful.Internal.MTL.State Int :> es’
    arising from a use of ‘M.modify’
  from the context: State Int :> es
  ```

  `mtl` のクラスに合わせるための効果が内部に別途あることがエラーから分かるが、記事では触れない。
- **既製の効果のモジュール名は Static/Dynamic・Local/Shared に分かれている。**
  記事では `Effectful.State.Static.Local`・`Effectful.Writer.Static.Local` に決め打ちする。

### 型推論の落とし穴

**`get` の型は決まらないことがある。** `get :: State s :> es => Eff es s` で、`s` は `es` から
一意に決まらない（関数従属が無い）ので、`n <- get` した `n` の型が曖昧になることがある。
`show (n :: Int)` のように使う側で決めるか、型注釈が要る。`freer-simple` でも同じだった。

## 必要な言語拡張

**`DataKinds` が必須**（型レベルリスト `'[...]` のため）。効果を自作するなら `GADTs` と
`TypeFamilies`（`type instance DispatchOf`）も要る。`Sum.hs`・`StateWriter.hs` は
`DataKinds` だけで通る。

`\case` は GHC2021 に含まれないので、掲載コードでは `\op -> case op of` と書く。
