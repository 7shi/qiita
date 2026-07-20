---
coediting: false
comments_count: 5
created_at: '2015-07-28T18:19:55+09:00'
id: 73e534c47bbebc71b37e
likes_count: 39
private: false
reactions_count: 0
stocks_count: 34
tags:
- name: JavaScript
  versions: []
- name: Haskell
  versions: []
title: Haskell 例外処理 超入門
updated_at: '2016-07-03T12:14:50+09:00'
url: https://qiita.com/7shi/items/73e534c47bbebc71b37e
slide: false
---

Haskellでは失敗を処理するのにモナドと例外の2つの方法があります。手っ取り早く失敗を処理することを目的として、それらの初歩を説明します。

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
1. Haskell 例外処理 超入門 ← この記事
1. [Haskell 構文解析 超入門](http://qiita.com/7shi/items/b8c741e78a96ea2c10fe)
1. 【予定】Haskell 継続モナド 超入門
1. 【予定】Haskell 型クラス 超入門
1. 【予定】Haskell モナドとゆかいな仲間たち
1. 【予定】Haskell Freeモナド 超入門
1. 【予定】Haskell Operationalモナド 超入門
1. 【予定】Haskell Effモナド 超入門
1. 【予定】Haskell アロー 超入門

練習の解答例は別記事に掲載します。

* [【解答例】Haskell 例外処理 超入門](http://qiita.com/7shi/items/f825dc54a5f6fb2a72dc)

# Eitherモナド

```hs:型表記
Either a b
```

成功時だけでなく、失敗時にも値が返せるモナドです。Maybeモナドの機能強化版のような失敗系モナドです。

Maybeモナドと比較します。型変数の`a`と`b`を配置位置から左右と呼んでいます。

型          |失敗     |成功
------------|---------|---------
`Maybe  a`  |`Nothing`|`Just a`
`Either a b`|`Left a` |`Right b`

`Right`が成功を表すのは、「正しい」という意味があるのに掛けているようです。

## return

`return`では`Right`が返されます。`Right`が`Just`に対応していることを思い浮かべてください。

```hs
main = do
    print (return 1 :: Either () Int)
```
```text:実行結果
Right 1
```

型を指定するため型注釈が必要です。

## either

[Data.Either](http://hackage.haskell.org/package/base-4.7.0.2/docs/Data-Either.html)モジュールの関数です。

```hs:型
either :: (a -> c) -> (b -> c) -> Either a b -> c
```

`Left`と`Right`の値を処理する関数を渡して`Either`を取り除きます。

```hs
import Data.Either

test = either (+ 1) (* 2)

main = do
    print $ test $ Left  4
    print $ test $ Right 4
```
```text:実行結果
5
8
```

### id

`either`と`id`を組み合わせれば、`Left`と`Right`の違いを無視して値が取り出せます。

※ `Either a b`の`a`と`b`が同じ型のときに限ります。

```hs
import Data.Either

main = do
    print $ either id id $ Left  4
    print $ either id id $ Right 8
```
```text:実行結果
4
8
```

## 脱出

Maybeモナドでは`Nothing`により`do`から脱出できるのと同じように、Eitherモナドでも`Left`で`do`から脱出できます。

```hs
test1 = do
    a <- Right 1
    Left ()       -- 脱出
    return a

test2 = do
    a <- Just 1
    Nothing       -- 脱出
    return a

main = do
    print test1
    print test2
```
```text:実行結果
Left ()
Nothing
```

### エラーの理由

Eitherモナドの一般的な使い方です。

`Nothing`と違って`Left`には値が添えられます。これを使って脱出時に文字列を返すことができます。

```hs
import Control.Monad

test x = do
    when (x < 5) $ Left $ show x ++ " < 5"
    return $ x * 2

main = do
    print $ test 4
    print $ test 8
```
```text:実行結果
Left "4 < 5"
Right 16
```

この`Left`はエラーを表していると考えれば、添えられる文字列はエラーの理由となります。

### 値を返す

`Left`は途中で値を返して抜けるのにも使用できます。

```hs
import Control.Monad

test x = either id id $ do
    when (x < 5) $ Left $ x + 1
    return $ x * 2

main = do
    print $ test 4
    print $ test 8
```
```text:実行結果
5
16
```

これはエラー処理ではなく、次のような手続型のコードを模倣しています。

```js:JavaScript
function test(x) {
    if (x < 5) return x + 1;
    return x * 2;
}

console.log(test(4));
console.log(test(8));
```
```text:実行結果
5
16
```

## 練習

【問1】次のコードで脱出の理由（`out of range`, `not xxx: 'X'`）を返すように修正してください。

```hs
import Data.Char
import Control.Monad

getch s n
    | n < length s = Just $ s !! n
    | otherwise    = Nothing

test s = do
    ch0 <- getch s 0
    ch1 <- getch s 1
    ch2 <- getch s 2
    unless (isUpper ch0) Nothing
    unless (isLower ch1) Nothing
    unless (isDigit ch2) Nothing
    return [ch0, ch1, ch2]

main = do
    print $ test "Aa0"
    print $ test "A"
    print $ test "aa0"
    print $ test "AA0"
    print $ test "Aaa"
```

⇒ [解答例](http://qiita.com/7shi/items/f825dc54a5f6fb2a72dc#%E3%82%A8%E3%83%A9%E3%83%BC%E3%81%AE%E7%90%86%E7%94%B1)

【問2】次のJavaScriptのコードを移植してください。Eitherモナドを使ってなるべく同じ構造にしてください。

```js:JavaScript
function fizzBuzz(x) {
    if (x % 3 == 0 && x % 5 == 0) return "FizzBuzz";
    if (x % 3 == 0) return "Fizz";
    if (x % 5 == 0) return "Buzz";
    return x.toString();
}

for (var i = 1; i <= 15; ++i) {
    console.log(fizzBuzz(i));
}
```

⇒ [解答例](http://qiita.com/7shi/items/f825dc54a5f6fb2a72dc#fizz-buzz)

# 例外

実行時エラーは**例外**として伝達されます。IOアクションで入出力を行う際にも発生することがあります。

例外処理はIOモナドのブロックに対して行うため、例外が絡むとIOモナドに縛られてしまいます。IOモナドが絡まない処理ではEitherモナドを使うことが望ましいです（詳細は後述）。

【追記 2016.07.03】以下に書くのは古い方法になりつつあるようです。最近の動向は以下の記事を参照してください。

* [@syocy](https://twitter.com/syocy): [Haskellの最近の例外ハンドリング - syocy’s diary](http://syocy.hatenablog.com/entry/2016/07/02/174426) 2016.07.02

## パターンマッチの失敗

実行時エラーでありがちなのはパターンマッチの失敗です。

```hs
foo 1 = "1"

main = do
    print $ foo 0  -- エラー
    print $ foo 1  -- 中断され到達しない
    print "end"
```
```text:実行結果（エラー）
xxx: Main.hs:1:1-11: Non-exhaustive patterns in function foo
```

例外が発生した時点でプログラムの実行が止まります。

## catch

[Control.Exception](http://hackage.haskell.org/package/base-4.8.1.0/docs/Control-Exception.html)モジュールの関数です。

```hs:型
catch :: Exception e => IO a -> (e -> IO a) -> IO a
```

例外をキャッチして処理します。第2引数は例外ハンドラで、引数の型で例外の種類を指定する必要があります。

すべての例外をキャッチするには`SomeException`型を指定します。

```hs
import Control.Exception           -- 追加

foo 1 = "1"

main = do
    catch (do                      -- 使用箇所
        print $ foo 0              -- 失敗
        print $ foo 1              -- 実行されない
        ) $ \(SomeException e) ->  -- 例外ハンドラ
            print e                -- 例外を表示
    print "end"                    -- ハンドリング後に続行
```
```text:実行結果
Main.hs:3:1-11: Non-exhaustive patterns in function foo

"end"
```

例外が発生した時点でハンドラに処理が移ります。ハンドリング対象のブロックは中断され戻りません。

### 演算子化

`catch`を演算子化して使う方法があります。他の言語（Javaなど）の見た目に近くなり括弧も減ります。

```hs
import Control.Exception

foo 1 = "1"

main = do
    do                                 -- 対象のブロック
        print $ foo 0
        print $ foo 1
        `catch` \(SomeException e) ->  -- catchを演算子化
            print e
    print "end"
```
```text:実行結果
Main.hs:3:1-11: Non-exhaustive patterns in function foo

"end"
```

## 例外の型

例外の型が合わなければキャッチできません。

```hs
import Control.Exception

main = do
    do
        print $ 1 `div` 0                 -- ゼロ除算
        `catch` \(PatternMatchFail _) ->  -- パターンマッチ失敗ではなくキャッチできない
            print "PatternMatchFail"
    print "end"                           -- 中断され到達しない
```
```text:実行結果（エラー）
xxx: divide by zero
```

## catches

```hs:型
catches :: IO a -> [Handler a] -> IO a
```

例外の型によってハンドラを振り分けます。リストに並べた順番で型がチェックされ、最初にマッチしたハンドラが実行されます。

```hs
import Control.Exception

main = do
    do
        print $ 1 `div` 0                         -- ゼロ除算
        `catches`                                 -- 使用箇所
            [ Handler $ \(PatternMatchFail _) ->
                print "PatternMatchFail"
            , Handler $ \(DivideByZero) ->        -- マッチ
                print "DivideByZero"
            , Handler $ \(SomeException _) ->
                print "SomeException"
            ]
    print "end"                                   -- ハンドリング後に続行
```
```text:実行結果
"DivideByZero"
"end"
```

`DivideByZero`は列挙型のデータ構築子で引数がありません。

## 練習

【問3】次のコードは例外が発生して途中で止まってしまいます。例外が発生したら元の文字列を表示して続行するように修正してください。

```hs
import Control.Monad

main =
    forM_ ["1", "a", "3"] $ \s ->
        print (read s :: Int)
```

具体的には以下のように出力してください。

```text:実行結果
1
"a"
3
```

⇒ [解答例](http://qiita.com/7shi/items/f825dc54a5f6fb2a72dc#%E4%BE%8B%E5%A4%96)

# 参照透過な関数

参照透過な関数（純粋関数）で発生した例外を扱う上で、いくつか注意点があります。

## 例外のすり抜け

`catch`の対象はIOアクションです。関数の戻り値を`return`でアクション化しようとしても、例外がキャッチできずにすり抜けてしまいます。

```hs
import Control.Exception

foo 1 = "1"

test = do
    return $ foo 0                 -- 失敗
    `catch` \(SomeException _) ->  -- すり抜ける
        return "???"               -- 実行されない

main = do
    print =<< test
```
```text:実行結果（エラー）
Main.hs:4:1-11: Non-exhaustive patterns in function foo

```

これは遅延評価に起因します。`catch`からは`foo 0`という式（サンク）が入ったIOアクションが返され、そこから値を取り出すのは`catch`の外で行われるためです。

## evaluate

```hs:型
evaluate :: a -> IO a
```

関数をその場で評価します。遅延評価（非正格評価）に対して正格評価と呼びます。

`catch`と組み合わせることで例外のすり抜けを防止できます。

```hs
import Control.Exception

foo 1 = "1"

test = do
    evaluate $ foo 0               -- 正格評価 → 失敗
    `catch` \(SomeException _) ->  -- キャッチされる
        return "???"               -- 実行される

main = do
    print =<< test
```
```text:実行結果
"???"
```

## 指針

IOモナドが絡まない処理では、例外は避けた方が無難です。評価が失敗する可能性のある関数は、MaybeモナドかEitherモナドを返すようにします。その方が記述も簡単になります。

```hs
foo 1 = Right "1"
foo _ = Left  "???"

main = do
    print $ foo 0
```
```text:実行結果
Left "???"
```

## 練習

【問4】`try`は例外を`Left`に変換する関数です。次のコードはうまく動きませんが、`try`の動作を確認できるように修正してください。

```hs
import Control.Exception
import Control.Monad

main = do
    forM_ [0..3] $ \i -> do
        a <- try $ return $ 6 `div` i
        print (a :: Either SomeException Int)
```

⇒ [解答例](http://qiita.com/7shi/items/f825dc54a5f6fb2a72dc#try)

# モナド変換子

IO以外のモナドで失敗を扱うには、モナド変換子でEitherモナドを合成すれば例外が避けられます。

復習を兼ねて[Haskell モナド変換子 超入門](http://qiita.com/7shi/items/4408b76624067c17e933)で出した例を書き替えます。MaybeモナドをEitherモナドにすることで、エラーの理由が返せるようになります。

次の手順でサンプルを書き換える過程を示します。

* モナドなし
    * Stateモナド
    * Eitherモナド
* モナド変換子で合成

## モナドなし

`getch`で1文字ずつ取得して、`get3`で3文字分を返します。文字数が足らないと例外が発生します。

```hs
getch (x:xs) = (x, xs)

get3 xs0 =
    let (x1, xs1) = getch xs0
        (x2, xs2) = getch xs1
        (x3, xs3) = getch xs2
    in [x1, x2, x3]

main = do
    print $ get3 "abcd"  -- OK
    print $ get3 "1234"  -- OK
    print $ get3 "a"     -- NG
```
```text:実行結果（エラー）
"abc"
"123"
xxx: Main.hs:1:1-22: Non-exhaustive patterns in function getch
```

### Stateモナド

状態の受け渡しが冗長なので、Stateモナドで抽象化します。依然として例外は発生します。

```hs
import Control.Monad.State

getch = state getch where   -- Stateモナドに関数を入れる
    getch (x:xs) = (x, xs)  -- 状態 -> (値, 状態)

get3 = evalState $ do
    x1 <- getch
    x2 <- getch
    x3 <- getch
    return [x1, x2, x3]

main = do
    print $ get3 "abcd"  -- OK
    print $ get3 "1234"  -- OK
    print $ get3 "a"     -- NG
```
```text:実行結果
"abc"
"123"
xxx: Pattern match failure in do expression at Main.hs:4:5-10
```

### Eitherモナド

最初のコードに戻って、例外を避けるためにEitherモナドで書き換えます。

```hs
getch (x:xs) = Right (x, xs)
getch _      = Left  "too short"

get3 xs0 = do
    (x1, xs1) <- getch xs0
    (x2, xs2) <- getch xs1
    (x3, xs3) <- getch xs2
    return [x1, x2, x3]

main = do
    print $ get3 "abcd"  -- OK
    print $ get3 "1234"  -- OK
    print $ get3 "a"     -- NG
```
```text:実行結果
Right "abc"
Right "123"
Left "too short"
```

## モナド変換子で合成

StateTモナド変換子でEitherモナドと合成すれば、StateモナドとEitherモナドの両方の特徴が使えます。

```hs
import Control.Monad.State

getch = StateT getch where
    getch (x:xs) = Right (x, xs)
    getch _      = Left  "too short"

get3 = evalStateT $ do
    x1 <- getch
    x2 <- getch
    x3 <- getch
    return [x1, x2, x3]

main = do
    print $ get3 "abcd"  -- OK
    print $ get3 "1234"  -- OK
    print $ get3 "a"     -- NG
```
```text:実行結果
Right "abc"
Right "123"
Left "too short"
```

この応用で、簡単なものならモナド変換子で合成して処理できるでしょう。

## 練習

【問5】問1の解答をStateTモナド変換子を使って書き直してください。

具体的には次のコードが動くようにしてください。

```hs
test = evalStateT $ do
    ch0 <- getch isUpper "upper"
    ch1 <- getch isLower "lower"
    ch2 <- getch isDigit "digit"
    return [ch0, ch1, ch2]
```

⇒ [解答例](http://qiita.com/7shi/items/f825dc54a5f6fb2a72dc#%E3%83%A2%E3%83%8A%E3%83%89%E5%A4%89%E6%8F%9B%E5%AD%90)

# 参考

以下の記事を参考にさせていただきました。

* [@shelarcy](https://twitter.com/shelarcy): [本物のプログラマはHaskellを使う - 第25回　Haskell流の例外処理を学ぶ：ITpro](http://itpro.nikkeibp.co.jp/article/COLUMN/20081104/318426/) 2008.11.5
* [@kazu_yamamoto](https://twitter.com/kazu_yamamoto): [Haskell での例外処理 - あどけない話](http://d.hatena.ne.jp/kazu-yamamoto/20120604/1338802792) 2012.6.4
* [@kazu_yamamoto](https://twitter.com/kazu_yamamoto): [Haskellでの例外処理(その2) - あどけない話](http://d.hatena.ne.jp/kazu-yamamoto/20120605/1338871044) 2012.6.5

各種言語における例外の概要が比較されている記事です。残念ながら個別の詳細記事は断念されていますが、Haskellについては次のように言及されています。

* [@Kokudori](https://twitter.com/Kokudori): [例外入門以前 - Qiita](http://qiita.com/Kokudori/items/3a953c00012408f76ab9) 2014.12.1

> Haskellはいくつかの点でユニークな取り組みを行っています。例えば、Haskellは純粋な世界では例外機構を廃止しMaybe/Eitherを導入し、不純な世界では例外機構を導入しています。例外処理をある区分によって使い分けている意味で、Haskellの例外処理は先進的です。

`evaluate`絡みでハマった経験があります。

* [@7shi](https://twitter.com/7shi): [Haskell - アンボックス化タプルの挙動を確認（微妙） - Qiita](http://qiita.com/7shi/items/60f787149673b4d4775f) 2015.1.5
