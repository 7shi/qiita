---
coediting: false
comments_count: 0
created_at: '2023-03-09T00:18:26+09:00'
id: 56071382384617911a58
likes_count: 2
private: false
reactions_count: 0
stocks_count: 1
tags:
- name: JavaScript
  versions: []
title: flatMap と yield*
updated_at: '2023-03-15T05:15:02+09:00'
url: https://qiita.com/7shi/items/56071382384617911a58
slide: false
---

`flatMap` と `yield*` は記述方法が異なりますが、似たような目的に使えます。他の書き方も含めて、簡単な例で比較します。

# 配列の結合

別々に生成した配列を結合します。

```js
function makeRange(from, to) {
    const ret = Array(to - from + 1);
    for (let i = from; i <= to; i++) {
        ret[i - from] = i;
    }
    return ret;
}

function makeArray() {
    return [99].concat(makeRange(1, 3)).concat(makeRange(1, 5));
}
```
```js:実行結果
> makeArray()
[ 99, 1, 2, 3, 1, 2, 3, 4, 5 ]
```

`makeRange` は敢えて泥臭く書きましたが、今は `map` を使うのがスマートかもしれません。

```js
function makeRange(from, to) {
    return Array(to - from + 1).fill().map((_, i) => from + i);
}
```

# flatMap

この例だと人によって実装方法が変わりそうです。元となる配列の要素を型で区別して膨らませる方法を使います。

※ `makeRange` は上で定義した関数です。

```js
function makeArrayFlatMap() {
    return [99, [3], [5]].flatMap(x => Array.isArray(x) ? makeRange(1, x[0]) : x);
}
```
```js:実行結果
> makeArrayFlatMap()
[ 99, 1, 2, 3, 1, 2, 3, 4, 5 ]
```

# push

配列を取り回しながら 1 つずつ `push` します。生成する配列を一本化したいという発想です。

```js
function pushRange(arr, from, to) {
    for (let i = from; i <= to; i++) {
        arr.push(i);
    }
}

function makeArrayPush() {
    const ret = [];
    ret.push(99);
    pushRange(ret, 1, 3);
    pushRange(ret, 1, 5);
    return ret;
}
```
```js:実行結果
> makeArrayPush()
[ 99, 1, 2, 3, 1, 2, 3, 4, 5 ]
```

個人的には、以前はこのやり方をよく使っていました。

# ジェネレーター

`yield*` によって他のジェネレーターを取り込みます。

```js
function* generateRange(from, to) {
    for (let i = from; i <= to; i++) {
        yield i;
    }
}

function* makeArrayGenerator() {
    yield 99;
    yield* generateRange(1, 3);
    yield* generateRange(1, 5);
}
```
```js:実行結果
> [...makeArrayGenerator()]
[ 99, 1, 2, 3, 1, 2, 3, 4, 5 ]
```

※ 実行結果ではジェネレーターから配列を生成しています。

`push` の方法に似ています。そのため個人的にはジェネレーターは馴染みやすかったです。

`flatMap` との対応を考えると、`yield` と `yield*` をまとめてやっているような印象です。個人的にはそのことに気付いたことで `flatMap` に馴染めるようになりました。

# 関連記事

配列と `flatMap` を一般化したようなものがモナドです。

https://qiita.com/7shi/items/27b6f3169961299a6195
