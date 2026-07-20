---
coediting: false
comments_count: 0
created_at: '2016-12-19T10:11:24+09:00'
id: e4c7ca9fdd8789a4ec7b
likes_count: 3
private: false
reactions_count: 0
stocks_count: 1
tags:
- name: F#
  versions: []
title: F# ScriptでPythonの__name__を真似する
updated_at: '2020-06-05T20:47:39+09:00'
url: https://qiita.com/7shi/items/e4c7ca9fdd8789a4ec7b
slide: false
---

最初に起動したスクリプトなのか、別のスクリプトから読み込まれたスクリプトなのか、実行時に判定する方法を調べました。

【2020.05.28】 F# Interactive に対応しました。

コマンドライン引数については以下の記事を参照してください。

* [F#スクリプトで引数の扱いをすり合わせる](https://qiita.com/7shi/items/9c3340d04ec0450678c4)

F# スクリプトを手軽に扱うには VS Code + Ionide がお勧めです。

* [F#開発環境の紹介](https://qiita.com/7shi/items/5fc7d6477d96bbd7a71d)

# Python

Pythonでは以下のように記述することで、最初に起動されたのかimportされたのかを判断することができます。

```py3:test1.py
if __name__ == '__main__':
    print("main")
```
```py3:test2.py
import test1
```
```text:実行結果
$ python test1.py
main

$ python test2.py
```

# F# スクリプト

これをF# スクリプトで真似してみました。一時変数が残らないように `do` 内に記述します。

```fsharp:Test1.fsx
do
    let frames = System.Diagnostics.StackTrace().GetFrames()
                 |> Array.map (fun frame -> frame.GetMethod().Name)
    if frames.[0] <> "main@" || Array.contains "EvalParsedSourceFiles" frames then () else
    printfn "main"
```
```fsharp:Test2.fsx
#load "Test1.fsx"
```
```text:実行結果
>fsi Test1.fsx
main

>fsi Test2.fsx

>fsc Test1.fsx
Microsoft (R) F# Compiler バージョン 10.6.0.0 for F# 4.7
Copyright (C) Microsoft Corporation. All rights reserved.

>fsc Test2.fsx
Microsoft (R) F# Compiler バージョン 10.6.0.0 for F# 4.7
Copyright (C) Microsoft Corporation. All rights reserved.

Test2.fsx(1,18): warning FS0988: プログラムのメイン モジュールが空です。実行しても何も処理されません

>Test1
main

>Test2
```

## 調査

このコードはスタックフレームの差分に基づいています。

```fsharp:Test3.fsx
for frame in System.Diagnostics.StackTrace().GetFrames() do
    printfn "%s" (frame.GetMethod().Name)
```
```fsharp:Test4.fsx
#load "Test3.fsx"
```
```text:ログ採取
>fsi Test3.fsx > Test3.log
>fsi Test4.fsx > Test4.log
```
```diff:差分
--- Test3.log   2020-05-28 05:37:40.295828000 +0900
+++ Test4.log   2020-05-28 05:37:46.470496400 +0900
@@ -9,8 +9,8 @@
 iter
 Iterate
 ProcessInputs
-EvalParsedDefinitions
-EvalParsedExpression
+EvalParsedSourceFiles
+EvalSourceFiles
 Invoke
 InteractiveCatch
 ExecInteraction
```

`EvalParsedDefinitions` があれば最初の起動、`EvalParsedSourceFiles` があれば別のスクリプトから読み込まれていると判断できるようです。

# 旧バージョン

当初は次のようにしていました。Python の記述方法に似ていますが、F# Interactive に未対応です。

```fsharp:Test1.fsx
if System.Diagnostics.StackTrace().GetFrame(0).GetMethod().Name = "main@" then
    printfn "main"
```
```fsharp:Test2.fsx
#load "Test1.fsx"
```
```text:実行結果
>fsi Test1.fsx
main

>fsi Test2.fsx
main

>fsc Test1.fsx
Microsoft (R) F# Compiler version 11.0.50727.1
Copyright (c) Microsoft Corporation. All Rights Reserved.

>fsc Test2.fsx
Microsoft (R) F# Compiler version 11.0.50727.1
Copyright (c) Microsoft Corporation. All Rights Reserved.

Test2.fsx(1,18): warning FS0988: Main module of program is empty: nothing will happen when it is run

>Test1
main

>Test2
```

# 参考

* [.NET で呼び出し元のメソッド情報を知りたいときは - 周回遅れのブルース](http://d.hatena.ne.jp/hilapon/20130216/1360986092) 2013.02.16
