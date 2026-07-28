---
coediting: false
comments_count: 0
created_at: '2020-06-12T21:52:09+09:00'
id: 2a945c346f74ca54552f
likes_count: 2
private: false
reactions_count: 0
stocks_count: 2
tags:
- name: Python
  versions: []
- name: Wiktionary
  versions: []
title: Wiktionaryで英語の不規則動詞を調査
updated_at: '2020-06-27T04:59:04+09:00'
url: https://qiita.com/7shi/items/2a945c346f74ca54552f
slide: false
---

Wiktionary の全文から特定の言語が抽出できるようになりました。意味のある情報を取り出す例として、英語の不規則動詞を調査します。

シリーズの記事です。

1. [Wiktionaryの効率的な処理方法を探る](https://qiita.com/7shi/items/e8091f6ac72491ad45a6)
1. [Wiktionaryの処理速度をF#とPythonで比較](https://qiita.com/7shi/items/1d6b97c657c6fffdbd70)
1. [Wiktionaryの言語コードを取得](https://qiita.com/7shi/items/4e3c614aac19d645fd1d)
1. [Wiktionaryから特定の言語を抽出](https://qiita.com/7shi/items/449e1aeaee3a25ca5a05)
1. Wiktionaryで英語の不規則動詞を調査 ← この記事
1. [Wiktionaryのスクリプトをローカルで動かす](https://qiita.com/7shi/items/6d1e8466b7586e5d0e90)

この記事のスクリプトは以下のリポジトリに掲載しています。

* <https://github.com/7shi/wiktionary-tools/tree/master/python/en-verb>

# 概要

Wiktionary から英語を抽出して、動詞の変化形を抽出します。

得られたデータを何段階かで分析して、不規則動詞を抽出します。

# 動詞の情報

see を例に、英語の動詞の変化形がどのように格納されているかを確認します。

* <https://en.wiktionary.org/wiki/see#Verb>

> **see** (third-person singular simple present **sees**, present participle **seeing**, simple past **saw** or (dialectal) **seen** or (dialectal) **seent** or (dialectal) **seed**, past participle **seen** or (dialectal) **seent** or (dialectal) **seed**)

文章での記述になっており、dialectal など別形の情報もあるため、これをプログラムでパースするのは難しそうです。

ソースを確認すると、処理しやすい形式になっています。

```text
{{en-verb|sees|seeing|saw|past2=seen|past2_qual=dialectal|past3=seent|past3_qual=dialectal|past4=seed|past4_qual=dialectal|seen|past_ptc2=seent|past_ptc2_qual=dialectal|past_ptc3=seed|past_ptc3_qual=dialectal}}
```

`past2=` などの追加情報を削ればすっきりします。

```text
{{en-verb|sees|seeing|saw|seen}}
```

原形はページのタイトルから取得する仕様のため、ここには含まれません。

`{{en-verb}}` の仕組みについては[次回の記事](https://qiita.com/7shi/items/6d1e8466b7586e5d0e90)で説明します。今回は仕組みには立ち入らないで、記述から読み取れる範囲で処理します。

## 抽出

[前回](https://qiita.com/7shi/items/449e1aeaee3a25ca5a05)のスクリプトを使って、Wiktionary のダンプから英語を抽出します。

```shell-session
$ python collect-lang.py enwiktionary.db English
reading positions... 928,987 / 928,987
optimizing... 49,835 -> 6,575
reading streams... 6,575 / 6,575
English: 928,988
```

``{{en-verb...}}`` を集めます。見出し語にスペースやハイフンが含まれるものは熟語または複合語として除外します。

```python:en-verb-1.py
import re, sys
pattern = re.compile("<!-- <title>(.*)</title> -->")
title = ""
for line in sys.stdin:
    if (m := pattern.match(line)):
        title = m[1]
    elif line.startswith("{{en-verb"):
        if not (" " in title or "-" in title):
            print(f"{title}\t{line.strip()}")
```
```shell-session:実行結果
$ python en-verb-1.py < English.txt > en-verb-1.tsv
$ wc -l en-verb-1.tsv
31336 en-verb-1.tsv
```

# データの整形

取得したデータを処理しやすいように整形します。

## リンクとコメントの除去

取得したデータを見るとリンクやコメントが入っています。

```text
$ grep "\[" en-verb-1.tsv | head -n 2
bequeath        {{en-verb|bequeaths|bequeathing|bequeathed|past2=[[bequoth]]|past2_qual=obsolete|bequeathed|past_ptc2=bequethen|past_ptc2_qual=rare}}
daylight        {{en-verb|head=[[daylight]]|daylights|daylighting|daylighted|past2=daylit}}
$ grep '<!--' en-verb-1.tsv | head -n 2
backcast        {{en-verb}} <!--possibly "backcast" as past tense?-->
benim   {{en-verb|benims|benimming|benam<!--?-->|benomen<!--?-->|past_ptc2=benome|past_ptc3=benumb}}
```

リンクの括弧とコメントを取り除きます。リンクで `[[:en:#Etymology_2|read]]` のように中が `|` で区切られているものは、最後の要素（この例では `read`）を残します。

```python:en-verb-2.py
import re, sys
pattern1 = re.compile(r"\[\[(.+?)\]\]")
pattern2 = re.compile("<!--(.*?)-->")
for line in sys.stdin:
    while (m := pattern1.search(line)):
        data = m[1].split("|")
        line = line[:m.start()] + data[-1] + line[m.end():]
    sys.stdout.write(pattern2("", line))
```
```shell-session:実行結果
$ python en-verb-2.py < en-verb-1.tsv > en-verb-2.tsv
$ diff -U 0 en-verb-1.tsv en-verb-2.tsv | head -n 11
--- en-verb-1.tsv       2020-06-16 21:24:23.801172600 +0900
+++ en-verb-2.tsv       2020-06-16 21:27:32.049432800 +0900
@@ -1460 +1460 @@
-backcast       {{en-verb}} <!--possibly "backcast" as past tense?-->
+backcast       {{en-verb}}
@@ -2213 +2213 @@
-benim  {{en-verb|benims|benimming|benam<!--?-->|benomen<!--?-->|past_ptc2=benome|past_ptc3=benumb}}
+benim  {{en-verb|benims|benimming|benam|benomen|past_ptc2=benome|past_ptc3=benumb}}
@@ -2242 +2242 @@
-bequeath       {{en-verb|bequeaths|bequeathing|bequeathed|past2=[[bequoth]]|past2_qual=obsolete|bequeathed|past_ptc2=bequethen|past_ptc2_qual=rare}}
+bequeath       {{en-verb|bequeaths|bequeathing|bequeathed|past2=bequoth|past2_qual=obsolete|bequeathed|past_ptc2=bequethen|past_ptc2_qual=rare}}
```

## 追加情報の除去

read の `past_ptc2=readen` のような追加情報は、方言や古い資料を調べるなら必要ですが、今回は取り除きます。`}}` の後に別の情報があればそれも取り除きます。

```python:en-verb-3.py
import re, sys
pattern1 = re.compile("{{(.*?)}}")
pattern2 = re.compile("[a-z0-9_]+?=")
for line in sys.stdin:
    if (m := pattern1.search(line)):
        data = [d for d in m[1].split("|") if not pattern2.match(d)]
        line = line[:m.start()] + "{{" + "|".join(data) + "}}\n"
    sys.stdout.write(line)
```
```shell-session:実行結果
$ python en-verb-3.py < en-verb-2.tsv > en-verb-3.tsv
$ diff -U 0 en-verb-2.tsv en-verb-3.tsv | head -n 8
--- en-verb-2.tsv       2020-06-16 21:27:32.049432800 +0900
+++ en-verb-3.tsv       2020-06-16 21:29:09.244774500 +0900
@@ -23 +23 @@
-86     {{en-verb}} {{lb|en|US}}
+86     {{en-verb}}
@@ -46 +46 @@
-abear  {{en-verb|abears|abearing|abore|aborn|past_ptc2=aborne}}
+abear  {{en-verb|abears|abearing|abore|aborn}}
```

# 規則動詞

今回は不規則動詞の調査が目的なので、規則動詞を除外します。

先ほど生成したデータから規則動詞の記述方法を確認します。

```text
open    {{en-verb}}
like    {{en-verb|lik}}
wish    {{en-verb|es}}
hone    {{en-verb|hon|es}}
chop    {{en-verb|chop|p|ing}}
compel  {{en-verb|compel|l|ed}}
```

これは次のような意味のようです。ハイフンは語幹と語尾の区切りです。

単語|三単現|現在分詞|過去分詞|解釈
----|----|----|----|----
open|open-s|open-ing|open-ed|語形の情報なし
like|like-s|lik-ing|lik-ed|後ろ2つの語幹 lik
wish|wish-es|wish-ing|wish-ed|三単現 es
hone|hon-es|hon-ing|hon-ed|語幹 hon と三単現 es
chop|chop-s|chop-p-ing|chop-p-ed|重複 p と現在分詞 ing
compel|compel-s|compel-l-ing|compel-l-ed|重複 l と過去形 ed

like と hone は同じパターンですが、どちらの書き方でも同じ結果になるようです。ハイフンの位置が違いますが、これは言語学的な意味があるわけではなく、変化形を生成するプログラムを想定したものです。

追加情報がないか、2項までか、3項目が ing か ed の単語は取り除きます。ついでに始まりの `{{en-verb|` と 終わりの `}}` も取り除いてタブ区切りにします。

```python:en-verb-4.py
import re, sys
pattern = re.compile("{{en-verb\\|(.*?)\\|*}}")
for line in sys.stdin:
    verb, forms = line.split("\t")
    if (m := pattern.match(forms)):
        forms = m[1].split("|")
        if len(forms) > 2 and forms[2] != "ing" and forms[2] != "ed":
            forms = "\t".join(forms)
            print(f"{verb}\t{forms}")
```
```shell-session:実行結果
$ python en-verb-4.py < en-verb-3.tsv > en-verb-4.tsv
$ wc -l en-verb-4.tsv
5298 en-verb-4.tsv
```

ある程度は絞り込めましたが、まだ多いです。

## 語形の調査

データを見ると、語幹を指定する記法で統一されてはいないようで、規則動詞が混じっています。

```text
crow    crows   crowing crowed  crowed
swop    swops   swopping    swopped
```

三単現と現在分詞と別形の情報は無視して、次の条件を満たすものは規則動詞として除外します。

1. 過去形の記載がない。
1. 過去形と過去分詞が同形で ed で終わる。
1. 原形が e で終わり、過去形は原形に d を付加。
1. 原形が y で終わり、過去形は y を i に変えて ed を付加。
1. 過去形は原形に ed を付加。
1. 過去形は原形の末尾の文字を重複させて ed を付加。（末尾 c には k を続ける単語がある）

文字の重複については条件がありますが、今回は必要ないため立ち入りません。

アポストロフィーが入った単語は記号を取り除いて判定します。

```text
127005	F	F's|F'ing|F'ed
```

過去形と過去分詞がともに `-` で未定義のものは取り除きます。

```python:en-verb-5.py
import sys
for line in sys.stdin:
    forms = line.strip().split("\t")
    if len(forms) == 4: forms.append(forms[3])
    verb, _, _, past, pp = [f.replace("'", "").replace("-", "") for f in forms]
    if past == pp:
        if not past: continue
        if past.endswith("ed"):
            if verb.endswith("e") and verb + "d" == past: continue
            if verb.endswith("y") and verb[:-1] + "ied" == past: continue
            if verb + "ed" == past: continue
            if verb + verb[-1] + "ed" == past: continue
            if verb[-1] == "c" and verb + "ked" == past: continue
    print("\t".join(forms))
```
```shell-session:実行結果
$ python en-verb-5.py < en-verb-4.tsv > en-verb-5.tsv
$ wc -l en-verb-5.tsv
1462 en-verb-5.tsv
```

# 同じパターンの除去

データを見ると、同じ単語が複数並んでいることがあります。

```text
think   thinks  thinking    thought thought
think   thinks  thinking    thought thought
```

また、複合語などで変化が同じパターンのものがあります。

```text
draw    draws   drawing drew    drawn
overdraw    overdraws   overdrawing overdrew    overdrawn
withdraw    withdraws   withdrawing withdrew    withdrawn
```

同じ単語を1つにまとめて、同じパターンは短い単語だけに絞ります。

```python:en-verb-6.py
import sys
verbs = {}
for line in sys.stdin:
    verb, *forms = line.strip().split("\t")
    if verb in verbs: continue
    verbs[verb] = forms
verbs2 = []
for v1 in verbs.items():
    contains = False
    for v2 in verbs.items():
        if v1[0] != v2[0] and v1[0].endswith(v2[0]):
            c = True
            for f1, f2 in zip(v1[1], v2[1]):
                if not f1.endswith(f2):
                    c = False
                    break
            if c:
                contains = True
                break
    if not contains:
        print("\t".join([v1[0]] + v1[1]))
```
```shell-session:実行結果
$ python en-verb-6.py < en-verb-5.tsv > en-verb-6.tsv
$ wc -l en-verb-6.tsv
379 en-verb-6.tsv
```

かなり絞り込めました。できたファイルを置いておきます。

* <https://github.com/7shi/wiktionary-tools/blob/master/python/en-verb/en-verb-6.tsv>

後は個別に手動で修正するのが現実的でしょう。

# 応用

今回の手法を応用すれば、英語以外の言語も調査できます。もちろん Wiktionary だけで情報が網羅されているとは限りませんが、プログラムを書けばすぐに情報は集まるため、手始めに見てみるには良さそうです。

新しい言語を学習する際に、自習用の資料を自作するのにも役立ちそうです。

私の方で何か試せば追記します。
