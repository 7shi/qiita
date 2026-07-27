---
coediting: false
comments_count: 0
created_at: '2023-08-03T02:47:04+09:00'
id: c7b21eb28c953315da7e
likes_count: 1
private: false
reactions_count: 0
stocks_count: 0
tags:
- name: JavaScript
  versions: []
- name: TTS
  versions: []
- name: WebSpeechAPI
  versions: []
title: ページに部分的な読み上げ機能を付ける
updated_at: '2023-11-24T11:52:11+09:00'
url: https://qiita.com/7shi/items/c7b21eb28c953315da7e
slide: false
---

web-tts という自作ライブラリを使って、Web ページに部分的な読み上げ機能を付ける方法を説明します。

# web-tts

web-tts は、はてなブログで対訳の読み上げを行うために開発したライブラリです。

https://github.com/7shi/web-tts

はてなブログに特化したものではないため、JavaScript が使える環境であれば使用できます。

対訳に特化したライブラリですが、コードを書けばページの一部分を指定して読み上げることができます。今回はその使い方を説明します。

# 準備

CSS と JavaScript を CDN 経由で読み込みます。（[参考](https://qiita.com/7shi/items/4d80f838638a5bb66265)）

```html
<link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/7shi/web-tts@0.11/speech.min.css">
<script src="https://cdn.jsdelivr.net/gh/7shi/web-tts@0.11/speech.min.js"></script>
```

音声の選択肢を出すための受け皿となる table を用意します。

```html
<table id="voice_table"></table>
```

言語を指定して table を初期化します。

```html
<script>
webTTS.initVoices({
  en: { name: "英語", country: "US", test: "hello" },
}, voice_table);
</script>
```

* `en` と `"US"` で `en-US`（アメリカ英語）を指定します。（後述）
* `test` でテスト用のフレーズを指定します。
* `name` はボタンのテキストを指定しているだけで、書き換えても言語選択には影響しません。

table にテスト用ボタンと選択肢が生成されます。

<p class="codepen" data-height="300" data-default-tab="result" data-slug-hash="VwVgWGz" data-user="7shi" style="height: 300px; box-sizing: border-box; display: flex; align-items: center; justify-content: center; border: 2px solid; margin: 1em 0; padding: 1em;">
  <span>See the Pen <a href="https://codepen.io/7shi/pen/VwVgWGz">
  web-tts (1) 音声選択</a> by 七誌 (<a href="https://codepen.io/7shi">@7shi</a>)
  on <a href="https://codepen.io">CodePen</a>.</span>
</p>
<script async src="https://cpwebassets.codepen.io/assets/embed/ei.js"></script>

## 音声一覧

`en-US` のように指定できる言語や地域の一覧を取得します。

<p class="codepen" data-height="300" data-default-tab="result" data-slug-hash="rNOdqmq" data-user="7shi" style="height: 300px; box-sizing: border-box; display: flex; align-items: center; justify-content: center; border: 2px solid; margin: 1em 0; padding: 1em;">
  <span>See the Pen <a href="https://codepen.io/7shi/pen/rNOdqmq">
  ブラウザで使える音声の調査</a> by 七誌 (<a href="https://codepen.io/7shi">@7shi</a>)
  on <a href="https://codepen.io">CodePen</a>.</span>
</p>
<script async src="https://cpwebassets.codepen.io/assets/embed/ei.js"></script>

:::note info
利用可能な音声は環境依存で、OS やブラウザによって異なります。Edge は OS に依存しない高品質なオンライン音声を豊富に揃えているためお勧めです。
:::

# 読み上げ

web-tts は読み上げ用のボタンとテキストをセットにして、それぞれ span として用意します。

```html
<p>
  <span id="button1"></span><span id="text1">This is a pen.</span>
</p>
```

JavaScript でボタンを初期化して、テキストと関連付けます。

```js
button1.playStop = ["▶", "■"];
button1.style.width = "1.5em";
webTTS.setSpeak(button1, "en", text1);
```

ボタンを押せばテキストが読み上げられるようになります。

<p class="codepen" data-height="300" data-default-tab="result" data-slug-hash="poQGwBz" data-user="7shi" style="height: 300px; box-sizing: border-box; display: flex; align-items: center; justify-content: center; border: 2px solid; margin: 1em 0; padding: 1em;">
  <span>See the Pen <a href="https://codepen.io/7shi/pen/poQGwBz">
  web-tts (2) 読み上げ</a> by 七誌 (<a href="https://codepen.io/7shi">@7shi</a>)
  on <a href="https://codepen.io">CodePen</a>.</span>
</p>
<script async src="https://cpwebassets.codepen.io/assets/embed/ei.js"></script>

:::note info
読み上げ位置を黄色で示す機能を実装していますが、位置を示すイベントが音声に実装されているかに依存します。Edge のオンライン音声では利用可能ですが、Chrome のオンライン音声では利用不可です。
:::

## 複数のテキスト

`speakTarget` が配列になっているのは、1 つのボタンに複数のテキストを関連付けられるようにするためです。センテンスごとに span を分けることを想定しています。

例を示します。

```html
<p>
  <span id="button1"></span>
  <span id="text1_1">This is a pen.</span>
  <span id="text1_2">That is a pencil.</span>
</p>
```

```js
button1.playStop = ["▶", "■"];
button1.style.width = "1.5em";
webTTS.setSpeak(button1, "en", text1_1, text1_2);
```

<p class="codepen" data-height="300" data-default-tab="result" data-slug-hash="QWJYMyL" data-user="7shi" style="height: 300px; box-sizing: border-box; display: flex; align-items: center; justify-content: center; border: 2px solid; margin: 1em 0; padding: 1em;">
  <span>See the Pen <a href="https://codepen.io/7shi/pen/QWJYMyL">
  web-tts (3) 複数のテキスト</a> by 七誌 (<a href="https://codepen.io/7shi">@7shi</a>)
  on <a href="https://codepen.io">CodePen</a>.</span>
</p>
<script async src="https://cpwebassets.codepen.io/assets/embed/ei.js"></script>

## setSpeak

ボタンの外見をセットするための関数を定義します。

```js
function setSpeak(button, lang, ...targets) {
  button.playStop = ["▶", "■"];
  button.style.width = "1.5em";
  webTTS.setSpeak(button, lang, ...targets);
}
```

以後のサンプルではこの関数を使用します。

## 連続読み上げ

speakTarget にボタンを指定すれば、複数のボタンに関連付けられたテキストを連続して読み上げることができます。

```html
<p>連続 <span id="button0"></span></p>
<p>
  <span id="button1"></span><span id="text1">This is a pen.</span><br>
  <span id="button2"></span><span id="text2">That is a pencil.</span>
</p>
```

```js
setSpeak(button1, "en", text1);
setSpeak(button2, "en", text2);
setSpeak(button0, "", button1, button2);
```

<p class="codepen" data-height="300" data-default-tab="result" data-slug-hash="rNQPzWW" data-user="7shi" style="height: 300px; box-sizing: border-box; display: flex; align-items: center; justify-content: center; border: 2px solid; margin: 1em 0; padding: 1em;">
  <span>See the Pen <a href="https://codepen.io/7shi/pen/rNQPzWW">
  web-tts (4) 連続読み上げ</a> by 七誌 (<a href="https://codepen.io/7shi">@7shi</a>)
  on <a href="https://codepen.io">CodePen</a>.</span>
</p>
<script async src="https://cpwebassets.codepen.io/assets/embed/ei.js"></script>

## 次を指定

別の方法として、次に再生するボタンを `nextSpeak` で指定します。

```html
<p>
  <span id="button1"></span><span id="text1">This is a pen.</span><br>
  <span id="button2"></span><span id="text2">That is a pencil.</span>
</p>
```

```js
setSpeak(button1, "en", text1);
setSpeak(button2, "en", text2);
button1.nextSpeak = button2;
```

<p class="codepen" data-height="300" data-default-tab="result" data-slug-hash="dyaeveX" data-user="7shi" style="height: 300px; box-sizing: border-box; display: flex; align-items: center; justify-content: center; border: 2px solid; margin: 1em 0; padding: 1em;">
  <span>See the Pen <a href="https://codepen.io/7shi/pen/dyaeveX">
  web-tts (5) 次を指定</a> by 七誌 (<a href="https://codepen.io/7shi">@7shi</a>)
  on <a href="https://codepen.io">CodePen</a>.</span>
</p>
<script async src="https://cpwebassets.codepen.io/assets/embed/ei.js"></script>

# 複数言語

`initVoices` に言語を追加してテキストの span の `language` に指定すれば、複数の言語を読み上げることができます。

```html
<script>
webTTS.initVoices({
  en: { name: "英語", country: "US", test: "hello" },
  fr: { name: "フランス語", country: "FR", test: "bonjour" },
}, voice_table);
</script>
```

```html
<p>連続 <span id="button0"></span></p>
<p>
  <span id="button1"></span><span id="text1">This is a pen.</span><br>
  <span id="button2"></span><span id="text2">C'est un stylo.</span>
</p>
```

```js
setSpeak(button1, "en", text1);
setSpeak(button2, "fr", text2);
setSpeak(button0, "", button1, button2);
```

<p class="codepen" data-height="300" data-default-tab="result" data-slug-hash="dyQamBV" data-user="7shi" style="height: 300px; box-sizing: border-box; display: flex; align-items: center; justify-content: center; border: 2px solid; margin: 1em 0; padding: 1em;">
  <span>See the Pen <a href="https://codepen.io/7shi/pen/dyQamBV">
  web-tts (6) 複数言語</a> by 七誌 (<a href="https://codepen.io/7shi">@7shi</a>)
  on <a href="https://codepen.io">CodePen</a>.</span>
</p>
<script async src="https://cpwebassets.codepen.io/assets/embed/ei.js"></script>

## 対訳

web-tts には複数言語のテキストを対訳形式に変換する機能があります。ボタンとテキストの関連付けは自動化されます。

:::note info
`<pre>` か `<code>` の片方だけでも機能します。`<pre>` は、デバッグ用に `hidden` を外したときに改行を維持することが目的です。`<code>` は、はてなブログでのはてなキーワード対策として付けているため、それ以外の環境では必須ではありません。
:::

```html
<pre hidden><code id="source1">
This is a pen.
C'est un stylo.

That is a pencil.
C'est un crayon.
</code></pre>
<p>
  <table id="button1"></table>
  <table id="text1"></table>
</p>
```

```js
const source1Table = webTTS.convertSource(source1);
webTTS.initTable(source1Table, button1, text1, "en", "fr");
```

<p class="codepen" data-height="300" data-default-tab="result" data-slug-hash="bGQzKpe" data-user="7shi" style="height: 300px; box-sizing: border-box; display: flex; align-items: center; justify-content: center; border: 2px solid; margin: 1em 0; padding: 1em;">
  <span>See the Pen <a href="https://codepen.io/7shi/pen/bGQzKpe">
  web-tts (7) 対訳</a> by 七誌 (<a href="https://codepen.io/7shi">@7shi</a>)
  on <a href="https://codepen.io">CodePen</a>.</span>
</p>
<script async src="https://cpwebassets.codepen.io/assets/embed/ei.js"></script>

この方式については以下の記事を参照してください。はてなブログを想定していますが、他でも応用できる内容です。

https://7shi.hateblo.jp/entry/2020/01/30/012947

# 会話

同一言語で異なる音声を指定すれば、会話のように読み上げることも可能です。

:::note warn
同一言語で異なる音声が利用可能かは環境依存です。Edge と Chrome と Windows ローカルの音声をコンマで区切って指定する例を示します。それ以外の環境では同一音声になります。（フォント指定の状況に似ています）
:::

```html
<script>
webTTS.initVoices({
  en1: { name: "英語1", lang: "en", test: "hello", prefer: "Eric Online,Male,David" },
  en2: { name: "英語2", lang: "en", test: "hello", prefer: "Aria Online,Female,Zira" },
}, voice_table);
</script>
```

```html
<p>連続 <span id="button0"></span></p>
<p>
  <span id="button1"></span><span id="text1">What is this?</span><br>
  <span id="button2"></span><span id="text2">This is a pen.</span>
</p>
```

```js
setSpeak(button1, "en1", text1);
setSpeak(button2, "en2", text2);
setSpeak(button0, "", button1, button2);
```

<p class="codepen" data-height="300" data-default-tab="result" data-slug-hash="YzRBRPW" data-user="7shi" style="height: 300px; box-sizing: border-box; display: flex; align-items: center; justify-content: center; border: 2px solid; margin: 1em 0; padding: 1em;">
  <span>See the Pen <a href="https://codepen.io/7shi/pen/YzRBRPW">
  web-tts (8) 会話</a> by 七誌 (<a href="https://codepen.io/7shi">@7shi</a>)
  on <a href="https://codepen.io">CodePen</a>.</span>
</p>
<script async src="https://cpwebassets.codepen.io/assets/embed/ei.js"></script>

## ピッチ

ピッチを指定して声を変える方法もあります。

:::note warn
Edge のオンライン音声のようにピッチの変更をサポートしない音声もあります。
:::

```html
<script>
webTTS.initVoices({
  en1: { name: "英語1", lang: "en", country: "US", pitch: 1, test: "hello" },
  en2: { name: "英語2", lang: "en", country: "US", pitch: 2, test: "hello" },
}, voice_table);
</script>
```

ピッチに指定できるのは 0 から 2 までの浮動小数点数で、デフォルトは 1 です。

https://developer.mozilla.org/en-US/docs/Web/API/SpeechSynthesisUtterance/pitch

# 環境依存

ここまで見たように、Web Speech API は手軽ではありますが、使用できる音声が環境に依存します。

商用サイトでは [Amazon Polly](https://aws.amazon.com/jp/polly/) や [Azure Speech Service](https://learn.microsoft.com/ja-JP/azure/ai-services/speech-service/) などの商用クラウドサービスを使うことになるでしょう。

:::note info
Edge で利用可能なオンライン音声は Azure Speech Service で提供される音声のサブセットのようです。
:::

# 関連記事

Web Speech API を直接扱うための記事です。web-tts はこれらの内容をまとめたものです。

https://qiita.com/7shi/items/43452dcd34e57100fc3c

https://qiita.com/7shi/items/a2bb35f27cd4a56f7bac

https://qiita.com/7shi/items/4cc1928061ff4598f10b

https://qiita.com/7shi/items/7f98e144cb69234c5e0e
