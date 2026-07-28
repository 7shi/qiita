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
updated_at: '2024-01-26T11:45:23+09:00'
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
    bind(f) { return f(this.value); }
}
```

値をそのまま保持するため、`ret` からは単にコンストラクタを呼ぶだけです。

`bind` に渡す `f` は `Identity` を返すため、`bind` の戻り値も `Identity` となります。

※ 型を TypeScript で書けば以下の通りです。

```ts:TypeScript
class Identity<T> {
    constructor(public value: T) { }
    static ret<T>(value: T): Identity<T> { return new Identity(value); }
    bind<U>(f: (value: T) => Identity<U>): Identity<U> { return f(this.value); }
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
    bind(f) { return f(this.value); }
```

`bind` を CPS として見れば `f` は継続となります。そういう目で恒等モナドの使用例を見れば、bind によって継続をつないでいます。

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

bind がどのように実装されるのか、段階を追って説明します。

単純なケースでは bind を `runCont` に置き換えても動きます。

```js
> m = Cont.ret(1)
Cont { runCont: [Function (anonymous)] }
> k = x => Cont.ret(x + 1)
[Function: k]
> m.bind(k).evalCont()
2
> m.runCont(k).evalCont()
2
```

これを仮にクラス外の関数として定義します。

```js:仮実装
> function bind1(m, k) { return m.runCont(k); }
undefined
> bind1(m, k).evalCont()
2
```

bind にはモナドを返す関数を渡す仕様のため、この実装では継続からモナドが返されます。状況を確認するため `Cont.ret` を使わずに継続の返り値を覗いてみます。

```js
> mlog = new Cont(k => { let r = k(1); console.log(r); return r; })
Cont { runCont: [Function (anonymous)] }
> bind1(mlog, k).evalCont()
Cont { runCont: [Function (anonymous)] }
2
```

※ `k(1)` は継続を取り出して使用しています。振る舞いとしては限定継続と呼ばれるタイプですが、詳細は機会を改めます。

継続モナドは関数をラップしているだけで、実際の計算はモナドがないかのように扱えることが望ましいです。最初のモナドから見えているのは `runCont` への引数なので、その部分でモナドを剝がしてから再度包むようにします。

```js:仮実装
> function bind2(m, k) { return new Cont(m.runCont(x => k(x).runCont)); }
undefined
> bind2(m, k).evalCont()
2
> bind2(mlog, k).evalCont()
[Function (anonymous)]
2
```

`k(1)` は関数です。これは CPS との対応を考えると分かります。

```js:モナドを介さない CPS
> (k => k(1))(x => k => k(x + 1))(x => x)
2
```

継続として受け取った `k` は上記 CPS の `x => k => k(x + 1)` に対応するため、`k(1)` は `x = 1` とした `k => k(x + 1)` となります。（部分適用）

CPS をラップするという考え方ではこれで良さそうですが、一歩進めて `k` を直接スタイルの関数として扱えるようにします。これは bind 完了後に `evalCont` などで渡される継続を適用することで行えます。

```js:仮実装
> function bind3(m, k) { return new Cont(c => m.runCont(x => k(x).runCont(c))); }
undefined
> bind3(m, k).evalCont()
2
> bind3(mlog, k).evalCont()
2
2
```

メソッドとして実装すれば完成です。

```js:再掲
    bind(k) { return new Cont(c => this.runCont(x => k(x).runCont(c))); }
```

かなり複雑な実装になりましたが、要点をまとめます。

* 取り出した継続はモナドを含まずに、直接スタイルの関数として扱える。
* bind に渡した関数が返すモナドがそのまま bind の戻り値とはならずに、再構築されたものが返される。
  ※ 実装の詳細を追うのでなければ、実用上はそのまま戻されたと思って扱える。

### bind による結合

bind でどのように結合されるのか、インライン展開したものを式変形して確認します。式変形で操作する個所を赤字で示します。

1. `m`
   → `new Cont(c => m.runCont(c))` ※ 比較用
2. `m.bind(k1)`
   → `new Cont(c => m.runCont(x => k1(x).runCont(c)))`
3. <code><font color="red"><b>m.bind(k1)</b></font>.bind(k2)</code>
   → <code>new Cont(c => m.runCont(x => k1(x).runCont(c)))<font color="red"><b>.bind(k2)</b></font></code>
   → <code><font color="red"><b>new Cont</b></font>(c => new Cont(c => m.runCont(x => k1(x).runCont(c)))<font color="red"><b>.runCont</b></font>(x => k2(x).runCont(c)))</code>
   → <code><font color="red"><b>(c => </b></font>new Cont(c => m.runCont(x => k1(x).runCont(<font color="red"><b>c</b></font>)))<font color="red"><b>(x => k2(x).runCont(c)))</b></font></code>
   → `new Cont(c => m.runCont(x => k1(x).runCont(x => k2(x).runCont(c))))`

※ 3 はラムダ式に適用した実引数を仮引数に展開しています。このような式変形をベータ簡約と呼びます。

式変形の過程を省略して並べます。`runCont(c)` の `c` に継続が埋め込まれる様子が分かります（赤字部分）。

1. <code>new Cont(c => m.runCont(<font color="red"><b>c</b></font>))</code>
2. <code>new Cont(c => m.runCont(<font color="red"><b>x => k1(x).runCont(c)</b></font>))</code>
3. <code>new Cont(c => m.runCont(x => k1(x).runCont(<font color="red"><b>x => k2(x).runCont(c)</b></font>)))</code>

※ 2 を単独で見る（bind の実装）と複雑に見えますが、1 と 3 を並べることでパターンが明確になります。

## callCC

継続モナドは継続の連結によって組み立てられるため、継続が取り出せます。そのための `callCC` という関数の実装を示します。

```js
function callCC(f) {
    return new Cont(c => f(x => new Cont(_ => c(x))).runCont(c));
}
```

`callCC` は call with current continuation の省略形です。

`callCC` の使い方は独特です。`callCC` に 1 引数の関数を渡せば、現在の継続（CC: Current Continuation）を引数として関数が呼ばれます（call）。現在の継続とは `callCC` の継続で、実装での `f(...)` の引数部分に対応します。

```js:現在の継続
x => new Cont(_ => c(x))
```

これを呼び出すことで `bind` によって結合された後続の継続を飛ばして、`callCC` の継続に処理が移ります。

※ 関数が継続モナドで構成されていれば、関数から抜けると見なせます。

最後の `.runCont(c)` の部分は、引数として渡される継続を呼ばなかったときだけ使われます。

※ 引数として渡される継続を呼び出すと `c(x)` と `.runCont(c)` で `c` を二重に適用しているように見えますが、`_ => c(x)` で引数を無視することによって bind で結合された継続は処理されないため `.runCont(c)` も処理されません。

### 使用例

以下の関数を継続モナドと `callCC` で書き換えます。

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

### ジェネレーター

継続モナドでの継続は bind で結合された範囲内に限定されるため、継続モナドから抜ければ呼び出し元に戻ります。継続モナドから抜けるときに継続を返すことで、後で継続モナドを再開することができます。

※ 限定継続と似たような動きですが、細かい点が異なります。詳細は機会を改めます。

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

※ この実装は Haskell とも Scheme とも異なります。それについては次節で説明します。

# Haskell と Scheme

今回の記事は JavaScript の知識がある方を念頭に、Haskell と Scheme からエッセンスを抽出して JavaScript で説明することを試みました。

モナドの上に継続を構築しているため二重の難しさがありますが、コードで構築されているためいじりながら理解を深めることが可能になります。コードから構築するアプローチとしては継続をサポートした処理系を作るという方法もありますが、継続モナドなら数行で済むためそれよりはお手軽です。

継続モナドの実装自体は短いので、JavaScript で書いても Haskell よりコード量が増えるわけではありません。ただし実装されたモナドを使う段階になると bind を明示的に書くのは入り組んでしまうので、Haskell の do ブロックのように言語仕様でモナドのサポートがあった方が書きやすくはあります。

`call/cc` の本家である Scheme では言語仕様として継続がサポートされます（第一級継続）。実装からのアプローチではなく、使うことで理解を深めるという観点では継続モナドよりもお手軽です。

継続モナドを用いた `callCC` では、継続の対象となるのは bind で結合された範囲に限定されます。それに対して Scheme の継続はそれまでのコールフロー全体を対象とするため呼び出し元まで記録されます。そのため Scheme の `call/cc` でジェネレーターを実装すると、再開後に呼び出し元へ戻るには呼び出し元からも継続を渡す必要があります。詳細は以下の記事を参照してください。

https://qiita.com/7shi/items/a44c5257f04f0c641ef0

Haskell ではジェネレーターから継続を返す部分で型が循環しますが、`data` で包めば移植できます。詳細は[後述](#haskell-への移植)します。

JavaScript は動的型付けのため型エラーで実行できないということはありませんが、もちろん間違った使い方をすれば実行時エラーになります。Haskell と Scheme の中間のような使用感だと思いました。

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

`callCC` の使用例は Haskell で先に動作確認しました。

```hs
f x = evalCont $ callCC $ \ret -> do
    when (x == 0) (ret "zero")
    return "non-zero"
```

これらを JavaScript に移植しました。

ジェネレーターの例は素朴に書き直しただけではコンパイルを通せないため、節を改めて説明します。

# Haskell への移植

ジェネレーターを Haskell に移植します。型が循環するため素朴には書けませんが、`data` を使えば解決します。

## type だけだと循環する

JS のジェネレーターが返すオブジェクト `{value, next}` の型を考えます。`next` は継続モナドを返し、その継続モナドの答えの型（`Cont r a` の `r`）は `{value, next}` 自身です。

型シノニムで書いてみます。

```hs:型シノニム
type It = (Maybe Int, () -> Cont It It)
```

右辺に `It` が現れています。型シノニムは名前を展開するだけのものなので、展開しても

* `(Maybe Int, () -> Cont (Maybe Int, () -> Cont ... ) ... )`

のように終わりません。GHC はこれを受け付けません。

```text:エラー
Cycle in type synonym declarations:
  type It = (Maybe Int, () -> Cont It It)
```

型シノニムを使わずタプルのまま型推論に任せても、同じところに行き着きます。Haskell の型は有限の木として表されるため、自分自身を含む型は表せません。型推論では、この状況を occurs check という検査で検出します。

※ `evalCont` を呼ぶまでは答えの型 `r` が多相なままなので、エラーは出ません。`r` がタプルの型に確定した瞬間にエラーとなります。

## data を使うと解決する

`data`（および `newtype`）は型を**名前で**新しく導入します。`It` は `It` という型そのものであって、中身のタプルの型と同一視されるわけではありません。型としては展開されない一枚岩なので、フィールドの型に自分自身が現れても構いません。

※ リストの定義 `data [a] = [] | a:[a]` も自分自身を含んでいます。再帰的なデータ構造は `data` で表現できます。

先ほどの型シノニムを `data`（レコード構文）で書き直します。

```hs:レコード構文
data It = It { value :: Maybe Int, next :: () -> Cont It It }
```

これで型が付きます。JS 版とほぼ一対一に対応する形で移植できます。

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

JS では値の有無を `undefined` で判定していましたが、Haskell では `Maybe` を使いました。`main` の `go` が JS の `while (it = it.next().evalCont())` に相当します。

`data` で包む代償は、コンストラクタ `It` を付けて作りパターンマッチで剝がす手間だけです。JS の無名オブジェクトに名前を付けたに過ぎません。

※ `callCC` の型 `((a -> Cont r b) -> Cont r a) -> Cont r a` の `b` は、`yield` を使う文脈で `It` に確定するため、多相性を扱う言語拡張（RankNTypes）は必要ありません。

※ 前掲の `Cont` の実装をそのまま使う場合、GHC では `Monad` のスーパークラスである `Functor` と `Applicative` のインスタンスも必要です。`fmap = liftM`、`(<*>) = ap` で済みます（`Control.Monad` から import）。標準の `Control.Monad.Trans.Cont` を使っても同じように動きます。

## 直和型による整理

値の有無を `Maybe` で表す代わりに直和型にすると、Haskell らしく整理できます。

```hs:整理した版
data Gen a
    = Done
    | Yield a (Cont (Gen a) (Gen a))  -- 値と、再開用の継続

yield ccOut v = callCC $ \next -> ccOut (Yield v (next ()))

runGen body = evalCont $ callCC $ \ccOut -> body ccOut >> return Done

toList Done = []
toList (Yield v k) = v : toList (evalCont k)
```

`Cont` の答えの型を `Gen a` 自身にしている点は変わりません。`runGen` でジェネレーターを組み立て、`toList` でリストに変換します。

```hs:使用例
g123    = runGen $ \ccOut -> let y = yield ccOut in do { y 1; y 2; y 3 }
nats    = runGen $ \ccOut -> let loop n = yield ccOut n >> loop (n + 1) in loop 0
squares = runGen $ \ccOut -> mapM_ (\n -> yield ccOut (n * n)) [1 .. 5]
```
```text:実行結果
> toList g123
[1,2,3]
> take 5 (toList nats)
[0,1,2,3,4]
> toList squares
[1,4,9,16,25]
```

`nats` のように無限のジェネレーターも書けます。また `do` ブロックが使えるため、`mapM_` のような既存のモナド用の関数がそのまま使えます。JavaScript で `bind` を入れ子にするより見通しが良くなります。
