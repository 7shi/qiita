---
coediting: false
comments_count: 0
created_at: '2020-02-11T05:46:42+09:00'
id: b3aba035c45868ab34e9
likes_count: 9
private: false
reactions_count: 0
stocks_count: 8
tags:
- name: Python
  versions: []
- name: Haskell
  versions: []
title: Pythonでもジェネレーターで関数モナドとStateモナドを模倣してみた
updated_at: '2020-02-16T13:02:01+09:00'
url: https://qiita.com/7shi/items/b3aba035c45868ab34e9
slide: false
---

ジェネレーターを DSL のように使って関数モナドと State モナドを模倣してみました。記述をそれっぽく見せることに重点を置いたため、bind や return を正確に実装したわけではありません。

この記事は次の記事の Python 版です。同じことが出来るはずなので確認したくなりました。

* [ジェネレーターで関数モナドとStateモナドを模倣してみた](https://qiita.com/7shi/items/e5365885fb53c015630c)

結果的に、ジェネレーターの `return` の仕様の変遷や、デコレーターが有用なことなどが分かりました。

# 実装

実装を並べると、関数モナドと State モナドの差分が分かりやすいです。

<table>
<tr><th>関数モナド</th><th>State モナド</th></tr>
<tr><td><pre>
def function_monad(g):
  def f(state):
    it = g()
    value = None
    try:
      while True:
        value = it.send(value)(state)
    except StopIteration as e:
      return e.value
  return f
</pre></td><td><pre>
def state_monad(g):
  def f(state):
    it = g()
    value = None
    try:
      while True:
        value, state = it.send(value)(state)
    except StopIteration as e:
      return (e.value, state)
  return f
</pre></td></tr>
</table>

関数モナドでは `state` は固定で `value` のみが更新されますが、State モナドでは両者をセットで扱い更新されます。

これを踏まえてState モナドで使う `get` と `put` を見れば、挙動が分かりやすいと思います。

```py
get = lambda state: (state, state)
put = lambda newState: lambda oldState: (None, newState)
```

# サンプル

以前書いた次の記事から引用しました。

* [コンピュテーション式でモナドを作ってみる](https://qiita.com/7shi/items/026c7daa5b0b24d02c0f)

## 関数モナド

`test` に対する引数が、`yield` の右のラムダ式に引数として与えられます。

<table>
<tr><th>Haskell</th><th>Python</th><th>JavaScript</th></tr>
<tr><td><pre>

test = do
  a &lt;- (+ 1)
  b &lt;- (* 2)
  return (a, b)

main = do
  print (test 3)
  print (test 5)
</pre>
実行結果
<pre>
(4,6)
(6,10)
</pre></td><td><pre>
@function_monad
def test():
  a = yield lambda x: x + 1
  b = yield lambda x: x * 2
  return (a, b)


print(test(3))
print(test(5))
</pre>
実行結果
<pre>
(4, 6)
(6, 10)
</pre></td><td><pre>
let test = functionMonad(
  function*() {
    let a = yield x => x + 1;
    let b = yield x => x * 2;
    return [a, b];
  });

log(test(3));
log(test(5));
</pre>
実行結果
<pre>
[4,6]
[6,10]
</pre></td></tr>
</table>

オンラインで実行 ([Repl.it](https://repl.it/))

* https://repl.it/@7shi/Python-Function-Monad

## State モナド

State モナドはコンテキストとして状態を持っており、呼び出す際に初期値を与えます。状態の取得は `get`、更新は `put` で行います。

<table>
<tr><th>Haskell</th><th>Python</th><th>JavaScript</th></tr>
<tr><td><pre>

test = do
  a &lt;- get
  put (a * 2)
  b &lt;- get
  return (a, b)


postInc = do
  x &lt;- get
  put (x + 1)
  return x


test2 = do
  a &lt;- postInc
  b &lt;- postInc
  return (a, b)

main = do
  print (evalState test  3)
  print (evalState test  5)
  print (evalState test2 3)
  print (evalState test2 5)
</pre>
実行結果
<pre>
(3,6)
(5,10)
(3,4)
(5,6)
</pre></td><td><pre>
@state_monad
def test():
  a = yield get
  yield put(a * 2)
  b = yield get
  return (a, b)

@state_monad
def postInc():
  x = yield get
  yield put(x + 1)
  return x

@state_monad
def test2():
  a = yield postInc
  b = yield postInc
  return (a, b)


print(test (3)[0])
print(test (5)[0])
print(test2(3)[0])
print(test2(5)[0])
</pre>
実行結果
<pre>
(3, 6)
(5, 10)
(3, 4)
(5, 6)
</pre></td><td><pre>
let test = stateMonad(
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

log(test (3)[0]);
log(test (5)[0]);
log(test2(3)[0]);
log(test2(5)[0]);
</pre>
実行結果
<pre>
[3,6]
[5,10]
[3,4]
[5,6]
</pre></td></tr>
</table>

オンラインで実行 ([Repl.it](https://repl.it/))

* https://repl.it/@7shi/Python-State-Monad

# リストモナド

同じ方式でリストモナドを実装できないか考えたのですが、多重ループとなる場合に変数の値を変えて同じコードを何度も実行する必要があり、実現する方法が思いつかずに断念しました。

ジェネレーターの中で普通に `for` で多重ループを書けば同じことはできます。

<table>
<tr><th>Haskell</th><th>Python</th><th>JavaScript</th></tr>
<tr><td><pre>




test = do
  x &lt;- [1, 2]
  y &lt;- [3, 4]
  [x, y]



main =
  print test
</pre>
実行結果
<pre>
[1,3,1,4,2,3,2,4]
</pre></td><td><pre>
def list_monad(g):
  return list(g())

@list_monad
def test():
  for x in [1, 2]:
    for y in [3, 4]:
      yield x; yield y




print(test)
</pre>
実行結果
<pre>
[1, 3, 1, 4, 2, 3, 2, 4]
</pre></td><td><pre>
function listMonad(g) {
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

log(test);
</pre>
実行結果
<pre>
[1,3,1,4,2,3,2,4]
</pre></td></tr>
</table>

オンラインで実行 ([Repl.it](https://repl.it/))

* https://repl.it/@7shi/Python-List-Monad

リスト内包表記で書くとフラット化が必要になります。

```py
>>> [[x, y] for y in [3, 4] for x in [1, 2]]
[[1, 3], [2, 3], [1, 4], [2, 4]]
>>> sum([[x, y] for y in [3, 4] for x in [1, 2]], [])
[1, 3, 2, 3, 1, 4, 2, 4]
```

【参考】[Python 3 で flatten する方法いろいろ](https://qiita.com/hoto17296/items/e1f80fef8536a0e5e7db)

# return

ジェネレーターで値付きの `return` が使えるようになったのは割と最近のことのようです。

* [Python 3.7 ではGeneretor で StopIteration を使うと RuntimeError になる](https://qiita.com/Ryuichirou/items/c18d31f549038169c711)

> これは[組み込み例外 — Python 3.7.3 ドキュメント](https://docs.python.org/ja/3/library/exceptions.html#StopIteration) に記述があり、[PEP 479 -- Change StopIteration handling inside generators](https://www.python.org/dev/peps/pep-0479/) がデフォルトで有効化されているためです。

以前のバージョンではエラーになっていたようです。

* [Python Does What?!?: a return to yield](https://www.pythondoeswhat.com/2017/04/a-return-to-yield_29.html)

> SyntaxError: 'return' with argument inside generator

# デコレーター

今回はデコレーターが大活躍しています。少し前に次の記事で知りました。

* [編集距離（レーベンシュタイン距離）を理解し、実装する](https://qiita.com/tanuk1647/items/5a591da10e2ea5bedef6)

> [Python用語集](https://docs.python.jp/3/glossary.html#term-decorator)に、以下の記載があります。
> 
> >**decorator**
> >
> >(デコレータ) 別の関数を返す関数で、通常、 @wrapper 構文で関数変換として適用されます。デコレータの一般的な利用例は、 classmethod() と staticmethod() です。
> >
> >デコレータの文法はシンタックスシュガーです。次の2つの関数定義は意味的に同じものです:
> >
> >```python
> >def f(...):
> >    ...
> >f = staticmethod(f)
> >
> >@staticmethod
> >def f(...):
> >    ...
> >```

※ 併記した JavaScript では関数でジェネレーターを包む様子を直接表記しています。

# 参考

Haskell のモナドは次の記事を参考にしてください。

* [Haskell 状態系モナド 超入門](https://qiita.com/7shi/items/2e9bff5d88302de1a9e9)
