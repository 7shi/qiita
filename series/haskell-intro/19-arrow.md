---
coediting: false
comments_count: 0
created_at: '2026-08-11T00:00:00+09:00'
id: ''
likes_count: 0
private: false
reactions_count: 0
stocks_count: 0
tags:
- name: Haskell
  versions: []
- name: アロー
  versions: []
- name: Arrow
  versions: []
- name: 関数合成
  versions: []
title: Haskell アロー 超入門
updated_at: ''
url: ''
slide: false
---

Haskell ではモナドと呼ばれる部品を組み合わせてプログラムを作りますが、アローは入力から出力への計算そのものを型として扱い、関数合成を一般化した枠組みです。モナドと違って次の計算を値から選べない代わりに、組み立てた時点で計算の形が決まります。実行前に中身を調べられるパーサを作りながら、その違いを説明します。

:::message
本記事の執筆には Claude Code (Opus 5) を利用しました。
:::

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
1. [Haskell 構文解析 超入門](http://qiita.com/7shi/items/b8c741e78a96ea2c10fe)
1. [Haskell 継続モナド 超入門](https://zenn.dev/7shi/articles/20260803-haskell-continuation-monad)
1. [Haskell 型クラス 超入門](https://zenn.dev/7shi/articles/20260805-haskell-type-classes)
1. [Haskell モナドとゆかいな仲間たち](https://zenn.dev/7shi/articles/20260807-haskell-monads-and-friends)
1. [Haskell Freeモナド 超入門](https://zenn.dev/7shi/articles/20260808-haskell-free-monad)
1. [Haskell Operationalモナド 超入門](https://zenn.dev/7shi/articles/20260809-haskell-operational-monad)
1. [Haskell Effモナド 超入門](https://zenn.dev/7shi/articles/20260811-haskell-eff-monad)
1. **Haskell アロー 超入門** ← この記事

今回のコードはすべて `runghc` で動きます。使うのは base に同梱されている `Control.Arrow` だけで、外部パッケージは要りません。

# 関数合成を一般化する

関数を `.` でつなぐと、2 つの関数を 1 つの関数にまとめられました。👉[ラムダ](https://qiita.com/7shi/items/1345bf32003faff435cb#関数合成)

`Control.Arrow` には、同じことを左から右へ書く `>>>` があります。

```hs
import Control.Arrow

f, g :: Int -> Int
f x = x + 1
g x = x * 2

main :: IO ()
main = do
    print $ (f . g) 1
    print $ (g >>> f) 1
```
```text:実行結果
3
3
```

`f . g` は「`g` を適用してから `f`」でしたが、`g >>> f` は書いた順に読めます。

## Category

`>>>` の土台にあるのが `Category` 型クラスです。`Control.Category` にあります。

```hs
class Category cat where
    id  :: cat a a
    (.) :: cat b c -> cat a b -> cat a c
```

`id` と `.` という名前のとおり、関数の恒等関数と関数合成をそのまま型クラスにしたものです。関数 `(->)` はこのインスタンスで、そのときの `id`・`.` が Prelude のものになります。

`>>>` は引数の順を入れ替えただけです。

```hs
f >>> g = g . f
```

自分で `instance Category` を書くときは、Prelude の `id`・`.` と名前が衝突するので、Prelude 側を隠す必要があります。

```hs
import Control.Category
import Prelude hiding ((.), id)
```

使うだけなら `Control.Category` を import しなくても構いません。`Control.Arrow` が `>>>` と `<<<`（向きが逆のもの）を再エクスポートしているためです。

## Kleisli

`>>>` でつなげるのは普通の関数だけではありません。`a -> m b` の形、つまりモナドを返す関数も `Kleisli` で包むと `>>>` でつながります。

```hs
newtype Kleisli m a b = Kleisli { runKleisli :: a -> m b }
```

これはモナド則を書き直したときに出てきた `>=>` と同じものです。👉[モナドとゆかいな仲間たち](https://zenn.dev/7shi/articles/20260807-haskell-monads-and-friends#-で書き直す)

文字列を数値にする `parse` と、偶数なら半分にする `half` を `Maybe` でつないでみます。どちらも失敗しうる関数です。👉[Maybeモナド](https://qiita.com/7shi/items/c7d7eec066af0fe0688d#maybeモナド)

```hs
import Control.Arrow
import Control.Monad ((>=>))

parse :: String -> Maybe Int
parse s = if not (null s) && all (`elem` "0123456789") s
          then Just (read s) else Nothing

half :: Int -> Maybe Int
half n = if even n then Just (n `div` 2) else Nothing

main :: IO ()
main = do
    print $ (parse >=> half) "10"
    print $ runKleisli (Kleisli parse >>> Kleisli half) "10"
    print $ (parse >=> half) "7"
    print $ runKleisli (Kleisli parse >>> Kleisli half) "7"
```
```text:実行結果
Just 5
Just 5
Nothing
Nothing
```

`>=>` と `>>>` が同じ結果を返しています。`Kleisli` は `>=>` に別の見た目を与えたものです。

ここまでで分かるのは、普通の関数とモナドを返す関数という別種のものが、`>>>` という同じ形でつながるということです。この「つなげる」を型クラスにしたのが `Category` で、その上に部品を足したものがアローです。

# アローの部品

**アロー**（arrow）は、入力から出力への計算を表す型です。`Arrow` 型クラスのインスタンスとして定義します。`a b c` と書いたとき、`b` が入力の型、`c` が出力の型です。

```hs
class Category a => Arrow a where
    arr    :: (b -> c) -> a b c
    first  :: a b c -> a (b, d) (c, d)
    second :: a b c -> a (d, b) (d, c)
    (***)  :: a b c -> a b' c' -> a (b, b') (c, c')
    (&&&)  :: a b c -> a b  c' -> a b (c, c')
```

スーパークラスが `Category` なので、`Arrow` のインスタンスを書くには `Category` のインスタンスも要ります。👉[型クラス](https://zenn.dev/7shi/articles/20260805-haskell-type-classes#スーパークラス)

`arr` はただの関数をアローに持ち上げる関数です。Free モナドの `liftF` や Operational モナドの `singleton` と同じ位置にあります。👉[Freeモナド](https://zenn.dev/7shi/articles/20260808-haskell-free-monad#liftf) 👉[Operationalモナド](https://zenn.dev/7shi/articles/20260809-haskell-operational-monad#継続を命令の型から外す)

残りの 4 つのうち、インスタンスで実際に定義が要るのは `first` だけです。`second`・`***`・`&&&` は `arr` と `first` から導けるため、既定の実装が用意されています。

## 配線

`***`・`&&&`・`first`・`second` の型に共通するのはタプルです。アローではタプルが配線にあたり、2 つの値を並べて流す線を表します。

```mermaid
flowchart LR
    subgraph S1["f &&& g（1 本を 2 本に分ける）"]
        direction LR
        a1["b"] --> f1["f"] --> c1["c"]
        a1 --> g1["g"] --> d1["c'"]
    end
    subgraph S2["f *** g（2 本を並べる）"]
        direction LR
        a2["b"] --> f2["f"] --> c2["c"]
        b2["b'"] --> g2["g"] --> d2["c'"]
    end
    subgraph S3["first f（片方だけ通す）"]
        direction LR
        a3["b"] --> f3["f"] --> c3["c"]
        b3["d"] --> d3["d"]
    end
```

関数 `(->)` は `Arrow` のインスタンスなので、そのまま試せます。

```hs
import Control.Arrow

main :: IO ()
main = do
    print $ ((+ 1) &&& (* 2)) (3 :: Int)
    print $ ((+ 1) *** show) (3 :: Int, 4 :: Int)
    print $ first  (+ 1) (1 :: Int, "x")
    print $ second (+ 1) ("x", 1 :: Int)
    print $ arr (+ 1) (1 :: Int)
```
```text:実行結果
(4,6)
(4,"4")
(2,"x")
("x",2)
2
```

`&&&` は同じ入力を 2 方向に流し、結果をタプルにします。`***` は 2 本の線をそれぞれ別の計算に通します。`first`・`second` はタプルの片方だけを通し、もう片方はそのまま素通しします。

これを使うと、リストの平均が計算の流れとして書けます。

```hs
import Control.Arrow

mean :: [Double] -> Double
mean = (sum &&& (fromIntegral . length)) >>> uncurry (/)

main :: IO ()
main = print $ mean [1, 2, 3, 4]
```
```text:実行結果
2.5
```

入力のリストを `&&&` で 2 方向に分け、片方で合計、片方で個数を求めて、タプルを `uncurry (/)` で割り算に渡しています。引数の名前が 1 つも出てきません。

## 練習

【問1】`mean` に倣って、リストの最大値と最小値の差を求める `spread` を `&&&` で書いてください。

```hs
spread :: [Int] -> Int

main :: IO ()
main = print $ spread [3, 1, 4, 1, 5]
```
```text:実行結果
4
```

:::details 解答例
```hs
spread :: [Int] -> Int
spread = (maximum &&& minimum) >>> uncurry (-)
```

`mean` と同じ形です。`&&&` で 2 方向に分け、`uncurry` で 2 引数の関数に渡します。
:::

# proc 記法

`>>>` と `&&&` だけで配線を書くと、線が増えたときに読みにくくなります。`do` に相当する記法として **proc 記法**が用意されています。使うには言語拡張 `Arrows` が要ります。

```hs
{-# LANGUAGE Arrows #-}
import Control.Arrow

mean :: [Double] -> Double
mean = proc xs -> do
    s <- sum -< xs
    n <- length -< xs
    returnA -< s / fromIntegral n

main :: IO ()
main = print $ mean [1, 2, 3, 4]
```
```text:実行結果
2.5
```

`&&&` で書いたものと同じ結果です。読み方は次のようになります。

|書き方|意味|
|---|---|
|`proc x -> ...`|入力を `x` という名前で受け取る|
|`y <- f -< x`|アロー `f` に入力 `x` を流し、出力を `y` とする|
|`returnA -< e`|`e` を出力にする|

`-<` の左がアロー、右が入力です。`do` の `<-` によく似ていますが、決定的な違いがあります。`-<` の左側には、`proc` で受け取った値を書けません。 上の例で `s` や `n` を使えるのは `-<` の右側だけです。

つまり、どのアローを使うかは書いた時点で決まっていて、流れてくる値によって選び直すことができません。これがこの記事の主題で、後の節で改めて扱います。

`proc` で書いたものは `arr`・`>>>`・`&&&` の組み合わせに展開されます。書けるものが増えるわけではなく、書き方が変わるだけです。シリーズで使ってきた言語拡張と並べると位置づけがはっきりします。

|回|拡張|種類|
|---|---|---|
|Free|`DeriveFunctor`|便利のため。書かなくても済む|
|Operational|`GADTs`|表現力のため。書けないものが書ける|
|アロー|`Arrows`|構文のため。書き方が変わる|

## 練習

【問2】問1の `spread` を proc 記法で書き直してください。

:::details 解答例
```hs
{-# LANGUAGE Arrows #-}
import Control.Arrow

spread :: [Int] -> Int
spread = proc xs -> do
    mx <- maximum -< xs
    mn <- minimum -< xs
    returnA -< mx - mn

main :: IO ()
main = print $ spread [3, 1, 4, 1, 5]
```
```text:実行結果
4
```

`&&&` で 2 方向に分けていたものが、2 行の `<-` になりました。同じ配線を 2 通りの書き方で表せます。
:::

# アローを自作する

ここまでは関数と `Kleisli` という既製のインスタンスを使ってきました。ここからは自分でアローを作ります。題材はパーサです。

パーサコンビネータでは、パーサを `>>=` でつないで大きなパーサを組み立てました。文字列を受け取って、結果と残りの文字列を返す関数がパーサの正体です。👉[構文解析](https://qiita.com/7shi/items/b8c741e78a96ea2c10fe#動作原理)

この方式では、組み立てたパーサが何を受け付けるのかは、実際に文字列を食わせてみるまで分かりません。今回作るのは、合成した時点で受け付ける文字が分かるパーサです。

## 静的パーサ

型はタプルで、2 つのものを同時に持ちます。

```hs
newtype P b c = P ([Char], [Char] -> b -> Maybe (c, [Char]))
```

左が**静的な情報**で、このパーサが受け付ける文字を並べたものです。右が実際の解析で、解析対象の文字列と入力値を受け取り、成功すれば出力値と残りの文字列を返します。失敗は `Maybe` で表します。

`Category` のインスタンスが要点です。

```hs
instance Category P where
    id = P ([], \s b -> Just (b, s))
    P (t2, g) . P (t1, f) = P (t1 ++ t2, \s b -> f s b >>= \(x, s') -> g s' x)
```

合成すると、静的な情報が `t1 ++ t2` で連結されます。解析を実行しなくても、2 つをつないだ結果が何を受け付けるかは決まります。 右側の関数は、前のパーサの結果と残りを次のパーサに渡すだけです。

`Arrow` のインスタンスは `arr` と `first` の 2 つを書きます。

```hs
instance Arrow P where
    arr f = P ([], \s b -> Just (f b, s))
    first (P (t, f)) = P (t, \s (b, d) -> fmap (\(c, s') -> ((c, d), s')) (f s b))
```

`arr` はただの関数を持ち上げるので、文字を消費しません。静的な情報は空です。`first` はタプルの片方だけを通すので、静的な情報は元のまま変わりません。

1 文字を読むパーサと、2 つの取り出し関数を用意します。

```hs
char :: Char -> P () ()
char c = P ([c], \s _ -> case s of
    (x:xs) | x == c -> Just ((), xs)
    _               -> Nothing)

expects :: P b c -> [Char]
expects (P (t, _)) = t

runP :: P b c -> [Char] -> b -> Maybe (c, [Char])
runP (P (_, f)) s b = f s b
```

`expects` が静的な情報を取り出す関数、`runP` が実際に走らせる関数です。全体をまとめます。

```hs
import Control.Arrow
import Control.Category
import Prelude hiding ((.), id)

newtype P b c = P ([Char], [Char] -> b -> Maybe (c, [Char]))

instance Category P where
    id = P ([], \s b -> Just (b, s))
    P (t2, g) . P (t1, f) = P (t1 ++ t2, \s b -> f s b >>= \(x, s') -> g s' x)

instance Arrow P where
    arr f = P ([], \s b -> Just (f b, s))
    first (P (t, f)) = P (t, \s (b, d) -> fmap (\(c, s') -> ((c, d), s')) (f s b))

char :: Char -> P () ()
char c = P ([c], \s _ -> case s of
    (x:xs) | x == c -> Just ((), xs)
    _               -> Nothing)

expects :: P b c -> [Char]
expects (P (t, _)) = t

runP :: P b c -> [Char] -> b -> Maybe (c, [Char])
runP (P (_, f)) s b = f s b

abc :: P () ()
abc = char 'a' >>> char 'b' >>> char 'c'

main :: IO ()
main = do
    print $ expects abc
    print $ runP abc "abcd" ()
    print $ runP abc "abd" ()
```
```text:実行結果
"abc"
Just ((),"d")
Nothing
```

1 行目が今回の主眼です。`abc` を走らせる前に、それが `"abc"` を受け付けるパーサだと分かっています。2 行目は成功して `"d"` が残った結果、3 行目は失敗です。

パーサコンビネータでは、こういう問い合わせはできませんでした。`>>=` でつないだ先には関数が入っていて、その中身は実行してみないと見えないからです。

## 練習

【問3】文字列をそのまま受け付ける `string` を書いてください。`char` を並べてつなぐだけです。

```hs
string :: [Char] -> P () ()

main :: IO ()
main = do
    print $ expects (string "abc")
    print $ runP (string "abc") "abcd" ()
```
```text:実行結果
"abc"
Just ((),"d")
```

:::details 解答例
```hs
string :: [Char] -> P () ()
string s = foldr (>>>) id (map char s)
```

各文字を `char` に変えて `>>>` で畳み込みます。初期値の `id` は `Control.Category` のもので、何も消費せず入力をそのまま返すパーサです。

`expects` が `"abc"` になるのは、`Category` の `.` が静的な情報を `++` で連結しているからです。畳み込みの回数が増えても、連結されていくだけです。
:::

# 分岐

順につなぐだけでなく、分かれ道も書きたくなります。proc 記法の中で `if` を使ってみると、`ArrowChoice` のインスタンスが要ると言われます。

```hs
class Arrow a => ArrowChoice a where
    left  :: a b c -> a (Either b d) (Either c d)
    (|||) :: a b d -> a c d -> a (Either b c) d
    (+++) :: a b c -> a b' c' -> a (Either b b') (Either c c')
```

`Arrow` がタプルで 2 本の線を並べていたのに対して、`ArrowChoice` は `Either` でどちらか一方を選びます。定義が要るのは `left` だけです。

```hs
instance ArrowChoice P where
    left (P (t, f)) = P (t, \s e -> case e of
        Left  b -> fmap (\(c, s') -> (Left c, s')) (f s b)
        Right d -> Just (Right d, s))
```

`Left` なら中のパーサに通し、`Right` ならそのまま素通しします。静的な情報は元のままです。

これで proc の中に `if` が書けます。

```hs
ab :: P Bool ()
ab = proc flag -> if flag then char 'a' -< () else char 'b' -< ()
```

`|||` を使って直接書くこともできます。分岐の条件を `Either` として外から受け取る形です。

```hs
ab2 :: P (Either () ()) ()
ab2 = char 'a' ||| char 'b'
```

走らせてみます。

```hs
main :: IO ()
main = do
    print $ expects ab
    print $ runP ab "ab" True
    print $ runP ab "ab" False
    print $ expects ab2
    print $ runP ab2 "ab" (Left ())
    print $ runP ab2 "ba" (Right ())
```
```text:実行結果
"ab"
Just ((),"b")
Nothing
"ab"
Just ((),"b")
Just ((),"a")
```

1 行目に注目してください。`expects ab` が `"ab"` を返しています。分岐しても静的な情報は取れます。 両方の枝の和になるので、`flag` の値がどちらに転んでも、起こりうることの全体は事前に分かります。

`flag` が実際に決まるのは実行時ですが、そのとき何が選ばれうるかは組み立てた時点で確定しているわけです。

# モナドにはできない

ここまで来ると、`P` をモナドにすればもっと自由に書けるのではないか、と思えてきます。実際に書こうとすると詰まります。

`>>=` にあたる関数の型を書き下してみます。

```hs
bindP :: P b c -> (c -> P b d) -> P b d
```

第 2 引数の `k` は、解析結果 `c` を受け取って次のパーサを返す関数です。結果の `P b d` を作るには、まず静的な情報、つまり `[Char]` の値を用意しなければなりません。

そこに何を書けばよいでしょうか。1 つ目のパーサの分は取り出せますが、2 つ目のパーサは `k` を適用しないと手に入りません。`k` を適用するには引数として `c` が要ります。そして `c` は解析を実行して初めて手に入る値です。

組み立てている時点では、解析対象の文字列すら渡されていません。静的な情報を作るために実行結果が要るというのは、順番が逆です。ここで行き詰まります。

`>>=` の自由さは、まさにここから来ています。次の計算を結果の値から選べるからこそ、組み立てた時点では次に何が来るか分かりません。アローの `>>>` はこの選択を持たないので、逆に全体の形が先に決まります。

## app を足すと書けてしまう

「選べない」のがアローの制約ですが、これを外す型クラスが用意されています。`ArrowApply` です。

```hs
class Arrow a => ArrowApply a where
    app :: a (a b c, b) c
```

入力としてアローそのものと値を受け取り、そのアローを走らせます。アローが値として流れてくるので、流れてきた値によって次の計算を選べます。

`P` に実装してみます。

```hs
instance ArrowApply P where
    app = P ([], \s (P (_, f), b) -> f s b)
```

これは書けてしまいます。ただし静的な情報の欄に書けるものがありません。実行時に受け取ったパーサを走らせるので、組み立て時点では何を消費するのか言えず、空にするしかないからです。

これを使うと、入力の値によって使うパーサを選べます。

```hs
choose :: P Bool ()
choose = arr (\flag -> (if flag then char 'a' else char 'b', ())) >>> app

main :: IO ()
main = do
    print $ expects choose
    print $ runP choose "ab" True
    print $ runP choose "ba" True
```
```text:実行結果
""
Just ((),"b")
Nothing
```

1 行目が嘘になっています。`expects choose` は「何も受け付けない」と答えるのに、2 行目では実際に `'a'` を消費して `"b"` が残っています。3 行目は先頭が `'a'` でないので失敗します。

型エラーにはならないので、正確に言えば「モナドにできない」のではなく、モナドにすると静的な情報が意味を失うということです。実行前に調べられるという利点は、`>>=` にあたる操作を持たないことと引き換えに得られています。

## 静的と動的

同じことは既に見た `Kleisli` にも当てはまります。`Kleisli m` はモナドから作ったアローなので、`app` を持ちます。モナドがあれば「値を取り出して次を選ぶ」ができるからです。アローとして書いても、静的な情報は取れません。

型クラスの階層と並べると位置づけが見えます。👉[モナドとゆかいな仲間たち](https://zenn.dev/7shi/articles/20260807-haskell-monads-and-friends#applicative)

|型クラス|次の計算を値から選べるか|
|---|---|
|`Applicative`|選べない。`<*>` は両側を先に決めてから組み合わせる|
|`Arrow`|選べない。`>>>` は組み立てた時点で全体が決まる|
|`Monad`|選べる。`>>=` の右辺は値を受け取る関数|
|`ArrowApply`|選べる。`app` でアローそのものを流せる|

上 2 つが静的、下 2 つが動的です。アローは `Applicative` の側にいて、`ArrowApply` を足すと `Monad` の側に移ります。

:::message
理論の上では `ArrowApply` を持つアローとモナドは互いに行き来できることが知られていますが、今回は立ち入りません。実感として押さえておきたいのは、`app` を足すと静的な利点が消えるという一点です。
:::

## 練習

【問4】入口で見た `parse` と `half` を `Kleisli` でつないでパイプラインを作り、さらに `app` で値によって次のアローを選んでください。

```hs
pipeline :: Kleisli Maybe String Int
choose   :: Kleisli Maybe Int Int

main :: IO ()
main = do
    print $ runKleisli pipeline "10"
    print $ runKleisli pipeline "7"
    print $ runKleisli choose 8
    print $ runKleisli choose (-8)
    print $ runKleisli choose 7
```
```text:実行結果
Just 50
Nothing
Just 4
Just 8
Nothing
```

`pipeline` は解析して半分にしてから 10 倍します。`choose` は正なら半分にし、負なら符号を反転します。

:::details 解答例
```hs
import Control.Arrow

parse :: String -> Maybe Int
parse s = if not (null s) && all (`elem` "0123456789") s
          then Just (read s) else Nothing

half :: Int -> Maybe Int
half n = if even n then Just (n `div` 2) else Nothing

pipeline :: Kleisli Maybe String Int
pipeline = Kleisli parse >>> Kleisli half >>> arr (* 10)

choose :: Kleisli Maybe Int Int
choose = arr (\n -> (if n > 0 then Kleisli half else arr negate, n)) >>> app
```

`pipeline` は失敗しうる関数とただの関数が `>>>` で混ざっています。ただの関数は `arr` で持ち上げます。

`choose` は `P` に `app` を入れたときと同じ形です。`arr` で「使うアローと入力値」のタプルを作り、`app` に流します。`-8` が `Just 8` になっているとおり、負のときは `half` を通らず反転だけしています。モナドから作ったアローは、値によって次を選べる側にいます。
:::

# アローの現在

アローは主流の書き方ではありません。実際にアローとして設計されたライブラリは限られています。

一方で、`Control.Arrow` の演算子自体は広く使われています。`&&&`・`***`・`first`・`second` は、アローの文脈と関係なく、タプルを扱う便利な関数として普通に登場します。関数に対して使えばそのまま動くので、既にどこかで見たことがあるかもしれません。

アローの枠組みを正面から使っている領域は、次のようなものです。

|分野|パッケージ|内容|
|---|---|---|
|FRP|Yampa|時間とともに変化する値を扱う。ストリーム関数がそのままアロー|
|SQL|opaleye|クエリをアローとして組み立て、SQL に変換してから実行する|
|XML|HXT|XML の変換をアローとして書く。更新は 2021 年で止まっている|

opaleye は今回の静的パーサと同じ発想です。組み立てた計算を実行前に SQL という別の形に変換するので、途中で値を見て次を選ばれると困ります。

Yampa のストリーム関数は Hughes の論文以来の定番の題材で、フィードバックを扱うために `ArrowLoop` と `rec` という道具が加わります。今回は扱いませんでした。

## Profunctor

`first` や `***` にあたる操作は、現代のライブラリでは `Profunctor` という別の語彙で語られることが多くなっています。入力と出力の両方を持つ型を表す型クラスで、タプルを扱う部分が `Strong`、`Either` を扱う部分が `Choice` という名前で分かれています。

`Arrow` が 1 つの型クラスにまとめていたものを、細かく分けた形です。アローが古いということではなく、同じ操作に別の名前が付いていると考えてください。`Control.Arrow` の演算子を見慣れておくと、そちらを読むときにも見当がつきます。

# まとめ

アローは、入力から出力への計算そのものを型として扱う枠組みです。`Category` の `>>>` でつなぎ、`Arrow` の `&&&`・`***`・`first` でタプルを配線し、proc 記法で名前を付けて書けます。

モナドと並べると違いがはっきりします。

|モナド|アロー|
|---|---|
|`a -> m b`。関数の戻り値としてモナドを返す|`a b c`。入力から出力への計算そのものを型にする|
|次の計算を値から選べる|形は組み立てた時点で決まる|
|中身は実行しないと分からない|実行前に調べられる|
|`>>=`・`>=>`|`>>>`・`&&&`・`***`|
|`do`|`proc`|
|（なし）|`ArrowApply` を足すとモナドと同じ側に移る|

自作した静的パーサでは、合成した時点で受け付ける文字が確定し、分岐しても両方の枝の和として取り出せました。`>>=` にあたる関数を書こうとすると、静的な情報を作るのに実行結果が要るという順番の矛盾で行き詰まります。`ArrowApply` を足せば書けますが、そのとき静的な情報は嘘になります。`>>=` が書けないことが、そのままアローの取り柄になっています。

命令をデータとして組み立て、後から解釈するという枠組みを続けて見てきましたが、アローはそれとは別の方法で、実行前に中身を知るという同じ利益を得ています。

|枠組み|中を見られるようにする方法|
|---|---|
|Free|命令を木のデータにして、後から辿る|
|Operational|継続を `>>=` の側に出し、命令を GADT で並べる|
|Eff|命令の型をリストにして複数の効果を混ぜる|
|アロー|合成の形を型に固定し、値への依存を断つ|

上の 3 つは `>>=` に意味を与えないことで組み立てと解釈を分けました。アローは `>>=` を持たないことで同じ利益を得ています。

ただし置き換えられる関係ではありません。手順書を複数のインタープリターで解釈し直すという使い方は Free の側のもので、アローから得られるのは、実行前に静的な情報を取り出せることと、値に依存しない配線を型で保証できることに限られます。

# 参考

アローの原論文と、proc 記法の出典です。

- Hughes, J. (2000). Generalising monads to arrows. *Science of Computer Programming*, 37(1–3), 67–111. https://doi.org/10.1016/S0167-6423(99)00023-4
- Paterson, R. (2001). A new notation for arrows. In *Proceedings of the Sixth ACM SIGPLAN International Conference on Functional Programming* (pp. 229–240). ACM. https://doi.org/10.1145/507635.507664
- Paterson, R. (2003). Arrows and computation. In J. Gibbons & O. de Moor (Eds.), *The Fun of Programming* (pp. 201–222). Palgrave Macmillan.

haskell.org にアロー関連の文献表とチュートリアルがまとまっています。

https://www.haskell.org/arrows/
