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

- **LLMによる記事の分類・ファイル名提案**
  ```bash
  uv run python classify.py [-m MODEL]
  ```
  ※ `items/` 配下の各記事のメタデータや本文をローカルLLMで解析し、シリーズ判定・カテゴリ分類・スラッグ決定を行い、結果を `classification.tsv` に出力します。実際のリネーム・移動は行いません。
  ※ デフォルトモデルは `ollama:gemma4:31b-it-qat` です。

- **分類結果TSVの整形・タイトル紐付け**
  ```bash
  uv run python scripts/format_classification.py [-o OUTPUT]
  ```
  ※ `classification.tsv` に `items/{id}.md` から読み取ったタイトルを紐付け、`proposed_path` でソートしたTSVを出力します。デフォルトで `classified_titles.tsv` に出力されます（`-o -` で標準出力指定可）。

## ディレクトリ構成

- `data/` : Qiita APIから取得した生のJSONファイル（`7shi-1.json` など）が保存されます。
- `items/` : JSONから展開されたマークダウンファイルが保存されます。ファイル名は記事のID（`{id}.md`）になります。
- `scripts/` : 各種スクリプトが配置されています。
- `classify.py` : ローカルLLMを用いて記事の分類・スラッグ決定・ファイル名提案を行い、`classification.tsv` を出力するスクリプト。
- `PLAN.md` : リポジトリ内記事の整理計画・分類方針・命名規約をまとめたドキュメント。
- `pyproject.toml` : `uv` によるPythonプロジェクトの設定ファイルです。
