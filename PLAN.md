# 整理計画

## 現状

`articles/{category}/{slug}.md` の形で281件の記事を整理済み。`category` は14種類（`ai`, `fsharp`, `haskell`, `javascript`, `languages`, `math`, `media`, `misc`, `python`, `quantum`, `retro`, `tools`, `webassembly`, `wiktionary`）。ファイル名の英字slugはタイトル・本文から意訳した短いkebab-case。

`articles.tsv` は `articles/` ディレクトリを実際に走査して生成するインデックスファイル（`scripts/aggregate_articles.py`）。`articles/` を正とし、`articles.tsv` はそこから機械的に再生成できる。

分類作業に使った `classified.tsv` / `category_map.txt` / `category.txt` および集計スクリプト `scripts/aggregate_category.py` は役目を終えたため削除済み。`scripts/classify.py` はLLM呼び出しの参照コードとして残している（`articles.tsv` の生成には使わない）。

## 残課題: シリーズ化

一部の記事は本文冒頭が関連記事へのリンク一覧（「〜一覧」「〜まとめ」）になっており、シリーズ関係が明示されている。この情報は `scripts/extract_series.py` でローカルLLMにより抽出済みで、結果は `series.jsonl` に保存されている（`root_id` と `member_ids` のペア）。

`series.jsonl` は機械可読だが人間には読めないため、`scripts/build_series.py` で `series.md` に整形した。以後は `series.md` を正データとし、`series.jsonl` はLLM出力の記録として残す。

### series.md の仕様

```markdown
## {slug}: {タイトル}

1. [{記事タイトル}](articles/{category}/{slug}.md) `{20桁ID}` ^root
2. ...
```

- 見出しの `{slug}` は起点記事のslug。シリーズを一意に識別する。
- 番号付き箇条書きの順序が連載順。将来ファイル名に付ける `01-`, `02-` の連番に対応する。
- マーク: `^root` 抽出元記事、`^dup` 複数シリーズに登場（要手動確認）、`^missing` `articles/` に存在しない記事（削除・限定公開）。
- `^root` は本文冒頭に他記事へのリンクを列挙していた記事、つまりこのシリーズ関係の抽出元を示す。連載順とは無関係で、71シリーズ中 先頭が20件・末尾が42件（続編が前作にリンクしているパターン）。「〜一覧」「〜まとめ」のような目次記事が `^root` になる場合はシリーズの親記事にあたる。手動確認の手掛かりとして残しているマークで、確認後は削除してよい。
- シリーズに属さない記事は記載しない（`series.md` に出てこない記事＝スタンドアロン）。
- 見出し行と箇条書き行はそれぞれ単純な正規表現でパースでき、ID・パス・タイトルの冗長性により `articles/` との整合性を検証できる。

### 残作業

1. LLM抽出結果の手動確認。71シリーズ・157記事のうち23記事が複数シリーズに重複（`^dup`）しており、大半は「子記事が目次記事へリンクしているだけ」のグループ。統合・分割・削除を人手で判断する。
2. 番号順が本文中のリンク出現順のため、連載順として妥当か確認する。
3. 確定後、シリーズを `articles/` の構造にどう反映するか（ディレクトリ分割、ファイル名連番、フロントマターへの追記など）を決める。
