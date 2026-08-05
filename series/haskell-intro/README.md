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

各回の導入文（前書き）は [PREFACES.md](PREFACES.md) にまとめてある。新しい回を書くときの文体合わせに使う。

## スタイル

- 他記事へのリンクは行末で `👉[記事タイトル](URL)` の形式で統一する。
- 過去記事を「第N回」のような具体的な回数で参照しない。回数は覚えていない読者もいるし、シリーズ構成が変わる可能性もある。
- 過去記事の内容に触れるときは、その記事を読んでいなくても分かるように独立して説明し直してから、リンクだけ添える。過去記事の文章をそのまま引用しない。

## 公開方針（13回以降）

Zenn は投稿すると自動的に英語版が生成されるため、13回以降の**新規記事は Zenn で公開**する。過去記事（1〜12回）まで Zenn に移行すると読者が混乱するため、そこまでは遡らない。

ただし**執筆自体は従来どおりこの Qiita 側リポジトリで行う**。過去回（1〜12回）との用語・構成の一貫性を確認しながら書く必要があり、過去ログ（Qiita 側の記事本文や本シリーズの `*-PLAN.md`）との比較が執筆に不可欠なため。

- 本文は `series/haskell-intro/` にファイルを作成して執筆する（フロントマターは Qiita 形式のまま。`id`・`url` は空にする＝Qiita には投稿しない目印）。
- Qiita には投稿しないため、補足・折りたたみなどの記法は最初から Zenn 記法（`:::message`・`:::details`）を使う。Qiita 独自記法（`:::note`・`<details>`）は使わない。
- 完成後、Zenn リポジトリ（`~/repos/zenn`）へ複製して公開する。手順は [CLAUDE.md](../../CLAUDE.md) の「Zenn への移植」節を参照。
- **移動ではなく複製。** この Qiita 側のファイルはそのまま残し、`id`・`url` も空のままにする（Qiita へは投稿しない）。

## 予定

16. Haskell Freeモナド 超入門
17. Haskell Operationalモナド 超入門
18. Haskell Effモナド 超入門
19. Haskell アロー 超入門

## 構想

- 基本的なモナド（IO・List・Maybe・State・Reader・Writer・ST・関数・Either系・Parser・継続）は9〜13回でひととおり網羅している。STMのような並行処理向けの応用は範囲外とする。
- ゴールはアロー。モナドを超えた抽象化の枠組みとして最終回に据える。
- Free・Operational・Effの関係:
  - FreeモナドとOperationalモナドはどちらも「DSL（命令の並び）を組み立てて後から解釈する」という同じ発想。Freeは再帰的なデータ型として直接構築し、命令を包む関手に`Functor`インスタンスが必要。Operationalは継続を明示するエンコーディング（`instr :>>= k`）を使い、GADTsで命令を列挙するだけでよく、`Functor`インスタンスが不要になる。
  - Effはこの「継続を明示するエンコーディング」（Freerモナド）をOperationalから受け継ぎつつ、命令の型をオープンユニオン（型レベルのリスト）にすることで**複数の効果の合成**を実現する。これはFree/Operationalの延長というより、モナド変換子（Monad Transformer）が担ってきた「複数の効果を組み合わせる」という課題を、継続明示エンコーディングという別の技法で解いたもの。スタックの順序や`lift`を気にせず効果を追加できる点が実用上のメリット。
- Freeモナドの「自由」の意味:
  - 圏論・代数学の「自由生成（free construction）」に由来する。自由モノイドがリスト（モノイド則だけを満たし、それ以外の余計な性質を持たない構造）であるのと同様に、Freeモナドは「モナド則だけを満たし、それ以上の意味づけを持たない構造」。
  - 実体は「DSLの命令列を、実行せずにデータ（木構造）として組み立てるための型」。
  - **組み立て（Freeモナド側）と解釈（インタプリタ側）を分離するのが核心**。`>>=`は命令をつなげるだけで実行しない。できあがった手順書を辿って実際の処理に変換するインタプリタは別関数として用意し、同じ手順書を本番実行用・テスト用モック・ログ収集用など複数のインタプリタで使い回せる。

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
