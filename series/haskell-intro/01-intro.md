---
coediting: false
comments_count: 3
created_at: '2014-08-20T15:02:12+09:00'
id: 145f1234f8ec2af923ef
likes_count: 1288
private: false
reactions_count: 0
stocks_count: 1236
tags:
- name: Haskell
  versions: []
title: Haskell 超入門
updated_at: '2026-08-08T06:16:40+09:00'
url: https://qiita.com/7shi/items/145f1234f8ec2af923ef
slide: false
---

Haskellで簡単なプログラムを書くのに最低限必要な基礎文法を取り上げます。練習では再帰に慣れることに重点を置きます。再帰によるリスト処理の例として各種ソート（挿入ソート、バブルソート、マージソート、クイックソート）を紹介します。ラムダやモナドなどの発展的な内容には触れませんのでご了承ください。

シリーズの記事です。

1. **Haskell 超入門** ← この記事
1. [Haskell 代数的データ型 超入門](http://qiita.com/7shi/items/1ce76bde464b4a55c143)
1. [Haskell アクション 超入門](http://qiita.com/7shi/items/85afd7bbd5d6c4115ad6)
1. [Haskell ラムダ 超入門](http://qiita.com/7shi/items/1345bf32003faff435cb)
1. [Haskell アクションとラムダ 超入門](http://qiita.com/7shi/items/4a8a2807bb5186576c61)
1. [Haskell IOモナド 超入門](http://qiita.com/7shi/items/d3d3492ddd90d47160f2)
1. [Haskell リストモナド 超入門](http://qiita.com/7shi/items/deb19c4cba933590ffbf)
1. [Haskell Maybeモナド 超入門](http://qiita.com/7shi/items/c7d7eec066af0fe0688d)
1. [Haskell 状態系モナド 超入門](http://qiita.com/7shi/items/2e9bff5d88302de1a9e9)
1. [Haskell モナド変換子 超入門](http://qiita.com/7shi/items/4408b76624067c17e933)
1. [Haskell 例外処理 超入門](http://qiita.com/7shi/items/73e534c47bbebc71b37e)
1. [Haskell 構文解析 超入門](http://qiita.com/7shi/items/b8c741e78a96ea2c10fe)
1. [Haskell 継続モナド 超入門](https://zenn.dev/7shi/articles/20260803-haskell-continuation-monad)
1. [Haskell 型クラス 超入門](https://zenn.dev/7shi/articles/20260805-haskell-type-classes)
1. [Haskell モナドとゆかいな仲間たち](https://zenn.dev/7shi/articles/20260807-haskell-monads-and-friends)
1. [Haskell Freeモナド 超入門](https://zenn.dev/7shi/articles/20260808-haskell-free-monad)
1. 【予定】Haskell Operationalモナド 超入門
1. 【予定】Haskell Effモナド 超入門
1. 【予定】Haskell アロー 超入門

練習の解答例は別記事に掲載します。

* [【解答例】Haskell 超入門](http://qiita.com/7shi/items/0ece8c3394e1328267ed)

~~コードを試す環境としてLeksahをご紹介します。~~（古いため非推奨です）

* ~~[Haskell IDE Leksah 入門](http://qiita.com/7shi/items/d1e5a0c22be6cf61d286)~~

応用編です。実際にプログラムを作ります。

* [Haskellによる8086逆アセンブラ開発入門](http://qiita.com/7shi/items/026839b2bc193dbfb0cb)
* [Haskellによる代数計算入門](http://qiita.com/7shi/items/096396f0007857676515)

番外編です。練習問題はありません。

* [HUnit 超入門](http://qiita.com/7shi/items/9fb326a87de6c3083784)
* [関数合成を機械的に扱う試み](http://qiita.com/7shi/items/f2c1365b792aa6046a49)
* [モナド則がちょっと分かった？](http://qiita.com/7shi/items/547b6137d7a3c482fe68)
* [Stateモナドによるポーランド記法の処理](http://qiita.com/7shi/items/8bed38f45272f194631a)
* [Stateモナドによる逆ポーランド記法の処理](http://qiita.com/7shi/items/0494704d00396687458f)
* [Stateモナドによる中置記法の処理](http://qiita.com/7shi/items/ee5afe4f088f0a1fc8c2)

このシリーズのネタ元にしたりするメモです。

* [Haskellの実験メモ一覧](http://qiita.com/7shi/items/b6cbb7df2dd969c84f49)

この記事にはF#版があります。

* [Haskellで学ぶF#入門](http://qiita.com/7shi/items/1d3750ba17f5a88b8405)

# ハローワールド

```hs:Main.hs
main = do
    print "Hello, World!"
```
```text:実行結果
"Hello, World!"
```

* 関数名 = 処理内容
* `main`には`do`を書きます。

## do

上の例は`do`を付けなくても実行できます。`--`はコメントです。

```hs
main =
    print "Hello, World!" -- OK
```
```text:実行結果
"Hello, World!"
```

`do`がない場合、連続して出力できません。

```hs:NG
main =
    print "Hello,"
    print "World!" -- エラー
```
```text:エラー内容
src/Main.hs:4:5:
    Couldn't match expected type `(a0 -> IO ()) -> [Char] -> t0'
                with actual type `IO ()'
    The function `print' is applied to three arguments,
    but its type `[Char] -> IO ()' has only one
    In the expression: print "Hello," print "World!"
    In an equation for `main': main = print "Hello," print "World!"
```

連続して出力するには`do`が必要です。

```hs
main = do
    print "Hello,"
    print "World!" -- OK
```
```text:実行結果
"Hello,"
"World!"
```

`do`を理解するにはアクションの知識が必要です。詳細は続編で説明するため、現段階では簡単な説明で先送りとします。👉[アクション](https://qiita.com/7shi/items/85afd7bbd5d6c4115ad6#%E3%82%A2%E3%82%AF%E3%82%B7%E3%83%A7%E3%83%B3)

* `main`では何度も文字が出力できるように`do`を付けた方が無難。

# 束縛

Haskellの変数は後で別の値を再代入することができません。そのため代入ではなく**束縛**という用語を使います。

※ 値が変更できないので変数は存在しないという見解もありますが、ここでは変数は必ずしも値が変更できることを意味しないという立場を取ります。（[参考1](https://twitter.com/igrep/status/753946652352708609)、[参考2](https://twitter.com/fumieval/status/754142523094773760)）

# トップレベル変数

他の言語でのグローバル変数に相当します。キーワードなどはなく、簡単な書き方です。

```hs
a = 1
b = 2
c = a + b

main = do
    print c
```
```text:実行結果
3
```

# ローカル変数

2種類の書き方があります。

## where

使用箇所の下で定義します。独特な書き方です。

```hs
main = do
    print c
    where
        a = 1
        b = 2
        c = a + b
```
```text:実行結果
3
```

## let

定義してから使用します。

```hs:doあり
main = do
    let a = 1
        b = 2
        c = a + b
    print c
```
```text:実行結果
3
```

`do`がなければ最後に`in`が必要になります。

```hs:doなし
main =
    let a = 1
        b = 2
        c = a + b in
    print c
```
```text:実行結果
3
```

書き方が複数あると混乱するため、今回はなるべく`let`は避けて`where`を使います。

# 関数

数学の $f(x)=x+1$ や $f(1)$ の括弧がない版だとイメージしてください。C言語の`return`に相当するキーワードは使いません。

※ `return`は存在しますが別の意味です。詳細は続編で説明します。👉[アクション](https://qiita.com/7shi/items/85afd7bbd5d6c4115ad6#return)

```hs
f x = x + 1
a = f 1

main = do
    print a
```
```text:実行結果
2
```

`a`を経由せずに`print`に直接`f 1`を渡すには、括弧で囲みます。

```hs
f x = x + 1

main = do
    print (f 1)
```
```text:実行結果
2
```

## $

閉じ括弧を省略するための`$`という書式があります。`$`から行末までを括弧で囲むのと同じ効果があります。

```hs
main = do
    print (f 1)
    print $ f 1
```

以後、`print`では基本的に`$`を使います。

## 関数の演算子化

2つの引数を取る関数を`` ` ``で囲むと中置演算子として使用できます。

```hs
add x y = x + y

main = do
    print $ add 1 2
    print $ 1 `add` 2
```
```text:実行結果
3
3
```

## 演算子の関数化

さっきの逆です。中置演算子を`()`で囲むと関数として使用できます。

```hs
main = do
    print $ 1 + 2
    print $ (+) 1 2
```
```text:実行結果
3
3
```

# 四則演算

```hs
main = do
    print $ 5 + 2
    print $ 5 - 2
    print $ 5 * 2
    print $ 5 / 2
    print $ div 5 2
    print $ mod 5 2
    print $ 5 `div` 2
    print $ 5 `mod` 2
```
```text:実行結果
7
3
10
2.5
2
1
2
1
```

* `/`による割り算は結果を浮動小数点数で返します。
* 割り算の商は`div`、剰余は`mod`で求めます。

# 命名規則

変数と関数は名前を小文字で始める必要があります。

大文字で始めるとエラーになります。

```hs
A = 1
F x = x + 1
```
```text:エラー内容
src\Main.hs:1:1: Not in scope: data constructor `A'
src\Main.hs:2:1: Not in scope: data constructor `F'
```

※ 他言語ではコーディング規約として扱われる内容ですが、Haskellでは文法的に決められています。

# if - then - else

まず、一行で書いてみます。

```hs
a = 1

main = do
    if a == 1 then print "1" else print "?"
```
```text:実行結果
"1"
```

※ 「等しい」は`==`、「等しくない」は`/=`です。後者は記号≠に由来します。

複数行で書く場合、`if`に対して`then`や`else`がぶら下がっていることを示すため、`then`や`else`のインデントを`if`より右にずらす必要があります。

```hs
a = 1

main = do
    if a == 1
        then print "1"
        else print "?"
```
```text:実行結果
"1"
```

※ `do`がなければ別の書き方ができますが、書き方が複数あると混乱するため説明を省略します。

## 値を返す

`if`は値を返すため、C言語の三項演算子のように使えます。

```hs
a = 1

main = do
    print $ if a == 1 then "1" else "?"
```
```text:実行結果
"1"
```

関数の定義と組み合わせた例です。

```hs
f a = if a == 1 then "1" else "?"

main = do
    print $ f 0
    print $ f 1
```
```text:実行結果
"?"
"1"
```

# パターンマッチ

関数内の全体を`if`で切り分ける代わりに、特定の引数を指定して関数を分割定義できます。このような書き方を**パターンマッチ**と呼びます。

```hs
f 1 = "1"
f a = "?"

main = do
    print $ f 0
    print $ f 1
```
```text:実行結果
"?"
"1"
```

値を無視する引数は`_`と書くことで、値を無視していることを明示します。

```hs
f 1 = "1"
f _ = "?"
```

これは独特な書き方のため、慣れが必要です。

## 階乗

例としてよく引き合いに出されます。

```hs
fact 0 = 1
fact n = n * fact (n - 1)

main = do
    print $ fact 5
```
```text:実行結果
120
```

`fact`の中で`fact`を呼んでいます。このような流れを**再帰**と言います。再帰は往復で処理されるため往路と復路に分けて考えます。

再帰の往路をトレースします。

1. `fact 5 = 5 * fact 4`
1. `fact 4 = 4 * fact 3`
1. `fact 3 = 3 * fact 2`
1. `fact 2 = 2 * fact 1`
1. `fact 1 = 1 * fact 0`
1. `fact 0 = 1`

`fact 0`が折り返し点となり、反転して復路に入ります。

1. `fact 1 = 1 * fact 0 = 1 * 1 = 1`
1. `fact 2 = 2 * fact 1 = 2 * 1 = 2`
1. `fact 3 = 3 * fact 2 = 3 * 2 = 6`
1. `fact 4 = 4 * fact 3 = 4 * 6 = 24`
1. `fact 5 = 5 * fact 4 = 5 * 24 = 120`

※ 往路だけで復路のない末尾再帰もありますが、今回の範囲を超えるため省略します。

### 簡約

往路をインライン展開すると次のように捉えることができます。

1. `fact 5`
1. `5 * fact 4`
1. `5 * 4 * fact 3`
1. `5 * 4 * 3 * fact 2`
1. `5 * 4 * 3 * 2 * fact 1`
1. `5 * 4 * 3 * 2 * 1 * fact 0`
1. `5 * 4 * 3 * 2 * 1 * 1`
1. `120`

このような式変形を**簡約**と呼びます。

### 基底部・再帰部

折り返し点となる定義を基底部、自分自身を呼び出している定義を再帰部と呼びます。

* 基底部: `fact 0 = 1`
* 再帰部: `fact n = n * fact (n - 1)`

## コツ

再帰の取り扱いにはパターンがあります。そこを意識するのがコツです。

### 作り方のコツ

1. 基底部を定義
2. 具体例に当てはめて一般化する

まず基底部を定義します。自然数を指定するタイプでは値が減少しながら再帰を繰り返すのが定石で、これ以上減少できない最小値が基底部となります。

階乗について考えます。マイナスの階乗が定義されていないため、計算可能な最小の階乗は $0!$ です。このことから基底部を定義します。

```hs:基底部
fact 0 = 1
```

再帰部は具体例を通して考えるのがコツです。たとえば5の階乗を考えます。

```math:具体例
5! = 5 \times 4 \times 3 \times 2 \times 1
```

再帰は引数を5から0に向かって減少させて処理します。1つ小さい引数（この場合は4）の結果を利用するのが定石です。このパターンで表すため、5の階乗を4の階乗で表せないか考えます。

```math:式変形
5! = 5 \times (4 \times 3 \times 2 \times 1) = 5 \times 4!
```

特定の数（この場合は5）での関係が得られました。これを一般化して5を$n$に置き換えます。4は$n-1$です。このように隣接する項目との関係で表された式を[漸化式](http://ja.wikipedia.org/wiki/%E6%BC%B8%E5%8C%96%E5%BC%8F)と呼びます。

```math:漸化式
n! = n \times (n-1)!
```

漸化式をコード化すれば再帰部が得られます。

```hs:再帰部
fact n = n * fact (n - 1)
```

このように基底部と再帰部は順を追って別々に作ることになるため、パターンマッチで定義を分離させる書き方と相性が良いです。

※ 数学の問題であれば得られた式を[数学的帰納法](http://ja.wikipedia.org/wiki/%E6%95%B0%E5%AD%A6%E7%9A%84%E5%B8%B0%E7%B4%8D%E6%B3%95)で証明することが求められますが、今回はプログラミングの練習が目的なので、いくつか具体例で動作確認して済ませます。

### 確認のコツ

一旦書き上げたプログラムを確認するコツです。既存のコードを読むときにも使えます。

再帰の流れは追わずに、結果が信頼できるものと見なして具体例で考えます。

```hs
fact n = n * fact (n - 1)
```

1. `fact 5 = 5 * fact 4`
2. `fact 4`は定義より`4! = 24`が返されると考えます。
3. `5 * 24 = 120`

次に再帰を使った練習問題をやるので、この方法を試してみてください。

## 練習

フィボナッチ数は`0, 1`が初期値として与えられ、それ以降は前2つの数字を合計して得られる数列です。

* 0, 1, 1, 2, 3, 5, 8, 13, 21, ...

【問1】任意のn番目のフィボナッチ数を計算する関数`fib`をパターンマッチで実装してください。最初の0は0番目とします。

ヒント: 基底部は1つとは限りません。

⇒ [解答例](http://qiita.com/7shi/items/0ece8c3394e1328267ed#%E3%83%91%E3%82%BF%E3%83%BC%E3%83%B3%E3%83%9E%E3%83%83%E3%83%81)

# ガード

1つの関数定義に引数の条件を列挙するガードという書き方があります。

```hs
fact n
    | n == 0    = 1
    | otherwise = n * fact (n - 1)

main = do
    print $ fact 5
```
```text:実行結果
120
```

こちらも独特な書き方のため、慣れが必要です。

## = の位置

引数の直後に`=`を書かないのは混乱を招くかもしれませんが、その間に条件が割り込んでいるためです。

一行で書いたものを対比してみます。

```hs
fact n          = 1
fact n | n == 0 = 1
       ^^^^^^^^
```

## 練習

【問2】問1で実装した関数をガードで書き直してください。

⇒ [解答例](http://qiita.com/7shi/items/0ece8c3394e1328267ed#%E3%82%AC%E3%83%BC%E3%83%89)

# 使い分け

慣習的にパターンマッチとガードは使い分けがされています。厳密に決まっているわけではありませんが、目安を示します。

1. まずパターンマッチで書けないか試します。
2. 範囲指定（例: `n < 5`）など式が必要でパターンマッチが使えない場合、ガードを使います。
3. パターンマッチで大まかに振り分けた後、ガードで細かく振り分けるというように、併用するケースもあります。

C言語などをご存知の方はおおまかに次のように考えるとイメージしやすいかもしれません。

* パターンマッチは `switch` - `case` の機能強化版
* ガードは `if` - `else if` の羅列

## 併用

上で実装した`fact`に負の数を渡すと無限ループになります。対策としてパターンマッチとガードを併用して引数を制限します。

```hs
fact 0 = 1
fact n | n > 0 = n * fact (n - 1)

main = do
    print $ fact (-1)
```
```text:実行結果（エラー）
Main.hs:(1,1)-(2,33): Non-exhaustive patterns in function fact
```

パターンマッチがガードで制限されるため、`(-1)`はどのパターンにもマッチせずにエラーとなります。

※ Erlangという言語では、このようなスタイルを非防御的プログラミング（non-defensive programming）と呼ぶそうです。

* 出典: [オープンソースアプリケーションのアーキテクチャ 15.1](https://github.com/m-takagi/aosa-ja)

エラーが起きないように処理する方法については、続編で説明します。👉[Maybeモナド](https://qiita.com/7shi/items/c7d7eec066af0fe0688d#guard)

# case - of

関数の中でパターンマッチを行います。`=`ではなく`->`を使います。

```hs
fact n = case n of
    0 -> 1
    _ | n > 0 -> n * fact (n - 1)

main = do
    print $ fact 5
```
```text:実行結果
120
```

※ 引数で`n`として受けているため、`case`中のパターンマッチでは`_`として受け流しています。

大抵は関数レベルのパターンマッチとガードで済んでしまうため、使用頻度はそれほど高くありません。

## 練習

【問3】問1で実装した関数を`case`-`of`で書き直してください。無限ループを防ぐためガードを追加してください。

⇒ [解答例](http://qiita.com/7shi/items/0ece8c3394e1328267ed#case---of)

# リスト

他言語の配列と似たようなものです。

```hs
main = do
    print [1, 2, 3, 4, 5]
```
```text:実行結果
[1,2,3,4,5]
```

※ Haskellではリストとは別に配列もあります。詳細は続編で説明します。👉[アクション](https://qiita.com/7shi/items/85afd7bbd5d6c4115ad6#iouarray)

## !!

リストから要素を取り出すには`!!`を使います。先頭の要素は0番目です。

```hs
main = do
    print $ [1, 2, 3, 4, 5] !! 3
```
```text:実行結果
4
```

## 連番

連番リストを生成する専用の書き方があります。

```hs
main = do
    print [1..5]
```
```text:実行結果
[1,2,3,4,5]
```

## ++

`++`によりリスト同士を結合できます。

```hs
main = do
    print $ [1, 2, 3] ++ [4, 5]
```
```text:実行結果
[1,2,3,4,5]
```

## :

`:`によりリストの先頭に要素を挿入できます。

```hs
main = do
    print $ 1:[2..5]
```
```text:実行結果
[1,2,3,4,5]
```

複数の先頭要素を連ねることもできます。

```hs
main = do
    print $ 1:2:[3..5]
```
```text:実行結果
[1,2,3,4,5]
```

`:`では末尾に追加できないため`++`を使用します。

```hs
main = do
    print $ [1..4] ++ [5]
```
```text:実行結果
[1,2,3,4,5]
```

## 文字列

文字列は文字のリストとして扱われます。

```hs
main = do
    print $ "abcde"
    print $ ['a', 'b', 'c', 'd', 'e']
    print $ ['a'..'e']
    print $ 'a':"bcde"
    print $ 'a':'b':"cde"
    print $ "abc" ++ "de"
    print $ "abcde" !! 3
```
```text:実行結果
"abcde"
"abcde"
"abcde"
"abcde"
"abcde"
"abcde"
'd'
```

## 引数

引数でリストの先頭要素を取り出せます。

```hs
first (x:xs) = x

main = do
    print $ first [1..5]
    print $ first "abcdef"
```
```text:実行結果
1
'a'
```

`(x:xs)`で先頭`x`とその後ろのリスト`xs`に分割して受け取ります。`xs`は`x`の複数形を意図しています。これらの名前には文法的な意味はなく、あくまで慣習です。

この例では`xs`を使っていないため`_`で未使用を明示した方が無難です。

```hs
first (x:_) = x
```

先頭要素は複数を連ねることもできます。

```hs
second (_:x:_) = x

main = do
    print $ second [1..5]
    print $ second "abcdef"
```
```text:実行結果
2
'b'
```

# リスト関係の関数

## length

リストの要素数を取得します。

```hs
main = do
    print $ length [1, 2, 3]
```
```text:実行結果
3
```

## sum

リストの要素をすべて足します。

```hs
main = do
    print $ sum [1..5]
```
```text:実行結果
15
```

## product

`sum`が足し算なら、`product`は掛け算です。

```hs
main = do
    print $ product [1..5]
```
```text:実行結果
120
```

## take

リストから先頭のn個を抽出します。

```hs
main = do
    print $ take 2 [1, 2, 3]
```
```text:実行結果
[1,2]
```

## drop

リストから先頭のn個を落とします。

```hs
main = do
    print $ drop 2 [1, 2, 3]
```
```text:実行結果
[3]
```

## reverse

リストの要素を逆に並べます。

```hs
main = do
    print $ reverse [1..5]
```
```text:実行結果
[5,4,3,2,1]
```

## 練習

`length`と同じ機能の関数`length'`を再実装する例です。

※ 関数名の`'`（ダッシュまたはプライム）は名前の一部で、数学の`a`に対する`a'`の感覚です。

```hs
length' []     = 0
length' (_:xs) = 1 + length' xs

main = do
    print $ length' [1, 2, 3]
```
```text:実行結果
3
```

【問4】`sum`, `product`, `take`, `drop`, `reverse`と同じ機能の関数を再実装してください。関数名には`'`を付けてください。

ヒント: リストを再帰で処理するパターンは`f (x:xs) = x ... f xs`です。

⇒ [解答例](http://qiita.com/7shi/items/0ece8c3394e1328267ed#%E5%86%8D%E5%AE%9F%E8%A3%85)

【問5】`product`を使って`fact`（階乗）を実装してください。

⇒ [解答例](http://qiita.com/7shi/items/0ece8c3394e1328267ed#%E9%9A%8E%E4%B9%97)

# タプル

関数で複数の値を返すことができます。括弧で複数の値を囲んだ部分を**タプル**と呼びます。

```hs
addsub x y = (x + y, x - y)

main = do
    print $ addsub 1 2
```
```text:実行結果
(3,-1)
```

タプルは全体でも分割でも受け取れます。

```hs
addsub x y = (x + y, x - y)
a = addsub 1 2
(a1, a2) = addsub 1 2

main = do
    print a
    print a1
    print a2
```
```text:実行結果
(3,-1)
3
-1
```

数学の座標をイメージすると良いでしょう。

* $P=(1,2)$
* $(x,y)=(1,2)$ ⇔ $x=1,y=2$

## リストとの比較

* リストの項目数は任意ですが、タプルでは固定です。
* リストの要素はすべて同じ型でないといけませんが、タプルでは任意です。
    * × `[1, "a"]`
    * ○ `(1, "a")`

## 関数

要素が2つのタプルから値を取り出す関数`fst`, `snd`があります。

```hs
main = do
    let p2 = (1, 2)
    print $ fst p2
    print $ snd p2
```
```text:実行結果
1
2
```

要素が3つ以上のタプルからは変数経由で値を取り出します。

```hs
main = do
    let p3 = (1, 2, 3)
    print p3
    let (_, _, p3z) = p3
    print p3z
```
```text:実行結果
(1,2,3)
3
```

※ リストのように`!!`で値を取り出すことはできません。

## 練習

【問6】点 $(p, q)$ から直線 $ax + by = c$ に下した垂線の交点を求める関数`perpPoint`を作成してください。aとbが両方ゼロになると解なしですが、チェックせずに無視してください。

ヒント: $ax + by = c$ の傾きは $-\frac{a}{b}$ です。直交する直線の傾きとの積が $-1$ となることから、垂線は $bx - ay = d$ と表せます。連立方程式を解けば交点が求まります。

⇒ [解答例](http://qiita.com/7shi/items/0ece8c3394e1328267ed#%E5%9E%82%E7%B7%9A%E3%81%AE%E4%BA%A4%E7%82%B9)

# import

ライブラリを読み込みます。

`Data.Char`（[リファレンス](https://hackage.haskell.org/package/base-4.7.0.0/docs/Data-Char.html)）で定義されている関数を使う例です。

* `ord`: 文字から文字コードを取得
* `chr`: 文字コードから文字に変換

```hs
import Data.Char

main = do
    print $ ord 'A'
    print $ chr 65
```
```text:実行結果
65
'A'
```

## 練習

【問7】[ROT13](http://ja.wikipedia.org/wiki/ROT13)を実装してください。

⇒ [解答例](http://qiita.com/7shi/items/0ece8c3394e1328267ed#rot13)

# ソート

挿入ソートの実装例を示します。

```hs
insert x [] = [x]
insert x (y:ys)
    | x < y     = x:y:ys
    | otherwise = y : insert x ys

isort []     = []
isort (x:xs) = insert x (isort xs)

main = do
    print $ isort [4, 6, 9, 8, 3, 5, 1, 7, 2]
```
```text:実行結果
[1,2,3,4,5,6,7,8,9]
```

処理の流れを説明します。

```hs
isort []     = []
isort (x:xs) = insert x (isort xs)
```

リストの先頭の要素を取り出しながら再帰することで、リストの要素を順番に挿入して行きます。

リスト`[4, 6, 9, 8, 3, 5, 1, 7, 2]`の往路をトレースします。

1. `isort [4, 6, 9, 8, 3, 5, 1, 7, 2] = insert 4 (isort [6, 9, 8, 3, 5, 1, 7, 2])`
1. `isort [6, 9, 8, 3, 5, 1, 7, 2] = insert 6 (isort [9, 8, 3, 5, 1, 7, 2])`
1. `isort [9, 8, 3, 5, 1, 7, 2] = insert 9 (isort [8, 3, 5, 1, 7, 2])`
1. `isort [8, 3, 5, 1, 7, 2] = insert 8 (isort [3, 5, 1, 7, 2])`
1. `isort [3, 5, 1, 7, 2] = insert 3 (isort [5, 1, 7, 2])`
1. `isort [5, 1, 7, 2] = insert 5 (isort [1, 7, 2])`
1. `isort [1, 7, 2] = insert 1 (isort [7, 2])`
1. `isort [7, 2] = insert 7 (isort [2])`
1. `isort [2] = insert 2 (isort [])`
1. `isort [] = []`

`insert`の第2引数は必ず`isort`でソートされたリストが渡されます。

挿入先のリストはソート済みであることを前提にできるため、挿入箇所の判定は後続要素との比較だけで済みます。

再帰により挿入先のリストの要素と順番に比較していきます。末尾に達すると`ys = []`となるため、そこに挿入します。

```hs
insert x [] = [x]
insert x (y:ys)
    | x < y     = x:y:ys
    | otherwise = y : insert x ys
```

例を示します。

1. `insert 3 [1, 2, 5, 7]` 次へ
1. `1: insert 3 [2, 5, 7]` 次へ
1. `1: 2: insert 3 [5, 7]` ここへ挿入
1. `1: 2: 3: [5, 7]`
1. `[1, 2, 3, 5, 7]`

復路をトレースします。

1. `isort [2] = insert 2 []`
1. `isort [7, 2] = insert 7 [2]`
1. `isort [1, 7, 2] = insert 1 [2, 7]`
1. `isort [5, 1, 7, 2] = insert 5 [1, 2, 7]`
1. `isort [3, 5, 1, 7, 2] = insert 3 [1, 2, 5, 7]`
1. `isort [8, 3, 5, 1, 7, 2] = insert 8 [1, 2, 3, 5, 7]`
1. `isort [9, 8, 3, 5, 1, 7, 2] = insert 9 [1, 2, 3, 5, 7, 8]`
1. `isort [6, 9, 8, 3, 5, 1, 7, 2] = insert 6 [1, 2, 3, 5, 7, 8, 9]`
1. `isort [4, 6, 9, 8, 3, 5, 1, 7, 2] = insert 4 [1, 2, 3, 5, 6, 7, 8, 9]`
1. `[1, 2, 3, 4, 5, 6, 7, 8, 9]`

このように要素を1つずつソートされたリストに挿入しています。

## 確認のコツ

再帰の確認のコツを説明しましたが、挿入ソートに適用してみます。具体例を使って、結果が信頼できるものと見なします。

```hs
isort (x:xs) = insert x (isort xs)
```

1. `isort [3, 5, 1, 7, 2] = insert 3 (isort [5, 1, 7, 2])`
2. `isort [5, 1, 7, 2]`は定義よりソート済みの`[1, 2, 5, 7]`が返されると考えます。
3. `insert 3 [1, 2, 5, 7] = [1, 2, 3, 5, 7]`

## デバッグ

`Debug.Trace.trace`を使えば途中経過を表示できます。

```hs:使い方
trace 表示する文字列 戻り値
```

簡単な例を示します。

```hs
import Debug.Trace

test x = trace ("test " ++ show x) x

main = do
    traceIO $ show $ test 5
```
```text:実行結果
test 5
5
```

* `show`は様々な型を文字列に変換する関数です。
* Leksahでは標準出力と標準エラー出力が混ざると表示がおかしくなるため、`print`ではなく`traceIO`を使っています。
* `traceIO`は文字列しか受け付けないため、`show`で変換しています。

挿入ソートをトレースしてみます。

```hs
import Debug.Trace

insert x [] = [x]
insert x (y:ys)
    | x < y     = x:y:ys
    | otherwise = y : insert x ys

isort []     = []
isort (x:xs) = trace dbg1 $ trace dbg2 ret
    where
        ret = insert x xs'
        xs' = isort xs
        dbg1 = "isort " ++ show (x:xs) ++ " = " ++
               "insert " ++ show x ++
               " (isort " ++ show xs ++ ")"
        dbg2 = "insert " ++ show x ++ " " ++ show xs' ++
               " = " ++ show ret

main = do
    traceIO $ show $ isort [4, 6, 9, 8, 3, 5, 1, 7, 2]
```
```text:実行結果
isort [4,6,9,8,3,5,1,7,2] = insert 4 (isort [6,9,8,3,5,1,7,2])
isort [6,9,8,3,5,1,7,2] = insert 6 (isort [9,8,3,5,1,7,2])
isort [9,8,3,5,1,7,2] = insert 9 (isort [8,3,5,1,7,2])
isort [8,3,5,1,7,2] = insert 8 (isort [3,5,1,7,2])
isort [3,5,1,7,2] = insert 3 (isort [5,1,7,2])
isort [5,1,7,2] = insert 5 (isort [1,7,2])
isort [1,7,2] = insert 1 (isort [7,2])
isort [7,2] = insert 7 (isort [2])
isort [2] = insert 2 (isort [])
insert 2 [] = [2]
insert 7 [2] = [2,7]
insert 1 [2,7] = [1,2,7]
insert 5 [1,2,7] = [1,2,5,7]
insert 3 [1,2,5,7] = [1,2,3,5,7]
insert 8 [1,2,3,5,7] = [1,2,3,5,7,8]
insert 9 [1,2,3,5,7,8] = [1,2,3,5,7,8,9]
insert 6 [1,2,3,5,7,8,9] = [1,2,3,5,6,7,8,9]
insert 4 [1,2,3,5,6,7,8,9] = [1,2,3,4,5,6,7,8,9]
[1,2,3,4,5,6,7,8,9]
```

`trace`を2回使うことで、往路と復路が確認できるように表示しています。

## 練習

【問8】[バブルソート](http://www.ics.kagoshima-u.ac.jp/~fuchida/edu/algorithm/sort-algorithm/bubble-sort.html)を実装してください。

ヒント: 交換する関数とソートする関数を分離して実装します。

⇒ [詳細説明](http://qiita.com/7shi/items/1e2a66bf8e8c7f0bd70f), [解答例](http://qiita.com/7shi/items/0ece8c3394e1328267ed#%E3%83%90%E3%83%96%E3%83%AB%E3%82%BD%E3%83%BC%E3%83%88)

【問9】[マージソート](http://www.ics.kagoshima-u.ac.jp/~fuchida/edu/algorithm/sort-algorithm/merge-sort.html)を実装してください。

⇒ [解答例](http://qiita.com/7shi/items/0ece8c3394e1328267ed#%E3%83%9E%E3%83%BC%E3%82%B8%E3%82%BD%E3%83%BC%E3%83%88)

# リスト内包表記

リストの要素すべてに同じ処理を施した別のリストを作成します。

```hs
fact 0 = 1
fact n | n > 0 = n * fact (n - 1)

main = do
    print [1, 2, 3, 4, 5]
    print [fact 1, fact 2, fact 3, fact 4, fact 5]
    print [fact x | x <- [1..5]]
```
```text:実行結果
[1,2,3,4,5]
[1,2,6,24,120]
[1,2,6,24,120]
```

`[1..5]`の要素を1つずつ`x`として取り出して、`fact x`として処理したリストを作成しています。

※ 同じことができる`map`という関数もあります。詳細は続編で説明します。👉[ラムダ](https://qiita.com/7shi/items/1345bf32003faff435cb#map)

## 条件

要素を取り出す際に条件を指定できます。

```hs
main = do
    print [x | x <- [1..9], x < 5]
```
```text:実行結果
[1,2,3,4]
```

`[1..9]`のうち`x < 5`を満たすものだけでリストを作成しています。

※ 同じことができる`filter`という関数もあります。詳細は続編で説明します。👉[ラムダ](https://qiita.com/7shi/items/1345bf32003faff435cb#filter)

### 練習

Haskellの特徴を示す例として、クイックソートがよく引き合いに出されます。

```hs
qsort []     = []
qsort (n:xs) = qsort lt ++ [n] ++ qsort gteq
    where
        lt   = [x | x <- xs, x <  n]
        gteq = [x | x <- xs, x >= n]

main = do
    print $ qsort [4, 6, 9, 8, 3, 5, 1, 7, 2]
```
```text:実行結果
[1,2,3,4,5,6,7,8,9]
```

【問10】処理の流れを説明してください。

⇒ [解答例](http://qiita.com/7shi/items/0ece8c3394e1328267ed#%E3%82%AF%E3%82%A4%E3%83%83%E3%82%AF%E3%82%BD%E3%83%BC%E3%83%88)

## 組み合わせ

複数のリストから値を取り出すこともできます。多重ループのようにすべての組み合わせが得られます。

```hs
main = do
    print [(x, y) | x <- [1..3], y <- "abc"]
```
```text:実行結果
[(1,'a'),(1,'b'),(1,'c'),(2,'a'),(2,'b'),(2,'c'),(3,'a'),(3,'b'),(3,'c')]
```

### 練習

【問11】三辺の長さが各20以下の整数で構成される直角三角形を列挙してください。並び順による重複を排除する必要はありません。

ヒント: 直角三角形の成立条件は三平方（ピタゴラス）の定理です。

⇒ [解答例](http://qiita.com/7shi/items/0ece8c3394e1328267ed#%E7%9B%B4%E8%A7%92%E4%B8%89%E8%A7%92%E5%BD%A2%E3%81%AE%E4%B8%89%E8%BE%BA)
