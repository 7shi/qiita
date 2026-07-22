# Qiita Articles

このリポジトリは、Qiitaで執筆した記事データをローカルで取得・管理するためのリポジトリです。

## 概要

Qiita API を利用して記事一覧データを JSON 形式で取得し、それらをパースして記事ごとに分割します。出力されるマークダウンファイルには、記事のメタデータ（タイトルやタグ、作成日時など）が YAML フロントマターとして付加されます。

## 前提条件

スクリプトの実行には以下のツールがインストールされている必要があります。

- [uv](https://github.com/astral-sh/uv) (Pythonのパッケージ・プロジェクト管理)
- `make`
- `curl`
- `jq`

## 使い方

以下のコマンドを実行すると、APIからのデータ取得からマークダウンファイルへの展開までが一括で行われます。

```bash
make all
```

個別のステップのみを実行したい場合は、以下のコマンドが利用できます。

- **JSONデータの取得のみ**
  ```bash
  make data/7shi-1.json
  ```
  ※ ページ番号を指定して、対象のJSONデータのみを取得できます。

- **マークダウンへの展開のみ**
  ```bash
  make extract
  ```
  ※ 取得済みのJSONファイルを読み込み、`items/` ディレクトリ配下にマークダウンファイル（`{id}.md`）を展開します。実行時に `uv` を通じて必要なPythonパッケージが準備されます。

- **LLMによる本文からのシリーズ記事IDグループ抽出**
  ```bash
  uv run scripts/extract_series.py [-m MODEL] [-o OUTPUT]
  ```
  ※ `items/` 配下の全記事を対象に総当たりで、本文冒頭に明示されているシリーズ構成（記事IDリンク群）をローカルLLMで解析し、判定結果を `series.jsonl` （シリーズグループは `member_ids` に記事IDリスト、単体記事は `member_ids: []`）に出力します。
  ※ デフォルトモデルは `ollama:gemma4:31b-it-qat` です。

- **LLMによる記事の分類・ファイル名提案**
  ```bash
  uv run scripts/classify.py [-m MODEL] [-s SERIES]
  ```
  ※ `series.jsonl` でシリーズグループ（`member_ids` が2件以上）判定された記事を除外し、残りの単体記事についてLLMで解析・カテゴリ分類・スラッグ決定を行い、結果を `classification.tsv` に出力します。
  ※ デフォルトモデルは `ollama:gemma4:31b-it-qat` です。

- **分類結果TSVの整形・タイトル紐付け**
  ```bash
  uv run scripts/format_classification.py [-o OUTPUT]
  ```
  ※ `classification.tsv` に `items/{id}.md` から読み取ったタイトルを紐付け、`proposed_path` でソートしたTSVを出力します。デフォルトで `classified_titles.tsv` に出力されます（`-o -` で標準出力指定可）。

## ドキュメント

- `PLAN.md` : リポジトリ内記事の整理計画・分類方針・命名規約をまとめたドキュメント。
- `docs/` : LLM抽出等の各種ノウハウや仕様を整理したドキュメント類。
  - [docs/20260722-placeholder-extraction.md](docs/20260722-placeholder-extraction.md) : LLMによる構造化情報抽出テクニック（URLプレースホルダー置換＋自記事 `0` 方式）の解説。

## ディレクトリ構成

- `data/` : Qiita APIから取得した生のJSONファイル（`7shi-1.json` など）が保存されます。
- `docs/` : 技術ドキュメントや抽出ノウハウをまとめたディレクトリです。
- `items/` : JSONから展開されたマークダウンファイルが保存されます。ファイル名は記事のID（`{id}.md`）になります。
- `scripts/` : 各種スクリプトが配置されています。
- `PLAN.md` : リポジトリ内記事の整理計画・分類方針・命名規約をまとめたドキュメント。
- `pyproject.toml` : `uv` によるPythonプロジェクトの設定ファイルです。
