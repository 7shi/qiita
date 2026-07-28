---
coediting: false
comments_count: 0
created_at: '2014-09-19T22:49:35+09:00'
id: 096396f0007857676515
likes_count: 28
private: false
reactions_count: 0
stocks_count: 24
tags:
- name: Haskell
  versions: []
title: Haskellによる代数計算入門
updated_at: '2017-11-30T11:54:06+09:00'
url: https://qiita.com/7shi/items/096396f0007857676515
slide: false
---

代数計算に触れる導入として、Haskellの代数的データ型による取っ掛かりを説明します。多項式の展開や微分などを扱います。

Haskellは初歩的な機能のみ使います。以下の内容を理解していれば十分です。

* [Haskell 超入門](http://qiita.com/7shi/items/145f1234f8ec2af923ef)
* [HUnit 超入門](http://qiita.com/7shi/items/9fb326a87de6c3083784)
* [Haskell 代数的データ型 超入門](http://qiita.com/7shi/items/1ce76bde464b4a55c143)

※ これらで解説していない機能は使っていないため、冗長になっている箇所が多々あります。あらかじめご了承ください。

練習の解答例は別記事に掲載します。

* [【解答例】Haskellによる代数計算入門](http://qiita.com/7shi/items/c62858d22a565095f791)

Haskell以外の言語での実装については以下を参照してください。

* https://gist.github.com/7shi/c0a6f489fbe22b98b015

※ 今回の記事とは異なり微分・積分しか実装していません。

この記事には関連記事があります。

* 2016.12.14 [多項式の積を計算](http://qiita.com/7shi/items/4fb60dacad46cb8e63b3)
* 2017.11.29 [ディラック作用素の代数計算](https://qiita.com/7shi/items/414fcb97c7aea6816a72)

# 足し算

足し算を表す直積型と、式を評価する関数`eval`を定義します。

```hs
module Main where

import Test.HUnit
import System.IO

data Add = Add Int Int deriving Show

eval (Add x y) = x + y

tests = TestList
    [ "eval 1" ~: eval (Add 1 1) ~?= 1+1
    , "eval 2" ~: eval (Add 2 3) ~?= 2+3
    ]

main = do
    runTestText (putTextToHandle stderr False) tests
```

⇒ [ここまでのコード](https://gist.github.com/7shi/6e4802af4e2bce6ef169/e68024be60dc67c67b0fc3b83c136b26242cf5b7)

## 練習

このままでは二項演算しかできません。具体的には`1+2+3`のような計算ができません。

【問1】フィールドをリストにしてください。テストも修正してください。

⇒ [解答例](http://qiita.com/7shi/items/c62858d22a565095f791#1-1)

# 引き算

引き算はマイナスの足し算として解釈します。

```hs:テスト
    , "eval 3" ~: eval (Add [5, -3]) ~?= 5-3
```

⇒ [ここまでのコード](https://gist.github.com/7shi/6e4802af4e2bce6ef169/5278d48075ca91fd913db8523ea545fc3b582952)

# 掛け算

足し算と同様に掛け算を実装します。

```hs:テスト
    , "eval 4" ~: eval (Mul [3, 4]) ~?= 3*4
```
```hs:
data Mul = Mul [Int] deriving Show

eval (Mul xs) = product xs
```

ところが`eval`がエラーとなります。引数に`Add`と`Mul`という互換性のない型を指定しているためです。

```text:エラー内容
    Couldn't match expected type `Add' with actual type `Mul'
    In the pattern: Mul xs
    In an equation for `eval': eval (Mul xs) = product xs
```

`Add`と`Mul`を直和型でまとめます。

```hs
data Expr = Add [Int]
          | Mul [Int]
          deriving Show
```

これで`eval`が`Add`と`Mul`の両方を受け付けるようになりました。

⇒ [ここまでのコード](https://gist.github.com/7shi/6e4802af4e2bce6ef169/15abd8a1bf1a0be1faec4e40a5bebe139c28a61d)

# 再帰型

このままでは足し算と掛け算を混ぜることができません。具体的には`1+2*3`のような計算ができません。

これを可能にするには`Add`や`Mul`のフィールドを`[Expr]`にする必要があります。そうすると`Int`を受け付けなくなるため、`Int`をフィールドに含む型を追加します。

それに伴い`eval`やテストも修正が必要です。

```hs
data Expr = N Int
          | Add [Expr]
          | Mul [Expr]
          deriving Show

eval (N   x ) = x
eval (Add xs) = sum     [eval x | x <- xs]
eval (Mul xs) = product [eval x | x <- xs]

tests = TestList
    [ "eval 1" ~: eval (Add[N 1,N  1 ]) ~?= 1+1
    , "eval 2" ~: eval (Add[N 2,N  3 ]) ~?= 2+3
    , "eval 3" ~: eval (Add[N 5,N(-3)]) ~?= 5-3
    , "eval 4" ~: eval (Mul[N 3,N  4 ]) ~?= 3*4
    , "eval 5" ~: eval (Add[N 1,Mul[N 2,N 3]]) ~?= 1+2*3
    , "eval 6" ~: eval (Mul[Add[N 1,N 2],N 3]) ~?= (1+2)*3
    ]
```

`Expr`に含まれる型がフィールドに`Expr`を持っています。このような形態を再帰型と呼びます。

代数的データ型の組み合わせで式を書いていますが大変です。実用的に使うにはパーサを実装したい所ですが、今回は代数的データ型に慣れることが目的のため見送ります。なお、あまりにも長いためスペースを詰めて書いています。

⇒ [ここまでのコード](https://gist.github.com/7shi/6e4802af4e2bce6ef169/e3a3cf05d26ebd1b7a26dd60ac06e6ca445f6fe6)

# 表示

式が何を表しているのか分かりにくいので、文字列に変換する関数を実装します。

```hs:テスト
    , "str 1" ~: str (Add[N 1,N  2 ,N  3 ])  ~?= "1+2+3"
    , "str 2" ~: str (Add[N 1,N(-2),N(-3)])  ~?= "1-2-3"
    , "str 3" ~: str (Mul[N 1,N  2 ,N  3 ])  ~?= "1*2*3"
    , "str 4" ~: str (Add[N 1,Mul[N 2,N 3]]) ~?= "1+2*3"
```
```hs
isneg (N n) | n < 0 = True
isneg _             = False

str (N x)     = show x
str (Add [])  = ""
str (Add [x]) = str x
str (Add (x:y:zs))
    | isneg y    = str x        ++ str (Add (y:zs))
str (Add (x:xs)) = str x ++ "+" ++ str (Add xs)
str (Mul [])     = ""
str (Mul [x])    = str x
str (Mul (x:xs)) = str x ++ "*" ++ str (Mul xs)
```

`isneg`は`1+-2`ではなく`1-2`となるように調整するための関数です。`str`から呼び出している部分のガード（`| isneg y`）で`otherwise`を使わずにパターンマッチを部分化しているのがポイントです。

⇒ [ここまでのコード](https://gist.github.com/7shi/6e4802af4e2bce6ef169/c3c8ebb046a299c2d6c062913b9aac0e326265a9)

## 使い分け

`print`で表示するとき、そのまま渡せば代数的データ型の構造そのまま、`str`では変換した式という使い分けです。

```hs:例
main = do
    let f = Mul[Add[N 1,N 2],N 3]
    print $ f
    print $ str f
```
```text:実行結果
Mul [Add [N 1,N 2],N 3]
"1+2*3"
```

## 練習

【問2】内部に含まれた式を括弧で囲むように修正してください。演算子の優先順位で括弧が含意されているもの（例: `1+2*3`）は除きます。具体的には以下のテストを通してください。

```hs:テスト
    , "str 5" ~: str (Add[Add[N 1,N 2],N 3]) ~?= "(1+2)+3"
    , "str 6" ~: str (Mul[Add[N 1,N 2],N 3]) ~?= "(1+2)*3"
    , "str 7" ~: str (Mul[Mul[N 1,N 2],N 3]) ~?= "(1*2)*3"
```
```text:修正前
### Failure in: 10:str 5
expected: "(1+2)+3"
 but got: "1+2+3"
### Failure in: 11:str 6
expected: "(1+2)*3"
 but got: "1+2*3"
### Failure in: 12:str 7
expected: "(1*2)*3"
 but got: "1*2*3"
```

⇒ [解答例](http://qiita.com/7shi/items/c62858d22a565095f791#1-2)

# 比較

式が等しいか比較しようとするとエラーになります。

```hs:テスト
    , "equal" ~: Add[N 1,N 2] ~?= Add[N 1,N 2]
```
```text:エラー内容
    No instance for (Eq Expr) arising from a use of `~?='
    Possible fix: add an instance declaration for (Eq Expr)
    （略）
```

表示に`deriving Show`が必要だったのと同様に、等しいかどうかの判定には`deriving Eq`が必要です。今回は既に`Show`が指定されているため、同時に`Eq`も指定するには括弧で囲みます。

```hs
data Expr = N Int
          | Add [Expr]
          | Mul [Expr]
          deriving (Show, Eq)
```

これでテストが通るようになりました。

⇒ [ここまでのコード](https://gist.github.com/7shi/6e4802af4e2bce6ef169/f08aae556c60dbdcdc097a8575a6ed682b422292)

# 変数

変数をサポートします。

```hs:テスト
    , "x 1" ~: str (Add [Var "x",N 1]) ~?= "x+1"
```
```hs:コンストラクタを修正
data Expr = N   Int
          | Var String
          | Add [Expr]
          | Mul [Expr]
          deriving (Show, Eq)
```
```hs:strに追加
str (Var name) = name
```

`Var`を含む式を`eval`に渡すとエラーになります。回避するには変数への数値代入をサポートする必要がありますが、今回は見送ります。そのためこれ以降`eval`は使用しません。

⇒ [ここまでのコード](https://gist.github.com/7shi/6e4802af4e2bce6ef169/811f1d1929149cf716097bb789f79c3dc2c14c2d)

# 指数

$x^2$ などをサポートします。汎用的な指数表現を実装するのが正攻法ですが、ここでは単純化のため`Var`のフィールドとして実装します。記述が長くなるのでコンストラクタのラッパー関数`x`を追加します。

```hs:テストを修正
    , "x 1" ~: str (Add [x 1,N 1]) ~?= "x+1"
```
```hs:テストに追加
    , "x 2" ~: str (Add [x 2,x 1,N 1]) ~?= "x^2+x+1"
```
```hs:コンストラクタを修正
data Expr = N   Int
          | Var String Int
          | Add [Expr]
          | Mul [Expr]
          deriving (Show, Eq)
```
```hs:xを追加
x n = Var "x" n
```
```hs:strを修正
str (Var x 1) = x
str (Var x n) = x ++ "^" ++ show n
```

⇒ [ここまでのコード](https://gist.github.com/7shi/6e4802af4e2bce6ef169/fea016bc05061d270de26d366d93bc97724c5835)

## 練習

【問3】係数も`Var`のフィールドに入れてください。具体的には以下のようにテストを修正して通してください。

```hs:テストを修正
    , "x 1" ~: str (Add [1`x`1,N 1]) ~?= "x+1"
    , "x 2" ~: str (Add [1`x`3,(-1)`x`2,(-2)`x`1,N 1]) ~?= "x^3-x^2-2x+1"
```

⇒ [解答例](http://qiita.com/7shi/items/c62858d22a565095f791#1-3)

# 並べ替え

項をxについて降べきの順に並べ替える関数を実装します。係数は無視して、x以外の変数は定数として扱います。

```hs:テスト
    , "xlt 1" ~: (1`x`1) `xlt` (1`x`2) ~?= True
    , "xlt 2" ~: (N 1)   `xlt` (1`x`1) ~?= True
    , "xsort 1" ~:
        let f = Add[1`x`1,N 1,1`x`2]
        in (str f, str $ xsort f)
        ~?= ("x+1+x^2", "x^2+x+1")
    , "xsort 2" ~:
        let f = Mul[Add[N 5,2`x`1],Add[1`x`1,N 1,1`x`2]]
        in (str f, str $ xsort f)
        ~?= ("(5+2x)*(x+1+x^2)", "(2x+5)*(x^2+x+1)")
```
```hs
xlt (Var "x" _ n1) (Var "x" _ n2) = n1 < n2
xlt (Var "x" _ _ ) _              = False
xlt _              (Var "x" _ _ ) = True
xlt _              _              = True -- ignore

xsort (Add xs) = Add $ f xs
    where
        f []     = []
        f (x:xs) = f xs1 ++ [x] ++ f xs2
            where
                xs1 = [xsort x' | x' <- xs, not $ x' `xlt` x]
                xs2 = [xsort x' | x' <- xs,       x' `xlt` x]
xsort (Mul xs) = Mul [xsort x | x <- xs]
xsort x = x
```

クイックソートを使っています。内部に含まれる多項式も再帰的に処理しています。

⇒ [ここまでのコード](https://gist.github.com/7shi/6e4802af4e2bce6ef169/45fda3ff75fdae50985ba2cee1d7cdacd0edc59b)

## 練習

【問4】xについて同類項を整理する関数`xsimplify`を実装してください。内部で`xsort`を使ってください。具体的には以下のテストを通してください。

```hs:テスト
    , "xsimplify 1" ~:
        let f = Add[2`x`1,N 3,4`x`2,1`x`1,N 1,1`x`2]
        in (str f, str $ xsimplify f)
        ~?= ("2x+3+4x^2+x+1+x^2", "5x^2+3x+4")
    , "xsimplify 2" ~:
        let f = Mul[Add[1`x`1,N 0,2`x`1],Add[1`x`2,Add[N 1,2`x`2],N 2]]
        in (str f, str $ xsimplify f)
        ~?= ("(x+0+2x)*(x^2+(1+2x^2)+2)", "3x*(3x^2+3)")
    , "xsimplify 3" ~:
        let f = Add[1`x`1,N 1,0`x`2,1`x`1,N 1,(-2)`x`1,N(-2)]
        in (str f, str $ xsimplify f)
        ~?= ("x+1+0x^2+x+1-2x-2", "0")
```

⇒ [解答例](http://qiita.com/7shi/items/c62858d22a565095f791#1-4)

# 式の掛け算

例: $(x+1)(x+2)=x^2+3x+2$

2つの式を掛けて展開する関数`multiply`を実装します。N, Var, Add, Mulのすべての組み合わせを実装します。

```hs:テスト
    , "multiply 1" ~:
        let f1 = N 2
            f2 = N 3
        in (str f1, str f2, str $ f1 `multiply` f2)
        ~?= ("2", "3", "6")
    , "multiply 2" ~:
        let f1 = N 2
            f2 = 3`x`2
        in (str f1, str f2, str $ f1 `multiply` f2)
        ~?= ("2", "3x^2", "6x^2")
    , "multiply 3" ~:
        let f1 = 2`x`3
            f2 = 3`x`4
        in (str f1, str f2, str $ f1 `multiply` f2)
        ~?= ("2x^3", "3x^4", "6x^7")
    , "multiply 4" ~:
        let f1 = N 2
            f2 = Add[1`x`1,2`x`2,N 3]
        in (str f1, str f2, str $ f1 `multiply` f2)
        ~?= ("2", "x+2x^2+3", "2x+4x^2+6")
    , "multiply 5" ~:
        let f1 = Add[1`x`1,N 1]
            f2 = Add[2`x`1,N 3]
            f3 = f1 `multiply` f2
            f4 = xsimplify f3
        in (str f1, str f2, str f3, str f4)
        ~?= ("x+1", "2x+3", "2x^2+3x+2x+3", "2x^2+5x+3")
```
```hs
multiply (N n1)        (N n2)        = N $ n1 * n2
multiply (N n1)        (Var x a2 n2) = Var x (n1 * a2) n2
multiply (Var x a1 n1) (N n2)        = Var x (a1 * n2) n1
multiply (Var x a1 n1) (Var y a2 n2)
    | x == y    = Var x (a1 * a2) (n1 + n2)
    | otherwise = Mul [Var x a1 n1, Var y a2 n2] 
multiply (Add xs1) (Add xs2) = Add [multiply x1 x2 | x1 <- xs1, x2 <- xs2]
multiply (Add xs1) x2        = Add [multiply x1 x2 | x1 <- xs1           ]
multiply x1        (Add xs2) = Add [multiply x1 x2 |            x2 <- xs2]
multiply (Mul xs1) (Mul xs2) = Mul (xs1 ++ xs2)
multiply (Mul xs1) x2        = Mul (xs1 ++ [x2])
multiply x1        (Mul xs2) = Mul (x1:xs2)
```

⇒ [ここまでのコード](https://gist.github.com/7shi/6e4802af4e2bce6ef169/fcc7ed796d5a64c746cd25206d58c1ac93653402)

## 練習

【問5】多項式の掛け算を一段階だけ展開する関数`expand`を実装してください。具体的には以下のテストを通してください。

```hs:テスト
    , "expand 1" ~:
        let f = Mul[Add[1`x`1,N 1],Add[1`x`1,N 2],Add[1`x`1,N 3]]
        in (str f, str $ expand f)
        ~?= ("(x+1)*(x+2)*(x+3)", "(x^2+2x+x+2)*(x+3)")
    , "expand 2" ~:
        let f = Add[N 1,Mul[Add[1`x`1,N 1],Add[1`x`1,N 2],Add[1`x`1,N 3]]]
        in (str f, str $ expand f)
        ~?= ("1+(x+1)*(x+2)*(x+3)", "1+(x^2+2x+x+2)*(x+3)")
```

⇒ [解答例](http://qiita.com/7shi/items/c62858d22a565095f791#2-1)

【問6】一段階で止めずにすべて展開する関数`expandAll`を実装してください。具体的には以下のテストを通してください。

```hs:テスト
    , "expandAll" ~:
        let f1 = Add[N 1,Mul[Add[1`x`1,N 1],Add[1`x`1,N 2],Add[1`x`1,N 3]]]
            f2 = expandAll f1
            f3 = xsimplify f2
        in (str f1, str f2, str f3)
        ~?= ( "1+(x+1)*(x+2)*(x+3)"
            , "1+(x^3+3x^2+2x^2+6x+x^2+3x+2x+6)"
            , "x^3+6x^2+11x+7"
            )
```

⇒ [解答例](http://qiita.com/7shi/items/c62858d22a565095f791#2-2)

# 微分

項を順に処理することで微分は簡単に実装できます。x限定ではなく変数を指定できるようにします。

```hs:テスト
    , "differentiate" ~:
        let f = Add[1`x`3,1`x`2,1`x`1,N 1]
        in (str f, str $ differentiate "x" f)
        ~?= ("x^3+x^2+x+1", "3x^2+2x+1+0")
```
```hs
differentiate x (Add ys) = Add [differentiate x y | y <- ys]
differentiate x (Var y a 1) | x == y = N a
differentiate x (Var y a n) | x == y = Var x (a * n) (n - 1)
differentiate _ (Var _ _ _) = N 0
differentiate _ (N _)       = N 0
```

多項式の掛け算が含まれている場合は先に展開しないと処理できないため、意図的に`Mul`のパターンマッチを書かずにエラーにしています。

⇒ [ここまでのコード](https://gist.github.com/7shi/6e4802af4e2bce6ef169/7d2606575d2b91bae0806b291aa0fcc098622c2e)

## 練習

[Data.Ratio](http://hackage.haskell.org/package/base-4.7.0.1/docs/Data-Ratio.html)により分数（`Rational`型）が使えます。

$\frac{1}{2}$は`1 % 2`と表記します。

```hs:使用例
import Data.Ratio

main = do
    print $ 1 % 3 + 1 % 5
```
```text:実行結果
8 % 15
```

【問7】不定積分を実装してください。具体的には以下のテストを通してください。

```hs:テスト
    , "integrate" ~:
        let f = Add[1`x`2,2`x`1,N 1]
        in (str f, str $ integrate "x" f)
        ~?= ("x^2+2x+1", "1/3 x^3+x^2+x+C")
```

⇒ [解答例](http://qiita.com/7shi/items/c62858d22a565095f791#1-6)
