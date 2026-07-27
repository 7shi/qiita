---
coediting: false
comments_count: 0
created_at: '2025-04-09T04:21:07+09:00'
id: a056f343ea4ee03285d9
likes_count: 0
private: false
reactions_count: 0
stocks_count: 0
tags:
- name: レスポンシブ
  versions: []
- name: tailwindcss
  versions: []
- name: Claude
  versions: []
title: Claude のアーティファクトで Tailwind CSS のレスポンシブデザインにハマった
updated_at: '2025-04-10T05:38:56+09:00'
url: https://qiita.com/7shi/items/a056f343ea4ee03285d9
slide: false
---

Claude のアーティファクトは、HTML や React (JSX) のコードスニペットをインタラクティブに表示・実行できる便利な機能です。しかし、Tailwind CSS でレスポンシブデザインを使おうとして、予期せぬ壁にぶつかりました。

本記事では、遭遇した問題と、その解決に至るまでの試行錯誤、そして得られた知見を共有します。

# アーティファクト環境における Tailwind CSS の初期状態

まず前提として、アーティファクト環境における Tailwind CSS の利用状況は、HTML と JSX で異なります。

- **HTML 環境:** デフォルトでは Tailwind CSS は利用できません。利用するには、CDN などから明示的に CSS を読み込む必要があります。

- **JSX 環境:** デフォルトで基本的な Tailwind クラスは利用できます。しかし、`md:` といったレスポンシブ修飾子が付いたクラスはデフォルトでは機能しません。レスポンシブデザインを実現するには、こちらも CDN などから明示的に読み込む必要があります。

このため、特にレスポンシブグリッドのような機能を使おうとすると、どちらの環境でもひと手間必要になります。

# 遭遇した問題点

- **`<script>` タグ (Tailwind Play CDN) が機能しない:**
   * HTML 環境で Tailwind を有効にするため、また JSX 環境でレスポンシブ機能を有効にするために、Play CDN `<script src="https://cdn.tailwindcss.com"></script>` を試しましたが、どちらの環境でもスタイルが適用されませんでした。
   * **観察結果:** アーティファクトのプレビューで DOM を確認すると、この `<script>` タグ自体が削除されていました。セキュリティ等の理由でフィルタリングされているようです。

- **レスポンシブクラスが効かない (JSX 環境):**
  * JSX 環境で `grid` や `bg-blue-500` のような基本クラスは適用されるものの、`md:grid-cols-3` のようなレスポンシブクラスが画面サイズを変更しても有効になりませんでした。

- **`<link>` タグ (静的 CSS CDN) でも特定の CDN が機能しない:**
  * 静的な CSS ファイル `tailwind.min.css` を `<link>` タグで読み込む方法を試しました。
  * `href` に JSDelivr の URL を指定した場合、`<link>` タグは DOM 上に存在しているにも関わらず、Tailwind のクラスが有効になりませんでした。

```html:NG
<link href="https://cdn.jsdelivr.net/npm/tailwindcss@2.2.19/dist/tailwind.min.css" rel="stylesheet">
```

# 解決策

試行錯誤の結果、cdnjs から静的 CSS を読み込むことで、Tailwind CSS（レスポンシブクラスを含む）をアーティファクト上で機能させることができました。

```html:OK
<link href="https://cdnjs.cloudflare.com/ajax/libs/tailwindcss/2.2.19/tailwind.min.css" rel="stylesheet">
```
:::note info
配信されるファイルの内容は JSDelivr と cdnjs で同一です。
:::

調査時のログを示します。

- https://claude.ai/share/14771c0d-1b96-4647-8f94-3e12b139cb99

# 知見と考察

今回の経験から、Claude アーティファクト環境で外部 CSS（特に CDN 経由）を利用する際には、以下の点に留意する必要があると考えられます。

* **`<script>` タグのフィルタリング:** 動的な外部スクリプトは、アーティファクト環境の制約により読み込み・実行が許可されない場合があります。外部 CSS の適用には `<link>` タグがより確実です。
* **CDN ホストの選択:** アーティファクト環境の内部的なネットワークポリシーやキャッシュ機構、あるいは他の内部的な要因により、特定の CDN ホストからのリソース読み込みが阻害される可能性があります。問題が発生した場合は、別の CDN ホストを試すのが有効なデバッグ手段となり得ます。
* **環境固有の挙動:** アーティファクトのような特殊な実行環境では、単体の HTML ファイルとは異なる挙動を示す場合があるため、観察と試行錯誤による対処が必要になることがあります。

# まとめ

Claude アーティファクトで Tailwind CSS のレスポンシブ機能（レスポンシブグリッド等）を使いたい場合は、まず `<link>` タグを使って cdnjs のような信頼できる CDN から静的 CSS ファイルを読み込むことを試してみてください。これにより、HTML/JSX の両環境で Tailwind のフル機能が利用可能になるはずです。

ここで調査したことは以下のプロジェクトで使用しています。

https://github.com/7shi/claude-slide
