# `callCC` は限定継続か（構成案 2・3 の裏取り）

「継続モナドは真のコールスタックをいじらないので、セマンティクスとしては限定継続では？」
という問いの検証。GHC 9.6.6 / transformers 0.6.1.0。実行は `runghc Delimited.hs`。

**結論: 到達範囲としては限定的だが、`shift`/`reset` の限定継続とは別物。**
争点を「(1) どこまで届くか」「(2) 合成できるか」に分けると整理できる。

| ファイル | 内容 |
|---|---|
| `Delimited.hs` | 到達範囲・abortive / composable の確認 |
| `Shift.hs` | `shift`/`reset` で双方向ジェネレーターを書き、`callCC` 版と比較 |

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
| `callCC` | `k :: a -> Cont r b`（`b` は本体内で 1 つに決まる）| abortive（脱出専用）|
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

```hs
evalCont $ reset $ do
    x <- shift $ \k -> return (k 10 + k 20)
    return (x * 2)                        -- 60 = 10*2 + 20*2
```

**`callCC` でも同じ形は書ける（型検査は通る）。** `callCC` は rank-2 ではなく
`((a -> Cont r b) -> Cont r a) -> Cont r a` なので、`b` は本体の中で 1 つの型に
単一化される。裏取りとして、`ret` を 2 つの型で使うと逆に型エラーになる
（`Delimited.hs` の (2e)。真の `forall b.` なら通るはずの形）。

```hs
evalCont $ callCC $ \k -> do
    x1 <- k 10
    x2 <- k 20                            -- 到達しない
    return ((x1 + x2) * 2)                -- 10（最初の k 10 で脱出）
```

**abortive なのは型ではなく実装。** `\x -> cont $ \_ -> c x` が後続を捨てるという
実行時の振る舞いによる。「型からして書けない」は誤り。

区切りは入れ子にできて、内側の `reset` の外は捕まらない（`nested` で確認、`130`）。

### `shift` 版のジェネレーターは `callCC` 版より簡単に書ける（`Shift.hs`）

Scheme の[限定継続でジェネレーターを実装する](https://qiita.com/7shi/items/6db3e19ddc1f8552d9a0)は
`call/cc` 版と限定継続版を並べて「**限定継続では継続を保存しておく必要がない。
`yield` は外部の変数を参照しないためジェネレーターの外で定義できる**」と結論している。
**これは Haskell でもそのまま再現した。**

```hs
-- callCC 版（../gen-bidirectional/GenBi.hs）: 脱出継続 ccOut を引き回す
type Out i o = Gen i o -> GenM i o i
yield :: Out i o -> o -> GenM i o i
yield ccOut v = callCC $ \next -> ccOut (Yield v next)
runGen body = evalCont $ callCC $ \ccOut -> body ccOut >> return Done

-- shift 版: ccOut が消え、Out 型ごと不要になる
yield :: o -> Cont (Gen i o) i
yield v = shift $ \k -> return (Yield v (return . k))
runGen body = evalCont $ reset (body >> return Done)
```

`Gen` の型と `feed` は両版で同一。出力も一致する（`feed accum [1,2,3,4]` → `[0,1,3,6]`）。

**記事への影響: 本線をどちらで書くかという判断が発生する。** Scheme の 2 部シリーズを
読んだ読者は「なぜ Haskell 版はわざわざ面倒な `callCC` で書くのか」を必ず思う。

**結論は「本線は `callCC` のまま、6 (a) の末尾で比較に触れる」。** 理由は 3 つ。

1. 記事の狙いは「bind は継続を抽象化したもの」で、`callCC` は `Cont` の定義から直接出る。
   `shift`/`reset` はもう一段の抽象で、区切りという別概念が要る。
2. `(next ())` → `next` という 6 (a) の見せ場は `callCC` 版の方が鮮明（純粋な削除になる）。
3. 03 回（`cps-to-continuation`）も `callCC` で書いており、シリーズの連続性がある。

### まとめの言い方

**`callCC` は「区切りの中の undelimited な call/cc」。**
区切られてはいるが、その区切りの中では abortive な完全継続。
`Cont` は限定継続を*表現できる*土台であって、`reset` / `shift` は自作しなくても
`Control.Monad.Trans.Cont` に入っている。

「セマンティクスとしては限定継続」は、到達範囲の話としては正しく、
継続の性質（abortive か composable か）の話としてはミスリード。

## 実行結果

`Delimited.hs`:

```
1        -- scope: 脱出は evalCont まで
after    -- その外は必ず実行される
1        -- abortive: +100 が効かない
5        -- composable: 1 + (1 + 3)
60       -- 同じ継続を 2 回呼んで足す
10       -- callCC で同じ形を書くと型は通るが最初の k で脱出する
[1]      -- 継続は多重呼び出しできる第一級の値
130      -- 入れ子の区切り: (1*10 + 2*10) + 100
```

`Shift.hs`:

```
[0,1,3,6]   -- callCC 版（../gen-bidirectional/GenBi.hs）と一致
```

## 記事構成への示唆

**「残る判断: 限定継続に触れるか」は触れる方に倒れる。**
Scheme の 2 部シリーズ（[call/cc](https://qiita.com/7shi/items/a44c5257f04f0c641ef0) /
[限定継続](https://qiita.com/7shi/items/6db3e19ddc1f8552d9a0)）を読んだ読者は
「Haskell の `callCC` は Scheme の `call/cc` と同じか」を必ず思うので、放置すると宙に浮く。

ただし**`shift`/`reset` そのものの解説は不要**。Scheme の
[限定継続でジェネレーターを実装する](https://qiita.com/7shi/items/6db3e19ddc1f8552d9a0)が
既に説明しているので、そちらへリンクする。

**置き場所は 3 箇所に分ける（決定済み）。**

1. **構成案 2「答えの型 `r` の役割」** — 「`r` は区切りである」を 1〜2 行。
   「`r` は抽象的で掴みにくい」への回答になる。限定継続という語はまだ出さなくてよい。
2. **構成案 3（`callCC`）の末尾** — abortive vs composable を数行。`shift`/`reset` が
   標準にあること、Scheme 2 部シリーズと 03 回へのリンク。
   「`callCC` は区切りの中の undelimited な call/cc」で締める。
   03 回は限定継続の話を 2 回「機会を改めます」と先送りしているので（`:360`, `:489`）、
   ここが回収先になる。
3. **構成案 6 (a) の末尾** — `Shift.hs` の比較（コード 2 行＋リンク）。
   Scheme 記事と同じ比較ができる唯一の地点。
