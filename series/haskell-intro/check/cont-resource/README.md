# ContT によるリソース管理の検証

`ContT` が Python の `with` に相当する使い方（`withFile` 等のネスト解消）で
期待どおり動くかを確認したもの。GHC 9.6.6 / mtl 2.3.1 / transformers 0.6.1.0。

実行は `runghc {ファイル名}`。

| ファイル | 内容 |
|---|---|
| `Nested.hs` | `withFile` を素直にネストしたファイルコピー（比較用） |
| `Flat.hs` | 同じものを `ContT` で平坦化 |
| `Order.hs` | 解放の順序と、遅延 IO の罠 |
| `Escape.hs` | `callCC` で途中脱出したときの解放 |

## 確認できたこと

### `with` 系の関数はそのまま `ContT` にできる

`withFile path mode` を部分適用すると `(Handle -> IO r) -> IO r` になり、
これは `ContT r IO Handle` の中身そのもの。`ContT` で包むだけで `do` の 1 行になる。

```hs
hSrc <- ContT $ withFile src ReadMode
```

ネスト版と平坦版で `open`/`close` のログは完全に一致した（`Order.hs`）。
解放は取得の逆順（LIFO）で、ネストと同じ。

```
open  A
open  B
use AB
close B
close A
```

### `evalContT` で締める

答えの型 `r` を確定させるために `evalContT`（`= flip runContT return`）を使う。
`copyFile :: FilePath -> FilePath -> ContT r IO ()` のように `r` を多相に
しておくと、呼び出し側で好きな型に埋められる。

### mtl 2.3 では `liftIO` が再輸出されない

`import Control.Monad.Cont` だけでは `liftIO` が見えず
`Variable not in scope: liftIO` になる。`Control.Monad.IO.Class` を明示的に
import する必要がある。記事に載せるコードでは import 行を省略しないこと。

### 遅延 IO の罠

`hGetContents` の結果を `ContT` の外へ持ち出すと、ハンドルが閉じた後に読むことになる。

```
Left a.txt: hGetContents: illegal operation (delayed read on closed handle)
```

`with` 系全体に共通する話だが、`ContT` は「どこでリソースが閉じるか」が
`do` の見た目から消えるぶん踏みやすい。記事で触れるなら注意として入れる。

### `callCC` で脱出しても解放される

`exit` は捕まえた継続を呼ぶだけなので、`with` 系のコールバックからは通常の
リターンとして抜ける。結果、後片付けはきちんと走る（`Escape.hs`）。

```
open  A
use A
close A
done
```

脱出以降で取得するはずだったリソース（B）はそもそも取得されない。
