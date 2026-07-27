---
coediting: false
comments_count: 0
created_at: '2024-11-12T22:04:04+09:00'
id: dc037c2d5b0add0da33a
likes_count: 20
private: false
reactions_count: 0
stocks_count: 21
tags:
- name: Windows
  versions: []
- name: radeon
  versions: []
- name: ROCm
  versions: []
- name: ollama
  versions: []
title: Windows/Radeon での Ollama のサポート状況
updated_at: '2025-10-19T11:11:04+09:00'
url: https://qiita.com/7shi/items/dc037c2d5b0add0da33a
slide: false
---

Ollama は Windows での Radeon GPU をサポートしていますが、ドライバのリビジョンによっては不具合があります。日本語情報が見当たらないため、メモを残しておきます。

更新履歴

- 2025/10/18 Ryzen AI Max+ 395 との比較を追記
- 2024/11/25 GeForce RTX 4060 Ti や Radeon 780M との比較を追記

# 概要

Ollama はローカルで LLM を動かすためのマルチプラットフォーム対応アプリケーションです。

https://ollama.com/

Windows 用に配布されているバイナリでは、NVIDIA だけでなく AMD の GPU もサポートされています。

https://ollama.com/blog/amd-preview

AMD 公式で提供されている HIP SDK でサポートされている GPU で動きます。

https://rocm.docs.amd.com/projects/install-on-windows/en/latest/reference/system-requirements.html

:::note alert
未対応の GPU は動作保証がないだけでなく、そもそも認識しません。
:::

:::note info
APU 内蔵 GPU (iGPU) は対象外です。（Strix Halo を除く）

ただし、iGPU の Radeon 780M には非公式パッチが存在します。（無保証）

- https://github.com/likelovewant/ROCmLibs-for-gfx1103-AMD780M-APU

本記事の最後に動作速度の比較を掲載しています。
:::

# ドライバ

一部のリビジョンのドライバには不具合があります。Adrenalin 24.12.1 以降の最新ドライバをご利用ください。

- [Drivers and Support for Processors and Graphics](https://www.amd.com/en/support/download/drivers.html)

:::note alert
Adrenalin 24.9.1 と 24.10.1 には既知の不具合があります。

- https://github.com/ollama/ollama/issues/7107

具体的には、`hipMalloc()` で 4GB 以上のメモリを確保しようとすると共有 GPU メモリに割り当てられてしまい、動作速度が 1/10 以下になります。

- https://github.com/ROCm/HIP/issues/3644
:::

<!--ドライバのインストール後、HIP SDK 6.1.2 をインストールしてください。

- [AMD HIP SDK for Windows](https://www.amd.com/ja/developer/resources/rocm-hub/hip-sdk.html)

インストールされていれば、特に設定しなくても Ollama は自動的に認識します。-->

# 動作速度

参考までに、以下の環境での CPU と GPU での動作速度を比較します。

- OS: Windows 11 [10.0.22631]
- RAM: 32GB
- CPU: AMD Ryzen 5 5600X 6-Core Processor
- GPU: AMD Radeon RX 7600 XT (VRAM 16GB)

:::note info
ベンチマーク上、Radeon RX 7600 XT は GeForce RTX 3060 とほぼ同性能のようです。

- [GeForce RTX 4090対AMD Radeon RX 7900 XTX](https://technical.city/ja/video/GeForce-RTX-4090-vs-Radeon-RX-7900-XTX)
:::

- LLM: gemma2:27b-instruct-*
- Prompt: `AIの未来を予測してください。`
- 計測対象: eval rate (tps)

量子化|CPU|GPU
----|---:|---:
Q4_K_S|2.40|7.94
Q4_K_M|2.27|6.87
IQ3_S|1.41|10.97

:::note info
表中の数字は tps（tokens per second: 1 秒間のトークン生成数）で、数字が大きいほど高速です。Ollama で `/set verbose` とすれば取得できます。
:::

速度だけに注目すれば、CPU では Q4_K_S、GPU では IQ3_S が良さそうです。

:::note warn
IQ3_S は計算量が多いため CPU では遅くなりますが、GPU では VRAM 使用量が約 14.5GB で 16GB 以内に収まるため高速に動きます。Q4_K_S/M は VRAM 16GB に収まらないため遅くなります。
:::

:::note info
Q4_K_S/M は Ollama 公式で提供されています。

```sh
ollama run gemma2:27b-instruct-q4_K_S
ollama run gemma2:27b-instruct-q4_K_M
```

IQ3_S は以下で公開されている GGUF を使用しました。

- https://huggingface.co/grapevine-AI/gemma-2-27b-it-gguf

```sh
ollama run hf.co/grapevine-AI/gemma-2-27b-it-gguf:IQ3_S
```
:::

量子化の種別については以下の記事を参照してください。横軸がサイズ、縦軸がエラー率です。Q4_K_M のバランスが良いため標準的に使われていますが、メモリに収まらないときは iMatrix 系列 (IQ*) でギリギリの線を狙うことになります。

https://sc-bakushu.hatenablog.com/entry/2024/02/26/062547

https://zenn.dev/bilzard/articles/summary-of-quants-type-in-gguf

:::note info
S/M/L というのは服やドリンクのサイズと同じ意味です。XL はありませんが、XS や XXS があります。
:::

<details><summary>生成例</summary>
> AIの未来を予測してください。

AIの未来は、非常にエキサイティングで、同時に複雑なものになると私は考えています。

**ポジティブな側面:**

* **様々な分野でのイノベーション加速:** AIは、医療、教育、科学技術など、あらゆる分野で画期的な進歩をもたらす可能性があります。病気の診断や治療、個別最適化された学習、新たな材料の発見など、人間の能力を拡張し、社会全体の課題解決に貢献するでしょう。
* **生産性向上と効率化:** 自動化技術の進化により、単純作業から複雑なデータ分析まで、多くのタスクがAIによって効率的に処理されるようになります。これにより、人々はより創造的な仕事や人間関係に時間を使うことができ、生活の質が向上すると期待されます。
* **パーソナライズされたサービス:** AIは個々のニーズに合わせてカスタマイズされた製品やサービスを提供できるようになり、人々の生活をより便利で快適にするでしょう。

**懸念される側面:**

* **雇用への影響:** 自動化によって、多くの仕事がAIに置き換えられる可能性があります。新たな雇用の創出も期待されますが、社会全体の雇用構造の変化は、経済や社会不安をもたらす可能性もあります。
* **倫理的な問題:** AIの意思決定の透明性や公平性、プライバシー保護など、倫理的な課題も浮上しています。AIの開発と利用において、人間の価値観を尊重し、責任ある開発が不可欠です。
* **悪用リスク:** AI技術は、兵器開発や監視社会の実現など、悪用に利用される可能性もあります。国際的な協力体制を構築し、AIの倫理的な使用に関するルール作りが必要です。

**結論:**

AIは大きな可能性を秘めていますが、同時に多くの課題も抱えています。AIの未来をより良いものにするためには、技術開発だけでなく、社会的な議論や制度設計も重要です。

私は、人間とAIが協力し、互いに補完することで、より明るい未来を創造できると信じています。
</details>

## GeForce や iGPU との比較

@A-Uta さんのご協力でパフォーマンス調査を行いました。

- https://x.com/UtaAoya/status/1860257074376245476

環境|詳細|備考
----|----|----
4060Ti|NVIDIA GeForce RTX 4060 Ti|VRAM 16GB
8060S|AMD Radeon 8060S|iGPU, UMA LPDDR5x-8000 64GB
7600XT|AMD Radeon RX 7600 XT|VRAM 16GB
395|AMD Ryzen AI Max+ 395|APU 16-Core 3.00GHz, LPDDR5x-8000 64GB
780M|AMD Radeon 780M|iGPU, UMA LPDDR5-6400 4+14GB
7840HS|AMD Ryzen 7 7840HS|APU 8-Core 3.80GHz, LPDDR5-6400 32GB
5600X|AMD Ryzen 5 5600X|CPU 6-Core 3.70GHz, DDR4-3200 32GB

- Prompt: `AIの未来を予測してください。（100字）`
- 計測対象: eval rate (tps)

モデル|4060Ti|8060S|7600XT|395|780M|7840HS|5600X
----|---:|---:|---:|---:|---:|---:|---:
Gemma 2 2B<br>(Q4_K_M)| 98.82 | 88.78 | 74.34 | 33.13 | 32.98 | 22.56 | 20.86
Gemma 2 9B<br>(Q4_K_M)| 37.96 | 29.74 | 29.32 | 10.60 |  9.20 |  7.46 |  6.73
Gemma 2 27B<br>(IQ3_S)| 19.77 | 12.15 | 10.59 |  3.20 |  2.85 |  2.53 |  1.78

:::note warn
GeForce を WSL2 からパススルーで使用すると、2B の速度がダウンするようです。

- https://x.com/UtaAoya/status/1861027053090570316
:::

モデル|コマンド
----|----
Gemma 2 2B (Q4_K_M)|`ollama run gemma2:2b-instruct-q4_K_M`
Gemma 2 9B (Q4_K_M)|`ollama run gemma2:9b-instruct-q4_K_M`
Gemma 2 27B (IQ3_S)|`ollama run hf.co/grapevine-AI/gemma-2-27b-it-gguf:IQ3_S`

# 関連記事

Intel Arc A770 との比較があります。

https://7shi.hateblo.jp/entry/2024/12/17/020636

ROCm の開発版で PyTorch を試す記事です。

https://qiita.com/7shi/items/6a68a49629c463bc90f7

AMD Ryzen AI Max+ 395 の CPU/GPU/NPU を測定・比較した記事です。

https://zenn.dev/7shi/articles/20251017-amd-llm
