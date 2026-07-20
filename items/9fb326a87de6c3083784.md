---
coediting: false
comments_count: 0
created_at: '2014-08-29T16:39:47+09:00'
id: 9fb326a87de6c3083784
likes_count: 27
private: false
reactions_count: 0
stocks_count: 25
tags:
- name: Haskell
  versions: []
title: HUnit 超入門
updated_at: '2015-07-28T22:29:41+09:00'
url: https://qiita.com/7shi/items/9fb326a87de6c3083784
slide: false
---

Haskellのユニットテスト用ライブラリHUnitを使うのに最低限必要な事項を説明します。

この記事は[Haskell 超入門](http://qiita.com/7shi/items/145f1234f8ec2af923ef)シリーズの番外編です。

# 設定

HUnitへの参照が必要です。

Leksahでの設定方法を説明します。Leksahについては以下を参照してください。

* [Haskell IDE Leksah 入門](http://qiita.com/7shi/items/d1e5a0c22be6cf61d286)

メニューから設定します。

* Package → Edit
    * Dependencies → HUnit と入力して [Add]
    * [Save]

依存関係を変更した後は[1]中間生成物を消去して[2]configureをやり直します。

![clean-configure.png](https://qiita-image-store.s3.amazonaws.com/0/32057/52e613c5-2aca-2d47-5e1e-564cad1a6268.png)

以上で設定は完了です。

# 使用方法

簡単な使用方法を説明します。

HUnitで定義されている`~:`と`~?=`という演算子を使って、想定される結果を記述します。奇妙な演算子ですが、先頭の`~`で識別してください。

```text
ラベル ~: 式 ~?= 期待値
```

ラベルはテストに名前を付けるのに使用します。省略可能ですが、エラー発生時に識別が難しくなるため、付けておく方が無難です。

```hs
import Test.HUnit
import System.IO

fact 1 = 1
fact n = n * fact (n - 1)

tests = TestList
    [ "fact 1" ~: fact 1 ~?= 1
    , "fact 2" ~: fact 2 ~?= 2
    , "fact 3" ~: fact 3 ~?= 6
    , "fact 4" ~: fact 4 ~?= 24
    , "fact 5" ~: fact 5 ~?= 120
    ]

main = do
    runTestText (putTextToHandle stderr False) tests
```

テストが通れば結果のみが表示されます。表示がシンプルになるように`putTextToHandle`で調整しています。

```text:実行結果
Cases: 5  Tried: 5  Errors: 0  Failures: 0
```

## 失敗

故意にテストを失敗させて結果を確認します。

```hs:テストの改変部分
    , "fact 5" ~: fact 5 ~?= 100
```
```text:実行結果
### Failure in: 4:fact 5
expected: 100
 but got: 120
Cases: 5  Tried: 5  Errors: 0  Failures: 1
```

## エラー

故意にエラーを発生させて結果を確認します。

```hs
import Test.HUnit
import System.IO

f 1 = 0

tests = TestList
    [ "f 0" ~: f 0 ~?= 0
    , "f 1" ~: f 1 ~?= 0
    , "f 2" ~: f 2 ~?= 0
    ]

main = do
    runTestText (putTextToHandle stderr False) tests
```
```text:実行結果
### Error in:   0:f 0
src\Main.hs:4:1-7: Non-exhaustive patterns in function f

### Error in:   2:f 2
src\Main.hs:4:1-7: Non-exhaustive patterns in function f

Cases: 3  Tried: 3  Errors: 2  Failures: 0
```

# その他

以上の知識で、初めのうちは充分ではないかと思います。

それ以外の使い方は以下を参照してください。

* [HaskellのUnitTest、HUnitについて学ぶ - エンジニアのソフトウェア的愛情](http://d.hatena.ne.jp/E_Mattsan/20121020/1350707524)

何か関数を実装するときは想定される結果でテストを書いておくことをお勧めします。テストについては以下を参照してください。

* [テスト駆動開発 - Wikipedia](http://ja.wikipedia.org/wiki/%E3%83%86%E3%82%B9%E3%83%88%E9%A7%86%E5%8B%95%E9%96%8B%E7%99%BA)
