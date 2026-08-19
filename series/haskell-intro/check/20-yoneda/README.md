# check/20-yoneda

20 回 `# 米田の補題` の検証コード。`runghc` で動く。**外部パッケージは不要。**

|ファイル|本文の位置|内容|
|---|---|---|
|`Yoneda.hs`|`## Yoneda`|`liftYoneda`／`lowerYoneda` の往復|
|`Coyoneda.hs`|`## Coyoneda`|`Functor` インスタンスを持たない型を `Functor` にしてしまう構成|

## 実行結果

```text:Yoneda.hs
[1,2,3]
Just 'a'
Right 3
[2,4,6]
Just "4"
```

```text:Coyoneda.hs
6
"4"
[2,4,6]
```

## 確認したこと

- **`Yoneda` の往復は元に戻る。** `lowerYoneda (liftYoneda x) == x` を
  `[]`・`Maybe`・`Either` で確認した。`forall b. (a -> b) -> f b` と `f a` が
  同じ情報を持っている。
- **`instance Functor (Coyoneda f)` は `f` に何も要求しない。**
  `fmap h (Coyoneda fb g) = Coyoneda fb (h . g)` は後ろの関数を合成するだけ。
  `Functor` インスタンスを持たない `data Box a = Box a` に対しても
  `fmap (* 2) (liftCoyoneda (Box 3))` が書ける。
  17 回の `instr :>>= k` に `Functor instr =>` が不要だった理由がこれ。
- **`lowerCoyoneda` にだけ `Functor f` が必要。** 包むのは無条件、取り出すときに初めて必要になる。
- **`fmap` は 2 回重ねても関数の合成になるだけ。**
  `fmap show (fmap (+ 1) ...)` が `Box` の中身を 1 度も動かさずに `"4"` を返す。

## 言語拡張の確認

|ファイル|拡張|要否|
|---|---|---|
|`Coyoneda.hs`|`ExistentialQuantification`|**必要**（`data Coyoneda f a = forall b. ...`）|
|〃|`GADTs`|`ExistentialQuantification` の代わりでも通る|
|`Yoneda.hs`|`RankNTypes`|**必要**（`newtype` のフィールドに `forall`）|

**`ExistentialQuantification`・`RankNTypes` はどちらも GHC2021 に含まれるのでプラグマは不要。**
17 回では `GADTs` が必要だったが、今回は GADT 構文を使わず `forall` を直接書いているため
`ExistentialQuantification` で足り、プラグマなしで通る。
