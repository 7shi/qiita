---
coediting: false
comments_count: 0
created_at: '2025-04-12T17:36:39+09:00'
id: 3fb540c72ad4577350c6
likes_count: 6
private: false
reactions_count: 0
stocks_count: 1
tags:
- name: retry
  versions: []
- name: Gemini
  versions: []
- name: errorhandling
  versions: []
- name: GenAI
  versions: []
title: Google Gen AI SDK 利用時のエラーハンドリングと再試行
updated_at: '2025-10-28T11:21:58+09:00'
url: https://qiita.com/7shi/items/3fb540c72ad4577350c6
slide: false
---

Google Gen AI SDK (google-genai) を利用して生成 AI にアクセスする際、ネットワークやサーバー側の都合で一時的なエラーが発生することがあります。アプリケーションの安定性を高めるためには、これらのエラーを適切に処理し、必要に応じてリトライするメカニズムを実装することが重要です。

この記事では、google-genai ライブラリでよく発生する一時的なエラーの種類とその対処法、特にリトライの実装について解説します。

# よく遭遇する一時的なエラー

生成リクエスト (`generate_content`) を実行した際、以下のような HTTP ステータスコードを持つエラーが返されることがあります。

* **429 (Resource Exhausted):** API のレート制限に達した場合に発生します。これは 1 分あたり、または 1 日あたりのリクエスト数制限のいずれかが原因である可能性があります。分単位の制限であれば、しばらく待つことで解消されます。
* **500 (Internal Server Error):** Google 側のサーバー内部で予期せぬ問題が発生した場合に返されます。通常は一時的なものです。
* **502 (Bad Gateway):** Google 側のサーバー内部でバックエンドサービスとの通信に問題がある場合に返されます。多くの場合、一時的な問題のため、30 秒待ってから再試行するようにエラーで指示されることがあります。
* **503 (Service Unavailable):** Google 側のサーバーが過負荷状態などの理由でリクエストを処理できない場合に返されます。これも通常は一時的な問題です。

これらのエラー（429 の日単位制限を除く）は、多くの場合、少し時間を置いてからリクエストを再試行することで成功する可能性があります。

# google-genai のエラークラス階層

google-genai ライブラリでは、API からのエラーは主に以下の 2 つの例外クラスで表現されます。

* `google.genai.errors.ClientError`: 4xx 系のクライアントエラー（例: 429 Rate Limit Exceeded / 400 Invalid Argument）
* `google.genai.errors.ServerError`: 5xx 系のサーバーエラー（例: 500 Internal Server Error / 502 Bad Gateway / 503 Service Unavailable）

これらのクラスの継承関係を MRO (Method Resolution Order) で確認してみましょう。

```python
>>> import google.genai
>>> google.genai.errors.ClientError.mro()
[<class 'google.genai.errors.ClientError'>, <class 'google.genai.errors.APIError'>, <class 'Exception'>, <class 'BaseException'>, <class 'object'>]
>>> google.genai.errors.ServerError.mro()
[<class 'google.genai.errors.ServerError'>, <class 'google.genai.errors.APIError'>, <class 'Exception'>, <class 'BaseException'>, <class 'object'>]
```

どちらのクラスも `google.genai.errors.APIError` を継承していることがわかります。したがって、これらの API 関連エラーをまとめて捕捉したい場合は、`APIError` を `except` 節で指定するのが便利です。

# エラーの捕捉とリトライの基本形

`try ... except` ブロックを使って `APIError` を捕捉し、エラーコード `e.code` を確認してリトライ可能なエラーかどうかを判断する基本的なコードは以下のようになります。

```python
try:
    return client.models.generate_content(...)
except google.genai.errors.APIError as e:
    if hasattr(e, "code") and e.code in [429, 500, 502, 503]:
        # 再試行
        ...
```

:::note info
上記コードは説明のために `generate_content` の引数や再試行の実装を省略 (`...`) しています。
:::

## 429 エラーの詳細

特に 429 (Resource Exhausted) エラーの場合、API レスポンスにはリトライに関する追加情報が含まれていることがあります。

以下は429エラーが発生した際の `e` の例です。

```python
>>> e
ClientError("429 RESOURCE_EXHAUSTED. {'error': {'code': 429, 'message': 'You exceeded your current quota, please check your plan and billing details. For more information on this error, head to: https://ai.google.dev/gemini-api/docs/rate-limits.', 'status': 'RESOURCE_EXHAUSTED', 'details': [{'@type': 'type.googleapis.com/google.rpc.QuotaFailure', 'violations': [{'quotaMetric': 'generativelanguage.googleapis.com/generate_content_free_tier_requests', 'quotaId': 'GenerateRequestsPerDayPerProjectPerModel-FreeTier', 'quotaDimensions': {'location': 'global', 'model': 'gemini-2.0-pro-exp'}, 'quotaValue': '25'}]}, {'@type': 'type.googleapis.com/google.rpc.Help', 'links': [{'description': 'Learn more about Gemini API quotas', 'url': 'https://ai.google.dev/gemini-api/docs/rate-limits'}]}, {'@type': 'type.googleapis.com/google.rpc.RetryInfo', 'retryDelay': '18s'}]}}")
```

エラーオブジェクト `e` の `details` 属性は `dict` 型のデータを含んでおり、これを整形して表示すると内容を把握しやすくなります。

```python
>>> import json
>>> print(json.dumps(e.details, indent=2))
{
  "error": {
    "code": 429,
    "message": "You exceeded your current quota, please check your plan and billing details. For more information on this error, head to: https://ai.google.dev/gemini-api/docs/rate-limits.",
    "status": "RESOURCE_EXHAUSTED",
    "details": [
      {
        "@type": "type.googleapis.com/google.rpc.QuotaFailure",
        "violations": [
          {
            "quotaMetric": "generativelanguage.googleapis.com/generate_content_free_tier_requests",
            "quotaId": "GenerateRequestsPerDayPerProjectPerModel-FreeTier",
            "quotaDimensions": {
              "location": "global",
              "model": "gemini-2.0-pro-exp"
            },
            "quotaValue": "25"
          }
        ]
      },
      {
        "@type": "type.googleapis.com/google.rpc.Help",
        "links": [
          {
            "description": "Learn more about Gemini API quotas",
            "url": "https://ai.google.dev/gemini-api/docs/rate-limits"
          }
        ]
      },
      {
        "@type": "type.googleapis.com/google.rpc.RetryInfo",
        "retryDelay": "18s"
      }
    ]
  }
}
```

注目すべきは `retryDelay` フィールドです。これは、API が推奨するリトライまでの待機時間を示しています。（この例では 18 秒）

この `retryDelay` を抽出するには、以下のようにアクセスできます。

```python
# インデックス決め打ちの場合（構造が変わるとエラーになる可能性）
>>> e.details["error"]["details"][2]["retryDelay"]
'18s'

# より安全な方法（リスト内包表記で retryDelay を持つ要素を探す）
>>> [rd for d in e.details["error"]["details"] if (rd := d.get("retryDelay"))]
['18s']
# 結果はリストで返るので、必要に応じて最初の要素を取り出す
```

1 分あたりのレート制限に達した場合、この `retryDelay` の秒数だけ待機すれば、次のリクエストが成功する可能性が高まります。

## リトライ処理の実装例

これらの知見を元に、API が推奨する `retryDelay` を考慮したリトライ処理を実装した例を示します。500 番台エラーの場合は、固定の待機時間（ここでは 30 秒）を設けています。

```python
for i in range(5, 0, -1):
    try:
        response = client.models.generate_content(...)
    except google.genai.errors.APIError as e:
        if hasattr(e, "code") and e.code in [429, 500, 502, 503]:
            print(e, file=sys.stderr)
            if i > 1:
                delay = 30
                if e.code == 429:
                    details = e.details["error"]["details"]
                    for d in details:
                        if (rd := d.get("retryDelay")) and (m := re.match(r"^(\d+)s$", rd)):
                            delay = int(m.group(1)) or delay
                            break
                for j in range(delay, -1, -1):
                    print(f"\rRetrying... {j}s ", end="", file=sys.stderr, flush=True)
                    if j:
                        time.sleep(1)
                print(file=sys.stderr)
        else:
            raise
raise RuntimeError("Max retries exceeded.")
```

## その他のエラー例

リトライでは解決しないエラーもあります。例えば、リクエストの内容自体に問題がある場合です。以下は、リクエストに含まれる画像の枚数が多すぎる（3600 枚を超えた）場合に発生する `400 Invalid Argument` エラーの例です。

```python:エラー（整形済）
google.genai.errors.ClientError: 400 INVALID_ARGUMENT.
{
  'error': {
    'code': 400,
    'message': 'Please use fewer than 3600 images in your request to models/gemini-2.5-pro-exp-03-25',
    'status': 'INVALID_ARGUMENT'
  }
}
```

この種のエラーは、サーバーの一時的な問題ではなく、リクエストのパラメータ（この場合は画像の枚数）を修正する必要があります。エラーメッセージをよく読み、原因を特定して対処しましょう。

:::note info
画像を 3600 枚以上渡すというのは普通では考えられない状況ですが、Gen AI には YouTube 動画を 1 秒ごとに 1 枚の画像に変換する機能があり、それによって 1 時間以上の動画を渡そうとしたときのエラーです。
:::

# まとめ

Google Gen AI SDK を利用する際には、429/500/502/503 といった一時的なエラーが発生する可能性を考慮し、適切なリトライ処理を実装することが堅牢なアプリケーションを構築する上で不可欠です。

`google.genai.errors.APIError` を捕捉し、エラーコードを確認することで、リトライすべきエラーかどうかを判断できます。特に 429 エラーの場合は、`e.details` に含まれる `retryDelay` 情報を活用することで、より効率的なリトライ戦略をとることが可能です。

一方で、400 エラーのようにリクエスト内容に起因する問題はリトライでは解決しないため、エラーメッセージに基づいた修正が必要になります。状況に応じた適切なエラーハンドリングを行いましょう。

# 関連記事

本記事は、Gemini による YouTube 動画解析で得られた知見をまとめたものです。

https://qiita.com/7shi/items/7578f1710e76770f1af1

画像生成の記事で利用しています。

https://qiita.com/7shi/items/d1371b923bba9a78820e

古い google-generativeai ライブラリでは、再試行を自動化するデコレーターが提供されていました。（google-genai には未対応）

https://qiita.com/7shi/items/d889d06ea5800b56ad05

古い google-generativeai ライブラリから新しい google-genai ライブラリへの移行を扱った記事です。

https://qiita.com/7shi/items/06ed3e922630fcbd7734

Gemini 1.0 Pro 公開当時の状況を扱った古い記事です。

https://qiita.com/7shi/items/54e45181052c914a4d45
