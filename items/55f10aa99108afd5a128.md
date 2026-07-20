---
coediting: false
comments_count: 0
created_at: '2020-02-13T01:54:59+09:00'
id: 55f10aa99108afd5a128
likes_count: 1
private: false
reactions_count: 0
stocks_count: 2
tags:
- name: JavaScript
  versions: []
- name: CPS変換
  versions: []
title: ジェネレーターを簡易的にCPS変換してみた
updated_at: '2022-11-19T00:30:12+09:00'
url: https://qiita.com/7shi/items/55f10aa99108afd5a128
slide: false
---

ジェネレーターをモナド用の DSL として使いたかったので、簡易的にパースして CPS 変換してみました。

<p class="codepen" data-height="265" data-theme-id="dark" data-default-tab="js,result" data-user="7shi" data-slug-hash="abOvEyM" style="height: 265px; box-sizing: border-box; display: flex; align-items: center; justify-content: center; border: 2px solid; margin: 1em 0; padding: 1em;" data-pen-title="CPS Transformation">
  <span>See the Pen <a href="https://codepen.io/7shi/pen/abOvEyM">
  CPS Transformation</a> by 七誌 (<a href="https://codepen.io/7shi">@7shi</a>)
  on <a href="https://codepen.io">CodePen</a>.</span>
</p>
<script async src="https://static.codepen.io/assets/embed/ei.js"></script>

# 概要

JavaScript の関数は `.toString` でソースを文字列として取得できます。

```javascript
> function test(x) { return x + 1; }
> test.toString()
'function test(x) { return x + 1; }'
```

ソースの文字列をパースして `yield` の後の行をコールバックとして切り出すことで、`yield` を区切りとした CPS 変換となります。（今回は `yield` しか変換しません）

具体例を示します。見やすいようにインデントを整えています。（実際の変換ではインデントは消えます）

```javascript:変換前
function* () {
    let x = yield [1, 2];
    let y = yield [3, 4];
    return [x, y];
}
```
```javascript:変換後
(function () {
    return bind([1, 2], x => {
        return bind([3, 4], y => {
            return [x, y];
        });
    });
})
```

今回のパースは手抜きで、スペースを除いた行頭に `yield` または `let 変数 = yield` があるケースしか見ていません。

変換前|変換後
----|----
`yield 式;`|`return bind(式, () => { 次の行以降 });`
`let 変数 = yield 式;`|`return bind(式, 変数 => { 次の行以降 });`

※ `let` に複数の変数が列挙されているケースは想定していません。

パース対象の関数は文法的なチェックが済んでいることを当てにしています。

【参考】[opol - JavaScriptで演算子オーバーロード](http://www.asahi-net.or.jp/~ab6s-med/NORTH/opol/index.html)

> 関数としてコードを書くのがオススメ。そうする事でブラウザーが変換前の段階で構文チェックしてくれる。 

## 制限

ブロックの中で `yield` は使えません。具体的には `if` や `for` などです。

```javascript:ダメな例
  if (cond) {
      yield m1;
  } else {
      yield m2;
  }
  for (let i = 0; i < 10; i++) {
      yield m;
  }
```

`if` は三項演算子へ書き換え、`for` はループの補助関数を用意するなどの対策が必要です。

```javascript:書き換え例
  yield cond ? m1 : m2;
  yield loop(10, m);
```

State モナド用のループの補助関数の例です。

```javascript
let loop = (n, m) => state => {
  if (n < 1) return [, state];
  let [_, newState] = m(state);
  return loop(n - 1, m)(newState);
};
```

※ トランスパイルするとキャプチャした `n,m` への参照が失われるため、内部構造を直接扱っています。

# リストモナド

ジェネレーターを DSL として使って、ある種のモナドの動きを模倣できます。ただしこの方法ではリストモナドは模倣できませんでした。

* [ジェネレーターで関数モナドとStateモナドを模倣してみた](https://qiita.com/7shi/items/e5365885fb53c015630c)

> 同じ方式でリストモナドを実装できないか考えたのですが、多重ループとなる場合に変数の値を変えて同じコードを何度も実行する必要があり、実現する方法が思いつかずに断念しました。

今回の CPS 変換により bind にコールバックが渡せるようになったため、リストモナドも模倣できるようになりました。

```javascript
function listMonad(g) {
  function bind(list, f) { return list.flatMap(f); }
  return eval(cpsTransform(bind, g))();
}

let test = listMonad(function*() {
  let x = yield [1, 2];
  let y = yield [3, 4];
  return [x, y];
});
log(test);
```
```text:実行結果
[1,3,1,4,2,3,2,4]
```

【追記:2022.11.18】毎回やり直すことで強引に模倣してみました。

https://qiita.com/7shi/items/6575cbb98c5a710a2945

# 状態系モナド

ジェネレーターからモナドの変換は関数で行い、値をモナドで包む `return`（Haskell の意味）は `new` で表現します。

<table>
<tr><th>Haskell</th><th>JavaScript</th></tr>
<tr>
<td><pre>test = do
    a &lt;- get
    return a

</pre></td>
<td><pre>let test = stateMonad(function*() {
    let a = yield get;
    return new stateMonad(a);
});
</pre></td></tr>
</table>

<table>
<tr><th>関数モナド</th><th>State モナド</th></tr>
<tr><td><pre>function functionMonad(g) {
  if (this.constructor == functionMonad)
    return () => g;
  function bind(m, f) {
    return state => {
      let value = m(state);
      let r = f(value);
      return r(state);
    };
  }
  let cps = eval(cpsTransform(bind, g));
  return state => cps()(state);
}
</pre></td><td><pre>function stateMonad(g) {
  if (this.constructor == stateMonad)
    return state => [g, state];
  function bind(m, f) {
    return state => {
      let [value, newState] = m(state);
      let r = f(value);
      return r(newState);
    };
  }
  let cps = eval(cpsTransform(bind, g));
  return state => cps()(state);
}
</pre></td></tr>
</table>

これらはどちらも状態系モナドとして同じ構造になっています。

1. `bind(m, f)` において、モナド `m` から値（と状態）を取り出す: `m(state)`
2. 取り出した値 `value` を `f` に引数として渡す: `f(value)`<br>
   ※ 引数として渡すことを変数への束縛と見なすので bind
3. `f` からモナド `r` が返ってくるので値（と状態）を取り出す: `r(state)`

## return 簡略版

Haskell の `return` に見た目を似せるため、ジェネレーターの最後の `return` でモナドに包まない生の値を返せるようにした実装です。

<table>
<tr><th>Haskell</th><th>JavaScript</th></tr>
<tr>
<td><pre>test = do
    a &lt;- get
    return a
</pre></td><td><pre>let test = stateMonad(function*() {
    let a = yield get;
    return a;
});
</pre></td></tr>
</table>

モナドをコンテナとして実装してはいませんが、値と区別するため `monad` 関数で印を付けます。

<table>
<tr>
<th><a href="https://codepen.io/7shi/pen/wvaKExe?editors=0010">関数モナド</a></th>
<th><a href="https://codepen.io/7shi/pen/WNvQgOO?editors=0010">State モナド</a></th>
</tr>
<tr><td><pre>function functionMonad(g) {
  function monad(m) {
    m.monad = functionMonad;
    return m;
  }
  if (this.constructor == functionMonad)
    return monad(() => g);
  function bind(m, f) {
    return monad(state => {
      let value = m(state);
      let r = f(value);
      if (!r.monad) r = new functionMonad(r);
      return r(state);
    });
  }
  let cps = eval(cpsTransform(bind, g));
  return state => cps()(state);
}
</pre></td><td><pre>function stateMonad(g) {
  function monad(m) {
    m.monad = stateMonad;
    return m;
  }
  if (this.constructor == stateMonad)
    return monad(state => [g, state]);
  function bind(m, f) {
    return monad(state => {
      let [value, newState] = m(state);
      let r = f(value);
      if (!r.monad) r = new stateMonad(r);
      return r(newState);
    });
  }
  let cps = eval(cpsTransform(bind, g));
  return state => cps()(state);
}
</pre></td></tr>
</table>

モナドではなく値が返されたときはモナドで包みます。

```javascript
      if (!r.monad) r = new functionMonad(r);
```

包まずに直に返すことも可能です。この方がオーバーヘッドは少ないです。

<table>
<tr><th>関数モナド</th><th>State モナド</th></tr>
<tr><td><pre>      if (!r.monad) return r;
</pre></td>
<td><pre>      if (!r.monad) return [r, newState];
</pre></td></tr>
</table>

## 状態書き換え版

参考までに `state` をモナド内のローカル変数として書き換える実装を示します。`bind` で `state` をリレーしないため、実装が簡単になっています。値をモナドで包む処理は省略しました。

<table>
<tr><th>関数モナド</th><th>State モナド</th></tr>
<tr><td><pre>function functionMonad(g) {
  let state;
  function bind(m, f) {
    let value;
    value = m(state);
    return f(value);
  }
  let cps = eval(cpsTransform(bind, g));
  return s => {
    state = s;
    return cps();
  };
}
</pre></td><td><pre>function stateMonad(g) {
  let state;
  function bind(m, f) {
    let value;
    [value, state] = m(state);
    return f(value);
  }
  let cps = eval(cpsTransform(bind, g));
  return s => {
    state = s;
    return [cps(), state];
  };
}
</pre></td></tr>
</table>

この状態書き換え版を CPS 変換しないで直接ジェネレーターを扱う版と比較すれば、CPS 変換が何をしているのか分かりやすいかもしれません。

【引用】[ジェネレーターで関数モナドとStateモナドを模倣してみた](https://qiita.com/7shi/items/e5365885fb53c015630c)

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

# 参考

出力の `log()` は次の実装を使っています。

* [divに対してconsole.logのようなことをする](https://qiita.com/7shi/items/ca174dac3af8235c5bd2)

今回の CPS 変換は、Haskell での do ブロックから `>>=` による表記への書き換えに対応します。

* [Haskell アクションとラムダ 超入門](https://qiita.com/7shi/items/4a8a2807bb5186576c61)

こちらのブログにちょうどその話題が言及されていました。

* [CPS変換についての覚え書き - ゴバブログ](https://blog.7nobo.me/2016/08/24/200000.html)

> こうして変換していく過程を見ていると、ほとんどモナドのdo記法から>>=を使った記法への変換と同じであることが分かりますね。
