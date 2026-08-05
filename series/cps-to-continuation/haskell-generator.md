---
coediting: false
comments_count: 0
created_at: '2026-07-28T00:00:00+09:00'
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
- name: 継続モナド
  versions: []
title: 継続モナドによるジェネレーターを Haskell で書く
updated_at: ''
url: ''
slide: false
---

継続モナドでジェネレーター（コルーチン）を実装しようとすると、型が循環して素朴には書けません。`data` で包めば解決することを示します。

以下の記事で JavaScript による実装を示しました。本記事はその Haskell 版です。

https://qiita.com/7shi/items/27b6f3169961299a6195

# 移植元

JavaScript による実装を再掲します。ジェネレーターは `{value, next}` というオブジェクトを返し、`next` を呼べば続きが計算されます。

```js:JavaScript
function g() {
    return { value: undefined, next: () => callCC(ccOut => {
        function yield(value) {
            return callCC(next => ccOut({value, next}));
        }
        return (
            yield(1).bind(_ =>
            yield(2).bind(_ =>
            yield(3).bind(_ =>
            Cont.ret()
        ))));
    })};
}

let it = g();
while (it = it.next().evalCont()) {
    console.log(it.value);
}
```

Haskell 側の継続モナドの実装も再掲します。

```hs:継続モナド
newtype Cont r a = Cont { runCont :: (a -> r) -> r }

instance Monad (Cont r) where
    return x = Cont ($ x)
    m >>= k  = Cont $ \c -> runCont m (\x -> runCont (k x) c)

evalCont :: Cont r r -> r
evalCont = (`runCont` id)

callCC :: ((a -> Cont r b) -> Cont r a) -> Cont r a
callCC f = Cont $ \c -> runCont (f (\x -> Cont $ \_ -> c x)) c
```

※ 現在の GHC では `Monad` のスーパークラスである `Functor` と `Applicative` のインスタンスも必要です。`Control.Monad` から `liftM` と `ap` を import して `fmap = liftM`、`(<*>) = ap` と書けば済みます。標準の [Control.Monad.Trans.Cont](https://hackage.haskell.org/package/transformers-0.6.1.0/docs/Control-Monad-Trans-Cont.html) を使っても以降の内容は同じように動きます。

# type だけだと循環する

`{value, next}` に型を付けることを考えます。`next` は継続モナドを返しますが、その継続モナドの答えの型（`Cont r a` の `r`）は `{value, next}` 自身です。

型シノニムで書いてみます。

```hs:型シノニム
type It = (Maybe Int, () -> Cont It It)
```

右辺に `It` が現れています。型シノニムは名前を展開するだけのものなので、展開しても

* `(Maybe Int, () -> Cont (Maybe Int, () -> Cont ... ) ... )`

のように終わりません。GHC はこれを受け付けません。

```text:エラー
Cycle in type synonym declarations:
  type It = (Maybe Int, () -> Cont It It)
```

型シノニムを使わずタプルのまま型推論に任せても、同じところに行き着きます。

```text:エラー
Couldn't match type ‘b0’ with ‘a0 -> Cont (Maybe Int, b0) b1’
```

`b0` の中に `b0` が現れています。これが循環です。

Haskell の型は有限の木として表されるため、自分自身を含む型はそのままでは表せません。型推論では、この状況を occurs check という検査で検出します。

※ `evalCont` を呼ぶまでは答えの型 `r` が多相なままなので、エラーは出ません。`r` がタプルの型に確定した瞬間にエラーとなります。

# data を使うと解決する

`data`（および `newtype`）は型を**名前で**新しく導入します。`It` は `It` という型そのものであって、中身のタプルの型と同一視されるわけではありません。型としては展開されない一枚岩なので、フィールドの型に自分自身が現れても構いません。

※ リストの定義 `data [a] = [] | a:[a]` も自分自身を含んでいます。再帰的なデータ構造は `data` で表現できます。

先ほどの型シノニムを `data`（レコード構文）で書き直します。

```hs:レコード構文
data It = It { value :: Maybe Int, next :: () -> Cont It It }
```

これで型が付きます。JavaScript 版とほぼ一対一に対応する形で移植できます。

```hs:ジェネレーター
data It = It { value :: Maybe Int, next :: () -> Cont It It }

g :: It
g = It Nothing $ \_ -> callCC $ \ccOut ->
    let yield v = callCC $ \nxt -> ccOut (It (Just v) nxt)
    in do
        yield 1
        yield 2
        yield 3
        return (It Nothing (\_ -> error "done"))

main :: IO ()
main = go g
  where
    go it =
        let it' = evalCont (next it ())
        in case value it' of
            Nothing -> return ()
            Just v  -> print v >> go it'
```
```text:実行結果
1
2
3
```

JavaScript では値の有無を `undefined` で判定していましたが、Haskell では `Maybe` を使いました。`main` の `go` が `while (it = it.next().evalCont())` に相当します。

`data` で包む代償は、コンストラクタ `It` を付けて作りパターンマッチで剝がす手間だけです。JavaScript の無名オブジェクトに名前を付けたに過ぎません。

※ `callCC` の型 `((a -> Cont r b) -> Cont r a) -> Cont r a` の `b` は、`yield` を使う文脈で `It` に確定するため、多相性を扱う言語拡張（RankNTypes）は必要ありません。

# 直和型による整理

値の有無を `Maybe` で表す代わりに直和型にすると、Haskell らしく整理できます。

```hs:整理した版
data Gen a
    = Done
    | Yield a (Cont (Gen a) (Gen a))  -- 値と、再開用の継続

yield ccOut v = callCC $ \next -> ccOut (Yield v (next ()))

runGen body = evalCont $ callCC $ \ccOut -> body ccOut >> return Done

toList Done = []
toList (Yield v k) = v : toList (evalCont k)
```

`Cont` の答えの型を `Gen a` 自身にしている点は変わりません。`runGen` でジェネレーターを組み立て、`toList` でリストに変換します。

```hs:使用例
g123    = runGen $ \ccOut -> let y = yield ccOut in do { y 1; y 2; y 3 }
nats    = runGen $ \ccOut -> let loop n = yield ccOut n >> loop (n + 1) in loop 0
squares = runGen $ \ccOut -> mapM_ (\n -> yield ccOut (n * n)) [1 .. 5]
```
```text:実行結果
> toList g123
[1,2,3]
> take 5 (toList nats)
[0,1,2,3,4]
> toList squares
[1,4,9,16,25]
```

`nats` のように無限のジェネレーターも書けます。また do ブロックが使えるため、`mapM_` のような既存のモナド用の関数がそのまま使えます。JavaScript で `bind` を入れ子にするより見通しが良くなります。

※ 1 行の do ブロックで `let` を使う場合、`do { let y = yield ccOut; y 1; y 2; y 3 }` とは書けません。明示的な波括弧の中ではレイアウト規則が働かないため、`;` が `let` の区切りと解釈されて `y 1` が次の束縛として読まれてしまいます。上記のように `let` を do ブロックの外に出すか、`do { let { y = yield ccOut }; ... }` と `let` 自体も波括弧で囲む必要があります。

# まとめ

* ジェネレーターの型が循環するのは、継続モナドの答えの型が、継続を保持するオブジェクト自身になるためです。
* Haskell の型は有限の木なので、型シノニムやタプルのままでは表せません。
* `data` は型を名前で導入するため、自分自身を含む型が書けます。JavaScript の無名オブジェクトに名前を付けるだけで移植できます。
