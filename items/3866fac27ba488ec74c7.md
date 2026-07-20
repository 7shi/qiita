---
coediting: false
comments_count: 2
created_at: '2020-05-19T00:13:04+09:00'
id: 3866fac27ba488ec74c7
likes_count: 5
private: false
reactions_count: 0
stocks_count: 5
tags:
- name: HTML
  versions: []
- name: JavaScript
  versions: []
- name: WebAudioAPI
  versions: []
title: AnalyserNodeのサンプルを動かしてみた
updated_at: '2022-07-26T20:44:34+09:00'
url: https://qiita.com/7shi/items/3866fac27ba488ec74c7
slide: false
---

MDN の AnalyserNode のサンプルコードは入力の部分が省略されていたため、マイクから音を拾うようにして動かしました。

![あ.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/32057/782a80ae-f353-4b67-632f-81a9d819bdb0.png)

埋め込みだとマイクがうまく動かないので、動作確認は CodePen を開いてください。

* [マイクからの音声波形データ](https://codepen.io/7shi/pen/rNOQyog)

【追記1】 同時に `getByteFrequencyData` による周波数分析を行うサンプルを作成しました。

* [マイクからの周波数分析](https://codepen.io/7shi/pen/JjYeOjO)

【追記2】Chrome の仕様変更に対応しました。

# 概要

MDN に AnalyserNode のサンプルコードが掲載されています。

* [AnalyserNode - Web API | MDN](https://developer.mozilla.org/ja/docs/Web/API/AnalyserNode)

```javascript
var audioCtx = new (window.AudioContext || window.webkitAudioContext)();
var analyser = audioCtx.createAnalyser();

  ...

analyser.fftSize = 2048;
var bufferLength = analyser.frequencyBinCount;
var dataArray = new Uint8Array(bufferLength);
analyser.getByteTimeDomainData(dataArray);

（略）
```

Voice-change-O-matic デモからの引用だと記載されていますが、残念ながらそのデモは使い方が分かりませんでした。

【追記】 MDN 日本語版の情報が古いようです。[英語版](https://developer.mozilla.org/en-US/docs/Web/API/AnalyserNode)からリンクされている https の方は動きました。

* [Voice-change-O-matic](https://mdn.github.io/voice-change-o-matic/)

そこで `...` の部分を補って動くコードにします。

【追記】 少し違う API ですが、英語版に完全な形でのサンプルがありました。MP3 を読み込む仕様です。

* [AnalyserNode.getFloatFrequencyData() - Web APIs | MDN](https://developer.mozilla.org/en-US/docs/Web/API/AnalyserNode/getFloatFrequencyData)

# 追加箇所

Canvas とボタンとエラーメッセージ用の span を用意します。

```html
<canvas id="canvas" width="500" height="200" style="border:1px solid #000000;"></canvas><br>
<button id="startButton">Start</button>
<span id="errorMessage"></span>
```

Canvas 関係の変数と、ボタンをクリックするとマイクから入力を開始するコードを補います。

```javascript
let canvasCtx = canvas.getContext("2d");
let WIDTH = canvas.width;
let HEIGHT = canvas.height;

let stream;
startButton.onclick = async function () {
  if (stream) return;
  try {
    await audioCtx.resume();
    stream = await navigator.mediaDevices.getUserMedia({
      audio: true
    });
    audioCtx.createMediaStreamSource(stream).connect(analyser);
  } catch (err) {
    errorMessage.textContent = err.toString();
  }
};
```

これでとりあえず動くようになりました。

# 参考

同じ MDN を参照している記事を参考にしました。

* [JavaScriptのAnalyzerNodeで拾った音の周波数を可視化してみる２ - saitodev.co](https://saitodev.co/article/JavaScript%E3%81%AEAnalyzerNode%E3%81%A7%E6%8B%BE%E3%81%A3%E3%81%9F%E9%9F%B3%E3%81%AE%E5%91%A8%E6%B3%A2%E6%95%B0%E3%82%92%E5%8F%AF%E8%A6%96%E5%8C%96%E3%81%97%E3%81%A6%E3%81%BF%E3%82%8B%EF%BC%92)

API の変更に伴い、以下の個所を修正する必要がありました。

```javascript
    //様々なブラウザでマイクへのアクセス権を取得する
    navigator.getUserMedia = navigator.getUserMedia || navigator.webkitGetUserMedia;
```

【参考】 [「MediaDevices.getUserMedia() 」について](https://qiita.com/Futo_Horio/items/bff1ce1d2e1b219b243d)

以下の個所で別の API を呼んでいるため、表示される波形が別の形になります。

```javascript
        analyser.getByteFrequencyData(data);
```

描画の度にバッファを確保していたため、メモリ使用量がどんどん増加しました。

```javascript
        var bufLen = analyser.frequencyBinCount;
        var data = new Uint8Array(bufLen);
```

マイクからの入力がそのまま出力に接続されているため、自分の声がそのまま再生されてハウリングの原因になっていました。

```javascript
        analyser.connect(audioCtx.destination);
```

この部分を外しても動作しました。

* [AnalyserNode - Web API | MDN](https://developer.mozilla.org/ja/docs/Web/API/AnalyserNode)

> １つのAnalyzerNodeは必ず１つの入力と出力を持ちます。出力先がなくてもAnalyzerNodeは問題ありません。

Chrome 71 以降での仕様変更により、事前に作った `AudioContext` に対してユーザー操作後に `resume()` が必須になりました。

```javascript
    await audioCtx.resume();
```

【参考】 [Chromeで Web Audio API の音が鳴らない現象への対処 (Warning: The AudioContext was not allowed to start) - Wizard Notes](https://www.wizard-notes.com/entry/javascript/web-audio-api-chrome-user-interaction)

色々と書きましたが、まず動くコードが欲しかったので、非常に助かりました。

# Python

今回はブラウザで JavaScript を使いましたが、方法を調査しているときに Python を使った記事を見掛けたので、メモしておきます。

* [Pythonで音声解析 – 音声データの周波数特性を調べる方法](https://jorublog.site/python-voice-analysis/)
* [リアルタイムで音声波形の取得【PyAudio】｜もくいち｜note](https://note.com/mokuichi/n/n70d61237e6c7)
