---
coediting: false
comments_count: 0
created_at: '2020-04-19T03:11:03+09:00'
id: bfb66e69672c08480b0b
likes_count: 0
private: false
reactions_count: 0
stocks_count: 1
tags:
- name: SQL
  versions: []
- name: SQLite3
  versions: []
- name: Tatoeba
  versions: []
title: 複数言語を指定して多言語の例文データを抽出
updated_at: '2020-06-05T10:15:29+09:00'
url: https://qiita.com/7shi/items/bfb66e69672c08480b0b
slide: false
---

Tatoeba という多言語例文サイトがあります。データは CC ライセンスで提供されています。

* https://tatoeba.org/jpn/downloads

> このページにあるファイルは、プログラムを組んで利用するためのものです。

今回は次の2つのファイルを使用します。

1. sentences.tar.bz2
2. links.tar.bz2

これらを SQLite に格納して、指定した言語の組み合わせで例文を抽出します。

```text:動作イメージ：英語・フランス語・日本語
eng: What is it?
fra: Qu'est-ce que c'est ?
jpn: これは何ですか。

eng: I will be back soon.
fra: Je serai bientôt de retour.
jpn: すぐに戻ります。
```

# 例文

まず本体の例文データを処理します。

sentences.tar.bz2 を展開します。入っているのは sentences.csv という1ファイルだけです。タブ区切りのテキストファイルです。

> 例文番号 [tab] 言語名 [tab] 例文

※ 2020年4月18日現在、展開後のファイルサイズは436MB、例文数は828万件です。毎日1,000件以上のペースで増えているようです。

## 取り込み

SQLite3 を起動します。指定したファイル名でデータベースが作成されます。

```text
$ sqlite3 tatoeba.db
SQLite version 3.31.1 2020-01-27 19:55:54
Enter ".help" for usage hints.
```

初期設定を行います。取り込み元データにダブルクォーテーションが含まれている関係上、通常のタブ区切りを指定してもうまくいかないため、ascii で区切り文字を指定します。

```sql
.headers on
.mode ascii
.separator "\t" "\n"
```

SQLite に取り込みます。

```sql
CREATE TABLE sentences(id INTEGER, lang CHAR(8), text TEXT);
.import sentences.csv sentences
```

## 確認

最初の5件を表示します。中国語です。

```sql
SELECT * FROM sentences LIMIT 5;
```
```text:実行結果
id      lang    text
1       cmn     我們試試看！
2       cmn     我该去睡觉了。
3       cmn     你在干什麼啊？
4       cmn     這是什麼啊？
5       cmn     今天是６月１８号，也是Muiriel的生日！
```

英語の例文を5件表示します。

```sql
SELECT * FROM sentences WHERE lang = 'eng' LIMIT 5;
```
```text:実行結果
id      lang    text
1276    eng     Let's try something.
1277    eng     I have to go to sleep.
1280    eng     Today is June 18th and it is Muiriel's birthday!
1282    eng     Muiriel is 20 now.
1283    eng     The password is "Muiriel".
```

上位5言語を表示します。

```sql
SELECT lang, count(*) AS c FROM sentences GROUP BY lang ORDER BY count DESC LIMIT 5;
```
```text:実行結果
lang    c
eng     1314951
rus     760210
ita     748858
tur     689489
epo     617347
```

言語ごとの例文数はサイトにも掲載されており、言語の略称が何を指すのかも確認できます。

* https://tatoeba.org/jpn/stats/sentences_by_language

※ 略称は ISO 639-3 に準拠しています。

* [Download Tables | ISO 639-3](https://iso639-3.sil.org/code_tables/download_tables)

## 正規化

データベースとして扱いやすくするため正規化を試みます。

### 言語名

言語名を専用のテーブルで管理して番号を割り振ります。

```sql
CREATE TABLE langs(lid INTEGER PRIMARY KEY, name CHAR(8));
INSERT INTO  langs(name)
    SELECT DISTINCT lang FROM sentences ORDER BY lang;
CREATE INDEX langs_lang_idx ON langs(name);
```

内容を確認します。

```sql
SELECT * FROM langs LIMIT 5;
```
```text:実行結果
lid     name
1       \N
2       abk
3       acm
4       ady
5       afb
```

※ `\N` は良く分かりませんが、削除された項目のようです。

### 言語

先ほど割り当てた番号を使って、例文番号と言語のテーブルを作成します。

```sql
CREATE TABLE slang(id INTEGER PRIMARY KEY, lang INTEGER);
INSERT INTO  slang
    SELECT id, lid FROM sentences
    INNER JOIN langs ON lang = name;
CREATE INDEX slang_lang_idx ON slang(lang);
```

内容を確認します。

```sql
SELECT * FROM slang LIMIT 5;
```
```text:実行結果
id      lang
1       59
2       59
3       59
4       59
5       59
```

言語名を取得するには内部結合を使用します。

```sql
SELECT * FROM slang INNER JOIN langs ON lang = lid LIMIT 5;
```
```text:実行結果
id      lang    lid     name
1       59      59      cmn
2       59      59      cmn
3       59      59      cmn
4       59      59      cmn
5       59      59      cmn
```

### 例文

例文番号と例文のテーブルを作成します。

```sql
CREATE TABLE stext(id INTEGER PRIMARY KEY, text TEXT);
INSERT INTO  stext SELECT id, text FROM sentences;
```

内容を確認します。

```sql
SELECT * FROM stext LIMIT 5;
```
```text:実行結果
id      text
1       我們試試看！
2       我该去睡觉了。
3       你在干什麼啊？
4       這是什麼啊？
5       今天是６月１８号，也是Muiriel的生日！
```

元データを復元するには内部結合を組み合わせます。

```sql
SELECT stext.id, name as lang, text FROM stext
INNER JOIN slang ON slang.id = stext.id
INNER JOIN langs ON lang = lid
LIMIT 5;
```
```text:実行結果
id      lang    text
1       cmn     我們試試看！
2       cmn     我该去睡觉了。
3       cmn     你在干什麼啊？
4       cmn     這是什麼啊？
5       cmn     今天是６月１８号，也是Muiriel的生日！
```

# リンク

翻訳を対応付けるにはリンクのデータを使用します。

links.tar.bz2 を展開します。入っているのは links.csv という1ファイルだけです。タブ区切りのテキストファイルです。

> 例文番号 [tab] 訳の例文番号

※ 2020年4月18日現在、展開後のファイルサイズは256MBです。

## 取り込み

SQLite に取り込みます。

```sql
CREATE TABLE links(id INTEGER, link INTEGER);
.import links.csv links
CREATE INDEX links_id_idx ON links(id);
```

## 確認

内容を確認します。

```sql
SELECT * FROM links LIMIT 5;
```
```text:実行結果
id      link
1       1276
1       2481
1       5350
1       5972
1       180624
```

id が指す例文に対しての翻訳が列挙されています。内部結合によって翻訳を確認します。

```sql
SELECT links.id, link, name as lang, text FROM links
INNER JOIN slang ON slang.id = link
INNER JOIN stext ON stext.id = link
INNER JOIN langs ON lang = lid
LIMIT 5;
```
```text:実行結果
id      link    lang    text
1       1276    eng     Let's try something.
1       2481    spa     ¡Intentemos algo!
1       5350    kor     뭔가 해보자!
1       5972    nld     Laten we iets proberen!
1       180624  por     Vamos tentar alguma coisa!
```

# 言語を指定して抽出

指定した言語間で翻訳が存在する例文を抽出します。

## 1つの言語への翻訳

例として、英語の例文に対して日本語の翻訳が存在するものを抽出します。

```sql
WITH slname AS (SELECT id, name AS lang FROM slang INNER JOIN langs ON lid = lang),
llang AS (SELECT links.id, link, lang FROM links INNER JOIN slname ON slname.id = link)
SELECT t.id, t.lang, l1.link, l1.lang
FROM (SELECT id, lang FROM slname WHERE lang = 'eng') AS t
INNER JOIN llang AS l1 ON l1.id = t.id AND l1.lang = 'jpn'
LIMIT 5;
```
```text:実行結果
id      lang    link    lang
1276    eng     4702    jpn
1277    eng     4703    jpn
1277    eng     344904  jpn
1280    eng     4705    jpn
1282    eng     4707    jpn
```

1277が2つあるのは、1つの英文に対して複数の和訳が存在することを表します。

## 2つの言語への翻訳

例として、英語の例文に対して日本語とチェコ語（ces）の翻訳が存在するものを抽出します。

```sql
WITH slname AS (SELECT id, name AS lang FROM slang INNER JOIN langs ON lid = lang),
llang AS (SELECT links.id, link, lang FROM links INNER JOIN slname ON slname.id = link)
SELECT t.id, t.lang, l1.link, l1.lang, l2.link, l2.lang
FROM (SELECT id, lang FROM slname WHERE lang = 'eng') AS t
INNER JOIN llang AS l1 ON l1.id = t.id AND l1.lang = 'jpn'
INNER JOIN llang AS l2 ON l2.id = t.id AND l2.lang = 'ces'
LIMIT 5;
```
```text:実行結果
id      lang    link    lang    link    lang
1276    eng     4702    jpn     338207  ces
1277    eng     4703    jpn     338210  ces
1277    eng     344904  jpn     338210  ces
1280    eng     4705    jpn     338214  ces
1280    eng     4705    jpn     3564938 ces
```

このやり方だと、1つの例文に対して日本語とチェコ語の翻訳が複数あれば、結果が無駄に増えてしまいます。そのため個別の link を表示するのは諦めて、id だけを表示するようにします。

```sql
WITH slname AS (SELECT id, name AS lang FROM slang INNER JOIN langs ON lid = lang),
llang AS (SELECT links.id, link, lang FROM links INNER JOIN slname ON slname.id = link)
SELECT DISTINCT t.id
FROM (SELECT id, lang FROM slname WHERE lang = 'eng') AS t
INNER JOIN llang AS l1 ON l1.id = t.id AND l1.lang = 'jpn'
INNER JOIN llang AS l2 ON l2.id = t.id AND l2.lang = 'ces'
LIMIT 5;
```
```text:実行結果
id
1276
1277
1280
1282
1283
```

## 間接訳

先ほどの実行結果から一部を引用します。

```
id      lang    link    lang    link    lang
1276    eng     4702    jpn     338207  ces
```

4702に対する翻訳を表示します。

```sql
SELECT t.id, link, name as lang, text
FROM (SELECT * FROM links WHERE id = 4702) as t
INNER JOIN slang ON slang.id = link
INNER JOIN stext ON stext.id = link
INNER JOIN langs ON lang = lid;
```
```text:実行結果
id      link    lang    text
4702    77      deu     Lass uns etwas versuchen!
4702    1276    eng     Let's try something.
4702    2481    spa     ¡Intentemos algo!
4702    3091    fra     Essayons quelque chose !
4702    5350    kor     뭔가 해보자!
4702    5409    rus     Давайте что-нибудь попробуем!
4702    5972    nld     Laten we iets proberen!
4702    180624  por     Vamos tentar alguma coisa!
4702    349370  pol     Spróbujmy coś zrobić!
4702    2431762 cmn     做点儿什么尝试下吧。
4702    2740008 fin     Yritetään jotain.
4702    3389511 fin     Yritetäänpä tehdä jotain.
4702    3864964 ita     Proviamo a fare qualcosa.
4702    4713467 ind     Mari kita mencoba melakukan sesuatu.
```

チェコ語（ces）がありません。これが意味するのは、1276 (eng) に対する翻訳に 4702 (jpn) と 338207 (ces) が含まれますが、4702 (jpn) に対する翻訳に 338207 (ces) は含まれないということです。

Tatoeba のサイトで 4702 を表示すると、338207 "Zkusme něco!" は「間接訳」という扱いになります。

* https://tatoeba.org/jpn/sentences/show/4702

間接訳を実装するには、リンクされている例文から更にリンクをたどる必要があります。

## 言語別リンクテーブル

今回は実装の容易さを優先して、間接訳を調べるのではなく、次のような方針で処理します。

例えば日本語とチェコ語のペアを抽出する場合、日本語の例文にチェコ語の翻訳がリンクされているケースだけでなく、チェコ語の例文に日本語がリンクされているケースと、他の言語の例文に対して日本語とチェコ語の翻訳がリンクされているケースも抽出します。

処理を容易にするため、例文の言語とリンクされている言語を混ぜたテーブルを作ります。

```sql
CREATE TABLE llang(id INTEGER, lang INTEGER);
INSERT INTO  llang
    SELECT * FROM slang
    UNION
    SELECT DISTINCT links.id AS id, lang FROM links
    INNER JOIN slang ON link = slang.id;
CREATE INDEX llang_id_idx   ON llang(id);
CREATE INDEX llang_lang_idx ON llang(lang);
```

内容を確認します。

```sql
SELECT * FROM llang LIMIT 5;
```
```text:実行結果
id      lang
1       16
1       33
1       34
1       43
1       59
```

## 組み合わせの抽出

指定した言語の組み合わせで例文を抽出するためには、ある id に対して指定した言語がすべて含まれているかを調べます。

例として英語・日本語・チェコ語の組み合わせを抽出します。

```sql
WITH lname AS (SELECT id, name AS lang FROM llang INNER JOIN langs ON lid = lang)
SELECT t.id FROM (SELECT id FROM lname WHERE lang = 'eng') AS t
INNER JOIN lname AS l1 ON l1.id = t.id AND l1.lang = 'jpn'
INNER JOIN lname AS l2 ON l2.id = t.id AND l2.lang = 'ces'
LIMIT 5;
```
```text:実行結果
id
3
35
39
42
43
```

抽出した組み合わせに対してテキストを表示します。

```sql
WITH lname AS (SELECT id, name AS lang FROM llang INNER JOIN langs ON lid = lang),
ids AS (
    SELECT t.id AS id1 FROM (SELECT id FROM lname WHERE lang = 'eng') AS t
    INNER JOIN lname AS l1 ON l1.id = t.id AND l1.lang = 'jpn'
    INNER JOIN lname AS l2 ON l2.id = t.id AND l2.lang = 'ces' LIMIT 3),
sentences AS (
    SELECT slang.id AS sid, name AS lang, text FROM slang
    INNER JOIN langs ON lid = lang
    INNER JOIN stext ON stext.id = slang.id)
SELECT * FROM (
    SELECT id1 AS id, sid AS link, lang, text FROM ids
    INNER JOIN sentences ON sid = id1
    UNION ALL
    SELECT id, link, lang, text FROM ids
    INNER JOIN links ON links.id = id1
    INNER JOIN sentences ON sid = link)
WHERE lang IN ('eng', 'jpn', 'ces') ORDER BY id, lang;
```
```text:実行結果
id      link    lang    text
3       338213  ces     Co děláš?
3       16492   eng     What are you doing?
3       4704    jpn     何してるの？
3       187615  jpn     何をしているの。
3       344912  jpn     何をしていますか。
35      1058169 ces     Takhle nemůžu žít.
35      1315    eng     I can't live that kind of life.
35      4742    jpn     私はそんな風には生きられない。
39      1058175 ces     Většina lidí si myslí, že jsem blázen.
39      1322    eng     Most people think I'm crazy.
39      4747    jpn     大抵の人は僕を気違いだと思っている。
```

これが今回やりたかったことです。

# スクリプト

処理を Python スクリプトにまとめました。

* https://gist.github.com/7shi/8ce48804556420f18d0fa1fcead6fa56

コマンドラインオプションで複数言語を指定して例文を抽出できます。

※ `-n` は表示する例文の数、`-m` は1つの例文に対して表示する翻訳の上限です。

```text
$ python gets.py -n 3 -m 1 eng jpn ces
sentences: 8141

#3 cmn: 你在干什麼啊？
eng: What are you doing?
jpn: 何してるの？
ces: Co děláš?

#35 cmn: 我不能活那種命。
eng: I can't live that kind of life.
jpn: 私はそんな風には生きられない。
ces: Takhle nemůžu žít.

#39 cmn: 大部份的人覺得我瘋了。
eng: Most people think I'm crazy.
jpn: 大抵の人は僕を気違いだと思っている。
ces: Většina lidí si myslí, že jsem blázen.
```

今後は抽出した例文の活用方法を考えたいです。

# 関連記事

多言語辞書 Wiktionary のダンプからデータを抽出する記事です。

* [Wiktionaryの効率的な処理方法を探る](https://qiita.com/7shi/items/e8091f6ac72491ad45a6)
