---
coediting: false
comments_count: 0
created_at: '2023-02-22T20:19:40+09:00'
id: a44c5257f04f0c641ef0
likes_count: 3
private: false
reactions_count: 0
stocks_count: 1
tags:
- name: JavaScript
  versions: []
- name: Scheme
  versions: []
- name: 継続
  versions: []
title: call/cc でジェネレーターを実装する
updated_at: '2023-03-15T05:15:53+09:00'
url: https://qiita.com/7shi/items/a44c5257f04f0c641ef0
slide: false
---

Scheme で `call/cc` を使ってジェネレーターを実装します。JavaScript を再現する方針で進めます。

実例を示すことに主眼があるため継続の概念については掘り下げませんが、この記事に必要となる範囲内で説明します。

シリーズの記事です。

1. call/cc でジェネレーターを実装する ← この記事
2. [限定継続でジェネレーターを実装する](https://qiita.com/7shi/items/6db3e19ddc1f8552d9a0)

関連記事として、JavaScript で継続モナドによって `call/cc` とジェネレーターを実装します。

* [CPS 変換から継続モナドへ](https://qiita.com/7shi/items/27b6f3169961299a6195)

# 例

まず例として、簡単な関数を書き換えます。

ゼロかどうかを判定する関数です。

```js:JavaScript
function f(x) {
  return x == 0 ? "zero" : "non-zero";
}
```
```scheme:Scheme
(define (f x)
  (if (zero? x) "zero" "non-zero")
)
```

Scheme では関数の最後に評価した値が戻り値となります。

## 脱出

分岐の中で早期 return します。

```js:JavaScript
function f(x) {
  if (x == 0) return "zero";
  return "non-zero";
}
```

これを Scheme で再現するには `call/cc` を使います。`call/cc` は `call-with-current-continuation` の省略形です。`call/cc` に 1 引数の関数を渡せば、現在の継続（CC: Current Continuation）を引数として関数が呼ばれます（call）。現在の継続とは「`call/cc` から戻った後の続き」というニュアンスで、関数内で継続を呼び出すと関数から即座に抜けて、継続への引数が `call/cc` の戻り値となります。

`call/cc` に渡す 1 引数の関数はラムダ式としてその場で定義するパターンが多いです。目的の処理を `call/cc` とラムダ式で包むことで、処理から抜けるという動作を追加することができます。

```scheme:Scheme
(define (f x) (call/cc (lambda (return)
  (if (zero? x) (return "zero"))
  (return "non-zero")
)))
```

この例では `call/cc` とラムダ式で関数本体を包むことで継続を取り出しています。継続を呼び出すことで関数から抜けて、継続への引数が `call/cc` の戻り値となることから、`return` が再現できます。

継続には他にも考慮すべき性質がありますが、必要なものは後ほど説明します。

※1. ラムダ式が通常通り終了した場合の戻り値も `call/cc` の戻り値となるため、3 行目は `return` を使わなくても同じ動作となります。

```scheme:Scheme
(define (f x) (call/cc (lambda (return)
  (if (zero? x) (return "zero"))
  "non-zero"
)))
```

※2. 継続を引数として明示的に受け取ることを継続渡しスタイルと呼びます。

```scheme:Scheme
(define (f x return)
  (if (zero? x) (return "zero"))
  (return "non-zero")
)
```

詳細は以下の記事を参照してください。

https://qiita.com/7shi/items/2d25f7afe25c3ca11acb

# ジェネレーター

JavaScript で簡単なジェネレーターの例を示します。

```js:JavaScript
function* g() {
  yield 1;
  yield 2;
  yield 3;
}
const it = g();
let result = it.next();
console.log(result.value);
result = it.next();
console.log(result.value);
result = it.next();
console.log(result.value);
```
```text:実行結果
1
2
3
```

これを Scheme で再現することを目指します。

## 戻り先

継続は単にラムダ式から抜けるだけではなく、`call/cc` が呼び出されたフローに巻き戻されます。

例えば単純に次のように実装したとします。

【注意】イメージを示す擬似コードのため動きません。

```scheme:Scheme
(define (g) (call/cc (lambda (yield)
  (yield 1)
  (yield 2)
  (yield 3)
)))
(define it (g))
(next it)
(display (value it)) (newline)
(next it)
(display (value it)) (newline)
(next it)
(display (value it)) (newline)
```

このコードには以下の問題点があります。

1. `(define it (g))` から `g` に入って `call/cc` が呼ばれるため、どこから再開されたかに関係なく `yield` の戻り先は常に `(define it (g))` となる。
    * 停止・再開によって戻り先が書き換えられることはない。
2. `yield` で一旦抜けた後、その続き（継続）から再開できるようになっていない。
3. `next` と `value` が定義されていない。

【追記】限定継続を使用すれば 1. の考慮は不要となります。詳細は[続編の記事](https://qiita.com/7shi/items/6db3e19ddc1f8552d9a0)を参照してください。

### 再開元の継続

これを回避するには、再開元で継続を取り出して渡す必要があります。

`(next it)` を `call/cc` とラムダ式で包んで、`next` の引数に継続を追加します。

* <code>(call/cc (lambda (cc-out) <font color="red"><b>(next it cc-out)</b></font>))</code>

### yield 側の継続

`yield` の続きを再開するために、`yield` でも継続を取り出して渡す必要があります。

再開元から渡された継続 `cc-out` の呼び出しを `call/cc` とラムダ式で包みます。継続が取る引数は 1 つだけなので、ジェネレーターが返す値と継続を `cons` でまとめて渡します。

* <code>(call/cc (lambda (cc-in) <font color="red"><b>(cc-out (cons 1 cc-in))</b></font>))</code>

※ ここまで見て来たように、まずやりたい処理を考えて、継続を取り出す必要があれば `call/cc` とラムダ式で包むというのが基本パターンです。

### next/value

ジェネレーターからは値と継続のペアが返されるため、これをイテレーターと見なします。

* `(cons 1 cc-in)`

まずジェネレーターを開始するためのイテレーターを用意します。まだ値は存在しないため null 値 `'()` にしておきます。

* `(define it (cons '() g))`

値は `car`、継続は `cdr` で取得します。これが擬似コードの `value` と `next` に相当します。

## 交互に継続

まとめると、再開元と yield 側とで交互に継続を取り出して渡し合うことになります。

```scheme:Scheme
(define (g cc-out)
  (set! cc-out (call/cc (lambda (cc-in) (cc-out (cons 1 cc-in)))))
  (set! cc-out (call/cc (lambda (cc-in) (cc-out (cons 2 cc-in)))))
  (set! cc-out (call/cc (lambda (cc-in) (cc-out (cons 3 cc-in)))))
)
(define it (cons '() g))
(set! it (call/cc (lambda (cc-out) ((cdr it) cc-out))))
(display (car it)) (newline)
(set! it (call/cc (lambda (cc-out) ((cdr it) cc-out))))
(display (car it)) (newline)
(set! it (call/cc (lambda (cc-out) ((cdr it) cc-out))))
(display (car it)) (newline)
```
```text:実行結果
1
2
3
```

`cc-out` と `it` を毎回書き換えています。

## ポイントフリースタイル

ラムダ式の引数をそのまま関数に適用するだけであれば、それは適用する関数と同じことになります。

* <code><font color="red"><b>(lambda (x) (</b></font>f <font color="red"><b>x))</b></font></code> → `f`

このような変形を[ラムダ計算](https://ja.wikipedia.org/wiki/%E3%83%A9%E3%83%A0%E3%83%80%E8%A8%88%E7%AE%97)ではベータ簡約と呼び、引数を明示的に書かないスタイルをポイントフリースタイルと呼びます。

イテレーターを更新する個所はポイントフリースタイルにできます。

<code>(set! it (call/cc <font color="red"><b>(lambda (cc-out) (</b></font>(cdr it) <font color="red"><b>cc-out))</b></font>))</code>
→ `(set! it (call/cc (cdr it)))`

※ `call/cc` の名前通り、`(cdr it)` に cc を渡して call しています。

## 共通部分の関数化

共通部分を関数化します。

```scheme:Scheme
(define (g cc-out)
  (define (yield x) (set! cc-out (call/cc (lambda (cc-in) (cc-out (cons x cc-in))))))
  (yield 1)
  (yield 2)
  (yield 3)
)
(define (next it) (call/cc (cdr it)))
(define it (cons '() g))
(set! it (next it))
(display (car it)) (newline)
(set! it (next it))
(display (car it)) (newline)
(set! it (next it))
(display (car it)) (newline)
```

まだ作り込みが甘くて問題もありますが、指摘に留めます。

* 用意された以上のデータを要求するとエラーになる。
    * JavaScript の `done` に相当する実装が不足。
* `yield` に値が送れない。
    * JavaScript では　`next` に引数が渡せる。
* ジェネレーターを定義するたびに `yield` を定義するのは面倒。
    * `yield` を共通化する仕組みが必要。

# 継続の位置付け

継続によってジェネレーターが作れることを見て来ました。しかしジェネレーターから継続を作ることはできません。継続の方がよりプリミティブな概念だと考えられます。

Scheme はプリミティブな概念を選択的に言語仕様に取り込んでいると言えます。応用で作れるものはライブラリとして実装できます。

継続の応用はジェネレーターだけではなく、以下にいくつか例が挙げられています。

https://ja.wikibooks.org/wiki/Scheme/%E7%B6%99%E7%B6%9A%E3%81%AE%E7%A8%AE%E9%A1%9E%E3%81%A8%E5%88%A9%E7%94%A8%E4%BE%8B

# ChatGPT

最後のコードを ChatGPT に説明してもらいました。説明とコメントの追加は別々に行いましたが、読みやすいように交互に配置します。

いくつか間違いと思われる個所を修正しましたが、なるべく元の言い回しを残すようにしました。

## 説明

このコードは、Schemeのコントロールフロー機能である「継続」(continuation)を使用して、ジェネレータ関数を実装しています。以下は、コードの動作の概要です。

```scheme
; ジェネレータ関数 g を定義する
(define (g cc-out)
  ; 内部関数 yield を定義する
  (define (yield x)
    ; 呼び出し元に戻るための継続 cc-out に対して値 x と現在の継続 cc-in のペアを返す
    ; 継続 cc-out を、次の呼び出し元から渡される新しい継続に置き換える
    (set! cc-out (call/cc (lambda (cc-in) (cc-out (cons x cc-in))))))
  ; 最初に 1 を yield する
  (yield 1)
  ; 次に 2 を yield する
  (yield 2)
  ; 最後に 3 を yield する
  (yield 3))
```

まず、gという名前のジェネレータ関数が定義されています。この関数は、cc-outという名前の継続を引数に取ります。

gは、内部でyieldという名前のローカル関数を定義します。yieldは、引数として受け取った値と現在の継続cc-inのペアをcc-outという継続に渡し、その後cc-inが呼び出されることを想定します。このようにすることで、yieldが呼び出された時点で実行を中断し、cc-inが呼び出された時に中断した箇所から再開することができます。これにより、gはジェネレータのように振る舞うことができます。

```scheme
; イテレータの次の要素を返す関数を定義する
(define (next it)
  ; (cdr it) に現在の継続を渡して呼び出し、結果が next の戻り値となる
  (call/cc (cdr it)))

; ジェネレータをイテレータに変換する
(define it (cons '() g))
```

gの定義が終わると、nextという名前の関数が定義されます。この関数は、イテレータitを引数として受け取り、次の要素を指すイテレータを返します。

nextは、内部でcall/ccを使用しています。call/ccは、現在の継続を取得することができる関数です。nextはitのcdrに保存されているgの継続に現在の継続を渡して呼び出します。gの継続が呼び出されれば、gの実行が再開されます。

```scheme
; 最初の要素を取得する
(set! it (next it))
(display (car it)) (newline)

; 次の要素を取得する
(set! it (next it))
(display (car it)) (newline)

; 次の要素を取得する
(set! it (next it))
(display (car it)) (newline)
```

gの最初のyieldは1と再開のための継続を返し、それがnextによって返されます。

その後、イテレータitが更新され、再びnextが呼び出されます。これにより、gの次のyieldが実行され、2と継続が返されます。最後に、イテレータitが更新され、もう一度nextが呼び出され、3と継続が返されます。

もし更にnextが呼び出されることがあれば、これ以上要素がないため、エラーが発生します。

nextを呼び出すたびに、displayという関数を使用して、それぞれのyieldによって返された値を表示しています。このコードの実行結果は、以下のようになります。

```text
1
2
3
```
