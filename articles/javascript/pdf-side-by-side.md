---
coediting: false
comments_count: 0
created_at: '2022-10-11T22:14:51+09:00'
id: 6daf22b6929d6187a22a
likes_count: 0
private: false
reactions_count: 0
stocks_count: 2
tags:
- name: HTML
  versions: []
- name: JavaScript
  versions: []
- name: PDF
  versions: []
title: ブラウザ内にPDFを並べて表示
updated_at: '2022-10-11T22:17:28+09:00'
url: https://qiita.com/7shi/items/6daf22b6929d6187a22a
slide: false
---

リモートで画面共有しながら説明する際に複数のPDFを並べる必要がありました。

ブラウザ内に表示させたかったので HTML を書いてみました。

# スプリッター

サイズ調整したかったので既存のライブラリを使用しました。

* https://split.js.org/

今回は CDN 経由で利用します。

* https://cdnjs.com/libraries/split.js

# HTML

必要最低限の内容を示します。

```html
<!DOCTYPE html>
<html lang="ja" style="height:100%">
<head>
    <meta charset="utf-8">
    <title>PDF</title>
    <style>
        .gutter { background-color: #eee; }
        .gutter.gutter-vertical { cursor: row-resize; }
    </style>
</head>
<body style="height:100%; margin:0; padding:0">
    <script src="https://cdnjs.cloudflare.com/ajax/libs/split.js/1.6.5/split.min.js"></script>
    <div class="split" style="height:100%">
        <div id="split-0">
            <embed src="1.pdf" type="application/pdf" style="width:100%; height:100%">
        </div>
        <div id="split-1">
            <embed src="2.pdf" type="application/pdf" style="width:100%; height:100%">
        </div>
        <div id="split-2">
            <embed src="3.pdf" type="application/pdf" style="width:100%; height:calc(100% - 8px)">
        </div>
    </div>
    <script>
        Split(["#split-0", "#split-1", "#split-2"], { direction: "vertical", minSize: 10 });
    </script>
</body>
</html>
```

`height:calc(100% - 8px)` で無駄なスクロールバーが出ないように微調整しています。
