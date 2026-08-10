---
coediting: false
comments_count: 0
created_at: '2015-01-22T17:10:00+09:00'
id: c7d7eec066af0fe0688d
likes_count: 53
private: false
reactions_count: 0
stocks_count: 52
tags:
- name: JavaScript
  versions: []
- name: Haskell
  versions: []
- name: ECMAScript
  versions:
  - '6'
title: Haskell Maybeモナド 超入門
updated_at: '2026-08-11T05:24:01+09:00'
url: https://qiita.com/7shi/items/c7d7eec066af0fe0688d
slide: false
---

Haskellではモナドと呼ばれる部品を組み合わせてプログラムを作ります。関数の評価に失敗したときにエラーを起こさずに処理する方法の初歩を説明します。Maybeモナドを手っ取り早く使うことを目的としているため、モナドの作り方や圏論には言及しません。

シリーズの記事です。

1. [Haskell 超入門](http://qiita.com/7shi/items/145f1234f8ec2af923ef)
1. [Haskell 代数的データ型 超入門](http://qiita.com/7shi/items/1ce76bde464b4a55c143)
1. [Haskell アクション 超入門](http://qiita.com/7shi/items/85afd7bbd5d6c4115ad6)
1. [Haskell ラムダ 超入門](http://qiita.com/7shi/items/1345bf32003faff435cb)
1. [Haskell アクションとラムダ 超入門](http://qiita.com/7shi/items/4a8a2807bb5186576c61)
1. [Haskell IOモナド 超入門](http://qiita.com/7shi/items/d3d3492ddd90d47160f2)
1. [Haskell リストモナド 超入門](http://qiita.com/7shi/items/deb19c4cba933590ffbf)
1. **Haskell Maybeモナド 超入門** ← この記事
1. [Haskell 状態系モナド 超入門](http://qiita.com/7shi/items/2e9bff5d88302de1a9e9)
1. [Haskell モナド変換子 超入門](http://qiita.com/7shi/items/4408b76624067c17e933)
1. [Haskell 例外処理 超入門](http://qiita.com/7shi/items/73e534c47bbebc71b37e)
1. [Haskell 構文解析 超入門](http://qiita.com/7shi/items/b8c741e78a96ea2c10fe)
1. [Haskell 継続モナド 超入門](https://zenn.dev/7shi/articles/20260803-haskell-continuation-monad)
1. [Haskell 型クラス 超入門](https://zenn.dev/7shi/articles/20260805-haskell-type-classes)
1. [Haskell モナドとゆかいな仲間たち](https://zenn.dev/7shi/articles/20260807-haskell-monads-and-friends)
1. [Haskell Freeモナド 超入門](https://zenn.dev/7shi/articles/20260808-haskell-free-monad)
1. [Haskell Operationalモナド 超入門](https://zenn.dev/7shi/articles/20260809-haskell-operational-monad)
1. [Haskell Effモナド 超入門](https://zenn.dev/7shi/articles/20260811-haskell-eff-monad)
1. 【予定】Haskell アロー 超入門

練習の解答例は別記事に掲載します。

* [【解答例】Haskell Maybeモナド 超入門](http://qiita.com/7shi/items/5a8b25d8db772bc27a71)

F#に応用した記事があります。

* [コンピュテーション式でモナドを作ってみる](http://qiita.com/7shi/items/026c7daa5b0b24d02c0f)

# モナド

前回の復習です。

* bind（`>>=`）と`return`で操作できる対象をモナドと呼びます。（※）
* 副作用を扱うのはIOモナド特有で、モナド共通の特徴ではありません。
* `do`ブロックは共通の見た目で記述できますが、モナドによって動きが異なります。

今までIOモナドとリストモナドを見て来ましたが、今回は失敗系と呼ばれるMaybeモナドを取り上げます。

※ bindとreturnが使えれば何でも良いわけではなく、モナド則というルールがあります。今回の範囲を超えるため詳細は省略しますが、興味があれば次の記事を参照してください。

* [@7shi](https://twitter.com/7shi): [モナド則がちょっと分かった？](http://qiita.com/7shi/items/547b6137d7a3c482fe68) 2015.3.9（改訂）

## 失敗系モナド

不正な引数を渡した時などに関数でエラーが発生して評価が失敗することがあります。このようなときにエラーを出さないで処理できるモナドは**失敗系モナド**と呼ばれます。

今回取り上げる失敗系モナドは次の2つです。

* Maybeモナド
* リストモナド

リストモナドと比較しながら新出のMaybeモナドについて説明します。

# Maybeモナド

```hs:型表記
Maybe a
```

「1個までしか値が持てないリスト」に相当するモナドです。個数が制限されている以外の挙動は基本的に同じです。

表記が異なるので比較します。

モナド  |0個      |1個     |2個     |3個        |4個以上
--------|---------|--------|--------|-----------|-------
リスト  |`[]`     |`[x]`   |`[x, y]`|`[x, y, z]`|（略）
Maybe   |`Nothing`|`Just x`|なし    |なし       |なし

0個は値がありませんが、これにより関数が評価に失敗して値を返せないことが表現できます。

## Just

値が入ったMaybeモナドは`return`でも`Just`でも生成できます。

```hs
main = do
    let a = return 1 :: Maybe Int
        b = Just 1
    print (a, b)
```
```text:実行結果
(Just 1,Just 1)
```

型注釈が不要な`Just`の方が使いやすいです。この記事では`do`ブロックの末尾でのみ`return`を使用します。

## 関数で失敗を返す

Haskell 超入門で取り上げた階乗の実装では、マイナスの引数はガードで弾いてエラーにしていました。👉[超入門](https://qiita.com/7shi/items/145f1234f8ec2af923ef#併用)

```hs
fact 0 = 1
fact n | n > 0 = n * fact (n - 1)

main = do
    print $ fact (-1)  -- 実行時エラー
```
```text:実行結果（エラー）
Main.hs:(1,1)-(2,33): Non-exhaustive patterns in function fact
```

エラーで処理が止まるのを防ぐため、評価に失敗したときは`Nothing`を返すようにします。型を合わせるため成功時には値を`Just`で包む必要があります。

```hs
import Control.Applicative

fact 0 = Just 1
fact n | n > 0     = (n *) <$> fact (n - 1)
       | otherwise = Nothing

main = do
    print $ fact (-1)
    print $ fact 5
```
```text:実行結果
Nothing
Just 120
```

値がないことで失敗を表現したため、エラーにならずに先に進めるようになりました。

## 練習

【問1】次の関数`fib`でエラーを回避するためMaybeモナドで書き換えてください。

```hs
fib 0 = 0
fib 1 = 1
fib n | n > 1 = fib (n - 2) + fib (n - 1)

main = do
    print $ fib (-1)
    print $ fib 6
```

⇒ [解答例](http://qiita.com/7shi/items/5a8b25d8db772bc27a71#フィボナッチ数)

# bind

Maybeモナドの挙動はリストと基本的に同じです。

確認のため`<-`で`Just`と`Nothing`から値を取り出してみます。

```hs
main = do
    print $ do
        a <- Just 1     -- 値がある
        return $ a * 2  -- 処理される
    print $ do
        a <- Just 1     -- 値がある
        b <- Nothing    -- 値がない
        return $ a * b  -- 処理されない
```
```text:実行結果
Just 2
Nothing
```

なぜ最後の行が処理されないのかを、リストに置き換えて考えてみます。Maybeモナドと同じ挙動なのを確認してください。

```hs
main = do
    print $ do
        a <- [1]        -- 値がある
        return $ a * 2  -- 処理される
    print $ do
        a <- [1]        -- 値がある
        b <- []         -- 値がない
        return $ a * b  -- 処理されない
```
```text:実行結果
[2]
[]
```

リストからの値の取り出しはループと見なせるため、ソースが空ならループの中には入りません。

```js:ECMAScript6
console.log(function () {
    var ret = [];
    for (var a of [1]) {      // 値がある
        ret.push(a * 2);      // 処理される
    }
    return ret;
}());
console.log(function () {
    var ret = [];
    for (var a of [1]) {      // 値がある
        for (var b of []) {   // 値がない（ソースが空）
            ret.push(a * b);  // 処理されない
        }
    }
    return ret;
}());
```
```text:実行結果(io.js)
[ 2 ]
[]
```

## 取り出しの失敗

リストは複数の値を持てるためループで解釈するのが自然ですが、値が1個までしか持てないMaybeモナドをループで解釈するのは不自然です。

ループのことは考えずに、原則に立ち返って`<-`では1つの値が取り出されるという目で見直します。

```hs
main = do
    print $ do
        a <- Just 1  -- 1を取り出す
        return a     -- モナドに入れて返す
```
```text:実行結果
Just 1
```

`Nothing`から値を取り出そうとしても失敗します。

```hs
main = do
    print $ do
        a <- Just 1     -- 1を取り出す
        b <- Nothing    -- 取り出せない（失敗）
        return $ a * b  -- 処理されない
```
```text:実行結果
Nothing
```

取り出しに失敗した時点で`do`から抜けて`Nothing`を返すと解釈します。

※ ループで解釈しても結果は同じですが、Maybeモナドでは抜けると解釈した方が簡単だということです。

他の言語で実装すれば、値を取り出すタイミングで毎回チェックすることになります。

```js:JavaScript
console.log(function () {
    var a = [1].pop();              // 要素を取り出す
    if (a == undefined) return [];  // 取り出せたかチェック
    var b = [].pop();               // 要素を取り出す（失敗）
    if (b == undefined) return [];  // ここで引っ掛かる
    return [a * b];                 // 処理されない
}());
```
```text:実行結果
[]
```

※ `undefined`で失敗が表現されているのは`Nothing`に似ています。

## パターンマッチ

`<-`はMaybeモナドを扱う`do`の中でしか使えません。それ以外はパターンマッチで`Just`から値を取り出します。

```hs
main = do              -- IOモナドを扱うdo（対象外）
    let a = Just 1
        (Just a') = a  -- パターンマッチ
    print a'
```
```text:実行結果
1
```

### Nothing

パターンマッチで`Nothing`から値を取り出そうとすると、コンパイルは通りますが**実行時に**エラーが発生します。

```hs
main = do
    let a = Just 1
        b = Nothing
        (Just a') = a  -- OK
        (Just b') = b  -- 実行時エラー
    print [a', b']
```
```text:実行結果（エラー）
Main.hs:5:9-21: Irrefutable pattern failed for pattern (Data.Maybe.Just b')
```

### エラー対策

Maybeモナドに対してパターンマッチするときは、必ず`Just`と`Nothing`の両方のパターンを記述するようにします。

```hs
test (Just x) = x  -- 引数でパターンマッチ
test Nothing  = 0  -- 忘れずに書く

main = do
    print $ test $ Just 1
    print $ test $ Nothing
```
```text:実行結果
1
0
```

## 練習

【問2】Maybeモナドを扱う`bind`を実装してください。`do`や`>>=`は使わないでください。

具体的には次のコードが動くようにしてください。

```hs
main = do
    print $ Just 1 `bind` \a -> Just $ a * 2
    print $ Just 1 `bind` \a -> Nothing `bind` \b -> Just $ a * b
```
```text:実行結果
Just 2
Nothing
```

⇒ [解答例](http://qiita.com/7shi/items/5a8b25d8db772bc27a71#bind)

# 失敗を含む処理

Maybeモナドを利用した失敗を含む処理をいくつか紹介します。

## 全てか無か

異常を検知した時点で処理を中断します。

```hs
import Control.Applicative

fact 0 = Just 1
fact n | n > 0     = (n *) <$> fact (n - 1)
       | otherwise = Nothing

facts n = do
    a <- fact $ n
    b <- fact $ n - 1
    c <- fact $ n - 2
    return (a, b, c)

main = do
    print $ facts 3
    print $ facts 2
    print $ facts 1  -- cで失敗
    print $ facts 0  -- bで失敗
```
```text:実行結果
Just (6,2,1)
Just (2,1,1)
Nothing
Nothing
```

値の取り出しが1つでも失敗すれば`Nothing`が返ります。**全てか無か**です。

## mapMaybe

[Data.Maybe](https://hackage.haskell.org/package/base-4.7.0.2/docs/Data-Maybe.html)モジュールの関数です。

```hs:型
mapMaybe :: (a -> Maybe b) -> [a] -> [b] 
```

Maybeモナドを外してリストを返す`map`です。

* `Just`: 取り出した値をリストに追加します。
* `Nothing`: リストから除外します。

途中で抜けずに、成功した結果だけを見たいときに便利です。

`map`と挙動を比較します。

```hs
import Control.Applicative
import Data.Maybe

fact 0 = Just 1
fact n | n > 0     = (n *) <$> fact (n - 1)
       | otherwise = Nothing

facts n = ( map      fact [n, n - 1, n - 2]
          , mapMaybe fact [n, n - 1, n - 2]
          )

main = do
    print $ facts 3
    print $ facts 2
    print $ facts 1  -- cで失敗
    print $ facts 0  -- bで失敗
```
```text:実行結果
([Just 6,Just 2,Just 1],[6,2,1])
([Just 2,Just 1,Just 1],[2,1,1])
([Just 1,Just 1,Nothing],[1,1])
([Just 1,Nothing,Nothing],[1])
```

`mapMaybe`ではMaybeモナドが取り払われたリストが得られます。

※ このサンプルは次の練習で使います。

## 練習

【問3】`mapMaybe`を再帰で再実装して、先ほどのサンプルで検証してください。

⇒ [解答例](http://qiita.com/7shi/items/5a8b25d8db772bc27a71#再帰)

【問4】問3の解答を`foldr`で書き換えてください。

⇒ [解答例](http://qiita.com/7shi/items/5a8b25d8db772bc27a71#foldr)

# doからの脱出

`do`の中に`Nothing`だけの行を書くと`_ <- Nothing`と解釈されるため、`<-`での脱出チェックが働きます。`[]`も同様です。

※ `<-`の有無に関わらず`do`の各行はbindで結ばれます。

C言語などでの`return`が持つ働きに似ていますが、値を返すことはできません。

```hs
main = do
    print $ do
        Nothing   -- 脱出
        return 1  -- 処理されない
    print $ do
        []        -- 脱出
        return 1  -- 処理されない
```
```text:実行結果
Nothing
[]
```

## 条件脱出

条件によって`Nothing`を返す行を書くことで、条件によって`do`から脱出できます。

文字列の先頭3文字が「大文字＋小文字＋数字」で構成されているかチェックする例です。

```hs
import Data.Char
import Control.Monad

getch s n
    | n < length s = Just $ s !! n  -- 指定した位置の文字を返す
    | otherwise    = Nothing        -- 範囲外

test s = do
    ch0 <- getch s 0                -- 文字列の範囲外なら脱出
    ch1 <- getch s 1                -- 文字列の範囲外なら脱出
    ch2 <- getch s 2                -- 文字列の範囲外なら脱出
    unless (isUpper ch0) Nothing    -- 大文字でなければ脱出
    unless (isLower ch1) Nothing    -- 小文字でなければ脱出
    unless (isDigit ch2) Nothing    -- 数字でなければ脱出
    return s                        -- 最終的な返り値

main = do
    print $ test "Aa0"              -- OK
    print $ test "A"                -- 文字不足
    print $ test "aa0"              -- ch0で失敗
    print $ test "AA0"              -- ch1で失敗
    print $ test "Aaa"              -- ch2で失敗
```
```text:実行結果
Just "Aa0"
Nothing
Nothing
Nothing
Nothing
```

ここでは`unless`を使用しましたが、専用の関数があります。

## guard

[Control.Monad](http://hackage.haskell.org/package/base-4.7.0.2/docs/Control-Monad.html)モジュールの関数です。

```hs:型
guard :: MonadPlus m => Bool -> m () 
```

引数が`False`のときに`do`ブロックを抜けます。C言語の`assert`に似ていますが、エラーは発生しません。

※ `MonadPlus`は値を持たないことが可能なモナドを示します。Maybeモナドは`Nothing`、リストモナドは`[]`があるため該当します。IOモナドなど内部の要素数が固定のモナドは該当しません。

先ほどの例を書き換えます。

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
    guard $ isUpper ch0  -- 使用箇所
    guard $ isLower ch1  -- 使用箇所
    guard $ isDigit ch2  -- 使用箇所
    return s

main = do
    print $ test "Aa0"   -- OK
    print $ test "A"     -- 文字不足
    print $ test "aa0"   -- ch0で失敗
    print $ test "AA0"   -- ch1で失敗
    print $ test "Aaa"   -- ch2で失敗
```
```text:実行結果
Just "Aa0"
Nothing
Nothing
Nothing
Nothing
```

途中で抜けるという挙動が暗黙的に織り込まれていることを再確認してください。

## 練習

【問5】文字列`s`が「`x`文字の連続した数字＋`y`文字の連続した大文字」で構成されるか判定する関数`numUpper x y s`を実装してください。成功した場合は`Just s`、失敗した場合は`Nothing`を返してください。余計な文字は含まないものとします。

具体的には次のコードが動くようにしてください。

```hs
main = do
    print $ numUpper 3 2 "123AB"
    print $ numUpper 3 2 "123ABC"
    print $ numUpper 3 2 "12ABC"
```

⇒ [解答例](http://qiita.com/7shi/items/5a8b25d8db772bc27a71#文字列チェック)

# Alternative

MonadPlus（値を持たないことが可能なモナド）だけで使えるApplicativeスタイルの一種です。評価に失敗したとき、別の評価を試せます。Alternative（オルタナティブ）は**代替・二者択一**という意味です。👉[構文解析](https://qiita.com/7shi/items/b8c741e78a96ea2c10fe#選択)

※ この説明は色々と妥協しています。正確にはMonoidの知識が必要ですが、今回の範囲を超えるため詳細は省略します。興味がある方は次の記事を参照してください。

* [@kazu_yamamoto](https://twitter.com/kazu_yamamoto): 【PDF】[あなたの知らない Monoid の世界](http://mew.org/~kazu/material/2012-monoid.pdf) 2012.11.18

## OR

Alternativeを説明する前に、条件式に使用する`||`（OR）の挙動を確認します。

`左 || 右`は左→右の順に評価されます。どちらか片方が`True`であれば良いので、左が`False`のときしか右は評価されません。

評価状況をトレースして確認します。

```hs
import Debug.Trace

isA ch = trace (show ch) $ ch == 'A'

main = do
    traceIO $ show $ isA 'A' || isA 'B'  -- 左のみ
    traceIO "---"
    traceIO $ show $ isA 'A' || isA 'A'  -- 左のみ
    traceIO "---"
    traceIO $ show $ isA 'B' || isA 'A'  -- 左 → 右
    traceIO "---"
    traceIO $ show $ isA 'B' || isA 'C'  -- 左 → 右
```
```text:実行結果
'A'
True
---
'A'
True
---
'B'
'A'
True
---
'B'
'C'
False
```

## `<|>`

Alternativeの演算子です。`||`と同じ要領で、左が`Nothing`のときだけ右を評価します。

```hs
import Control.Applicative

main = do
    print $ Just 1  <|> Nothing                -- 左のみ
    print $ Just 1  <|> Just 2                 -- 左のみ
    print $ Nothing <|> Just 2                 -- 左 → 右
    print  (Nothing <|> Nothing :: Maybe Int)  -- 左 → 右（要型注釈）
```
```text:実行結果
Just 1
Just 1
Just 2
Nothing
```

`Nothing`だけではMaybeモナドの中の型が決められないため、最後の例では型注釈を加えています。

## リスト

リストに対して`<|>`を使うと択一ではなく列挙されます。常に左と右の両方が評価されます。

```hs
import Control.Applicative

main = do
    print $ [1] <|> []             -- 左 → 右
    print $ [1] <|> [2]            -- 左 → 右
    print $ []  <|> [2]            -- 左 → 右
    print  ([]  <|> []  :: [Int])  -- 左 → 右（要型注釈）
```
```text:実行結果
[1]
[1,2]
[2]
[]
```

Maybeモナドとの違いについては「Maybeモナドは値が複数持てないため、1つ目が確定した時点で処理を完了する」と解釈すれば良いでしょう。

## do

`do`と`do`を`<|>`でつなぐこともできます。

2つに分岐した流れが合流する様子は、`if`～`then`～`else`による条件分岐に似ています。

![Alternative.png](https://qiita-image-store.s3.amazonaws.com/0/32057/c88dc207-2c37-d3cd-ffe8-a6137947a0ea.png)

```hs
import Control.Applicative
import Control.Monad

check x = do
    do                  -- 分岐点
        guard $ x == 1  -- 分岐1
        <|> do
        guard $ x == 3  -- 分岐2
    Just x              -- 合流

main = do
    forM_ [1..5] $ \x -> print $ check x
```
```text:実行結果
Just 1
Nothing
Just 3
Nothing
Nothing
```

## 練習

【問6】文字列`s`の先頭3文字が「数字＋大文字＋小文字」または「大文字＋小文字＋小文字」で構成されるかを判定する関数`check s`を実装してください。`<|>`を使って、成功した場合は`Just s`、失敗した場合は`Nothing`を返してください。後続の文字は判定に影響しないものとします。

具体的には次のコードが動くようにしてください。

```hs
main = do
    print $ check "1"
    print $ check "2Ab"
    print $ check "Abc"
    print $ check "Ab1"
    print $ check "1AB"
```

⇒ [解答例](http://qiita.com/7shi/items/5a8b25d8db772bc27a71#alternative)

# まとめ

Maybeモナドはリストの機能限定版のようなモナドですが、色々な応用があります。

* `Nothing`: 関数で値が返せないことを表現
* `<-`, `guard`: 処理の途中で脱出
* `mapMaybe`: 成功と失敗が混ざったリストから、成功だけを抽出
* `<|>`: 何種類かの処理を試行

# 謝辞

Alternativeについては山本先生よりご教示いただきました。

<blockquote><p>&lt;|&gt; は Alternative 型クラスのメソッドです。import Control.Applicative すれば、Maybe でも &lt;|&gt; は使えます。</p>&mdash; 山本和彦 (@kazu_yamamoto) <a href="https://twitter.com/kazu_yamamoto/status/519030642428747776">2014年10月6日</a></blockquote>

<blockquote><p>Alternative は制限の緩い MonadPlus です。Monad が掛け算、MonadPlus が足し算の系を表します。MonadPlus はもう古いので、忘れて Alternative を使って下さい。</p>&mdash; 山本和彦 (@kazu_yamamoto) <a href="https://twitter.com/kazu_yamamoto/status/519031028040474624">2014年10月6日</a></blockquote>

<blockquote><p>ちなみに Parsec の &lt;|&gt; は、Alternative ではなく、独自実装だったと思います。</p>&mdash; 山本和彦 (@kazu_yamamoto) <a href="https://twitter.com/kazu_yamamoto/status/519031170822975488">2014年10月6日</a></blockquote>

<blockquote><p>Alternative に関しては、このスライドを見ると、頭なの中がすっきりするかもしれません。 <a href="http://mew.org/~kazu/material/2012-monoid.pdf">http://mew.org/~kazu/material/2012-monoid.pdf</a></p>&mdash; 山本和彦 (@kazu_yamamoto) <a href="https://twitter.com/kazu_yamamoto/status/519035278321651712">2014年10月6日</a></blockquote>
