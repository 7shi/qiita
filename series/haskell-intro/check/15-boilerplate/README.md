# 階層と定型の検証（記事「3 段まとめて書く定型」の節）

GHC 9.6.6。実行は `runghc {ファイル名}`。

| ファイル | 内容 |
|---|---|
| `MonadOnly.hs` | `instance Monad` だけを書いたときのエラー（スーパークラス不足） |
| `Boilerplate.hs` | `fmap = liftM` / `(<*>) = ap` の定型で階層を埋める |
| `ReturnOnly.hs` | `pure` を書かず `return` を実装した場合の警告 |

## 実行結果

`MonadOnly.hs`（コンパイルエラー）:

```
MonadOnly.hs:4:10: error: [GHC-39999]
    • No instance for ‘Applicative Identity’
        arising from the superclasses of an instance declaration
    • In the instance declaration for ‘Monad Identity’
```

14回の `Monoid`/`Semigroup` と同じ `arising from the superclasses`。

`Boilerplate.hs`:

```
Node (Leaf 2) (Leaf 4)
Node (Leaf 1) (Leaf 2)
```

`fmap` を `liftM` に任せても葉の値がきちんと 2 倍になる。

`ReturnOnly.hs`（警告あり・実行はできる）:

```
ReturnOnly.hs:9:10: warning: [GHC-06201] [-Wmissing-methods]
    • No explicit implementation for
        ‘pure’
    • In the instance declaration for ‘Applicative Foo’

ReturnOnly.hs:13:5: warning: [-Wnoncanonical-monad-instances]
    Noncanonical ‘return’ definition detected
    in the instance declaration for ‘Monad Foo’.
    ‘return’ will eventually be removed in favour of ‘pure’
    Either remove definition for ‘return’ (recommended) or define as ‘return = pure’
    See also: https://gitlab.haskell.org/ghc/ghc/-/wikis/proposal/monad-of-no-return

Foo 2
```

`-Wnoncanonical-monad-instances` はデフォルトで有効（`-Wall` 不要）。
「実装するのは `pure` の方」という記事の主張の直接の根拠になる。
