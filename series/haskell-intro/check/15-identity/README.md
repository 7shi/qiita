# Identity の自作（記事「モナドを自作する」の節）

GHC 9.6.6。実行は `runghc {ファイル名}`。

| ファイル | 内容 |
|---|---|
| `MyIdentity.hs` | `Functor`・`Applicative`・`Monad` を定型を使わずに 3 つとも手書き |

## 実行結果

```
6
3
6
```

3 行目が `do` で書いた `calc`。自分で書いたのは 3 つの `instance` だけで、
`do`・`<-`・`return` はそのまま動く。

## 補足

標準の `Identity` は `Data.Functor.Identity` にあるが `Prelude` には入っていないため、
import しなければ名前は衝突しない（この検証コードは import なしで通っている）。
