# check/18-union

18 回のオープンユニオンを自作できるかの事前検証（2026-08-09）。**記事の掲載コードではなく、
設計判断のための試作。** 本文でどこまで自作するかは 18-PLAN.md の決定待ち。

|ファイル|内容|
|---|---|
|`Union.hs`|`Union`・`Member`（`inj`/`prj`）・`Eff`・`send`・2 つの効果（`Teletype`・`Counter`）とハンドラー|

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

- **17 回の `Program` の `instr` を `Union effs` に差し替えるだけで、複数の効果が混ざる。**
  `Eff` の定義・`instance Monad`・`send` は 17 回の `Program`・`singleton` とほぼ同じ形。

  ```hs
  data Eff effs a where
      Return :: a -> Eff effs a
      (:>>=) :: Union effs b -> (b -> Eff effs a) -> Eff effs a
  ```

- **`Union` は `Here`/`There` の 2 コンストラクターの GADT で書ける。**
  型レベルリストの先頭なら `Here`、それ以外は `There` で 1 つずつ潜る。

  ```hs
  data Union effs a where
      Here  :: eff a -> Union (eff ': effs) a
      There :: Union effs a -> Union (eff ': effs) a
  ```

  - `data Union (effs :: [* -> *]) a where` と種を書くと `-Wstar-is-type` の警告が出る
    （`Data.Kind.Type` を使えという趣旨）。**種注釈は省略できる**ので、省いた形にした。
- **ハンドラーは効果を 1 つ剥がす関数**（`Eff (Counter ': effs) a -> Eff effs a`）。
  自分の担当は処理し、`There` で来たものは素通しする。この形で入れ子に適用できる。
- **`Member` の素朴な実装には重なるインスタンスが要る。**
  `{-# OVERLAPPING #-}`・`{-# OVERLAPPABLE #-}` を付けないと
  「Overlapping instances for Member Teletype '[Teletype]」でエラーになる。
  実ライブラリ（freer-simple）はこれを避けるため、型族で位置を計算する
  `FindElem` を使っている。
- **スマートコンストラクターには型注釈が要る。** `putLine s = send (PutLine s)` のように
  型を書かないと、`Member` 制約が一般化されず「type variable would escape its scope」になる。
- **空のリストのハンドラー**は `run :: Eff '[] a -> a` として書ける。
  `Union '[] a` にはコンストラクターが無いので `case u of {}` で済む
  （`EmptyCase` は GHC2021 に含まれるので pragma 不要。別途確認済み）。
  `Union.hs` は最後を `IO` のハンドラーで閉じているため `There _ -> error "impossible"` に
  なっている。**本文でどちらの形を採るかは要検討**（18-PLAN の TODO）。

## 必要な言語拡張

`DataKinds`・`GADTs`・`FlexibleInstances`・`MultiParamTypeClasses`。
後ろ 2 つは `Member` を多引数の型クラスとして定義するため。
