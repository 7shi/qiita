# check/17-package

17 回「operational パッケージ」の検証コード。

|ファイル|内容|
|---|---|
|`Package.hs`|本文の掲載コード（`TeletypeI`・`greet`・`view` を使う `run`・`interpretWithMonad`）|

## 実行方法

`operational` は GHC に同梱されていないため、stack でパッケージを指定する
（lts-22.28 に `operational-0.2.4.2` が収録されている）。

```
stack script --resolver lts-22.28 --package operational Package.hs
```

## 実行結果（標準入力: alice、carol）

```text
name?
Hello, alice!
name?
Hello, carol!
```

## 確認したこと

- `Control.Monad.Operational` の `Program`・`singleton`・`view`・`ProgramView`
  （`Return`・`:>>=`）・`interpretWithMonad` が本文の記述どおりに動く。
- `view` の戻り値 `ProgramView` は `Show` インスタンスを持たない
  （`print (view prog)` は型エラー）。パターンマッチで 1 段ずつ剥がす用途。
- `view` を使う `run` と `interpretWithMonad` で同じ結果になる。
