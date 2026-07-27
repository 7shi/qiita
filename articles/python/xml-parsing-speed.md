---
coediting: false
comments_count: 0
created_at: '2020-06-10T22:12:16+09:00'
id: c7608db7a097ddd16be6
likes_count: 12
private: false
reactions_count: 0
stocks_count: 15
tags:
- name: Python
  versions: []
- name: XML
  versions: []
title: PythonのXMLパースを速度比較
updated_at: '2020-06-16T15:09:03+09:00'
url: https://qiita.com/7shi/items/c7608db7a097ddd16be6
slide: false
---

Python の ElementTree XML API はパースの方法がいくつか提供されます。速度に注目して比較します。

計測に使用した環境は以下の通りです。

* OS: Windows 10 1909
* CPU: AMD Ryzen 5 2500U with Radeon Vega Mobile Gfx (4 cores)
* Python 3.8.2 (WSL1)

# 概要

Python では XML を扱うための ElementTree XML API があります。

* [xml.etree.ElementTree --- ElementTree XML API — Python 3 ドキュメント](https://docs.python.org/ja/3/library/xml.etree.elementtree.html)

主に 4 種類の方法が提供されます。

1. `fromstring`
2. `XMLParser`
3. `XMLPullParser`
4. `iterparse`

これらはメモリ効率やブロッキング回避など条件に応じて使い分けます。今回はそういった条件は気にしないで、巨大な XML の処理時間だけに注目します。

## 対象

Wiktionary 英語版のダンプファイルを対象とします。ダンプデータは bzip2 で圧縮されて提供されます。記事執筆時点で入手可能な2020年5月1日版を、展開しないで圧縮されたまま利用します。（展開すると 6GB ほどになります）

* <https://dumps.wikimedia.org/enwiktionary/><br>
  enwiktionary-20200501-pages-articles-multistream.xml.bz2 890.8 MB

ダンプファイルは次のようなタグ構造を持ちます。

* [Wikipediaのダンプからページを取り出す](https://qiita.com/7shi/items/7a4aa381ec3dc97bd0f2)

```xml
<mediawiki>
    <siteinfo> ⋯ </siteinfo>
    <page> ⋯ </page>
    <page> ⋯ </page>
           ⋮
    <page> ⋯ </page>
</mediawiki>
```

全体はあまりにも巨大なため、一部だけを取り出して処理できるようにマルチストリームという方式で圧縮されています。

<table><tr><td>siteinfo</td><td>page × 100</td><td>page × 100</td><td>⋯</td></tr></table>

今回はストリームを 1 つずつ取り出しながら全体を処理します。

2 番目以降のストリームには `<page>` タグが 100 個集まっています。

```xml
    <page> ⋯ </page>
    <page> ⋯ </page>
           ⋮
    <page> ⋯ </page>
```

各 `<page>` タグは次のような構造になっています。

```xml
  <page>
    <title>タイトル</title>
    <ns>名前空間</ns>
    <id>ID</id>
    <revision>
      <id>Revision ID</id>
      <parentid>更新前の Revision ID</parentid>
      <timestamp>更新日時</timestamp>
      <contributor>
        <username>編集者</username>
        <id>編集者 ID</id>
      </contributor>
      <comment>編集時のコメント</comment>
      <model>wikitext</model>
      <format>text/x-wiki</format>
      <text bytes="長さ" xml:space="preserve">記事の内容</text>
      <sha1>ハッシュ値</sha1>
    </revision>
  </page>
```

このうち `<text>` タグの中身を抽出して、行数を数えます。以下の記事で行った調査の一部です。

* [Wiktionaryの効率的な処理方法を探る](https://qiita.com/7shi/items/e8091f6ac72491ad45a6)

この記事で使用するスクリプトは以下のリポジトリに含まれています。

* https://github.com/7shi/wiktionary-tools/tree/master/python/research

それぞれの方法で `<page>` から `<id>` と `<text>` を取り出す `getpage` を実装します。

`getpage` を利用して行数を数える部分は共通化します。

```python:共通部分
lines = 0
with open(target, "rb") as f:
    f.seek(slen[0])
    for length in slen[1:-1]:
        for id, text in getpages(f.read(length)):
            for line in text:
                lines += 1
print(f"lines: {lines:,}")
```

※ `slen` は事前に調査した各ストリームの長さです。

# fromstring

XML を文字列で渡してツリーを作ります。ツリーに対して操作（タグを検索して取り出すなど）を行います。

※ 概念的には JavaScript の DOM 操作とほぼ同じです。

コード|処理時間
----|---:
[python/research/countlines-text-xml.py](https://github.com/7shi/wiktionary-tools/blob/master/python/research/countlines-text-xml.py)|5m50.826s

```python
def getpages(bz2data):
    xml = bz2.decompress(bz2data).decode("utf-8")
    pages = ET.fromstring(f"<pages>{xml}</pages>")
    for page in pages:
        if int(page.find("ns").text) == 0:
            id = int(page.find("id").text)
            with io.StringIO(page.find("revision/text").text) as text:
                yield id, text
```

XML にはルートタグが必要なため、仮に `<pages>` で囲んでいます。これを外すとエラーになります。

`<ns>` はページの種類を表します。`0` が通常のページなので、それだけに絞り込んでいます。

`<id>` は何種類かあります。`page.find("id")` は `<page>` 直下の `<id>` のみが対象となります。`<text>` は `<revision>` の中にあるため `page.find("revision/text")` と指定します。このような指定方法は XPath と呼ばれます。

# XMLParser

`fromstring` がツリーの構築のために内部的に使用しているパーサーです。これを直接使えば、ツリーの構築をスキップしてパースだけが行えるため速度的に有利です。

[SAX](https://ja.wikipedia.org/wiki/Simple_API_for_XML) と呼ばれる方式とほぼ同じで、**プッシュ型**と呼ばれるタイプのパーサーです。タグ開始やタグ終了などのイベントを処理するメソッドを持つクラスを用意します。

コード|処理時間
----|---:
[python/research/countlines-text-xmlparser.py](https://github.com/7shi/wiktionary-tools/blob/master/python/research/countlines-text-xmlparser.py)|6m46.163s

```python
class XMLTarget:
    def __init__(self):
        self._ns   = 0
        self._id   = 0
        self._data = []
        self.pages = []

    def start(self, tag, attrib):
        self._data = []

    def data(self, data):
        self._data.append(data)

    def end(self, tag):
        if tag == "ns":
            self._ns = int(self._data[0])
            self._id = 0
        elif self._id == 0 and tag == "id":
            self._id = int(self._data[0])
        elif self._ns == 0 and tag == "text":
            text = []
            cur = ""
            for d in self._data:
                if d == "\n":
                    text.append(cur)
                    cur = ""
                else:
                    cur += d
            if cur: text.append(cur)
            self.pages.append((self._id, text))
        self._data = []

def getpages(bz2data):
    target = XMLTarget()
    parser = ET.XMLParser(target=target)
    parser.feed("<pages>")
    parser.feed(bz2.decompress(bz2data).decode("utf-8"))
    return target.pages
```

`data` はタグの中身です。長い行や改行で分割されて送られて来るため、行ごとにまとめます。

## クラス変数

ドキュメントでは以下のようなサンプルコードが示されます。

* <https://docs.python.org/ja/3/library/xml.etree.elementtree.html#xml.etree.ElementTree.XMLParser>

```python
>>> class MaxDepth:                     # The target object of the parser
...     maxDepth = 0
...     depth = 0
...     def start(self, tag, attrib):   # Called for each opening tag.
...         self.depth += 1
...         if self.depth > self.maxDepth:
...             self.maxDepth = self.depth
...     def end(self, tag):             # Called for each closing tag.
...         self.depth -= 1
...     def data(self, data):
...         pass            # We do not need to do anything with data.
...     def close(self):    # Called when all data has been parsed.
...         return self.maxDepth
```

クラス直下で定義した変数 `maxDepth` と `depth` はクラス変数で、全インスタンス共通です。このコードでは `+=` や `=` など更新の際にインスタンス変数が作られてクラス変数は隠蔽されます。そのためクラス変数の値はずっと `0` で更新されません。

しかしクラス変数がリストで `append` などのメソッドを使ってしまうと話は違います。これにハマってしまい、なかなか思ったように動くコードが書けませんでした。

* [Pythonでクラス変数とインスタンス変数を取り違えてハマった](https://qiita.com/7shi/items/d37493c58a8bb8d7beed)

# XMLPullParser

**プル型**と呼ばれるタイプのパーサーです。Java では SAX に対して [StAX](https://ja.wikipedia.org/wiki/Streaming_API_for_XML) と呼ばれます。

プッシュ型のようにクラスを用意する必要がなく、ループと条件分岐で処理できるためコードが単純になります。

【参考】 [XmlReader と SAX リーダーの比較 | Microsoft Docs](https://docs.microsoft.com/ja-jp/previous-versions/dotnet/netframework-1.1/sbw89de7(v=vs.71))

コード|処理時間
----|---:
[python/research/countlines-text-xmlpull.py](https://github.com/7shi/wiktionary-tools/blob/master/python/research/countlines-text-xmlpull.py)|6m4.553s

```python
def getpages(bz2data):
    xml = bz2.decompress(bz2data).decode("utf-8")
    parser = ET.XMLPullParser()
    parser.feed("<pages>")
    parser.feed(xml)
    ns, id = 0, 0
    for ev, el in parser.read_events():
        if el.tag == "ns":
            ns = int(el.text)
            id = 0
        elif id == 0 and el.tag == "id":
            id = int(el.text)
        elif ns == 0 and el.tag == "text":
            with io.StringIO(el.text) as text:
                yield id, text
```

`<id>` が何種類かあるため、`<ns>` の直後のものだけを拾うように `id = 0` と初期化してチェックします。

# iterparse

プル型のパーサーです。`XMLPullParser` との違いは以下のように説明されます。

* <https://docs.python.org/ja/3/library/xml.etree.elementtree.html#pull-api-for-non-blocking-parsing>

> `XMLPullParser` は柔軟性が非常に高いため、単純に使用したいユーザーにとっては不便かもしれません。アプリケーションにおいて、XML データの読み取り時にブロックすることに支障がないが、インクリメンタルにパースする能力が欲しい場合、`iterparse()` を参照してください。大きな XML ドキュメントを読んでいて、全てメモリ上にあるという状態にしたくない場合に有用です。

`iterparse()` はイテレーターを返して、`next()` で進めるごとにパースを進めるという仕組みです。利用するコードの構造は `XMLPullParser` とほぼ同じです。

コード|処理時間
----|---:
[python/research/countlines-text-xmliter.py](https://github.com/7shi/wiktionary-tools/blob/master/python/research/countlines-text-xmliter.py)|6m29.298s

```python
def getpages(bz2data):
    xml = bz2.decompress(bz2data).decode("utf-8")
    ns, id = 0, 0
    for ev, el in ET.iterparse(io.StringIO(f"<pages>{xml}</pages>")):
        if el.tag == "ns":
            ns = int(el.text)
            id = 0
        elif id == 0 and el.tag == "id":
            id = int(el.text)
        elif ns == 0 and el.tag == "text":
            with io.StringIO(el.text) as text:
                yield id, text
```

# まとめ

今回試した中では、ツリーを作る `fromstring` が最も高速でした。ただしその差は大きくないため、今回のような規模（6GB）のデータを扱うのでなければ、あまり問題にはならないでしょう。

※ これらの方式はメモリ効率やブロッキングなどで使い分けるため、速度だけで判断するものではありません。

方式|コード|処理時間
----|----|---:
fromstring|[python/research/countlines-text-xml.py](https://github.com/7shi/wiktionary-tools/blob/master/python/research/countlines-text-xml.py)|5m50.826s
XMLParser|[python/research/countlines-text-xmlparser.py](https://github.com/7shi/wiktionary-tools/blob/master/python/research/countlines-text-xmlparser.py)|6m46.163s
XMLPullParser|[python/research/countlines-text-xmlpull.py](https://github.com/7shi/wiktionary-tools/blob/master/python/research/countlines-text-xmlpull.py)|6m04.553s
iterparse|[python/research/countlines-text-xmliter.py](https://github.com/7shi/wiktionary-tools/blob/master/python/research/countlines-text-xmliter.py)|6m29.298s

参考までに、.NET Framework ではツリーの構築にもプル型の `XmlReader` を使用します。ツリーを構築せずに `XmlReader` を直接使った方が高速です。

* [Wiktionaryの全文処理をF#とPythonで速度比較](https://qiita.com/7shi/items/1d6b97c657c6fffdbd70)

方式|コード|処理時間|備考
----|----|---:|----
XmlDocument|[fsharp/research/countlines-text-split-doc.fsx](https://github.com/7shi/wiktionary-tools/blob/master/fsharp/research/countlines-text-split-doc.fsx)|6m21.588s|ツリーあり
XmlReader|[fsharp/research/countlines-text-split-reader.fsx](https://github.com/7shi/wiktionary-tools/blob/master/fsharp/research/countlines-text-split-reader.fsx)|3m17.916s|ツリーなし
