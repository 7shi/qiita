---
coediting: false
comments_count: 0
created_at: '2020-07-07T20:51:49+09:00'
id: 771069479b91797b1fd6
likes_count: 14
private: false
reactions_count: 0
stocks_count: 11
tags:
- name: JavaScript
  versions: []
title: dom-to-imageを試す
updated_at: '2020-10-02T23:40:37+09:00'
url: https://qiita.com/7shi/items/771069479b91797b1fd6
slide: false
---

HTML の Element を画像に変換するライブラリ dom-to-image を試しました。Chrome では良好ですが、Firefox では文字のサイズが変わってはみ出すようです。

<p class="codepen" data-height="310" data-theme-id="light" data-default-tab="result" data-user="7shi" data-slug-hash="QWymMyO" style="height: 310px; box-sizing: border-box; display: flex; align-items: center; justify-content: center; border: 2px solid; margin: 1em 0; padding: 1em;" data-pen-title="Test: dom-to-image">
  <span>See the Pen <a href="https://codepen.io/7shi/pen/QWymMyO">
  Test: dom-to-image</a> by 七誌 (<a href="https://codepen.io/7shi">@7shi</a>)
  on <a href="https://codepen.io">CodePen</a>.</span>
</p>
<script async src="https://static.codepen.io/assets/embed/ei.js"></script>

↑ 左が撮影元の Element、右がそれを画像化したものです。内容はデザインでよく使われる [lorem ipsum](https://ja.wikipedia.org/wiki/Lorem_ipsum) と呼ばれるダミーテキストで、意味はありません。

シリーズの記事です。

1. dom-to-imageを試す ← 今回の記事
1. [html2canvasを試す](https://qiita.com/7shi/items/ba7089e864fefac69808)
1. [複数の画像を生成してローカルに保存](https://qiita.com/7shi/items/9d27e1a4911626e1fb8b)

# dom-to-image

リポジトリ: [tsayen/dom-to-image: Generates an image from a DOM node using HTML5 canvas](https://github.com/tsayen/dom-to-image)

画像に変換する方法は README に説明があります。DeepL で翻訳したものに手を加えて引用します。

> このライブラリは SVG の `<foreignObject>` タグの中に任意の HTML コンテンツを入れることができる機能を使っています。そして、その DOM ノードをレンダリングするためには、以下の手順を踏む必要があります。
> 
> 1. 元の DOM ノードを再帰的にクローン
> 
> 1. ノードと各サブノードのスタイルを計算して、対応するクローンにコピー
>   * 疑似要素の再作成を忘れないでください。それらはどのような方法でもクローンされません。
> 
> 1. ウェブフォントを埋め込む
>   * ウェブフォントを表す可能性のある `@font-face` 宣言をすべて探す
>   * ファイルの URL を解析して、対応するファイルをダウンロード
>   * base64 エンコードして、コンテンツを `data:` で表される URL としてインライン化
>   * 処理されたすべての CSS ルールを連結して1つの `<style>` 要素にまとめ、それをクローンにアタッチ
> 
> 1. 画像を埋め込む
>   * `<img>` 要素に画像 URL を埋め込む
>   * CSS の `background` プロパティで使用される画像を、フォントと同様の方法でインライン化
> 
> 1. クローンされたノードを XML にシリアライズ
> 
> 1. XML を `<foreignObject>` タグにラップして SVG に入れて、データ URL を作成
> 
> 1. オプションで、PNG コンテンツや生のピクセルデータを Uint8Array として取得するには、SVG をソースとして Image 要素を作成して、オフスクリーンで Canvas を作成してレンダリングし、Canvas からコンテンツを読み込む。
> 
> 1. 完成！

以下の記事ではライブラリを用いずにこの方法を説明しています。

* [一発芸！SVGでHTMLを画像化する](https://qiita.com/haribote/items/b17d46b9679ce2fb2712)

# 利用方法

自前でどこかに置かなくても、[jsDelivr](https://www.jsdelivr.com/) 経由で参照できます。

```html
<script src="https://cdn.jsdelivr.net/npm/dom-to-image@2.6.0/dist/dom-to-image.min.js"></script>
```

README のサンプルコードを元に async/await で書き換えます。

```javascript
(async () => {
  try {
    let img = new Image();
    img.src = await domtoimage.toPng(src);
    dst.appendChild(img);
  } catch (e) {
    console.error("oops, something went wrong!", e);
  }
})();
```

# 動作結果

この記事の冒頭に貼ったサンプルのスクリーンショットを見ます。

Chrome では下に少し余白ができますが、文字のサイズはそのままで画像化されます。
![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/32057/be129574-7c0b-bcb1-b6b8-2eea65cf3c6e.png)

Firefox では文字のサイズが変わってしまうため、画像からはみ出してしまいます。
![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/32057/11fae41f-eea6-d217-d254-8e2e93dfcf39.png)
撮影対象がブラウザに依存するのでなければ、Chrome で利用するのが無難なようです。

# Firefox

手動になってしまいますが、Firefox では対象の Element の右クリックで画像化できます。

1. 右クリック → 要素を調査
2. 開発ツールが表示される
3. 選択されているノードを右クリック → ノードのスクリーンショットを撮影
4. ダウンロードフォルダにスクリーンショットが生成

※ dom-to-image は自動化にメリットがあるとは思いますが…

なお、この方法は SVG の画像化にも利用できます。

* [WikipediaのSVG画像をPNGで取得](https://qiita.com/7shi/items/1f5c6a6561ef5c1e357b)

# 参考

dom-to-image は以下の記事で知りました。

* [DOMをPNGに変換してリサイズしてからダウンロードする](https://qiita.com/ayatas/items/c2d2d24e9a8118b928fb)
