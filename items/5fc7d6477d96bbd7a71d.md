---
coediting: false
comments_count: 3
created_at: '2016-12-30T18:57:12+09:00'
id: 5fc7d6477d96bbd7a71d
likes_count: 32
private: false
reactions_count: 0
stocks_count: 35
tags:
- name: F#
  versions: []
title: F#開発環境の紹介
updated_at: '2020-06-11T15:27:51+09:00'
url: https://qiita.com/7shi/items/5fc7d6477d96bbd7a71d
slide: false
---

私が常用している F# スクリプトの開発環境を紹介します。個人的には、小規模なプログラミングでは最強の使い勝手だと感じています。これが便利で F# を使っていると言っても過言ではありません。

【2018.07.31】記事を全面的に書き直しました。[以前の内容](https://bitbucket.org/7shi/ikebin/wiki/fsharp_old)は非推奨です。

F# を試してみたい方は、入門記事を参照してください。

* 2017.01.04 [C#/JavaScriptで学ぶF#入門](http://qiita.com/7shi/items/ff746903680ae8d0d7ce)
* 2017.01.11 [Haskellで学ぶF#入門](http://qiita.com/7shi/items/ff746903680ae8d0d7ce)

Visual Studio Code の拡張機能では Markown+Math もお勧めです。

* [Visual Studio CodeとMarkdown+Mathの紹介](http://7shi.hateblo.jp/entry/2018/07/30/214913)

# 特徴

[Visual Studio Code](https://code.visualstudio.com/) の拡張機能 [Ionide-fsharp](http://ionide.io/) の紹介です。

Ionide-fsharp には様々な機能がありますが、今回は F# スクリプトでの使い勝手に焦点を絞ります。

* F# スクリプトをファイル単体で扱えるためプロジェクトの煩わしさがありません。
* 補完が使えます。
* トップレベルの定義には型が表示されます。それ以外でもツールチップで型が分かります。
* ビルドしなくてもリアルタイムでエラーチェックしてくれます。
* コードのアウトライン（関数や変数の一覧）が表示されます。
* エディタ内で実行して結果を確認できます。

使用イメージです。
![image.png](https://qiita-image-store.s3.amazonaws.com/0/32057/14f36a75-71be-cea3-f40e-a68da3b031bc.png)

# バージョン

執筆時点のバージョンは以下の通りです。

* Visual Studio Code 1.25.1
* Ionide-fsharp 3.25.0

# インストール

F# 環境と Visual Studio Code をダウンロードしてインストールします。

## Windows

Build Tools for Visual Studio 2019 をダウンロードします。

* [ダウンロード | IDE、Code、Team Foundation Server | Visual Studio](https://visualstudio.microsoft.com/ja/downloads/)<br>
  下の方にある「Visual Studio 2019 のツール」をクリック<br>
  ![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/32057/f2ed0dbe-60c2-29b7-4324-4b9f0ad2ca59.png)

実行すると Visual Studio Installer が起動します。

※ 名前が誤解を招きやすいですが、今回は Visual Studio をインストールするわけではありません。

インストール対象を選ぶ画面になるので「.NET デスクトップ ビルドツール」をチェックします。
![image.png](https://qiita-image-store.s3.amazonaws.com/0/32057/3223f5a7-ce01-badd-8811-7a1aeea18699.png)

右側に表示されるオプションで「F# コンパイラ」をチェックします。
![image.png](https://qiita-image-store.s3.amazonaws.com/0/32057/027500fd-940e-d25f-4ddd-2a4b329b6d27.png)

右下の[インストール]をクリックします。

インストールが終了したらウィンドウを閉じてください。

## macOS

以下のページの Option 1 を参照してください。

* [Use F# on Mac OSX](https://fsharp.org/use/mac/)

## Linux

以下のページを参照してください。

* [Use F# on Linux](https://fsharp.org/use/linux/)

## 共通

Visual Studio Code を公式サイトよりダウンロードしてインストールします。

* https://code.visualstudio.com/

Visual Studio Code を起動して、拡張機能をインストールします。

1. 画面左の拡張機能のアイコン ![image.png](https://qiita-image-store.s3.amazonaws.com/0/32057/30ec9ddc-f627-fad2-16ae-44b4ba90aae5.png) をクリックします。
1. テキストボックスに `ionide` と入力します。
1. Ionide-fsharp の [インストール] をクリックします。
1. インストールが完了したら [再読み込み] をクリックします。Visual Studio Code の画面の中身が消えますが、しばらくして元の画面に戻れば完了です。

# 使い方

F#スクリプトのソース（拡張子 .fsx）を開きます。
画面左の F# のアイコン ![image.png](https://qiita-image-store.s3.amazonaws.com/0/32057/fb5e447f-26c8-6f11-8206-cde1bb523f04.png) をクリックするとコードのアウトラインが表示されます。
画面右上の実行のアイコン ▶ をクリックすると実行できます。
![image.png](https://qiita-image-store.s3.amazonaws.com/0/32057/56dbde98-a46b-e3b7-10ed-ee76975d3ffb.png)

シンプルですが、ちょっとしたスクリプトを書くにはこれで十分です。

## 注意点

* 実行のアイコン ▶ をクリックしてもソースが自動保存されません。明示的に保存操作を行わないと、修正内容が反映されないまま実行されます。実行前に必ず [Ctrl]+[S] で保存してください。
* 実行結果が表示されるターミナルを閉じずに再度実行すると、以前のターミナルがそのまま残ります。その都度「ゴミ箱」アイコンで閉じるか、定期的にすべて閉じるかする必要があります。
* 実行のアイコン ▶ をクリックしたときに `connect ECONNREFUSED 127.0.0.1:8xxx` というエラーが出る場合、次で説明する `FSharp.fsacRuntime` を一度 `netcore` にしてから `net` に変更してみてください。<br>※ デフォルトで `net` が選択されているように見えますが、明示的に指定しないと機能しないため、一度変更して戻します。

## FSharp.fsacRuntime

この記事の手順でインストールすると、Windows で F# ファイルを開いたとき右下に ```Consider using the .Net Core language services by setting `FSharp.fsacRuntime` to `netcore` ``` という警告が出ることがあります。
![image.png](https://qiita-image-store.s3.amazonaws.com/0/32057/5f83b589-46d0-63ca-0de4-0be5feaab923.png)
これは次のように設定して消します。

1. メニューから「ファイル → 基本設定 → 設定」を開きます。
2. 左のツリーから「拡張機能 → FSharp configuration」を選択します。
3. FShrp: FSac Runtime で netcore を選択します。
4. Visual Studio Code を再起動します。

![image.png](https://qiita-image-store.s3.amazonaws.com/0/32057/9bbf072e-531c-1f6f-2260-4d211994d493.png)

# F# スクリプト

F# スクリプトは柔軟性があり便利です。こういう使い方のための言語仕様なのかと感じました。

* 参照ライブラリを `#r` ディレクティブで指定できます。
* 複数ファイルを同時に開いてタブで切り替えられます。実行のアイコン ▶ で実行されるのはそのとき開いているファイルです。複数ファイルの連携は `#load` ディレクティブで対応できます。
* 複数ファイルで構成される F# プログラムはファイルの順序を指定する必要があります。F# スクリプトではメインのファイルに `#load` ディレクティブを並べることで代用できます。
* 以下の記事の方法を使えば、最初に読み込まれたかどうかで処理を変えることができます。
  * [F# ScriptでPythonの\_\_name\_\_を真似する](http://qiita.com/7shi/items/e4c7ca9fdd8789a4ec7b)
