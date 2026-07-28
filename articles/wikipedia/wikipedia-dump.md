---
coediting: false
comments_count: 2
created_at: '2020-05-25T07:09:47+09:00'
id: 7a4aa381ec3dc97bd0f2
likes_count: 32
private: false
reactions_count: 0
stocks_count: 33
tags:
- name: Python
  versions: []
- name: XML
  versions: []
- name: SQLite3
  versions: []
- name: Wikipedia
  versions: []
- name: bzip2
  versions: []
title: Wikipediaのダンプからページを取り出す
updated_at: '2020-06-05T18:10:21+09:00'
url: https://qiita.com/7shi/items/7a4aa381ec3dc97bd0f2
slide: false
---

Wikipedia は全ページのダンプを提供しています。巨大なデータですが圧縮したまま扱えるようにインデックスが用意されています。実際にデータを取り出してみます。

# 準備

ダンプデータについての説明は以下にあります。

* [Wikipedia:データベースダウンロード - Wikipedia](https://ja.wikipedia.org/wiki/Wikipedia:%E3%83%87%E3%83%BC%E3%82%BF%E3%83%99%E3%83%BC%E3%82%B9%E3%83%80%E3%82%A6%E3%83%B3%E3%83%AD%E3%83%BC%E3%83%89)

> ファイルサイズが巨大なため、解凍したXMLを通常のエディタやブラウザで開かないようにご注意ください。

Wikipedia 日本語版のデータは以下にあります。

* https://dumps.wikimedia.org/jawiki/

記事執筆時点で入手可能な2020年5月1日版より、以下の2つのファイルを使用します。

1. jawiki-20200501-pages-articles-multistream.xml.bz2 3.0 GB
1. jawiki-20200501-pages-articles-multistream-index.txt.bz2 23.9 MB

1番目の XML が本体のデータです。圧縮済みでこのサイズですから展開するととんでもないサイズになりますが、圧縮したまま扱えるように配慮されているため今回は展開しません。

2番目のインデックスの方は展開します。107MB ほどになります。

# 仕様

以下の記事でダンプされた XML のタグの構造を調べています。

* [XMLのタグの構造と出現数を調べる](https://qiita.com/7shi/items/022c58cf9a86ced595ef)

主要部分の構造は以下の通りです。1 つの項目が 1 つの page タグに格納されます。

```xml
<mediawiki>
    <siteinfo> ⋯ </siteinfo>
    <page> ⋯ </page>
    <page> ⋯ </page>
           ⋮
    <page> ⋯ </page>
</mediawiki>
```

bz2 ファイルは単純に XML ファイル全体を圧縮したのではなく、100 項目ごとのブロックで構成されています。ブロックを取り出してピンポイントで展開できます。この構造を**マルチストリーム**と呼びます。

<table><tr><td>siteinfo</td><td>page × 100</td><td>page × 100</td><td>⋯</td></tr></table>

インデックスは行ごとに次の構造となっています。

```text
bz2のオフセット:id:title
```

実際のデータを確認します。

```text
$ head -n 5 jawiki-20200501-pages-articles-multistream-index.txt
690:1:Wikipedia:アップロードログ 2004年4月
690:2:Wikipedia:削除記録/過去ログ 2002年12月
690:5:アンパサンド
690:6:Wikipedia:Sandbox
690:10:言語
```

690 から始まるブロックの長さを知るには、次のブロックの開始位置を確認する必要があります。

```text
$ head -n 101 jawiki-20200501-pages-articles-multistream-index.txt | tail -n 2
690:217:ミュージシャン一覧 (グループ)
814164:219:曲名一覧
```

1行1項目のため、行数を数えれば全体の項目数が分かります。約250万項目あります。

```text
$ wc -l jawiki-20200501-pages-articles-multistream-index.txt
2495246 jawiki-20200501-pages-articles-multistream-index.txt
```

# 取り出し

実際に特定の項目を取り出してみます。「Qiita」を対象とします。

* [Qiita - Wikipedia](https://ja.wikipedia.org/wiki/Qiita)

## 情報取得

「Qiita」を検索します。

```text
$ grep Qiita jawiki-20200501-pages-articles-multistream-index.txt
2919984762:3691277:Qiita
3081398799:3921935:Template:Qiita tag
3081398799:3921945:Template:Qiita tag/doc
```

Template は無視して、最初の id=3691277 を対象とします。

基本的には 1 ブロック 100 項目ですが、中には例外があってずれているようなので、次のブロックの開始位置を手動で確認します。

```text
2919984762:3691305:Category:ガボンの二国間関係
2920110520:3691306:Category:日本・カメルーン関係
```

必要な情報が揃いました。

id|ブロック|次のブロック
---:|---:|---:
3691277|2919984762|2920110520

## Python

Python を起動します。

```text
$ python
Python 3.8.2 (default, Apr  8 2020, 14:31:25)
[GCC 9.3.0] on linux
Type "help", "copyright", "credits" or "license" for more information.
```

圧縮ファイルを開きます。

```py
>>> f = open("jawiki-20200501-pages-articles-multistream.xml.bz2", "rb")
```

オフセットを指定して、Qiita の項目を含むブロックを取り出します。

```py
>>> f.seek(2919984762)
2919984762
>>> block = f.read(2920110520 - 2919984762)
```

ブロックを展開して、文字列を取得します。

```py
>>> import bz2
>>> data = bz2.decompress(block)
>>> xml = data.decode(encoding="utf-8")
```

内容を確認します。page タグが 100 個入っています。

```py
>>> print(xml)
  <page>
    <title>Category:恵庭市長</title>
    <ns>14</ns>
    <id>3691165</id>
（略）
```

このままでは扱いにくいので、XML としてパースします。パースにはルート要素が必要なため、適当に追加します。

```py
>>> import xml.etree.ElementTree as ET
>>> root = ET.fromstring("<root>" + xml + "</root>")
```

中身を確認します。ルートの下に page タグが 100 個入っています。

```py
>>> len(root)
100
>>> [child.tag for child in root]
['page', 'page', （略）, 'page']
```

id を指定して page を取得します。`find` の引数は XPath と呼ばれる記法です。

```py
>>> page = root.find("page/[id='3691277']")
```

内容を確認します。

```py
>>> page.find("title").text
'Qiita'
>>> page.find("revision/text").text[:50]
'{{Infobox Website\n|サイト名=Qiita\n|ロゴ=\n|スクリーンショット=\n|スク'
```

ファイルとして保存します。

```py
>>> tree = ET.ElementTree(page)
>>> tree.write("Qiita.xml", encoding="utf-8")
```

次のようなファイルが得られます。

```xml:Qiita.xml
<page>
    <title>Qiita</title>
    <ns>0</ns>
    <id>3691277</id>
    <revision>
      <id>77245770</id>
      <parentid>75514051</parentid>
      <timestamp>2020-04-26T12:21:10Z</timestamp>
      <contributor>
        <username>Linuxmetel</username>
        <id>1613984</id>
      </contributor>
      <comment>Qiitaの論争についてと、LGTM　ストックの説明の追加</comment>
      <model>wikitext</model>
      <format>text/x-wiki</format>
      <text bytes="4507" xml:space="preserve">{{Infobox Website
|サイト名=Qiita
（略）
[[Category:日本のウェブサイト]]</text>
      <sha1>mtwuh9z42c7j6ku1irgizeww271k4dc</sha1>
    </revision>
  </page>
```

# スクリプト

一連の流れをスクリプトにまとめました。

* <https://github.com/7shi/wiktionary-tools/blob/master/python/conv_index.py>
* <https://github.com/7shi/wiktionary-tools/blob/master/python/mediawiki.py>

インデックスを SQLite に格納して使用します。

## SQLite

スクリプトでインデックスを TSV に変換して、取り込み用 SQL を生成します。

```text
python conv_index.py jawiki-20200501-pages-articles-multistream-index.txt
```

3つのファイルが生成されます。

* jawiki-20200501-pages-articles-multistream-index-1.tsv
* jawiki-20200501-pages-articles-multistream-index-2.tsv
* jawiki-20200501-pages-articles-multistream-index.sql

SQLite に取り込みます。

```text
sqlite3 jawiki.db ".read jawiki-20200501-pages-articles-multistream-index.sql"
```

これで準備が完了しました。

## 使い方

DB にはインデックスのみが格納されているため、同じディレクトリに xml.bz2 ファイルが必要です。DB に xml.bz2 のファイル名が記録されているためリネームしないでください。

DB と項目名を指定すると、結果が表示されます。デフォルトでは text タグの内容のみですが、`-x` を指定すれば page タグ内のすべてのタグが出力されます。

```text
python mediawiki.py jawiki.db Qiita
python mediawiki.py -x jawiki.db Qiita
```

ファイルに出力できます。

```text
python mediawiki.py -o Qiita.txt jawiki.db Qiita
python mediawiki.py -o Qiita.xml -x jawiki.db Qiita
```

mediawiki.py はライブラリとしても使えるように作られています。

```py
import mediawiki
db = mediawiki.DB("jawiki.db")
print(db["Qiita"].text)
```

# 関連記事

マルチストリームと bz2 モジュールについての記事です。

* [Pythonでマルチストリームbzip2を逐次展開する](https://qiita.com/7shi/items/b619caed4a70902f0ece)

多言語辞書 Wiktionary のダンプからデータを抽出する記事です。Wikipedia の関連プロジェクトでダンプの形式は同じです。

* [Wiktionaryの効率的な処理方法を探る](https://qiita.com/7shi/items/e8091f6ac72491ad45a6)

# 参考

Wikipedia のインデックスの仕様について参考にしました。

* [wikipedia - how to use information provided in wiki download's index file? - Stack Overflow](https://stackoverflow.com/questions/29020732/how-to-use-information-provided-in-wiki-downloads-index-file)

ElementTree XML API はドキュメントを参照しました。

* [xml.etree.ElementTree --- ElementTree XML API](https://docs.python.org/ja/3/library/xml.etree.elementtree.html)

SQLite の使い方は例文データを処理した時に調べました。

* [複数言語を指定して多言語の例文データを抽出](https://qiita.com/7shi/items/bfb66e69672c08480b0b)
