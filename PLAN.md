# 整理計画

## 現状

`articles/{category}/{slug}.md` の形で281件の記事を整理済み。`category` は14種類（`ai`, `fsharp`, `haskell`, `javascript`, `languages`, `math`, `media`, `misc`, `python`, `quantum`, `retro`, `tools`, `webassembly`, `wiktionary`）。ファイル名の英字slugはタイトル・本文から意訳した短いkebab-case。

`articles.tsv` は `articles/` ディレクトリを実際に走査して生成するインデックスファイル（`scripts/aggregate_articles.py`）。`articles/` を正とし、`articles.tsv` はそこから機械的に再生成できる。

分類作業に使った `classified.tsv` / `category_map.txt` / `category.txt` および集計スクリプト `scripts/aggregate_category.py` は役目を終えたため削除済み。`scripts/classify.py` はLLM呼び出しの参照コードとして残している（`articles.tsv` の生成には使わない）。

## 残課題: シリーズ化

一部の記事は本文冒頭が関連記事へのリンク一覧（「〜一覧」「〜まとめ」）になっており、シリーズ関係が明示されている。この情報は `scripts/extract_series.py` でローカルLLMにより抽出済みで、結果は `series.jsonl` に保存されている（`root_id` と `member_ids` のペア）。

現状の `articles/{category}/{slug}.md` はシリーズ関係を反映していないフラット構造。`series.jsonl` を使ってシリーズをどう表現するか（ディレクトリ分割、ファイル名連番、フロントマターへの追記など）は今後検討する。
