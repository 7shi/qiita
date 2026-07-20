---
coediting: false
comments_count: 0
created_at: '2020-07-08T05:55:17+09:00'
id: ba7089e864fefac69808
likes_count: 23
private: false
reactions_count: 0
stocks_count: 19
tags:
- name: JavaScript
  versions: []
title: html2canvasを試す
updated_at: '2020-07-09T02:06:04+09:00'
url: https://qiita.com/7shi/items/ba7089e864fefac69808
slide: false
---

HTML の Element を画像に変換するライブラリ html2canvas を試しました。Chrome では良好ですが、Firefox では文字のサイズが変わってレイアウトが崩れるようです。

<p class="codepen" data-height="310" data-theme-id="light" data-default-tab="result" data-user="7shi" data-slug-hash="NWxYOMm" style="height: 310px; box-sizing: border-box; display: flex; align-items: center; justify-content: center; border: 2px solid; margin: 1em 0; padding: 1em;" data-pen-title="Test: html2canvas">
  <span>See the Pen <a href="https://codepen.io/7shi/pen/NWxYOMm">
  Test: html2canvas</a> by 七誌 (<a href="https://codepen.io/7shi">@7shi</a>)
  on <a href="https://codepen.io">CodePen</a>.</span>
</p>
<script async src="https://static.codepen.io/assets/embed/ei.js"></script>

↑ 左が撮影元の Element、右がそれを画像化したものです。内容はデザインでよく使われる [lorem ipsum](https://ja.wikipedia.org/wiki/Lorem_ipsum) と呼ばれるダミーテキストで、意味はありません。

シリーズの記事です。

1. [dom-to-imageを試す](https://qiita.com/7shi/items/771069479b91797b1fd6)
1. html2canvasを試す ← 今回の記事
1. [複数の画像を生成してローカルに保存](https://qiita.com/7shi/items/9d27e1a4911626e1fb8b)

# html2canvas

公式: <http://html2canvas.hertzen.com/>

驚異的な力技で実装されているようです。

* [動的コンテンツを画像化できるJSライブラリ "html2canvas" を使おう - KAYAC engineers' blog](https://techblog.kayac.com/html2canvas)

> `html2canvas`は、WebページのDOMやCSSを読み込み、その結果を元に解釈した結果をCanvasエレメント上に描画するライブラリです。 すなわち、実際にスクリーンショットを撮っているわけではなく、挙動としてはレンダリングエンジンに近いです。 （CSSの解釈はなんと1つ1つ実装されているので、作者は本当にすごいと思います）

# 利用方法

自前でどこかに置かなくても、[jsDelivr](https://www.jsdelivr.com/) 経由で参照できます。

```html
<script src="https://cdn.jsdelivr.net/npm/html2canvas@1.0.0-rc.5/dist/html2canvas.min.js"></script>
```

README のサンプルコードを元に async/await で書き換えます。

```javascript
(async () => {
  dst.appendChild(await html2canvas(src));
})();
```

# 動作結果

この記事の冒頭に貼ったサンプルのスクリーンショットを見ます。

Chrome では上に少し余白ができますが、文字のサイズはそのままで画像化されます。
![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/32057/2f0bd7cb-fa8c-05bf-0e63-13bd02d72192.png)
Firefox では文字のサイズが変わってしまうため、単語間のスペースが潰れたり文字が重なったりします。
![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/32057/383565a5-563d-8ae1-8fc9-9e7e7683a853.png)
撮影対象がブラウザに依存するのでなければ、Chrome で利用するのが無難なようです。

※ 手動ですが Firefox で Element を画像化する方法は[前回の記事](https://qiita.com/7shi/items/771069479b91797b1fd6)を参照してください。

# 参考

以下の記事では CDN にあるバージョンは古いとありますが、jsDelivr では npm に登録されている最新版が利用できます。

* [【2019年度版】JavaScriptでhtmlを画像化する方法(html2canvasの使い方) | ワクベク](https://wakubeku.com/?p=175)
