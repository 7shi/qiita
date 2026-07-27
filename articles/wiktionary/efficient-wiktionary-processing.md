---
coediting: false
comments_count: 0
created_at: '2020-06-05T08:19:19+09:00'
id: e8091f6ac72491ad45a6
likes_count: 7
private: false
reactions_count: 0
stocks_count: 5
tags:
- name: Python
  versions: []
- name: SQLite3
  versions: []
- name: Wiktionary
  versions: []
title: Wiktionaryの効率的な処理方法を探る
updated_at: '2020-06-27T04:54:28+09:00'
url: https://qiita.com/7shi/items/e8091f6ac72491ad45a6
slide: false
---

Wikipedia の関連プロジェクトとして Wiktionary という多言語辞書があります。Python で全文を効率的に処理する方法を探ります。

シリーズの記事です。

1. Wiktionaryの効率的な処理方法を探る ← この記事
1. [Wiktionaryの処理速度をF#とPythonで比較](https://qiita.com/7shi/items/1d6b97c657c6fffdbd70)
1. [Wiktionaryの言語コードを取得](https://qiita.com/7shi/items/4e3c614aac19d645fd1d)
1. [Wiktionaryから特定の言語を抽出](https://qiita.com/7shi/items/449e1aeaee3a25ca5a05)
1. [Wiktionaryで英語の不規則動詞を調査](https://qiita.com/7shi/items/2a945c346f74ca54552f)
1. [Wiktionaryのスクリプトをローカルで動かす](https://qiita.com/7shi/items/6d1e8466b7586e5d0e90)

この記事のスクリプトは以下のリポジトリに掲載しています。

* <https://github.com/7shi/wiktionary-tools/tree/master/python/research>

計測に使用した環境は以下の通りです。

* OS: Windows 10 1909
* CPU: AMD Ryzen 5 2500U with Radeon Vega Mobile Gfx (4 cores)
* Python 3.8.2 (WSL1)

# 概要

Wiktionary としては最大規模の英語版を対象とします。

* [Wiktionary, the free dictionary](https://en.wiktionary.org/wiki/Wiktionary:Main_Page)

Wikipedia と同様に、Wiktionary もダンプデータが提供されます。内容の収集にスクレイピングは禁止されており、ダンプデータの利用が推奨されます。

ダンプデータは bzip2 で圧縮されて提供されます。記事執筆時点で入手可能な2020年5月1日版を、展開しないで圧縮されたまま利用します。（展開すると 6GB ほどになります）

* <https://dumps.wikimedia.org/enwiktionary/><br>
  enwiktionary-20200501-pages-articles-multistream.xml.bz2 890.8 MB

※ 他の言語版などの複数のデータを扱うことも視野に入れて、手間とディスクスペースの節約が狙いです。

ダンプデータは展開せずに扱うことが想定されており、マルチストリームという方式で圧縮されています。

* [Wikipediaのダンプからページを取り出す](https://qiita.com/7shi/items/7a4aa381ec3dc97bd0f2)

※ Wikipedia と Wiktionary のダンプデータの仕様は同じです。

今回は Wiktionary の全文を走査して、どの項目にどの言語のデータが含まれるかのテーブルを作成します。

※ 得られるデータそのものよりも、全文を走査するための手法を確立することに重点があります。用途に応じてスクリプトを改造するという使い方を想定しています。

# ストリームサイズ

各ストリームのオフセットはダンプと共にインデックスとして配布されていますが、長さの情報が含まれません。次のストリームのオフセットから推測できますが、その方法だと最後のストリームから閉じタグが分離できません。

各ストリームのサイズを調査します。ファイルと不可分なデータのため、先頭でファイル名を出力します。

* [python/research/streamlen.py](https://github.com/7shi/wiktionary-tools/blob/master/python/research/streamlen.py)

```python
import bz2

target = "enwiktionary-20200501-pages-articles-multistream.xml.bz2"
print(target)

size = 1024 * 1024  # 1MB
with open(target, "rb") as f:
    decompressor = bz2.BZ2Decompressor()
    slen = 0
    data = b''
    while data or (data := f.read(size)):
        len1 = len(data)
        decompressor.decompress(data)
        data = decompressor.unused_data
        slen += len1 - len(data)
        if decompressor.eof:
            print(slen)
            slen = 0
            decompressor = bz2.BZ2Decompressor()
```
```shell-session:実行結果
$ time python streamlen.py > streamlen.tsv

real    2m53.684s
user    2m52.641s
sys     0m0.953s
```

`BZ2Decompressor` の使い方については以下の記事を参照してください。

* [Pythonでマルチストリームbzip2を逐次展開する](https://qiita.com/7shi/items/b619caed4a70902f0ece)

# 行数

ファイル全体を 1 行ずつ読み込むのに必要な時間を確認します。最低限の所要時間を知るのが目的のため、XML はパースしません。

* [python/research/countlines.py](https://github.com/7shi/wiktionary-tools/blob/master/python/research/countlines.py)

```python
import bz2
target = "enwiktionary-20200501-pages-articles-multistream.xml.bz2"
lines = 0
with bz2.open(target, "rt", encoding="utf-8") as f:
    while (line := f.readline()):
        lines += 1
print(f"lines: {lines:,}")
```
```shell-session:実行結果
$ time python countlines.py
lines: 215,082,554

real    3m34.911s
user    3m33.625s
sys     0m1.188s
```

ストリームサイズの取得よりも時間が掛かっているのは、UTF-8 への変換と行の切り出しが加わったためのようです。

なお、`bzcat` と `wc` の組み合わせは高速です。

```shell-session
$ time bzcat enwiktionary-20200501-pages-articles-multistream.xml.bz2 | wc -l
215082553

real    2m32.203s
user    2m31.250s
sys     0m15.109s
```

※ 結果が 1 行ずれているのは、末尾の閉じタグ `</mediawiki>` が改行されていないためです。

```shell-session
$ echo -n '</mediawiki>' | wc -l
0
```

## ストリーム分割

処理単位を分割する準備として、ストリームごとに分割して行数を数えます。2 種類の方法を比較します。

* [python/research/countlines-BytesIO.py](https://github.com/7shi/wiktionary-tools/blob/master/python/research/countlines-BytesIO.py)

```python
import bz2, io

with open("streamlen.tsv") as f:
    target = f.readline().strip()
    slen = [int(line) for line in f.readlines()]

lines = 0
with open(target, "rb") as f:
    for length in slen:
        with io.BytesIO(f.read(length)) as b:
            with bz2.open(b, "rt", encoding="utf-8") as t:
                while (line := t.readline()):
                    lines += 1
print(f"lines: {lines:,}")
```

* [python/research/countlines-StringIO.py](https://github.com/7shi/wiktionary-tools/blob/master/python/research/countlines-StringIO.py)

```python:（抜粋）
        text = bz2.decompress(f.read(length)).decode("utf-8")
        with io.StringIO(text) as t:
            while (line := t.readline()):
                lines += 1
```
```shell-session:実行結果
$ time python countlines-BytesIO.py
lines: 215,082,554

real    3m37.827s
user    3m36.250s
sys     0m1.547s

$ time python countlines-StringIO.py
lines: 215,082,554

real    3m18.568s
user    3m16.438s
sys     0m2.047s
```

データを展開して文字列に変換してから `StringIO` で読み取る方が高速です。以後、こちらを採用します。

# テキスト抽出

ダンプで使われている XML のタグは、以下の記事で調査しました。

* [XMLのタグの構造と出現数を調べる](https://qiita.com/7shi/items/022c58cf9a86ced595ef)

`<text>` タグの中身を抽出して、行数を数えます。文字列処理と XML パーサーとを比較します。

* [python/research/countlines-text.py](https://github.com/7shi/wiktionary-tools/blob/master/python/research/countlines-text.py)

```python:文字列処理
import bz2, io

with open("streamlen.tsv") as f:
    target = f.readline().strip()
    slen = [int(line) for line in f.readlines()]

def getpages(bz2data):
    with io.StringIO(bz2.decompress(bz2data).decode("utf-8")) as t:
        ns, id = 0, 0
        while (line := t.readline()):
            line = line.lstrip()
            if line.startswith("<ns>"):
                ns = int(line[4:line.find("<", 4)])
                id = 0
            elif id == 0 and line.startswith("<id>"):
                id = int(line[4:line.find("<", 4)])
            elif line.startswith("<text "):
                p = line.find(">")
                if line[p - 1] == "/": continue
                if ns != 0:
                    while not line.endswith("</text>\n"):
                        line = t.readline()
                    continue
                first = line[p + 1:]
                def text():
                    line = first
                    while line:
                        if line.endswith("</text>\n"):
                            line = line[:-8]
                            if line: yield line
                            break
                        else:
                            yield line
                        line = t.readline()
                yield id, text()

lines = 0
with open(target, "rb") as f:
    f.seek(slen[0])
    for length in slen[1:-1]:
        for id, text in getpages(f.read(length)):
            for line in text:
                lines += 1
print(f"lines: {lines:,}")
```

XML パーサー版は `import` を追加して `getpages` を差し替えます。

* [python/research/countlines-text-xml.py](https://github.com/7shi/wiktionary-tools/blob/master/python/research/countlines-text-xml.py)

```python:XMLパーサー（抜粋）
def getpages(bz2data):
    xml = bz2.decompress(bz2data).decode("utf-8")
    pages = ET.fromstring(f"<pages>{xml}</pages>")
    for page in pages:
        if int(page.find("ns").text) == 0:
            id = int(page.find("id").text)
            with io.StringIO(page.find("revision/text").text) as text:
                yield id, text
```
```shell-session:実行結果
$ time python countlines-text.py
lines: 76,501,897

real    4m6.555s
user    4m4.203s
sys     0m2.328s

$ time python countlines-text-xml.py
lines: 76,501,897

real    5m50.826s
user    5m47.047s
sys     0m3.531s
```

文字列処理版は複雑ですが高速です。XML パーサー版は処理内容が分かりやすいです。差異は `getpages` で吸収しているため、以降も両方式の比較を続けます。

なお、XML のパースにはいくつか方式があります。今回はその中でも最も高速なものを使用します。詳細は以下の記事を参照してください。

* [PythonのXMLパースを速度比較](https://qiita.com/7shi/items/c7608db7a097ddd16be6)

# 言語テーブル

今までのコードから、共通部分を括り出します。

* [python/research/mediawiki_parse.py](https://github.com/7shi/wiktionary-tools/blob/master/python/research/mediawiki_parse.py)

どの項目にどの言語のデータが含まれるかのテーブルを作成します（`output1.tsv`）。言語名は別テーブルに正規化します（`output2.tsv`）。

1 つの記事は `==言語名==` という行で区切られているため、それを検出して id と紐付けます。下位の見出しで `===項目名===` が使用されるため区別します。

* [python/research/checklang.py](https://github.com/7shi/wiktionary-tools/blob/master/python/research/checklang.py)
* [python/research/checklang-xml.py](https://github.com/7shi/wiktionary-tools/blob/master/python/research/checklang-xml.py)

```python:共通部分
with open(target, "rb") as f:
    f.seek(slen[0])
    for length in slen[1:-1]:
        for id, text in getpages(f.read(length)):
            for line in text:
                if line.startswith("==") and not line.startswith("==="):
                    lang = line[2:].strip()
                    e = len(lang) - 1
                    while e > 0 and lang[e] == '=': e -= 1
                    lang = lang[: e + 1].strip()
                    if lang in langs:
                        lid = langs[lang]
                    else:
                        lid = len(langs) + 1
                        langs[lang] = lid
                    results.append((id, lid))

with open("output1.tsv", "w", encoding="utf-8") as f:
    for id, lid in results:
        f.write(f"{id}\t{lid}\n")

with open("output2.tsv", "w", encoding="utf-8") as f:
    for k, v in langs.items():
        f.write(f"{v}\t{k}\n")
```
```shell-session:実行結果
$ time python checklang.py

real    4m35.440s
user    4m29.844s
sys     0m4.672s

$ time python checklang-xml.py

real    10m12.721s
user    10m6.813s
sys     0m5.875s
```

※ XML 版との差が行数を数えたとき以上に開いています。詳細は不明ですが、計測した環境は長時間負荷が掛かると発熱によってクロックが低下することが影響しているかもしれません。

## 正規表現

`==` の検出に正規表現を使用します。正規表現をコンパイルして使用することで、文字列処理を組み合わせるよりも少し速いようです。

* [python/research/checklang-re.py](https://github.com/7shi/wiktionary-tools/blob/master/python/research/checklang-re.py)
* [python/research/checklang-xml-re.py](https://github.com/7shi/wiktionary-tools/blob/master/python/research/checklang-xml-re.py)

```python:変更箇所
with open(target, "rb") as f:
    pattern = re.compile("==([^=].*)==")
    f.seek(slen[0])
    for length in slen[1:-1]:
        for id, text in getpages(f.read(length)):
            for line in text:
                if (m := pattern.match(line)):
                    lang = m[1].strip()
                    if lang in langs:
                        lid = langs[lang]
                    else:
                        lid = len(langs) + 1
                        langs[lang] = lid
                    results.append((id, lid))
```
```shell-session:実行結果
$ time python checklang-re.py

real    4m31.855s
user    4m26.375s
sys     0m5.250s

$ time python checklang-xml-re.py

real    9m59.988s
user    9m53.484s
sys     0m6.297s
```

## 並列化

Python ではマルチプロセスを利用して並列化します。

* [Pythonの並列計算サンプルをF#に移植](https://qiita.com/7shi/items/b5121bb3a94e691cd1c5)

プロセス間通信のオーバーヘッドがあるため、ストリームは 10 個ずつ処理します。ファイル名とオフセットと長さを渡して、ファイルの読み取りはワーカープロセス側で行います。

* [python/research/checklang-parallel.py](https://github.com/7shi/wiktionary-tools/blob/master/python/research/checklang-parallel.py)
* [python/research/checklang-parallel-re.py](https://github.com/7shi/wiktionary-tools/blob/master/python/research/checklang-parallel-re.py)
* [python/research/checklang-parallel-xml.py](https://github.com/7shi/wiktionary-tools/blob/master/python/research/checklang-parallel-xml.py)
* [python/research/checklang-parallel-xml-re.py](https://github.com/7shi/wiktionary-tools/blob/master/python/research/checklang-parallel-xml-re.py)

```python:正規表現なし
def getlangs(args):
    target, pos, length = args
    with open(target, "rb") as f:
        f.seek(pos)
        bz2data = f.read(length)
    result = []
    for id, text in getpages(bz2data):
        for line in text:
            if line.startswith("==") and not line.startswith("==="):
                lang = line[2:].strip()
                e = len(lang) - 1
                while e > 0 and lang[e] == '=': e -= 1
                result.append((id, lang[: e + 1].strip()))
    return result
```
```python:正規表現あり
def getlangs(args):
    target, pos, length = args
    with open(target, "rb") as f:
        f.seek(pos)
        bz2data = f.read(length)
    result = []
    for id, text in getpages(bz2data):
        for line in text:
            if (m := re.match("==([^=].*)==", line)):
                result.append((id, m[1].strip()))
    return result
```
```python:共通部分
if __name__ == "__main__":
    import concurrent.futures

    target, spos, slen = mediawiki_parse.read()
    slen.pop()
    split = 10
    poslens = [(target, spos[i], sum(slen[i : i + split]))
               for i in range(1, len(slen), split)]

    results, langs = [], {}
    with concurrent.futures.ProcessPoolExecutor() as executor:
        for result in executor.map(getlangs, poslens):
            for id, lang in result:
                if lang in langs:
                    lid = langs[lang]
                else:
                    lid = len(langs) + 1
                    langs[lang] = lid
                results.append((id, lid))

    with open("output1.tsv", "w", encoding="utf-8") as f:
        for id, lid in results:
            f.write(f"{id}\t{lid}\n")

    with open("output2.tsv", "w", encoding="utf-8") as f:
        for k, v in langs.items():
            f.write(f"{v}\t{k}\n")
```
```shell-session:実行結果
$ time python checklang-parallel.py

real    1m16.566s
user    8m43.188s
sys     0m9.281s

$ time python checklang-parallel-re.py

real    1m7.106s
user    8m12.281s
sys     0m8.953s

$ time python checklang-parallel-xml.py

real    1m49.075s
user    13m33.594s
sys     0m13.922s

$ time python checklang-parallel-xml-re.py

real    1m49.981s
user    13m38.625s
sys     0m14.688s
```

データ量から考えれば、XML 版も十分高速です。

## まとめ

XML のパースの方法（文字列処理またはパーサー）は裏側に隠したため、スクリプトを書く側からは正規表現や並列化を利用するかどうかが焦点となります。

今回は影響しませんが、文字列処理だけでは文字実体参照が残っているのに注意が必要です。具体的には `&amp;` `&quot;` `&lt;` `&gt;` の4種類が使用されます。

用途に応じてスクリプトを改造するという使い方を想定しているため、利用者の好みに応じて選択することになるでしょう。

ソース|所要時間|速度
----|---:|:--:
[checklang.py](https://github.com/7shi/wiktionary-tools/blob/master/python/research/checklang.py)|4m35.440s|△
[checklang-re.py](https://github.com/7shi/wiktionary-tools/blob/master/python/research/checklang-re.py)|4m31.855s|△
[checklang-xml.py](https://github.com/7shi/wiktionary-tools/blob/master/python/research/checklang-xml.py)|10m12.721s|×
[checklang-xml-re.py](https://github.com/7shi/wiktionary-tools/blob/master/python/research/checklang-xml-re.py)|9m59.988s|×
[checklang-parallel.py](https://github.com/7shi/wiktionary-tools/blob/master/python/research/checklang-parallel.py)|1m16.566s|◎
[checklang-parallel-re.py](https://github.com/7shi/wiktionary-tools/blob/master/python/research/checklang-parallel-re.py)|1m07.106s|◎
[checklang-parallel-xml.py](https://github.com/7shi/wiktionary-tools/blob/master/python/research/checklang-parallel-xml.py)|1m49.075s|○
[checklang-parallel-xml-re.py](https://github.com/7shi/wiktionary-tools/blob/master/python/research/checklang-parallel-xml-re.py)|1m49.981s|○

# データの利用

手法の確立が主な目的ですが、せっかくデータを集計したので利用します。

## SQLite

TSV のままでは使いにくいので、SQLite に投入します。

```text:idlang.sql
.mode ascii
.separator "\t" "\n"

.print Importing \'output1.tsv\'...
CREATE TABLE idlang(id INTEGER, lid INTEGER, PRIMARY KEY(id, lid));
.import output1.tsv idlang
CREATE INDEX idlang_id_idx  ON idlang(id);
CREATE INDEX idlang_lid_idx ON idlang(lid);

.print Importing \'output2.tsv\'...
CREATE TABLE langname(lid INTEGER PRIMARY KEY, name TEXT);
.import output2.tsv langname
```
```shell-session:実行結果
$ sqlite3 enwiktionary.db '.read idlang.sql'
Importing 'output1.tsv'...
output1.tsv:158105: INSERT failed: UNIQUE constraint failed: idlang.id, idlang.lid
output1.tsv:1958539: INSERT failed: UNIQUE constraint failed: idlang.id, idlang.lid
output1.tsv:6912349: INSERT failed: UNIQUE constraint failed: idlang.id, idlang.lid
Importing 'output2.tsv'...
```

いくつか UNIQUE 制約に引っ掛かりますが、これらはすべて修正されていることを確認しました。定期的にチェックしているようです。

* [Wiktionary処理中のエラーを調査](https://7shi.hateblo.jp/entry/2020/06/11/163037)

## 言語ランキング

言語数を確認します。

```sql
sqlite> SELECT COUNT(*) FROM langname;
3978
```

収録語数トップ 20 を表示します。

```sql
sqlite> .headers on
sqlite> .mode column
sqlite> SELECT RANK() OVER(ORDER BY cnt DESC) AS rank, name, cnt FROM langname INNER JOIN
   ...> (SELECT lid, COUNT(lid) as cnt FROM idlang GROUP BY lid ORDER BY cnt DESC LIMIT 20)
   ...> AS langcnt ON langname.lid = langcnt.lid;
rank        name        cnt
----------  ----------  ----------
1           English     928987
2           Latin       805426
3           Spanish     668035
4           Italian     559757
5           Russian     394340
6           French      358570
7           Portuguese  282596
8           German      272451
9           Chinese     192619
10          Finnish     176100
11          Catalan     123277
12          Latvian     122870
13          Esperanto   117827
14          Dutch       103664
15          Japanese    103286
16          Swedish     95591
17          Polish      86094
18          Norwegian   65889
19          Greek       62700
20          Hungarian   60329
```

日本語の収録語数は約10万で15位のようです。

こういった感じで、目的に合わせてデータを抽出するスクリプトを書いて、データベースに入れるなどして集計すれば、色々と有益な情報が得られそうです。

# データの比較

今回集計したのと同じような情報は別のデータとして提供されています。両者を比較します。

ダンプとして提供される categorylinks はカテゴリー分類のデータです。

* <https://dumps.wikimedia.org/enwiktionary/><br>
  enwiktionary-20200501-categorylinks.sql.gz 344.6 MB

SQL 形式のため、以下の記事のコードで TSV に変換します。

* [MySQLのダンプをTSVに変換するスクリプトを書く](https://qiita.com/7shi/items/c296a168d53c7af28942)

"言語名_lemmas" というカテゴリーは、今回の記事で抽出したのとほぼ同じデータです。

※ この "lemma" は数学の「補題」ではなく、「辞書の見出し語」の意味です。

## 日本語

categorylinks で日本語の id リストを作成して、今回のデータと比較します。

```shell-session
$ grep "\bJapanese_lemmas\b" enwiktionary-20200501-categorylinks.tsv | cut -f 1 > japanese-1.txt
$ grep Japanese output2.tsv
39      Japanese
620     Old Japanese
1178    Middle Japanese
3978    Japanese Sign Language
$ grep $'\t'39$ output1.tsv | cut -f 1 > japanese-2.txt
$ wc -l japanese-*.txt
  69535 japanese-1.txt
 103286 japanese-2.txt
 172821 合計
```

件数が全然違います。詳細は不明ですが、基準が異なるようです。

# 関連記事

多言語例文サイト Tatoeba のデータを抽出する記事です。

* [複数言語を指定して多言語の例文データを抽出](https://qiita.com/7shi/items/bfb66e69672c08480b0b)
