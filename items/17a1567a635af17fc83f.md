---
coediting: false
comments_count: 0
created_at: '2014-08-22T16:13:38+09:00'
id: 17a1567a635af17fc83f
likes_count: 39
private: false
reactions_count: 0
stocks_count: 32
tags:
- name: Haskell
  versions: []
title: Haskellで関数のオーバーロード
updated_at: '2016-09-19T18:48:23+09:00'
url: https://qiita.com/7shi/items/17a1567a635af17fc83f
slide: false
---

[Haskellの実験メモ](http://qiita.com/7shi/items/b6cbb7df2dd969c84f49)です。

HaskellでC++やJavaなどでできる関数のオーバーロードのようなことをやってみました。型クラスについての簡単な説明も含みます。

新しい言語を使うときはまさに手探りで、試行錯誤の過程についても記載しています。パターンマッチによる関数の分割定義を見たとき、関数のオーバーロードに似ていると感じたことが発端となっています。

# C++

C++では同じ名前で引数の型が異なる関数を複数定義することができます。（関数のオーバーロード）

```cpp
#include <iostream>
#include <string>

using namespace std;

string foo(int i) {
    if (i == 1) return "bar";
    return "?";
}

string foo(const string &s) {
    if (s == "1") return "baz";
    return "?";
}

int main() {
    cout << foo(1) << endl;
    cout << foo("1") << endl;
}
```
```text:実行結果
bar
baz
```

# Haskell

結論から言うと次のコードで同等な処理ができます。

```hs
{-# LANGUAGE FlexibleInstances    #-}
{-# LANGUAGE UndecidableInstances #-}
{-# LANGUAGE IncoherentInstances  #-}

class Foo a where
    foo :: a -> String

instance (Num a, Eq a) => Foo a where
    foo 1 = "bar"
    foo _ = "?"

instance Foo String where
    foo "1" = "baz"
    foo _   = "?"

main = do
    putStrLn $ foo 1
    putStrLn $ foo "1"
```
```text:実行結果
bar
baz
```

ここにたどり着くまでにはかなり試行錯誤しました。

## 引数の型エラー

最初に試したものはエラーになりました。

```hs
foo 1   = "bar"
foo "1" = "baz"
foo _   = "?"

main = do
    putStrLn $ foo 1
    putStrLn $ foo "1"
```
```text:エラー内容
src\Main.hs:1:5:
    No instance for (Num [Char]) arising from the literal `1'
    Possible fix: add an instance declaration for (Num [Char])
    In the pattern: 1
    In an equation for `foo': foo 1 = "bar"
```

型が異なるものはパターンマッチできません。

## 型クラス

Haskellには型クラスという機能があります。これは型のグループ化で、関数をそのグループ（型クラス）に対して定義します。クラスという名称からオブジェクト指向言語（Javaなど）のクラスを連想させますが、どちらかというとクラスというよりインターフェースに近いです。Haskellの`instance`は実装を任意の型に後付けできます。

* 参考 1: [型クラス - ウォークスルー Haskell](http://walk.wgag.net/haskell/typeclass.html)
* 参考 2: [Haskellの型クラスとF#のインターフェース](http://qiita.com/7shi/items/cd7f65a898dd5696c73d)

関数`foo`を含む型クラス`Foo`を定義して`Int`と`String`を登録しましたが、エラーとなりました。

```hs
class Foo a where
    foo :: a -> String

instance Foo Int where
    foo 1 = "bar"
    foo _ = "?"

instance Foo String where
    foo "1" = "baz"
    foo _   = "?"

main = do
    putStrLn $ foo 1
    putStrLn $ foo "1"
```
```text:エラー内容
src\Main.hs:8:10:
    Illegal instance declaration for `Foo String'
      (All instance types must be of the form (T t1 ... tn)
       where T is not a synonym.
       Use -XTypeSynonymInstances if you want to disable this.)
    In the instance declaration for `Foo String'
```

`String`はPreludeの中で`type String = [Char]`と定義されている型シノニムです。デフォルトでは型シノニムは型クラスのインスタンスに指定できませんが、エラーにもあるようにTypeSynonymInstances拡張で許可されます。

* 参考 3: [Haskellの言語拡張たち - rfなブログ](http://rf0444.hatenablog.jp/entry/20120513/1336883141)

しかしこれだけではエラーになります。

```hs:ソースの頭に追加
{-# LANGUAGE TypeSynonymInstances #-}
```
```text:エラー内容
src\Main.hs:10:10:
    Illegal instance declaration for `Foo String'
      (All instance types must be of the form (T a1 ... an)
       where a1 ... an are *distinct type variables*,
       and each type variable appears at most once in the instance head.
       Use -XFlexibleInstances if you want to disable this.)
    In the instance declaration for `Foo String'
```

`String`の実体は`[Char]`ですが、これはリストの型クラスに対するインスタンスです。デフォルトでは型クラスのインスタンスに指定できませんが、エラーにもあるようにFlexibleInstances拡張で許可されます。

FlexibleInstancesにはTypeSynonymInstancesも含むため、簡単のため前者のみを指定します。

```hs:ソースの頭に追加
{-# LANGUAGE FlexibleInstances #-}
```

## 数値リテラル

FlexibleInstancesにより型クラスのエラーは解消しますが、今度は呼び出す側でエラーとなります。

```text:エラー内容
src\Main.hs:14:16:
    No instance for (Foo a0) arising from a use of `foo'
    The type variable `a0' is ambiguous
    Possible fix: add a type signature that fixes these type variable(s)
    （略）

src\Main.hs:14:20:
    No instance for (Num a0) arising from the literal `1'
    The type variable `a0' is ambiguous
    Possible fix: add a type signature that fixes these type variable(s)
    （略）
```

エラーにあるように呼び出す側の引数に型を指定すれば動きます。

```hs:修正箇所
    putStrLn $ foo (1 :: Int)
```
```text:実行結果
bar
baz
```

これで一応は目的を達成しましたが、やや不満があります。`show`では`:: Int`などと書かなくてもちゃんと動くので、型を指定しなくても済むようにす方法があるはずです。

```hs:showの例
main = do
    putStrLn $ show 1
    putStrLn $ show "1"
```
```text:実行結果
1
"1"
```

`show`のような使い勝手を目指してもう少し続けます。

## Num

エラーを見ると`Num`についての記載があります。

```text:エラーの該当箇所
    No instance for (Num a0) arising from the literal `1'
```

型クラスのインスタンスを`Int`から`Num`に変更するとエラーになります。

```hs:修正箇所
instance Num a => Foo a where
```
```text:エラー内容
src\Main.hs:7:10:
    Constraint is no smaller than the instance head
      in the constraint: Num a
    (Use -XUndecidableInstances to permit this)
    In the instance declaration for `Foo a'
```

デフォルトでは型クラスのインスタンスに型制約を指定できませんが、エラーにもあるようにUndecidableInstances拡張で許可されます。

```hs:ソースの頭に追加
{-# LANGUAGE UndecidableInstances #-}
```

しかしまた別のエラーです。

```text:エラー内容
src\Main.hs:9:9:
    Could not deduce (Eq a) arising from the literal `1'
    from the context (Num a)
      bound by the instance declaration at src\Main.hs:8:10-23
    Possible fix: add (Eq a) to the context of the instance declaration
    （略）

src\Main.hs:16:16:
    Overlapping instances for Foo [Char] arising from a use of `foo'
    （略）
```

1つ目のエラーはパターンマッチで値が比較できないことが原因です。エラーにもあるように型制約`Eq`を追加します。

```hs:修正箇所
instance (Num a, Eq a) => Foo a where
```

2つ目のエラーは`String`が`Num a`の`a`として解釈（`Num String`）されようとすることに起因します。GHCiで`Num`のインスタンスを確認します。

```hs:GHCi
Prelude> :i Num
class Num a where
（略）
        -- Defined in `GHC.Num'
instance Num Integer -- Defined in `GHC.Num'
instance Num Int -- Defined in `GHC.Num'
instance Num Float -- Defined in `GHC.Float'
instance Num Double -- Defined in `GHC.Float'
```

型クラスに登録されていないインスタンスを除外するためIncoherentInstances拡張を有効化します。

```hs:ソースの頭に追加
{-# LANGUAGE IncoherentInstances #-}
```

正常に動くようになりました。これで最初に掲載したコードが得られました。

さくっとIncoherentInstances拡張を持ち出して解決しましたが、たどり着くまではかなりの試行錯誤が必要でした。

## IncoherentInstances拡張

手詰まりとなったため、Preludeで`show`がどのように定義されているかを調べました。

* [The Haskell 98 Report: Standard Prelude](http://www.haskell.org/onlinereport/standard-prelude.html)

`Show [a]`を定義して、型制約`Show a`により`Show Char`から`[Char]`を絞り込んでいるようです。

```hs:Preludeより抜粋
instance  Show Char  where
    （略）

instance  (Show a) => Show [a]  where
    showsPrec p      = showList
```

とりあえずPreludeから`Show`を書き写して試行錯誤しました。その過程で次のようなエラーが起きました。

```hs:Showの改造
{-# LANGUAGE UndecidableInstances,FlexibleInstances #-}

class Show' a where
    show' :: a -> String
    show' _ = "?"

instance Show' Integer where
    show' _ = "Integer"

instance Show' Int  where
    show' _ = "Int"

instance Show' Float where
    show' _ = "Float"

instance Show' Double where
    show' _ = "Double"

instance Show' Char where
    show' _ = "Char"

instance Show' a => Show' [a] where
    show' _ = "List"

instance Num a => Show' a where
    show' _ = "Num"

main = do
    print (show' 1)
    --print (show' "1")
```
```text:エラー内容
src\Main.hs:29:12:
    Overlapping instances for Show' a0 arising from a use of show'
    Matching instances:
    （略）
    (The choice depends on the instantiation of `a0'
     To pick the first instance above, use -XIncoherentInstances
     when compiling the other instance declarations)
    （略）
```

どうやら型制約`Show' a`と`Num a`が競合して、それを回避するためにIncoherentInstances拡張が提案されたようです。このような経緯で発見しました。
