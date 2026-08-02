# 値を出すだけのジェネレーターの検証（記事の掲載コード）

記事「ジェネレーター」「何度でも再開できる」の節に載せたコードそのもの。
GHC 9.6.6 / transformers 0.6.1.0。実行は `runghc {ファイル名}`。

| ファイル | 内容 |
|---|---|
| `Gen.hs` | `Gen a` の定義・`runGen`・`yield`・`loop`・`gen`（`yield` を3つ並べただけ）|
| `GenClone.hs` | 同じ `Gen` を 2 回 `loop` に掛け、消費されないことの確認 |

型注釈は付けていない（記事の掲載コードに合わせた）。

双方向版（`Gen i o`・`feed`）は `../13-gen-bidirectional/`、
IO と組み合わせた版は `../13-gen-io/` にあるが、いずれも記事からは外した。

サンプルは `yield 1`・`yield 2`・`yield 3` を並べただけのもの。
[CPS 変換から継続モナドへ](https://qiita.com/7shi/items/27b6f3169961299a6195)の
ジェネレーター（JavaScript・Haskell）と同じ内容。

## 実行結果

`Gen.hs`:

```
1
2
3
```

`GenClone.hs`:

```
1
2
3
1
2
3
```

`loop` で最後まで進めても `g` は変化しないため、2 回目も同じ結果になる。
