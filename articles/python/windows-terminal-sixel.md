---
coediting: false
comments_count: 0
created_at: '2025-06-08T18:04:40+09:00'
id: 69d1e7c15c7c6a5bb34f
likes_count: 1
private: false
reactions_count: 0
stocks_count: 1
tags:
- name: Python
  versions: []
- name: SIXEL
  versions: []
- name: WindowsTerminal
  versions: []
title: Windows Terminal で Python から Sixel
updated_at: '2025-10-19T23:44:20+09:00'
url: https://qiita.com/7shi/items/69d1e7c15c7c6a5bb34f
slide: false
---

Windows Terminal では Sixel がサポートされています。Python から Sixel で画像を表示します。

# python-sixel

Python で Sixel を扱うには python-sixel というライブラリがよく紹介されますが、Windows 非対応の termios に依存しているため、WSL でしか動きません。

Windows に対応したフォークを利用します。

- https://github.com/sbamboo/python-sixel

```bat
pip install git+https://github.com/sbamboo/python-sixel.git
```

# サンプル

test.png を表示する例です。

```py
import sys, sixel
sixel.converter.SixelConverter("test.png").write(sys.stdout)
```

:::note info
これを拡張して、画像ファイルの指定やアスペクト比を維持したリサイズを実装しました。

- https://gist.github.com/7shi/d987aaf60362351bf43f3e64da22579a
:::

matplotlib で描画した数式を表示する例です。（グラフも同様にできます）

```py:formula.py
formula = r"\int_{0}^{\pi} \sin(x) dx = 2"

import sys, io, matplotlib.figure, sixel
fig = matplotlib.figure.Figure(figsize=(1, 1), dpi=120)
fig.text(0, 0, f"${formula}$", fontsize=12, color="white")
with io.BytesIO() as buf:
    fig.savefig(buf, format="png", bbox_inches="tight", facecolor="black")
    sixel.converter.SixelConverter(buf).write(sys.stdout)
```
**実行例:**
![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/32057/4e6c7724-f099-41a2-b9b8-4fbf754a3330.png)

画像生成と組み合わせた例です。ガチャをするときに画像ファイルを別途確認しなくて済むのが便利です。

```py:pizza.py
model  = "Linaqruf/anything-v3-1"
prompt = "girl eating pizza"
output = "pizza.png"

import sys, diffusers, torch, sixel
pipe = diffusers.StableDiffusionPipeline.from_pretrained(model)
pipe = pipe.to("cuda")
result = pipe(prompt=prompt, width=256, height=256, num_inference_steps=10)
result.images[0].save(output)
sixel.converter.SixelConverter(output).write(sys.stdout)
```
**実行例:**
![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/32057/52d9734f-69b8-4e43-a57f-60aa2ac5524e.png)

:::note info
絵柄は毎回変わります。
:::

# 関連記事

diffusers の使い方については以下の記事を参照してください。

https://qiita.com/7shi/items/b4da43f342f0fe3c189c

:::note info
この記事は CPU で動かす前提のため、GPU で動かすには `pipe = pipe.to("cuda")` を追加する必要があります。
:::

Gemini による画像生成ガチャの記事です。Sixel を利用しています。

https://qiita.com/7shi/items/d1371b923bba9a78820e
