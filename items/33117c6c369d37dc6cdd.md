---
coediting: false
comments_count: 0
created_at: '2017-01-16T15:06:38+09:00'
id: 33117c6c369d37dc6cdd
likes_count: 11
private: false
reactions_count: 0
stocks_count: 8
tags:
- name: F#
  versions: []
- name: GIF
  versions: []
title: GIFのバイナリを読んでみた
updated_at: '2017-01-18T18:25:06+09:00'
url: https://qiita.com/7shi/items/33117c6c369d37dc6cdd
slide: false
---

GIFの仕様書を見ながら小さなGIFファイルを読んでみました。調査結果を基に手を加えてアニメーション化を試み、差分を示しました。

シリーズの記事です。

1. GIFのバイナリを読んでみた ← この記事
1. [GIFのLZW圧縮を調べてみた](http://qiita.com/7shi/items/cfe1c6e42aff78c06652)
1. [GIFのLZWを展開してみた](http://qiita.com/7shi/items/778f58d4647b10f0f403)

# 参考

英語版Wikipediaと、そこからリンクされている仕様書を参照しました。

* [GIF - Wikipedia](https://en.wikipedia.org/wiki/GIF)
* [Cover Sheet for the GIF89a Specification](http://www.w3.org/Graphics/GIF/spec-gif89a.txt)

# サンプル

GIMPで16×16の画像を作りました。

![gif1.gif](https://qiita-image-store.s3.amazonaws.com/0/32057/d6692680-9082-986f-a486-a8e4c2156ce0.gif)

```text:バイナリダンプ
00000000  47 49 46 38 37 61 10 00  10 00 a1 02 00 00 00 00  |GIF87a..........|
00000010  80 80 80 ff ff ff ff ff  ff 2c 00 00 00 00 10 00  |.........,......|
00000020  10 00 00 02 2b 94 8f a9  16 b0 0b 42 78 c8 09 4b  |....+......Bx..K|
00000030  b1 a4 fb 60 f5 5d 4f 28  74 47 03 a4 91 07 22 92  |...`.]O(tG....".|
00000040  14 bd e5 b4 98 62 56 51  f7 ac db fa fe 43 14 00  |.....bVQ.....C..|
00000050  00 3b                                             |.;|
```

## 解読

仕様書を見ながらコメントを付けます。仕様書の該当するセクションを記載します。

* F#で文字の `B` や数値の `uy` は `byte` 型を表すサフィックスで、省略できません。
* Width, Height などの2バイト値はリトルエンディアンです。

```fsharp:GIFTest.fsx
let gif = [|
    // 17. Header.
    'G'B; 'I'B; 'F'B  // Signature
    '8'B; '7'B; 'a'B  // Version

    // 18. Logical Screen Descriptor.
    16uy; 0uy  // Logical Screen Width
    16uy; 0uy  // Logical Screen Height
    0xA1uy     // <Packed Fields>
               //   Global Color Table Flag
               //   | Color Resolution
               //   | |   Sort Flag
               //   | |   | Size of Global Color Table
               //   1 010 0 001
    2uy        // Background Color Index
    0uy        // Pixel Aspect Ratio

    // 19. Global Color Table.
    0x00uy; 0x00uy; 0x00uy  // RGB #0
    0x80uy; 0x80uy; 0x80uy  // RGB #1
    0xFFuy; 0xFFuy; 0xFFuy  // RGB #2
    0xFFuy; 0xFFuy; 0xFFuy  // RGB #3

    // 20. Image Descriptor.
    0x2Cuy     // Image Separator
    0uy ; 0uy  // Image Left Position
    0uy ; 0uy  // Image Top Position
    16uy; 0uy  // Image Width
    16uy; 0uy  // Image Height
    0uy        // <Packed Fields>
               //   Local Color Table Flag
               //   | Interlace Flag
               //   | | Sort Flag
               //   | | | Reserved
               //   | | | |  Size of Local Color Table
               //   0 0 0 00 000

    // 22. Table Based Image Data.
    2uy     // LZW Minimum Code Size
    // F. Variable-Length-Code LZW Compression.
    0x2Buy  // block size
            // data bytes
    0x94uy; 0x8Fuy; 0xA9uy; 0x16uy; 0xB0uy; 0x0Buy; 0x42uy; 0x78uy
    0xC8uy; 0x09uy; 0x4Buy; 0xB1uy; 0xA4uy; 0xFBuy; 0x60uy; 0xF5uy
    0x5Duy; 0x4Fuy; 0x28uy; 0x74uy; 0x47uy; 0x03uy; 0xA4uy; 0x91uy
    0x07uy; 0x22uy; 0x92uy; 0x14uy; 0xBDuy; 0xE5uy; 0xB4uy; 0x98uy
    0x62uy; 0x56uy; 0x51uy; 0xF7uy; 0xACuy; 0xDBuy; 0xFAuy; 0xFEuy
    0x43uy; 0x14uy; 0x00uy
    0uy     // Block Terminator

    // 27. Trailer.
    0x3Buy  // GIF Trailer
|]
```

## 表示

先ほどのコードに付け足しで画面表示します。

```fsharp:GIFTest.fsx（続き）
#r "System"
#r "System.Drawing"
#r "System.Windows.Forms"

open System
open System.IO
open System.Drawing
open System.Windows.Forms

[<EntryPoint; STAThread>] do
let w = new Form(Text = "GIF", Size = Size(180, 100))
let p = new PictureBox(Dock = DockStyle.Fill,
                       SizeMode = PictureBoxSizeMode.CenterImage)
try
    p.Image <- Image.FromStream(new MemoryStream(gif))
with _ -> ()
w.Controls.Add p
Application.EnableVisualStyles()
Application.Run w
```
![gif.png](https://qiita-image-store.s3.amazonaws.com/0/32057/2bb80dd4-4284-3d16-4be2-ed13d4b535b0.png)

* [コード全体](https://bitbucket.org/snippets/7shi/gpn7q/revisions/bf96ced1f11926819e4554472377d6bbef5d4258)

# GIFアニメーション化

3ステップでGIFを手動編集してアニメーション化を試みます。

## カラーテーブルのローカル化

後で複数のGIFを連結することを想定して、手動でカラーテーブルをローカルに移します。

* Background Color Index: 情報が消えますが、とりあえず無視します。
* Color Resolution: 個々の画像を見ないと分かりませんが、簡単のため111に決め打ちします。

```diff:GIFTest-L.diff
--- GIFTest.fsx
+++ GIFTest-L.fsx
@@ -6,34 +6,34 @@
     // 18. Logical Screen Descriptor.
     16uy; 0uy  // Logical Screen Width
     16uy; 0uy  // Logical Screen Height
-    0xA1uy     // <Packed Fields>
+    0x70uy     // <Packed Fields>
                //   Global Color Table Flag
                //   | Color Resolution
                //   | |   Sort Flag
                //   | |   | Size of Global Color Table
-               //   1 010 0 001
-    2uy        // Background Color Index
+               //   0 111 0 000
+    0uy        // Background Color Index
     0uy        // Pixel Aspect Ratio
 
-    // 19. Global Color Table.
-    0x00uy; 0x00uy; 0x00uy  // RGB #0
-    0x80uy; 0x80uy; 0x80uy  // RGB #1
-    0xFFuy; 0xFFuy; 0xFFuy  // RGB #2
-    0xFFuy; 0xFFuy; 0xFFuy  // RGB #3
-
     // 20. Image Descriptor.
     0x2Cuy     // Image Separator
     0uy ; 0uy  // Image Left Position
     0uy ; 0uy  // Image Top Position
     16uy; 0uy  // Image Width
     16uy; 0uy  // Image Height
-    0uy        // <Packed Fields>
+    0x81uy     // <Packed Fields>
                //   Local Color Table Flag
                //   | Interlace Flag
                //   | | Sort Flag
                //   | | | Reserved
                //   | | | |  Size of Local Color Table
-               //   0 0 0 00 000
+               //   1 0 0 00 001
+
+    // 21. Local Color Table.
+    0x00uy; 0x00uy; 0x00uy  // RGB #0
+    0x80uy; 0x80uy; 0x80uy  // RGB #1
+    0xFFuy; 0xFFuy; 0xFFuy  // RGB #2
+    0xFFuy; 0xFFuy; 0xFFuy  // RGB #3
 
     // 22. Table Based Image Data.
     2uy     // LZW Minimum Code Size
```

* [コード全体](https://bitbucket.org/snippets/7shi/gpn7q/revisions/8637066554bf4aae9b329b63328d394db3719158)

## アニメーション化（1フレーム）

ループ回数（0で無限）とフレーム情報を入れてアニメーション化します。1フレームを無限に繰り返すためアニメーションしているようには見えません。

※ ループ回数はNetscapeのアプリケーション拡張として定義します。

```diff:GIFTest-A.diff
--- GIFTest-L.fsx
+++ GIFTest-A.fsx
@@ -1,7 +1,7 @@
 let gif = [|
     // 17. Header.
     'G'B; 'I'B; 'F'B  // Signature
-    '8'B; '7'B; 'a'B  // Version
+    '8'B; '9'B; 'a'B  // Version
 
     // 18. Logical Screen Descriptor.
     16uy; 0uy  // Logical Screen Width
@@ -15,6 +15,32 @@
     0uy        // Background Color Index
     0uy        // Pixel Aspect Ratio
 
+    // 26. Application Extension.
+    0x21uy            // Extension Introducer
+    0xFFuy            // Extension Label
+    11uy              // Block Size
+                      // Application Identifier
+    'N'B; 'E'B; 'T'B; 'S'B; 'C'B; 'A'B; 'P'B; 'E'B
+    '2'B; '.'B; '0'B  // Appl. Authentication Code
+    3uy               // Application Data Size
+    1uy               // data sub-block index (always 1)
+    0uy; 0uy          // unsigned number of repetitions
+    0uy               // Block Terminator
+
+    // 23. Graphic Control Extension.
+    0x21uy     // Extension Introducer
+    0xF9uy     // Graphic Control Label
+    4uy        // Block Size
+    0uy        // <Packed Fields>
+               //   Reserved
+               //   |   Disposal Method
+               //   |   |   User Input Flag
+               //   |   |   | Transparent Color Flag
+               //   000 000 0 0
+    10uy; 0uy  // Delay Time (10ms * 10 = 0.1s)
+    0uy        // Transparent Color Index
+    0uy        // Block Terminator
+
     // 20. Image Descriptor.
     0x2Cuy          // Image Separator
     0x00uy; 0x00uy  // Image Left Position
```

* [コード全体](https://bitbucket.org/snippets/7shi/gpn7q/revisions/c80f28dcf67df3f571a5ba59ce77d50792fb0642)

## アニメーション化（2フレーム）

パレットを変えて赤字にした同じ絵を追加してアニメーションさせます。

```diff:GIFTest-A2.diff
--- GIFTest-A.fsx
+++ GIFTest-A2.fsx
@@ -74,6 +74,53 @@
     0x43uy; 0x14uy; 0x00uy
     0uy     // Block Terminator
 
+    // 23. Graphic Control Extension.
+    0x21uy     // Extension Introducer
+    0xF9uy     // Graphic Control Label
+    4uy        // Block Size
+    0uy        // <Packed Fields>
+               //   Reserved
+               //   |   Disposal Method
+               //   |   |   User Input Flag
+               //   |   |   | Transparent Color Flag
+               //   000 000 0 0
+    10uy; 0uy  // Delay Time (10ms * 10 = 0.1s)
+    0uy        // Transparent Color Index
+    0uy        // Block Terminator
+
+    // 20. Image Descriptor.
+    0x2Cuy     // Image Separator
+    0uy ; 0uy  // Image Left Position
+    0uy ; 0uy  // Image Top Position
+    16uy; 0uy  // Image Width
+    16uy; 0uy  // Image Height
+    0x81uy     // <Packed Fields>
+               //   Local Color Table Flag
+               //   | Interlace Flag
+               //   | | Sort Flag
+               //   | | | Reserved
+               //   | | | |  Size of Local Color Table
+               //   1 0 0 00 001
+
+    // 21. Local Color Table.
+    0xFFuy; 0x00uy; 0x00uy  // RGB #0
+    0xFFuy; 0x80uy; 0x80uy  // RGB #1
+    0xFFuy; 0xFFuy; 0xFFuy  // RGB #2
+    0xFFuy; 0xFFuy; 0xFFuy  // RGB #3
+
+    // 22. Table Based Image Data.
+    2uy     // LZW Minimum Code Size
+    // F. Variable-Length-Code LZW Compression.
+    0x2Buy  // block size
+            // data bytes
+    0x94uy; 0x8Fuy; 0xA9uy; 0x16uy; 0xB0uy; 0x0Buy; 0x42uy; 0x78uy
+    0xC8uy; 0x09uy; 0x4Buy; 0xB1uy; 0xA4uy; 0xFBuy; 0x60uy; 0xF5uy
+    0x5Duy; 0x4Fuy; 0x28uy; 0x74uy; 0x47uy; 0x03uy; 0xA4uy; 0x91uy
+    0x07uy; 0x22uy; 0x92uy; 0x14uy; 0xBDuy; 0xE5uy; 0xB4uy; 0x98uy
+    0x62uy; 0x56uy; 0x51uy; 0xF7uy; 0xACuy; 0xDBuy; 0xFAuy; 0xFEuy
+    0x43uy; 0x14uy; 0x00uy
+    0uy     // Block Terminator
+
     // 27. Trailer.
     0x3Buy  // GIF Trailer
 |]
```
![gif-a2.gif](https://qiita-image-store.s3.amazonaws.com/0/32057/dade5c91-8003-745a-f410-feea9cb75a5c.gif)

* [コード全体](https://bitbucket.org/snippets/7shi/gpn7q)

# 感想

GIFはシンプルな構造で、バイナリいじりの入門にも良いかもしれないと思いました。結果がアニメーションするので面白いです。
