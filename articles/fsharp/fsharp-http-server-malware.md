---
coediting: false
comments_count: 0
created_at: '2023-02-12T15:05:53+09:00'
id: bcf1998f1dd3755ac82c
likes_count: 0
private: false
reactions_count: 0
stocks_count: 0
tags:
- name: F#
  versions: []
- name: Defender
  versions: []
- name: HttpListener
  versions: []
title: 簡易 HTTP サーバーとマルウェア判定
updated_at: '2023-02-13T19:22:41+09:00'
url: https://qiita.com/7shi/items/bcf1998f1dd3755ac82c
slide: false
---

F# でサンプルの簡易 HTTP サーバーをビルドしたところ、Windows Defender にマルウェア判定されるものとされないものがありました。

マルウェア判定を乗り切ったとしても、管理者権限やファイアーウォールなどで使い勝手に問題があります。

# 断り書き

* 決まった文字列を返すだけで、悪意ある動作は含まれません。
* マルウェアの作り方を説明するものではありません。

# ChatGPT

ChatGPT に F# での HTTP サーバーのサンプルを要求して提示されたコードです。

```fsharp:httpsrv-1.fs
open System
open System.Net
open System.Text

let listener = new HttpListener()
listener.Prefixes.Add("http://localhost:8080/")
listener.Start()

let rec handleRequests () =
    async {
        let! context = Async.FromBeginEnd(listener.BeginGetContext, listener.EndGetContext)
        use response = context.Response
        let responseString = "Hello, World!"
        let buffer = Encoding.UTF8.GetBytes(responseString)
        response.ContentLength64 <- int64 buffer.Length
        let output = response.OutputStream
        do! Async.FromBeginEnd(buffer, 0, buffer.Length, output.BeginWrite, output.EndWrite)
        do! handleRequests ()
    }

handleRequests () |> Async.Start
Console.ReadLine() |> ignore
```

※ 2 つ目の `Async.FromBeginEnd` の引数が間違っていたのを修正しています。

# マルウェア判定

検索したところ、ChatGPT のものによく似たコードがありました。

80 番ポートで待ち受けて "hello world" と返すだけの簡易 HTTP サーバーです。

http://www.fssnip.net/1X/title/Simple-HTTP-server-with-Async-workflow

```fsharp:httpsrv-2.fs
open System
open System.Net

type HttpListener with
    static member Run (url:string,handler: (HttpListenerRequest -> HttpListenerResponse -> Async<unit>)) = 
        let listener = new HttpListener()
        listener.Prefixes.Add url
        listener.Start()
        let asynctask = Async.FromBeginEnd(listener.BeginGetContext,listener.EndGetContext)
        async {
            while true do 
                let! context = asynctask
                Async.Start (handler context.Request context.Response)
        } |> Async.Start 
        listener

HttpListener.Run("http://*:80/App/",(fun req resp -> 
        async {
            let out = Text.Encoding.ASCII.GetBytes "hello world"
            resp.OutputStream.Write(out,0,out.Length)
            resp.OutputStream.Close()
        }
    )) |> ignore

Console.Read () |> ignore
```

これは Trojan:Win32/Wacatac.H!ml と判定されました。

https://www.microsoft.com/en-us/wdsi/threats/malware-encyclopedia-description?name=Trojan%3aWin32%2fWacatac.H!ml&threatid=2147814523

ChatGPT のコードで再帰していた部分が、こちらでは `while true` で無限ループになっています。試しに再帰に書き換えてみましたが、この違いが判定に影響するようです。

# VirusTotal

他のセキュリティソフトの状況を調べるため VirusTotal でチェックしました。

https://www.virustotal.com/gui/home/upload

||httpsrv-1 (3/70)|httpsrv-2 (5/71)|
|----|----|----|
|Cybereason|Malicious.9555c6|
|Elastic||Malicious (moderate Confidence)
|Microsoft||Trojan:Win32/Wacatac.H!ml
|SecureAge|Malicious|Malicious
|Trapmine|Malicious.moderate.ml.score|Malicious.moderate.ml.score
|Zillya||Downloader.Tiny.Win32.17020

全体からの割合としては少数ですが、httpsrv-2 の方が少し多いようです。

# 使い勝手

マルウェア判定されるのも困りものですが、HttpListener の使い勝手も微妙です。

ローカルでテストするだけなら簡単ですが、他のクライアントからのアクセスを許可しようとすると面倒なことになります。管理者権限で実行して、ファイアーウォールも EXE ではなく HTTP.SYS に対して許可する必要があります。

https://techracho.bpsinc.jp/baba/2009_12_26/860

https://www.moonmile.net/blog/archives/6406

仕方ないので TcpListener で HTTP を扱ってみました。

https://qiita.com/7shi/items/f59b6804167717f8f2d6

# HttpClient

クライアントの方は、従来の WebClient が deprecated となり、HttpClient への移行が推奨されています。

https://learn.microsoft.com/ja-jp/dotnet/api/system.net.webclient?view=net-7.0

> このクラスを新しい開発に `WebClient` 使用することはお勧めしません。代わりに、クラスを使用します **System.Net.Http.HttpClient** 。

httpsrv-1 から結果を取得する例です。

```fsharp
open System.Net.Http

let client = new HttpClient()
let task = client.GetStringAsync "http://localhost:8080/"
printfn "%s" task.Result
```

この例では Defender は反応しませんでした。

※ 少し込み入ったものを作ったらマルウェア判定されたのですが、いじっているうちに再現しなくなりました。
