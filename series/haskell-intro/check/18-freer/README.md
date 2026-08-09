# check/18-freer

18 回の `freer-simple` パッケージの事前検証（2026-08-09）。**記事の掲載コードではなく、
設計判断のための試作。**

|ファイル|内容|
|---|---|
|`StateWriter.hs`|`State` と `Writer` を混ぜ、**ハンドラーの適用順を入れ替えて結果を比べる**|
|`Teletype.hs`|17 回の `TeletypeI` をそのまま効果にし、`State` と `IO` を混ぜる|
|`Sum.hs`|**10 回（モナド変換子）の `sum'` を `Eff` で書き直したもの**|

## 実行方法

`freer-simple` は GHC に同梱されておらず、**lts-22.28（16・17 回の resolver）には無い。
lts-23 系列にのみ収録**されている。

```
stack script --resolver lts-23.28 --package freer-simple StateWriter.hs
echo alice | stack script --resolver lts-23.28 --package freer-simple Teletype.hs
stack script --resolver lts-23.28 --package freer-simple Sum.hs
```

⚠ lts-23.28 は GHC 9.8.4 なので、この環境の stack は次の警告を出す。**動作には影響しない。**

```text
Stack has not been tested with GHC versions above 9.4, and using 9.8.4, this may fail
Stack has not been tested with Cabal versions above 3.8, but version 3.10.3.0 was found, this may fail
```

## 実行結果

```text:StateWriter.hs
(((),1),["n = 0"])
(((),["n = 0"]),1)
```

```text:Teletype.hs（標準入力: alice）
name?
Hello, alice! (0)
1
```

```text:Sum.hs
+1 -> 1
+2 -> 3
+3 -> 6
+4 -> 10
+5 -> 15
15
```

## 確認したこと

- **`freer-simple-1.2.1.2` は lts-23.28 で動く。** `stack script` の形は 16・17 回と同じ。
- **効果の定義は 17 回の命令の型そのもの。** ライブラリの `State`・`Writer` も GADT。

  ```hs
  data State s r where
      Get :: State s s
      Put :: !s -> State s ()

  data Writer w r where
      Tell :: w -> Writer w ()
  ```

- **17 回の `TeletypeI` は 1 文字も変えずに効果として使える**（`Teletype.hs`）。
  変わるのはスマートコンストラクターの `singleton` が `send` になる点だけ。

  ```hs
  putLine :: Member Teletype effs => String -> Eff effs ()
  putLine = send . PutLine
  ```

- **ハンドラーの適用順は自由**（`StateWriter.hs`）。`Member` 制約で書いておけば、
  `runWriter . runState` でも `runState . runWriter` でも通り、結果のタプルの入れ子が
  変わる。モナド変換子でスタックの順序を決め打ちするのとの対比になる。
- **`lift` が要らない**（`Sum.hs`）。10 回では `lift $ putStrLn ...` だったところが
  `sendM $ putStrLn ...` になる。持ち上げの回数を数える必要が無く、`liftIO` に
  相当するものも要らない。
  - `runM :: Monad m => Eff '[m] a -> m a` で最後に `IO` を取り出す。
  - `sendM :: (Monad m, LastMember m effs) => m a -> Eff effs a`。

### 型推論の落とし穴（本文で触れるか要検討）

1. **`get` の型は決まらないことがある。** `get :: Member (State s) effs => Eff effs s` で、
   `s` は `effs` から一意に決まらない（関数従属が無い）ので、
   `n <- get` した `n` の型が曖昧になることがある。`show (n :: Int)` のように
   使う側で決めるか、型注釈が要る。
2. **手順書の型を具体的なリストで書くと、ハンドラーの適用順が固定される。**
   `prog :: Eff '[State Int, Writer [String]] ()` と書くと `runWriter . runState` の
   順しか通らない。`Member` 制約で書くのが定石。
3. **`Member` 制約を書くと `-Wsimplifiable-class-constraints` の警告が出る**ことがある。
   `GADTs`（`MonoLocalBinds` を含意）を有効にすれば消える。自作の効果を GADT で
   定義する回なので、実際には問題にならない。
4. **ハンドラーを適用した中間結果には型注釈が要る場合がある。**
   `runWriter (runState (0 :: Int) prog :: Eff '[Writer [String]] ((), Int))` のように、
   残りの効果リストを書かないと `w` が決まらない。

## 必要な言語拡張

**`DataKinds` が必須**（型レベルリスト `'[...]` のため）。自作の効果を定義するなら
`GADTs` も要る。`TypeOperators`・`FlexibleContexts` は GHC2021 に含まれるので不要
（`Teletype.hs` は `DataKinds` と `GADTs` の 2 つだけで通る）。
