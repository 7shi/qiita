---
coediting: false
comments_count: 0
created_at: '2017-01-04T22:30:42+09:00'
id: ff746903680ae8d0d7ce
likes_count: 63
private: false
reactions_count: 0
stocks_count: 59
tags:
- name: JavaScript
  versions: []
- name: F#
  versions: []
- name: C#
  versions: []
title: C#/JavaScriptで学ぶF#入門
updated_at: '2020-08-14T20:34:56+09:00'
url: https://qiita.com/7shi/items/ff746903680ae8d0d7ce
slide: false
---

C#やJavaScript（ES2015）と比較しながらF#の文法を説明します。手続型の延長線上で取っ掛かりをつかむことを目的とします。関数型については深追いしません。

* とりあえず手続型的な発想でも構わないので、F#を使ってみます。
* 関数型特有の概念の説明には重点を置きませんが、その導入になるようには意識します。
* 一気に関数型に飛ばないで、ベターC#として慣れていくような入り方を目指します。
* 関数型の理解を深めるのは慣れてからでも遅くないというスタンスです。

この記事は以前開催していた[F#入門](https://connpass.com/series/361/)のテキストを改訂したものです。

この記事には姉妹編があります。

* [Haskellで学ぶF#入門](http://qiita.com/7shi/items/1d3750ba17f5a88b8405) 2017.01.11

F#を手っ取り早く試すために、私が常用している環境を紹介します。

* [F#開発環境の紹介](http://qiita.com/7shi/items/5fc7d6477d96bbd7a71d) 2016.12.30

# F#について

F#の構文は見慣れないものだと思います。この記事ではC#/JavaScriptと比較しながら構文に慣れることに重点を置きます。

## 背景

F#が分かりにくいと感じる原因は、主に以下の2種類ではないでしょうか。

1. 構文の異質さ（C系言語などと比較して）
2. 関数型の考え方

今回は前者の壁に的を絞ります。両者は完全に分離しているわけではないため、後者の領域も多少は言及します。個人的にはF#は構文が簡潔で短く書けるのが良いと思っています。触り始めの頃は関数型のことはあまり意識しませんでした。

## 位置付け

F#はC#と同様に.NET Frameworkで動く言語です。クラスを定義したり使ったりなど、基本的にはC#でできるのとほぼ同じことができます。

※ これは大雑把な説明で、細かい点で違いはあります（`protected`や入れ子にされた型など）。

それに対してJavaScriptは出自が異なりますが、C#よりもJavaScriptで説明した方が分かりやすいケースもあるため、説明に取り入れました。

# ハローワールド

※ 横幅の関係上、インデントはスペース2つとします。

<blockquote><table><tr><th>C#</th><th>JavaScript</th><th>F#</th></tr><tr><td><pre>
using System;

class Program
{
  static void Main()
  {
    Console.WriteLine("hello");
  }
}
</pre></td><td><pre>
console.log("hello");
</pre></td><td><pre>
printfn "hello"
</pre>または<pre>
open System
Console.WriteLine "hello"
</pre></td></tr></table></blockquote>

* C#はMainメソッドが必須で、クラスで包む必要があります。簡単のため以後の例では省略します。
* JavaScriptとF#はクラスやMainで包む必要がありません。
* F#はセミコロンが必要ありません。（JavaScriptも省略可能）
* F#では引数を`()`で囲む必要がありません。（付けても動きます）
* F#の`open`はC#の`using`に相当します。以後の例では省略します。

## printf/printfn

F#の`printf`/`printfn`は`open`も何もなくいきなり使える標準の出力用関数です。

```fsharp:F#
printf "hello\n"
printfn "hello"
```

関数名の接尾辞`n`は`"\n"`と同様に New line に由来して、改行を意味します。

複数の引数はコンマではなくスペースで区切ります。（詳細は次のセクションで解説します）

```fsharp:F#
printfn "%d" 1
```

`printf`はコンパイラがフォーマット文字列を認識して、引数の型をチェックします。

```fsharp:F#
printfn "%d" "abc"  // エラー
printfn "%s" 0      // エラー
```

# 複数の引数

F#では複数の引数の扱い方が二系統あり、F#ネイティブの関数と.NETのメソッドとで異なります。

<blockquote><table><tr><th>C#</th><th>JavaScript</th><th>F#</th></tr><tr><td><pre>
Console.WriteLine("{0} {1}”,
  1 + 1, Math.Sqrt(2));
</pre></td><td><pre>
console.log(1 + 1, Math.sqrt(2));
</pre></td><td><pre>
printfn "%d %f" (1 + 1) (sqrt 2.)
</pre>または<pre>
Console.WriteLine("{0} {1}",
  1 + 1, Math.Sqrt 2.)
</pre></td></tr></table></blockquote>

※ F#の2.は2.0のことで、浮動小数点数であることを示します。（後述）

## F#ネイティブの関数

複数の引数はコンマではなくスペースで区切ります。

```fsharp:F#
printfn "%d" 1
```

コンマを付けると警告されてうまく動きません。（後述のタプルとして扱われます）

```fsharp:F#
printfn "%d", 1  // 警告され文字も出力されない
```

括弧で囲む必要はありません。付けるとエラーになります。

```fsharp:F#
printfn("%d" 1)   // エラー
printfn("%d", 1)  // エラー
```

引数で計算や関数呼び出しを行う場合、引数としてまとめるため括弧で囲む必要があります。

```fsharp:F#（再掲）
printfn "%d %f" (1 + 1) (sqrt 2.)
```

## .NETのメソッド

タプルと呼ばれる複数の値を組み合わせた型として扱われます。C#と同じスタイルで、引数はコンマで区切って括弧で囲みます。

```fsharp:F#
Console.WriteLine("{0}", 1)
```

括弧を省略すると警告されてうまく動きません。

```fsharp:F#
Console.WriteLine "{0}", 1  // 警告され実行時例外
```

.NETのメソッドでも1引数の場合は括弧が省略可能です。

```fsharp:F#
Console.WriteLine "hello"
```

以後の例では、F#はネイティブの関数（`printfn`など）があれば、.NETのメソッド（`Console.WriteLine`など）よりも優先して使用します。

## 数値型のキャスト

F#では数値型を自動的にキャストしてくれないため`sqrt(2)`はエラーになります。
C#/JavaScriptから見ると不親切ですが、型推論を優先するための言語設計です。

浮動小数点数型はC#とは型名が異なるため注意が必要です。

C#|F#
----|----
float|float32
double|float

倍精度が浮動小数点数の基本で、単精度がオプショナルという解釈だと思われます。

## おまけ

LISPを知っていれば、最上位の括弧が省略されていると考えればしっくり来るかもしれません。括弧で囲んでも動きます。

```fsharp:F#
(printfn "%f" (sqrt 2.))
```

# 変数

F#の変数はデフォルトで再代入できないという特徴があります。そのことについての説明は後に回して、まずは単純に変数を定義するケースを取り上げます。

変数は`let`で定義します。型推論されるため、C#の`var`に相当します。JavaScriptでは`var`は関数スコープとなるため、ES2015で追加されたブロックスコープの`let`に相当します。

<blockquote><table><tr><th>C#</th><th>JavaScript</th><th>F#</th></tr><tr><td><pre>
var a = 1;
</pre></td><td><pre>
let a = 1;
</pre></td><td><pre>
let a = 1
</pre></td></tr></table></blockquote>

型を明示的に指定する方法もあります。JavaScriptはasm.jsで型で示します。

<blockquote><table><tr><th>C#</th><th>JavaScript</th><th>F#</th></tr><tr><td><pre>
int a = 1;
</pre></td><td><pre>
let a = 1 | 0;
</pre></td><td><pre>
let a: int = 1
</pre></td></tr></table></blockquote>

F#では可能な限り型推論に任せるスタイルを推奨します。

## 束縛

F#はデフォルトでは変数に入れた値は変更できません。変数と値の結び付きが強く、「代入」ではなく「束縛」と表現します。

<blockquote><table><tr><th>C#</th><th>JavaScript</th><th>F#</th></tr><tr><td><pre>
const int a = 1;
Console.WriteLine(a);
a = 2;  // エラー
</pre></td><td><pre>
const a = 1;
console.log(a);
a = 2;  // エラー
</pre></td><td><pre>
let a = 1
printfn "%d" a
a = 2  // 警告（代入ではなく比較）
</pre></td></tr></table></blockquote>

F#では`=`と`==`を書き分けずにどちらも`=`です。`let`以外の`=`は比較として扱われます。

F#で値が変更できるようにするには`mutable`を付けます。値の変更には`<-`を使います。

<blockquote><table><tr><th>C#</th><th>JavaScript</th><th>F#</th></tr><tr><td><pre>
int a = 1;
Console.WriteLine(a);
a = 2;
Console.WriteLine(a);
</pre></td><td><pre>
let a = 1;
console.log(a);
a = 2;
console.log(a);
</pre></td><td><pre>
let mutable a = 1
printfn "%d" a
a &#60;- 2
printfn "%d" a
</pre></td></tr></table></blockquote>

`mutable`を付けずに宣言した変数に再代入する方法はありません。

## 複数の変数定義

複数の変数を一度に定義する書式を示します。

<blockquote><table><tr><th>C#</th><th>JavaScript</th><th>F#</th></tr><tr><td><pre>
int x = 1, y = 2;
</pre></td><td><pre>
let x = 1, y = 2;
</pre></td><td><pre>
let x, y = 1, 2
</pre></td></tr></table></blockquote>

※ C#では`var`を使うと複数の変数を一度に定義できません。

F#の書式は括弧で囲めば数学に近くなり、座標の表記に似たものだと理解できます。括弧の有無で意味は変わりません。

```fsharp:F#
let (x, y) = (1, 2)
```

# F# Interactive

ちょっとした実験は対話的に実行した方が便利です。F# Interactive (fsi) と呼ばれるREPLがあります。

Windows では `fsi.exe` ですが、Mono 環境では `fsharpi` コマンドで呼び出します。

fsiではセミコロンを2つ付けると、評価されて値が表示されます。

```fsharp:fsi
> let a=1;;
val a : int = 1
```

※ `val`は値（value）の意味です。

変数の値を見るには変数名だけでOKです。

```fsharp:fsi
> a;;
val it : int = 1
```

itは直前に評価された値が束縛されている変数で「それ（it）」の意味です。

```fsharp:fsi
> it;;
val it : int = 1
```

`;;`を付け忘れると複数行入力として扱われます。次の行で付ければ評価されます。

```fsharp:fsi
> a
- ;;
```

電卓としても使えます。

```fsharp:fsi
> 1+1;;
val it : int = 2
```

`let`なしの`=`が比較になっているのを確認します。

```fsharp:fsi
> a=1;;
val it : bool = true
> a=2;;
val it : bool = false
```

等しくないのを表すのは`<>`です。

```fsharp:fsi
> a<>1;;
val it : bool = false
```

終了は`#q;;`と入力します。

```fsharp:fsi
> #q;;
```

# 条件式

`if`は構文が少し違うだけで基本的に同じです。

<blockquote><table><tr><th>C#</th><th>JavaScript</th><th>F#</th></tr><tr><td><pre>
if (a == 1)
  Console.WriteLine("1");
else
  Console.WriteLine("?");
</pre></td><td><pre>
if (a == 1)
  console.log("1");
else
  console.log("?");
</pre></td><td><pre>
if a = 1 then
  printfn "1"
else
  printfn "?"
</pre></td></tr></table></blockquote>

## ブロック

F#はインデントでブロックが構成されるので、C#のように複文での中括弧に相当するものはありません。

<blockquote><table><tr><th>C#</th><th>JavaScript</th><th>F#</th></tr><tr><td><pre>
if (a == 1)
{
  Console.WriteLine("1");
  Console.WriteLine("!");
}
</pre></td><td><pre>
if (a == 1) {
  console.log("1");
  console.log("!");
}
</pre></td><td><pre>
if a = 1 then
  printfn "1"
  printfn "!"
</pre></td></tr></table></blockquote>

## 三項演算子

F#の`if`はそのまま三項演算子としても使えます。（`if`は文ではなく式のため）

<blockquote><table><tr><th>C#</th><th>JavaScript</th><th>F#</th></tr><tr><td><pre>
var b = a == 1 ? 2 : 0;
</pre></td><td><pre>
let b = a == 1 ? 2 : 0;
</pre></td><td><pre>
let b = if a = 1 then 2 else 0
</pre></td></tr></table></blockquote>

## 複合技

F#では最後に評価された値が返されるため、処理と代入を混ぜることができます。これは慣れると便利な技です。

<blockquote><table><tr><th>C#</th><th>JavaScript</th><th>F#</th></tr><tr><td><pre>
int b;
if (a == 1)
{
  Console.WriteLine("1");
  b = 2;
}
else
{
  Console.WriteLine("?");
  b = 0;
}
</pre></td><td><pre>
let b;
if (a == 1) {
  console.log("1");
  b = 2;
} else {
  console.log("?");
  b = 0;
}
</pre></td><td><pre>
let b =
  if a = 1 then
    printfn "1"
    2
  else
    printfn "?"
    0
</pre></td></tr></table></blockquote>

## タプル

条件分岐の結果、複数の値を代入するような処理を一気に書けます。うまくハマるととても簡潔になります。

<blockquote><table><tr><th>C#</th><th>JavaScript</th><th>F#</th></tr><tr><td><pre>
int x, y;
if (a == 1)
{
  x = 1;
  y = 2;
}
else
{
  x = 3;
  y = 4;
}
</pre></td><td><pre>
let x, y;
if (a == 1) {
  x = 1;
  y = 2;
} else {
  x = 3;
  y = 4;
}
</pre></td><td><pre>
let x, y = if a = 1 then 1, 2 else 3, 4
</pre></td></tr></table></blockquote>

この構文が分かりにくければ、括弧を付けて考えると良いかもしれません。

```fsharp:F#
let (x, y) = if a = 1 then (1, 2) else (3, 4)
```

# 関数

説明の都合上、F#は冗長な構文から先に紹介します。

<blockquote><table><tr><th>C#</th><th>JavaScript</th><th>F#</th></tr><tr><td><pre>
class Test
{
  static int inc(int x)
  {
    return x + 1;
  }
  static int add(int x, int y)
  {
    return x + y;
  }
  static void Main()
  {
    Console.WriteLine(inc(1));
    Console.WriteLine(add(1, 2));
  }
}
</pre></td><td><pre>
function inc(x) {
  return x + 1;
}
function add(x, y) {
  return x + y;
}
console.log(inc(1));
console.log(add(1, 2));
</pre></td><td><pre>
let inc = fun x -> x + 1
let add = fun x y -> x + y
printfn "%d" (inc 1)
printfn "%d" (add 1 2)
</pre></td></tr></table></blockquote>

F#は変数の束縛と同じ構文で、関数が束縛されています。

```fsharp:F#（対比）
let inc = 0
let inc = fun x -> x + 1
```

右辺の `fun x -> x + 1` は左辺に束縛されて名前が付くことから、単体では名前が無く、無名関数などと呼ばれます。

## ラムダ式

F#の書き方は、C#のラムダ式やJavaScriptのアロー関数式に相当します。

<blockquote><table><tr><th>C#</th><th>JavaScript</th><th>F#</th></tr><tr><td><pre>
Func&#60;int, int> inc = x => x + 1;
Func&#60;int, int, int> add = (x, y) => x + y;
Console.WriteLine(inc(1));
Console.WriteLine(add(1, 2));
</pre></td><td><pre>
let inc = x => x + 1;
let add = (x, y) => x + y;
console.log(inc(1));
console.log(add(1, 2));
</pre></td><td><pre>
let inc = fun x -> x + 1
let add = fun x y -> x + y
printfn "%d" (inc 1)
printfn "%d" (add 1 2)
</pre></td></tr></table></blockquote>

C#の`Func`は冗長ですが、型推論が効かないため省略できません。

```csharp:C#
var inc = (int x) => x + 1;  // エラー
```

ちなみにVB.NETでは匿名デリゲート型に型推論されます。

```vbnet:VB.NET
Dim inc = Function(x%) x + 1
```

※ C#では引数や戻り値の型が同じデリゲート間でもキャストできませんが、VB.NETではできることから、匿名デリゲート型に割り当てても問題がないという判断だと思われます。

## 糖衣構文

`fun`を省略して引数を左辺に記述できます。通常はこちらを使います。

<blockquote><table><tr><th>F# (funあり)</th><th>F# (funなし)</th></tr><tr><td><pre>
let inc = fun x -> x + 1
let add = fun x y -> x + y
</pre></td><td><pre>
let inc x = x + 1
let add x y = x + y
</pre></td></tr></table></blockquote>

`fun`なしの方が便利です。最初に見せなかったのは、関数が値と同じように束縛されていることを示したかったためです。

## fsi

F# Interactiveで色々な書き方を動作確認します。この手の簡単な確認にREPLは便利です。

<blockquote><table><tr><th>F# Interactive</th><th>JavaScript (Node.js)</th></tr><tr><td><pre>
let inc = fun x -> x + 1;;
inc 1;;
(inc 1);;
inc(1);;
(fun x -> x + 1) 1;;
</pre></td><td><pre>
inc = x => x + 1
inc(1)
(x => x + 1)(1)
</pre></td></tr></table></blockquote>

※ 最後の例は関数を束縛せずにインラインで使っています。`fun`を省略した構文では表現できません。

## unit

C#での`void`に相当するのが`unit`です。値としては`()`と表現します。

<blockquote><table><tr><th>C#</th><th>JavaScript</th><th>F#</th></tr><tr><td><pre>
void test1() {}
int test2() { return 1; }
</pre></td><td><pre>
function test1() {}
function test2() { return 1; }
</pre></td><td><pre>
let test1() = ()
let test2() = 1
</pre></td></tr></table></blockquote>

ラムダ式などで書いてみます。

<blockquote><table><tr><th>C#</th><th>JavaScript</th><th>F#</th></tr><tr><td><pre>
Action test1 = () => {};
Func&#60;int> test2 = () => 1;
</pre></td><td><pre>
let test1 = () => {};
let test2 = () => 1;
</pre></td><td><pre>
let test1 = fun () -> ()
let test2 = fun () -> 1
</pre></td></tr></table></blockquote>

変数（`test3`）と関数（`test4`）を比べてみます。

<blockquote><table><tr><th>C#</th><th>JavaScript</th><th>F#</th></tr><tr><td><pre>
int test3 = 0;
Func&#60;int> test4 = () => 0;
</pre></td><td><pre>
let test3 = 0;
let test4 = () => 0;
</pre></td><td><pre>
let test3 = 0
let test4() = 0
</pre></td></tr></table></blockquote>

## ignore

F#では関数の戻り値を捨てると警告されます。

<blockquote><table><tr><th>C#</th><th>JavaScript</th><th>F#</th></tr><tr><td><pre>
Func&#60;int> a = () => 1;
a();  // 警告なし
</pre></td><td><pre>
let a = () => 1;
a();  // 警告なし
</pre></td><td><pre>
let a() = 1
a()  // 警告
</pre></td></tr></table></blockquote>

警告を抑えるため、`ignore`関数で明示的に無視します。C言語で`void`にキャストする流儀に似ています。

<blockquote><table><tr><th>C言語</th><th>F#</th></tr><tr><td><pre>
int a() { return 1; }
void test() { (void)a(); }
</pre></td><td><pre>
let a() = 1
ignore(a())
</pre></td></tr></table></blockquote>

※ gccには戻り値を無視したときに警告する `__attribute__((warn_unused_result))` があります。

## パイプライン演算子

引数と関数を分離するパイプライン演算子というものがあります。ネストした引数の括弧を外してフラットに記述するのに使います。戻り値の警告を受けて`ignore`を追加するときに便利です。

<blockquote><table><tr><th>F#</th><th>F# (右向き)</th><th>F# (左向き)</th></tr><tr><td><pre>
ignore(a())
</pre></td><td><pre>
a() |> ignore
</pre></td><td><pre>
ignore &#60;| a()
</pre></td></tr></table></blockquote>

右向きのパイプライン演算子は、シェルのパイプのような感覚で関数の多重呼び出しに使えます。左向きはHaskellの`$`に似ていますが、連続して使うと`$`とは意味が変わるため（後述）、連続させるときは`<<`演算子による関数合成と併用します。

<blockquote><table><tr><th>F#</th><th>F# (右向き)</th><th>F# (左向き)</th></tr><tr><td><pre>
foo(bar(baz()))
</pre></td><td><pre>
() |> baz |> bar |> foo
</pre></td><td><pre>
foo &#60;&#60; bar &#60;&#60; baz &#60;| ()
</pre></td></tr></table></blockquote>

`<|`を連続して使用すると、複数の引数を個別に適用する意味となります。

```fsharp:F#
printfn "%d,%s" <| 5 <| "abc"
```

## 再帰関数

C#/JavaScriptでラムダ式を使わずに再帰で階乗を求めます。

<blockquote><table><tr><th>C#</th><th>JavaScript</th></tr><tr><td><pre>
class Test
{
  static int frac(int x)
  {
    return x &#60; 1 ? 1 : x * frac(x - 1);
  }
  static void Main()
  {
    Console.WriteLine(frac(5));
  }
}
</pre></td><td><pre>
function frac(x) {
  return x &#60; 1 ? 1 : x * frac(x - 1);
}
console.log(frac(5));
</pre></td></tr></table></blockquote>

これをラムダ式で書きます。C#では自分自身が参照できなくなるため、一度`null`で初期化するという小手先の技が必要となります。JavaScriptは参照が動的に処理されるため問題ありません。F#では自分自身を参照するために専用の`rec`キーワードが用意されています。

<blockquote><table><tr><th>C#</th><th>JavaScript</th><th>F#</th></tr><tr><td><pre>
Func&#60;int, int> frac = null;
frac = x =>
  x &#60; 1 ? 1 : x * frac(x - 1);
Console.WriteLine(frac(5));
</pre></td><td><pre>
let frac = x =>
  x &#60; 1 ? 1 : x * frac(x - 1);
console.log(frac(5));
</pre></td><td><pre>
let rec frac x =
  if x &#60; 1 then 1 else x * frac(x - 1)
printfn "%d" (frac 5)
</pre></td></tr></table></blockquote>

※ デフォルトで再帰可能になっていないのは、同名の変数で覆い隠すシャドウイングを考慮した言語設計のようです。F#の元になったOCamlについての記事を紹介します。

* [@camlspotter](https://twitter.com/camlspotter): [OCaml の let と let rec はなぜ別扱いになっているのか、決定版、もしくは OCaml 暦十何年だったか忘れたけど仕事で Haskell を一年使ってみた - Oh, you `re no (fun _ → more)](http://d.hatena.ne.jp/camlspotter/20110509/1304933919) 2011.05.09

## 前方参照

一般論として用語を解説します。

パーサは上から下にコードを読み進めます。進行方向に沿って下が「前方」と表現されます。

```text
     後方
1 aaaa↓
2 bbbb↓
3 cccc↓
     前方
```

前方で定義されている関数にアクセス（参照）することを「前方参照」と呼びます。下の例では`test()`が前方参照されています。

<blockquote><table><tr><th>C#</th><th>JavaScript</th></tr><tr><td><pre>
class Test
{
  static void Main()
  {
    test();  // 前方参照
  }
  static void test()
  {
    Console.WriteLine("abc");
  }
}
</pre></td><td><pre>
test();  // 前方参照

function test() {
  console.log("abc");
}
</pre></td></tr></table></blockquote>

※ 直感的には「上が前」のように感じられるので注意が必要です。C言語の前方宣言は呼び出し元から見て「前方にある宣言」ではなく、「前方参照を可能にするための宣言」という意味だと解釈できます。

F#は前方参照ができません。他の言語でもラムダ式だけで記述すると似たような状況になりますが、それと同じだと考えてください。

<blockquote><table><tr><th>C#</th><th>JavaScript</th><th>F#</th></tr><tr><td><pre>
test();  // エラー
Action test = () =>
  Console.WriteLine("abc");
</pre></td><td><pre>
test();  // エラー
let test = () =>
  console.log("abc");
</pre></td><td><pre>
test()  // エラー
let test() = printfn "abc"
</pre></td></tr></table></blockquote>

F#に前方宣言はありません。必ず後方（上）で定義する必要があります。

<blockquote><table><tr><th>C#</th><th>JavaScript</th><th>F#</th></tr><tr><td><pre>
Action test = () =>
  Console.WriteLine("abc");
test();  // OK
</pre></td><td><pre>
let test = () =>
  console.log("abc");
test()  // OK
</pre></td><td><pre>
let test() = printfn "abc"
test()  // OK
</pre></td></tr></table></blockquote>

これは強い制限のようにも感じられますが、コードを読んだり部分的に引用したりするときは、そこより上だけを見ておけば良いという利点があります。

## 相互再帰

前方宣言はありませんが、相互に再帰する場合は特別な構文があります。

F#では`rec`と`and`を使います。C#ではラムダ式を使わなければ特に問題はなく、JavaScriptでは動的に参照されるためアロー関数式でも特に意識する必要はありません。

<blockquote><table><tr><th>C#</th><th>JavaScript</th><th>F#</th></tr><tr><td><pre>
void test1() { test2(); }
void test2() { test1(); }
</pre></td><td><pre>
let test1 = () => test2();
let test2 = () => test1();
</pre></td><td><pre>
let rec test1() = test2()
and test2() = test1()
</pre></td></tr></table></blockquote>

どうしても相互再帰が避けられないケースはありますが、その場合はクラスタとしてひとまとめに定義することが必要です。離して定義することはできません。

## 関数内関数

C#ではクラス直下のメソッドと、メソッド内のラムダ式の書式が大きく異なります。

※ C# 7ではローカル関数という機能が追加され、この制限が緩和されます。

F#やJavaScriptでは関数の中でも関数が定義できます。

<blockquote><table><tr><th>C#</th><th>JavaScript</th><th>F#</th></tr><tr><td><pre>
class Test
{
  static int inc1(int x)
  {
    return x + 1;
  }
  static void test()
  {
    Func&#60;int, int> inc2 = x => x + 1;
    Console.WriteLine(inc1(1));
    Console.WriteLine(inc2(1));
  }
  static void Main()
  {
    test();
  }
}
</pre></td><td><pre>
function inc1(x) {
  return x + 1;
}
function test() {
  function inc2(x) {
    return x + 1;
  }
  console.log(inc1(1));
  console.log(inc2(1));
}
test();
</pre></td><td><pre>
let inc1 x = x + 1
let test() =
  let inc2 x = x + 1
  printfn "%d" (inc1 1)
  printfn "%d" (inc2 1)
test()
</pre></td></tr></table></blockquote>

# カリー化

関数型で必ず話題になるカリー化を説明します。

※ とりあえずF#を使うだけなら必須というわけではありません。分かりにくければ飛ばしても構いません。

必要に応じて次の記事を参照すると良いでしょう。

* [カリー化と部分適用（JavaScriptとHaskell）](http://qiita.com/7shi/items/a0143daac77a205e7962) 2014.10.15

## 糖衣構文

以下の3種類はすべて同じ意味です。

1. `let add = fun x -> fun y -> x + y`
2. `let add = fun x y -> x + y`
3. `let add x y = x + y`

2と3は1の糖衣構文です。1をC#/JavaScriptに翻訳して呼び出してみます。

<blockquote><table><tr><th>C#</th><th>JavaScript</th><th>F#</th></tr><tr><td><pre>
Func&#60;int, Func&#60;int, int>> add =
    x => y => x + y;
Console.WriteLine(add(1)(2));
</pre></td><td><pre>
let add = x => y => x + y;
console.log(add(1)(2));
</pre></td><td><pre>
let add = fun x -> fun y -> x + y
printfn "%d" (add 1 2)
</pre></td></tr></table></blockquote>

ラムダ式がネストしています。初見では分かりにくいですが、括弧を付けてみます。

<blockquote><table><tr><th>C#</th><th>JavaScript</th><th>F#</th></tr><tr><td><pre>
Func&#60;int, Func&#60;int, int>> add =
    x => (y => x + y);
Console.WriteLine(add(1)(2));
</pre></td><td><pre>
let add = x => (y => x + y);
console.log(add(1)(2));
</pre></td><td><pre>
let add = fun x -> (fun y -> x + y)
printfn "%d" (add 1 2)
</pre></td></tr></table></blockquote>

JavaScriptでは`function`で記述した方が分かりやすいかもしれません。

```js:JavaScript
let add = function(x) {
  return function(y) {
    return x + y;
  };
};
console.log(add(1)(2));
```

## 部分適用

C#/JavaScriptでは引数を1つずつ渡していますが（`add(1)(2)`）、引数を片方だけ渡すこともできます。こうして得られた中間的な関数に残りの引数を渡すと最終的な結果が得られます。

<blockquote><table><tr><th>C#</th><th>JavaScript</th><th>F#</th></tr><tr><td><pre>
var inc = add(1);
Console.WriteLine(inc(2));
</pre></td><td><pre>
let inc = add(1);
console.log(inc(2));
</pre></td><td><pre>
let inc = add 1
printfn "%d" (inc 2)
</pre></td></tr></table></blockquote>

このように引数を途中まで渡して関数を得ることを部分適用と呼びます。部分適用できるように関数の中に関数を入れる形式をカリー化と呼びます。

※ 部分適用が誤ってカリー化と呼ばれることがあるので注意が必要です。

F#では冒頭で挙げた1～3のすべてがカリー化された関数で部分適用できます。カリー化されない関数を定義するには、引数をコンマで区切りタプルとします。引数をタプルで取る関数でもラムダ式でラップすれば擬似的に部分適用は可能です。

<blockquote><table><tr><th>F# (カリー化)</th><th>F# (非カリー化)</th><th>C# (非カリー化)</th></tr><tr><td><pre>
let add x y = x + y
let inc = add 1
</pre></td><td><pre>
let add(x, y) = x + y
let inc = fun y -> add(1, y)
</pre></td><td><pre>
Func&#60;int, int, int> add = (x, y) => x + y;
Func&#60;int, int> inc = y => add(1, y);
</pre></td></tr></table></blockquote>

最初の方で.NETのメソッドの呼び方がネイティブ関数とは異なると述べましたが、引数がタプルとして扱われカリー化されていないためです。

# 配列

C#ではサイズを指定して配列を作るとゼロで初期化されます。JavaScriptではTypedArrayで同様の処理が可能です。F#では専用の関数を使用します。

<blockquote><table><tr><th>C#</th><th>JavaScript</th><th>F#</th></tr><tr><td><pre>
var a = new int[5];
</pre></td><td><pre>
let a = new Int32Array(5);
</pre></td><td><pre>
let a = Array.zeroCreate&#60;int> 5
</pre></td></tr></table></blockquote>

初期値を指定して配列を作成する方法を示します。F#では要素の区切りはセミコロンなのに注意が必要です（コンマ区切りはタプルを意味するため）。また、F#では配列アクセスで添字の前にドットが必要です。

<blockquote><table><tr><th>C#</th><th>JavaScript</th><th>F#</th></tr><tr><td><pre>
var a = new[] {1, 2, 3, 4};
Console.WriteLine(a[2]);
</pre></td><td><pre>
var a = [1, 2, 3, 4];
console.log(a[2]);
</pre></td><td><pre>
let a = [|1; 2; 3; 4|]
printfn "%d" a.[2]
</pre></td></tr></table></blockquote>

F#では配列をスライスできます。末尾の指定方法がJavaScriptとF#では異なるのに注意します。C#では言語サポートがないため地道にコピーします。

<blockquote><table><tr><th>C#</th><th>JavaScript</th><th>F#</th></tr><tr><td><pre>
var b = new int[2];
Array.Copy(a, 2, b, 0, 2);
</pre></td><td><pre>
let b = a.slice(2, 4);
</pre>※ 4は末尾の添字+1</td><td><pre>
let b = a.[2..3]
</pre>※ 3は末尾の添字</td></tr></table></blockquote>

JavaScriptとF#は文字列の切り出にもスライスが使用可能です。

<blockquote><table><tr><th>C#</th><th>JavaScript</th><th>F#</th></tr><tr><td><pre>
"abcde".Substring(2, 2);
</pre></td><td><pre>
"abcde".slice(2, 4);
</pre></td><td><pre>
"abcde".[2..3]
</pre></td></tr></table></blockquote>

# ループ

F#には`while`と`for`はありますが、`continue`と`break`はありません。再帰で書き直す方法を覚えておくと潰しが効きます。考え方としてはループ変数を引数に見立てて、条件を満たせば再帰的に自分を呼び出します。

<blockquote><table><tr><th>C#</th><th>JavaScript</th><th>F#</th></tr><tr><td><pre>
var r = new Random();
for (int i = 0; i &#60; 10; i++)
{
  var v = r.Next(10);
  Console.WriteLine(v);
  if (v > 5) break;
}
</pre></td><td><pre>
for (let i = 0; i &#60; 10; i++) {
  let v = (Math.random() * 10) | 0;
  console.log(v);
  if (v > 5) break;
}
</pre></td><td><pre>
let r = new Random()
let rec loop i =
  if i &#60; 10 then
    let v = r.Next(10)
    printfn "%d" v
    if not(v > 5) then
      loop (i + 1)
loop 0
</pre></td></tr></table></blockquote>

※ 再帰呼び出しは`continue`に相当して、明示的に`continue`を書かないとループから抜けてしまうと解釈できます。ただし`continue`と違って後続の処理が打ち切られるわけではないため、再帰呼び出しの後に処理が来ないように注意する必要があります。後に処理が来ない再帰を**末尾再帰**と呼びます。

再帰を使わずに`while`で無理やり実装することもできます。うまく書けないときはこの手で逃げることがあるかもしれません。

<blockquote><table><tr><th>C#</th><th>JavaScript</th><th>F#</th></tr><tr><td><pre>
var r = new Random();
int i = 0, v = 0;
while (i &#60; 10 && !(v > 5))
{
  v = r.Next(10);
  Console.WriteLine(v);
  i++;
}
</pre></td><td><pre>
let i = 0, v = 0;
while (i &#60; 10 && !(v > 5)) {
  v = (Math.random() * 10) | 0;
  console.log(v);
  i++;
}
</pre></td><td><pre>
let r = new Random()
let mutable i, v = 0, 0
while i &#60; 10 && not(v > 5) do
  v &#60;- r.Next(10)
  printfn "%d" v
  i &#60;- i + 1
</pre></td></tr></table></blockquote>

※ この記事では取り上げませんが、F#にはループの代用となる様々な関数が用意されており、本来そちらを使うことが推奨されます。しかしそういったものがうまく適用できないときは、最終手段としてここで説明したような方法でどうにかすることもあるでしょう。

## 複雑な例

標準入力から文字列を読み取り、先頭から連続する数字だけを抜き出して表示する例を示します。C#では代入した値をそのまま評価できますが、F#ではできないため工夫が必要です。JavaScriptはNode.jsで示します。

```csharp:C#
string line;
while ((line = Console.ReadLine()) != null)
{
  int i;
  for (i = 0; i < line.Length; i++)
    if (!Char.IsNumber(line[i])) break;
  Console.WriteLine(line.Substring(0, i));
}
```
```js:JavaScript(Node.js)
let isDigit = ch => "0" <= ch && ch <= "9";

let loop = function*() {
  let line;
  while ((line = yield) != null) {
    let i;
    for (i = 0; i < line.length; i++)
      if (!isDigit(line[i])) break;
    console.log(line.slice(0, i));
  }
}();
loop.next();

let rl = require("readline").createInterface(
  process.stdin, process.stdout, null);
rl.on("line", line => loop.next(line));
rl.on("close", () => loop.next(null));
```
```fsharp:F#
let rec loop() =
  let line = Console.ReadLine()
  if line <> null then
    let rec loop2 i =
      if i < line.Length && Char.IsNumber(line.[i]) then
        loop2 (i + 1)
      else
        line.[0 .. i - 1]
    printfn "%s" (loop2 0)
    loop()
loop()
```

※ Windowsで標準入力読み切り型プログラムを終了させるには [Ctrl]+[Z] [Enter] と操作しますが、Node.jsでは [Ctrl]+[D] です。

Node.jsでの標準入力の扱いは次の記事を参考にしました。

* [Node.jsの標準入力と](http://qiita.com/hiroqn@github/items/c927bc97780c34eda562) 2013.10.03

# 参照

F#では`mutable`の親戚のような参照という型があります。参照は`ref`というキーワードを指定するとその場でインスタンスが作られます。

※ C#で引数を参照で渡すための`ref`とは別物です。

値へのアクセスはプロパティによる方法と演算子による方法があります。演算子の方がよく使われます。`!` は参照剥がし（デリファレンス）演算子で、C#の否定演算子とは無関係です。参照への代入は `:=` です。

<blockquote><table><tr><th>C#</th><th>F# (mutable)</th><th>F# (参照・プロパティ)</th><th>F# (参照・演算子)</th></tr><tr><td><pre>
int a = 1;
Console.WriteLine(a);
a = 2;
Console.WriteLine(a);
</pre></td><td><pre>
let mutable a = 1
printfn "%d" a
a &#60;- 2
printfn "%d" a
</pre></td><td><pre>
let b = ref 1
printfn "%d" b.Value
b.Value &#60;- 2
printfn "%d" b.Value
</pre></td><td><pre>
let b = ref 1
printfn "%d" !b
b := 2
printfn "%d" !b
</pre></td></tr></table></blockquote>

C#よりもC++で説明した方が分かりやすいかもしれません。比較の都合上、C++は参照ではなくポインタで示します。C#でもポインタは使えますが、1要素の配列で表現する方が簡単なのでその方法で示します。

<blockquote><table><tr><th>C++</th><th>C#</th><th>JavaScript</th><th>F#</th></tr><tr><td><pre>
int *b = new int(1);
printf("%d\n", *b);
*b = 2;
printf("%d\n", *b);
</pre></td><td><pre>
int[] b = new[] {1};
Console.WriteLine(b[0]);
b[0] = 2;
Console.WriteLine(b[0]);
</pre></td><td><pre>
let b = [1];
console.log(b[0]);
b[0] = 2;
console.log(b[0]);
</pre></td><td><pre>
let b = ref 1
printfn "%d" !b
b := 2
printfn "%d" !b
</pre></td></tr></table></blockquote>

※ C++でも `*b = 2;` は `b[0] = 2;` に書き換えられます。

# クロージャ

関数内関数から外のローカル変数にアクセスできます。これをレキシカルスコープと呼んで、変数への参照をキャプチャと表現します。キャプチャを伴った関数をクロージャと呼びます。

<blockquote><table><tr><th>C#</th><th>JavaScript</th><th>F#</th></tr><tr><td><pre>
Action test1 = () => {
  var i = 0;
  Action test2 = () =>
    Console.WriteLine(i);
  test2();
};
</pre></td><td><pre>
let test1 = () => {
  let i = 0;
  let test2 = () =>
    console.log(i);
  test2();
};
</pre></td><td><pre>
let test1() =
  let i = 0
  let test2() =
    printfn "%d" i
  test2()
</pre></td></tr></table></blockquote>

上の例ではC#やJavaScriptでは値が変更可能な変数をキャプチャしていますが、F#では`mutable`な変数はキャプチャできません。Javaでもラムダ式（匿名クラス）から`final`を指定した変数しか参照できないのと似ています。

※ Java 8では初期化以外で値を触らなければ事実上の`final`としてコンパイルが通ります。下のコードでは意図的に`i`の値を変更しています。

<blockquote><table><tr><th>F#</th><th>Java 8</th></tr><tr><td><pre>
let test1() =
  let mutable i = 0
  let test2() =
    printfn "%d" i  // エラー
  i &#60;- 1
  test2()
</pre></td><td><pre>
void test1() {
  int i = 0;
  Runnable test2 = () ->
    System.out.println(i);  // エラー
  i = 1;
  test2.run();
}
</pre></td></tr></table></blockquote>

F#では参照で回避します。Javaでは`final`を付け、中身を変更可能にするため配列で包む回避策があります。

<blockquote><table><tr><th>F#</th><th>Java 8</th></tr><tr><td><pre>
let test1() =
  let i = ref 0
  let test2() =
    printfn "%d" !i
  i := 1
  test2()
</pre></td><td><pre>
void test1() {
  final int i[] = {0};
  Runnable test2 = () ->
    System.out.println(i[0]);
  i[0] = 1;
  test2.run();
}
</pre></td></tr></table></blockquote>

## 理由

ローカルの`mutable`変数はスタックに確保されるのに対し、参照の実体はヒープに確保されます。スタックに確保された変数はスコープアウト時に破棄されます。しかしクロージャにキャプチャされた変数の寿命はスコープに縛られないため、参照によりヒープに確保して解放はGCに任せることで、スコープアウト問題を回避しています。

C#ではキャプチャされる変数はコンパイラが自動的に扱い方を変えるためこの制限がありません。F#では敢えてエラーにしていると思われます。

# クラス

F#とC#で構文がかなり違いますが、`protected`や入れ子にされた型がない以外はほぼ同じことが表現できます。JavaScriptは色々な書き方ができますが、ここではF#との対比の都合上`class`を使わない古い書き方で示します。

<blockquote><table><tr><th>C#</th><th>JavaScript</th><th>F#</th></tr><tr><td><pre>
class Num
{
  private int num = 0;
  public void Next()
  {
    Console.WriteLine(++num);
  }
}
class Test
{
  static void Main()
  {
    var n = new Num();
    for (int i = 0; i < 5; i++)
      n.Next();
  }
}
</pre></td><td><pre>
function Num() {
  this.num = 0;
  this.Next = function() {
    console.log(++this.num);
  };
}
let n = new Num();
for (let i = 0; i < 5; i++)
  n.Next();
</pre></td><td><pre>
type Num() =
  let mutable num = 0
  member this.Next() =
    num &#60;- num + 1
    printfn "%d" num
let n = Num()
for i = 0 to 4 do
  n.Next()
</pre></td></tr></table></blockquote>

※ JavaScriptは`function`とアロー記法では`this`の扱いが異なります。メソッド内で`this`を使う場合は`function`を使用します。

F#でアクセス制御を省略したときのデフォルトは、`let`が`private`、`member`が`public`となります。`type`名の後の`()`はコンストラクタの引数を表しています。JavaScriptは関数の引数がそのままコンストラクタの引数として使われていて、F#と書き方が似ていることに注目してください。

F#ではインスタンス生成に`new`は不要です。`IDisposable`を実装したクラスでは`new`を付けないと警告されますが、それ以外では`new`を付けると警告されます。

※ `IDisposable`かどうか毎回調べると面倒なので、個人的にはデフォルトで省略して、警告されたら付けるという運用をしています。

## コンストラクタ

コンストラクタで引数を処理する例を示します。JavaScriptで引数をそのままキャプチャしているのに注目してください（`this`を使用しないためアロー記法）。

<blockquote><table><tr><th>C#</th><th>JavaScript</th><th>F#</th></tr><tr><td><pre>
class Num
{
  private int num = 0;
  public Num(int n)
  {
    num = n;
  }
  public void Next()
  {
    Console.WriteLine(++num);
  }
}
class Test
{
  static void Main()
  {
    var n = new Num(5);
    for (int i = 0; i < 5; i++)
      n.Next();
  }
}
</pre></td><td><pre>
function Num(num) {
  this.Next = () =>
    console.log(++num);
}
let n = new Num(5);
for (let i = 0; i < 5; i++)
  n.Next();
</pre></td><td><pre>
type Num(n) =
  let mutable num = n
  member this.Next() =
    num &#60;- num + 1
    printfn "%d" num
let n = Num 5
for i = 0 to 4 do
    n.Next()
</pre></td></tr></table></blockquote>

## クロージャと比較

クロージャをクラスの代わりに使って比較してみます。F#は一旦参照で受けるため冗長になっていますが、C#やJavaScriptはその必要がないため単純です。JavaScriptとF#はクラスの書き方とよく似ているのに注目してください。

<blockquote><table><tr><th>C#</th><th>JavaScript</th><th>F#</th></tr><tr><td><pre>
Func&#60;int, Action> Num = num =>
  () => Console.WriteLine(++num);
var next = Num(5);
for (int i = 0; i < 5; i++)
  next();
</pre></td><td><pre>
function Num(num) {
  return () =>
    console.log(++num);
}
let next = Num(5);
for (let i = 0; i < 5; i++)
  next();
</pre></td><td><pre>
let Num(n) =
  let num = ref n
  fun () ->
    num := !num + 1
    printfn "%d" !num
let next = Num 5
for i = 0 to 4 do
  next()
</pre></td></tr></table></blockquote>

# 多態

## サブクラスによるオーバーライド

数字と足し算のAST（抽象構文木）の例を示します。JavaScriptは継承ではなくダックタイピングで実装します。

```csharp:C#
abstract class Val
{
  public abstract int Value { get; }
}
class Num : Val
{
  private int num;
  public Num(int n) { num = n; }
  public override int Value { get { return num; } }
}
class Add : Val
{
  private Val a, b;
  public Add(Val a, Val b) {
    this.a = a;
    this.b = b;
  }
  public override int Value
  {
    get { return a.Value + b.Value; }
  }
}
class Test
{
  static void Main() {
    var expr = new Add(new Num(2), new Num(3));
    Console.WriteLine(expr.Value);
  }
}
```
```js:JavaScript
function Num(num) {
  Object.defineProperty(this, "Value", {
    get: () => num
  });
}
function Add(a, b) {
  Object.defineProperty(this, "Value", {
    get: () => a.Value + b.Value
  });
}
let expr = new Add(new Num(2), new Num(3));
console.log(expr.Value);
```
```fsharp:F#
[<AbstractClass>]
type Val() =
  abstract Value: int
type Num(num) =
  inherit Val()
  override this.Value = num
type Add(a: Val, b: Val) =
  inherit Val()
  override this.Value = a.Value + b.Value
let expr = Add(Num 2, Num 3)
printfn "%d" expr.Value
```

## 判別共用体

F#には多態を簡潔に表現する判別共用体というものがあります。クラスごとの評価関数を個別にオーバーライドするのではなく、一箇所にまとめて書くスタイルです。

```fsharp:F#
type Val =
| Num of int
| Add of Val * Val

let rec eval = function
| Num(num) -> num
| Add(a, b) -> eval a + eval b

let expr = Add(Num 2, Num 3)
printfn "%d" (eval expr)
```

判別共用体がうまくハマるパターンではものすごく簡潔になります。

JavaScriptで雰囲気を真似た例を示します。C#では冗長になるため省略します。

```js:JavaScript
function Num(num) {
  this.num = num;
}
function Add(a, b) {
  this.a = a;
  this.b = b;
}
function eval(v) {
  if (v instanceof Num)
    return v.num;
  if (v instanceof Add)
    return eval(v.a) + eval(v.b);
}
let expr = new Add(new Num(2), new Num(3));
console.log(eval(expr));
```

# 資料

今回と同じような視点の記事を紹介します。

この記事の元になった記事です。C#的なオブジェクト指向構文を中心にまとめています。

* [C#プログラマのためのF#入門](http://d.hatena.ne.jp/n7shi/20090722) 2009.07.22

限定された範囲内でC#をF#に変換するトランスレータです。JavaScriptで実装されているため、ブラウザ上で動きます。

* [C# to F# translator](http://7shi.bitbucket.org/cs2fs/) 2015.08.01

C#とF#との対比記事です。引用されているF# Tutorialはプロジェクト作成のときに選択できます。

* [@neuecc](https://twitter.com/neuecc): [F# TutorialをC#と比較しながらでF#を学ぶ](http://neue.cc/2009/11/09_214.html) 2009.11.09
