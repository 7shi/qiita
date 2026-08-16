# check/20-monoid

20 回 `# モナドはモノイド対象` の検証コード。`runghc` で動く。**外部パッケージは不要。**

|ファイル|本文の位置|内容|
|---|---|---|
|`Join.hs`|`## join`|`>>=` と `join` が相互に定義できること|
|`Laws.hs`|`## モノイド則`|`Monoid` の則と、`join`・`return` で書いたモナド則|
|`Whisker.hs`|`## ηT と μT`|`@` で型引数を明示した $\eta T$・$T\eta$・$\mu T$・$T\mu$|

## 実行結果

```text:Join.hs
[1,10,2,20,3,30]
[1,10,2,20,3,30]
[1,2,3]
[1,2,3]
Just 6
Just 3
```

```text:Laws.hs
True
True
[1,2,3,4]
[1,2,3,4]
True
True
True
Just 'a'
Just 'a'
```

```text:Whisker.hs
[[1],[2],[3]]
[[1,2,3]]
[[1,2],[3]]
[[1],[2],[3]]
True
True
True
```

## 確認したこと

- **`>>=` と `join` は相互に定義できる。** `bind m k = join (fmap k m)` が
  `>>=` と同じ結果を返し、`join' mm = mm >>= id` が `join` と同じ結果を返す。
  どちらを基本に取っても同じモナドになる。
- **`join . join == join . fmap join` が成り立つ。**
  `[[[1,2],[3]],[[4]]]` に対して両辺とも `[1,2,3,4]`。
  外側から潰しても内側から潰しても同じところに着く。
- **`join . return == id`・`join . fmap return == id` が成り立つ。**
  `Monoid` の `mempty <> x == x`・`x <> mempty == x` と同じ形。
- `Maybe` でも同じ等式が成り立つことを確認した。
- **`@m`・`@a` のように型変数へ型適用できる。** `forall m a.` で型変数をスコープに入れれば、
  `return @m @(m a)`（$\eta T$）と `fmap @m (return @m @a)`（$T\eta$）が書き分けられる。
  型はどちらも `m a -> m (m a)` で同じだが、`[1,2,3]` に適用すると
  `[[1,2,3]]` と `[[1],[2],[3]]` で結果が違う。作用する側の違いがそのまま出る。
- **$\mu$ の側も同様。** `join @m @(m a)`（$\mu T$）と `fmap @m (join @m @a)`（$T\mu$）は
  型が `m (m (m a)) -> m (m a)` で一致し、`join` を後ろに付けると結合律で一致する。

## 言語拡張の確認

`Join.hs`・`Laws.hs` は `runghc -XHaskell2010` で通る。**言語拡張は不要。**

`Whisker.hs` は `ScopedTypeVariables`（`forall` の型変数を本体で使う）と
`TypeApplications`（`@`）が必要。**どちらも GHC2021 に含まれるのでプラグマは書かない。**
`ExplicitForAll` は `ScopedTypeVariables` に含まれるため単独では不要だった。

|拡張|`Whisker.hs`|
|---|---|
|`ScopedTypeVariables`|必要|
|`TypeApplications`|必要|
|`ExplicitForAll`|不要（`ScopedTypeVariables` に含まれる）|
