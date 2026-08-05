# Applicative と Monad の違いの検証（記事「Applicative と Monad の違い」の節）

GHC 9.6.6。実行は `runghc {ファイル名}`。

| ファイル | 内容 |
|---|---|
| `AppVsMonad.hs` | `>>=` は前の結果に依存でき、`<*>` は構造が事前に決まっている |
| `ZipList.hs` | リストの `<*>`（全組み合わせ）と `ZipList` の `<*>`（同位置）の対比 |
| `ZipBind.hs` | `ZipList` 相当の型にリストと同じ `>>=` を書くと `<*>` と `ap` が食い違うこと |

## 実行結果

`AppVsMonad.hs`:

```
[1,2,2,3,3,3]
[(1,10),(1,20),(2,10),(2,20)]
Just 2
```

`ZipList.hs`:

```
[11,21,31,12,22,32,13,23,33]
[11,22,33]
```

`ZipBind.hs`:

```
[(1,10),(2,20)]
[(1,10),(1,10),(1,10),(1,10)]
```

1 行目が `<*>`、2 行目が同じ型の `>>=` から組み立てた `ap`。
`(<*>) == ap` はモナドが守るべき規則なので、この `Zip` は `Monad` として失格。

`ap` の結果が無限リストになるのは `return`（= `pure`）が `Zip . repeat` のため。
記事では `take 4` で打ち切っている。この点も「整合する `>>=` が存在しない」ことの現れ。

## 補足

base の `ZipList` には `Monad` インスタンスがない。
`Functor`・`Applicative`・`Alternative`・`Foldable`・`Traversable` は用意されている。

```
ghci> :i ZipList
type ZipList :: * -> *
newtype ZipList a = ZipList {getZipList :: [a]}
instance Traversable ZipList
instance Foldable ZipList
instance Alternative ZipList
instance Applicative ZipList
instance Functor ZipList
（略）
```
