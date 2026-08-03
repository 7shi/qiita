# 戻り値の型で実装が選ばれることの検証（記事「戻り値の型で実装が選ばれる」の節）

GHC 9.6.6。実行は `runghc {ファイル名}`。

| ファイル | 内容 |
|---|---|
| `ReadBounded.hs` | `read`・`minBound`・`maxBound`・`mempty` が型注釈だけで実装を選ぶ。02回で例を省略した `Read`・`Bounded` の回収 |
| `Ambiguous.hs` | `print (read "123")` の ambiguous type variable エラー |
| `Defaulting.hs` | 数値リテラルは型のデフォルト規則で注釈なしに動く |

## 実行結果

`ReadBounded.hs`:

```
123
1.5
Red
-9223372036854775808
Blue
White
[Blue,Red,Green,White]
""
[]
```

`Ambiguous.hs`（コンパイルエラー、2箇所に出る）:

```
Ambiguous.hs:1:8: error: [GHC-39999]
    • Ambiguous type variable ‘a0’ arising from a use of ‘print’
      prevents the constraint ‘(Show a0)’ from being solved.
      Probable fix: use a type annotation to specify what ‘a0’ should be.
（略）
Ambiguous.hs:1:15: error: [GHC-39999]
    • Ambiguous type variable ‘a0’ arising from a use of ‘read’
      prevents the constraint ‘(Read a0)’ from being solved.
      Probable fix: use a type annotation to specify what ‘a0’ should be.
```

記事には冒頭の2行ずつを抜粋して掲載した。

`Defaulting.hs`:

```
1
3
1.5
```

決まらない数値は `Integer`、小数が絡めば `Double` になる。標準の型クラスにしか
働かないため、自作の `Foo`（`../14-class-instance/FooAmbiguous.hs`）では救われない。
