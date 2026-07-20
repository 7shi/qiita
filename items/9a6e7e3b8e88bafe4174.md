---
coediting: false
comments_count: 0
created_at: '2015-12-07T13:58:50+09:00'
id: 9a6e7e3b8e88bafe4174
likes_count: 6
private: false
reactions_count: 0
stocks_count: 5
tags:
- name: Haskell
  versions: []
- name: F#
  versions: []
title: アローの取っ掛かり
updated_at: '2017-01-10T10:24:35+09:00'
url: https://qiita.com/7shi/items/9a6e7e3b8e88bafe4174
slide: false
---

[Haskellの実験メモ](http://qiita.com/7shi/items/b6cbb7df2dd969c84f49)です。

アローの取っ掛かりをつかむため、次の記事のサンプルをアローなしで書き換えてみました。

* [Programming with Arrows 読解　1 : tnomuraのブログ](http://tnomura9.exblog.jp/18517156)

今回の記事で書き換えを試みているのは、アローを使わずに済ませるためではなく、感覚をつかむために既知の概念と比較したいからです。

F#のパイプライン演算子や関数合成と似ているので、F#とも比較します。

# 準備

2つのテキストファイルを用意します。

```test.txt
hello, world
```
```test2.txt
Consider this simple Haskell definition, of a function which counts the number of occurrences of a given word w in a string:
```

# ファイルを読んで表示

アローの例を引用します。

```hs:アロー
import Control.Arrow

readFile' = Kleisli readFile
putStrLn' = Kleisli putStrLn
printFile = readFile' >>> putStrLn'

main = runKleisli printFile "test.txt"
```
```text:実行結果
hello, world
```

この例だとアローを持ち出さなくても`>=>`でどうにかなります。

※ 実行結果は同じなので省略します。

```hs:モナド1
import Control.Monad

printFile = readFile >=> putStrLn

main = printFile "test.txt"
```

`>=>`はモナド則3の右辺に出て来るようなラムダ式を書き換えるのに使えます。

* `m >>= (\x -> f x >>= g)` → `m >>= (f >=> g)`

モナド則については次の記事を参照してください。

* [モナド則がちょっと分かった？](http://qiita.com/7shi/items/547b6137d7a3c482fe68) 2014.12.1

上の書き換えを逆に行えば`>>=`で表現できます。

※ ポイントフリーであることがアローの目的の1つとして挙げられていますが、以下の書き換えにより引数が明示されポイントフリーではなくなっているため、コンセプトが台無しになっています。

```hs:モナド2
printFile = \x -> readFile x >>= putStrLn

main = printFile "test.txt"
```

敢えてラムダ式にしなくても引数を左辺に移動しても同じです。

```hs:モナド3
printFile x = readFile x >>= putStrLn

main = printFile "test.txt"
```

## F♯

F#のパイプライン演算子`|>`と似ています。

```fsharp:F#
open System.IO

let printFile x = File.ReadAllText x |> printfn "%s"

printFile "test.txt"
```

パイプライン演算子 `|>` を関数合成 `>>` にすればポイントフリーにできます。Haskellで`>=>`を使ったスタイルとほとんど同じ雰囲気です。

```fsharp:F#
open System.IO

let printFile = File.ReadAllText >> printfn "%s"

printFile "test.txt"
```

# 指定した単語を数える

もう少し複雑な例を引用します。

```hs:アロー
import Control.Arrow

count w =
    Kleisli readFile >>>
    arr words >>>
    arr (filter (==w)) >>>
    arr (show . length) >>>
    Kleisli putStrLn

main = runKleisli (count "a") "test2.txt"
```
```text:実行結果
3
```

同様にモナドで書き換えます。関数を`Monad m => a -> m b`という型にするため`return .`で合成しているのがミソです。

```hs:モナド1
import Control.Monad

count w =
    readFile >=>
    return . words >=>
    return . (filter (==w)) >=>
    return . (show . length) >=>
    putStrLn

main = (count "a") "test2.txt"
```
```hs:モナド2
count w = \x ->
    readFile x >>=
    return . words >>=
    return . (filter (==w)) >>=
    return . (show . length) >>=
    putStrLn

main = (count "a") "test2.txt"
```
```hs:モナド3
count w x =
    readFile x >>=
    return . words >>=
    return . (filter (==w)) >>=
    return . (show . length) >>=
    putStrLn

main = (count "a") "test2.txt"
```

## F♯

F#も似たような感じで書けますが、`words`に相当する部分がラムダ式になっていて少し冗長です。（もっと良い方法があるかもしれませんが）

```fsharp:F#
open System.IO

let count w x =
    File.ReadAllText x |>
    (fun s -> s.Split ' ') |>
    Array.filter ((=) w) |>
    Array.length |>
    printfn "%d"

(count "a") "test2.txt"
```

関数合成で `x` をポイントフリーにします。

```fsharp:F#
open System.IO

let count w =
    File.ReadAllText >>
    (fun s -> s.Split ' ') >>
    Array.filter ((=) w) >>
    Array.length >>
    printfn "%d"

(count "a") "test2.txt"
```

# 感想

アローは`>=>`が取っ掛かりになりそうだという感触がつかめました。

まさにそうやってアローの導入を試みた記事があります。とても分かりやすいのでお勧めです。

* @CyLomw: [Arrow を理解する (まとめ)](http://qiita.com/CyLomw/items/eb543cff8715e4f441a3) 2015.1.3

今回のような`>=>`で書き換えられる程度のサンプルだと敢えてアローを使う必要もないのですが、もっと複雑になって来ればアローが真価を発揮するのでしょう。
