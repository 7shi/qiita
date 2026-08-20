---
coediting: false
comments_count: 0
created_at: '2015-07-31T15:47:02+09:00'
id: b8c741e78a96ea2c10fe
likes_count: 92
private: false
reactions_count: 0
stocks_count: 74
tags:
- name: Haskell
  versions: []
- name: parsec
  versions: []
title: Haskell 構文解析 超入門
updated_at: '2026-08-20T10:10:23+09:00'
url: https://qiita.com/7shi/items/b8c741e78a96ea2c10fe
slide: false
---

Haskellではモナドと呼ばれる部品を組み合わせて構文解析を行います。この方式をパーサコンビネータと呼びます。動作原理を簡単に説明しながら使い方の初歩を説明します。Parsecというライブラリで簡単な四則演算器を作成します。

シリーズの記事です。

1. [Haskell 超入門](http://qiita.com/7shi/items/145f1234f8ec2af923ef)
1. [Haskell 代数的データ型 超入門](http://qiita.com/7shi/items/1ce76bde464b4a55c143)
1. [Haskell アクション 超入門](http://qiita.com/7shi/items/85afd7bbd5d6c4115ad6)
1. [Haskell ラムダ 超入門](http://qiita.com/7shi/items/1345bf32003faff435cb)
1. [Haskell アクションとラムダ 超入門](http://qiita.com/7shi/items/4a8a2807bb5186576c61)
1. [Haskell IOモナド 超入門](http://qiita.com/7shi/items/d3d3492ddd90d47160f2)
1. [Haskell リストモナド 超入門](http://qiita.com/7shi/items/deb19c4cba933590ffbf)
1. [Haskell Maybeモナド 超入門](http://qiita.com/7shi/items/c7d7eec066af0fe0688d)
1. [Haskell 状態系モナド 超入門](http://qiita.com/7shi/items/2e9bff5d88302de1a9e9)
1. [Haskell モナド変換子 超入門](http://qiita.com/7shi/items/4408b76624067c17e933)
1. [Haskell 例外処理 超入門](http://qiita.com/7shi/items/73e534c47bbebc71b37e)
1. **Haskell 構文解析 超入門** ← この記事
1. [Haskell 継続モナド 超入門](https://zenn.dev/7shi/articles/20260803-haskell-continuation-monad)
1. [Haskell 型クラス 超入門](https://zenn.dev/7shi/articles/20260805-haskell-type-classes)
1. [Haskell モナドとゆかいな仲間たち](https://zenn.dev/7shi/articles/20260807-haskell-monads-and-friends)
1. [Haskell Freeモナド 超入門](https://zenn.dev/7shi/articles/20260808-haskell-free-monad)
1. [Haskell Operationalモナド 超入門](https://zenn.dev/7shi/articles/20260809-haskell-operational-monad)
1. [Haskell Effモナド 超入門](https://zenn.dev/7shi/articles/20260811-haskell-eff-monad)
1. [Haskell アロー 超入門](https://zenn.dev/7shi/articles/20260813-haskell-arrow)
1. [Haskell 圏論 超入門](https://zenn.dev/7shi/articles/20260820-haskell-category-theory)

練習の解答例は別記事に掲載します。

* [【解答例】Haskell 構文解析 超入門](http://qiita.com/7shi/items/f65814b1e91d48ec8d12)

この記事には関連記事があります。

* [Stateモナドによる中置記法の処理](http://qiita.com/7shi/items/ee5afe4f088f0a1fc8c2)

この記事には他言語版があります。

* [C++11 パーサコンビネータ 超入門](http://qiita.com/7shi/items/6a12160276a8db358e34) 2015.11.27
* [C++11 パーサコンビネータ 超入門 2](http://qiita.com/7shi/items/f86f2f7ad68cfff1b399) 2015.11.30
* [Java パーサコンビネータ 超入門](http://qiita.com/7shi/items/68228e19552c271bea81) 2016.05.12
* [Java パーサコンビネータ 超入門 2](http://qiita.com/7shi/items/39a9ddffcc5bdf2c0142) 2016.05.14

この記事には関連記事があります。

* [JSONパーサーを作る](http://qiita.com/7shi/items/04c2991239894687ef2f) 2016.12.26

# 動作原理

パーサコンビネータとは単純なパーサ（構文解析器）を組み合わせることで複雑な構文解析にも対応できる仕組みです。その動作原理をなるべく平易な実装で説明します。

## モナドなし

まずモナドなしでパーサを作ります。

### 1文字取得

指定した文字列から先頭の1文字を取得します。

```hs
anyChar (x:_) = x

main = do
    print $ anyChar "abc"
```
```text:実行結果
'a'
```

`anyChar`が最初のパーサです。

### 連続呼び出し

`anyChar`を連続呼び出しすることで複数文字を取得できるように拡張します。

まだ読み取っていない残りの文字列をタプルで返せば、次の呼び出しで次の文字が取得できます。

```hs
anyChar (x:xs) = (x, xs)

main = do
    let r1 = anyChar "abc"
        r2 = anyChar $ snd r1
    print r1
    print r2
```
```text:実行結果
('a',"bc")
('b',"c")
```

### 結果の分離

結果として返されるタプルの中身を分離して受け取ります。

```hs
anyChar (x:xs) = (x, xs)

main = do
    let (x1, xs1) = anyChar "abc"
        (x2, xs2) = anyChar xs1
    print [x1, x2]
```
```text:実行結果
"ab"
```

`anyChar`を2回繰り返すことで、先頭から2文字取得しています。

### 関数化

2文字取得する部分を関数化します。

```hs
anyChar (x:xs) = (x, xs)

test1 xs0 =                      -- 関数化
    let (x1, xs1) = anyChar xs0
        (x2, xs2) = anyChar xs1
    in [x1, x2]

main = do
    print $ anyChar "abc"
    print $ test1   "abc"
```
```text:実行結果
('a',"bc")
"ab"
```

### 組み合わせ

`test1`も残りの文字列を返すようにすれば、別の箇所で`anyChar`と組み合わせて利用できるようになります。

```hs
anyChar (x:xs) = (x, xs)

test1 xs0 =
    let (x1, xs1) = anyChar xs0
        (x2, xs2) = anyChar xs1
    in ([x1, x2], xs2)           -- 残りの文字列を返す

test2 xs0 =
    let (x1, xs1) = test1   xs0  -- test1で処理した残りを
        (x2, xs2) = anyChar xs1  -- anyCharで処理する
    in (x1 ++ [x2], xs2)

main = do
    print $ anyChar "abc"
    print $ test1   "abc"
    print $ test2   "abc"        -- 追加
```
```text:実行結果
('a',"bc")
("ab","c")
("abc","")
```

`test1`は`anyChar`を2つ組み合わせて作ったパーサです。`test2`は`test1`と`anyChar`を組み合わせて作ったパーサです。このように簡単なパーサを組み合わせて複雑なパーサを作っていくのが、パーサコンビネータの基本的な考え方です。

`main`の中で`anyChar`と`test1`と`test2`が同列に並んでいますが、どれもパーサとして同じような位置付けだと見立ててください。

### エラー

文字数が足りなければエラーで止まります。

```hs
anyChar (x:xs) = (x, xs)

test1 xs0 =
    let (x1, xs1) = anyChar xs0
        (x2, xs2) = anyChar xs1
    in ([x1, x2], xs2)

test2 xs0 =
    let (x1, xs1) = test1   xs0
        (x2, xs2) = anyChar xs1
    in (x1 ++ [x2], xs2)

main = do
    print $ anyChar "abc"
    print $ test1   "abc"
    print $ test2   "abc"
    print $ test2   "12"   -- エラー
    print $ test2   "123"  -- ここに来ない
```
```text:実行結果
('a',"bc")
("ab","c")
("abc","")
xxx: Main.hs:1:1-24: Non-exhaustive patterns in function anyChar

```

### テスト関数

エラーが出ても続行できるように、テスト用の関数`parseTest`を作成して例外を処理します。

```hs
import Control.Exception           -- 追加

parseTest p s = do                 -- 追加
    print $ fst $ p s              -- タプルの第1要素を表示
    `catch` \(SomeException e) ->
        putStr $ show e

anyChar (x:xs) = (x, xs)

test1 xs0 =
    let (x1, xs1) = anyChar xs0
        (x2, xs2) = anyChar xs1
    in ([x1, x2], xs2)

test2 xs0 =
    let (x1, xs1) = test1   xs0
        (x2, xs2) = anyChar xs1
    in (x1 ++ [x2], xs2)

main = do
    parseTest anyChar "abc"
    parseTest test1   "abc"
    parseTest test2   "abc"
    parseTest test2   "12"         -- エラー
    parseTest test2   "123"        -- 続行
```
```text:実行結果
'a'
"ab"
"abc"
Main.hs:8:1-24: Non-exhaustive patterns in function anyChar
"123"
```

### 条件取得

`anyChar`は無条件で文字を取得していましたが、条件が指定できる`satisfy`を追加します。

```hs
import Control.Exception
import Data.Char                        -- 追加

parseTest p s = do
    print $ fst $ p s
    `catch` \(SomeException e) ->
        putStr $ show e

anyChar   (x:xs)       = (x, xs)
satisfy f (x:xs) | f x = (x, xs)        -- 追加

main = do
    parseTest (satisfy (== 'a')) "abc"  -- OK
    parseTest (satisfy (== 'a')) "123"  -- NG
    parseTest (satisfy isDigit ) "abc"  -- NG
    parseTest (satisfy isDigit ) "123"  -- OK
```
```text:実行結果
'a'
Main.hs:10:1-32: Non-exhaustive patterns in function satisfy
Main.hs:10:1-32: Non-exhaustive patterns in function satisfy
'1'
```

今回の機能追加に直接関係ない`test1`と`test2`は削除しました。

### 事前定義

`satisfy`で条件を指定するのは冗長なので、よく使うパターンを事前定義します。

```hs
import Control.Exception
import Data.Char

parseTest p s = do
    print $ fst $ p s
    `catch` \(SomeException e) ->
        putStr $ show e

anyChar   (x:xs)       = (x, xs)
satisfy f (x:xs) | f x = (x, xs)

char c = satisfy (== c)         -- 追加
digit  = satisfy isDigit        -- 追加
letter = satisfy isLetter       -- 追加

main = do
    parseTest (char 'a') "abc"  -- OK
    parseTest (char 'a') "123"  -- NG
    parseTest digit  "abc"      -- NG
    parseTest digit  "123"      -- OK
    parseTest letter "abc"      -- OK
    parseTest letter "123"      -- NG
```
```text:実行結果
'a'
Main.hs:10:1-32: Non-exhaustive patterns in function satisfy
Main.hs:10:1-32: Non-exhaustive patterns in function satisfy
'1'
'a'
Main.hs:10:1-32: Non-exhaustive patterns in function satisfy
```

### 組み合わせ判定

先ほど追加したパーサを組み合わせて、先頭から「アルファベット」「数字」「数字」という組み合わせを判定するパーサを示します。

```hs
import Control.Exception
import Data.Char

parseTest p s = do
    print $ fst $ p s
    `catch` \(SomeException e) ->
        putStr $ show e

anyChar   (x:xs)       = (x, xs)
satisfy f (x:xs) | f x = (x, xs)

char c = satisfy (== c)
digit  = satisfy isDigit
letter = satisfy isLetter

test3 xs0 =                     -- 追加
    let (x1, xs1) = letter xs0
        (x2, xs2) = digit  xs1
        (x3, xs3) = digit  xs2
    in ([x1, x2, x3], xs3)

main = do
    parseTest test3 "abc"       -- NG
    parseTest test3 "123"       -- NG
    parseTest test3 "a23"       -- OK
    parseTest test3 "a234"      -- OK
```
```text:実行結果
Main.hs:10:1-32: Non-exhaustive patterns in function satisfy
Main.hs:10:1-32: Non-exhaustive patterns in function satisfy
"a23"
"a23"
```

### まとめ

ここまでがパーサコンビネータの動作原理を理解するために最低限必要な実装です。登場したテストを1つにまとめます。

```hs
import Control.Exception
import Data.Char

parseTest p s = do
    print $ fst $ p s
    `catch` \(SomeException e) ->
        putStr $ show e

anyChar   (x:xs)       = (x, xs)
satisfy f (x:xs) | f x = (x, xs)

char c = satisfy (== c)
digit  = satisfy isDigit
letter = satisfy isLetter

test1 xs0 =
    let (x1, xs1) = anyChar xs0
        (x2, xs2) = anyChar xs1
    in ([x1, x2], xs2)

test2 xs0 =
    let (x1, xs1) = test1   xs0
        (x2, xs2) = anyChar xs1
    in (x1 ++ [x2], xs2)

test3 xs0 =
    let (x1, xs1) = letter xs0
        (x2, xs2) = digit  xs1
        (x3, xs3) = digit  xs2
    in ([x1, x2, x3], xs3)

main = do
    parseTest anyChar "abc"
    parseTest test1   "abc"
    parseTest test2   "abc"
    parseTest test2   "12"      -- NG
    parseTest test2   "123"
    parseTest (char 'a') "abc"
    parseTest (char 'a') "123"  -- NG
    parseTest digit  "abc"      -- NG
    parseTest digit  "123"
    parseTest letter "abc"
    parseTest letter "123"      -- NG
    parseTest test3  "abc"      -- NG
    parseTest test3  "123"      -- NG
    parseTest test3  "a23"
    parseTest test3  "a234"
```
```text:実行結果
'a'
"ab"
"abc"
Main.hs:9:1-32: Non-exhaustive patterns in function anyChar
"123"
'a'
Main.hs:10:1-32: Non-exhaustive patterns in function satisfy
Main.hs:10:1-32: Non-exhaustive patterns in function satisfy
'1'
'a'
Main.hs:10:1-32: Non-exhaustive patterns in function satisfy
Main.hs:10:1-32: Non-exhaustive patterns in function satisfy
Main.hs:10:1-32: Non-exhaustive patterns in function satisfy
"a23"
"a23"
```

このコードをモナドで書き換えて、足りない機能を追加します。

## Stateモナド

解析対象の文字列を状態と見なせばStateモナドが使えます。👉[状態系モナド](https://qiita.com/7shi/items/2e9bff5d88302de1a9e9#stateモナド)

### 練習

【問1】モナドなしのまとめのコードをStateモナドを使って書き換えてください。

⇒ [解答例](http://qiita.com/7shi/items/f65814b1e91d48ec8d12#stateモナド)

引数が減ってコードが短くなります。元の`test1`などにあった `xs0` → `xs1` → `xs2` という状態の受け渡しが省略されたことで、変数名の管理も簡単になります。

### sequence

モナド化したことで連続した文字取得は`sequence`を使って簡単に書けます。

競合を避けるためControl.Applicativeは選択的に`import`します。選択する対象全体を括弧で囲みますが、演算子は個別に括弧で囲むため、結果として二重に括弧で囲むことになります。

```hs
import Control.Exception
import Control.Applicative ((<$>), (<*>))      -- 選択的import
import Control.Monad
import Control.Monad.State
import Data.Char

parseTest p s = do
    print $ evalState p s
    `catch` \(SomeException e) ->
        putStr $ show e

anyChar = state $ anyChar where
    anyChar (x:xs) = (x, xs)

satisfy :: (Char -> Bool) -> State String Char
satisfy f = state $ satisfy where
    satisfy (x:xs) | f x = (x, xs)

char c = satisfy (== c)
digit  = satisfy isDigit
letter = satisfy isLetter

test1 = sequence [anyChar, anyChar]            -- 単純化
test2 = (++) <$> test1 <*> sequence [anyChar]  -- 少しややこしい
test3 = sequence [letter, digit, digit]        -- 単純化

main = do
    parseTest test1 "abc"
    parseTest test2 "abc"
    parseTest test2 "12"                       -- NG
    parseTest test2 "123"
    parseTest test3 "abc"                      -- NG
    parseTest test3 "123"                      -- NG
    parseTest test3 "a23"
    parseTest test3 "a234"
```
```text:実行結果
"ab"
"abc"
Main.hs:13:5-28: Non-exhaustive patterns in function anyChar
"123"
Main.hs:17:5-34: Non-exhaustive patterns in function satisfy
Main.hs:17:5-34: Non-exhaustive patterns in function satisfy
"a23"
"a23"
```

## Maybeモナド

Maybeモナドを使えば例外を使わずに失敗が扱えます。👉[Maybeモナド](https://qiita.com/7shi/items/c7d7eec066af0fe0688d#maybeモナド)

### 練習

【問2】モナドなしのまとめのコードをMaybeモナドを使って書き換えてください。

⇒ [解答例](http://qiita.com/7shi/items/f65814b1e91d48ec8d12#maybeモナド)

## Eitherモナド

Maybeモナドにより例外処理をなくしても、失敗はすべて`Nothing`のため理由がよく分かりません。👉[例外処理](https://qiita.com/7shi/items/73e534c47bbebc71b37e#eitherモナド)

Eitherモナドを使って、失敗した理由を`Left`で返します。Either用の`<|>`を独自に定義します。

```hs
import Data.Char

parseTest p s = case p s of
    Right (r, _) -> print r
    Left  e      -> putStrLn $ "[" ++ show s ++ "] " ++ e

anyChar (x:xs) = Right (x, xs)
anyChar _      = Left "too short"

satisfy f (x:xs) | not $ f x = Left $ ": " ++ show x
satisfy f    xs              = anyChar xs

Left a <|> Left b = Left $ b ++ a
Left _ <|> b      = b
a      <|> _      = a

char c xs = satisfy (== c)   xs <|> Left ("not char " ++ show c)
digit  xs = satisfy isDigit  xs <|> Left "not digit"
letter xs = satisfy isLetter xs <|> Left "not letter"

test1 xs0 = do
    (x1, xs1) <- anyChar xs0
    (x2, xs2) <- anyChar xs1
    return ([x1, x2], xs2)

test2 xs0 = do
    (x1, xs1) <- test1   xs0
    (x2, xs2) <- anyChar xs1
    return (x1 ++ [x2], xs2)

test3 xs0 = do
    (x1, xs1) <- letter xs0
    (x2, xs2) <- digit  xs1
    (x3, xs3) <- digit  xs2
    return ([x1, x2, x3], xs3)

main = do
    parseTest anyChar "abc"
    parseTest test1   "abc"
    parseTest test2   "abc"
    parseTest test2   "12"      -- NG
    parseTest test2   "123"
    parseTest (char 'a') "abc"
    parseTest (char 'a') "123"  -- NG
    parseTest digit  "abc"      -- NG
    parseTest digit  "123"
    parseTest letter "abc"
    parseTest letter "123"      -- NG
    parseTest test3  "abc"      -- NG
    parseTest test3  "123"      -- NG
    parseTest test3  "a23"
    parseTest test3  "a234"
```
```text:実行結果
'a'
"ab"
"abc"
["12"] too short
"123"
'a'
["123"] not char 'a': '1'
["abc"] not digit: 'a'
'1'
'a'
["123"] not letter: '1'
["abc"] not digit: 'b'
["123"] not letter: '1'
"a23"
"a23"
```

エラーメッセージをカスタマイズして分かりやすくなりました。

## モナド変換子で合成

StateTモナド変換子でEitherモナドと合成すれば、StateモナドとEitherモナドの両方の特徴が使えます。

```hs
import Control.Applicative ((<$>), (<*>))
import Control.Monad
import Control.Monad.State
import Data.Char

parseTest p s = case evalStateT p s of
    Right r -> print r
    Left  e -> putStrLn $ "[" ++ show s ++ "] " ++ e

anyChar = StateT $ anyChar where
    anyChar (x:xs) = Right (x, xs)
    anyChar _      = Left "too short"

satisfy f = StateT $ satisfy where
    satisfy (x:xs) | not $ f x = Left $ ": " ++ show x
    satisfy    xs              = runStateT anyChar xs

(StateT a) <|> (StateT b) = StateT $ \s ->
    (a s)  <|> (b s) where
    Left a <|> Left b = Left $ b ++ a
    Left _ <|> b      = b
    a      <|> _      = a

left = lift . Left

char c = satisfy (== c)   <|> left ("not char " ++ show c)
digit  = satisfy isDigit  <|> left "not digit"
letter = satisfy isLetter <|> left "not letter"

test1 = sequence [anyChar, anyChar]
test2 = (++) <$> test1 <*> sequence [anyChar]
test3 = sequence [letter, digit, digit]

main = do
    parseTest anyChar "abc"
    parseTest test1   "abc"
    parseTest test2   "abc"
    parseTest test2   "12"      -- NG
    parseTest test2   "123"
    parseTest (char 'a') "abc"
    parseTest (char 'a') "123"  -- NG
    parseTest digit  "abc"      -- NG
    parseTest digit  "123"
    parseTest letter "abc"
    parseTest letter "123"      -- NG
    parseTest test3  "abc"      -- NG
    parseTest test3  "123"      -- NG
    parseTest test3  "a23"
    parseTest test3  "a234"
```
```text:実行結果
'a'
"ab"
"abc"
["12"] too short
"123"
'a'
["123"] not char 'a': '1'
["abc"] not digit: 'a'
'1'
'a'
["123"] not letter: '1'
["abc"] not digit: 'b'
["123"] not letter: '1'
"a23"
"a23"
```

合成による複雑さが`<|>`に集約されています。こういったものは通常はライブラリが用意するので、あまり意識する必要はない部分ではあります。

### 選択

`<|>`を使えば「アルファベットまたは数字」のような選択的なパーサを構築できます。👉[Maybeモナド](https://qiita.com/7shi/items/c7d7eec066af0fe0688d#alternative)

```hs
import Control.Applicative ((<$>), (<*>))
import Control.Monad
import Control.Monad.State
import Data.Char

parseTest p s = case evalStateT p s of
    Right r -> print r
    Left  e -> putStrLn $ "[" ++ show s ++ "] " ++ e

anyChar = StateT $ anyChar where
    anyChar (x:xs) = Right (x, xs)
    anyChar _      = Left "too short"

satisfy f = StateT $ satisfy where
    satisfy (x:xs) | not $ f x = Left $ ": " ++ show x
    satisfy    xs              = runStateT anyChar xs

(StateT a) <|> (StateT b) = StateT $ \s ->
    (a s)  <|> (b s) where
    Left a <|> Left b = Left $ b ++ a
    Left _ <|> b      = b
    a      <|> _      = a

left = lift . Left

char c = satisfy (== c)   <|> left ("not char " ++ show c)
digit  = satisfy isDigit  <|> left "not digit"
letter = satisfy isLetter <|> left "not letter"

test4 = letter <|> digit  -- 選択

main = do
    parseTest test4 "a"   -- OK
    parseTest test4 "1"   -- OK
    parseTest test4 "!"   -- NG
```
```text:実行結果
'a'
'1'
["!"] not digit: '!'not letter: '!'
```

エラーがごちゃごちゃしていますが、動作原理の説明が目的のため気にしないことにします。

### 関数で繰り返し

モナドは関数で繰り返しを表現できます。「先頭がアルファベットで、その後に3桁の数字が続く」というパーサを見てみます。

```hs
import Control.Applicative ((<$>), (<*>))
import Control.Monad
import Control.Monad.State
import Data.Char

parseTest p s = case evalStateT p s of
    Right r -> print r
    Left  e -> putStrLn $ "[" ++ show s ++ "] " ++ e

anyChar = StateT $ anyChar where
    anyChar (x:xs) = Right (x, xs)
    anyChar _      = Left "too short"

satisfy f = StateT $ satisfy where
    satisfy (x:xs) | not $ f x = Left $ ": " ++ show x
    satisfy    xs              = runStateT anyChar xs

(StateT a) <|> (StateT b) = StateT $ \s ->
    (a s)  <|> (b s) where
    Left a <|> Left b = Left $ b ++ a
    Left _ <|> b      = b
    a      <|> _      = a

left = lift . Left

char c = satisfy (== c)   <|> left ("not char " ++ show c)
digit  = satisfy isDigit  <|> left "not digit"
letter = satisfy isLetter <|> left "not letter"

test5 = sequence [letter, digit, digit, digit]  -- ベタ書き
test6 = sequence $ letter : replicate 3 digit   -- 関数使用

main = do
    parseTest test5 "a123"                      -- OK
    parseTest test5 "ab123"                     -- NG
    parseTest test6 "a123"                      -- OK
    parseTest test6 "ab123"                     -- NG
```
```text:実行結果
"a123"
["ab123"] not digit: 'b'
"a123"
["ab123"] not digit: 'b'
```

文字通り「モナドを部品として組み合わせてパーサを構築」というコードです。工夫すれば色々できそうだと気付けばしめたものです。

## 練習

【問3】指定したパーサを0回以上適用して返すコンビネータ`many`を実装してください。

具体的には次のコードが動くようにしてください。

```hs
test7 = many letter
test8 = many (letter <|> digit)

main = do
    parseTest test7 "abc123"
    parseTest test7 "123abc"
    parseTest test8 "abc123"
    parseTest test8 "123abc"
```
```text:実行結果
"abc"
""
"abc123"
"123abc"
```

⇒ [解答例](http://qiita.com/7shi/items/f65814b1e91d48ec8d12#many)

# Parsec

ここまで実装して来たパーサはすべてParsecというライブラリで提供されています。Parsecと関数名を合わせたため、今までのテストがそのまま実行できます。

依存パッケージ: [parsec](https://hackage.haskell.org/package/parsec)

```hs
import Text.Parsec
import Control.Applicative ((<$>), (<*>))

test1 = sequence [anyChar, anyChar]
test2 = (++) <$> test1 <*> sequence [anyChar]
test3 = sequence [letter, digit, digit]
test4 = letter <|> digit
test5 = sequence [letter, digit, digit, digit]
test6 = sequence $ letter : replicate 3 digit
test7 = many letter
test8 = many (letter <|> digit)

main = do
    parseTest anyChar "abc"
    parseTest test1   "abc"
    parseTest test2   "abc"
    parseTest test2   "12"      -- NG
    parseTest test2   "123"
    parseTest (char 'a') "abc"
    parseTest (char 'a') "123"  -- NG
    parseTest digit  "abc"      -- NG
    parseTest digit  "123"
    parseTest letter "abc"
    parseTest letter "123"      -- NG
    parseTest test3  "abc"      -- NG
    parseTest test3  "123"      -- NG
    parseTest test3  "a23"
    parseTest test3  "a234"
    parseTest test4  "a"
    parseTest test4  "1"
    parseTest test4  "!"        -- NG
    parseTest test5  "a123"
    parseTest test5  "ab123"    -- NG
    parseTest test6  "a123"
    parseTest test6  "ab123"    -- NG
    parseTest test7  "abc123"
    parseTest test7  "123abc"
    parseTest test8  "abc123"
    parseTest test8  "123abc"
```
```text:実行結果
'a'
"ab"
"abc"
parse error at (line 1, column 3):
unexpected end of input
"123"
'a'
parse error at (line 1, column 1):
unexpected "1"
expecting "a"
parse error at (line 1, column 1):
unexpected "a"
expecting digit
'1'
'a'
parse error at (line 1, column 1):
unexpected "1"
expecting letter
parse error at (line 1, column 2):
unexpected "b"
expecting digit
parse error at (line 1, column 1):
unexpected "1"
expecting letter
"a23"
"a23"
'a'
'1'
parse error at (line 1, column 1):
unexpected "!"
expecting letter or digit
"a123"
parse error at (line 1, column 2):
unexpected "b"
expecting digit
"a123"
parse error at (line 1, column 2):
unexpected "b"
expecting digit
"abc"
""
"abc123"
"123abc"
```

エラーメッセージが詳細です。

## エラーチェック

Parsecでは`<|>`でエラーが細かくチェックされます。

`左 <|> 右`として、左のパーサが内部で複数のパーサから構成されるとき、そのうち1つでも成功してその後で失敗したなら、右のパーサは処理されずにエラーとなります。

```hs
import Text.Parsec

test9 = sequence [char 'a', char 'b']  -- 'a'が成功して'b'で失敗したらエラー
    <|> sequence [char 'a', char 'c']

main = do
    parseTest test9 "ab"
    parseTest test9 "ac"
```
```text:実行結果
"ab"
parse error at (line 1, column 2):
unexpected "c"
expecting "b"
```

この挙動を把握しておかないとハマります。

### 練習

【問4】問3の解答の自前実装では失敗時に返される`Left`に状態が含まれず、1つでも成功していたかが判断できません。`left`を次のように修正することで状態を返して、Parsecと同じようにエラーをチェックしてください。

```hs
left e = StateT $ \s -> Left (e, s)
```

具体的には次のコードで2番目のテストが失敗するようにしてください。

```hs
test9 = sequence [char 'a', char 'b']
    <|> sequence [char 'a', char 'c']

main = do
    parseTest test9 "ab"
    parseTest test9 "ac"
```
```text:実行結果
"ab"
["ac"] not char 'b': 'c'
```

⇒ [解答例](http://qiita.com/7shi/items/f65814b1e91d48ec8d12#エラーチェック)

## バックトラック

パースに失敗したとき、状態を巻き戻して別の方法でパースをやり直すことを**バックトラック**と呼びます。

### try

バックトラックするには対象となるパーサを`try`で囲みます。失敗すると元の状態に戻って`<|>`の右のパーサが処理されます。

※ 例外処理の`try`と同名ですが、別の関数です。

エラーチェックで登場した`test9`と挙動を比較します。

```hs
import Text.Parsec

test9 = sequence [char 'a', char 'b']
    <|> sequence [char 'a', char 'c']
test10 = try (sequence [char 'a', char 'b'])
         <|>  sequence [char 'a', char 'c']

main = do
    parseTest test9  "ab"
    parseTest test9  "ac"
    parseTest test10 "ab"
    parseTest test10 "ac"
```
```text:実行結果
"ab"
parse error at (line 1, column 2):
unexpected "c"
expecting "b"
"ab"
"ac"
```

### string

1文字ずつ`char`でパースしなくても、文字列で指定できる`string`があります。ただし内部では1文字ずつ処理されているため、途中の失敗をバックトラックするには`try`が必要です。

挙動の違いを比較します。

```hs
import Text.Parsec

test11 =      string "ab"  <|> string "ac"
test12 = try (string "ab") <|> string "ac"

main = do
    parseTest test11 "ab"
    parseTest test11 "ac"
    parseTest test12 "ab"
    parseTest test12 "ac"
```
```text:実行結果
"ab"
parse error at (line 1, column 1):
unexpected "c"
expecting "ab"
"ab"
"ac"
```

デフォルトのトランザクションの範囲は`char`で、`string`**ではない**と解釈できます。`try`によってトランザクションの範囲を広げることになります。

### LL(1)

バックトラックなしで処理できる文法をLL(1)文法と呼びます。

* [LL法 - Wikipedia](https://ja.wikipedia.org/wiki/LL%E6%B3%95)

以下の記事にParsecはLL(1)で最高の性能を発揮するとあります。

* [@kazu_yamamoto](https://twitter.com/kazu_yamamoto): [とりとめのないパーサー談義 - あどけない話](http://d.hatena.ne.jp/kazu-yamamoto/20081201/1228115457) 2008.12.1

先ほどの`test10`は、重複する`char 'a'`をまとめることでバックトラックのないLL(1)となります。両者を比較します。

```hs
import Text.Parsec

test10 = try (sequence [char 'a', char 'b'])
         <|>  sequence [char 'a', char 'c']
test13 = sequence [char 'a', char 'b' <|> char 'c']

main = do
    parseTest test10 "ab"
    parseTest test10 "ac"
    parseTest test13 "ab"
    parseTest test13 "ac"
```
```text:実行結果
"ab"
"ac"
"ab"
"ac"
```

この例によりLL(1)が高速な理由が直感的に伝わるでしょうか？

`test10`から`test13`への変形は数式の因数分解に似ています。コードでの`<|>`を足し算、`,`を掛け算に見立てます。簡単のため`sequence`を省略して比較します。

<table><tr><th>コード</th><th>数式</th></tr><tr><td><code>[char 'a', char 'b'] &lt;|> [char 'a', char 'c']</code></td><td>$ab + ac$</td></tr><tr><td><code>[char 'a', char 'b' &lt;|> char 'c']</code></td><td>$a(b + c)$</td></tr></table>

### 練習

【問5】問4の解答の自前実装に`try`と`string`を実装してください。

具体的には次のコードが動くようにしてください。

```hs
test10 = try (sequence [char 'a', char 'b'])
         <|>  sequence [char 'a', char 'c']
test11 =      string "ab"  <|> string "ac"
test12 = try (string "ab") <|> string "ac"

main = do
    parseTest test10 "ab"
    parseTest test10 "ac"
    parseTest test11 "ab"
    parseTest test11 "ac"
    parseTest test12 "ab"
    parseTest test12 "ac"
```
```text:実行結果
"ab"
"ac"
"ab"
["ac"] not char 'b': 'c'
"ab"
"ac"
```

⇒ [解答例](http://qiita.com/7shi/items/f65814b1e91d48ec8d12#バックトラック)

# 四則演算器

Parsecの練習として、簡単な四則演算器を作ります。文字列で式を与えると計算して答えを返します。

例: `"1+2*3"` → `7`

ここから先の内容から構文解析に関係する部分を省いて計算だけに特化した記事があります。`many`がないため作り方が少し違います。

* [Stateモナドによる中置記法の処理](http://qiita.com/7shi/items/ee5afe4f088f0a1fc8c2)

## 数字

数字を読み込むパーサを実装します。最低でも1文字は必要なため`many`（0回以上の繰り返し）ではなく`many1`（1回以上の繰り返し）を使います。

```hs
import Text.Parsec

number = many1 digit

main = do
    parseTest number "123"
```
```text:実行結果
"123"
```

### 数値

結果を数値で返すように修正します。

```hs
import Text.Parsec

number = do
    x <- many1 digit
    return (read x :: Int)  -- 変換

main = do
    parseTest number "123"
```
```text:実行結果
123
```

## 足し算

足し算を計算するパーサを実装します。

`'+'`で区切って項を個別に取り出します。

```hs
import Text.Parsec

expr = do                   -- 追加
    x <- number
    char '+'
    y <- number
    return [x, y]

number = do
    x <- many1 digit
    return (read x :: Int)

main = do
    parseTest number "123"
    parseTest expr   "1+2"  -- 追加
```
```text:実行結果
123
[1,2]
```

### many

`+数値`を`many`により0回以上の繰り返しとして扱います。

```hs
import Text.Parsec

expr = do
    x  <- number
    xs <- many $ do           -- 繰り返し
        char '+'
        number
    return $ x:xs             -- 連結

number = do
    x <- many1 digit
    return (read x :: Int)

main = do
    parseTest number "123"
    parseTest expr   "1+2"    -- '+'が1個
    parseTest expr   "123"    -- '+'が0個
    parseTest expr   "1+2+3"  -- '+'が2個
```
```text:実行結果
123
[1,2]
[123]
[1,2,3]
```

### sum

リストを合計すれば計算できます。

```hs
import Text.Parsec

expr = do
    x  <- number
    xs <- many $ do
        char '+'
        number
    return $ sum $ x:xs       -- 合計

number = do
    x <- many1 digit
    return (read x :: Int)

main = do
    parseTest number "123"
    parseTest expr   "1+2"    -- OK
    parseTest expr   "123"    -- OK
    parseTest expr   "1+2+3"  -- OK
```
```text:実行結果
123
3
123
6
```

構文解析と計算を分離せずに同時に処理しているのがポイントです。

## 引き算

マイナスの項を足すとして処理します。

```hs
import Text.Parsec

expr = do
    x  <- number
    xs <- many $ do
            char '+'
            number
        <|> do                -- 追加
            char '-'
            y <- number
            return $ -y       -- マイナスの項
    return $ sum $ x:xs

number = do
    x <- many1 digit
    return (read x :: Int)

main = do
    parseTest number "123"
    parseTest expr   "1+2"
    parseTest expr   "123"
    parseTest expr   "1+2+3"
    parseTest expr   "1-2-3"  -- OK
    parseTest expr   "1-2+3"  -- OK
```
```text:実行結果
123
3
123
6
-4
2
```

## 四則演算

掛け算や割り算は`sum`では処理できないため、`many`で関数のリストを返して`foldl`で畳み込みます。

引き算でセクションを作ろうとすると単項演算子扱いされてしまうため、代用関数`subtract`を使います。

```hs
import Text.Parsec

expr = do
    x  <- number
    fs <- many $ do
            char '+'
            y <- number
            return (+ y)               -- セクション
        <|> do
            char '-'
            y <- number
            return $ subtract y        -- 部分適用
        <|> do                         -- 追加：ここから
            char '*'
            y <- number
            return (* y)
        <|> do
            char '/'
            y <- number
            return (`div` y)           -- 追加：ここまで
    return $ foldl (\x f -> f x) x fs

number = do
    x <- many1 digit
    return (read x :: Int)

main = do
    parseTest number "123"
    parseTest expr   "1+2"
    parseTest expr   "123"
    parseTest expr   "1+2+3"
    parseTest expr   "1-2-3"
    parseTest expr   "1-2+3"
    parseTest expr   "2*3+4"           -- OK
    parseTest expr   "2+3*4"           -- NG
    parseTest expr   "100/10/2"        -- OK
```
```text:実行結果
123
3
123
6
-4
2
10
20
5
```

演算子の優先順位が処理できていません。

### 演算子の優先順位

足し算から見ると、1つの数字と掛け算のブロックは項（term）として対等です。数式で例えると $2x+1$ において $2x$ と $1$ が項という単位として $+$ から並列に扱われていることに相当します。

項単位で計算するように分離すれば演算子の優先順位が表現できます。

```hs
import Text.Parsec

expr = do
    x  <- term                         -- 項を取得
    fs <- many $ do
            char '+'
            y <- term                  -- 項を取得
            return (+ y)
        <|> do
            char '-'
            y <- term                  -- 項を取得
            return $ subtract y
    return $ foldl (\x f -> f x) x fs

term = do                              -- exprと同じ構造
    x  <- number
    fs <- many $ do
            char '*'
            y <- number
            return (* y)
        <|> do
            char '/'
            y <- number
            return (`div` y)
    return $ foldl (\x f -> f x) x fs

number = do
    x <- many1 digit
    return (read x :: Int)

main = do
    parseTest number "123"
    parseTest expr   "1+2"
    parseTest expr   "123"
    parseTest expr   "1+2+3"
    parseTest expr   "1-2-3"
    parseTest expr   "1-2+3"
    parseTest expr   "2*3+4"
    parseTest expr   "2+3*4"           -- OK
    parseTest expr   "100/10/2"
```
```text:実行結果
123
3
123
6
-4
2
10
14
5
```

## 演算子

パースに便利な演算子`<*`を紹介します。Applicativeスタイルの一種です。

`左 <* 右`は右の値を捨てて、左の値を返します。`=<<`と違って評価の流れを記号化したわけではなく、左から右に評価されます。

一時変数を避けるのに使えます。同じ結果になるのを確認してください。

```hs
import Text.Parsec
import Control.Applicative ((<*))

test1 = do
    x <- letter          -- 一時変数に結果を束縛
    digit                -- 文字は確認するが結果は捨てる
    return x             -- 一時変数を返す

test2 = letter <* digit  -- test1と同じ処理

main = do
    parseTest test1 "a1"
    parseTest test2 "a1"
```
```text:実行結果
'a'
'a'
```

逆を指す`*>`もありますが`>>`と同じです。`<*`と`*>`は残す値を指示していると見立てます。

```hs
import Text.Parsec
import Control.Applicative ((<*), (*>))

main = do
    parseTest (sequence [letter,    digit, letter]) "a1c"
    parseTest (sequence [letter <*  digit, letter]) "a1c"
    parseTest (sequence [letter  *> digit, letter]) "a1c"
    parseTest (sequence [letter  >> digit, letter]) "a1c"
```
```text:実行結果
"a1c"
"ac"
"1c"
"1c"
```

## 整理

共通する処理を関数化して、Applicativeスタイルでコードを整理します。処理の流れは同じです。

```hs
import Text.Parsec
import Control.Applicative ((<$>), (<*>), (*>))

eval m fs = foldl (\x f -> f x) <$> m <*> fs
apply f m = flip f <$> m

expr = eval term $ many $
        char '+' *> apply (+) term
    <|> char '-' *> apply (-) term

term = eval number $ many $
        char '*' *> apply (*) number
    <|> char '/' *> apply div number

number = read <$> many1 digit

main = do
    parseTest number "123"
    parseTest expr   "1+2"
    parseTest expr   "123"
    parseTest expr   "1+2+3"
    parseTest expr   "1-2-3"
    parseTest expr   "1-2+3"
    parseTest expr   "2*3+4"
    parseTest expr   "2+3*4"
    parseTest expr   "100/10/2"
```
```text:実行結果
123
3
123
6
-4
2
10
14
5
```

簡潔で形式的な記述になりました。いきなりこのコードを見ても形式的過ぎて理解しにくいかもしれませんが、コードの変形過程を追ってみてください。

## BNF

ここまで実装したような処理はBNF（[バッカス・ナウア記法](https://ja.wikipedia.org/wiki/%E3%83%90%E3%83%83%E3%82%AB%E3%82%B9%E3%83%BB%E3%83%8A%E3%82%A6%E3%82%A2%E8%A8%98%E6%B3%95)）と呼ばれる形式言語で記述できます。

拡張版の[EBNF](https://ja.wikipedia.org/wiki/EBNF)で示します。

```text:EBNF
expr = term  , {"+"|"-", term  }
term = number, {"*"|"/", number}
```

### 変形

今回のコードに合わせてEBNFを変形します。

演算子それぞれに処理を記述します。

```text:EBNF
expr = term  , {("+", term  ) | ("-", term  )}
term = number, {("*", number) | ("/", number)}
```

この変形は数式の展開に似ています。EBNFの`|`を足し算、`,`を掛け算に見立てます。コードでは`<|>`と`*>`に相当します。`*>`は`*`が掛け算っぽいです。

<table><tr><th>種類</th><th>展開前</th><th>展開後</th></tr><tr><td>数式</td><td>$(p + m)t$</td><td>$pt + mt$</td></tr><tr><td>EBNF</td><td><code>"+"|"-", term</code></td><td><code>("+", term) | ("-", term)</code></td></tr><tr><td>コード</td><td><code>(char '+' &lt;|> char '-') *> term</code></td><td><code>char '+' *> term &lt;|> char '-' *> term</code></td></tr></table>

※ `*>`の実体は`>>`と同じで`>>=`に行きつくため（`a >> b = a >>= \_ -> b`）、`>>=`も掛け算だと見立てられることになります。今回の範囲を超えるため詳細は省略します。

### 比較

コードにコメントとして追記するので比較してください。慣れて来れば、先にBNFで定義してからコードを書いた方が効率的だと感じるでしょう。

```hs:比較
-- expr = term, {("+", term) | ("-", term)}
expr = eval term $ many $
        char '+' *> apply (+) term
    <|> char '-' *> apply (-) term

-- term = number, {("*", number) | ("/", number)}
term = eval number $ many $
        char '*' *> apply (*) number
    <|> char '/' *> apply div number
```

このコードはなるべくBNFに近付けるよう意識しています。このような使い方は[ドメイン固有言語](https://ja.wikipedia.org/wiki/%E3%83%89%E3%83%A1%E3%82%A4%E3%83%B3%E5%9B%BA%E6%9C%89%E8%A8%80%E8%AA%9E)（DSL）に見立てられます。

<blockquote class="twitter-tweet" lang="ja"><p lang="ja" dir="ltr">Haskellのモナドは、言語内DSLを定義するための型クラスです。モナドのインスタンスは、何か用のDSLなんだと思えばいいです。それ以上、難しく考える必要はありません。</p>&mdash; 山本和彦 (@kazu_yamamoto) <a href="https://twitter.com/kazu_yamamoto/status/555195571724492800">2015, 1月 14</a></blockquote>

<blockquote class="twitter-tweet" lang="ja"><p lang="ja" dir="ltr">モナドって文字を見たら、言語内DSLに変換して下さい。たとえば、Parser モナドは、Parser 用の DSL です。</p>&mdash; 山本和彦 (@kazu_yamamoto) <a href="https://twitter.com/kazu_yamamoto/status/406047095708082176">2013, 11月 28</a></blockquote>

## 練習

【問6】項の下位に因子（factor）という層を追加して、括弧をサポートしてください。`<*`を使ってください。

具体的には次のコードが動くようにしてください。

```hs
main = do
    parseTest expr "(2+3)*4"
```
```text:実行結果
20
```

ヒント: `factor = ("(", expr, ")") | number`

⇒ [解答例](http://qiita.com/7shi/items/f65814b1e91d48ec8d12#括弧)

【問7】スペースを無視してください。

具体的には次のコードが動くようにしてください。

```hs
main = do
    parseTest expr "1 + 2"
    parseTest expr "123"
    parseTest expr "1 + 2 + 3"
    parseTest expr "1 - 2 - 3"
    parseTest expr "1 - 2 + 3"
    parseTest expr "2 * 3 + 4"
    parseTest expr "2 + 3 * 4"
    parseTest expr "100 / 10 / 2"
    parseTest expr "( 2 + 3 ) * 4"
```
```text:実行結果
3
123
6
-4
2
10
14
5
20
```

ヒント: [spaces](https://hackage.haskell.org/package/parsec-3.1.9/docs/Text-Parsec-Char.html#v:spaces)

⇒ [解答例](http://qiita.com/7shi/items/f65814b1e91d48ec8d12#スペース)

【問8】問7の解答を、Parsecを使わずに問5の解答の自前実装に足りない関数を補って動かしてください。ただし次のように演算子の優先順位を指定する必要があります。

```hs:演算子の優先順位
infixr 1 <|>
```

ヒント: `spaces = skipMany space`

⇒ [解答例](http://qiita.com/7shi/items/f65814b1e91d48ec8d12#自前実装)

# リファレンス

ここまで自前実装すればもう十分でしょう。この先はParsecを使いこなすことに集中する段階です。必要に応じてリファレンスを参照してください。

* [parsec](http://hackage.haskell.org/package/parsec-3.1.9)

よく使うのは以下のモジュールです。

* [Text.Parsec](http://hackage.haskell.org/package/parsec-3.1.9/docs/Text-Parsec.html)
* [Text.Parsec.Char](http://hackage.haskell.org/package/parsec-3.1.9/docs/Text-Parsec-Char.html)

# 実装解説

Parsecのソースは今回の自前実装よりもかなり複雑です。興味があれば@hirataraさんの記事を参照してください。

* 2013.02.14 [Parsecのソースちら見](http://qiita.com/hiratara/items/b10ea9fa5d4e8e471a7c)
* 2013.02.15 [Parsecのソースちら見(2)](http://qiita.com/hiratara/items/755cd0e7f4b4cecf60da)
* 2013.02.15 [Parsecのソースちら見(3)](http://qiita.com/hiratara/items/a451b04fb19bfcc7ff08)

# 謝辞

パーサについては[@kazu_yamamoto](https://twitter.com/kazu_yamamoto)先生よりご教示いただきました。

<blockquote lang="ja"><p lang="ja" dir="ltr">&lt;|&gt; は Alternative 型クラスのメソッドです。import Control.Applicative すれば、Maybe でも &lt;|&gt; は使えます。</p>&mdash; 山本和彦 (@kazu_yamamoto) <a href="https://twitter.com/kazu_yamamoto/status/519030642428747776">2014, 10月 6</a></blockquote>

<blockquote data-conversation="none" lang="ja"><p lang="ja" dir="ltr">Alternative は制限の緩い MonadPlus です。Monad が掛け算、MonadPlus が足し算の系を表します。MonadPlus はもう古いので、忘れて Alternative を使って下さい。</p>&mdash; 山本和彦 (@kazu_yamamoto) <a href="https://twitter.com/kazu_yamamoto/status/519031028040474624">2014, 10月 6</a></blockquote>

<blockquote data-conversation="none" lang="ja"><p lang="ja" dir="ltr">ちなみに Parsec の &lt;|&gt; は、Alternative ではなく、独自実装だったと思います。</p>&mdash; 山本和彦 (@kazu_yamamoto) <a href="https://twitter.com/kazu_yamamoto/status/519031170822975488">2014, 10月 6</a></blockquote>

<blockquote data-conversation="none" lang="ja"><p lang="ja" dir="ltr">Alternative に関しては、このスライドを見ると、頭なの中がすっきりするかもしれません。 <a href="http://t.co/v5MH4a6eP5">http://t.co/v5MH4a6eP5</a></p>&mdash; 山本和彦 (@kazu_yamamoto) <a href="https://twitter.com/kazu_yamamoto/status/519035278321651712">2014, 10月 6</a></blockquote>

<blockquote data-conversation="none" lang="ja"><p lang="ja" dir="ltr">パーサに関しては、Hutton さんのページに、ちゃんと動くコードがあるので、それを写経するといいかもしれません。僕がパーサの修行に実装したパーサは、これです。 <a href="http://t.co/1zxNHojuJ2">http://t.co/1zxNHojuJ2</a></p>&mdash; 山本和彦 (@kazu_yamamoto) <a href="https://twitter.com/kazu_yamamoto/status/519035854237356032">2014, 10月 6</a></blockquote>

# おわりに

個人的にはParsecの挙動を理解することがHaskellを勉強し始めた動機でした。当初はモナドの扱いに慣れていなかったことと相まって、Parsecが内部でどのような処理を行っているかがまったく想像できずに、ブラックボックスとして使うことすら困難を覚えました。

Haskellの勉強を進めるうちに、パーサがStateモナドとMaybeモナドの合成で表現できることに気付いたのが突破口となりました。

* [Parsecをモナド変換子で模倣](http://qiita.com/7shi/items/201f379443079736e18e) 2015.4.28

今回は昔の自分のような困難を感じている人を想定して、Parsecを使う前に動作原理を説明しました。超入門シリーズは今回の構文解析が1つの山場となっているため、Maybeモナド以降は構文解析に関係するサンプルを入れて、今回の内容につながるよう構成しています。

自前実装により動作原理が把握できれば、Parsecを使うときにも何となく動きが推測できるようになるでしょう。そうすれば勘が働いて応用も思い付きやすくなります。
