# check/18-union

18 回の構成案 3「手順書に複数の命令を混ぜる」の検証（2026-08-09）。

17 回の `Program instr a` の `instr` を `Union es` に差し替えると、複数の効果が
1 つの手順書に混ざる。**17 回から地続きの自作版。**

|ファイル|内容|
|---|---|
|`Union.hs`|`Union`・`:>`（`inj`/`prj`）・`Eff`・`send`・2 つの効果（`Teletype`・`Counter`）とハンドラー|

同じ型・同じ API を別の実装で満たしたものが `check/18-env/`（構成案 4）。
**両者は出力が完全に一致する。**

## 実行方法

**パッケージ不要。`runghc` で動く。**

```
echo alice | runghc Union.hs
```

```text:実行結果
name?
Hello, alice! 0
```

## 確認したこと

- **17 回の `Program` の `instr` を `Union es` に差し替えるだけで、複数の効果が混ざる。**
  `Eff` の定義・`instance Monad`・`send` は 17 回の `Program`・`singleton` とほぼ同じ形。

  ```hs
  data Eff es a where
      Return :: a -> Eff es a
      (:>>=) :: Union es b -> (b -> Eff es a) -> Eff es a
  ```

- **`Union` は `Here`/`There` の 2 コンストラクターの GADT で書ける。**
  型レベルリストの先頭なら `Here`、それ以外は `There` で 1 つずつ潜る。

  ```hs
  data Union es a where
      Here  :: e a -> Union (e ': es) a
      There :: Union es a -> Union (e ': es) a
  ```

  - `data Union (es :: [* -> *]) a where` と種を書くと `-Wstar-is-type` の警告が出る
    （`Data.Kind.Type` を使えという趣旨）。**種注釈は省略できる**ので、省いた形にした。
- **ハンドラーは効果を 1 つ剥がす関数**（`Eff (Counter ': es) a -> Eff es a`）。
  自分の担当（`Here`）は処理し、`There` で来たものは素通しする。この形で入れ子に適用できる。
- **`:>` は重なるインスタンス 2 本で書ける。**
  `{-# OVERLAPPING #-}`・`{-# OVERLAPPABLE #-}` を付けないと
  「Overlapping instances」でエラーになる。
  - **実際の `effectful` も同じ手口**（`effectful-core/src/Effectful/Internal/Effect.hs:52`）。
    `freer-simple` は型族 `FindElem` で位置を計算してこれを避けていた。
  - 名前も `effectful` に合わせて `Member` ではなく `:>` にしてある
    （`e :> es` は「効果 `e` がリスト `es` に含まれる」）。
- **スマートコンストラクターには型注釈が要る。** `putLine s = send (PutLine s)` のように
  型を書かないと、`:>` 制約が一般化されず「type variable would escape its scope」になる。
- **空のリストのハンドラー**は `run :: Eff '[] a -> a` として書ける。
  `Union '[] a` にはコンストラクターが無いので `case u of {}` で済む
  （`EmptyCase` は GHC2021 に含まれるので pragma 不要。別途確認済み）。
  `Union.hs` は最後を `IO` のハンドラーで閉じているため `There _ -> error "impossible"` に
  なっている。**本文でどちらの形を採るかは要検討**（18-PLAN の TODO）。

## 必要な言語拡張

`DataKinds`・`GADTs`・`FlexibleInstances`・`MultiParamTypeClasses`。
後ろ 2 つは `:>` を多引数の型クラスとして定義するため。
