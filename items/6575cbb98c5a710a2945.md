---
coediting: false
comments_count: 0
created_at: '2022-11-18T23:51:35+09:00'
id: 6575cbb98c5a710a2945
likes_count: 0
private: false
reactions_count: 0
stocks_count: 1
tags:
- name: JavaScript
  versions: []
- name: generator
  versions: []
- name: Iterator
  versions: []
title: イテレーターのクローンもどき
updated_at: '2022-11-18T23:51:35+09:00'
url: https://qiita.com/7shi/items/6575cbb98c5a710a2945
slide: false
---

JavaScript のジェネレーターでは実行途中のイテレーターをクローンできません。無理やりそれっぽいことをしてみました。

# 実装

`next()` に渡す引数をキャッシュして、毎回最初からやり直すことで強引にクローンのように見せかけます。

```js
function makeCloneableIterator(g) {
  const it = g();
  const args = [];
  return {
    next(arg) {
      args.push(arg);
      return it.next(arg);
    },
    clone() {
      const ret = makeCloneableIterator(g);
      args.forEach(ret.next);
      return ret;
    }
  };
}
```

## 使用例

途中から再開しているように見えます。

```js
const it = makeCloneableIterator(function*(){
  yield 1;
  yield 2;
  return "return";
});

console.log(it.next());
const it2 = it.clone();
console.log(it.next());
console.log(it.next());
console.log(it2.next());
console.log(it2.next());
```
```text:実行結果
{ value: 1, done: false }
{ value: 2, done: false }
{ value: "return", done: true }
{ value: 2, done: false }
{ value: "return", done: true }
```

# リストモナド

イテレーターをコピーできないことは、ジェネレーターでリストモナドを模倣する際に障害になっていました。

https://qiita.com/7shi/items/e5365885fb53c015630c

https://esdiscuss.org/topic/how-would-we-copy-an-iterator

今回の実装を使えばリストモナドも模倣できます。

```js
function* ListMonad(g) {
  function* f(it, arg) {
    const r = it.next(arg);
    if (r.done) {
      yield r.value;
    } else {
      for (const v of r.value) {
        const it2 = it.clone();
        yield* f(it2, v);
      }
    }
  }
  yield* f(makeCloneableIterator(g));
}
```

## 使用例

Haskell のコードを移植してみます。

```haskell
main =
  print $ do
    x <- [1, 2, 3]
    y <- [x * 10, x * 100, x * 1000]
    return $ x + y
```
```text:実行結果
[11,101,1001,22,202,2002,33,303,3003]
```

<p class="codepen" data-height="300" data-default-tab="js,result" data-slug-hash="ExRbWBW" data-user="7shi" style="height: 300px; box-sizing: border-box; display: flex; align-items: center; justify-content: center; border: 2px solid; margin: 1em 0; padding: 1em;">  <span>See the Pen <a href="https://codepen.io/7shi/pen/ExRbWBW">  Cloneable  Iterator</a> by 七誌 (<a href="https://codepen.io/7shi">@7shi</a>)
  on <a href="https://codepen.io">CodePen</a>.</span>
</p>
<script async src="https://cpwebassets.codepen.io/assets/embed/ei.js"></script>

※ 出力の `log()` は次の実装を使っています。

https://qiita.com/7shi/items/ca174dac3af8235c5bd2

## 経緯

これまでリストモナドを模倣するのに `for` を使ったり、強引に CPS 変換をしたりしていました。

https://qiita.com/7shi/items/8ec339bcddbb6692b738

https://qiita.com/7shi/items/55f10aa99108afd5a128

今回の実装はあくまで実験的なもので、`for` を使うのが素直な気はします。

# 参考

回答で [forkable-iterator](https://github.com/tjenkinson/forkable-iterator) というライブラリが紹介されています。

https://stackoverflow.com/questions/46416266/how-to-clone-an-iterator-in-javascript

これは値をキャッシュすることでイテレーターをコピーする方法です。リストモナドの例のように値が変わる場合には使えません。
