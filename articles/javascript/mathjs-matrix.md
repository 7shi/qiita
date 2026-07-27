---
coediting: false
comments_count: 0
created_at: '2022-10-27T04:17:59+09:00'
id: e75fa610f24a3350b260
likes_count: 1
private: false
reactions_count: 0
stocks_count: 1
tags:
- name: JavaScript
  versions: []
- name: 行列
  versions: []
- name: math.js
  versions: []
- name: Deno
  versions: []
title: Math.js で行列計算
updated_at: '2022-10-28T23:35:46+09:00'
url: https://qiita.com/7shi/items/e75fa610f24a3350b260
slide: false
---

JavaScript で 6 元連立方程式を大量に解く必要があったので Math.js を試しました。Deno での利用についても触れます。

* [math.js | an extensive math library for JavaScript and Node.js](https://mathjs.org/)

※ Python の numpy や sympy を使うなら情報も多くて簡単ですが、方程式が必要になったコードの他の部分は Deno で書いていたこともあって JavaScript でやってみました。

# Node.js

[ダウンロードページ](https://mathjs.org/download.html)に書いてあるように配布物が 1 ファイルにまとめられているので、npm ではなくそちらを使います。

* https://unpkg.com/mathjs@11.3.2/lib/browser/math.js

まずは感触をつかむため REPL で使ってみます。

math.js をダウンロードして置いたディレクトリで Node.js を起動して、行列の計算をします。

```javascript
> math = require("./math.js")
（略）
> x=[[1,2],[3,4]]
[ [ 1, 2 ], [ 3, 4 ] ]
> y=[5,6]
[ 5, 6 ]
> math.multiply(x,y)
[ 17, 39 ]
```
```math
x=\begin{pmatrix}1&2\\3&4\end{pmatrix},
\ y=\begin{pmatrix}5\\6\end{pmatrix},
\ xy=\begin{pmatrix}17\\39\end{pmatrix}
```

※ 演算子のオーバーロードができないため `x * y` のような書き方はできません。

# メソッドチェーン

プロトタイプが拡張されたわけではないので、`x.multiply(y)` のようにメソッドを呼ぶことはできません。

その代わり `chain` ～ `done` で挟めばメソッドチェーンが使えます。

```javascript
> math.chain(x).multiply(y).done()
[ 17, 39 ]
```

簡単な計算だと冗長なだけですが、ある程度長くなればメリットがありそうです。

比較のため両方の書き方で同じ計算をしてみます。

```javascript
> math.multiply(math.transpose(math.multiply(x,y)),math.inv(x))
[ 24.5, -2.5 ]
> math.chain(x).multiply(y).transpose().multiply(math.inv(x)).done()
[ 24.5, -2.5 ]
```
```math
(xy)^\top x^{-1}=\begin{pmatrix}24.5\\-2.5\end{pmatrix}
```

※ ベクトルは自動的に転置されるため、コードでは転置を省略できます。

```javascript
> math.multiply(math.multiply(x, y), math.inv(x))
[ 24.5, -2.5 ]
> math.chain(x).multiply(y).multiply(math.inv(x)).done()
[ 24.5, -2.5 ]
```

REPL で `math.` まで書いて [Tab] で候補を出して、気になったメソッドをドキュメントで確認すれば良さそうです。

# 連立方程式

連立方程式を解くには行列で書き直します。

```math
\left\{
\begin{array}{l}
3x+2y=2 \\
4x+3y=3
\end{array}
\right.
\quad\rightarrow\quad
\begin{pmatrix}3&2\\4&3\end{pmatrix}
\begin{pmatrix}x\\y\end{pmatrix}
=\begin{pmatrix}2\\3\end{pmatrix}
```

両辺に左側から係数の逆行列を掛けることで解が求まります。

```math
\begin{pmatrix}x\\y\end{pmatrix}
=\begin{pmatrix}3&2\\4&3\end{pmatrix}^{-1}
 \begin{pmatrix}2\\3\end{pmatrix}
=\begin{pmatrix}0\\1\end{pmatrix}
```

これをコードで計算します。

```javascript
> math.chain([[3,2],[4,3]]).inv().multiply([2,3]).done()
[ 0, 1 ]
```

なお、今回の調査の目的だった 6 元連立方程式は、行列のサイズを大きくするだけで計算できました。

https://qiita.com/7shi/items/700dc16d9dca40afbe99

# Deno

Deno を認識して Node.js 互換周りの面倒を見てくれる CDN があり、そのうち 1 つの [esm.sh](https://esm.sh/) 経由で読み込みます。

```javascript
> import * as math from "https://esm.sh/mathjs@11.3.2/"
undefined
> math.chain([[3,2],[4,3]]).inv().multiply([2,3]).done()
[ 0, 1 ]
```


## 試行錯誤

参考までに、試行錯誤の過程を残しておきます。

ドキュメントには `import` する例が載っています。

* https://mathjs.org/docs/getting_started.html

```javascript
import { sqrt } from 'mathjs'

console.log(sqrt(-4).toString()) // 2i
```

Deno の REPL で試すとエラーになりました。

```javascript
> import { sqrt } from "./math.js"
Uncaught TypeError: Cannot set properties of undefined (setting 'math')
    at file:///mnt/c/Users/7shi/Desktop/%E4%BD%9C%E6%A5%AD%E4%B8%AD/tts/gismu/node/math.js:2:184
    at file:///mnt/c/Users/7shi/Desktop/%E4%BD%9C%E6%A5%AD%E4%B8%AD/tts/gismu/node/math.js:2:189
```

math.js は Babel で生成された読むのに適さないコードです。整形して最初の部分を見ると、環境ごとにエクスポート先を選んでいる部分でエラーになっています。

```javascript:整形したコード
!function (e,t) {
  "object" == typeof exports && "object" == typeof module
  ? module.exports = t()
  : "function" == typeof define && define.amd
    ? define([], t)
    : "object" == typeof exports
      ? exports.math = t()
      : e.math = t() // ここでエラー
}(this, (() => (() => {
```

`exports` というオブジェクトを用意するだけでうまくいきました。

```javascript
> const exports={}
undefined
> import "./math.js"
Module {}
> exports.math.sqrt(4)
2
```

モジュールとしてインポートしたわけではなく、`exports.math = t()` によってライブラリが詰め込まれた状態です。

かなり無理やりな方法で、しかも REPL でしか通用しません。コードをファイルに書くと名前空間が分離されるため、ダミーで用意した `exports` が見付けられなくなります。

## 互換モード

Deno には Node.js の互換モードがあったようです。

* [Deno v1.15で導入されたNode.js互換モードについて](https://zenn.dev/uki00a/articles/node-compat-mode-introduced-in-deno-v1-15)

互換モードは既に削除されたとのことですが、Deno をサポートした CDN 経由で読み込む方法が紹介されています。

> 例えば、[esm.sh](https://github.com/alephjs/esm.sh)や[Skypack](https://www.skypack.dev/)などのCDNは、Node.jsの組み込みモジュールの読み込みを検出すると、自動的に`deno_std/node`を読み込むように置換してくれます。

esm.sh 経由でモジュールを読み込むとすんなり動きました。これが最初に紹介した方法です。

Deno が npm をサポートしたのもつい最近だったと思いましたが、それとは別に CDN 側でも Deno 対応が進んでいるのは驚きました。

* [【Deno】「やっぱnpmをサポートするわ」 → 10日後「サポートしたわ」 - Qiita](https://qiita.com/rana_kualu/items/7eb1acff8f66948b04eb)
