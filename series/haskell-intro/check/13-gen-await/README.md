# 消費側コルーチン `await` の検証（構成案 6 (c)）

## ⚠ 結論: 動いたが、記事からは落とした

**否定的結果の記録として残してある。** 3 本とも動くが、記事に載せる価値がないと判断した。

1. **`await` は (a) 双方向ジェネレーターの部分集合。** 消費側 `Sink i r` は
   `Gen i o` の出力を潰した `o = ()` の場合でしかなく、新しい概念がない。
2. **パーサーは 12 回（構文解析 超入門）の劣化版。** `Sink i r` を `feed` で駆動するのは
   `StateT [i] Maybe r` と同型で、12 回の `StateT` + `Either` そのもの。
   しかも先読みを自前で持ち回る必要があり、`try` によるバックトラックも書けない。
3. **pipes の原型だけが (a)(b) に無い話だが、そこが一番重い**（`RankNTypes` + `escape`）。
   記事の本線（bind は継続の抽象化）から最も遠い場所に一番コストがかかる。

以下は当時の検証内容。上の判断の根拠として残す。

---

`yield` の双対として `await`（値を待って中断する）が書けるか、
生産側と消費側を繋げられるか。GHC 9.6.6 / transformers 0.6.1.0。実行は `runghc {ファイル名}`。

| ファイル | 内容 |
|---|---|
| `Await.hs` | `await` の最小実装。`Sink i r` 型と `feed` |
| `Parser.hs` | `await` でトークンを 1 つずつ受け取る四則演算パーサー |
| `Pipe.hs` | `yield` と `await` を 1 つの型に統合。字句解析 → 構文解析の 2 段接続 |

## 確認できたこと

### `await` は `yield` から出す値を取り除いただけ

```hs
data Gen  i o = Done  | Yield o (i -> Cont (Gen i o)  (Gen i o))   -- 6 (a)
data Sink i r = Ret r | Await   (i -> Cont (Sink i r) (Sink i r))  -- 6 (c)
```

```hs
yield ccOut v = callCC $ \next -> ccOut (Yield v next)
await ccOut   = callCC $ \next -> ccOut (Await   next)
```

**差分は「出す値 `v` があるかどうか」だけ。** 再開用の継続が `i -> ...` なのは同じ。
6 (a) で `(next ())` → `next` を見せた直後なら、ここは数行で済む。

型の循環も再発しない（`data` で包んでいるので当然）。`Await.hs` は `RankNTypes` 不要。

### 終わり方が生産側と逆になる

生産側の `Gen` は `Done`（もう出さない）で終わるが、消費側の `Sink` は
`Ret r`（結果を返して終わる）で終わる。本体の型も `GenM i o x` → `SinkM i r r` と、
最後の値が意味を持つ形に変わる。`runSink` で `Ret <$> body cc` と包むところがそれ。

呼び出し側も `feed :: Sink i r -> [i] -> Maybe r` になり、
**入力が尽きたまま `Await` なら `Nothing`** という失敗が新しく出てくる。
生産側の `feed :: Gen i o -> [i] -> [o]` は「短くなる」だけで失敗しなかった。

```
Just 6    -- sum3 [1,2,3,4]      余った入力は無視
Nothing   -- sum3 [1,2]          足りない
Just 6    -- sumUntil0 [1,2,3,0,9]
Nothing   -- sumUntil0 [1,2,3]   0 が来ない
```

### パーサー（`Parser.hs`）— 12 回と接続できる

`expr := term ('+' term)*` / `term := num ('*' num)*` を `await` だけで書ける。

```
Just 7     -- 1+2*3
Just 26    -- 2*3+4*5
Just 10    -- 10
Just 6     -- 1 + 2 + 3
Nothing    -- [TNum 1, TPlus] で入力が尽きる
```

**引っかかったのは先読み。** `await` は消費してしまうので戻せない。
ここでは各関数が「読んでしまった 1 つ先のトークン」を返り値に添えて返す
（`term :: ... -> SinkM Token r (Int, Token)`）ことで回避した。

12 回の Parsec 版は入力全体を持っているので好きなだけ先読みできる。
**「入力を待つ」形にすると先読みが自前の持ち回りになる**のがコルーチン版の性質で、
これは pipes / conduit で `leftover` の仕組みがある理由そのもの。記事で一言触れる価値がある。

なお 12 回は文字単位のパーサーなので、そこから繋ぐなら
「文字を `await` する」形にもできる。ここではトークン単位にして、
字句解析との接続（下記）に見せ場を寄せた。

### 統合すると pipes / conduit の原型になる（`Pipe.hs`）

`yield` と `await` の両方を持つ型にすると、字句解析器（文字を待ってトークンを出す）が書ける。

```hs
data Pipe i o r
    = PDone r
    | PYield o (() -> Cont (Pipe i o r) (Pipe i o r))
    | PAwait   (i -> Cont (Pipe i o r) (Pipe i o r))
```

下流駆動で繋ぐ `connect` が書けた。**下流が `await` したら上流を `yield` まで進める**、
という 10 行程度のもの。

```
Just 7     -- 1+2*3
Just 26    -- 2*3+4*5
Just 6     -- 1 + 2 + 3
Just 7     -- 7
Nothing    -- "1+2" は終端が来ないまま入力が尽きる
```

`parser :: Pipe Token o Int` が **`o` について多相のまま**（`yield` しないので）
書けるのが気持ちよく、`Sink` が `Pipe` の特殊形だと型で見える。

### ⚠ 統合した瞬間に `RankNTypes` が必要になる

**これが (c) で一番の収穫。** 6 (a) では「`RankNTypes` は不要」と書いたが、
`yield`（`()` を返す）と `await`（`i` を返す）を同じ本体で使うと、
脱出継続の答えの型を 1 つに固定できなくなる。

```hs
type Out i o r = forall a. Pipe i o r -> PipeM i o r a
```

さらに `callCC` がくれる脱出継続は単相なので、そのままでは `Out` に渡せない
（`type variable 'a' would escape its scope`）。**呼んだら戻ってこない**ことを使って
答えを捨てる形で付け直す必要がある。

```hs
escape :: (Pipe i o r -> Cont (Pipe i o r) (Pipe i o r)) -> Out i o r
escape cc p = cont (\_ -> evalCont (cc p))
```

「継続は呼んだら戻らない」という 3 回（`callCC`）の話が、
型を通すための道具として実際に効く場面になっている。
ただし記事の分量としては重い。**(c) を短く済ませるなら `Await.hs` + `Parser.hs` までにして、
`Pipe.hs` は「繋げると pipes になる」と述べてコードは畳むか別記事に回す**のがよい。

## 記事構成への結論

当初は「1. `await` だけ / 2. + パーサー / 3. + pipes への統合」の 3 段階で切ることを
考えたが、**1 は (a) に含まれ、2 は 12 回に含まれ、3 は重すぎる**ため全部落とした。

記事に残すとすれば**「消費側は出力を `()` に潰したものなので (a) に含まれる」の一文**だけ。
5 で `toList` が書けた理由（入力が `()` に潰れていた）とちょうど対になるので、
(a) の締めに 1 行入れる余地はある。

## 関連

- 生産側（双方向）: `../13-gen-bidirectional/`
- IO との交互実行: `../13-gen-io/`
- リソース管理: `../13-cont-resource/`
