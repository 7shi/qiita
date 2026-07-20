---
coediting: false
comments_count: 0
created_at: '2025-05-01T04:58:19+09:00'
id: 31ce829808fa5bcd890b
likes_count: 2
private: false
reactions_count: 0
stocks_count: 1
tags:
- name: JSX
  versions: []
- name: React
  versions: []
- name: babel
  versions: []
- name: ESModules
  versions: []
title: React 19 で実行時にブラウザ内 Babel 変換を使う
updated_at: '2025-08-15T17:55:35+09:00'
url: https://qiita.com/7shi/items/31ce829808fa5bcd890b
slide: false
---

React 19 以降、CDN での配布は ESM 専用となり、従来のように `<script>` タグで読み込むことができなくなりました。事前に Babel で JSX を変換しておけば問題ありませんが、実行時でのブラウザ内変換に問題が発生します。その対処法について述べます。

:::note info
React を手軽に試すため、JSX のビルド環境を構築せずに、HTML 単体での動作を想定しています。
:::

# 配布方法の変更

React 18 までは `<script>` タグで読み込むことが可能でした。

https://ja.legacy.reactjs.org/docs/cdn-links.html

```html
<script crossorigin src="https://unpkg.com/react@18/umd/react.production.min.js"></script>
<script crossorigin src="https://unpkg.com/react-dom@18/umd/react-dom.production.min.js"></script>
```

React 19 では UMD ビルドが廃止され、ESM 専用となりました。

- [Running React 19 From a CDN and using esm.sh | Peter Kellner's Blog](https://peterkellner.net/2024/05/10/running-react-19-from-a-cdn-and-using-esm.sh/)

> UMD was widely used in the past as a convenient way to load React without a build step. Now, there are modern alternatives for loading modules as scripts in HTML documents. Starting with React 19, React will no longer produce UMD builds to reduce the complexity of its testing and release process.

> （日本語訳）UMD は、ビルドステップなしで React をロードする便利な方法として、これまで広く使用されてきた。現在では、HTML ドキュメントにスクリプトとしてモジュールをロードするための、より現代的な代替手段がある。React 19 以降、React はテストおよびリリースプロセスの複雑さを軽減するため、UMD ビルドを生成しなくなる。

モジュール内で読み込みます。

```js
import React from "https://esm.sh/react@19";
import { createRoot } from "https://esm.sh/react-dom@19/client";
```

JSX を使わないか、事前にビルドする場合は問題ありません。

# 実行時変換への対応

実行時にブラウザ内で Babel によって JSX の変換を行うと、スクリプトはモジュールではなくなるため、ESM が正常に読み込めなくなります。

```html
<script src="https://unpkg.com/@babel/standalone/babel.min.js"></script>
<script type="text/jsx">
import React from "https://esm.sh/react@19";
import { createRoot } from "https://esm.sh/react-dom@19/client";
</script>
```
```text:エラー
ReferenceError: require is not defined
```

モジュール内で読み込んで、グローバル変数経由で JSX に渡すという変則的な方法で対応できます。

```html:対応版
<script src="https://unpkg.com/@babel/standalone/babel.min.js"></script>
<script type="module">
import React from "https://esm.sh/react@19";
import { createRoot } from "https://esm.sh/react-dom@19/client";
window.React = React;
window.createRoot = createRoot;
</script>
```

簡単なデザインを含んだサンプルを示します。

<p class="codepen" data-height="300" data-default-tab="html,result" data-slug-hash="oggoOxw" data-pen-title="React Component 4" data-user="7shi" style="height: 300px; box-sizing: border-box; display: flex; align-items: center; justify-content: center; border: 2px solid; margin: 1em 0; padding: 1em;">
  <span>See the Pen <a href="https://codepen.io/7shi/pen/oggoOxw">
  React Component 4</a> by 七誌 (<a href="https://codepen.io/7shi">@7shi</a>)
  on <a href="https://codepen.io">CodePen</a>.</span>
</p>
<script async src="https://public.codepenassets.com/embed/index.js"></script>

:::note info
CodePen 側での設定は行わず、必要なことはすべて HTML 内に書いています。
:::

`<html>` や `<body>` で囲めば、HTML 単体で動作します。

```html
<!DOCTYPE html>
<html>
<head><title>React Test</title></head>
<body>
<!-- ここに書く -->
</body>
</html>
```

# 互換性

React 18 以前と 19 以降では、配布方法だけでなく API も一部異なります。

:::note warn
記事執筆時点では React 18 以前の情報がかなり残っているため、注意が必要です。
:::

例えば以下の記事の最後でリンクされている Pen は動作しなくなっています。（この記事はテスト用として CodePen を利用する動機が参考になります）

https://zenn.dev/shuyin02/scraps/7781bc0b7af54d

- https://codepen.io/watanabe-tsubasa/pen/xxNKKve

**修正方法 1**

```js:@18 を指定
import React from "https://esm.sh/react@18";
import ReactDOM from "https://esm.sh/react-dom@18";
```

**修正方法 2**

```js:@19 を指定、/client を追加
import React from "https://esm.sh/react@19";
import ReactDOM from "https://esm.sh/react-dom@19/client";
```

# 参考

CodePen での React 19 の使い方は以下の Pen を参照しました。

- https://codepen.io/chriscoyier/pen/RNboKBL

# 関連記事

この記事に掲載したサンプルの構成について解説した記事です。

https://qiita.com/7shi/items/53324b515595df3fa442
