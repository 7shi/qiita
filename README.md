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

1. **データ取得とマークダウン展開**
   - `data/*.json` (Qiita APIからの生JSONデータ)
   - `items/*.md` (フロントマター付きマークダウン)

2. **LLMによる解析スクリプト (独立・順不同)**
   - `scripts/classify.py` → `classified.tsv` (全記事の分類・SLUG生成)
   - `scripts/extract_series.py` → `series.jsonl` (本文からのシリーズ構成抽出)

   いずれも一度限りの整理作業に使った中間生成物で、結果を `articles/` (分類) と `series/` (シリーズ構成) に反映済みのため `classified.tsv` / `series.jsonl` 自体は削除済み。スクリプトはLLM抽出手法の参照コードとして残している。

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

- **記事一覧の集計のみ**
  ```bash
  make articles
  ```
  ※ `articles/{category}/{slug}.md` と `series/{slug}/{filename}.md` を走査し、記事一覧を `ARTICLES.tsv` に出力します。

---

### 2. LLMによる記事分類・構造化

`items/*.md` 展開後、以下のスクリプトを実行して記事の分類やシリーズ抽出を行います（互いに依存関係はありません）。

#### 記事の分類・SLUG生成
```bash
uv run scripts/classify.py [-m MODEL]
```
全記事についてLLMで解析・カテゴリ分類・スラッグ決定を行い、結果を `classified.tsv` に出力します。
- **デフォルトモデル**: `ollama:gemma4:31b-it-qat`
- **出力**: `classified.tsv`

#### 本文からのシリーズ記事抽出
```bash
uv run scripts/extract_series.py [-m MODEL] [-o OUTPUT]
```
`items/` 配下の全記事を対象に、本文冒頭に明示されているシリーズ構成（記事IDリンク群）をローカルLLMで解析し、判定結果を `series.jsonl` に出力します。（シリーズグループは `member_ids` に記事IDリスト、単体記事は `member_ids: []`）
- **デフォルトモデル**: `ollama:gemma4:31b-it-qat`
- **出力**: `series.jsonl`

## ドキュメント

- `PLAN.md` : `articles/` の整理状況とシリーズ化の残課題をまとめたドキュメント。
- `docs/` : LLM抽出等の各種ノウハウや仕様を整理したドキュメント類。
  - [docs/20260722-placeholder-extraction.md](docs/20260722-placeholder-extraction.md) : LLMによる構造化情報抽出テクニック（URLプレースホルダー置換＋自記事 `0` 方式）の解説。

## ディレクトリ・主要ファイル構成

- `articles/` : `articles/{category}/{slug}.md` の形で記事本体を格納するディレクトリです。記事一覧の正本（インデックス元）です。
- `ARTICLES.tsv` : `articles/` と `series/` ディレクトリを走査して集計した記事一覧ファイル。
- `data/` : Qiita APIから取得した生のJSONファイル（`7shi-1.json` など）が保存されます。
- `docs/` : 技術ドキュメントや抽出ノウハウをまとめたディレクトリです。
- `items/` : JSONから展開されたマークダウンファイルが保存されます。ファイル名は記事のID（`{id}.md`）になります。
- `PLAN.md` : `articles/` の整理状況とシリーズ化の経緯をまとめたドキュメント。
- `pyproject.toml` : `uv` によるPythonプロジェクトの設定ファイルです。
- `scripts/` : 各種スクリプトが配置されています。
- `series/` : 複数記事にまたがるシリーズを `series/{slug}/` ディレクトリにまとめたものです。各ディレクトリの `README.md` が目録（正本）です。
