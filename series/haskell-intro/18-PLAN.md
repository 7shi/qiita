# Haskell Effモナド 超入門 プラン

記事番号は 18、ファイル名は `18-eff-monad.md`（予定。13〜17 回の `-monad` 命名規則に揃える）。
型名が `Eff` のままなので、**タイトルは `effectful` を使っても変更不要。**

**状態: 設計段階（2026-08-09）。本文未着手。**

**2026-08-09、パッケージを `freer-simple` から `effectful` へ変更した**（下記「パッケージの変更」）。
それに伴い構成を組み直してある。変更前の設計は末尾「採らなかった案」に残した。

## 記事の狙い

**ゴールは「複数の効果を混ぜる」。** そのために命令の型を 1 つから複数へ広げる。

17 回の Operational モナドは、命令の型 `instr` を 1 つ決めて手順書を組み立てた。
テレタイプの手順書にはテレタイプの命令しか置けない。18 回はここを開き、
**複数の命令の型を 1 つの手順書に混ぜられるようにする**（オープンユニオン）。

そしてこれは、シリーズで一度扱った課題の別解にあたる。**別種のモナドを組み合わせる**という、
モナド変換子（10 回）が担っていた仕事である。👉[モナド変換子](https://qiita.com/7shi/items/4408b76624067c17e933)

### この回の一行の主張

**Free から始まった系譜は、モナド変換子への対案として育った。**

その証拠が論文の題そのものにある。

> Extensible Effects: **An Alternative to Monad Transformers**
> （Kiselyov, Sabry, & Swords, 2013）

16 回・17 回では「組み立てと解釈の分離」という観点だけで Free と Operational を見てきたが、
この系譜が実際に向かっていた先は、モナドスタックと `lift` の置き換えだった。
**18 回はその答え合わせの回になる。**

`effectful` の README も「モナド変換子スタックの置き換えを目指す」と明言しているので、
この主張はパッケージを変えても崩れない。むしろ根拠が公式ドキュメントとして手に入る。

|10 回（モナド変換子）|18 回（Eff）|
|---|---|
|`StateT Int (WriterT [String] IO) a`|`Eff es a` ＋ `State Int :> es`・`Writer [String] :> es`|
|型に積む順を書く。順が変わると型が変わる|`:>` 制約で書けば順を書かなくてよい|
|`lift`・`lift . lift`・`liftIO` で持ち上げる|`liftIO` だけ。**持ち上げの回数という概念が無い**|
|効果を足すとスタックの深さが変わり、`lift` の数が変わる|リストに足すだけ|
|新しい効果を作るには変換子とインスタンス群を書く|命令の型を GADT で 1 つ書くだけ|
|`runWriterT . runStateT`（型の順に従う）|`runWriter . runState`（**順を選べる**）|

### もう一本の柱

**型レベルの見え方は同じまま、実装は差し替えられる。**

自作を 2 段にして、これを読者の手で確かめられるようにする（構成案 3・4）。

- 17 回の `Program` から地続きの Freer + `Union` 版。
- ハンドラーの環境を渡り歩く関数にした版（`effectful` の骨格）。

**両者は型・API・出力が完全に一致する。** 構成案 7 でエフェクトシステムを分類するとき、
この 2 つがそのまま Freer 系と `ReaderT IO` 系の縮図になる。

## パッケージの変更（2026-08-09）

当初は `freer-simple` で設計し、検証コードも作った（`check/18-freer/`）。
しかし **`freer-simple` は 2022-01-07 の 1.2.1.2 が最終リリースで、現行 LTS に収録されていない。**
デファクトスタンダードは `effectful` に移っている。実際に移植して動かした上で、切り替えた。

|項目|`freer-simple`|`effectful`|
|---|---|---|
|最新版|1.2.1.2（2022-01-07 が最終アップロード）|2.6.1.0（リポジトリの master は 2.7.0.0、2026-08-02 のコミットあり）|
|Stackage|lts-23 系列まで。**現行 LTS には無い**|**lts-24.53・nightly-2026-08-08 に収録。** lts-22.28 にも 2.3.1.0 で入っている|
|実体|Freer（`Val`/`E`）＋ `Union` ＋ `FTCQueue`|`newtype Eff es a = Eff (Env es -> IO a)`。**`ReaderT IO` にハンドラー環境を持たせたもの**|
|命令の型の種|`* -> *`|`(Type -> Type) -> Type -> Type`（`m` 引数が付く）|
|Member 制約|`Member e effs`（型族 `FindElem` で位置を計算）|`e :> es`（**`{-# OVERLAPPING #-}` の 2 インスタンス**）|
|IO の持ち上げ|`sendM`（`LastMember IO effs`）|`liftIO`（`IOE :> es`）|
|純粋な実行|`run`|`runPureEff`|

### 得たもの

- **resolver の但し書きが軽くなる。** 現行 LTS にも 16・17 回の lts-22.28 にもある。
- **`liftIO` が使える。** 10 回で既に出た名前なので、`sendM` という新語を導入せずに済む。
- **`:>` の素朴な実装が実ライブラリと一致する。** `{-# OVERLAPPING #-}` は
  `effectful-core/src/Effectful/Internal/Effect.hs:52` の実装そのもの。
  `freer-simple` は型族で避けていたので、自作版の「本物はこうではない」という
  但し書きが 1 つ消える。
- **中間結果の型注釈が減る。** `runWriter @[String]` の型適用で済む。

### 失ったもの

- **17 回の `TeletypeI` はそのままでは効果にならない。** `m` 引数と
  `type instance DispatchOf Teletype = Dynamic` の 2 点を足す必要がある。
- **命令列をデータとして組み立てる形が、ライブラリ側には無い。** `send` は環境から
  ハンドラーを引いて即実行する。16・17 回の「組み立てと解釈の分離」は、`Eff` の型と
  `interpret` という API の形として残り、データ構造としては消える。
  **これは隠さず構成案 4 の主題にする。**
- **モジュール名の分岐が増える。** `Effectful.State.Static.Local` / `.Static.Shared` /
  `.Dynamic`（`freer-simple` は `Control.Monad.Freer.State` だけ）。
  記事では `Static.Local` に決め打ちして `:::message` で一言添える。

## 発展の系譜（記事の入口）

**ユーザー指示: 最初に発展の系譜をなぞったうえで、それがモナド変換子を効率化したような
役割に発展したことを説明する。**

|年|出来事|この系譜への寄与|
|---|---|---|
|2008|Swierstra "Data types à la carte"（JFP 18(4)）|`Functor` の余積（`:+:`）で複数の命令の型を混ぜる。**オープンユニオンの原型**。⚠ 書誌の裏取りは TODO|
|2010|Apfelmus, The Monad.Reader Issue 15「The Operational Monad Tutorial」|続きを `>>=` 側に持たせるエンコーディング（17 回の主題）|
|2013|Kiselyov, Sabry, & Swords "Extensible Effects: An Alternative to Monad Transformers"（Haskell Symposium 2013, pp. 59–70, DOI 10.1145/2503778.2503791）|**モナド変換子への対案**として提示。ただし土台は Free で、命令の型に `Functor` を要求していた|
|2015|Kiselyov & Ishii "Freer Monads, More Extensible Effects"（Haskell Symposium 2015, pp. 94–105, DOI 10.1145/2804302.2804319）|土台を Freer に差し替え。`Functor` 不要になる|
|現在|`freer-simple`・`polysemy`（Freer 系）と `effectful`・`cleff`（`ReaderT IO` 系）|**実装は 2 系統に分かれた。** 型レベルの見え方はどちらも同じ|

- **17 回の 参考 節で挙げた 2 本の論文が、そのままこの表の骨格になる。**
  17 回は「Freer は Operational とほぼ同じもの」という同一性の話で止めたが、
  18 回は「では Freer は何のために作られたのか」を継ぐ。
- ⚠ **2013 年版と 2015 年版の区別が要る**（17-PLAN 決定事項 4 で 18 回に回した項目）。
  最初の Extensible Effects は Free ベースで `Functor` を要求していた。
- ⚠ **Swierstra 2008 の書誌と、`freer` → `freer-effects` → `freer-simple` の
  フォーク関係は記憶ベース。書く前に裏を取る**（TODO）。
- ⚠ 歴史の羅列で終わらせない。年表は 1 つの表に圧縮し、すぐ問題提起へ進む。

## 17 回との接続

**17 回が 18 回に渡すのは `Program`・`singleton`・GADT で命令を並べる形・インタープリターであって、
`Freer` という語ではない**（2026-08-09 ユーザー判断）。

- 17 回本文で `Freer` に触れているのは冒頭の `:::message` の一言だけ
  （「同等の方式は Freer モナドとも呼ばれます」）。**18 回の構成を縛らない。**
- 17 回は 548 行と軽く、GADTs と存在型を扱いながらも過積載ではない。
  18 回が 1100 行程度になっても、2 回の合計としては均衡する。
- したがって **`FTCQueue`・線形化・「素の Freer との差分は 2 点」の対応表は落とす。**
  左結合の性能問題は 17 回の `## 性能の注意` で決着済みで、蒸し返す必要がない。
- 17 回から持ち越すのは `Program instr a` の形そのもの。構成案 3 で `instr` を
  `Union es` に差し替える一手が、オープンユニオン導入の最短路になる。

## 構成案

### 1. `# 複数の効果を混ぜる`（入口・系譜）

年表 → 論文の題 → モナド変換子への対案、の順（ユーザー指示）。
ここで記事全体の目的地（10 回の書き直し）を宣言する。

そのうえで問題提起。17 回の `Program instr a` は命令の型が 1 つで、
テレタイプと状態を同じ手順書に置けない。

### 2. `# 型レベルのリスト`

`DataKinds` と `'[Teletype, State Int]`、`:>` 制約。

- **シリーズ初の型レベルの話で、この回で唯一の重い新出。**
- 深入りせず「リストを型として書ける」「`'` は値のリストと区別するための印」に絞る。

### 3. `# 手順書に複数の命令を混ぜる`（自作その 1・17 回から地続き）

`Program instr a` の `instr` を `Union es` に差し替えるだけで効果が混ざる。

```hs
data Union es a where
    Here  :: e a -> Union (e ': es) a
    There :: Union es a -> Union (e ': es) a
```

- `:>` の自作（`{-# OVERLAPPING #-}`）と `send`。17 回の `singleton` に対応する。
- **ハンドラーは効果を 1 つ剥がす関数。** 剥がすたびにリストが短くなり `Eff '[] a` で終わる。
- 自分の担当（`Here`）は処理し、他人宛（`There`）は素通しする。
- **`runghc` だけで動くところまで確認済み**（`check/18-union/`）。
- **`{-# OVERLAPPING #-}` は `effectful` の実装そのもの**なので、
  「本物はこうではない」という但し書きが要らない。
- 【練習1】3 つ目の効果とハンドラーを足す。

### 4. `# 同じ型、別の実装`（自作その 2・新規）★この案の要

型の見え方を一切変えずに、中身を「ハンドラーの環境を受け取る関数」に置き換える。

```hs
newtype Eff es a = Eff { unEff :: Env es -> IO a }

data Env es where
    ENil  :: Env '[]
    ECons :: (forall x. e x -> IO x) -> Env es -> Env (e ': es)

interpret :: (forall x. e x -> Eff es x) -> Eff (e ': es) a -> Eff es a
interpret f (Eff m) = Eff $ \env -> m (ECons (\op -> unEff (f op) env) env)
```

- **`runghc` だけで動き、構成案 3 と出力が完全に一致する 60 行**（検証済み。
  下記「検証済みの事実」）。`State` は `IORef` で実装する。
- 要点は、**命令列をデータとして組み立てる必要はもう無い**こと。
  `send` は環境からハンドラーを引いて即実行する。
- 16・17 回の「組み立てと解釈の分離」は、`Eff` の型と `interpret` という API の形として残り、
  データ構造としては消える。**この転回を隠さずに書く。**
- これが `effectful` の骨格であることを明かして構成案 5 へ渡す。

### 5. `# effectful パッケージ`

16 回（`free`）・17 回（`operational`）と同じ位置づけ。

- **17 回の `TeletypeI` を効果にする。** 変更は `m` 引数と
  `type instance DispatchOf Teletype = Dynamic` の 2 点だけ。

  ```hs
  data Teletype :: Effect where
      PutLine :: String -> Teletype m ()
      GetLine ::           Teletype m String

  type instance DispatchOf Teletype = Dynamic
  ```

  - `m` は高階効果（ハンドラーの中で `Eff` の計算を受け取る効果）のための引数で、
    今回は使わない。`:::message` で一言。
- `send`・`interpret_`・`runEff`・`runPureEff`・`IOE`。
- 既製の効果（`State`・`Writer`・`Reader`・`Error`）と、モジュール名の分岐
  （Static/Dynamic・Local/Shared）に一言。**記事では `Static.Local` に決め打ちする。**
- resolver は **lts-24.53**（現行 LTS。`effectful-2.6.1.0`）。

### 6. `# モナド変換子との比較`（**この回の見せ場**）

**10 回の `sum'` をそのまま書き直す。** 10 回の冒頭で「`do` の中では同じ種類のモナドしか
使えない」という問題提起に使われた、あのコードである。

```hs
-- 10 回
sum' xs = (`execStateT` 0) $ do
    forM_ xs $ \i -> do
        modify (+ i)
        v <- get
        lift $ putStrLn $ "+" ++ show i ++ " -> " ++ show v

-- 18 回
sum' xs = runEff $ execState (0 :: Int) $
    forM_ xs $ \i -> do
        modify (+ i)
        v <- get
        liftIO $ putStrLn $ "+" ++ show i ++ " -> " ++ show (v :: Int)
```

- **実行結果は 1 文字も変わらない**（検証済み）。
- `lift` が `liftIO` になる。**回数を数える必要が無い。**
  10 回で既に出た名前なので、新しい語を導入せずに済む。
- 10 回の `# 多重持ち上げ`・`## liftIO` で扱った問題（ネストの深さで `lift` の数が変わり、
  呼び出し方によっては合わなくなる）が**まるごと消える**。ここが一番効く対比。
- **ハンドラーの適用順を選べる**ことも見せる。`runWriter . runState` と
  `runState . runWriter` で結果の入れ子が変わる（検証済み）。
- 上記「一行の主張」の対比表でまとめる。
- ⚠ **モナド変換子を否定しない。** 17 回の「Free との優劣を煽らない」と同じ姿勢。
  `mtl` は現在も主流で、Eff 系が置き換えたわけではない。「同じ課題への別解」と書く。
- 【練習2】`Writer` を足して、同じ手順書からログも取る。

### 7. `# エフェクトシステムの現在`

**実用頻度を偽らない**（17 回の方針を踏襲）。系譜は構成案 1 で済んでいるので短くまとめる。

- `mtl`（モナド変換子）は依然として主流。
- Eff 系は実装方式で分かれる。**構成案 3 と 4 の 2 つの自作が、そのままこの分類の縮図。**

  |方式|パッケージ|自作との対応|
  |---|---|---|
  |Freer ＋ オープンユニオン|`freer-simple`・`polysemy`|構成案 3|
  |`ReaderT IO` ＋ ハンドラー環境|`effectful`・`cleff`|構成案 4|
  |carrier class|`fused-effects`|（触れるだけ）|

- `freer-simple` は 2022 年 1 月が最終更新で現行 LTS に無い、`effectful` は
  lts-24.53・nightly に収録。**事実として書く。**
- ⚠ **各パッケージの現況は執筆時に確認し直す**（TODO）。

### 8. `# まとめ`

- 型レベルリストと `:>`、効果を 1 つ剥がすハンドラー。
- 型レベルの見え方は同じまま、実装は差し替えられたこと（構成案 3 と 4）。
- 10 回との対比表。
- ⚠ **次回予告は書かない**（16 回決定事項 12・ユーザー指示）。

## 分量の見積もり

|節|見積もり|
|---|---|
|1. 複数の効果を混ぜる|60|
|2. 型レベルのリスト|80|
|3. 手順書に複数の命令を混ぜる|250|
|4. 同じ型、別の実装|200|
|5. effectful パッケージ|200|
|6. モナド変換子との比較|200|
|7. エフェクトシステムの現在|80|
|8. まとめ|60|
|**合計**|**約 1130**|

15 回（1252 行）より少し短い程度。12 回（1604 行）という前例もあるので許容範囲。

**長すぎた場合の削り順**（2026-08-09 決定）。

1. 構成案 1 の年表を圧縮する。
2. 構成案 3 の `:>` 自作を軽くする。
3. 構成案 4 のコードを図と型シグネチャに置き換える（約 200 行減）。

⚠ **構成案 4 を削ると構成案 7 の分類が実感を伴わなくなる**ので、最後の手段。

## 練習（2 問。解答は `:::details` で本文に統合）

|#|位置|題材|狙い|
|---|---|---|---|
|問1|構成案 3 末尾|自作の `Eff` に 3 つ目の効果を足し、ハンドラーを書く|`Here`/`There` の素通しを自分の手で書く|
|問2|構成案 6 末尾|`effectful` で `Writer` を足し、同じ手順書からログも取る|**効果を足すのがリストへの追加だけであること**を体感する|

- ⚠ **スタックマシンは使わない。** 16 回・17 回で連続して出したので、3 回連続は単調。
  18 回の主題は「混ぜる」ことなので、題材が 1 つでは主題を表せない。
- ⚠ テレタイプは本文で再登場する（17 回の `TeletypeI` がほぼそのまま使えることを見せるため）。
  練習では別の効果を作らせる。

## 決定事項

**1〜6 は 2026-08-09 に設計として置いたもの。7〜9 は同日のパッケージ変更に伴う追加。**

1. **入口は発展の系譜**（ユーザー指示）。年表 → 論文の題 → モナド変換子への対案、の順。
2. **ゴールは 10 回（モナド変換子）の書き直し**（ユーザー指示）。
   **10 回冒頭の `sum'` がそのまま素材になる**（検証済み）。
3. **モナド変換子を否定しない。** `mtl` は主流のまま、Eff 系は同じ課題への別解、という整理。
4. **言語拡張は `DataKinds` と `GADTs` の 2 つ**（検証済み）。
   `GADTs` は 17 回で導入済みなので、**新しく増えるのは `DataKinds` だけ。**
5. **実行環境は `stack script --resolver lts-24.53 --package effectful`**（2026-08-09 ユーザー判断）。
   16・17 回は lts-22.28 だったので、resolver が変わることを `:::message` で断る。
   - **現行 LTS をそのまま使う。** `freer-simple` の制約（lts-23 系列にしか無い）が
     消えた以上、古い resolver に留まる理由が無い。
   - lts-22.28 でも `effectful-2.3.1.0` で動くが、そちらには `interpret_` が無く、
     `LocalEnv` を `_` で捨てる形が掲載コードに載る。
6. **自作は 2 段**（構成案 3・4）。**「型レベルの見え方は同じまま、実装は差し替えられる」が
   この回のもう一本の柱。**
7. **パッケージは `effectful`**（2026-08-09 ユーザー判断）。`freer-simple` は更新が止まっており、
   現行 LTS に無いため。
8. **`FTCQueue`・線形化・「素の Freer との差分は 2 点」は落とす。**
   17 回本文に Freer の節が無いので、18 回で復元する義理がない。
9. **`effectful` が Freer ではないことを隠さない。** 構成案 4 で正面から扱い、
   構成案 7 の分類につなげる。

## 前提知識

### 既習の材料

|材料|出典|18 回での使いどころ|
|---|---|---|
|モナド変換子・モナドスタック・`lift`・`liftIO`・多重持ち上げ|`10-monad-transformers.md`|**比較対象そのもの**|
|`State`・`Writer`・`Reader`|`09-state-monads.md`|既製の効果と同じ顔ぶれ|
|`forall`（明示的な全称量化）|`09-state-monads.md` `### forall`・`17-operational-monad.md`|`Env` のハンドラー・`interpret` の型|
|`class` / `instance` / 種（`:k`）|`14-type-classes.md`|`:>` 制約・型レベルリストの種|
|`Functor` / `Applicative` / `Monad` の 3 段・定型|`15-monads-and-friends.md`|自作 `Eff` を 3 段揃える|
|Free モナド・命令の型・手順書・インタープリター|`16-free-monad.md`|系譜の起点|
|`Program`・`singleton`・GADT で命令を並べる|`17-operational-monad.md`|**`Union` に差し替えるだけ、という説明の土台**|
|外部パッケージを stack で使う|`16-free-monad.md` `# free パッケージ`|同じ手順（resolver だけ違う）|
|`IORef`|`09-state-monads.md`|構成案 4 の `State` の実装|

⚠ `IORef` を 09 回のどこでどう扱ったか、執筆前に確認する（TODO）。

### 未出（18 回で初出になるもの）

|初出|重さ|扱い|
|---|---|---|
|`DataKinds` と型レベルリスト（`'[...]`）|**シリーズ初の型レベルの話**|最大の負荷。`'` の意味と、リストが型として書けることに絞る|
|オープンユニオン（`Union`・`:>`）|中|自作する（構成案 3）|
|ハンドラー環境（`Env`）|中|自作する（構成案 4）|
|`Effect` 種と `m` 引数・`DispatchOf`|軽|高階効果のための引数、と `:::message` で一言|
|`send`・`interpret_`・`runEff`/`runPureEff`・`IOE`|軽|パッケージの API|
|Static / Dynamic ディスパッチ、Local / Shared|軽|モジュール名の説明として一言。`Static.Local` に決め打ち|
|ハンドラーという語|軽|「インタープリター」との使い分けを決める（下記 TODO）|

⚠ **`DataKinds` が唯一の重い新出。** 17 回は GADTs と存在型を背負ったが、
18 回は GADTs が既習なので、新しく背負うのは型レベルリストだけになる。

## 検証済みの事実（2026-08-09）

**すべて実際に動かして確認した。**

### パッケージの現況

- **`effectful` は lts-24.53・nightly-2026-08-08 に 2.6.1.0 で収録。**
  ローカルの `~/repos/effectful`（master、2026-08-02 のコミット）は 2.7.0.0。
- **3 つの resolver で実際に動かし、出力が完全に一致することを確認した。**

  |resolver|GHC|effectful|結果|
  |---|---|---|---|
  |**lts-24.53**（採用）|9.10.3|2.6.1.0|3 本とも動作。`interpret_` 可|
  |lts-23.28|9.8.4|2.5.1.0|3 本とも動作。`interpret_` 可|
  |lts-22.28（16・17 回）|9.6.6|2.3.1.0|3 本とも動作。**`interpret_` が無い**|

  - **2.3.1.0 には `interpret_` が無い。** `interpret $ \_ op -> case op of ...` と書けば動く
    （第 1 引数は `LocalEnv`。高階効果でのみ使う）。
  - 2.5.1.0 → 2.6.1.0 で、本文が使う API（`send`・`interpret_`・`runEff`・`runPureEff`・
    `IOE`・`Effectful.State.Static.Local`）に変更は無かった。
- **`freer-simple` の最終アップロードは 1.2.1.2 / 2022-01-07。** 現行 LTS には無い。
- ⚠ この環境の stack は GHC 9.6 以降に対して
  「Stack has not been tested with GHC versions above 9.4」の警告を出す。GHC 9.10.3 でも
  同じ警告だけで、**増えるものは無かった。動作には影響しない。**
  16・17 回と同じ扱いにする。

### ライブラリの内部

- **`newtype Eff (es :: [Effect]) a = Eff (Env es -> IO a)`**
  （`effectful-core/src/Effectful/Internal/Monad.hs:126`）。
  `Env` は `offset` / `PrimArray Ref` / `IORef Storage` の 3 フィールドで、
  効果ごとの状態を可変配列に持つ（`Effectful/Internal/Env.hs:97`）。**Freer ではない。**
- **`type Effect = (Type -> Type) -> Type -> Type`**
  （`effectful-core/src/Effectful/Internal/Effect.hs:24`）。命令の型に `m` 引数が付く。
- **`:>` は `{-# OVERLAPPING #-}` の 2 インスタンスで実装されている**
  （同 `:52`）。`reifyIndex` で `Env` 内の位置を数える。
  **自作版と同じ手口。** 加えて `e :> '[]` に `TypeError` を置いて分かりやすい
  エラーメッセージを出している。
- `runPureEff` は `unsafeDupablePerformIO` で走る（同 `Monad.hs:132`）。
  **純粋な実行はできるが、内側は `IO`。** 本文でどこまで触れるかは未決。
- `effectful` は継続を捕まえる効果（`NonDet` の全解探索・`Coroutine`）を提供できない。
  README に明記されている。⚠ **18 回では触れない見込み**（範囲外）。

### 移植して動かした結果

**`freer-simple` 版（`check/18-freer/`）の 3 本を移植し、出力は 3 本とも 1 文字も変わらなかった。**

|内容|`freer-simple`|`effectful`|
|---|---|---|
|10 回の `sum'`|`runM` / `sendM`|`runEff` / **`liftIO`**|
|Member 制約|`Member (State Int) effs`|`State Int :> es`|
|純粋な実行|`run`|`runPureEff`|
|順序入れ替え|両順とも通る|**両順とも通る**（中間の型注釈が不要になり `runWriter @[String]` で済む）|
|命令の型|`data Teletype r where`|`data Teletype :: Effect where` ＋ `m` 引数 ＋ `DispatchOf`|
|IO の混在|`LastMember IO effs`|`IOE :> es`|
|ハンドラー|`interpretM go`|`interpret_ $ \op -> case op of ...`|

- **型推論の落とし穴は `effectful` でも同じ。** `n <- get` の `s` は `es` から一意に決まらないので、
  `show (n :: Int)` のように使う側で決めるか型注釈が要る。
  **本文でどこまで触れるかは未決。**
- `\case` は GHC2021 に含まれないので、掲載コードでは `\op -> case op of` と書く。

### 自作の 2 段（構成案 3・4）

- **構成案 3（Freer ＋ `Union`）は `runghc` だけで動く**（`check/18-union/Union.hs`）。
  `Union`（`Here`/`There`）・Member（`inj`/`prj`）・`Eff`・`send`・
  2 つの効果とハンドラーまで、パッケージ無しで動いた。
  - 種注釈 `(es :: [* -> *])` を書くと `-Wstar-is-type` の警告が出るので**省く**。
  - 空のリストのハンドラーは `run :: Eff '[] a -> a` で、`case u of {}` で書ける
    （`Union '[] a` にコンストラクターが無いため。`EmptyCase` は GHC2021 に含まれる）。
- **構成案 4（ハンドラー環境）も `runghc` だけで動く。約 80 行**（`check/18-env/Env.hs`）。
  `Eff`・`Env`（`ENil`/`ECons`）・`:>`・`send`・`interpret`・`run` と、
  `Teletype`・`Counter`（`IORef` 実装）の 2 効果。
  **`check/18-union/Union.hs` と出力が完全に一致することを `diff` で確認済み。**
  - 必要な言語拡張は `DataKinds`・`GADTs`・`RankNTypes`・`FlexibleInstances`・
    `MultiParamTypeClasses`。**`RankNTypes` が構成案 3 から増える**（`forall x.` のため）。
  - `run` の型は `Eff '[] a -> IO a` になる（構成案 3 は `Eff '[] a -> a`）。
    この実装が `IO` の上に載っているため。`effectful` の `runPureEff` は
    `unsafeDupablePerformIO` でこれを隠している。

## 未決事項・TODO

- [ ] **⚠ 「ハンドラー」という語を導入するか**（構成案 3・4）。16 回以降「インタープリター」で
      統一してきた。`effectful` の関数名は `interpret` なので、語を増やさない選択もある。
      ただし「効果を 1 つ剥がす関数」を指す語が要る場面が増える。
- [ ] **⚠ 型推論の落とし穴（`get` の型が決まらない）を本文で扱うか。**
      練習で読者が踏む可能性が高い。
- [ ] **⚠ `runPureEff` が内側で `IO` を走らせていることに触れるか。**
      「純粋に見えるが `IO` の上」は面白いが、脱線でもある。
- [ ] Swierstra "Data types à la carte"（2008）の書誌と、
      `freer` → `freer-effects` → `freer-simple` のフォーク関係の裏を取る。
- [ ] Eff 系パッケージの現況を執筆時点で確認し直す。
- [ ] 10 回を通読し、`sum'`・`# 多重持ち上げ`・`## liftIO`・`## モナドスタック` の
      当時の言い回しに繋がる形で書く（README.md「スタイル」）。
      行末 👉リンクのアンカーは `uv run scripts/anchor.py <見出し>` で生成する。
- [ ] 09 回の `IORef` の扱いを確認する（構成案 4 の前提知識）。
- [ ] 練習 2 問を実装して動作確認する。
- [x] 検証コードを `check/18-*/` に整理した（2026-08-09）。各ディレクトリに `README.md` あり。
      - `check/18-union/` … 構成案 3。**`Member` を `:>`、`effs` を `es` に改名**して
        構成案 4・5 と用語を揃えた（動作再確認済み）
      - `check/18-env/` … 構成案 4。`Env.hs`。**`18-union` と出力が完全に一致**することを
        `diff` で確認済み
      - `check/18-effectful/` … 構成案 5・6。`Teletype.hs`・`StateWriter.hs`・`Sum.hs`
      - `check/18-freer/` … **記事には載らない。** 採らなかった案の記録として残した
- [ ] 導入文（PREFACES.md 用）の案。**初稿を書き上げてから確認する**
      （17 回と同じ運用。2026-08-08 ユーザー指示）。
- [ ] 本文の初稿を書く → `18-eff-monad.md`
- [ ] `README.md` の目次・`PREFACES.md`・`ARTICLES.tsv` を更新する
- [ ] 各記事の目次にある「1.【予定】Haskell Effモナド 超入門」をリンクに差し替える
      （01〜17 回すべて）。Zenn の URL が決まってから
- [ ] フロントマターの `url` に Zenn の記事 URL を入れる
- [ ] Zenn へ複製し `ZENN.tsv` に追記する

## 公開方針

[README.md](README.md) の「公開方針（13回以降）」に従う。13〜17 回と同じ扱い。

- 執筆はこの Qiita 側リポジトリ、公開は Zenn。`id` は空のまま、`url` は Zenn の
  スラッグが決まった時点で埋める。
- 補足・折りたたみは Zenn 記法（`:::message`・`:::details`）。`:::details` は解答例専用。
- 練習の解答は別記事にせず本文に統合し、関連する節の末尾に分散。
- 検証コードは `check/18-*/` に置き、各ディレクトリに `README.md`。
- **言語拡張の基準は GHC2021**（16 回で確定）。`DataKinds`・`GADTs` は含まれないので
  pragma が掲載コードに載る。17 回の `GADTs` と同じ扱い。
- **言語拡張の書き方への 👉リンクは張らない**（17-PLAN 推敲時の変更点 2、ユーザー判断）。

## 既存記事との関係

- ⚠ **[Freer Effectsが、だいたいわかった](https://qiita.com/YoshikuniJujo/items/988ac4b69a27974154fd)
  （YoshikuniJujo、全 16 回）と重なる回**（16-PLAN・17-PLAN で予告済み）。
  あちらは Freer Effects がゴールで、オープンユニオン・型族・キューまで自作している。
  **執筆前に改めて棚卸しする**（TODO）。
  - 差別化の軸は 2 つ。**10 回（モナド変換子）との接続**と、
    **`effectful` を扱うこと**（あちらは Freer 系のみ）。
  - 本文からリンクは張らない（16・17 回と同じ方針）。
- `articles/haskell/` に Eff・Extensible Effects へ言及した記事は無い（16 回で確認済み。
  念のため再確認する）。

## 推敲時の観点

16・17 回から引き継ぐ。

- 半角スペースのルール（CLAUDE.md）。タイトルの「Effモナド」はタイトルとしての表記で、
  本文では `Eff モナド` と空ける。
- 掲載コードと `check/18-*/` のファイルが一致しているか。実行結果・警告も実際の出力と一致するか。
- 過去記事を「第N回」のような回数で参照していないか。
- 他記事へのリンクが行末の `👉[省略タイトル](URL#アンカー)` 形式に揃っているか。
  10 回の省略タイトルは `モナド変換子`。
- **10 回を読んでいない読者が置いていかれていないか。** 比較が主題なので、
  モナドスタックと `lift` を独立して説明し直す必要がある（README.md「スタイル」）。
- **構成案 3 と 4 の関係が読者に伝わっているか。** 「2 通り書かされた」ではなく
  「型が同じで実装が違う」ことが要点。
- まとめ節に次回予告が入っていないか。
- 圏論に踏み込んでいないか。**代数的効果（algebraic effects）という語を出すかは要判断。**
  README.md「未定のアイデア」で「代数的効果とハンドラ」は理論回の項目として
  確保してあるので、18 回では名前を出すに留めるのが筋。
- **系譜の節が長くなりすぎていないか。** 歴史は入口であって主題ではない。

## 19 回以降への引き継ぎ

- **アロー**（19 回予定）。モナドを超えた抽象化として最終回に据える（README.md「構想」）。
- **`Foldable`・`Traversable`・`Alternative`・`MonadFail`**（15 回決定事項 15・
  16 回決定事項 13・17-PLAN で 3 回連続の見送り）。**18 回でも扱わない**見込み。
  README.md「網羅性の穴」のとおり、独立した回（15 回の続編）にするのが現実的。
- **代数的効果とハンドラ**（README.md「未定のアイデア」）。Free・Operational・Eff を
  通り終えた時点で、名前と位置づけを与えるだけで済む。
- **codensity モナド / Church エンコード**（13-PLAN・16 回決定事項 10 で先送り）。
  18 回で `FTCQueue` を落としたので、**引き取り手がいないまま残る。**
- **高階効果**（`local`・`catch` のように、ハンドラーが `Eff` の計算を受け取る効果）。
  18 回では `m` 引数の説明だけで済ませる。踏み込むなら別の回。

## 採らなかった案（`freer-simple` 前提の設計・2026-08-09 まで）

**記録として残す。** 当初は `freer-simple` を使い、17 回の Freer から地続きに
「素の Freer との差分は 2 点」で説明する構成だった。

- 構成案 2 として `# Freer モナド` の節を置き、17 回の初稿から削除された材料
  （コミット `dcd23e8`。`git show dcd23e8 -- series/haskell-intro/17-operational-monad.md`）を
  移す予定だった。`FTCQueue` と `Impure u q >>= k = Impure u (q |> k)` による線形化。
- `freer-simple` の `Eff`（`Control.Monad.Freer.Internal`）と素の Freer の対応表。

  |素の Freer|`Eff`|意味|
  |---|---|---|
  |`Pure` / `Impure`|`Val` / `E`|名前だけの違い|
  |命令の型 `f b`|`Union effs b`|命令の型が 1 つからリストへ|
  |続き `b -> Freer f a`|`Arrs effs b a`（`FTCQueue`）|続きをキューで保持（線形化）|

- 落とした理由は 2 つ。
  1. **`freer-simple` の更新が 2022 年で止まっており、現行 LTS に無い**（上記「パッケージの変更」）。
  2. **17 回本文に Freer の節が無い**ので、`FTCQueue` を 18 回で復元する義理がない
     （上記「17 回との接続」）。
- 検証コードは `check/18-freer/` に残っている。**記事には載らない。**

## 補足

- 検証コードは `series/haskell-intro/check/18-*/` に置く（CLAUDE.md の「検証コード」の方式）。
  `effectful` を使うディレクトリは stack での実行方法と resolver を `README.md` に明記する
  （16 回の `free`・17 回の `operational` と同じ扱い）。
- このファイルは拡張子を除く部分が大文字・数字・ハイフンのみなので
  `ARTICLES.tsv` の収集対象から除外される。
