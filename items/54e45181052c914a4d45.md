---
coediting: false
comments_count: 0
created_at: '2024-01-18T14:38:18+09:00'
id: 54e45181052c914a4d45
likes_count: 1
private: false
reactions_count: 0
stocks_count: 0
tags:
- name: GeminiPro
  versions: []
title: Gemini 1.0 Pro プレビュー版の利用制限にまつわるエラーについて
updated_at: '2025-04-12T17:47:22+09:00'
url: https://qiita.com/7shi/items/54e45181052c914a4d45
slide: false
---

Gemini 1.0 Pro プレビュー版は 1 分間に 15 リクエストという制限があります。仕様が分からないとエラーが発生したときに不安なためメモしておきます。

:::note alert
この記事の内容は古いです。2025 年 4 月時点の状況は、以下の記事を参照してください。
:::

https://qiita.com/7shi/items/3fb540c72ad4577350c6

# 制限

https://ai.google.dev/pricing?hl=ja

> レート制限
> 15 RPM（1 分あたりのリクエスト数）

:::note warn
公開当初は 60 RPM でしたが制限されました。

2024 年 5 月 14 日に従量課金が始まりますが、無料枠も残ります。👉[詳細](https://qiita.com/owayo/items/8b4cb63b35b84a343054)
:::

超過すると 429 エラーが発生して拒否されます。

```text
429 Resource has been exhausted (e.g. check quota).
```

:::note warn
当初は情報が錯綜していて、制限回数内は無料で、超過分が有料になるかのような記事も散見されます。

実際にはこのエラーが発生したからと言って課金が要求されるわけではありません。間隔を空けて再試行すれば解消します。
:::

:::note info
正式公開後に課金することで制限が緩和されます。

> 360 RPM（1 分あたりのリクエスト数）
:::

# 他のエラー

サーバーが混みあっていると 500 エラーが発生するようです。

```text
500 An internal error has occurred. Please retry or report in https://developers.generativeai.google/guide/troubleshooting
```

これは回数制限とは別です。間隔を空けて再試行することになります。

:::note warn
混雑している時間帯だと間隔を空けても頻繁に発生します。経験上、30 分から 1 時間くらいはそのような状態が続くこともありました。

混雑が解消すればスムーズに処理されるようになります。
:::

# 同時クエリ

回数制限内であれば同時に複数のクエリを投げても受理されるようですが、仕様は未確認です。`generate_content_async()` のような非同期 API はそのような用途を想定しているのかもしれませんが、こちらも未確認です。

# 関連記事

安全設定に起因するエラーについては以下の記事を参照してください。

https://qiita.com/7shi/items/667e1206469b2a1a4e00
