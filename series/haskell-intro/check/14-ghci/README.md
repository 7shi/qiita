# 種（kind）の確認（記事「型引数を取る型クラス」の節）

GHC 9.6.6。GHCi での確認が中心。

GHC 9.6 の `:k` は `Type` ではなく `*` で表示する（記事もこれに合わせた）。

```
ghci> :k Int
Int :: *
ghci> :k Bool
Bool :: *
ghci> :k Maybe
Maybe :: * -> *
ghci> :k []
[] :: * -> *
ghci> :k IO
IO :: * -> *
ghci> :k Either
Either :: * -> * -> *
ghci> :k Show
Show :: * -> Constraint
ghci> :k Monad
Monad :: (* -> *) -> Constraint
```

## 種が合わない場合

| ファイル | 内容 |
|---|---|
| `MonadInt.hs` | `instance Monad Int` は種が合わずコンパイルエラー |

```
MonadInt.hs:1:16: error: [GHC-83865]
    • Expected kind ‘* -> *’, but ‘Int’ has kind ‘*’
    • In the first argument of ‘Monad’, namely ‘Int’
```
