---
coediting: false
comments_count: 0
created_at: '2014-09-19T22:08:30+09:00'
id: 1ce76bde464b4a55c143
likes_count: 157
private: false
reactions_count: 0
stocks_count: 126
tags:
- name: Java
  versions: []
- name: Haskell
  versions: []
title: Haskell 代数的データ型 超入門
updated_at: '2016-05-05T12:43:39+09:00'
url: https://qiita.com/7shi/items/1ce76bde464b4a55c143
slide: false
---

代数的データ型の基本的な使い方を説明します。

シリーズの記事です。

1. [Haskell 超入門](http://qiita.com/7shi/items/145f1234f8ec2af923ef)
1. Haskell 代数的データ型 超入門 ← この記事
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
1. 【予定】Haskell 継続モナド 超入門
1. 【予定】Haskell 型クラス 超入門
1. 【予定】Haskell モナドとゆかいな仲間たち
1. 【予定】Haskell Freeモナド 超入門
1. 【予定】Haskell Operationalモナド 超入門
1. 【予定】Haskell Effモナド 超入門
1. 【予定】Haskell アロー 超入門

練習の解答例は別記事に掲載します。

* [【解答例】Haskell 代数的データ型 超入門](http://qiita.com/7shi/items/0bed757ed0b51944a669)

この記事には応用編があります。

* [Haskellによる代数計算入門](http://qiita.com/7shi/items/096396f0007857676515)

この記事には@shigemk2さんによるScala版があります。

* [Scala 代数的データ型 超入門](http://qiita.com/shigemk2/items/31f6bdbf4dfebb0b9adc)

# 代数的データ型

以下の3つを合わせて代数的データ型と呼びます。

1. 列挙型（他言語の`enum`に相当）
2. 直積型（他言語の`struct`に相当）
3. 直和型（他言語の`union`に相当）

これらを1つずつ見ていきます。

# 列挙型

種類を区別するための型です。他言語の`enum`に相当します。

```hs
data Color = Blue | Red | Green | White
```

この例での`Color`を型（型構築子）、`Blue`などをコンストラクタ（データ構築子）と呼びます。

※ コンストラクタは構築子と訳されます。用語は括弧書きの型構築子やデータ構築子と呼ばれることが一般的です。ここではオブジェクト指向言語での慣例に従いカタカナ表記として、用語は以下の記事に合わせています。

* [型 - HaskellWiki](https://www.haskell.org/haskellwiki/%E5%9E%8B) 2009.12.7

## 命名規則

型とコンストラクタは大文字で始める必要があります。

小文字で始めるとエラーになります。

```hs:NG-型
data color = Blue | Red | Green | White
```
```text:エラー内容
Malformed head of type or class declaration: color
```

```hs:NG-コンストラクタ
data Color = blue | Red | Green | White
```
```text:エラー内容
Not a data constructor: `blue'
```

※ 変数・関数が小文字始まりなのと対になる仕様です。

## Show

自分で定義した型はそのままでは`print`で表示できません。

```hs:NG
data Color = Blue | Red | Green | White

main = do
    print Blue
```
```text:エラー内容
No instance for (Show Color) arising from a use of `print'
Possible fix: add an instance declaration for (Show Color)
（略）
```

型定義の最後に`deriving Show`を追加すれば表示できるようになります。

```hs:OK
data Color = Blue | Red | Green | White deriving Show

main = do
    print Blue
```
```text:実行結果
Blue
```

`deriving`により自分で定義した型に機能が追加できます。機能を表す部分（`Show`）は**型クラス**と呼ばれます。標準で指定できる型クラスは6種類ですが、後で`Bool`の定義とともに掲載します。

## Enum

型クラス`Enum`を指定すれば数値と相互変換できるようになります。

関数名|機能|備考
------|----|----
`fromEnum`|列挙型 → 数値|`0`始まり
`toEnum`|数値 → 列挙型|`::`で変換する型を指定、範囲外はエラー

例を示します。複数の型クラスを指定するには括弧で囲みます。

```hs
data Color = Blue | Red | Green | White deriving (Show, Enum)

main = do
    print $ fromEnum Blue
    print $ fromEnum Red
    print $ fromEnum Green
    print $ fromEnum White
    print (toEnum 0 :: Color)
    print (toEnum 1 :: Color)
    print (toEnum 2 :: Color)
    print (toEnum 3 :: Color)
```
```text:実行結果
0
1
2
3
Blue
Red
Green
White
```

※ 演算子の優先順位の関係上、`::`は括弧で囲む必要があります（`$`ではなく）。

## Bool

真偽値を表す`Bool`は標準ライブラリ（Prelude）で定義された列挙型です。

```hs:定義
data Bool = False | True deriving (Eq, Ord, Enum, Read, Show, Bounded)
```

標準で指定できる6種類の型クラスがすべて指定されています。

型クラス|概要
-------|----
`Eq`   |`==`や`/=`で比較できます。
`Ord`  |順番を持ちます。`<`や`>`で大小比較できます。
`Read` |文字列から変換できます。
`Bounded`|最小値と最大値を持ちます。

※ 具体的な使用例については、今回の範囲を超えるため詳細は省略します。

## 練習

【問1】光の三原色と、2つの色を混合する関数`mix`を定義してください。混ぜることによってできる色も定義の対象とします。ただし同じ成分同士は強め合わないものとします。

ヒント: `mix Blue Red = Magenta`, その他の色 `Green | Cyan | Yellow | White`

⇒ [解答例](http://qiita.com/7shi/items/0bed757ed0b51944a669#%E5%88%97%E6%8C%99%E5%9E%8B)

# 直積型

内部に値を持つ型です。他言語の構造体に相当します。馴染みのない用語かもしれませんが、集合論に由来します。

## 構文

```hs
data 型 = コンストラクタ [フィールドの型 ...]
```

型とコンストラクタは同名でも別名でも構いません。

同名の例を示します。

```hs
data Point = Point Int Int deriving Show

offset (Point x1 y1) (Point x2 y2) =
    Point (x1 + x2) (y1 + y2)

main = do
    let a = Point 2 3
        b = Point 1 1
        c = offset a b
    print c
```
```text:実行結果
Point 3 4
```

フィールドの値はパターンマッチで取り出します。名前による方法はレコード構文として後述します。

## 直積

何が積なのかというイメージを説明します。

先ほどの例で`Point 3 4`というのは、`3`と`4`が組み合わさって1つのデータを構成しています。これを`3*4`のような因数の組み合わせで1つの項を構成しているように捉えます。

集合論による説明は次の記事を参照してください。

* [@CyLomw](https://twitter.com/CyLomw): [Haskell - GHC 拡張を使って直積っぽい型の表記とかしてみる - Qiita](http://qiita.com/CyLomw/items/7e72e98cfe1c8026df2a) 2015.1.13

## newtype

フィールドが1つだけの直積型は`newtype`という別のキーワードで定義できます。

```hs:構文
newtype 型 = コンストラクタ フィールドの型
```
```hs:例
newtype Foo = Foo Int
```

内部処理の違いから`data`よりも高速に動作するため、フィールドが1つだけなら`newtype`で定義した方が良いとされています。`data`とは評価タイミングなど細かい部分で違いがありますが、通常ほとんど意識する必要はありません。参考リンクを置いておきます。

* [Newtype - HaskellWiki](https://www.haskell.org/haskellwiki/Newtype) 2014.11.22

## 練習

【問2】x,y,w,hを表現した`Rect`型を定義して、`Rect`に`Point`が含まれるかどうかを判定する関数`contains`を実装してください。

具体的には以下のコードが動くようにしてください。

```hs
main = do
    print $ contains (Rect 2 2 3 3) (Point 1 1)
    print $ contains (Rect 2 2 3 3) (Point 2 2)
    print $ contains (Rect 2 2 3 3) (Point 3 3)
    print $ contains (Rect 2 2 3 3) (Point 4 4)
    print $ contains (Rect 2 2 3 3) (Point 5 5)
```
```text:実行結果
False
True
True
True
False
```

⇒ [解答例](http://qiita.com/7shi/items/0bed757ed0b51944a669#%E7%9B%B4%E7%A9%8D%E5%9E%8B)

# 直和型

列挙型にフィールドを付加することで、複数の直積型を定義したものです。列挙型と直積型の両方の特徴を併せ持っています。

```hs:構文
data 型 = コンストラクタ [フィールドの型 ...] | コンストラクタ [フィールドの型 ...] [| ...]
```
```hs:例
data Foo = Bar Int Int | Baz Int Int Int
```

この名前も集合論に由来します。複数の直積型の和だと捉えれば、イメージしやすいかもしれません。

* `Bar Int Int | Baz Int Int Int` → Int*Int + Int*Int*Int

※ C言語では共用体に相当しますが、C言語のように共用体のフィールドを選ぶことで解釈を変えることはできません。区別が保持されるという意味合いでF#では判別共用体と呼びます。

## サンプル

```hs
data Test = TestInt Int
          | TestStr String
          deriving Show

foo (TestInt  1 ) = "bar"
foo (TestStr "1") = "baz"
foo _             = "?"

main = do
    print $ foo $ TestInt  0
    print $ foo $ TestInt  1
    print $ foo $ TestStr "0"
    print $ foo $ TestStr "1"
```
```text:実行結果
"?"
"bar"
"?"
"baz"
```

関数の引数は同一の型しか受け付けないため、通常は数値`Int`と文字列`String`の両方を渡すことはできません。この例では代数的データ型を挟むことでどちらも渡せるようにしています。

## オブジェクト指向との比較

オブジェクト指向の感覚では`Test`が基底クラス、`TestInt`と`TestStr`が派生クラスに相当します。関数の扱いは基底クラスのメソッドを派生クラスでオーバーライドする感覚に近いです。

```java:Test.java
class TestInt extends Test {
    private int i;
    public TestInt(int i) { this.i = i; }
    public String foo() {
        if (i == 1) return "bar";
        return super.foo();
    }
}

class TestStr extends Test {
    private String s;
    public TestStr(String s) { this.s = s; }
    public String foo() {
        if (s.equals("1")) return "baz";
        return super.foo();
    }
}

abstract class Test {
    public String foo() { return "?"; }
    public static void main(String[] args) {
        System.out.println(new TestInt( 0 ).foo());
        System.out.println(new TestInt( 1 ).foo());
        System.out.println(new TestStr("0").foo());
        System.out.println(new TestStr("1").foo());
    }
}
```
```text:実行結果
?
bar
?
baz
```

### オーバーロード

この例ではわざわざ型を作らなくてもオーバーロードした方が簡単です。

```java:Test.java
class Test {
    public static String foo() {
        return "?";
    }
    public static String foo(int i) {
        if (i == 1) return "bar";
        return foo();
    }
    public static String foo(String s) {
        if (s.equals("1")) return "baz";
        return foo();
    }
    public static void main(String[] args) {
        System.out.println(foo( 0 ));
        System.out.println(foo( 1 ));
        System.out.println(foo("0"));
        System.out.println(foo("1"));
    }
}
```
```text:実行結果
?
bar
?
baz
```

Haskellでも型クラスを自分で定義すればオーバーロードと似たようなことが可能です。型クラスの定義は今回の範囲を超えますが、参考リンクを置いておきます。

* [Haskellで関数のオーバーロード](http://qiita.com/7shi/items/17a1567a635af17fc83f)
* [Haskellの型クラスとF#のインターフェース](http://qiita.com/7shi/items/cd7f65a898dd5696c73d)

## リスト

リストは直和型として定義されています。

```hs:定義
data [a] = [] | a:[a]
```

※ `a`は型変数と呼ばれ任意の型が入ります。今回の範囲を超えるため詳細は省略します。

後者は再帰的に`a:([] | a:[a])`と変形できるため、後続要素が無限に続く可能性があります。

* `a:(a:(a: ... ([])))`

### 型シノニム

文字のリストが文字列です。`[Char]`（文字のリスト）に`String`という別名を付けています。

```hs:定義
type String = [Char]
```

このような別名を**型シノニム**と呼びます。[synonym](http://ja.wikipedia.org/wiki/%E3%82%B7%E3%83%8E%E3%83%8B%E3%83%A0)は**同意語・別名**という意味です。

## 練習

【問3】`Rect`と`Point`を2次元と3次元の両方に対応させて、問2の`contains`も対応させてください。

具体的には以下のコードが動くようにしてください。

```hs
main = do
    print $ contains (Rect 2 2 3 3) (Point 1 1)
    print $ contains (Rect 2 2 3 3) (Point 2 2)
    print $ contains (Rect 2 2 3 3) (Point 3 3)
    print $ contains (Rect 2 2 3 3) (Point 4 4)
    print $ contains (Rect 2 2 3 3) (Point 5 5)
    print $ contains (Rect3D 2 2 2 3 3 3) (Point3D 1 1 1)
    print $ contains (Rect3D 2 2 2 3 3 3) (Point3D 2 2 2)
    print $ contains (Rect3D 2 2 2 3 3 3) (Point3D 3 3 3)
    print $ contains (Rect3D 2 2 2 3 3 3) (Point3D 4 4 4)
    print $ contains (Rect3D 2 2 2 3 3 3) (Point3D 5 5 5)
```
```text:実行結果
False
True
True
True
False
False
True
True
True
False
```

⇒ [解答例](http://qiita.com/7shi/items/0bed757ed0b51944a669#%E7%9B%B4%E5%92%8C%E5%9E%8B)

# レコード構文

直積型や直和型のフィールドに名前を付けることができます。これを**レコード構文**と呼びます。

```hs:構文
data 型 = コンストラクタ { 名前 :: 型 [, 名前 :: 型 ...] } [| ...]
```

フィールド名は小文字で始める必要があります。

```hs:例
data Foo = Foo { bar :: Int, baz :: String }
```

## 生成

```hs:構文
コンストラクタ { 名前 = 値 [, 名前 = 値 ...] }
```
```hs:例
Foo { bar = 1, baz = "a" }
```

無名のときと同じ方法でも生成できます。その場合でも`print`では名前が表示されます。

両方の例を示します。

```hs
data Foo = Foo { bar :: Int, baz :: String } deriving Show

main = do
    print $ Foo { bar = 1, baz = "a" }  -- 名前を指定して束縛
    print $ Foo 2 "b"                   -- 無名のときと同じ方法
```
```text:実行結果
Foo {bar = 1, baz = "a"}
Foo {bar = 2, baz = "b"}
```

## フィールド値の取得

フィールド名がそのままフィールド値を取得する関数になります。無名のときと同様にパターンマッチでも取り出せます。レコード構文でパターンマッチすることもできます。

```hs
data Foo = Foo { bar :: Int, baz :: String } deriving Show

main = do
    let f = Foo { bar = 1, baz = "a" }
    print f
    print (bar f, baz f)       -- フィールド名を関数として使用
    let (Foo a b) = f          -- パターンマッチで取り出し
    print (a, b)
    let (Foo { bar = c }) = f  -- レコード構文でパターンマッチ
    print c
```
```text:実行結果
Foo {bar = 1, baz = "a"}
(1,"a")
(1,"a")
1
```

## 一部を変更したコピー

Haskellの変数は値を書き換えることができませんが、フィールドも同様です。その代わり一部の値を変更したコピーを生成できます。

```hs:構文
変数 { 名前 = 値 [, 名前 = 値 ...] }
```

例を示します。

```hs
data Foo = Foo { bar :: Int, baz :: String } deriving Show

main = do
    let f = Foo { bar = 1, baz = "a" }
        g = f   { bar = 2 }  -- barを変更したコピー
    print f                  -- 元のまま
    print g                  -- 変更されたコピー
```
```text:実行結果
Foo {bar = 1, baz = "a"}
Foo {bar = 2, baz = "a"}
```

## 練習

【問4】問2の解答をレコード構文で書き直してください。

⇒ [解答例](http://qiita.com/7shi/items/0bed757ed0b51944a669#%E3%83%AC%E3%82%B3%E3%83%BC%E3%83%89%E6%A7%8B%E6%96%87)

# 参考

レコード構文は次の記事を参考にしました。

* [@eielh](https://twitter.com/eielh): [Haskell のフィールドラベルをもつデータ型について - そんなこと覚えてない](http://blog.eiel.info/blog/2014/09/06/datatypes-with-field-labels-for-haskell/) 2014.9.6

レコード構文を使い倒すためのLensというライブラリがあります。オブジェクト指向のようなことができるようです。

* [lens: Lenses, Folds and Traversals | Hackage](http://hackage.haskell.org/package/lens)
* [@kazu_yamamoto](https://twitter.com/kazu_yamamoto): [Lensことはじめ - あどけない話](http://d.hatena.ne.jp/kazu-yamamoto/20130319/1363661572) 2013.3.19
