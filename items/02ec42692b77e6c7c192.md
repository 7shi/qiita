---
coediting: false
comments_count: 0
created_at: '2017-02-01T16:01:53+09:00'
id: 02ec42692b77e6c7c192
likes_count: 1
private: false
reactions_count: 0
stocks_count: 0
tags:
- name: F#
  versions: []
title: RAIIでピン止め
updated_at: '2017-02-02T13:16:12+09:00'
url: https://qiita.com/7shi/items/02ec42692b77e6c7c192
slide: false
---

小ネタです。一時的に配列の生ポインタが欲しかったので、[RAII](https://ja.wikipedia.org/wiki/RAII)でピン止めするクラスを作りました。

```fsharp
open System
open System.Runtime.InteropServices

type Pin(o) =
    let gch = GCHandle.Alloc(o, GCHandleType.Pinned)
    member x.Addr = gch.AddrOfPinnedObject()
    interface IDisposable with member x.Dispose() = gch.Free()
```

一行`do`で使う例を示します。

```fsharp
let a = [|0; 1; 2; 3|]
do use p = new Pin(a) in printfn "0x%x" p.Addr
```

# P/Invoke

P/Invokeと組み合わせた例です。

```fsharp
[<DllImport("msvcrt.dll", CallingConvention = CallingConvention.Cdecl)>]
extern int puts(nativeint s)

let s = [|'a'B; 'b'B; 'c'B; 0uy|]
do use p = new Pin(s) in puts p.Addr |> ignore
```

この例では`nativeint`で渡すために無理矢理ピン止めしていますが、普通はそんなことをする必要はありません。

```fsharp
[<DllImport("msvcrt.dll", CallingConvention = CallingConvention.Cdecl)>]
extern int puts(byte[] s)

let s = [|'a'B; 'b'B; 'c'B; 0uy|]
puts s |> ignore
```

ピン止めのことを意識していれば、`byte[]`を指定しても裏側ではマーシャリングでピン止めされている状況が想像できます。

引数に`obj`を指定してもコンパイルは通りますが、実行時にアクセス違反が発生します。

```fsharp:アクセス違反
[<DllImport("msvcrt.dll", CallingConvention = CallingConvention.Cdecl)>]
extern int puts(obj s)

let s = [|'a'B; 'b'B; 'c'B; 0uy|]
puts s |> ignore
```

# 動機

OpenGLには [glVertexPointer()](https://www.opengl.org/sdk/docs/man2/xhtml/glVertexPointer.xml) の第4引数`pointer`のように、引数で渡す配列の型が可変な関数があります。型ごとに別のP/Invokeを定義する以外の方法として、一時的に生ポインタを取得することを試みました。

F#でのOpenGLについては以下の記事を参照してください。

* [F#でOpenGL](http://qiita.com/7shi/items/029343420518b6884d7c) 2017.01.19
