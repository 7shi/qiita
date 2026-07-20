---
coediting: false
comments_count: 0
created_at: '2025-05-14T02:53:14+09:00'
id: 53324b515595df3fa442
likes_count: 1
private: false
reactions_count: 0
stocks_count: 2
tags:
- name: JSX
  versions: []
- name: React
  versions: []
title: HTML の繰り返し構造をタグで共通化する React 入門
updated_at: '2025-05-14T03:05:37+09:00'
url: https://qiita.com/7shi/items/53324b515595df3fa442
slide: false
---

Claude にアーティファクトで図表の入ったドキュメントの生成を依頼すると、アプリ的な機能がなくてもカジュアルに React を使います。その手の React を扱うための最低限の知識として、静的 HTML の繰り返し構造を独自のタグで抽象化する「シンタックスシュガー」として捉えるアプローチを解説します。

:::note warn
HTML の延長線上で React の取っ掛かりをつかむことを目的としています。Web アプリ開発の入門ではないためご注意ください。
:::

:::note info
CSS は独自に定義しないで [Tailwind CSS](https://tailwindcss.com/) を使用します。これは Claude が生成するコードの傾向に合わせています。
:::

# HTML の繰り返し構造の問題点

Web サイトを記述していると、同じような HTML 構造が何度も登場することがあります。

例えば、以下のようなカード構造があるとします。

```html
<div class="bg-gray-100 min-h-screen flex items-center justify-center space-x-3">
  <div class="bg-white rounded-lg shadow-md p-6 max-w-sm">
    <h1 class="text-xl font-bold text-gray-800 mb-2">
      カード 1
    </h1>
    <div class="flex space-x-2">
      <div class="bg-blue-100 text-blue-800 px-3 py-1 rounded-full text-sm">
        React
      </div>
    </div>
  </div>
  <div class="bg-white rounded-lg shadow-md p-6 max-w-sm">
    <h1 class="text-xl font-bold text-gray-800 mb-2">
      カード 2
    </h1>
    <div class="flex space-x-2">
      <div class="bg-green-100 text-green-800 px-3 py-1 rounded-full text-sm">
        JSX
      </div>
    </div>
  </div>
</div>
```

<p class="codepen" data-height="300" data-default-tab="result" data-slug-hash="ByymPbV" data-pen-title="React Component 1" data-user="7shi" style="height: 300px; box-sizing: border-box; display: flex; align-items: center; justify-content: center; border: 2px solid; margin: 1em 0; padding: 1em;">
  <span>See the Pen <a href="https://codepen.io/7shi/pen/ByymPbV">
  React Component 1</a> by 七誌 (<a href="https://codepen.io/7shi">@7shi</a>)
  on <a href="https://codepen.io">CodePen</a>.</span>
</p>
<script async src="https://public.codepenassets.com/embed/index.js"></script>


この構造が 10 回、20 回と繰り返されると、HTML は膨大な量になり、メンテナンスが困難になります。では、このような繰り返し構造をどのように共通化できるでしょうか？

## React コンポーネントによる抽象化

React の最大の特徴の一つは、UI を再利用可能な「コンポーネント」として定義できることです。コンポーネントは、HTML の構造を抽象化して、再利用可能なパーツとして定義します。

コンポーネントは JavaScript の中にタグが記述できるように拡張された JSX と呼ばれる形式で関数として定義します。

上記のカード例を React コンポーネントにすると、次のようになります。

```jsx
function Card({ title, children }) {
  return (
    <div className="bg-white rounded-lg shadow-md p-6 max-w-sm">
      <h1 className="text-xl font-bold text-gray-800 mb-2">
        {title}
      </h1>
      <div className="flex space-x-2">
        {children}
      </div>
    </div>
  );
}

function Tag({ color, children }) {
  return (
    <div className={`bg-${color}-100 text-${color}-800 px-3 py-1 rounded-full text-sm`}>
      {children}
    </div>
  );
}
```

関数として定義された `Card` や `Tag` は、独自に定義したタグのように利用できます。

```jsx
createRoot(root).render(
  <div className="bg-gray-100 min-h-screen flex items-center justify-center space-x-3">
    <Card title="カード 1">
      <Tag color="blue">React</Tag>
    </Card>
    <Card title="カード 2">
      <Tag color="green">JSX</Tag>
    </Card>
  </div>
);
```

:::note info
`createRoot` は外部からインポートします。`root` に対応する `<div id="root">` は、あらかじめ HTML 側で定義します。詳細は後で HTML 全体の例として示します。
:::

コンポーネントで定義された HTML の構造に、引数で渡された情報が埋め込まれて展開されます。

<p class="codepen" data-height="300" data-default-tab="result" data-slug-hash="xbbPaJX" data-pen-title="React Component 2" data-user="7shi" style="height: 300px; box-sizing: border-box; display: flex; align-items: center; justify-content: center; border: 2px solid; margin: 1em 0; padding: 1em;">
  <span>See the Pen <a href="https://codepen.io/7shi/pen/xbbPaJX">
  React Component 2</a> by 七誌 (<a href="https://codepen.io/7shi">@7shi</a>)
  on <a href="https://codepen.io">CodePen</a>.</span>
</p>

このように、複雑な HTML 構造がタグとして表現でき、必要な情報だけを渡すことで、同じ構造を持つ要素を簡単に量産できます。

## コンポーネントへのデータ受け渡し

上記の例で、`title` や `content` などのデータをコンポーネントに渡す仕組みが「props」（properties の略）です。props を理解することが React のコンポーネントモデルを習得する鍵となります。

### JSX での props の渡し方

コンポーネントの利用側では、HTML の属性のように props を記述します。

```jsx
<Card title="カード 1">
  <Tag color="blue">React</Tag>
</Card>
```

これは `Card` という関数の呼び出しに変換されます。

### props オブジェクトの構造

`Card` コンポーネントが呼び出されると、以下のような props オブジェクトが引数として渡されます。

```jsx
{
  title: "カード 1",
  children: [
    <Tag color="blue">React</Tag>
  ],
}
```

:::note info
開始タグと終了タグの間に記述された内容が自動的に `children` という名前の props として扱われます。
:::

### コンポーネント内での props の使用

コンポーネント関数では、この props オブジェクトを引数として受け取ります。
```jsx
function Card(props) {
  ...
}
```

### 分割代入による props の扱い

props オブジェクトのプロパティに毎回 `props.` を付けてアクセスするのは冗長です。JavaScript の分割代入を使うことで、よりシンプルに書けます。

```jsx
function Card({ title, children }) {
  ...
}
```

## HTML と JSX の構造比較

React（JSX）で書いたコードは、最終的には通常の HTML 構造に変換されます。

タグの中に `{` ... `}` として記述した式の中身が展開されます。

```jsx
function Card({ title, children }) {
  return (
    <div className="bg-white rounded-lg shadow-md p-6 max-w-sm">
      <h1 className="text-xl font-bold text-gray-800 mb-2">
        {title}    // この部分
      </h1>
      <div className="flex space-x-2">
        {children} // この部分
      </div>
    </div>
  );
}
```

コンポーネントの利用例と props を再掲します。

```jsx:コンポーネントの利用例
<Card title="カード 1">
  <Tag color="blue">React</Tag>
</Card>
```

```jsx:props
{
  title: "カード 1",
  children: [
    <Tag color="blue">React</Tag>
  ],
}
```

これは以下のように展開されます。

```jsx
<div class="bg-white rounded-lg shadow-md p-6 max-w-sm">
  <h1 class="text-xl font-bold text-gray-800 mb-2">
    カード 1
  </h1>
  <div class="flex space-x-2">
    <Tag color="blue">React</Tag>
  </div>
</div>
```

`Tag` も同様に展開され、最終的には以下のようになります。

```html
<div class="bg-white rounded-lg shadow-md p-6 max-w-sm">
  <h1 class="text-xl font-bold text-gray-800 mb-2">
    カード 1
  </h1>
  <div class="flex space-x-2">
    <div class="bg-blue-100 text-blue-800 px-3 py-1 rounded-full text-sm">
      React
    </div>
  </div>
</div>
```

このように、小さなコンポーネントを組み合わせることで、複雑な UI を明確かつ保守しやすい形で構築できます。HTML のような親子関係を自然に表現しながらも、再利用性と保守性を高めることができるのです。

# 最小限の React 環境で始める

React を始めるには、必ずしも複雑なビルド環境は必要ありません。HTML の中で CDN から必要なスクリプトを読み込むだけで、簡単に始められます。

```html:example.html
<!DOCTYPE html>
<html>
<head>
  <title>React Test</title>
  <link href="https://cdnjs.cloudflare.com/ajax/libs/tailwindcss/2.2.19/tailwind.min.css" rel="stylesheet" />
</head>
<body>
  <div id="root"></div>
  <script src="https://unpkg.com/@babel/standalone/babel.min.js"></script>
  <script type="module">
import React from "https://esm.sh/react@19";
import { createRoot } from "https://esm.sh/react-dom@19/client";
window.React = React;
window.createRoot = createRoot;
  </script>
  <script type="text/jsx">

※※※※ ここに JSX を書く ※※※※

  </script>
</body>
</html>
```

この HTML ファイルをブラウザで開けば動作します。

:::note info
`import` で行っていることは、以下の記事を参照してください。
:::

https://qiita.com/7shi/items/31ce829808fa5bcd890b

# CodePen で React を使う

この記事にも埋め込んだように、CodePen でも React を使用することが可能です。手順を示します。

1. 新規に Pen を作成
2. HTML に以下の内容を記述
   ```html
   <div id="root"></div>
   ```
3. JS タブの [⚙] をクリック
4. JavaScript Preprocessor に Babel を選択
5. [Save & Close] をクリック
6. JS (Babel) の欄に React コードを貼り付け
7. 先頭の import 文を以下に置き換え（存在しない場合は追加）
   ```jsx
   import React from "https://esm.sh/react@19";
   import { createRoot } from "https://esm.sh/react-dom@19/client";
   ```
8. 末尾でメインコンポーネント（ここでは App とする）のレンダリングを指定
   ```jsx
   createRoot(root).render(<App />);
   ```

公開リンクは、右下の Embed から Iframe の `src` 属性の値をコピーしてください。

:::note info
CodePen での React 19 の使い方は以下の Pen を参照しました。

- https://codepen.io/chriscoyier/pen/RNboKBL
:::

# まとめ

React コンポーネントは、繰り返し使用される UI 要素を抽象化し、再利用可能にする強力な手段です。HTML の繰り返し構造をコンポーネント化することで、コードは簡潔になり、保守性が大幅に向上します。

props を通じてデータを渡し、特に `children` props を活用することで、HTML のような親子関係を持つ構造を関数型のコンポーネントで自然に表現できます。

小さなコンポーネントから始めて、それらを組み合わせることで、複雑なアプリケーションを明確な構造を持つ形で構築できるのが React の利点です。

# 関連情報

Claude に「〇〇についてまとめたスライドをReactで作成してください」と指示すれば、本記事で説明したようなコードを生成します。

その手順を詳細に指示したプロンプトを作成しました。いくつかスライドの例をアップしており、ここまでの React の知識があれば構造は読み解けると思います。

https://github.com/7shi/claude-slide
