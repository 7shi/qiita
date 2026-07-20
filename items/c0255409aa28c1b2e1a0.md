---
coediting: false
comments_count: 0
created_at: '2025-03-16T03:07:37+09:00'
id: c0255409aa28c1b2e1a0
likes_count: 9
private: false
reactions_count: 0
stocks_count: 6
tags:
- name: Python
  versions: []
- name: 画像認識
  versions: []
- name: Gemma
  versions: []
- name: ollama
  versions: []
title: Ollama で Gemma 3 による画像認識
updated_at: '2025-03-25T21:04:59+09:00'
url: https://qiita.com/7shi/items/c0255409aa28c1b2e1a0
slide: false
---

Ollama を利用して Gemma 3 で画像を分析します。

# Gemma 3

Gemma 3 は Google が開発したローカルで動かせる LLM です。

https://note.com/npaka/n/nc6b8f3cc8837

1B/4B/12B/27B の 4 つのサイズが用意されています。

https://ollama.com/library/gemma3

4B 以上のモデルは画像認識が可能で、サイズが大きいほど精度が向上します。本記事では 4B を例に説明を進めます。

# 準備

Ollama をインストールして、モデルをダウンロードしてください。

```sh
ollama pull gemma3:4b
```

# コマンドラインからの実行

画像を置いたフォルダで Ollama を実行します。

```sh
ollama run gemma3:4b
```

処理速度を測定するためのオプションを指定します。

```text
/set verbose
```

プロンプトで `./` に続けてファイル名を指定すれば読み込まれます。

```text:プロンプト
画像を説明してください。./image.png
```

入力画像（別途生成）: image.png (1024×1024)

<details><summary>生成パラメーター</summary>

- Model: [Animagine XL 3.1](https://huggingface.co/cagliostrolab/animagine-xl-3.1)
- Prompt: 1girl, original, eating pizza
- Negative Prompt: nsfw, lowres, (bad), text, error, fewer, extra, missing, worst quality, jpeg artifacts, low quality, watermark, unfinished, displeasing, oldest, early, chromatic aberration, signature, extra digits, artistic error, username, scan, [abstract]

</details>

<img src="https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/32057/f5f4171d-5a9a-4534-609c-8128ae3b9f2c.png" width="50%">

出力例

> この画像は、アニメ風の若い女性を描いたものです。以下に詳細を説明します。
> 
> *   **人物:**
>     *   若い女性で、茶色のショートヘアをしています。
>     *   頬にはピンク色のチークをしています。
>     *   大きな、少し憂鬱な目をしています。
>     *   彼女は、オレンジ色のフリースジャケットと緑色のセーターを着ています。
> *   **背景:**
>     *   木製のテーブルの上に座っています。
>     *   背景には窓があり、自然光が差し込んでいます。
> *   **オブジェクト:**
>     *   彼女は、ピザを食べています。ピザにはトマトとチーズが乗っています。
> *   **スタイル:**
>     *   全体的にアニメ風で、細部まで丁寧に描かれています。
>     *   色使いは暖色系で、全体的に温かみのある雰囲気です。
> 
> この画像は、美味しそうなピザを食べる若い女性の可愛らしいイラストです。

```text:測定結果
total duration:       6.9259706s
load duration:        62.7936ms
prompt eval count:    273 token(s)
prompt eval duration: 2.942s
prompt eval rate:     92.79 tokens/s
eval count:           214 token(s)
eval duration:        3.912s
eval rate:            54.70 tokens/s
```

以下の環境で測定しました。

- OS: Windows 11 Home [10.0.26100.3476]
- RAM: DDR4-3200 64GB
- CPU: AMD Ryzen 5 5600X 6-Core Processor
- GPU: AMD Radeon RX 7600 XT (VRAM 16GB)

## 文章での説明

プロンプトで指定すれば文章で説明できます。

```text:プロンプト
箇条書きではなく文章で、画像を説明してください。./image.png
```

出力例

> このイラストは、明るい光が差し込む室内で、可愛らしいアニメ風の少女を描いています。
> 
> 少女は、オレンジ色のフリースジャケットと緑色のセーターを着ています。彼女は、丸いテーブルの上に置かれたピザを、両手で持って、一口食べる準備をしています。ピザにはトマトソースとチーズ、そしてトマトのスライスが散りばめられています。
> 
> 少女の表情は、楽しそうに、そして少し照れくさそうに見つめています。頬にはほんのりとしたピンク色のチークをしています。背景には、窓から差し込む自然光がぼんやりと写っており、暖かく、居心地の良い雰囲気を作り出しています。全体的に、このイラストは、美味しそうなピザと、少女の可愛らしい表情が組み合わさって、温かみのある、ほのぼのとした雰囲気を醸し出しています。

```text:測定結果
total duration:       6.359634s
load duration:        64.1589ms
prompt eval count:    280 token(s)
prompt eval duration: 2.848s
prompt eval rate:     98.31 tokens/s
eval count:           188 token(s)
eval duration:        3.438s
eval rate:            54.68 tokens/s
```

# 文字認識

文字認識も可能です。

```text:プロンプト
文字を読み取ってください。./text.png
```

ただし精度的に 4B は実用的ではなく、27B で 90% くらいという印象です。

<blockquote class="twitter-tweet" data-conversation="none"><p lang="ja" dir="ltr">日本語も多少は読めるみたいです。 <a href="https://t.co/Dvb2NqiQSK">pic.twitter.com/Dvb2NqiQSK</a></p>&mdash; 七誌 (@7shi) <a href="https://twitter.com/7shi/status/1899764515161731074?ref_src=twsrc%5Etfw">March 12, 2025</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script> 

手書き文字にも対応しています。詳細は以下の記事を参照してください。

https://note.com/aisatoshi/n/n27cb98388e7e

# Python

Python から読み込む例です。

```sh:ライブラリ追加
pip install ollama
```

```py
import ollama

response = ollama.chat(
    model = "gemma3:4b",
    messages = [{
        "role": "user",
        "content": "画像を説明してください。",
        "images": ["image.png"],
    }],
)
print(response["message"]["content"])
```

## リサイズ

画像サイズによっては応答しなくなる可能性があるため、リサイズ処理を追加した例です。

:::note info
Ollama に縮小した画像データを渡しますが、元のファイルは変更しません。
:::

```sh:ライブラリ追加
pip install pillow
```

```py
import ollama, io
from PIL import Image

def shrink_image(image_path, max_size):
    image = Image.open(image_path)
    w1, h1 = image.size
    if max(w1, h1) > max_size:
        if w1 > h1:
            w2 = max_size
            h2 = int(h1 * (max_size / w1))
        else:
            w2 = int(w1 * (max_size / h1))
            h2 = max_size
        image = image.resize((w2, h2), resample=Image.LANCZOS)
    buf = io.BytesIO()
    image.save(buf, format="PNG")
    return buf.getvalue()

response = ollama.chat(
    model = "gemma3:4b",
    messages = [{
        "role": "user",
        "content": "画像を説明してください。",
        "images": [shrink_image("image.png", 512)],
    }],
)
print(response["message"]["content"])
```

# LangChain

LangChain での利用法は以下の記事を参照してください。

https://zenn.dev/asap/articles/18b110d551b811

# Kobold.cpp

Ollama だけでなく Kobold.cpp での使い方も説明されている記事です。

https://six-loganberry-ba7.notion.site/25-03-24-Ollama-kobold-cpp-Gemma3-1c0f7e7600e980c08683f6f7a7f27ab1

# 関連記事

本記事は、以下の記事の改訂版という位置付けです。Gemma 3 は Llama 3.2-Vision よりも高性能です。

https://qiita.com/7shi/items/500fc95ecf80866ba83a

ピザ画像の元ネタは以下を参照してください。

https://qiita.com/7shi/items/b4da43f342f0fe3c189c
