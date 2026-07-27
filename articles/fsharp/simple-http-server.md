---
coediting: false
comments_count: 0
created_at: '2023-02-13T03:54:27+09:00'
id: f59b6804167717f8f2d6
likes_count: 1
private: false
reactions_count: 0
stocks_count: 1
tags:
- name: F#
  versions: []
- name: TCP
  versions: []
- name: httpd
  versions: []
title: TcpListener で簡易 HTTP サーバーを作る
updated_at: '2023-02-15T12:50:51+09:00'
url: https://qiita.com/7shi/items/f59b6804167717f8f2d6
slide: false
---

.NET の TcpListener で簡単な HTTP サーバーを作ります。

# 経緯

.NET には HttpListener がありますが、マルウェア誤判定や管理者権限やファイアーウォールなどであまり使い勝手が良くありません。

https://qiita.com/7shi/items/bcf1998f1dd3755ac82c

仕方ないので TcpListener で HTTP を扱うことにしました。

# 実装

8080 番ポートで待ち受けて Hello, HTTP! と返します。

HttpListener と違って管理者権限は不要で、自動的に出て来るファイアーウォールのダイアログで許可するだけで使えます。

```fsharp
open System
open System.IO
open System.Net
open System.Net.Sockets
open System.Text

let listener = new TcpListener(IPAddress.Any, 8080)
listener.Start()
let rec acceptLoop () = async {
    let! client = listener.AcceptTcpClientAsync() |> Async.AwaitTask
    use stream = client.GetStream()
    use sr = new StreamReader(stream)
    use sw = new StreamWriter(stream, Encoding.ASCII)
    let req = [|
        let mutable line = sr.ReadLine()
        while String.IsNullOrEmpty line |> not do
            yield line
            line <- sr.ReadLine() |]
    printfn "%A %A %s" DateTime.Now client.Client.RemoteEndPoint req.[0]
    let buf = Encoding.ASCII.GetBytes "Hello, HTTP!"
    fprintfn sw "HTTP/1.1 200 OK"
    fprintfn sw "Connection: close"
    fprintfn sw "Content-Length: %d" buf.Length
    fprintfn sw "Content-Type: text/plain"
    fprintfn sw ""
    sw.Flush()
    stream.Write(buf, 0, buf.Length)
    client.Close()
    return! acceptLoop () }
acceptLoop () |> Async.Start
Console.ReadLine() |> ignore
listener.Stop()
```

`sw.Flush()` がとても重要です。これがないとヘッダなしでデータ本体だけが送られてしまい、おかしなことになります。

# 画像

画像を返す例です。

以下の記事で実装した `captureScreen` を使用して画面をキャプチャします。

https://qiita.com/7shi/items/71be43cd0934f944721a

```fsharp
let rec acceptLoop () = async {
    let! client = listener.AcceptTcpClientAsync() |> Async.AwaitTask
    use stream = client.GetStream()
    use sr = new StreamReader(stream)
    use sw = new StreamWriter(stream, Encoding.ASCII)
    let request = [|
        let mutable line = sr.ReadLine()
        while String.IsNullOrEmpty line |> not do
            yield line
            line <- sr.ReadLine() |]
    printfn "%A %A %s" DateTime.Now client.Client.RemoteEndPoint request.[0]
    let status, mime, buf =
        if request.[0].StartsWith "GET / HTTP" then
            use bmp = captureScreen Screen.PrimaryScreen.Bounds
            use ms = new MemoryStream()
            bmp.Save(ms, ImageFormat.Png)
            "200 OK", "image/png", ms.ToArray()
        else
            let status = "404 Not Found"
            status, "text/plain", Encoding.ASCII.GetBytes status
    fprintfn sw "HTTP/1.1 %s" status
    fprintfn sw "Connection: close"
    fprintfn sw "Content-Length: %d" buf.Length
    fprintfn sw "Content-Type: %s" mime
    fprintfn sw ""
    sw.Flush()
    stream.Write(buf, 0, buf.Length)
    client.Close()
    return! acceptLoop () }
```

# 感想

HTTP を自前実装するのは勉強には良いのですが、あまり複雑なものを作ることは現実的ではありません。

定型的な処理をするような簡易的なツールに割り切って組み込むのが関の山という気がします。

# 参考

https://www.misuzilla.org/Blog/2016/01/31/CreateYourOwnHttpServerUsingCSharp
