---
coediting: false
comments_count: 0
created_at: '2026-08-09T00:00:00+09:00'
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
- name: Effモナド
  versions: []
- name: effectful
  versions: []
title: Haskell Effモナド 超入門
updated_at: ''
url: ''
slide: false
---

Eff モナドは、複数の効果を混ぜられるよう命令の型を型レベルのリストとして持ちます。モナド変換子でモナドを積み重ねていた役割を置き換えます。実装の変遷を反映して 2 通りの方式を説明します。

:::message
本記事の執筆には Claude Code (Opus 5) を利用しました。
:::

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
1. [Haskell 継続モナド 超入門](https://zenn.dev/7shi/articles/20260803-haskell-continuation-monad)
1. [Haskell 型クラス 超入門](https://zenn.dev/7shi/articles/20260805-haskell-type-classes)
1. [Haskell モナドとゆかいな仲間たち](https://zenn.dev/7shi/articles/20260807-haskell-monads-and-friends)
1. [Haskell Freeモナド 超入門](https://zenn.dev/7shi/articles/20260808-haskell-free-monad)
1. [Haskell Operationalモナド 超入門](https://zenn.dev/7shi/articles/20260809-haskell-operational-monad)
1. **Haskell Effモナド 超入門** ← この記事
1. 【予定】Haskell アロー 超入門

# Free モナドから拡張可能な効果へ

前々回・前回は、命令を並べた手順書をデータとして組み立て、後からインタープリターで解釈するという枠組みを扱ってきました。Free モナドは続きを命令の型の中に持ち、Operational モナドは続きを `>>=` の側に持ちます。👉[Freeモナド](https://zenn.dev/7shi/articles/20260808-haskell-free-monad#%E5%91%BD%E4%BB%A4%E3%81%AE%E5%9E%8B) 👉[Operationalモナド](https://zenn.dev/7shi/articles/20260809-haskell-operational-monad#%E7%B6%9A%E3%81%8D%E3%82%92%E5%91%BD%E4%BB%A4%E3%81%AE%E5%9E%8B%E3%81%8B%E3%82%89%E5%A4%96%E3%81%99)

どちらも命令の型は 1 つでした。テレタイプの手順書にはテレタイプの命令しか置けません。

命令の型がまとまってひとかたまりの機能になったものを**効果**（effect）と呼びます。Free モナドの系譜は、当初から複数の効果を混ぜる方向へ発展してきており、行き着く先はモナド変換子が担ってきた役割の置き換えです。今回はその発展をたどります。

## 発展の系譜

この枠組みは、複数の命令の型を混ぜる方向へ発展してきました。

|年|出来事|寄与|
|---|---|---|
|2008|Swierstra "Data types à la carte"|複数の命令の型を 1 つの型に合成する手法。この系譜の出発点|
|2010|Apfelmus「The Operational Monad Tutorial」|続きを `>>=` の側に持たせる方式（前回の主題）|
|2013|Kiselyov, Sabry, & Swords "Extensible Effects: An Alternative to Monad Transformers"|複数の効果を混ぜる枠組みとして体系化。土台は Free で、命令の型に `Functor` を要求していた|
|2015|Kiselyov & Ishii "Freer Monads, More Extensible Effects"|土台を Freer に差し替え。`Functor` インスタンスが不要になった|

書誌は最後の参考に挙げます。

2015 年の論文の題にある Freer は、前回の Operational と基本的に同じ方式を指す名前です。👉[Operationalモナド](https://zenn.dev/7shi/articles/20260809-haskell-operational-monad#%E7%B6%9A%E3%81%8D%E3%82%92%E5%91%BD%E4%BB%A4%E3%81%AE%E5%9E%8B%E3%81%8B%E3%82%89%E5%A4%96%E3%81%99)

`Program instr a` における `instr` を複数に拡張することで、拡張可能な効果（extensible effects）にたどり着きます。

## モナド変換子への対案

従来、別種のモナドを組み合わせる手段としては、モナド変換子が用いられてきました。👉[モナド変換子](https://qiita.com/7shi/items/4408b76624067c17e933#%E3%83%A2%E3%83%8A%E3%83%89%E5%A4%89%E6%8F%9B%E5%AD%90)

`State` と `IO` を一緒に使いたければ `StateT Int IO` のように型を積み、内側のアクションは `lift` で持ち上げます。積んだ型のことをモナドスタックと呼びました。👉[モナド変換子](https://qiita.com/7shi/items/4408b76624067c17e933#%E3%83%A2%E3%83%8A%E3%83%89%E3%82%B9%E3%82%BF%E3%83%83%E3%82%AF)

前々回・前回は「組み立てと解釈の分離」という観点で Free と Operational を見てきましたが、Free モナドから始まった発展の系譜は、モナドスタックの置き換えに向かっていたわけです。

# 複数の効果を混ぜる

ここからは実装に入り、複数の効果を混ぜるための仕組みを組み立てていきます。

## 混ぜられない手順書

前回の `Program instr a` の `instr` は 1 つの型しか受け取れないため、複数の効果を混ぜることはできません。👉[Operationalモナド](https://zenn.dev/7shi/articles/20260809-haskell-operational-monad#%E7%B6%9A%E3%81%8D%E3%82%92%E5%91%BD%E4%BB%A4%E3%81%AE%E5%9E%8B%E3%81%8B%E3%82%89%E5%A4%96%E3%81%99)

前回のテレタイプ（`Teletype`）を使って確かめます。👉[Operationalモナド](https://zenn.dev/7shi/articles/20260809-haskell-operational-monad#%E3%81%BE%E3%81%A8%E3%82%81)

これに加えて、通し番号を返す命令（`Counter`）を新たに用意します。命令は手順書を構成するデータなので、Counter 自体に副作用はありません。

```hs
data Teletype a where
    PutLine :: String -> Teletype ()
    GetLine ::           Teletype String

data Counter a where
    Tick :: Counter Int
```

`Teletype` と `Counter` は別々の命令の型です。実際に `Program Teletype` の手順書に `Counter` の命令 `Tick` を混ぜようとすると、型エラーになります。

```hs
greet :: Program Teletype ()
greet = do
    putLine "name?"
    name <- getLine'
    n <- tick         -- エラー: Tick は Teletype の命令ではない
    putLine ("Hello, " ++ name ++ "! " ++ show n)
```

`instr` が 1 つに固定されているのが原因なので、ここをリストにします。`Teletype` と `Counter` を両方使う手順書、と書けるようにするわけです。そのために、まず型のレベルでリストを扱う方法が必要になります。

## 型レベルのリスト

`[1, 2, 3]` は値のリストです。同じ書き方で `[Teletype, Counter]` のように型を並べたものを、型として扱えるようにするのが `DataKinds` という言語拡張です。

```hs:言語拡張
{-# LANGUAGE DataKinds #-}
```

型のレベルでリストを書くときは、値のリストと区別するために先頭にクォート `'` を付けます。

```hs
'[Teletype, Counter]
```

要素を 1 つ足すコンス演算子も、値の `:` に対して `':` になります。値のリストで `1 : [2, 3]` と書くのと同じ関係です。

```hs
Teletype ': '[Counter]  -- '[Teletype, Counter] と同じ
```

GHCi では `:set` で言語拡張を有効にできます。種を確認します。👉[Freeモナド](https://zenn.dev/7shi/articles/20260808-haskell-free-monad#%E7%A8%AE)

```text:GHCi
ghci> :set -XDataKinds
ghci> :k Teletype
Teletype :: * -> *
ghci> :k '[Teletype, Counter]
'[Teletype, Counter] :: [* -> *]
```

`Teletype` は型を 1 つ受け取って型になるので種が `* -> *` です。それを並べたリストの種は `[* -> *]` になります。角括弧が値のリストではなく種に付いている点が目印です。

:::message
`DataKinds` を有効にしないと、型の位置にリストを書いた時点でエラーになります。

```text:GHCi
ghci> :k '[Teletype, Counter]
Illegal type: ‘'[Teletype, Counter]’
  Perhaps you intended to use DataKinds
```

拡張の名前は「データ（値）を種に持ち上げる」という意味です。値のリストの書き方が、そのまま型のレベルで使えるようになります。
:::

今回はリストが書ければ十分なので、型レベルの計算には踏み込みません。

## 手順書に複数の命令を混ぜる

`Program instr a` における `instr` の型を、「リスト `es` のうちどれか 1 つの命令」を表す型に差し替えます。このような型を**オープンユニオン**（open union）と呼びます。ユニオンは和、オープンは要素を後から足せることを指します。

```hs
data Union es a where
    Here  :: e a -> Union (e ': es) a
    There :: Union es a -> Union (e ': es) a
```

GADT で書いています。前回と同じく、コンストラクターごとに戻り値の型を宣言する構文です。👉[Operationalモナド](https://zenn.dev/7shi/articles/20260809-haskell-operational-monad#%E5%91%BD%E4%BB%A4%E3%81%AE%E5%9E%8B%E3%82%92-gadt-%E3%81%A7%E4%B8%A6%E3%81%B9%E3%82%8B)

- `Here` はリストの先頭の型 `e` の命令をそのまま包みます。
- `There` は先頭以外のどこかにある命令を包みます。中身は 1 つ短いリストのユニオンです。

`'[Teletype, Counter]` なら、`Tick :: Counter Int` は 2 番目なので `There (Here Tick)` になります。値としては、包んだ `There` の数が位置を表しています。

## 型クラスで位置を隠す

`There (Here Tick)` のように手で書くのは現実的ではありません。効果をリストのどこに置いたかを、使う側が数えることになるからです。位置の計算は型クラスに任せます。

```hs
{-# LANGUAGE MultiParamTypeClasses #-}

class e :> es where
    inj :: e a -> Union es a
```

`class e :> es where` は中置（infix）のクラス宣言で、`class (:>) e es where` の糖衣構文です。`:>` がクラス名で、`e` と `es` が型変数にあたります。前回 `:>>=` のところで見たように、演算子を名前にするときは `:` で始める決まりがあります。👉[Operationalモナド](https://zenn.dev/7shi/articles/20260809-haskell-operational-monad#%E7%B6%9A%E3%81%8D%E3%82%92%E5%91%BD%E4%BB%A4%E3%81%AE%E5%9E%8B%E3%81%8B%E3%82%89%E5%A4%96%E3%81%99)

中置のクラス宣言には `TypeOperators` という拡張が必要ですが、GHC2021 に含まれているのでプラグマは不要です。標準の型クラスは型変数 1 つに限られるため、型変数を 2 つ取るには `MultiParamTypeClasses` が必要です。

`e :> es` は「効果 `e` がリスト `es` に含まれる」と読みます。`inj` は inject（注入）の略で、命令を然るべき位置に包む関数です。

インスタンスは 2 本です。先頭で見つかったらそこで止め、そうでなければ 1 つ潜って探し直します。リストに対する再帰と同じ形が、型クラスの解決として動きます。

```hs
{-# LANGUAGE FlexibleInstances #-}

instance {-# OVERLAPPING #-} e :> (e ': es) where
    inj = Here

instance {-# OVERLAPPABLE #-} e :> es => e :> (e' ': es) where
    inj = There . inj
```

`e :> (e ': es)` と `e :> (e' ': es)` は、`e'` が `e` と同じ場合に両方あてはまります。どちらを選ぶかをコンパイラが決められないので、そのままでは「Overlapping instances」というエラーになります。`{-# OVERLAPPING #-}` を付けた方を優先し、`{-# OVERLAPPABLE #-}` を付けた方は譲る、と指示することで、先頭を優先して選ばせています。

インスタンスの頭に `e ': es` のような具体的な型を書くことも標準では許されていないので、`FlexibleInstances` が必要です。

# Eff モナド

`Program` の `instr` を `Union es` に差し替えます。名前は effect（効果）に由来する `Eff` とします。

```hs
data Eff es a where
    Return :: a -> Eff es a
    (:>>=) :: Union es b -> (b -> Eff es a) -> Eff es a
```

前回の宣言と並べると、`Program`/`instr` を `Eff`/`es` に読み替えた名前の違いを除けば、変わったのは `instr` が `Union es` になった 1 か所だけです。

```hs
(:>>=) :: instr b    -> (b -> Program instr a) -> Program instr a  -- 前回
(:>>=) :: Union es b -> (b -> Eff es a)        -> Eff es a         -- 今回
```

3 段のインスタンスも前回のままです。👉[Operationalモナド](https://zenn.dev/7shi/articles/20260809-haskell-operational-monad#%E7%B6%9A%E3%81%8D%E3%82%92%E5%91%BD%E4%BB%A4%E3%81%AE%E5%9E%8B%E3%81%8B%E3%82%89%E5%A4%96%E3%81%99)

```hs
import Control.Monad (ap, liftM)

instance Functor (Eff es) where
    fmap = liftM

instance Applicative (Eff es) where
    pure = Return
    (<*>) = ap

instance Monad (Eff es) where
    Return a   >>= k = k a
    (u :>>= j) >>= k = u :>>= (\b -> j b >>= k)
```

前回 `singleton` だった関数は、`inj` で包む一手が増えて `send` になります。名前も、命令を効果システムへ送り出すという意味の `send` が慣例です。

```hs
send :: e :> es => e a -> Eff es a
send e = inj e :>>= Return
```

型に付いた `e :> es` が要点です。「`e` がリストのどこかにあれば使える」という書き方なので、位置も、リストの残りに何が入っているかも指定していません。

## 効果を 2 つ書く

命令の型は、さきほど書いた `Teletype` と `Counter` をそのまま使います。前回と同じ、GADT で戻り値の型を並べるだけの書き方です。手順書の側が変わっただけなので、命令の側は書き換えずに済みます。

スマートコンストラクターは `send` を使います。型には `:>` の制約だけを書きます。

```hs
putLine :: Teletype :> es => String -> Eff es ()
putLine s = send (PutLine s)

getLine' :: Teletype :> es => Eff es String
getLine' = send GetLine

tick :: Counter :> es => Eff es Int
tick = send Tick
```

これで手順書に両方の命令を置けます。使う効果を制約として並べるだけです。

```hs
greet :: (Teletype :> es, Counter :> es) => Eff es ()
greet = do
    putLine "name?"
    name <- getLine'
    n <- tick
    putLine ("Hello, " ++ name ++ "! " ++ show n)
```

`es` が具体的なリストではなく型変数のままである点に注目してください。`greet` は「テレタイプとカウンターが入っていればどんなリストでもよい」手順書です。`greet` 自身が使う効果を増やすなら制約の追加が要りますが、他の効果を使う手順書と組み合わせて `es` にその効果が加わるだけなら、`greet` の型はそのまま使えます。

## ハンドラー

インタープリター側を書きます。前回は手順書を最後まで解釈して結果を返す 1 つの関数でしたが、効果が複数ある今回はそうはいきません。全体の流れは、手順書を先頭から 1 コマンドずつ見て、自分が担当する効果ならその場で処理し、そうでなければ次のハンドラーへそのまま渡す、という中継です。効果を 1 つだけ取り除くインタープリターを**ハンドラー**（handler）と呼びます。

今回、`Teletype` は `IO` で文字列の入出力を処理します。他のハンドラー（`Counter`）は `Eff es a -> Eff es' a` という、`Eff` の世界に留まる型をしていますが、`IO` へ変換するハンドラーだけは `Eff ... a -> IO a` と、返す型が `Eff` ではなく `IO` です。一度 `IO` に変換してしまうと、そこから先は `Eff` を受け取るハンドラーに渡せなくなります。つまり、`IO` へ変換するハンドラーは常に一番外側（最後に適用するもの）になります。`Counter` はそれより手前に置いて「担当外なら次へ渡す」形のハンドラーになります。

まず、途中で素通しする方のハンドラーから見ます。型で見ると、リストの先頭の効果が消えます。

```hs
runCounter :: Int -> Eff (Counter ': es) a -> Eff es a
```

中身は、自分宛（`Here`）の命令を処理し、他人宛（`There`）はそのまま素通しします。

```hs
runCounter _ (Return a) = Return a
runCounter n (u :>>= k) = case u of
    Here Tick -> runCounter (n + 1) (k n)
    There u'  -> u' :>>= (runCounter n . k)
```

`Here Tick` の枝では、現在の値 `n` を続きに渡し、カウンターを 1 つ進めて先へ進みます。`There u'` の枝では、`u'` が 1 つ短いリストのユニオンになっているので、それを `:>>=` で組み直して手順書として返します。素通しした命令は、後から適用される別のハンドラーが受け取ります。

`n` を引数として持ち回り、更新した値を次の再帰呼び出しに渡すこの形は、`State` モナドが「現在の状態を受け取り、更新した状態を次に渡す」のと同じ動きです。`Counter` 専用の状態を、`runCounter` が手作業の再帰で持ち回っている、と見ることができます。

テレタイプの方は、途中で素通しするのではなく、本物の `IO` で処理して鎖を終わらせる方です。リストが `'[Teletype]` だけになった状態、つまり上で触れたとおり最後に適用するハンドラー専用の型になります。

```hs
runTeletype :: Eff '[Teletype] a -> IO a
runTeletype (Return a) = return a
runTeletype (u :>>= k) = case u of
    Here (PutLine s) -> putStrLn s >> runTeletype (k ())
    Here GetLine     -> getLine >>= runTeletype . k
    There u'         -> case u' of {}
```

最後の行は見慣れない書き方です。`There u'` の `u'` は `Union '[] a` ですが、`Here` も `There` も空でないリストを要求するので、この型の値は作れません。値が存在しない型に対する `case` は、枝を 1 つも書かずに `case u' of {}` と書けます。

:::message
枝が空の `case` は `EmptyCase` という拡張ですが、これは GHC2021 に含まれているので、プラグマを書かなくてもそのまま使えます。
:::

「ここには来ない」と `error` で書く代わりに、来ないことを型で示した形です。

:::message
`There u' -> error "unreachable"` と書いても型は通り、実際に来ない以上は動作も変わりません。`error :: String -> a` も、どんな型 `a` にもなれる式だからです。ただし、これは「来ないはずだ」というプログラマーの主張を GHC がそのまま信じているだけで、検証はされていません。将来コードを書き換えてこの枝に実際に来るようになっても、コンパイルは通ったまま、実行時に初めて失敗します。`case u' of {}` は、`u'` の型に値が存在しないことを GHC 自身が確認した上で枝 0 個を認めているので、そもそもこの枝に来る値を作ることが型として不可能です。「来ないと信じて実行時に賭ける」書き方と「来られないことを型で証明する」書き方の違いです。
:::

## 動かす

ハンドラーを内側から順に適用します。

```hs
main = runTeletype (runCounter 0 greet)
```
```text:実行結果（標準入力: alice）
name?
Hello, alice! 0
```

`greet` の型は `(Teletype :> es, Counter :> es) => Eff es ()` でした。`runCounter 0 greet` と書いた時点で `es` が `Counter ': es'` に決まり、続けて `runTeletype` を適用したことで `es'` が `'[]` に決まります。結果として `es` は `'[Counter, Teletype]` です。手順書の側にリストを書かなくても、適用したハンドラーの並びから決まります。

必要な言語拡張をまとめておきます。`GADTs` は前回導入したので、新しく増えるのは `DataKinds` と、`:>` を定義するための 2 つです。

```hs
{-# LANGUAGE GADTs #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
```

## 練習

【問1】3 つ目の効果として、文字列を記録する `Logger` を足してください。命令は `Log` の 1 つで、記録した文字列をリストで集めるハンドラー `runLogger` を書きます。ハンドラーが結果の型を変えている点が `runCounter` と違います。

```hs
data Logger a where
    Log :: String -> Logger ()

logMsg :: Logger :> es => String -> Eff es ()
logMsg = undefined     -- ここを書く

runLogger :: Eff (Logger ': es) a -> Eff es (a, [String])
runLogger = undefined  -- ここを書く

greet :: (Teletype :> es, Counter :> es, Logger :> es) => Eff es ()
greet = do
    putLine "name?"
    name <- getLine'
    logMsg ("got " ++ name)
    n <- tick
    logMsg ("tick " ++ show n)
    putLine ("Hello, " ++ name ++ "! " ++ show n)

main = do
    ((), logs) <- runTeletype (runCounter 0 (runLogger greet))
    mapM_ putStrLn logs
```
```text:実行結果（標準入力: alice）
name?
Hello, alice! 0
got alice
tick 0
```

:::details 解答例
```hs
logMsg :: Logger :> es => String -> Eff es ()
logMsg s = send (Log s)

runLogger :: Eff (Logger ': es) a -> Eff es (a, [String])
runLogger (Return a) = Return (a, [])
runLogger (u :>>= k) = case u of
    Here (Log s) -> do
        (a, ls) <- runLogger (k ())
        return (a, s : ls)
    There u'     -> u' :>>= (runLogger . k)
```

`Here (Log s)` の枝では、続きを先に処理してから、その結果のリストの先頭に `s` を足しています。素通しの `There u'` の枝は `runCounter` とまったく同じ形です。

`greet` の宣言に足したのは `Logger :> es` という制約 1 つだけで、既に書いてある `putLine` や `tick` には手を入れていません。効果を足すのがリストへの追加で済む、というのがこの形の効きどころです。
:::

# Eff の別実装

ここまでは、前回の手順書を素直に拡張してきました。命令はデータとして組み立てられ、ハンドラーがそれを辿ります。

ところが、ここまでに書いた型と関数の顔ぶれ、つまり `Eff es a`・`e :> es`・`send`・ハンドラーの型は、中身を丸ごと差し替えても成立します。それを実際にやってみます。

## 手順書をやめる

`Eff` を、データではなく関数にします。受け取るのは、効果のリストと同じ長さのハンドラーの列です。

```hs
newtype Eff es a = Eff { unEff :: Env es -> IO a }

data Env es where
    ENil  :: Env '[]
    ECons :: (forall x. e x -> IO x) -> Env es -> Env (e ': es)
```

`Env es` が、リストの各効果に対応するハンドラーを並べたものです。`ECons` の第 1 引数がハンドラー 1 つで、「命令を受け取って `IO` を返す関数」になっています。

`forall x.` が付いているのは、1 つのハンドラーが `PutLine :: Teletype ()` と `GetLine :: Teletype String` の両方に使えなければならないからです。前回 `interpretWithMonad` の型で出てきたのと同じ事情です。👉[Operationalモナド](https://zenn.dev/7shi/articles/20260809-haskell-operational-monad#operational-%E3%83%91%E3%83%83%E3%82%B1%E3%83%BC%E3%82%B8)

`Eff` の中身が関数になったので、3 段のインスタンスは定型ではなく手で書きます。どれも「環境を配って回る」だけです。

```hs
instance Functor (Eff es) where
    fmap f (Eff m) = Eff $ fmap f . m

instance Applicative (Eff es) where
    pure = Eff . const . pure
    Eff f <*> Eff x = Eff $ \env -> f env <*> x env

instance Monad (Eff es) where
    Eff m >>= k = Eff $ \env -> m env >>= \a -> unEff (k a) env
```

`>>=` は、環境 `env` を両側に渡しているだけです。前の実装では命令をデータとしてつなぎ替えていましたが、ここには命令が出てきません。

## 環境から引く

`:>` は同じ名前・同じ役割ですが、メソッドが変わります。位置を数えて `Union` を作る代わりに、環境から該当するハンドラーを取り出します。インスタンスの構造は前と同じです。

```hs
class e :> es where
    handler :: Env es -> (forall x. e x -> IO x)

instance {-# OVERLAPPING #-} e :> (e ': es) where
    handler (ECons h _) = h

instance {-# OVERLAPPABLE #-} e :> es => e :> (e' ': es) where
    handler (ECons _ r) = handler r
```

`send` の型は前の実装とまったく同じですが、中身は劇的に変わります。

```hs
send :: e :> es => e a -> Eff es a
send op = Eff $ \env -> handler env op
```

命令をデータにせず、その場でハンドラーを引いて実行しています。組み立てるものが何もありません。

ハンドラーを作る側は、環境を 1 つ伸ばす関数になります。

```hs
interpret :: (forall x. e x -> Eff es x) -> Eff (e ': es) a -> Eff es a
interpret f (Eff m) = Eff $ \env -> m (ECons (\op -> unEff (f op) env) env)
```

`Eff (e ': es) a` を受け取って `Eff es a` を返す、という型は前の実装のハンドラーと同じです。中身は「渡された `f` をハンドラーとして環境に積み、内側を走らせる」になりました。

最後に、空のリストまで剥がしたものを走らせます。環境が空なので `ENil` を渡すだけです。

```hs
run :: Eff '[] a -> IO a
run (Eff m) = m ENil
```

## 効果は書き換えない

効果の定義とスマートコンストラクターは、1 文字も変わりません。`greet` もそのままです。

```hs
data Teletype a where
    PutLine :: String -> Teletype ()
    GetLine ::           Teletype String

data Counter a where
    Tick :: Counter Int

putLine :: Teletype :> es => String -> Eff es ()
putLine s = send (PutLine s)

getLine' :: Teletype :> es => Eff es String
getLine' = send GetLine

tick :: Counter :> es => Eff es Int
tick = send Tick

greet :: (Teletype :> es, Counter :> es) => Eff es ()
greet = do
    putLine "name?"
    name <- getLine'
    n <- tick
    putLine ("Hello, " ++ name ++ "! " ++ show n)
```

ハンドラーは `interpret` で書きます。テレタイプは命令を `IO` に写すだけです。

```hs
runTeletype :: Eff (Teletype ': es) a -> Eff es a
runTeletype = interpret $ \op -> Eff $ \_ -> case op of
    PutLine s -> putStrLn s
    GetLine   -> getLine
```

カウンターは状態を持ちます。前の実装ではハンドラーの引数として持ち回っていましたが、ここでは辿るという動作自体がないので、置き場所がありません。`IORef` を使います。👉[状態系モナド](https://qiita.com/7shi/items/2e9bff5d88302de1a9e9#%E7%A0%B4%E5%A3%8A%E7%9A%84%E4%BB%A3%E5%85%A5)

```hs
import Data.IORef

runCounter :: Int -> Eff (Counter ': es) a -> Eff es a
runCounter n0 m = do
    r <- Eff $ \_ -> newIORef n0
    interpret (\Tick -> Eff $ \_ -> do
        n <- readIORef r
        writeIORef r (n + 1)
        return n) m
```

走らせ方だけ、最後に `run` が要ります。

```hs
main = run (runTeletype (runCounter 0 greet))
```
```text:実行結果（標準入力: alice）
name?
Hello, alice! 0
```

前の実装と 1 文字も違わない出力です。

## 何が変わったのか

2 つの実装を並べます。

| |手順書（オープンユニオン）|環境（ハンドラーの列）|
|---|---|---|
|`Eff es a` の中身|`Return`／`:>>=` のデータ|`Env es -> IO a` の関数|
|`send`|命令をデータとして置く|環境からハンドラーを引いて即実行|
|ハンドラー|データを辿って剥がす|環境にハンドラーを 1 つ積む|
|状態の持ち方|辿る関数の引数|`IORef`|
|最後に走らせる|`Eff '[Teletype] a -> IO a`|`Eff '[] a -> IO a`|
|追加で要る拡張|なし|`RankNTypes`（`forall x.` のため）|

`Eff es a`・`e :> es`・`send`・ハンドラーの型という表向きの顔は変わっていません。効果の定義も、スマートコンストラクターも、`greet` も共通です。

大きく変わったのは、組み立てと解釈が分離していないことです。前々回・前回で見た「手順書をデータとして組み立て、後から解釈する」という枠組みが、この実装には残っていません。`send` はその場で実行してしまいます。分離は、`Eff` という型と `interpret` という関数の形として残ってはいますが、データ構造としては消えました。

そのため、同じ手順書を複数のインタープリターで使い回すという Free モナドの利点は、こちらでは形を変えます。手順書が残らないので、使い回すのは「効果に対して多相な関数」の方です。`greet` の型が `(Teletype :> es, Counter :> es) => Eff es ()` と `es` について多相なので、どんなハンドラーの組み合わせにも渡せます。本番用と、テスト用のモックと、ログ収集用のハンドラーを差し替える、という使い方はそのまま成立します。

もう 1 つ、`run` の型が `Eff '[] a -> IO a` になったことも実装の都合です。効果を全部剥がしても `IO` が残るのは、この実装が `IO` の上に載っているからです。

この 2 つ目の実装が、次に使うパッケージの骨格になっています。

# effectful パッケージ

実際には、[effectful](https://hackage.haskell.org/package/effectful) パッケージを使います。名前のとおり効果を扱うライブラリで、[`Effectful`](https://hackage.haskell.org/package/effectful-core/docs/Effectful.html) モジュールが入口です。

中心の型は次のように定義されています。

```hs
newtype Eff (es :: [Effect]) a = Eff (Env es -> IO a)
```

前節で自作したものと同じ形です。`Env` の中身は効率のために可変配列になっていますが、「効果のリストと同じ長さのハンドラーの列を受け取る関数」という骨格は変わりません。

## 効果を定義する

自作してきた `Teletype` を、`effectful` の効果に直します。足すのは 2 点だけです。

```hs
data Teletype :: Effect where
    PutLine :: String -> Teletype m ()
    GetLine ::           Teletype m String

type instance DispatchOf Teletype = Dynamic
```

1 点目は、命令の型に `m` という引数が増えたことです。効果の種は `Effect` という別名になっていて、中身は次のとおりです。

```hs
type Effect = (Type -> Type) -> Type -> Type
```

自作版の効果は `Type -> Type`（つまり `* -> *`）でしたが、こちらは引数が 1 つ多くなっています。

:::message
`m` は**高階効果**（higher-order effect）のための引数です。ハンドラーが `Eff` の計算そのものを受け取る効果、たとえば例外を捕まえる `catch` や、環境を局所的に書き換える `local` がこれにあたります。今回のように命令が値だけを受け取る効果では使わないので、`m` はどこにも現れません。
:::

2 点目は、その効果をどう解釈するかの宣言です。`Dynamic` は「ハンドラーを実行時に選ぶ」、つまり自作版と同じく後から与える方式を指します。`Effectful.Dispatch.Dynamic` モジュールを `import` すると使えます。

スマートコンストラクターは `send` です。名前も型も自作版と同じで、効果を要求する制約が `:>` で書けるところまで一致しています。

```hs
putLine :: Teletype :> es => String -> Eff es ()
putLine = send . PutLine

getLine' :: Teletype :> es => Eff es String
getLine' = send GetLine
```

ハンドラーは `interpret_` で作ります。自作版の `interpret` と同じ位置づけです。

```hs
runTeletypeIO :: IOE :> es => Eff (Teletype : es) a -> Eff es a
runTeletypeIO = interpret_ $ \op -> case op of
    PutLine s -> liftIO $ putStrLn s
    GetLine   -> liftIO getLine
```

`IOE` は `IO` を使えることを表す効果です。`liftIO` で `IO` アクションを持ち上げるところは、モナド変換子のときと同じ書き方になります。👉[モナド変換子](https://qiita.com/7shi/items/4408b76624067c17e933#liftio)

:::message
`interpret_` の末尾のアンダースコアは、高階効果向けの引数を省いた版であることを表します。`interpret` の方はハンドラーの第 1 引数に `LocalEnv` を取りますが、今回のような効果では使わないので `interpret_` が便利です。
:::

## 既製の効果

`State`・`Writer`・`Reader`・`Error` といったおなじみの顔ぶれが、効果として用意されています。👉[状態系モナド](https://qiita.com/7shi/items/2e9bff5d88302de1a9e9#%E7%8A%B6%E6%85%8B%E7%B3%BB%E3%83%A2%E3%83%8A%E3%83%89)

`get`・`put`・`modify`・`tell`・`ask` といった関数の名前も同じなので、書き味はほとんど変わりません。

:::message
既製の効果はモジュール名が分岐しています。`State` なら `Effectful.State.Static.Local`・`Effectful.State.Static.Shared`・`Effectful.State.Dynamic` があり、状態をスレッドごとに持つか共有するか、ハンドラーを差し替え可能にするかで選びます。

本記事では `Effectful.State.Static.Local` を使います。`Static` は解釈が固定されていることを、`Local` はスレッドローカルであることを表します。
:::

`Teletype` と `State` を混ぜた例です。

```hs
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE TypeFamilies #-}
import Effectful
import Effectful.Dispatch.Dynamic
import Effectful.State.Static.Local

data Teletype :: Effect where
    PutLine :: String -> Teletype m ()
    GetLine ::           Teletype m String

type instance DispatchOf Teletype = Dynamic

putLine :: Teletype :> es => String -> Eff es ()
putLine = send . PutLine

getLine' :: Teletype :> es => Eff es String
getLine' = send GetLine

runTeletypeIO :: IOE :> es => Eff (Teletype : es) a -> Eff es a
runTeletypeIO = interpret_ $ \op -> case op of
    PutLine s -> liftIO $ putStrLn s
    GetLine   -> liftIO getLine

greet :: (Teletype :> es, State Int :> es) => Eff es ()
greet = do
    putLine "name?"
    name <- getLine'
    n <- get
    putLine ("Hello, " ++ name ++ "! (" ++ show (n :: Int) ++ ")")
    put (n + 1)

main :: IO ()
main = do
    ((), s) <- runEff $ runState (0 :: Int) $ runTeletypeIO greet
    print s
```
```text:実行結果（標準入力: alice）
name?
Hello, alice! (0)
1
```

`type instance` を書くので `TypeFamilies` が要ります。型レベルのリストは `DataKinds` のままです。なお `Eff (Teletype : es)` のようにリストの途中では、クォートを省いても型として解釈されるので `':` と書かなくても通ります。

最後に走らせる関数は 2 つあります。

```hs
runEff     :: Eff '[IOE] a -> IO a
runPureEff :: Eff '[] a -> a
```

`IO` を使う手順書は `runEff` で、使わない手順書は `runPureEff` で走らせます。自作版の `run` が `Eff '[] a -> IO a` だったのに対し、`runPureEff` は `IO` が付かない点が違います。実装は `IO` の上で走らせた結果を取り出しているので、型の上で純粋に見せているということです。

:::message
`n <- get` と書いたとき、`n` の型が決まらないことがあります。`get` の型は `State s :> es => Eff es s` で、`s` はリスト `es` から一意には決まりません。上の例で `show (n :: Int)` と書いてあるのはこのためです。使う側で型が決まらなければ、注釈が要ります。
:::

:::message
`effectful` は GHC に同梱されていないため、実行には導入が必要です。[Stack](https://docs.haskellstack.org/) を使う場合は次のように起動できます。

```
stack script --resolver lts-24.53 --package effectful ファイル名.hs
```
:::

# モナド変換子との比較

冒頭で触れたとおり、この枠組みはモナド変換子への対案として作られました。実際に書き比べます。

素材はモナド変換子の回の冒頭に出てきたものです。リストを畳んで合計しつつ、途中経過を表示します。状態と `IO` を両方使うので、`State` だけでは書けませんでした。

```hs
import Control.Monad
import Control.Monad.State

sum' xs = (`execStateT` 0) $ do
    forM_ xs $ \i -> do
        modify (+ i)
        v <- get
        lift $ putStrLn $ "+" ++ show i ++ " -> " ++ show v

main = do
    print =<< sum' [1..5]
```

`StateT` を積み、内側の `putStrLn` を `lift` で持ち上げています。これを `Eff` で書き直します。

```hs
{-# LANGUAGE DataKinds #-}
import Control.Monad
import Effectful
import Effectful.State.Static.Local

sum' :: [Int] -> IO Int
sum' xs = runEff $ execState (0 :: Int) $
    forM_ xs $ \i -> do
        modify (+ i)
        v <- get
        liftIO $ putStrLn $ "+" ++ show i ++ " -> " ++ show (v :: Int)

main = print =<< sum' [1..5]
```
```text:実行結果
+1 -> 1
+2 -> 3
+3 -> 6
+4 -> 10
+5 -> 15
15
```

出力は 1 文字も変わりません。`do` の中身もほぼそのままで、`lift` が `liftIO` になっただけです。

## 持ち上げの回数が消える

この書き換えで効いているのは、`lift` の回数という概念が消えたことです。

モナド変換子では、`lift` はモナドスタックを 1 段だけ登ります。`StateT` の中でさらに `ReaderT` を使えば `lift . lift` が要るし、その部分を関数に切り出して単独で呼ぶと段数が合わなくなってエラーになりました。👉[モナド変換子](https://qiita.com/7shi/items/4408b76624067c17e933#%E5%A4%9A%E9%87%8D%E6%8C%81%E3%81%A1%E4%B8%8A%E3%81%92)

`Eff` にはスタックがないので、この問題自体が起きません。効果はリストに入っているかいないかだけで、深さがありません。`liftIO` も、モナド変換子のときは「深さに関係なく一気に持ち上げる `IO` 専用の関数」でしたが、`Eff` では単に `IOE` の効果を呼ぶ関数です。

効果を足すときの手間も変わります。

|やりたいこと|モナド変換子|Eff|
|---|---|---|
|効果を組み合わせる|型を積む（`StateT Int (WriterT [String] IO)`）|リストに並べる（`State Int :> es`・`Writer [String] :> es`）|
|内側のアクションを使う|`lift`・`lift . lift`・`liftIO`|`liftIO` のみ|
|効果を 1 つ足す|スタックが深くなり `lift` の数が変わる|制約を 1 つ足すだけ|
|新しい効果を作る|変換子とインスタンス群を書く|命令の型を GADT で 1 つ書く|
|走らせる|`runWriterT . runStateT`（型の順に従う）|`runWriter . runState`（順を選べる）|

## ハンドラーの順を選べる

最後の行を確かめます。`State` と `Writer` を使う手順書を書きます。

```hs
{-# LANGUAGE DataKinds #-}
import Effectful
import Effectful.State.Static.Local
import Effectful.Writer.Static.Local

prog :: (State Int :> es, Writer [String] :> es) => Eff es ()
prog = do
    n <- get
    tell ["n = " ++ show (n :: Int)]
    put (n + 1)

main = do
    print $ runPureEff $ runWriter @[String] $ runState (0 :: Int) prog
    print $ runPureEff $ runState (0 :: Int) $ runWriter @[String] prog
```
```text:実行結果
(((),1),["n = 0"])
(((),["n = 0"]),1)
```

同じ `prog` に対して、ハンドラーを 2 通りの順で適用できています。剥がした順にタプルが外側へ積まれるので、結果の入れ子が変わります。

モナド変換子では、`StateT Int (WriterT [String] Identity)` と書いた時点で順が決まり、`runWriterT . runStateT` の順でしか外せませんでした。`Eff` では手順書の型が `(State Int :> es, Writer [String] :> es) => Eff es ()` と順序を含まないので、外す側が決められます。

:::message
`runWriter @[String]` は型適用という書き方で、型引数を直接指定しています。`Writer w` の `w` がリスト `es` から一意に決まらないため、ここで指定する必要があります。`get` の型が決まらなかったのと同じ事情です。
:::

## どちらを使うのか

`mtl` に代表されるモナド変換子は、今も広く使われています。Eff 系がそれを過去のものにしたわけではありません。`effectful` の README も、モナド変換子スタックの置き換えを目指すと述べる一方で、モナド変換子を無用にするつもりはない、と明記しています。

Free から Operational へ進んだときも、優劣ではなく用途の違いでした。👉[Operationalモナド](https://zenn.dev/7shi/articles/20260809-haskell-operational-monad#free-%E3%81%A8-operational-%E3%81%AE%E4%BD%BF%E3%81%84%E5%88%86%E3%81%91)

ここも同じで、別種の効果を組み合わせるという同じ課題に対する、別の解き方が 2 つある、という見方が実情に合っています。

## 練習

【問2】上の `sum'` に `Writer` を足して、途中経過を表示する代わりに記録してください。`IO` を使わなくなるので、`runEff` は `runPureEff` に変わります。

```hs
sum' :: [Int] -> (Int, [String])
sum' xs = undefined  -- ここを書く

main = do
    let (s, logs) = sum' [1..5]
    mapM_ putStrLn logs
    print s
```
```text:実行結果
+1 -> 1
+2 -> 3
+3 -> 6
+4 -> 10
+5 -> 15
15
```

:::details 解答例
```hs
{-# LANGUAGE DataKinds #-}
import Control.Monad
import Effectful
import Effectful.State.Static.Local
import Effectful.Writer.Static.Local

sum' :: [Int] -> (Int, [String])
sum' xs = runPureEff $ runWriter @[String] $ execState (0 :: Int) $
    forM_ xs $ \i -> do
        modify (+ i)
        v <- get
        tell ["+" ++ show i ++ " -> " ++ show (v :: Int)]
```

`liftIO $ putStrLn ...` を `tell [...]` に替え、ハンドラーとして `runWriter` を足しただけです。手順書の側では `Writer` を使うことを宣言する必要すらなく、型は推論に任せています。

`IOE` を使わなくなったので `runEff` が `runPureEff` になり、`sum'` の型から `IO` が消えました。モナド変換子なら `StateT Int IO` を `WriterT [String] (State Int)` に組み替えるところですが、ここではハンドラーを 1 つ足し引きしただけです。
:::

# エフェクトシステムの現在

拡張可能な効果を提供するライブラリは、Haskell に複数あります。標準ライブラリに含まれるものはなく、どれも外部パッケージで、似た機能を別々の名前と方式で提供しています。

`Eff` という型名は `freer-simple`・`effectful`・`cleff` のどれも使っていますが、中身は同じではありません。今回自作した 2 つがそうだったように、型の見え方が一致していても実装は別物です。

一方で `polysemy` だけは型名が `Sem` で、`Eff` ではありません。名前でグループ分けはできない、ということです。

Freer という語も紛らわしいところです。`freer-simple` はモジュール名が `Control.Monad.Freer` ですが、そこから出てくる型は `Eff` だけで、`Freer` という名前の型はありません。前回 Operational の別名として出てきた Freer は、論文とモジュール名に残る呼び名であって、コードには現れなくなっています。👉[Operationalモナド](https://zenn.dev/7shi/articles/20260809-haskell-operational-monad#%E7%B6%9A%E3%81%8D%E3%82%92%E5%91%BD%E4%BB%A4%E3%81%AE%E5%9E%8B%E3%81%8B%E3%82%89%E5%A4%96%E3%81%99)

## 実装の方式で分かれる

中身は方式で分かれます。今回自作した 2 つが、そのまま主要な 2 系統にあたります。

|パッケージ|型|方式|lts-24.53|
|---|---|---|---|
|`freer-simple`|`Eff es`|Freer とオープンユニオン（手順書の実装）|なし|
|`polysemy`|`Sem r`|同上|1.9.2.0|
|`effectful`|`Eff es`|`ReaderT IO` とハンドラーの環境（環境の実装）|2.6.1.0|
|`cleff`|`Eff es`|同上|なし|
|`fused-effects`|キャリア|効果を型クラスで表し、実装を型で選ぶ|1.1.2.7|

`fused-effects` だけは方式が違い、今回自作したどちらにも当てはまりません。

とはいえ型レベルの見え方は、どれもよく似ています。効果のリストがあり、制約で必要な効果を宣言し、ハンドラーを適用して剥がしていきます。今回 2 つの実装で同じ `greet` が動いたのと同じことが、パッケージの間でも起きています。乗り換えるときに書き換えるのはハンドラーの周辺が中心で、手順書の側はあまり変わりません。

## 高階効果という軸

もう 1 つの分かれ目が、`effectful` の `m` 引数のところで出てきた高階効果です。ハンドラーが `Eff` の計算そのものを受け取る効果で、`catch` や `local` がこれにあたります。

命令が値だけを受け取る一階の効果に比べ、高階効果はどの方式でも扱いが難しく、ライブラリごとに専用の仕組みが用意されています。`polysemy` の Tactics、`cleff` と `effectful` のコンビネーターがそれです。効果を自作するだけなら意識せずに済みますが、ライブラリの API が入り組んで見える理由の一端はここにあります。

方式によっては、そもそも書けない効果もあります。`effectful` は、続きを捕まえて後から何度でも再開する種類の効果、たとえば全分岐を集める `NonDet` やコルーチンを提供できないと README で明言しています。継続を土台にしてこれを解こうとした `eff` というライブラリもありましたが、開発は止まっています。

## 選ぶときの目安

`mtl` がいちばん使われていることは先に触れたとおりです。効果システムは選択肢が増えている最中で、決着はついていません。

そのうえで Eff 系から選ぶなら、更新が続いているかどうかが目安になります。上の表のとおり `freer-simple` は 2022 年 1 月、`cleff` は 2022 年 5 月のリリースが最後で、現行の Stackage LTS には入っていません。本記事が `effectful` を使ったのはこのためです。

:::message
命令を並べて後からハンドラーが意味を与える、という枠組みには**代数的効果**（algebraic effects）という呼び名もあります。Free・Operational・Eff はいずれもこの系譜にあたります。Haskell に限らず、言語機能としてこれを備えた処理系もあります。
:::

# まとめ

Eff モナドは、使える命令の型を 1 つからリストへ広げたモナドでした。

前回の `Program instr a` との差は、`instr` が `Union es` になったことだけです。リストのどれか 1 つの命令、という型を挟むことで、複数の効果が同じ手順書に混ざります。位置の計算は `:>` という型クラスが引き受けるので、書く側は「この効果を使う」と宣言するだけで済みます。

ハンドラーは効果を 1 つ剥がす関数でした。自分宛の命令を処理し、他人宛は素通しします。適用するたびにリストが短くなり、空になったところで走らせます。

型レベルの見え方はそのままに、実装は差し替えられました。手順書をデータとして組み立てる実装と、ハンドラーの環境を受け取る関数の実装は、同じ `greet` を同じ出力で動かします。後者では組み立てと解釈の分離がデータ構造としては消え、`Eff` の型と `interpret` の形にだけ残ります。実際のパッケージも主にこの 2 つの方式に分かれています。

モナド変換子との比較が、この枠組みが作られた理由でした。

|モナド変換子|Eff|
|---|---|
|`StateT Int (WriterT [String] IO) a`|`Eff es a` と `State Int :> es`・`Writer [String] :> es`|
|型に積む順を書く|順を書かない|
|`lift`・`lift . lift`・`liftIO`|`liftIO` のみ|
|効果を足すと `lift` の数が変わる|制約を 1 つ足すだけ|
|外す順は型で決まる|外す順を選べる|

積み重ねではなく、集合として持つ。それが `lift` の回数という概念を消しました。

新しく必要になった言語拡張は `DataKinds` です。値のリストの書き方が型のレベルで使えるようになり、効果のリストを型として書けるようになりました。シリーズで初めての、型レベルの道具でした。

# 参考

今回の系譜にあたる論文です。

- Swierstra, W. (2008). Data types à la carte. *Journal of Functional Programming*, 18(4), 423–436. https://doi.org/10.1017/S0956796808006758
- Kiselyov, O., Sabry, A., & Swords, C. (2013). Extensible effects: an alternative to monad transformers. In *Proceedings of the 2013 ACM SIGPLAN Symposium on Haskell* (pp. 59–70). ACM. https://doi.org/10.1145/2503778.2503791
- Kiselyov, O., & Ishii, H. (2015). Freer monads, more extensible effects. In *Proceedings of the 2015 ACM SIGPLAN Symposium on Haskell* (pp. 94–105). ACM. https://doi.org/10.1145/2804302.2804319

`effectful` の README には、モナド変換子の何が問題で、`ReaderT` を土台に選んだのはなぜかが書かれています。

https://github.com/haskell-effectful/effectful
