---
coediting: false
comments_count: 0
created_at: '2017-01-11T18:42:47+09:00'
id: 1d3750ba17f5a88b8405
likes_count: 37
private: false
reactions_count: 0
stocks_count: 28
tags:
- name: Haskell
  versions: []
- name: F#
  versions: []
title: Haskellで学ぶF#入門
updated_at: '2020-06-26T14:54:44+09:00'
url: https://qiita.com/7shi/items/1d3750ba17f5a88b8405
slide: false
---

Haskellと比較しながらF#を説明します。練習では再帰に慣れることに重点を置きます。再帰によるリスト処理の例として各種ソート（挿入ソート、バブルソート、マージソート、クイックソート）を紹介します。

※ 一応、Haskellは飛ばしてF#だけでも読めるようには配慮したつもりです。Haskellがよく分からなければ飛ばして読んでみてください。

この記事はHaskellの記事をベースにしています。

* [Haskell 超入門](http://qiita.com/7shi/items/145f1234f8ec2af923ef) 2014.08.20

練習の解答例は別記事に掲載します。

* [【解答例】Haskellで学ぶF#入門](http://qiita.com/7shi/items/b174d1c50aab9350dafc)

この記事には姉妹編があります。

* [C#/JavaScriptで学ぶF#入門](http://qiita.com/7shi/items/ff746903680ae8d0d7ce) 2017.01.04

この記事には関連記事があります。

* [doブロックとコンピュテーション式](http://qiita.com/7shi/items/92139286a4e9b5620d69) 2016.07.01
* [functionのインデント](http://qiita.com/7shi/items/7f490819e818dd7aa37c) 2016.12.14

F#を手っ取り早く試すために、私が常用している環境を紹介します。

* [F#開発環境の紹介](http://qiita.com/7shi/items/5fc7d6477d96bbd7a71d) 2016.12.30

# ハローワールド

<blockquote><table><tr><th>Haskell</th><th>F#</th></tr><tr><td><pre>
main = do
    putStrLn "Hello, World!"
</pre></td><td><pre>
printfn "Hello, World!"
</pre></td></tr><tr><td>実行結果<pre>
Hello, World!
</pre></td><td>実行結果<pre>
Hello, World!
</pre></td></tr></table></blockquote>

## エントリーポイント

F#は処理をいきなり書き始めることができるため、`main`は必須ではありません。もし必要であれば`[<EntryPoint>]`属性を添えて関数を書きます。関数名は任意で`main`でなくても構いませんが、引数と戻り値は必須です。C言語と比較します。

<blockquote><table><tr><th>C言語</th><th>F#</th></tr><tr><td><pre>
#include &lt;stdio.h>

int main(int argc, char *argv[]) {
    printf("Hello, World!\n");
    return 0;
}
</pre></td><td><pre>
[&lt;EntryPoint>]
let main args =
    printfn "Hello, World!"
    0
</pre></td></tr><tr><td>実行結果<pre>
Hello, World!
</pre></td><td>実行結果<pre>
Hello, World!
</pre></td></tr></table></blockquote>

F#は`[<EntryPoint>]`に`do`ブロックを組み合わせることで、引数や戻り値が省略可能です。

```fsharp:F#
[<EntryPoint>]
do
    printfn "Hello, World!"
```
```text:実行結果
Hello, World!
```

簡単のため、以後の例ではエントリーポイントなしで処理を書きます。

## do

Haskellは`do`ブロック内では文法が変わりますが、F#の`do`ではそういったことはありません。F#の`do`はC言語などの`{}`と同じようにブロックを表します。

F#でHaskellの`do`ブロックに相当するのはコンピュテーション式です。詳細は次の記事を参照してください。

* [doブロックとコンピュテーション式](http://qiita.com/7shi/items/92139286a4e9b5620d69) 2016.07.01

Haskellでは連続出力に`do`が必須ですが、F#ではそういった制約はありません。

<blockquote><table><tr><th>Haskell</th><th>F#</th></tr><tr><td><pre>
main = do
    putStrLn "Hello, World!"
    putStrLn "Hello, World!"
</pre></td><td><pre>
printfn "Hello, World!"
printfn "Hello, World!"
</pre></td></tr><tr><td>実行結果<pre>
Hello, World!
Hello, World!
</pre></td><td>実行結果<pre>
Hello, World!
Hello, World!
</pre></td></tr></table></blockquote>

## printf

Haskellの`print`はShowのインスタンスを受け付けます。F#ではフォーマットに`%A`を指定すれば任意の型を受け付けます。

<blockquote><table><tr><th>Haskell</th><th>F#</th></tr><tr><td><pre>
main = do
    print 1
    print "abc"
</pre></td><td><pre>
printfn "%A" 1
printfn "%A" "abc"
</pre></td></tr><tr><td>実行結果<pre>
1
"abc"
</pre></td><td>実行結果<pre>
1
"abc"
</pre></td></tr></table></blockquote>

F#では`%d`などの型に紐付けられたフォーマットを指定すればコンパイラで型がチェックされるため、フォーマットでサポートされている型は個別に指定した方が無難です。

# 束縛

F#の変数（識別子）は後で別の値を再代入することができません。そのため代入ではなく**束縛**という用語を使います。

## let

F#ではトップレベルやローカルの区別なく、束縛には常に`let`が必要です。

※ Haskellの`where`に相当するキーワードはありません。

<blockquote><table><tr><th>Haskell</th><th>F#</th></tr><tr><td><pre>
a = 1
b = 2

main = do
    let c = a + b
    print c
</pre></td><td><pre>
let a = 1
let b = 2

do
    let c = a + b
    printfn "%d" c
</pre></td></tr><tr><td>実行結果<pre>
3
</pre></td><td>実行結果<pre>
3
</pre></td></tr></table></blockquote>

# 関数

数学の $f(x)=x+1$ や $f(1)$ の括弧がない版だとイメージしてください。C言語の`return`に相当するキーワードは使いません。

※ `return`は存在しますが別の意味です。詳細は[doブロックとコンピュテーション式](http://qiita.com/7shi/items/92139286a4e9b5620d69)を参照してください。

<blockquote><table><tr><th>Haskell</th><th>F#</th></tr><tr><td><pre>
f x = x + 1
a = f 1

main = do
    print a
</pre></td><td><pre>
let f x = x + 1
let a = f 1

printfn "%d" a
</pre></td></tr><tr><td>実行結果<pre>
2
</pre></td><td>実行結果<pre>
2
</pre></td></tr></table></blockquote>

`a`を経由せずに`printfn`に直接`f 1`を渡すには、括弧で囲みます。

<blockquote><table><tr><th>Haskell</th><th>F#</th></tr><tr><td><pre>
f x = x + 1

main = do
    print (f 1)
</pre></td><td><pre>
let f x = x + 1

printfn "%d" (f 1)
</pre></td></tr><tr><td>実行結果<pre>
2
</pre></td><td>実行結果<pre>
2
</pre></td></tr></table></blockquote>

## パイプライン演算子

閉じ括弧の省略にはパイプライン演算子`<|`が使えます。

<blockquote><table><tr><th>Haskell</th><th>F#</th></tr><tr><td><pre>
main = do
    print (f 1)
    print $ f 1
</pre></td><td><pre>
printfn "%d" (f 1)
printfn "%d" &lt;| f 1
</pre></td></tr></table></blockquote>

連続で使用した場合、`<|`はHaskellの`$`とは挙動が異なるので注意が必要です。F#でHaskellの挙動を真似するには`<<`による関数合成と併用する必要があります。対応を示します。

<blockquote><table><tr><th>Haskell</th><th>F#</th></tr><tr><td><pre>
main = do
    print $ abs $ 3 - 5
    let a = atan2 (sqrt 2) (sqrt 3)
    print a
</pre></td><td><pre>
printfn "%d" &lt;&lt; abs &lt;| 3 - 5
let a = atan2 &lt;| sqrt 2. &lt;| sqrt 3.
printfn "%f" a
</pre></td></tr><tr><td>実行結果<pre>
2
0.684719203002283
</pre></td><td>実行結果<pre>
2
0.684719
</pre></td></tr></table></blockquote>

逆向きの `|>` もあります。連続して使用すれば、関数の多重ネストをシェルのパイプのように記述できます。

```fsharp:F#
printfn "%d" (abs (3 - 5))
3 - 5 |> abs |> printfn "%d"
```
```text:実行結果
2
2
```

## 関数の演算子化

F#ではHaskellのように関数を演算子として使うことはできません。

```hs:Haskell
add x y = x + y

main = do
    print $ add 1 2
    print $ 1 `add` 2  -- 関数の演算子化
```
```text:実行結果
3
3
```

## 演算子の関数化

中置演算子を`()`で囲むと関数として使用できます。

<blockquote><table><tr><th>Haskell</th><th>F#</th></tr><tr><td><pre>
main = do
    print $ 1 + 2
    print $ (+) 1 2
</pre></td><td><pre>
printfn "%d" &lt;| 1 + 2
printfn "%d" &lt;| (+) 1 2
</pre></td></tr><tr><td>実行結果<pre>
3
3
</pre></td><td>実行結果<pre>
3
3
</pre></td></tr></table></blockquote>

# 四則演算

F#で割り算で小数点以下を扱う場合は、オペランドを明示的に浮動小数点数で記述します。Haskellのような `/` と `div` の区別はありません。

<blockquote><table><tr><th>Haskell</th><th>F#</th></tr><tr><td><pre>
main = do
    print $ 5 + 2
    print $ 5 - 2
    print $ 5 * 2
    print $ 5 / 2
    print $ div 5 2
    print $ mod 5 2
    print $ 5 `div` 2
    print $ 5 `mod` 2
</pre></td><td><pre>
printfn "%d" &lt;| 5 + 2
printfn "%d" &lt;| 5 - 2
printfn "%d" &lt;| 5 * 2
printfn "%f" &lt;| 5. / 2.
printfn "%d" &lt;| (/) 5 2
printfn "%d" &lt;| (%) 5 2
printfn "%d" &lt;| 5 / 2
printfn "%d" &lt;| 5 % 2
</pre></td></tr><tr><td>実行結果<pre>
7
3
10
2.5
2
1
2
1
</pre></td><td>実行結果<pre>
7
3
10
2.500000
2
1
2
1
</pre></td></tr></table></blockquote>

# 命名規則

Haskellとは異なり変数や関数を大文字で始めてもエラーにはなりませんが、慣習的に小文字で始めます。

# if - then - else

まず、一行で書いてみます。

<blockquote><table><tr><th>Haskell</th><th>F#</th></tr><tr><td><pre>
a = 1

main = do
    if a == 1 then print "1" else print "?"
</pre></td><td><pre>
let a = 1

if a = 1 then printfn "1" else printfn "?"
</pre></td></tr><tr><td>実行結果<pre>
"1"
</pre></td><td>実行結果<pre>
1
</pre></td></tr></table></blockquote>

※ 「等しい」は`=`、「等しくない」は`<>`です。

複数行で書く場合のインデントにはある程度のバリエーションがありますが、よく使われるパターンを示します。

<blockquote><table><tr><th>Haskell</th><th>F#</th></tr><tr><td><pre>
a = 1

main = do
    if a == 1
        then print "1"
        else print "?"
</pre></td><td><pre>
let a = 1

if a = 1 then
    printfn "1"
else
    printfn "?"
</pre></td></tr><tr><td>実行結果<pre>
"1"
</pre></td><td>実行結果<pre>
1
</pre></td></tr></table></blockquote>

※ F#の`else`はインデントで特別なルールがありますが、書き方が複数あると混乱するため説明を省略します。

## 値を返す

`if`は値を返すため、C言語の三項演算子のように使えます。

<blockquote><table><tr><th>Haskell</th><th>F#</th></tr><tr><td><pre>
a = 1

main = do
    print $ if a == 1 then "1" else "?"
</pre></td><td><pre>
let a = 1

printfn "%s" &lt;| if a = 1 then "1" else "?"
</pre></td></tr><tr><td>実行結果<pre>
"1"
</pre></td><td>実行結果<pre>
1
</pre></td></tr></table></blockquote>

関数の定義と組み合わせた例です。

<blockquote><table><tr><th>Haskell</th><th>F#</th></tr><tr><td><pre>
f a = if a == 1 then "1" else "?"

main = do
    print $ f 0
    print $ f 1
</pre></td><td><pre>
let f a = if a = 1 then "1" else "?"

printfn "%s" &lt;| f 0
printfn "%s" &lt;| f 1
</pre></td></tr><tr><td>実行結果<pre>
"?"
"1"
</pre></td><td>実行結果<pre>
?
1
</pre></td></tr></table></blockquote>

# 関数のパターンマッチ

関数内の全体を`if`で切り分ける代わりに、`function`キーワードで引数を振り分けられます。このような書き方を**パターンマッチ**と呼びます。

※ Haskellのように関数を複数定義するような形にはしません。

<blockquote><table><tr><th>Haskell</th><th>F#</th></tr><tr><td><pre>
f 1 = "1"
f a = "?"

main = do
    print $ f 0
    print $ f 1
</pre></td><td><pre>
let f = function
| 1 -> "1"
| a -> "?"

printfn "%s" &lt;| f 0
printfn "%s" &lt;| f 1
</pre></td></tr><tr><td>実行結果<pre>
"?"
"1"
</pre></td><td>実行結果<pre>
?
1
</pre></td></tr></table></blockquote>

値を無視する引数は`_`と書くことで、値を無視していることを明示します。

<blockquote><table><tr><th>Haskell</th><th>F#</th></tr><tr><td><pre>
f 1 = "1"
f _ = "?"
</pre></td><td><pre>
let f = function
| 1 -> "1"
| _ -> "?"
</pre></td></tr></table></blockquote>

これは独特な書き方のため、慣れが必要です。

## 階乗

例としてよく引き合いに出されます。

<blockquote><table><tr><th>Haskell</th><th>F#</th></tr><tr><td><pre>
fact 0 = 1
fact n = n * fact (n - 1)

main = do
    print $ fact 5
</pre></td><td><pre>
let rec fact = function
| 0 -> 1
| n -> n * fact (n - 1)

printfn "%d" &lt;| fact 5
</pre></td></tr><tr><td>実行結果<pre>
120
</pre></td><td>実行結果<pre>
120
</pre></td></tr></table></blockquote>

`fact`の中で`fact`を呼んでいます。このような流れを**再帰**と言います。再帰関数には`rec`キーワードを付けます。`rec`を付けなければ自分が参照できずにエラーになります。

※ デフォルトで再帰可能になっていないのは、同名の変数で覆い隠すシャドウイングを考慮した言語設計のようです。F#の元になったOCamlについての記事を紹介します。

* [@camlspotter](https://twitter.com/camlspotter): [OCaml の let と let rec はなぜ別扱いになっているのか、決定版、もしくは OCaml 暦十何年だったか忘れたけど仕事で Haskell を一年使ってみた - Oh, you `re no (fun _ → more)](http://d.hatena.ne.jp/camlspotter/20110509/1304933919) 2011.05.09

再帰は往復で処理されるため往路と復路に分けて考えます。

再帰の往路をトレースします。

1. `| 5 -> 5 * fact 4`
1. `| 4 -> 4 * fact 3`
1. `| 3 -> 3 * fact 2`
1. `| 2 -> 2 * fact 1`
1. `| 1 -> 1 * fact 0`
1. `| 0 -> 1`

`| 0 -> 1`が折り返し点となり、反転して復路に入ります。

1. `| 1 -> 1 * fact 0 = 1 * 1 = 1`
1. `| 2 -> 2 * fact 1 = 2 * 1 = 2`
1. `| 3 -> 3 * fact 2 = 3 * 2 = 6`
1. `| 4 -> 4 * fact 3 = 4 * 6 = 24`
1. `| 5 -> 5 * fact 4 = 5 * 24 = 120`

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

* 基底部: `| 0 -> 1`
* 再帰部: `| n -> n * fact (n - 1)`

## コツ

再帰の取り扱いにはパターンがあります。そこを意識するのがコツです。

### 作り方のコツ

1. 基底部を定義
2. 具体例に当てはめて一般化する

まず基底部を定義します。自然数を指定するタイプでは値が減少しながら再帰を繰り返すのが定石で、これ以上減少できない最小値が基底部となります。

階乗について考えます。マイナスの階乗が定義されていないため、計算可能な最小の階乗は $0!$ です。このことから基底部を定義します。

```fsharp:基底部
let rec fact = function
| 0 -> 1
```

再帰部は具体例を通して考えるのがコツです。たとえば5の階乗を考えます。

```math:具体例
5! = 5 × 4 × 3 × 2 × 1
```

再帰は引数を5から0に向かって減少させて処理します。1つ小さい引数（この場合は4）の結果を利用するのが定石です。このパターンで表すため、5の階乗を4の階乗で表せないか考えます。

```math:式変形
5! = 5 × (4 × 3 × 2 × 1) = 5 × 4!
```

特定の数（この場合は5）での関係が得られました。これを一般化して5を$n$に置き換えます。4は$n-1$です。このように隣接する項目との関係で表された式を[漸化式](http://ja.wikipedia.org/wiki/%E6%BC%B8%E5%8C%96%E5%BC%8F)と呼びます。

```math:漸化式
n! = n × (n-1)!
```

漸化式をコード化すれば再帰部が得られます。

```fsharp:fact再帰部
| n -> n * fact (n - 1)
```

このように基底部と再帰部は順を追って別々に作ることになるため、パターンマッチで分岐する書き方と相性が良いです。

※ 数学の問題であれば得られた式を[数学的帰納法](http://ja.wikipedia.org/wiki/%E6%95%B0%E5%AD%A6%E7%9A%84%E5%B8%B0%E7%B4%8D%E6%B3%95)で証明することが求められますが、今回はプログラミングの練習が目的なので、いくつか具体例で動作確認して済ませます。

### 確認のコツ

一旦書き上げたプログラムを確認するコツです。既存のコードを読むときにも使えます。

再帰の流れは追わずに、結果が信頼できるものと見なして具体例で考えます。

```fsharp:fact再帰部
| n -> n * fact (n - 1)
```

1. `| 5 -> 5 * fact 4`
2. `fact 4`は定義より`4! = 24`が返されると考えます。
3. `5 * 24 = 120`

次に再帰を使った練習問題をやるので、この方法を試してみてください。

## 練習

フィボナッチ数は`0, 1`が初期値として与えられ、それ以降は前2つの数字を合計して得られる数列です。

* 0, 1, 1, 2, 3, 5, 8, 13, 21, ...

【問1】任意のn番目のフィボナッチ数を計算する関数`fib`をパターンマッチで実装してください。最初の0は0番目とします。

ヒント: 基底部は1つとは限りません。

⇒ [解答例](http://qiita.com/7shi/items/b174d1c50aab9350dafc#%E3%83%95%E3%82%A3%E3%83%9C%E3%83%8A%E3%83%83%E3%83%81%E6%95%B0)

# ガード

パターンマッチに`when`で条件を付加するガードという書き方があります。

上で実装した`fact`に負の数を渡すと無限ループになります。対策としてガードを追加して引数を制限します。

※ マイナスの階乗は数学的に定義されていないので、弾いても問題ありません。

<blockquote><table><tr><th>Haskell</th><th>F#</th></tr><tr><td><pre>
fact 0 = 1
fact n | n > 0 = n * fact (n - 1)

main = do
    print $ fact 5
</pre></td><td><pre>
let rec fact = function
| 0 -> 1
| n when n > 0 -> n * fact (n - 1)

printfn "%d" &lt;| fact 5
</pre></td></tr><tr><td>実行結果<pre>
120
</pre></td><td>実行結果<pre>
120
</pre></td></tr></table></blockquote>

## 例外

先ほどのコードは Imcomplete patter matches と警告されます。マイナスのときの処理が抜けているためです。

警告を消すため、残り全部の意味で `_`で受けて`failwith`で例外を発生させます。

```fsharp:F#
let rec fact = function
| 0 -> 1
| n when n > 0 -> n * fact (n - 1)
| _ -> failwith "< 0"
```

※ Haskellでは例外を使用するには構造を変える必要があるため、対応コードは省略します。Haskellで例外を使わずに処理する方法については[Haskell Maybeモナド 超入門](http://qiita.com/7shi/items/c7d7eec066af0fe0688d#guard)を参照してください。

## 練習

【問2】問1で実装した関数に、無限ループを防ぐためのガードを追加してください。

⇒ [解答例](http://qiita.com/7shi/items/b174d1c50aab9350dafc#%E3%82%AC%E3%83%BC%E3%83%89)

# match

関数の中でパターンマッチを行うには `match` - `with` を使います。

※ Haskellとは異なり、F#では`function`も`match`も`->`を使います。

<blockquote><table><tr><th>Haskell</th><th>F#</th></tr><tr><td><pre>
fact n = case n of
    0 -> 1
    _ | n > 0 -> n * fact (n - 1)

main = do
    print $ fact 5
</pre></td><td><pre>
let rec fact n =
    match n with
    | 0 -> 1
    | _ when n > 0 -> n * fact (n - 1)
    | _ -> failwith "< 0"

printfn "%d" &lt;| fact 5
</pre></td></tr><tr><td>実行結果<pre>
120
</pre></td><td>実行結果<pre>
120
</pre></td></tr></table></blockquote>

※ 引数で`n`として受けているため、`match`中のパターンマッチでは`_`として受け流しています。

`function`は関数レベルの分岐のためインデントしませんでしたが、`match`は関数の中のためインデントが必須です。詳細は次の記事を参照してください。

* [functionのインデント](http://qiita.com/7shi/items/7f490819e818dd7aa37c) 2016.12.14

## 練習

【問3】問2で実装した関数を`match`で書き直してください。

⇒ [解答例](http://qiita.com/7shi/items/b174d1c50aab9350dafc#match)

# リスト

他言語の配列と似たようなものです。F#では要素は `;` で区切ります。慣れるまで間違えやすいので注意してください。

※ F#では `,` で区切ると意味が変わり、大抵の場合はエラーとなります。

<blockquote><table><tr><th>Haskell</th><th>F#</th></tr><tr><td><pre>
main = do
    print [1, 2, 3, 4, 5]
</pre></td><td><pre>
printfn "%A" [1; 2; 3; 4; 5]
</pre></td></tr><tr><td>実行結果<pre>
[1,2,3,4,5]
</pre></td><td>実行結果<pre>
[1; 2; 3; 4; 5]
</pre></td></tr></table></blockquote>

※ F#ではリストとは別に配列もあります。今回はリストの使い方に慣れることを目的とするため、配列については省略します。

要素は改行によっても区切られます。実際には改行の方が基本で、改行せずに区切るのが `;` です。

```fsharp:F#
printfn "%A" [
    1
    2
    3
    4
    5]
```
```text:実行結果
[1; 2; 3; 4; 5]
```

## 要素の取り出し

リストから要素を取り出すには`.[]`を使います。先頭の要素は0番目です。

※ 他の言語に慣れていると `.` が異様に映りますが、`[]`もオブジェクトのメソッドだということを示しています。

<blockquote><table><tr><th>Haskell</th><th>F#</th></tr><tr><td><pre>
main = do
    print $ [1, 2, 3, 4, 5] !! 3
</pre></td><td><pre>
printfn "%d" [1; 2; 3; 4; 5].[3]
</pre></td></tr><tr><td>実行結果<pre>
4
</pre></td><td>実行結果<pre>
4
</pre></td></tr></table></blockquote>

## 連番

連番リストを生成する専用の書き方があります。

<blockquote><table><tr><th>Haskell</th><th>F#</th></tr><tr><td><pre>
main = do
    print [1..5]
</pre></td><td><pre>
printfn "%A" [1..5]
</pre></td></tr><tr><td>実行結果<pre>
[1,2,3,4,5]
</pre></td><td>実行結果<pre>
[1; 2; 3; 4; 5]
</pre></td></tr></table></blockquote>

## 連結

`@`によりリスト同士を結合できます。

<blockquote><table><tr><th>Haskell</th><th>F#</th></tr><tr><td><pre>
main = do
    print $ [1, 2, 3] ++ [4, 5]
</pre></td><td><pre>
printfn "%A" &lt;| [1; 2; 3] @ [4; 5]
</pre></td></tr><tr><td>実行結果<pre>
[1,2,3,4,5]
</pre></td><td>実行結果<pre>
[1; 2; 3; 4; 5]
</pre></td></tr></table></blockquote>

## ::

`::`によりリストの先頭に要素を挿入できます。

※ Haskellとは`:`と`::`の意味が逆なのに注意が必要です。

<blockquote><table><tr><th>Haskell</th><th>F#</th></tr><tr><td><pre>
main = do
    print $ 1:[2..5]
</pre></td><td><pre>
printfn "%A" &lt;| 1::[2..5]
</pre></td></tr><tr><td>実行結果<pre>
[1,2,3,4,5]
</pre></td><td>実行結果<pre>
[1; 2; 3; 4; 5]
</pre></td></tr></table></blockquote>

複数の先頭要素を連ねることもできます。

<blockquote><table><tr><th>Haskell</th><th>F#</th></tr><tr><td><pre>
main = do
    print $ 1:2:[3..5]
</pre></td><td><pre>
printfn "%A" &lt;| 1::2::[3..5]
</pre></td></tr><tr><td>実行結果<pre>
[1,2,3,4,5]
</pre></td><td>実行結果<pre>
[1; 2; 3; 4; 5]
</pre></td></tr></table></blockquote>

`::`では末尾に追加できないため`@`を使用します。

<blockquote><table><tr><th>Haskell</th><th>F#</th></tr><tr><td><pre>
main = do
    print $ [1..4] ++ [5]
</pre></td><td><pre>
printfn "%A" &lt;| [1..4] @ [5]
</pre></td></tr><tr><td>実行結果<pre>
[1,2,3,4,5]
</pre></td><td>実行結果<pre>
[1; 2; 3; 4; 5]
</pre></td></tr></table></blockquote>

## 文字列

Haskellでは文字列は文字のリストとして扱われますが、F#では別物です。文字列の連結は`+`で、`@`や`::`は使えません。

F#で文字列をリストに変換するには`List.ofSeq`を使用します。

<blockquote><table><tr><th>Haskell</th><th>F#</th></tr><tr><td><pre>
main = do
    print $ "abcde"
    print $ ['a', 'b', 'c', 'd', 'e']
    print $ ['a'..'e']
    print $ 'a':"bcde"
    print $ 'a':'b':"cde"
    print $ "abc" ++ "de"
    print $ "abcde" !! 3
</pre></td><td><pre>
printfn "%A" &lt;| "abcde"
printfn "%A" &lt;| ['a'; 'b'; 'c'; 'd'; 'e']
printfn "%A" &lt;| ['a'..'e']
printfn "%A" &lt;| 'a'::List.ofSeq "bcde"
printfn "%A" &lt;| 'a'::'b'::List.ofSeq "cde"
printfn "%A" &lt;| "abc" + "de"
printfn "%A" &lt;| "abcde".[3]
</pre></td></tr><tr><td>実行結果<pre>
"abcde"
"abcde"
"abcde"
"abcde"
"abcde"
"abcde"
'd'
</pre></td><td>実行結果<pre>
"abcde"
['a'; 'b'; 'c'; 'd'; 'e']
['a'; 'b'; 'c'; 'd'; 'e']
['a'; 'b'; 'c'; 'd'; 'e']
['a'; 'b'; 'c'; 'd'; 'e']
"abcde"
'd'
</pre></td></tr></table></blockquote>

文字のリストから文字列への変換は次のようにします。

```fsharp:F#
let a = ['a'..'f']
let s = Array.ofList a |> System.String.Concat
printfn "%A -> %A" a s
```
```text:実行結果
['a'; 'b'; 'c'; 'd'; 'e'; 'f'] -> "abcdef"
```

## パターンマッチ

パターンマッチでリストの先頭要素を取り出せます。

<blockquote><table><tr><th>Haskell</th><th>F#</th></tr><tr><td><pre>
first (x:xs) = x

main = do
    print $ first [1..5]
    print $ first "abcdef"
</pre></td><td><pre>
let first = function
| x::xs -> x
| _ -> failwith "empty"

printfn "%A" &lt;| first [1..5]
printfn "%A" &lt;| first (List.ofSeq "abcdef")
</pre></td></tr><tr><td>実行結果<pre>
1
'a'
</pre></td><td>実行結果<pre>
1
'a'
</pre></td></tr></table></blockquote>

`x::xs`で先頭`x`とその後ろのリスト`xs`に分割して受け取ります。`xs`は`x`の複数形を意図しています。これらの名前には文法的な意味はなく、あくまで慣習です。

この例では`xs`を使っていないため`_`で未使用を明示した方が無難です。

<blockquote><table><tr><th>Haskell</th><th>F#</th></tr><tr><td><pre>
first (x:_) = x
</pre></td><td><pre>
| x::_ -> x
</pre></td></tr></table></blockquote>

先頭要素は複数を連ねることもできます。

<blockquote><table><tr><th>Haskell</th><th>F#</th></tr><tr><td><pre>
second (_:x:_) = x

main = do
    print $ second [1..5]
    print $ second "abcdef"
</pre></td><td><pre>
let second = function
| _::x::_ -> x
| _ -> failwith "too short"

printfn "%A" &lt;| second [1..5]
printfn "%A" &lt;| second (List.ofSeq "abcdef")
</pre></td></tr><tr><td>実行結果<pre>
2
'b'
</pre></td><td>実行結果<pre>
2
'b'
</pre></td></tr></table></blockquote>

# リスト関係の関数

F#では`List`のメソッドという扱いです（`List.ofSeq` など）。

`List.`は省略できません。これは冗長な印象を受けますが、いくつかメリットがあります。

* F#では型推論を優先する言語設計のため、関数のオーバーロードができません。モジュールのメソッドであれば、配列・リスト・シーケンスなど互換性のない型に対して、同じ名前のメソッドが提供できます。
* インテリセンスのサポートがある環境では、`List.`と打てばメソッド名の候補が補完されます。

## length

リストの要素数を取得します。

<blockquote><table><tr><th>Haskell</th><th>F#</th></tr><tr><td><pre>
main = do
    print $ length [1, 2, 3]
</pre></td><td><pre>
printfn "%d" &lt;| List.length [1; 2; 3]
</pre></td></tr><tr><td>実行結果<pre>
3
</pre></td><td>実行結果<pre>
3
</pre></td></tr></table></blockquote>

## sum

リストの要素をすべて足します。

<blockquote><table><tr><th>Haskell</th><th>F#</th></tr><tr><td><pre>
main = do
    print $ sum [1..5]
</pre></td><td><pre>
printfn "%d" &lt;| List.sum [1..5]
</pre></td></tr><tr><td>実行結果<pre>
15
</pre></td><td>実行結果<pre>
15
</pre></td></tr></table></blockquote>

## rev

リストの要素を逆に並べます。

<blockquote><table><tr><th>Haskell</th><th>F#</th></tr><tr><td><pre>
main = do
    print $ reverse [1..5]
</pre></td><td><pre>
printfn "%A" &lt;| List.rev [1..5]
</pre></td></tr><tr><td>実行結果<pre>
[5,4,3,2,1]
</pre></td><td>実行結果<pre>
[5; 4; 3; 2; 1]
</pre></td></tr></table></blockquote>

## 練習

`length`と同じ機能の関数を再実装する例です。

```fsharp:F#
let rec length = function
| []    -> 0
| _::xs -> 1 + length xs

printfn "%d" &lt;| length [1; 2; 3]
```
```text:実行結果
3
```

【問4】`sum`, `rev`と同じ機能の関数を再実装してください。`sum`の掛け算版`product`も実装してください。

ヒント: リストを再帰で処理するパターンは`| x::xs -> x ... f xs`です。

⇒ [解答例](http://qiita.com/7shi/items/b174d1c50aab9350dafc#%E5%86%8D%E5%AE%9F%E8%A3%85)

【問5】`product`を使って`fact`（階乗）を実装してください。

⇒ [解答例](http://qiita.com/7shi/items/b174d1c50aab9350dafc#%E9%9A%8E%E4%B9%97)

# タプル

関数で複数の値を返すことができます。括弧で複数の値を囲んだ部分を**タプル**と呼びます。

※ F#ではタプルの括弧を省略できますが、この記事では混乱を避けるため省略しません。

<blockquote><table><tr><th>Haskell</th><th>F#</th></tr><tr><td><pre>
addsub x y = (x + y, x - y)

main = do
    print $ addsub 1 2
</pre></td><td><pre>
let addsub x y = (x + y, x - y)

printfn "%A" &lt;| addsub 1 2
</pre></td></tr><tr><td>実行結果<pre>
(3,-1)
</pre></td><td>実行結果<pre>
(3, -1)
</pre></td></tr></table></blockquote>

タプルは全体でも分割でも受け取れます。

<blockquote><table><tr><th>Haskell</th><th>F#</th></tr><tr><td><pre>
addsub x y = (x + y, x - y)
a = addsub 1 2
(a1, a2) = addsub 1 2

main = do
    print a
    print a1
    print a2
</pre></td><td><pre>
let addsub x y = (x + y, x - y)
let a = addsub 1 2
let (a1, a2) = addsub 1 2

printfn "%A" a
printfn "%d" a1
printfn "%d" a2
</pre></td></tr><tr><td>実行結果<pre>
(3,-1)
3
-1
</pre></td><td>実行結果<pre>
(3, -1)
3
-1
</pre></td></tr></table></blockquote>

数学の座標をイメージすると良いでしょう。

* $P=(1,2)$
* $(x,y)=(1,2)$ ⇔ $x=1,y=2$

## リストとの比較

* リストの項目数は任意ですが、タプルでは固定です。
* リストの要素はすべて同じ型でないといけませんが、タプルでは任意です。
    * × `[1; "a"]`
    * ○ `(1, "a")`

## 関数

要素が2つのタプルから値を取り出す関数`fst`, `snd`があります。

<blockquote><table><tr><th>Haskell</th><th>F#</th></tr><tr><td><pre>
main = do
    let p2 = (1, 2)
    print $ fst p2
    print $ snd p2
</pre></td><td><pre>
let p2 = (1, 2)
printfn "%d" &lt;| fst p2
printfn "%d" &lt;| snd p2
</pre></td></tr><tr><td>実行結果<pre>
1
2
</pre></td><td>実行結果<pre>
1
2
</pre></td></tr></table></blockquote>

要素が3つ以上のタプルからは変数経由で値を取り出します。

<blockquote><table><tr><th>Haskell</th><th>F#</th></tr><tr><td><pre>
main = do
    let p3 = (1, 2, 3)
    print p3
    let (_, _, p3z) = p3
    print p3z
</pre></td><td><pre>
let p3 = (1, 2, 3)
printfn "%A" p3
let (_, _, p3z) = p3
printfn "%d" p3z
</pre></td></tr><tr><td>実行結果<pre>
(1,2,3)
3
</pre></td><td>実行結果<pre>
(1, 2, 3)
3
</pre></td></tr></table></blockquote>

※ リストのように`.[]`で値を取り出すことはできません。

## 練習

【問6】点 $(p, q)$ から直線 $ax + by = c$ に下した垂線の交点を求める関数`perpPoint`を作成してください。aとbが両方ゼロになると解なしですが、チェックせずに無視してください。

具体的には次のコードが動くようにしてください。`0.`などは浮動小数点数（`float`）のリテラルです。

```fsharp
printfn "%A" &lt;| perpPoint (0., 2.) (1., -1., 0.)
```
```text:実行結果
(1.0, 1.0)
```

ヒント: $ax + by = c$ の傾きは $-\frac{a}{b}$ です。直交する直線の傾きとの積が $-1$ となることから、垂線は $bx - ay = d$ と表せます。連立方程式を解けば交点が求まります。

⇒ [解答例](http://qiita.com/7shi/items/b174d1c50aab9350dafc#%E5%9E%82%E7%B7%9A%E3%81%AE%E4%BA%A4%E7%82%B9)

# キャスト

`int`などの基本的な型は、型名を関数として扱うことでキャストできます。

キャストを使用して、文字コードを取得したり、文字コードを文字に変換したりする例です。

※ Haskellでは専用の関数をインポートして使用します。

<blockquote><table><tr><th>Haskell</th><th>F#</th></tr><tr><td><pre>
import Data.Char

main = do
    print $ ord 'A'
    print $ chr 65
</pre></td><td><pre>
printfn "%d" &lt;| int 'A'
printfn "%c" &lt;| char 65
</pre></td></tr><tr><td>実行結果<pre>
65
'A'
</pre></td><td>実行結果<pre>
65
A
</pre></td></tr></table></blockquote>

## 練習

【問7】[ROT13](http://ja.wikipedia.org/wiki/ROT13)を実装してください。

具体的には次のコードが動くようにしてください。

```fsharp
let hello13 = rot13 "Hello, World!"
printfn "%s" hello13
printfn "%s" <| rot13 hello13
```
```text:実行結果
Uryyb, Jbeyq!
Hello, World!
```

⇒ [解答例](http://qiita.com/7shi/items/b174d1c50aab9350dafc#rot13)

# ソート

挿入ソートの実装例を示します。

<blockquote><table><tr><th>Haskell</th><th>F#</th></tr><tr><td><pre>
insert x [] = [x]
insert x (y:ys)
    | x &lt; y     = x:y:ys
    | otherwise = y : insert x ys

isort []     = []
isort (x:xs) = insert x (isort xs)

main = do
    let t = [4, 6, 9, 8, 3, 5, 1, 7, 2]
    print $ isort t
</pre></td><td><pre>
let rec insert x = function
| [] -> [x]
| y::ys when x &lt; y -> x::y::ys
| y::ys -> y :: insert x ys

let rec isort = function
| [] -> []
| x::xs -> insert x (isort xs)

let t = [4; 6; 9; 8; 3; 5; 1; 7; 2]
printfn "%A" &lt;| isort t
</pre></td></tr><tr><td>実行結果<pre>
[1,2,3,4,5,6,7,8,9]
</pre></td><td>実行結果<pre>
[1; 2; 3; 4; 5; 6; 7; 8; 9]
</pre></td></tr></table></blockquote>

処理の流れを説明します。

```fsharp:F#
let rec isort = function
| [] -> []
| x::xs -> insert x (isort xs)
```

リストの先頭の要素を取り出しながら再帰することで、リストの要素を順番に挿入して行きます。

リスト`[4; 6; 9; 8; 3; 5; 1; 7; 2]`の往路をトレースします。

1. `| [4; 6; 9; 8; 3; 5; 1; 7; 2] -> insert 4 (isort [6; 9; 8; 3; 5; 1; 7; 2])`
1. `| [6; 9; 8; 3; 5; 1; 7; 2] -> insert 6 (isort [9; 8; 3; 5; 1; 7; 2])`
1. `| [9; 8; 3; 5; 1; 7; 2] -> insert 9 (isort [8; 3; 5; 1; 7; 2])`
1. `| [8; 3; 5; 1; 7; 2] -> insert 8 (isort [3; 5; 1; 7; 2])`
1. `| [3; 5; 1; 7; 2] -> insert 3 (isort [5; 1; 7; 2])`
1. `| [5; 1; 7; 2] -> insert 5 (isort [1; 7; 2])`
1. `| [1; 7; 2] -> insert 1 (isort [7; 2])`
1. `| [7; 2] -> insert 7 (isort [2])`
1. `| [2] -> insert 2 (isort [])`
1. `| [] -> []`

`insert`の第2引数は必ず`isort`でソートされたリストが渡されます。

挿入先のリストはソート済みであることを前提にできるため、挿入箇所の判定は後続要素との比較だけで済みます。

再帰により挿入先のリストの要素と順番に比較していきます。末尾に達すると`ys = []`となるため、そこに挿入します。

```fsharp:F#
let rec insert x = function
| [] -> [x]
| y::ys when x < y -> x::y::ys
| y::ys -> y :: insert x ys
```

例を示します。

1. `insert 3 [1; 2; 5; 7]` 次へ
1. `1::insert 3 [2; 5; 7]` 次へ
1. `1::2::insert 3 [5; 7]` ここへ挿入
1. `1::2::3::[5; 7]`
1. `[1; 2; 3; 5; 7]`

`isort`の復路をトレースします。

1. `| [2] -> insert 2 []`
1. `| [7; 2] -> insert 7 [2]`
1. `| [1; 7; 2] -> insert 1 [2; 7]`
1. `| [5; 1; 7; 2] -> insert 5 [1; 2; 7]`
1. `| [3; 5; 1; 7; 2] -> insert 3 [1; 2; 5; 7]`
1. `| [8; 3; 5; 1; 7; 2] -> insert 8 [1; 2; 3; 5; 7]`
1. `| [9; 8; 3; 5; 1; 7; 2] -> insert 9 [1; 2; 3; 5; 7; 8]`
1. `| [6; 9; 8; 3; 5; 1; 7; 2] -> insert 6 [1; 2; 3; 5; 7; 8; 9]`
1. `| [4; 6; 9; 8; 3; 5; 1; 7; 2] -> insert 4 [1; 2; 3; 5; 6; 7; 8; 9]`
1. `[1; 2; 3; 4; 5; 6; 7; 8; 9]`

このように要素を1つずつソートされたリストに挿入しています。

## 確認のコツ

再帰の確認のコツを説明しましたが、挿入ソートに適用してみます。具体例を使って、結果が信頼できるものと見なします。

```fsharp:isort再帰部
| x::xs -> insert x (isort xs)
```

1. `| [3; 5; 1; 7; 2] -> insert 3 (isort [5; 1; 7; 2])`
2. `| [5; 1; 7; 2]`は定義よりソート済みの`[1; 2; 5; 7]`が返されると考えます。
3. `insert 3 [1; 2; 5; 7] = [1; 2; 3; 5; 7]`

## デバッグ

F#ではHaskellのように副作用の分離が強制されないため、通常の`printf`デバッグが可能です。

挿入ソートをトレースしてみます。

```fsharp:F#
let rec insert x = function
| [] -> [x]
| y::ys when x < y -> x::y::ys
| y::ys -> y :: insert x ys

let rec isort = function
| [] -> []
| x::xs ->
    printfn "isort %A = insert %d (isort %A)" (x::xs) x xs
    let xs' = isort xs
    let ret = insert x xs'
    printfn "insert %d %A = %A" x xs' ret
    ret

let t = [4; 6; 9; 8; 3; 5; 1; 7; 2]
printfn "%A" <| isort t
```
```text:実行結果
isort [4; 6; 9; 8; 3; 5; 1; 7; 2] = insert 4 (isort [6; 9; 8; 3; 5; 1; 7; 2])
isort [6; 9; 8; 3; 5; 1; 7; 2] = insert 6 (isort [9; 8; 3; 5; 1; 7; 2])
isort [9; 8; 3; 5; 1; 7; 2] = insert 9 (isort [8; 3; 5; 1; 7; 2])
isort [8; 3; 5; 1; 7; 2] = insert 8 (isort [3; 5; 1; 7; 2])
isort [3; 5; 1; 7; 2] = insert 3 (isort [5; 1; 7; 2])
isort [5; 1; 7; 2] = insert 5 (isort [1; 7; 2])
isort [1; 7; 2] = insert 1 (isort [7; 2])
isort [7; 2] = insert 7 (isort [2])
isort [2] = insert 2 (isort [])
insert 2 [] = [2]
insert 7 [2] = [2; 7]
insert 1 [2; 7] = [1; 2; 7]
insert 5 [1; 2; 7] = [1; 2; 5; 7]
insert 3 [1; 2; 5; 7] = [1; 2; 3; 5; 7]
insert 8 [1; 2; 3; 5; 7] = [1; 2; 3; 5; 7; 8]
insert 9 [1; 2; 3; 5; 7; 8] = [1; 2; 3; 5; 7; 8; 9]
insert 6 [1; 2; 3; 5; 7; 8; 9] = [1; 2; 3; 5; 6; 7; 8; 9]
insert 4 [1; 2; 3; 5; 6; 7; 8; 9] = [1; 2; 3; 4; 5; 6; 7; 8; 9]
[1; 2; 3; 4; 5; 6; 7; 8; 9]
```

`printfn`を2回使うことで、往路と復路が確認できるように表示しています。

## 練習

【問8】[バブルソート](http://www.ics.kagoshima-u.ac.jp/~fuchida/edu/algorithm/sort-algorithm/bubble-sort.html)を実装してください。

ヒント: 交換する関数とソートする関数を分離して実装します。

⇒ [詳細説明](http://qiita.com/7shi/items/1e2a66bf8e8c7f0bd70f), [解答例](http://qiita.com/7shi/items/b174d1c50aab9350dafc#%E3%83%90%E3%83%96%E3%83%AB%E3%82%BD%E3%83%BC%E3%83%88)

【問9】[マージソート](http://www.ics.kagoshima-u.ac.jp/~fuchida/edu/algorithm/sort-algorithm/merge-sort.html)を実装してください。

ヒント: リストを分割する関数を実装します。

⇒ [解答例](http://qiita.com/7shi/items/b174d1c50aab9350dafc#%E3%83%9E%E3%83%BC%E3%82%B8%E3%82%BD%E3%83%BC%E3%83%88)

# リスト内包表記

リストの要素すべてに同じ処理を施した別のリストを作成します。

<blockquote><table><tr><th>Haskell</th><th>F#</th></tr><tr><td><pre>
fact 0 = 1
fact n | n > 0 = n * fact (n - 1)

main = do
    print [1, 2, 3, 4, 5]
    print [fact 1, fact 2, fact 3, fact 4, fact 5]
    print [fact x | x &lt;- [1..5]]
</pre></td><td><pre>
let rec fact = function
| 0 -> 1
| n when n > 0 -> n * fact (n - 1)
| _ -> failwith "< 0"

printfn "%A" &lt;| [1; 2; 3; 4; 5]
printfn "%A" &lt;| [fact 1; fact 2; fact 3; fact 4; fact 5]
printfn "%A" &lt;| [for x in 1..5 -> fact x]
</pre></td></tr><tr><td>実行結果<pre>
[1,2,3,4,5]
[1,2,6,24,120]
[1,2,6,24,120]
</pre></td><td>実行結果<pre>
[1; 2; 3; 4; 5]
[1; 2; 6; 24; 120]
[1; 2; 6; 24; 120]
</pre></td></tr></table></blockquote>

`1..5`の要素を1つずつ`x`として取り出して、`fact x`として処理したリストを作成しています。

※ 同じことができる`map`という関数もありますが、詳細は省略します。

## 条件

要素を取り出す際に条件を指定する例を示します。

<blockquote><table><tr><th>Haskell</th><th>F#</th></tr><tr><td><pre>
main = do
    print [x | x &lt;- [1..9], x &lt; 5]
</pre></td><td><pre>
printfn "%A" &lt;| [for x in 1..9 do if x &lt; 5 then yield x]
</pre></td></tr><tr><td>実行結果<pre>
[1,2,3,4]
</pre></td><td>実行結果<pre>
[1; 2; 3; 4]
</pre></td></tr></table></blockquote>

`1..9`のうち`x < 5`を満たすものだけでリストを作成しています。

※ 同じことができる`filter`という関数もありますが、詳細は省略します。

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

【問10】動きを考えて、F#に移植してください。

⇒ [解答例](http://qiita.com/7shi/items/b174d1c50aab9350dafc#%E3%82%AF%E3%82%A4%E3%83%83%E3%82%AF%E3%82%BD%E3%83%BC%E3%83%88)

## 多重ループ

リスト内包表記で多重ループを使った例を示します。

複数のリストから値を取り出すこともできます。多重ループのようにすべての組み合わせが得られます。

<blockquote><table><tr><th>Haskell</th><th>F#</th></tr><tr><td><pre>
main = do
    print [(x, y) | x &lt;- [1..3], y &lt;- "abc"]
</pre></td><td><pre>
printfn "%A" &lt;| [
    for x in 1..3 do
    for y in "abc" -> (x, y)]
</pre></td></tr><tr><td>実行結果<pre>
[(1,'a'),(1,'b'),(1,'c'),(2,'a'),(2,'b'),(2,'c'),
 (3,'a'),(3,'b'),(3,'c')]
</pre></td><td>実行結果<pre>
[(1, 'a'); (1, 'b'); (1, 'c'); (2, 'a'); (2, 'b');
 (2, 'c'); (3, 'a'); (3, 'b'); (3, 'c')]

</pre></td></tr></table></blockquote>

### 練習

【問11】三辺の長さが各20以下の整数で構成される直角三角形を列挙してください。並び順による重複を排除する必要はありません。

ヒント: 直角三角形の成立条件は三平方（ピタゴラス）の定理です。

⇒ [解答例](http://qiita.com/7shi/items/b174d1c50aab9350dafc#%E7%9B%B4%E8%A7%92%E4%B8%89%E8%A7%92%E5%BD%A2%E3%81%AE%E4%B8%89%E8%BE%BA)
