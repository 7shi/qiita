---
coediting: false
comments_count: 0
created_at: '2020-05-27T03:58:26+09:00'
id: c296a168d53c7af28942
likes_count: 1
private: false
reactions_count: 0
stocks_count: 0
tags:
- name: Python
  versions: []
- name: MySQL
  versions: []
- name: F#
  versions: []
- name: mysqldump
  versions: []
- name: TSV
  versions: []
title: MySQLのダンプをTSVに変換するスクリプトを書く
updated_at: '2020-06-09T15:27:19+09:00'
url: https://qiita.com/7shi/items/c296a168d53c7af28942
slide: false
---

MySQL からダンプされた SQL を他の用途に使うため、タブ区切りのテキスト（いわゆる TSV）に変換を試みます。

# 概要

MySQL のテーブルは mysqldump で SQL としてダンプできます。主要部分は CREATE 文と INSERT 文です。

* [ひとつのテーブルを指定してダンプ | mysqldumpの教科書](https://mysqldump.i-like-pudding.com/ja/archives/table-designation/)

> ```sql
（略）
CREATE TABLE `t_price` (
（略）
INSERT INTO `t_price` VALUES (1,'定型',25,82),（略）(10,'定型外',4000,1180);
（略）
> ```

自分で管理している MySQL からのダンプであれば、直接 TSV にダンプできます。

* [MySQLのデータをcsv,tsv形式でダンプする - Qiita](https://qiita.com/d-dai/items/e56c2e5abf558328373f)

他で公開されているデータが SQL のダンプしかない場合、一度取り込んでダンプするか、変換するかになります。今回はスクリプトを書いて変換を試みます。

※ 後述しますが、Wiktionary のダンプの変換を想定しています。データが巨大なため、一度取り込むのは避けたいのです。

# 仕様

SQL から INSERT 文の VALUES だけを取り出して TSV に変換します。具体的には次のような挙動を目指します。

```sql:変換前
INSERT INTO `table` VALUES (1,2,3),(4,5,6);
INSERT INTO `table` VALUES (1,'a,b','c\'d');
```
```text:変換後
1	2	3
4	5	6
1	a,b	c'd
```

# Python

Python で変換スクリプトを書きます。

## read_string

一重引用符 `'` で囲まれる文字列をパースします。これが一番混み入っています。

最初の文字が `'` かどうかをチェックします。エスケープシーケンスの処理は簡略化して、`\"`, `\'`, `\\` の場合は `\` を除去しますが、その他の制御文字の場合は `\` を残します。

`test` はテスト用のフラグです。

```py:sql2tsv.py
test = True

def read_string(src, pos):
    length = len(src)
    if pos >= length or src[pos] != "'": return None
    pos += 1
    ret = ""
    while pos < length and src[pos] != "'":
        if src[pos] == "\\":
            pos += 1
            end = pos >= length
            if end or not src[pos] in "\"'\\":
                ret += "\\"
            if end: break
        ret += src[pos]
        pos += 1
    if pos < length and src[pos] == "'": pos += 1
    return (ret, pos)

if test:
    src = r"'a,b','c\'d'"
    pos = 0
    while pos < len(src):
        s, p = read_string(src, pos)
        print("read_string", (src, pos), "->", (s, p))
        pos = p + 1
```
```text:実行結果
read_string ("'a,b','c\\'d'", 0) -> ('a,b', 5)
read_string ("'a,b','c\\'d'", 6) -> ("c'd", 12)
```

## read_value

1つのデータを読み取ります。文字列なら `read_string` を読んで、それ以外は `,` か `(` まで読み進めます。

```py:sql2tsv.py（続き）
def read_value(src, pos):
    length = len(src)
    if pos >= length: return None
    sp = read_string(src, pos)
    if sp: return sp
    p = pos
    while p < length and src[p] != "," and src[p] != ")":
        p += 1
    return (src[pos:p], p)

if test:
    for src in ["1,2,3", r"1,'a,b','c\'d'"]:
        pos = 0
        while (value := read_value(src, pos)):
            s, p = value
            print("read_value", (src, pos), "->", (s, p))
            pos = p + 1
```
```text:実行結果
read_value ('1,2,3', 0) -> ('1', 1)
read_value ('1,2,3', 2) -> ('2', 3)
read_value ('1,2,3', 4) -> ('3', 5)
read_value ("1,'a,b','c\\'d'", 0) -> ('1', 1)
read_value ("1,'a,b','c\\'d'", 2) -> ('a,b', 7)
read_value ("1,'a,b','c\\'d'", 8) -> ("c'd", 14)
```

## read_values

括弧内のコンマで区切られたデータをすべて読み取ります。

```py:sql2tsv.py（続き）
def read_values(src, pos):
    length = len(src)
    if pos >= length or src[pos] != "(": return None
    pos += 1
    ret = []
    if pos < length and src[pos] != ")":
        while (value := read_value(src, pos)):
            s, pos = value
            ret.append(s)
            if pos >= length or src[pos] != ",": break
            pos += 1
    if pos < length and src[pos] == ")": pos += 1
    return (ret, pos)

if test:
    for src in [r"(1,2,3)", r"(1,'a,b','c\'d')"]:
        print("read_values", (src, 0), "->", read_values(src, 0))
```
```text:実行結果
read_values ('(1,2,3)', 0) -> (['1', '2', '3'], 7)
read_values ("(1,'a,b','c\\'d')", 0) -> (['1', 'a,b', "c'd"], 16)
```

## read_all_values

括弧で囲まれたデータをすべて読み取ります。ループでの扱いを想定してジェネレーターにします。

```py:sql2tsv.py（続き）
def read_all_values(src, pos):
    length = len(src)
    while (sp := read_values(src, pos)):
        s, pos = sp
        yield s
        if pos >= length or src[pos] != ",": break
        pos += 1

if test:
    src = r"(1,2,3),(1,'a,b','c\'d')"
    print("read_all_values", (src, 0), "->", list(read_all_values(src, 0)))
```
```text:実行結果
read_all_values ("(1,2,3),(1,'a,b','c\\'d')", 0) -> [['1', '2', '3'], ['1', 'a,b', "c'd"]]
```

## read_sql

SQL の各行から `INSERT INTO` で始まる行を見付けて `read_all_values` で処理します。

```py:sql2tsv.py（続き）
def read_sql(stream):
    while (line := stream.readline()):
        if line.startswith("INSERT INTO "):
            p = line.find("VALUES (")
            if p >= 0: yield from read_all_values(line, p + 7)

if test:
    import io
    src = r"""
INSERT INTO `table` VALUES (1,2,3),(4,5,6);
INSERT INTO `table` VALUES (1,'a,b','c\'d');
""".strip()
    print("read_sql", (src,))
    print("->", list(read_sql(io.StringIO(src))))
```
```text:実行結果
read_sql ("INSERT INTO `table` VALUES (1,2,3),(4,5,6);\nINSERT INTO `table` VALUES (1,'a,b','c\\'d');",)
-> [['1', '2', '3'], ['4', '5', '6'], ['1', 'a,b', "c'd"]]
```

## コマンド化

必要な関数はすべて実装しました。テストをオフにします。

```py:sql2tsv.py（変更）
test = False
```

指定したファイルを読み込んで、指定したファイルに書き出します。gzip 圧縮された SQL ファイルを展開せずに直接読み込めます。

UTF-8 のバイト列が文字の途中で切れている場合を想定して、`open` では `errors="replace"` を指定します。これにより異常な文字は � に置換されます。`errors` を指定しない場合はエラーになります。

【参考】 [(Windows) Python3でのUnicodeEncodeErrorの原因と回避方法 - Qiita](https://qiita.com/butada/items/33db39ced989c2ebf644)

```py:sql2tsv.py（続き）
if __name__ == "__main__":
    import gzip, sys
    try:
        target = sys.argv[1]
        openf = None
        if target.endswith(".sql"   ): openf =      open
        if target.endswith(".sql.gz"): openf = gzip.open
        if not openf: raise Exception("not supported: " + target)
    except Exception as e:
        print(e)
        print("usage: %s sql[.gz]" % sys.argv[0])
        exit(1)
    tsv = target[:target.rfind(".sql")] + ".tsv"
    with openf(target, "rt", encoding="utf-8", errors="replace") as fr:
        with open(tsv, "w", encoding="utf-8") as fw:
            for values in read_sql(fr):
                fw.write("\t".join(values))
                fw.write("\n")
```

次のように使います。出力は拡張子を変えた `file.tsv` となります。

```text
python sql2tsv.py file.sql
```

スクリプト全体は以下に置きました。

* <https://github.com/7shi/wiktionary-tools/blob/master/sql2tsv/sql2tsv.py>

# 計測

どのくらいの速度で処理できるか、巨大なファイルで計測します。

Wikipedia の関連プロジェクトとして Wiktionary という多言語辞書があります。今回は Wiktionary のダンプデータを利用します。

なお、Wiktionary の本文の処理については以下の記事でも扱っています。

* [Wiktionaryの効率的な処理方法を探る](https://qiita.com/7shi/items/e8091f6ac72491ad45a6)

## Wiktionary 日本語版

記事執筆時点で入手可能な2020年5月1日版より、以下のファイルを使用します。ファイルを展開すると 90 MB ほどになります。

* https://dumps.wikimedia.org/jawiktionary/<br>
  jawiktionary-20200501-categorylinks.sql.gz 10.7 MB

今回のスクリプトで変換すると、79 MB ほどの TSV が出力されます。圧縮ファイルを直接読み込んでも遅延は誤差程度です。

```text
$ time python sql2tsv.py jawiktionary-20200501-categorylinks.sql

real    0m20.330s
user    0m19.797s
sys     0m0.500s

$ time python sql2tsv.py jawiktionary-20200501-categorylinks.sql.gz

real    0m20.751s
user    0m20.344s
sys     0m0.391s
```

行数は 95 万行ほどです。

```text
$ wc -l jawiktionary-20200501-categorylinks.tsv
951077 jawiktionary-20200501-categorylinks.tsv
```

## Wiktionary 英語版

記事執筆時点で入手可能な2020年5月1日版より、以下のファイルを使用します。展開すると 3 GB ほどに膨れ上がります。

* https://dumps.wikimedia.org/enwiktionary/<br>
  enwiktionary-20200501-categorylinks.sql.gz 344.6 MB

これを変換します。出力されるファイルは 2.6 GB ほどです。

```text
$ time python sql2tsv.py enwiktionary-20200501-categorylinks.sql

real    12m49.856s
user    12m36.641s
sys     0m12.750s

$ time python sql2tsv.py enwiktionary-20200501-categorylinks.sql.gz

real    13m5.832s
user    12m53.609s
sys     0m11.531s
```

行数は 2,800 万行にもなります。

```text
$ wc -l enwiktionary-20200501-categorylinks.tsv
28021874 enwiktionary-20200501-categorylinks.tsv
```

# F# 

F# に移植しました。

* <https://github.com/7shi/wiktionary-tools/blob/master/sql2tsv/sql2tsv.fsx>

計測結果は次にまとめます。Python に比べてかなり高速です。

# まとめ

計測結果を並べます。

ファイル|言語|時間
----|----|---:
jawiktionary-20200501-categorylinks.sql|Python|0m20.330s
jawiktionary-20200501-categorylinks.sql|F#|0m03.168s
jawiktionary-20200501-categorylinks.sql.gz|Python|0m20.751s
jawiktionary-20200501-categorylinks.sql.gz|F#|0m03.509s
enwiktionary-20200501-categorylinks.sql|Python|12m49.856s
enwiktionary-20200501-categorylinks.sql|F#|1m52.396s
enwiktionary-20200501-categorylinks.sql.gz|Python|13m05.832s
enwiktionary-20200501-categorylinks.sql.gz|F#|2m15.380s

圧縮ファイルを直接処理すると多少遅くはなりますが、ディスクスペースが節約できるため有利です。

# 関連記事

今回のスクリプトは以下の記事で使用しています。

* [Wiktionaryの効率的な処理方法を探る](https://qiita.com/7shi/items/e8091f6ac72491ad45a6)
