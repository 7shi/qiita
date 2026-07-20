---
coediting: false
comments_count: 0
created_at: '2020-06-24T21:48:48+09:00'
id: 01899f69f010a029242f
likes_count: 0
private: false
reactions_count: 0
stocks_count: 1
tags:
- name: F#
  versions: []
- name: WinRT
  versions: []
- name: リフレクション
  versions: []
title: F#でリフレクションを駆使してWinRTを扱う
updated_at: '2020-06-25T15:18:32+09:00'
url: https://qiita.com/7shi/items/01899f69f010a029242f
slide: false
---

F# でリフレクションを駆使して WinRT を扱ったコードを C# と比較します。

この記事のコードは以下のリポジトリに掲載しています。

* <https://github.com/7shi/winrt-speech/tree/master/fsharp>

C# のコードは以下の記事から引用します。実行結果はこちらを参照してください。

* [WinRTで音声合成](https://qiita.com/7shi/items/dc21a3be8b7c69fbc11b)

# 将来展望

現在開発中の [C#/WinRT](https://docs.microsoft.com/ja-jp/windows/uwp/csharp-winrt/) と F# 5.0 を組み合わせれば、リフレクションを駆使した泥臭いコードは不要になる見込みです。

* [Hacking Windows with F# 5.0 Scripts - DEV](https://dev.to/tunaxor/hacking-windows-with-f-5-0-scripts-4k2o)

# 概要

WinRT は通常の .NET アセンブリとは異なるため言語側でもサポートが必要です。記事執筆時点で F# には WinRT のサポートがないため、リフレクション経由で扱う必要があります。

特に WinRT で多用される非同期処理が問題になります。詳細は以下の記事を参照してください。

* [WinRTの非同期メソッドをリフレクションで扱う](https://qiita.com/7shi/items/e8de755a5738f862e09f)

# 音声一覧

読み上げに使用できる音声一覧を取得します。

```csharp:voices/Program.cs
using System;
using Windows.Media.SpeechSynthesis;

class Program
{
    static void Main()
    {
        foreach (var voice in SpeechSynthesizer.AllVoices) {
            Console.WriteLine("{0}: {1}", voice.Language, voice.Description);
        }
    }
}
```
```fsharp:voices.fsx
open System
let SpeechSynthesizer = Type.GetType(@"
    Windows.Media.SpeechSynthesis.SpeechSynthesizer,
    Windows.Foundation.UniversalApiContract,
    ContentType=WindowsRuntime")
for voice in SpeechSynthesizer.GetProperty("AllVoices").GetValue(null) :?> seq<obj> do
    let t = voice.GetType()
    let lang = t.GetProperty("Language"   ).GetValue(voice) :?> String
    let desc = t.GetProperty("Description").GetValue(voice) :?> String
    printfn "%s: %s" lang desc
```

インスタンスは `obj` のまま扱って、メンバーはリフレクション経由で触ります。かなり面倒です。

# 音声合成

音声を指定してしゃべらせます。

```csharp:speak/Program.cs
using System;
using System.Threading.Tasks;
using Windows.Media.Core;
using Windows.Media.SpeechSynthesis;
using Windows.Media.Playback;

class Program
{
    static void SetVoice(SpeechSynthesizer synthesizer, string v) {
        foreach (var voice in SpeechSynthesizer.AllVoices) {
            if (voice.DisplayName == v) {
                synthesizer.Voice = voice;
                break;
            }
        }
    }

    static async Task Main()
    {
        var voice = "Microsoft Ichiro";
        var text  = "こんにちは、世界";
        var synthesizer = new SpeechSynthesizer();
        SetVoice(synthesizer, voice);
        var stream = await synthesizer.SynthesizeTextToStreamAsync(text);
        var player = new MediaPlayer();
        player.Source = MediaSource.CreateFromStream(stream, stream.ContentType);
        var tcs = new TaskCompletionSource<int>();
        player.MediaEnded += (sender, o) => tcs.SetResult(0);
        player.Play();
        await tcs.Task;
    }
}
```
```fsharp:speak.fsx
#r "System.Runtime.WindowsRuntime"

open System
open System.Threading.Tasks

let SpeechSynthesizer = Type.GetType @"
    Windows.Media.SpeechSynthesis.SpeechSynthesizer,
    Windows.Foundation.UniversalApiContract,
    ContentType=WindowsRuntime"
let SpeechSynthesisStream = Type.GetType @"
    Windows.Media.SpeechSynthesis.SpeechSynthesisStream,
    Windows.Foundation.UniversalApiContract,
    ContentType=WindowsRuntime"
let MediaPlayer = Type.GetType @"
    Windows.Media.Playback.MediaPlayer,
    Windows.Foundation.UniversalApiContract,
    ContentType=WindowsRuntime"
let TypedEventHandler(a, b) = Type.GetType(@"
    Windows.Foundation.TypedEventHandler`2,
    Windows.Foundation.FoundationContract,
    ContentType=WindowsRuntime").MakeGenericType(a, b)

let AsTaskGeneric = query {
    for m in typeof<WindowsRuntimeSystemExtensions>.GetMethods() do
    where (m.Name = "AsTask")
    let ps = m.GetParameters()
    where (ps.Length = 1 && ps.[0].ParameterType.Name = "IAsyncOperation`1")
    select m
    exactlyOne }
let await resultType winRtTask =
    let AsTask = AsTaskGeneric.MakeGenericMethod [|resultType|]
    let task = AsTask.Invoke(null, [|winRtTask|])
    task.GetType().GetProperty("Result").GetValue(task)

let setVoice synthesizer (v: string) =
    let AllVoices = SpeechSynthesizer.GetProperty("AllVoices")
    match [ for voice in AllVoices.GetValue(null) :?> seq<obj> do
            let DisplayName = voice.GetType().GetProperty("DisplayName")
            if (DisplayName.GetValue(voice) :?> String) = v then yield voice ] with
    | [voice] -> synthesizer.GetType().GetProperty("Voice").SetValue(synthesizer, voice)
    | _ -> ()

let voice = "Microsoft Ichiro"
let text  = "こんにちは、世界"
let synthesizer = Activator.CreateInstance(SpeechSynthesizer)
setVoice synthesizer voice
let stream =
    SpeechSynthesizer.GetMethod("SynthesizeTextToStreamAsync").Invoke(synthesizer, [|text|])
    |> await SpeechSynthesisStream
let player = Activator.CreateInstance(MediaPlayer)
MediaPlayer.GetMethod("SetStreamSource").Invoke(player, [|stream|])
let tcs = TaskCompletionSource<unit>()
type C = static member f(_: obj, _: obj) = tcs.SetResult()
let d = Delegate.CreateDelegate(TypedEventHandler(MediaPlayer, typeof<obj>), typeof<C>.GetMethod("f"))
MediaPlayer.GetEvent("MediaEnded").AddMethod.Invoke(player, [|d|])
MediaPlayer.GetMethod("Play").Invoke(player, [||])
tcs.Task.Result
```

かなり厳しい感じです。この調子で複雑なものを作るのは、あまり現実的ではない気がします。

## イベントハンドラ

型を指定してデリゲートを作るには `MethodInfo` が必要です。F# の関数から `MethodInfo` を取得しようとすると、IL を解析するようなハックが必要になるようです。

* [reflection - Retrieve MethodInfo of a F# function - Stack Overflow](https://stackoverflow.com/questions/1575180/retrieve-methodinfo-of-a-f-function)

そこまでしなくてもクラスを定義すれば済むため、メソッドが1つだけのクラスを作ります。

```fsharp
type C = static member f(_: obj, _: obj) = tcs.SetResult()
let d = Delegate.CreateDelegate(TypedEventHandler(MediaPlayer, typeof<obj>), typeof<C>.GetMethod("f"))
```

[TypedEventHandler](https://docs.microsoft.com/ja-jp/uwp/api/windows.foundation.typedeventhandler-2?view=winrt-18362) は2つの引数を持つジェネリック デリゲートです。

```csharp
public delegate void TypedEventHandler<TSender,TResult>(TSender sender, TResult args);
```

`TypedEventHandler<MediaPlayer, Object>` と `C.f` では第1引数の型が異なりますが、引数の反変性として容認されます。

* [共変戻り値と反変引数](https://qiita.com/7shi/items/39a222b5928bf0b6f745)

![17_反変引数.png](https://qiita-image-store.s3.amazonaws.com/0/32057/fdaa73cd-da3f-a5fb-5ccd-e2c194269619.png)

# 感想

いずれ不要になることも分かっているので、あまり頑張っても仕方ない気はしますが、リフレクションで動的に型を扱う練習にはなると思いました。（WinRT でなくてもできますが）
