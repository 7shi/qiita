# check/16-free

`free` パッケージ（[Control.Monad.Free](https://hackage.haskell.org/package/free)）の動作確認。
16 回本文の「木の一般化」（`Free Two` が 15 回の `Tree` と同じ形であること）の裏取り。

システムの GHC には `free` が入っていないため、他の `check/*/` と異なり `runghc` では動かない。
**stack で実行する。** `test.hs` 自体には `stack script` ヘッダを書かず、起動コマンド側で
resolver とパッケージを指定する（記事の掲載コードを素の Haskell のまま保つため）。

```
stack script --resolver lts-22.28 --package free test.hs
```

## 実行結果

```
[1,2,3]
```

`Free Two` で `Pure`（葉）と `Free (Two l r)`（枝）から木を組み立て、`toL` で
深さ優先に走査した結果。15 回の `Tree`（`Leaf`/`Node`）と同じ形であることを確認できた。

## 補足

- resolver `lts-22.28` は GHC 9.6.6 を使うため、システムの GHC（`ghc --version` で確認済み）
  と一致する。`--system-ghc` を付けると自環境の GHC を再利用でき、初回セットアップが速くなる
  （`stack setup --system-ghc --resolver lts-22.28` で確認済み）。
- `stack runghc --package free -- test.hs` は本環境では `Setup.hs` のビルドに失敗した
  （`Cabal`/`base` のパッケージDBが絡む問題。原因未調査）。`stack script` の方を使うこと。
