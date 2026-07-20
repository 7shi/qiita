---
coediting: false
comments_count: 0
created_at: '2020-05-07T20:00:07+09:00'
id: 98c032737e7adcf7fd76
likes_count: 2
private: false
reactions_count: 0
stocks_count: 0
tags:
- name: WebSpeechAPI
  versions: []
- name: SSML
  versions: []
title: Web Speech APIでSSMLのテスト
updated_at: '2020-07-04T18:32:12+09:00'
url: https://qiita.com/7shi/items/98c032737e7adcf7fd76
slide: false
---

Web Speech API で SSML を含むテキストの読み上げを試みました。しかし現状ではサポートされていないようです。

"test" を「ハロー」と読み上げる例です。（うまくいきません）

<p class="codepen" data-height="300" data-theme-id="light" data-default-tab="result" data-user="7shi" data-slug-hash="WNQMggp" style="height: 300px; box-sizing: border-box; display: flex; align-items: center; justify-content: center; border: 2px solid; margin: 1em 0; padding: 1em;" data-pen-title="Web Speech APIでSSMLのテスト ">
  <span>See the Pen <a href="https://codepen.io/7shi/pen/WNQMggp">
  Web Speech APIでSSMLのテスト </a> by 七誌 (<a href="https://codepen.io/7shi">@7shi</a>)
  on <a href="https://codepen.io">CodePen</a>.</span>
</p>
<script async src="https://static.codepen.io/assets/embed/ei.js"></script>

↑ エラーになる場合は一度 [CodePen](https://codepen.io/) を開いてから、この記事をリロードしてください。

以下の記事のサンプルを改造しました。

* [Web Speech API で読み上げ位置を取得](https://qiita.com/7shi/items/43452dcd34e57100fc3c)

# Chromium 系

Chrome と Edge では次の挙動を示しました。

* ローカルエンジン (Windows): タグが無視され「テスト」と読み上げ
* オンラインエンジン: タグもテキストとして読み上げ

オンラインエンジンはブラウザの開発元のサービスに紐付いており、日本語は以下の通りです。

* Chrome: Google 日本語
* Edge: Microsoft Nanami Online (Natural) - Japanese (Japan)

※ もしかして Nanami は[窓辺ななみ](https://ja.wikipedia.org/wiki/%E7%AA%93%E8%BE%BA%E3%81%AA%E3%81%AA%E3%81%BF)と関係があるのでしょうか？（アニメ声ではないですが）

# Firefox

Firefox ではオンラインエンジンはなく、ローカルエンジンのみです。

* ローカルエンジン (Windows): タグもテキストとして読み上げ

同じローカルエンジンを使用しても Chromium 系と挙動が違います。

# SAPI

Windows ローカルのエンジンを SAPI で使用すると、SSML が認識され「ハロー」と読み上げます。

```text
wintts -i test.ssml
```

挙動が違うことから、ブラウザはローカルエンジンに SSML を含むテキストを直接渡しているわけではないようです。

使用している wintts は以下の記事で作成したコマンドです。

* [PythonでWindows 10の音声合成を使用する](https://qiita.com/7shi/items/a5fb03406e0626b4f138)

SAPI での SSML の使用については以下の記事を参照してください。

* [SAPIで発音を指定する](https://qiita.com/7shi/items/51017b4b268f66e11c42)
