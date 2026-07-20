---
coediting: false
comments_count: 0
created_at: '2014-08-27T13:38:35+09:00'
id: 622c322bd482b340038c
likes_count: 13
private: false
reactions_count: 0
stocks_count: 14
tags:
- name: JavaScript
  versions: []
- name: ECMAScript
  versions:
  - '6'
title: ECMAScript 6のyieldでコルーチン
updated_at: '2014-09-04T12:07:36+09:00'
url: https://qiita.com/7shi/items/622c322bd482b340038c
slide: false
---

ドラッグ＆ドロップをイベントドリブンで書くと処理が分断されます。コルーチンを使うことでシーケンシャルに書くテクニックがあります。ECMAScript 6のyieldを使って実装してみます。

【注】ECMAScript 6は策定中の仕様のため、ブラウザにより実装状況が異なります。今回はFirefox 31.0で動作確認を行いました。

* 参考 1: [function* - JavaScript | MDN](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/function*)
* 参考 2: [harmony:generators [ES Wiki]](http://wiki.ecmascript.org/doku.php?id=harmony:generators)

この記事には続編があります。

* [ECMAScript 6のyieldでコルーチン(2)](http://qiita.com/7shi/items/e9d65db80bfaa6adaa16)

この記事はF#版をベースに作成しました。

* [F#のシーケンスでコルーチン](http://qiita.com/7shi/items/29d10e74c8df30df04af)
* [F#のシーケンスでコルーチン(2)](http://qiita.com/7shi/items/78fa1d02730c7cd11786)

# コルーチンを使わない書き方

コルーチンを使わずにイベントドリブンで書いてみます。

⇒ [jsdo.itで動作確認](http://jsdo.it/7shi/77cx)

```html:DnDCoroutine.html
<!DOCTYPE html>
<html>
<head>
<title>DnD Coroutine</title>
</head>
<body>
<canvas id="canvas" width="300" height="300" style="border:solid 1px"></canvas>
<script type="application/javascript">
var canvas = document.getElementById("canvas");
var ctx = canvas.getContext("2d");

var rx = 10, ry = 10, rw = 40, rh = 40;
var startX, startY, startRX, startRY, dragging = false;

function paint() {
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    ctx.fillStyle = "red";
    ctx.fillRect(rx, ry, rw, rh);
}

paint();

function contains(rx, ry, rw, rh, x, y) {
    return rx <= x && x < rx + rw && ry <= y && y < ry + rh;
}

canvas.onmousedown = function(e) {
    var r = canvas.getBoundingClientRect();
    var ex = e.clientX - r.left, ey = e.clientY - r.top;
    if (!contains(rx, ry, rw, rh, ex, ey)) return;
    startX  = ex, startY  = ey;
    startRX = rx, startRY = ry;
    dragging = true;
    canvas.setCapture();
};

canvas.onmousemove = function(e) {
    if (!dragging) return;
    var r = canvas.getBoundingClientRect();
    var ex = e.clientX - r.left, ey = e.clientY - r.top;
    rx = startRX + ex - startX;
    ry = startRY + ey - startY;
    paint();
};

canvas.onmouseup = function(e) {
    if (!dragging) return;
    dragging = false;
    canvas.releaseCapture();
};
</script>
</body>
</html>
```

状態を変数に入れてmousedown, mousemove, mouseupを別々に処理します。

# コルーチンをサポートするクラス

イベントが発生するたびにジェネレータから値を読み取ることで処理を継続することができます（値は使わないため無視しています）。このように中断されることを前提とした関数のようなものをコルーチンと呼びます。

ドラッグ＆ドロップに特化したサポートクラスを作ります。

```js
function DnDCoroutine(target) {
    var dndc = this, gen;
    dndc.x = 0;
    dndc.y = 0;
    dndc.isDragging = false;
    function setXY(e) {
        var r = target.getBoundingClientRect();
        dndc.x = e.clientX - r.left;
        dndc.y = e.clientY - r.top;
    }
    target.addEventListener("mousedown", function(e) {
        setXY(e);
        gen = dndc.coroutine(dndc.x, dndc.y);
        dndc.isDragging = !gen.next().done;
    });
    target.addEventListener("mousemove", function(e) {
        setXY(e);
        if (dndc.isDragging) {
            dndc.isDragging = !gen.next().done;
        }
    });
    target.addEventListener("mouseup", function(e) {
        setXY(e);
        if (dndc.isDragging) {
            dndc.isDragging = false;
            gen.next();
        }
    });
}
```

`done`はジェネレータから抜けたかどうかを調べるフラグです。Firefox独自実装の`yield`では例外を返していましたが、ECMAScript 6では仕様が変わりました。

* 参考 3: [Firefoxで使える2つのyieldの挙動の違いについて](http://qiita.com/takashi/items/bcef8f9c313b1e6eac52)

これを使って書き直すと次のようになります。

⇒ [jsdo.itで動作確認](http://jsdo.it/7shi/5fJ4)

```js
var canvas = document.getElementById("canvas");
var ctx = canvas.getContext("2d");

var rx = 10, ry = 10, rw = 40, rh = 40;

function paint() {
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    ctx.fillStyle = "red";
    ctx.fillRect(rx, ry, rw, rh);
}

paint();

function contains(rx, ry, rw, rh, x, y) {
    return rx <= x && x < rx + rw && ry <= y && y < ry + rh;
}

var dndc = new DnDCoroutine(canvas);
dndc.coroutine = function*(startX, startY) {
    if (!contains(rx, ry, rw, rh, startX, startY)) return;
    canvas.setCapture();
    var startRX = rx, startRY = ry;
    while ((yield 0), dndc.isDragging) {
        rx = startRX + dndc.x - startX;
        ry = startRY + dndc.y - startY;
        paint();
    }
    canvas.releaseCapture();
};
```

マウスを押し下げてから離すまでの処理が一連の流れで書けるようになりました。

`yield`で処理を中断して新しいイベントを待ちます。`yield`の値は特に使っていないので`0`には意味がありません。ドラッグが終わればループから抜けて`canvas.releaseCapture()`が実行されます。
