---
coediting: false
comments_count: 0
created_at: '2020-06-09T19:49:09+09:00'
id: 6bc57ddde5a06e526496
likes_count: 7
private: false
reactions_count: 0
stocks_count: 1
tags:
- name: F#
  versions: []
- name: .NETCore
  versions: []
title: .NET CoreでプロジェクトなしにF#を使う
updated_at: '2020-06-10T17:20:29+09:00'
url: https://qiita.com/7shi/items/6bc57ddde5a06e526496
slide: false
---

.NET Core はプロジェクトを作ってビルドするのが基本ですが、敢えてプロジェクトなしで使ってみました。

# 概要

F# Interactive 経由では簡単に使えます。

F# コンパイラはプロジェクトなしの単体で使うことは想定されていなかったため、別環境のものを使いました。生成された EXE ファイルは、コンフィグの JSON ファイルを書けば動きました。

# 環境

WSL1 上の Arch Linux に dotnet-sdk をインストールします。

* [WSLでUbuntuと共存させてArch Linuxを使う](https://qiita.com/7shi/items/cfda84909b2ea787afdb)
* [.NET Core - ArchWiki](https://wiki.archlinux.jp/index.php/.NET_Core)

# F# Interactive

`dotnet fsi` で起動します。

【参考】 [F#をはじめよう | Qrunch（クランチ）](https://qrunch.net/@hiro3/entries/J1vPMLFiuDeOGT0t)

`dotnet` コマンドの使用が初めてであれば、テレメトリに関するメッセージが表示されます。

※ F# Interactive ではなく .NET Core 側のメッセージです。次回からは表示されません。

```text
$ dotnet fsi

.NET Core 3.1 へようこそ!
---------------------
SDK バージョン: 3.1.103

テレメトリ
---------
.NET Core ツールは、エクスペリエンスの向上のために利用状況データを収集します。データは匿名です。
データは Microsoft によ って収集され、コミュニティと共有されます。テレメトリをオプトアウトするには、
好みのシェルを使用して、DOTNET_CLI_TELEMETRY_OPTOUT 環境変数を '1' または 'true' に設定できます。

.NET Core CLI ツールのテレメトリの詳細をご覧ください: https://aka.ms/dotnet-cli-telemetry

----------------
ドキュメントを確認する: https://aka.ms/dotnet-docs
問題を報告し、GitHub でソースを参照する: https://github.com/dotnet/core
新機能を参照する: https://aka.ms/dotnet-whats-new
インストール済みの HTTPS 開発者の証明書の詳細情報: https://aka.ms/aspnet-core-https
'dotnet --help' を使用して利用可能なコマンドを確認するか、次にアクセスする: https://aka.ms/dotnet-cli-docs
初めてのアプリを作成する: https://aka.ms/first-net-core-app
--------------------------------------------------------------------------------------

Microsoft (R) F# インタラクティブ バージョン 10.7.0.0 for F# 4.7
Copyright (C) Microsoft Corporation. All rights reserved.

ヘルプを表示するには次を入力してください: #help;;

>
```

F# スクリプトのファイルを指定すれば実行できます。

```shell-session
$ cat test.fsx
printfn "hello"

$ dotnet fsi test.fsx
hello
```

# F# コンパイラ

安易に `dotnet fsc` を試しましたがダメでした。

```text
$ dotnet fsc
指定されたコマンドまたはファイルが見つからなかったため、実行できませんでした。
次のような原因が考えられます:
  * 組み込みの dotnet コマンドのスペルが間違っている。
  * .NET Core プログラムを実行しようとしたが、dotnet-fsc が存在しない。
  * グローバル ツールを実行しようとしたが、プレフィックスとして dotnet が付いたこの名前の実行可能ファイルが PATH に見つ からなかった。
```

パッケージに含まれるファイルを確認します。EXE ファイルは fsc.exe と fsi.exe だけのようです。

```shell-session
$ pacman -Ql dotnet-sdk | grep exe
dotnet-sdk /usr/share/dotnet/sdk/3.1.103/FSharp/fsc.exe
dotnet-sdk /usr/share/dotnet/sdk/3.1.103/FSharp/fsi.exe
```

EXE ファイルを直接指定すると起動はします。

```shell-session
$ dotnet /usr/share/dotnet/sdk/3.1.103/FSharp/fsc.exe
Microsoft (R) F# Compiler バージョン 10.7.0.0 for F# 4.7
Copyright (C) Microsoft Corporation. All rights reserved.

error FS0207: 入力が指定されていません
```

しかし入力を指定するとエラーになります。

```shell-session
$ dotnet /usr/share/dotnet/sdk/3.1.103/FSharp/fsc.exe test.fsx

error FS0193: Could not load file or assembly 'Microsoft.Build.Tasks.v4.0, Version=4.0.0.0, 
Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a'. The system cannot find the file specified.
```

どうやら単体で利用することは想定されておらず、プロジェクトを作ってビルドするしかないようです。

fsc.exe をダミーに置き換えて、プロジェクトをビルドする際のオプションを確認しました。`--noframework` を指定して、細かく分けられた大量の DLL を指定する必要があるようです。

* [[F#] fsc dummy](https://gist.github.com/7shi/de715c11f7a1597133c975bfb078cfef)

コンパイラを単体で利用することは諦めて、プロジェクトを作るか、.NET Framework または Mono のコンパイラを使うことにします。

# 実行

Windows 側の fsc.exe でビルドしたバイナリの実行を試みます。

```text
$ cat test.fsx
printfn "hello"

$ fsc.exe test.fsx
Microsoft (R) F# Compiler バージョン 10.6.0.0 for F# 4.7
Copyright (C) Microsoft Corporation. All rights reserved.

$ dotnet test.exe
A fatal error was encountered. The library 'libhostpolicy.so' required to execute the application 
was not found in '/home/xxx/'.
Failed to run as a self-contained app. If this should be a framework-dependent app, add the 
/home/xxx/test.runtimeconfig.json file specifying the appropriate framework.
```

`test.runtimeconfig.json` を書かないと実行できないようです。

```json:test.runtimeconfig.json
{
  "runtimeOptions": {
    "tfm": "netcoreapp3.1",
    "framework": {
      "name": "Microsoft.NETCore.App",
      "version": "3.1.0"
    }
  }
}
```

※ このファイルはプロジェクトを作ってビルドしたものから流用しました。

これで実行できるようになりました。

```shell-session
$ dotnet test.exe
hello
```

# プロジェクト

コンフィグを取得するため、プロジェクトを作ってビルドします。

【参考】 [コマンドラインツールF#を使って作業を開始する | Microsoft Docs](https://docs.microsoft.com/ja-jp/dotnet/fsharp/get-started/get-started-command-line)

```shell-session
$ dotnet new console -lang "F#" -o test
The template "Console Application" was created successfully.

Processing post-creation actions...
Running 'dotnet restore' on test/test.fsproj...
  Restore completed in 162.12 ms for /home/xxx/test/test.fsproj.

Restore succeeded.

$ cd test

$ dotnet build
.NET Core 向け Microsoft (R) Build Engine バージョン 16.4.0+e901037fe
Copyright (C) Microsoft Corporation.All rights reserved.

  Restore completed in 42.72 ms for /home/xxx/test/test.fsproj.
  test -> /home/xxx/test/bin/Debug/netcoreapp3.1/test.dll

ビルドに成功しました。
    0 個の警告
    0 エラー

経過時間 00:00:04.65
```

EXE ではなく DLL が生成されます。

コンパイラをダミーに置き換えてオプションを確認すると、実体は EXE でファイル名が DLL になっているようです。

* [[F#] fsc dummy](https://gist.github.com/7shi/de715c11f7a1597133c975bfb078cfef)

<blockquote><pre>-o:obj/Debug/netcoreapp3.1/test.dll</pre><pre>--target:exe</pre></blockquote>

同時に生成されたランチャー経由で実行します。`dotnet` コマンドからも実行できます。

```text
$ cd bin/Debug/netcoreapp3.1/

$ ./test
Hello World from F#!

$ dotnet test.dll
Hello World from F#!
```

このディレクトリから持って来たのが先ほどの test.runtimeconfig.json です。

ランチャーの正体は以下の記事で説明されています。

【参考】 [主に技術日記: .NET Coreが動くまで](http://yfakariya.blogspot.com/2017/03/net-core.html)

> **.NET Core 実行可能アプリケーションとは**
> 
> スタンドアローンモードで説明したように、<アプリケーション名>.exe（Windows 以外では <アプリケーション名>）という名前にリネームされ、スタンドアローンモードで実行される corehost です。
> （リネーム処理は .NET Core SDK の Microsoft.NET.Publish.targets ファイルに書かれています）

実行ファイルはランチャーで、本体は DLL として扱うというのが、今までと勝手が違います。生成された実行ファイルをコマンドとして扱うには妥当なやり方のように思いました。
