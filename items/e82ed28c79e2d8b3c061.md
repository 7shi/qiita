---
coediting: false
comments_count: 0
created_at: '2024-01-06T15:17:35+09:00'
id: e82ed28c79e2d8b3c061
likes_count: 2
private: false
reactions_count: 0
stocks_count: 0
tags:
- name: Python
  versions: []
- name: JavaScript
  versions: []
- name: flatMap
  versions: []
- name: 内包表記
  versions: []
title: リスト内包表記の二重ループと flatMap
updated_at: '2024-07-03T02:59:22+09:00'
url: https://qiita.com/7shi/items/e82ed28c79e2d8b3c061
slide: false
---

Python でのリスト内包表記の二重ループと JavaScript での `flatMap` を比較します。順を追ってコードを構築します。

# 題材

ネストしたデータと、フラットなデータを考えます。

<table>
<tr><th>ネスト</th><td>1</td><td colspan="2">2 3</td><td colspan="3">4 5 6</td></tr>
<tr><th>フラット</th><td>1</td><td>2</td><td>3</td><td>4</td><td>5</td><td>6</td></tr>
</table>

構成を文字列で表現して、ネストしたリストに変換します。

* `1,2+3,4+5+6` → `[[1], [2, 3], [4, 5, 6]]`

コードを少し変形してフラット化します。

* `[[1], [2, 3], [4, 5, 6]]` → `[1, 2, 3, 4, 5, 6]`

# Python

:::note info
REPL での実行状況を示します。`>>> ` はプロンプトで、コードではありません。
:::

変換元の文字列を `a` とします。

```py
>>> a = "1,2+3,4+5+6"
```

まず `,` で区切ります。

```py
>>> b = a.split(",")
>>> b
['1', '2+3', '4+5+6']
```

各項目を `+` で区切ります。

```py
>>> c = [s.split("+") for s in b]
>>> c
[['1'], ['2', '3'], ['4', '5', '6']]
```

各項目を数値に変換します。リスト内包表記をネストさせます。

```py
>>> d = [[int(x) for x in xs] for xs in c]
>>> d
[[1], [2, 3], [4, 5, 6]]
```

ここまでの処理をまとめます。`c` や `b` を定義に置き換えます。

```py
>>> [[int(x) for x in xs] for xs in [s.split("+") for s in a.split(",")]]
[[1], [2, 3], [4, 5, 6]]
```

`xs` に入るのは `s.split("+")` であることに着目すれば、コードが整理できます。

```py
>>> [[int(x) for x in s.split("+")] for s in a.split(",")]
[[1], [2, 3], [4, 5, 6]]
```

:::note info
リスト内包表記がネストしていることは、結果のリストがネストしていることに対応します。
:::

ネストを解消して二重ループにすれば、結果はフラットなリストになります。単に内部の `[` `]` を外すだけでなく、`for` の順番が入れ変わっていることに注意してください。（通常の二重ループと同じ順番）

```py
>>> [int(x) for s in a.split(",") for x in s.split("+")]
[1, 2, 3, 4, 5, 6]
```

:::note info
コードの変形によって結果が変化することを示すのが狙いです。
:::

# JavaScript

:::note info
Node.js の REPL での実行状況を示します。`> ` はプロンプトで、コードではありません。
:::

まずステップごとに処理します。`map` を使います。

```js
> a = "1,2+3,4+5+6"
'1,2+3,4+5+6'
> b = a.split(",")
[ '1', '2+3', '4+5+6' ]
> c = b.map(s => s.split("+"))
[ [ '1' ], [ '2', '3' ], [ '4', '5', '6' ] ]
> d = c.map(xs => xs.map(x => parseInt(x)))
[ [ 1 ], [ 2, 3 ], [ 4, 5, 6 ] ]
```

メソッドチェーンで処理をつなぎます。

```js
> a.split(",").map(s => s.split("+")).map(xs => xs.map(x => parseInt(x)))
[ [ 1 ], [ 2, 3 ], [ 4, 5, 6 ] ]
```

コードを整理します。

```js
> a.split(",").map(s => s.split("+").map(x => parseInt(x)))
[ [ 1 ], [ 2, 3 ], [ 4, 5, 6 ] ]
```

:::note info
`map` がフラットなメソッドチェーンではなくネストしていることは、結果の配列がネストしていることに対応します。
:::

外側の `map` を `flatMap` に置き換えれば結果がフラットになります。

```js
> a.split(",").flatMap(s => s.split("+").map(x => parseInt(x)))
[ 1, 2, 3, 4, 5, 6 ]
```

# まとめ

コードのどこを変更しているかに注意します。

```py:Python
>>> a = "1,2+3,4+5+6"
>>> [[int(x) for x in s.split("+")] for s in a.split(",")]
[[1], [2, 3], [4, 5, 6]]
>>> [int(x) for s in a.split(",") for x in s.split("+")]
[1, 2, 3, 4, 5, 6]
```

```js:JavaScript
> a = "1,2+3,4+5+6"
'1,2+3,4+5+6'
> a.split(",").map(s => s.split("+").map(x => parseInt(x)))
[ [ 1 ], [ 2, 3 ], [ 4, 5, 6 ] ]
> a.split(",").flatMap(s => s.split("+").map(x => parseInt(x)))
[ 1, 2, 3, 4, 5, 6 ]
```

## 参考

`flatMap` がリスト内包表記の二重ループに対応することは、調べてみると以前から指摘されています。

https://qiita.com/_shimada/items/407749af47c110ba8322

> PythonでflatMapを使いたくなって調べてみたら、PythonにはなんとflatMapがなく、そういう時はネストしたリスト内包表記使うといろいろなところに書いてあった

# おまけ

参考までに Python で別の書き方を見てみます。

## map

Python でも `map` を使ってみます。JavaScript と違ってメソッドではなく関数です。中間過程でリストが生成されないことに注意が必要です。

```py
>>> a = "1,2+3,4+5+6"
>>> b = a.split(",")
>>> c = map(lambda s: s.split("+"), b)
>>> c
<map object at 0x7ff9100af0d0>
>>> d = map(lambda xs: map(int, xs), c)
>>> d
<map object at 0x7ff9102583d0>
>>> list(map(list, d))
[[1], [2, 3], [4, 5, 6]]
```

処理をまとめます。

```py
>>> d = map(lambda xs: map(int, xs), map(lambda s: s.split("+"), a.split(",")))
>>> list(map(list, d))
[[1], [2, 3], [4, 5, 6]]
```

コードを整理します。

```py
>>> d = map(lambda s: map(int, s.split("+")), a.split(","))
>>> list(map(list, d))
[[1], [2, 3], [4, 5, 6]]
```

`flatMap` の代わりに結果をフラット化して取り出します。

```py
>>> d = map(lambda s: map(int, s.split("+")), a.split(","))
>>> from itertools import chain
>>> list(chain.from_iterable(d))
[1, 2, 3, 4, 5, 6]
```

フラット化については以下の記事を参考にしました。

https://qiita.com/hoto17296/items/e1f80fef8536a0e5e7db

https://xef.hatenadiary.org/entry/20121027/p2

ジェネレーターをネストさせるときは `yield from` を使用すれば効率が上がります。

https://www.getwebtips.net/blog/2020/7/1/python-compose-nested-multiple-generators-with-yield-from-expression/

https://qiita.com/trsqxyz/items/013ea4ece0de52328f17

## ジェネレーター内包表記

内包表記で `[` `]` の代わりに `(` `)` で囲めばジェネレーターになります。

中間でリストを作らずに内包表記が使えます。

```py
>>> a = "1,2+3,4+5+6"
>>> d = ((int(x) for x in s.split("+")) for s in a.split(","))
>>> d
<generator object <genexpr> at 0x7ff91023eb20>
>>> list(map(list, d))
[[1], [2, 3], [4, 5, 6]]
>>> e = (int(x) for s in a.split(",") for x in s.split("+"))
>>> e
<generator object <genexpr> at 0x7ff910418f40>
>>> list(e)
[1, 2, 3, 4, 5, 6]
```

関数の引数をジェネレーター内包表記で書けます。括弧を二重にする必要はありません。

```py
>>> list(int(x) for s in a.split(",") for x in s.split("+"))
[1, 2, 3, 4, 5, 6]
>>> sum(int(x) for s in a.split(",") for x in s.split("+"))
21
```

# 関連記事

`flatMap` をジェネレーターに関連付けて考察した記事です。要点は一対多の結果を列挙することです。

https://qiita.com/7shi/items/56071382384617911a58
