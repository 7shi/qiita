---
coediting: false
comments_count: 0
created_at: '2020-02-07T21:19:27+09:00'
id: 43452dcd34e57100fc3c
likes_count: 14
private: false
reactions_count: 0
stocks_count: 7
tags:
- name: JavaScript
  versions: []
- name: TextToSpeech
  versions: []
- name: WebSpeechAPI
  versions: []
title: Web Speech API で読み上げ位置を取得
updated_at: '2020-06-20T20:06:32+09:00'
url: https://qiita.com/7shi/items/43452dcd34e57100fc3c
slide: false
---

ブラウザでテキストを読み上げる Web Speech API で読み上げ位置を取得します。

# Web Speech API

語学学習に音声合成が使えないかとクラウドサービスを調べましたが、契約が必要で課金が気になります。

* [【ミニレビュー】入力したテキストを音声に変換するAWS「Amazon Polly」を無料で試す-Impress Watch](https://www.watch.impress.co.jp/docs/review/minireview/1243596.html)

> Amazon Pollyの初回利用から12カ月間は、500万字/月まで無料。500万字なら、音声の長さで100時間超は使える計算となるので、試しに使ってみるには十分です。

最近のブラウザでは API として実装されていることを知りました。これなら契約しなくても利用できます。

* [Web Speech API](https://wicg.github.io/speech-api/)
* [Web Speech API - Web API | MDN](https://developer.mozilla.org/ja/docs/Web/API/Web_Speech_API)

概要は次の記事に詳しいです。

* [Webページでブラウザの音声合成機能を使おう - Web Speech API Speech Synthesis](https://qiita.com/hmmrjn/items/be29c62ba4e4a02d305c)
* [Web Speech APIの実装 - Speech Synthesis API | CodeGrid](https://app.codegrid.net/entry/2016-web-speech-api-1)

詳細はこれらに譲り、要点をサンプルで示します。

# 設定

音声の再生は環境に依存します。Chrome や [Chromium Edge](https://www.microsoft.com/en-us/edge?icid=SMC-IA-4501095) はデフォルトでオンラインのエンジンが利用できます。その他の環境では以下を参照してください。

* [Windows 10で読み上げ言語を追加](https://7shi.hateblo.jp/entry/2020/02/22/185810)
* [Androidで読み上げ言語を追加](https://7shi.hateblo.jp/entry/2020/02/22/211557)

# 読み上げ

主に 2 つのインターフェイスを使います。

* [SpeechSynthesis - Web API | MDN](https://developer.mozilla.org/ja/docs/Web/API/SpeechSynthesis)
* [SpeechSynthesisUtterance - Web API | MDN](https://developer.mozilla.org/ja/docs/Web/API/SpeechSynthesisUtterance)

API がサポートされているブラウザでは `speechSynthesis` というインスタンスがデフォルトで存在します。読み上げは `SpeechSynthesisUtterance` のインスタンスで言語を指定して `speechSynthesis.speak()` に渡します。読み上げの中止は `speechSynthesis.cancel()` です。

実装例を示します。API が使える環境かどうかは `speechSynthesis` の存在をチェックします。

<p class="codepen" data-height="265" data-theme-id="dark" data-default-tab="js,result" data-user="7shi" data-slug-hash="MWwWdYa" style="height: 265px; box-sizing: border-box; display: flex; align-items: center; justify-content: center; border: 2px solid; margin: 1em 0; padding: 1em;" data-pen-title="Web Speech API のテスト (1)">
  <span>See the Pen <a href="https://codepen.io/7shi/pen/MWwWdYa">
  Web Speech API のテスト (1)</a> by 七誌 (<a href="https://codepen.io/7shi">@7shi</a>)
  on <a href="https://codepen.io">CodePen</a>.</span>
</p>

↑ エラーになる場合は一度 [CodePen](https://codepen.io/) を開いてから、この記事をリロードしてください。

# 音声の指定

使用できる音声が複数ある場合、それらを選択できるようにします。音声をローカルにインストールしていなくても、Chromium 系のブラウザではオンラインのエンジンが使えるものもあります。

音声一覧は `speechSynthesis.getVoices()` で取得できます。注意点として初回の呼び出しで空の配列が返って来る環境があります。その場合は裏で準備が進んでいるため、しばらくして再度呼べば取得できます。取得のタイミングは `onvoiceschanged` イベントで通知されます。

SpeechSynthesisUtterance に選択した voice を設定します。Android の Chrome では lang の設定も必要なため、voice から lang を取得して設定します。

```javascript
u.voice = opt[0].voice;
u.lang  = u.voice.lang;
```

それらの仕様を踏まえた実装例です。取得に失敗した場合、コールバックで再度取得します。

<p class="codepen" data-height="265" data-theme-id="dark" data-default-tab="js,result" data-user="7shi" data-slug-hash="JjdjVvR" style="height: 265px; box-sizing: border-box; display: flex; align-items: center; justify-content: center; border: 2px solid; margin: 1em 0; padding: 1em;" data-pen-title="Web Speech API のテスト (2)">
  <span>See the Pen <a href="https://codepen.io/7shi/pen/JjdjVvR">
  Web Speech API のテスト (2)</a> by 七誌 (<a href="https://codepen.io/7shi">@7shi</a>)
  on <a href="https://codepen.io">CodePen</a>.</span>
</p>

# 読み上げ位置を取得

今どこを読み上げているかという情報は `onboundary` イベントで通知されます。

※ エンジンによってはサポートされていません。Chrome では、PC 版で使えるオンラインエンジン（Google 日本語）や Android の Google テキスト読み上げではイベントが発生しないようです。

実装例を示します。最後に `onend` イベントで選択を解除します。

<p class="codepen" data-height="265" data-theme-id="dark" data-default-tab="js,result" data-user="7shi" data-slug-hash="rNVNgWW" style="height: 265px; box-sizing: border-box; display: flex; align-items: center; justify-content: center; border: 2px solid; margin: 1em 0; padding: 1em;" data-pen-title="Web Speech API のテスト (3)">
  <span>See the Pen <a href="https://codepen.io/7shi/pen/rNVNgWW">
  Web Speech API のテスト (3)</a> by 七誌 (<a href="https://codepen.io/7shi">@7shi</a>)
  on <a href="https://codepen.io">CodePen</a>.</span>
</p>
<script async src="https://static.codepen.io/assets/embed/ei.js"></script>

読み上げの際に形態素解析が行われているのが垣間見えて面白いです。

# SSML

仕様には `onmark` イベントがあります。これが使えれば細かい状況が把握できそうです。

> 発話された utterance が SSML (音声合成マークアップ言語) の "mark" タグに達した時に発火します。

しかし現状では SSML はサポートされていない環境が多いようです。

* [Webアプリケーションに声をつける (Web Speech API, Cloud Text-to-Speech API) - 朝日ネット　技術者ブログ](https://techblog.asahi-net.co.jp/entry/2019/01/21/194815)

> 仕様上、text にプレーンテキストのほかに [SSML](http://www.asahi-net.or.jp/~ax2s-kmtn/ref/accessibility/REC-speech-synthesis11-20100907.html) を指定できるのですが、現在、一部の Voice でしか対応していないようです。

実際に試してみました。タグは無視されるか、テキストとして読み上げの対象になるかで、まだ使える段階ではないようです。

* [Web Speech API でSSMLのテスト](https://qiita.com/7shi/items/98c032737e7adcf7fd76)

# 関連記事

Promise や async/await と組み合わせる方法を説明した記事です。

* [非同期APIをPromiseでラップしてasync/awaitで使う](https://qiita.com/7shi/items/a2bb35f27cd4a56f7bac)

Promise と組み合わせて読み上げをキャンセルする方法を説明した記事です。

* [Promiseの処理をキャンセルする](https://qiita.com/7shi/items/4cc1928061ff4598f10b)

自分の勉強を兼ねてブログで語学記事を執筆することを計画しており、テンプレートを作成中です。対訳を記述しやすくするなどの利便性に注力しています。

* [Web Speech API のテンプレート - 七誌の開発日記](http://7shi.hateblo.jp/entry/2020/01/30/012947)
