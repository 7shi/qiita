# このリポジトリのルール

Qiita の記事を `articles/{category}/` と `series/{slug}/` に整理したリポジトリ。
整理の方針・作業フローは [PLAN.md](PLAN.md)、ディレクトリ構成は [README.md](README.md) を参照。

## フロントマターと Qiita の同期状態

記事のフロントマターは Qiita から取得したメタデータをそのまま保持している。
ローカルでの新規作成・編集は、以下のルールで**Qiita へ未反映であること**を表す。

| 状態 | `id` | `url` | `updated_at` |
|---|---|---|---|
| Qiita と同期済み | 20桁ID | Qiita の URL | 取得時の日時 |
| ローカルで新規作成した記事 | `''` | `''` | `''` |
| 既存記事をローカルで更新した | 20桁ID（そのまま） | URL（そのまま） | `''` |

- **新規記事は `id` と `url` を空文字列にする。** まだ Qiita 上に存在しないため。
  `created_at` には作成日を入れる。
- **新規・更新のどちらでも `updated_at` を空文字列にする。**
  空であることが「Qiita へ反映が必要」の目印になる。
- Qiita へ投稿・更新したら、取得し直して実際の値で埋める。
  新規記事の場合はこのとき `id` と `url` も埋まる。

```yaml
# ローカルで新規作成した記事の例
created_at: '2026-07-28T00:00:00+09:00'
id: ''
updated_at: ''
url: ''
```

記事本文を書き換えたときは `updated_at` を空にするのを忘れないこと。

## 記事執筆時の特殊記法

Qiita 独自の記法（`:::note` による補足説明、`<details>` による折りたたみなど）は @NOTATIONS.md を参照する。標準の Markdown ではないため、他所へ転記すると崩れる。

## 半角スペースのルール

アルファベット（バッククォートで囲んだコードを含む）とひらがな・カタカナ・漢字の間には半角スペースを入れる。句読点（、。・「」など）を挟む場合は不要。

- 例: `Haskell ではモナドと呼ばれる` / `` `callCC` は abortive です ``
- 既存の Qiita 記事タイトル（他記事へのリンクテキストなど）は実際のタイトルそのままなので対象外。書き換えない。

## 記事間のリンク

未投稿の記事へリンクする場合は相対パス（`haskell-generator.md` など）で書き、投稿後に Qiita の URL へ差し替える。

## Zenn への移植

Qiita の記事を Zenn 側でも公開したい場合の手順。**移動ではなく複製**として扱う。
Qiita 側のファイルはそのまま残置し、`id`・`url` などフロントマターも変更しない。

**最初から Zenn 限定で公開するとわかっている記事**（例: haskell-intro 13回以降。
@series/haskell-intro/README.md の「公開方針」を参照）は、Qiita に投稿する予定がないため
**執筆時点から Zenn の記法（`:::message`・`:::details` など。Zenn 側の `NOTATIONS.md` を参照）を
直接使う。** この場合、下記手順 4（記法変換）は不要になる。`:::note`・`<details>` による
Qiita 独自記法（@NOTATIONS.md）は、Qiita で公開する記事にのみ使う。

1. Zenn リポジトリ（`~/repos/zenn`）の流儀を確認する。
   - `README.md`・`CLAUDE.md`・`NOTATIONS.md`（Zenn 独自記法）
2. slug を決めて記事を初期化する（Zenn 側 CLAUDE.md の手順どおり）。
   ```
   npx zenn new:article --slug YYYYMMDD-xxx
   ```
3. 記事の本文（フロントマターを除く部分）をコピーし、フロントマターを Zenn 形式
   （`title`/`emoji`/`type`/`topics`/`published`）に置き換える。
4. **既に Qiita 独自記法で書かれている記事**（Qiita に投稿済みの記事を後から Zenn にも
   載せる場合など）に限り、Qiita 独自記法を Zenn 記法に変換する。
   - `:::note info` → `:::message`
   - `:::note alert` / `:::note warn` → `:::message alert`
   - `<details><summary>タイトル</summary> ... </details>` → `:::details タイトル ... :::`
5. Zenn リポジトリの慣例として、Claude Code で執筆した記事の冒頭に以下を入れる
   （既存の Zenn 記事に倣う。必須ではないが揃えておく）。
   ```
   :::message
   本記事の執筆には Claude Code (バージョン) を利用しました。
   :::
   ```
6. Qiita 上にしか存在しない記事へのリンク（シリーズ目次・参考リンクなど）はそのまま
   Qiita の URL で残す。書き換えない。
7. 複製した記事は [ZENN.tsv](ZENN.tsv) に対応を追記する（`qiita`・`zenn` の2列。
   それぞれのリポジトリからの相対パス）。以後は下記の同期スクリプトで本文を揃える。

### ZENN.tsv と同期スクリプト

```
make sync
```

`ZENN.tsv` の各行について、フロントマターを除いた本文を比較し、異なれば更新日時（mtime）が
新しい方の本文を古い方へ上書きする。フロントマターはそれぞれの形式のまま保持される。
Qiita 側を書き換えた場合は `updated_at` を空にする（前述の同期状態のルール）。

- `-n`（`--dry-run`）で更新内容の確認のみ。
- Zenn リポジトリの位置は `--zenn-root` で変更できる（既定は `~/repos/zenn`）。

## ARTICLES.tsv

- `articles/` と `series/` を走査して機械生成するインデックス。手で編集しない。
- 記事を追加・移動・リネームしたら再生成する。

```
make articles
```

拡張子を除く部分が大文字だけのファイル（`README.md`, `PLAN.md`, `NOTES.md` など）は記事ではないものとして収集対象から除外される。

## 検証コード

- 記事に載せるコードを実際に動かして確認する場合、`{記事のディレクトリ}/check/` に置く。
- 掲載コードと同じ内容のファイルと `README.md` を含める。
- 例: `series/XXX/check/README.md`
