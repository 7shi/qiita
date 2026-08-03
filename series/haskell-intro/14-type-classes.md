---
coediting: false
comments_count: 0
created_at: '2026-08-04T00:00:00+09:00'
id: ''
likes_count: 0
private: false
reactions_count: 0
stocks_count: 0
tags:
- name: Haskell
  versions: []
- name: 型クラス
  versions: []
- name: ポリモーフィズム
  versions: []
title: Haskell 型クラス 超入門
updated_at: ''
url: ''
slide: false
---

`deriving Show`・`Monad m =>`・`return` と、このシリーズは最初から**型クラス**の上を歩いてきましたが、その仕組みは「今回の範囲を超える」と言って先送りしてきました。今回はその回収です。型クラスとは何かを一言で言えば、型ごとに違う実装を選ぶ仕組みです。

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
1. **Haskell 型クラス 超入門** ← この記事
1. 【予定】Haskell モナドとゆかいな仲間たち
1. 【予定】Haskell Free モナド 超入門
1. 【予定】Haskell Operational モナド 超入門
1. 【予定】Haskell Eff モナド 超入門
1. 【予定】Haskell アロー 超入門

# 2 種類の多相

同じ名前の関数がいろいろな型に使えることを**多相**（polymorphism）と呼びます。Haskell の多相には性質の異なる 2 種類があり、その違いが今回の記事の軸になります。

まず `id` と `length` を見ます。

```hs:型
id     :: a -> a
length :: [a] -> Int
```

`a` はどんな型にもなれる型変数です。`id` は受け取ったものをそのまま返すだけなので、`a` が `Int` でも `String` でもやることは同じです。`length` も要素の個数を数えるだけで、要素が何型かは関係ありません。実装は 1 つで足ります。

これを**パラメトリック多相**（parametric polymorphism）と呼びます。型変数が何であっても同じ実装が動きます。

次に `show` を見ます。

```hs:型
show :: Show a => a -> String
```

`a` に型変数が使われているのは同じですが、`Show a =>` が付いています。`show` は値を文字列に変換する関数なので、`Int` の `123` と `Bool` の `True` ではやることが違います。数値を 10 進表記に直す処理と、`True`・`False` という名前を返す処理は別物です。つまり実装が型ごとに必要です。

これを**アドホック多相**（ad hoc polymorphism）と呼びます。ad hoc はラテン語由来で「その場限りの」という意味で、型ごとに個別の実装をあてがうことを指します。

|   |実装|例|
|---|---|---|
|パラメトリック多相|すべての型で同じ|`id :: a -> a`, `length :: [a] -> Int`|
|アドホック多相|型ごとに違う|`show :: Show a => a -> String`|

分かれ目は `=>` が付くかどうかです。この `Show a =>` の部分は[第7回](http://qiita.com/7shi/items/deb19c4cba933590ffbf)で**型クラス制約**として説明したもので、`Show` が型クラスです。

シリーズでこれまで使ってきたものは、ほとんどがアドホック多相の仕組みの上に載っています。

* `deriving Show`（[第2回](http://qiita.com/7shi/items/1ce76bde464b4a55c143)）
* `Monad m =>`（[第7回](http://qiita.com/7shi/items/deb19c4cba933590ffbf)）
* `return`（[第6回](http://qiita.com/7shi/items/d3d3492ddd90d47160f2)以降）

これらがなぜ動いていたのかを、今回は型クラスを自分で定義するところから見ていきます。

# class と instance

第2回では他言語の関数のオーバーロード（同じ名前で引数の型が違う関数を複数定義すること）を紹介し、「Haskell でも型クラスを自分で定義すればオーバーロードと似たようなことが可能です」と書いて、定義の説明は先送りしていました。まずそこから回収します。

第2回に載せた Java のオーバーロードです（この後の Haskell に合わせて `String` を `boolean` に変えています）。

```java:Test.java
class Test {
    public static String foo(int i) {
        if (i == 1) return "bar";
        return "?";
    }
    public static String foo(boolean b) {
        if (b) return "baz";
        return "?";
    }
}
```

Haskell では型クラスを使って書きます。

```hs
class Foo a where
    foo :: a -> String

instance Foo Int where
    foo 1 = "bar"
    foo _ = "?"

instance Foo Bool where
    foo True  = "baz"
    foo False = "?"

main = do
    putStrLn $ foo (0 :: Int)
    putStrLn $ foo (1 :: Int)
    putStrLn $ foo False
    putStrLn $ foo True
```
```text:実行結果
?
bar
?
baz
```

`class` と `instance` の役割は分かれています。

|構文|役割|内容|
|---|---|---|
|`class`|宣言|名前と型だけを決める。実装は書かない。|
|`instance`|実装|特定の型に対する中身を書く。|

`class Foo a where` の `a` は型変数で、「`Foo` という型クラスに属する型を `a` と呼ぶ」という意味です。その下に `foo :: a -> String` と書くことで、「`Foo` に属する型には `foo` という関数がある」ことを宣言します。この関数を型クラスの**メソッド**と呼びます。

:::message
オブジェクト指向のメソッドと名前は同じですが、オブジェクトに属しているわけではありません。型クラスに属する普通の関数です。
:::

`instance Foo Int where` は「`Int` を `Foo` のインスタンスにする」宣言で、その下にメソッドの実装を書きます。宣言（`class`）と実装（`instance`）が分離しているため、インスタンスは後から好きなだけ追加できます。継承のように型定義の時点でインターフェースを組み込む必要がないのがアドホック多相の特徴で、この後付けのしやすさはその裏返しです。

自分で定義した型もインスタンスにできます。第2回の `Color` を使います。

```hs
data Color = Blue | Red | Green | White

class Foo a where
    foo :: a -> String

instance Foo Int where
    foo 1 = "bar"
    foo _ = "?"

instance Foo Color where
    foo Blue = "青"
    foo Red  = "赤"
    foo _    = "?"

main = do
    putStrLn $ foo (1 :: Int)
    putStrLn $ foo Blue
    putStrLn $ foo Green
```
```text:実行結果
bar
青
?
```

インスタンスを定義していない型に使うとエラーになります。

```hs:NG
instance Foo Bool where
    foo True  = "baz"
    foo False = "?"

main = putStrLn $ foo Blue    -- Color のインスタンスがない
```
```text:エラー内容
    • No instance for ‘Foo Color’ arising from a use of ‘foo’
```

第2回で `deriving Show` を付け忘れたときに出た `No instance for (Show Color)` と同じ形のエラーです。あのときの `Show` も型クラスで、`deriving` はそのインスタンスを用意する手段だったわけです（後述）。

## 型注釈が要る理由

上の例で `foo (0 :: Int)` と型注釈を付けたのが気になったかもしれません。外すとエラーになります。

```hs:NG
main = putStrLn $ foo 1
```
```text:エラー内容
    • Ambiguous type variable ‘a0’ arising from a use of ‘foo’
      prevents the constraint ‘(Foo a0)’ from being solved.
      Probable fix: use a type annotation to specify what ‘a0’ should be.
```

数値リテラルの `1` は `Int` とは限らず、`Integer` や `Double` にもなれます。どの型か決まらないと `foo` のどの実装を使えばよいか決まらないため、コンパイラが「曖昧」（ambiguous）だと言っています。

これは型クラスの核心に関わる現象なので、後で改めて扱います。ここでは「実装を選ぶには型が決まっている必要がある」とだけ覚えておいてください。

# デフォルト実装

`class` の中にはメソッドの型だけでなく、実装を書いておくこともできます。これを**デフォルト実装**と呼びます。`instance` 側で書かなければ、そちらが使われます。

標準の `Eq` がその例です。

```hs:Eqの定義（抜粋）
class Eq a where
    (==), (/=) :: a -> a -> Bool
    x == y = not (x /= y)
    x /= y = not (x == y)
```

`==` と `/=` が互いのデフォルト実装になっているため、どちらか一方を実装すればもう一方が付いてきます。

```hs
data Color = Blue | Red | Green | White

instance Eq Color where
    Blue  == Blue  = True
    Red   == Red   = True
    Green == Green = True
    White == White = True
    _     == _     = False

main = do
    print $ Blue == Blue
    print $ Blue == Red
    print $ Blue /= Red     -- 定義していないが使える
    print $ Blue /= Blue
```
```text:実行結果
True
False
True
False
```

`/=` は一切書いていませんが、デフォルト実装の `not (x == y)` が働きます。

このように「最低限これだけ実装すればよい」という組み合わせを**最小完全定義**（minimal complete definition）と呼びます。GHCi の `:info` で確認できます。

```text:GHCi
ghci> :info Eq
type Eq :: * -> Constraint
class Eq a where
  (==) :: a -> a -> Bool
  (/=) :: a -> a -> Bool
  {-# MINIMAL (==) | (/=) #-}
（略）
```

`MINIMAL (==) | (/=)` が最小完全定義で、`|` は「どちらか」を表します。両方とも書かなければデフォルト実装同士が無限に呼び合ってしまうため、少なくとも一方は必要です。

:::message
どちらも書かなくてもコンパイルは通りますが、`-Wall` を付けると警告が出ます。実行すると無限ループになります。
:::

## 練習

【問1】メソッドを 2 つ持ち、片方にデフォルト実装がある型クラスを定義してください。複数の型をインスタンスにして、デフォルト実装が使われる型と上書きする型の両方を用意してください。

ヒント: 図形の面積を求める `area` と、名前を返す `name` など。

:::details 解答例
```hs
data Circle = Circle Double
data Rect   = Rect Double Double

class Shape a where
    area :: a -> Double
    name :: a -> String
    name _ = "図形"          -- デフォルト実装

instance Shape Circle where
    area (Circle r) = pi * r * r
    name _ = "円"            -- 上書き

instance Shape Rect where
    area (Rect w h) = w * h  -- name はデフォルト実装のまま

main = do
    putStrLn $ name (Circle 1) ++ ": " ++ show (area (Circle 1))
    putStrLn $ name (Rect 2 3) ++ ": " ++ show (area (Rect 2 3))
```
```text:実行結果
円: 3.141592653589793
図形: 6.0
```

`area` にはデフォルト実装がないため、どちらのインスタンスでも実装が必要です。`name` は `Rect` では省略したのでデフォルト実装が使われます。
:::

# 型クラス制約

第7回では `Monad m =>` を「使う側」から説明しました。ここでは定義する側から見直します。

```hs
same :: Eq a => a -> a -> String
same x y = if x == y then "同じ" else "違う"
```

`Eq a =>` は「`a` は `Eq` のインスタンスでなければならない」、言い換えると「`a` に `==` の実装があること」を要求しています。この要求があるおかげで、関数の中で `==` が使えます。逆に制約を書かなければ `==` は使えません。型変数のままではどの実装を呼べばよいか分からないからです。

制約は複数書けます。括弧で囲んでカンマで区切ります。

```hs
describe :: (Eq a, Show a) => a -> a -> String
describe x y = show x ++ (if x == y then " == " else " /= ") ++ show y

main = do
    putStrLn $ describe (1 :: Int) 1
    putStrLn $ describe 'a' 'b'
```
```text:実行結果
1 == 1
'a' /= 'b'
```

## instance 側の制約

制約は `instance` にも書けます。標準の `Show` にこの形があります。

```hs:Showの定義（抜粋）
instance Show a => Show [a] where
    （略）
```

「`a` が `Show` のインスタンスなら、`[a]` も `Show` のインスタンスになる」という意味です。リストの表示は要素を `show` して `,` で繋ぎ `[]` で囲むだけですが、その要素の表示方法は要素の型に任せる必要があります。それが制約 `Show a =>` です。

第2回以来ずっと `print [1,2,3]` が動いていたのはこの仕組みによります。自分で定義した型でも同じです。

```hs
data Color = Blue | Red | Green | White deriving Show

main = do
    print [Blue, Red]
    print [[Blue], [Red, Green]]
    print (Just [Blue, Red])
```
```text:実行結果
[Blue,Red]
[[Blue],[Red,Green]]
Just [Blue,Red]
```

`Show Color` を用意しただけで、`[Color]`・`[[Color]]`・`Maybe [Color]` がすべて表示できます。インスタンスが制約を辿って再帰的に組み立てられるためです。

# 戻り値の型で実装が選ばれる

ここが型クラスとオブジェクト指向のインターフェースが決定的に違うところです。

オブジェクト指向では、メソッドを呼ぶには必ずレシーバとなる値（オブジェクト）が要ります。どの実装が呼ばれるかはその値が決めます。

型クラスでは実装を決めるのは型です。値ではありません。したがってメソッドの引数に型変数が現れなくても構いません。

```hs:型
read     :: Read a    => String -> a
minBound :: Bounded a => a
mempty   :: Monoid a  => a
return   :: Monad m   => a -> m a
```

`read` は `a` が戻り値にしか現れません。`minBound` と `mempty` に至っては引数がなく、型変数は戻り値の型そのものです。オブジェクト指向のインターフェースではこういうメソッドは書けません。

第2回では `deriving` できる標準の型クラス 6 種類を表にして、`Read` と `Bounded` の使用例は省略していました。ここで回収します。

```hs
data Color = Blue | Red | Green | White
    deriving (Show, Read, Eq, Ord, Enum, Bounded)

main = do
    print (read "123" :: Int)
    print (read "1.5" :: Double)
    print (read "Red" :: Color)
    print (minBound :: Int)
    print (minBound :: Color)
    print (maxBound :: Color)
    print ([minBound .. maxBound] :: [Color])
```
```text:実行結果
123
1.5
Red
-9223372036854775808
Blue
White
[Blue,Red,Green,White]
```

同じ `read "123"` という式が、`:: Int` を付ければ数値に、`:: Double` を付ければ小数になります。文字列は同じなのに結果が変わるのは、型が実装を選んでいるからです。

`[minBound .. maxBound]` は `Bounded` と `Enum` の組み合わせで、その型のすべての値を列挙するイディオムです。ここでも型注釈だけが手掛かりになっています。

## ambiguous type variable

型注釈を外すと決まらなくなります。

```hs:NG
main = print (read "123")
```
```text:エラー内容
    • Ambiguous type variable ‘a0’ arising from a use of ‘print’
      prevents the constraint ‘(Show a0)’ from being solved.
      Probable fix: use a type annotation to specify what ‘a0’ should be.
（略）
    • Ambiguous type variable ‘a0’ arising from a use of ‘read’
      prevents the constraint ‘(Read a0)’ from being solved.
      Probable fix: use a type annotation to specify what ‘a0’ should be.
```

`read` は文字列を受け取って何かの型を返しますが、`print` はどんな型でも表示できてしまうため、間に挟まった型が最後まで決まりません。これは Haskell を書いていると必ず一度は踏むエラーです。`Ambiguous type variable` を見たら「型注釈が足りない」と読み替えてください。

`class と instance` の節で `foo 1` が通らなかったのも同じ理由です。

## 数値リテラルだけ注釈が要らない理由

一方で `print 1` は注釈なしで動きます。

```hs
main = do
    print 1
    print (1 + 2)
```
```text:実行結果
1
3
```

`1` の型は `Num a => a` で本来は曖昧なのですが、数値については**型のデフォルト規則**（type defaulting）があり、決まらない場合は `Integer`（小数が絡めば `Double`）が選ばれます。数値リテラルを書くたびに `:: Int` と注釈するのは煩雑すぎるための特例です。

この規則が働くのは標準の型クラスだけで、自分で定義した `Foo` のような型クラスには適用されません。`foo 1` がエラーになったのはそのためです。

## オブジェクト指向との比較

型クラスの `class` はオブジェクト指向のインターフェースと書式が似ているため、同じものだと思いたくなります。F# のインターフェースとの比較を別記事に書いています。

* [Haskellの型クラスとF#のインターフェース](http://qiita.com/7shi/items/cd7f65a898dd5696c73d)

そこでの結論は「似ているのは定義だけで、実装や呼び出し方法はあまり似ていません」でした。本節で見た「値がなくても型さえ決まれば実装が選べる」という性質が、その違いの中身です。なぜそんなことが可能なのかは、最後の「辞書渡し」の節で答えます。

# スーパークラス

型クラスには継承関係を持たせられます。`class` の宣言に制約を書くと、それが**スーパークラス**になります。

```hs:Ordの定義（抜粋）
class Eq a => Ord a where
    compare :: a -> a -> Ordering
    (<)  :: a -> a -> Bool
    （略）
```

「`Ord` のインスタンスであるためには `Eq` のインスタンスでもあること」という要求です。大小比較ができるなら等値比較もできるはずだ、という関係が型で表現されています。第2回で `deriving (Eq, Ord, Enum, Read, Show, Bounded)` と並べて書いていたものには、こういう順序関係が隠れていました。

## Semigroup と Monoid

もう一組、実際に使われる例を見ます。[第9回](http://qiita.com/7shi/items/2e9bff5d88302de1a9e9)の Writer モナドで「`w` には `Monoid` 型クラス制約が掛かっていますが、今回の範囲を超えるため省略します」と書いた、その `Monoid` です。

```hs:定義（抜粋）
class Semigroup a where
    (<>) :: a -> a -> a

class Semigroup a => Monoid a where
    mempty :: a
```

2 段構えになっています。

|型クラス|持つもの|意味|
|---|---|---|
|`Semigroup`|`<>`|2 つを**結合**できる|
|`Monoid`|`<>` と `mempty`|結合できて、**単位元**もある|

`Semigroup`（半群）は結合の演算 `<>` だけを持つ段階です。`Monoid`（モノイド）はそれに加えて、結合しても何も変わらない値 `mempty`（単位元）を持ちます。リストなら `<>` が `++`、`mempty` が `[]` です。文字列も同じです。

```hs
main = do
    print $ "abc" <> "def"
    print $ [1,2] <> [3 :: Int]
    print (mempty :: String)
    print (mempty :: [Int])
```
```text:実行結果
"abcdef"
[1,2,3]
""
[]
```

`mempty` は前節で見た「引数に型変数が現れない」メソッドそのものです。`:: String` と `:: [Int]` という型注釈だけで実装が選ばれています。

自分の型をインスタンスにしてみます。カウントを表す型で、`<>` を足し算、`mempty` を `0` とします。

```hs
newtype Count = Count Int deriving Show

instance Semigroup Count where
    Count a <> Count b = Count (a + b)

instance Monoid Count where
    mempty = Count 0

main = do
    print $ Count 1 <> Count 2
    print (mempty :: Count)
    print $ mconcat [Count 1, Count 2, Count 3]
```
```text:実行結果
Count 3
Count 0
Count 6
```

`mconcat` は `Monoid` のメソッドで、リストをまとめて結合します。`mempty` から始めて `<>` で畳み込むだけなので、デフォルト実装が用意されており、こちらで書く必要はありません。

`Semigroup` のインスタンスを書かずに `Monoid` だけ書くとエラーになります。

```hs:NG
newtype Count = Count Int deriving Show

instance Monoid Count where
    mempty = Count 0
```
```text:エラー内容
    • No instance for ‘Semigroup Count’
        arising from the superclasses of an instance declaration
    • In the instance declaration for ‘Monoid Count’
```

`arising from the superclasses`（スーパークラスに由来する）と、はっきり書かれています。

## Writer に載せる

これで第9回の Writer が回収できます。`tell` の型は次の通りです。

```hs:型
tell :: Monoid w => w -> Writer w ()
```

`w` が `Monoid` であることを要求しています。`tell` は状態を上書きするのではなく追記する操作でしたが、その「追記」の実体が `<>` です。そして何も書き込んでいない初期状態が `mempty` です。第9回で主にリストを使っていたのは、リストが `Monoid` のインスタンスで `<>` が `++` になるためでした。

`Count` を載せれば、リスト以外でも Writer が使えます。

```hs
import Control.Monad.Writer

newtype Count = Count Int deriving Show

instance Semigroup Count where
    Count a <> Count b = Count (a + b)

instance Monoid Count where
    mempty = Count 0

test :: Writer Count ()
test = do
    tell (Count 1)
    tell (Count 2)
    tell (Count 3)

main = print $ runWriter test
```
```text:実行結果
((),Count 6)
```

ログを溜め込む代わりに合計だけを取る Writer になりました。Writer 側は何も変えていません。`Monoid` のインスタンスを差し替えるだけで振る舞いが変わるのがアドホック多相です。

:::message
型クラスの継承の応用例として、ベクトル空間を型クラスの階層で表現した記事があります。👉[Haskellで空間を実装してみた](http://qiita.com/7shi/items/0bd828489aa176252fe8)
:::

## 練習

【問2】`Semigroup` と `Monoid` のインスタンスを自作して、Writer モナドで使ってください。

ヒント: 最大値を保持する型など。

:::details 解答例
```hs
import Control.Monad.Writer

newtype MaxInt = MaxInt Int deriving Show

instance Semigroup MaxInt where
    MaxInt a <> MaxInt b = MaxInt (max a b)

instance Monoid MaxInt where
    mempty = MaxInt minBound

test :: [Int] -> Writer MaxInt ()
test = mapM_ (tell . MaxInt)

main = do
    print $ mconcat [MaxInt 3, MaxInt 1, MaxInt 4]
    print $ runWriter (test [3, 1, 4, 1, 5, 9, 2, 6])
```
```text:実行結果
MaxInt 4
((),MaxInt 9)
```

単位元は「`max` を取っても相手が変わらない値」なので、`Int` の最小値 `minBound` になります。ここでも `minBound` が戻り値の型だけで決まるメソッドです。
:::

# 型引数を取る型クラス

ここまでに出てきた型クラスは `Int`・`Bool`・`Color` のような型に付いていました。`Monad` は少し様子が違います。

第7回に載せた対比です。

```hs
a ::            IO Int
b ::            [] Int
c :: Monad m => m  Int
```

`m` に入るのは `IO` や `[]` で、これらは単独では型になりません。`IO Int` や `[] Int`（`[Int]` の別表記）のように型を 1 つ受け取って初めて型になります。つまり `Monad` は型を取って型を返すものに付く型クラスです。

この「型の型」を**種**（kind）と呼びます。GHCi の `:k` で確認できます。

```text:GHCi
ghci> :k Int
Int :: *
ghci> :k Bool
Bool :: *
ghci> :k Maybe
Maybe :: * -> *
ghci> :k []
[] :: * -> *
ghci> :k IO
IO :: * -> *
ghci> :k Either
Either :: * -> * -> *
```

`*` が「そのままで型であるもの」を表します。`Maybe` は `* -> *` で、型を 1 つ受け取って型を返します。関数の型と同じ読み方です。`Either` は 2 つ受け取ります。

型クラスの種も見られます。

```text:GHCi
ghci> :k Show
Show :: * -> Constraint
ghci> :k Monad
Monad :: (* -> *) -> Constraint
```

`Show` は `*` を、`Monad` は `* -> *` を受け取ります。`Constraint` は型クラス制約を表します。ここに型クラスが 2 種類あることがはっきり見えます。

|種|型クラスの例|インスタンスの例|
|---|---|---|
|`*`|`Show`, `Eq`, `Ord`, `Monoid`|`Int`, `Bool`, `Color`|
|`* -> *`|`Monad`|`IO`, `[]`, `Maybe`|

種が合わないインスタンスは書けません。

```hs:NG
instance Monad Int
```
```text:エラー内容
    • Expected kind ‘* -> *’, but ‘Int’ has kind ‘*’
    • In the first argument of ‘Monad’, namely ‘Int’
```

`Int` は `*` なので、`Monad` が要求する `* -> *` に合いません。型に型が付くのと同じように、種が合わないものは弾かれます。

:::message
`instance Monad` を自分で書く、つまりモナドを自作する話は本シリーズでは扱いません。既存のモナドを使いこなす方に絞っています。
:::

# deriving の正体

第2回からずっと使ってきた `deriving` は、インスタンス定義の自動生成でした。

```hs:derivingを使う
data Color = Blue | Red | Green | White deriving Show

main = do
    print Blue
    print [Blue, Red]
    print (Just White)
```
```text:実行結果
Blue
[Blue,Red]
Just White
```

これと同じことを `instance Show Color` を手で書いても実現できます。それが次の練習です。

`deriving` できるのが標準の 6 種類（`Eq`・`Ord`・`Enum`・`Bounded`・`Show`・`Read`）に限られているのは、型の構造から機械的に実装が決まるものだけだからです。

|型クラス|機械的に決まる根拠|
|---|---|
|`Show` / `Read`|コンストラクタの名前をそのまま文字列にする|
|`Eq`|同じコンストラクタで、中身も等しいか|
|`Ord` / `Enum`|`data` に書いた順番|
|`Bounded`|最初と最後のコンストラクタ|

逆に「足し算とは何か」のような意味づけが必要な型クラスは自動生成できません。`Num` が `deriving` できないのはこのためです。

## 練習

【問3】列挙型に `instance Show` を手で書いて、`deriving Show` と同じ出力になることを確かめてください。

:::details 解答例
```hs
data Color = Blue | Red | Green | White

instance Show Color where
    show Blue  = "Blue"
    show Red   = "Red"
    show Green = "Green"
    show White = "White"

main = do
    print Blue
    print [Blue, Red]
    print (Just White)
```
```text:実行結果
Blue
[Blue,Red]
Just White
```

`show` を定義するだけで `print` も `[Color]` も `Maybe Color` も動きます。`print` は `putStrLn . show` に相当し、リストや `Maybe` の表示は `instance Show a => Show [a]` のような制約付きインスタンスが要素の `show` を呼び出すためです。

:::message
引数を持つコンストラクタの場合、`show` だけを定義すると `Just (Circle 1.0)` のような括弧が付きません。`deriving` は `showsPrec` という優先順位を考慮するメソッドの方を生成しています。ここでは深追いしません。
:::
:::

【問4】自作の型に `instance Num` を書いて、`+` や `-` が使えるようにしてください。使わないメソッドは `undefined` で構いません。

ヒント: 2 次元ベクトルなど。`Num` のメソッドは `+`・`-`・`*`・`negate`・`abs`・`signum`・`fromInteger` です。

:::details 解答例
```hs
data Vec = Vec Double Double deriving Show

instance Num Vec where
    Vec a b + Vec c d = Vec (a + c) (b + d)
    Vec a b - Vec c d = Vec (a - c) (b - d)
    negate (Vec a b)  = Vec (negate a) (negate b)
    (*)         = undefined
    abs         = undefined
    signum      = undefined
    fromInteger = undefined

main = do
    print $ Vec 1 2 + Vec 3 4
    print $ Vec 1 2 - Vec 3 4
    print $ negate (Vec 1 2)
    print $ Vec 1 2 + Vec 3 4 - Vec 1 1
```
```text:実行結果
Vec 4.0 6.0
Vec (-2.0) (-2.0)
Vec (-1.0) (-2.0)
Vec 3.0 5.0
```

`+` や `-` は特別な構文ではなく `Num` のメソッドなので、インスタンスを書けば自作の型でも使えます。演算子のオーバーロードがアドホック多相として実現されている例です。

`undefined` を並べる代わりに省略してもコンパイルは通りますが、`-Wall` を付けると警告が出ます。

```text:警告内容
    • No explicit implementation for
        ‘*’, ‘abs’, ‘signum’, ‘fromInteger’, and (either ‘negate’ or ‘-’)
```

`either ‘negate’ or ‘-’` とあるように、この 2 つは互いのデフォルト実装になっています。

`fromInteger` を実装すると、数値リテラルをそのまま自作の型として書けるようになります。

```hs:fromIntegerを実装した場合
    fromInteger n = Vec (fromInteger n) (fromInteger n)
```
```hs
main = do
    print $ Vec 1 2 + 1
    print $ sum [Vec 1 1, Vec 2 2, Vec 3 3]
```
```text:実行結果
Vec 2.0 3.0
Vec 6.0 6.0
```

`1` が `Vec 1 1` として解釈されています。`sum` が動くのも、初期値の `0` が `fromInteger` を通って `Vec 0 0` になるためです。
:::

# 仕組み: 辞書渡し

最後に、アドホック多相が実行時に何をしているのかを見ます。飛ばしても以降に影響はありません。

型クラス制約 `Eq a =>` は、コンパイラがメソッドの実装をまとめたレコードを隠れた引数として渡すことで実現されています。このレコードを**辞書**（dictionary）と呼びます。

`Eq` を例に、手で書き下してみます。

```hs
-- class → メソッドをまとめたレコード型
data EqDict a = EqDict { eqM :: a -> a -> Bool }

-- instance → そのレコードの値
dEqInt :: EqDict Int
dEqInt = EqDict (==)

dEqBool :: EqDict Bool
dEqBool = EqDict (==)

-- 型クラス制約 (Eq a =>) → 隠れた引数
same :: EqDict a -> a -> a -> String
same d x y = if eqM d x y then "同じ" else "違う"

main = do
    putStrLn $ same dEqInt  1 1
    putStrLn $ same dEqBool True False
```
```text:実行結果
同じ
違う
```

対応関係をまとめます。

|型クラスの構文|辞書渡しでの姿|
|---|---|
|`class`|メソッドをまとめたレコード型|
|`instance`|そのレコードの値|
|`Eq a =>`|隠れた引数|
|メソッドの呼び出し|レコードのフィールドの取り出し|

要点は 1 行で言えます。`=>` の左側は、実行時には `->` の引数になっている。

この見方を持つと、前に見た 2 つの現象が同じ理由から出てくることが分かります。

戻り値の型だけで実装が選べる理由。辞書は値とは独立した引数なので、引数に型変数が現れる必要がありません。`mempty` を辞書で書けばこうなります。

```hs
data MonoidDict a = MonoidDict
    { appendM :: a -> a -> a
    , emptyM  :: a
    }

dMonoidList :: MonoidDict [b]
dMonoidList = MonoidDict (++) []

main = do
    print (emptyM dMonoidList :: String)
    print (appendM dMonoidList "abc" "def")
```
```text:実行結果
""
"abcdef"
```

`emptyM dMonoidList` は辞書を渡しただけで値が出てきます。オブジェクト指向では、オブジェクト自身が実装表（vtable）を持ち歩くため、値がなければメソッドを呼べません。Haskell は辞書が値から独立しているので、型さえ決まれば値がなくても実装を選べます。

ambiguous エラーになる理由。型が決まらないということは、渡すべき辞書が決まらないということです。「曖昧」の正体はこれです。

スーパークラスは辞書が辞書を含む形になります。`Ord` の辞書は中に `Eq` の辞書を持っており、だから `Ord a =>` と書くだけで `==` も使えます。

:::message
これは意味論としての説明です。実際の GHC は最適化で辞書渡しを消してしまうことが多く（型が具体的に分かる箇所は特殊化して直接呼び出しにする）、生成されるコードが常にこの形とは限りません。
:::

# まとめ

型クラスはアドホック多相、つまり型ごとに違う実装を選ぶ仕組みです。

|   |実装|制約|例|
|---|---|---|---|
|パラメトリック多相|すべての型で同じ|なし|`id`, `length`|
|アドホック多相|型ごとに違う|`=>` が付く|`show`, `==`, `return`|

`class` で宣言し、`instance` で型ごとに実装します。デフォルト実装を書いておけば `instance` 側を省略でき、その最低限が最小完全定義です。スーパークラスで階層を作れます。`deriving` はインスタンス定義の自動生成で、構造から機械的に決まるものに限られます。

そして実装を選ぶのは値ではなく型です。だから `read s :: Int` のように戻り値の型だけで実装が決まり、型が決まらなければ ambiguous エラーになります。仕組みとしては、制約が実行時の隠れた引数（辞書）になっていると考えれば説明が付きます。

シリーズでずっと使ってきた `return :: Monad m => a -> m a` も同じ形です。`IO`・`[]`・`Maybe`・`Cont` のどれにもなれたのは、`m` が決まった時点でその `Monad` インスタンスの実装が選ばれていたからです。

次回はその `Monad` の周辺を見ます。`Functor`・`Applicative` という、これまで名前だけ出して先送りにしてきた型クラスたちです。今回スーパークラスを済ませたので、それらが階層をなしていることも説明できるようになりました。
