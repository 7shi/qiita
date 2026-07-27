---
coediting: false
comments_count: 0
created_at: '2016-12-31T00:31:05+09:00'
id: efc236112abc6db94fbd
likes_count: 0
private: false
reactions_count: 0
stocks_count: 0
tags:
- name: F#
  versions: []
title: ファイルのDnDを受けるGUIの雛形
updated_at: '2016-12-31T19:48:13+09:00'
url: https://qiita.com/7shi/items/efc236112abc6db94fbd
slide: false
---

F#でファイルのDnDを受けるプログラムの雛形です。捨てスクリプトなどでファイルを加工することがよくありますが、そういったものと組み合わせればコマンドラインに不慣れな人にも配布しやすくなります。

Windows FormsとWPFの両方で示します。GUIをコードで書くのは辛い面もありますが、この手のものは定型なのでコピペで済みます。

# Windows Forms

```fsharp:DnDWF.fsx
#r "System"
#r "System.Drawing"
#r "System.Windows.Forms"

open System
open System.Drawing
open System.Windows.Forms

[<EntryPoint; STAThread>] do
let w = new Form(Text = "サンプル", AllowDrop = true)
w.Controls.Add (new Label(Text = "ここにファイルを DnD してください。",
                          Dock = DockStyle.Fill,
                          TextAlign = ContentAlignment.MiddleCenter))
w.DragEnter.Add <| fun e ->
    if e.Data.GetDataPresent DataFormats.FileDrop then
        e.Effect <- DragDropEffects.Link
w.DragDrop.Add <| fun e ->
    let files = e.Data.GetData(DataFormats.FileDrop) :?> string[]
    if files = null then () else
    // ここに処理を書く
    for f in files do
        printfn "%s" f
Application.EnableVisualStyles()
Application.Run w
```

# WPF

```fsharp:DnDWPF.fsx
#r "System"
#r "System.Xaml"
#r "PresentationCore"
#r "PresentationFramework"
#r "WindowsBase"

open System
open System.Windows
open System.Windows.Controls

[<EntryPoint; STAThread>] do
let w = Window(Title = "サンプル",
               Width = 300., Height = 200., AllowDrop = true)
let g = Grid()
g.Children.Add (
    Label(Content = "ここにファイルを DnD してください。",
          HorizontalAlignment = HorizontalAlignment.Center,
          VerticalAlignment = VerticalAlignment.Center)) |> ignore
w.Content <- g
w.DragEnter.Add <| fun e ->
    if e.Data.GetDataPresent DataFormats.FileDrop then
        e.Effects <- DragDropEffects.Link
w.Drop.Add <| fun e ->
    let files = e.Data.GetData(DataFormats.FileDrop) :?> string[]
    if files = null then () else
    // ここに処理を書く
    for f in files do
        printfn "%s" f
Application().Run w |> ignore
```

# 開発

私はこの規模のものは次の環境で扱っています。

* [F#開発環境の紹介](http://qiita.com/7shi/items/5fc7d6477d96bbd7a71d) 2016.12.30

# 配布

作ったプログラムの配布方法として、バイナリ配布とスクリプト配布のケースを紹介します。

## バイナリ配布

F#ランタイム付き（`--standalone`）でコンパイルすれば、実行時にランタイムが必要とならないため手軽です。

```text
fsc --standalone --platform:x86 --target:winexe ソース.fsx
```

## スクリプト配布

ランタイムをインストールしておけば、スクリプト配布も可能です。

* [Microsoft Build Tools 2015](https://www.microsoft.com/ja-JP/download/details.aspx?id=48159)
* [Visual F# Tools 4.0 RTM](https://www.microsoft.com/en-us/download/details.aspx?id=48179)

F#スクリプトは直接実行できるため、Visual Studioやビルド作業は不要です。.fsx ファイルをダブルクリックすれば、どのアプリで開くか選択肢が出て来るので、以下にある fsi.exe を指定すれば起動します。

* (64bit OS) `C:\Program Files (x86)\Microsoft SDKs\F#\4.0\Framework\v4.0\fsi.exe`
* (32bit OS) `C:\Program Files\Microsoft SDKs\F#\4.0\Framework\v4.0\fsi.exe`

「常にこのアプリを使って .fsx ファイルを開く」にチェックを付けておけば、次回からはダブルクリックだけで開けるようになります。
