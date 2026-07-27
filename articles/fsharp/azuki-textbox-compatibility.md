---
coediting: false
comments_count: 0
created_at: '2023-02-15T16:04:47+09:00'
id: 1a9b5c17c070b67199b0
likes_count: 1
private: false
reactions_count: 0
stocks_count: 0
tags:
- name: F#
  versions: []
- name: .NETFramework
  versions: []
- name: WinForms
  versions: []
- name: Azuki
  versions: []
title: Azuki に TextBox 互換のメンバを追加
updated_at: '2023-02-23T18:51:47+09:00'
url: https://qiita.com/7shi/items/1a9b5c17c070b67199b0
slide: false
---

手っ取り早く TextBox を AzukiControl に置き換えるため、いくつかメソッドやプロパティを追加しました。

※ 部分的な実装のため完全互換ではありません。

# Azuki

Azuki は C# 2.0 で書かれたフリーのテキストエディタエンジンです。

https://azuki.osdn.jp/

https://github.com/kkato233/azuki

https://srad.jp/story/09/01/27/0547207/

# AzukiTextBox

Azuki はメンバ名などある程度は TextBox を意識しているようですが、互換ではありません。

AzukiControl を継承して必要最低限のメソッドやプロパティを追加します。

```fsharp
type AzukiTextBox() as this =
    inherit AzukiControl()

    member _.Select(start, length) =
        this.SetSelection(start, start + length)
    member _.DeselectAll() =
        this.SelectionLength <- 0
    member _.SelectionStart
        with get() = this.GetSelection() |> fst
        and set(index) = this.SetSelection(index, index)
    member _.SelectionLength
        with get() = this.GetSelectedTextLength()
        and set(length) = this.Select(this.SelectionStart, length)
    member _.SelectedText
        with get() = this.GetSelectedText()
        and set(text) = this.Document.Replace(text)

    member _.Lines =
        let doc = this.Document
        Array.init<string> doc.LineCount doc.GetLineContent
    member _.GetLineFromCharIndex index =
        this.GetLineIndexFromCharIndex index
    member _.GetFirstCharIndexFromLine line =
        this.GetLineHeadIndex line
    member _.GetFirstCharIndexOfCurrentLine() =
        this.GetLineHeadIndexFromCharIndex this.SelectionStart
```

※ 少し名前が違うだけのものを追加するのはどうなのかという気もしますが、既存のコードになるべく手を入れずに使いたかったための措置です。

# メモ

* タブ関連 `UsesTabForIndent = false, TabWidth = 2`
* 自動インデント `AutoIndentHook = AutoIndentHooks.GenericHook`
* コンテキストメニュー

https://qiita.com/7shi/items/b28767a0f1303bd08245

# 使用感

* API のすり合わせをして TextBox と差し替えましたが、コンパイルが通ればすんなり動きました。
* undo/redo が柔軟になるので、それだけでも差し替える価値があります。
* TextBox と同様の Windows 標準のキーバインドで、挙動にあまり違和感はありません。
* 5000 行程度のファイルを読ませると少し時間が掛かります。

# 参考

https://yaneurao.hatenadiary.com/entry/20100519/p9

https://yaneurao.hatenadiary.com/entry/20100519/p10
