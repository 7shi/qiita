# Applicative と Monad の違いの検証（記事「Applicative と Monad の違い」の節）

GHC 9.6.6。実行は `runghc {ファイル名}`。

| ファイル | 内容 |
|---|---|
| `AppVsMonad.hs` | `>>=` は前の結果に依存でき、`<*>` は構造が事前に決まっている |
| `ZipList.hs` | `ZipList` の定義と、リストの `<*>`（全組み合わせ）との対比 |
| `ZipListBase.hs` | base の `ZipList` を使うと `ZipList.hs` と同じ結果になること |
| `ZipListLaws.hs` | `ZipList.hs` の定義が `Applicative` 則を満たすこと |
| `ZipDiag.hs` | 自前の `ZipList` に対角線を取る `>>=` を書くと `<*>` と `ap` が一致すること |
| `ZipAssoc.hs` | その `>>=` が結合法則を破ること（単位元則は成り立つ） |

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
ZipList {getZipList = [11,22,33]}
[11,22,33]
ZipList {getZipList = [110,120,130]}
[0,0,0]
```

2 行目（`<*>`）と 3 行目（`zipWith` 直接）が一致することで、`<*>` の中身が `zipWith` だと分かる。
4 行目は `pure`（= `repeat`）が相手の長さに揃うこと、5 行目はその中身が無限リストであること。
`Show` は base と同じく `deriving`。`newtype` の包みが表示に出るので、
1 行目の素のリストと型が違うことが見て取れる。

`ZipListBase.hs`:

```
[11,21,31,12,22,32,13,23,33]
[11,22,33]
```

`getZipList` で取り出しているので 2 行目は中身だけ。値は `ZipList.hs` と一致。base の定義は `Functor` が `deriving`、`Applicative` に `liftA2` の
定義もあるが、`<*>` の中身（`zipWith`）と `pure`（`repeat`）は同じ。

`ZipListLaws.hs`:

```
[11,22,33]
True
False
True
True
True
```

2 行目が恒等則 `pure id <*> v == v`。3 行目は `pure` を有限リスト（`ZipList [id]`）に
置き換えた場合で、結果が短くなって恒等則が破れる。`pure` が `repeat` でなければならない理由。
4 行目以降は準同型・交換・`fmap` との整合。`pure` 同士の比較は `take` で打ち切っている。

`ZipDiag.hs`:

```
ZipList {getZipList = [(1,10),(2,20)]}
ZipList {getZipList = [(1,10),(2,20)]}
```

1 行目が `<*>`、2 行目が対角線を取る `>>=` から組み立てた `ap`。
`(<*>) == ap` はモナドが守るべき規則で、こちらは満たしている。

リストと同じ `>>=`（`concatMap`）を書いた場合は `ap` が全組み合わせになって
`<*>` と食い違うが、そもそも `<*>` と別物なので当たり前であり、
「整合する `>>=` が存在しない」ことの説明にはならない。そのため対角線版を採用した。

`ZipAssoc.hs`:

```
ZipList {getZipList = [1,2]}
ZipList {getZipList = [100,201]}
ZipList {getZipList = [100]}
True
True
```

2・3 行目が `(m >>= f) >>= g` と `m >>= (\x -> f x >>= g)` で、結合法則が破れている。
`m >>= f` を先に計算すると `f 2 == ZipList [9, 2]` の 0 番目が対角線から外れて落ちるため
`g 9 == ZipList []` に到達せず、長さが変わる。

4・5 行目は左右の単位元則で、こちらは成り立つ。`return`（= `pure`）が `ZipList . repeat` で
無限リストなので、`return x >>= f` は `f x` の長さで打ち切られて `f x` に一致する。

つまり `<*>` と整合させるには位置を揃えるしかなく、そうすると結合法則が守れない。
これが `ZipList` に `Monad` インスタンスがない理由。

## GHCi での確認

`zipWith`・`repeat`・関数として渡す `($)` はシリーズ初出のため、記事で先に紹介している。

```
ghci> zipWith (+) [1, 2, 3] [10, 20, 30]
[11,22,33]
ghci> zipWith (+) [1, 2, 3] [10, 20]
[11,22]
ghci> take 3 (repeat 0)
[0,0,0]
ghci> zipWith ($) [(+ 1), (* 2)] [10, 20]
[11,40]
```

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
