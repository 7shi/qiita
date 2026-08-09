# check/18-env

18 回の `# 同じ型、別の実装` の掲載コード（2026-08-09）。

`check/18-union/` と**型・API・出力が同じまま、実装だけを差し替えた**もの。
手順書をデータとして組み立てるのをやめ、ハンドラーの環境を受け取る関数にしている。
これが `effectful` の骨格にあたる。

|ファイル|内容|
|---|---|
|`Env.hs`|`Eff`・`Env`（`ENil`/`ECons`）・`:>`・`send`・`interpret`・`run` と、2 つの効果（`Teletype`・`Counter`）|

## 実行方法

**パッケージ不要。`runghc` で動く。**

```
echo alice | runghc Env.hs
```

```text:実行結果
name?
Hello, alice! 0
```

**`check/18-union/Union.hs` と出力が完全に一致する。**

```
diff <(echo alice | runghc ../18-union/Union.hs) <(echo alice | runghc Env.hs)
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
- **`run :: Eff '[] a -> IO a`。** 空の環境 `ENil` を渡すだけ。
  `18-union` の `run :: Eff '[] a -> a` と違って `IO` が出るのは、この実装が
  `IO` の上に載っているため。`effectful` の `runPureEff` は
  `unsafeDupablePerformIO` でこれを隠している。

## 必要な言語拡張

`DataKinds`・`GADTs`・`RankNTypes`・`FlexibleInstances`・`MultiParamTypeClasses`。

`RankNTypes` は `ECons` と `interpret` の `forall x.` のため。`18-union` には無かった。
