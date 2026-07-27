---
coediting: false
comments_count: 0
created_at: '2025-01-09T23:19:25+09:00'
id: 500fc95ecf80866ba83a
likes_count: 24
private: false
reactions_count: 0
stocks_count: 22
tags:
- name: Python
  versions: []
- name: 画像認識
  versions: []
- name: LLaMA
  versions: []
- name: ollama
  versions: []
title: Ollama で Llama 3.2-Vision のテストと翻訳
updated_at: '2025-03-16T18:22:09+09:00'
url: https://qiita.com/7shi/items/500fc95ecf80866ba83a
slide: false
---

Ollama を利用して Llama3.2-Vision で画像を分析し、Aya Expanse で日本語に翻訳します。

:::note info
Llama 3.2-Vision よりも高性能な Gemma 3 がリリースされており、そちらのご利用を推奨します。
:::

https://qiita.com/7shi/items/c0255409aa28c1b2e1a0

更新履歴

- 2025/03/16 Gemma 3 に誘導
- 2025/01/10 リサイズ処理を追記

# 準備

Ollama をインストールして、モデルを pull してください。

```sh
ollama pull llama3.2-vision
ollama pull aya-expanse
```

Python にライブラリをインストールしてください。

```sh
pip install ollama
```

## 日本語

Llama3.2-Vision は日本語での出力は一応できますが、英語に比べて内容が劣化します。画像認識で公式にサポートされているのは英語だけです。

https://huggingface.co/meta-llama/Llama-3.2-11B-Vision-Instruct

> Note for image+text applications, English is the only language supported.

日本語訳

> 注意：image+text での利用については、英語のみがサポートされます。

そのため本記事では画像の分析結果を英語で出力して、別のモデルで日本語に翻訳します。

:::note info
ちょっと試してみるのであれば、日本語で質問した方が手軽ではあります。記事の最後に、コードを書かずに Ollama で直接実行する例を紹介しています。
:::

# コード

```py
import ollama

response1 = ollama.chat(
    model = "llama3.2-vision",
    messages = [{
        "role": "user",
        "content": "What is in this image?",
        "images": ["image.png"],
    }],
)
print(response1["message"]["content"])

response2 = ollama.chat(
    model = "aya-expanse",
    messages = [{
        "role": "user",
        "content": "Translate into Japanese:\n" + response1["message"]["content"],
    }],
)
print(response2["message"]["content"])
```

## 実行例

入力画像（別途生成）: image.png (1024×1024)

<details><summary>生成パラメーター</summary>

- Model: [Animagine XL 3.1](https://huggingface.co/cagliostrolab/animagine-xl-3.1)
- Prompt: 1girl, original, eating pizza
- Negative Prompt: nsfw, lowres, (bad), text, error, fewer, extra, missing, worst quality, jpeg artifacts, low quality, watermark, unfinished, displeasing, oldest, early, chromatic aberration, signature, extra digits, artistic error, username, scan, [abstract]

</details>

<img src="https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/32057/f5f4171d-5a9a-4534-609c-8128ae3b9f2c.png" width="50%">

実行結果

> The image contains a girl eating pizza. The girl has short gray hair and large yellow eyes. She is wearing an orange jacket with black cuffs, over a green top. Her cheeks are blushed pink, as if she is embarrassed or shy. There is a pizza on the table in front of her. It has a thin crust and is topped with cheese, pepperoni, and tomato sauce. The girl is holding a slice of the pizza in her left hand, while bringing another piece to her mouth with her right hand.
> 画像には、ピザを食べる少女が写っています。少女は灰色の短い髪と大きな黄色の目をしています。彼女はオレンジ色のジャケット（黒の袖）に緑色のシャツを着ています。頬は恥ずかしがり屋か緊張しているようにも見えるピンク色に赤らめています。彼女の前のテーブルにはピザがあります。生地は薄く、チーズ、ペパロニ、トマトソースがのっています。少女は左手でピザの一切れを持ち上げ、右手で別のピザを口に入れようとしています。

:::note info
実行結果は毎回変わります。
:::

以下の環境で 43 秒掛かりました。

- OS: Windows 11 Home [10.0.26100.2605]
- RAM: 32GB
- CPU: AMD Ryzen 5 5600X 6-Core Processor
- GPU: AMD Radeon RX 7600 XT (VRAM 16GB)

# リサイズ

画像サイズによっては応答がなくなることがあるようなので、リサイズ処理を追加した例です。

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

response1 = ollama.chat(
    model = "llama3.2-vision",
    messages = [{
        "role": "user",
        "content": "What is in this image?",
        "images": [shrink_image("image.png", 512)],
    }],
)
print(response1["message"]["content"])

response2 = ollama.chat(
    model = "aya-expanse",
    messages = [{
        "role": "user",
        "content": "Translate into Japanese:\n" + response1["message"]["content"],
    }],
)
print(response2["message"]["content"])
```

# コマンド版

コマンドライン引数でファイル名などを指定できるようにして、ストリームで出力して統計情報を表示するようにしました。

- https://gist.github.com/7shi/64c99dda8c9b413a92284be2960a47e2

Ollama でストリームを扱う方法は以下の記事を参照してください。

https://qiita.com/7shi/items/be2ca03a654f4d26ba5f

:::note info
頻繁にモデルを切り替えるとオーバーヘッドが大きい上にメモリリークも蓄積します。画像ごとに分析と翻訳をするのではなく、まずすべての画像を分析してから、その結果を翻訳しています。
:::

## 実行例

先ほどと同じ画像を読み込ませた例です。

```text
$ time python test.py image.png --translate Japanese --model aya-expanse --shrink 512
Image 1/1: image.png

This picture contains a girl with short hair and yellow eyes, possibly wearing an orange jacket, eating pizza. There is also some light coming from the window on the left side of the picture. The atmosphere looks like a cozy dining room or restaurant. In general, it seems to be a casual setting where someone can enjoy their meal without feeling rushed or pressured to finish quickly.

--- Statistics ---
total duration:       0:00:26.061680
load duration:        0:00:09.553586
prompt eval count:    18
prompt eval duration: 0:00:07.657000
prompt eval rate:     2.35 tokens/s
eval_count:           75
eval duration:        0:00:08.752000
eval rate:            8.57 tokens/s

Image 1/1: image.png

この写真には、ショートヘアで黄色い目をした女の子がおり、おそらくオレンジ色のジャケットを着てピザを食べています。写真の左側の窓から光が差し込んでいます。雰囲気は居心地の良いダイニングルームやレストランみたいです。一般的に、誰かが食事を楽しめるカジュアルな環境で、急いで終わらせなければならないというプレッシャーがありません。

--- Statistics ---
total duration:       0:00:10.892199
load duration:        0:00:07.681414
prompt eval count:    154
prompt eval duration: 0:00:00.047000
prompt eval rate:     3276.60 tokens/s
eval_count:           93
eval duration:        0:00:02.770000
eval rate:            33.57 tokens/s

real    0m37.878s
user    0m0.000s
sys     0m0.015s
```

説明の部分だけを抽出します。

> This picture contains a girl with short hair and yellow eyes, possibly wearing an orange jacket, eating pizza. There is also some light coming from the window on the left side of the picture. The atmosphere looks like a cozy dining room or restaurant. In general, it seems to be a casual setting where someone can enjoy their meal without feeling rushed or pressured to finish quickly.
> この写真には、ショートヘアで黄色い目をした女の子がおり、おそらくオレンジ色のジャケットを着てピザを食べています。写真の左側の窓から光が差し込んでいます。雰囲気は居心地の良いダイニングルームやレストランみたいです。一般的に、誰かが食事を楽しめるカジュアルな環境で、急いで終わらせなければならないというプレッシャーがありません。

# 参考

以下のポストに触発されて実験しました。

<blockquote class="twitter-tweet"><p lang="ja" dir="ltr">llama3.2-vision ローカルで動いた！<br>すごすぎんか？？まじ？ <a href="https://t.co/wLtsyv7Fdm">https://t.co/wLtsyv7Fdm</a> <a href="https://t.co/v2YyeimoYR">pic.twitter.com/v2YyeimoYR</a></p>&mdash; GOROman (@GOROman) <a href="https://twitter.com/GOROman/status/1877189504378765754?ref_src=twsrc%5Etfw">January 9, 2025</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

## Mac

Mac では MLX VLM の方が高速なようです。

https://zenn.dev/wmoto_ai/articles/58e6bcf58d6032

<blockquote class="twitter-tweet"><p lang="ja" dir="ltr">ollama + llama3.2-vision だと遅いけど、MLX VLM + Qwen2-VL-2B だととても速い。</p>&mdash; GOROman (@GOROman) <a href="https://twitter.com/GOROman/status/1877661652956422472?ref_src=twsrc%5Etfw">January 10, 2025</a></blockquote>

生成した情報を macOS のアプリ「写真」の機能である「キャプション（写真説明）」に書き込む記事です。

https://n-pilot.hateblo.jp/entry/2025/01/10/043352

## 直接実行

コードを書かずにファイル名を直接指定しても認識します。（カレントディレクトリには `./` が必要）

https://note.com/akb428/n/nad1b37ca082c

<blockquote class="twitter-tweet"><p lang="ja" dir="ltr">ollama run llama3.2-vision &quot;これなに？詳細に説明して。 ./a.png&quot; <br><br>cliだけでいけた！ <a href="https://t.co/wQJfD8RBrk">https://t.co/wQJfD8RBrk</a> <a href="https://t.co/LuUfcia8Mz">pic.twitter.com/LuUfcia8Mz</a></p>&mdash; 佐々木竹充/SASAKI TAKERU (@urekat) <a href="https://twitter.com/urekat/status/1877505251026284685?ref_src=twsrc%5Etfw">January 9, 2025</a></blockquote>
