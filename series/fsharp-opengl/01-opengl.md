---
coediting: false
comments_count: 0
created_at: '2017-01-19T16:15:04+09:00'
id: 029343420518b6884d7c
likes_count: 5
private: false
reactions_count: 0
stocks_count: 2
tags:
- name: F#
  versions: []
- name: OpenGL
  versions: []
title: F#でOpenGL
updated_at: '2017-01-31T14:01:03+09:00'
url: https://qiita.com/7shi/items/029343420518b6884d7c
slide: false
---

F#でOpenGLを試してみました。外部ライブラリは使わずWindows Formsに描画します。

次の記事に掲載されたC言語のサンプルをF#に移植しました。

* [その１ ライブラリのインストールとOpenGLの初期化](http://marupeke296.com/OGL_No1_Install.html) 2011.09.21

.NET移植の際に参考にした記事です。

* [OpenGLの初期化](http://sky.geocities.jp/freakish_osprey/opengl/opengl_init.htm) 2009.08.25
* [c# - Making a winform form owner drawable - Stack Overflow](http://stackoverflow.com/questions/3851579/making-a-winform-form-owner-drawable) 2010.10.03

シリーズの記事です。

* F#でOpenGL ← この記事
* [F#にOpenGLの歯車デモを移植](http://qiita.com/7shi/items/efdf0ae04a24bc1b7623)
* [OpenGLでオフスクリーンレンダリング](http://qiita.com/7shi/items/b02f2e45b49c0314fd12)

関連するコードをまとめたリポジトリです。

* https://bitbucket.org/7shi/fsgl

# 実装

完成したコードを説明します。

* [GLTest.fsx](https://bitbucket.org/snippets/7shi/K7Myb)

Win32APIをインポートしてOpenGL用にFormを継承します。

## ディレクティブなど

構造体の警告を抑制します。

```fsharp
#nowarn "9"
```

Windows Forms関係を読み込みます。

```fsharp
#r "System"
#r "System.Drawing"
#r "System.Windows.Forms"

open System
open System.Drawing
open System.Runtime.InteropServices
open System.Windows.Forms
```

## Win32API

定数を定義します。

```fsharp
let CS_VREDRAW =  1
let CS_HREDRAW =  2
let CS_OWNDC   = 32

let PFD_DOUBLEBUFFER   =  1
let PFD_DRAW_TO_WINDOW =  4
let PFD_SUPPORT_OPENGL = 32
```

必要な構造体を定義します。`#nowarn "9"` を指定しないとここで警告されます。

```fsharp
[<Struct; StructLayout(LayoutKind.Sequential)>]
type PIXELFORMATDESCRIPTOR =
    val mutable nSize           : int16
    val mutable nVersion        : int16
    val mutable dwFlags         : int
    val mutable iPixelType      : byte
    val mutable cColorBits      : byte
    val mutable cRedBits        : byte
    val mutable cRedShift       : byte
    val mutable cGreenBits      : byte
    val mutable cGreenShift     : byte
    val mutable cBlueBits       : byte
    val mutable cBlueShift      : byte
    val mutable cAlphaBits      : byte
    val mutable cAlphaShift     : byte
    val mutable cAccumBits      : byte
    val mutable cAccumRedBits   : byte
    val mutable cAccumGreenBits : byte
    val mutable cAccumBlueBits  : byte
    val mutable cAccumAlphaBits : byte
    val mutable cDepthBits      : byte
    val mutable cStencilBits    : byte
    val mutable cAuxBuffers     : byte
    val mutable iLayerType      : byte
    val mutable bReserved       : byte
    val mutable dwLayerMask     : int
    val mutable dwVisibleMask   : int
    val mutable dwDamageMask    : int
```

必要な関数のP/Invokeを定義します。

```fsharp
[<DllImport("user32.dll")>]
extern nativeint GetDC(nativeint hWnd)
[<DllImport("user32.dll")>]
extern int ReleaseDC(nativeint hWnd, nativeint hDC)
[<DllImport("gdi32.dll")>]
extern int ChoosePixelFormat(nativeint hDC, PIXELFORMATDESCRIPTOR& ppfd)
[<DllImport("gdi32.dll", SetLastError = true)>]
extern bool SetPixelFormat(nativeint hDC, int format, PIXELFORMATDESCRIPTOR& ppfd)
[<DllImport("gdi32.dll")>]
extern bool SwapBuffers(nativeint hDC)
[<DllImport("opengl32.dll")>]
extern nativeint wglCreateContext(nativeint hDC)
[<DllImport("opengl32.dll")>]
extern bool wglMakeCurrent(nativeint hDC, nativeint hGLRC)
[<DllImport("opengl32.dll")>]
extern bool wglDeleteContext(nativeint hGLRC)
```

## GLForm

OpenGLを有効にしたFormを継承して実装します。Paintイベント時にOpenGLで描画できるようにします。Windows FormsでOpenGLを使うために最低限必要なことが凝縮されています。

```fsharp
type GLForm() =
    inherit Form()

    let mutable hDC   = 0n
    let mutable hGLRC = 0n

    override x.CreateParams =
        x.SetStyle(ControlStyles.Opaque, true)
        let cp = base.CreateParams
        cp.ClassStyle <- cp.ClassStyle ||| CS_VREDRAW ||| CS_HREDRAW ||| CS_OWNDC
        cp

    override x.OnHandleCreated e =
        base.OnHandleCreated e
        let mutable pfd =
            PIXELFORMATDESCRIPTOR(
                nSize        = (Marshal.SizeOf<PIXELFORMATDESCRIPTOR>() |> int16),
                nVersion     = 1s,
                dwFlags      = (PFD_DOUBLEBUFFER ||| PFD_DRAW_TO_WINDOW ||| PFD_SUPPORT_OPENGL),
                cColorBits   = 32uy,
                cDepthBits   = 24uy,
                cStencilBits = 8uy)
        hDC <- GetDC x.Handle
        let format = ChoosePixelFormat(hDC, &pfd)
        if format = 0 then
            failwith "Can not choose format"
        if not <| SetPixelFormat(hDC, format, &pfd) then
            raise <| ComponentModel.Win32Exception(Marshal.GetLastWin32Error())
        hGLRC <- wglCreateContext hDC

    override x.Dispose disposing =
        ignore <| wglDeleteContext hGLRC
        ignore <| ReleaseDC(x.Handle, hDC)
        base.Dispose disposing

    override x.OnPaint e =
        ignore <| wglMakeCurrent(hDC, hGLRC)
        base.OnPaint e
        ignore <| SwapBuffers hDC
        ignore <| wglMakeCurrent(0n, 0n)
```

ここまではWin32の世界でした。

## OpenGL

ここからはOpenGLの世界です。

今回必要なものだけ定数やP/Invokeを定義します。

```fsharp
let GL_COLOR_BUFFER_BIT = 0x00004000

[<DllImport("opengl32.dll")>]
extern void glClearColor(float32 red, float32 green, float32 blue, float32 alpha)
[<DllImport("opengl32.dll")>]
extern void glClear(int mask)
[<DllImport("opengl32.dll")>]
extern void glFlush()
[<DllImport("opengl32.dll")>]
extern void glRectf(float32 x1, float32 y1, float32 x2, float32 y2)
```

## サンプル

GLFormのPaintイベントでOpenGLによって描画します。

```fsharp
[<EntryPoint; STAThread>] do
let f = new GLForm(Text = "OpenGLテスト", ClientSize = Size(640, 480))
f.Paint.Add <| fun _ ->
    glClearColor(0.0f, 0.5f, 1.0f, 1.0f)
    glClear(GL_COLOR_BUFFER_BIT)
    glRectf(-0.5f, -0.5f, 0.5f, 0.5f)
    glFlush()
Application.Run f
```

![OpenGL.png](https://qiita-image-store.s3.amazonaws.com/0/32057/45f0fbf7-7527-9109-2681-82d21f6d8e41.png)

無事に描画できました。
