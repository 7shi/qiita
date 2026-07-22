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

## 処理フロー

データ取得からLLMによる分類・整理までの全体フローは以下の通りです。

```
[ Qiita API ]
      │ (curl / jq)
      ▼
[ data/*.json ] (生JSONデータ)
      │
      │ (scripts/extract.py / make extract)
      ▼
[ items/*.md ] (フロントマター付きマークダウン)
      │
      │ (scripts/extract_series.py)
      ▼
[ series.jsonl ] (シリーズグループ判定結果)
      │
      │ (scripts/classify.py)
      ▼
[ classified.tsv ] (単体記事の分類・ファイル名提案)
```

## 使い方

### 1. 記事データの取得とマークダウン化

#### 一括実行
APIからの全データ取得およびマークダウンファイル（`items/*.md`）への展開を一括で行います。

```bash
make all
```

#### 個別実行
- **JSONデータの取得のみ**
  ```bash
  make data/7shi-1.json
  ```
  ※ ページ番号を指定して、対象のJSONデータのみを取得します。

- **マークダウンへの展開のみ**
  ```bash
  make extract
  ```
  ※ 取得済みのJSONファイルを読み込み、`items/` ディレクトリ配下にマークダウンファイル（`{id}.md`）を展開します。

---

### 2. LLMによる記事分類・構造化フロー

`items/*.md` 展開後、以下の順番でスクリプトを実行して記事の構造化・分類を進めます。

#### Step 1: 本文からのシリーズ記事抽出
```bash
uv run scripts/extract_series.py [-m MODEL] [-o OUTPUT]
```
`items/` 配下の全記事を対象に総当たりで、本文冒頭に明示されているシリーズ構成（記事IDリンク群）をローカルLLMで解析し、判定結果を `series.jsonl` に出力します。（シリーズグループは `member_ids` に記事IDリスト、単体記事は `member_ids: []`）
- **デフォルトモデル**: `ollama:gemma4:31b-it-qat`
- **出力**: `series.jsonl`

#### Step 2: 単体記事の分類・ファイル名提案
```bash
uv run scripts/classify.py [-m MODEL] [-s SERIES]
```
`series.jsonl` でシリーズグループ（`member_ids` が2件以上）と判定された記事を除外し、残りの単体記事についてLLMで解析・カテゴリ分類・スラッグ決定を行い、結果を `classified.tsv` に出力します。
- **デフォルトモデル**: `ollama:gemma4:31b-it-qat`
- **入力**: `series.jsonl`
- **出力**: `classified.tsv`

## ドキュメント

- `PLAN.md` : リポジトリ内記事の整理計画・分類方針・命名規約をまとめたドキュメント。
- `docs/` : LLM抽出等の各種ノウハウや仕様を整理したドキュメント類。
  - [docs/20260722-placeholder-extraction.md](docs/20260722-placeholder-extraction.md) : LLMによる構造化情報抽出テクニック（URLプレースホルダー置換＋自記事 `0` 方式）の解説。

## ディレクトリ・主要ファイル構成

- `data/` : Qiita APIから取得した生のJSONファイル（`7shi-1.json` など）が保存されます。
- `docs/` : 技術ドキュメントや抽出ノウハウをまとめたディレクトリです。
- `items/` : JSONから展開されたマークダウンファイルが保存されます。ファイル名は記事のID（`{id}.md`）になります。
- `scripts/` : 各種スクリプトが配置されています。
- `series.jsonl` : `extract_series.py` によるシリーズ判定結果ファイル。
- `classified.tsv` : `classify.py` による単体記事の分類・パス提案結果ファイル。
- `PLAN.md` : リポジトリ内記事の整理計画・分類方針・命名規約をまとめたドキュメント。
- `pyproject.toml` : `uv` によるPythonプロジェクトの設定ファイルです。
