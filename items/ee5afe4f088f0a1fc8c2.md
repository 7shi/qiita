---
coediting: false
comments_count: 0
created_at: '2015-07-22T18:54:30+09:00'
id: ee5afe4f088f0a1fc8c2
likes_count: 6
private: false
reactions_count: 0
stocks_count: 5
tags:
- name: Haskell
  versions: []
title: Stateモナドによる中置記法の処理
updated_at: '2015-09-28T21:19:11+09:00'
url: https://qiita.com/7shi/items/ee5afe4f088f0a1fc8c2
slide: false
---

中置記法の処理を例に、状態の取り扱い方を示します。初めにStateモナドを使わないで書いてから、Stateモナドを使って書き換えます。コードの変化を比較することで、モナドのDSL的な側面を示すのが狙いです。BNFにも触れますが、構文解析は行いません。

この記事は[Haskell 超入門](http://qiita.com/7shi/items/145f1234f8ec2af923ef)シリーズの番外編です。特に以下の記事と関連しています。

* [Haskell 状態系モナド 超入門](http://qiita.com/7shi/items/2e9bff5d88302de1a9e9)
* [Haskell 構文解析 超入門](http://qiita.com/7shi/items/b8c741e78a96ea2c10fe)

この記事には姉妹編があります。

* [Stateモナドによるポーランド記法の処理](http://qiita.com/7shi/items/8bed38f45272f194631a)
* [Stateモナドによる逆ポーランド記法の処理](http://qiita.com/7shi/items/0494704d00396687458f)

この記事には関連記事があります。

* [Maybeモナドによる中置記法の処理](http://qiita.com/7shi/items/cda901af6abb732f9c64)

# [中置記法](https://ja.wikipedia.org/wiki/%E4%B8%AD%E7%BD%AE%E8%A8%98%E6%B3%95)

演算子をオペランド（演算対象）の間に置く記法です。いわゆる普通の数式です。演算子に優先順位があり、必要に応じて括弧を使います。

* `1+2`
* `2*3+4`
* `2+3*4`
* `(2+3)*4`

# 実装

中置記法を文字列で渡して計算する処理を実装します。

今回はパーサに深入りするのを避けるため、オペランドと演算子はスペースで区切られていることを前提とします。

× `"1+2"`, `"(2+3)*4"`
○ `"1 + 2"`, `"( 2 + 3 ) * 4"`

パーサについては以下の記事で説明します。

* [Haskell 構文解析 超入門](http://qiita.com/7shi/items/b8c741e78a96ea2c10fe)

## 分割

文字列をスペースで分割します。

```hs
eval src = words src

main = do
    print $ eval "1 + 2"
```
```text:実行結果
["1","+","2"]
```

## 数字

まず数字だけの式を考えます。先頭の要素を数値に変換して返します。

```hs
eval src = expr $ words src

expr (x:_) = read x :: Int  -- 数値に変換して返す

main = do
    print $ eval "1"
```
```text:実行結果
1
```

`expr`は expression の略で「式」を意味します。処理系ではこのような名前を付ける慣習があります。

## 計算

演算子が来れば、次の値を読み込んで計算します。

```hs
eval src = expr $ words src

expr (x:"+":y:_) = read x + read y  -- 追加
expr (x      :_) = read x           -- 型推論に任せる

main = do
    print $ eval "1"
    print $ eval "1 + 2"
```
```text:実行結果
1
3
```

### 連続した計算

`1+2+3`のように連続した計算は繰り返し処理する必要があります。

`x+y`を`x`と`+y`の部分に分け、`+y`を繰り返し処理します。その時点での計算結果（アキュムレータ）を再帰で渡しているのがポイントです。

```hs
eval src = expr $ words src

expr    (    y:src) = expr' (    read y) src  -- 先頭を読み後続に回す
expr' x ("+":y:src) = expr' (x + read y) src  -- 繰り返し処理
expr' x _ = x

main = do
    print $ eval "1"
    print $ eval "1 + 2"
    print $ eval "1 + 2 + 3"  -- OK
```
```text:実行結果
1
3
6
```

### 引き算

すんなり追加できます。

```hs
eval src = expr $ words src

expr    (    y:src) = expr' (    read y) src
expr' x ("+":y:src) = expr' (x + read y) src
expr' x ("-":y:src) = expr' (x - read y) src  -- 追加
expr' x _ = x

main = do
    print $ eval "1"
    print $ eval "1 + 2"
    print $ eval "1 + 2 + 3"
    print $ eval "1 - 2 - 3"  -- OK
    print $ eval "1 - 2 + 3"  -- OK
```
```text:実行結果
1
3
6
-4
2
```

### 掛け算

同様に掛け算を追加しても、演算子の優先順位が処理されないため、結果がおかしくなります。

```hs
eval src = expr $ words src

expr    (    y:src) = expr' (    read y) src
expr' x ("+":y:src) = expr' (x + read y) src
expr' x ("-":y:src) = expr' (x - read y) src
expr' x ("*":y:src) = expr' (x * read y) src  -- 追加
expr' x _ = x

main = do
    print $ eval "1"
    print $ eval "1 + 2"
    print $ eval "1 + 2 + 3"
    print $ eval "1 - 2 - 3"
    print $ eval "1 - 2 + 3"
    print $ eval "2 * 3 + 4"  -- OK
    print $ eval "2 + 3 * 4"  -- 14ではなく20になる
```
```text:実行結果
1
3
6
-4
2
10
20
```

## 階層分け

足し算から見ると、1つの数字と掛け算のブロックは項（term）として対等です。数式で例えると $2x+1$ において $2x$ と $1$ が項という単位として $+$ から並列に扱われていることに相当します。

項単位で計算するように分離すれば演算子の優先順位が表現できます。

```hs
eval src = expr $ words src

expr         src  = let (y, src') = term src in expr'      y  src'
expr' x ("+":src) = let (y, src') = term src in expr' (x + y) src'
expr' x ("-":src) = let (y, src') = term src in expr' (x - y) src'
expr' x _ = x

term    (    y:src) = term' (    read y) src
term' x ("*":y:src) = term' (x * read y) src
term' x src = (x, src)  -- 値と未処理のリストをタプルで返す

main = do
    print $ eval "1"
    print $ eval "1 + 2"
    print $ eval "1 + 2 + 3"
    print $ eval "1 - 2 - 3"
    print $ eval "1 - 2 + 3"
    print $ eval "2 * 3 + 4"
    print $ eval "2 + 3 * 4"  -- OK
```
```text:実行結果
1
3
6
-4
2
10
14
```

`expr`の中で`read`を使用して箇所が`term`に置き換えられているのに注意してください。

### 更に階層分け

`expr`と`term`の記述を対称的にするため、`expr`もタプルを返して、`term`の下に値を返す階層を追加します。これは因子`factor`と呼ばれます。

```hs
eval src = fst $ expr $ words src

expr         src  = let (y, src') = term   src in expr'      y  src'
expr' x ("+":src) = let (y, src') = term   src in expr' (x + y) src'
expr' x ("-":src) = let (y, src') = term   src in expr' (x - y) src'
expr' x      src  = (x, src)

term         src  = let (y, src') = factor src in term'      y  src'
term' x ("*":src) = let (y, src') = factor src in term' (x * y) src'
term' x      src  = (x, src)

factor (x:xs) = (read x, xs)

main = do
    print $ eval "1"
    print $ eval "1 + 2"
    print $ eval "1 + 2 + 3"
    print $ eval "1 - 2 - 3"
    print $ eval "1 - 2 + 3"
    print $ eval "2 * 3 + 4"
    print $ eval "2 + 3 * 4"
```
```text:実行結果
1
3
6
-4
2
10
14
```

## 括弧

括弧をサポートします。括弧は1つの値と同じように扱われるため`factor`で実装します。括弧の中には式が入っているため`expr`を呼びます。

ついでに割り算もサポートします。型推論により戻り値が浮動小数点数になります。

```hs
eval src = fst $ expr $ words src

expr         src  = let (y, src') = term   src in expr'      y  src'
expr' x ("+":src) = let (y, src') = term   src in expr' (x + y) src'
expr' x ("-":src) = let (y, src') = term   src in expr' (x - y) src'
expr' x      src  = (x, src)

term         src  = let (y, src') = factor src in term'      y  src'
term' x ("*":src) = let (y, src') = factor src in term' (x * y) src'
term' x ("/":src) = let (y, src') = factor src in term' (x / y) src' -- 追加
term' x      src  = (x, src)

factor ("(":src) = case expr src of (y, (")":src')) -> (y, src')     -- 追加
factor (  x:src) = (read x, src)

main = do
    print $ eval "1"
    print $ eval "1 + 2"
    print $ eval "1 + 2 + 3"
    print $ eval "1 - 2 - 3"
    print $ eval "1 - 2 + 3"
    print $ eval "2 * 3 + 4"
    print $ eval "2 + 3 * 4"
    print $ eval "( 2 + 3 ) * 4"  -- OK
    print $ eval "100 / 10 / 2"   -- OK
```
```text:実行結果
1.0
3.0
6.0
-4.0
2.0
10.0
14.0
20.0
5.0
```

閉じ括弧が省略されるとパターンマッチでエラーになりますが、式として間違っているため意図した動作です。

# Stateモナド

Stateモナドは状態を受け取って、値と更新された状態を返します。

* 状態 → (値, 状態)

処理対象のリストを状態に見立て、Stateモナドを使って書き換えます。手続きを逐一記述するスタイルで冗長に書きます。

```hs
import Control.Monad.State

pop = do
    (x:xs) <- get
    put xs
    return x

eval src = evalState expr $ words src

expr = do
    y <- term
    expr' y
expr' x = do
    src <- get
    case src of
        ("+":_) -> do
            pop
            y <- term
            expr' $ x + y
        ("-":_) -> do
            pop
            y <- term
            expr' $ x - y
        _ -> return x

term = do
    y <- factor
    term' y
term' x = do
    src <- get
    case src of
        ("*":_) -> do
            pop
            y <- factor
            term' $ x * y
        ("/":_) -> do
            pop
            y <- factor
            term' $ x / y
        _ -> return x

factor = do
    x <- pop
    case x of
        "(" -> do
            y <- expr
            z <- pop
            case z of
                ")" -> return y
        _ -> return $ read x

main = do
    print $ eval "1"
    print $ eval "1 + 2"
    print $ eval "1 + 2 + 3"
    print $ eval "1 - 2 - 3"
    print $ eval "1 - 2 + 3"
    print $ eval "2 * 3 + 4"
    print $ eval "2 + 3 * 4"
    print $ eval "( 2 + 3 ) * 4"
    print $ eval "100 / 10 / 2"
```
```text:実行結果
1.0
3.0
6.0
-4.0
2.0
10.0
14.0
20.0
5.0
```

状態（`src`など）の受け渡しが明示的には記述されなくなります。裏で状態が受け渡されているため、本質的には書き換え前のコードと同じです。

## 整理

`>>=`やApplicativeスタイルでコードを整理します。処理の流れは同じです。

```hs
import Control.Monad.State
import Control.Applicative

pop = state pop where
    pop (x:xs) = (x, xs)

eval src = evalState expr $ words src

expr = term >>= expr'
expr' x = get >>= f where
    f ("+":_) = pop >> (x +) <$> term >>= expr'
    f ("-":_) = pop >> (x -) <$> term >>= expr'
    f _       = return x

term = factor >>= term'
term' x = get >>= f where
    f ("*":_) = pop >> (x *) <$> factor >>= term'
    f ("/":_) = pop >> (x /) <$> factor >>= term'
    f _       = return x

factor = pop >>= f where
    f "(" = do
        x <- expr
        pop >>= g x where
            g x ")" = return x
    f x = return $ read x

main = do
    print $ eval "1"
    print $ eval "1 + 2"
    print $ eval "1 + 2 + 3"
    print $ eval "1 - 2 - 3"
    print $ eval "1 - 2 + 3"
    print $ eval "2 * 3 + 4"
    print $ eval "2 + 3 * 4"
    print $ eval "( 2 + 3 ) * 4"
    print $ eval "100 / 10 / 2"
```
```text:実行結果
1.0
3.0
6.0
-4.0
2.0
10.0
14.0
20.0
5.0
```

失敗系の処理を抽象化していないため冗長です。

# モナド変換子

※ 発展的な内容です。難しければ読み飛ばしても構いません。

失敗系の処理はMaybeモナドで表現できるため、モナド変換子でStateモナドと合成を試みます。

Maybeモナドやモナド変換子については以下を参照してください。

* [Haskell Maybeモナド 超入門](http://qiita.com/7shi/items/c7d7eec066af0fe0688d)
* [Haskell モナド変換子 超入門](http://qiita.com/7shi/items/4408b76624067c17e933)

## Maybeモナド

パターンマッチはMaybeモナドで表現できます。`do`の中で`Nothing`が現れると評価が中断されるのを`<|>`でリカバーします。

```hs
import Control.Applicative
import Control.Monad
import Data.Maybe

test1 "a" = 1
test1 "b" = 2

test2 x = fromJust $
    do
        guard $ x == "a"
        return 1
    <|> do
        guard $ x == "b"
        return 2

main = do
    print (test1 "a", test2 "a")
    print (test1 "b", test2 "b")
```
```text:実行結果
(1,1)
(2,2)
```

パターンマッチの失敗については以下を参照してください。

* [MaybeとStateを合成: パターンマッチの失敗](http://qiita.com/7shi/items/12036631dad1979a273b#%E3%83%91%E3%82%BF%E3%83%BC%E3%83%B3%E3%83%9E%E3%83%83%E3%83%81%E3%81%AE%E5%A4%B1%E6%95%97) 2015.4.24

## 合成

StateTモナド変換子でMaybeモナドを合成すれば、StateモナドとMaybeモナドの性質を同時に利用できます。

```hs
import Data.Maybe
import Control.Monad.State
import Control.Applicative

is x = StateT is where
    is (y:ys) | x == y = Just (y, ys)
    is _               = Nothing

pop = StateT pop where
    pop (x:xs) = Just (x, xs)
    pop _      = Nothing

eval src = fromJust $ evalStateT expr $ words src

expr = term >>= expr'
expr' x = do is "+"; (x +) <$> term >>= expr'
      <|> do is "-"; (x -) <$> term >>= expr'
      <|> return x

term = factor >>= term'
term' x = do is "*"; (x *) <$> factor >>= term'
      <|> do is "/"; (x /) <$> factor >>= term'
      <|> return x

factor  = do is "("; x <- expr; is ")"; return x
      <|> read <$> pop

main = do
    print $ eval "1"
    print $ eval "1 + 2"
    print $ eval "1 + 2 + 3"
    print $ eval "1 - 2 - 3"
    print $ eval "1 - 2 + 3"
    print $ eval "2 * 3 + 4"
    print $ eval "2 + 3 * 4"
    print $ eval "( 2 + 3 ) * 4"
    print $ eval "100 / 10 / 2"
```
```text:実行結果
1.0
3.0
6.0
-4.0
2.0
10.0
14.0
20.0
5.0
```

手続きが省略され形式的になっています。モナドによるDSLだと言えます。モナドによる構文解析（パーサコンビネータ）もこの延長線上にあります。

Maybeモナドの役割については、以下の記事を参照してください。

* [Maybeモナドによる中置記法の処理](http://qiita.com/7shi/items/cda901af6abb732f9c64)

# BNF

ここまで実装したような処理はBNF（[バッカス・ナウア記法](https://ja.wikipedia.org/wiki/%E3%83%90%E3%83%83%E3%82%AB%E3%82%B9%E3%83%BB%E3%83%8A%E3%82%A6%E3%82%A2%E8%A8%98%E6%B3%95)）と呼ばれる形式言語で記述できます。

拡張版の[EBNF](https://ja.wikipedia.org/wiki/EBNF)で示します。

```text:EBNF
expr   = term  , {"+"|"-",  term  }
term   = factor, {"*"|"/",  factor}
factor = ("(", expr, ")") | number
```

## 変形

今回のコードに合わせてEBNFを変形します。

`expr`と`term`の内部を分割します。

```text:EBNF
expr   = term, expr'
expr'  = {"+"|"-", term}
term   = factor, term'
term'  = {"*"|"/", factor}
factor = ("(", expr, ")") | number
```

ループを再帰で表現します。

```text:EBNF
expr   = term, [expr']
expr'  = "+"|"-", term, [expr']
term   = factor, [term']
term'  = "*"|"/", factor, [term']
factor = ("(", expr, ")") | number
```

演算子それぞれに処理を記述します。

```text:EBNF
expr   = term, [expr']
expr'  = ("+", term, [expr']) | ("-", term, [expr'])
term   = factor, [term']
term'  = ("*", factor, [term']) | ("/", factor, [term'])
factor = ("(", expr, ")") | number
```

この変形は数式の展開に似ています。

例: $(a + b)xy = axy + bxy$

## 比較

コードにコメントとして追記するので比較してください。モナドによるDSLはBNFを意識しています。

```hs:比較
-- expr = term, [expr']
expr = term >>= expr'
-- expr' = ("+", term, [expr']) | ("-", term, [expr'])
expr' x = do is "+"; (x +) <$> term >>= expr'
      <|> do is "-"; (x -) <$> term >>= expr'
      <|> return x

-- term = factor, [term']
term = factor >>= term'
-- term' = ("*", factor, [term']) | ("/", factor, [term'])
term' x = do is "*"; (x *) <$> factor >>= term'
      <|> do is "/"; (x /) <$> factor >>= term'
      <|> return x

-- factor = ("(", expr, ")") | number
factor  = do is "("; x <- expr; is ")"; return x
      <|> read <$> pop
```

慣れて来れば、先にBNFで定義してからコードを書いた方が効率的だと感じるでしょう。
