# check/16-free

16 回「木を一般化する」の検証コード。

|ファイル|内容|実行方法|
|---|---|---|
|`Free.hs`|本文の掲載コード。自作 `Free` と `Free Two`（二分木）|`runghc Free.hs`|
|`Rose.hs`|`Free []`（多分岐の木）|`runghc Rose.hs`|
|`Ex1.hs`|【問1】自作 `Tree` と `Free Two` の結果が一致することの確認|`runghc Ex1.hs`|
|`Pkg.hs`|`free` パッケージ版（`foldFree`・`iterM`）|下記 stack|
|`test.hs`|`free` パッケージの最初の動作確認（`Free Two` で木を組む）|下記 stack|

## 実行結果

```text:Free.hs
[1,2]
[2,4]
[1,10,2,20]
```

```text:Rose.hs
[1,2,3]
[1,10,2,20,3,30]
```

```text:Ex1.hs
Node (Node (Leaf 1) (Leaf 10)) (Node (Leaf 2) (Leaf 20))
Node (Node (Leaf 1) (Leaf 10)) (Node (Leaf 2) (Leaf 20))
Node (Leaf 2) (Leaf 4)
Node (Leaf 2) (Leaf 4)
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

## `free` パッケージを使うファイルの実行方法

システムの GHC には `free` が入っていないため、`Pkg.hs` と `test.hs` は他の `check/*/` と
異なり `runghc` では動かない。**stack で実行する。** ソース側には `stack script` ヘッダを
書かず、起動コマンド側で resolver とパッケージを指定する（記事の掲載コードを素の Haskell の
まま保つため）。

```
stack script --resolver lts-22.28 --package free Pkg.hs
stack script --resolver lts-22.28 --package free test.hs
```

- resolver `lts-22.28` は GHC 9.6.6 を使い、システムの GHC と同じバージョンになる。
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

standalone deriving（`StandaloneDeriving`）が要るため、本文では使わず、木の中身は
`toList` で走査して確認する方式にした（16-PLAN.md の決定事項 6：`DeriveFunctor` 以外の
言語拡張は出さない）。

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
