---
coediting: false
comments_count: 0
created_at: '2025-04-14T03:38:18+09:00'
id: 7578f1710e76770f1af1
likes_count: 13
private: false
reactions_count: 0
stocks_count: 4
tags:
- name: YouTube
  versions: []
- name: Gemini
  versions: []
- name: 動画解析
  versions: []
title: Gemini が YouTube 動画をどう扱うかの調査
updated_at: '2025-04-20T02:11:06+09:00'
url: https://qiita.com/7shi/items/7578f1710e76770f1af1
slide: false
---

Google が提供する大規模言語モデル Gemini は、テキストだけでなく、画像や音声、動画といったマルチモーダルな情報を扱える点が大きな特徴です。本記事では YouTube 動画の処理について、調査結果をまとめます。

:::note warn
本記事では [Google AI Studio](https://aistudio.google.com/) と API 利用に焦点を当てています。AI チャットの Web サービスとしての [Gemini](https://gemini.google.com/)（旧 Bard）とは挙動が異なりますが、そちらについては調査対象には含めていません。
:::

# 概要

Google AI Studio では YouTube の URL を貼り付けるだけで、動画の内容を理解し、様々なタスクを実行させることが可能です。実際にこの機能を使ってみると、処理に必要なトークン数が異常に多く、処理が非常に重いことに気付きます。

- テキストボックスに [URL](https://www.youtube.com/watch?v=n17NFYBBjXY) を貼り付けた状況

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/32057/00f524c8-f1a3-43ef-a2ac-fc04d1c1918f.png)

:::note info
約 9 分の動画で約 157K トークン（約 17K トークン/分）
:::

本記事では、なぜこれほどまでに重いのかを挙動から推測して、実用的な活用方法を探ります。

## 追記

逆瀬川さん @sakasegawa より、計算方法をご教示いただきました。

<blockquote class="twitter-tweet"><p lang="ja" dir="ltr">個人メモから抜粋:<br>1fps, 1フレームあたり258トークン<br>1秒あたりほかにいるもの: タイムスタンプ7トークン, 音声32トークン<br>1秒あたり258 + 7 + 32 = 297トークンのはずだけれど, 295トークンくらい<br>1分あたり17,700トークン<br>10分あたり177,000トークン<br>1時間あたり1,062,000トークン</p>&mdash; 逆瀬川 (@gyakuse) <a href="https://twitter.com/gyakuse/status/1911498757658824736?ref_src=twsrc%5Etfw">April 13, 2025</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

# Gemini は動画をどう処理しているのか？

Gemini が内部でどのように動画を処理しているのか、いくつかの手掛かりから、その仕組みを推測してみました。

:::note info
【追記】これは当初、資料が見付けられなかったことによります。推測した情報は、公式資料により裏付けが取れました。👉[「参考」](#参考)
:::

実験結果をまとめたリポジトリから、特徴的な個所を抽出して検討します。

https://github.com/7shi/gemini-youtube-test

## 手がかり 1：異常なトークン数と「3600 枚の壁」

最大のヒントは、前述した異常なトークン数と、特定の条件下で発生するエラーメッセージです。1 時間を超える長さの YouTube 動画を Gemini に解析させようとすると、以下のようなエラーが発生し、処理が拒否されます。

```py:エラー（整形済）
google.genai.errors.ClientError: 400 INVALID_ARGUMENT.
{
  'error': {
    'code': 400,
    'message': 'Please use fewer than 3600 images in your request to models/gemini-2.5-pro-exp-03-25',
    'status': 'INVALID_ARGUMENT'
  }
}
```

メッセージには明確に「3600 枚未満の画像を使用してください」とあります。1 時間は 3600 秒であることから、Gemini は動画を 1 秒に 1 枚の静止画（フレーム）に分解し、画像として処理しているのではないかと推測されます。

大量の画像データを処理するためトークン数が膨大になることが、重さの主な原因と考えられます。

以下のログでは映像に含まれる文字情報が読み取られていることから、実際に画像を処理していることが分かります。

<img src="https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/32057/7084b88f-f3c4-4e48-a15b-cbb3192beda5.png" width="50%">

- [text/fall-25p-en.md](https://github.com/7shi/gemini-youtube-test/blob/main/text/fall-25p-en.md)

> * **Visuals:** Title card. Black and white image featuring two silhouetted figures in a dark, smoky room. One figure stands while the other sits at a counter. White text overlays: "Albert Camus 'The Fall'", "アルベール・カミュ『転落』" (Albert Camus "The Fall"), and production credits ("Conversation: NotebookLM", "Director: Gemini 1.5 Flash", "Image: Stable Diffusion 3").

## 手がかり 2：音声の直接解析

従来の LLM を用いた動画要約では、YouTube から字幕（文字起こし）をテキストデータとして取得し、それを処理するのが一般的でした。この方法なら、トークン数は大幅に抑えられます。

しかし、Gemini の解析結果を見ると、単に字幕データを処理しているだけではないことがわかります。

1. **文字起こし結果が字幕と異なる**：Gemini に動画の文字起こしをさせると、YouTube が提供する字幕データと必ずしも一致しません。これは、Gemini が字幕データを参照するのではなく、動画の音声を直接認識・解析している可能性を示唆しています。
   - [text/fall-20f-en.md](https://github.com/7shi/gemini-youtube-test/blob/main/text/fall-20f-en.md)（疑問文として解釈）
   ```text:字幕
   Like you put the book down but you can't shake it.
   ```
   ```text:Gemini
   Like you put the book down but you can't shake it?
   ```
   &nbsp;

2. **話者の区別が可能**：Gemini は動画に登場する複数の話者を区別できます。これは、通常の字幕データには含まれていない情報です。
   - [text/fall-20f-en.md](https://github.com/7shi/gemini-youtube-test/blob/main/text/fall-20f-en.md)
   > **[00:00:04 to 00:00:55] Discussion on Camus' "The Fall"**
   > *   **Visual:** Rainy city streets, transitioning to a bar scene with a rainy window, and then to a gavel and law book.
   > *   **Audio:**
   >     *   Speaker 1: Okay, so you know how sometimes you read something and it just kind of sticks with you?
   >     *   Speaker 2: Mhm.
   >     *   Speaker 1: Like you put the book down but you can't shake it?
   >     *   Speaker 2: Absolutely.

これらの挙動から、Gemini は音声データそのものを解析して、声質の違いから話者を特定していることが示唆されます。

## 推定される動作

Gemini の YouTube 動画解析は「1 秒 1 枚の画像解析＋音声直接解析」という、非常にリッチな情報処理を行っている可能性が高いです。これが、従来の字幕ベース解析とは一線を画す能力と、その代償としての重さを生み出していると考えられます。

動画内で話者の名前がテロップで表示された場合、Gemini はその情報を認識して、話者の特定に利用している様子が見られます。

- [Pre-Training GPT-4.5](https://www.youtube.com/watch?v=6nJZopACRuQ)（サンプルリポジトリ外）

> * **Visuals:** A person holds a digital clapperboard in front of the camera. The board reads "SAM A PODCAST", SCENE 101, TAKE 1, and lists names "ASPREY T", "TIRA", "DREW KASS". The timecode runs: 15.10.53.09. Four men are seated around a light-colored wooden table in a modern, minimalist room. A large green plant is behind the man on the far right. Sam Altman (implied, far left) is looking towards the man next to him (Alex Paino). Text overlays appear: "Pre-Training" and "GPT-4.5". The clapperboard claps shut.
>   * **Audio:**
>     * Man 1 (Sam): How many parameters is it still or do we not care?
>     * Man 2 (Alex): I think we should just...
>     * *(Clapper sound)*

# Gemini 動画解析のメリット

この重い処理はどのようなメリットをもたらすのでしょうか。字幕データだけでは得られない、Gemini ならではのメリットを見ていきましょう。

* **映像情報の活用:**
  * **話者の特定:** 誰が話しているのかを、映像（口の動き、姿、テロップ）と音声から判断します。複数人が参加する対談や会議の議事録作成などに役立ちます。
  * **状況・行動の把握:** ストーリー性のある動画などで、登場人物が何をしているか、どのような状況かを理解します。セリフだけでは分からない文脈を捉えることができます。
  * **視覚情報の抽出:** チュートリアル動画や講義動画などで画面に表示される図、グラフ、コード、スライドの内容を認識し、抽出できます。学習や情報収集の効率が格段に向上します。
* **音声情報の活用:**
    * **高精度な話者分離:** 声質の違いを捉え、誰の発言かを明確にします。議論の流れや各々の意見を正確に追跡できます。

## 使い分けが重要

Gemini の動画解析は強力ですが、常に最適な選択肢とは限りません。状況に応じて、従来の字幕データ解析と使い分けることが重要です。

* **Gemini 動画解析が適しているケース:**
  * **複数人の対話・議論:** 話者の区別が重要となる動画（インタビュー、パネルディスカッションなど）
  * **映像に重要な情報が含まれる動画:** 画面上の図解、デモンストレーション、プログラミング画面、風景や人物の動きが意味を持つ動画
  * **話者の特定や行動の把握が必要な場合:** ドキュメンタリー、ドラマなど
* **字幕データ解析で十分な（または適している）ケース:**
  * **一人の話者が淡々と話す動画:** いわゆる「モノローグ」形式の講演、解説動画などで、映像情報に大きな意味がない場合
  * **処理の軽さ・コストを最優先したい場合:** 大量の動画を高速に処理したい、API利用料を抑えたい場合
  * **テキスト情報のみが必要な場合:** 動画の要約やキーワード抽出が主目的の場合

現状では、動画の内容を事前に確認しないとどちらの方法が最適か判断するのは難しいです。当面は、目的に応じて手動で処理方法を選択するのが現実的でしょう。

# 実践編：Gemini で動画を効率的に解析する

Gemini の動画解析機能を実際に活用する上で、いくつか注意点とコツがあります。

## 処理上限

前述の「3600 枚の壁」により、現状では **1 時間**が Gemini で直接解析できる動画の長さの上限と考えられます。長時間のライブ配信などを扱う場合は注意が必要です。将来的にはこの上限が緩和されることを期待します。

## 構造化出力 (JSON)

Gemini に「この動画の内容を要約して」のように自由形式で指示を出すことも可能です。しかし、後でプログラム等でデータを活用したい場合、出力形式が安定しないと扱いにくくなります。

そこでお勧めなのが **JSON 形式での構造化出力**です。例えば、以下のようなスキーマ（構造）を定義して出力を求めます。

- スキーマ: [schema-m.json](https://github.com/7shi/gemini-youtube-test/blob/main/schema-m.json)
- 出力例: [json/fall-20p-m.json](https://github.com/7shi/gemini-youtube-test/blob/main/json/fall-20p-m.json)

```json
{
  "scenes": [
    {
      "audio": [],
      "time": "00:00:00",
      "visuals": "Title card: Albert Camus \"The Fall\", アルベール・カミュ『転落』, Conversation: NotebookLM, Director: Gemini 1.5 Flash, Image: Stable Diffusion 3. The visual shows silhouettes of two men in a smoky, dimly lit room resembling a bar."
    },
    {
      "audio": [
        {
          "speaker": "Speaker 1",
          "transcription": "Okay, so you know how sometimes you read something and it just kind of sticks with you?"
        },
        {
          "speaker": "Speaker 2",
          "transcription": "Mhm."
        },
        {
          "speaker": "Speaker 1",
          "transcription": "Like you put the book down but you can't shake it."
        },
        {
          "speaker": "Speaker 2",
          "transcription": "Absolutely. Well, listeners sent in this excerpt from Camus's The Fall, and it's like Oh yeah, The Fall. It's uh it's one of those books."
        },
        {
          "speaker": "Speaker 1",
          "transcription": "It gets under your skin."
        }
      ],
      "time": "00:00:05",
      "visuals": "A nighttime view down a wet, cobblestone street lined with buildings in Amsterdam. Streetlights reflect in puddles on the road. Text overlays in English and Japanese discuss the feeling of a book that 'sticks with you' or 'gets under your skin'."
    },
（以下略）
```

JSON で出力させることで、後続の処理（データベースへの格納、さらなる分析、レポート生成など）が格段に容易になります。

:::note warn
時間は `MM:SS` の形式で指定することが推奨されています。👉[参考](https://x.com/gyakuse/status/1911501573911646242)

`HH:MM:SS` の形式では、時間情報が正確に取れないことがあります。当初その仕様を知らなかったため、リポジトリ内のログはすべて `HH:MM:SS` で処理しました。（スキーマだけは `MM:SS` に修正済）

- [Pre-Training GPT-4.5](https://www.youtube.com/watch?v=6nJZopACRuQ)（サンプルリポジトリ外）
```json:途中で時間の単位がずれる例
    {
      "speaker": "Amin",
      "time": "00:10:46",
      "transcription": "That we skipped them for this one. For the next one, we have to do it. There is no way around it. And it's always those choices that basically make the timeline of building the perfect system take much longer."
    },
    {
      "speaker": "Amin",
      "time": "10:51:00",
      "transcription": "Uh so we are always compromising on what is the fastest way to get to this result. The systems is not an end on its own. The product that the thing that it produces is. So, for the next 10x for me, it would be uh of course fault tolerance."
    },
```
:::

### スキーマ設計のポイント

* **シーン（場面）単位で区切る:** 時間経過や話題の変化で区切ると分かりやすい。
* **映像情報に対して複数の発言を紐付け:** 複数話者の場合、発言ごとに映像情報を繰り返すと冗長になるため、シーンに対して複数の発言を紐付けるのが効率的。
* **話者情報を含める:** 誰の発言かを明確にする。
* **用途に応じてカスタマイズ:** モノローグ動画なら発言をリストではなく単一文字列にしても良いかもしれません。

例としてカスタマイズしたスキーマを示します。

* [schema-1.json](https://github.com/7shi/gemini-youtube-test/blob/main/schema-1.json): モノローグ用（映像あり・発言は単一文字列）
* [schema-a.json](https://github.com/7shi/gemini-youtube-test/blob/main/schema-a.json): 対談動画用（映像なし・発言はリスト）

スキーマの調整は以下の記事を参考にしてください。

https://qiita.com/7shi/items/5a1add7189c45ae4a254

## モデル選択

Gemini にはいくつかのモデルが存在します。そして、この動画解析のような負荷の高い処理には、**高性能なモデルが必要**です。

Gemini 1.5 Pro や Gemini 2.0 Flash では、比較的短い（10 分程度）動画の解析でも正常に出力できないケースがありました。（長い動画では更に顕著です）

- [json/fall-15p-m.json](https://github.com/7shi/gemini-youtube-test/blob/main/json/fall-15p-m.json)（途中で切れている）
- [json/fall-20f-m.json](https://github.com/7shi/gemini-youtube-test/blob/main/json/fall-20f-m.json)（最後が壊れている）
- [text/fall-20f-ja.md](https://github.com/7shi/gemini-youtube-test/blob/main/text/fall-20f-ja.md)（途中で切れている）

安定して動画解析を行うためには、Gemini 2.0 Pro (Experimental) や Gemini 2.5 Pro (Experimantal/Preview) といった、より高性能なモデルを選択する必要があります。感覚的には、2.0 Pro と 2.5 Pro の間では、動画解析性能に大きな差は感じられませんでした。（リポジトリのログを参照）

【追記】Gemini 2.5 Flash Preview 04-17 は動画が 30 分を超えると抜けが発生するようです。15 分程度の動画であれば特に問題はなさそうです。

:::note warn
高性能なモデルほど無料枠は少なく、利用料金が高くなります。また、無料枠を利用する場合、入力データが Google のモデル改善に利用される可能性があるため、機密性の高い情報を扱うことは避けてください。
:::

## 推奨されるワークフロー

Gemini の動画解析は強力ですが、トークン消費量が多いため、API 利用料がかさむ可能性があります。また、解析結果に対して「ここの表現を修正して」といった指示を出すたびに、再度動画全体を処理するのは非効率です。

そこで、以下のワークフローを推奨します。

1. **動画内容の書き出し：**
   Gemini に YouTube 動画 URL を渡し、JSON スキーマを指定して、映像・音声・話者情報を含む詳細な内容を書き出させます。
2. **書き出したデータを対象に処理：**
   生成された JSON データをインプットとして、要約、翻訳、記事生成、質疑応答などの後続タスクを（必要であれば別の、より軽量な LLM も活用しつつ）行います。

この方法なら、重い動画解析処理は最初の 1 回だけで済みます。その後の修正や追加処理は、比較的軽量な JSON データを対象に行えるため、コストと時間を大幅に節約できます。

また、モノローグ動画で映像情報が不要と判断できる場合は、最初から字幕データを使う方が効率が良いでしょう。

# まとめ

Gemini による YouTube 動画解析は、「1 秒 1 枚の画像解析＋音声直接解析」というリッチな処理により、従来の字幕ベース解析では不可能だったレベルの深い動画理解を実現します。話者分離、映像内の情報抽出など、その応用範囲は広がります。

一方で、処理の重さ（高トークン消費）、モデル性能への依存、約 1 時間という処理上限といった制約も存在します。

この強力な機能を最大限に活かすためには、その特性を理解し、ユースケースに応じて字幕解析と使い分け、構造化出力や効率的なワークフローを構築することが重要です。

# 参考

動画理解についての公式情報です。

https://cloud.google.com/vertex-ai/generative-ai/docs/multimodal/video-understanding?hl=ja

> **ベスト プラクティス**
> 
> 動画を使用する場合は、最良の結果を得るために、次のベスト プラクティスと情報を使用してください。
> 
> - プロンプトに 1 つの動画が含まれている場合は、テキスト プロンプトの前に動画を配置します。
> - 音声付き動画のタイムスタンプのローカライズが必要な場合は、モデルに `MM:SS` 形式のタイムスタンプを生成させます。最初の 2 桁が分、最後の 2 桁が秒を表します。タイムスタンプに関する質問にも同じ形式を使用します。

# 関連記事

Gemini のエラー処理についてまとめた記事です。本記事での調査で得られた知見をまとめたものです。

https://qiita.com/7shi/items/3fb540c72ad4577350c6

サンプルとして扱った動画は、以下の手法で作成しました。

https://qiita.com/7shi/items/04962cf58e172da662c1
