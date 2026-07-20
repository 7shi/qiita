---
coediting: false
comments_count: 0
created_at: '2020-06-17T15:35:40+09:00'
id: 4e3c614aac19d645fd1d
likes_count: 2
private: false
reactions_count: 0
stocks_count: 0
tags:
- name: Lua
  versions: []
- name: Wiktionary
  versions: []
title: Wiktionaryの言語コードを取得
updated_at: '2020-06-27T04:54:54+09:00'
url: https://qiita.com/7shi/items/4e3c614aac19d645fd1d
slide: false
---

Wiktionary のページのソースでは言語名がコードで記述されます。データの定義方法を確認します。

シリーズの記事です。

1. [Wiktionaryの効率的な処理方法を探る](https://qiita.com/7shi/items/e8091f6ac72491ad45a6)
1. [Wiktionaryの処理速度をF#とPythonで比較](https://qiita.com/7shi/items/1d6b97c657c6fffdbd70)
1. Wiktionaryの言語コードを取得 ← この記事
1. [Wiktionaryから特定の言語を抽出](https://qiita.com/7shi/items/449e1aeaee3a25ca5a05)
1. [Wiktionaryで英語の不規則動詞を調査](https://qiita.com/7shi/items/2a945c346f74ca54552f)
1. [Wiktionaryのスクリプトをローカルで動かす](https://qiita.com/7shi/items/6d1e8466b7586e5d0e90)

# 一覧表

英語は en、日本語は ja のようにコード化されます。2文字のコードは ISO-639-1、3文字のコードは ISO-639-2 と 3 に準拠しますが、それ以外の祖語や人工言語などは独自に定義されます。

* 一覧表: [Wiktionary:List of languages](https://en.wiktionary.org/wiki/Wiktionary:List_of_languages)

ソースを見ても表は記述されていません。

```text
==Two-letter codes==
These codes are taken from [[w:ISO 639-1|ISO 639-1]].
{{#invoke:list of languages|show|ids=1|two-letter code}}

==Three-letter codes==
These codes are taken from [[w:ISO 639-3|ISO 639-3]], a few from [[w:ISO 639-2|ISO 639-2]].

===a===
{{#invoke:list of languages|show|ids=1|three-letter code|a}}
```

# Scribunto

`#invoke` は MediaWiki の Scribunto という拡張機能で、Lua で記述されたモジュールを呼び出します。

* [Extension:Scribunto/Lua リファレンス マニュアル - MediaWiki](https://www.mediawiki.org/wiki/Extension:Scribunto/Lua_reference_manual/ja)

先ほどの `{{#invoke:list of languages|show|ids=1|two-letter code}}` は関数の呼び出しを表します。

* モジュール: `list of languages`
* 関数: `show`
* 引数: `ids=1`, `two-letter code`

モジュールは `Module:モジュール名` というページに記述されます。

* [Module:list of languages](https://en.wiktionary.org/wiki/Module:list_of_languages)

リンク先にプログラムがあって挙動が調べられるのは面白い仕組みだと思いました。

# データ

コードを見ると、次のような記述があります。

```lua
function export.count(frame)
	return require("Module:table").size(require("Module:languages/alldata"))
end
```

`require` の引数はリンクされているので確認すると、言語コードを定義しているモジュールが列挙されます。

* [Module:languages/alldata](https://en.wiktionary.org/wiki/Module:languages/alldata)

```lua
local modules = {
    ["Module:languages/data2"] = true,
    ["Module:languages/data3/a"] = true,
    ["Module:languages/data3/b"] = true,
    （略）
    ["Module:languages/data3/z"] = true,
    ["Module:languages/datax"] = true,
}
```

`Module:languages/data2` は2文字の言語コードを定義します。

* [Module:languages/data2](https://en.wiktionary.org/wiki/Module:languages/data2)

```lua
local m = {}

m["aa"] = {
	"Afar",
	"Q27811",
	"cus",
	aliases = {"Qafar"},
	scripts = Latn,
}
（略）
return m
```

連想配列にデータを詰めて返します。

# JSON

この手のデータは今なら JSON で定義されることが多いと思うので、試しに変換してみます。

`Module:languages/data2` のコードを data2.lua として保存します。コピペでも構いませんが、以前の記事で作ったスクリプトを使えば次の通りです。

* [Wikipediaのダンプからページを取り出す](https://qiita.com/7shi/items/7a4aa381ec3dc97bd0f2)

```shell-session
$ python mediawiki.py -o data2.lua enwiktionary.db "Module:languages/data2"
```

これを Lua で読み込んで JSON に変換して出力します。

```lua:conv.lua
local pretty = require "resty.prettycjson"
mw = { ustring = { char = utf8.char } }
print(pretty(require "data2"))
```
```shell:実行結果
$ lua conv.lua > data2.json
$ head -n 10 data2.json
{
        "oc": {
                "1": "Occitan",
                "2": "Q14185",
                "3": "roa",
                "scripts": [
                        "Latn",
                        "Hebr"
                ],
                "ancestors": [
```

連想配列に格納される順番は毎回変わるようで、実行するたびに data2.json の並びは変わります。

## 参考

`luarocks --local` でインストールしたライブラリへのパスは環境変数で設定しました。

```text
export LUA_PATH="$HOME/.luarocks/share/lua/5.3/?.lua;;"
export LUA_CPATH="$HOME/.luarocks/lib/lua/5.3/?.so;;"
```

`;;` はデフォルトの検索パスです。

* [lua_reference_watch_out_point_module - Lua Tips](http://秀丸マクロ.net/lua_tips/?lua_reference_watch_out_point_module)

Lua での JSON は以下の記事を参考にしました。

* [Luaをサクッと](https://qiita.com/O21/items/c528c75dee72bc6f2f6a)
* [lua nginx moduleでjson形式のレスポンスを返す(cjson) - Symfoware](https://symfoware.blog.fc2.com/blog-entry-1972.html)

JSON の整形には以下を使用しました。

* [bungle/lua-resty-prettycjson: Lua cJSON Pretty Formatter](https://github.com/bungle/lua-resty-prettycjson)

# 日本語版

MediaWiki にはテンプレートという機能があります。`{{名前}}` という文字列を `テンプレート:名前` というページで指示した内容に置き換えます。（タグなどを組み合わせて指示されます）

* [Help:テンプレート - MediaWiki](https://www.mediawiki.org/wiki/Help:Templates/ja)

日本語版では表記揺れ対策やカテゴリー分類のために言語名はテンプレートを使う方針のようです。（方針は各言語版で異なります）

【例】 `{{jpn}}` → 日本語

* [テンプレート:jpn - ウィクショナリー日本語版](https://ja.wiktionary.org/wiki/%E3%83%86%E3%83%B3%E3%83%97%E3%83%AC%E3%83%BC%E3%83%88:jpn)

```text
<onlyinclude>日本語</onlyinclude>[[Category:言語表記テンプレート|{{PAGENAME}}]][[Category:ISO 639-3|{{PAGENAME}}]]
```

`{{jpn}}` は `<onlyinclude>` タグで囲まれた「日本語」で置き換えられます。

言語名のテンプレートはカテゴリーとしてまとめられています。一覧表もあります。

* [カテゴリ:言語表記テンプレート - ウィクショナリー日本語版](https://ja.wiktionary.org/wiki/%E3%82%AB%E3%83%86%E3%82%B4%E3%83%AA:%E8%A8%80%E8%AA%9E%E8%A1%A8%E8%A8%98%E3%83%86%E3%83%B3%E3%83%97%E3%83%AC%E3%83%BC%E3%83%88)
* [Wiktionary:テンプレートの一覧/言語表記 - ウィクショナリー日本語版](https://ja.wiktionary.org/wiki/Wiktionary:%E3%83%86%E3%83%B3%E3%83%97%E3%83%AC%E3%83%BC%E3%83%88%E3%81%AE%E4%B8%80%E8%A6%A7/%E8%A8%80%E8%AA%9E%E8%A1%A8%E8%A8%98)

Lua で処理されるモジュールのデータと連動しているわけではなく、別々に管理されているようです。

# 他言語版

他の言語版でも言語名にテンプレートは使われているようですが、運用方法は各言語版の裁量に任されているらしく、テンプレート名などは統一されていないようです。

それらのデータを使いたい場合は、個別に実態を調査する必要があります。
