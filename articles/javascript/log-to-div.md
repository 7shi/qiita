---
coediting: false
comments_count: 0
created_at: '2020-02-10T23:50:30+09:00'
id: ca174dac3af8235c5bd2
likes_count: 2
private: false
reactions_count: 0
stocks_count: 2
tags:
- name: JavaScript
  versions: []
title: divに対してconsole.logのようなことをする
updated_at: '2020-05-12T01:14:56+09:00'
url: https://qiita.com/7shi/items/ca174dac3af8235c5bd2
slide: false
---

CodePen で出力結果を貼るとき、コンソールの代わりに div に出力したかったので簡易的に実装しました。簡易的なので `%d` などのフォーマットは利用できません。

<p class="codepen" data-height="265" data-theme-id="dark" data-default-tab="js,result" data-user="7shi" data-slug-hash="yLNNJoX" style="height: 265px; box-sizing: border-box; display: flex; align-items: center; justify-content: center; border: 2px solid; margin: 1em 0; padding: 1em;" data-pen-title="output for &amp;lt;div&amp;gt;">
  <span>See the Pen <a href="https://codepen.io/7shi/pen/yLNNJoX">
  output for &lt;div&gt;</a> by 七誌 (<a href="https://codepen.io/7shi">@7shi</a>)
  on <a href="https://codepen.io">CodePen</a>.</span>
</p>
<script async src="https://static.codepen.io/assets/embed/ei.js"></script>

↑ エラーになる場合は直接開いてください: <https://codepen.io/7shi/pen/yLNNJoX>

# コード

出力関係のコードを JavaScript 側に入れたくなかったので、HTML 側に入れました。

```html:HTML
<!-- CC0 http://creativecommons.org/publicdomain/zero/1.0/ -->
<div id="result"></div>
<script>
  function log(...args) {
    let str = "";
    for (let i = 0; i < args.length; i++) {
      if (i > 0) str += " ";
      let arg = args[i];
      if (typeof arg == "string") str += arg;
      else str += JSON.stringify(arg);
    }
    result.appendChild(document.createTextNode(str));
    result.appendChild(document.createElement("br"));
  }
</script>
```

`console.log()` を置き換えてはいないので、`log()` として使います。

```javascript
log("hello");
```

# 文字列化

単純に `.toString()` とするだけでは配列や連想配列がうまく出力されません。

```javascript:ブラウザのコンソール
> [1,2,[3,4]].toString()
"1,2,3,4"
> ({a:1, b:2}).toString()
"[object Object]"
```

`.toSource()` というのを見掛けましたが、残念ながら Firefox の独自仕様でした。

```javascript:Firefoxのコンソール
> [1,2,[3,4]].toSource()
"[1, 2, [3, 4]]"
> ({a:1, b:2}).toSource()
"({a:1, b:2})"
```

[JSON.stringify()](https://developer.mozilla.org/ja/docs/Web/JavaScript/Reference/Global_Objects/JSON/stringify) で文字列化するのが手軽で良いようです。

```javascript:ブラウザのコンソール
JSON.stringify([1,2,[3,4]])
"[1,2,[3,4]]"
JSON.stringify({a:1, b:2})
"{\"a\":1,\"b\":2}"
```

# 参考

* [Qiitaで記事にCodePenが埋め込めるようになりました](https://qiita.com/Qiita/items/edae7417214c8e957f54)
* [javascriptのデバッグでobjectの中身を文字列として展開する方法 | infoScoop開発者ブログ](https://www.infoscoop.org/blogjp/2012/05/17/javascript%E3%81%AE%E3%83%87%E3%83%90%E3%83%83%E3%82%B0%E3%81%A7object%E3%81%AE%E4%B8%AD%E8%BA%AB%E3%82%92%E6%96%87%E5%AD%97%E5%88%97%E3%81%A8%E3%81%97%E3%81%A6%E5%B1%95%E9%96%8B%E3%81%99%E3%82%8B/)
* [Show console.log() in an HTML element in JavaScript - Stack Overflow](https://stackoverflow.com/questions/36342437/show-console-log-in-an-html-element-in-javascript)
