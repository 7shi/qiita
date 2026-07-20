---
coediting: false
comments_count: 0
created_at: '2023-08-03T20:03:38+09:00'
id: 4d80f838638a5bb66265
likes_count: 8
private: false
reactions_count: 0
stocks_count: 3
tags:
- name: JavaScript
  versions: []
- name: CDN
  versions: []
title: 自作ライブラリを jsDelivr から取得
updated_at: '2023-11-24T12:08:43+09:00'
url: https://qiita.com/7shi/items/4d80f838638a5bb66265
slide: false
---

専用のファイル置き場がない状況で、既存のサービスなどで使うために自作の JavaScript ライブラリをどこかに置きたいことがあります。そういうときは GitHub と jsDelivr の組み合わせが便利です。

# jsDelivr

大量にアクセスされるファイルをキャッシュして高速に配信する仕組みを CDN (Contents Delivery Network) と呼びます。

jsDelivr は CDN の 1 つです。

https://www.jsdelivr.com/

# GitHub 連携方法

jsDelivr に登録手続きを行わなくても、GitHub に公開リポジトリがあれば jsDelivr から配信できます。

:::note info
自作のライブラリや、CDN への登録情報が見当たらない既存のライブラリを利用するのに便利です。
:::

トップページにある GitHub のタブをクリックすれば利用方法が表示されます。それを引用して解説を加えます。

```
// load any GitHub release, commit, or branch
// note: we recommend using npm for projects that support it
https://cdn.jsdelivr.net/gh/user/repo@version/file
```

`user`, `repo`, `version`, `file` の部分を書き換えれば、GitHub にある公開リポジトリのファイルが取得できます。GitHub を開いて URL からこれらの情報を取得するのが簡単です。バージョンは git タグを指します。

:::note info
npm でサポートされているプロジェクトは、そちらを使うようにとのことです。以下で jQuery を例に使用方法が説明されますが、これは例であって、本来は npm として参照して欲しいということのようです。
:::

```
// load jQuery v3.6.4
https://cdn.jsdelivr.net/gh/jquery/jquery@3.6.4/dist/jquery.min.js
```

GitHub での URL と比較します。

* https://github.com/jquery/jquery/blob/3.6.4/dist/jquery.min.js

これを書き換えて jsDelivr の URL が得られます。

* `https://github.com/` → `https://cdn.jsdelivr.net/gh`
* `/blob/` → `@`

:::note alert
GitHub で raw ファイルのリンクは取得できますが、大量のアクセスを捌くことは想定されていません。これが配信専用の CDN を間に挟む理由です。
:::

```
// use a version range instead of a specific version
https://cdn.jsdelivr.net/gh/jquery/jquery@3.6/dist/jquery.min.js
https://cdn.jsdelivr.net/gh/jquery/jquery@3/dist/jquery.min.js
```

マイナーバージョンやリビジョンを省略すれば、指定した範囲内の最新版が取得できます。

記事執筆時点（2023 年 8 月 23 日）では 3.6 系の最新版は 3.6.4、3 系の最新版は 3.7.0 のため、それらが取得されます。

:::note warn
バージョンを省略した場合、最新バージョンが push されてから配信に反映されるまで最大 1 日程度のラグがあるようです。配信に反映されてもブラウザ側ではいつまでも古いキャッシュを使い続ける傾向があり（明確な期間は不明）、その場合はブラウザ側でキャッシュをクリアしないと更新されません。

バージョンを省略せずにフルで指定した場合、push 後すぐにアクセスできます。致命的なバグの修正はバージョンを省略せずに指定した方が無難です。
:::

```
// omit the version completely to get the latest one
// you should NOT use this in production
https://cdn.jsdelivr.net/gh/jquery/jquery/dist/jquery.min.js
```

バージョン指定を完全に省略した場合、最新版が取得されます。

:::note alert
製品では使用するべきではないと注意書きがあります。メジャーバージョンアップなどで非互換が発生することがあるためでしょう。
:::

```
// add ".min" to any JS/CSS file to get a minified version
// if one doesn't exist, we'll generate it for you
https://cdn.jsdelivr.net/gh/jquery/jquery@3.6.4/src/core.min.js
```

リポジトリに minify したファイルが置かれていなければ、自動で生成してくれます。

:::note info
自作ライブラリだと毎回 minify して push するのは手間なので、これは助かります。
:::

```
// add / at the end to get a directory listing
https://cdn.jsdelivr.net/gh/jquery/jquery/
```

URL の最後に `/` を付ければ、ディレクトリ内のファイルが列挙されます。

# 参考

https://kamoqq.info/post/cdn-jsdelivr/

https://sutara79.hatenablog.com/entry/2015/05/29/130043
