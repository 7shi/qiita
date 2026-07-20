---
coediting: false
comments_count: 2
created_at: '2020-02-15T22:45:34+09:00'
id: 8219dcc22950253b26fb
likes_count: 4
private: false
reactions_count: 0
stocks_count: 5
tags:
- name: JavaScript
  versions: []
- name: XorShift
  versions: []
title: Xorshiftなどの擬似乱数をプロットして比較してみた
updated_at: '2022-11-06T13:38:57+09:00'
url: https://qiita.com/7shi/items/8219dcc22950253b26fb
slide: false
---

Xorshift で得られた乱数が適度にばらけているか視覚的に確認するため、平面に分布をプロットしました。

比較のためアルゴリズムが選べるようにしましたが、残念ながら違いは感じられませんでした。

<p class="codepen" data-height="308" data-theme-id="dark" data-default-tab="js,result" data-user="7shi" data-slug-hash="wvaMWBN" style="height: 308px; box-sizing: border-box; display: flex; align-items: center; justify-content: center; border: 2px solid; margin: 1em 0; padding: 1em;" data-pen-title="Xorshift32">
  <span>See the Pen <a href="https://codepen.io/7shi/pen/wvaMWBN">
  Xorshift32</a> by 七誌 (<a href="https://codepen.io/7shi">@7shi</a>)
  on <a href="https://codepen.io">CodePen</a>.</span>
</p>
<script async src="https://static.codepen.io/assets/embed/ei.js"></script>

↑ エラーになる場合は一度 [CodePen](https://codepen.io/) を開いてから、この記事をリロードしてください。

この記事には Haskell 版があります。

* [Xorshiftを移植してみた](https://qiita.com/7shi/items/0e2951155fd8949dbc55)

# 実装

Xorshift は実装が簡単な割に良好な擬似乱数を生成します。

* [Xorshift - Wikipedia](https://ja.wikipedia.org/wiki/Xorshift)
* [論文翻訳: Xorshift RNGs - MOXBOX](https://hazm.at/mox/algorithm/pseudorandom-number/xorshift-rngs/index.html)
* [Google Chromeが採用した、擬似乱数生成アルゴリズム「xorshift」の数理 – びりあるの研究ノート](https://blog.visvirial.com/articles/575)
* [Xorshiftをざっくり理解する | Blog](https://kanamesasaki.github.io/blog/20220128-xorshift/)

JavaScript で実装します。

```javascript
const [XSgetSeed, XSgetNext, XSrand] = (() => {
  const m = 2 ** 32;
  const XSgetSeed = () => Math.floor(Math.random() * (m - 1)) + 1;
  const s = Uint32Array.of(XSgetSeed());
  function XSgetNext(seed) {
    if (seed !== undefined) s[0] = seed;
    s[0] ^= s[0] << 13;
    s[0] ^= s[0] >>> 17;
    s[0] ^= s[0] << 5;
    return s[0];
  }
  return [XSgetSeed, XSgetNext, (seed) => XSgetNext(seed) / m];
})();
```

* 計算結果を符号なし整数で格納するため 1 要素の TypedArray を使用しました。
* 右シフトを符号なしで行うため `>>>` を使用しました。（[コメント欄](#comment-49398363005b9c56c868)でご教示いただきました）
* 引数でシード値が指定できるようにしました。指定しなければ保持していた値を使います。初期値は JavaScript 組み込みの乱数から得ます。
* `XSrand` は `Math.random` と同じ使い方ができるように結果を 0 以上 1 未満の浮動小数点数で返します。
* シフト回数の組み合わせは複数あります。このコードで使用している 13, 17, 5 は原著論文で例として使われていた組み合わせです。他の記事では 13, 17, 15 もよく使われますが、どちらも動作します。

# Math.random

`Math.random` ではシード値が指定できません。

* [Math.random() - JavaScript | MDN](https://developer.mozilla.org/ja/docs/Web/JavaScript/Reference/Global_Objects/Math/random)

> 実装側で乱数生成アルゴリズムの初期シードを選択し、ユーザーが初期シードを選択、またはリセットすることは出来ません。

シード値が必要な場合に Xorshift は手軽な代替手段となるでしょう。

# 線形合同法

従来用いられていた単純なアルゴリズムです。

* [線形合同法 - Wikipedia](https://ja.wikipedia.org/wiki/%E7%B7%9A%E5%BD%A2%E5%90%88%E5%90%8C%E6%B3%95)

> Stephen K. Park と Keith W. Miller が、彼らのサーベイ中で「最低基準」として示したもので、より良い選択肢が無いのならば、自作などせずにこれを使うべしというもの。
> 
> ```math
> X_{n+1}=\left(48,271\times X_{n}\right)\ {\bmod {\ }}(2^{31}-1)
> ```

> 4\. [comp.lang.c FAQ list · Question 13.15](http://c-faq.com/lib/rand.html) ただしソースコードでは乗数が 16807 になっているので注意すること。48271 を使ったほうが（もしかしたら計算がわずかに重くなるかもしれないが）少し良い乱数列になる。ソースコード中のその数の部分を書き換えるだけでよい。

これを JavaScript に移植しました。シード値の扱いは Xorshift の `getNext` に合わせています。

```javascript
const [PMgetSeed, PMgetNext, PMrand] = (() => {
  const a = 48271;
  const m = 2 ** 31 - 1;
  const q = Math.floor(m / a);
  const r = m % a;
  const PMgetSeed = () => Math.floor(Math.random() * (m - 1)) + 1;
  const s = Int32Array.of(PMgetSeed(), 0, 0, 0);
  function PMgetNext(seed) {
    if (seed) s[0] = seed;
    s[1] = s[0] / q;
    s[2] = s[0] % q;
    s[3] = a * s[2] - r * s[1];
    s[0] = s[3] > 0 ? s[3] : s[3] + m;
    return s[0];
  }
  return [PMgetSeed, PMgetNext, (seed) => PMgetNext(seed) / m];
})();
```

※ XorShift と比較できるように、コードの構成を似せています。

# Web Crypto API

MDN には次のように言及があります。

* [Math.random() - JavaScript | MDN](https://developer.mozilla.org/ja/docs/Web/JavaScript/Reference/Global_Objects/Math/random)

> Math.random() の提供する乱数は、暗号に使用可能な安全性を備えていません。セキュリティに関連する目的では使用しないでください。代わりに Web Crypto API（より正確には[window.crypto.getRandomValues()](https://developer.mozilla.org/ja/docs/Web/API/RandomSource/getRandomValues) メソッド）を使用してください。

こちらも比較に使ってみました。

```javascript
const cryptoRand = (() => {
  const m = 2 ** 32;
  const buf = new Uint32Array(1);
  return () => window.crypto.getRandomValues(buf)[0] / m;
})();
```

# プロット

Canvas にサイズ 1×1 の長方形を描くことで点を打ちます。最初の 20 個の乱数は値を表示します。

```javascript
function test() {
  result.innerHTML = "";
  const ctx = canvas.getContext("2d");
  const w = canvas.width;
  const h = canvas.height;
  ctx.fillStyle = "white";
  ctx.fillRect(0, 0, w, h);
  ctx.fillStyle = "black";
  const count = parseInt(dots.value);
  const rnd = select.selectedOptions[0].function;
  for (let i = 0; i < count; i++) {
    const rx = rnd();
    const ry = rnd();
    if (i < 10) {
      log(rx);
      log(ry);
    }
    const x = Math.floor(rx * w);
    const y = Math.floor(ry * h);
    ctx.fillRect(x, y, 1, 1);
  }
}
```

この種のプロットについて Wikipedia に言及があります。

* [線形合同法 - Wikipedia](https://ja.wikipedia.org/wiki/%E7%B7%9A%E5%BD%A2%E5%90%88%E5%90%8C%E6%B3%95)

> 線形合同法一般の欠点に、多次元で規則的に分布するという性質がある。線形合同法による乱数列$r _ 0$, $r _ 1$, $r _ 2$, $r _ 3$, ... から($r _ 0$, $r _ 1$), ($r _ 1$, $r _ 2$), ($r _ 2$, $r _ 3$), ... のように順番に割り当ててプロットすると、それが疎になるのはしょうがないのだが（例として、全部で10000個しかない点を、10000x10000 の矩形にプロットすることになるのだから、稠密にはなりえない）、一定の間隔の平面上に点が並んでしまうのが問題である。

今回のプロットは 100×100 と小さかったため、目で見て分かるほどには表面化しませんでした。

# 関連記事

出力の `log()` は次の実装を使っています。

* [divに対してconsole.logのようなことをする](https://qiita.com/7shi/items/ca174dac3af8235c5bd2)
