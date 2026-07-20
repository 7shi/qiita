---
coediting: false
comments_count: 0
created_at: '2024-11-12T04:10:41+09:00'
id: a432cb83a28a74131bc7
likes_count: 2
private: false
reactions_count: 0
stocks_count: 2
tags:
- name: WSL2
  versions: []
- name: BitNet
  versions: []
title: WSL2 での BitNet のハマり所
updated_at: '2024-12-18T17:05:51+09:00'
url: https://qiita.com/7shi/items/a432cb83a28a74131bc7
slide: false
---

WSL2 で BitNet を試したらハマりました。調査の結果、WSL2 特有とは言えない問題で、他の環境でも発生する可能性があります。参考のためメモを残しておきます。

# 概要

- GGUF 変換には大量のメモリが必要
- debug ビルドのパフォーマンスは約 1/10
- Windows ネイティブと比較した WSL2 のオーバーヘッドは誤差程度

# 環境

OS: Windows 11 [10.0.22631] WSL2
CPU: AMD Ryzen 5 5600X 6-Core Processor
RAM: 32GB (WSL2: 16GB)

# BitNet

BitNet はニューラルネットワークのウェイトを -1, 0, 1 で 3 値化することで、計算量を劇的に削減する技術です。

https://qiita.com/tech-Mira/items/67dec9c5a5f025d2727a

実際に LLM を動かせる実装が公開されています。

https://github.com/microsoft/BitNet

今回はこれを対象とします。

# GGUF 変換失敗

README の手順通りに実行すると、途中で `SIGKILL` が発生して止まります。

```sh
$ python setup_env.py --hf-repo HF1BitLLM/Llama3-8B-1.58-100B-tokens -q i2_s
INFO:root:Compiling the code using CMake.
INFO:root:Downloading model HF1BitLLM/Llama3-8B-1.58-100B-tokens from HuggingFace to models/Llama3-8B-1.58-100B-tokens...
INFO:root:Converting HF model to GGUF format...
ERROR:root:Error occurred while running command: Command '['/home/7shi/llm/venv/bin/python', 'utils/convert-hf-to-gguf-bitnet.py', 'models/Llama3-8B-1.58-100B-tokens', '--outtype', 'f32']' died with <Signals.SIGKILL: 9>., check details in logs/convert_to_f32_gguf.log
```

モデルはいったん `f32` に変換してから、指定した `i2_s` で量子化します。`f32` に変換する途中で、メモリ不足になって落ちたようです。

WSL2 はデフォルトでメインメモリの半分が上限となっているため、今回の環境では 16GB となります。8B のモデルを `f32` で展開すると 8×4=32GB のメモリが必要になるため、まったく足りません。メモリ全部を WSL2 に割り当てるわけにはいかないのですが、WSL Settings で 24GB まで増やしてもダメでした。

:::note warn
昨今は量子化済みの GGUF が用意されていることが一般的になっており、8B 程度のモデルは `Q4_K_M` 量子化で 4GB 程度です。そのためメモリは 8GB くらいあれば動くという感覚でしたが、量子化しない `f32` ではまったく足りないということです。
:::

Windows ネイティブ環境でビルドすればメモリがフルに使えるため問題なく変換できました。以下から変換済みの GGUF をダウンロードすることも可能です。

https://huggingface.co/eugenehp/Llama3-8B-1.58-100B-tokens-GGUF/blob/main/ggml-model-i2_s.gguf

なお、`tl2` は `f32` を経由しないため、問題なく変換できました。

```sh
$ python setup_env.py -md models/Llama3-8B-1.58-100B-tokens -q tl2
INFO:root:Compiling the code using CMake.
INFO:root:Loading model from directory models/Llama3-8B-1.58-100B-tokens.
INFO:root:Converting HF model to GGUF format...
INFO:root:GGUF model saved at models/Llama3-8B-1.58-100B-tokens/ggml-model-tl2.gguf
```

# 遅い

モデルを別の所から持ってきて動かせるようにはなったのですが、とても遅いです。

```sh
$ python run_inference.py -m models/Llama3-8B-1.58-100B-tokens/ggml-model-i2_s.gguf -p "Daniel went back to the the the garden. Mary travelled to the kitchen. Sandra journeyed to the kitchen. Sandra went to the hallway. John went to the bedroom. Mary went back to the garden. Where is Mary?\nAnswer:" -n 6 -temp 0
register_backend: registered backend CPU (1 devices)
register_device: registered device CPU (AMD Ryzen 5 5600X 6-Core Processor)
warning: not compiled with GPU offload support, --gpu-layers option will be ignored
warning: see main README.md for information on enabling GPU BLAS support
build: 3947 (406a5036) with clang version 18.1.8 for x86_64-pc-linux-gnu (debug)
（中略）

Daniel went back to the the the garden. Mary travelled to the kitchen. Sandra journeyed to the kitchen. Sandra went to the hallway. John went to the bedroom. Mary went back to the garden. Where is Mary?
Answer: Mary is in the garden.

llama_perf_sampler_print:    sampling time =       1.25 ms /    54 runs   (    0.02 ms per token, 43338.68 tokens per second)
llama_perf_context_print:        load time =    4469.38 ms
llama_perf_context_print: prompt eval time =   37644.47 ms /    48 tokens (  784.26 ms per token,     1.28 tokens per second)
llama_perf_context_print:        eval time =    3733.29 ms /     5 runs   (  746.66 ms per token,     1.34 tokens per second)
llama_perf_context_print:       total time =   41385.42 ms /    53 tokens
```

生成速度（下から 2 行目の eval time）は 1.34tps となっていますが、これは従来の量子化で CPU 動作させるよりも遅いです。

Issue には clang が 18 以上のバージョンでないといけないというやり取りがありますが、ここでは 18.1.8 を使っています。

https://github.com/microsoft/BitNet/issues/30

調査の結果、原因は `build: 3947 ... (debug)` の部分にあるように debug ビルドになっているためだと判明しました。

```sh
build: 3947 (406a5036) with clang version 18.1.8 for x86_64-pc-linux-gnu (debug)
```

:::note alert
なぜ debug ビルドになったかは不明です。Issue のログを見てもやはり debug ビルドになっているので、原因は clang のバージョンではない可能性があります。
:::

`build` ディレクトリを削除して再度ビルドを試みると、`(debug)` の文字は消えて正常動作するようになりました。

```sh
$ rm -rf build

$ python setup_env.py -md models/Llama3-8B-1.58-100B-tokens -q tl2
INFO:root:Compiling the code using CMake.
INFO:root:Loading model from directory models/Llama3-8B-1.58-100B-tokens.
INFO:root:GGUF model already exists at models/Llama3-8B-1.58-100B-tokens/ggml-model-tl2.gguf

$ python run_inference.py -m models/Llama3-8B-1.58-100B-tokens/ggml-model-i2_s.gguf -p "Daniel went back to the the the garden. Mary travelled to the kitchen. Sandra journeyed to the kitchen. Sandra went to the hallway. John went to the bedroom. Mary went back to the garden. Where is Mary?\nAnswer:" -n 6 -temp 0
warning: not compiled with GPU offload support, --gpu-layers option will be ignored
warning: see main README.md for information on enabling GPU BLAS support
build: 3947 (406a5036) with clang version 18.1.8 for x86_64-pc-linux-gnu
（中略）

Daniel went back to the the the garden. Mary travelled to the kitchen. Sandra journeyed to the kitchen. Sandra went to the hallway. John went to the bedroom. Mary went back to the garden. Where is Mary?
Answer: Mary is in the garden.


llama_perf_sampler_print:    sampling time =       0.41 ms /    54 runs   (    0.01 ms per token, 131707.32 tokens per second)
llama_perf_context_print:        load time =    3524.20 ms
llama_perf_context_print: prompt eval time =    3934.08 ms /    48 tokens (   81.96 ms per token,    12.20 tokens per second)
llama_perf_context_print:        eval time =     415.09 ms /     5 runs   (   83.02 ms per token,    12.05 tokens per second)
llama_perf_context_print:       total time =    4351.10 ms /    53 tokens
```

1.34tps → 12.05tps と大幅にスピードアップしました。CPU のみでこの速度は画期的です。

:::note alert
ディレクトリを消して再度同じコマンドを入力しただけなのに、なぜビルド種別が変わったのかは不明です。
:::

# 速度比較

Windows ネイティブと WSL2 のベンチマーク結果を貼っておきます。

```text:Windows ネイティブ
>llama-cli
build: 3947 (406a5036) with Clang 17.0.3 for x64
（中略）

>llama-bench -m ggml-model-i2_s.gguf -m ggml-model-tl2.gguf
```

| model                          |       size |     params | backend    | threads |          test |                  t/s |
| ------------------------------ | ---------: | ---------: | ---------- | ------: | ------------: | -------------------: |
| llama 8B I2_S - 2 bpw ternary  |   3.58 GiB |     8.03 B | CPU        |       6 |         pp512 |         57.59 ± 0.40 |
| llama 8B I2_S - 2 bpw ternary  |   3.58 GiB |     8.03 B | CPU        |       6 |         tg128 |         12.06 ± 0.02 |
| llama 8B TL2                   |   3.33 GiB |     8.03 B | CPU        |       6 |         pp512 |         25.84 ± 0.11 |
| llama 8B TL2                   |   3.33 GiB |     8.03 B | CPU        |       6 |         tg128 |         12.40 ± 0.02 |

```text:WSL2
$ llama-cli
build: 3947 (406a5036) with clang version 18.1.8 for x86_64-pc-linux-gnu
（中略）

$ llama-bench -m ggml-model-i2_s.gguf -m ggml-model-tl2.gguf
```

| model                          |       size |     params | backend    | threads |          test |                  t/s |
| ------------------------------ | ---------: | ---------: | ---------- | ------: | ------------: | -------------------: |
| llama 8B I2_S - 2 bpw ternary  |   3.58 GiB |     8.03 B | CPU        |       6 |         pp512 |         57.68 ± 0.51 |
| llama 8B I2_S - 2 bpw ternary  |   3.58 GiB |     8.03 B | CPU        |       6 |         tg128 |         13.87 ± 0.03 |
| llama 8B TL2                   |   3.33 GiB |     8.03 B | CPU        |       6 |         pp512 |         25.02 ± 0.31 |
| llama 8B TL2                   |   3.33 GiB |     8.03 B | CPU        |       6 |         tg128 |         13.88 ± 0.05 |

プロンプト評価速度 (pp512) はほぼ同じで、生成速度 (tg128) は WSL2 の方がやや速いという結果になりました。

:::note info
コンパイラの違いなども影響するとは思いますが、よく言われるような WSL2 のオーバーヘッドは気にしなくても良さそうです。
:::

記事執筆時点では BitNet 対応でそれなりに動くモデルは Llama3-8B-1.58 しかありませんが、instruct モデルではなく実用性は微妙です。対応モデルが増えることを期待します。

【追記 2024/12/18】Falcon 3 が対応しました。

https://qiita.com/7shi/items/24eb2b2b9e6149cb1d54
