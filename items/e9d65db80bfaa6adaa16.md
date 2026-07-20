---
coediting: false
comments_count: 0
created_at: '2014-09-04T10:44:08+09:00'
id: e9d65db80bfaa6adaa16
likes_count: 10
private: false
reactions_count: 0
stocks_count: 8
tags:
- name: JavaScript
  versions: []
- name: ECMAScript
  versions:
  - '6'
title: ECMAScript 6のyieldでコルーチン(2)
updated_at: '2014-09-04T12:05:08+09:00'
url: https://qiita.com/7shi/items/e9d65db80bfaa6adaa16
slide: false
---

ドラッグ＆ドロップをイベントドリブンで書くと処理が分断されます。コルーチンを使うことでシーケンシャルに書くテクニックがあります。ECMAScript 6のyieldを使って実装してみます。

【注】ECMAScript 6は策定中の仕様のため、ブラウザにより実装状況が異なります。今回はFirefox 31.0で動作確認を行いました。

* 参考 1: [function* - JavaScript | MDN](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/function*)
* 参考 2: [harmony:generators [ES Wiki]](http://wiki.ecmascript.org/doku.php?id=harmony:generators)

この記事は以下の続編です。

* [ECMAScript 6のyieldでコルーチン](http://qiita.com/7shi/items/622c322bd482b340038c)

今回は表示されている四角形をリサイズできるように拡張します。

この記事はF#版をベースに作成しました。

* [F#のシーケンスでコルーチン](http://qiita.com/7shi/items/29d10e74c8df30df04af)
* [F#のシーケンスでコルーチン(2)](http://qiita.com/7shi/items/78fa1d02730c7cd11786)

# コルーチンを使わない書き方

コルーチンを使わずにイベントドリブンで書いてみます。

⇒ [jsdo.itで動作確認](http://jsdo.it/7shi/jnOj)

```html:DnDCoroutine2.html
<!DOCTYPE html>
<html>
<head>
<title>DnD Coroutine 2</title>
</head>
<body>
<canvas id="canvas" width="300" height="300" style="border:solid 1px"></canvas>
<script type="application/javascript">
var canvas = document.getElementById("canvas");
var ctx = canvas.getContext("2d");

var Pos = { "Out": 0, "Low": 1, "In": 2, "High": 3 };
var thres = 3;

function getpos(v, l, h) {
    if (Math.abs(l - v) < thres) {
        return Pos.Low;
    } else if (Math.abs(h - v) < thres) {
        return Pos.High;
    } else if (l < v && v < h) {
        return Pos.In;
    } else {
        return Pos.Out;
    }
}

var rx = 10, ry = 10, rw = 40, rh = 40;
var startX, startY, startRX, startRY, startRW, startRH, dragging = false;
var horz = Pos.Out, vert = Pos.Out;

function paint() {
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    ctx.fillStyle = "red";
    ctx.fillRect(rx, ry, rw, rh);
}

paint();

canvas.onmousedown = function(e) {
    if (horz == Pos.Out || vert == Pos.Out) return;
    var r = canvas.getBoundingClientRect();
    startX = e.clientX - r.left;
    startY = e.clientY - r.top;
    startRX = rx, startRY = ry, startRW = rw, startRH = rh;
    dragging = true;
    canvas.setCapture();
};

canvas.onmousemove = function(e) {
    var r = canvas.getBoundingClientRect();
    var ex = e.clientX - r.left, ey = e.clientY - r.top;
    if (!dragging) {
        horz = getpos(ex, rx, rx + rw);
        vert = getpos(ey, ry, ry + rh);
        var cur = "";
        if (vert == Pos.In && horz == Pos.In) {
            cur = "move";
        } else if (vert != Pos.Out && horz != Pos.Out) {
            if (vert == Pos.Low ) cur  = "n";
            if (vert == Pos.High) cur  = "s";
            if (horz == Pos.Low ) cur += "w";
            if (horz == Pos.High) cur += "e";
            cur += "-resize";
        }
        if (canvas.style.cursor != cur) canvas.style.cursor = cur;
    } else {
        var inside = vert == Pos.In && horz == Pos.In;
        var dx = ex - startX, dy = ey - startY;
        rx = horz == Pos.Low || inside ? startRX + dx : startRX;
        ry = vert == Pos.Low || inside ? startRY + dy : startRY;
        rw = horz == Pos.Low ? startRW - dx : horz == Pos.High ? startRW + dx : startRW;
        rh = vert == Pos.Low ? startRH - dy : vert == Pos.High ? startRH + dy : startRH;
        if (rw <= 0) rx += rw, rw = Math.max(1, -rw);
        if (rh <= 0) ry += rh, rh = Math.max(1, -rh);
        paint();
    }
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

リサイズ中にサイズがマイナスになった場合、位置を調整してサイズがプラスになるように細工しています。

# コルーチンをサポートするクラス

イベントが発生するたびにジェネレータから値を読み取ることで処理を継続することができます（値は使わないため無視しています）。このように中断されることを前提とした関数のようなものをコルーチンと呼びます。

ドラッグ＆ドロップに特化したサポートクラスを作ります。ボタンを押す前と押した後のmousemoveを別枠で扱えるようにしています。

```js
function DnDCoroutine(target) {
    var dndc = this, gen = null;
    dndc.x = 0;
    dndc.y = 0;
    dndc.isDragging = false;
    function next(e) {
        var r = target.getBoundingClientRect();
        dndc.x = e.clientX - r.left;
        dndc.y = e.clientY - r.top;
        if (gen != null && gen.next().done) gen = null;
    }
    target.addEventListener("mousedown", function(e) {
        dndc.isDragging = true;
        next(e);
    });
    target.addEventListener("mousemove", function(e) {
        if (!dndc.isDragging && gen == null)
            gen = dndc.coroutine();
        next(e);
    });
    target.addEventListener("mouseup", function(e) {
        dndc.isDragging = false;
        next(e);
    });
}
```

`done`はジェネレータから抜けたかどうかを調べるフラグです。Firefox独自実装の`yield`では例外を返していましたが、ECMAScript 6では仕様が変わりました。

* 参考 3: [Firefoxで使える2つのyieldの挙動の違いについて](http://qiita.com/takashi/items/bcef8f9c313b1e6eac52)

これを使って書き直すと次のようになります。

⇒ [jsdo.itで動作確認](http://jsdo.it/7shi/bbE2)

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

var dndc = new DnDCoroutine(canvas);
dndc.coroutine = function*() {
    var horz = Pos.Out, vert = Pos.Out;
    for (; !dndc.isDragging; yield 0) {
        horz = getpos(dndc.x, rx, rx + rw);
        vert = getpos(dndc.y, ry, ry + rh);
        var cur = "";
        if (vert == Pos.In && horz == Pos.In) {
            cur = "move";
        } else if (vert != Pos.Out && horz != Pos.Out) {
            if (vert == Pos.Low ) cur  = "n";
            if (vert == Pos.High) cur  = "s";
            if (horz == Pos.Low ) cur += "w";
            if (horz == Pos.High) cur += "e";
            cur += "-resize";
        }
        if (canvas.style.cursor != cur) canvas.style.cursor = cur;
    }
    if (horz == Pos.Out || vert == Pos.Out) return;
    var inside = vert == Pos.In && horz == Pos.In;
    startX = dndc.x, startY = dndc.y;
    startRX = rx, startRY = ry, startRW = rw, startRH = rh;
    canvas.setCapture();
    for (; dndc.isDragging; yield 0) {
        var dx = dndc.x - startX, dy = dndc.y - startY;
        rx = horz == Pos.Low || inside ? startRX + dx : startRX;
        ry = vert == Pos.Low || inside ? startRY + dy : startRY;
        rw = horz == Pos.Low ? startRW - dx : horz == Pos.High ? startRW + dx : startRW;
        rh = vert == Pos.Low ? startRH - dy : vert == Pos.High ? startRH + dy : startRH;
        if (rw <= 0) rx += rw, rw = Math.max(1, -rw);
        if (rh <= 0) ry += rh, rh = Math.max(1, -rh);
        paint();
    }
    canvas.releaseCapture();
};
```

`yield`で処理を中断して新しいイベントを待ちます。`yield`の値は特に使っていないので`0`には意味がありません。ドラッグが終わればループから抜けて`canvas.releaseCapture()`が実行されます。

以下の3つの状態が一連の流れで書けるようになりました。

1. ボタンが押されていない状態。マウスの位置に応じてカーソルの形を変える。
2. ボタンが押された瞬間。ドラッグ開始の初期設定をする。
3. ボタンを押されている状態。リサイズや移動を行う。

一応作ってはみたものの、1と2,3を分離した方が良いような気もします。まだ工夫の余地があります。
