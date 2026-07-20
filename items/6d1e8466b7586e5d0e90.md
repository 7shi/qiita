---
coediting: false
comments_count: 0
created_at: '2020-06-27T04:50:00+09:00'
id: 6d1e8466b7586e5d0e90
likes_count: 1
private: false
reactions_count: 0
stocks_count: 2
tags:
- name: Lua
  versions: []
- name: Wiktionary
  versions: []
title: Wiktionaryのスクリプトをローカルで動かす
updated_at: '2025-07-13T18:04:18+09:00'
url: https://qiita.com/7shi/items/6d1e8466b7586e5d0e90
slide: false
---

Wiktionary では変化形を Lua のスクリプトで生成します。テンプレートの仕組みをざっと見て、スクリプトをローカルで動かします。

シリーズの記事です。

1. [Wiktionaryの効率的な処理方法を探る](https://qiita.com/7shi/items/e8091f6ac72491ad45a6)
1. [Wiktionaryの処理速度をF#とPythonで比較](https://qiita.com/7shi/items/1d6b97c657c6fffdbd70)
1. [Wiktionaryの言語コードを取得](https://qiita.com/7shi/items/4e3c614aac19d645fd1d)
1. [Wiktionaryから特定の言語を抽出](https://qiita.com/7shi/items/449e1aeaee3a25ca5a05)
1. [Wiktionaryで英語の不規則動詞を調査](https://qiita.com/7shi/items/2a945c346f74ca54552f)
1. Wiktionaryのスクリプトをローカルで動かす ← この記事

この記事のスクリプトは以下のリポジトリに掲載しています。

* <https://github.com/7shi/wiktionary-tools/tree/master/lua/en-verb>

# テンプレート

MediaWiki にはテンプレートという機能があります。`{{名前}}` という文字列を `テンプレート:名前` というページで指示した内容に置き換えます。指示にはタグなどを組み合わせます。

* [Help:テンプレート - MediaWiki](https://www.mediawiki.org/wiki/Help:Templates/ja)

# en-verb

[前回の記事](https://qiita.com/7shi/items/2a945c346f74ca54552f)で見たように、英語の動詞変化形は `{{en-verb}}` というテンプレートで作られます。

`{{en-verb}}` の参照先は `Template:en-verb` です。

* <https://en.wiktionary.org/wiki/Template:en-verb>

```text:ソース
{{#invoke:en-headword|show|verbs}}<!--

-->{{#if:{{#invoke:ugly hacks|is_valid_page_name|{{{1|valid}}}}}||[[Category:Template with raw link/en-verb]][[Category:Template with raw link/en-verb/1]]}}<!--
-->{{#if:{{#invoke:ugly hacks|is_valid_page_name|{{{2|valid}}}}}||[[Category:Template with raw link/en-verb]][[Category:Template with raw link/en-verb/2]]}}<!--
-->{{#if:{{#invoke:ugly hacks|is_valid_page_name|{{{3|valid}}}}}||[[Category:Template with raw link/en-verb]][[Category:Template with raw link/en-verb/3]]}}<!--
-->{{#if:{{#invoke:ugly hacks|is_valid_page_name|{{{4|valid}}}}}||[[Category:Template with raw link/en-verb]][[Category:Template with raw link/en-verb/4]]}}<!--

--><noinclude>{{documentation}}</noinclude>
```

この内容をざっくり見ます。

## invoke

```text
{{#invoke:en-headword|show|verbs}}
```

`#invoke` は MediaWiki の Scribunto という拡張機能で、Lua で記述されたモジュールを呼び出します。

* [Extension:Scribunto/Lua リファレンス マニュアル - MediaWiki](https://www.mediawiki.org/wiki/Extension:Scribunto/Lua_reference_manual/ja)

関数の呼び出しを表します。

* モジュール: `en-headword`
* 関数: `show`
* 引数: `verbs`

モジュールは `Module:モジュール名` というページに記述された Lua のスクリプトです。

* <https://en.wiktionary.org/wiki/Module:en-headword>

```lua:（抜粋）
-- The main entry point.
-- This is the only function that can be invoked from a template.
function export.show(frame)
```

後でこのスクリプトを実際に動かします。👉[スクリプトを動かす](#スクリプトを動かす)

## コメント

```text
<!--

-->
```

ソースの見やすさのため改行を入れる際、表示から除外するためコメントにしているようです。

## カテゴリー

```text
{{#if:{{#invoke:ugly hacks|is_valid_page_name|{{{1|valid}}}}}||[[Category:Template with raw link/en-verb]][[Category:Template with raw link/en-verb/1]]}}
```

ページへの引数をチェックします。引数では変化形が指定され、そのページが存在しなければ `Template with raw link/en-verb` などのカテゴリーに入れます。変化形も見出しに入れるためにチェックするのが目的のようです。

ページに対する引数は `{{{1}}}` のように取得します。引数が存在しなければチェックする必要はありませんが、ここでは `{{{1|valid}}}` と指定することで、引数がなければ `valid` という存在するページを使ってチェックを通しているようです。4番目の引数まで同じコードが続きます。

* [Help:テンプレート内でのパーサー関数 - MediaWiki](https://www.mediawiki.org/wiki/Help:Parser_functions_in_templates/ja)

ある種のプログラミングですが、独特な手法のため初見ではすぐに意味が分かりませんでした。

日本語版ではこの手法で変化形も生成します。👉[日本語版](#日本語版)

## documentation

```text
<noinclude>{{documentation}}</noinclude>
```

ブラウザで [Template:en-verb](https://en.wiktionary.org/wiki/Template:en-verb) を開くと説明が表示されますが、それを埋め込んでいます。

指定は相対パスで、実体は `Template:en-verb/documentation` です。

* <https://en.wiktionary.org/wiki/Template:en-verb/documentation>

`<noinclude>` が指定されているため、他のページから `{{en-verb}}` で埋め込むときには無視されます。

# スクリプトを動かす

[Module:en-headword](https://en.wiktionary.org/wiki/Module:en-headword) は読むにはやや長いため、まずは動かしてみます。

## 依存関係

モジュールは `mw.ustring` などの MediaWiki のライブラリを使用します。

* <https://github.com/wikimedia/mediawiki-extensions-Scribunto/tree/master/includes/engines/LuaCommon/lualib>

Wiktionary の別のモジュールも呼び出します。

## 準備

依存するファイルをダウンロードしたりダンプから取り出すスクリプトを用意しました。

* <https://github.com/7shi/wiktionary-tools/blob/master/lua/en-verb/get.sh>

ダンプからの取り出しは、以前の記事で作成したデータベースを使用します。（enwiktionary.db）

* [Wiktionaryから特定の言語を抽出](https://qiita.com/7shi/items/449e1aeaee3a25ca5a05)

## 実行

`Template:en-verb` からの `Module:en-headword` の呼び出しをエミュレートするスクリプトを用意しました。コマンドライン引数を `frame` に入れてモジュールに渡します。

* <https://github.com/7shi/wiktionary-tools/blob/master/lua/en-verb/en-verb.lua>

```lua
start = 1
if arg[1] == "-s" then start = 2 end
if not arg[start] then
    print("usage: lua " .. arg[0] .. " [-s] word [args...]")
    return
end
lualib = "mediawiki-extensions-Scribunto/includes/engines/LuaCommon/lualib/"
package.path = lualib .. "?.lua;" .. lualib .. "mw.?.lua;" .. package.path
frame = {
    args = {"verbs"},
    title = word,
    getParent = function()
        args = {}
        for k, v in pairs(arg) do
            if k > start then args[k - start] = v end
        end
        return {args = args}
    end,
    expandTemplate = function(frame, title)
        --print(title.title)
    end,
}
mw = {
    getCurrentFrame = function()
        return frame
    end,
    loadData = require,
    title = {
        getCurrentTitle = function()
            return { text = arg[start], subpageText = arg[start], }
        end,
    },
    text    = require("text"),
    ustring = require("ustring/ustring"),
}
result = require("Module:en-headword").show(frame)
if start > 1 then result = string.gsub(result, "<.->", "") end
print(result)
```

これを実行すれば、Wiktionary に埋め込まれるデータが取得できます。Lua への最初の引数には原形、それ以降は `en-verb` の引数を与えます。

* 例: set `{{en-verb|sets|setting|set}}`

```xml
$ lua en-verb.lua set sets setting set
<strong class="Latn headword" lang="en">set</strong> (<i>third-person singular simple present</i> 
<b class="Latn form-of lang-en 3|s|pres-form-of      " lang="en">[[sets#English|sets]]</b>, 
<i>present participle</i> <b class="Latn form-of lang-en pres|ptcp-form-of      " lang="en">
[[setting#English|setting]]</b>, <i>simple past and past participle</i> 
<b class="Latn form-of lang-en past|and|past|ptcp-form-of      " lang="en">[[set#English|set]]</b>)
```

ごちゃごちゃしているので、タグを取り除くオプション `-s` を用意しました。

```text
$ lua en-verb.lua -s set sets setting set
set (third-person singular simple present [[sets#English|sets]], present participle 
[[setting#English|setting]], simple past and past participle [[set#English|set]])
```

※ 変化形はリンクになっています。説明と区別するため取り除かずに残しました。

例を見ながら色々と試してみると良いでしょう。

* <https://en.wiktionary.org/wiki/Template:en-verb>

## 最短一致

他の言語の正規表現では `*` に対する最短一致は `*?` が一般的ですが、Lua では `-` です。これによってタグを取り除きます。

```lua
if start > 1 then result = string.gsub(result, "<.->", "") end
```

## 参考

Lua の仕様はコンパクトで、1つのウェブページに網羅されています。

* [Lua 5.3 Reference Manual](http://www.lua.org/manual/5.3/)
* [Lua 5.3 リファレンスマニュアル](http://milkpot.sakura.ne.jp/lua/lua53_manual_ja.html)（非公式日本語版）

# 日本語版

日本語版では Lua のモジュールは使わずに、タグによる条件分岐で変化形を生成します。

* [テンプレート:en-verb - ウィクショナリー日本語版](https://ja.wiktionary.org/wiki/%E3%83%86%E3%83%B3%E3%83%97%E3%83%AC%E3%83%BC%E3%83%88:en-verb)

```text
<onlyinclude>{{head|en|verb|head={{{head|}}}}}
(<small>三単現: </small>{{#if:{{isValidPageName|{{{1|valid}}}}}|''[[<!--
  -->{{en-verb/getPres3rdSg|{{{1|}}}|{{{2|}}}|{{{3|}}}|{{{4|}}}}}<!--
-->]]''|{{{1|-}}}}},
<small>現在分詞: </small>{{#if:{{isValidPageName|{{{2|valid}}}}}|''[[<!--
  -->{{en-verb/getPresP|{{{1|}}}|{{{2|}}}|{{{3|}}}|{{{4|}}}}}<!--
-->]]''|{{{2|-}}}}}, 
<small>過去形: </small>{{#if:{{isValidPageName|{{{3|valid}}}}}|''[[<!--
  -->{{en-verb/getPast|{{{1|}}}|{{{2|}}}|{{{3|}}}|{{{4|}}}}}<!--
-->]]''|{{{3|-}}}}},
<small>過去分詞: </small>{{#if:{{isValidPageName|{{{4|{{{3|valid}}}}}}}}|''[[<!--
  -->{{en-verb/getPastP|{{{1|}}}|{{{2|}}}|{{{3|}}}|{{{4|}}}}}<!--
-->]]''|{{{4|{{{3|-}}}}}}}} )
<includeonly>[[Category:{{eng}}]][[Category:{{eng}} {{verb}}]]</includeonly></onlyinclude>
```

このうち三単現の ``{{en-verb/getPres3rdSg}}`` だけ見てみます。

* [テンプレート:en-verb/getPres3rdSg - ウィクショナリー日本語版](https://ja.wiktionary.org/wiki/%E3%83%86%E3%83%B3%E3%83%97%E3%83%AC%E3%83%BC%E3%83%88:en-verb/getPres3rdSg)

```text
<onlyinclude><!--
// 第2/3パラメータが "es"であるとき、"{1}[{2}]es"をかえす
-->{{#ifeq:{{#if:{{{3|}}}|{{{3}}}|{{{2}}}}}|es|{{{1}}}{{#if:{{{3|}}}|{{{2}}}}}es|<!--
  // その他の場合で、第2/3パラメータが "ied" であるとき、"{1}{2}es"をかえす
  -->{{#ifeq:{{{2}}}{{{3}}}|ied|{{{1}}}{{{2}}}es|<!--
      // その他の場合で、第2/3パラメータが"d", "ed", 又は "ing"であるとき、"{PAGENAME}s"を返す。
      -->{{#switch: {{#if:{{{3|}}}|{{{3}}}|{{{2}}}}}|d|ed|ing={{PAGENAME}}s|<!--
        // その他の場合で、3個以上のパラメータがあるとき、{1}を返す。
        -->{{#if:{{{3|}}}|{{{1}}}|<!--
          // その他は{PAGENAME}sを返す。
          -->{{PAGENAME}}s<!--
-->}}}}}}}}</onlyinclude>
```

処理内容はコメントに書いてある通りですが、慣れないと分かりにくいため、一部だけ説明します。

```text
{{#if:{{{3|}}}|{{{3}}}|{{{2}}}}}
```

これは三項演算子で書けば `exists($3) ? $3 : $2` のような意味です。第3パラメータがあればそれを、なければ第2パラメータを返す式です。null 合体演算子で書けば `$3 ?? $2` に相当します。

`{{{3|}}}` と `{{{3}}}` は引数が存在しないときの挙動が異なるため、使い分けます。`{{{3|}}}` は引数が存在しないときに else を選ばせるためのイディオムのようです。

* [Help:テンプレート内でのパーサー関数 - MediaWiki](https://www.mediawiki.org/wiki/Help:Parser_functions_in_templates/ja)

記法が独特で取っつきにくいですが、コードは局所化されて規模が小さいので、少し慣れれば Lua のスクリプトよりも追いやすいかもしれません。

# 感想

今まで Wiktionary で変化形をどう記述しているのかさっぱり分かりませんでした。実際に調べてみると、テンプレートとモジュールを組み合わせた複雑な仕組みを持っていることが分かりました。言語の専門家とプログラマーが共同で作業しないと作り込めないため、個人にはなかなか敷居が高いように感じました。

## OmegaWiki

:::note alert
OmegaWiki は開発停止したためリンクが切れています。サルベージしたデータの利用法は以下の記事を参照してください。
:::

https://qiita.com/7shi/items/94fc7418051e50eb68eb

[OmegaWiki](http://www.omegawiki.org/Meta:Main_Page) という多言語辞書プロジェクトは、Wiktionary への不満がきっかけで作られたようです。

* http://www.omegawiki.org/Help:Introduction_to_OmegaWiki#History

> The idea of OmegaWiki was born out of frustration with Wiktionary. Many Wiktionary projects worked together in using templates to indicate the non-language specific information. The labels of this information were indicated using templates. It proved useful; much information was copied from one project to another. It became problematic when updates happened. It had to be done manually in all participating projects. Given that the ISO 639-6 recognises in between 7,000 and 8,000 languages, it just does not scale. 

DeepL 翻訳に手を加えた訳

> OmegaWiki のアイデアは、Wiktionary への不満から生まれました。多くの Wiktionary のプロジェクトは、言語に固有ではない情報を示すためにテンプレートを使っていました。この情報のラベルはテンプレートを使って表示されました。それは役に立ったため、多くの情報がプロジェクトから別のプロジェクトへとコピーされました。しかし更新が行われると問題になります。コピーされたすべてのプロジェクトを手動で更新する必要があります。ISO 639-6 では 7,000 から 8,000 の言語を識別しますが、このやり方はスケールしません。

今回の調査から、何となくこの気持ちが分かる気がします。
