# check/20-free

20 回 `# 随伴と自由生成` の検証コード。**free パッケージを使うので `runghc` では動かない。**

```
stack script --resolver lts-24.53 --package free Free.hs
```

|ファイル|本文の位置|内容|
|---|---|---|
|`Free.hs`|`### foldFree の動作確認`|`foldMap` と `foldFree` を並べ、どちらも「1 つ与えると一意に決まる」ことを確認|

## 実行結果

```text:Free.hs
hello
world
(["hello","world"],())
(["hello"],())
```

## 確認したこと

- **`Free`・`foldFree`・`liftF` は free パッケージ（`Control.Monad.Free`）のものを使う。**
  自前定義でも同じ出力になることは確認済みだが、16 回で紹介したパッケージがあるので
  本文もこちらに合わせた。`~>` はパッケージにないので自分で定義する。
- **`foldFree` は `Functor f` を要求しない。**
  `foldFree phi (Free g) = phi g >>= foldFree phi` は `phi` で `m` に移してから
  `>>=` でつなぐだけなので、`f` 側の `fmap` を使わない。
  `Free` を `Monad` のインスタンスにする側と `liftF` では `Functor f` が必要（16 回のとおり）。
- **同じ `prog` を 2 つのインタープリターで動かせる。** `toIO :: Say ~> IO` では標準出力に出て、
  `toLog :: Say ~> ((,) [String])` ではログのリストになる。
  与えるのは命令 1 つ分のインタープリターだけで、手順書全体のインタープリターはそこから決まる。
- **`((,) w)` は base で `Monoid w => Monad ((,) w)` になっている。**
  Writer を自作しなくても `foldFree` の行先として使える。
- **往復も確かめた。** `foldFree toLog . liftF` は元の `toLog` に戻る。
  行って戻ると元に戻るので 1 対 1 の対応。
  `foldFree phi . liftF == phi` が成り立つのは `phi` が自然変換で
  `phi (fmap Pure x) == fmap Pure (phi x)` となり、`>>= return` が消えるため。
  リスト側の往復（`foldMap g . (: [])` が元の `g` に戻る）は
  本文の `## 普遍性` の GHCi で示した。
  **逆向きだけを単独で見せようとすると、`foldFree`（`foldMap`）由来でない
  インタープリター（準同型）を別に用意する必要があり、かえって複雑になる。**
  往復で示して「行って戻ると元に戻る」と説明する方が読みやすい。
- **`foldMap` と型が並ぶ。**

  ```hs
  foldMap  :: Monoid m => (a -> m)  -> [a]      -> m
  foldFree :: Monad  m => (f ~> m)  -> Free f a -> m a
  ```

## 言語拡張の確認

|拡張|要否|
|---|---|
|`RankNTypes`|**必要**（`type f ~> g = forall a. f a -> g a`）|
|`TypeOperators`|**必要**（`~>`）|

**どちらも GHC2021 に含まれるのでプラグマは不要。**
