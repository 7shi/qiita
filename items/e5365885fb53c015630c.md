---
coediting: false
comments_count: 1
created_at: '2020-02-11T01:27:05+09:00'
id: e5365885fb53c015630c
likes_count: 8
private: false
reactions_count: 0
stocks_count: 3
tags:
- name: JavaScript
  versions: []
- name: Haskell
  versions: []
title: ジェネレーターで関数モナドとStateモナドを模倣してみた
updated_at: '2022-11-19T00:17:34+09:00'
url: https://qiita.com/7shi/items/e5365885fb53c015630c
slide: false
---

ジェネレーターを DSL のように使って関数モナドと State モナドを模倣してみました。記述をそれっぽく見せることに重点を置いたため、bind や return を正確に実装したわけではありません。

関数モナド（のようなもの）

<p class="codepen" data-height="265" data-theme-id="dark" data-default-tab="js,result" data-user="7shi" data-slug-hash="eYNNNVz" style="height: 265px; box-sizing: border-box; display: flex; align-items: center; justify-content: center; border: 2px solid; margin: 1em 0; padding: 1em;" data-pen-title="Function Monad">
  <span>See the Pen <a href="https://codepen.io/7shi/pen/eYNNNVz">
  Function Monad</a> by 七誌 (<a href="https://codepen.io/7shi">@7shi</a>)
  on <a href="https://codepen.io">CodePen</a>.</span>
</p>

State モナド（のようなもの）

<p class="codepen" data-height="265" data-theme-id="dark" data-default-tab="js,result" data-user="7shi" data-slug-hash="ZEGGGNL" style="height: 265px; box-sizing: border-box; display: flex; align-items: center; justify-content: center; border: 2px solid; margin: 1em 0; padding: 1em;" data-pen-title="State Monad">
  <span>See the Pen <a href="https://codepen.io/7shi/pen/ZEGGGNL">
  State Monad</a> by 七誌 (<a href="https://codepen.io/7shi">@7shi</a>)
  on <a href="https://codepen.io">CodePen</a>.</span>
</p>
<script async src="https://static.codepen.io/assets/embed/ei.js"></script>

この記事には Python 版があります。

* [Pythonでもジェネレーターで関数モナドとStateモナドを模倣してみた](https://qiita.com/7shi/items/b3aba035c45868ab34e9)

# 実装

実装を並べると、関数モナドと State モナドの差分が分かりやすいです。

<table>
<tr><th>関数モナド</th><th>State モナド</th></tr>
<tr><td><pre>function functionMonad(g) {
  return state => {
    let it = g(), result, value;
    while (!(result = it.next(value)).done) {
      value = result.value(state);
    }
    return result.value;
  };
}
</pre></td><td><pre>function stateMonad(g) {
  return state => {
    let it = g(), result, value;
    while (!(result = it.next(value)).done) {
      [value, state] = result.value(state);
    }
    return [result.value, state];
  };
}
</pre></td></tr>
</table>

関数モナドでは `state` は固定で `value` のみが更新されますが、State モナドでは両者をセットで扱い更新されます。

これを踏まえてState モナドで使う `get` と `put` を見れば、挙動が分かりやすいと思います。

```text
let get = state => [state, state];
let put = newState => oldState => [, newState];
```

# サンプル

以前書いた次の記事から引用しました。

* [コンピュテーション式でモナドを作ってみる](https://qiita.com/7shi/items/026c7daa5b0b24d02c0f)

Haskell と JavaScript と Python を並べて比較します。

## 関数モナド

`test` に対する引数が、`yield` の右のラムダ式に引数として与えられます。

<table>
<tr><th>Haskell</th><th>JavaScript</th><th>Python</th></tr>
<tr><td><pre>test = do
  a &lt;- (+ 1)
  b &lt;- (* 2)
  return (a, b)
&nbsp;
main = do
  print (test 3)
  print (test 5)
</pre>
</td><td><pre>let test = functionMonad(
  function*() {
    let a = yield x => x + 1;
    let b = yield x => x * 2;
    return [a, b];
  });
&nbsp;
log(test(3));
log(test(5));
</pre>
</td><td><pre>@function_monad
def test():
  a = yield lambda x: x + 1
  b = yield lambda x: x * 2
  return (a, b)
&nbsp;
print(test(3))
print(test(5))
</pre>
</td></tr>
<tr><td>
実行結果
<pre>(4,6)
(6,10)
</pre>
</td><td>
実行結果
<pre>[4,6]
[6,10]
</pre>
</td><td>
実行結果
<pre>(4, 6)
(6, 10)
</pre>
</td></tr>
</table>

## State モナド

State モナドはコンテキストとして状態を持っており、呼び出す際に初期値を与えます。状態の取得は `get`、更新は `put` で行います。

<table>
<tr><th>Haskell</th><th>JavaScript</th><th>Python</th></tr>
<tr><td><pre>test = do
  a &lt;- get
  put (a * 2)
  b &lt;- get
  return (a, b)
&nbsp;
postInc = do
  x &lt;- get
  put (x + 1)
  return x
&nbsp;
test2 = do
  a &lt;- postInc
  b &lt;- postInc
  return (a, b)
&nbsp;
main = do
  print (evalState test  3)
  print (evalState test  5)
  print (evalState test2 3)
  print (evalState test2 5)
</pre>
</td>
<td><pre>let test = stateMonad(
  function*() {
    let a = yield get;
    yield put(a * 2);
    let b = yield get;
    return [a, b];
  });
let postInc = stateMonad(
  function*() {
    let x = yield get;
    yield put(x + 1);
    return x;
  });
let test2 = stateMonad(
  function*() {
    let a = yield postInc;
    let b = yield postInc;
    return [a, b];
  });
&nbsp;
log(test (3)[0]);
log(test (5)[0]);
log(test2(3)[0]);
log(test2(5)[0]);
</pre>
</td>
<td><pre>@state_monad
def test():
  a = yield get
  yield put(a * 2)
  b = yield get
  return (a, b)
&nbsp;
@state_monad
def postInc():
  x = yield get
  yield put(x + 1)
  return x
&nbsp;
@state_monad
def test2():
  a = yield postInc
  b = yield postInc
  return (a, b)
&nbsp;
print(test (3)[0])
print(test (5)[0])
print(test2(3)[0])
print(test2(5)[0])
</pre>
</td></tr>
<tr><td>
実行結果
<pre>(3,6)
(5,10)
(3,4)
(5,6)
</pre>
</td><td>
実行結果
<pre>[3,6]
[5,10]
[3,4]
[5,6]
</pre>
</td><td>
実行結果
<pre>(3, 6)
(5, 10)
(3, 4)
(5, 6)
</pre>
</td></tr>
</table>

# リストモナド

同じ方式でリストモナドを実装しようとすると、多重ループとなる場合に変数の値を変えて同じコードを何度も実行する必要があます。

現状では毎回やり直すか、ジェネレーターを強引に CPS 変換するくらいしか方法がなさそうです。

https://qiita.com/7shi/items/6575cbb98c5a710a2945

https://qiita.com/7shi/items/55f10aa99108afd5a128

ジェネレーターの中で普通に `for` で多重ループを書けば同じことはできます。

<table>
<tr><th>Haskell</th><th>JavaScript</th><th>Python</th></tr>
<tr><td><pre>test = do
  x &lt;- [1, 2]
  y &lt;- [3, 4]
  [x, y]
&nbsp;
main =
  print test
</pre>
</td><td><pre>function listMonad(g) {
  return Array.from(g());
}
let test = listMonad(
  function*() {
    for (let x of [1, 2]) {
      for (let y of [3, 4]) {
        yield x; yield y
      }
    }
  });
&nbsp;
log(test);
</pre>
</td><td><pre>def list_monad(g):
  return list(g())
&nbsp;
@list_monad
def test():
  for x in [1, 2]:
    for y in [3, 4]:
      yield x; yield y
&nbsp;
print(test)
</pre>
</td></tr>
<tr><td>
実行結果
<pre>[1,3,1,4,2,3,2,4]
</pre>
</td><td>
実行結果
<pre>[1,3,1,4,2,3,2,4]
</pre>
</td><td>
実行結果
<pre>[1, 3, 1, 4, 2, 3, 2, 4]
</pre>
</td></tr>
</table>

`for` による方法は次の記事を参照してください。

https://qiita.com/7shi/items/8ec339bcddbb6692b738

## flatMap

リストモナドの挙動は `.flatMap` で再現できます。

```javascript
> [1, 2].flatMap(x => [3, 4].flatMap(y => [x, y]))
[ 1, 3, 1, 4, 2, 3, 2, 4 ]
```

# 参考

出力の `log()` は次の実装を使っています。

* [divに対してconsole.logのようなことをする](https://qiita.com/7shi/items/ca174dac3af8235c5bd2)

Haskell のモナドは次の記事を参考にしてください。

* [Haskell 状態系モナド 超入門](https://qiita.com/7shi/items/2e9bff5d88302de1a9e9)

次の記事に触発されました。

* [JavaScript + generator で Maybe、 Either、 Promise、 継続モナドと do 構文を実装し async-await と比べてみる](https://qiita.com/legokichi/items/0582e71f4e6984548933)

ジェネレーターを DSL として使う発想は、co が async/await を模倣していたのにヒントを得ました。

* [非同期APIをPromiseでラップしてasync/awaitで使う](https://qiita.com/7shi/items/a2bb35f27cd4a56f7bac)
* [ES2017におけるasyncとgenerator、Promise、CPS、モナドの関係](https://qiita.com/legokichi/items/77a36b7d2b75d8278f9d)
