# Haskell Effモナド 超入門 プラン

記事番号は 18、ファイル名は `18-eff-monad.md`（予定。13〜17 回の `-monad` 命名規則に揃える）。

**状態: 設計段階（2026-08-09）。本文未着手。** 検証コードは `check/18-union/`・`check/18-freer/` に
先行して作成済み（下記「検証済みの事実」）。

17-PLAN.md の「18 回（Eff）の執筆環境」「タイトルの変更と取り消し」で調べた内容を出発点にし、
実際に `freer-simple` を動かして裏を取った上で構成を組んだ。

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

|10 回（モナド変換子）|18 回（Eff）|
|---|---|
|`StateT Int (WriterT [String] IO) a`|`Eff '[State Int, Writer [String], IO] a`|
|型に積む順を書く。順が変わると型が変わる|`Member` 制約で書けば順を書かなくてよい|
|`lift`・`lift . lift`・`liftIO` で持ち上げる|`send`・`sendM`。**持ち上げの回数という概念が無い**|
|効果を足すとスタックの深さが変わり、`lift` の数が変わる|リストに足すだけ|
|新しい効果を作るには変換子とインスタンス群を書く|命令の型を GADT で 1 つ書くだけ|
|`runWriterT . runStateT`（型の順に従う）|`runWriter . runState`（**順を選べる**）|

## 発展の系譜（記事の入口）

**ユーザー指示: 最初に発展の系譜をなぞったうえで、それがモナド変換子を効率化したような
役割に発展したことを説明する。**

|年|出来事|この系譜への寄与|
|---|---|---|
|2008|Swierstra "Data types à la carte"（JFP 18(4)）|`Functor` の余積（`:+:`）で複数の命令の型を混ぜる。**オープンユニオンの原型**。⚠ 書誌の裏取りは TODO|
|2010|Apfelmus, The Monad.Reader Issue 15「The Operational Monad Tutorial」|続きを `>>=` 側に持たせるエンコーディング（17 回の主題）|
|2013|Kiselyov, Sabry, & Swords "Extensible Effects: An Alternative to Monad Transformers"（Haskell Symposium 2013, pp. 59–70, DOI 10.1145/2503778.2503791）|**モナド変換子への対案**として提示。ただし土台は Free で、命令の型に `Functor` を要求していた|
|2015|Kiselyov & Ishii "Freer Monads, More Extensible Effects"（Haskell Symposium 2015, pp. 94–105, DOI 10.1145/2804302.2804319）|土台を Freer に差し替え。`Functor` 不要になり、続きを型整列キューで保持して線形化|
|現在|`freer-simple`（`freer` → `freer-effects` → `freer-simple` の系列）|2015 年版の実装。**エクスポートされる型の名前は `Eff`**|

- **17 回の 参考 節で挙げた 2 本の論文が、そのままこの表の骨格になる。**
  17 回は「Freer は Operational とほぼ同じもの」という同一性の話で止めたが、
  18 回は「では Freer は何のために作られたのか」を継ぐ。
- ⚠ **2013 年版と 2015 年版の区別が要る**（17-PLAN 決定事項 4 で 18 回に回した項目）。
  最初の Extensible Effects は Free ベースで `Functor` を要求していた。
  Freer 版はそれを作り直したもので、現行の Eff 系ライブラリは後者。
- ⚠ **Swierstra 2008 と `freer` → `freer-effects` → `freer-simple` のフォーク関係は
  記憶ベース。書く前に裏を取る**（TODO）。

### 名前のギャップ（17-PLAN から引き継ぎ・確認済み）

**素の Freer を提供するライブラリは存在しない。** `freer-simple` がエクスポートするのは
`Eff` だけで、「Freer」の名前はモジュール名 `Control.Monad.Freer` にのみ残る。
コンストラクター `Val`・`E` は `Control.Monad.Freer.Internal` にある。

**ユーザー指示のとおり、ここを本文で明示する。** 17 回で学んだ Freer と、
これから使う `Eff` は同じものの延長だが、名前も形も少し違う。

```hs
-- 17 回で自作した Program
data Program instr a where
    Return :: a -> Program instr a
    (:>>=) :: instr b -> (b -> Program instr a) -> Program instr a

-- 論文の Freer（17 回の 参考 で触れた形）
data Freer f a where
    Pure   :: a -> Freer f a
    Impure :: f b -> (b -> Freer f a) -> Freer f a

-- freer-simple の Eff（Control.Monad.Freer.Internal）
data Eff effs a
    = Val a
    | forall b. E (Union effs b) (Arrs effs b a)

type Arr  effs a b = a -> Eff effs b
type Arrs effs a b = FTCQueue (Eff effs) a b
```

対応は 1 対 1 で、**素の Freer からの差分はちょうど 2 点。**

|素の Freer|`Eff`|意味|
|---|---|---|
|`Pure` / `Impure`|`Val` / `E`|名前だけの違い|
|命令の型 `f b`|`Union effs b`|**命令の型が 1 つからリストへ**（18 回の主題）|
|続き `b -> Freer f a`|`Arrs effs b a`（`FTCQueue`）|**続きを関数 1 本ではなくキューで保持**（線形化）|

## 17 回から持ち越した材料

**17 回の初稿にあった `# Freer モナド` の節は、公開直前に削除された**
（コミット `dcd23e8`「Freerモナドの独立セクションを削除し冒頭の補足に集約」）。
その内容が 18 回の材料としてそのまま残っている。

- 論文の `Freer`（`Pure`/`Impure`）の定義と `Program` との対応
- `FTCQueue` の定義と、`Impure u q >>= k = Impure u (q |> k)` による線形化の説明
- 「`operational` は溜めてから組み替え、Freer は最初から 1 列」という対比

`git show dcd23e8 -- series/haskell-intro/17-operational-monad.md` で原文が読める。
**書き直すのではなく、この文章を土台にして 18 回へ移す。**

⚠ ただし 17 回本文には現在この説明が無いので、**18 回では「前回の続き」ではなく
独立した説明として書く**（README.md「スタイル」の方針どおり）。
17 回で残っているのは冒頭の `:::message`（Freer という別名と比較級の由来）と
参考 節の論文だけ、という前提で書くこと。

## 構成案

### 1. `# Free から Eff までの系譜`

上記の年表。**論文の題を見せて、この系譜がモナド変換子への対案だったことを明かす。**
ここで記事全体の目的地（10 回の書き直し）を宣言する。

- 16 回・17 回では「組み立てと解釈の分離」としか言っていなかったので、
  **同じものを別の角度から見せ直す**構成になる。
- ⚠ 歴史の羅列で終わらせない。年表は 1 つの表に圧縮し、すぐ次節のコードへ進む。

### 2. `# Freer モナド`

17 回から持ち越した材料（上記）。`Program` → `Freer` → `Eff` の対応表と、
`FTCQueue` による線形化。

- **`Eff` の定義を先に見せて、差分が 2 点であることを示す。**
  この 2 点がそのまま 3 節（オープンユニオン）と本節（キュー）の主題になる。
- ⚠ **キューは擬似コードに留める案**（`|>` はライブラリの操作なのでそのままでは動かない。
  17 回の削除済み原稿もそう断っていた）。自作 `Eff` に組み込むかは未決（下記 TODO）。

### 3. `# オープンユニオン`

**命令の型を 1 つからリストへ。** 17 回の `Program instr a` の `instr` を
`Union effs` に差し替えるだけで、複数の効果が混ざる。

```hs
data Union effs a where
    Here  :: eff a -> Union (eff ': effs) a
    There :: Union effs a -> Union (eff ': effs) a
```

- 型レベルリスト（`'[State Int, Teletype]`）と `DataKinds`。**シリーズ初の型レベルの話。**
- `Member` 制約と `send`。17 回の `singleton` に対応する。
- **`runghc` で動くところまで自作できることを確認済み**（`check/18-union/`）。
- ⚠ 自作の範囲は未決（下記 TODO）。`Member` の重なるインスタンスまで見せると重い。

### 4. `# 効果を混ぜる`

自作の `Eff` で 2 つの効果を動かす。**ハンドラーは効果を 1 つ剥がす関数**という形を見せる。

```hs
runCounter :: Int -> Eff (Counter ': effs) a -> Eff effs a
```

- 自分の担当（`Here`）は処理し、他人宛（`There`）は素通しする。
- 剥がすたびにリストが短くなり、最後は `Eff '[] a` になる。
- **インタープリターがハンドラーと呼ばれる**理由がここで出る。16・17 回の
  インタープリターは手順書を丸ごと解釈したが、ここでは 1 つの効果だけを引き受ける。
  - ⚠ **用語は「インタープリター」で統一してきた**（16 回の確定事項）。
    「ハンドラー」を新しく出すかは要検討。ライブラリの関数名が `interpret` なので、
    「効果を 1 つ処理するインタープリター」と呼んで済ませる案もある。

### 5. `# freer-simple パッケージ`

16 回（`free`）・17 回（`operational`）と同じ位置づけ。

- `Eff`・`send`・`Member`・`run`・`runM`・`interpret`・`interpretM`。
- **既製の効果**が揃っている。定義はどれも 17 回で書いた命令の型そのもの。

  ```hs
  data State s r where
      Get :: State s s
      Put :: !s -> State s ()

  data Writer w r where
      Tell :: w -> Writer w ()

  data Reader r a where
      Ask :: Reader r r

  newtype Error e r where
      Error :: e -> Error e r
  ```

- **17 回の `TeletypeI` は 1 文字も変えずに効果として使える。**
  変わるのは `singleton` が `send` になるだけ（`check/18-freer/Teletype.hs` で確認済み）。
- resolver が 16・17 回と違う（**lts-23.28**）ことを `:::message` で断る。

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
sum' xs = runM $ execState (0 :: Int) $
    forM_ xs $ \i -> do
        modify (+ i)
        v <- get
        sendM $ putStrLn $ "+" ++ show i ++ " -> " ++ show (v :: Int)
```

- **実行結果は 1 文字も変わらない**（検証済み。`check/18-freer/Sum.hs`）。
- `lift` が `sendM` になる。**回数を数える必要が無い。**
- 10 回の `# 多重持ち上げ`・`## liftIO` で扱った問題（ネストの深さで `lift` の数が変わり、
  呼び出し方によっては合わなくなる）が**まるごと消える**。ここが一番効く対比。
- **ハンドラーの適用順を選べる**ことも見せる（`check/18-freer/StateWriter.hs`）。
  `runWriter . runState` と `runState . runWriter` で結果の入れ子が変わる。
  10 回のモナドスタックでは型に積む順を書いた。
- 上記「一行の主張」の対比表でまとめる。
- ⚠ **モナド変換子を否定しない。** 17 回の「Free との優劣を煽らない」と同じ姿勢。
  `mtl` は現在も主流で、Eff 系が置き換えたわけではない。「同じ課題への別解」と書く。

### 7. `# エフェクトシステムの現在`

**実用頻度を偽らない**（17 回の方針を踏襲）。

- `mtl`（モナド変換子）は依然として主流。
- Eff 系は `polysemy`・`effectful`・`cleff`・`fused-effects` など複数あり、
  実装方式も分かれている（`freer-simple`・`polysemy` は Freer 系譜、
  `effectful`・`cleff` は `ReaderT IO` 方式、`fused-effects` は carrier class 方式）。
- `freer-simple` は入門向けに読みやすいが、**最新の LTS には入っていない**
  （lts-23 系列まで）。この事実自体が現状を語るので、隠さず書く。
- ⚠ **各パッケージの現況は執筆時に確認し直す**（TODO）。17-PLAN の表は 2026-08-08 時点。

### 8. `# まとめ`

- 系譜の 1 行のまとめ（Free → Operational/Freer → Extensible Effects → Eff）。
- 差分は 2 点（キューと `Union`）だったこと。
- 10 回との対比表。
- ⚠ **次回予告は書かない**（16 回決定事項 12・ユーザー指示）。

## 練習（案・2 問。解答は `:::details` で本文に統合）

|#|位置|題材|狙い|
|---|---|---|---|
|問1|構成案 4 末尾|自作の `Eff` に 3 つ目の効果を足し、ハンドラーを書く|`Here`/`There` の素通しを自分の手で書く|
|問2|構成案 6 末尾|`freer-simple` で `Writer` を足し、同じ手順書からログも取る|**効果を足すのがリストへの追加だけであること**を体感する|

- ⚠ **スタックマシンは使わない。** 16 回・17 回で連続して出したので、3 回連続は単調
  （17-PLAN 決定事項 1 の ⚠ と同じ懸念）。18 回の主題は「混ぜる」ことなので、
  題材が 1 つでは主題を表せない。
- ⚠ テレタイプは本文で再登場する（17 回の `TeletypeI` がそのまま使えることを見せるため）。
  練習では別の効果を作らせる。

## 決定事項

**1〜6 は 2026-08-09 に設計として置いたもの。ユーザー確認が要るものは ⚠ を付けた。**

1. **入口は発展の系譜**（ユーザー指示）。年表 → 論文の題 → モナド変換子への対案、の順。
2. **`Eff` と素の Freer の差分 2 点（`FTCQueue`・`Union`）を明示する**（ユーザー指示）。
   17 回で学んだ形と、実際のライブラリの形のギャップを隠さない。
3. **ゴールは 10 回（モナド変換子）の書き直し**（ユーザー指示「モナド変換子の記事と
   関連付けられるかも検討」への回答）。**関連付けられる。10 回冒頭の `sum'` が
   そのまま素材になる**（検証済み）。
4. **実行環境は `stack script --resolver lts-23.28 --package freer-simple`。**
   16・17 回の lts-22.28 とは違う（`freer-simple` は lts-23 系列にのみ収録）。
   本文で resolver が変わることを断る。
5. **言語拡張は `DataKinds` と `GADTs` の 2 つ**（検証済み）。
   `GADTs` は 17 回で導入済みなので、**新しく増えるのは `DataKinds` だけ。**
   17 回の「表現力のための言語拡張」という整理をそのまま延長できる。
6. **モナド変換子を否定しない。** `mtl` は主流のまま、Eff 系は同じ課題への別解、という整理。

## 前提知識

### 既習の材料

|材料|出典|18 回での使いどころ|
|---|---|---|
|モナド変換子・モナドスタック・`lift`・`liftIO`・多重持ち上げ|`10-monad-transformers.md`|**比較対象そのもの**|
|`State`・`Writer`・`Reader`|`09-state-monads.md`|既製の効果と同じ顔ぶれ|
|`class` / `instance` / 種（`:k`）|`14-type-classes.md`|`Member` 制約・型レベルリストの種|
|`Functor` / `Applicative` / `Monad` の 3 段・定型|`15-monads-and-friends.md`|自作 `Eff` を 3 段揃える|
|Free モナド・命令の型・手順書・インタープリター|`16-free-monad.md`|系譜の起点|
|`Program`・`singleton`・GADT で命令を並べる・`forall`|`17-operational-monad.md`|**`Union` に差し替えるだけ、という説明の土台**|
|外部パッケージを stack で使う|`16-free-monad.md` `# free パッケージ`|同じ手順（resolver だけ違う）|

### 未出（18 回で初出になるもの）

|初出|重さ|扱い|
|---|---|---|
|`DataKinds` と型レベルリスト（`'[...]`）|**シリーズ初の型レベルの話**|最大の負荷。`'` の意味と、リストが型として書けることに絞る|
|オープンユニオン（`Union`・`Member`・`inj`/`prj`）|中|自作して見せる（範囲は未決）|
|`FTCQueue`・型整列キュー|中|擬似コードに留める案|
|`Eff`・`send`・`run`/`runM`・`interpret`/`interpretM`|軽|パッケージの API|
|ハンドラーという語|軽|「インタープリター」との使い分けを決める（構成案 4 の ⚠）|

⚠ **`DataKinds` が唯一の重い新出。** 17 回は GADTs と存在型の 2 つを背負って過積載気味
だったが、18 回は GADTs が既習なので、新しく背負うのは型レベルリストだけになる。
**深入りせず「リストを型として書ける」「`'` は値のリストと区別するための印」で足りるはず。**

## 検証済みの事実（2026-08-09）

**すべて実際に動かして確認した。** 詳細は `check/18-union/README.md`・
`check/18-freer/README.md`。

- **`freer-simple-1.2.1.2` は lts-23.28 で動く**（`stack script --resolver lts-23.28
  --package freer-simple`）。17-PLAN の「lts-23 系列にのみ収録」という調査を実測で裏付けた。
  - ⚠ この環境の stack は GHC 9.8.4 に対して
    「Stack has not been tested with GHC versions above 9.4」の警告を出す。**動作には影響しない。**
    記事に載せるかは要検討。
- **オープンユニオンは `runghc` だけで自作できる**（`check/18-union/Union.hs`）。
  `Union`（`Here`/`There`）・`Member`（`inj`/`prj`）・`Eff`・`send`・
  2 つの効果とハンドラーまで、パッケージ無しで動いた。
  - `Member` の素朴な実装には `{-# OVERLAPPING #-}`・`{-# OVERLAPPABLE #-}` が要る。
    実ライブラリは型族（`FindElem`）で位置を計算してこれを避けている。
  - 空のリストのハンドラーは `run :: Eff '[] a -> a` で、`case u of {}` で書ける
    （`Union '[] a` にコンストラクターが無いため。`EmptyCase` は GHC2021 に含まれる）。
  - 種注釈 `(effs :: [* -> *])` を書くと `-Wstar-is-type` の警告が出るので**省く**。
- **17 回の `TeletypeI` はそのまま効果になる**（`check/18-freer/Teletype.hs`）。
  `singleton` を `send` に変えるだけ。`State` と `IO` も同時に混ざる。
- **10 回の `sum'` は `Eff` で書き直せて、出力が完全に一致する**（`check/18-freer/Sum.hs`）。
  `lift` → `sendM`、`execStateT` → `execState`、最後に `runM`。
- **ハンドラーの適用順は選べる**（`check/18-freer/StateWriter.hs`）。
  `Member` 制約で書いておけば `runWriter . runState` と `runState . runWriter` の
  両方が通り、結果のタプルの入れ子だけが変わる。
- **型推論の落とし穴が 4 つある**（`check/18-freer/README.md` に詳細）。
  `get` の型が決まらない・手順書の型を具体的なリストで書くと順が固定される・
  `-Wsimplifiable-class-constraints` の警告・中間結果に型注釈が要ることがある。
  **本文でどこまで触れるかは未決。**

## 未決事項・TODO

- [ ] **⚠ 自作の範囲を決める。** 選択肢は 3 つ。**16・17 回は「自作 → パッケージ」で
      通してきたので、何らかの形で自作するのが既定路線。**
  1. `Union`・`Member`・`Eff`・ハンドラーまで全部自作（検証済み・動く）。
     重なるインスタンスの説明が要る。
  2. `Union`（`Here`/`There`）と `Eff` だけ自作し、`Member` は自作しない。
     `send` の代わりに `Here`/`There` を手で書く。軽いが実用形から遠い。
  3. 自作しない。図と型シグネチャで説明してパッケージへ。**シリーズ初の「自作しない回」**
     になるので、採るなら理由を明記する。
- [ ] **⚠ `FTCQueue` をどこまで見せるか。** 17 回の削除済み原稿は擬似コード
      （`Impure u q >>= k = Impure u (q |> k)`）で済ませていた。自作 `Eff` に
      組み込むと重い。**擬似コードのままが有力。**
- [ ] **⚠ 「ハンドラー」という語を導入するか**（構成案 4）。16 回以降「インタープリター」で
      統一してきた。ライブラリの関数名は `interpret` なので、語を増やさない選択もある。
- [ ] Swierstra "Data types à la carte"（2008）の書誌と、
      `freer` → `freer-effects` → `freer-simple` のフォーク関係の裏を取る。
- [ ] Eff 系パッケージの現況を執筆時点で確認し直す（17-PLAN の表は 2026-08-08 時点）。
- [ ] 10 回を通読し、`sum'`・`# 多重持ち上げ`・`## liftIO`・`## モナドスタック` の
      当時の言い回しに繋がる形で書く（README.md「スタイル」）。
      行末 👉リンクのアンカーは `uv run scripts/anchor.py <見出し>` で生成する。
- [ ] 17 回の削除済み節（`git show dcd23e8`）を取り出し、18 回向けに書き直す。
- [ ] 練習 2 問を実装して動作確認する。
- [ ] 掲載コードを `check/18-*/` に揃える（現在あるのは設計検証用の試作）。
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
  （YoshikuniJujo、全 16 回）と正面から重なる回**（16-PLAN・17-PLAN で予告済み）。
  あちらは Freer Effects がゴールで、オープンユニオン・型族・キューまで自作している。
  **執筆前に改めて棚卸しする**（TODO）。
  - 差別化の軸は **10 回（モナド変換子）との接続**。シリーズ内に「モナド変換子で
    別種のモナドを混ぜた」回があり、そこへ戻れることが本シリーズ固有の構成になる。
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
  18 回で `FTCQueue` を扱うなら、左結合の `>>=` への対策という括りで隣接する話題になる。

## 補足

- 検証コードは `series/haskell-intro/check/18-*/` に置く（CLAUDE.md の「検証コード」の方式）。
  `freer-simple` を使うディレクトリは stack での実行方法と resolver を `README.md` に明記する
  （16 回の `free`・17 回の `operational` と同じ扱い。**resolver が違う点に注意**）。
- このファイルは拡張子を除く部分が大文字・数字・ハイフンのみなので
  `ARTICLES.tsv` の収集対象から除外される。
