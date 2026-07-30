# 双方向ジェネレーターの検証（構成案 6 (a)）

再開時に値を渡せるジェネレーター（JS の `it.next(x)` に相当）が Haskell で書けるか。
GHC 9.6.6 / transformers 0.6.1.0。実行は `runghc {ファイル名}`。

生産専用版は zenn リポジトリの `check/20260730-haskell-generator/`（`GenStd.hs`・`GenMin.hs`）。
命名はそちらに合わせた。

| ファイル | 内容 |
|---|---|
| `GenBi.hs` | 標準の `Control.Monad.Trans.Cont` を使い、コルーチンだけ自前実装 |
| `GenBiMin.hs` | 継続モナドも含めて全部自前の最小実装 |
| `GenClone.hs` | 同じ中断点から何度でも再開できることの確認 |

`GenBiMin.hs` の先頭 26 行（`Cont` の定義・インスタンス・`evalCont`・`callCC`）以外は
`GenBi.hs` と**完全に同一**（`diff` で確認済み）。生産専用版と同じ構成なので、
記事で `Cont` を自作した流れからそのまま標準ライブラリへ接続できる。

## 確認できたこと

### 型の循環は再発しない

PLAN.md の型スケッチがそのまま通った。

```hs
data Gen i o
    = Done
    | Yield o (i -> Cont (Gen i o) (Gen i o))
```

再開用の継続が `i -> ...` の関数になっただけで、`data` で包んでいるので
occurs check には引っかからない。`RankNTypes` も不要。

### 生産専用版からの差分が驚くほど小さい

```hs
-- 生産専用
data Gen a   = Done | Yield a (Cont (Gen a) (Gen a))
type Out a   = Gen a -> GenM a ()
yield ccOut v = callCC $ \next -> ccOut (Yield v (next ()))

-- 双方向
data Gen i o = Done | Yield o (i -> Cont (Gen i o) (Gen i o))
type Out i o = Gen i o -> GenM i o i
yield ccOut v = callCC $ \next -> ccOut (Yield v next)
```

**`(next ())` が `next` になっただけ。** 生産専用版は捕まえた継続に `()` を渡して
潰していたのを、渡さずそのまま格納するだけで双方向になる。

「捕まえた継続は関数だから引数を渡せる」という構成案 3 の `callCC` の話が、
コードの差分そのものとして出る。**記事ではここを見せ場にできる。**

`yield` の型が `GenM i o ()` から `GenM i o i` に変わるので、
脱出継続 `Out` の答えの型も `()` から `i` に変わる。これも `callCC` の型
（`((a -> m b) -> m a) -> m a` の `a` が `yield` の戻り値）から追える。

### `toList` が書けなくなり、`feed` になる

生産専用版の `toList :: Gen a -> [a]` は、入力が必要になった時点で書けない。
代わりに入力列を与える `feed` になる。

```hs
feed :: Gen i o -> [i] -> [o]
feed (Yield v next) (i:is) = v : feed (evalCont (next i)) is
feed _ _ = []
```

生産専用版で `toList` が書けたのは入力が `()` に潰れていたから、と振り返れる。

#### ⚠ 訂正: これは「リストを超えた証拠」ではない

**当初この README は `feed` を「リストを超えた」ことの証拠としていたが、成立しない。**
`feed` の型は `[i] -> [o]`、すなわち**リストからリストへの関数**である。
実際、下の実行結果はどれも既存のリスト関数で書ける。

| 例 | `feed` の結果 | リストでの等価物 |
|---|---|---|
| `feed accum [1,2,3,4]` | `[0,1,3,6]` | `init (scanl (+) 0 [1,2,3,4])` |
| `feed lengths [...]` | `[0,2,5]` | `mapAccumL` 相当 |
| `feed untilZero [1,2,0,5]` | `[0,1,3]` | `scanl` + 打ち切り |

`accum` は `scanl` そのもの。`Gen i o` を `[o]` に変換できないのは**型の話**であって、
表現力の話ではない。`feed` が書けるということは、むしろ
**入力を先に全部与えるなら双方向コルーチンはリスト関数に潰せる**ことを示している。

**`feed` の正しい役割は「潰せることを見せる」方。** そして潰した姿
`[i] -> [o]` は Haskell 1.0 の `type Behaviour = [Response] -> [Request]` に一致する。
`feed` が `Behaviour` と型が同じなのは偶然ではない。

**本当の境界は 6 (b)**（出力を見てから次の入力を IO で決める）。ただしそれも
「リストでは書けない」のではなく、**遅延リストの knot-tying でなら書ける**。
それが Haskell 1.0 のやり方で、`~`（遅延パターン）が必要で壊れやすく、結局捨てられた。
→ 記事の線引きは「リストでは書けない」ではなく
**「リストでも書けるが遅延に頼った knot-tying が要り、Haskell はそれを試して捨てた」**。

### 実行結果

```
[0,1,3,6]   -- accum: 累算器に 1,2,3,4 を渡す
[0,2,5]     -- lengths: 出力 Int・入力 String（型が違ってよい）
[0,1,3]     -- untilZero: 0 を渡すと終了、残りの入力は無視
[]          -- 入力なし
```

`accum` は `yield` した値を足し込んで途中結果を返す。題材としてはこれで足りる。
`lengths` は `i` と `o` が別の型でよいことの確認用。

### 注意: 最初の `yield` は入力を消費する前に起きる

`feed` は `yield` 1 回と入力 1 個を対にするので、入力を n 個渡すと出力も n 個までで、
**最後の入力を反映した `yield` は観測されない**。`accum` に `[1,2,3,4]` を渡して
`[0,1,3,6]` になるのがそれで、`6+4=10` は出力されない。

ジェネレーターは「まず出して、それから受け取る」ので入出力の個数がずれる。
記事で実行結果を見せるとき、ここは一言説明しないと読者が数え違える。

### 同じ中断点から何度でも再開できる（`GenClone.hs`）

`Gen i o` は純粋な値で、中の継続も値なので、**同じ中断点から違う入力で何度でも再開できる**。

```hs
let g = step accum 10
peek g              -- Just 10
peek (step g 1)     -- Just 11
peek (step g 100)   -- Just 110
peek (step g 1000)  -- Just 1010
```

`g` は消費されない。分岐した先をさらに分岐させれば木になる。

```
[Just 11,Just 12,Just 101,Just 102]
```

**これは JavaScript や Python のジェネレーターにはできない。**
`articles/javascript/cloneable-iterator.md` が
「JavaScript のジェネレーターでは実行途中のイテレーターをクローンできません」として
最初からやり直す回避策を書いているのがその裏返し。

記事にとっての意味は大きい。「実用には既存のジェネレーターを使えばよい」という
当然の疑問に対して、**自前で組んだ方が能力が上**だと答えられる。
`callCC` の「継続は何度でも呼べる」という性質が、そのまま機能として出ている。

同じ話が Promise にもある。`articles/javascript/wrap-async-api-with-promise.md` は
`resolve` が継続に近いとしつつ、相違点として「継続は何度でも呼べるが `resolve` を
複数回呼んでも 2 回目以降は何も起きない」を挙げている。
**Promise も JS のジェネレーターも、継続の一部の性質しか持っていない。**

## 残り

構成案 6 の (b) は `../gen-io/`。(c) `await` は `../gen-await/` で検証したが、
**この記事（(a)）の部分集合でしかないため落とした**（消費側は出力を `()` に潰したもの）。
なお `ContT` によるリソース管理（構成案 7）は `../cont-resource/` で確認済み。
