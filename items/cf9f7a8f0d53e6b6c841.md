---
coediting: false
comments_count: 0
created_at: '2022-01-12T14:44:28+09:00'
id: cf9f7a8f0d53e6b6c841
likes_count: 1
private: false
reactions_count: 0
stocks_count: 1
tags:
- name: C#
  versions: []
- name: .NETFramework
  versions: []
- name: WinForms
  versions: []
- name: WMF
  versions: []
title: RichTextBoxに画像を挿入
updated_at: '2022-01-12T22:33:53+09:00'
url: https://qiita.com/7shi/items/cf9f7a8f0d53e6b6c841
slide: false
---

画像データを WMF に埋め込んで Windows Forms の RichTextBox に挿入します。

# 概要

RichTextBox には画像を挿入するメソッドがありません。検索するとクリップボード経由で渡す方法がよく紹介されますが、今回は画像を含む RTF を生成して挿入します。

RTF の仕様には PNG など各種形式が含まれますが、RichTextBox が受け付けるのは WMF のみです。検索すると P/Invoke で WMF を生成する方法が見付かりますが、今回は直接 WMF を生成します。

# 実装

WMF に埋め込む DIB は BMP ファイルの 14 バイト以降です。画像を BMP に書き出して使用します。

```cs
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Text;

public class ImageToRtf
{
    public static void Write16(StringBuilder sb, params int[] args)
    {
        foreach (int w in args)
        {
            sb.AppendFormat("{0:X2}{1:X2}", w & 0xff, (w >> 8) & 0xff);
        }
    }

    public static string Convert(Image img, Color back)
    {
        int w = img.Width, h = img.Height;
        int picw = w * 2540 / 96, pich = h * 2540 / 96;
        int picwgoal = w * 1440 / 96, pichgoal = h * 1440 / 96;

        var sb = new StringBuilder();
        sb.AppendFormat(
            @"{{\rtf1{{\pict\wmetafile8\picw{0}\pich{1}\picwgoal{2}\pichgoal{3} ",
            picw, pich, picwgoal, pichgoal);

        byte[] bmp;
        using (var bitmap = new Bitmap(w, h))
        {
            using (var g = Graphics.FromImage(bitmap))
            {
                g.Clear(back);
                g.DrawImage(img, 0, 0, w, h);
            }
            using (var ms = new MemoryStream())
            {
                bitmap.Save(ms, ImageFormat.Bmp);
                bmp = ms.ToArray();
            }
        }

        int size1 = 14 + (bmp.Length - 14) / 2;
        int size2 = 9 + 5 + 5 + size1 + 3;

        Write16(sb,
            // META_HEADER Record
            1, 9, 0x300, size2, size2 >> 16, 0, size1, size1 >> 16, 0,
            // META_SETWINDOWORG Record
            5, 0, 0x20b, 0, 0,
            // META_SETWINDOWEXT Record
            5, 0, 0x20c, pich, picw,
            // META_STRETCHDIB Record
            size1, size1 >> 16, 0xf43, 0x20, 0xcc, 0, h, w, 0, 0, pich, picw, 0, 0
        );
        sb.Append(BitConverter.ToString(bmp, 14).Replace("-", ""));
        Write16(sb, 3, 0, 0); // META_EOF Record
        sb.Append("}}");

        return sb.ToString();
    }
}
```

# 使用例

透過色はサポートされないため、背景色を指定します。

```cs
var rtb = new RichTextBox();
using (var bmp = new Bitmap("test.png"))
{
    rtb.SelectedRtf = ImageToRtf.Convert(bmp, Color.White);
}
```

# 参考

WMF の仕様です。

* [[MS-WMF]: Windows Metafile Format | Microsoft Docs](https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-wmf/4813e7fd-52d0-4f42-965f-228c8b7488d2)

同じ目的のコードです。これらをベースに整理しました。

* [Insert image in RichTextBox without quality loss (WMF) - CodeProject](https://www.codeproject.com/Questions/540673/InsertplusimageplusinplusRichTextBoxpluswithoutplu)
* [c# - Programmatically adding Images to RTF Document - Stack Overflow](https://stackoverflow.com/questions/1490734/programmatically-adding-images-to-rtf-document)
* [[C#][WPF][WinForms]RichTextBoxで画像(JPEG)を挿入する。 - ガラクタの軌跡](https://garakutatech.blogspot.com/2021/01/cwpfwinformsrichtextboxjpeg.html)
