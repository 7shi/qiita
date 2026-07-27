---
coediting: false
comments_count: 0
created_at: '2024-12-18T17:01:44+09:00'
id: 24eb2b2b9e6149cb1d54
likes_count: 2
private: false
reactions_count: 0
stocks_count: 0
tags:
- name: LLM
  versions: []
- name: BitNet
  versions: []
title: Falcon 3 の BitNet 版を試す
updated_at: '2026-04-23T05:31:50+09:00'
url: https://qiita.com/7shi/items/24eb2b2b9e6149cb1d54
slide: false
---

Falcon 3 モデルファミリーには BitNet 量子化版が含まれています。BitNet 対応モデルが待たれていた中での登場ということもあり、さっそく試してベンチマークを取りました。

https://huggingface.co/collections/tiiuae/falcon3-67605ae03578be86e4e87026

- https://huggingface.co/tiiuae/Falcon3-10B-Instruct-1.58bit
- https://huggingface.co/tiiuae/Falcon3-7B-Base-1.58bit
- https://huggingface.co/tiiuae/Falcon3-7B-Instruct-1.58bit
- https://huggingface.co/tiiuae/Falcon3-3B-Instruct-1.58bit
- https://huggingface.co/tiiuae/Falcon3-1B-Instruct-1.58bit

更新履歴:

- 2026/04/23 TL2 の動作確認に成功したため（👉[詳細](https://zenn.dev/7shi/scraps/60580be831d272)）、ベンチマーク結果に追加
- 2024/12/18 (23:30) 起動コマンドに関する問題が解決したため、記述を修正

# BitNet b1.58

BitNet は、重みを -1, 0, +1 の 3 値に制限することで、行列積の計算を大幅に簡略化しています。これにより計算は高速化され、メモリ使用量も大幅に削減されることが期待されます。

https://github.com/microsoft/BitNet

BitNet の推論エンジンには、2 種類の実装方式があります。

- **I2_S（Multiply-Add 方式）:** 実行時にテンソルのサイズに合わせて動的に計算する汎用エンジン。対応モデルは固定化されない。
- **TL2（Look-Up Table 方式）:** 対象モデルの行列サイズをコンパイル時に定数としてハードコーディングする専用エンジン。対応モデルが固定化されるため、モデルごとにビルドが必要。

詳細は以下の記事を参照してください。

https://zenn.dev/7shi/articles/20260422-bitnet-algorithm

# 動作確認

Falcon 3 サポートは以下のプルリクエストでマージされました。

https://github.com/microsoft/BitNet/pull/137

:::note info
このプルリクエストは、モデルを追加する具体例としても価値がありそうです。
:::

GitHub から最新のソースを取得して、README に従ってビルドします。

```sh
python setup_env.py --hf-repo tiiuae/Falcon3-7B-Instruct-1.58bit -q i2_s
```

その際、モデルの変換が行われますが、メインメモリは 32GB 以上が必要となります。詳細は以下の記事を参照してください。

https://qiita.com/7shi/items/a432cb83a28a74131bc7

:::note info
この記事は WSL2 とありますが、環境を限定しない内容です。
:::

~~ただしマージに伴っていくつか混乱が生じており、現時点では README の Basic usage に従っても正常動作しません。~~（解決済）

Basic usage に書かれているコマンドを実行します。

```sh
python run_inference.py -m models/Falcon3-7B-Instruct-1.58bit/ggml-model-i2_s.gguf -p "You are a helpful assistant" -cnv
```

起動して会話モードになります。終了は [Ctrl]+[C] です。

```text
== Running in interactive mode. ==
 - Press Ctrl+C to interject at any time.
 - Press Return to return control to the AI.
 - To return control without starting a new line, end your input with '/'.
 - If you want to submit another line, end your input with '\'.

<|system|>
You are a helpful assistant

> こんにちは
こんにちは！どのようにお手伝いできますか？

> あなたの名前は？
私の名前は助言です。どのようにお手伝いできますか？

> AIについて教えてください。

>
AIは、計算機が人間の知識や判断を継承することできるサイズだという、人間に近いものです。AIは、データを受け入れ、自動的に調整 されるアルゴリズムを持ち、特定の任務を解決する能力を有するものです。

AIは以
>
下のような設計があります。

1. **データ構造化（Data Structuring）**: AIはデータを有する組み合わせた形式で記録され、それらを認識し、説明する能力を持つことができます。

2. **自動的調整機
>
llama_perf_sampler_print:    sampling time =       8.92 ms /   128 runs   (    0.07 ms per token, 14356.21 tokens per second)
llama_perf_context_print:        load time =     879.51 ms
llama_perf_context_print: prompt eval time =   13078.77 ms /    89 tokens (  146.95 ms per token,     6.80 tokens per second)
llama_perf_context_print:        eval time =   33109.90 ms /   320 runs   (  103.47 ms per token,     9.66 tokens per second)
llama_perf_context_print:       total time =  114258.90 ms /   409 tokens
Interrupted by user
Ctrl+C pressed, exiting...
```

:::note info
返事が返って来なかったり、途中で切れたときは、何も入力せずに [Enter] とすれば続行します。
:::

# ベンチマーク

測定環境

- OS: Windows 11 Home [10.0.26100.2605]
- CPU: AMD Ryzen 5 5600X 6-Core Processor (3.70GHz)
- RAM: DDR4-3200 64GB

BitNet が利用する llama.cpp にはベンチマークコマンド `llama-bench` があります。pp512 は 512 トークンのプロンプトを処理  (Prompt Processing) する速度、tg128 は 128 トークンを生成 (Token Generation) する速度を測定します。

比較のため以下から取得した Q4_K_M と並べた結果を貼ります。

https://huggingface.co/bartowski/Falcon3-3B-Instruct-GGUF

| model               |        size |     params | pp512 (t/s)    | tg128 (t/s)   |
| ------------------- | ----------: | ---------: | -------------: | ------------: |
| Falcon 3 10B I2_S   |    3.71 GiB |    10.31 B |  41.88 ± 1.11 |  12.32 ± 0.02 |
| Falcon 3 10B TL2    |    3.37 GiB |    10.31 B |  15.88 ± 0.24 |  12.64 ± 0.05 |
| Falcon 3 10B Q4_K_M |    5.85 GiB |    10.31 B |  14.72 ± 0.25 |   6.57 ± 0.01 |
| Falcon 3 7B I2_S    |    3.05 GiB |     7.46 B |  59.76 ± 0.71 |  15.95 ± 0.03 |
| Falcon 3 7B TL2     |    2.81 GiB |     7.46 B |  24.72 ± 0.41 |  16.35 ± 0.10 |
| Falcon 3 7B Q4_K_M  |    4.25 GiB |     7.46 B |  20.70 ± 0.37 |   9.19 ± 0.01 |
| Falcon 3 3B I2_S    |    2.06 GiB |     3.23 B | 152.32 ± 4.33 |  27.66 ± 0.07 |
| Falcon 3 3B TL2     |    1.98 GiB |     3.23 B |  60.88 ± 2.64 |  28.07 ± 0.25 |
| Falcon 3 3B Q4_K_M  |    1.86 GiB |     3.23 B |  55.37 ± 2.65 |  21.83 ± 0.11 |
| Falcon 3 1B I2_S    |    1.26 GiB |     1.67 B | 306.47 ± 3.65 |  47.37 ± 0.21 |
| Falcon 3 1B TL2     |    1.22 GiB |     1.67 B | 130.19 ± 6.19 |  47.23 ± 0.49 |
| Falcon 3 1B Q4_K_M  |    0.98 GiB |     1.67 B | 115.84 ± 1.89 |  40.44 ± 1.41 |

（BitNet ビルド `1f86f058` CPU 6 スレッド）

## ベンチマーク結果の分析

### I2_S vs TL2

pp512 においては、I2_S が TL2 の約 2.4〜2.6 倍の速度でプロンプトを処理できています。これは I2_S で採用されている「Weight & Activation Parallelism」などの最適化が効果的に機能した結果だと考えられます。

一方、tg128 においては TL2 と I2_S はほぼ横並びで（TL2 がわずかに速い場合もあり）、LUT 方式のキャッシュ効率の良さと I2_S の並列化最適化が互角の戦いをしている状態と言えます。

TL2 はモデルごとにコード生成とビルドが必要という手間を考えると、実用上は I2_S を選択するのが無難だと言えます。

### I2_S vs Q4_K_M

プロンプト評価速度（pp512）においては、I2_S は Q4_K_M 比で約 2.7〜2.9 倍の高速化を達成しました。しかし、ユーザー体験により直接的な影響を与えるのは、テキスト生成時の速度です。

テキスト生成速度（tg128）の測定結果では、モデルサイズによって異なる傾向が見られました。10B モデルでは、I2_S が 12.32 tps、Q4_K_M が 6.57 tps という結果となり、約 1.88 倍の速度向上を達成しています。一方、3B モデルでは 1.27 倍、1B モデルでは 1.17 倍と、モデルサイズが小さくなるにつれて速度向上の効果は限定的になっています。

## 実用面での課題

10B クラスのモデルでは、速度向上の恩恵が比較的大きく、精度低下の影響も小型モデルほどではないと考えられるため、条件付きで実用できる可能性があります。

一方、7B 以下のモデルでは、既存の Q4_K_M 量子化で十分な性能が得られており、速度向上が限定的である上に精度低下のデメリットが大きいため、実用性には疑問が残ります。

内積計算の最適化によって期待されるほどの速度が出ているとは言い難い気はします。逆に言えば Q4_K_M がかなり頑張っているとも言えそうです。

# まとめ

今まで BitNet はテスト的なモデルしか動いていませんでしたが、ようやく実用的なモデルが対応したので、改めて試してみるには良いと思います。
