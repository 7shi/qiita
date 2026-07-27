---
coediting: false
comments_count: 0
created_at: '2023-11-03T22:26:06+09:00'
id: 6000e9ce33145bec49a0
likes_count: 2
private: false
reactions_count: 0
stocks_count: 0
tags:
- name: Python
  versions: []
- name: Unicode
  versions: []
title: Unicode 正規化と文字操作
updated_at: '2023-11-06T14:05:04+09:00'
url: https://qiita.com/7shi/items/6000e9ce33145bec49a0
slide: false
---

Unicode 正規化を文字操作に応用します。

合成文字はデータ数と文字数が一致しないなど Unicode の複雑性として言及されることが多いですが、便利な一面もあります。

# Unicode 正規化

Unicode には文字の構成要素をまとめて 1 つのコードで表す NFC と、構成要素を別々にコード化する NFD という正規化方式があります。

※ その他 NFKC と NFKD もありますが、この記事では扱いません。

https://ja.wikipedia.org/wiki/Unicode%E6%AD%A3%E8%A6%8F%E5%8C%96

正規化を処理する API として、Python には `unicodedata.normalize` があります。

* [unicodedata --- Unicode データベース — Python 3.12.0 ドキュメント](https://docs.python.org/ja/3/library/unicodedata.html)

## 濁点

「が」という平仮名を例に説明します。NFC ではまとめて 1 つのコードで表しますが、NFD では「か」と「゛」に分解したコードで表します。

```python
>>> import unicodedata
>>> def tohex(s):
...     return " ".join([f"{ord(ch):04x}" for ch in s])
...
>>> tohex(unicodedata.normalize("NFC", "が"))
'304c'
>>> tohex(unicodedata.normalize("NFD", "が"))
'304b 3099'
>>> chr(0x304b)
'か'
>>> chr(0x3099)
'゙'
```

※ `"\uXXXX"` という指定方法もあります。今後はこちらを使用します。

```python
>>> "\u304b"
'か'
```

分解すると `len` が文字数とは一致しなくなることに注意が必要です。

```python
>>> len("が")
1
>>> len(unicodedata.normalize("NFD", "が"))
2
```

`unicodedata.name` で Unicode 規格での文字の名前が確認できます。

```python
>>> unicodedata.name("\u304c")
'HIRAGANA LETTER GA'
>>> unicodedata.name("\u304b")
'HIRAGANA LETTER KA'
>>> unicodedata.name("\u3099")
'COMBINING KATAKANA-HIRAGANA VOICED SOUND MARK'
```

※ 合成に使われる付加記号類には COMBINING で始まる名前が付けられます。結合文字と呼ばれます。

https://ja.wikipedia.org/wiki/%E5%90%88%E6%88%90%E6%B8%88%E3%81%BF%E6%96%87%E5%AD%97

`unicodedata.decomposition` でどのように分解されるか確認できます。「か」はこれ以上分解できないため空文字列が返されます。

```python
>>> unicodedata.decomposition("か")
''
>>> unicodedata.decomposition("が")
'304B 3099'
````

※ 文字コードが文字列で返されるため、先ほど定義した `tohex` は不要です。

## 複数の付加記号

アルファベットには複数の付加記号（アクセント類）が付くことがあり、NFD では記号ごとに分解されます。

```python
>>> tohex(unicodedata.normalize("NFD", "ḉ"))
'0063 0327 0301'
>>> unicodedata.name("ḉ")
'LATIN SMALL LETTER C WITH CEDILLA AND ACUTE'
>>> unicodedata.name("\u0063")
'LATIN SMALL LETTER C'
>>> unicodedata.name("\u0327")
'COMBINING CEDILLA'
>>> unicodedata.name("\u0301")
'COMBINING ACUTE ACCENT'
```

`decomposition` は 2 段階で定義されます。`normalize` ではこれを一度に処理します。

```python
>>> unicodedata.decomposition("ḉ")
'00E7 0301'
>>> "\u00e7"
'ç'
>>> unicodedata.decomposition("ç")
'0063 0327'
>>> unicodedata.name("ç")
'LATIN SMALL LETTER C WITH CEDILLA'
```

この場合、付加記号の順番を変えても NFC での合成に影響はありません。

```python
>>> tohex(unicodedata.normalize("NFC", "\u0063\u0327\u0301"))
'1e09'
>>> tohex(unicodedata.normalize("NFC", "\u0063\u0301\u0327"))
'1e09'
```

付加記号の並びで異なる文字を表すこともあります。その組み合わせが規格で定義されているかに依存するため、規則性はありません。

```python
>>> tohex(unicodedata.normalize("NFD", "ǖ"))
'0075 0308 0304'
>>> tohex(unicodedata.normalize("NFD", "ṻ"))
'0075 0304 0308'
>>> unicodedata.name("\u0075")
'LATIN SMALL LETTER U'
>>> unicodedata.name("\u0308")
'COMBINING DIAERESIS'
>>> unicodedata.name("\u0304")
'COMBINING MACRON'
```

ある記号がどのような文字と組み合わせられるかは、Unicode 規格書や Wikipedia で確認できます。

https://unicode.org/standard/standard.html

https://ja.wikipedia.org/wiki/%E3%83%80%E3%82%A4%E3%82%A2%E3%82%AF%E3%83%AA%E3%83%86%E3%82%A3%E3%82%AB%E3%83%AB%E3%83%9E%E3%83%BC%E3%82%AF

# 文字操作

通常の利用ではデータ量が抑えられる NFC 正規化が有利です。

文字の操作には NFD が有用です。いくつか例を示します。

## 濁点を付ける

濁点を表す付加記号を付けるだけです。

```python
>>> def dakuten(ch):
...     return ch + "\u3099"
...
>>> dakuten("さ")
'ざ'
>>> dakuten("ツ")
'ヅ'
```

このままだとデータ量が大きくなってしまいます。

```python
>>> len(dakuten("さ"))
2
>>> tohex(dakuten("さ"))
'3055 3099'
```

`return` の前に `NFC` で合成した方が良いでしょう。

```python
>>> def dakuten(ch):
...     return unicodedata.normalize("NFC", ch + "\u3099")
...
>>> tohex(dakuten("さ"))
'3056'
```

濁点を付加すると文字コードが 1 つ増えるだけに見えますが、例外はあります。

```python
>>> tohex("か"), tohex(dakuten("か"))
('304b', '304c')
>>> tohex("は"), tohex(dakuten("は"))
('306f', '3070')
>>> tohex("う"), tohex(dakuten("う"))
('3046', '3094')
```

一般的に、ある記号を付けたときの文字コードの変化には規則性がありません。正規化をライブラリに任せれば、文字コードの変化を知らなくても処理が書けるので便利です。

# 濁点を取り除く

NFD で分解して最初の 1 文字だけを残せば、一律に濁点が取り除けます。

```python
>>> def strip(text):
...     return "".join([unicodedata.normalize("NFD", ch)[0] for ch in text])
...
>>> strip("がぎぐげご")
'かきくけこ'
```

## 転写

ある文字から別の文字に書き換えるのにも利用できます。（転写）

古代ギリシア語は付加記号類が多く、アルファベットに転写するため Unicode 正規化を利用しました。

https://github.com/7shi/greektrans

```python
>>> import greektrans
>>> greektrans.romanize("Πάτερ ἡμῶν ὁ ἐν τοῖς οὐρανοῖς·")
'Páter hēmôn ho en tóès ūranóès;'
```

基本的には濁点を付ける例と同じことをやっています。当初は NFD で分解せずに NFC 正規化された状態で処理していたため、変換部分はすべてテーブルに依存していました。NFD で分解して扱うことによって、コードで付加記号を明示的に記述できるようになりました。記号の変更にも対応しやすいです。

転写の詳細はこちらを参照してください。

* [古代ギリシア語のローマ字転写 - 七誌の開発日記](https://7shi.hateblo.jp/entry/2023/11/04/005458)
