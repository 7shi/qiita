# Haskell Operationalモナド 超入門 プラン

記事番号は 17、ファイル名は `17-operational.md`（予定）。

**状態: 下書き（2026-08-07）。本格的な構成設計はこれから。**
16-PLAN.md の「17 回以降への引き継ぎ」を出発点に、方向性だけを書き留めたもの。
決定事項ではないので、書き始める前に改めて詰める。

## 公開方針

[README.md](README.md) の「公開方針（13回以降）」に従う。13〜16 回と同じ扱い。

- 執筆はこの Qiita 側リポジトリ、公開は Zenn。`id`・`url` は空のままにし、Zenn のスラッグが
  決まった時点で `url` を埋める。
- 補足・折りたたみは Zenn 記法（`:::message`・`:::details`）。
- 練習問題は解答を別記事にせず `:::details` で本文に統合し、関連する節の末尾に分散。
- 検証コードは `check/17-*/` に置き、各ディレクトリに `README.md`。
  `operational` パッケージは base・mtl 外の依存なので、stack での実行方法を明記する
  （16 回の `free` と同じ扱い）。

## 記事の狙い（案）

**ゴールは「`Functor` を経由しないエンコーディング」。**

16 回の Free モナドは、`>>=` が枝を `fmap` で辿るため、命令の型に `Functor`
インスタンスを要求した。Operational は続き（継続）を明示的に持つ形にすることで、
`>>=` が `fmap` を使わずに済み、`Functor` インスタンスが不要になる。

同じ「DSL を組み立てて後から解釈する」発想のまま、エンコーディングだけを差し替える回。
**組み立てと解釈の分離という主題は 16 回から変えない。** 変わるのは表現の仕方だけ。

### この回の一行の主張（案）

16 回で手で書いた `instance Functor` が、まるごと要らなくなる。

|16 回（Free）|17 回（Operational）|
|---|---|
|`data GenF o next = Yield o next deriving Functor`|`data GenI o a where Yield :: o -> GenI o ()`|
|`data TeletypeF next = PutLine String next \| GetLine (String -> next)`|`PutLine :: String -> TeletypeI ()` / `GetLine :: TeletypeI String`|
|続きは `next` の位置に埋め込む|続きは `>>=` 側が持つ|
|`GetLine` の続きが関数になるのを自分で捌く|命令の戻り値の型を書くだけ|

特に **16 回の練習【問3】のテレタイプが効く。** `GetLine (String -> next)` という
「続きが関数になる」形と、その `fmap` が関数合成 `f . k` になるところを手で書かせてあるので、
Operational でそれが消えるのを見せると差分がはっきりする。

## Freer との関係・実用頻度（2026-08-07 追記）

**Operational と Freer は同じエンコーディングの別名。** タイトルは
「Haskell Operationalモナド 超入門」のままでよい、と確認した。

```haskell
-- operational の Program
instr b :>>= (b -> Program instr a)

-- Freer
data Freer f a = Pure a | forall b. Impure (f b) (b -> Freer f a)
```

命令 1 つと「その結果を受け取って続きを返す関数」の組という、同じ形。

|名前|出自|由来|
|---|---|---|
|Operational|Apfelmus、`operational` パッケージと The Monad.Reader の記事（2010 年頃）|操作的意味論（operational semantics）|
|Freer|Kiselyov & Ishii "Freer Monads, More Extensible Effects"（2015）|`Free` より要求が少ない（`Functor` すら不要）＝「より自由」|

**Operational が先。** Kiselyov らが Extensible Effects を作り直す際に同じ形へ辿り着き、
`Free` との対比で `Freer` と命名した、という順序。
（2015 年の論文が Apfelmus を明示的に引用しているかは**未確認**。出すなら裏を取る。）

紛らわしい点として、**Extensible Effects の最初の版（2013 年、Kiselyov, Sabry, Swords）は
Free ベースで `Functor` を要求していた。** 2015 年の Freer 版がそれを作り直したもので、
現行の Eff 系ライブラリは後者。18 回で経緯に触れるならこの区別が要る。

- **決定: 本文で Freer の名前を出す。**（下記 TODO の「名前だけ出すか」は出す方向で確定）
  18 回で読者が `freer-simple`・`polysemy` などの外部資料に当たると Freer という語に
  出会うため。「このエンコーディングは Freer とも呼ばれ、Eff 系のライブラリはその名前を使う」
  という一言を置く。深入りはしない。

### 外部記事との関係（2026-08-08 追記）

16 回の推敲で日本語の Free モナド解説を棚卸しした（16-PLAN「既存記事との関係」）。
そこで**この回と最も近い日本語資料**が見つかったので記録しておく。

- [Freer Effectsが、だいたいわかった](https://qiita.com/YoshikuniJujo/items/988ac4b69a27974154fd)
  （YoshikuniJujo、全 N 回のシリーズ）
  - 圏論用語を避けて自作していく方針が本シリーズと同じ。**Free の概要から入り、
    存在型・型族・GADTs を個別に解説してから Freer と Extensible Effects へ進む**という
    構成も、16 → 17 → 18 回の流れとほぼ重なる。
  - **17 回の範囲では衝突しない。** あちらは Freer Effects がゴールで、
    こちらは「エンコーディングの差し替え」だけを 1 回分に切り出す構成のため。
    ただし**18 回（Eff）では正面から重なる**ので、その時点で改めて棚卸しする。
  - GADTs・存在型の導入の仕方（上記 TODO）で迷ったときの比較対象になる。
    **参考にはするが、本文からリンクは張らない**（16 回と同じ方針。読者を別の前提へ
    送らない）。
- 「Operational」という名前で書かれた日本語の解説は、Free に比べて格段に少ない。
  この回の存在意義（Eff の前段として独立させる）はその点でも立つ。

### 実用頻度についての注意

**`operational` パッケージ自体の実務での採用例は稀。** 教材としての性格が強い。
一方で**エンコーディングは現代のエフェクトシステムの土台**になっている。

|パッケージ|立ち位置|
|---|---|
|`free`|依存としては多い。ただし「Free で DSL を書く」用途は限定的|
|`operational`|ほぼ教材。実務での採用例は稀|
|`polysemy`・`effectful`・`freer-simple`・`fused-effects`|エフェクトシステムとして実際に使われている|
|`mtl`|依然として主流|

※ Hackage のダウンロード数などは**未確認**。記事に定量的な主張を書くなら裏を取る。

記事では「パッケージは広く使われていないが、この形が Eff 系の土台になっている」という
位置づけを明示する。**実用頻度を偽らない。** 逆に言えば、17 回の価値は
「18 回（Eff）でエンコーディングの転回とオープンユニオンを同時に教えずに済む」ことにある。
オープンユニオンだけでも `DataKinds`・`TypeOperators`・型レベルリスト・`Member` 制約と重いので、
負荷分散として 17 回を分ける意義がある。

## 16 回からの引き継ぎ（回収候補）

16-PLAN.md「17 回以降への引き継ぎ」より。**すべてを 17 回で回収する必要はない。**

|項目|17 回で扱うか|メモ|
|---|---|---|
|Operational モナド|**主題**|—|
|`Foldable`・`Traversable`|**扱わない（決定）**|下記。対比が綺麗に立たなかった|
|codensity・Church エンコード|保留|左結合 `>>=` の対策。18 回以降でも可|
|`Alternative`・`MonadFail`|保留|Operational と関係が薄い|
|Filinski『Representing Monads』|**扱わない（決定）**|README の「未定のアイデア」＞「制御構造をモナドで書くという理論」へ集約した|

### `Foldable`・`Traversable` の扱い（検討して見送りに決定）

16 回では決定事項 13 で「扱わない」とした。17 回で「Free はなれるが Operational はなれない」
という**対比として**拾えないか検討したが、**成り立たなかったので見送る。**

検証結果（`ghc` / `stack script --resolver lts-22.28 --package free` で確認）。

|型|`Foldable`|根拠|
|---|---|---|
|`Free Two a`（木）|**可**|`sum` → `13`、`foldr (:) []` → `[1,10,2]`、`traverse` も通る|
|`Free (GenF o) a`（`Yield o next`）|**可**|ただし集まるのは最後の戻り値だけで無意味|
|`Free TeletypeF a`（`GetLine (String -> next)`）|**不可**|下記エラー|
|Operational / Freer|**不可**|続きが常に関数の中にある|

```text
error: [GHC-16437]
    • Can't make a derived instance of ‘Foldable TeletypeF’:
        Constructor ‘GetLine’ must not contain function types
```

**真の境界は「Free か Operational か」ではなく「続きが関数の中にあるかどうか」で、
これは Free の内側を貫いている。** 16 回のテレタイプは Free でありながら `Foldable` に
できない。Operational は構造上つねに続きが関数なので決して満たさない、という言い方なら
正確だが、**説明するのに 3 ケース要る。** 17 回の主題に対して寄り道。

見送りの理由:

1. **対比が綺麗に立たない**（上記）。無理に立てると不正確になる。
2. **17 回は既に重い。** GADTs／存在型というシリーズ初の「表現力のための言語拡張」を
   背負う回に、未紹介の型クラスを 2 つ足すのは過積載。
3. **本来の回収先が違う。** `Foldable`・`Traversable` は 15 回（`Functor`・`Applicative`・
   `Monad` の 3 段）の穴なので、その続編で扱うのが筋（README.md「構想」の「網羅性の穴」）。

### 型クラス名を出さずに使える洞察（採用）

上記の裏にある事実は、**型クラス名を出さずに 1 段落で使う。** Operational の位置づけを
支えるので、名前なしなら置く価値がある。文案:

> Operational では、続きが関数の中にあります。つまり入力を与えないと先へ進めないので、
> 手順書の中身を外から並べて取り出すことはできません。**インタプリタを通す以外に中を見る
> 方法がない**、という構造になっています。

「Free は汎用のデータ構造でもあり、Operational は DSL 専用」という整理につながる。
置き場所は構成案 6（Free と Operational の使い分け）が候補。

## 構成案（ざっくり）

1. **Free の復習と不満** — 16 回の `GenF`・`TeletypeF` を再掲し、`Functor` インスタンスが
   要ること、特に `GetLine` で続きが関数になることを思い出させる。
   16 回を読んでいない読者にも分かるよう独立して説明し直す（README のスタイル）。
2. **続きを外に出す** — `Yield o next` の `next` を型から外し、代わりに `>>=` の側が
   `(b -> Program instr a)` として持つ形へ。ここが転回点。
   `>>=` が継続を合成するだけになり、`fmap` が消えることを見せる。
3. **GADTs で命令を並べる** — 命令の戻り値の型を各コンストラクタが宣言する。
   `Yield :: o -> GenI o ()`、`GetLine :: TeletypeI String` の形。
   **シリーズ初の「表現力のための言語拡張」**（16 回の `DeriveFunctor` は
   「便利のための言語拡張」だった。この対比は使えそう）。
4. **インタプリタ** — `view` で 1 段ずつ剥がして辿る。16 回と同じ題材
   （ジェネレーター・テレタイプ）を同じインタプリタの形で書き直し、**手順書の表現が
   変わってもインタプリタの書き方は変わらない**ことを見せる。
5. **operational パッケージ** — `Program`・`singleton`・`view`・`ProgramView`。
   16 回の `free` パッケージ節と同じ位置づけ。
6. **Free と Operational の使い分け** — 表で整理。
7. **まとめ** — 次回予告は書かない（16 回決定事項 12・ユーザー指示）。

## 未決事項・TODO

- [ ] `operational` パッケージの API を実際に確認する（`Control.Monad.Operational` の
      `Program`・`ProgramT`・`singleton`・`view`・`ProgramView(Return, (:>>=))`・
      `interpretWithMonad`）。**記憶で書かず、必ず動かして確かめる。**
      stack で lts-22.28 に入っているか要確認。無ければ resolver を調整する。
- [ ] 自作版をどこまで書くか。16 回は `Free` を自作してからパッケージに進んだので、
      同じ流れなら `Program` も自作する。ただし存在型（`forall b.`）が必要になるため、
      GADTs の導入と合わせて重くならないか要検討。
- [ ] **GADTs をどう導入するか。** シリーズで初めて型の表現力を広げる拡張になる。
      `ExistentialQuantification` との関係をどこまで説明するか。深入りは避けたい。
      GADT 構文なしで書けるなら、そちらを先に見せる案もある。
- [x] Freer モナドという呼び名を出すか → **出す。** 上記「Freer との関係」を参照。
      同一のエンコーディングであることと、Eff 系が Freer と呼ぶことを一言。深入りはしない。
- [ ] 2013 年版／2015 年版 Extensible Effects の経緯を 17 回で書くか 18 回に回すか。
      17 回では「Freer とも呼ぶ」だけに留め、経緯は 18 回の方が収まりが良いかもしれない。
- [ ] 左結合 `>>=` の性能問題は Operational でも残る（はず）。16 回で `Free` について
      書いた「性能の注意」と同じ現象か、実測して確認する。
      codensity をここで出すかは分量次第。
- [ ] 題材をどうするか。16 回と同じジェネレーター・テレタイプを使い回すのが差分を見せるには
      最適だが、同じ題材が 2 回続く単調さがある。
      - **スタックマシンは 16 回の練習【問3】【問4】に入った**（16-PLAN 変更点 13、
        `check/16-stack/`）。17 回で使えなくなったわけではなく、むしろ
        **同じ題材を Free と Operational で書き比べる材料になる。**
        16 回は `Pop (Int -> next)` と `Functor` インスタンスが要ったが、
        Operational なら `Pop :: StackI Int` と GADTs で書けるはず（要検証）。
        ジェネレーターを 13 回（継続）と 16 回（Free）で作り直したのと同じ構図。
      - 新しい題材を足すなら、GADTs の戻り値の型が複数あることを見せやすいものを選ぶ。
- [ ] 前提知識の整理。14 回（型クラス・辞書渡し）・16 回（Free）は必須。
      13 回（継続）は「続きを持ち回る」という点で効くが、必須にはしない。
- [ ] 導入文（PREFACES.md 用）の案を書く。

## 検討メモ

- **Free との優劣を煽らない。** Operational が「上位互換」ではない。Free は再帰的な
  データ構造そのものなので木として扱いやすく（上記「型クラス名を出さずに使える洞察」）、
  Operational は命令の列挙が楽。用途が違うという整理にする。
- **圏論には言及しない**（README のスタイル）。Freer・Kan 拡張・codensity の圏論的背景には
  立ち入らない。名前を出すとしても由来として触れるに留める。
- 16 回の「自由」の節に相当する、名前の由来を説明する節を置くか。
  「Operational」は operational semantics（操作的意味論）から来ているはずだが、
  **未確認。** 出すなら裏を取る。
  ここは Freer の由来（`Free` より要求が少ないので「より自由」）と並べると収まりが良い。
  16 回で「自由とは何か」を説明済みなので、比較級として接続できる。

## 補足

- 検証コードは `series/haskell-intro/check/17-*/` に置く（CLAUDE.md の「検証コード」の方式）。
- このファイルは拡張子を除く部分が大文字・数字・ハイフンのみなので
  `ARTICLES.tsv` の収集対象から除外される。
