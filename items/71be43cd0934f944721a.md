---
coediting: false
comments_count: 0
created_at: '2023-02-13T16:00:44+09:00'
id: 71be43cd0934f944721a
likes_count: 1
private: false
reactions_count: 0
stocks_count: 2
tags:
- name: F#
  versions: []
- name: スクリーンショット
  versions: []
- name: GDI
  versions: []
title: GDI ベースの画面キャプチャ
updated_at: '2023-02-15T13:15:40+09:00'
url: https://qiita.com/7shi/items/71be43cd0934f944721a
slide: false
---

昔ながらの GDI ベースの画面キャプチャについて、.NET Framework で完結する方法と、Win32 API を使う方法を示します。

# 使用例

何種類かの `captureScreen` の実装を示しますが使い方は共通です。

プライマリスクリーン全体をキャプチャして画像ファイルに保存する例です。

```fsharp
open System.Drawing
open System.Drawing.Imaging
open System.Windows.Forms

do
    use bmp = captureScreen(Screen.PrimaryScreen.Bounds)
    bmp.Save("screen.png", ImageFormat.Png)
```

# Graphics.CopyFromScreen

以前は問題がありましたが、今は安定しているようなのでこちらを使うのが簡単です。

```fsharp
let captureScreen (r: Rectangle) =
    let ret = new Bitmap(r.Width, r.Height)
    use g = Graphics.FromImage ret
    g.CopyFromScreen(r.Location, Point.Empty, r.Size)
    ret
```

`CaptureBlt` を指定しなければ半透明のウィンドウがキャプチャできないという情報がありますが、手元で試した限り Windows 10 では特に問題ないようです。（[DWM](https://learn.microsoft.com/ja-jp/windows/win32/dwm/dwm-overview?source=recommendations) 実装以前の状況だと思われます）

https://dobon.net/vb/dotnet/graphics/screencapture.html

# P/Invoke

`Graphics.CopyFromScreen` が安定しなかった頃に使っていたコードです。

使っている Win32 API は `GetDesktopWindow()` と `BitBlt()` です。

※ Bitblt は [Bit Block Transfer](https://ja.wikipedia.org/wiki/Bit_Block_Transfer) の略でビットブリットと読まれます。

```fsharp
open System.Drawing
open System.Drawing.Imaging
open System.Runtime.InteropServices

[<DllImport("user32.dll")>] extern nativeint GetDesktopWindow()
[<DllImport("gdi32.dll")>] extern bool BitBlt(
    nativeint hdcDest, int nXDest, int nYDest, int nWidth, int nHeight,
    nativeint hdcSrc, int nXSrc, int nYSrc, int dwRop)

let captureScreen (r: Rectangle) =
    let ret = new Bitmap(r.Width, r.Height, PixelFormat.Format32bppRgb)
    let desktop = GetDesktopWindow()
    use g1 = Graphics.FromImage ret
    use g2 = Graphics.FromHwnd desktop
    let hdc1 = g1.GetHdc()
    let hdc2 = g2.GetHdc()
    ignore <| BitBlt(
        hdc1, 0, 0, r.Width, r.Height,
        hdc2, r.X, r.Y, 
        int CopyPixelOperation.SourceCopy)
    g1.ReleaseHdc(hdc1)
    g2.ReleaseHdc(hdc2)
    ret
```

`PixelFormat.Format32bppRgb` を指定しないと黒い部分が透過されて白いゴミが出ます。

`GetDesktopWindow()` ではなく `IntPtr.Zero` を使ったコードも紹介されますが、両者の違いについての議論があります。

https://dobon.net/vb/bbs/log3-25/14968.html

## BeginPaint ～ EndPaint

`Graphics.FromHwnd` が使えることに気付かなかったときに使っていたコードです。構造体も定義するなど大掛かりになっています。

※ 今となっては使う意味はありませんが、参考までに掲載します。

```fsharp
open System.Drawing
open System.Drawing.Imaging
open System.Runtime.InteropServices

[<StructLayout(LayoutKind.Sequential)>]
type RECT =
    struct
        val mutable left  : int
        val mutable top   : int
        val mutable right : int
        val mutable bottom: int
        new (l, t, r, b) = { left = l; top = t; right = r; bottom = b }
        static member Empty = RECT(0, 0, 0, 0)
    end

[<StructLayout(LayoutKind.Sequential)>]
type PAINTSTRUCT =
    struct
        val mutable hdc        : nativeint
        val mutable fErase     : bool
        val mutable rcPaint    : RECT
        val mutable fRestore   : bool
        val mutable fIncUpdate : bool
        [<MarshalAs(UnmanagedType.ByValArray, SizeConst = 32)>]
        val mutable rgbReserved:byte[]
        new (h, fe, r, fr, fi, rgb) =
            { hdc = h; fErase = fe; rcPaint = r; fRestore = fr; fIncUpdate = fi; rgbReserved = rgb }
        static member Empty =
            PAINTSTRUCT(nativeint 0, false, RECT.Empty, false, false, Array.zeroCreate<byte> 32)
    end

[<DllImport("user32.dll")>] extern nativeint GetDesktopWindow()
[<DllImport("user32.dll")>] extern nativeint BeginPaint(nativeint hwnd, PAINTSTRUCT& lpPaint)
[<DllImport("user32.dll")>] extern bool EndPaint(nativeint hWnd, PAINTSTRUCT& lpPaint)

let SRCCOPY = 0x00cc0020
[<DllImport("gdi32.dll")>] extern bool BitBlt(
    nativeint hdcDest, int nXDest, int nYDest, int nWidth, int nHeight,
    nativeint hdcSrc, int nXSrc, int nYSrc, int dwRop)

let captureScreen (r: Rectangle) =
    let ret = new Bitmap(r.Width, r.Height)
    let desktop = GetDesktopWindow()
    use g = Graphics.FromImage(ret)
    g.FillRectangle(Brushes.Black, 0, 0, r.Width, r.Height)
    let hdc1 = g.GetHdc()
    let mutable ps = PAINTSTRUCT.Empty
    let hdc2 = BeginPaint(desktop, &ps)
    ignore <| BitBlt(hdc1, 0, 0, r.Width, r.Height, hdc2, r.X, r.Y, SRCCOPY)
    ignore <| EndPaint(desktop, &ps)
    g.ReleaseHdc(hdc1)
    ret
```

# 関連情報

ネットワークへの応用です。

https://qiita.com/7shi/items/f59b6804167717f8f2d6

今回は画面全体を対象にしましたが、特定のウィンドウだけをキャプチャするなら `PrintWindow()` が便利です。

https://dobon.net/vb/dotnet/graphics/invokepaint.html
