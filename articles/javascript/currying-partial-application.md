---
coediting: false
comments_count: 2
created_at: '2014-10-15T00:03:49+09:00'
id: a0143daac77a205e7962
likes_count: 113
private: false
reactions_count: 0
stocks_count: 84
tags:
- name: JavaScript
  versions: []
- name: Haskell
  versions: []
title: カリー化と部分適用（JavaScriptとHaskell）
updated_at: '2022-12-08T18:57:25+09:00'
url: https://qiita.com/7shi/items/a0143daac77a205e7962
slide: false
---

カリー化と部分適用について簡単に説明します。特定の言語に依存しない概念を説明するのが目的ですが、例としてJavaScriptとHaskellを使用します。

# JavaScript

カリー化と部分適用はよく混同されるので注意が必要です。

* 関数を引数1つずつに分割してネストさせることを**カリー化**と呼びます。
* 一部の引数を固定化して新しい関数を作り出すことを**部分適用**と呼びます。

<table><tr><th></th><th>非カリー化</th><th>カリー化</th></tr><tr><td>関数定義</td><td><pre>
function add(x, y) {
    return x + y;
}
</pre></td><td><pre>
function add(x) {
    return function(y) {
        return x + y;
    };
}
</pre></td></tr><tr><td>使用例</td><td><pre>
&gt; add(1,2)
3
</pre></td><td><pre>
&gt; add(1)(2)
3
</pre></td></tr><tr><td>部分適用</td><td><pre>
function add1(y) {
    return add(1, y);
}
</pre></td><td><pre>
var add1 = add(1);
</pre></td></tr><tr><td>使用例</td><td colspan="2"><pre>
&gt; add1(2)
3
</pre></td></tr></table>

関数がカリー化されていれば、引数が足りないときに中間過程の関数が返って来ます。

```text
> add1 = add(1)
[Function]
> add1.toString()
'function (y){return x+y;}'
```

`add1`の`x`の値は`1`に固定化されているため、部分適用となります。

# Haskell

Haskellの関数はデフォルトでカリー化されており、非カリー化はタプルで表現します。

<table><tr><th></th><th>非カリー化</th><th>カリー化</th></tr><tr><td>関数定義</td><td><pre>
add (x, y) = x + y
</pre></td><td><pre>
add x y = x + y
</pre></td></tr></tr><tr><td>使用例</td><td><pre>
&gt; add (1,2)
3
</pre></td><td><pre>
&gt; add 1 2
3
</pre></td></tr><tr><td>部分適用</td><td><pre>
add1 y = add(1, y)
</pre></td><td><pre>
add1 = add 1
</pre></td></tr><tr><td>使用例</td><td colspan="2"><pre>
&gt; add1 2
3
</pre></td></tr></table>

`add x y = x + y` は `add = \x -> \y -> x + y` の糖衣構文です。

# Q&A

Q. カリー化は何が嬉しいの？ 
A. 部分適用が簡単にできます。

Q. 部分適用なんて使うの？
A. コールバックの特殊化で便利ですが、JavaScriptではあまり使わないかもしれません。

Q. コールバックの特殊化とは？
A. 一部だけ異なるコールバックを大量に用意するのではなく、共通関数に対する部分適用で済ませるということです。

Q. あまり使わないのになぜJavaScriptで説明したの？
A. 馴染みのない言語の縁のない概念というわけではないからです。

※ 投げ槍な解答ですが、実例を通して慣れるしかないと思います。

# 参考

* [カリー化 - Wikipedia](http://ja.wikipedia.org/wiki/%E3%82%AB%E3%83%AA%E3%83%BC%E5%8C%96)

Haskellで説明を書きました。

* [Haskell ラムダ 超入門](http://qiita.com/7shi/items/1345bf32003faff435cb) 2014.11.27
