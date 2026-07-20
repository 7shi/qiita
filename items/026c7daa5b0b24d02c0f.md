---
coediting: false
comments_count: 0
created_at: '2016-07-03T00:46:58+09:00'
id: 026c7daa5b0b24d02c0f
likes_count: 21
private: false
reactions_count: 0
stocks_count: 16
tags:
- name: Haskell
  versions: []
- name: F#
  versions: []
title: コンピュテーション式でモナドを作ってみる
updated_at: '2020-02-11T05:58:36+09:00'
url: https://qiita.com/7shi/items/026c7daa5b0b24d02c0f
slide: false
---

コンピュテーション式の練習として、いくつかモナドを作ってみました。`Bind`と`Return`だけで何ができるのかをイメージするのが目的です。

モナドやHaskellは前提知識とはしません。モナドを理解していなくても動きを追うことは可能です。最初にHaskellで例を示しますが、すぐ対応するF#を示すので推測できるはずです。

この記事は次の続編です。

* [doブロックとコンピュテーション式](http://qiita.com/7shi/items/92139286a4e9b5620d69) 2016.07.01

今回扱うモナドの詳細は以下を参照してください。

* [モナド則がちょっと分かった？](http://qiita.com/7shi/items/547b6137d7a3c482fe68) 2014.12.01
* [Haskell 状態系モナド 超入門](http://qiita.com/7shi/items/2e9bff5d88302de1a9e9) 2014.12.27
* [Haskell Maybeモナド 超入門](http://qiita.com/7shi/items/c7d7eec066af0fe0688d) 2015.01.22
* [Haskell リストモナド 超入門](http://qiita.com/7shi/items/deb19c4cba933590ffbf) 2014.12.19

他の言語でも似たようなことをした記事です。

* [ジェネレーターで関数モナドとStateモナドを模倣してみた](https://qiita.com/7shi/items/e5365885fb53c015630c)
* [Pythonでもジェネレーターで関数モナドとStateモナドを模倣してみた](https://qiita.com/7shi/items/b3aba035c45868ab34e9)

# モナド

※ この節の説明は前提知識がないと意味不明だと思います。先に実例に触れて振り返るときの指針として言及しているだけなので、適当に受け流して先に進んでください。

`return`と`>>=`(bind)で操作できてモナド則を満たすものをモナドと呼びます。

## モナド則

モナド則は`return`と`>>=`の動きに関するルールです。

1. `return x >>= f` == `f x`
2. `m >>= return` == `m`
3. `(m >>= f) >>= g` == `m >>= (\x -> f x >>= g)`

いきなり見ても理解できる代物ではないので、あまり気にしなくても構いません。一応、読み方を説明しておきます。

* 各モナド則は式を == で区切り、左辺と右辺が等しいかを見ます。
* 等しくなるものがモナドだ、というルールです。
* 等しくならないものは作れますが、それはモナドではありません。

これで何ができるかは一意に決まるようなものではありません。色々できるとしか言いようがありません。紙と鉛筆で何ができるかと言われて「文章が書ける、計算ができる、絵が描ける」と答えるようなものです。それに相当する具体例として何種類かのモナドを示します。

1. 関数モナド
2. Stateモナド
3. リストモナド
4. Maybeモナド

※ 個々のモナドが何らかの抽象的な原理（モナドの本質？圏論？）から導出されたと捉えない方が良いです。わけがわからなくなります。`return`と`>>=`は紙と鉛筆みたいなもので、その組み合わせでうまくいくものがいくつか発見されている、くらいに考えるのが良いでしょう。

## オペランド

`>>=`のオペランドはモナド則3にも表れているように`m >>= f`と書くことが多いです。`m`はモナド、`f`は関数を表します。

媒介変数`x`で表したものと比較してみます。

```hs:Haskell
test1 = m >>= f
test2 = do
    x <- m
    f x
test3 = m >>= \x -> f x
```

`test1` と `test2` と `test3` はすべて同じ動作を表します。

`test2` では `m` から取り出した値を `x` に束縛して、`x` を `f` に引数として渡しています。実態としては `x` への束縛は関数の引数として表現されており、それを明示したのが `test3` です。ラムダ式で受け取った `x` をそのまま `f` に取り回しているだけなので `f` 単体と等価となり `test1` に戻ります。

## コンピュテーション式

コンピュテーション式はモナドを実装することも考慮されていますが、モナド専用というわけではありません。意図的にモナド則を満たさない「モナドもどき」を作ることは可能で、今回は扱いませんがそれも場合によっては有用かもしれません。

【追記 2016.07.04】モナドもどきを作ってみた例です。

* [試作したコンピュテーション式と関数モナド](http://qiita.com/7shi/items/6635d6bea5c455cbb4da) 2016.07.04

# 作業手順

作業手順をパターン化します。

1. Haskellの例
2. `do`を剥がす
3. `return`を実装
4. 1段で`>>=`を実装
5. 多段対応
6. ビルダーを実装

# 関数モナド

渡した引数を補って計算するモナドです。

`m >>= f`の`m`の部分に関数が来ます。これは関数をモナドとして扱っているという意味合いで「関数モナド」です。

## 1. Haskellの例

まずお手本としてHaskellを見ます。

```hs:Haskell
test = do
    a <- (+ 1)
    b <- (* 2)
    return (a, b)

main = do
    print (test 3)
    print (test 5)
```
```text:実行結果
(4,6)
(6,10)
```

## 2. doを剥がす

`test`から`do`を剥がします。

```hs:Haskell
test =
    (+ 1) >>= \a ->
    (* 2) >>= \b ->
    return (a, b)
```

ラムダ式のネストが分かりにくいため、括弧とネストを付けたものを示します。

```hs:Haskell
test =
    (+ 1) >>= (\a ->
        (* 2) >>= (\b ->
            return (a, b)))
```

後ろがどんどん深くなっています。ただ、実際に考えるときは最初に示したようなフラットにイメージしておいた方が混乱が少ないです。ラムダ式の範囲を意識する必要があれば変形して確認すれば良いです。

## 3. returnを実装

渡された引数を無視して指定した値を返す関数を返します。

これをF#で実装します。予約語との衝突を避けるため`ret`とします。

```fsharp:F#
let ret x = fun _ -> x

let test = ret 8

do
    printfn "%A" (test 3)
    printfn "%A" (test 5)
```
```text:実行結果
8
8
```

`test`に渡された引数を無視しています。

`let ret x _ = x` と書いても動作は同じです（カリー化）。今回は `ret` の引数は1つで関数を返すという意図を表すため、右辺に `fun` を明示的に書きました。

## 4. 1段で>>=を実装

いきなり多段を考えると混乱するので、まずは1段で考えます。

```hs:Haskell
test = (+ 1) >>= return

main = do
    print (test 3)
    print (test 5)
```
```text:実行結果
4
6
```

`m >>= f`全体で1引数の関数が構成されます。`test`に引数を渡して評価できるのはそのためです。

これをF#で実装します。

```fsharp:F#
let ret   x   = fun _ -> x
let (>>=) m f = fun x -> f (m x) ()

let test = (fun x -> x + 1) >>= ret

do
    printfn "%A" (test 3)
    printfn "%A" (test 5)
```
```text:実行結果
4
6
```

`f (m x)`だけではなく、その後で更に`()`を渡しているのがしっくり来ないかもしれません。

※ `()`を渡すことには問題がありますが、今の段階では分からないことなので、後で検証します。

`ret` をインライン展開して考えます。

```fsharp:F#
let test = (fun x -> x + 1) >>= (fun x -> (fun _ -> x))
```

`>>=` で左右に区切って考えます。左辺の `fun x -> x + 1` を評価した値が右辺に渡されます。それが引数として `x` に束縛されて `fun _ -> x` が返されます。これに `()` を渡せば `x` が取り出せます。

`>>=` の実装と見比べれば、以下のステップで評価が進むことが分かります。

1. `(m x)` 左辺を評価
2. `f (m x)` 戻り値を右辺に渡して、引数へ束縛
3. `f (m x) ()` 返された関数を評価

右辺が `ret` であれば値から関数を返すので、`(m x)` を渡すだけでは関数が返って来ます。そのため更に引数を渡して関数を評価しているわけです。`ret` に渡される引数は無視されるので適当に `()` を渡しています。

`f` への1番目の引数が値の束縛、2番目の引数が次の式の評価に使われます。

※ モナド則2により `let test = fun x -> x + 1` と単純化されます。これはつまり `let test x = x + 1` ということです。

## 5. 多段対応

元の例に適用するとエラーになります。

```fsharp:F#
let ret   x   = fun _ -> x
let (>>=) m f = fun x -> f (m x) ()

let test =
    (fun x -> x + 1) >>= fun a ->
    (fun x -> x * 2) >>= fun b ->
    ret (a, b)

do
    printfn "%A" (test 3)
    printfn "%A" (test 5)
```
```text:エラー内容
Test.fsx(6,19): error FS0001: The type 'int' does not match the type 'unit'
Test.fsx(6,17): error FS0043: The type 'int' does not match the type 'unit'
Test.fsx(10,19): error FS0039: The value or constructor 'test' is not defined
Test.fsx(11,19): error FS0039: The value or constructor 'test' is not defined
```

最初のエラーに注目します。`(fun x -> x * 2)`の`x`に`()`が渡されるため、`x * 2`の計算ができずにエラーになっています。

### 構造を単純化して考える

具体的なコードだと分かりにくいので、構造を単純化して1段と2段を比較します。

1. `m >>= ret`
2. `m1 >>= (fun x -> (m2 >>= ret))`

1の`return`に相当する部分が、2では`(fun x -> (m2 >>= ret))`となっています。`f (m x) ()` で渡される`()`が1と2でどのように扱われているかを比較します。

1では `m` を評価した値が `ret` に渡されて、`ret` 内部で作られた関数 `fun _ -> x` が返されます。それに対して `()` を渡しても捨てられるため問題化しません。

2では `m1` を評価した値が `(fun x -> (m2 >>= ret))` に渡されて、`->` の右に記述された式 `m2 >>= ret` が返されます。`m2 >>= ret` は何か値を与えると計算する関数になるため、計算できない値 `()` を渡すとエラーになります。`m2 >>= ret` にも外部から渡された引数をそのまま渡す必要があります。

以上より`>>=`を次のように修正すれば良いことが分かります。

```fsharp:F#（修正箇所）
let (>>=) m f = fun x -> f (m x) x
```

### 例に戻る

修正を元の例に適用してみます。

```fsharp:F#
let ret   x   = fun _ -> x
let (>>=) m f = fun x -> f (m x) x

let test =
    (fun x -> x + 1) >>= fun a ->
    (fun x -> x * 2) >>= fun b ->
    ret (a, b)

do
    printfn "%A" (test 3)
    printfn "%A" (test 5)
```
```text:実行結果
(4, 6)
(6, 10)
```

うまく動きました。

`f (m x) x` の最後の `x` は、`>>=` で連結された次の式に回されるのに使われます。階層構造ではなくフラットに捉えて、最初の `>>=` から次の `>>=` へのバトンだとイメージするのが良いでしょう。

## 6. ビルダーを実装

ビルダーを実装すれば、コンピュテーション式が使えるようになります。

```fsharp:F#
let ret   x   = fun _ -> x
let (>>=) m f = fun x -> f (m x) x

type FuncBuilder() =
    member __.Return(x)  = ret x
    member __.Bind(m, f) = m >>= f
let func = FuncBuilder()

let test = func {
    let! a = fun x -> x + 1
    let! b = fun x -> x * 2
    return (a, b) }

do
    printfn "%A" (test 3)
    printfn "%A" (test 5)
```
```text:実行結果
(4, 6)
(6, 10)
```

今まで作って来た`>>=`と`ret`との関係を示すためビルダーから使っていますが、いきなりビルダーで実装しても構いません。

```fsharp:F#
type FuncBuilder() =
    member __.Return(x)  = fun _ -> x
    member __.Bind(m, f) = fun x -> f (m x) x
let func = FuncBuilder()
```

# Stateモナド

関数モナドでは外部から渡された値は変化せずにバトンとして渡されましたが、それを変化させることを考えます。以後、通例に従って「バトン」ではなく「状態」と呼びます。

## 1. Haskellの例

```hs:Haskell
import Control.Monad.State

test = do
    a <- get
    put (a * 2)
    b <- get
    return (a, b)

main = do
    print (evalState test 3)
    print (evalState test 5)
```
```text:実行結果
(3,6)
(5,10)
```

関数モナドは`test`に直接値を渡せば評価できましたが、Stateモナドでは`evalState`の力を借りています。

`get`は状態を取得するアクションです。状態は`put`によって書き替えることが可能です。

## 2. doを剥がす

```hs:Haskell
test =
    get         >>= \a ->
    put (a * 2) >>= \_ ->
    get         >>= \b ->
    return (a, b)
```

`<-`を書かない行は形式的に`_`に渡して捨てます。それ専用の`>>`という演算子もありますが、`>>=`で統一的に記述するため今回は使用しません。

※ コンピュテーション式では`do!`と書きます。後で使います。

## 3. returnを実装

形式上`evalState`を経由してはいますが、まだ関数モナドと同じです。

```fsharp:F#
let evalState m = m

let ret x = fun _ -> x

let test = ret 8

do
    printfn "%A" (evalState test 3)
    printfn "%A" (evalState test 5)
```
```text:実行結果
8
8
```

## 4. 1段で>>=を実装

まず`get`を確認します。まだ関数モナドと同じです。

```fsharp:F#
let evalState m = m
let get = id

let ret   x   = fun _ -> x
let (>>=) m f = fun x -> f (m x) x

let test = get >>= ret

do
    printfn "%A" (evalState test 3)
    printfn "%A" (evalState test 5)
```
```text:実行結果
3
5
```

## 5. 多段対応

`put`を混ぜてみます。

```fsharp:F#
let ret   x   = fun _ -> x
let (>>=) m f = fun x -> f (m x) x

let evalState m = m
let get = id
let put = ret

let test =
    get         >>= fun a ->
    put (a * 2) >>= fun _ ->
    get         >>= fun b ->
    ret (a, b)

do
    printfn "%A" (evalState test 3)
    printfn "%A" (evalState test 5)
```
```text:実行結果
(3, 3)
(5, 5)
```

`put`がうまく機能していません。

### 修正

次の`>>=`に渡される状態が元のままになっているため、`(m x)`の戻り値を使います。

```fsharp:F#（修正箇所）
let (>>=) m f = fun x ->
    let y = m x
    f y y
```
```text:実行結果
(3, 6)
(5, 10)
```

うまく動きました。

## 値と状態の分離

実はまだStateモナドとしては不完全です。

Haskellでは次のようなことが可能です。

```hs:Haskell
import Control.Monad.State

postInc = do
    x <- get
    put (x + 1)
    return x

test2 = do
    a <- postInc
    b <- postInc
    return (a, b)

main = do
    print (evalState test2 3)
    print (evalState test2 5)
```
```text:実行結果
(3,4)
(5,6)
```

`postInc`で状態を更新しますが、`return`されるのは更新前の値です。

※ C言語などの `i++` をイメージしています。

### `do`を剥がす

```hs:Haskell
postInc =
    get         >>= \x ->
    put (x + 1) >>= \_ ->
    return x

test2 =
    postInc >>= \a ->
    postInc >>= \b ->
    return (a, b)
```

### 不具合

これをF#で試すとうまく動きません。

```fsharp:F#
let ret   x   = fun _ -> x
let (>>=) m f = fun x ->
    let y = m x
    f y y

let evalState m = m
let get = id
let put = ret

let postInc =
    get         >>= fun x ->
    put (x + 1) >>= fun _ ->
    ret x

let test2 =
    postInc >>= fun a ->
    postInc >>= fun b ->
    ret (a, b)

do
    printfn "%A" (evalState test2 3)
    printfn "%A" (evalState test2 5)
```
```text:実行結果
(3, 3)
(5, 5)
```

値と状態を分離していないため、`postInc` から返された値がそのまま状態として使われてしまい、インクリメントが打ち消されています。

### 修正

値と状態を分離して、タプルで受け渡すようにします。変更は以下のコードに押し込められるため、それを利用するコードは修正不要です。（外から見えるインターフェースに影響がないという意味です）

```fsharp:F#（修正箇所）
let ret   x   = fun s -> (x, s)
let (>>=) m f = fun s ->
    let (x, s') = m s
    f x s'

let evalState m s = fst (m s)
let get   = fun s -> (s , s)
let put s = fun _ -> ((), s)
```
```text:実行結果
(3, 4)
(5, 6)
```

Haskellと同じ動きをするようになりました。

`evalState`以外の修正箇所では状態を受け取って値と状態のタプルを返しています。

* `状態 -> (値, 状態)`

`evalState`ではタプルから値だけを返しています。

関数モナドでは`s`に相当する部分が不変だったため、このように分離して管理する必要がありませんでした。

## 6. ビルダーを実装

`put`では返される値`()`を捨てています。Haskellでは何も書かないと自動的に値が捨てられますが、F#では`do!`で明示します。

```fsharp:F#
let ret   x   = fun s -> (x, s)
let (>>=) m f = fun s ->
    let (x, s') = m s
    f x s'

type StateBuilder() =
    member __.Return(x)  = ret x
    member __.Bind(m, f) = m >>= f
let state = StateBuilder()

let evalState m s = fst (m s)
let get   = fun s -> (s , s)
let put s = fun _ -> ((), s)

let test = state {
    let! a = get
    do! put (a * 2)
    let! b = get
    return (a, b) }

let postInc = state {
    let! x = get
    do! put (x + 1)
    return x }

let test2 = state {
    let! a = postInc
    let! b = postInc
    return (a, b) }

do
    printfn "%A" (evalState test  3)
    printfn "%A" (evalState test  5)
    printfn "%A" (evalState test2 3)
    printfn "%A" (evalState test2 5)
```
```text:実行結果
(3, 6)
(5, 10)
(3, 4)
(5, 6)
```

関数モナドやStateモナドのように裏で状態を取り回すタイプは**状態系モナド**と呼ばれます。状態を扱うことはモナド共通の特徴というわけではなく、次に別のタイプを見ます。

# リストモナド

関数はモナドとして扱えましたが、リストもモナドとして扱えます。

今まで見て来た状態系モナドとは異なるタイプです。状態を引き回すことはしません。

リストモナドはループを扱うことができます。

## 1. Haskellの例

```hs:Haskell
test = do
    a <- [1, 2, 3]
    b <- [4, 5, 6]
    return (a * b)

main = do
    print test
```
```text:実行結果
[4,5,6,8,10,12,12,15,18]
```

リストからの値の取り出しが値を1つずつ取り出すループに変換されます。フラットに書いていますが二重ループです。F#で動作を真似たものと見比べてみてください。

```fsharp:F#
let test =
    let list = System.Collections.Generic.List<int>()
    for a in [1; 2; 3] do
        for b in [4; 5; 6] do
            list.Add(a * b)
    Seq.toList list

do
    printfn "%A" test
```
```text:実行結果
[4; 5; 6; 8; 10; 12; 12; 15; 18]
```

コンピュテーション式でHaskellの挙動を再現することを目指します。

※ HaskellからF#に変換するとき、リストの区切りを`,`から`;`に書き替える必要があります。`,`のままだとタプルが入った1要素のリストになってしまいます。

## 2. doを剥がす

```hs:Haskell
test =
    [1, 2, 3] >>= \a ->
    [4, 5, 6] >>= \b ->
    return (a * b)
```

## 3. returnを実装

要素が1つのリストを返します。

```fsharp:F#
let ret x = [x]

let test = ret 1

do
    printfn "%A" test
```
```text:実行結果
[1]
```

## 4. 1段で>>=を実装

ループを意識して実装します。

```fsharp:F#
let ret x = [x]
let (>>=) (m:'a list) f =
    let list = System.Collections.Generic.List<'a>()
    for x in m do
        list.AddRange(f x)
    Seq.toList list

let test = [1; 2; 3] >>= ret

do
    printfn "%A" test
```
```text:実行結果
[1; 2; 3]
```

## 5. 多段対応

そのまま試してみます。

```fsharp:F#
let ret x = [x]
let (>>=) (m:'a list) f =
    let list = System.Collections.Generic.List<'a>()
    for x in m do
        list.AddRange(f x)
    Seq.toList list

let test =
    [1; 2; 3] >>= fun a ->
    [4; 5; 6] >>= fun b ->
    ret (a * b)

do
    printfn "%A" test
```
```text:実行結果
[4; 5; 6; 8; 10; 12; 12; 15; 18]
```

すんなり動きました。

## 6. ビルダーを実装

```fsharp:F#
let ret x = [x]
let (>>=) (m:'a list) f =
    let list = System.Collections.Generic.List<'a>()
    for x in m do
        list.AddRange(f x)
    Seq.toList list

type ListMonadBuilder() =
    member __.Return(x)  = ret x
    member __.Bind(m, f) = m >>= f
let listMonad = ListMonadBuilder()

let test = listMonad {
    let! a = [1; 2; 3]
    let! b = [4; 5; 6]
    return a * b }

do
    printfn "%A" test
```
```text:実行結果
[4; 5; 6; 8; 10; 12; 12; 15; 18]
```

コンピュテーション式だけを見れば、`for`なしでループが実現されているように見えます。

## 空のリスト

空のリストを与えると、後続の処理が行われません。

```fsharp:F#（変更箇所）
let test = listMonad {
    let! a = [1; 2; 3]
    let! b = []
    return a * b }
```
```text:実行結果
[]
```

空のリストを与えてもループの中に入らないと解釈できます。

```fsharp:F#
let test =
    let list = System.Collections.Generic.List<int>()
    for a in [1; 2; 3] do
        for b in [] do       // 空のリスト
            list.Add(a * b)  // 中に入らない
    Seq.toList list

do
    printfn "%A" test
```
```text:実行結果
[]
```

この性質の応用として、コンピュテーション式の途中でわざと空のリストを与えて途中脱出に使えます。

# Maybeモナド

「1個までしか要素が持てないリスト」に相当するモナドです。個数が制限されている以外の挙動は基本的に同じです。

HaskellとF#では表記が若干異なるので比較します。F#では `option` 型を使用します。

Haskell|0個 |1個 |2個 |3個 |4個以上
-------|----|----|----|----|-------
リスト |`[]` |`[x]` |`[x, y]`|`[x, y, z]`|（略）
`Maybe`|`Nothing`|`Just x`|なし |なし |なし

F#  |0個 |1個 |2個 |3個 |4個以上
----|----|----|----|----|-------
リスト|`[]` |`[x]` |`[x; y]`|`[x; y; z]`|（略）
`option`|`None`|`Some x`|なし |なし |なし

0個は値がありませんが、これにより関数が評価に失敗して値を返せないことが表現できます。

## 1. Haskellの例

`Nothing`から値を取り出そうとしても失敗して、処理が途中で打ち切られます。空のリストで途中脱出になるのと同じだと考えれば良いでしょう。

```hs:Haskell
fact 0 = Just 1
fact n | n > 0 = do n' <- fact (n - 1); return (n * n')
       | otherwise = Nothing

facts n = do
    a <- fact  n
    b <- fact (n - 1)
    c <- fact (n - 2)
    return (a, b, c)

main = do
    print (facts 3)
    print (facts 2)
    print (facts 1)  -- cで失敗
    print (facts 0)  -- bで失敗
```
```text:実行結果
Just (6,2,1)
Just (2,1,1)
Nothing
Nothing
```

## 2. doを剥がす

```hs:Haskell
fact 0 = Just 1
fact n | n > 0 = fact (n - 1) >>= \n' -> return (n * n')
       | otherwise = Nothing

facts n =
    fact  n      >>= \a ->
    fact (n - 1) >>= \b ->
    fact (n - 2) >>= \c ->
    return (a, b, c)
```

## 3. returnを実装

`Some`に入れるだけです。

```fsharp:F#
let ret x = Some x

let test = ret 1

do
    printfn "%A" test
```
```text:実行結果
Some 1
```

## 4. 1段で>>=を実装

要素数は0か1なので、ループとして処理する必要はありません。

```fsharp:F#
let ret x = Some x
let (>>=) (m:'a option) f =
    match m with
    | Some x -> f x
    | None   -> None

let test = Some 1 >>= ret

do
    printfn "%A" test
```
```text:実行結果
Some 1
```

`f`を評価しないことで、処理を途中で打ち切ることになります。

## 5. 多段対応

そのまま試してみます。

```fsharp:F#
let ret x = Some x
let (>>=) (m:'a option) f =
    match m with
    | Some x -> f x
    | None   -> None

let rec fact = function
| 0            -> Some 1
| n when n > 0 -> fact (n - 1) >>= fun n' -> ret (n * n')
| _            -> None

let facts n =
    fact  n      >>= fun a ->
    fact (n - 1) >>= fun b ->
    fact (n - 2) >>= fun c ->
    ret (a, b, c)

do
    printfn "%A" (facts 3)
    printfn "%A" (facts 2)
    printfn "%A" (facts 1)  // cで失敗
    printfn "%A" (facts 0)  // bで失敗
```
```text:実行結果
Some (6, 2, 1)
Some (2, 1, 1)
<null>
<null>
```

`None`は`<null>`と表示されていますが、すんなり動きました。

## 6. ビルダーを実装

```fsharp:F#
let ret x = Some x
let (>>=) (m:'a option) f =
    match m with
    | Some x -> f x
    | None   -> None

type MaybeBuilder() =
    member __.Return(x)  = ret x
    member __.Bind(m, f) = m >>= f
let maybe = MaybeBuilder()

let rec fact = function
| 0            -> Some 1
| n when n > 0 -> maybe { let! n' = fact (n - 1) in return (n * n') }
| _            -> None

let facts n = maybe {
    let! a = fact  n
    let! b = fact (n - 1)
    let! c = fact (n - 2)
    return (a, b, c) }

do
    printfn "%A" (facts 3)
    printfn "%A" (facts 2)
    printfn "%A" (facts 1)  // cで失敗
    printfn "%A" (facts 0)  // bで失敗
```
```text:実行結果
Some (6, 2, 1)
Some (2, 1, 1)
<null>
<null>
```

`let!`のタイミングで失敗がチェックされて、失敗していたら途中で打ち切られます。

# おわりに

いくつかモナドをコンピュテーション式で実装して来ました。複雑なコードは一気に書けないので、なるべく直感的に少しずつ書く過程を示そうと試みました。`Return`と`Bind`だけで色々な処理が表現できることが分かれば、まずは十分ではないでしょうか。

ここに示したものはどれも基本的なモナドばかりです。ある程度は慣れておけば、新しい発想のタネともなるのではないでしょうか。
