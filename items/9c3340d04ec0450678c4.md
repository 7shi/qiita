---
coediting: false
comments_count: 0
created_at: '2020-05-28T07:14:05+09:00'
id: 9c3340d04ec0450678c4
likes_count: 2
private: false
reactions_count: 0
stocks_count: 2
tags:
- name: F#
  versions: []
title: F#スクリプトで引数の扱いをすり合わせる
updated_at: '2020-06-05T20:47:14+09:00'
url: https://qiita.com/7shi/items/9c3340d04ec0450678c4
slide: false
---

プロジェクトを作らずにファイル単体で書ける F# スクリプトは重宝しますが、コンパイルしたときと F# Interactive で動かすときとでコマンドライン引数が変わります。それをすり合わせました。

F# スクリプトを手軽に扱うには VS Code + Ionide がお勧めです。

* [F#開発環境の紹介](https://qiita.com/7shi/items/5fc7d6477d96bbd7a71d)

# 状況確認

コマンドライン引数の扱いを確認します。

```fsharp:args1.fsx
printfn "%A" (System.Environment.GetCommandLineArgs())
```
```text:Windows
>fsi args1.fsx abc def
[|"fsi"; "args1.fsx"; "abc"; "def"|]

>fsc args1.fsx
Microsoft (R) F# Compiler バージョン 10.6.0.0 for F# 4.7
Copyright (C) Microsoft Corporation. All rights reserved.

>args1 abc def
[|"args1"; "abc"; "def"|]
```
```text:Mono
$ fsharpi args1.fsx abc def
[|"/usr/lib/mono/fsharp/fsi.exe"; "--exename:fsharpi"; "args1.fsx"; "abc"; "def"|]

$ fsharpc args1.fsx
Microsoft (R) F# Compiler version 10.2.3 for F# 4.5
Copyright (c) Microsoft Corporation. All Rights Reserved.

$ mono args1.exe abc def
[|"/home/xxx/test/args1.exe"; "abc"; "def"|]
```

fsi の存在が見えています。Mono ではオプションも見えています。

プログラムに引数として渡したい `abc` `def` の位置が、コンパイルした時とずれています。

# 対策

fsi から起動されているかどうかを確認して、引数の開始位置をずらします。

```fsharp:args2.fsx
let args =
    let args = System.Environment.GetCommandLineArgs()
    match System.IO.Path.GetFileNameWithoutExtension args.[0] with
    | "fsi" | "fsiAnyCpu" ->
        args.[1..] |> Array.skipWhile (fun s -> s.StartsWith("--"))
    | _ -> args

printfn "%A" args
```
```text:Windows
>fsi args2.fsx abc def
[|"args2.fsx"; "abc"; "def"|]

>fsc args2.fsx
Microsoft (R) F# Compiler バージョン 10.6.0.0 for F# 4.7
Copyright (C) Microsoft Corporation. All rights reserved.

>args2 abc def
[|"args2"; "abc"; "def"|]
```
```text:Mono
$ fsharpi args2.fsx abc def
[|"args2.fsx"; "abc"; "def"|]

$ fsharpc args2.fsx
Microsoft (R) F# Compiler version 10.2.3 for F# 4.5
Copyright (c) Microsoft Corporation. All Rights Reserved.

$ mono args2.exe abc def
[|"/home/xxx/test/args2.exe"; "abc"; "def"|]
```

fsi の存在が隠れて、コンパイルした時と同様に扱えるようになりました。

# 合わせ技

最初に起動したスクリプトかどうかを判定する方法が以下の記事にあります。

* [F# ScriptでPythonの\_\_name\_\_を真似する](https://qiita.com/7shi/items/e4c7ca9fdd8789a4ec7b)

これを今回の技と組み合わせます。

```fsharp
do
    let frames = System.Diagnostics.StackTrace().GetFrames()
                 |> Array.map (fun frame -> frame.GetMethod().Name)
    if frames.[0] <> "main@" || Array.contains "EvalParsedSourceFiles" frames then () else
    let args =
        let args = System.Environment.GetCommandLineArgs()
        match System.IO.Path.GetFileNameWithoutExtension args.[0] with
        | "fsi" | "fsiAnyCpu" ->
            args.[1..] |> Array.skipWhile (fun s -> s.StartsWith("--"))
        | _ -> args
    printfn "%A" args
```

ここでやりたいことは Python でよく見かける以下と同じことです。

```python:Python
import sys
if __name__ == '__main__':
    print(sys.argv)
```

※ Python に比べると過剰な感は否めません。

# EntryPoint

最初は EntryPoint を使えば良いのではないかと思ったのですが、コンパイルしたときしか実行されません。

```fsharp:entry.fsx
open System

[<EntryPoint>]
let main args =
    printfn "%A" args
    0
```
```text:Mono
$ fsharpi entry.fsx abc def

$ fsharpc entry.fsx
Microsoft (R) F# Compiler version 10.2.3 for F# 4.5
Copyright (c) Microsoft Corporation. All Rights Reserved.

$ mono entry.exe abc def
[|"abc"; "def"|]
```

EntryPoint に渡される引数には実行ファイルの名前は含まれませんが、それを知りたいことがあるため、今回の記事の方法では敢えて残しています。

# 経緯

以前使っていた MonoDevelop では F# スクリプトもコンパイルして実行していたので、あまり気にしていませんでした。しかし最近使っている VS Code + Ionide ではコンパイルせずに実行するため、挙動の違いが無視できなくなりました。
