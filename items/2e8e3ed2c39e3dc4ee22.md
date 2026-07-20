---
coediting: false
comments_count: 0
created_at: '2024-09-14T04:07:05+09:00'
id: 2e8e3ed2c39e3dc4ee22
likes_count: 248
private: false
reactions_count: 0
stocks_count: 210
tags:
- name: cursor
  versions: []
- name: Gemini
  versions: []
- name: cline
  versions: []
title: Cursor の無料版を使い続ける場合の設定
updated_at: '2026-06-04T10:24:51+09:00'
url: https://qiita.com/7shi/items/2e8e3ed2c39e3dc4ee22
slide: false
---

Cursor の Pro 版でサポートされる AI 機能は非常に強力であり、無料版と比較して多くのメリットがあります。しかし、個人開発者や学生など予算に限りがある人にとっては、Pro 版の利用は難しい場合があります。

本記事では、無料で利用できる Gemini, Cline, Cody を設定することで、Cursor の無料版で少しでも Pro の使用感に近付ける方法を紹介します。

:::note alert
この記事の内容は古くなっています。拡張機能でやり繰りするなら VS Code と実質的に変わりません。課金が難しい場合、無料枠のある [Antigravity IDE](https://antigravity.google/) を検討してみてください。
:::

:::note warn
Cursor を活用するには、Cursor Pro の契約が望ましいことは言うまでもありません。本記事は、必要以上に Pro の契約を回避することを推奨するものではありません。
:::

:::note info
Cursor は学生への 1 年間無償提供が始まりました。該当される方はご利用を推奨します。（その場合、本記事の設定は基本的に不要です）
:::

https://www.itmedia.co.jp/aiplus/articles/2505/07/news109.html

更新履歴

- 2026/06/04 記事の内容が古くなったことを警告
- 2026/01/10 Gemini 2.5 Flash の無料枠が 1 日 20 回に縮小されたことを記載
- 2025/06/29 Gemini 2.5 Flash を推奨
- 2025/05/07 学生への 1 年間無償提供を紹介
- 2025/05/05 Gemini 2.5 Flash Preview 04-17 を推奨
- 2025/03/13 Gemini 2.0 Flash との相性を踏まえ、Roo Code を推奨
- 2025/03/12 Composer が再編されて Agent になり、無料版でも使えるようになったのを反映
- 2025/01/09 無料枠で使い続けるという趣旨から、コード補完には Cody を推奨

# 概要

Cursor の無料版でも最低限の基本機能は利用できます。

- AI Chat でのメンション：Codebase (RAG)、Git、ファイル指定
  - RAG を構築する手間が不要
  - Git 機能は、コミットメッセージを生成するのに便利（特に英語でコミットメッセージを書く場合）
  - ファイル内容をブラウザの AI にコピペして質問して、その回答をまたコピペで持って来るような手間が省ける
- [Ctrl]+[K] によるコード生成・修正

無料版で制限される機能はプラグインで代替することで、VS Code に同じプラグインを入れた状態よりも機能は多くなります。特に Codebase は有用です。

## 制限事項

Cursor の無料版における制限事項と、その代替案です。

- Cursor Tab（自動補完）の無料枠（使い切り 2,000回）を使い切った → Cody で代用（GitHub Copilot ユーザーはそちらの利用も可）
- プレミアムモデルの無料枠（50 回 / 月）を使い切った → Ask は Gemini、Agent/Edit は Roo Code で代用
- Web メンション（Web 検索）は Open AI 以外では利用不可 → 代替手段なし
  - Gemini を設定しても、Open AI に対して Gemini の API キーを使おうとしてエラー

## 小規模モデル

小規模モデルの枠は "gpt-4o-mini or cursor-small" とされていますが、`gpt-3.5-turbo` もこの枠で扱われます。`gpt-4o-mini` が使えるため、敢えて使う意味はなさそうですが。

# Gemini

AI Chat や [Ctrl]+[K] で Cursor の無料枠を使い切っても、Gemini の無料枠を使うことで継続して利用できます。（Agent/Edit を除く）

モデルは Gemini 2.5 Flash を推奨します。無料枠のレート制限は以下の通りです。👉[参考](https://ai.google.dev/gemini-api/docs/rate-limits?hl=ja#free-tier)

2026 年 1 月 10 日時点

- 1 分あたりのリクエスト数 (RPM): 5
- 1 日あたりのリクエスト数 (RPD): 20

枠は太平洋時間の午前 0 時にリセットされます。👉[参考](https://ai.google.dev/gemini-api/docs/rate-limits?hl=ja)

太平洋標準時は日本時間の午後 5 時ですが、3 月の第 2 日曜日から 11 月の第 1 日曜日まではサマータイム（太平洋夏時間）となり午後 4 時となります。👉[参考](https://ja.wikipedia.org/wiki/%E5%A4%AA%E5%B9%B3%E6%B4%8B%E6%A8%99%E6%BA%96%E6%99%82)

:::note alert
無料枠での入出力はサービス改善に利用されます。機密情報は渡さないようにご注意ください。👉[参考](https://x.com/kinopee_ai/status/1849729328466030903)
:::

## Gemini の設定

[Google AI Studio](https://aistudio.google.com/) に登録して、API キーを取得してください。

Cursor で設定を開きます。

- ファイル → ユーザー設定 → Cursor Settings
  - Models

Google API Key を貼って [Verify] をクリックします。

モデル一覧で `gemini-2.5-flash` にチェックを付けます。

:::note warn
もしキーを追加するときや、初めて Gemini を使うときにエラーが出た場合、少し時間を置いて再試行してみてください。
:::

# Cline

Cursor チャットの Agent/Edit はプレミアムモデル専用です。枠を使い切った場合、Cline で代用できます。

https://marketplace.visualstudio.com/items?itemName=saoudrizwan.claude-dev

API キーを登録すれば Gemini が利用できます。

# Cody

自動補完（Cursor Tab）は Cody で代用できます。利用にはユーザー登録が必要ですが、基本機能は無料です。

https://marketplace.visualstudio.com/items?itemName=sourcegraph.cody-ai

:::note warn
似た名前の拡張機能がたくさんあるため、インストール時に注意してください。

Cursor の自動補完の方が機能は豊富ですが、まったく利用できないよりはずっと良いです。
:::

## その他（自動補完）

無料で利用できる自動補完の拡張機能は他にもあります。

- [Codeium](https://marketplace.visualstudio.com/items?itemName=Codeium.codeium): GitHub Copilot に似た使用感、無料枠では独自開発の Base Model を提供、自前の API Key は使用不可（開発元は Windsurf というエディタも開発）
- [Gemini Code Assist](https://marketplace.visualstudio.com/items?itemName=Google.geminicodeassist): Google が提供。自動補完の反応頻度が低いような印象だが、[Ctrl]+[Enter] で明示的に呼び出せる
- [Continue](https://marketplace.visualstudio.com/items?itemName=Continue.continue): API Key で LLM を登録、ローカル LLM も使用可能

# 関連記事

別のシステムでひな形を作成して、細かい修正は Cursor に引き継ぐ方法を紹介します。

https://qiita.com/7shi/items/c19c22489839e822ef33

同じジャンルの Windsurf エディタの紹介です。

https://qiita.com/7shi/items/0b818083792364f34f82

# 参考

本記事で紹介したツールが体系的に整理して紹介されています。

https://laiso.hatenablog.com/entry/2025/01/07/045009

Cody の紹介記事です。

https://zenn.dev/sanami/articles/7c24ce973b7e7c

Codeium の紹介記事です。

https://bitbeans.com/blog/codeiumai/

https://qiita.com/dd7223dd/items/98d956184aea119ea41f

Continue の紹介記事です。

https://qiita.com/Tadataka_Takahashi/items/0485159e444056892529
