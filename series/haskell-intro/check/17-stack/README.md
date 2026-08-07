# check/17-stack

17 回 練習【問1】【問2】スタックマシン DSL の検証コード。`runghc` で動く。
16 回 練習【問3】【問4】（`check/16-stack/`）の Operational 版。

|ファイル|内容|
|---|---|
|`Stack.hs`|`StackI`・`push`・`pop`・`calc`（問1）と `runStack`（問2）。`Program` の定義を先頭に補ってある|

## 実行結果

```text
7
```

## 確認したこと

- `Pop :: StackI Int` と GADT で宣言するだけで `pop = singleton Pop` が `Stack Int` になる。
  16 回の `Pop (Int -> next)` + `deriving Functor` がまるごと消えることを確認。
- `runStack` は 16 回の解答と同じ骨組み。違いは続きのありかだけで、
  `Push n :>>= k` の `k` は関数なので `k ()` に適用してから辿る。
- 空のスタックに `Pop` が来たときは 0 を返す（16 回と同じ流儀）。
- 言語拡張は GADTs のみ。
