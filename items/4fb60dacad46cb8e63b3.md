---
coediting: false
comments_count: 0
created_at: '2016-12-14T18:49:11+09:00'
id: 4fb60dacad46cb8e63b3
likes_count: 5
private: false
reactions_count: 0
stocks_count: 11
tags:
- name: F#
  versions: []
- name: 数学
  versions: []
title: 多項式の積を計算
updated_at: '2017-11-30T11:56:25+09:00'
url: https://qiita.com/7shi/items/4fb60dacad46cb8e63b3
slide: false
---

数学の勉強を兼ねて、数式を計算するプログラムを作っています。Qiita などに貼ることを前提に TeX のコードを出力します。

※ プログラミングを数学の勉強に応用する例としての紹介です。この方法で勉強するなら各自で似たようなコードを書くことになります。この記事で紹介するのは、どちらかというと捨てスクリプトの類です。

簡単な計算しかできませんが、計算過程をコードで記述することで好きなように変形するのが狙いです。例を示します。

```math
(x+y)^3=x^3+3x^2y+3xy^2+y^3
```

シリーズの記事です。この記事で作ったプログラムを拡張して計算します。

1. 多項式の積を計算 ← この記事
1. [外積と愉快な仲間たち](http://qiita.com/7shi/items/017d2d2c758f76071f23)
1. [ユークリッド空間のホッジ双対とバブルソート](http://qiita.com/7shi/items/f54302058149d07da592)
1. [四元数を作ろう](http://qiita.com/7shi/items/2036e7a739c2a9e04025)
1. [四元数と行列で見る内積と外積の「内」と「外」](http://qiita.com/7shi/items/a80988a32a0d706e9378)
1. [八元数を作ろう](http://qiita.com/7shi/items/b34fe724d36fb7d96456)
1. [八元数の積をプログラムで確認](http://qiita.com/7shi/items/8495b2d6b888e7b8703f)
1. [外積の成分をプログラムで確認](http://qiita.com/7shi/items/02c758c03d2fd7038912)
1. [多元数の積の構成](http://qiita.com/7shi/items/88be5203769e629df243)
1. [十六元数を作ろう](http://qiita.com/7shi/items/989d59d74a505a92c419)

関連するコードをまとめたリポジトリです。

* https://bitbucket.org/7shi/math7

この記事には関連記事があります。

* 2014.09.19 [Haskellによる代数計算入門](http://qiita.com/7shi/items/096396f0007857676515)
* 2017.11.29 [ディラック作用素の代数計算](https://qiita.com/7shi/items/414fcb97c7aea6816a72)

# 実装

実装には F# を使用します。

以下の記事で紹介した手法で開発しました。

* 2016.12.30 [F#開発環境の紹介](http://qiita.com/7shi/items/5fc7d6477d96bbd7a71d)

F#の入門記事を書いています。

* 2017.01.04 [C#/JavaScriptで学ぶF#入門](http://qiita.com/7shi/items/ff746903680ae8d0d7ce)
* 2017.01.11 [Haskellで学ぶF#入門](http://qiita.com/7shi/items/1d3750ba17f5a88b8405)

## 項

まず項の表現方法を決めます。係数と文字をタプルにして組み合わせます。定数項は文字を空にします。

```fsharp:例
(2,"x")  // 2x
(3,"")   // 3
```

これを文字列に変換する関数 `str` を実装します。

```fsharp
let str = function
|  a, "" -> sprintf "%d" a
|  1, x  ->       x
| -1, x  -> "-" + x
|  a, x  -> sprintf "%d%s" a x

printfn "%s" (str ( 3,"" ))
printfn "%s" (str ( 1,"x"))
printfn "%s" (str ( 2,"y"))
printfn "%s" (str (-1,"y"))
printfn "%s" (str (-2,"z"))
```
```text:実行結果
3
x
2y
-y
-2z
```

## 多項式

多項式はリストで表現します。

```fsharp:例
[2,"x"; 3,"y"]  // 2x+3y
```

これを文字列に変換する関数 `strs` を実装します。順番 `i` を見て `+` を挿入します。

```fsharp
let strs ts =
    ts
    |> List.mapi (fun i (a, _ as t) ->
        if i > 0 && a >= 0 then "+" + str t else str t)
    |> String.concat ""

printfn "%s" (strs [2,"x"; 3,"y"])
```
```text:実行結果
2x
```

## べき乗

べき乗は同じ文字の繰り返しで表現します。`str` を対応させます。`Seq.groupBy` がポイントです。

```fsharp
let str (a, x) =
    if x = "" then a.ToString() else
    let sa = match a with 1 -> "" | -1 -> "-" | _ -> a.ToString()
    x.ToCharArray()
    |> Seq.groupBy id
    |> Seq.map (fun (e, xs) ->
        match Seq.length xs with
        | 1 -> e.ToString()
        | n -> sprintf "%c^%d" e n)
    |> String.concat ""
    |> (+) sa

printfn "%s" (str (1,"xx"))
```
```text:実行結果
x^2
```

## 項の積

項の積を計算する関数 `prod` を実装します。係数を掛けて、文字は連結します。

```fsharp
let prod (ts:(int * string) list) =
    ts |> Seq.reduce (fun (a, x) (b, y) -> a * b, x + y)

printfn "%s" (prod [2,"x"; 3,"y"] |> str)
```
```text:実行結果
6xy
```

## 多項式の積

多項式の積を計算する関数 `prods` を実装します。

```fsharp
let prods ts =
    ts
    |> Seq.reduce (fun al bl ->
        [for a in al do for b in bl -> prod [a; b]])

let a, b = [1,"x"; 2,"" ], [1,"x"; 3,"" ]
let c, d = [1,"x"; 2,"y"], [1,"x"; 3,"y"]
printfn "(%s)(%s)=%s" (strs a) (strs b) (prods [a; b] |> strs)
printfn "(%s)(%s)=%s" (strs c) (strs d) (prods [c; d] |> strs)
```
```text:実行結果
(x+2)(x+3)=x^2+3x+2x+6
(x+2y)(x+3y)=x^2+3xy+2yx+6y^2
```

## 同類項の整理

同類項を整理する関数 `simplify` を実装します。ここでも `Seq.groupBy` を使います。`xy` と `yx` を同一視するためソートします。

```fsharp
let simplify (ts:(int * string) list) =
    ts
    |> Seq.groupBy (fun (a, x) -> System.String(x.ToCharArray() |> Array.sort))
    |> Seq.map (fun (a, xl) -> xl |> Seq.map fst |> Seq.sum, a)
    |> Seq.toList

printfn "(%s)(%s)=%s" (strs a) (strs b) (prods [a; b] |> simplify |> strs)
printfn "(%s)(%s)=%s" (strs c) (strs d) (prods [c; d] |> simplify |> strs)
```
```text:実行結果
(x+2)(x+3)=x^2+5x+6
(x+2y)(x+3y)=x^2+5xy+6y^2
```

# 使用例

$(x+y)$ のべき乗を計算してみます。

```fsharp
printfn @"\begin{align}"
let f = [1,"x"; 1,"y"]
for n = 2 to 8 do
    let ff = List.replicate n f |> prods |> simplify
    printfn @"(%s)^%d&=%s \\" (strs f) n (strs ff)
printfn @"\end{align}"
```
```text:出力結果
\begin{align}
(x+y)^2&=x^2+2xy+y^2 \\
(x+y)^3&=x^3+3x^2y+3xy^2+y^3 \\
(x+y)^4&=x^4+4x^3y+6x^2y^2+4xy^3+y^4 \\
(x+y)^5&=x^5+5x^4y+10x^3y^2+10x^2y^3+5xy^4+y^5 \\
(x+y)^6&=x^6+6x^5y+15x^4y^2+20x^3y^3+15x^2y^4+6xy^5+y^6 \\
(x+y)^7&=x^7+7x^6y+21x^5y^2+35x^4y^3+35x^3y^4+21x^2y^5+7xy^6+y^7 \\
(x+y)^8&=x^8+8x^7y+28x^6y^2+56x^5y^3+70x^4y^4+56x^3y^5+28x^2y^6+8xy^7+y^8 \\
\end{align}
```
```math
\begin{align}
(x+y)^2&=x^2+2xy+y^2 \\
(x+y)^3&=x^3+3x^2y+3xy^2+y^3 \\
(x+y)^4&=x^4+4x^3y+6x^2y^2+4xy^3+y^4 \\
(x+y)^5&=x^5+5x^4y+10x^3y^2+10x^2y^3+5xy^4+y^5 \\
(x+y)^6&=x^6+6x^5y+15x^4y^2+20x^3y^3+15x^2y^4+6xy^5+y^6 \\
(x+y)^7&=x^7+7x^6y+21x^5y^2+35x^4y^3+35x^3y^4+21x^2y^5+7xy^6+y^7 \\
(x+y)^8&=x^8+8x^7y+28x^6y^2+56x^5y^3+70x^4y^4+56x^3y^5+28x^2y^6+8xy^7+y^8 \\
\end{align}
```

プログラム全体: [Term.fsx](https://bitbucket.org/7shi/math7/src/tip/Term.fsx)

# Math7

この記事で作ったプログラムをベースに機能拡張しながら続編の記事を書いています。

* https://bitbucket.org/7shi/math7

Math7 という名前は適当で、7は七誌の七です。
