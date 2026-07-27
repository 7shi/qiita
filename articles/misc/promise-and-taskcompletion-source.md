---
coediting: false
comments_count: 0
created_at: '2020-06-26T01:17:56+09:00'
id: 5e1e95252f1456301522
likes_count: 4
private: false
reactions_count: 0
stocks_count: 1
tags:
- name: JavaScript
  versions: []
- name: C#
  versions: []
- name: WinRT
  versions: []
- name: WebSpeechAPI
  versions: []
- name: AsyncAwait
  versions: []
title: PromiseとTaskCompletionSource
updated_at: '2020-06-26T16:20:22+09:00'
url: https://qiita.com/7shi/items/5e1e95252f1456301522
slide: false
---

非同期処理に使う JavaScript の Promise と .NET Framework (C#) の TaskCompletionSource を比較します。

# 概要

Promise や TaskCompletionSource のどちらか片方の知識から、比較によってもう一方の取っ掛かりにするのが狙いです。

JavaScript のコードは以下の記事から一部引用します。Promise の概要もこちらで説明しています。

* [非同期APIをPromiseでラップしてasync/awaitで使う](https://qiita.com/7shi/items/a2bb35f27cd4a56f7bac)

Promise は `await` での利用に限定して、`.then()` は利用しません。

JavaScript は [Deno](https://deno.land/) を想定してトップレベルで `await` を使用します。ただし最後の Web Speech API の例は、ブラウザで動かす必要があるため `async` 関数で囲みます。

# 待機

定番の `setTimeout` を `Promise` でラップしたものです。

```JavaScript:JavaScript
function wait(timeout) {
    return new Promise((resolve, reject) => setTimeout(resolve, timeout));
}

await wait(1000);
console.log(1);
await wait(2000);
console.log(2);
await wait(3000);
console.log(3);
```

C# に移植します。用意されている `Task.Delay()` を使うだけです。

```csharp:C#
using System;
using System.Threading.Tasks;

class Test
{
    static async Task Main()
    {
        await Task.Delay(1000);
        Console.WriteLine(1);
        await Task.Delay(2000);
        Console.WriteLine(2);
        await Task.Delay(3000);
        Console.WriteLine(3);
    }
}
```
```text:実行結果
1
2
3
```

# TaskCompletionSource

.NET Framework で JavaScript の `Promise` に仕様が近いのは `TaskCompletionSource` です。

## resolve

`resolve` に相当するのは `SetResult` です。簡単な例で比較します。

```JavaScript:JavaScript
let p = new Promise((resolve, reject) => resolve(1));
console.log(await p);
```
```csharp:C#
using System;
using System.Threading.Tasks;

class Test
{
    static async Task Main()
    {
        var tcs = new TaskCompletionSource<int>();
        tcs.SetResult(1);
        Console.WriteLine(await tcs.Task);
    }
}
```
```text:実行結果
1
```

※ この例では非同期の嬉しさがありませんが、後で `SetResult` が遅延する例を示します。👉[音声合成](#音声合成)

`SetResult` の名前のニュアンスは「`await` で取り出すための結果をセットする」という感じでしょうか。個人的には分かりやすい名前だと思います。

## reject

`reject` に相当するのは `SetException` です。簡単な例で比較します。

```JavaScript:JavaScript
function test(f) {
    return new Promise((resolve, reject) => {
        if (f) resolve(1); else reject(new Error());
    });
}

try {
    console.log(await test(true));
    console.log(await test(false));
} catch (e) {
    console.log(e);
}
```
```csharp:C#
using System;
using System.Threading.Tasks;

class Test
{
    static Task<int> test(bool f)
    {
        var tcs = new TaskCompletionSource<int>();
        if (f) tcs.SetResult(1); else tcs.SetException(new Exception());
        return tcs.Task;
    }

    static async Task Main()
    {
        try
        {
            Console.WriteLine(await test(true));
            Console.WriteLine(await test(false));
        }
        catch (Exception e)
        {
            Console.WriteLine(e);
        }
    }
}
```
```text:実行結果
1
System.Exception: 種類 'System.Exception' の例外がスローされました。
   場所 System.Runtime.ExceptionServices.ExceptionDispatchInfo.Throw()
   場所 System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification(Task task)
   場所 System.Runtime.CompilerServices.TaskAwaiter`1.GetResult()
   場所 Test.<Main>d__1.MoveNext()
```

わざと例外を発生させています。

### TaskCompletionSource の模倣

コールバックの引数を外に出せば `TaskCompletionSource` が模倣できます。

```javascript:JavaScript
class TaskCompletionSource {
    constructor() {
        this.Task = new Promise((resolve, reject) => {
            this.SetResult    = resolve;
            this.SetException = reject;
        });
    }
}

function test(f) {
    let tcs = new TaskCompletionSource();
    if (f) tcs.SetResult(1); else tcs.SetException(new Error());
    return tcs.Task;
}

try {
    console.log(await test(true));
    console.log(await test(false));
} catch (e) {
    console.log(e);
}
```

### Promise の模倣

`SetResult` と `SetException` をコールバックに引数で渡せば `Promise` が模倣できます。

```csharp:C#
using System;
using System.Threading.Tasks;

class Promise<T>
{
    private TaskCompletionSource<T> tcs = new TaskCompletionSource<T>();
    public static implicit operator Task<T>(Promise<T> p) => p.tcs.Task;
    public Promise(Action<Action<T>, Action<Exception>> action) =>
        action(tcs.SetResult, tcs.SetException);
}

class Test
{
    static Task<int> test(bool f)
    {
        return new Promise<int>((resolve, reject) => {
            if (f) resolve(1); else reject(new Exception());
        });
    }

    static async Task Main()
    {
        try
        {
            Console.WriteLine(await test(true));
            Console.WriteLine(await test(false));
        }
        catch (Exception e)
        {
            Console.WriteLine(e);
        }
    }
}
```

同じようなことを試みた記事です。

* [C#でコールバック処理をPromiseる](https://qiita.com/divideby_zero/items/e9d3cc33dc7b63993585)

`.then()` や `.catch()` を模倣しようとすると、かなり面倒なことになるようです。

* [[C#]TaskクラスをJavaScriptのPromiseっぽく使ってみる実験](https://qiita.com/matarillo/items/40fbdc4223689a1e6c43)

## キャンセル

`TaskCompletionSource` ではキャンセルもサポートされます。（`SetCanceled`）

`Promise` には対応するものがないため、キャンセルを実装するには工夫が必要です。

* [Promiseの処理をキャンセルする](https://qiita.com/7shi/items/4cc1928061ff4598f10b)

比較は省略します。

# 音声合成

コールバックで終了やエラーの通知が来るタイプとして、Web Speech API の例を WinRT に移植して比較します。

```JavaScript:JavaScript
function speak(lang, text) {
    return new Promise((resolve, reject) => {
        let u = new SpeechSynthesisUtterance(text);
        u.lang = lang;
        u.onend = resolve;
        u.onerror = reject;
        speechSynthesis.speak(u);
    });
}

(async function () {
    try {
        await speak("en", "Hello, world!");
        await speak("fr", "Bonjour, monde !");
        await speak("ja", "こんにちは、世界！");
    } catch (e) {
        console.log(e);
    }
})();
```
```csharp:C#
using System;
using System.Linq;
using System.Threading.Tasks;
using Windows.Media.Core;
using Windows.Media.SpeechSynthesis;
using Windows.Media.Playback;

class Program
{
    static Task Speak(string lang, string text)
    {
        var tcs = new TaskCompletionSource<int>();
        try
        {
            var voice = SpeechSynthesizer.AllVoices.First(v => v.Language.StartsWith(lang));
            var synthesizer = new SpeechSynthesizer();
            var player = new MediaPlayer();
            synthesizer.Voice = voice;
            var stream = synthesizer.SynthesizeTextToStreamAsync(text).AsTask().Result;
            player.Source = MediaSource.CreateFromStream(stream, stream.ContentType);
            player.MediaEnded += (sender, o) => tcs.SetResult(0);
            player.Play();
        }
        catch (Exception e)
        {
            tcs.SetException(e);
        }
        return tcs.Task;
    }

    static async Task Main()
    {
        try
        {
            await Speak("en", "Hello, world!");
            await Speak("fr", "Bonjour, monde !");
            await Speak("ja", "こんにちは、世界！");
        }
        catch (Exception e)
        {
            Console.WriteLine(e);
        }
    }
}
```

JavaScript では API に任せている部分を WinRT では記述しているためやや混み入っています。`MediaEnded` のイベントハンドラの中から `SetResult` を呼んでいるのがポイントです。`await Speak()` は再生が終了するまで待ちます。

WinRT での音声合成については以下の記事を参照してください。

* [WinRTで音声合成](https://qiita.com/7shi/items/dc21a3be8b7c69fbc11b)
