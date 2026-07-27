---
coediting: false
comments_count: 0
created_at: '2014-12-18T23:11:10+09:00'
id: 8ec339bcddbb6692b738
likes_count: 1
private: false
reactions_count: 0
stocks_count: 1
tags:
- name: Haskell
  versions: []
- name: ECMAScript
  versions: []
title: ジェネレーターでリストモナドを模倣してみた
updated_at: '2022-11-19T00:22:11+09:00'
url: https://qiita.com/7shi/items/8ec339bcddbb6692b738
slide: false
---

 [Haskellの実験メモ](http://qiita.com/7shi/items/b6cbb7df2dd969c84f49)です。

ECMAScript 6のジェネレーターでHaskellのリストモナドを模倣してみました。

# 一重

```hs:Haskell
main = do
    print $ do
        x <- [1..5]
        return $ x * 2
```
```text:実行結果
[2,4,6,8,10]
```

これになるべく近くなるように模倣してみました。ジェネレーターや`for`～`of`は動作環境を選びます。

```js:ES2015
console.log(Array.from(function*() {
    for (let x of [1, 2, 3, 4, 5]) {
        yield x * 2;
    }
}()));
```
```text:実行結果
[ 2, 4, 6, 8, 10 ]
```

参考までに、ジェネレーターを使わない例を示します。

```js:ES2015
console.log(function() {
    let ret = [];
    for (let x of [1, 2, 3, 4, 5]) {
        ret.push(x * 2);
    }
    return ret;
}());
```
```text:実行結果
[ 2, 4, 6, 8, 10 ]
```

この方式は以下の記事で使用しています。

* [Haskell リストモナド 超入門](http://qiita.com/7shi/items/deb19c4cba933590ffbf) 2014.12.19

# 二重

```hs:Haskell
main = do
    print $ do
        x <- [1..3]
        y <- "abc"
        return (x, y)
```
```text:実行結果
[(1,'a'),(1,'b'),(1,'c'),(2,'a'),(2,'b'),(2,'c'),(3,'a'),(3,'b'),(3,'c')]
```

同じ方針で模倣します。

```js:ES2015
console.log(Array.from(function*() {
    for (let x of [1, 2, 3]) {
        for (let y of "abc") {
            yield [x, y];
        }
    }
}()));
```
```text:実行結果
[ [ 1, 'a' ],
  [ 1, 'b' ],
  [ 1, 'c' ],
  [ 2, 'a' ],
  [ 2, 'b' ],
  [ 2, 'c' ],
  [ 3, 'a' ],
  [ 3, 'b' ],
  [ 3, 'c' ] ]
```

タプルがないため配列で代用しています。

## フラット化

Haskellでは`return`ではなく複数の項目を含むリストを返すとフラット化されます。LINQの`SelectMany`やScalaの`flatMap`と関係があります。

タプルと比較します。リストにする関係上、要素の型は同じにします。

```hs:Haskell
main = do
    print $ do
        x <- [1,2]
        y <- [3,4]
        return (x, y)
    print $ do
        x <- [1,2]
        y <- [3,4]
        [x, y]
```
```text:実行結果
[(1,3),(1,4),(2,3),(2,4)]
[1,3,1,4,2,3,2,4]
```

`join`と`return`を省略しているとも解釈できます。リスト内包表記で結果をフラットにするには`join`必須です。

```hs:Haskell
import Control.Monad

main = do
    print $ do
        x <- [1,2]
        y <- [3,4]
        return [x, y]
    print [[x, y] | x <- [1,2], y <- [3,4]]
    print $ join $ do
        x <- [1,2]
        y <- [3,4]
        return [x, y]
    print $ join $ [[x, y] | x <- [1,2], y <- [3,4]]
```
```text:実行結果
[[1,3],[1,4],[2,3],[2,4]]
[[1,3],[1,4],[2,3],[2,4]]
[1,3,1,4,2,3,2,4]
[1,3,1,4,2,3,2,4]
```

ジェネレーターで模倣するには`yield`を複数回に分けるのが簡単です。

```js:ES2015
console.log(Array.from(function*() {
    for (let x of [1, 2]) {
        for (let y of [3, 4]) {
            yield x;
            yield y;
        }
    }
}()));
```
```text:実行結果
[ 1, 3, 1, 4, 2, 3, 2, 4 ]
```

# 関連記事

https://qiita.com/7shi/items/6575cbb98c5a710a2945

https://qiita.com/7shi/items/e5365885fb53c015630c

https://qiita.com/7shi/items/55f10aa99108afd5a128
