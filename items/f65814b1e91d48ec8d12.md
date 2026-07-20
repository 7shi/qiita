---
coediting: false
comments_count: 0
created_at: '2015-07-31T15:48:22+09:00'
id: f65814b1e91d48ec8d12
likes_count: 5
private: false
reactions_count: 0
stocks_count: 2
tags:
- name: Haskell
  versions: []
title: 【解答例】Haskell 構文解析 超入門
updated_at: '2015-11-25T00:59:02+09:00'
url: https://qiita.com/7shi/items/f65814b1e91d48ec8d12
slide: false
---

[Haskell 構文解析 超入門](http://qiita.com/7shi/items/b8c741e78a96ea2c10fe)の解答例です。

# Stateモナド

【問1】モナドなしのまとめのコードをStateモナドを使って書き換えてください。

```hs
import Control.Exception
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

test1 = do
    x1 <- anyChar
    x2 <- anyChar
    return [x1, x2]

test2 = do
    x1 <- test1
    x2 <- anyChar
    return $ x1 ++ [x2]

test3 = do
    x1 <- letter
    x2 <- digit
    x3 <- digit
    return [x1, x2, x3]

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
Main.hs:11:5-28: Non-exhaustive patterns in function anyChar
"123"
'a'
Main.hs:15:5-34: Non-exhaustive patterns in function satisfy
Main.hs:15:5-34: Non-exhaustive patterns in function satisfy
'1'
'a'
Main.hs:15:5-34: Non-exhaustive patterns in function satisfy
Main.hs:15:5-34: Non-exhaustive patterns in function satisfy
Main.hs:15:5-34: Non-exhaustive patterns in function satisfy
"a23"
"a23"
```

※ `satisfy`に型注釈を付けないとエラーになります。

# Maybeモナド

【問2】モナドなしのまとめのコードをMaybeモナドを使って書き換えてください。

```hs
import Data.Char

parseTest p s = case p s of
    Just (r, _) -> print r
    n           -> print n

anyChar (x:xs) = Just (x, xs)
anyChar _      = Nothing

satisfy f (x:xs) | f x = Just (x, xs)
satisfy _ _            = Nothing

char c = satisfy (== c)
digit  = satisfy isDigit
letter = satisfy isLetter

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
Nothing
"123"
'a'
Nothing
Nothing
'1'
'a'
Nothing
Nothing
Nothing
"a23"
"a23"
```

# many

【問3】指定したパーサを0回以上適用して返すコンビネータ`many`を実装してください。

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

many p = ((:) <$> p <*> many p) <|> return []

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

# エラーチェック

【問4】問3の解答の自前実装では失敗時に返される`Left`に状態が含まれず、1つでも成功していたかが判断できません。`left`を次のように修正することで状態を返して、Parsecと同じようにエラーをチェックしてください。

```hs
import Control.Applicative ((<$>), (<*>))
import Control.Monad
import Control.Monad.State
import Data.Char

parseTest p s = case evalStateT p s of
    Right r     -> print r
    Left (e, _) -> putStrLn $ "[" ++ show s ++ "] " ++ e

anyChar = StateT $ anyChar where
    anyChar (x:xs) = Right (x, xs)
    anyChar    xs  = Left ("too short", xs)

satisfy f = StateT $ satisfy where
    satisfy (x:xs) | not $ f x = Left (": " ++ show x, x:xs)
    satisfy    xs              = runStateT anyChar xs

(StateT a) <|> (StateT b) = StateT f where
    f s0 =   (a  s0) <|> (b  s0) where
        Left (a, s1) <|> _ | s0 /= s1 = Left (     a, s1)
        Left (a, _ ) <|> Left (b, s2) = Left (b ++ a, s2)
        Left _       <|> b            = b
        a            <|> _            = a

left e = StateT $ \s -> Left (e, s)

char c = satisfy (== c)   <|> left ("not char " ++ show c)
digit  = satisfy isDigit  <|> left "not digit"
letter = satisfy isLetter <|> left "not letter"

many p = ((:) <$> p <*> many p) <|> return []

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

# バックトラック

【問5】問4の解答の自前実装に`try`と`string`を実装してください。

```hs
import Control.Applicative ((<$>), (<*>))
import Control.Monad
import Control.Monad.State
import Data.Char

parseTest p s = case evalStateT p s of
    Right r     -> print r
    Left (e, _) -> putStrLn $ "[" ++ show s ++ "] " ++ e

anyChar = StateT $ anyChar where
    anyChar (x:xs) = Right (x, xs)
    anyChar    xs  = Left ("too short", xs)

satisfy f = StateT $ satisfy where
    satisfy (x:xs) | not $ f x = Left (": " ++ show x, x:xs)
    satisfy    xs              = runStateT anyChar xs

(StateT a) <|> (StateT b) = StateT f where
    f s0 =   (a  s0) <|> (b  s0) where
        Left (a, s1) <|> _ | s0 /= s1 = Left (     a, s1)
        Left (a, _ ) <|> Left (b, s2) = Left (b ++ a, s2)
        Left _       <|> b            = b
        a            <|> _            = a

try (StateT p) = StateT $ \s -> case p s of
    Left (e, _) -> Left (e, s)
    r           -> r 

left e = StateT $ \s -> Left (e, s)

char c = satisfy (== c)   <|> left ("not char " ++ show c)
digit  = satisfy isDigit  <|> left "not digit"
letter = satisfy isLetter <|> left "not letter"

string s = sequence [char x | x <- s]

many p = ((:) <$> p <*> many p) <|> return []

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

# 括弧

【問6】項の下位に因子（factor）という層を追加して、括弧をサポートしてください。`<*`を使ってください。

```hs
import Text.Parsec
import Control.Applicative ((<$>), (<*>), (<*), (*>))

eval m fs = foldl (\x f -> f x) <$> m <*> fs
apply f m = flip f <$> m

-- expr = term, {("+", term) | ("-", term)}
expr = eval term $ many $
        char '+' *> apply (+) term
    <|> char '-' *> apply (-) term

-- term = factor, {("*", factor) | ("/", factor)}
term = eval factor $ many $
        char '*' *> apply (*) factor
    <|> char '/' *> apply div factor

-- factor = ("(", expr, ")") | number
factor = char '(' *> expr <* char ')' <|> number

number = read <$> many1 digit

main = do
    parseTest expr "(2+3)*4"
```
```text:実行結果
20
```

# スペース

【問7】スペースを無視してください。

`factor`の修正だけで対応できます。

```hs
import Text.Parsec
import Control.Applicative ((<$>), (<*>), (<*), (*>))

eval m fs = foldl (\x f -> f x) <$> m <*> fs
apply f m = flip f <$> m

-- expr = term, {("+", term) | ("-", term)}
expr = eval term $ many $
        char '+' *> apply (+) term
    <|> char '-' *> apply (-) term

-- term = factor, {("*", factor) | ("/", factor)}
term = eval factor $ many $
        char '*' *> apply (*) factor
    <|> char '/' *> apply div factor

-- factor = [spaces], ("(", expr, ")") | number, [spaces]
factor = spaces
      *> (char '(' *> expr <* char ')' <|> number)
     <*  spaces

number = read <$> many1 digit

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

# 自前実装

【問8】問7の解答を、Parsecを使わずに問5の解答の自前実装に足りない関数を補って動かしてください。ただし次のように演算子の優先順位を指定する必要があります。

```hs
import Control.Applicative ((<$>), (<*>), (<*), (*>))
import Control.Monad
import Control.Monad.State
import Data.Char

parseTest p s = case evalStateT p s of
    Right r     -> print r
    Left (e, _) -> putStrLn $ "[" ++ show s ++ "] " ++ e

anyChar = StateT $ anyChar where
    anyChar (x:xs) = Right (x, xs)
    anyChar    xs  = Left ("too short", xs)

satisfy f = StateT $ satisfy where
    satisfy (x:xs) | not $ f x = Left (": " ++ show x, x:xs)
    satisfy    xs              = runStateT anyChar xs

infixr 1 <|>
(StateT a) <|> (StateT b) = StateT f where
    f s0 =   (a  s0) <|> (b  s0) where
        Left (a, s1) <|> _ | s0 /= s1 = Left (     a, s1)
        Left (a, _ ) <|> Left (b, s2) = Left (b ++ a, s2)
        Left _       <|> b            = b
        a            <|> _            = a

try (StateT p) = StateT $ \s -> case p s of
    Left (e, _) -> Left (e, s)
    r           -> r 

left e = StateT $ \s -> Left (e, s)

char c = satisfy (== c)   <|> left ("not char " ++ show c)
digit  = satisfy isDigit  <|> left "not digit"
letter = satisfy isLetter <|> left "not letter"
space  = satisfy isSpace  <|> left "not space"
spaces = skipMany space

string s = sequence [char x | x <- s]

many p = many1 p <|> return []
many1 p = (:) <$> p <*> many p
skipMany p = many p *> return ()

eval m fs = foldl (\x f -> f x) <$> m <*> fs
apply f m = flip f <$> m

-- expr = term, {("+", term) | ("-", term)}
expr = eval term $ many $
        char '+' *> apply (+) term
    <|> char '-' *> apply (-) term

-- term = factor, {("*", factor) | ("/", factor)}
term = eval factor $ many $
        char '*' *> apply (*) factor
    <|> char '/' *> apply div factor

-- factor = [spaces], ("(", expr, ")") | number, [spaces]
factor = spaces
      *> (char '(' *> expr <* char ')' <|> number)
     <*  spaces

number = read <$> many1 digit

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
