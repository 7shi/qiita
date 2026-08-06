---
coediting: false
comments_count: 0
created_at: '2014-11-27T23:53:14+09:00'
id: 1345bf32003faff435cb
likes_count: 80
private: false
reactions_count: 0
stocks_count: 63
tags:
- name: JavaScript
  versions: []
- name: Haskell
  versions: []
title: Haskell ラムダ 超入門
updated_at: '2026-08-07T03:30:36+09:00'
url: https://qiita.com/7shi/items/1345bf32003faff435cb
slide: false
---

Haskellの文法に慣れて来た方を対象に、ラムダ式や高階関数を使って関数を取り回す方法を説明します。カリー化や部分適用も取り上げます。いわゆる関数型言語らしい機能です。

シリーズの記事です。

1. [Haskell 超入門](http://qiita.com/7shi/items/145f1234f8ec2af923ef)
1. [Haskell 代数的データ型 超入門](http://qiita.com/7shi/items/1ce76bde464b4a55c143)
1. [Haskell アクション 超入門](http://qiita.com/7shi/items/85afd7bbd5d6c4115ad6)
1. **Haskell ラムダ 超入門** ← この記事
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
1. 【予定】Haskell モナドとゆかいな仲間たち
1. 【予定】Haskell Freeモナド 超入門
1. 【予定】Haskell Operationalモナド 超入門
1. 【予定】Haskell Effモナド 超入門
1. 【予定】Haskell アロー 超入門

練習の解答例は別記事に掲載します。

* [【解答例】Haskell ラムダ 超入門](http://qiita.com/7shi/items/bfa4c282c504c24578d2)

この記事には@shigemk2さんによるScala版があります。

* [Scala ラムダ超入門](http://qiita.com/shigemk2/items/3a5e5df9fe85cf0b4eb2)

この記事はとある方への誕生日プレゼントとして捧げます。

# ラムダ式

今まで取り上げて来た文法では、関数の引数を左辺で定義していました。

```hs
inc x = x + 1

main = do
    print $ inc 5
```
```text:実行結果
6
```

引数を右辺で定義する文法があります。

```hs
inc = \x -> x + 1

main = do
    print $ inc 5
```
```text:実行結果
6
```

この右辺を**ラムダ式**と呼びます。`\`（バックスラッシュ）をギリシア文字の **λ**（ラムダ）に見立てています。

※ Windowsで`\`は円記号で表示されることがありますが、本来のASCIIではバックスラッシュです。

## 練習

【問1】次に示す関数`fact`をラムダ式と`case`～`of`で書き換えてください。

```hs
fact 0         = 1
fact n | n > 0 = n * fact (n - 1)

main = do
    print $ fact 5
```

⇒ [解答例](http://qiita.com/7shi/items/bfa4c282c504c24578d2#%E9%9A%8E%E4%B9%97)

# 型注釈

型注釈とラムダ式を並べると、型注釈の書式がラムダ式と共通していることが分かります。

```hs
inc :: Int -> Int
inc =  \x  -> x + 1

main = do
    print $ inc 5
```
```text:実行結果
6
```

## 練習

【問2】次に示す関数`add`をラムダ式で書き換えてください。

```hs
add :: Int -> Int -> Int
add x y = x + y

main = do
    print $ add 2 3
```

⇒ [解答例](http://qiita.com/7shi/items/bfa4c282c504c24578d2#%E8%A4%87%E6%95%B0%E3%81%AE%E5%BC%95%E6%95%B0)

# 無名関数

ラムダ式は名前のない関数（[無名関数](http://ja.wikipedia.org/wiki/%E7%84%A1%E5%90%8D%E9%96%A2%E6%95%B0)）で、それを変数に束縛していると捉えることができます。

```hs
a = 1
b = \x -> x + 1

main = do
    print $ b a
```
```text:実行結果
2
```

ラムダ式を束縛しないで使うこともできます。

```hs
main = do
    print $ (\x -> x + 1) 1
```
```text:実行結果
2
```

一度しか使わない関数にわざわざ名前を付けるのが面倒なとき、ラムダ式は便利です。

## 複数の引数

次の3つはすべて同じ型`Int -> Int -> Int`です。

1. `mul x y = x * y`
2. `mul = \x y -> x * y`
3. `mul = \x -> \y -> x * y`

1と2は3の糖衣構文です。

## 練習

【問3】次に示す関数`add`を定義せずに、呼び出し側で無名関数にインライン展開してください。

```hs
add x y = x + y

main = do
    print $ add 2 3
```

⇒ [解答例](http://qiita.com/7shi/items/bfa4c282c504c24578d2#%E7%84%A1%E5%90%8D%E9%96%A2%E6%95%B0)

# 高階関数

引数として関数を受け取ったり、戻り値として関数を返したりする関数を[高階関数](http://ja.wikipedia.org/wiki/%E9%AB%98%E9%9A%8E%E9%96%A2%E6%95%B0)と呼びます。

## 引数

引数として関数を受け取る高階関数の例です。

```hs
f g = g 2 3

add x y = x + y
mul = \x y -> x * y

main = do
    print $ f add
    print $ f mul
```
```text:実行結果
5
6
```

上の`mul`はラムダ式が変数に束縛され、その変数を`f`に渡しています。変数を経由せずにラムダ式を直接渡すこともできます。

```hs
f g = g 2 3

main = do
    print $ f $ \x y -> x + y
    print $ f $ \x y -> x * y
```
```text:実行結果
5
6
```

## 戻り値

戻り値として関数を返す高階関数の例です。

```hs
add x = \y -> x + y

main = do
    let add2 = add 2
    print $ add2 3
    print $ (add 2) 3
    print $ add 2 3
```
```text:実行結果
5
5
5
```

上の`add`はラムダ式`\y -> x + y`で表される無名関数を返す高階関数です。高階関数から戻された関数に後続の引数を渡すことで連続して呼び出すことができます。

## 練習

【問4】次に示す関数`f`と`add`を定義せずに、呼び出し側で無名関数にインライン展開してください。

```hs
f g = g 1 2
add x y = x + y

main = do
    print $ f add
```

⇒ [解答例](http://qiita.com/7shi/items/bfa4c282c504c24578d2#%E5%BC%95%E6%95%B0)

【問5】次に示す関数`add`を定義せずに、呼び出し側で無名関数にインライン展開してください。

```hs
add x = \y -> x + y

main = do
    print $ add 1 2
```

⇒ [解答例](http://qiita.com/7shi/items/bfa4c282c504c24578d2#%E6%88%BB%E3%82%8A%E5%80%A4)

# カリー化

複数の引数を取る関数に対して、引数を後ろから1つずつ右辺に移動させてみます。

```hs
add x y = x + y
add' x = \y -> x + y
add'' = \x -> \y -> x + y

main = do
    print $ add   2 3
    print $ add'  2 3
    print $ add'' 2 3
```
```text:実行結果
5
5
5
```

どれも同じように振る舞うため、定義は等価だと見なせます。このように引数を1つずつ分割して関数をネストさせることを[カリー化](http://ja.wikipedia.org/wiki/%E3%82%AB%E3%83%AA%E3%83%BC%E5%8C%96)と呼びます。Haskellでは複数の引数を取る関数は自動的にカリー化されます。

## 部分適用

引数が足りない場合、後で付け足せば呼び出しを完成させることができます。このようなことが可能になるのも関数がカリー化されているためです。

```hs
add x y = x + y

main = do
    let add2 = add 2
    print $ add2 3
    print $ (add 2) 3
    print $ add 2 3
```
```text:実行結果
5
5
5
```

上の`add2`のように一部の引数を固定化して新しい関数を作り出すことを**部分適用**と呼びます。

## 注意点

カリー化と部分適用は混同されることがあります。具体的には、部分適用を指してカリー化と呼ばれることがありますが、これは誤用です。

改めて定義を確認します。

* カリー化とは：関数を引数1つずつに分割してネストさせること
* 部分適用とは：一部の引数を固定化して新しい関数を作り出すこと

詳細は次の記事にまとめました。

* [@7shi](https://twitter.com/7shi): [カリー化と部分適用（JavaScriptとHaskell） - Qiita](http://qiita.com/7shi/items/a0143daac77a205e7962) 2014.10.15

## 練習

【問6】次に示す関数`combine`を、引数1つずつに分割してネストさせたラムダ式で書き換えてください。

```hs
combine a b c = a:b:[c]

main = do
    let a = combine 1
        b = a 2
        c = b 3
    print c
    print $ combine 'a' 'b' 'c'
```

⇒ [解答例](http://qiita.com/7shi/items/bfa4c282c504c24578d2#%E3%82%AB%E3%83%AA%E3%83%BC%E5%8C%96)

【問7】次のコードから関数`double`を除去してください。ラムダ式は使わないでください。

```hs
f xs g = [g x | x <- xs]
double x = 2 * x

main = do
    print $ f [1..5] double
```

ヒント: 演算子の関数化`(*)`

⇒ [解答例](http://qiita.com/7shi/items/bfa4c282c504c24578d2#%E9%83%A8%E5%88%86%E9%81%A9%E7%94%A8)

# 演算子

演算子を関数化すれば高階関数に渡すことができます。

```hs
f g = g 2 3

main = do
    print $ f (+)
    print $ f (*)
```
```text:実行結果
5
6
```

## 部分適用

演算子を関数化すれば部分適用できます。（問7で出題）

```hs
f g = g 5

main = do
    print $ f $ (-) 2
```
```text:実行結果
-3
```

## セクション

中置演算子のまま片方のオペランド（被演算子）を省略した不完全な式は部分適用として扱われます。これを**セクション**と呼びます。セクションは括弧で囲む必要があります。

ラムダ式とセクションを対比します。`(- 2)`はマイナス2という数値として解釈されるため、2種類の回避方法を示しています。

```hs
f g = g 5

main = do
    print [f $ \x -> 2 + x, f (2 +)]
    print [f $ \x -> x + 2, f (+ 2)]
    print [f $ \x -> 2 - x, f (2 -)]
    print [f $ \x -> x - 2, f (+(-2)), f $ subtract 2]
```
```text:実行結果
[7,7]
[7,7]
[-3,-3]
[3,3,3]
```

関数を演算子化すればセクションとして扱えます。

```hs
f g = g 5

main = do
    print $ f (2 `div`)
    print $ f (`div` 2)
```
```text:実行結果
0
2
```

セクションは次の記事を参考にしました。

* [@jutememo](https://twitter.com/jutememo): [Haskell のセクションと中置記法 | すぐに忘れる脳みそのためのメモ](http://jutememo.blogspot.jp/2008/06/haskell_24.html) 2008.6.24
* [@kk_ataka](https://twitter.com/kk_ataka): [すごいHaskellたのしく学ぼうでHaskellことはじめ4 - kk_Atakaの日記](http://d.hatena.ne.jp/kk_Ataka/20130220/1361365130) 2013.2.20

## 練習

【問8】次のコードからラムダ式を排除してください。

```hs
f1 g = g 1
f2 g = g 2 3

main = do
    print $ f1 $ \x -> x - 3
    print $ f1 $ \x -> 3 - x
    print $ f2 $ \x y -> x + y
```

⇒ [解答例](http://qiita.com/7shi/items/bfa4c282c504c24578d2#%E6%BC%94%E7%AE%97%E5%AD%90)

# 色々な関数

Prelude（標準ライブラリ）で定義されている高階関数をいくつか紹介します。

## map

リストの要素すべてに同じ処理を施した別のリストを作成します。

同じことができるリスト内包表記と対比します。👉[超入門](https://qiita.com/7shi/items/145f1234f8ec2af923ef#%E3%83%AA%E3%82%B9%E3%83%88%E5%86%85%E5%8C%85%E8%A1%A8%E8%A8%98)

```hs
main = do
    print $ map (* 2) [1..5]
    print [x * 2 | x <- [1..5]]
```
```text:実行結果
[2,4,6,8,10]
[2,4,6,8,10]
```

リスト内包表記との使い分けは特に基準はありませんが、高階関数の扱いに慣れればリスト内包表記が冗長に感じるかもしれません。

## filter

リストから要素を取り出す際に条件を指定できます。

同じことができるリスト内包表記と対比します。👉[超入門](https://qiita.com/7shi/items/145f1234f8ec2af923ef#%E6%9D%A1%E4%BB%B6)

```hs
main = do
    print $ filter (< 5) [1..9]
    print [x | x <- [1..9], x < 5]
```
```text:実行結果
[1,2,3,4]
[1,2,3,4]
```

## flip

2引数関数で引数の順序を反転します。

第2引数への部分適用をセクションやラッパーと対比します。

```hs
src = [1..5]
test1 = flip map src
test2 = (`map` src)
test3 f = map f src

main = do
    print $ test1 (* 2)
    print $ test2 (* 2)
    print $ test3 (* 2)
```
```text:実行結果
[2,4,6,8,10]
[2,4,6,8,10]
[2,4,6,8,10]
```

第1引数がラムダ式で記述すると長くなる時、先に第2引数を記述するために使うと便利です。Yコンビネータで実例を出します。

## foldl

リストの要素を左から1つずつ処理しながら集計します。関数名末尾の`l`はLeft（左）の意味です。

* `foldl :: 集計関数 -> 初期値 -> リスト -> 集計結果`

`foldl`で`sum`相当の処理をしてみました。

```hs
main = do
    print $ sum [1..100]
    print $ foldl (+) 0 [1..100]
```
```text:実行結果
5050
5050
```

`foldl`は手続型言語のループを関数化したものだと見なせます。次のJavaScriptコードと比較してみてください。

```js:JavaScript
var sum = 0;
for (var i = 1; i <= 100; ++i) {
    sum += i;
}
console.log(sum);
```
```text:実行結果
5050
```

集計の初期値として`0`を用意して、ループで`i`を次々に足していきます。そこから処理（足し算）と初期値を取り出して関数化したのが`foldl`だと見なすわけです。

## foldr

リストの要素を右から1つずつ処理しながら集計します。関数名末尾の`r`はRight（右）の意味です。

```hs
main = do
    print $ foldr (-) 0 [1..5]
```
```text:実行結果
3
```

再帰でリストの全要素を処理する際に、再帰から返って来た値を使って関数の戻り値を計算すると、戻り値が確定するのは再帰の復路です。この手の再帰を関数化したものだと見なせます。次のコードと比較してみてください。

```hs:再帰で書き換え
test []     = 0
test (x:xs) = x - test xs

main = do
    print $ test [1..5]
```
```text:実行結果
3
```

再帰の折り返し値として`0`を用意して、復路で`x`から次々に引いていきます。そこから処理（引き算）と折り返し値（最初に作用させる値）を取り出して関数化したのが`foldr`だと見なすわけです。

* `1 - (2 - (3 - (4 - (5 - 0))))` → `1 - 2 + 3 - 4 + 5` → `3`

※ 復路で実際の計算が始まるため、計算の順はリストの右からとなります。これがRightの意味です。

`foldr`は次の記事を参考にしました。

* [@taiju](https://twitter.com/taiju): [プログラミングHaskellのfoldr, foldlの説明が秀逸だった件 - あと味](http://taiju.hatenablog.com/entry/20130202/1359773888) 2013.2.2

## 練習

【問9】`map`, `filter`, `flip`, `foldl`, `foldr`を再帰で再実装してください。関数名には`'`を付けてください。

具体的には以下のコードが動くようにしてください。

```hs
main = do
    print $ map' (* 2) [1..5]
    print $ filter' (< 5) [1..9]
    print $ flip' map' [1..5] (* 2)
    print $ foldl' (+) 0 [1..100]
    print $ foldl' (-) 0 [1..5]
    print $ foldr' (-) 0 [1..5]
```
```text:実行結果
[2,4,6,8,10]
[1,2,3,4]
[2,4,6,8,10]
5050
-15
3
```

⇒ [解答例](http://qiita.com/7shi/items/bfa4c282c504c24578d2#%E5%86%8D%E5%B8%B0)

【問10】`foldl`で`reverse`と`maximum`と`minimum`を再実装してください。関数名には`'`を付けてください。

具体的には以下のコードが動くようにしてください。

```hs
main = do
    let src = [-5..5]
    print $ reverse' src
    print $ maximum' src
    print $ minimum' src
```
```text:実行結果
[5,4,3,2,1,0,-1,-2,-3,-4,-5]
5
-5
```

⇒ [解答例](http://qiita.com/7shi/items/bfa4c282c504c24578d2#foldl)

【問11】次に示す関数`qsort`を`filter`で書き替えてください。

```hs
qsort []     = []
qsort (n:xs) = qsort lt ++ [n] ++ qsort gteq
    where
        lt   = [x | x <- xs, x <  n]
        gteq = [x | x <- xs, x >= n]

main = do
    print $ qsort [4, 6, 9, 8, 3, 5, 1, 7, 2]
```

⇒ [解答例](http://qiita.com/7shi/items/bfa4c282c504c24578d2#%E3%82%AF%E3%82%A4%E3%83%83%E3%82%AF%E3%82%BD%E3%83%BC%E3%83%88)

【問12】次に示す関数`bswap`を`foldr`で書き替えてください。

※ バブルソートの本体は`foldr`では実装できないため省きました。

```hs
bswap [x] = [x]
bswap (x:xs)
    | x > y     = y:x:ys
    | otherwise = x:y:ys
    where
        (y:ys) = bswap xs

main = do
    print $ bswap [4, 3, 1, 5, 2]
```
```text:実行結果
[1,4,3,2,5]
```

⇒ [解答例](http://qiita.com/7shi/items/bfa4c282c504c24578d2#%E3%83%90%E3%83%96%E3%83%AB)

この問題は次の記事を参考にしました。

* [@kazu_yamamoto](https://twitter.com/kazu_yamamoto): [リストの畳み込みと展開 - あどけない話](http://d.hatena.ne.jp/kazu-yamamoto/20110913/1315905876) 2011.9.13

# 不動点コンビネータ

自己参照のできない無名のラムダ式で再帰を実現するテクニックとして、[不動点コンビネータ](http://ja.wikipedia.org/wiki/%E4%B8%8D%E5%8B%95%E7%82%B9%E3%82%B3%E3%83%B3%E3%83%93%E3%83%8D%E3%83%BC%E3%82%BF)を利用する方法があります。あまり使う機会はないかもしれませんが、たまに見掛けるので知識として知っておいても損はないでしょう。

## Yコンビネータ

Yコンビネータ（不動点コンビネータの一種）と呼ばれる補助関数を定義します。

```hs
y f = f (y f)
```

Yコンビネータにラムダ式を渡すと、ラムダ式の第1引数にYコンビネータに包まれた自分自身が渡されます。これを使うことで再帰ができます。

`sum`をインラインで実装した例です。ラムダ式の第1引数を関数名に見立てています。

```hs
y f = f (y f)

main = do
    print $ flip y [1..100] $
        \sum xs -> case xs of
            []      -> 0
            (x:xs') -> x + sum xs'
```
```text:実行結果
5050
```

Yコンビネータは次の記事を参考にしました。

* [@kazu_yamamoto](https://twitter.com/kazu_yamamoto): [Haskell で Y コンビネータ - あどけない話](http://d.hatena.ne.jp/kazu-yamamoto/20100519/1274240859) 2010.5.19
* [@kazu_yamamoto](https://twitter.com/kazu_yamamoto): [Yコンビネータのまとめ - あどけない話](http://d.hatena.ne.jp/kazu-yamamoto/20100601/1275367421) 2010.6.1

## 練習

【問13】Yコンビネータを使って10番目のフィボナッチ数を計算してください。

⇒ [解答例](http://qiita.com/7shi/items/bfa4c282c504c24578d2#%E3%83%95%E3%82%A3%E3%83%9C%E3%83%8A%E3%83%83%E3%83%81%E6%95%B0)

# 関数合成

関数を連続して呼ぶのに対して、`.`で関数を合成しても同じことができます。

```hs
f x = x + 1
g x = x * 2

main = do
    print $ f (g 1)
    print $ (f . g) 1
```
```text:実行結果
3
3
```

関数を評価する順番はどちらも `g` → `f` です。

関数を使うだけだとあまり違いは感じませんが、高階関数に渡すときに関数合成は便利です。

```hs
f x = x + 1
g x = x * 2
h f = f 1

main = do
    print $ h $ f . g
    print $ h $ \x -> f $ g x
```
```text:実行結果
3
3
```

## 2引数

`g`の引数が増えるといきなり難しくなります。

```hs
f x = x * 2
g x y = x + y

main = do
    print $ f $ g 1 2        -- (1 + 2) * 2
    print $ ((f .) . g) 1 2  -- 関数合成
```
```text:実行結果
6
6
```

初期の段階であまり追及するようなものではないため紹介程度に留めておきますが、興味がある方は次の記事を参照してください。

* [@7shi](https://twitter.com/7shi): [Haskell - 関数合成を機械的に扱う試み - Qiita](http://qiita.com/7shi/items/f2c1365b792aa6046a49) 2015.2.9

# ポイントフリースタイル

部分適用を利用すれば、別の関数に渡すだけの引数を省略できます。これを**ポイントフリースタイル**と呼びます。👉[アクションとラムダ](https://qiita.com/7shi/items/4a8a2807bb5186576c61#%E3%83%9D%E3%82%A4%E3%83%B3%E3%83%88%E3%83%95%E3%83%AA%E3%83%BC%E3%82%B9%E3%82%BF%E3%82%A4%E3%83%AB)

簡単な例を示します。

```hs
f1 x y = x - y
f2 x y = (-) x y
f3 x   = (-) x
f4     = (-)

g1 x = f4 2 x
g2   = f4 2

main = do
    print $ g2 5
```
```text:実行結果
-3
```

関数合成と組み合わせれば色々なパターンで引数を排除することができます。ただあまり突き詰めると、すぐには読めないコードになるような印象があります。

もっと恐ろしいものの片鱗を味わいたい方は、次の記事を参照してみてください。

* [@melponn](https://twitter.com/melponn): [ポイントフリースタイル入門 - melpon日記](http://d.hatena.ne.jp/melpon/20111031/1320024473) 2011.10.31
