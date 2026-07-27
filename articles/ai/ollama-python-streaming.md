---
coediting: false
comments_count: 0
created_at: '2024-08-08T02:09:59+09:00'
id: be2ca03a654f4d26ba5f
likes_count: 15
private: false
reactions_count: 0
stocks_count: 15
tags:
- name: Python
  versions: []
- name: ollama
  versions: []
title: ollama-python のストリーム機能
updated_at: '2024-08-08T09:30:53+09:00'
url: https://qiita.com/7shi/items/be2ca03a654f4d26ba5f
slide: false
---

Ollama の公式 Python ライブラリ ollama-python を使用すれば、LLM からの応答をストリームで受け取ることができます。これにより、応答が生成されるたびに小さなチャンクで受け取ることができ、リアルタイムで処理や表示が可能になります。

https://github.com/ollama/ollama-python

# 基本的な使い方

ライブラリをインストールします。

```sh
pip install ollama
```

`ollama.chat()` 関数によりストリームモードでチャットを開始して、返されたオブジェクトを反復処理して、各チャンクにアクセスします。

```python
import ollama
stream = ollama.chat(
    model="gemma2:2b",
    messages=[{"role": "user", "content": "hi"}],
    stream=True
)
for chunk in stream:
    print(chunk["message"]["content"], end="", flush=True)
```
```text:実行結果
Hello! 👋

What can I do for you today? 🙂
```

:::note info
実行結果は毎回変わります。
:::

# チャンク

各チャンクの内容を確認します。

```py
for chunk in stream:
    print(chunk)
```
```text:出力（抜粋）
{'model': 'gemma2:2b', 'created_at': '2024-08-07T03:57:33.0365888Z', 'message': {'role': 'assistant', 'content': 'Hello'}, 'done': False}
{'model': 'gemma2:2b', 'created_at': '2024-08-07T03:57:33.2801449Z', 'message': {'role': 'assistant', 'content': '!'}, 'done': False}
（中略）
{'model': 'gemma2:2b', 'created_at': '2024-08-07T03:57:37.0774624Z', 'message': {'role': 'assistant', 'content': ''}, 'done_reason': 'stop', 'done': True, 'total_duration': 4353619900, 'load_duration': 63915300, 'prompt_eval_count': 10, 'prompt_eval_duration': 246847000, 'eval_count': 17, 'eval_duration': 4032296000}
```

チャンクを整形して示します。`created_at` は [ISO 8601](https://ja.wikipedia.org/wiki/ISO_8601) 形式です。

```python
{
    'model': 'gemma2:2b',
    'created_at': '2024-08-07T03:57:33.0365888Z',
    'message': {'role': 'assistant', 'content': 'Hello'},
    'done': False
}
```

最後のチャンクには、追加の情報が含まれます。

```python
{
    'model': 'gemma2:2b',
    'created_at': '2024-08-07T03:57:37.0774624Z',
    'message': {'role': 'assistant', 'content': ''},
    'done_reason': 'stop',
    'done': True,
    'total_duration': 4353619900,
    'load_duration': 63915300,
    'prompt_eval_count': 10,
    'prompt_eval_duration': 246847000,
    'eval_count': 17,
    'eval_duration': 4032296000
}
```

- `done_reason`: 応答が終了した理由
- `total_duration`: 全体の処理時間（ナノ秒単位）
- `load_duration`: モデルのロードにかかった時間（ナノ秒単位）
- `prompt_eval_count`: 評価されたプロンプトのトークン数
- `prompt_eval_duration`: プロンプトの評価にかかった時間（ナノ秒単位）
- `eval_count`: 生成されたトークン数
- `eval_duration`: 生成にかかった時間（ナノ秒単位）

:::note info
ナノ秒は 10 億分の 1 秒です。
:::

## パフォーマンス統計の表示

最後のチャンクから取得した情報を表示する例を示します。

```python
eval_count = last_chunk["eval_count"]
eval_duration = last_chunk["eval_duration"] / 1e9  # ナノ秒から秒に変換
tokens_per_second = eval_count / eval_duration

print(f"生成されたトークン数: {eval_count}")
print(f"生成にかかった時間: {eval_duration:.2f}秒")
print(f"トークン生成速度: {tokens_per_second:.2f}トークン/秒")
```

# まとめ

ストリーム、応答の表示、およびパフォーマンス統計の計算を組み合わせた例です。

```python
import ollama
from datetime import timedelta

def stream(model, prompt):
    stream = ollama.chat(
        model=model,
        messages=[{"role": "user", "content": prompt}],
        stream=True
    )
    for chunk in stream:
        print(chunk["message"]["content"], end="", flush=True)
    
    count = chunk["eval_count"]
    duration = chunk["eval_duration"] / 1e9
    delta = timedelta(seconds=duration)
    tps = count / duration
    print(f"[count={count}, duration={delta}, tps={tps:.2f}]")

stream("gemma2:2b", "hi")
```
```text:実行例
Hi! 👋  How can I help you today? 😊
[count=15, duration=0:00:03.439581, tps=4.36]
```

:::note info
計測は 2012 年製の第 3 世代 Core i5-3320M (2.60GHz) で行っています。
:::
