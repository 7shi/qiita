# class と instance の検証（記事「class と instance」の節）

GHC 9.6.6。実行は `runghc {ファイル名}`。

| ファイル | 内容 |
|---|---|
| `Foo.hs` | `class Foo` を定義し `Int`・`Bool` をインスタンスにする。02回の Java のオーバーロードに対応 |
| `FooColor.hs` | 自作型 `Color` もインスタンスにする |
| `FooAmbiguous.hs` | `foo 1` と型注釈を外すとコンパイルエラー |
| `FooNoInstance.hs` | インスタンスのない型に使うとコンパイルエラー |

## 実行結果

`Foo.hs`:

```
?
bar
?
baz
```

`FooColor.hs`:

```
bar
青
?
```

`FooAmbiguous.hs`（コンパイルエラー）:

```
FooAmbiguous.hs:8:19: error: [GHC-39999]
    • Ambiguous type variable ‘a0’ arising from a use of ‘foo’
      prevents the constraint ‘(Foo a0)’ from being solved.
      Probable fix: use a type annotation to specify what ‘a0’ should be.
      Potentially matching instance:
        instance Foo Int
```

数値リテラルの型が決まらないため。標準の型クラスではないので型のデフォルト規則が働かない。

`FooNoInstance.hs`（コンパイルエラー）:

```
FooNoInstance.hs:10:19: error: [GHC-39999]
    • No instance for ‘Foo Color’ arising from a use of ‘foo’
```

02回の `No instance for (Show Color)` と同じ形。
