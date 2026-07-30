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

これまでの回では`>>=`（bind）を使うたびに、その中身を深く問わずに済ませてきました。今回は`>>=`の中に隠れている**継続**を取り出し、それを値として扱えるようにした**継続モナド**を説明します。

継続モナドは「難しいモナド」として紹介されがちですが、実体はこれまで書いてきた`>>=`の正体を明示的に取り出したものに過ぎません。その上で、継続を値として取り出せると何が嬉しいのかを、実際に動くコルーチン（ジェネレーター）の実装を通して示します。

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
1. 【予定】Haskell Freeモナド 超入門
1. 【予定】Haskell Operationalモナド 超入門
1. 【予定】Haskell Effモナド 超入門
1. 【予定】Haskell アロー 超入門

# bindと継続

`m >>= k`の`k`は「`m`の後に続く残りの計算」です。これを**継続**（continuation）と呼びます。

`do`ブロックはこの`>>=`の連鎖に脱糖されます。これまで扱ってきたモナドで確認します。

```hs
do
    x <- m
    y <- f x
    g x y
```

上記は次のように脱糖されます。

```hs
m >>= \x ->
f x >>= \y ->
g x y
```

`\x -> f x >>= \y -> g x y`の部分が`m`の継続です。`m`が値を生成した後に何をするかが、この関数として渡されています。

IOモナドなら「次に実行するアクション」、Maybeモナドなら「値があったときに続ける処理」、リストモナドなら「各要素に対して行う処理」が継続にあたります。モナドの種類が変わっても`k`が継続だという構図は変わりません。

継続はいつも`>>=`の中に隠れていて、直接触ることはできません。今回はこれを表に引っ張り出します。

# 継続モナド

継続を値として取り出せるようにしたモナドが**継続モナド**（`Cont`）です。導出の足場として、[10 回](https://qiita.com/7shi/items/4408b76624067c17e933)の「Identityモナド」を使います。

## Identityモナドのbindは既にCPS

[10 回](https://qiita.com/7shi/items/4408b76624067c17e933)で説明した通り、`Identity`は値をそのまま持つだけの最も単純なモナドです。

```hs:定義（再掲）
newtype Identity a = Identity { runIdentity :: a }
```

`Identity`の`bind`を、継続`k`を主役にして書き直してみます。

```hs
m >>= k = k (runIdentity m)   -- k を呼ぶだけ
```

これは**継続渡しスタイル**（CPS: Continuation-Passing Style）そのものです。値を直接返すのではなく、値を渡す先の関数`k`を呼ぶことで計算を進めています。

CPSで書かれた関数を末尾再帰化の道具として使う話は、姉妹編の[CPS 変換による末尾再帰化](https://qiita.com/7shi/items/2d25f7afe25c3ca11acb)（JavaScript）が扱っています。ただしあちらの動機は「ループにするための CPS」で、今回の「継続を掴むための CPS」とは目的が違います。詳しくは深入りしません。

## kは外から来るだけで保持できない

`Identity`の`bind`では、`k`はその場で呼ばれるだけです。呼び出し元が渡した`k`を、`Identity`の中に保持しておいて後で取り出す、ということはできません。

継続を取り出せるようにするには、モナドの内部で「継続渡しスタイルの関数」そのものを保持する必要があります。

## 反転してCont r aを作る

`Identity`は`runIdentity :: a`という形で値を直接持っていました。継続を保持する形にするには、これを反転させます。

```hs
newtype Identity   a = Identity { runIdentity ::           a }
newtype Cont     r a = Cont     { runCont     :: (a -> r) -> r }
```

`Identity`が「値」を持っていたのに対して、`Cont`は「値を渡すと`r`を返す関数」を持ちます。これは`Identity`から値を引き算した形ではなく、CPSであることを利用して**関数として反転**させた形です。単純に値を引いてしまうと`Identity`自身に戻るだけで、`(a -> r) -> r`は出てきません。

姉妹編の[CPS 変換から継続モナドへ](https://qiita.com/7shi/items/27b6f3169961299a6195)（JavaScript）が同じ筋をたどっています。核心を引用します。

> 恒等モナドに継続を渡すことはできますが、外部から与えられるだけで取り出すことはできません。継続を取り出せるようにするため、モナド内部で継続渡しスタイルの関数を保持するようにしたのが**継続モナド**です。

`return`・`>>=`・`evalCont`を実装します。

```hs
newtype Cont r a = Cont { runCont :: (a -> r) -> r }

instance Functor (Cont r) where
    fmap = liftM

instance Applicative (Cont r) where
    pure x = Cont ($ x)
    (<*>) = ap

instance Monad (Cont r) where
    m >>= k = Cont $ \c -> runCont m (\x -> runCont (k x) c)

evalCont :: Cont r r -> r
evalCont = (`runCont` id)
```

※ `Monad`のスーパークラスである`Functor`・`Applicative`のインスタンスも必要です。`Control.Monad`の`liftM`・`ap`で機械的に導出できます。

`evalCont`は、渡す継続に`id`（何もしない関数）を指定して値を取り出します。標準ライブラリでは`Control.Monad.Trans.Cont`にこれと同じものが用意されています。

## 継続を保持できることから3つの自由が出る

`Identity`との違いは「継続を保持できること」だけですが、ここから3つの自由が生まれます。これが記事全体の見取り図になります。

| 得た自由 | 対応する内容 |
|---|---|
| `k`を呼ばない | `callCC`による早期脱出 |
| `k`を後で呼ぶ | ジェネレーター |
| `k`を何度も呼ぶ | 分岐するジェネレーター |

## 答えの型rは区切り

`Cont r a`の`r`は「最終的に何を返すか」を表す型ですが、抽象的で掴みにくく感じるかもしれません。

その正体の一つが**区切り**（prompt）です。`evalCont`が返った時点で、それより外の継続は捕まえられません。`r`は「`evalCont`の内側で完結する計算の型」を表しています。この点は後で`callCC`と一緒に詳しく見ます。

# callCC

`k`を呼ばずに脱出する自由を実現するのが`callCC`（call with current continuation）です。

```hs:型
callCC :: ((a -> Cont r b) -> Cont r a) -> Cont r a
```

`callCC`に渡した関数は、「現在の継続」を引数として受け取って呼ばれます。この継続を呼び出すことで、それ以降の処理を飛ばして`callCC`から抜けられます。

```hs
import Control.Monad (when)
import Control.Monad.Trans.Cont (evalCont, callCC)

f :: Int -> String
f x = evalCont $ callCC $ \ret -> do
    when (x == 0) (ret "zero")
    return "non-zero"
```
```text:実行結果
"zero"    -- f 0
"non-zero"  -- f 1
```

`x == 0`のとき`ret "zero"`を呼ぶと、`return "non-zero"`には到達せず`"zero"`が結果になります。

## 実装から読み解く

`callCC`の実装を見ると、`ret`の正体がわかります。

```hs
callCC :: ((a -> Cont r b) -> Cont r a) -> Cont r a
callCC f = Cont $ \c -> runCont (f (\x -> Cont $ \_ -> c x)) c
```

`f`に渡される`\x -> Cont $ \_ -> c x`が「現在の継続」です。呼び出すと、自分の後に続くはずだった継続（`\_ -> ...`の`_`の部分）を無視して、外側の継続`c`にいきなり`x`を渡します。これが「脱出」の実体です。

型を見ると`k :: a -> Cont r b`の`b`が多相（呼び出し側では決まらない）になっています。これは`k`を呼んだら二度と戻ってこないことを表しています。このように「呼んだら戻らない」性質を**abortive**（脱出専用）と呼びます。

## 限定継続との関係

「継続モナドは実際のコールスタックを操作しないので、限定継続（delimited continuation）ではないか」という疑問が浮かぶかもしれません。答えは半分正しく半分ミスリードです。

争点を2つに分けます。

- **捕まえた継続はどこまで届くか**：`evalCont`の外へは出られません。脱出しても`evalCont`の外側は必ず実行されます。

  ```hs
  main = do
      let r = evalCont $ callCC $ \k -> do
                  _ <- k (1 :: Int)
                  return 999          -- ここには来ない
      print r
      putStrLn "after"                -- 脱出はここまで飛べない
  ```
  ```text:実行結果
  1
  after
  ```

  ここは確かに限定的です。**`evalCont`が区切り（prompt）そのもの**で、`r`が区切りの正体だという先ほどの話がここでつながります。

- **捕まえた継続は合成できるか**：`callCC`はabortiveです。`k`の戻り値を使おうとしても戻ってこないので効きません。

  ```hs
  abortive :: Int
  abortive = evalCont $ callCC $ \k -> do
      x <- k 1
      return (x + 100)                -- 到達しない
  ```
  ```text:実行結果
  1
  ```

  ここが決定的な差です。真の限定継続の道具である`shift`・`reset`（`Control.Monad.Trans.Cont`に標準で用意されています）では、捕まえた継続は値を返す普通の関数なので、結果を合成できます。**composable**と呼ばれる性質です。

  ```hs
  import Control.Monad.Trans.Cont (evalCont, reset, shift)

  composable :: Int
  composable = evalCont $ reset $ do
      x <- shift $ \k -> return (k (k 3))
      return (1 + x)
  ```
  ```text:実行結果
  5   -- 1 + (1 + 3)
  ```

  `reset`が区切りを作り、`shift`がその区切りまでの継続を`k`として値の形で捕まえます。捕まえた`k`は関数として何度でも呼べ、呼んだ結果をさらに計算に使えます。同じ`k`を2回使うことすらできます。

  ```hs
  twice :: Int
  twice = evalCont $ reset $ do
      x <- shift $ \k -> return (k 10 + k 20)
      return (x * 2)
  ```
  ```text:実行結果
  60   -- (10*2) + (20*2)
  ```

  `callCC`ではこの形は型からして書けません。`k :: a -> Cont r b`の`b`が多相なので、`k`を2回呼んで結果を組み合わせることはできないのです。

まとめると、**`callCC`は「区切りの中のundelimitedな`call/cc`」**です。`evalCont`という区切りの中に限定されてはいますが、その中では「呼んだら戻らない」完全な脱出継続として振る舞います。

`shift`・`reset`のより詳しい意味論は、Scheme を題材にした姉妹編で解説しています。

* [call/cc でジェネレーターを実装する](https://qiita.com/7shi/items/a44c5257f04f0c641ef0)
* [限定継続でジェネレーターを実装する](https://qiita.com/7shi/items/6db3e19ddc1f8552d9a0)

※ Scheme はネイティブな`call/cc`を前提に書かれており、CPSで継続を表現するHaskellとは継続の扱いが異なります。上の説明で最低限の理解はできていますが、意味論をより深く追いたい場合はこちらを参照してください。

限定継続の話は姉妹編の[CPS 変換から継続モナドへ](https://qiita.com/7shi/items/27b6f3169961299a6195)で2度「機会を改めます」と先送りされていましたが、ここで回収したことになります。

# 応用: コルーチン

継続を保持できることの一番の見せ場が、`k`を**後で**呼ぶ自由です。これを使うとコルーチン（ジェネレーター）が実装できます。

## 型が循環する

生成した値をその場で返さず、いったん抜けて後から再開する。これがジェネレーターの動きです。「抜ける」ときに、再開のための継続を一緒に持ち出す必要があります。

```hs:NG
type Gen a = Maybe (a, Cont (Gen a) (Gen a))
```

このように`type`で素直に書こうとすると、コンパイルが通りません。

```text:エラー
Cycle in type synonym declarations:
  Gen.hs:3:1-44: type Gen a = Maybe (a, Cont (Gen a) (Gen a))
```

`type`は単なる別名なので、使われた箇所でそのまま展開されます。`Gen a`の定義の中に`Gen a`自身が現れているため、展開が終わりません。有限の木として型を表せず、[02 回](https://qiita.com/7shi/items/1ce76bde464b4a55c143)の「型シノニム」で説明した`type`の限界がここで表面化します。

## dataで包んで解決する

`data`・`newtype`はこれとは事情が違います。名前そのものが型として自立するので、展開せずに循環を畳み込めます。

```hs
data Gen a = Done | Yield a (Cont (Gen a) (Gen a))
```

コンストラクタを1枚挟むだけで、同じ「自己参照する型」がそのまま定義できます。対価はコンストラクタの付け外しだけです。

これでジェネレーターの型が用意できました。

```hs
import Control.Monad.Trans.Cont (Cont, evalCont, callCC)

data Gen a = Done | Yield a (Cont (Gen a) (Gen a))

type GenM a = Cont (Gen a)
type Out a = Gen a -> GenM a ()

yield :: Out a -> a -> GenM a ()
yield ccOut v = callCC $ \next -> ccOut (Yield v (next ()))

runGen :: (Out a -> GenM a x) -> Gen a
runGen body = evalCont $ callCC $ \ccOut -> body ccOut >> return Done
```

`yield`は`callCC`で「現在の継続」（`next`、再開ポイント）を捕まえ、`Yield`に包んで`ccOut`（`runGen`の外へ抜ける継続）に渡します。`ccOut`を呼ぶことで`callCC`の内側から抜け、値と再開用の継続の組を`runGen`の呼び出し元まで持ち出します。

```hs
toList :: Gen a -> [a]
toList Done = []
toList (Yield v next) = v : toList (evalCont next)

nats :: Gen Int
nats = runGen $ \ccOut ->
    let loop n = yield ccOut n >> loop (n + 1)
    in loop 0

finite :: Gen Int
finite = runGen $ \ccOut -> mapM_ (yield ccOut) [1, 2, 3]

main :: IO ()
main = do
    print (take 5 (toList nats))
    print (toList finite)
```
```text:実行結果
[0,1,2,3,4]
[1,2,3]
```

無限のジェネレーター（`nats`）も有限のジェネレーター（`finite`）も同じ`yield`で書け、`take`・`mapM_`のような既存のコンビネーターがそのまま使えます。

## 双方向のやり取り

ここまでは値を出すだけの一方通行でしたが、`yield`は再開時に渡された値を戻り値として受け取れます（JavaScript の `it.next(x)` に相当）。出力の型`o`と入力の型`i`を分けます。

```hs
data Gen i o = Done | Yield o (i -> Cont (Gen i o) (Gen i o))
```

再開用の継続が`i -> ...`という関数になっただけで、型の循環は同じように`data`で解決します。`RankNTypes`のような拡張も要りません。

生産専用版との差分はこれだけです。

```hs
-- 生産専用
yield ccOut v = callCC $ \next -> ccOut (Yield v (next ()))

-- 双方向
yield ccOut v = callCC $ \next -> ccOut (Yield v  next    )
```

**`(next ())`が`next`になっただけ。** 生産専用版は捕まえた継続に`()`を渡してその場で潰していただけで、渡さずそのまま格納すれば双方向になります。「捕まえた継続は関数だから引数を渡せる」という`callCC`の性質が、コードの差分そのものとして目に見えます。

```hs
import Control.Monad.Trans.Cont (Cont, evalCont, callCC)

data Gen i o = Done | Yield o (i -> Cont (Gen i o) (Gen i o))

type GenM i o = Cont (Gen i o)
type Out i o = Gen i o -> GenM i o i

yield :: Out i o -> o -> GenM i o i
yield ccOut v = callCC $ \next -> ccOut (Yield v next)

runGen :: (Out i o -> GenM i o x) -> Gen i o
runGen body = evalCont $ callCC $ \ccOut -> body ccOut >> return Done

feed :: Gen i o -> [i] -> [o]
feed (Yield v next) (i:is) = v : feed (evalCont (next i)) is
feed _ _ = []

-- 累算器: 渡された値を足し込み、途中結果を yield する
accum :: Gen Int Int
accum = runGen $ \ccOut ->
    let loop s = yield ccOut s >>= \x -> loop (s + x)
    in loop 0

main :: IO ()
main = print (feed accum [1, 2, 3, 4])
```
```text:実行結果
[0,1,3,6]
```

`toList`が書けたのは、入力が`()`に潰れていて渡す値がなかったからです。入力が必要になると、代わりに入力列をまとめて渡す`feed :: Gen i o -> [i] -> [o]`になります。

※ ジェネレーターは「まず出して、それから受け取る」ので入出力の個数がずれます。`accum`に`[1,2,3,4]`を渡すと`[0,1,3,6]`になり、最後の入力を反映した`6+4=10`は出力されません。

### feedが示すもの

`feed`の型は`[i] -> [o]`、つまりリストからリストへの関数です。ここだけを見ると「結局リストに戻るなら継続は要らなかったのでは」と思うかもしれません。実際、`accum`の結果`[0,1,3,6]`は`init (scanl (+) 0 [1,2,3,4])`と同じで、既存のリスト関数に置き換えられます。

**`feed`が示しているのは「継続がリストを超えた証拠」ではなく、逆に「入力を先に全部与えるなら、双方向コルーチンはリスト関数に潰せる」ということです。** この線引きは後で改めて整理します。

### 歴史上の先例

`feed`の型`[i] -> [o]`には歴史上の先例があります。IOモナド導入前のHaskell 1.0（1990年）は、遅延ストリームで副作用を扱っており、プログラムの型が次のように定義されていました。

```hs
type Behaviour = [Response] -> [Request]
```

`feed prog`の型はこの`Behaviour`と一致します。つまり**双方向コルーチンを2本の遅延リストで表したもの**が、まさにHaskell 1.0のプログラムだったことになります。当時は正しい順序で計算させるために遅延パターン`~`が必要で、これを外すとデッドロックしました。この経緯と詳細は単発記事にまとめています。

https://zenn.dev/7shi/articles/20260731-haskell-io-history

Haskell 1.0はこの継続I/Oと並行して、ストリームを扱う版のI/Oも持っていました。両者はモナド版（Haskell 1.3、1996年）に置き換えられ、現在の`IO`モナドに至ります。

### shift/resetで書き直す

「限定継続との関係」の節で`callCC`はabortive、`shift`はcomposableだと説明しました。`shift`・`reset`を使うと、このジェネレーターはもっと簡単に書けます。

```hs
import Control.Monad.Trans.Cont (Cont, evalCont, reset, shift)

yield :: o -> Cont (Gen i o) i
yield v = shift $ \k -> return (Yield v (return . k))

runGen :: Cont (Gen i o) x -> Gen i o
runGen body = evalCont $ reset (body >> return Done)

accum :: Gen Int Int
accum = runGen $ let loop s = yield s >>= \x -> loop (s + x) in loop 0
```
```text:実行結果
[0,1,3,6]   -- callCC 版と一致
```

`callCC`版では脱出継続`ccOut`を`yield`と`runGen`の間で引き回す必要がありましたが、`shift`は呼び出し元まで戻るのでその引き回しが要りません。`Out i o`という型ごと消えています。Scheme を扱った姉妹編（[限定継続でジェネレーターを実装する](https://qiita.com/7shi/items/6db3e19ddc1f8552d9a0)）が「限定継続では継続を保存しておく必要がなく、`yield`は外部の変数を参照しないため外で定義できる」と結論しているのと同じ現象がHaskellでも再現します。

それでも本記事の本線は`callCC`のままにします。理由は3つです。

1. 記事の狙いである「bindは継続を抽象化したもの」に対して、`callCC`は`Cont`の定義から直接出てきます。`shift`・`reset`はもう一段上の抽象で、区切りという別概念が必要です。
2. 直前で見せた`(next ())` → `next`という差分は`callCC`版の方が鮮明です（純粋な削除になります）。
3. 姉妹編の[CPS 変換から継続モナドへ](https://qiita.com/7shi/items/27b6f3169961299a6195)も`callCC`で書いており、シリーズとしての連続性があります。

### 既存のジェネレーターより能力が上

「実用には既存のジェネレーターを使えばよいのでは」という疑問に対する答えがこれです。`Gen i o`は純粋な値なので、**同じ中断点から何度でも再開できます。**

中断点から1歩進める`step`と、そこでの出力を覗く`peek`を用意します。

```hs
step :: Gen i o -> i -> Gen i o
step (Yield _ next) i = evalCont (next i)
step Done _ = Done

peek :: Gen i o -> Maybe o
peek (Yield v _) = Just v
peek Done = Nothing

main :: IO ()
main = do
    let g = step accum 10   -- 10 を渡した状態
    print (peek g)
    print (peek (step g 1))
    print (peek (step g 100))
    print (peek (step g 1000))
```
```text:実行結果
Just 10
Just 11    -- g は消費されない
Just 110
Just 1010
```

違う入力を渡せば分岐し、分岐した先をさらに分岐させれば木になります。JavaScript や Python のジェネレーターはこれができません（消費すると元の状態が失われます）。[イテレーターのクローンもどき](https://qiita.com/7shi/items/6575cbb98c5a710a2945)が最初からやり直す回避策を書いているのが、その裏返しです。`Promise`も`resolve`を2回呼べないという点で同様で、[非同期APIをPromiseでラップしてasync/awaitで使う](https://qiita.com/7shi/items/a2bb35f27cd4a56f7bac)が相違点として挙げています。

`callCC`で捕まえた継続は普通の関数値なので、何度でも呼べます。これが「実用上も自前で組んだ方が能力が上」という形で表に出ています。

## 副作用と交互に進む

`ContT r IO`に持ち上げると、各`yield`の間でIOアクションを実行できます。[10 回](https://qiita.com/7shi/items/4408b76624067c17e933)のモナドスタックの要領で`Cont`に`m`（ここでは`IO`）が挟まります。

```hs
import Control.Monad.Trans.Cont (ContT, evalContT, callCC)
import Control.Monad.IO.Class (liftIO)

data Gen a = Done | Yield a (ContT (Gen a) IO (Gen a))

type GenM a = ContT (Gen a) IO
type Out a = Gen a -> GenM a ()

-- yield の定義は純粋版と 1 文字も変わらない
yield :: Out a -> a -> GenM a ()
yield ccOut v = callCC $ \next -> ccOut (Yield v (next ()))

runGen :: (Out a -> GenM a x) -> IO (Gen a)
runGen body = evalContT $ callCC $ \ccOut -> body ccOut >> return Done
```

差分は機械的です。`Cont`が`ContT ... IO`に、`evalCont`が`evalContT`になり、`runGen`の結果が`IO (Gen a)`になります。生産側で`liftIO`を使う必要はありますが、`yield`の定義自体は1文字も変わりません。

※ mtl 2.3 では`Control.Monad.Cont`が`liftIO`を再輸出しないため、`Control.Monad.IO.Class`から明示的にimportする必要があります。

```hs
noisy :: IO (Gen Int)
noisy = runGen $ \ccOut ->
    let y n = do
            liftIO $ putStrLn ("  produce " ++ show n)
            yield ccOut n
    in mapM_ y [1, 2, 3]

main :: IO ()
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

生産側と消費側のIOが期待通り交互に実行されています。

### 遅延がなくなる

ここが(b)の本当の見せ場です。純粋版では`take 5 (toList nats)`が遅延評価のおかげでそのまま動きました。無限のジェネレーターでも、必要な分だけ計算されるからです。

`ContT r IO`では`toList`が`IO [a]`になるため、この遅延は効きません。無限のジェネレーターを打ち切るドライバーを自分で書く必要があります。しかも素朴に書くと、判断する前に1回余分に再開してしまいます。

```hs
takeIOEager :: Int -> Gen a -> IO [a]
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
takeIO :: Int -> Gen a -> IO [a]
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

ここまでの例はどれも遅延リストで書き直せます。`[1,2,3]`、`[0 ..]`、`map (^ 2) [1 .. 5]`はもちろん、一般の状態機械も`unfoldr`（`Just (値, 次の状態)`が`yield`に相当）で表現できます。生産専用版で`toList`が書けたのも、双方向版で`feed`が既存のリスト関数に潰せたのも、この裏返しです。

ではどこからがリストで素直に書けなくなるのでしょうか。正確な境界は「双方向のジェネレーターに、出力を見てから次の入力をIOで決めるループ」を組み合わせたところです。(a) と (b) をそのまま組み合わせます。

```hs
data Gen i o = Done | Yield o (i -> ContT (Gen i o) IO (Gen i o))
type GenM i o = ContT (Gen i o) IO
type Out i o = Gen i o -> GenM i o i

-- 純粋な双方向版と yield の定義は同一
yield :: Out i o -> o -> GenM i o i
yield ccOut v = callCC $ \next -> ccOut (Yield v next)

runGen :: (Out i o -> GenM i o x) -> IO (Gen i o)
runGen body = evalContT $ callCC $ \ccOut -> body ccOut >> return Done

-- 出力を見てから次の入力を IO で決めるドライバー
drive :: (o -> IO (Maybe i)) -> Gen i o -> IO ()
drive _ Done = return ()
drive f (Yield v next) = do
    mi <- f v
    case mi of
        Nothing -> return ()
        Just i -> evalContT (next i) >>= drive f
```

```hs
accum :: IO (Gen Int Int)
accum = runGen $ \ccOut ->
    let loop s = do
            liftIO $ putStrLn ("  [gen] total = " ++ show s)
            x <- yield ccOut s
            loop (s + x)
    in loop 0

main :: IO ()
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

出力を見てから次の入力をIOで決める、というループはリストでは（遅延させても）書けません。

ただし「リストでは書けない」と言い切ってしまうのは正確ではありません。先ほど見たように`Haskell 1.0`はこれを遅延リストの**knot-tying**で実現していました。`~`（遅延パターン）に頼った書き方で、壊れやすく、最終的にHaskellはこれを試した上で捨てました。

正確な線引きはこうなります。**「リストでも書けるが、遅延に頼ったknot-tyingが要り、Haskellはそれを試して捨てた」。** これは思弁ではなく史実です。継続モナドによるコルーチンは、Haskellがかつて遅延リストで実現していたものを、副作用を明示するモナドの形で作り直したものだと言えます。

# 実用: リソース管理

ここまでは原理を通すことを優先してきましたが、`ContT`は実用でも使われています。ここで実用面を回収します。

## withFileとContTの型が一致する

`withFile path mode`を部分適用すると`(Handle -> IO r) -> IO r`という型になります。これは`ContT r IO Handle`の中身そのものです。

```hs:ネスト
withFile src ReadMode $ \hSrc ->
    withFile dest WriteMode $ \hDest -> do
        content <- hGetContents hSrc
        hPutStr hDest content
```

```hs:ContT
copyFile :: FilePath -> FilePath -> ContT r IO ()
copyFile src dest = do
    hSrc  <- ContT $ withFile src  ReadMode
    hDest <- ContT $ withFile dest WriteMode
    content <- liftIO $ hGetContents hSrc
    liftIO $ hPutStr hDest content

main :: IO ()
main = evalContT $ copyFile "a.txt" "b.txt"
```

`ContT`で包むだけで、ネストしていた`with`系の呼び出しが`do`の1行ずつに平坦になります。「継続を保持できるモナド」である`Cont r a`（`(a -> r) -> r`）が、標準ライブラリの`with`系関数とまったく同じ形をしていた、という形で構成案2の話が回収できます。

※ 例外時にもリソースが解放される仕組み（`bracket`・`finally`）が`withFile`の内部で使われていますが、詳細には立ち入りません。

`Python`の`with`（`@contextmanager`）も同じ形をしています。`yield`の位置で`with`の本体（＝継続）が実行される、という作りは、ここまで作ってきたジェネレーターの`yield`と同じ仕組みです。コルーチンとリソース管理は、別の応用ではなく同じ仕組みの言い換えです。

## forMが効く

ファイルを1つコピーするだけならネストのままでも大差ありませんが、複数のファイルを開こうとすると差が出ます。`with`系のままではリストに対する明示的な再帰が必要になりますが、`ContT`なら`forM`が使えます。

```hs
import Control.Monad (forM)

openAll :: [FilePath] -> ContT r IO [Handle]
openAll paths = forM paths $ \p -> ContT $ withFile p ReadMode

main :: IO ()
main = evalContT $ do
    hs <- openAll ["a.txt", "b.txt", "c.txt"]
    liftIO $ mapM_ (\h -> hGetContents h >>= putStr) hs
```

「モナドにすると既存のコンビネーターが効く」というジェネレーターの`mapM_`・`take`と同じ構図が、実用の場面でも鳴っています。

## 解放の順序と注意点

解放は取得の逆順（LIFO）になり、ネストで書いた場合と同じ順序になります。

```text:実行結果
open  A
open  B
use AB
close B
close A
```

`callCC`で途中脱出しても、後片付けはきちんと走ります。

```hs
escape :: IO ()
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

脱出以降で取得するはずだったリソース（B）はそもそも取得されないため、Aの解放だけがきちんと走ります。

注意点が一つあります。`hGetContents`の結果を`ContT`の外へ持ち出すと、ハンドルが閉じた後に読むことになってエラーになります。

```text:エラー
Left a.txt: hGetContents: illegal operation (delayed read on closed handle)
```

`with`系全般に共通する罠ですが、`ContT`では「どこでリソースが閉じるか」が`do`の見た目から消えるため、特に踏みやすくなっています。副作用が付いた瞬間に遅延の前提が壊れるという構図は、ジェネレーターの節で見た「純粋なら遅延が吸収するが、副作用が付くと露出する」の再演です。

`ContT`によるリソース管理の入り方は、以下の記事を参考にしました。`forM`が効くという論点は特に強く、そのまま取り込みました。

* [Haskellでリソースの管理を継続モナドで行う](https://qiita.com/tanakh/items/81fc1a0d9ae0af3865cb)
* [継続モナド(ContT)のリソース管理活用](https://qiita.com/sparklingbaby/items/2eacabb4be93b9b64755)

# まとめ

`m >>= k`の`k`という、これまで`>>=`の中に隠れていた継続を、`Cont r a`というモナドの中に保持できる値として取り出しました。取り出せることから3つの自由（呼ばない・後で呼ぶ・何度も呼ぶ）が生まれ、それぞれが早期脱出（`callCC`）・ジェネレーター・分岐するジェネレーターという形で実現できることを見ました。

応用として実装したコルーチンは、リストで素直に書ける範囲を丁寧に確認しながら進めることで、「リストでは書けない」という言い切りではなく「リストでも遅延に頼ったknot-tyingなら書けるが、Haskellはそれを実際に試して捨てた」という史実に基づいた線引きにたどり着きました。最後に見た`ContT`によるリソース管理は、原理としては同じ仕組みが実用の場面でどう使われているかの実例です。
