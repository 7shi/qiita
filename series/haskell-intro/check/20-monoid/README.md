# check/20-monoid

20 回 `# モナドはモノイド対象` の検証コード。`runghc` で動く。**外部パッケージは不要。**

|ファイル|本文の位置|内容|
|---|---|---|
|`Join.hs`|`## join`|`>>=` と `join` が相互に定義できること|
|`Laws.hs`|`## モノイド則`|`Monoid` の則と、`join`・`return` で書いたモナド則|

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

## 言語拡張の確認

2 ファイルとも `runghc -XHaskell2010` で通る。**言語拡張は不要。**
