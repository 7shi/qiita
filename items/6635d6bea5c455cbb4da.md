---
coediting: false
comments_count: 0
created_at: '2016-07-04T00:40:33+09:00'
id: 6635d6bea5c455cbb4da
likes_count: 0
private: false
reactions_count: 0
stocks_count: 1
tags:
- name: F#
  versions: []
title: 試作したコンピュテーション式と関数モナド
updated_at: '2016-07-04T21:43:40+09:00'
url: https://qiita.com/7shi/items/6635d6bea5c455cbb4da
slide: false
---

StateモナドとMaybeモナドを合成すれば、状態を変化させながら失敗したときに打ち切ることが可能です。モナド変換子まで実装するのは大変なので、モナドに拘らずに目的に特化したコンピュテーション式を作ってみようと考えました。

この記事は次の続編です。

* [不揃いなデータをコンピュテーション式で処理](http://qiita.com/7shi/items/567e92474681a38de86a) 2016.06.30

上に掲載したコンピュテーション式を、どうやって作ったかという過程を説明します。あまり定義には深入りせずに、少しずつ変形して得ました。

また、修正して頂いたコードについても考察します。関数モナドに近いのではないかと思いました。

# 発端

Stateモナドでは状態を取得するのに`get`を使用します。動作決め打ちのコンピュテーション式を作れば、`get`のようなアクションが不要になるのではないかと考えました。

```fsharp
type GetBuilder() =
    member this.Bind(_, f) = fun s -> (f s) s
    member this.Zero() = fun _ -> ()
let get = GetBuilder()

let test = get {
    let! a = () in printfn "%d" a
    let! a = () in printfn "%d" a }

test 1
test 2
```
```text:実行結果
1
1
2
2
```

## 改造

値を取得する度に`+ 1`することを試してみました。

```fsharp
type IncBuilder() =
    member this.Bind(_, f) = fun s -> (f s) (s + 1)
    member this.Zero() = fun _ -> ()
let inc = IncBuilder()

let test = inc {
    let! a = () in printfn "%d" a
    let! a = () in printfn "%d" a }

test 1
test 2
```
```text:実行結果
1
2
2
3

```

`Bind`の実装で、`s`は`f`への引数、`(s + 1)`は次のブロックに渡す状態です。

※ 状態系モナドでは次のブロックに状態を渡すという解釈が、細かいトレースに煩わされずに形式的に扱うためのコツのような気がしています。

## リスト

リストの先頭から1つずつ取り出すように修正します。

```fsharp
type ListReaderBuilder() =
    member this.Bind(_, f) = fun (x::xs) -> (f x) xs
    member this.Zero() = fun _ -> ()
let listReader = ListReaderBuilder()

let test = listReader {
    let! a = () in printfn "%d" a
    let! a = () in printfn "%d" a }

test [1;2;3]
printfn "---"
test [4;5;6]
```
```text:実行結果
1
2
---
4
5
```

※ パターンマッチの不備で警告されます。

## 脱出

途中でリストが尽きたら脱出するように修正します。（Maybe風味）

```fsharp
type ListReaderBuilder() =
    member this.Bind(_, f) = function x::xs -> f x xs | _ -> ()
    member this.Zero() = fun _ -> ()
let listReader = ListReaderBuilder()
 
let test = listReader {
    let! a = () in printfn "%d" a
    let! a = () in printfn "%d" a }
 
test [1;2;3]
printfn "---"
test [4]
```
```text:実行結果
1
2
---
4
```

# 修正

[@pocketberserker](https://twitter.com/pocketberserker)さんによる修正です。

* [Twitterで流れてきたListReaderコンピュテーション式の解説 - pocketberserkerの爆走](http://qiita.com/7shi/items/567e92474681a38de86a) 2016.06.30

`Bind`の第1引数を捨てずに評価すれば、`do!`で簡単に書けるというご指摘です。

```fsharp
type ListReaderBuilder() =
  member this.Bind(g, f) = function (x::xs) -> (f (g x)) xs | _ -> ()
  member this.Return(_) = fun _ -> ()
let listReader = ListReaderBuilder()
 
let test = listReader {
  do! printfn "%d"
  do! printfn "%d"
}

test [1;2;3]
printfn "---"
test [4]
```
```text:実行結果
1
2
---
4
```

値が取れなくなるのではないかと懸念しましたが、`id`で普通に取れました。

## 関数モナド

修正していただいたコンピュテーション式の意味を考えましたが、関数モナドが出発点なのではないかと気付きました。確認するために関数モナドを作ってみた副産物が次の記事です。

* [doブロックとコンピュテーション式](http://qiita.com/7shi/items/92139286a4e9b5620d69) 2016.07.01

実際、関数モナドを使えば、値こそ変化しないものの似たことができます。

```fsharp
type FuncBuilder() =
    member __.Bind(m, f) = fun x -> f (m x) x
    member __.Return(x)  = fun _ -> x
let func = FuncBuilder() 

let test = func {
    do! printfn "%A"
    do! printfn "%A"
}

test [1;2;3]
printfn "---"
test [4]
```
```text:実行結果
[1; 2; 3]
[1; 2; 3]
---
[4]
[4]
```

これをリストが変化するように改造すれば、修正して頂いたコードが得られます。

# まとめ

アクションを消そうという発想で出発しましたが、関数モナドに揺り戻されました。何だかんだ言っても、やはり定石は手堅いです。
