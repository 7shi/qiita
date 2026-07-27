---
coediting: false
comments_count: 0
created_at: '2025-04-23T00:21:18+09:00'
id: 06ed3e922630fcbd7734
likes_count: 13
private: false
reactions_count: 0
stocks_count: 8
tags:
- name: Python
  versions: []
- name: Gemini
  versions: []
title: Gemini API 移行ガイド
updated_at: '2025-04-23T16:58:53+09:00'
url: https://qiita.com/7shi/items/06ed3e922630fcbd7734
slide: false
---

このガイドでは、旧 Python ライブラリ google-generativeai を使用しているコードを、新しい google-genai ライブラリに移行するための主要な変更点と対応するコード例を示します。

# 概要

新ライブラリの大きな変更点は、API へのアクセスがクライアントインスタンスを介して行われるようになったことです。これにより、複数の設定や異なる API エンドポイントをより柔軟に管理できるようになります。

「こんにちは」 と話しかけるだけの簡単な例を示します。

```py:旧 google-generativeai
import os
import google.generativeai as genai

genai.configure(api_key=os.environ["GEMINI_API_KEY"])

model = genai.GenerativeModel(model_name="gemini-2.0-flash")
response = model.generate_content("こんにちは")
print(response.text)
```

```py:新 google-genai
import os
from google import genai

client = genai.Client(api_key=os.environ.get("GEMINI_API_KEY"))

response = client.models.generate_content(
    model="gemini-2.0-flash",
    contents=["こんにちは"],
)
print(response.text)
```

# 機能別

機能別に移行例を紹介します。

## ライブラリのインポートと初期化

旧ライブラリでは、API キーをグローバルに設定していました。新ライブラリでは、API キーをクライアントインスタンスの作成時に渡します。これにより 1 つのコード内で複数の API キーを利用することが可能になります。

```py:旧 google-generativeai
import os
import google.generativeai as genai

# API キーをグローバルに設定
genai.configure(api_key=os.environ["GEMINI_API_KEY"])
```

```py:新 google-genai
import os
from google import genai

# API キーを持つクライアントインスタンスを作成
client = genai.Client(api_key=os.environ["GEMINI_API_KEY"])
```

## モデルとコンテンツ生成

旧ライブラリではモデルインスタンスを作成していましたが、新ライブラリではクライアントインスタンスからモデル操作のエンドポイント `client.models` を経由して操作を行います。

```py:旧 google-generativeai
# モデルインスタンスを作成
model = genai.GenerativeModel(model_name="gemini-2.0-flash")

# コンテンツを生成
response = model.generate_content("こんにちは")
print(response.text)
```

```py:新 google-genai
# クライアントインスタンスから `generate_content` を呼び出す
# モデル名は引数として渡す
response = client.models.generate_content(
    model="gemini-2.0-flash",
    contents=["こんにちは"], # 入力はリスト形式
)
print(response.text)
```

:::note info
新ライブラリでは、入力コンテンツはテキストだけでなく画像なども含めることができるように、リスト形式で渡します。テキストのみの場合もリストで囲んでください。
:::

## 生成設定の指定

生成時の各種設定（温度、最大トークン数など）は、旧ライブラリではモデルインスタンスまたは生成メソッド呼び出し時に指定できましたが、新ライブラリでは生成メソッドの `config` 引数に `GenerateContentConfig` オブジェクトとして渡します。

```py:旧 google-generativeai
# モデルインスタンス作成時に指定
model = genai.GenerativeModel(
    model_name="gemini-2.0-flash",
    generation_config={
        "temperature": 0.7,
        "max_output_tokens": 150,
    },
)
response = model.generate_content("短い物語を書いてください")

# メソッド呼び出し時に指定
model = genai.GenerativeModel(model_name="gemini-2.0-flash")
response = model.generate_content(
    "短い物語を書いてください",
    generation_config={
        "temperature": 0.7,
        "max_output_tokens": 150,
    },
)
```

```py:新 google-genai
response = client.models.generate_content(
    model="gemini-2.0-flash",
    contents=["短い物語を書いてください"],
    config=genai.types.GenerateContentConfig(
        temperature=0.7,
        max_output_tokens=150,
    ),
)
```

## ストリーミング生成

長い応答をチャンクごとに受け取るストリーミングは、旧ライブラリでは `stream=True` で指定していましたが、新ライブラリでは専用のメソッド `generate_content_stream` を使用します。

```py:旧 google-generativeai
model = genai.GenerativeModel(model_name="gemini-2.0-flash")

# `stream=True` を指定
response = model.generate_content("非常に長い文章を書いてください", stream=True)

# チャンクを順に処理
for chunk in response:
    if chunk.text:
        print(chunk.text, end="", flush=True)
```

```py:新 google-genai
# `generate_content_stream` メソッドを使用
response = client.models.generate_content_stream(
    model="gemini-2.0-flash",
    contents=["非常に長い文章を書いてください"],
)

# チャンクを順に処理
for chunk in response:
    if chunk.text:
        print(chunk.text, end="", flush=True)
```

:::note info
`chunk.text` は `None` になることがあるため、確認した方が無難です。`flush=True` を指定しないと、バッファリングされてすぐ出力されません。
:::

## ファイルのアップロードと管理

画像や PDF などのファイルを API に渡すためにアップロードする機能も、クライアントインスタンスの `files` エンドポイントに移動しました。

```py:旧 google-generativeai
file_path = "path/to/your/image.jpg"
mime_type = "image/jpeg"

# ファイルをアップロード
uploaded_file = genai.upload_file(path=file_path, mime_type=mime_type)
print(f"Uploaded file: {uploaded_file.uri}")

# アップロードされたファイルを使用して生成
response = model.generate_content([uploaded_file, "この画像について説明してください"])

# ファイルを削除
genai.delete_file(uploaded_file.name)
```

```py:新 google-genai
import time # ファイル処理完了を待つために必要

file_path = "path/to/your/image.jpg"

# クライアントの `files` エンドポイントからアップロード（MIME タイプは自動判別）
uploaded_file = client.files.upload(file=file_path)
print(f"Uploaded file: {uploaded_file.uri}")

# ファイルの状態が `PROCESSING` から変わるまで待機（必要に応じて）
while uploaded_file.state.name == "PROCESSING":
    print("Waiting for file to be processed...")
    time.sleep(2) # 適宜待機時間を調整
    uploaded_file = client.files.get(name=uploaded_file.name) # 最新の状態を取得

# アップロードされたファイルを使用して生成
response = client.models.generate_content(
    model="gemini-2.0-flash",
    contents=[uploaded_file, "この画像について説明してください"]
)

# ファイルを削除
client.files.delete(name=uploaded_file.name)
```

:::note info
新ライブラリでは、動画などでは内容のトークン化が非同期で行われるため、完了待ちの処理を入れています。（必要なければ素通り）
:::

## キャッシュの利用

特定のコンテンツ（例：長いシステムプロンプトや大きなファイル）をキャッシュして、繰り返し生成に使用することで効率化を図る機能も、クライアントの `caches` エンドポイントに移動しました。

```py:旧 google-generativeai
# キャッシュを作成
cache = genai.caching.CachedContent.create(
    model="gemini-2.0-flash",
    system_instruction="あなたはプロの編集者です。",
    contents=["キャッシュしたい長いテキストコンテンツ"],
)
print(f"Created cache: {cache.name}")

# キャッシュを使用してモデルインスタンスを作成
cached_model = genai.GenerativeModel.from_cached_content(cache)
cached_model.generation_config = {"temperature": 0.3} # 生成設定も適用

# キャッシュされたモデルで生成
response = cached_model.generate_content("このテキストを校正してください")

# キャッシュを削除
cache.delete()
```

```py:新 google-genai
# クライアントの `caches` エンドポイントからキャッシュを作成
cache = client.caches.create(
    model="gemini-2.0-flash",
    config=genai.types.CreateCachedContentConfig(
        system_instruction="あなたはプロの編集者です。",
        contents=["キャッシュしたい長いテキストコンテンツ"],
    ),
)
print(f"Created cache: {cache.name}")

# キャッシュを使用して生成設定を作成
generate_config_with_cache = genai.types.GenerateContentConfig(
    cached_content=cache.name, # キャッシュの名前を指定
    temperature=0.3, # 他の生成設定も一緒に指定
)

# キャッシュを使用して生成
response = client.models.generate_content(
    model="gemini-2.0-flash", # キャッシュ作成時と同じモデルを指定
    contents=["このテキストを校正してください"],
    config=generate_config_with_cache,
)

# キャッシュを削除
client.caches.delete(name=cache.name)
```

:::note info
新ライブラリでは、キャッシュ自体が生成設定の一部として扱われるようになり、より柔軟性が高まっています。
:::

## 利用統計情報の取得

生成応答に含まれるトークン数などの利用統計情報へのアクセス方法も変更されています。

### 非ストリーミング

応答オブジェクト `response` から `usage_metadata` を取得します。

```py:旧 google-generativeai
model = genai.GenerativeModel(model_name="gemini-2.0-flash")
response = model.generate_content("テスト")

# 応答オブジェクトから取得
if response.usage_metadata:
    print(f"Prompt tokens: {response.usage_metadata.prompt_token_count}")
```

```py:新 google-genai
response = client.models.generate_content(
    model="gemini-2.0-flash",
    contents=["テスト"],
)

# 応答オブジェクトから取得
if response.usage_metadata:
    print(f"Prompt tokens: {response.usage_metadata.prompt_token_count}")
```

### ストリーミング

旧ライブラリではストリーミングの場合でも最終的な `usage_metadata` は応答オブジェクトから取得することができましたが、新ライブラリでは最終チャンクからのみとなっています。

```py:旧 google-generativeai
model = genai.GenerativeModel(model_name="gemini-2.0-flash")
response = model.generate_content("テスト", stream=True)

# チャンクを順に処理
for chunk in response:
    if chunk.text:
        print(chunk.text, end="", flush=True)

# 応答オブジェクトから取得
if response.usage_metadata:
    print(f"Prompt tokens: {response.usage_metadata.prompt_token_count}")

# または最終チャンクの `to_dict()` から取得
chunk_dict = chunk.to_dict()
if usage_metadata := chunk_dict.get("usage_metadata"):
    print("Chunk prompt tokens:", usage_metadata["prompt_token_count"])
```

```py:新 google-genai
response = client.models.generate_content_stream(
    model="gemini-2.0-flash",
    contents=["テスト"],
)

# チャンクを順に処理
for chunk in response:
    if chunk.text:
        print(chunk.text, end="", flush=True)

# 最終チャンクの `to_json_dict()` から取得
chunk_dict = chunk.to_json_dict()
if usage_metadata := chunk_dict.get("usage_metadata"):
    print("Chunk prompt tokens:", usage_metadata["prompt_token_count"])
```

# 参考

https://ai.google.dev/gemini-api/docs?hl=ja

- [テキスト生成](https://ai.google.dev/gemini-api/docs/text-generation?hl=ja)
- [コンテキストのキャッシュ保存](https://ai.google.dev/gemini-api/docs/caching?hl=ja&lang=python)
- [Files API](https://ai.google.dev/gemini-api/docs/files?hl=ja)


# 関連記事

本記事は、以下の記事で行った移行作業から、要点をまとめました。

https://qiita.com/7shi/items/f7625cc56a57e2d245ea

新ライブラリでのエラーハンドリングについての記事です。

https://qiita.com/7shi/items/3fb540c72ad4577350c6
