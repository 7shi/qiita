---
coediting: false
comments_count: 0
created_at: '2020-05-03T20:24:38+09:00'
id: 1f5c6a6561ef5c1e357b
likes_count: 0
private: false
reactions_count: 0
stocks_count: 0
tags:
- name: SVG
  versions: []
- name: PNG
  versions: []
- name: Wikipedia
  versions: []
title: WikipediaのSVG画像をPNGで取得
updated_at: '2020-07-07T21:12:05+09:00'
url: https://qiita.com/7shi/items/1f5c6a6561ef5c1e357b
slide: false
---

Wikipedia では SVG がよく使われます。画像を再利用する際、SVG のまま取得することも可能ですが、PNG に変換して保存する方法も用意されています。

※ この記事で想定しているのは元画像が SVG のものについてですが、JPEG でも同じ手順でリサイズした画像の取得は可能です。

# 記事から保存

記事のページでは SVG は PNG に変換して表示されています。記事のページから画像を保存すれば PNG となります。

# 別のサイズで保存

SVG は画像サイズが自由に変更可能ですが、PNG に変換するとサイズが固定されます。記事に表示されているよりも大きなサイズで保存する方法も用意されています。

1. 画像をクリックします。画像が広がります。
2. 右下の [詳細] をクリックします。<br>![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/32057/44c2c587-751d-152b-77d1-c086c2f1b819.png)
3. 各種サイズに変換された PNG へのリンクが表示されます。（下記引用の<font color="red">**赤字**</font>部分）

【例】 https://commons.wikimedia.org/wiki/File:Bitmap_VS_SVG.svg

> Size of this PNG preview of this SVG file: <font color="red">**512 × 327 pixels**</font>. Other resolutions: <font color="red">**320 × 204 pixels | 640 × 409 pixels | 800 × 511 pixels | 1,024 × 654 pixels | 1,280 × 818 pixels**</font>.
> Language select: [ ]
> Original file ‎(SVG file, nominally 512 × 327 pixels, file size: 3 KB)
> This image rendered as PNG in other widths: <font color="red">**200px, 500px, 1000px, 2000px**</font>.

詳細ページには画像のライセンスも書かれています。CC-BY や CC-BY-SA の場合、帰属表示が必要です。

* [Wikipedia:ライセンス更新 - Wikipedia](https://ja.wikipedia.org/wiki/Wikipedia:%E3%83%A9%E3%82%A4%E3%82%BB%E3%83%B3%E3%82%B9%E6%9B%B4%E6%96%B0)
* [Creative Commonsにおける「表示」ってめんどくさいけど、実際どうすればいいのか - ゆうれいパジャマβ](https://kuma.hateblo.jp/entry/20160628/1467053372)

# Firefox

Firefox の機能でスクリーンショットとしてダウンロードすることも一応できます。（一応というのは、普通の方法だと弾かれるため）

記事中の画像をクリックして画像が広がった状態では、PNG に変換した画像が表示されています。この画像を再度クリックすると、SVG での表示に切り替わります。

この状態で Firefox のスクリーンショット機能を使おうとしても「このページはスクリーンショットを撮れません。」として弾かれます。しかし他のキャプチャソフトを使わなくても、次のようにすれば回避できます。

1. 右クリック → 要素を調査
2. 開発ツールが表示される
3. 選択されているノードを右クリック → ノードのスクリーンショットを撮影
4. ダウンロードフォルダにスクリーンショットが生成

この方法だと日時に基づいたファイル名になります。元のファイル名を保持したい場合は、Wikipedia で変換した PNG を取得した方が手軽です。

※ 元々この方法をよく使っていたのですが、後で Wikipedia 自体に変換機能があることに気付きました。

なお、この方法は Element の画像化にも利用できます。

* [dom-to-imageを試す](https://qiita.com/7shi/items/771069479b91797b1fd6)
