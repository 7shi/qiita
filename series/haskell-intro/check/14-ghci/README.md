# 種（kind）の確認（記事「型引数を取る型クラス」の節）

GHC 9.6.6。GHCi での確認が中心。実行は `runghc {ファイル名}`。

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

`Constraint` と `*` の違い（矢印の右側）。型構築子に型を与えると型（`*`）になるが、
型クラスに型を与えても型にはならず制約（`Constraint`）になる。

```
ghci> :k Maybe Int
Maybe Int :: *
ghci> :k Show Int
Show Int :: Constraint
```

## 種が `* -> *` の型クラスの例

記事本文では `Monad` ではなく自作の `Container` を主な例にした（`Monad` の中身は 15 回へ送るため）。

| ファイル | 内容 |
|---|---|
| `Container.hs` | `class Container f` を `Maybe`・`[]` のインスタンスにする |
| `ContainerInt.hs` | `instance Container Int` は種が合わずコンパイルエラー |
| `MonadInt.hs` | 同じエラーが `Monad` でも出る（記事には載せていない）|

```
$ runghc Container.hs
Nothing
Just 1
[]
[1]
```

`Container.hs` を読み込んだ GHCi での `:k`。

```
ghci> :k Container
Container :: (* -> *) -> Constraint
```

`empty :: f a` は引数に型の手掛かりがないため、型注釈がないと ambiguous になる
（`mempty`・`minBound` と同じ形）。`Container.hs` の `main` で型注釈を付けているのはそのため。

## 種が合わない場合

```
ContainerInt.hs:6:20: error: [GHC-83865]
    • Expected kind ‘* -> *’, but ‘Int’ has kind ‘*’
    • In the first argument of ‘Container’, namely ‘Int’
      In the instance declaration for ‘Container Int’
```

```
MonadInt.hs:1:16: error: [GHC-83865]
    • Expected kind ‘* -> *’, but ‘Int’ has kind ‘*’
    • In the first argument of ‘Monad’, namely ‘Int’
```
