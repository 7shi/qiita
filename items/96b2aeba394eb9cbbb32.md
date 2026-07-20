---
coediting: false
comments_count: 0
created_at: '2020-07-01T14:59:14+09:00'
id: 96b2aeba394eb9cbbb32
likes_count: 3
private: false
reactions_count: 0
stocks_count: 0
tags:
- name: HTML
  versions: []
- name: JavaScript
  versions: []
title: 指定したHTML要素にスクロール
updated_at: '2020-07-11T22:56:33+09:00'
url: https://qiita.com/7shi/items/96b2aeba394eb9cbbb32
slide: false
---

JavaScript で指定した HTML 要素にスクロールさせます。自動的にフォーカスを移動させることなどを想定しています。

よくある処理だと思いますが、そのものズバリのサンプルが見当たらなかったので、実装を残しておきます。

<p class="codepen" data-height="265" data-theme-id="light" data-default-tab="js,result" data-user="7shi" data-slug-hash="gOPXxre" style="height: 265px; box-sizing: border-box; display: flex; align-items: center; justify-content: center; border: 2px solid; margin: 1em 0; padding: 1em;" data-pen-title="ensureVisible">
  <span>See the Pen <a href="https://codepen.io/7shi/pen/gOPXxre">
  ensureVisible</a> by 七誌 (<a href="https://codepen.io/7shi">@7shi</a>)
  on <a href="https://codepen.io">CodePen</a>.</span>
</p>
<script async src="https://static.codepen.io/assets/embed/ei.js"></script>

このサンプルでは [Start] をクリックすると、0.5 秒ごとに選択位置を移動して、それに追随してスクロールします。

# 実装

.NET Framework の `ListView` には `EnsureVisible` というメソッドがあり、指定した項目が画面外にある場合はスクロールして表示することができます。

* [ListView.EnsureVisible(Int32) メソッド (System.Windows.Forms) | Microsoft Docs](https://docs.microsoft.com/ja-jp/dotnet/api/system.windows.forms.listview.ensurevisible?view=netcore-3.1)

それを真似て HTML でも `ensureVisible` を実装しました。マージンと HTMLElement を指定します。HTMLElement は複数指定できます。

```javascript
function ensureVisible(margin, ...elems) {
  let rs = elems.map((elem) => elem.getBoundingClientRect());
  let tp = Math.min(...rs.map((r) => r.top   )) - margin;
  let bt = Math.max(...rs.map((r) => r.bottom)) + margin;
  if (tp < 0) {
    let top = pageYOffset + tp;
    scroll({ top, behavior: "smooth" });
  } else if (bt > innerHeight) {
    let top = pageYOffset + bt - innerHeight;
    scroll({ top, behavior: "smooth" });
  }
}
```

# 位置の指定

[getBoundingClientRect](https://developer.mozilla.org/ja/docs/Web/API/Element/getBoundingClientRect) は画面上の位置（相対座標）を取得します。スクロールすると変化します。

[scroll](https://developer.mozilla.org/ja/docs/Web/API/Window/scroll) はドキュメント上の位置（絶対座標）を指定します。そのため表示の開始位置 `pageYOffset` を足すことで補正します。今回の実装ではスムーズスクロールを利用しています。

```javascript
    scroll({ top: top, behavior: "smooth" });
```

スクロール量を指定する [scrollBy](https://developer.mozilla.org/ja/docs/Web/API/Window/scrollBy) もありますが、スムーズスクロールをサポートしていないため利用しませんでした。

# サンプル

サンプルでは 0.5 秒のウェイトを Promise で処理しています。

```javascript
function wait(timeout) {
  return new Promise((resolve, reject) => setTimeout(resolve, timeout));
}

start.onclick = async () => {
  for (let td of Array.from(table.getElementsByTagName("td"))) {
    ensureVisible(20, td);
    td.classList.add("selected");
    await wait(500);
    td.classList.remove("selected");
  }
  ensureVisible(20, moveToTop);
};
```

詳細は以下の記事を参照してください。

* [非同期APIをPromiseでラップしてasync/awaitで使う](https://qiita.com/7shi/items/a2bb35f27cd4a56f7bac)

# 経緯

音声合成の読み上げ位置を追うために実装しました。

* [カミュ『地獄のプロメテウス』（短編集『夏』より） - 七誌の開発日記](https://7shi.hateblo.jp/entry/2020/07/01/000419)
