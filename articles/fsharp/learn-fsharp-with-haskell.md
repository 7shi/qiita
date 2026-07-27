---
coediting: false
comments_count: 0
created_at: '2017-01-11T18:44:54+09:00'
id: b174d1c50aab9350dafc
likes_count: 1
private: false
reactions_count: 0
stocks_count: 0
tags:
- name: Haskell
  versions: []
- name: F#
  versions: []
title: 【解答例】Haskellで学ぶF#入門
updated_at: '2017-01-14T16:17:46+09:00'
url: https://qiita.com/7shi/items/b174d1c50aab9350dafc
slide: false
---

[Haskellで学ぶF#入門](http://qiita.com/7shi/items/1d3750ba17f5a88b8405)の解答例です。

# フィボナッチ数

## パターンマッチ

【問1】任意のn番目のフィボナッチ数を計算する関数`fib`をパターンマッチで実装してください。

初期値`0, 1`を基底部とします。

```fsharp:基底部
let rec fib = function
| 0 -> 0
| 1 -> 1
```

`0, 1, 1, 2, 3, 5, ...`より`fib 5`について考えます。

```fsharp:具体例
fib 5 = 2 + 3 = fib 3 + fib 4
```

これを`n`で一般化すれば再帰部となります。

```fsharp:再帰部
| n -> fib (n - 2) + fib (n - 1)
```

テストを追加して解答とします。

```fsharp:解答
let rec fib = function
| 0 -> 0
| 1 -> 1
| n -> fib (n - 2) + fib (n - 1)

printfn "%d" <| fib 6
```
```text:実行結果
8
```

## ガード

【問2】問1で実装した関数に、無限ループを防ぐためのガードを追加してください。

```fsharp
let rec fib = function
| 0 -> 0
| 1 -> 1
| n when n > 1 -> fib (n - 2) + fib (n - 1)
| _ -> failwith "< 0"

printfn "%d" <| fib 6
```
```text:実行結果
8
```

## match

【問3】問2で実装した関数を`match`で書き直してください。

```fsharp
let rec fib n =
    match n with
    | 0 -> 0
    | 1 -> 1
    | _ when n > 1 -> fib (n - 2) + fib (n - 1)
    | _ -> failwith "< 0"

printfn "%d" <| fib 6
```
```text:実行結果
8
```

# 再実装

【問4】`sum`, `rev`と同じ機能の関数を再実装してください。`sum`の掛け算版`product`も実装してください。

```fsharp
let rec sum = function
| []    -> 0
| x::xs -> x + sum xs

let rec rev = function
| []    -> []
| x::xs -> rev xs @ [x]

let rec product = function
| []    -> 1
| x::xs -> x * product xs

printfn "%d" <| sum [1..5]
printfn "%A" <| rev [1..5]
printfn "%d" <| product [1..5]
```
```text:実行結果
15
[5; 4; 3; 2; 1]
120
```

* リストが空になるまで順番にたどるため、基底部として`[]`を定義します。

## 別解

※ 勉強会で出た意見を反映した項目です。

`@`を避けた実装です。本文では説明していませんが末尾再帰です。

```fsharp
let rec rev xs =
    let rec f ys = function
    | []    -> ys
    | x::xs -> f (x::ys) xs
    f [] xs
```

# 階乗

【問5】`product`を使って`fact`（階乗）を実装してください。

```fsharp
let rec product = function
| []    -> 1
| x::xs -> x * product xs

let fact n = product [1..n]

printfn "%d" <| fact 5
```
```text:実行結果
120
```

# 垂線の交点

【問6】点 $(p, q)$ から直線 $ax + by = c$ に下した垂線の交点を求める関数`perpPoint`を作成してください。aとbが両方ゼロになると解なしですが、チェックせずに無視してください。

```math
ax + by = c \cdots (1)
```

(1)への垂線は

```math
bx - ay = d \cdots (2)
```

(2)に $(p,q)$ を代入します。

```math
d = bp - aq \cdots (3)
```

(1)と(2)の連立方程式を解いて(3)を代入すれば交点が求まります。

```math
x=\frac{ac+bd}{a^2+b^2}, y=\frac{bc-ad}{a^2+b^2}
```

これをコード化します。

```fsharp:解答
let perpPoint (p, q) (a, b, c) =
    let d = b * p - a * q
    let x = (a * c + b * d) / (a * a + b * b)
    let y = (b * c - a * d) / (a * a + b * b)
    (x, y)

printfn "%A" <| perpPoint (0., 2.) (1., -1., 0.)
```
```text:実行結果
(1.0, 1.0)
```

# ROT13

【問7】[ROT13](http://ja.wikipedia.org/wiki/ROT13)を実装してください。

```fsharp
let rot13ch = function
| ch when 'A' <= ch && ch <= 'M'
       || 'a' <= ch && ch <= 'm' -> char <| int ch + 13
| ch when 'N' <= ch && ch <= 'Z'
       || 'n' <= ch && ch <= 'z' -> char <| int ch - 13
| ch -> ch

let rot13 s =
    let rec f = function
    | []    -> []
    | x::xs -> rot13ch x :: f xs
    List.ofSeq s |> f |> Array.ofList |> System.String.Concat

let hello13 = rot13 "Hello, World!"
printfn "%s" hello13
printfn "%s" <| rot13 hello13
```
```text:実行結果
Uryyb, Jbeyq!
Hello, World!
```

# バブルソート

【問8】[バブルソート](http://www.ics.kagoshima-u.ac.jp/~fuchida/edu/algorithm/sort-algorithm/bubble-sort.html)を実装してください。

⇒ [詳細説明](http://qiita.com/7shi/items/1e2a66bf8e8c7f0bd70f)

```fsharp
let rec bswap = function
| [ ] -> [ ]
| [x] -> [x]
| x::xs ->
    match bswap xs with
    | [] -> [x]
    | y::ys ->
        if x > y then y::x::ys
                 else x::y::ys

let rec bsort xs =
    match bswap xs with
    | []    -> []
    | y::ys -> y :: bsort ys

printfn "%A" <| bswap [4; 3; 1; 5; 2]
printfn "%A" <| bsort [4; 3; 1; 5; 2]
printfn "%A" <| bsort [5; 4; 3; 2; 1]
printfn "%A" <| bsort [4; 6; 9; 8; 3; 5; 1; 7; 2]
```
```text:実行結果
[1; 4; 3; 2; 5]
[1; 2; 3; 4; 5]
[1; 2; 3; 4; 5]
[1; 2; 3; 4; 5; 6; 7; 8; 9]
```

# マージソート

【問9】[マージソート](http://www.ics.kagoshima-u.ac.jp/~fuchida/edu/algorithm/sort-algorithm/merge-sort.html)を実装してください。

* ソートしながら2つのリストをマージする関数`merge`を作ります。
* リストを分割する関数`split`を作ります。ソート前のリストは順番を保持することに意味がないため、実装しやすさを優先します。
* 往路で分割、復路でマージを再帰関数で表現します。

```fsharp
let rec merge = function
| xs, [] -> xs
| [], ys -> ys
| x::xs, y::ys ->
    if x < y then x :: merge (xs, y::ys)
             else y :: merge (x::xs, ys)

let rec split = function
| [ ] -> ([ ], [])
| [x] -> ([x], [])
| x::y::zs ->
    let xs, ys = split zs
    (x::xs, y::ys)

let rec msort = function
| [ ] -> [ ]
| [x] -> [x]
| xs ->
    let ys, zs = split xs
    merge (msort ys, msort zs)

printfn "%A" <| msort [4; 6; 9; 8; 3; 5; 1; 7; 2]
```
```text:実行結果
[1; 2; 3; 4; 5; 6; 7; 8; 9]
```

# クイックソート

【問10】動きを考えて、F#に移植してください。

リスト`[4, 6, 9, 8, 3, 5, 1, 7, 2]`をソートします。

`(n:xs) = 4 : [6, 9, 8, 3, 5, 1, 7, 2]`

リストの最初の要素`4`を基準に3つの部分に分けます。

```hs
qsort (n:xs) = qsort lt ++ [n] ++ qsort gteq
    where
        lt   = [x | x <- xs, x <  n]
        gteq = [x | x <- xs, x >= n]
```

* 4未満: `lt   = [x | x <- xs, x <  n]` → `[3, 1, 2]`
* 4: `[x]` → `[4]`
* 4以上: `gteq = [x | x <- xs, x >= n]` → `[6, 9, 8, 5, 7]`

`lt`と`gteq`をソートして結合します。

```text:実行イメージ
qsort [3, 1, 2] ++ [4] ++ qsort [6, 9, 8, 5, 7]
          ↓                           ↓
      [1, 2, 3] ++ [4] ++       [5, 6, 7, 8, 9]
          ↓                           ↓
      [1, 2, 3,     4,           5, 6, 7, 8, 9]
```

`qsort [3, 1, 2]`と`qsort [6, 9, 8, 5, 7]`の内部では、同様の処理が繰り返されています。

これを踏まえて移植します。

```fsharp:F#
let rec qsort = function
| [] -> []
| n::xs ->
    let lt   = [for x in xs do if x <  n then yield x]
    let gteq = [for x in xs do if x >= n then yield x]
    qsort lt @ [n] @ qsort gteq

printfn "%A" <| qsort [4; 6; 9; 8; 3; 5; 1; 7; 2]
```
```text:実行結果
[1; 2; 3; 4; 5; 6; 7; 8; 9]
```

# 直角三角形の三辺

【問11】三辺の長さが各20以下の整数で構成される直角三角形を列挙してください。並び順による重複を排除する必要はありません。

複数ソースのリスト内包表記に三平方の定理で条件付けします。

```fsharp
printfn "%A" <| [
    for a in 1..20 do
    for b in 1..20 do
    for c in 1..20 do
    if a * a + b * b = c * c then yield (a, b, c)]
```
```text:実行結果
[(3, 4, 5); (4, 3, 5); (5, 12, 13); (6, 8, 10); (8, 6, 10); (8, 15, 17);
 (9, 12, 15); (12, 5, 13); (12, 9, 15); (12, 16, 20); (15, 8, 17); (16, 12, 20)]
```

## 重複排除

※ 勉強会で出た意見を反映した項目です。

条件 $a<b$ を追加すれば並び順による重複が排除できます。

```fsharp
printfn "%A" <| [
    for a in 1..20 do
    for b in 1..20 do
    for c in 1..20 do
    if a * a + b * b = c * c && a < b then yield (a, b, c)]
```
```text:実行結果
[(3, 4, 5); (5, 12, 13); (6, 8, 10); (8, 15, 17); (9, 12, 15); (12, 16, 20)]
```

条件で制限するのではなく、ソースから抜けば計算量が削減できます。

```fsharp
printfn "%A" <| [
    for a in 1..20 do
    for b in a..20 do
    for c in b..20 do
    if a * a + b * b = c * c then yield (a, b, c)]
```
```text:実行結果
[(3, 4, 5); (5, 12, 13); (6, 8, 10); (8, 15, 17); (9, 12, 15); (12, 16, 20)]
```
