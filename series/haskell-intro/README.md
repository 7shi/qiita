# Haskell 超入門

1. [Haskell 超入門](01-intro.md) `145f1234f8ec2af923ef`
   - [【解答例】Haskell 超入門](01a-intro.md) `0ece8c3394e1328267ed`
2. [Haskell 代数的データ型 超入門](02-algebraic-data-types.md) `1ce76bde464b4a55c143`
   - [【解答例】Haskell 代数的データ型 超入門](02a-algebraic-data-types.md) `0bed757ed0b51944a669`
3. [Haskell アクション 超入門](03-actions.md) `85afd7bbd5d6c4115ad6`
   - [【解答例】Haskell アクション 超入門](03a-actions.md) `623fd55b8b68398becdc`
4. [Haskell ラムダ 超入門](04-lambda.md) `1345bf32003faff435cb`
   - [【解答例】Haskell ラムダ 超入門](04a-lambda.md) `bfa4c282c504c24578d2`
5. [Haskell アクションとラムダ 超入門](05-actions-and-lambdas.md) `4a8a2807bb5186576c61`
   - [【解答例】Haskell アクションとラムダ 超入門](05a-actions-and-lambdas.md) `cb99bb70ee103408bf51`
6. [Haskell IOモナド 超入門](06-io-monad.md) `d3d3492ddd90d47160f2`
   - [【解答例】Haskell IOモナド 超入門](06a-io-monad.md) `dfc114f133580ee85686`
7. [Haskell リストモナド 超入門](07-list-monad.md) `deb19c4cba933590ffbf`
   - [【解答例】Haskell リストモナド 超入門](07a-list-monad.md) `4a24fd9395f5a60d811d`
8. [Haskell Maybeモナド 超入門](08-maybe-monad.md) `c7d7eec066af0fe0688d`
   - [【解答例】Haskell Maybeモナド 超入門](08a-maybe-monad.md) `5a8b25d8db772bc27a71`
9. [Haskell 状態系モナド 超入門](09-state-monads.md) `2e9bff5d88302de1a9e9`
   - [【解答例】Haskell 状態系モナド 超入門](09a-state-monads.md) `fe978f1bd2d52760419d`
10. [Haskell モナド変換子 超入門](10-monad-transformers.md) `4408b76624067c17e933`
    - [【解答例】Haskell モナド変換子 超入門](10a-monad-transformers.md) `79fe0e4c77427368ae2d`
11. [Haskell 例外処理 超入門](11-exception-handling.md) `73e534c47bbebc71b37e`
    - [【解答例】Haskell 例外処理 超入門](11a-exception-handling.md) `f825dc54a5f6fb2a72dc`
12. [Haskell 構文解析 超入門](12-parsing.md) `b8c741e78a96ea2c10fe`
    - [【解答例】Haskell 構文解析 超入門](12a-parsing.md) `f65814b1e91d48ec8d12`
13. [Haskell 継続モナド 超入門](13-continuation-monad.md)（Zenn で公開）
14. [Haskell 型クラス 超入門](14-type-classes.md)（Zenn で公開）
15. [Haskell モナドとゆかいな仲間たち](15-monads-and-friends.md)（Zenn で公開）
16. [Haskell Freeモナド 超入門](16-free-monad.md)（Zenn で公開）
17. [Haskell Operationalモナド 超入門](17-operational-monad.md)（Zenn で公開）
18. [Haskell Effモナド 超入門](18-eff-monad.md)（Zenn で公開）
19. [Haskell アロー 超入門](19-arrow.md)（Zenn で公開）
20. [Haskell 圏論 超入門](20-category-theory.md)（Zenn で公開）

各回の導入文（前書き）は [PREFACES.md](PREFACES.md) にまとめてある。新しい回を書くときの文体合わせに使う。

## 動機

**あまり数学に寄せず、他のプログラミング言語と同じような接し方をする。** Haskell の入門記事は数学的な背景から入るものが多いが、このシリーズは言語の機能として説明し、書いて動かすことを優先する。「超入門」という題もこの姿勢から来ている。下記スタイルの「圏論には言及しない」は、この動機の具体的な現れ。

## スタイル

- 他記事へのリンクは行末で `👉[記事の省略タイトル](URL#アンカー)` の形式で統一する。
  - 省略タイトルは記事タイトルから「Haskell」と「超入門」を除いた部分（例: 03回なら`アクション`）。01回は`超入門`、15回は`モナドとゆかいな仲間たち`が例外（タイトルが「Haskell 超入門」「Haskell モナドとゆかいな仲間たち」で正規表現 `Haskell (.*) 超入門` にマッチしないため）。
  - アンカー（`#`以降）は見出しを小文字化し、記号を削除し、空白を `-` にしたもの。変換規則は実例から確認済みで、**Qiita と Zenn で同一**だった。規則の詳細と実装は [scripts/anchor.py](../../scripts/anchor.py) の docstring を参照（実例は [anchor-sample.md](../../anchor-sample.md)）。`uv run scripts/anchor.py --test` で実例との照合を検証できる。見出しを直接アンカーへ変換するには `uv run scripts/anchor.py <見出し>` を使う。
  - **日本語はパーセントエンコードせず、そのまま書く。** ブラウザ側が照合時にデコードするため、`#命令の型` と `#%E5%91%BD%E4%BB%A4%E3%81%AE%E5%9E%8B` は等価に機能する。ソースの可読性を優先して非エンコードで統一した（2026-08-11 に既存記事も一括変換）。エンコードした形が必要なら `uv run scripts/anchor.py --encode <見出し>`。
  - URLは01〜12回がfront matterの`id`からQiita URLを、13回以降はfront matterの`url`（下記「公開方針」参照）をそのまま使う。
- **タイトルの「Freeモナド」「IOモナド」のようなスペース無しの表記は、タイトルとしての整合性のためのもの。本文では引きずらず、通常どおり半角スペースを入れる**（`Free モナド`・`Operational モナド`）。日本語の文字と接する場合が対象で、[CLAUDE.md](../../CLAUDE.md) の「半角スペースのルール」に従う。タイトル・フロントマターの `title`／タグ・目次の記事タイトル・他記事へのリンクテキストは実際のタイトルなのでそのまま。
- 過去記事を「第N回」のような具体的な回数で参照しない。回数は覚えていない読者もいるし、シリーズ構成が変わる可能性もある。
- 過去記事の内容に触れるときは、その記事を読んでいなくても分かるように独立して説明し直してから、リンクだけ添える。過去記事の文章をそのまま引用しない。
- **言語拡張の基準は GHC2021。**（16回で確定。16-PLAN 変更点 11）
  - **GHC2021 に含まれる拡張は、掲載コードにも検証コードにも `{-# LANGUAGE #-}` を書かない。** `runghc`・`stack script` とも既定が GHC2021（GHC 9.2 以降）。含まれない拡張だけ書く（16回は0個、17回は `GADTs`、18回は `DataKinds`・`GADTs`）。
  - **GHC2021 に含まれるかどうかは記憶で判断せず、`runghc -XHaskell2010` に掛けて確かめる。** 拡張を1つずつ外して必要性を洗い出し、結果を `check/*/README.md` に表で残す。`FlexibleInstances`・`MultiParamTypeClasses`・`FlexibleContexts`・`TypeOperators`・`RankNTypes`・`EmptyCase`・`ScopedTypeVariables`・`DeriveFunctor` あたりは**含まれる**（プラグマ不要）。`DataKinds`・`GADTs`・`TypeFamilies`・`LambdaCase`・`UnboxedTuples`・`MagicHash` は**含まれない**。
  - Haskell2010 で必要になる拡張は、該当箇所に `:::message` で補足する。
  - `forall` は**使うだけなら拡張不要**（09回の `runST`、17回の `interpretWithMonad` はライブラリ側の型にある）。引数や `data` のフィールドに**自分で書くと `RankNTypes`**（GHC2021 に含まれるのでプラグマは不要。18回が初出）。
- **圏論には言及しない。** `Functor`（関手）のように名前の由来として触れるに留める。圏論の視点はモナドを自作・設計する際には役立つが、既存のモナドを使う観点では必須ではなく、そこまで準備するのは入門としては重すぎるため。上記「動機」のとおり、数学ではなく他言語と同じ感覚で扱うのが方針。初期の回（6〜10回）では導入文でも「圏論には言及しません」と明記していた。

## 公開方針（13回以降）

Zenn は投稿すると自動的に英語版が生成されるため、13回以降の**新規記事は Zenn で公開**する。過去記事（1〜12回）まで Zenn に移行すると読者が混乱するため、そこまでは遡らない。

ただし**執筆自体は従来どおりこの Qiita 側リポジトリで行う**。過去回（1〜12回）との用語・構成の一貫性を確認しながら書く必要があり、過去ログ（Qiita 側の記事本文や本シリーズの `*-PLAN.md`）との比較が執筆に不可欠なため。

- 本文は `series/haskell-intro/` にファイルを作成して執筆する（フロントマターは Qiita 形式のまま）。`id` は空にする（Qiita には投稿しない目印）。`url` は Zenn 側のスラッグが決まった時点で Zenn の記事 URL を入れる（本文が Zenn 側にまだ同期されていなくても構わない）。記事間の話題参照リンクをこの `url` から実 URL に変換するために使う（上記「スタイル」参照）。
- Qiita には投稿しないため、補足・折りたたみなどの記法は最初から Zenn 記法（`:::message`・`:::details`）を使う。Qiita 独自記法（`:::note`・`<details>`）は使わない。
  - **`:::details` は練習問題の解答例（`:::details 解答例`）専用。** 補足説明は折りたたまず `:::message` にする。補足を折りたたむと読者が開かずに読み飛ばすため、折りたたみは「まず自分で解いてほしい」解答例にだけ使う。
  - `:::message` はタイトルを持てないので、`:::details` のタイトルにあたる文言はブロック冒頭の一文に溶かして書く。既存の `:::message` は太字見出しを置かず、いきなり本文から始まる文体で統一されている。
- 完成後、Zenn リポジトリ（`~/repos/zenn`）へ複製して公開する。手順は [CLAUDE.md](../../CLAUDE.md) の「Zenn への移植」節を参照。
- **移動ではなく複製。** この Qiita 側のファイルはそのまま残し、`id` は空のままにする（Qiita へは投稿しない）。`url` は上記のとおり Zenn の記事 URL を入れる。

## 構想

シリーズは20回で完結した。以下は執筆時の構想メモ。

- 基本的なモナド（IO・List・Maybe・State・Reader・Writer・ST・関数・Either系・Parser・継続）は9〜13回でひととおり網羅している。STMのような並行処理向けの応用は範囲外とする。
- ゴールはアロー。モナドを超えた抽象化の枠組みとして19回に据えた。**20回はさらにその先へ進み、シリーズで積み上げてきたコードに圏論の名前を与えて完結させた**（[Haskell 圏論 超入門](20-category-theory.md)）。19回の `Kleisli`（Kleisli 圏）と17回の Operational モナド（米田の補題）が主な題材になった。
- Free・Operational・Effの関係:
  - FreeモナドとOperationalモナドはどちらも「DSL（命令の並び）を組み立てて後から解釈する」という同じ発想。Freeは再帰的なデータ型として直接構築し、命令を包む関手に`Functor`インスタンスが必要。Operationalは継続を明示するエンコーディング（`instr :>>= k`）を使い、GADTsで命令を列挙するだけでよく、`Functor`インスタンスが不要になる。
  - Effはこの「継続を明示するエンコーディング」（Freerモナド）をOperationalから受け継ぎつつ、命令の型をオープンユニオン（型レベルのリスト）にすることで**複数の効果の合成**を実現する。これはFree/Operationalの延長というより、モナド変換子（Monad Transformer）が担ってきた「複数の効果を組み合わせる」という課題を、継続明示エンコーディングという別の技法で解いたもの。スタックの順序や`lift`を気にせず効果を追加できる点が実用上のメリット。
  - **素の Freer を提供するライブラリは存在しない（2026-08-08 に freer-simple-1.2.1.2 のソースと doc-index で確認。詳細は 17-PLAN）。** freer-simple の `Eff` は素の Freer に 2 点の拡張を加えたもの: (1) 続きを素の関数ではなく型整列キュー（`FTCQueue`）で保持し、左結合 `>>=` の二乗問題を回避（線形化。17 回の Freer の節でコードを示して扱う）、(2) 命令の型をオープンユニオン化（18 回の主題）。`freer` パッケージも同様にオープンユニオン型の Eff 実装。**「Freer」の名前は概念・論文と freer-simple のモジュール名（`Control.Monad.Freer`）に残り、エクスポートされる型は `Eff` のみ。** 17 回と実際のライブラリ（Eff）の間にはこのギャップがある。なお freer-simple は lts-23 系列にのみ収録（lts-22・24・nightly にはない）。**この制約もあって 18 回は freer-simple ではなく effectful を使うことにした**（2026-08-09。18-PLAN「パッケージの変更」）。resolver は現行 LTS の `lts-24.53` で、**16・17 回も同じ resolver に更新済み**（18-PLAN「過去記事の resolver 更新」）。
- Freeモナドの「自由」の意味:
  - 圏論・代数学の「自由生成（free construction）」に由来する。自由モノイドがリスト（モノイド則だけを満たし、それ以外の余計な性質を持たない構造）であるのと同様に、Freeモナドは「モナド則だけを満たし、それ以上の意味づけを持たない構造」。
  - 実体は「DSLの命令列を、実行せずにデータ（木構造）として組み立てるための型」。
  - **組み立て（Freeモナド側）と解釈（インタプリタ側）を分離するのが核心**。`>>=`は命令をつなげるだけで実行しない。できあがった手順書を辿って実際の処理に変換するインタプリタは別関数として用意し、同じ手順書を本番実行用・テスト用モック・ログ収集用など複数のインタプリタで使い回せる。

### 網羅性の穴（`Foldable`・`Traversable`）

15回が `Functor`・`Applicative`・`Monad` の3段で止まったため、本編では扱わなかった。`Alternative`・`MonadFail`・`Comonad` も同様に宙に浮いたまま完結を迎えた。**20回の[補遺](20-category-theory.md#補遺)「周辺の型クラス」に整理してある。**

## 未定のアイデア

アロー（19回）の後、理論寄りの話題を扱う回を追加するかどうかを検討していた。**遅延評価・パラメトリシティ・カリー＝ハワード対応・ヒンドリー＝ミルナー型推論・F代数と再帰スキーム・圏論などの候補を洗い出したが、独立した回にはせず、20回の[補遺](20-category-theory.md#補遺)（「評価戦略と意味論」「型の理論」「圏論のその先」「応用」）に地図として整理する形に落ち着いた。** 圏論だけは20回の本編そのものとして扱った。

## 応用編

- [Haskellによる8086逆アセンブラ開発入門](8086-disassembler.md) `026839b2bc193dbfb0cb`
  - [【解答例】Haskellによる8086逆アセンブラ開発入門](8086-disassembler-answer.md) `6d228b6fc4734f48a33e`
- [Haskellによる代数計算入門](haskell-algebraic-computation.md) `096396f0007857676515`
  - [【解答例】Haskellによる代数計算入門](algebraic-calculation.md) `c62858d22a565095f791`

## 番外編

- [関数合成を機械的に扱う試み](function-composition.md) `f2c1365b792aa6046a49`
- [HUnit 超入門](hunit-intro.md) `9fb326a87de6c3083784`
- [モナド則の絵を描いてみた](monad-laws.md) `539c2c46edfb5313cbc6`
- [モナド則がちょっと分かった？](monad-laws-2.md) `547b6137d7a3c482fe68`
