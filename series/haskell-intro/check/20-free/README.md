# check/20-free

20 回 `# 随伴と自由生成` の検証コード。`runghc` で動く。**外部パッケージは不要。**

|ファイル|本文の位置|内容|
|---|---|---|
|`Free.hs`|`## 普遍性`|`foldMap` と `foldFree` を並べ、どちらも「1 つ与えると一意に決まる」ことを確認|

## 実行結果

```text:Free.hs
["1","2","3"]
6
hello
world
(["hello","world"],())
```

## 確認したこと

- **`foldFree` は `Functor f` を要求しない。**
  `foldFree phi (Free g) = phi g >>= foldFree phi` は `phi` で `m` に移してから
  `>>=` でつなぐだけなので、`f` 側の `fmap` を使わない。
  `Free` を `Monad` のインスタンスにする側では `Functor f` が必要（16 回のとおり）。
- **同じ `prog` を 2 つの解釈で動かせる。** `toIO :: Say ~> IO` では標準出力に出て、
  `toLog :: Say ~> ((,) [String])` ではログのリストになる。
  与えるのは命令 1 つの翻訳だけで、手順書全体の解釈はそこから決まる。
- **`((,) w)` は base で `Monoid w => Monad ((,) w)` になっている。**
  Writer を自作しなくても `foldFree` の解釈先として使える。
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
