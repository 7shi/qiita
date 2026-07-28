# 整理計画

## 現状

`articles/{category}/{slug}.md` の形で記事を整理済み（現在233件）。`category` は19種類（`ai`, `fsharp`, `haskell`, `javascript`, `languages`, `math`, `media`, `misc`, `parser`, `python`, `quantum`, `retro`, `therock`, `tools`, `tts`, `webassembly`, `wikipedia`, `wiktionary`, `winrt`）。ファイル名の英字slugはタイトル・本文から意訳した短いkebab-case。

`articles.tsv` は `articles/` ディレクトリを実際に走査して生成するインデックスファイル（`scripts/aggregate_articles.py`）。`articles/` を正とし、`articles.tsv` はそこから機械的に再生成できる。**`series/` は対象外**（`scripts/aggregate_articles.py` は `articles/*/*.md` のみ走査し、`series/{slug}/` へ移行済みの記事は `articles.tsv` に含まれない）。`make articles` で依存チェックなしに再生成できるよう `Makefile` を改変済み（`articles: articles.tsv` の中間ターゲットを廃止し、`articles` から直接 `aggregate_articles.py` を実行）。シリーズを `series/{slug}/` へ移行するたびに `make articles` を実行して再生成する。

分類作業に使った `classified.tsv` / `category_map.txt` / `category.txt` および集計スクリプト `scripts/aggregate_category.py` は役目を終えたため削除済み。`scripts/classify.py` はLLM呼び出しの参照コードとして残している（`articles.tsv` の生成には使わない）。

## シリーズ化

一部の記事は本文冒頭が関連記事へのリンク一覧（「〜一覧」「〜まとめ」）になっており、シリーズ関係が明示されている。この情報は `scripts/extract_series.py` でローカルLLMにより抽出済みで、結果は `series.jsonl` に保存されている（`root_id` と `member_ids` のペア）。

`series.jsonl` は機械可読だが人間には読めないため、`scripts/build_series.py` で `series.md` に整形した。以後は `series.md` を正データとし、`series.jsonl` はLLM出力の記録として残す。

### series.md の仕様

```markdown
## {slug}: {タイトル}

1. [{記事タイトル}](articles/{category}/{slug}.md) `{20桁ID}` ^root
2. ...
```

- 見出しの `{slug}` は起点記事のslug。シリーズを一意に識別する。
- 番号付き箇条書きの順序が連載順。
- マーク: `^root` 抽出元記事、`^dup` 複数シリーズに登場（要手動確認）、`^missing` `articles/` に存在しない記事（削除・限定公開）。
- `^root` は本文冒頭に他記事へのリンクを列挙していた記事、つまりこのシリーズ関係の抽出元を示す。連載順とは無関係。「〜一覧」「〜まとめ」のような目次記事が `^root` になる場合はシリーズの親記事にあたる。手動確認の手掛かりとして残しているマークで、確認・移行後は削除してよい。
- シリーズに属さない記事は記載しない（`series.md` に出てこない記事＝スタンドアロン）。
- 見出し行と箇条書き行はそれぞれ単純な正規表現でパースでき、ID・パス・タイトルの冗長性により `articles/` との整合性を検証できる。
- 本編の解答記事（【解答例】）はサブ項目として `1a.`, `2a.`, ... の番号を振る（本編 `1.` の直後に配置）。

### series/{slug}/ への移行

シリーズを確定させたら `articles/{category}/` から `series/{slug}/` へ記事を `git mv` し、`series/{slug}/README.md` に目録を作成、`series.md` から該当シリーズを削除する（=このシリーズは以後 `articles.tsv`/`series.md` の対象外とし、`series/{slug}/README.md` を正とする）。

- 連載順が確定している本編は `01-slug.md`, `02-slug.md`, ... とファイル名に連番を付与する。解答記事は `01a-slug.md` のように本編と同じ番号にサフィックス `a` を付ける。
- 応用編・番外編（本編と直接関係はあるが連載順に含まれない記事）は同じ `series/{slug}/` ディレクトリに入れるが、ファイル名に番号は付与しない。
- 他シリーズと記事を共有する場合（`^dup`）、その記事の主たる帰属先ではない側は移動せず、参照パスだけ更新する。主たる帰属先が定まらない/両シリーズにとって本質的なメンバーの場合は個別に判断する。
- 移動によって既存の `series.md` の他シリーズが参照しているパスが変わることがあるため、移動後は `series.md` 全体を `articles/haskell/` 等の旧パスでgrepして参照漏れがないか確認する。
- 最上位の `series/README.md` に `series/{slug}/README.md` へのリンクを1行ずつ追記する。

**実施例**: `haskell-intro`（Haskell 超入門、本編12章+解答12件、応用編2件、番外編4件）を `series/haskell-intro/` に移行済み。応用編・番外編のうち他シリーズが主たる帰属先の記事（`intel8086-machine-language-intro`, `polynomial-product`, `dirac-operator`）は移動せず `articles/` に残置し、`series.md` 側にトリムした形で記録を残した（[series/haskell-intro/README.md](series/haskell-intro/README.md), 関連コミット `4b680e4`）。

### 残作業

1. LLM抽出結果の手動確認。`series.md` に残る各シリーズについて、`^dup` の重複関係を人手で判断し、統合・分割・削除を決める。
2. 番号順が本文中のリンク出現順のため、連載順として妥当か確認する。
3. 確認・確定したシリーズから順に `series/{slug}/` へ移行する（上記の手順を踏襲、移行のたびに `make articles` で `articles.tsv` を再生成する）。
