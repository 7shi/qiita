---
coediting: false
comments_count: 0
created_at: '2024-03-05T05:43:56+09:00'
id: 65741fa8ab0a553f51be
likes_count: 24
private: false
reactions_count: 0
stocks_count: 17
tags:
- name: ollama
  versions: []
title: 別マシンの Ollama へのアクセス
updated_at: '2025-10-18T20:51:52+09:00'
url: https://qiita.com/7shi/items/65741fa8ab0a553f51be
slide: false
---

Ollama は各種 LLM をローカルで手軽に動かせます。HTTP サーバーとして実装されているため、LLM を専用マシンに分離することも簡単です。

https://ollama.com/

更新履歴

- 2025/10/18 GUI での設定方法を追記

# アクセス制限

Ollama のデフォルトでは `127.0.0.1:11434` で待ち受けされるため、ローカルからのアクセスに制限されます。

:::note info
`11434` は **llAMA** (LLAMA) ということのようです。
:::

:::note warn
WSL2 はホストとは別の IP アドレスを持っているため、Windows 側の Ollama に WSL2 から `127.0.0.1:11434` でアクセスすることはできません。
:::

# GUI

他のマシンから接続を受け付けるには、GUI の Settings から設定します。

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/32057/ac822592-c34c-47d6-96ee-c66a1e6522c4.png)

（セキュリティ環境がデフォルトであれば）Windows ファイアーウォールから確認を求められるため、許可します。

# 環境変数

:::note info
GUI で設定できるようになる以前の設定方法です。
:::

外部からのアクセスを許可するには環境変数 `OLLAMA_HOST` と `OLLAMA_ORIGINS` を設定します。👉[FAQ](https://github.com/ollama/ollama/blob/main/docs/faq.md)

```text:設定例
OLLAMA_HOST=0.0.0.0
OLLAMA_ORIGINS=192.168.0.*
```

※ `127.0.0.1` と `0.0.0.0` の違いについては以下の記事が参考になります。

https://qiita.com/amuyikam/items/0063df223aed40193ba9

# クライアント

`OLLAMA_HOST` はサーバーだけでなく、クライアントにも影響します。

`OLLAMA_HOST` が設定されていない、または自ホストが指定されている場合、`ollama` コマンドを実行すると、サーバーが起動していなければ自動的に起動します。一方、他のホストが設定されている場合は、指定されたホストに接続しようとしますが、起動していなければ失敗します。

# ライブラリ

Python からアクセスするための公式ライブラリがあります。

https://github.com/ollama/ollama-python

`OLLAMA_HOST` が設定されていれば、自動的にそちらに接続します。

```py
import ollama
ollama.generate(model="gemma2:2b", prompt="Who are you?")
```

# LangChain

汎用的な LLM ライブラリである LangChain でも Ollama はサポートされています。

https://python.langchain.com/docs/integrations/llms/ollama

ただし LangChain では OLLAMA_HOST は参照されないため、別マシンにアクセスするには `base_url` を指定する必要があります。

```python:例
from langchain_community.llms import Ollama
llm = Ollama(base_url="http://192.168.0.11:11434", model="gemma2:2b")
llm.invoke("Who are you?")
```

# 参考

ローカル LLM の構築は手間が掛かりそうなので敬遠していましたが、Ollama はあっさり動きました。型落ちのノート PC (Core i5-3320M) でも、`gemma:2b` は 5tps くらいは出るので驚きました（`gemma2:2b` も同程度）。Ollama と Gemma の組み合わせは私にとって画期的でした。

https://www.youtube.com/watch?v=6oGbsAg8x5E

https://zenn.dev/seya/articles/03399b9e3d465e
