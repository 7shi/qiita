---
coediting: false
comments_count: 0
created_at: '2024-11-13T05:14:06+09:00'
id: f0942fda82fefcbbdb03
likes_count: 2
private: false
reactions_count: 0
stocks_count: 2
tags:
- name: Python
  versions: []
- name: StableDiffusion
  versions: []
- name: FLUX.1
  versions: []
title: stable-diffusion.cpp と Python バインディング
updated_at: '2024-11-13T11:59:44+09:00'
url: https://qiita.com/7shi/items/f0942fda82fefcbbdb03
slide: false
---

画像生成 AI の C++ 実装である stable-diffusion.cpp と、その Python バインディングを紹介します。

# stable-diffusion.cpp

LLM では PyTorch ベースの transformers ライブラリに対して、C++ で実装された llama.cpp があります。

同様に、画像生成では PyTorch ベースの diffusers ライブラリに対して、C++ で実装されたのが stable-diffusion.cpp です。

https://github.com/leejet/stable-diffusion.cpp

SD 1.x/2.x/XL/3/3.5, FLUX.1 dev/schnell に対応しています。

stable-diffusion.cpp は、llama.cpp と同じ ggml というライブラリを使用しています。CUDA や ROCm (HIP) などには ggml で対応しています。

自分でビルドしなくても、バイナリが配布されています。

- https://github.com/leejet/stable-diffusion.cpp/releases

:::note info
Windows で Radeon を使用している場合、WebUI 系では FLUX.1 の生成速度が十分でないため、記事執筆時点では stable-diffusion.cpp が最速だと思われます。
:::

## 使用方法

コマンドとしてモデルやプロンプトを指定して画像を生成します。

```sh:SD1.5
sd -m v1-5-pruned-emaonly.safetensors -p "a lovely cat"
```

<img src="https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/32057/6775292c-bcfa-908b-8571-3158e608f2c5.png" width="50%">

Radeon RX 7600 XT (HIP SDK 5.5.1) での生成時間（モデル読み込みを除く）: 16.10s (1.49it/s)

:::note info
モデルの自動ダウンロード機能はないため、Hugging Face などから自分でダウンロードする必要があります。
:::

## FLUX.1

FLUX.1 は量子化した GGUF が用意されています。

- https://huggingface.co/leejet/FLUX.1-schnell-gguf
- https://huggingface.co/leejet/FLUX.1-dev-gguf

これによりメモリ使用量を削減することができます。

```sh:FLUX.1 schnell
sd --diffusion-model flux1-schnell-q4_k.gguf --vae ae.safetensors --clip_l clip_l.safetensors --t5xxl t5xxl_fp16.safetensors -p "a lovely cat holding a sign says 'flux.cpp'" --cfg-scale 1.0 --sampling-method euler --steps 4
```

<img src="https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/32057/d03822f8-4644-38a1-4ee5-d5b8c64d0a1a.png" width="50%">

Radeon RX 7600 XT (HIP SDK 5.5.1) での生成時間（モデル読み込みを除く）: 23.68s (2.99s/it)

使い方の詳細は、公式ドキュメントを参照してください。

- https://github.com/leejet/stable-diffusion.cpp/blob/master/docs/flux.md

# Python バインディング

llama.cpp に対して llama-cpp-python があるように、stable-diffusion.cpp にも stable-diffusion-cpp-python があります。

https://github.com/william-murray1204/stable-diffusion-cpp-python

pip でのインストール時に stable-diffusion.cpp をビルドする仕組みになっています。そのため事前にビルド環境を準備する必要があります。

Windows での Radeon (HIP) では問題があります。解決策は以下の Issue を参照してください。

- https://github.com/william-murray1204/stable-diffusion-cpp-python/issues/5

## メリット

stable-diffusion.cpp はコマンドとして実行しますが、起動ごとにモデルを読み込むため、オーバーヘッドがばかになりません。

Python バインディングを使用すれば、モデルを一度だけ読み込んで、複数の画像が生成できるようになります。

:::note info
これは非常に有用なため、作者に感謝の意を伝えました。

- https://github.com/william-murray1204/stable-diffusion-cpp-python/issues/6
:::

例を示します。

```py
from stable_diffusion_cpp import StableDiffusion

stable_diffusion = StableDiffusion(
    diffusion_model_path="flux1-schnell-q3_k.gguf",
    clip_l_path="clip_l.safetensors",
    t5xxl_path="t5xxl_fp16.safetensors",
    vae_path="ae.safetensors",
)

prompts = [
    ("flux1-cat.png", "a lovely cat holding a sign says 'flux.cpp'"),
    ("flux1-dog.png", "a lovely dog holding a sign says 'flux.cpp'"),
]

for fn, prompt in prompts:
    output = stable_diffusion.txt_to_img(
        prompt=prompt,
        sample_steps=4,
        cfg_scale=1.0, # a cfg_scale of 1 is recommended for FLUX
        sample_method="euler", # euler is recommended for FLUX
    )
    output[0].save(fn)
```

<img src="https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/32057/930d1caf-9cc6-d003-10b4-35477941af32.png" width="50%"><img src="https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/32057/3636aebd-86d9-9a29-425c-ac7cb47aaa91.png" width="50%">

# 参考

https://zenn.dev/syoyo/articles/a2779def150fbb
