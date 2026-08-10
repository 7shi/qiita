# check/18-env

18 回の `# 同じ型、別の実装` の掲載コード（2026-08-09）。

`check/18-union/` と**型・API・出力が同じまま、実装だけを差し替えた**もの。
手順書をデータとして組み立てるのをやめ、ハンドラーの環境を受け取る関数にしている。
これが `effectful` の骨格にあたる。

|ファイル|内容|
|---|---|
|`Env.hs`|`Eff`・`Env`（`ENil`/`ECons`）・`:>`・`send`・`interpret`・`run` と、2 つの効果（`Teletype`・`Counter`）|
|`Logger.hs`|**練習【問2】の解答例。** `18-union/Logger.hs`（問1）と同じ `Logger` をこの実装で書き直したもの|

## 実行方法

**パッケージ不要。`runghc` で動く。**

```
echo alice | runghc Env.hs
echo alice | runghc Logger.hs
```

```text:Env.hs（標準入力: alice）
name?
Hello, alice! 0
```

```text:Logger.hs（標準入力: alice）
name?
Hello, alice! 0
got alice
tick 0
```

**`check/18-union/` の対応するファイルと出力が完全に一致する。**

```
diff <(echo alice | runghc ../18-union/Union.hs)  <(echo alice | runghc Env.hs)
diff <(echo alice | runghc ../18-union/Logger.hs) <(echo alice | runghc Logger.hs)
```

## 確認したこと

- **`Eff` は手順書ではなく関数。** 環境を受け取って `IO` を返す。

  ```hs
  newtype Eff es a = Eff { unEff :: Env es -> IO a }

  data Env es where
      ENil  :: Env '[]
      ECons :: (forall x. e x -> IO x) -> Env es -> Env (e ': es)
  ```

  `Env es` は効果のリストと同じ長さの、ハンドラーの列。`forall x.` が要るのは、
  1 つのハンドラーが `PutLine :: Teletype ()` と `GetLine :: Teletype String` の
  どちらにも使えなければならないため。17 回の `interpretWithMonad` と同じ事情。
- **`send` は命令をデータにせず、その場で実行する。** 環境から自分の効果のハンドラーを
  引いて適用するだけ。

  ```hs
  send :: e :> es => e a -> Eff es a
  send op = Eff $ \env -> handler env op
  ```

- **`interpret` は環境を 1 つ伸ばす。** 効果を 1 つ剥がす関数、という見え方は
  `18-union` と同じだが、中身は「ハンドラーを環境に積んで内側を走らせる」。

  ```hs
  interpret :: (forall x. e x -> Eff es x) -> Eff (e ': es) a -> Eff es a
  interpret f (Eff m) = Eff $ \env -> m (ECons (\op -> unEff (f op) env) env)
  ```

- **`:>` は `18-union` と同じ形の重なるインスタンス 2 本。** 違いは、位置を数えて
  `Union` を作るのではなく、環境から該当するハンドラーを取り出す点だけ。
  **実際の `effectful` も `{-# OVERLAPPING #-}` を使っている**
  （`effectful-core/src/Effectful/Internal/Effect.hs:52`）。
- **状態は `IORef` で持つ。** `runCounter` はカウンターを `IORef` に置き、ハンドラーが
  読み書きする。`18-union` ではインタープリターの引数として持ち回っていた。
  `effectful` の `State` も同じく `IORef` 方式（`Static.Local` はスレッドローカル）。
- **結果の型を変えるハンドラー（`runLogger`）は `interpret` の外側で組み立てる。**
  `interpret` が返せるのは `Eff es a` だけなので、`IORef` に記録を溜めて
  `interpret` の適用後に読み出し、`(a, [String])` に組み直す。
  `18-union` では手順書を辿りながら継続の結果にリストを継ぎ足していた部分。

  ```hs
  runLogger :: Eff (Logger ': es) a -> Eff es (a, [String])
  runLogger m = do
      r <- Eff $ \_ -> newIORef []
      a <- interpret (\(Log s) -> Eff $ \_ -> modifyIORef r (s :)) m
      ls <- Eff $ \_ -> readIORef r
      return (a, reverse ls)
  ```

  - `modifyIORef r (s :)` は先頭に足すので、最後に `reverse` する。
  - 命令が 1 つなので `\(Log s) -> ...` と直接パターンマッチできる（`runCounter` の `\Tick` と同じ）。
- **`run :: Eff '[] a -> IO a`。** 空の環境 `ENil` を渡すだけ。
  `18-union` の `run :: Eff '[] a -> a` と違って `IO` が出るのは、この実装が
  `IO` の上に載っているため。`effectful` の `runPureEff` は
  `unsafeDupablePerformIO` でこれを隠している。

## 必要な言語拡張

**GHC2021 基準（16 回で確定）。pragma は `DataKinds`・`GADTs` の 2 つだけ。**
どちらも GHC2021 に含まれないため。

`runghc -XHaskell2010` に掛けて洗い出した結果（2026-08-10 に 1 つずつ外して確認）、
Haskell2010 では次も要る。いずれも GHC2021 に含まれるので pragma は書かない。

|拡張|理由|
|---|---|
|`RankNTypes`|`ECons` のフィールドと `interpret`・`handler` の引数の `forall x.`|
|`TypeOperators`|型に `':`・`:>` を使う|
|`MultiParamTypeClasses`|`:>` が型変数を 2 つ取る|
|`FlexibleInstances`|インスタンスの頭が `e ': es`|
|`FlexibleContexts`|`greet` の制約が `Teletype :> es`|

`Logger.hs` も同じ拡張で通る（2026-08-11 に確認）。`EmptyCase` は要らない。

`RankNTypes` が要るのは `18-union` との違い（あちらは `EmptyCase` が要る）。
**このシリーズで `forall` を「使う」のではなく「自分で書く」のは 18 回が初めて**
（09 回の `runST`・17 回の `interpretWithMonad` は利用側なので拡張不要。
`check/17-package/README.md` の「`forall` の確認」を参照）。
