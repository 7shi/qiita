# `callCC` は限定継続か（構成案 2・3 の裏取り）

「継続モナドは真のコールスタックをいじらないので、セマンティクスとしては限定継続では？」
という問いの検証。GHC 9.6.6 / transformers 0.6.1.0。実行は `runghc Delimited.hs`。

**結論: 到達範囲としては限定的だが、`shift`/`reset` の限定継続とは別物。**
争点を「(1) どこまで届くか」「(2) 合成できるか」に分けると整理できる。

## 確認できたこと

### 捕まえた継続は first class（ここは「限定的」ではない）

捕まえた継続はただの Haskell の関数値。データ構造に格納でき
（`gen-bidirectional` の `Yield o (i -> Cont ...)` がまさにそれ）、
`evalCont` が返った後でも呼べ、**何度でも呼べる**（`../gen-bidirectional/GenClone.hs`）。

**「真のコールスタックをいじらない」ことは first class 性を損なう理由ではなく、
成り立たせている理由。** Scheme のネイティブ `call/cc` がスタックのコピーで達成する
multi-shot を、CPS では継続がクロージャなのでタダで得ている。

### (1) 到達範囲は `evalCont` まで — ここは限定的

```hs
let r = evalCont $ callCC $ \k -> do
            _ <- k (1 :: Int)
            return 999          -- ここには来ない
print r
putStrLn "after"                -- 脱出はここまで飛べない
```
```
1
after
```

`runCont` / `evalCont` が prompt そのもので、その外の継続は捕まらない。
**答えの型 `r` が区切りの正体**と言える。構成案 2 の「`r` は抽象的で掴みにくい」への
回答の一つになるので、記事で使える言い方。

### (2) `callCC` は abortive、`shift` は composable — ここが決定的な差

| | 捕まえた継続の型 | 性質 |
|---|---|---|
| `callCC` | `k :: a -> Cont r b`（`b` が多相＝戻らない）| abortive（脱出専用）|
| `shift` | `k` は値を返す | composable（合成できる）|

`callCC` は `k` の結果を使おうとしても戻ってこない。

```hs
evalCont $ callCC $ \k -> do
    x <- k 1
    return (x + 100)   -- 到達しない → 結果は 1
```

`shift` は `k` が値を返すので合成できる。古典例
`reset (1 + shift (\k -> k (k 3)))` = `1 + (1 + 3)` = `5` がそのまま書ける。

```hs
evalCont $ reset $ do
    x <- shift $ \k -> return (k (k 3))
    return (1 + x)                        -- 5
```

**同じ継続を 2 回呼んで結果を組み合わせる**こともできる。
`callCC` ではこの形は型からして書けない。

```hs
evalCont $ reset $ do
    x <- shift $ \k -> return (k 10 + k 20)
    return (x * 2)                        -- 60 = 10*2 + 20*2
```

区切りは入れ子にできて、内側の `reset` の外は捕まらない（`nested` で確認、`130`）。

### まとめの言い方

**`callCC` は「区切りの中の undelimited な call/cc」。**
区切られてはいるが、その区切りの中では abortive な完全継続。
`Cont` は限定継続を*表現できる*土台であって、`reset` / `shift` は自作しなくても
`Control.Monad.Trans.Cont` に入っている。

「セマンティクスとしては限定継続」は、到達範囲の話としては正しく、
継続の性質（abortive か composable か）の話としてはミスリード。

## 実行結果

```
1        -- scope: 脱出は evalCont まで
after    -- その外は必ず実行される
1        -- abortive: +100 が効かない
5        -- composable: 1 + (1 + 3)
60       -- 同じ継続を 2 回呼んで足す
[1]      -- 継続は多重呼び出しできる第一級の値
130      -- 入れ子の区切り: (1*10 + 2*10) + 100
```

## 記事構成への示唆

**「残る判断: 限定継続に触れるか」は触れる方に倒れる。**
Scheme の 2 部シリーズ（[call/cc](https://qiita.com/7shi/items/a44c5257f04f0c641ef0) /
[限定継続](https://qiita.com/7shi/items/6db3e19ddc1f8552d9a0)）を読んだ読者は
「Haskell の `callCC` は Scheme の `call/cc` と同じか」を必ず思うので、放置すると宙に浮く。

ただし深入りは不要。以下の 2 点＋リンクで足りる。

1. `evalCont` が区切り（＝答えの型 `r` が区切りの正体）。
2. `callCC` は abortive、`shift` / `reset` は composable で、どちらも標準にある。

置き場所は**構成案 2 の「答えの型 `r` の役割」**が自然。
`r` が何かという問いの答えの一つが「区切り」なので、伏線の張り方としても噛み合う。
