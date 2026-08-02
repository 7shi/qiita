---
coediting: false
comments_count: 0
created_at: '2026-07-31T00:00:00+09:00'
id: ''
likes_count: 0
private: false
reactions_count: 0
stocks_count: 0
tags:
- name: Haskell
  versions: []
- name: モナド
  versions: []
- name: 継続
  versions: []
title: Haskell 継続モナド 超入門
updated_at: ''
url: ''
slide: false
---

Haskell ではモナドと呼ばれる部品を組み合わせてプログラムを作ります。`>>=`（bind）の中に隠れている**継続**を取り出し、それを値として扱えるようにした**継続モナド**を説明します。継続を値として取り出せると何が嬉しいのかを、実際に動くコルーチン（ジェネレーター）の実装を通して示します。

シリーズの記事です。

1. [Haskell 超入門](http://qiita.com/7shi/items/145f1234f8ec2af923ef)
1. [Haskell 代数的データ型 超入門](http://qiita.com/7shi/items/1ce76bde464b4a55c143)
1. [Haskell アクション 超入門](http://qiita.com/7shi/items/85afd7bbd5d6c4115ad6)
1. [Haskell ラムダ 超入門](http://qiita.com/7shi/items/1345bf32003faff435cb)
1. [Haskell アクションとラムダ 超入門](http://qiita.com/7shi/items/4a8a2807bb5186576c61)
1. [Haskell IOモナド 超入門](http://qiita.com/7shi/items/d3d3492ddd90d47160f2)
1. [Haskell リストモナド 超入門](http://qiita.com/7shi/items/deb19c4cba933590ffbf)
1. [Haskell Maybeモナド 超入門](http://qiita.com/7shi/items/c7d7eec066af0fe0688d)
1. [Haskell 状態系モナド 超入門](http://qiita.com/7shi/items/2e9bff5d88302de1a9e9)
1. [Haskell モナド変換子 超入門](http://qiita.com/7shi/items/4408b76624067c17e933)
1. [Haskell 例外処理 超入門](http://qiita.com/7shi/items/73e534c47bbebc71b37e)
1. [Haskell 構文解析 超入門](http://qiita.com/7shi/items/b8c741e78a96ea2c10fe)
1. Haskell 継続モナド 超入門 ← この記事
1. 【予定】Haskell 型クラス 超入門
1. 【予定】Haskell モナドとゆかいな仲間たち
1. 【予定】Haskell Free モナド 超入門
1. 【予定】Haskell Operational モナド 超入門
1. 【予定】Haskell Eff モナド 超入門
1. 【予定】Haskell アロー 超入門

# bind と継続

他の言語でもおなじみのパターンとして、処理が終わった後に呼ばれるコールバックがあります。

```js:Node.js のコールバック
readFile("input.txt", (contents) => {
    console.log(contents);
});
```

`readFile` は「読み終わったら何をするか」を表すコールバックを受け取ります。この「次にすること」を**継続**（continuation）と呼びます。

同じ形は `Python` の `with` にもあります。

```py:Python の with
with open("input.txt", "r") as f:
    contents = f.read()
    print(contents)
```

見た目はブロック構文ですが、`with` の本体は「ファイルを開いた後に何をするか」を表しています。ただし Python は本体を関数として渡すのではなく、構文としてその場に展開します。同じ役割を関数として明示的に受け取るのが Haskell の `withFile` です。

```hs:Haskell の withFile
withFile "input.txt" ReadMode $ \h -> do
    contents <- hGetContents h
    putStr contents
```

`withFile` はファイルを開き、そのハンドルをラムダに渡して、終わったら閉じます。`ReadMode` は読み込みモード、`hGetContents` はハンドルから内容を読み込む関数です。ここではラムダが継続にあたります。

`readFile`・`with`・`withFile` は、いずれも「続きに何をするか」を先に切り出している点で同じ形です。渡し方だけが違います。

ここで区別しておきたいのが、継続そのものと、継続の渡し方です。`readFile`・`withFile` は結果を返り値にせず、コールバックという形で継続を引数として受け取っています。このように継続を引数として渡すことを**継続渡し**（continuation-passing）、そのように書くスタイルを**CPS**（Continuation-Passing Style: 継続渡しスタイル）と呼びます。

## bind と CPS

Haskell の bind（`>>=`）も同じ構造を持っています。`m >>= k` の `k` は「`m` の結果を受け取って続きを行う関数」、つまり継続です。`k` を引数として受け取る bind は、まさに継続渡しの形をしています。

IO モナドなら「次に実行するアクション」、Maybe モナドなら「値があったときに続ける処理」、リストモナドなら「各要素に対して行う処理」が継続にあたります。モナドの種類が変わっても `k` が継続だという構図は変わりません。

bind が CPS の構造を持っていることを、最も単純なモナドである恒等モナド（`Identity`）で確認します。中に値が入っているだけのモナドです。👉[Haskell モナド変換子 超入門](https://qiita.com/7shi/items/4408b76624067c17e933)

```hs
import Control.Monad.Identity

calc = do
    x <- return 3
    return (x * 2)

main = print $ runIdentity calc
```
```text:実行結果
6
```

`do` 記法は `>>=` の連鎖の糖衣構文です。展開すれば次のようになります。👉[Haskell アクションとラムダ 超入門](https://qiita.com/7shi/items/4a8a2807bb5186576c61)

```hs
calc =
    return 3 >>= \x ->
    return (x * 2)
```

`return 3 >>= k` の `k` に相当する `\x -> return (x * 2)` が、`return 3` の後に続く継続です。

`Identity` の bind の定義を、この継続 `k` に注目して見てみます。

```hs
m >>= k = k (runIdentity m)
```

`runIdentity m` は `Identity` から値を取り出す操作です。取り出した値を `k` に渡すことで計算を進めています。継続を引数として受け取って呼ぶという構造は CPS と同じです。

# 継続モナド

`Identity` の bind では、継続 `k` はその場で呼ばれるだけです。これは bind の定義が決めているため、外から挙動を変える余地はありません。

そこで、値の代わりに `k` の呼び出しを含む CPS の関数、つまり「継続に値を渡す関数」をモナドの中身にすることを考えます。`k` の呼び出しが関数の中に閉じ込められるため、それをどのように呼ぶかをコード側が制御できるようになります。これが継続モナド `Cont` です。

```hs:型表記
Cont r a
```

* `r`: 最終的な結果の型
* `a`: 継続モナドの中に含まれる値の型

使用するには `Control.Monad.Trans.Cont` を import します。

## runCont

```hs:型
runCont :: Cont r a -> (a -> r) -> r
```

`Identity` が中に値を持っていて `runIdentity` で取り出せるのに対して、`Cont` は中に次の関数を持っていて `runCont` で取り出せます。

```hs:Cont が持つ関数
(a -> r) -> r
```

これは継続 `a -> r` を受け取って、その継続にモナドから取り出した値を渡して、得られた結果を返す関数です。`runCont` の第 2 引数 `a -> r` がこの継続にあたり、bind の中で使われる継続 `k`（`a -> Cont r b`）とは型が異なります。

```hs
import Control.Monad.Trans.Cont

main = do
    let a = return 1 :: Cont Int Int
    print $ runCont a (+ 100)  -- 継続に1が渡される
```
```text:実行結果
101
```

`runIdentity` は中の値をそのまま返すだけですが、`runCont` は値をどう使うかという継続を渡さないと結果が得られません。値を受け取ってから使い方を決めるのではなく、使い方を先に渡しておく、という順序の違いです。

:::note info
`runCont` の呼び出し自体は普通に `r` を返すので、値を継続の先でしか使えないという制約はありません。内部の実装が CPS の形をしているだけです。
:::

## evalCont

```hs:型
evalCont :: Cont r r -> r
```

継続に `id`（何もしない関数）を指定して値を取り出す関数です。

```hs
evalCont = (`runCont` id)
```

`Identity` の `runIdentity` と同じように使えます。

```hs
import Control.Monad.Identity
import Control.Monad.Trans.Cont

main = do
    print $ runIdentity (return 1 :: Identity Int)
    print $ evalCont    (return 1 :: Cont Int Int)
```
```text:実行結果
1
1
```

## cont

```hs:型
cont :: ((a -> r) -> r) -> Cont r a
```

`(a -> r) -> r` という型の関数から継続モナドを作る関数です。

中に `1` を含む継続モナドを作ってみます。

```hs
import Control.Monad.Trans.Cont

main = do
    let m1 = return 1             -- 1が入ったモナド
        m2 = cont $ \c -> c 1     -- m1と等価: 継続 -> 継続に1を渡す
    print $ evalCont m1
    print $ evalCont m2
```
```text:実行結果
1
1
```

## bind

```hs:実装
m >>= k = cont $ \c -> runCont m (\x -> runCont (k x) c)
```

`k` と `c` という 2 つの関数が現れます。どちらも継続と呼ばれますが、型が違うことに注意が必要です。

| | 型 | 中身 |
|---|---|---|
| `k`（bind に渡す関数） | `a -> Cont r b` | 続きの計算をモナドとして書いたもの |
| `c`（`runCont` が受け取る継続） | `b -> r` | 値を受け取るだけの素の関数 |

`k` の戻り値からモナドを取り除いたのが `\x -> runCont (k x) c` です。それで `runCont m c` の `c` を置き換えます。

1. `m` の評価: `runCont m c`
2. `m >>= k` の評価: `runCont m (\x -> runCont (k x) c)`

bind の時点ではどのような `c` が渡されるか未定なので、それをラムダの引数で受け取る構造になっています。👉[詳細 (JavaScript)](https://qiita.com/7shi/items/27b6f3169961299a6195)

`Identity` のように `k` を bind 時には呼ばないで、モナドの中に閉じ込めています。これによって、継続をどのように呼ぶかをコード側が制御できるようになります。

# callCC

bind が CPS の形をしているのは `Cont` に限らずすべてのモナドに共通する性質です。それでも `Cont` が「継続モナド」と呼ばれるのは、`k` の呼び出しが `\c -> ...` という関数の中に閉じ込められ、「ここから先の計算全体」を表す継続として保持されるためです。

この「継続を保持できる」性質を使って、今まさに実行中の継続を取り出すのが `callCC` です。

```hs:型
callCC :: ((a -> Cont r b) -> Cont r a) -> Cont r a
```

`callCC` 自体も CPS の形をしています。`callCC f` として関数 `f` を渡せば、`f` が `callCC` の継続として呼び出されます。`callCC` は `f` に引数として現在の継続 `a -> Cont r b` を渡します。`f` の中でこの継続を呼び出せば、それ以降の処理を飛ばして `callCC` から抜けられます。

```hs
import Control.Monad (when)
import Control.Monad.Trans.Cont (evalCont, callCC)

f x = evalCont $ callCC $ \ret -> do
    when (x == 0) (ret "zero")
    return "non-zero"

main = do
    print $ f 0
    print $ f 1
```
```text:実行結果
"zero"
"non-zero"
```

`x == 0` のとき `ret "zero"` を呼べば、`return "non-zero"` には到達せず `"zero"` が結果になります。この動作がどのように実現されているのかを、以下で組み立てていきます。

## 実装

```hs
callCC f = cont $ \c -> runCont (f (\x -> cont $ \_ -> c x)) c
```

`f` と、`f` に引数として渡される `\x -> cont $ \_ -> c x` という 2 つの関数が現れます。どちらも継続ですが、指しているスコープが違います。`callCC f` をひとつのブロックと見れば、`f` はそのブロックの内側での継続です。一方 `f` の引数は、`callCC f` の後に続けられた、ブロックの外側での継続です。これが `ret` の正体で、呼び出すとブロックの外へ抜けます。

`ret` の中身の `\x -> cont $ \_ -> c x` は、自分自身に続く継続 `_` は捨てて、外側の継続 `c` に `x` を渡す関数です。そのため `ret` を呼んだ時点で計算が打ち切られ、`callCC` の外側にジャンプします。呼ばなければ `f` の本体はそのまま最後まで実行され、末尾の `c` が結果を受け取ります。

bind と `callCC` は互いに逆方向の型変換をしています。

| | 変換元 | 変換先 | 実装 |
|---|---|---|---|
| bind | `k :: a -> Cont r b` | `b -> r` | `\x -> runCont (k x) c` |
| `callCC` | `c :: a -> r` | `a -> Cont r b` | `\x -> cont $ \_ -> c x` |

bind は `k` の戻り値からモナドを剥がしていたのに対して、`callCC` は逆に `c` の戻り値をモナドで包んでいます。👉[詳細 (JavaScript)](https://qiita.com/7shi/items/27b6f3169961299a6195)

# 応用: コルーチン

継続を保持できることの一番の見せ場が、`k` を**後で**呼ぶ自由です。これを使うとコルーチン（ジェネレーター）が実装できます。

## 型が循環する

生成した値をその場で返さず、いったん抜けて後から再開する。これがジェネレーターの動きです。「抜ける」ときに、再開のための継続を一緒に持ち出す必要があります。

```hs:NG
type Gen a = Maybe (a, Cont (Gen a) (Gen a))
```

このように `type` で素直に書こうとすると、コンパイルが通りません。

```text:エラー
Cycle in type synonym declarations:
  Gen.hs:3:1-44: type Gen a = Maybe (a, Cont (Gen a) (Gen a))
```

`type` は単なる別名なので、使われた箇所でそのまま展開されます。`Gen a` の定義の中に `Gen a` 自身が現れているため、展開が終わりません。有限の木として型を表せず、「型シノニム」で説明した `type` の限界がここで表面化します。👉[Haskell 代数的データ型 超入門](https://qiita.com/7shi/items/1ce76bde464b4a55c143)

## data で包んで解決する

`data`・`newtype` はこれとは事情が違います。名前そのものが型として自立するので、展開せずに循環を畳み込めます。

```hs
data Gen a = Done | Yield a (Cont (Gen a) (Gen a))
```

コンストラクタを1枚挟むだけで、同じ「自己参照する型」がそのまま定義できます。対価はコンストラクタの付け外しだけです。

これでジェネレーターの型が用意できました。

```hs
import Control.Monad.Trans.Cont (Cont, evalCont, callCC)

data Gen a = Done | Yield a (Cont (Gen a) (Gen a))

yield ccOut v = callCC $ \next -> ccOut (Yield v (next ()))

runGen body = evalCont $ callCC $ \ccOut -> body ccOut >> return Done
```

`yield` は `callCC` で「現在の継続」（`next`、再開ポイント）を捕まえ、`Yield` に包んで `ccOut`（`runGen` の外へ抜ける継続）に渡します。`ccOut` を呼ぶことで `callCC` の内側から抜け、値と再開用の継続の組を `runGen` の呼び出し元まで持ち出します。

```hs
toList Done = []
toList (Yield v next) = v : toList (evalCont next)

nats = runGen $ \ccOut ->
    let loop n = yield ccOut n >> loop (n + 1)
    in loop 0

finite = runGen $ \ccOut -> mapM_ (yield ccOut) [1, 2, 3]

main = do
    print (take 5 (toList nats))
    print (toList finite)
```
```text:実行結果
[0,1,2,3,4]
[1,2,3]
```

無限のジェネレーター（`nats`）も有限のジェネレーター（`finite`）も同じ `yield` で書け、`take`・`mapM_` のような既存のコンビネーターがそのまま使えます。

## 双方向のやり取り

ここまでは値を出すだけの一方通行でしたが、`yield` は再開時に渡された値を戻り値として受け取れます（JavaScript の `it.next(x)` に相当）。出力の型 `o` と入力の型 `i` を分けます。

```hs
data Gen i o = Done | Yield o (i -> Cont (Gen i o) (Gen i o))
```

再開用の継続が `i -> ...` という関数になっただけで、型の循環は同じように `data` で解決します。`RankNTypes` のような拡張も要りません。

生産専用版との差分はこれだけです。

```hs
-- 生産専用
yield ccOut v = callCC $ \next -> ccOut (Yield v (next ()))

-- 双方向
yield ccOut v = callCC $ \next -> ccOut (Yield v  next    )
```

**`(next ())` が `next` になっただけ。** 生産専用版は捕まえた継続に `()` を渡してその場で潰していただけで、渡さずそのまま格納すれば双方向になります。「捕まえた継続は関数だから引数を渡せる」という `callCC` の性質が、コードの差分そのものとして目に見えます。

```hs
import Control.Monad.Trans.Cont (Cont, evalCont, callCC)

data Gen i o = Done | Yield o (i -> Cont (Gen i o) (Gen i o))

yield ccOut v = callCC $ \next -> ccOut (Yield v next)

runGen body = evalCont $ callCC $ \ccOut -> body ccOut >> return Done

feed (Yield v next) (i:is) = v : feed (evalCont (next i)) is
feed _ _ = []

-- 累算器: 渡された値を足し込み、途中結果を yield する
accum = runGen $ \ccOut ->
    let loop s = yield ccOut s >>= \x -> loop (s + x)
    in loop 0

main = print (feed accum [1, 2, 3, 4])
```
```text:実行結果
[0,1,3,6]
```

`toList` が書けたのは、入力が `()` に潰れていて渡す値がなかったからです。入力が必要になると、代わりに入力列をまとめて渡す `feed` になります。

```hs:型
feed :: Gen i o -> [i] -> [o]
```

:::note info
ジェネレーターは「まず出して、それから受け取る」ので入出力の個数がずれます。`accum` に `[1,2,3,4]` を渡すと `[0,1,3,6]` になり、最後の入力を反映した `6+4=10` は出力されません。
:::

### feed が示すもの

`feed` の型は `[i] -> [o]`、つまりリストからリストへの関数です。ここだけを見ると「結局リストに戻るなら継続は要らなかったのでは」と思うかもしれません。実際、`accum` の結果 `[0,1,3,6]` は `init (scanl (+) 0 [1,2,3,4])` と同じで、既存のリスト関数に置き換えられます。

**`feed` が示しているのは「継続がリストを超えた証拠」ではなく、逆に「入力を先に全部与えるなら、双方向コルーチンはリスト関数に潰せる」ということです。** この線引きは後で改めて整理します。

### 歴史上の先例

`feed` の型 `[i] -> [o]` には歴史上の先例があります。IO モナド導入前の Haskell 1.0（1990年）は、遅延ストリームで副作用を扱っており、プログラムの型が次のように定義されていました。

```hs
type Behaviour = [Response] -> [Request]
```

`feed prog` の型はこの `Behaviour` と一致します。つまり**双方向コルーチンを2本の遅延リストで表したもの**が、まさに Haskell 1.0のプログラムだったことになります。当時は正しい順序で計算させるために遅延パターン `~` が必要で、これを外すとデッドロックしました。この経緯と詳細は単発記事にまとめています。

https://zenn.dev/7shi/articles/20260731-haskell-io-history

Haskell 1.0はこの継続 I/O と並行して、ストリームを扱う版の I/O も持っていました。両者はモナド版（Haskell 1.3、1996年）に置き換えられ、現在の `IO` モナドに至ります。

### 既存のジェネレーターより能力が上

「実用には既存のジェネレーターを使えばよいのでは」という疑問に対する答えがこれです。`Gen i o` は純粋な値なので、**同じ中断点から何度でも再開できます。**

中断点から1歩進める `step` と、そこでの出力を覗く `peek` を用意します。

```hs
step (Yield _ next) i = evalCont (next i)
step Done _ = Done

peek (Yield v _) = Just v
peek Done = Nothing

main = do
    let g = step accum 10   -- 10 を渡した状態
    print (peek g)
    print (peek (step g 1))
    print (peek (step g 100))
    print (peek (step g 1000))
```
```text:実行結果
Just 10
Just 11
Just 110
Just 1010
```

`g` は何度使っても消費されません。違う入力を渡せば分岐し、分岐した先をさらに分岐させれば木になります。JavaScript や Python のジェネレーターはこれができません（消費すると元の状態が失われます）。[イテレーターのクローンもどき](https://qiita.com/7shi/items/6575cbb98c5a710a2945)が最初からやり直す回避策を書いているのが、その裏返しです。`Promise` も `resolve` を2回呼べないという点で同様で、[非同期APIをPromiseでラップしてasync/awaitで使う](https://qiita.com/7shi/items/a2bb35f27cd4a56f7bac)が相違点として挙げています。

`callCC` で捕まえた継続は普通の関数値なので、何度でも呼べます。これが「実用上も自前で組んだ方が能力が上」という形で表に出ています。

## 副作用と交互に進む

`ContT r IO` に持ち上げると、各 `yield` の間で IO アクションを実行できます。モナドスタックの要領で `Cont` に `m`（ここでは `IO`）が挟まります。👉[Haskell モナド変換子 超入門](https://qiita.com/7shi/items/4408b76624067c17e933)

```hs
import Control.Monad.Trans.Cont (ContT, evalContT, callCC)
import Control.Monad.IO.Class (liftIO)

data Gen a = Done | Yield a (ContT (Gen a) IO (Gen a))

-- yield の定義は純粋版と 1 文字も変わらない
yield ccOut v = callCC $ \next -> ccOut (Yield v (next ()))

runGen body = evalContT $ callCC $ \ccOut -> body ccOut >> return Done
```

差分は機械的です。`Cont` が `ContT ... IO` に、`evalCont` が `evalContT` になり、`runGen` の結果が `IO (Gen a)` になります。生産側で `liftIO` を使う必要はありますが、`yield` の定義自体は1文字も変わりません。

:::note info
mtl 2.3 では `Control.Monad.Cont` が `liftIO` を再輸出しないため、`Control.Monad.IO.Class` から明示的に import する必要があります。
:::

```hs
noisy = runGen $ \ccOut ->
    let y n = do
            liftIO $ putStrLn ("  produce " ++ show n)
            yield ccOut n
    in mapM_ y [1, 2, 3]

main = do
    g <- noisy
    xs <- consume g
    print xs
  where
    consume Done = return []
    consume (Yield v k) = do
        putStrLn ("  consume " ++ show v)
        g <- evalContT k
        (v :) <$> consume g
```
```text:実行結果
  produce 1
  consume 1
  produce 2
  consume 2
  produce 3
  consume 3
[1,2,3]
```

生産側と消費側の IO が期待通り交互に実行されています。

### 遅延がなくなる

ここが `ContT r IO` の本当の見せ場です。純粋版では `take 5 (toList nats)` が遅延評価のおかげでそのまま動きました。無限のジェネレーターでも、必要な分だけ計算されるからです。

`ContT r IO` では `toList` が `IO [a]` になるため、この遅延は効きません。無限のジェネレーターを打ち切るドライバーを自分で書く必要があります。しかも素朴に書くと、判断する前に1回余分に再開してしまいます。

```hs
takeIOEager 0 _ = return []
takeIOEager _ Done = return []
takeIOEager n (Yield v k) = do
    g <- evalContT k              -- 必要か判断する前に再開してしまう
    (v :) <$> takeIOEager (n - 1) g
```
```text:実行結果（takeIOEager 3）
  produce 0
  produce 1
  produce 2
  produce 3     ← 3 個しか要らないのに 4 回生産される
[0,1,2]
```

再開の前に打ち切りを判定すれば直ります。

```hs
takeIO n _ | n <= 0 = return []
takeIO _ Done = return []
takeIO n (Yield v k)
    | n == 1 = return [v]         -- ここで止めれば余分な生産は起きない
    | otherwise = do
        g <- evalContT k
        (v :) <$> takeIO (n - 1) g
```
```text:実行結果（takeIO 3）
  produce 0
  produce 1
  produce 2
[0,1,2]
```

純粋なジェネレーターでは遅延評価が黙って吸収してくれていたことが、副作用を付けた瞬間に目に見える形で露出しました。「リストで十分」と思える場面が実は遅延に頼った偶然の一致だったことが、ここでわかります。

## リストとの境界

ここまでの例はどれも遅延リストで書き直せます。`[1,2,3]`、`[0 ..]`、`map (^ 2) [1 .. 5]` はもちろん、一般の状態機械も `unfoldr`（`Just (値, 次の状態)` が `yield` に相当）で表現できます。生産専用版で `toList` が書けたのも、双方向版で `feed` が既存のリスト関数に潰せたのも、この裏返しです。

ではどこからがリストで素直に書けなくなるのでしょうか。正確な境界は「双方向のジェネレーターに、出力を見てから次の入力を IO で決めるループ」を組み合わせたところです。「双方向のやり取り」と「副作用と交互に進む」をそのまま組み合わせます。

```hs
data Gen i o = Done | Yield o (i -> ContT (Gen i o) IO (Gen i o))

-- 純粋な双方向版と yield の定義は同一
yield ccOut v = callCC $ \next -> ccOut (Yield v next)

runGen body = evalContT $ callCC $ \ccOut -> body ccOut >> return Done

-- 出力を見てから次の入力を IO で決めるドライバー
drive _ Done = return ()
drive f (Yield v next) = do
    mi <- f v
    case mi of
        Nothing -> return ()
        Just i -> evalContT (next i) >>= drive f
```

```hs
accum = runGen $ \ccOut ->
    let loop s = do
            liftIO $ putStrLn ("  [gen] total = " ++ show s)
            x <- yield ccOut s
            loop (s + x)
    in loop 0

main = do
    g <- accum
    drive step g   -- 合計が 5 を超えたら打ち切る
  where
    step total = do
        putStrLn ("  [drv] got " ++ show total)
        if total > 5
            then do putStrLn "  [drv] stop"; return Nothing
            else do
                let n = total + 1
                putStrLn ("  [drv] send " ++ show n)
                return (Just n)
```
```text:実行結果
  [gen] total = 0
  [drv] got 0
  [drv] send 1
  [gen] total = 1
  [drv] got 1
  [drv] send 2
  [gen] total = 3
  [drv] got 3
  [drv] send 4
  [gen] total = 7
  [drv] got 7
  [drv] stop
```

出力を見てから次の入力を IO で決める、というループはリストでは（遅延させても）書けません。

ただし「リストでは書けない」と言い切ってしまうのは正確ではありません。先ほど見たように `Haskell 1.0` はこれを遅延リストの**knot-tying**で実現していました。`~`（遅延パターン）に頼った書き方で、壊れやすく、最終的に Haskell はこれを試した上で捨てました。

正確な線引きはこうなります。**「リストでも書けるが、遅延に頼った knot-tying が要り、Haskell はそれを試して捨てた」。** これは思弁ではなく史実です。継続モナドによるコルーチンは、Haskell がかつて遅延リストで実現していたものを、副作用を明示するモナドの形で作り直したものだと言えます。

# 限定継続

「継続を保持できる」ことの威力を `callCC` で確認してきましたが、`callCC` は継続を扱う唯一の方法ではありません。もう一つの道具である**限定継続**（delimited continuation）を導入し、ここまで作ったコルーチンの実装がどう単純化されるかを確認します。

## 区切り

「継続を保持できる」と言っても、捕まえた継続がどこまで届くかには制約があります。`callCC` で確認します。

```hs
main = do
    let r = evalCont $ callCC $ \ret -> do
                _ <- ret (1 :: Int)
                return 999          -- ここには来ない
    print r
    putStrLn "after"                -- 脱出はここまで飛べない
```
```text:実行結果
1
after
```

`ret` を呼んで `callCC` を脱出しても、`evalCont` の外側（`putStrLn "after"`）は必ず実行されます。bind で連結された `Cont` ひとつがひとまとまりの単位で、`evalCont` はその外側で結果を取り出すだけの関数だからです。

この「継続が届く範囲」の境界を**区切り**（delimiter）と呼びます。`Cont` では bind で連結された範囲ひとつ、`evalCont` の呼び出しがその境界にあたります。`callCC` で捕まえた継続は、この区切りの中でしか意味を持ちません。

## shift/reset

区切りを明示的に作るのが `reset`、区切りまでの継続を値として取り出すのが `shift` です。どちらも `Control.Monad.Trans.Cont` に標準で用意されています。

```hs:型
reset :: Cont r r -> Cont r' r
shift :: ((a -> r) -> Cont r r) -> Cont r a
```

`reset e` は `e` をひとつの区切りにします。`shift f` は `f` に「`reset` までの継続」を関数として渡し、`f` の中でそれを呼び出せるようにします。

同じ形の式を `callCC` と `shift`/`reset` の両方で書き、挙動を比較します。

まず `callCC` です。

```hs
import Control.Monad.Trans.Cont (evalCont, callCC)

viaCallCC = evalCont $ do
    x <- callCC $ \ret -> do
        n <- ret 5
        return (2 + n)  -- 到達しない
    return (2 * (1 + x))

main = print viaCallCC
```
```text:実行結果
12
```

`ret 5` を呼ぶと `callCC` から即座に `5` が返り、`x` に `5` が入って `2 * (1 + 5)` が計算されて `12` になります。`ret 5` の継続である `return (2 + n)` は実行されません。

次に同じ形を `shift`・`reset` で書きます。

```hs
import Control.Monad.Trans.Cont (evalCont, reset, shift)

viaShift = evalCont $ reset $ do
    x <- shift $ \k -> do
        let n = k 5     -- k は素の値を返すので let で受けられる
        return (2 + n)  -- 到達する
    return (2 * (1 + x))

main = print viaShift
```
```text:実行結果
14
```

`callCC` の `ret` と同じく、`shift` の `k` もここで呼び出されます。ただし `ret` と違って、呼んだ時点で残りのコードが捨てられることはありません。呼んだ場所に戻ってきて `do` ブロックの続きがそのまま実行されます。`do` ブロックが（ふつうの関数のように）最後まで進むと、そこで得られた値がそのまま `shift` を抜けて区切り全体の値になります。

1. `k` には「`shift` の後に続くコード」、つまり戻り値の `x` への束縛と `return (2 * (1 + x))` が、`reset` の区切りの終端まであらかじめ1つの関数にまとめられて渡されます。`reset` の外側（呼び出し元やそれ以降のコード）は含まれません。渡された時点で完成した、ただの関数です。
2. `k 5` を呼ぶと、その関数がその場で実行されます。引数の `5` が `shift` の戻り値として `x` に束縛され、続けて `2 * (1 + 5)` が計算され、`12` という値が呼んだ場所にそのまま返ります。
3. `12` が `n` に束縛され、`do` ブロックが最後の `return (2 + n)` に到達して `14` になります。この値がそのまま区切り（`reset`）全体の値になります。

注意したいのは、`shift` の `do` ブロックを抜けた先が、テキスト上で外に書かれている `return (2 * (1 + x))` ではないことです。`shift` は本体を抜けると常に区切り（`reset`）へ直接抜けます。外側の続きが実行されるのは `k` を呼んだときだけで、この例では手順2の `k 5` の中で実行されています。手順 3 で本体を抜けた後にもう一度実行されることはありません。

`callCC` では `ret 5` の後に書いた `2 + n` の部分が捨てられて `12` になるのに対し、`shift` では `k 5` が呼んだ場所に戻ってくるため `2 + n` が生き残って `14` になります。

## 呼ぶ回数は自由

`shift` の `k` はただの関数として渡されるので、`f` の中で呼ぶかどうか、何回呼ぶかはコード次第です。

`k` を一度も呼ばなければ、外側の続きはそもそも実行されません。

```hs
noCall = evalCont $ reset $ do
    x <- shift $ \k -> return 999
    return (2 * (1 + x))
```
```text:実行結果
999
```

`f` が `999` を返すだけで `k` を呼ばなかったため、その `999` がそのまま区切り全体の値になります。`return (2 * (1 + x))` は `k` の中身として渡されているだけで、`k` を呼ばない限り実行されることはありません。

逆に `k` は呼べば戻ってくる普通の関数なので、同じ `k` を2回呼ぶこともできます。

```hs
twice = evalCont $ reset $ do
    x <- shift $ \k -> return (k 10 + k 20)
    return (x * 2)
```
```text:実行結果
60
```

`k 10` は `10 * 2`、`k 20` は `20 * 2` を返し、足して `60` になります。`callCC` の `ret` は呼べばその場で脱出するので、呼ばなければ本体が最後まで進むだけ、2回書いても2回目には到達しません。呼ぶ回数で外側の続きを操作するという選択肢自体がありません。

### 実装

```hs
reset e = cont $ \k -> k (evalCont e)
shift f = cont $ \k -> evalCont (f k)
```

`reset e` は `evalCont e` で `e` を評価し切って値を取り出します。区切りの内側を先に「ただの値」まで還元してから、外側の継続 `k` に渡しています。

`shift f` では `cont $ \k -> ...` の `k` こそが「`reset` までの継続」です。`shift f` の後に続くコードは、bind によってこの `k` として `f` に渡されます。`f` の中で `k` を呼べば、呼んだ場所に結果が返ってくる普通の関数呼び出しとして働きます。呼ばなければ `evalCont (f k)` が `f` の結果をそのまま区切りの値として使います。

`callCC` の実装と並べると、対比がはっきりします。

| | 捕まえる関数の型 | 呼んだときの挙動 |
|---|---|---|
| `callCC` の `ret` | `a -> Cont r b`（モナドに包まれる） | その場で `callCC` を脱出する |
| `shift` の `k` | `a -> r`（素の値を返す関数） | 呼び出した場所に戻り、結果を式の中で使える |

`callCC` の `ret` は「呼ぶと戻らない」関数として渡されるのに対し、`shift` の `k` は「呼べば戻ってくる」普通の関数として渡されます。

## コルーチンを shift/reset で書き直す

`shift`・`reset` を使うと、前節で組み立てたコルーチンはもっと簡単に書けます。

```hs
import Control.Monad.Trans.Cont (Cont, evalCont, reset, shift)

data Gen i o = Done | Yield o (i -> Cont (Gen i o) (Gen i o))

yield v = shift $ \k -> return (Yield v (return . k))

runGen body = evalCont $ reset (body >> return Done)

feed (Yield v next) (i:is) = v : feed (evalCont (next i)) is
feed _ _ = []

-- 累算器: 渡された値を足し込み、途中結果を yield する
accum = runGen $ let loop s = yield s >>= \x -> loop (s + x) in loop 0

main = print (feed accum [1, 2, 3, 4])
```
```text:実行結果
[0,1,3,6]
```

`Gen` と `feed` は `callCC` 版と同じもので、結果も一致します。違うのは `yield`・`runGen`・`accum` の3つだけです。

`callCC` 版では脱出継続 `ccOut` を `yield` と `runGen` の間で引き回す必要がありましたが、`shift` は呼び出し元まで戻るのでその引き回しが要りません。`yield` から引数が1つ消えています。👉[参考 (Scheme)](https://qiita.com/7shi/items/6db3e19ddc1f8552d9a0)

## 共通部品としての限定継続

`shift`・`reset` は抽象的な道具で、それが何を可能にするのかは定義だけからは掴みにくいものです。その具体的な答えがこのコードです。多くの言語が処理系の専用構文として組み込んでいるコルーチンが、限定継続を土台にすれば数行で書けます。

他の言語の `yield` も、振る舞いとしては同じものです。Python や JavaScript の `yield` は「関数の途中で止まり、呼び出し元へ値を返し、後で同じ場所から再開する」という動きをします。「`yield` から関数の終わりまでの残り」を保留したまま呼び出し元へ抜け、後からその続きを動かす、という点で `shift` と対応します。保留される範囲がその関数の中に収まる点も、`reset` の区切りと同じ構図です。`await` から先を後で再開する async/await も同様で、コルーチンとして一つにくくれます。

対応するのはあくまで振る舞いで、実現方法までは同じとは限りません。処理系が中断した実行状態をそのまま保持する形で実装することも、状態機械へ変換することもあり、いずれにせよ続きが第一級の値として手に入るとは限りません。既存のジェネレーターが同じ中断点から一度しか再開できないのは、この違いによるものです。

つまり限定継続は、各言語が個別の構文として作り込んできたこれらの機能を、共通の部品として取り出したものだと言えます。専用構文は書きやすい代わりに処理系が決めた使い方しかできませんが、部品として持っていれば `Gen` のような型も再開の仕方も自分で決められます。何度でも再開できるジェネレーターが書けたのは、その自由の一例です。

# 実用: リソース管理

ここまでは原理を通すことを優先してきましたが、`ContT` は実用でも使われています。ここで実用面を回収します。

## withFile と ContT の型が一致する

冒頭で継続の例として挙げた `withFile` に戻ります。`withFile path mode` を部分適用すると `(Handle -> IO r) -> IO r` という型になります。これは `ContT r IO Handle` が `runContT` の位置に持つ関数そのものです。

```hs:ネスト
withFile src ReadMode $ \hSrc ->
    withFile dest WriteMode $ \hDest -> do
        content <- hGetContents hSrc
        hPutStr hDest content
```

```hs:ContT
copyFile src dest = do
    hSrc  <- ContT $ withFile src  ReadMode
    hDest <- ContT $ withFile dest WriteMode
    content <- liftIO $ hGetContents hSrc
    liftIO $ hPutStr hDest content

main = evalContT $ copyFile "a.txt" "b.txt"
```

`ContT` で包むだけで、ネストしていた `with` 系の呼び出しが `do` の1行ずつに平坦になります。`Cont` が持つ `(a -> r) -> r` が、標準ライブラリの `with` 系関数とまったく同じ形をしていた、ということです。

:::note info
例外時にもリソースが解放される仕組み（`bracket`・`finally`）が `withFile` の内部で使われていますが、詳細には立ち入りません。
:::

冒頭で見たように、`Python` の `with` は最初から平坦に並びます。Python が `with` を構文として組み込んでいて、本体を関数にせずその場に展開するからです。Haskell にはそういう構文がなく、`withFile` の本体は本物のラムダなので、素直に書けばネストします。`ContT` はそのネストを `do` の並びに戻す道具で、構文を持たない言語が同じ平坦さをライブラリだけで手に入れている、と言えます。

その `with` を `@contextmanager` で書くと、両者が同じ形であることがはっきりします。`yield` の位置で `with` の本体（＝継続）が実行される、という作りは、ここまで作ってきたジェネレーターの `yield` と同じ仕組みです。コルーチンとリソース管理は、別の応用ではなく同じ仕組みの言い換えです。

## forM が効く

ファイルを1つコピーするだけならネストのままでも大差ありませんが、複数のファイルを開こうとすると差が出ます。`with` 系のままではリストに対する明示的な再帰が必要になりますが、`ContT` なら `forM` が使えます。

```hs
import Control.Monad (forM)

openAll paths = forM paths $ \p -> ContT $ withFile p ReadMode

main = evalContT $ do
    hs <- openAll ["a.txt", "b.txt", "c.txt"]
    liftIO $ mapM_ (\h -> hGetContents h >>= putStr) hs
```

「モナドにすると既存のコンビネーターが効く」というジェネレーターの `mapM_`・`take` と同じ構図が、実用の場面でも鳴っています。

## 解放の順序と注意点

解放は取得の逆順（LIFO）になり、ネストで書いた場合と同じ順序になります。

```text:実行結果
open  A
open  B
use AB
close B
close A
```

`callCC` で途中脱出しても、後片付けはきちんと走ります。

```hs
escape = evalContT $ callCC $ \exit -> do
    a <- ContT $ withRes "A"
    liftIO $ putStrLn $ "use " ++ a
    exit ()                            -- ここで脱出
    b <- ContT $ withRes "B"           -- 実行されない
    liftIO $ putStrLn $ "use " ++ b
```
```text:実行結果
open  A
use A
close A
done
```

脱出以降で取得するはずだったリソース（B）はそもそも取得されないため、A の解放だけがきちんと走ります。

注意点が一つあります。`hGetContents` の結果を `ContT` の外へ持ち出すと、ハンドルが閉じた後に読むことになってエラーになります。

```text:エラー
Left a.txt: hGetContents: illegal operation (delayed read on closed handle)
```

`with` 系全般に共通する罠ですが、`ContT` では「どこでリソースが閉じるか」が `do` の見た目から消えるため、特に踏みやすくなっています。副作用が付いた瞬間に遅延の前提が壊れるという構図は、ジェネレーターの節で見た「純粋なら遅延が吸収するが、副作用が付くと露出する」の再演です。

`ContT` によるリソース管理の入り方は、以下の記事を参考にしました。`forM` が効くという論点は特に強く、そのまま取り込みました。

* [Haskellでリソースの管理を継続モナドで行う](https://qiita.com/tanakh/items/81fc1a0d9ae0af3865cb)
* [継続モナド(ContT)のリソース管理活用](https://qiita.com/sparklingbaby/items/2eacabb4be93b9b64755)

# まとめ

`m >>= k` の `k` という、これまで `>>=` の中に隠れていた継続を、`Cont r a` というモナドの中に保持できる値として取り出しました。取り出せることから3つの自由（呼ばない・後で呼ぶ・何度も呼ぶ）が生まれ、それぞれが早期脱出（`callCC`）・ジェネレーター・分岐するジェネレーターという形で実現できることを見ました。

応用として実装したコルーチンは、リストで素直に書ける範囲を丁寧に確認しながら進めることで、「リストでは書けない」という言い切りではなく「リストでも遅延に頼った knot-tying なら書けるが、Haskell はそれを実際に試して捨てた」という史実に基づいた線引きにたどり着きました。

`callCC` でコルーチンを組み上げた後で振り返った限定継続の節では、`shift`・`reset` という別の道具が「区切り」と「合成可能性」の両方を持つこと、そしてそれを使うと同じコルーチンがより簡潔に書けることを確認しました。最後に見た `ContT` によるリソース管理は、原理としては同じ仕組みが実用の場面でどう使われているかの実例です。
