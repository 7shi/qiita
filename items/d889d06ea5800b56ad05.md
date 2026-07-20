---
coediting: false
comments_count: 2
created_at: '2025-01-13T19:56:20+09:00'
id: d889d06ea5800b56ad05
likes_count: 3
private: false
reactions_count: 0
stocks_count: 1
tags:
- name: Python
  versions: []
- name: retry
  versions: []
- name: Gemini
  versions: []
- name: ratelimit
  versions: []
title: Gemini で自動再試行
updated_at: '2025-05-09T22:38:13+09:00'
url: https://qiita.com/7shi/items/d889d06ea5800b56ad05
slide: false
---

Gemini の無料枠を利用していると、しばしばレート制限に引っ掛かって 429 Resource Exhausted エラーが発生します。しばらく待ってから再試行すれば解決しますが、これを自動化する API が用意されています。

更新履歴:

- 2025/03/23 google-genai では使用できないことを追記

:::note alert
本記事で説明している API は、古いライブラリである google-generativeai を対象としています。新しいライブラリである google-genai には対応していないため、自前でエラーをハンドリングする必要があります。

```py:例
try:
    return client.models.generate_content(...)
except google.genai.errors.APIError as e:
    if hasattr(e, "code") and e.code in [429, 500, 502, 503]:
        # 再試行
        ...
```

詳細は以下の記事を参照してください。
:::

https://qiita.com/7shi/items/3fb540c72ad4577350c6

# レート制限

記事執筆時点で主力となっている Gemini 2.0 Flash Experimental の無料枠のレート制限を示します。

2025 年 1 月 13 日時点

- 1 分あたりのリクエスト数: 10
- 1 日あたりのリクエスト数: 1,500

このうちよく引っ掛かるのが 1 分当たりのリクエスト数 (rpm: requests per minute) です。仕様上、1 日あたりのリクエスト数を超過していなければ、最大で 1 分程度待てば解消します。

# 自動再試行

Google の API には `Retry` デコレーターによる再試行機能が用意されています。以下のような特徴があります。

1. **指数バックオフ**：再試行の間隔が徐々に長くなります。これにより、サーバーの負荷を軽減しつつ、復旧の機会を待つことができます。

2. **ジッター**：再試行間隔にランダムな変動を加えます。多数のクライアントが同時に再試行することを防ぎます。

3. **再試行可能なエラー**：すべてのエラーに対して再試行するわけではありません。一時的なエラー（レート制限やネットワークエラーなど）の場合のみ再試行します。

再試行可能なエラーは以下の通りです。

- https://github.com/googleapis/python-api-core/blob/1ca7973a395099403be1a99c7c4583a8f22d5d8e/google/api_core/retry/retry_base.py#L83

```py
"""A predicate that checks if an exception is a transient API error.

The following server errors are considered transient:

- :class:`google.api_core.exceptions.InternalServerError` - HTTP 500, gRPC
    ``INTERNAL(13)`` and its subclasses.
- :class:`google.api_core.exceptions.TooManyRequests` - HTTP 429
- :class:`google.api_core.exceptions.ServiceUnavailable` - HTTP 503
- :class:`requests.exceptions.ConnectionError`
- :class:`requests.exceptions.ChunkedEncodingError` - The server declared
    chunked encoding but sent an invalid chunk.
- :class:`google.auth.exceptions.TransportError` - Used to indicate an
    error occurred during an HTTP request.
"""
```

リクエストを処理する関数に `Retry` デコレーターを付ければ、その関数が自動的に再試行されます。

```sh:追加ライブラリ
pip install google-api-core
```

```python:例
from google.api_core import retry

@retry.Retry()
def generate_content(model, *args, **kwargs):
    return model.generate_content(*args, **kwargs)
```

この例では、`model.generate_content(...)` の代わりに `generate_content(model, ...)` を呼ぶことで、失敗時に再試行が行われます。

【出典】 https://github.com/google-gemini/generative-ai-python/issues/46

:::note info
関数名は `generate_text` から `generate_content` に書き換えました。また、リンクされている text_calculator は認証が求められますが、以下で閲覧できるノートブックと同一だと思われます。

- https://github.com/google/generative-ai-docs/blob/main/site/en/examples/text_calculator.ipynb
:::

## 動作確認

どのような間隔で再試行するのかを確認するため、意図的に 429 エラーを発生させるコードを試します。

```python
import logging, sys, traceback
from google.api_core import retry, exceptions

# 再試行状況を表示するための設定。これを設定しなければ何も表示されない。
logger = logging.getLogger("google.api_core.retry")
logger.setLevel(logging.DEBUG)
logger.addHandler(logging.StreamHandler())

# `test` 関数に自動再試行を設定
@retry.Retry()
def test():
    raise exceptions.ResourceExhausted("Rate limit exceeded.")

try:
    # 間隔を置いて自動的に再試行される
    test()
except Exception as e:
    # 一定時間経過しても成功しなければ打ち切られる
    print(f"Error occurred at: {traceback.extract_tb(sys.exc_info()[2])[-1]}")
    print(e)
```

待機時間はランダム化されているため、実行結果は毎回異なります。デフォルトでは 1 秒前後から始めて間隔を徐々に伸ばし、一定時間内に正常終了しなければ打ち切ってエラーとなります。

```text:ログ 1
Retrying due to 429 Rate limit exceeded., sleeping 0.9s ...
Retrying due to 429 Rate limit exceeded., sleeping 0.2s ...
Retrying due to 429 Rate limit exceeded., sleeping 1.7s ...
Retrying due to 429 Rate limit exceeded., sleeping 1.6s ...
Retrying due to 429 Rate limit exceeded., sleeping 3.0s ...
Retrying due to 429 Rate limit exceeded., sleeping 10.4s ...
Retrying due to 429 Rate limit exceeded., sleeping 35.7s ...
Retrying due to 429 Rate limit exceeded., sleeping 13.9s ...
Error occurred at: <FrameSummary file /test/.venv/lib/python3.12/site-packages/google/api_core/retry/retry_base.py, line 221 in _retry_error_helper>
Timeout of 120.0s exceeded, last exception: 429 Rate limit exceeded.
```

```text:ログ 2
Retrying due to 429 Rate limit exceeded., sleeping 0.5s ...
Retrying due to 429 Rate limit exceeded., sleeping 0.9s ...
Retrying due to 429 Rate limit exceeded., sleeping 3.6s ...
Retrying due to 429 Rate limit exceeded., sleeping 6.8s ...
Retrying due to 429 Rate limit exceeded., sleeping 15.7s ...
Retrying due to 429 Rate limit exceeded., sleeping 17.9s ...
Retrying due to 429 Rate limit exceeded., sleeping 58.8s ...
Error occurred at: <FrameSummary file /test/.venv/lib/python3.12/site-packages/google/api_core/retry/retry_base.py, line 221 in _retry_error_helper>
Timeout of 120.0s exceeded, last exception: 429 Rate limit exceeded.
```

実行ごとに待機時間が異なります。これは「ジッター」と呼ばれるランダムな変動が加えられているためです。

## タイムアウト

ログの最後で、タイムアウトが 120 秒と表示されています。

```text
Timeout of 120.0s exceeded, (略)
```

これはデフォルト値で、その時間を超えないように打ち切るアルゴリズムとなっています。具体的には、ログには表示されませんが次の待機時間 `sleep` が用意されており、それを経過時間に足して 120 秒を超えるなら打ち切られます。

- https://github.com/googleapis/python-api-core/blob/main/google/api_core/retry/retry_unary.py#L139

```python
    timeout = kwargs.get("deadline", timeout)

    deadline = time.monotonic() + timeout if timeout is not None else None
    error_list: list[Exception] = []

    for sleep in sleep_generator:
        try:
            result = target()
            if inspect.isawaitable(result):
                warnings.warn(_ASYNC_RETRY_WARNING)
            return result

        # pylint: disable=broad-except
        # This function explicitly must deal with broad exceptions.
        except Exception as exc:
            # defer to shared logic for handling errors
            _retry_error_helper(
                (略)
            )
            # if exception not raised, sleep before next attempt
            time.sleep(sleep)
```

## 再試行設定のカスタマイズ

https://googleapis.dev/python/google-api-core/latest/retry.html

`@retry.Retry`デコレータには、以下のようなオプションがあります。イコールの右辺は初期値です。

- `initial=1.0`：最初の再試行までの待機時間（秒）
- `maximum=60.0`：最大の待機時間（秒）
- `multiplier=2.0`：待機時間を増やす倍率
- `timeout=120.0`：再試行を続ける最大時間（秒）

例として `initial=10` に変更してみます。

```python:変更箇所
@retry.Retry(initial=10)
```
```text:ログ 3
Retrying due to 429 Rate limit exceeded., sleeping 6.0s ...
Retrying due to 429 Rate limit exceeded., sleeping 15.3s ...
Retrying due to 429 Rate limit exceeded., sleeping 15.3s ...
Retrying due to 429 Rate limit exceeded., sleeping 54.7s ...
Error occurred at: <FrameSummary file /test/.venv/lib/python3.12/site-packages/google/api_core/retry/retry_base.py, line 221 in _retry_error_helper>
Timeout of 120.0s exceeded, last exception: 429 Rate limit exceeded.
```

ジッターが加えられるため指定した秒数で始まるわけではありませんが、デフォルトよりも最初の待機時間が増えていることが確認できました。

# まとめ

再試行処理は、無料枠で Gemini を利用する上で重要な機能です。`Retry` デコレーターを使用することで、効率的な再試行処理が実装できます。適切な設定とエラーハンドリングにより、アプリケーションの安定性を向上させることができるでしょう。

# 参考

https://ai.google.dev/gemini-api/docs/troubleshooting?hl=ja&lang=python

<blockquote><table><tr>
<td>ResourceExhausted</td>
<td>google.api_core.exceptions.ResourceExhausted</td>
<td>割り当てが使い切れました。しばらくしてからもう一度お試しください。このようなエラーに対処するには、<a href="https://googleapis.dev/python/google-api-core/latest/retry.html">自動再試行</a>の設定を検討してください。</td>
</tr></table></blockquote>

# 関連記事

無料枠の提供当初からリミット制限はありました。

https://qiita.com/7shi/items/54e45181052c914a4d45

Google AI Studio の API Key で使用できる LLM の種類です。

https://qiita.com/7shi/items/ac3c2b1bea3bb4e9eb70
