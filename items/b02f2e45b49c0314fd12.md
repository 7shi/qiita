---
coediting: false
comments_count: 0
created_at: '2017-01-30T18:13:28+09:00'
id: b02f2e45b49c0314fd12
likes_count: 2
private: false
reactions_count: 0
stocks_count: 2
tags:
- name: F#
  versions: []
- name: OpenGL
  versions: []
title: OpenGLでオフスクリーンレンダリング
updated_at: '2017-02-12T00:23:56+09:00'
url: https://qiita.com/7shi/items/b02f2e45b49c0314fd12
slide: false
---

Windows FormsにOpenGLで描画できるようになったので、オフスクリーンレンダリングを試みました。今回はOpenGLのフレームバッファではなくWin32APIを使用します。

![OSGears.gif](https://qiita-image-store.s3.amazonaws.com/0/32057/ca22cc76-ae88-3855-434f-3a257e1fd7e9.gif)

シリーズの記事です。

* [F#でOpenGL](http://qiita.com/7shi/items/029343420518b6884d7c)
* [F#にOpenGLの歯車デモを移植](http://qiita.com/7shi/items/efdf0ae04a24bc1b7623)
* OpenGLでオフスクリーンレンダリング ← この記事

関連するコードをまとめたリポジトリです。

* https://bitbucket.org/7shi/fsgl

<font color="red">**【注意】**</font>この記事のサンプルは[レガシーなAPI](https://www.khronos.org/opengl/wiki/Legacy_OpenGL)を使っています。新しいAPIへの移行は機会を改めることにして、今回はレガシーなまま進めます。

# 参考

Mesaのサイトに最低限の説明があります。

http://www.mesa3d.org/brianp/sig97/offscrn.htm#wgl

> Basically, a bitmap is created with CreateDIBSection. A pixel format with the PFD_DRAW_TO_BITMAP, PFD_SUPPORT_OPENGL, PFD_SUPPORT_GDI flags must be chosen. After creating a WGL context and binding it, OpenGL rendering can proceed. 

これだけでは良く分からないため、以下の記事を参照しました。

* [プログラミングメモ日記 OpenGLで直接ビットマップに描画する方法についてまとめ](http://qwertyfk.blog16.fc2.com/blog-entry-74.html) 2012.01.02
* [CreateDIBSectionによる汎用ビットマップ](http://lcl.web5.jp/prog/dibsec.html) 2007.06.28

# 実装

Win32APIの構造体やP/Invokeを定義します。

```fsharp
[<Struct; StructLayout(LayoutKind.Sequential)>]
type BITMAPINFOHEADER =
    val mutable biSize          : int
    val mutable biWidth         : int
    val mutable biHeight        : int
    val mutable biPlanes        : int16
    val mutable biBitCount      : int16
    val mutable biCompression   : int
    val mutable biSizeImage     : int
    val mutable biXPelsPerMeter : int
    val mutable biYPelsPerMeter : int
    val mutable biClrUsed       : int
    val mutable biClrImportant  : int

let PFD_DRAW_TO_BITMAP =  8
let PFD_SUPPORT_GDI    = 16

let DIB_PAL_COLORS = 1

[<DllImport("gdi32.dll")>]
extern nativeint CreateDIBSection(nativeint hdc, BITMAPINFOHEADER& lpbmi, int usage,
                                  nativeint& ppvBits, nativeint hSection, int offset)
[<DllImport("gdi32.dll")>]
extern nativeint CreateCompatibleDC(nativeint hdc)
[<DllImport("gdi32.dll")>]
extern nativeint SelectObject(nativeint hdc, nativeint h)
[<DllImport("gdi32.dll")>]
extern bool DeleteDC(nativeint hdc)
[<DllImport("gdi32.dll")>]
extern bool DeleteObject(nativeint ho)
```

使いやすいようにクラスで包みます。

```fsharp
type GLBitmap(width, height) =
    let mutable hBMP  = 0n
    let mutable hDC   = 0n
    let mutable hOld  = 0n
    let mutable hGLRC = 0n

    do
        let mutable bmi =
            BITMAPINFOHEADER(
                biSize        = Marshal.SizeOf<BITMAPINFOHEADER>(),
                biWidth       = width,
                biHeight      = height,
                biPlanes      = 1s,
                biBitCount    = 32s)
        let mutable ppvBits = 0n
        hBMP <- CreateDIBSection(0n, &bmi, DIB_PAL_COLORS, &ppvBits, 0n, 0)
        let hdc = GetDC 0n
        hDC <- CreateCompatibleDC(hdc)
        ignore <| ReleaseDC(0n, hdc)
        hOld <- SelectObject(hDC, hBMP)
        let mutable pfd =
            PIXELFORMATDESCRIPTOR(
                nSize        = (Marshal.SizeOf<PIXELFORMATDESCRIPTOR>() |> int16),
                nVersion     = 1s,
                dwFlags      = (PFD_DRAW_TO_BITMAP ||| PFD_SUPPORT_OPENGL ||| PFD_SUPPORT_GDI),
                cColorBits   = 32uy,
                cDepthBits   = 24uy,
                cStencilBits = 8uy)
        let format = ChoosePixelFormat(hDC, &pfd)
        if format = 0 then
            failwith "Can not choose format"
        if not <| SetPixelFormat(hDC, format, &pfd) then
            raise <| ComponentModel.Win32Exception(Marshal.GetLastWin32Error())
        hGLRC <- wglCreateContext hDC

    interface IDisposable with
        override x.Dispose() =
            ignore <| wglDeleteContext hGLRC
            ignore <| SelectObject(hDC, hOld)
            ignore <| DeleteDC hDC
            ignore <| DeleteObject hBMP

    member x.MakeCurrent() =
        ignore <| wglMakeCurrent(hDC, hGLRC)
        new RAII(fun () -> ignore <| wglMakeCurrent(0n, 0n))

    member x.Width  = width
    member x.Height = height
    member x.Handle = hBMP
```

やっていることは[前回の記事](http://qiita.com/7shi/items/efdf0ae04a24bc1b7623)とほぼ同じで、ウィンドウに関する記述をビットマップで置き換えています。

以上で実装したコードは[GL7.fsx](https://bitbucket.org/7shi/fsgl/src/tip/GL7.fsx)に追加しました。

# サンプル

歯車のサンプルをオフスクリーンレンダリングして画像ファイルに書き出すようにしました。主要部を引用します。

```fsharp
let dir = "output"
if not <| Directory.Exists dir then
    ignore <| Directory.CreateDirectory dir
let bmp = new GLBitmap(256, 256)
do  use raii = bmp.MakeCurrent()
    init()
    reshape bmp.Width bmp.Height
for i = 0 to 8 do
    angle <- float32 i * 2.f
    do use raii = bmp.MakeCurrent() in draw()
    use img = Image.FromHbitmap bmp.Handle
    let fn = sprintf "%02d.png" i
    printfn "%s" fn
    img.Save(Path.Combine(dir, fn), ImageFormat.Png)
```

プログラム全体です。

* [OSGears.fsx](https://bitbucket.org/7shi/fsgl/src/tip/OSGears.fsx)

※ 依存しているファイルは[リポジトリ](https://bitbucket.org/7shi/fsgl)を参照してください。

# 画面表示

オフスクリーンレンダリングであることを示すためサンプルではウィンドウに表示しませんでしたが、画面表示の例を示します。

```fsharp
[<EntryPoint; STAThread>] do
let size = Size(256, 256)
let f = new Form(Text = "Gears (Off-Screen Rendering)", ClientSize = size)
let bmp = new GLBitmap(size.Width, size.Height)
do  use raii = bmp.MakeCurrent()
    init()
    reshape size.Width size.Height
let p = new PictureBox(Dock = DockStyle.Fill)
p.Paint.Add <| fun e ->
    draw()
    angle <- angle + 0.1f  //2.0f
    do use raii = bmp.MakeCurrent() in draw()
    use img = Image.FromHbitmap bmp.Handle
    e.Graphics.DrawImage(img, (p.Width - size.Width) / 2, (p.Height - size.Height) / 2)
    p.Invalidate()
f.Controls.Add p
Application.Run f
```
