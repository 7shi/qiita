---
coediting: false
comments_count: 0
created_at: '2020-06-16T20:31:18+09:00'
id: 449e1aeaee3a25ca5a05
likes_count: 1
private: false
reactions_count: 0
stocks_count: 1
tags:
- name: Python
  versions: []
- name: SQLite3
  versions: []
- name: Wiktionary
  versions: []
title: Wiktionaryから特定の言語を抽出
updated_at: '2020-06-27T04:55:04+09:00'
url: https://qiita.com/7shi/items/449e1aeaee3a25ca5a05
slide: false
---

特定の言語を調査するのに Wiktionary のデータ全体は大き過ぎるので、前処理として言語を指定して抽出するスクリプトを作りました。

シリーズの記事です。

1. [Wiktionaryの効率的な処理方法を探る](https://qiita.com/7shi/items/e8091f6ac72491ad45a6)
1. [Wiktionaryの処理速度をF#とPythonで比較](https://qiita.com/7shi/items/1d6b97c657c6fffdbd70)
1. [Wiktionaryの言語コードを取得](https://qiita.com/7shi/items/4e3c614aac19d645fd1d)
1. Wiktionaryから特定の言語を抽出 ← この記事
1. [Wiktionaryで英語の不規則動詞を調査](https://qiita.com/7shi/items/2a945c346f74ca54552f)
1. [Wiktionaryのスクリプトをローカルで動かす](https://qiita.com/7shi/items/6d1e8466b7586e5d0e90)

この記事のスクリプトは以下のリポジトリに掲載しています。

* <https://github.com/7shi/wiktionary-tools/tree/master/python/tools>

# 概要

特定の言語を調査するのに全文を処理するのは無駄が多いです。前処理として言語を指定して抽出します。

エディタでも開けるサイズのテキストファイルとなるため、扱いやすくなります。今までのように高速化のための特別な方法を工夫しなくても、普通のテキスト処理で情報が抽出できます。

# 準備

Wiktionary 英語版のダンプファイルを利用します。

※ Wiktionary 日本語版にも対応しています。[他の言語版](https://meta.wikimedia.org/wiki/Wiktionary)では記述方法に多少の違いがあるため、個別に対応が必要です。

ダンプデータは bzip2 で圧縮されて提供されます。記事執筆時点で入手可能な2020年5月1日版を、展開しないで圧縮されたまま利用します。（展開すると 6GB ほどになります）

※ 他の日付版も使えます。

* <https://dumps.wikimedia.org/enwiktionary/><br>
  enwiktionary-20200501-pages-articles-multistream.xml.bz2 890.8 MB

※ ダンプと一緒にインデックスも提供されますが、独自に再作成するため不要です。

ダウンロードした xml.bz2 はどこかに置いて残しておく必要があります。どこでも良いですが、今回はホームディレクトリに専用のフォルダを作って入れます。

* ~/share/wiktionary/

データを展開しながらストリームの長さを調べます。展開したデータから並列でページの情報（インデックス相当）や言語の見出しを調べます。

* <https://github.com/7shi/wiktionary-tools/blob/master/python/tools/db-make.py>

※ [初回の記事](https://qiita.com/7shi/items/e8091f6ac72491ad45a6)で作ったスクリプトのうち最速の方法で一本化しました。

```shell-session:実行結果
$ python db-make.py ~/share/wiktionary/enwiktionary-20200501-pages-articles-multistream.xml.bz2
934,033,103 / 934,033,103 | 68,608
checking redirects...
reading language codes...
checking language names...
writing DB files...
```

※ xml.bz2 ファイルの位置を DB に記録します。必要に応じて読み込むため、移動や削除をするとエラーになります。

8つのファイルが生成されます。

ファイル名|内容
----|----
db-settings.tsv|設定情報（ファイル名）
db-streams.tsv|ストリーム情報（ID、オフセット、長さ）
db-namespaces.tsv|名前空間（ns タグ）
db-pages.tsv|ページ情報（ID、ストリーム、名前空間、タイトル、転送、名前空間）
db-idlang.tsv|ページ（ID）に含まれる言語（ID）
db-langname.tsv|言語 ID と言語名（エイリアス含む）の対応表
db-langcode.tsv|言語コードと言語名の対応表
db-templates.tsv|埋め込みテンプレート

用意した SQL を使って SQLite に投入します。簡単な SQL なので、テーブル構成を確認するにはこれを読むのが手っ取り早いと思います。

* <https://github.com/7shi/wiktionary-tools/blob/master/python/tools/db.sql>

```shell-session
$ sqlite3 enwiktionary.db ".read db.sql"
importing 'db-settings.tsv'...
importing 'db-streams.tsv'...
importing 'db-namespaces.tsv'...
importing 'db-pages.tsv'...
importing 'db-idlang.tsv'...
importing 'db-langname.tsv'...
Importing 'db-langcode.tsv'...
Importing 'db-templates.tsv'...
```

以上で準備は完了です。

データを投入してしまえば生成された db-*.tsv は不要ですが、SQLite だけでなく `grep` などコマンドからも調べるのであれば、残しておくと良いでしょう。

## 並列化とジェネレーター

並列化での工夫を紹介します。

```python:db-make.py（抜粋）
    with concurrent.futures.ProcessPoolExecutor() as executor:
        for pgs, idl in executor.map(getlangs, f(getstreams(target))):
```

`f` と `getstreams` はジェネレーターです。`executor.map` は `getlangs` を並列化しており、メインプロセスからはジェネレーターのように見えます。

`getstreams` は並列化できない処理です。`f` でフィルタリングして `yield` したデータが `getlangs` に渡されます。`f` は単なるフィルターではなく、進捗情報を表示したり、`getlangs` に渡さないデータを処理したりします。

# 言語名

言語名は生成された db-langname.tsv で確認できます。

収録語数が多い順でランキングを作成する SQL を用意しました。

* <https://github.com/7shi/wiktionary-tools/blob/master/python/tools/rank.sql>

```shell-session
$ sqlite3 enwiktionary.db ".read rank.sql" > rank.tsv
$ head -n 10 rank.tsv
1       English 928987
2       Latin   805426
3       Spanish 668035
4       Italian 559757
5       Russian 394340
6       French  358570
7       Portuguese      282596
8       German  272451
9       Chinese 192619
10      Finnish 176100
```

# 言語の抽出

言語名を指定して `言語名.txt` というファイルに抽出するスクリプトを用意しました。

* <https://github.com/7shi/wiktionary-tools/blob/master/python/tools/collect-lang.py>

※ 連続したストリームを一度に読み込んだり、データの展開を並列化したりなど、処理速度に配慮しています。スクリプトはやや複雑です。

抽出したテキストにはコメントとしてページの区切りを入れています。タイトルが見出し語に相当します。

```text
<!-- <title>タイトル</title> -->
```

例として英語を抽出します。

```shell-session
$ time python collect-lang.py enwiktionary.db English
reading positions... 928,987 / 928,987
optimizing... 49,835 -> 6,575
reading streams... 6,575 / 6,575
English: 928,988
```

行数とファイルサイズを確認します。

```shell-session
$ wc -l English.txt
14461960 English.txt
$ wc --bytes English.txt
452471057 English.txt
```

英語の収録語数は最大規模ですが、抽出後は 430MB 程度のサイズとなりエディタでも何とか開けます。

※ 抽出したデータの利用方法については、[次回の記事](https://qiita.com/7shi/items/2a945c346f74ca54552f)で例を示します。

言語名を複数指定することも可能です。

```shell-session
$ python collect-lang.py enwiktionary.db Arabic Estonian Hebrew Hittite Ido Interlingua Interlingue Novial "Old English" "Old High German" "Old Saxon" Phoenician Vietnamese Volapük Yiddish
reading positions... 143,926 / 143,926
optimizing... 25,073 -> 10,386
reading streams... 10,386 / 10,386
Arabic: 50,380
Estonian: 8,756
Hebrew: 9,845
Hittite: 392
Ido: 19,978
Interlingua: 3,271
Interlingue: 638
Novial: 666
Old English: 10,608
Old High German: 1,434
Old Saxon: 1,999
Phoenician: 129
Vietnamese: 25,588
Volapük: 3,918
Yiddish: 6,324
```

# 別枠の言語

新しく追加された人工言語や再建された祖語は、Wiktionary の格納方法が異なるため先ほどのスクリプトでは抽出できません。

これらは単語ごとに専用のページを持っています。

* Appendix:言語/単語
* Reconstruction:言語/単語

どのような言語があるかをスクリプトで調べます。

* <https://github.com/7shi/wiktionary-tools/blob/master/python/tools/search-title.py>

```shell-session
$ python search-title.py enwiktionary.db
reading `pages`... 6,860,637 / 6,860,637
```

search-title.tsv が出力されます。ページのタイトルから単語の部分を落として出現数の多い順に並べたものです。

```shell-session
$ grep Appendix search-title.tsv | head -n 5
3492    Appendix:Lojban/
3049    Appendix:Proto-Germanic/
2147    Appendix:Klingon/
1851    Appendix:Quenya/
888     Appendix:Proto-Slavic/
$ grep Reconstruction search-title.tsv | head -n 5
5096    Reconstruction:Proto-Germanic/
3009    Reconstruction:Proto-Slavic/
1841    Reconstruction:Proto-West Germanic/
1724    Reconstruction:Proto-Indo-European/
1451    Reconstruction:Proto-Samic/
```

正規表現でタイトルを指定して抽出するスクリプトを用意しました。

* <https://github.com/7shi/wiktionary-tools/blob/master/python/tools/collect-title.py>

※ それほど大量のページは処理しないという想定で、処理速度には注意を払っていません。

使用例を示します。出力ファイル名を指定する必要があります。

```shell-session:印欧祖語
$ python collect-title.py enwiktionary.db PIE.txt "^Reconstruction:Proto-Indo-European/"
reading `pages`... 6,860,557 / 6,860,557
Sorting...
writing `pages`... 1,726 / 1,726
```
```shell-session:トキポナ（人工言語）
$ python collect-title.py enwiktionary.db Toki_Pona.txt "^Appendix:Toki Pona/"
reading `pages`... 6,860,637 / 6,860,637
Sorting...
writing `pages`... 130 / 130
```

スクリプトは正規表現を処理しているだけなので、特定の言語名が含まれるページをすべて抽出することも可能です。

```shell-session:ノヴィアル（人工言語）
$ python collect-title.py enwiktionary.db Novial2.txt Novial
reading `pages`... 6,860,557 / 6,860,557
Sorting...
writing `pages`... 148 / 148
```

# スクリプトの雛形

独自にスクリプトを書く場合の参考として雛形を用意しました。進捗を表示しながらすべてのデータを読み込みます。

* <https://github.com/7shi/wiktionary-tools/blob/master/python/tools/db-template.py>

```shell-session
$ python db-template.py enwiktionary.db
reading `settings`... 1 / 1
reading `streams`... 68,609 / 68,609
reading `namespaces`... 46 / 46
reading `pages`... 6,860,557 / 6,860,557
reading `idlang`... 6,916,807 / 6,916,807
reading `langname`... 3,978 / 3,978
reading `langcode`... 8,146 / 8,146
reading `templates`... 32,880 / 32,880
```

※ データをただ読み込むだけで処理は行いません。
