---
coediting: false
comments_count: 0
created_at: '2023-02-26T20:06:56+09:00'
id: 2d25f7afe25c3ca11acb
likes_count: 9
private: false
reactions_count: 0
stocks_count: 3
tags:
- name: JavaScript
  versions: []
- name: 末尾再帰
  versions: []
- name: CPS変換
  versions: []
title: CPS 変換による末尾再帰化
updated_at: '2024-04-09T16:50:44+09:00'
url: https://qiita.com/7shi/items/2d25f7afe25c3ca11acb
slide: false
---

CPS 変換による非末尾再帰の末尾再帰化について説明します。前回説明したループと対応付けた末尾再帰とは異なる形です。

シリーズの記事です。

1. [ループと末尾再帰](https://qiita.com/7shi/items/5c44c23ef92f4c4273b4)
2. CPS 変換による末尾再帰化 ← この記事
3. [CPS 変換から継続モナドへ](https://qiita.com/7shi/items/27b6f3169961299a6195)

# 継続渡しスタイル

次のような `return` で値を返す関数があったとします。これを**直接スタイル**と呼びます。

```js:直接スタイル
function inc(x) {
    return(x + 1);
}
```

引数を追加して関数 `k` を受け取り、`return` を `k` に置き換えます。これは関数が値を返さずに別の関数に結果を渡しており、**継続渡しスタイル**（**CPS**: Continuation-passing style）と呼びます。

```js:継続渡しスタイル (CPS)
function incCPS(x, k) {
    k(x + 1);
}
```

`k` は「続きの処理」というニュアンスで**継続**と呼びます。関数に継続を渡すスタイルということです。

※1. Scheme には直接スタイルのコンテキストから継続を取り出す `call/cc` という関数があり、取り出した継続は `return` のように使えます。詳細は以下の記事を参照してください。

https://qiita.com/7shi/items/a44c5257f04f0c641ef0

※2. Promise に現れる `resolve` は継続に相当します。Promise については以下の記事を参照してください。

https://qiita.com/7shi/items/a2bb35f27cd4a56f7bac

## 使用例

それぞれの関数で計算結果を表示する例です。

```js
console.log(inc(1));
incCPS(1, console.log);
```
```text:実行結果
2
2
```

直接スタイルでは結果が戻り値として返されるのに対して、継続渡しスタイルでは結果を受け取る関数を指定します。

## 呼び出しのネスト

呼び出しをネストさせるときはラムダ式（アロー関数式）で結果を取り回します。

```js
console.log(inc(inc(1)));               // 3
incCPS(1, x => incCPS(x, console.log)); // 3
```

※ コメントは実行結果です。

ラムダ式の引数に値を渡すことは、直接スタイルで変数に値を束縛することに対応します。

```js
const x = inc(1);    // x = 2
console.log(inc(x)); // 3
```

## カリー化

呼び出し側でのラムダ式が煩雑ですが、省略できるようにする方法があります

多引数関数を 1 引数関数のネストで表現することを**カリー化**と呼びます。

※ カリー化については以下の記事を参照してください。

https://qiita.com/7shi/items/a0143daac77a205e7962

`incCPS` をカリー化します。

```js
function incCPSCurried(x) {
    return function (k) {
        k(x + 1);
    };
}

incCPSCurried(1)(x => incCPSCurried(x)(console.log)); // 3
```

これだけだと複雑になっただけであまり嬉しさはありませんが、少し手を加えてみます。

継続としてカリー化された関数を渡せば、`k(x + 1)` は継続を受け取る関数となります。これを返すようにすれば、呼び出し側では関数呼び出しを連続させる形になってラムダ式が不要になります。

```js
function incCPSCurried2(x) {
    return function (k) {
        return k(x + 1);
    };
}

incCPSCurried2(1)(incCPSCurried2)(console.log); // 3
```

見慣れない書き方かもしれませんが、括弧のネストが深くならず、実行順に記述されていることに注目すれば、意味を汲み取るのは難しくないはずです。

※ パイプラインのようなものだと捉えることができます。

https://qiita.com/ttatsf/items/65fb3187766306275cf9

なお、カリー化については紹介に留め、ここから先では使用しません。

# 階乗

直接スタイルによる非末尾再帰関数です。

```js
function fact(n) {
    if (n <= 1) {
        return 1;
    } else {
        return fact(n - 1) * n;
    }
}
```

継続渡しスタイルに書き換えます。非末尾再帰における復路で行う計算 `* n` を継続に押し込みます。

```js
function factCPS(n, k) {
    if (n <= 1) {
        k(1);
    } else {
        factCPS(n - 1, v => k(v * n));
    }
}
```

## 末尾再帰

`factCPS` が末尾再帰になっていることに注目してください。

※ 記事執筆時点で JavaScript では末尾呼び出しの最適化は Safari 以外で実装されていないため、ここでは事実上ないものとして扱います。そのため処理の効率化については考慮しません。

フローを示します。ラムダ式のネストが成長する過程を赤字で示します。

<table>
<tr><td>再帰</td><td>
factCPS( 5, k )<br>
→ factCPS( 4, <font color="red"><b>v =></b></font> k<font color="red"><b>(v * 5)</b></font> )<br>
→ factCPS( 3, <font color="red"><b>v =></b></font> (v => k(v * 5))<font color="red"><b>(v * 4)</b></font> )<br>
→ factCPS( 2, <font color="red"><b>v =></b></font> (v => (v => k(v * 5))(v * 4))<font color="red"><b>(v * 3)</b></font> )<br>
→ factCPS( 1, <font color="red"><b>v =></b></font> (v => (v => (v => k(v * 5))(v * 4))(v * 3))<font color="red"><b>(v * 2)</b></font> )<br>
</td></tr>
<tr><td>継続</td><td>
→ (v => (v => (v => (v => k(v * 5))(v * 4))(v * 3))(v * 2))<font color="red"><b>(1)</b></font><br>
→ (v => (v => (v => k(v * 5))(v * 4))(v * 3))(1 * 2)<br>
→ (v => (v => k(v * 5))(v * 4))(2 * 3)<br>
→ (v => k(v * 5))(6 * 4)<br>
→ k(24 * 5)<br>
</td></tr></table>

再帰から復路がなくなった代わりに、複雑に成長したラムダ式の計算があります。

## ベータ簡約

ネストしたラムダ式への実引数（赤字）を仮引数（青字）に入れ込むことでネストが解消します。このような変形を[ラムダ計算](https://ja.wikipedia.org/wiki/%E3%83%A9%E3%83%A0%E3%83%80%E8%A8%88%E7%AE%97)では**ベータ簡約**と呼びます。

<code>v => (<font color="blue"><b>v</b></font> => k(<font color="blue"><b>v</b></font> * 5)))<font color="red"><b>(v * 4)</b></font></code>
→ <code>v => k(<font color="red"><b>(v * 4)</b></font> * 5))</code>

ベータ簡約を使ったフローを示します。

<table><tr><td>
factCPS( 5, k )<br>
→ factCPS( 4, v => k(v * 5) )<br>
→ factCPS( 3, v => k((v * 4) * 5) )<br>
→ factCPS( 2, v => k((v * 3) * 20) )<br>
→ factCPS( 1, v => k((v * 2) * 60) )<br>
→ (v => k(v * 120))(1)<br>
→ k(120)
</td></tr></table>

※ 現実の JavaScript 処理系でこのような変形を行うのは難しそうですが、理論的には可能だということです。

## コンパイラとの関係

継続渡しスタイルによる再帰は手で書くのに適した形式とは言い難いですが、コンパイラで CPS 変換を行えば機械的に非末尾再帰を末尾再帰に変換できます。

説明を引用します。

https://qiita.com/tanakh/items/81fc1a0d9ae0af3865cb

> こんなまどろっこしいことをして何が嬉しいのかというと、実際のところこの例では嬉しい事はなにもないのですが、コンパイラの最適化などでは嬉しいケースも有ります。例えば、CPSにおいては、関数呼び出しは必ず末尾呼び出し、つまりただのジャンプとして扱うことができるのです。

> 毎回クロージャを作るなんて、このほうが効率悪いんじゃないの？と思うかもしれませんが、コンパイラが十分に賢ければ、このクロージャを作るのは回避されることが期待されて、なおかつ再帰呼び出しがジャンプに書き換えられて、このコードは理想的には極めて効率よく実行される「可能性がある」と言えます。「可能性がある」というのは、Haskellのコンパイラはこれをたまによくうまくやってくれないことがあって、でも気分が良ければ調子よくやってくれます。コンパイラの気持ちは複雑で人間は常に弄ばれます。
> 
> また、このCPSへの変換は通常機械的に行うことができます。機械的にCPSに変換した後に、アグレッシブな最適化をかけることによって、正しい末尾再帰の実装を特別な枠組みなしに実現したり、関数呼び出しがの最適化がやりやすくなったりしてコンパイラ自体の単純化にも寄与したりします。

# フィボナッチ数列

漸化式を再帰でコード化した一般的な実装を示します。

```js
function fib(n) {
    if (n <= 2) {
        return 1;
    } else {
        return fib(n - 2) + fib(n - 1);
    }
}
```

これを CPS 変換すれば末尾再帰になります。

```js
function fibCPS(n, k) {
    if (n <= 2) {
        k(1);
    } else {
        fibCPS(n - 2, a =>
            fibCPS(n - 1, b =>
                k(a + b)));
    }
}
```

計算のアルゴリズム自体は同じなので、CPS 変換によって計算量が削減されるわけではありません。

※ Node.js では `fibCPS` は `n` が 19 くらいでエラーになります。前述のように末尾呼び出しの最適化はないものとして、処理の効率化は考慮の対象外です。

## 分岐しない版

[前回の記事](https://qiita.com/7shi/items/5c44c23ef92f4c4273b4)で紹介した再帰が分岐しない実装を CPS 変換しやすいように手直ししたものです。

```js
function fib2(n) {
    function f(n) {
        if (n <= 2) {
            return [1, 1];
        } else {
            let [a, b] = f(n - 1);
            return [b, a + b];
        }
    }
    return f(n)[1];
}
```

CPS 変換します。非末尾再帰において復路で行う計算を継続に押し込みます。

```js
function fib2CPS(n, k) {
    function f(n, k) {
        if (n <= 2) {
            k(1, 1);
        } else {
            f(n - 1, (a, b) => k(b, a + b));
        }
    }
    f(n, (_, b) => k(b));
}
```

※ `(_, b)` の `_` は使わない引数であることを示すスタイルに従ったものです。JavaScript ではただそういう名前というだけですが、言語によっては仕様で決められているものもあります。

内部関数 `f` は、直接スタイルでは値を 2 つ戻すため配列を返しますが、継続渡しスタイルでは継続を 2 引数の関数としています。ただしそれは内部的な扱いで、外部から受け取る継続は 1 引数です。
