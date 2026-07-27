---
coediting: false
comments_count: 0
created_at: '2025-03-22T04:20:56+09:00'
id: d1371b923bba9a78820e
likes_count: 4
private: false
reactions_count: 0
stocks_count: 0
tags:
- name: Python
  versions: []
- name: Gemini
  versions: []
- name: 画像生成
  versions: []
title: Gemini の画像生成でガチャ
updated_at: '2025-06-12T19:45:47+09:00'
url: https://qiita.com/7shi/items/d1371b923bba9a78820e
slide: false
---

Google AI Studio では、画像生成やプロンプトによる画像編集が行えます。ガチャを自動化するために Python でスクリプトを書きます。

更新履歴

- 2025/06/08 Sixel に対応
- 2025/05/09 新モデルに対応：Gemini 2.0 Flash Preview Image Generation `gemini-2.0-flash-preview-image-generation`
- 2025/04/01 google-genai 1.9.0 に対応（`base64.decodebytes` を除去）
- 2025/03/22 Gemini 2.0 Flash (Image Generation) Experimental `gemini-2.0-flash-exp-image-generation`

# Gemini 2.0 Flash Preview Image Generation

Google AI Studio は Gemini API による開発のプロトタイピングを行うサイトです。

https://aistudio.google.com/

機能拡張を重ねて、必ずしも開発者でなくても AI チャットサイトとしても使えるようになっています。

その中でも注目されているのは、Gemini 2.0 Flash Preview Image Generation による画像生成機能です。画像を生成するだけでなく、絵柄を保ったままプロンプトによる画像編集が行えます。

https://note.com/npaka/n/n32ceba34041b?sub_rt=share_sb

# 画像編集の例

入力画像（プロンプト「アニメの絵で、住宅街を女の子と猫が歩いている。」）

:::note info
Gemini ではなく、Grok で生成した画像です。
:::

<img src="https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/32057/665b07d5-e0dd-4342-8e51-5e755d02d7ed.jpeg" width="50%">

```text:プロンプト
少女だけを残して白背景にしてください。
```

出力画像

<img src="https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/32057/725a0d48-510d-421f-8c25-f1c563d90aff.jpeg" width="50%">

:::note info
左下の青いマークは、Gemini のウォーターマークです。
:::

この画像は足元が見切れています。この後の使用例で Gemini に足を描き加えてもらって、全身画像の生成を試みます。

# ガチャの自動化

なかなか思ったような画像が得られないことも多く、何かの拍子に出力がブロックされてしまうこともあるため、スクリプトで自動化するのが効率的です。

Google AI Studio にはスクリプト生成機能があります。まず、やりたいことを手作業で行って、[Get code] とすることで作業を再現するスクリプトが生成されます。

生成されたコードをベースにして、リファレンスを参考に画像の読み書き部分を簡略化しました。

https://ai.google.dev/gemini-api/docs/image-generation?hl=ja

Google AI Studio には無料枠があります。Gemini 2.0 Flash Preview Image Generation は 1 分間に 10 リクエスト、1 日に 1,500 リクエストが上限です。超過してもいきなり課金されるのではなく、429 エラーになります。1 分間の上限に達したときは、しばらく待って再試行します。

https://qiita.com/7shi/items/3fb540c72ad4577350c6

スクリプトを実行するには、Google AI Studio で API Key を発行して、環境変数 `GEMINI_API_KEY` にセットする必要があります。

```sh:追加ライブラリ
pip install pillow google-genai git+https://github.com/sbamboo/python-sixel.git
```

```python:gemini.py
import sys, os, time
from pathlib import Path
from PIL import Image
from io import BytesIO
from sixel.converter import SixelConverter
from google import genai
from google.genai import types

model  = "gemini-2.0-flash-preview-image-generation"
client = genai.Client(api_key=os.environ.get("GEMINI_API_KEY"))
config = types.GenerateContentConfig(
    temperature=1,
    top_p=0.95,
    top_k=40,
    max_output_tokens=8192,
    response_modalities=["image", "text"],
    safety_settings=[
        types.SafetySetting(
            category="HARM_CATEGORY_CIVIC_INTEGRITY",
            threshold="OFF",  # Off
        ),
    ],
    response_mime_type="text/plain",
)

def generate_content_retry(*args):
    for i in range(5, 0, -1):
        try:
            response = client.models.generate_content(
                model=model,
                config=config,
                contents=args,
            )
            if response.candidates and response.candidates[0].content:
                return response
            else:
                print(response.prompt_feedback, file=sys.stderr)
        except genai.errors.APIError as e:
            if hasattr(e, "code") and e.code in [429, 500, 502, 503]:
                print(e, file=sys.stderr)
                if i > 1:
                    for j in range(30, -1, -1):
                        print(f"\rRetrying... {j}s ", end="", file=sys.stderr, flush=True)
                        if j:
                            time.sleep(1)
                    print(file=sys.stderr)
            else:
                raise
    raise RuntimeError("Max retries exceeded.")

dbg = [None]

def generate(repeat, inputs, prompt):
    prompt = prompt.strip()
    print(prompt)
    print("-" * 20)
    imgpath = Path(inputs[0])
    imgs = [Image.open(path) for path in inputs]
    imgnum = 1
    for _ in range(repeat):
        response = generate_content_retry(*imgs, prompt)
        for part in response.candidates[0].content.parts:
            if part.text:
                print(part.text.strip())
            elif d := part.inline_data:
                while True:
                    file_name = f"{imgpath.stem}-{imgnum:03d}.png"
                    imgnum += 1
                    if not os.path.exists(file_name):
                        break
                dbg[0] = d
                img = Image.open(BytesIO(d.data))
                img.save(file_name)
                print("File saved:", file_name)
                w = 256
                h = int(w * img.height / img.width)
                img = img.resize((w, h), resample=Image.LANCZOS)
                with BytesIO() as buf:
                    img.save(buf, format="PNG")
                    SixelConverter(buf).write(sys.stdout)
                print()
```

`generate` の `inputs` は入力画像のリストです。複数指定できますが、空にすることはできません。出力画像のファイル名は、最初の入力画像のファイル名の後に連番を付加したものとなります。

例: `["foo.png", "bar.png"]` → foo-001.png, foo-002.png, ...

再度実行すれば、続きの連番から生成されます。

:::note info
5 枚程度生成してみて、必要に応じてプロンプトを修正して再度実行するような流れを想定しています。
:::

Sixel を利用して生成画像をターミナルに出力しています。詳細は以下を参照してください。

https://qiita.com/7shi/items/69d1e7c15c7c6a5bb34f

## 使用例

入力画像やプロンプトを指定して `gemini.generate` を呼び出します。

```py:girl.py
repeat = 5  # 試行回数
inputs = ["girl.png"]  # 入力画像
prompt = """
この少女はレディースサンダルを履いて歩いています。
足を描いて、全身が収まるようにしてください。
"""

from gemini import generate
generate(repeat, inputs, prompt)
```

全身が収まるような縦長の出力画像を期待しているため、それに合わせて手動でリサイズした入力画像を用意します。

入力画像

<img src="https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/32057/031f36e4-ec49-479e-bf53-bdfe175d4568.png" width="30%">

出力画像（例）

<img src="https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/32057/3c7e32bc-da53-4e0d-bd1b-b605292da28f.png" width="30%">
<img src="https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/32057/e542c0f5-644d-480b-a632-688a58d036e4.png" width="30%">
<img src="https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/32057/120769ab-3750-4db6-9448-e32ead0fdd48.png" width="30%">

:::note info
ここでは比較的うまくいった画像を掲載していますが、実際には失敗画像の方が多いです（👉[参考](https://x.com/7shi/status/1903136968017604923)）。プロンプトは結果を見ながら随時修正します。
:::

出力画像が並んでいるのを見ると、アニメの設定画集みたいですね。こんなことが個人でも手軽に行えるようになるとは、すごい時代になったものです。

# 関連記事

他の AI 画像生成と比較します。

https://note.com/7shi/n/n5d59945abf8d

同じ画像を使って動画生成を試みる記事です。

https://note.com/7shi/n/nc502404c49d4

もともと単なるテストだったのですが、これだけ使い回しているとキャラクターに愛着が湧いてきます。

https://note.com/7shi/n/na23085e09b86

理論的には、Gemini により設定画像からポーズを生成して、別途生成した背景を合成することで任意のシーンを描画することが可能です。その手法は紙芝居やマンガの生成にも応用できるでしょう。

https://note.com/7shi/n/n8e217297ece5
