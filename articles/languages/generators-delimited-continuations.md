---
coediting: false
comments_count: 0
created_at: '2023-02-24T23:27:51+09:00'
id: 6db3e19ddc1f8552d9a0
likes_count: 2
private: false
reactions_count: 0
stocks_count: 3
tags:
- name: Scheme
  versions: []
- name: 限定継続
  versions: []
title: 限定継続でジェネレーターを実装する
updated_at: '2023-03-01T20:52:38+09:00'
url: https://qiita.com/7shi/items/6db3e19ddc1f8552d9a0
slide: false
---

限定継続を使えばジェネレーターが簡単に実装できます。

シリーズの記事です。

1. [call/cc でジェネレーターを実装する](https://qiita.com/7shi/items/a44c5257f04f0c641ef0)
2. 限定継続でジェネレーターを実装する ← この記事

# 限定継続

限定継続は範囲を限定した継続です。

この記事では Scheme 処理系として [GNU Guile](https://www.gnu.org/software/guile/) で動作確認しています。限定継続を扱うにはモジュールを読み込む必要があります。

```scheme
(use-modules (ice-9 control))
```

https://www.gnu.org/software/guile/manual/html_node/Shift-and-Reset.html

簡単な例で継続と挙動を比較します。

## 継続

```scheme
> (* 2 (+ 1 (call/cc (lambda (k) (+ 2 (k 5))))))
12
```

`(k 5)` で `call/cc` から 5 が返され、`(* 2 (+ 1 5))` が計算されて `12` となります。

## 限定継続

限定継続では `reset` で範囲を限定して、その中で `shift` によって継続を取り出します。ラムダ式は不要なため、`shift` だけで `call/cc` とラムダ式に対応します。継続で呼び出した計算は `reset` まで到達すると呼び出し元に返ります。

```Scheme
> (reset (* 2 (+ 1 (shift k (+ 2 (k 5))))))
14
```

`(k 5)` で `shift` から 5 が返され、`(* 2 (+ 1 5))` が計算されて `12` となる所までは同じです。

1 <code>(reset (* 2 (+ 1 (shift k (+ 2 <font color="red"><b>(k 5)</b></font>)))))</code>
2 <code>(reset (* 2 (+ 1 <font color="red"><b>5</b></font>)))</code>
3 <code>(reset (* 2 <font color="red"><b>6</b></font>))</code>
4 <code>(reset <font color="red"><b>12</b></font>)</code>

`12` が `reset` に渡ると `(k 5)` の戻り値となり、計算が続行されます。

※ `call/cc` では飛ばされた `(+ 2 ...)` の計算が行われます。

5 <code>(reset (* 2 (+ 1 (shift k (+ 2 <font color="red"><b>12</b></font>)))))</code>
6 <code>(reset (* 2 (+ 1 (shift k <font color="red"><b>14</b></font>))))</code>

`14` が `shift` に渡ると `reset` の戻り値となり、計算は完了します。

<!-- ### 解釈

`k` は `shift` の外側を関数化したものだと解釈できます。

<code>(reset <font color="red"><b>(* 2 (+ 1</b></font> (shift k (+ 2 (<font color="red"><b>k</b></font> 5)))<font color="red"><b>))</b></font>)</code>
→ <code>(define (<font color="red"><b>k</b></font> x) <font color="red"><b>(* 2 (+ 1</b></font> x<font color="red"><b>))</b></font>) (+ 2 (<font color="red"><b>k</b></font> 5))</code> -->

## 説明の引用

ここまでの例を踏まえた上で、Wikibooks から説明を引用します。

> shift / reset は部分継続（partial continuation, 限定継続 [delimited continuation](https://en.wikipedia.org/wiki/Delimited_continuation)）を使うための構文である。 call/ccにより渡される継続と異なり、続きの計算全てを表す継続ではなく、resetのある途中位置までの継続を表し、終わりまで達したならば継続の呼び出し元へ返る。呼び出し元へ返るという点では部分継続は普通の関数と同じように扱うことができる。 

https://ja.wikibooks.org/wiki/Scheme/%E7%B6%99%E7%B6%9A%E3%81%AE%E7%A8%AE%E9%A1%9E%E3%81%A8%E5%88%A9%E7%94%A8%E4%BE%8B#shift_/_reset

# ジェネレーター

限定継続は呼び出し元に返るため、ジェネレーターが簡単に実装できます。

```Scheme
(define (yield x) (shift k (cons x k)))
(define (g) (reset
  (yield 1)
  (yield 2)
  (yield 3)
))
(define (next it) ((cdr it)))
(define it (cons '() g))
(set! it (next it))
(display (car it)) (newline)
(set! it (next it))
(display (car it)) (newline)
(set! it (next it))
(display (car it)) (newline)
```
```text:実行結果
1
2
3
```

`shift` に `(cons x k)` が渡ると `reset` から抜けて呼び出し元に返されます。

※ `reset` と `shift` は実行時のフローで関連付けられるため、コード上でネストさせておく必要はありません。

## 比較

[前回の記事](https://qiita.com/7shi/items/a44c5257f04f0c641ef0)での継続による実装では、呼び出し元に戻るため `next` でも継続を取り出して `cc-out` を更新する必要がありました。

```scheme:継続
(define (g cc-out)
  (define (yield x) (set! cc-out (call/cc (lambda (cc-in) (cc-out (cons x cc-in))))))
  (yield 1)
  (yield 2)
  (yield 3)
)
(define (next it) (call/cc (cdr it)))
```

限定継続では呼び出し元に戻ることができるため継続を保存しておく必要がありません。`yield` は外部の変数を参照しないためジェネレーターの外で定義できます。`next` は継続の取り出しが不要なため `(cdr it)` を直接呼び出せば済みます。

```scheme:限定継続
(define (yield x) (shift k (cons x k)))
(define (g) (reset
  (yield 1)
  (yield 2)
  (yield 3)
))
(define (next it) ((cdr it)))
```

このようにジェネレーターは限定継続のシンプルな応用となります。

# 参考

* [Delimited continuation - Wikipedia](https://en.wikipedia.org/wiki/Delimited_continuation)
* 浅井 健一「[shift/reset プログラミング入門](http://pllab.is.ocha.ac.jp/~asai/cw2011tutorial/main-j.pdf)」2011
