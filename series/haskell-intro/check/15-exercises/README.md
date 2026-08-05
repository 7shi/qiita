# 練習問題の解答例（記事の練習4問）

GHC 9.6.6。実行は `runghc {ファイル名}`。

| ファイル | 対応 | 内容 |
|---|---|---|
| `Q1Pair.hs` | 【問1】 | `Pair` に `instance Functor` |
| `Q2Pair.hs` | 【問2】 | 問1 の `Pair` に `instance Applicative` |
| `Q3State.hs` | 【問3】 | State モナドの自作。3 つとも手書き（定型は使わない）|
| `Q4Rose.hs` | 【問4】 | 多分岐の木 `Rose` を `Monad` に。定型 + `map` による `>>=` |

## 実行結果

`Q1Pair.hs`:

```
Pair 2 4
Pair "1" "2"
```

`Q2Pair.hs`:

```
Pair 11 22
Pair 0 0
```

`Q3State.hs`:

```
55
```

09回の練習で手書きした `bind`・`return'`・`get'`・`put'` を `>>=`・`pure` として
登録し直したもの。`fib` が `do` と `<-` で書けるようになる。

`instance` の宣言は `State s`（型変数を 1 つ残した形）でなければ種が合わない。

`do` の中の `(a, b) <- get'` はタプルの単一コンストラクタパターンなので、
GHC は失敗し得ないと判断し `MonadFail` を要求しない。

`Q4Rose.hs`:

```
Node [Leaf 2,Node [Leaf 4,Leaf 6]]
Node [Node [Leaf 1,Leaf 10],Node [Node [Leaf 2,Leaf 20],Node [Leaf 3,Leaf 30]]]
```

`Tree` の `Node l r` を左右個別に再帰していたところが `map (>>= f) ts` になる。
