---
coediting: false
comments_count: 0
created_at: '2023-02-12T18:30:08+09:00'
id: b28767a0f1303bd08245
likes_count: 1
private: false
reactions_count: 0
stocks_count: 1
tags:
- name: F#
  versions: []
- name: WinForms
  versions: []
- name: RichTextBox
  versions: []
- name: Azuki
  versions: []
title: RichTextBox にコンテキストメニューを付ける
updated_at: '2023-02-15T16:40:58+09:00'
url: https://qiita.com/7shi/items/b28767a0f1303bd08245
slide: false
---

Windows Forms の TextBox はデフォルトでコンテキストメニューが用意されていますが、RichTextBox にはありません。簡易的に実装したものを公開します。

# 実装

```fsharp
type EditContextMenu(fUndo, fRedo, fCut, fCopy, fPaste, fDelete, fSelectAll) as this =
    inherit ContextMenuStrip()

    let undo = new ToolStripMenuItem("&Undo", ShortcutKeys = (Keys.Control ||| Keys.Z), ShowShortcutKeys = true)
    let redo = new ToolStripMenuItem("&Redo", ShortcutKeys = (Keys.Control ||| Keys.Y), ShowShortcutKeys = true)
    let cut = new ToolStripMenuItem("Cu&t", ShortcutKeys = (Keys.Control ||| Keys.X), ShowShortcutKeys = true)
    let copy = new ToolStripMenuItem("&Copy", ShortcutKeys = (Keys.Control ||| Keys.C), ShowShortcutKeys = true)
    let paste = new ToolStripMenuItem("&Paste", ShortcutKeys = (Keys.Control ||| Keys.V), ShowShortcutKeys = true)
    let delete = new ToolStripMenuItem("&Delete")
    let selectAll = new ToolStripMenuItem("Select &All", ShortcutKeys = (Keys.Control ||| Keys.A), ShowShortcutKeys = true)

    do
        undo     .Click.Add <| fun _ -> fUndo()
        redo     .Click.Add <| fun _ -> fRedo()
        cut      .Click.Add <| fun _ -> fCut()
        copy     .Click.Add <| fun _ -> fCopy()
        paste    .Click.Add <| fun _ -> fPaste()
        delete   .Click.Add <| fun _ -> fDelete()
        selectAll.Click.Add <| fun _ -> fSelectAll()

        ignore <| this.Items.Add undo
        ignore <| this.Items.Add redo
        ignore <| this.Items.Add(new ToolStripSeparator())
        ignore <| this.Items.Add cut
        ignore <| this.Items.Add copy
        ignore <| this.Items.Add paste
        ignore <| this.Items.Add delete
        ignore <| this.Items.Add(new ToolStripSeparator())
        ignore <| this.Items.Add selectAll

    new(rtb: RichTextBox) as this =
        new EditContextMenu(
            rtb.Undo, rtb.Redo,
            rtb.Cut, rtb.Copy, rtb.Paste,
            (fun _ -> rtb.SelectedText <- ""),
            rtb.SelectAll) then
        this.Opening.Add <| fun _ ->
            this.SetEnabled(
                rtb.CanUndo, rtb.CanRedo,
                rtb.SelectionLength > 0,
                Clipboard.ContainsText() || Clipboard.ContainsImage(),
                rtb.TextLength > 0)

    member _.SetEnabled(u, r, f, p, a) =
        undo     .Enabled <- u
        redo     .Enabled <- r
        cut      .Enabled <- f
        copy     .Enabled <- f
        paste    .Enabled <- p
        delete   .Enabled <- f
        selectAll.Enabled <- a
```

# 使い方

`EditContextMenu.Create` に RichTextBox のインスタンスを渡します。

```fsharp
let rtb = new RichTextBox()
rtb.ContextMenuStrip <- new EditContextMenu(rtb)
```

# Azuki

もともと今回のコンテキストメニューは Azuki というテキストエディタエンジンで使うことを想定していました。

`EditContextMenu.Create` にオーバーロードを追加すれば対応できます。

```fsharp
    new(ac: AzukiControl) as this =
        new EditContextMenu(
            ac.Undo, ac.Redo,
            ac.Cut, ac.Copy, ac.Paste, ac.Delete,
            ac.SelectAll) then
        this.Opening.Add <| fun _ ->
            this.SetEnabled(
                ac.CanUndo, ac.CanRedo,
                ac.GetSelectedTextLength() > 0,
                Clipboard.ContainsText(),
                ac.TextLength > 0)
```

Azuki については以下の記事にリンクをまとめています。

https://qiita.com/7shi/items/1a9b5c17c070b67199b0
