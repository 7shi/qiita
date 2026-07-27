---
coediting: false
comments_count: 0
created_at: '2020-07-09T01:57:11+09:00'
id: 9d27e1a4911626e1fb8b
likes_count: 3
private: false
reactions_count: 0
stocks_count: 3
tags:
- name: JavaScript
  versions: []
- name: XMLHttpRequest
  versions: []
title: 複数の画像を生成してローカルに保存
updated_at: '2020-07-09T13:54:33+09:00'
url: https://qiita.com/7shi/items/9d27e1a4911626e1fb8b
slide: false
---

HTML 要素を画像化した複数のファイルをローカルの専用サーバーに送って保存します。

シリーズの記事です。

1. [dom-to-imageを試す](https://qiita.com/7shi/items/771069479b91797b1fd6)
1. [html2canvasを試す](https://qiita.com/7shi/items/ba7089e864fefac69808)
1. 複数の画像を生成してローカルに保存 ← 今回の記事

# ライブラリ

前回まで同じ目的の2つのライブラリを比較しました。どちらも Firefox では文字サイズが変わってレイアウトが崩れるため、今回は Chrome を前提に進めます。

テキストだけを含む要素の画像化ではどちらを使ってもほとんど差がありませんでした。XMLHttpRequest でファイルを送るには Blob に変換する必要があるため、その機能をサポートしている dom-to-image を使用します。

HTML 要素を画像化した Blob の生成は簡単にできます。

```javascript
let blob = await domtoimage.toBlob(src);
```

# サーバー

以下の記事で作ったファイルを受け取るサーバー (server.ts) を使用します。

* [簡易HTTPサーバーでブラウザからファイルの入出力を試す](https://qiita.com/7shi/items/5b3304b4419ae80e650e)

ファイルを受け取りたいディレクトリで server.ts を起動して待ち受けます。

# スクリプト

画像を生成するための描画は済んでいるという前提で、送信に関係するコードを示します。

## log

コンソールを模した `div` にログを出力します。

```javascript
function log(str) {
  result.appendChild(document.createTextNode(str));
  result.appendChild(document.createElement("br"));
}
```

以下の記事のコードを簡略化したものです。

* [divに対してconsole.logのようなことをする](https://qiita.com/7shi/items/ca174dac3af8235c5bd2)

## XMLHttpRequest

XMLHttpRequest を Promise 化します。

```javascript
function send(method, url, blob) {
  log(`${method} ${url}`);
  return new Promise((resolve, reject) => {
    let req = new XMLHttpRequest();
    req.open(method, url);
    req.onload = () => {
      let result = `${req.status} ${req.response}`;
      if (req.status == 200) {
        log(result);
        resolve();
      } else {
        reject(result);
      }
    };
    req.onerror = () => reject("error");
    req.onabort = () => reject("abort");
    req.ontimeout = () => reject("timeout");
    req.send(blob);
  });
}
```

正常終了は `resolve`、エラーは `reject` を呼びます。

4種類のコールバックをチェックしているのは、以下の記事を参考にしました。

* [【メモ】XMLHttpRequestのイベントについて](https://qiita.com/ShinyaKato/items/64b6726c361f5377b0f3)

> 以下の4つのイベントは同時に発火することがありません
> 
> * onload
> * onerror
> * onabort
> * ontimeout
> 
> よって、**4つ全て指定しないと通信の終了を取りこぼす可能性があります**

## 送信

画像の Blob を XMLHttpRequest で送信します。画像をすべて送信したら、サーバーを終了させます。

```javascript
try {
  result.innerHTML = "";
  for (let [i, src] of sources) {
    let blob = await domtoimage.toBlob(src);
    await send("POST", `http://127.0.0.1:8080/${i}.png`, blob);
  }
  await send("GET", "http://127.0.0.1:8080/end");
} catch (e) {
  log(e);
  log("Aborted.");
}
```

成功した時の状況です。

```text:クライアント側（ブラウザ）
POST http://127.0.0.1:8080/0.png
200 <m>created</m>
POST http://127.0.0.1:8080/1.png
200 <m>created</m>
POST http://127.0.0.1:8080/2.png
200 <m>created</m>
POST http://127.0.0.1:8080/3.png
200 <m>created</m>
POST http://127.0.0.1:8080/4.png
200 <m>created</m>
GET http://127.0.0.1:8080/end
200 <m>bye!</m>
```
```text:サーバー側
$ deno run --allow-net --allow-read --allow-write server.ts
http://127.0.0.1:8080
127.0.0.1 OPTIONS /0.png
127.0.0.1 POST /0.png
0.png 18321 created
127.0.0.1 OPTIONS /1.png
127.0.0.1 POST /1.png
1.png 18537 created
127.0.0.1 OPTIONS /2.png
127.0.0.1 POST /2.png
2.png 18706 created
127.0.0.1 OPTIONS /3.png
127.0.0.1 POST /3.png
3.png 18573 created
127.0.0.1 OPTIONS /4.png
127.0.0.1 POST /4.png
4.png 18562 created
127.0.0.1 GET /end
```

ローカルで閉じた通信です。サーバーを起動したディレクトリには受信したファイルがあります。

```text
$ ls
0.png  1.png  2.png  3.png  4.png
```

# サンプル

文章の選択個所を変えた画像を生成するサンプルです。

* https://codepen.io/7shi/pen/YzwLKmv

[Send to Local] を実行するには、server.ts を起動しておく必要があります。

# 感想

ブラウザを画像生成のエンジンとして使えるようになったので、文字中心のコンテンツを動画化するのに威力を発揮しそうです。一部の色を変えるような単純な効果でも、手動だと大変でしたが、自動化できれば大幅に省力化できます。

以前書いた記事では連続画像を効果的に生成する方法がないため紙芝居レベルに留まっていましたが、今回の方法を応用すれば動きを付けることもできそうです。

* [紙芝居方式で動画を作成](https://qiita.com/7shi/items/9a4f2220cfde4fbbdce7)
