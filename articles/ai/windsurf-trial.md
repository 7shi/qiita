---
coediting: false
comments_count: 0
created_at: '2025-01-17T18:34:43+09:00'
id: 0b818083792364f34f82
likes_count: 6
private: false
reactions_count: 0
stocks_count: 3
tags:
- name: エージェント
  versions: []
- name: Codeium
  versions: []
- name: Windsurf
  versions: []
title: Windsurf トライアルの流れ
updated_at: '2025-04-23T18:29:11+09:00'
url: https://qiita.com/7shi/items/0b818083792364f34f82
slide: false
---

Windsurf エディタは VS Code 派生の AI エディタです。自動補完とエージェント機能が統合されています。トライアルと Free プランへの移行についてまとめます。

https://codeium.com/windsurf

:::note alert
【追記 2025/4/23】料金体系が変更になり、Flow Action のカウントがなくなりました。本記事の内容は古くなっています。
:::

https://windsurf.com/blog/pricing-v2

# 概要

各プランでサポートされる機能は、基本的には Pricing に書いてある通りです。

https://codeium.com/pricing

実際に Windsurf を使う前に見ても、用語が独特なこともあって、具体的にどういう機能に対応するのかイメージしにくいかもしれません。そのため実際に使った上で、実用上の影響が大きい機能に絞って説明します。

# トライアルの流れ

Windsurf の AI 機能を利用するにはユーザー登録が必要です。ユーザー登録が済めばトライアルが始まります。課金しなかった場合のフローをまとめます。

1. ユーザー登録
2. トライアル（2 週間）
3. Free プランへの移行

トライアルで利用可能な機能は Pro に準じますが、付与される枠は一度きりで、Pro とは回数が異なります。トライアル終了後、使用した回数はリセットされずに Free プランに移行するため、5 回以上使っていれば 1 か月間はエージェントが使用不可です。

|機能|Trial (一度)|Free (月)|Pro (月)|
|----|---:|---:|---:|
|Premium Cascade User Prompt Credits|50|5|500|
|Premium Cascade Flow Action Credits|200|5|1,500|
|in-editor AI chats|無制限|無制限|無制限|
|Autocomplete|無制限|無制限|無制限|
|Supercomplete|無制限|利用不可|無制限|

## 用語解説

- **Cascade**: 「連鎖的・段階的に処理が進む」という意味で、エージェント機能を含むチャットを指す
  - エージェントに何か指示すると、一連のやり取りの中で必要な処理を段階的に行うことに由来
  - エージェントの有効 (Write)・無効 (Chat) が切り替え可能
- **Premium Cascade User Prompt**: チャットで Claude 3.5 Sonnet や GPT-4o が利用できる回数
  - 利用できるのは提供されたモデルのみで、API Key 登録による利用は不可
- **Premium Cascade Flow Action**: エージェントによるアクション（編集・コマンド実行）機能が利用できる回数
  - 1 回のチャットに対して複数のアクションが実行されることが一般的で、個別にカウントされるため Premium Cascade User Prompt より多めに設定されている
  - アクションに対しては毎回承認が求められ、Reject すればフローは中断
- **in-editor AI chats**: エディタ内でコード生成を指示する AI チャット機能、[Ctrl]+[I] で呼び出す
  - Claude 3.5 Sonnet や GPT-4o は枠を消費せず、Free プランでも利用可能（👉[参考](https://x.com/kinopee_ai/status/1879381490179715163)）
  - ターミナル内でも利用可能、コマンドの生成やオプションの確認などに利用
- **Autocomplete**: 基本的なコード補完、後続の内容を予測して補完
- **Supercomplete**: カーソル周辺の修正内容を随時提案、複数行に渡る変更にも対応

:::note info
エージェントによるアクションは、Claude において MCP を呼び出すのに似ています。in-editor AI chats と Autocomplete は GitHub Copilot と同様な機能です。
:::

## 使用感

Cascade の Write モード（エージェント有効）では、コードに対する変更はチャット内に表示されず、コードが直接修正されます。修正はユーザーが承認することで確定されます。

AI Chat との間でコピペや適用 (Apply) が不要な点は、AI 機能が後付けではなくエディタレベルで統合されていると感じさせるポイントです。

Cursor との比較では機能が絞り込まれていると感じます。それが Pro プランの価格差にも反映されています。

## 枠を使い切った場合

Premium Cascade User Prompt を使い切った場合、Premium Cascade Flow Action が残っていても消費できなくなります。【追記】Web 検索機能で残った枠を消費することは可能です。

枠を使い切った後の可用性は、Free と Pro では異なります。

- **Free**: 追加での枠購入は不可
  - **Write モード**: Cascade Base モデル（Windsurf 独自モデル）が利用不可なため、枠を使い切ればエージェント機能自体が利用不可
  - **Chat モード**: Cascade Base モデルが利用可能
- **Pro**: 追加での枠購入が可能
  - API Key での利用は不可なため、追加利用には枠の購入が必須
  - 枠を購入しなくても Cascade Base モデルでのエージェント利用が可能 (Priority unlimited access to Cascade Base Model)
  - Cascade Base モデルは枠 (Premium Cascade User Prompt / Premium Cascade Flow Action) を消費しない
- **トライアル**: Pro プランに準じるが、追加での枠購入は不可
  - 枠を使い切っても Cascade Base モデルでのエージェント利用が可能

:::note warn
トライアル期間が終了して Free プランに移行した直後に限り、制限が反映されずに Cascade Base モデルでのエージェントや Supercomplete が利用できてしまうことがありました。これは本来の仕様ではありませんが、Free プランでも利用可能だと勘違いした経験があるのでご注意ください。（👉[参考](https://x.com/7shi/status/1879989388798775448)）
:::

# Codeium

開発元の Codeium 社は、Codeium という VS Code を含む各種エディタ用の拡張機能を提供しています。

Codeium には Autocomplete やチャットに相当する機能はありますが、Supercomplete やエージェントに相当する機能は提供されていません。Windsurf の Free プランでできることは、Codeium でほぼカバーされているようです。

また、Codeium には CodeLens（コード内から直接チャットで説明を呼び出す）のように、Windsurf では提供されていない機能もあります。

## 参考

https://bitbeans.com/blog/codeiumai/

https://qiita.com/dd7223dd/items/98d956184aea119ea41f
