# check/19-parser

19 回「アローを自作する」「分岐」「モナドにはできない」の検証コード。**この回の主題そのもの。**

|ファイル|内容|`runghc`|
|---|---|---|
|`Parser.hs`|静的パーサ `P`。`Category`・`Arrow`・`ArrowChoice` を自作。`string`（問3）と分岐を含む|通る|
|`Apply.hs`|`P` に `ArrowApply` を持たせるとどうなるかの実験|通る|
|`Bind.hs`|`>>=` にあたるものを書こうとして詰まる箇所|**通らない（意図的）**|

## 静的パーサ（`Parser.hs`）

```hs
newtype P b c = P ([Char], [Char] -> b -> Maybe (c, [Char]))
```

タプルの左が静的な情報（受け付ける文字）、右が実際の解析。
`Category` の `.` が `t1 ++ t2` で静的な情報を連結するので、
**合成した時点で全体が何を受け付けるかが確定する。**

```text:Parser.hs
"abc"
Just ((),"d")
Nothing
"abc"
Just ((),"d")
"ab"
Just ((),"b")
Nothing
"ab"
Just ((),"b")
Just ((),"a")
```

|行|意味|
|---|---|
|1|`expects abc`。**実行前に分かる**|
|2・3|`abc` を走らせた結果（成功・失敗）|
|4・5|練習【問3】の `string "abc"`。`char` を `>>>` で畳み込んでも `expects` が連結される|
|6|`proc` の `if` で分岐した `ab` の `expects`。**両方の枝の和**になる|
|7・8|分岐の両側を走らせた結果|
|9|`\|\|\|` で書いた `ab2` の `expects`。`ab` と同じ|
|10・11|`Left`・`Right` を渡して走らせた結果|

6 行目が効く。値がどちらに転んでも、**起こりうることの全体は事前に分かる。**

### 言語拡張の確認

**pragma は `{-# LANGUAGE Arrows #-}` の 1 行だけ。**
その状態で `runghc -XHaskell2010` に掛けても通る（`FlexibleInstances`・
`RankNTypes` などは不要）。`import Prelude hiding ((.), id)` は
`Control.Category` の `id`・`.` と衝突するためで、拡張ではない。

## `ArrowApply` の実験（`Apply.hs`）

`app :: P (P b c, b) c` は**実装できてしまう。** ただし実行時に受け取ったパーサを
走らせるので、静的な情報を先に言えず、**空にするしかない。**

```hs
instance ArrowApply P where
    app = P ([], \s (P (_, f), b) -> f s b)

choose :: P Bool ()
choose = arr (\flag -> (if flag then char 'a' else char 'b', ())) >>> app
```

```text:Apply.hs
""
Just ((),"b")
Nothing
```

**1 行目が嘘になっている。** `expects choose` は「何も受け付けない」と答えるのに、
実際には `'a'` を消費して `"b"` が残っている。3 行目は先頭が `'a'` でないので失敗。

- `app` があると、**入力の値によって次のパーサを選べる**（モナドの `>>=` にあたる）。
- その自由さと引き換えに、静的な情報が失われる。
- ⚠ **型エラーにはならない**ので、「モナドにできない」は
  「書けない」ではなく「書くと静的な情報が嘘になる」が正確。本文もこの言い方にした。

## `>>=` の行き詰まり（`Bind.hs`）

**このファイルはコンパイルが通らない。** 型穴（`_`）で詰まる箇所を示すためのもの。

```hs
bindP :: P b c -> (c -> P b d) -> P b d
bindP (P (t1, f)) k = P (t1 ++ expects (k _), \s b -> Nothing)
```

```text
error: [GHC-88464]
    • Found hole: _ :: c
      Where: ‘c’ is a rigid type variable bound by
               the type signature for:
                 bindP :: forall b c d. P b c -> (c -> P b d) -> P b d
```

**静的な情報を組み立てるには `k` を適用しなければならず、そのためには
解析結果 `c` が要る。** しかし `c` は実行してみないと手に入らない。
「組み立て時に確定できるものと、実行時にしか手に入らないもの」の境界が
そのままエラーとして出る。

- `Apply.hs` の `app` は、この要求を「静的な情報を諦める」ことで回避している。
- ⚠ **本文では型穴を使わず散文で詰まらせた**（19-PLAN 決定事項 9）。
  このファイルは裏付けとして残す。
