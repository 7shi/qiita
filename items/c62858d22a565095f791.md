---
coediting: false
comments_count: 0
created_at: '2014-09-19T22:50:46+09:00'
id: c62858d22a565095f791
likes_count: 6
private: false
reactions_count: 0
stocks_count: 6
tags:
- name: Haskell
  versions: []
title: 【解答例】Haskellによる代数計算入門
updated_at: '2014-09-23T10:23:07+09:00'
url: https://qiita.com/7shi/items/c62858d22a565095f791
slide: false
---

# リスト化

【問1】フィールドをリストにしてください。テストも修正してください。

```hs
data Add = Add [Int] deriving Show

eval (Add xs) = sum xs

tests = TestList
    [ "eval 1" ~: eval (Add [1, 1]) ~?= 1+1
    , "eval 2" ~: eval (Add [2, 3]) ~?= 2+3
    ]
```

⇒ [ここまでのコード](https://gist.github.com/7shi/6e4802af4e2bce6ef169/b1ffe00788a87a4c7a989de88f79146dd9843fd0)

# 括弧

【問2】内部に含まれた式を括弧で囲むように修正してください。演算子の優先順位で括弧が含意されているもの（例: `1+2*3`）は除きます。

以下の場合に括弧を付けます。

* `Add`の中に`Add`が入っている場合（例: `(1+2)+3`）
* `Mul`の中に`Add`が入っている場合（例: `(1+2)*3`）
* `Mul`の中に`Mul`が入っている場合（例: `(1*2)*3`）

```hs:strを修正
str (N x) = show x
str (Add [])       = ""
str (Add [Add xs]) = "(" ++ str (Add xs) ++ ")"
str (Add [x])      = str x
str (Add (x:y:zs))
    | isneg y      = str (Add [x])        ++ str (Add (y:zs))
str (Add (x:xs))   = str (Add [x]) ++ "+" ++ str (Add xs)
str (Mul [])       = ""
str (Mul [Add xs]) = "(" ++ str (Add xs) ++ ")"
str (Mul [Mul xs]) = "(" ++ str (Mul xs) ++ ")"
str (Mul [x])      = str x
str (Mul (x:xs))   = str (Mul [x]) ++ "*" ++ str (Mul xs)
```

⇒ [ここまでのコード](https://gist.github.com/7shi/6e4802af4e2bce6ef169/1dc7721116f937c76f7edfa83aef968c9865b6e5)

# 係数

【問3】係数も`Var`のフィールドに入れてください。

```hs:コンストラクタを修正
data Expr = N Int
          | Var String Int Int
          | Add [Expr]
          | Mul [Expr]
          deriving (Show, Eq)
```
```hs:xを修正
x a n = Var "x" a n
```
```hs:strを修正
str (Var x  1 1) = x
str (Var x(-1)1) = "-" ++ x
str (Var x  a 1) = show a ++ x
str (Var x  a n) = str (Var x a 1) ++ "^" ++ show n
```

係数が負の時に`+-`と表示されないように調整します。

```hs:isnegを修正
isneg (N n)       | n < 0 = True
isneg (Var _ a _) | a < 0 = True
isneg _                   = False
```

⇒ [ここまでのコード](https://gist.github.com/7shi/6e4802af4e2bce6ef169/a7caa2ea84c729847ebc68bf1d2e6f2b86a943e5)

# 同類項の整理

【問4】xについて同類項を整理する関数`xsimplify`を実装してください。内部で`xsort`を使ってください。

テストに使われている特殊ケースに対応するための関数を実装します。

* ネストした`Add`をフラットにする: $x^2+(1+2x^2)+2=3x^2+3$

```hs
flatten []              = []
flatten ((Add xs1):xs2) = flatten (xs1 ++ xs2)
flatten (x:xs)          = x : flatten xs
```

コンストラクタのラッパーで特殊ケースに対応します。

* ゼロを消す: $x+1-x-1=0$
* 単項を`Add`から外す: $(x+2x)=3x$

```hs
add []  = N 0
add [x] = x
add xs  = Add xs
```

`xsort`を使うと降べきの順になるので、同類項のチェックが隣接する項だけで済みます。

```hs
xsimplify (Add xs) = add $ f $ getxs $ xsort $ Add $ flatten xs
    where
        getxs (Add xs) = xs
        f []  = []
        f ((N     0  ):xs) = f xs
        f ((Var _ 0 _):xs) = f xs
        f [x] = [xsimplify x]
        f ((N a1):(N a2):zs) = f $ N (a1 + a2) : zs
        f ((Var "x" a1 n1):(Var "x" a2 n2):zs)
            | n1 == n2 = f $ (a1 + a2)`x`n1 : zs
        f (x:xs) = xsimplify x : f xs
xsimplify (Mul xs) = Mul [xsimplify x | x <- xs]
xsimplify x = x
```

計算結果を再帰に掛けているのがポイントです。

⇒ [ここまでのコード](https://gist.github.com/7shi/6e4802af4e2bce6ef169/1a96560ac8eb0730d4efa0c6ec3b756283619a0e)

# 展開

## 一段階

【問5】多項式の掛け算を一段階だけ展開する関数`expand`を実装してください。

`add`と同じようにコンストラクタのラッパーを作ります。

```hs
mul []  = N 1
mul [x] = x
mul xs  = Mul xs

expand (Mul xs) = mul $ f xs
    where
        f []  = []
        f [x] = [expand x]
        f (x:y:xs) = multiply x y : xs
expand (Add xs) = add $ f xs
    where
        f []  = []
        f (x:xs)
            | x /= x'   = x':xs
            | otherwise = x : f xs
            where
                x' = expand x
expand x = x
```

⇒ [ここまでのコード](https://gist.github.com/7shi/6e4802af4e2bce6ef169/3f9152536e24c8fbe9903788931218eb5db5609b)

## すべて

【問6】一段階で止めずにすべて展開する関数`expandAll`を実装してください。

結果が変わらなくなるまで`expand`を繰り返します。

```hs
expandAll x
    | x /= x'   = expandAll x'
    | otherwise = x
    where
        x' = expand x
```

⇒ [ここまでのコード](https://gist.github.com/7shi/6e4802af4e2bce6ef169/489a9a824efd0ada497634ce624fe9615f8ca202)

# 積分

【問7】不定積分を実装してください。

Exprのフィールドを`Int`から`Rational`にします。

```hs:importに追加
import Data.Ratio
```
```hs:Exprを修正
data Expr = N Rational
          | Var String Rational Rational
          | Add [Expr]
          | Mul [Expr]
          deriving (Show, Eq)
```

整数が`3 % 1`のように分数で表示されてしまい、テストが通らなくなります。

```text
### Failure in: 6:str 1
expected: "1+2+3"
 but got: "1 % 1+2 % 1+3 % 1"
```

分母が1かどうかをチェックして表示する関数を作成します。

* 分子・分母を取得する関数は[Data.Ratio](http://hackage.haskell.org/package/base-4.7.0.1/docs/Data-Ratio.html)で調べます。
* テストで係数が分数のときにスペースを入れているのに対応するため、引数でサフィックスを指定します。

```hs
rstr x s
    | d == 1    = show n
    | otherwise = show n ++ "/" ++ show d ++ s
    where
        n = numerator x
        d = denominator x
```

`rstr`を使うように`str`を修正します。

```hs:strを修正（抜粋）
str (N x) = rstr x ""
str (Var x  a 1) = rstr a " " ++ x
str (Var x  a n) = str (Var x a 1) ++ "^" ++ rstr n ""
```

これでまたテストが通ります。

不定積分を実装します。

```hs
integrate x (Add ys) = Add $ [integrate x y | y <- ys] ++ [Var "C" 1 1]
integrate x (Var y a n)
    | x == y    = Var x (a / (n + 1)) (n + 1)
    | otherwise = Mul [Var y a n, Var x 1 1]
integrate x (N n) = Var x n 1
```

⇒ [ここまでのコード](https://gist.github.com/7shi/6e4802af4e2bce6ef169)
