---
coediting: false
comments_count: 0
created_at: '2023-03-08T05:25:43+09:00'
id: 27b6f3169961299a6195
likes_count: 6
private: false
reactions_count: 0
stocks_count: 4
tags:
- name: JavaScript
  versions: []
- name: モナド
  versions: []
- name: CPS変換
  versions: []
title: CPS 変換から継続モナドへ
updated_at: ''
url: https://qiita.com/7shi/items/27b6f3169961299a6195
slide: false
---

CPS 変換をモナドにしたものが継続モナドです。必要となる最低限の事項を JavaScript の観点から説明します。

シリーズの記事です。

1. [ループと末尾再帰](https://qiita.com/7shi/items/5c44c23ef92f4c4273b4)
2. [CPS 変換による末尾再帰化](https://qiita.com/7shi/items/2d25f7afe25c3ca11acb)
3. CPS 変換から継続モナドへ ← この記事

# コンテナ

オブジェクトの入れ物となるオブジェクトを**コンテナ**と呼びます。

配列は代表的なコンテナです。ただし要素数が任意であることは配列特有で、コンテナの必須要件ではありません。

1 要素のコンテナの実装例です。

```js
class Container {
    constructor(value) { this.value = value; }
}
```

# bind

配列に対する操作として、JavaScript には `map` と `flatMap` というメソッドがあります。

同じ処理で使い方を比較します。

```js
> [1, 2, 3].map(x => x * 2)
[ 2, 4, 6 ]
> [1, 2, 3].flatMap(x => [x * 2])
[ 2, 4, 6 ]
```

それぞれのメソッドに渡すラムダ式（アロー関数式）に注目します。`map` に渡す方は要素から要素に変換するのに対して、`flatMap` に渡す方では要素から配列に変換します。

※ `flatMap` に配列ではなく要素を返す関数を渡せば `map` と同じ挙動を示しますが、ここではそのような使い方は例外的なものとして除外して考えます。

```js:ここでは除外
> [1, 2, 3].flatMap(x => x * 2)
[ 2, 4, 6 ]
```

`flatMap` のようにコンテナを返す関数を適用する操作を一般化して **bind** と呼びます。

※ bind という名前の由来は変数への**束縛**と見なせるためです。（詳細は後述）

## flatMap

bind の立場から考えると、配列に特化した bind が `flatMap` だと言えます。

渡す関数がコンテナを返すことで柔軟な処理が行えます。いくつか例を示します。

要素数を変化させることができます。

```js
> [1, 2, 3].flatMap(x => Array(x).fill(x))
[ 1, 2, 2, 3, 3, 3 ]
```

空配列を返すことで要素数が減らせるため、`filter` と同じことができます。

```js
> [1, 2, 3].filter(x => x != 2)
[ 1, 3 ]
> [1, 2, 3].flatMap(x => x != 2 ? [x] : [])
[ 1, 3 ]
```

これに対して `map` は要素を 1:1 で変換するため、配列の要素数は変化しません。配列を返すラムダ式を渡せば、要素が配列になります。

```js
> [1, 2, 3].map(x => Array(x).fill(x))
[ [ 1 ], [ 2, 2 ], [ 3, 3, 3 ] ]
> [1, 2, 3].map(x => x != 2 ? [x] : [])
[ [1], [], [3] ]
```

`flatMap` のようにコンテナを返す関数を受け取ることで、柔軟な操作が行えることが期待できます。

※ 同じ処理を `flatMap` を含む何種類かの方法で書いて比較する記事です。勘所をつかむのに参考になるかもしれません。

https://qiita.com/7shi/items/56071382384617911a58

# モナド

コンテナを生成する関数と bind を持ち、モナド則と呼ばれる規則を満たすコンテナを**モナド**と呼びます。

※ `flatMap` を bind とすれば、配列もモナドの一種だと見なせます。

今回の記事ではモナド則を満たすような例しか扱わないため、モナド則を前提とせずに読めるように配慮しました。そのため説明は省略します。詳細は以下を参照してください。

https://qiita.com/7shi/items/547b6137d7a3c482fe68

なお、map を持つコンテナを一般化したものは関手（functor）と呼ばれます。関手はモナドよりも基礎的なものとして位置付けられますが、説明は省略します。

## return

コンテナを生成する関数を Haskell では return と呼びます。JavaScript の `return` のように関数から抜けて値を返すという機能はなく、まったくの別物です。

※ 用途として多少重なる部分があり、命名の際に意識されたようです。（詳細は後述）

return はコンテナの内部構造を抽象化しているため、必ずしもコンテナが実際に保持するオブジェクトをそのまま引数に取るとは限りません。今回の記事ではモナドをクラスとして実装して、コンストラクタの引数はコンテナが内部で保持するオブジェクトを直接受け取ることとします。コンストラクタとは別に return に相当する `ret` という静的メソッドを用意します。

※ `return` は予約語で名前に使えないため、省略して `ret` としました。

## 恒等モナド

1 要素だけを保持するコンテナに bind を実装すると、恒等モナドと呼ばれる最も簡単なモナドになります。

```js:恒等モナド
class Identity {
    constructor(value) { this.value = value; }
    static ret(value) { return new Identity(value); }
    bind(k) { return k(this.value); }
}
```

値をそのまま保持するため、`ret` からは単にコンストラクタを呼ぶだけです。

`bind` に渡す `k` は `Identity` を返すため、`bind` の戻り値も `Identity` となります。

※ 型を TypeScript で書けば以下の通りです。

```ts:TypeScript
class Identity<T> {
    constructor(public value: T) { }
    static ret<T>(value: T): Identity<T> { return new Identity(value); }
    bind<U>(k: (value: T) => Identity<U>): Identity<U> { return k(this.value); }
}
```

使用例を示します。（JavaScript と TypeScript で共通）

```js
> Identity.ret(1).bind(x => Identity.ret(x + 1).bind(y => Identity.ret(x * y)))
Identity { value: 2 }
```

`bind` に渡すラムダ式の引数にはコンテナが持つ値が渡されます。これを変数への束縛に対応付けるのが、bind の名前の由来のようです。

具体的には以下のように対応します。

```js
Identity.ret(    1).bind(x =>  // const x = 1;
Identity.ret(x + 1).bind(y =>  // const y = x + 1;
Identity.ret(x * y)))          // return x * y;
```

Haskell には do ブロックという、モナドの操作を上記コメントのような形で書くための糖衣構文が用意されています。変数への束縛が直感的に表現できます。

```hs:Haskell
do
    x <- return 1
    y <- return (x + 1)
    return (x * y)
```

繰り返しますが `return` はモナドを生成する関数で、JavaScript の return のように値を返すという機能はありません。bind に渡す関数はモナドを返す必要があるため、最後に戻り値となるモナドを生成するのに `return` が使われます。上記の例を見ると、末尾の `return` はまるで値を返しているように見えます。このことが命名で意識されたようです。

## 配列との関係

恒等モナドは 1 要素固定の配列だと見なせます。それを端的に示す例です。

```js:配列
> a1 = [1]
[ 1 ]
> a2 = a1.flatMap(x => [x + 1])
[ 2 ]
```
```js:恒等モナド
> i1 = Identity.ret(1)
Identity { value: 1 }
> i2 = i1.bind(x => Identity.ret(x + 1))
Identity { value: 2 }
```

`flatMap` と `bind` が同じように機能していることが分かります。

# DSL

恒等モナドは値をそのまま持っているだけなので、何か特別な機能を提供するわけではありません。

モナドでの値の持ち方を工夫して bind の振る舞いを定義することで、各種の有用なモナドを構成することができます。例えば複数の値を持てるようにして bind で `flatMap` を実装すれば、配列をモナドとして構成したことになります。

イメージとしては、モナドで DSL を構築して、用途に特化した処理を do ブロックで記述する、という感じです。JavaScript では Promise に特化した糖衣構文として async/await がありますが、それを一般化してユーザー定義できるようにしたようなものです。

Promise は、`resolve` を return、`then` を bind だと考えれば、簡単な例ではモナドとして振る舞います。`async function` は do ブロックに対応します。

```js:then
Promise.resolve(1).then(x =>
Promise.resolve(x + 1).then(y =>
Promise.resolve(x * y)))
```
```js:async function
async function () {
    const x = await Promise.resolve(1);
    const y = await Promise.resolve(x + 1);
    return Promise.resolve(x * y);
}
```

※ 複雑な例では Promise は必ずしもモナドとして振る舞うとは限りません（モナド則を満たさないことがあります）。言語設計者はモナドのことは当然知っているはずですが、実装上の都合を優先したのでしょう。

# 継続モナド

各種モナドを説明するのが目的ではないため、そのうちの 1 つである継続モナドに焦点を絞ります。

恒等モナドの `bind` を再掲します。

```js:再掲
    bind(k) { return k(this.value); }
```

`bind` を CPS として見れば `k` は継続となります。そういう目で恒等モナドの使用例を見れば、bind によって継続をつないでいます。

```js:再掲
> Identity.ret(1).bind(x => Identity.ret(x + 1).bind(y => Identity.ret(x * y)))
Identity { value: 2 }
```

恒等モナドに継続を渡すことはできますが、外部から与えられるだけで取り出すことはできません。

継続を取り出せるようにするため（詳細は後述）、モナド内部で継続渡しスタイルの関数を保持するようにしたのが**継続モナド**です。

```js:継続モナド
class Cont {
    constructor(runCont) { this.runCont = runCont; }
    static ret(x) { return new Cont(k => k(x)); }
    bind(k) { return new Cont(c => this.runCont(x => k(x).runCont(c))); }
    evalCont() { return this.runCont(x => x); }
}
```

恒等モナドとは内部の実装が変化していますが、表面的な使い方は変わりません。先ほどの恒等モナドの例を `Identity` から `Cont` に書き換えて実行します。

```js
> Cont.ret(1).bind(x => Cont.ret(x + 1).bind(y => Cont.ret(x * y)))
Cont { runCont: [Function (anonymous)] }
```

恒等モナドでは値を直接保持していたため値が見えましたが、継続モナドでは関数を保持しているため値は見えません。

## return

`ret` では恒等モナドと同じように値からモナドを生成しますが、値を CPS の関数に変換して保持します。

```js:再掲
    static ret(x) { return new Cont(k => k(x)); }
```

保持されている関数は `runCont` でアクセスできるため、継続として恒等関数を渡すことで値が取り出せます。

```js
> m = Cont.ret(1)
Cont { runCont: [Function (anonymous)] }
> m.runCont(x => x)
1
```

値の取り出しは頻繁に使うため `evalCont` というメソッドを用意しました。

```js
> m.evalCont()
1
```

先ほどの例も同様に値が取り出せます。

```js
> Cont.ret(1).bind(x => Cont.ret(x + 1).bind(y => Cont.ret(x * y))).evalCont()
2
```

`ret` を使わずにコンストラクタを直接呼ぶように書き換えれば、内部が CPS 化されていることが見て取れます。

```js
> new Cont(k => k(1)).bind(x => new Cont(k => k(x + 1)).bind(y => new Cont(k => k(x * y)))).evalCont()
2
```

こういった内部構造が `ret` によって覆い隠されているわけです。

## bind

bind の挙動を確認するため、配列と恒等モナドの比較に使用した例を継続モナドでも試します。

```js
> c1 = Cont.ret(1)
Cont { runCont: [Function (anonymous)] }
> c2 = c1.bind(x => Cont.ret(x + 1))
Cont { runCont: [Function (anonymous)] }
> c1.evalCont()
1
> c2.evalCont()
2
```

`c2` は `c1` に対して bind したものですが、`c2` 自体がモナドとなります。モナドは bind によってどんどん成長します。

配列や恒等モナドでは値を直接保持しているため `bind` で計算が行われます。それに対して継続モナドでは bind はモナドと関数の結合だけを行い、結合が完了したモナドに継続を渡した（`evalCont` が呼ばれた）ときに計算が行われます。（[結合の様子は後述](#bind-による結合)）

bind がどのように実装されるのか、段階を追って説明します。bind される側のモナドを `M`、bind に渡す関数を `K`、値を取り出すための継続を `C` とします。

※ 仮引数と区別するため大文字にします。

```js
> M = Cont.ret(1)
Cont { runCont: [Function (anonymous)] }
> K = x => Cont.ret(x + 1)
[Function: K]
> C = x => x
[Function: C]
```

`K` と `C` はどちらも継続と呼ばれますが、型が違うことに注意が必要です。

| | 受け取るもの | 返すもの |
|---|---|---|
| `K`（bind に渡す関数） | 値 | モナド |
| `C`（`runCont` に渡す継続） | 値 | 結果 |

`M` に `C` を渡せば、`M` が保持している CPS の関数が呼ばれて結果が得られます。

```js
> M.runCont(C)
1
```

bind は、この `C` の位置に `K` をつなぎ込む操作です。しかし `C` の位置に置けるのは値から結果を返す関数です。`K` が返すのはモナドなので、剝がして型を合わせる必要があります。

`M` から得られた `1` で `K` を呼べば、モナドが得られます。

```js:値 → モナド
> K(1)
Cont { runCont: [Function (anonymous)] }
```

モナドから `runCont` を取り出せば、中の CPS の関数が得られます。これがモナドを剝がす操作です。

```js:値 → CPS の関数
> K(1).runCont
[Function (anonymous)]
```

その CPS の関数に継続を渡せば、ようやく結果が得られます。

```js:値 → 結果
> K(1).runCont(C)
2
```

ここまで直接書いてきた `1` は `M` が内部で継続に渡す値なので、bind の時点では決まっていません。そこで `1` を仮引数 `x` に変えて、外部から与えられるようにします。

```js:値を仮引数に分離
> K1 = x => K(x).runCont(C)
[Function: K1]
> K1(1)
2
```

これで `K1` が値から結果を返す関数になったため、`M.runCont(C)` の `C` の位置につなぎ込みます。

```js:C の位置に K をつなぎ込む
> M.runCont(C)
1
> M.runCont(K1)
2
```

ここまで直接書いてきた `C` は bind の時点では決まっていないため、仮引数 `c` に変えて、外部から与えられるようにします。

```js:継続を仮引数に分離
> M_K = c => M.runCont(K1)
[Function: M_K]
> M_K(C)
2
```

bind はモナドを返すため、`M_K` をモナドに包みます。

```js:モナドに包む
> M_bind_K = new Cont(M_K)
Cont { runCont: [Function: M_K] }
> M_bind_K.runCont(C)
2
```

`M_bind_K` をインライン展開します。

```js:インライン展開
> M_bind_K = new Cont(c => M.runCont(x => K(x).runCont(C)))
Cont { runCont: [Function (anonymous)] }
```

`M` を `this`、`K` を引数 `k` にしてメソッドにすることで、最初に示した実装が得られます。

```js:メソッドにする
    bind(k) { return new Cont(c => this.runCont(x => k(x).runCont(c))); }
```

かなり複雑な実装になりましたが、要点をまとめます。

* `m.bind(k)` において、`bind` に渡す関数 `k`（モナドを返す）と `runCont` に渡す継続 `c`（結果を返す）は型が異なるため、bind は `k` を `c` の型に変換する必要がある。
* 具体的には `x => k(x).runCont(c)` として、`k` の返したモナドを `runCont` で剝がして継続 `c` を渡す。これで値から結果を返す関数に変換できる。
* 恒等モナドの bind は `m` が持つ値で `k` を即座に呼び、`k` が返すモナドがそのまま bind の戻り値となる。それに対して、継続モナドでは bind の時点では `k` はまだ呼ばれず、変換した `k` を `m` に結合した新しいモナドが bind の戻り値となる。

※ モナドとしての表面上の使い方は恒等モナドと継続モナドとで大きく違わないため、実装の詳細に踏み込まなくても、実用上は評価のタイミングだけ意識しておけば使うことは可能です。

### bind による結合

bind でどのように結合されるのか、インライン展開したものを式変形して確認します。次の行で書き換える箇所を赤字で示します。

1. `M`
   → `new Cont(c => M.runCont(c))` ※ 比較用
2. `M.bind(K1)`
   → `new Cont(c => M.runCont(x => K1(x).runCont(c)))`
3. <code><font color="red"><b>M.bind(K1)</b></font>.bind(K2)</code>
   → <code>new Cont(c => M.runCont(x => K1(x).runCont(c)))<font color="red"><b>.bind(K2)</b></font></code>
   → <code><font color="red"><b>new Cont</b></font>(c => new Cont(c => M.runCont(x => K1(x).runCont(c)))<font color="red"><b>.runCont</b></font>(x => K2(x).runCont(c)))</code>
   → <code><font color="red"><b>(c => </b></font>new Cont(c => M.runCont(x => K1(x).runCont(<font color="red"><b>c</b></font>)))<font color="red"><b>(x => K2(x).runCont(c)))</b></font></code>
   → `new Cont(c => M.runCont(x => K1(x).runCont(x => K2(x).runCont(c))))`

※ 3 はラムダ式に適用した実引数を仮引数に展開しています。このような式変形をベータ簡約と呼びます。

式変形の過程を省略して並べます。`runCont(c)` の `c` に継続が埋め込まれる様子が分かります（赤字部分）。

1. <code>new Cont(c => M.runCont(<font color="red"><b>c</b></font>))</code>
2. <code>new Cont(c => M.runCont(<font color="red"><b>x => K1(x).runCont(c)</b></font>))</code>
3. <code>new Cont(c => M.runCont(x => K1(x).runCont(<font color="red"><b>x => K2(x).runCont(c)</b></font>)))</code>

※ 2 を単独で見る（bind の実装）と複雑に見えますが、1 と 3 を並べることでパターンが明確になります。

## callCC

継続モナドは継続の連結によって組み立てられるため、継続が取り出せます。そのための `callCC` という関数の実装を示します。

```js
function callCC(f) {
    return new Cont(c => f(x => new Cont(_ => c(x))).runCont(c));
}
```

`callCC` は call with current continuation の省略形です。`callCC` に 1 引数の関数を渡せば、現在の継続（CC: Current Continuation）を引数として関数が呼ばれます（call）。現在の継続とは `callCC` の継続、つまり `runCont` に渡された `c` のことです。

### 使用例

実装の詳細に入る前に、`callCC` で何ができるのかを確認します。以下の関数を継続モナドと `callCC` で書き換えます。

```js
function f(x) {
    if (x == 0) return "zero";
    return "non-zero";
}
```

`callCC` に渡す 1 引数の関数はラムダ式としてその場で定義するパターンが多いです。目的の処理を `callCC` とラムダ式で包むことで、処理から抜けるという動作を追加することができます。

```js
function f(x) {
    return callCC(ret =>
        (x == 0 ? ret("zero") : Cont.ret()).bind(_ =>
        Cont.ret("non-zero"))
    ).evalCont();
}
```
```js:実行結果
> f(0)
'zero'
> f(1)
'non-zero'
```

`x == 0` のときは `ret("zero")` によって、bind でつながれた後続の `Cont.ret("non-zero")` が飛ばされています。この動作がどのように実現されているのかを、以下で組み立てていきます。

### 実装の組み立て

`callCC` もモナドを返すため `new Cont(c => ...)` という形になります。この `c` が現在の継続です。`f` はモナドを返すので、`c` を渡せば結果が得られます。

```js:骨組み
new Cont(c => f(?).runCont(c))
```

残るのは `f` に渡す `?` の部分です。取り出したい継続は `c` ですが、`c` は値から結果を返す関数なので、そのままでは `f` の中で bind につなげられません。bind に渡す `k` と同じ型（値からモナドを返す関数）に変換する必要があります。bind とは変換の向きが逆です。

| | 変換するもの | 変換後 | 実装 |
|---|---|---|---|
| bind | `k`（値 → モナド） | `c` と同じ型 | `x => k(x).runCont(c)` |
| `callCC` | `c`（値 → 結果） | `k` と同じ型 | `x => new Cont(_ => c(x))` |

`x =>` で値を受け取って `c(x)` で結果を得て、それを `new Cont` で包めばモナドになります。このとき包んだ関数の仮引数は後続の継続を受け取りますが、`_` として捨てます。

つまり後続を飛ばす処理は、取り出される継続そのものに埋め込まれています。これで最初に示した実装になります。

```js:再掲
function callCC(f) {
    return new Cont(c => f(x => new Cont(_ => c(x))).runCont(c));
}
```

動作を確認します。使用例の `x == 0` の場合と `x != 0` の場合に相当します。

```js
> callCC(ret => ret("zero").bind(_ => Cont.ret("non-zero"))).evalCont()
'zero'
> callCC(ret => Cont.ret("non-zero")).evalCont()
'non-zero'
```

取り出した継続を呼べば後続が飛ばされて `callCC` の継続に処理が移ります。

実装には `c(x)` と `.runCont(c)` の 2 箇所で `c` が現れるため二重に適用しているように見えますが、上の 2 例はどちらか一方だけを通ります。

| 例 | 結果 | `c` を適用する箇所 |
|---|---|---|
| `ret("zero")` を呼ぶ | `'zero'` | `c(x)` |
| `ret` を呼ばない | `'non-zero'` | `.runCont(c)` |

`.runCont(c)` が渡す継続は、bind で結合された後続の末尾に `c` が埋め込まれたものです。`ret("zero")` を呼ぶと `_ => c(x)` がその継続を丸ごと無視するため、末尾の `c` には到達しません。

### ジェネレーター

継続モナドでの継続は bind で結合された範囲内に限定されるため、継続モナドから抜ければ呼び出し元に戻ります。継続モナドから抜けるときに継続を返すことで、後で継続モナドを再開することができます。

※ このように継続の対象が一定の範囲に閉じているという性質は、限定継続（`shift`/`reset`）と呼ばれる仕組みと共通します。ただし `callCC` で取り出した継続は bind で結合された後続を捨てるため、限定継続のようにその場へ値を返して計算を続けることはできません。そのため抜けるための継続と再開するための継続を別々に取り出して組み合わせる必要があります。👉[参考 (Scheme)](https://qiita.com/7shi/items/6db3e19ddc1f8552d9a0)

これを利用すればジェネレーターが実装できます。

```js
function g() {
    return { value: undefined, next: () => callCC(ccOut => {
        function yield(value) {
            return callCC(next => ccOut({value, next}));
        }
        return (
            yield(1).bind(_ =>
            yield(2).bind(_ =>
            yield(3).bind(_ =>
            Cont.ret()
        ))));
    })};
}

let it = g();
while (it = it.next().evalCont()) {
    console.log(it.value);
}
```
```text:実行結果
1
2
3
```

※ このジェネレーターは JavaScript で先に実装したもので、Haskell へは逆に移植しました。Scheme で `call/cc` を使う場合とは実装が異なります。詳細は次節で説明します。

# Haskell と Scheme

今回の記事は JavaScript の知識がある方を念頭に、Haskell と Scheme からエッセンスを抽出して JavaScript で説明することを試みました。

モナドの上に継続を構築しているため二重の難しさがありますが、コードで構築されているためいじりながら理解を深めることが可能になります。コードから構築するアプローチとしては継続をサポートした処理系を作るという方法もありますが、継続モナドなら数行で済むためそれよりはお手軽です。

継続モナドの実装自体は短いので、JavaScript で書いても Haskell よりコード量が増えるわけではありません。ただし実装されたモナドを使う段階になると bind を明示的に書くのは入り組んでしまうので、Haskell の do ブロックのように言語仕様でモナドのサポートがあった方が書きやすくはあります。

`call/cc` の本家である Scheme では言語仕様として継続がサポートされます（第一級継続）。実装からのアプローチではなく、使うことで理解を深めるという観点では継続モナドよりもお手軽です。

継続モナドを用いた `callCC` では、継続の対象となるのは bind で結合された範囲に限定されます。それに対して Scheme の継続はそれまでのコールフロー全体を対象とするため呼び出し元まで記録されます。そのため Scheme の `call/cc` でジェネレーターを実装すると、再開後に呼び出し元へ戻るには呼び出し元からも継続を渡す必要があります。詳細は以下の記事を参照してください。

https://qiita.com/7shi/items/a44c5257f04f0c641ef0

## 移植元

Haskell での継続モナドの説明とソースを参照しました。

https://hackage.haskell.org/package/transformers-0.6.1.0/docs/Control-Monad-Trans-Cont.html

※ 関数などの見出しの右端にある Source からソースに飛びます。

モナド変換子 `ContT` を介在させずに直接 `Cont` と `callCC` を実装するように書き換えました。

```hs:モナド変換子を取り除いた実装
newtype Cont r a = Cont { runCont :: (a -> r) -> r }

instance Monad (Cont r) where
    return x = Cont ($ x)
    m >>= k  = Cont $ \c -> runCont m (\x -> runCont (k x) c)

evalCont :: Cont r r -> r
evalCont = (`runCont` id)

callCC :: ((a -> Cont r b) -> Cont r a) -> Cont r a
callCC f = Cont $ \c -> runCont (f (\x -> Cont $ \_ -> c x)) c
```

※ 現在の GHC では `Monad` のスーパークラスである `Functor` と `Applicative` のインスタンスも必要です。`Control.Monad` から `liftM` と `ap` を import して `fmap = liftM`、`(<*>) = ap` と書けば済みます。

`callCC` の使用例は Haskell で先に動作確認しました。

```hs
f x = evalCont $ callCC $ \ret -> do
    when (x == 0) (ret "zero")
    return "non-zero"
```

これらを JavaScript に移植しました。

## ジェネレーター

ジェネレーターは当初 Haskell でうまく実装できなかったため、JavaScript で先に実装しました。それを Haskell に移植する際、`{value, next}` に相当する型が循環するため、`data` で包む必要がありました。

※ JavaScript は動的型付けのため型の循環でエラーになることはありませんが、もちろん間違った使い方をすれば実行時エラーになります。Haskell と Scheme の中間のような使用感だと思いました。

```hs:ジェネレーター
data It = It { value :: Maybe Int, next :: () -> Cont It It }

g :: It
g = It Nothing $ \_ -> callCC $ \ccOut ->
    let yield v = callCC $ \nxt -> ccOut (It (Just v) nxt)
    in do
        yield 1
        yield 2
        yield 3
        return (It Nothing (\_ -> error "done"))

main :: IO ()
main = go g
  where
    go it =
        let it' = evalCont (next it ())
        in case value it' of
            Nothing -> return ()
            Just v  -> print v >> go it'
```
```text:実行結果
1
2
3
```

`main` の `go` が JavaScript の `while (it = it.next().evalCont())` に相当します。値の有無は `undefined` の代わりに `Maybe` で表しました。

型が循環する理由と、直和型で整理した実装は別記事にまとめました。

https://zenn.dev/7shi/articles/20260730-haskell-generator
