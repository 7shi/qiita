---
coediting: false
comments_count: 0
created_at: '2023-06-22T01:34:45+09:00'
id: b2d37b00132c23858a50
likes_count: 4
private: false
reactions_count: 0
stocks_count: 4
tags:
- name: radeon
  versions: []
- name: amdgpu
  versions: []
- name: StableDiffusion
  versions: []
- name: diffusers
  versions: []
title: AMD GPU での Stable Diffusion の改善
updated_at: '2025-06-02T01:33:01+09:00'
url: https://qiita.com/7shi/items/b2d37b00132c23858a50
slide: false
---

AMD GPU で Stable Diffusion のパフォーマンスが改善されたという情報と、関連する AMD の動向を紹介します。

:::note warn
導入方法を説明しますが、対象となる GPU を所持していないため動作確認できていません。
:::

:::note info
【追記 2025/06/02】Windows 版の ROCm が自分でビルドして試せるようになりました。
:::

https://qiita.com/7shi/items/6a68a49629c463bc90f7

# 情報源

リリースノートによれば Adrenalin Edition 23.5.2 は、従来の 23.5.1 に比べて RX 7900 XTX での Stable Diffusion 1.5 のパフォーマンスが 2 倍近く向上したとのことです。

https://www.amd.com/en/support/kb/release-notes/rn-rad-win-23-5-2

> * Performance optimizations for Microsoft Olive DirectML pipeline for Stable Diffusion 1.5 on AMD Radeon RX 7900 series graphics
>     * Boost your performance by an average of 2x in Microsoft Olive Optimized DirectML Stable Diffusion 1.5 using AMD Software: Adrenalin Edition™ 23.5.2 on the AMD Radeon<sup>™️</sup> RX 7900 XTX graphics card, versus the previous software driver version 23.5.1. <sup>RS-579</sup>

日本語の記事です。

https://ascii.jp/elem/000/004/139/4139541/

> AMD Radeon RX 7000シリーズビデオカードはAIワークロードに最適化されたAIアクセラレーターを搭載。最新ドライバーを適用したAMD Radeon RX 7900 XTXビデオカードでは、Stable Diffusion 1.5（DirectMLとMicrosoft Olive最適化バージョン）にて従来ドライバー（23.5.1）と比べて平均2倍のパフォーマンスを達成できるという。

この記事からリンクされている AMD のブログに説明があります。

https://community.amd.com/t5/gaming/accelerating-ai-with-amd-radeon/ba-p/609959

> Microsoft has optimized DirectML to accelerate transformer and diffusion models, used in Stable Diffusion, so that they run even better across the Windows hardware ecosystem.  AMD is enabling the next wave of hardware accelerated AI programs using DirectML as seen in the pre-release of Olive. Step by step instructions are available on the main site, which makes it easy to install: [Olive/examples/directml/stable_diffusion at main · microsoft/Olive · GitHub](https://github.com/microsoft/Olive/tree/main/examples/directml/stable_diffusion).

DeepL による翻訳

> マイクロソフトは DirectML を最適化し、Stable Diffusion で使用されているトランスフォーマーと拡散モデルを高速化することで、Windows ハードウェア・エコシステム全体でより優れた動作を実現しました。 AMD は、Olive のプレリリースに見られるように、DirectML を使用してハードウェアアクセラレーションによる AI プログラムの次の波を可能にします。メインサイトにはステップ・バイ・ステップのインストラクションが用意されており、簡単にインストールできます: [Olive/examples/directml/stable_diffusion at main · microsoft/Olive · GitHub](https://github.com/microsoft/Olive/tree/main/examples/directml/stable_diffusion).

# Olive

Stable Diffusion のモデルを Olive によって ONNX に最適化して変換します。画像生成には diffusers の OnnxStableDiffusionPipeline から onnxruntime-directml を使用します。

:::note warn
Stable Diffusion web UI には対応していません。利用には diffusers の知識が必要となります。diffusers については[入門記事](https://qiita.com/7shi/items/b4da43f342f0fe3c189c)を参照してください。
:::

Olive は AMD GPU 専用ではなく、NVIDIA GPU への対応も行われています。記事から Olive や ONNX に言及した部分を引用します。

https://www.4gamer.net/games/999/G999905/20230524027/

> また，PyTorchモデルの最適化，およびディープラーニングモデルの相互変換を行うオープンなフレームワーク「Open Neural Network Exchange」（ONNX）の変換を行うツール「microsoft/Olive」を，MicrosoftがGitHubで公開している。今後は，MicrosoftとNVIDIAが協力してOliveを使用した最適化を進めていくそうだ。
>これにより，AIアプリケーションの開発者は，GeForce RTX GPUを搭載したワークステーションやノートPC上でモデルをカスタマイズしたり最適化したりしたうえで，それを「Microsoft Azure」のクラウドにプッシュするといったことが，より自在に行えるようになると，NVIDIAは説明している。
> ちなみに，OliveはGPUへの最適化機能もあるので，NVIDIAとの共同開発によりNVIDIA製GPUでの性能の向上も期待できるかもしれない。

## インストール

Windows 10 に Python 3.10 と Git for Windows をインストールします。

venv で環境を分離します。

https://github.com/microsoft/Olive/blob/main/examples/README.md

```text:Windows コマンドプロンプト
python -m venv olive-env
olive-env\Scripts\activate.bat
```

Alternatively として示される動作確認されたバージョンをインストールします。

https://github.com/microsoft/Olive/tree/main/examples/directml/stable_diffusion

```text
pip install olive-ai[directml]==0.2.1
git clone https://github.com/microsoft/olive --branch v0.2.1
cd olive/examples/directml/stable_diffusion
pip install -r requirements.txt
```

:::note info
ここまでは Python を使ったことがあれば特に問題ない作業です。
:::

## 変換

説明に従ってまずモデルを変換します。

```text
python stable_diffusion.py --optimize
```

残念ながら対象となる RX 7900 は所持していません。Ryzen 5 APU の内蔵 GPU（ドライバー 23.5.2 対応）で試しましたが、途中でタイムアウトが発生して止まりました。（何度やっても同様）
![DirectML-3.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/32057/dc667094-175b-04f3-47f6-73f98044db13.png)
動作対象外の環境なので止むを得ません。

# 関連情報

今回の記事に関連する AMD の動向を紹介します。

## 続報

試用レポートによれば、どんなモデルでも変換できるわけではないようです。

https://pc.watch.impress.co.jp/docs/news/1525079.html

https://g-pc.info/archives/33037/

## Microsoft

AMD とMicrosoft は AI 関連で協力関係にあります。今回のドライバーの最適化もその一環かもしれません。

https://gigazine.net/news/20230508-microsoft-amd-teaming-against-nvidia/

## ROCm

NVIDIA のフラッグシップモデルである H100 に対抗して、AMD は MI300 を発表しました。記事の中で AMD 版 CUDA とも言える ROCm について簡単に説明されています。

https://pc.watch.impress.co.jp/docs/column/ubiq/1508816.html

> 今回、AIデータセンター向けのソフトウェア開発環境「ROCm」に関する説明も行なった。ROCmに関しては既にInstinct向けに投入しており、現在はROCm 5というリリースが提供されている。このROCmは非常にざっくり言ってしまえば、AMD版CUDAであり、TensorFlowやPyTorchといったディープラーニングのフレームワークなどを活用して、AMDのCPU、GPUやFPGAなどでAIの学習や推論を行なうソフトウェアを容易に構築できる。

ROCm は長らく Linux のみの対応でしたが、ここに来て Windows 対応の噂が出ています。

https://g-pc.info/archives/31010/

## Ryzen AI

最新の Ryzen APU には Ryzen AI という AI プロセッサが搭載されます。

https://www.itmedia.co.jp/pcuser/articles/2306/15/news081.html

<blockquote>AMDの最新モバイル向けAPU（GPU統合型CPU）「Ryzen 7040シリーズ」は、エントリーモデルを除いてCPUコア／GPUコアから独立した「Ryzen AI」というAIプロセッサを備えている。</blockquote>

> Ryzen AIは「AMD XDNAアーキテクチャ」に基づく機械学習演算に特化したプロセッサである。
> 
> XDNAアーキテクチャ自体は、AMD傘下のXilinx（ザイリンクス）が開発したもので、AIエンジン（演算部）とメモリのユニットが脳の神経回路を模した「ニューラルネットワーク」で連結されていることが特徴だ。

Ryzen AI は ONNX をサポートします。

https://pc.watch.impress.co.jp/docs/news/event/1504847.html

> 今後はアプリ開発者が生成AIのアプリをWindows上で動かしたい場合には、ONNX runtimeやDirectMLに向けて作れば、AMDのRyzen AIだけでなく、IntelのMeteor Lakeに搭載されているNPU(Intel的な言い方であればVPU)、QualcommのSnapdragon AI Engine、さらにはNVIDIAのGPUなどを効率よく利用して高性能な生成AIアプリを構築することが可能になる。

ONNX がサポートされるなら、Stable Diffusion での利用も期待できます。パフォーマンスを GPU と比較できれば面白そうです。

# APU

APU はメインメモリから VRAM を割り当てるため、大量の VRAM を必要とする生成 AI に有利ではないかとして試した記事です。速度的には CPU オンリーよりは高速ですが、ハイエンド GPU には及ばないようです。

https://gigazine.net/news/20230818-apu-gpu-vram-ai/

https://g-pc.info/archives/32881/
