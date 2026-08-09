# check/16-free

16 回「木を一般化する」の検証コード。

|ファイル|内容|実行方法|
|---|---|---|
|`Free.hs`|本文の掲載コード（「インスタンス」節と「動かす」節を連結）。自作 `Free` と `Free Two`（二分木）|`runghc Free.hs`|
|`Rose.hs`|`Free []`（多分岐の木）|`runghc Rose.hs`|
|`Ex1.hs`|【問1】自作 `Tree` と `Free Two` の結果が一致することの確認|`runghc Ex1.hs`|
|`TupleTwo.hs`|`Two` をタプルの型シノニムで代用できないことの確認（**コンパイルエラーになるのが期待結果**）|`runghc TupleTwo.hs`|
|`Pkg.hs`|`free` パッケージ版（`foldFree`・`iterM`）|下記 stack|
|`test.hs`|`free` パッケージの最初の動作確認（`Free Two` で木を組む）|下記 stack|

## 実行結果

```text:Free.hs
(1 2)
(2 4)
((1 10) (2 20))
```

```text:Rose.hs
[1 [2 3]]
[[1 10] [[2 20] [3 30]]]
```

```text:Ex1.hs
((1 10) (2 20))
((1 10) (2 20))
(2 4)
(2 4)
```

`Ex1.hs` の 1・2 行目、3・4 行目がそれぞれ一致している。`Free Two` が自作 `Tree` と
同じものであることの裏取り。

```text:Pkg.hs
[1,2,3]
[0,1,2,3,4]
1
2
3
1
2
3
```

```text:test.hs
[1,2,3]
```

## GHCi で確認した種

```text:GHCi（Free.hs をロード）
ghci> :k Two
Two :: * -> *
ghci> :k Free
Free :: (* -> *) -> * -> *
ghci> :k Free Two
Free Two :: * -> *
ghci> :k Free Two Int
Free Two Int :: *
```

## `Two` をタプルで代用できないこと

本文「種」節の `:::message`（`Two` はタプルで済ませられそうにも見えますが〜）の裏取り。
`TupleTwo.hs` の結果。

```text:エラー内容
    • The type synonym ‘Two’ should have 1 argument, but has been given none
    • In the type synonym declaration for ‘Tree’
```

`Free Two a` は `Two` を未適用のまま渡すが、型シノニムは常に適用しきる必要があるため通らない。

タプルの型構築子 `(,)` を直接使う場合は種が合わない。

```text:GHCi
ghci> :k (,)
(,) :: * -> * -> *
ghci> :k (,) Int
(,) Int :: * -> *
ghci> fmap (+1) (1,2)
(1,3)
```

`* -> *` にするには片方を固定するしかなく、その `Functor` は右側だけに作用する
（`fmap (+1) (1,2)` が `(1,3)` になる）。枝の中のすべての木に `fmap` が届かないので、
木の枝としては使えない。

## `free` パッケージを使うファイルの実行方法

システムの GHC には `free` が入っていないため、`Pkg.hs` と `test.hs` は他の `check/*/` と
異なり `runghc` では動かない。**stack で実行する。** ソース側には `stack script` ヘッダを
書かず、起動コマンド側で resolver とパッケージを指定する（記事の掲載コードを素の Haskell の
まま保つため）。

```
stack script --resolver lts-24.53 --package free Pkg.hs
stack script --resolver lts-24.53 --package free test.hs
```

- resolver `lts-24.53`（GHC 9.10.3、`free-5.2`）は執筆時点の現行 LTS。
  **当初は `lts-22.28`（GHC 9.6.6、システムの GHC と同じバージョン）を使っていたが、
  執筆環境の都合を読者に押し付ける理由が無いので 2026-08-09 に現行 LTS へ更新した**
  （18-PLAN「過去記事の resolver 更新」）。`free` はどちらの resolver でも 5.2 で、
  出力は `diff` で完全一致することを確認済み。
- この環境の stack は GHC 9.6 以降に対して
  「Stack has not been tested with GHC versions above 9.4」の警告を出す。
  **動作には影響しない。**
- **`--system-ghc` は付けてはいけない。** 付けると `Setup.hs` のビルドで
  「There are files missing in the `base-4.18.2.1` package」というエラーになる。
  この環境の GHC は動的リンク前提（`ghc` で自前ビルドするときも `-dynamic` が要る）で、
  stack が `Setup.hs` を静的にビルドしようとして失敗するため。
  `--system-ghc` なしなら stack が自前の GHC を使うので通る。
- `stack runghc --package free -- ファイル名.hs` も同じ理由で失敗する。

## `deriving Show` が使えないこと

`data Free f a = Pure a | Free (f (Free f a)) deriving Show` はコンパイルできない。

```text:エラー内容
    • Could not deduce ‘Show (f (Free f a))’
        arising from the first field of ‘Free’ (type ‘f (Free f a)’)
      from the context: Show a
        bound by the deriving clause for ‘Show (Free f a)’
      Possible fix:
        use a standalone 'deriving instance' declaration,
          so you can specify the instance context yourself
```

standalone deriving（`StandaloneDeriving`）が要るため、本文では使わない。ただし
`f` を固定すれば条件が決まるので、`instance Show a => Show (Tree a)`（`type Tree = Free Two`）
のように手で書ける。葉を値、枝を括弧（`Free []` では角括弧）で表示するので、
葉を並べるだけの `toList` と違い、木の形がそのまま見える。

## 言語拡張の基準（GHC2021）

本文・検証コードとも **GHC2021 を基準にして pragma を書かない**。GHC 9.2 以降の既定。
Haskell2010 で必要になる拡張は、本文の該当箇所に `:::message` で補足してある。

`runghc -XHaskell2010` で全ファイルを確認した結果（`free` パッケージを使う
`Pkg.hs`・`test.hs` は `stack script` で別途確認）。

|拡張|要求するファイル|該当する本文の箇所|
|---|---|---|
|`FlexibleInstances`|`Free.hs`・`Rose.hs`・`Ex1.hs`|「動かす」節の `instance Show`。`Free Two a` は `Two` が型変数でないため。`TypeSynonymInstances`（`type Tree = Free Two` を `instance` の頭に書く分）も含意される|
|`DeriveFunctor`|`Gen.hs`・`GenIO.hs`・`Teletype.hs`・`Pkg.hs`|「Functor インスタンス」節の `deriving Functor`|

他のファイル（`Slow.hs`・`Manual.hs`・`TupleTwo.hs`）は Haskell2010 でも通る。

## `free` パッケージとの差分

[Control.Monad.Free](https://hackage.haskell.org/package/free-5.2/docs/src/Control.Monad.Free.html)
のソースと突き合わせた結果。

|項目|本文の自作版|`free` パッケージ|
|---|---|---|
|`data Free`|`Pure a \| Free (f (Free f a))`|同じ（`deriving (Generic, Generic1)` が付く）|
|`>>=`|`Free g >>= k = Free (fmap (>>= k) g)`|同じ（`Free m >>= f = Free ((>>= f) <$> m)`）|
|`pure`|`Pure`|同じ|
|`fmap`|`liftM`|直接定義（`go` による再帰）。結果は同じ|
|`<*>`|`ap`|直接定義（`Pure`/`Free` の 3 パターン）。結果は同じ|
|`liftF`|`Free (fmap Pure c)`|`Control.Monad.Free.Class` の `wrap . fmap return`。同じ形|

コンストラクタ名まで同じなので、自作版のインタプリタ（`toList` など）は
`import Control.Monad.Free` に差し替えるだけでそのまま動く（`Pkg.hs` で確認済み）。
