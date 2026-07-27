---
coediting: false
comments_count: 0
created_at: '2014-08-25T12:43:28+09:00'
id: cd7f65a898dd5696c73d
likes_count: 9
private: false
reactions_count: 0
stocks_count: 9
tags:
- name: Haskell
  versions: []
- name: F#
  versions: []
title: Haskellの型クラスとF#のインターフェース
updated_at: '2015-05-07T12:00:24+09:00'
url: https://qiita.com/7shi/items/cd7f65a898dd5696c73d
slide: false
---

[Haskellの実験メモ](http://qiita.com/7shi/items/b6cbb7df2dd969c84f49)です。

Haskellの型クラスはオブジェクト指向言語のインターフェースと似ている面があります。特にF#のインターフェースは書式まで似ているため比較してみます。ただし似ているのは定義だけで、実装や呼び出し方法はあまり似ていません。

* 参考: [Haskellで関数のオーバーロード](http://qiita.com/7shi/items/17a1567a635af17fc83f)

# 定義

書式がとても似ています。

```hs:Haskell:型クラス
class Foo a where
    foo :: a -> String
```

```fsharp:F#:インターフェース
type Foo<'a> =
    abstract foo: 'a -> string
```

# 実装

Haskellの型クラスは、対象となる型とは分離した形で型クラスのインスタンスを作成します。

```hs:Haskell
instance (Num a, Eq a) => Foo a where
    foo 1 = "bar"
    foo _ = "?"

instance Foo String where
    foo "1" = "baz"
    foo _   = "?"
```

F#はあくまでオブジェクト指向的な意味合いでのインターフェースなので、クラスを定義して実装します。

```fsharp:F#
type FooInt() =
    interface Foo<int> with
        member x.foo a =
            match a with
            | 1 -> "bar"
            | _ -> "?"

type FooString() =
    interface Foo<string> with
        member x.foo a =
            match a with
            | "1" -> "baz"
            | _   -> "?"
```

# 呼び出し

Haskellの型クラスの関数はそのまま呼び出せます。

```hs:Haskell
main = do
    putStrLn $ foo 1
    putStrLn $ foo "1"
```

F#ではクラスのインスタンスを作成して、インターフェースにキャストして呼び出します。

```fsharp:F#
printfn "%s" <| (FooInt   () :> Foo<int>   ).foo 1
printfn "%s" <| (FooString() :> Foo<string>).foo "1"
```

そもそも概念が異なるので、同列に比較するのは無理があります。

# メソッドのオーバーロード

F#ではメソッドのオーバーロードが可能です。今回の例ではこちらを使った方が簡単です。

```fsharp:F#
type Foo =
    static member foo a =
        match a with
        | 1 -> "bar"
        | _ -> "?"

    static member foo a =
        match a with
        | "1" -> "baz"
        | _   -> "?"

printfn "%s" <| Foo.foo 1
printfn "%s" <| Foo.foo "1"
```

F#では型クラスに相当するものはありませんが、必要に応じてインターフェースかオーバーロードを使い分けることになりそうです。
