---
coediting: false
comments_count: 0
created_at: '2020-06-24T16:40:28+09:00'
id: dc21a3be8b7c69fbc11b
likes_count: 5
private: false
reactions_count: 0
stocks_count: 5
tags:
- name: C#
  versions: []
- name: WinRT
  versions: []
- name: TTS
  versions: []
- name: TextToSpeech
  versions: []
title: WinRTで音声合成
updated_at: '2020-10-15T14:50:12+09:00'
url: https://qiita.com/7shi/items/dc21a3be8b7c69fbc11b
slide: false
---

WinRT で音声合成を試します。従来の API よりも扱える音声が増えたことを確認します。C# を使用します。

この記事のコードは以下のリポジトリに掲載しています。

* <https://github.com/7shi/winrt-speech/tree/master/csharp>

他の言語での利用については以下の記事を参照してください。

* [Rust/WinRTで音声合成](https://qiita.com/7shi/items/885501607aecee7613fa)
* [VBSでOneCoreの音声を使用する](https://qiita.com/7shi/items/7781516d6746e29c03b4)
* [PythonでWindows 10の音声合成を使用する](https://qiita.com/7shi/items/a5fb03406e0626b4f138)
* [F#でリフレクションを駆使してWinRTを扱う](https://qiita.com/7shi/items/01899f69f010a029242f)

JavaScript との比較については以下の記事を参照してください。

* [PromiseとTaskCompletionSource](https://qiita.com/7shi/items/5e1e95252f1456301522)

# Windows の音声合成

Windows 10 でサポートされる音声の一覧です。

* [付録 A: Windows 10 のナレーターでサポートされている言語と音声 - Windows Help](https://support.microsoft.com/ja-jp/help/22805/windows-10-supported-narrator-languages-voices)

日本語以外の言語を使用する場合は追加します。

* [Windows 10で読み上げ言語を追加](https://7shi.hateblo.jp/entry/2020/02/22/185810)

今回はすべての言語を追加した状態でテストします。

# 音声一覧

従来の API と WinRT とで結果が異なります。

Windows 10 での新しい音声は OneCore という枠組みで扱われます。従来の API では OneCore の音声が扱えません。

## 従来の API

.NET Framework の [System.Speech.Synthesis](https://docs.microsoft.com/ja-jp/dotnet/api/system.speech.synthesis) で音声一覧を取得します。

```csharp:voices-net/Program.cs
using System;
using System.Speech.Synthesis;

class Program
{
    static void Main()
    {
        var synth = new SpeechSynthesizer();
        foreach (var voice in synth.GetInstalledVoices()) {
            var vi = voice.VoiceInfo;
            Console.WriteLine("{0}: {1}", vi.Culture, vi.Description);
        }
    }
}
```
```text:実行結果
ja-JP: Microsoft Haruka Desktop - Japanese
en-GB: Microsoft Hazel Desktop - English (Great Britain)
en-US: Microsoft David Desktop - English (United States)
en-US: Microsoft Zira Desktop - English (United States)
es-ES: Microsoft Helena Desktop - Spanish (Spain)
es-MX: Microsoft Sabina Desktop - Spanish (Mexico)
fr-FR: Microsoft Hortense Desktop - French
it-IT: Microsoft Elsa Desktop - Italian (Italy)
de-DE: Microsoft Hedda Desktop - German
ko-KR: Microsoft Heami Desktop - Korean
pl-PL: Microsoft Paulina Desktop - Polish
pt-BR: Microsoft Maria Desktop - Portuguese(Brazil)
ru-RU: Microsoft Irina Desktop - Russian
zh-CN: Microsoft Huihui Desktop - Chinese (Simplified)
zh-HK: Microsoft Tracy Desktop - Chinese(Traditional, HongKong SAR)
zh-TW: Microsoft Hanhan Desktop - Chinese (Taiwan)
```

一部の音声しか取得できません。SAPI ではレジストリを参照することで OneCore の音声を取得できますが、その方法は System.Speech.Synthesis では使えません。

また、System.Speech.Synthesis は .NET Core 3.1 では動きません。WinRT に移行するようにということのようです。

## WinRT

ほぼすべて（後述）の音声が取得できます。

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
```text:実行結果
fr-FR: Microsoft Hortense - French (France)
en-GB: Microsoft George - English (United Kingdom)
en-US: Microsoft David - English (United States)
es-ES: Microsoft Pablo - Spanish (Spain)
de-DE: Microsoft Stefan - German (Germany)
it-IT: Microsoft Cosimo - Italian (Italy)
en-AU: Microsoft Catherine - English (Australia)
en-CA: Microsoft Linda - English (Canada)
ca-ES: Microsoft Herena - Catalan (Catalan)
en-GB: Microsoft Hazel - English (United Kingdom)
en-GB: Microsoft Susan - English (United Kingdom)
en-IN: Microsoft Heera - English (India)
da-DK: Microsoft Helle - Danish (Denmark)
en-US: Microsoft Zira - English (United States)
es-ES: Microsoft Helena - Spanish (Spain)
es-ES: Microsoft Laura - Spanish (Spain)
de-DE: Microsoft Hedda - German (Germany)
es-MX: Microsoft Sabina - Spanish (Mexico)
fi-FI: Microsoft Heidi - Finnish (Finland)
fr-CA: Microsoft Caroline - French (Canada)
de-DE: Microsoft Katja - German (Germany)
fr-FR: Microsoft Julie - French (France)
hi-IN: Microsoft Kalpana - Hindi (India)
ja-JP: Microsoft Ayumi - Japanese (Japan)
it-IT: Microsoft Elsa - Italian (Italy)
ar-EG: Microsoft Hoda - Arabic (Egypt)
ja-JP: Microsoft Haruka - Japanese (Japan)
ko-KR: Microsoft Heami - Korean (Korean)
pl-PL: Microsoft Paulina - Polish (Poland)
pt-BR: Microsoft Maria - Portuguese (Brazil)
pt-PT: Microsoft Helia - Portuguese (Portugal)
ru-RU: Microsoft Irina - Russian (Russia)
zh-CN: Microsoft Huihui - Chinese (Simplified, PRC)
zh-CN: Microsoft Yaoyao - Chinese (Simplified, PRC)
zh-HK: Microsoft Tracy - Chinese (Traditional, Hong Kong S.A.R.)
zh-TW: Microsoft Hanhan - Chinese (Traditional, Taiwan)
zh-TW: Microsoft Yating - Chinese (Traditional, Taiwan)
he-IL: Microsoft Asaf - Hebrew (Israel)
hi-IN: Microsoft Hemant - Hindi (India)
de-AT: Microsoft Michael - German (Austria)
hr-HR: Microsoft Matej - Croatian (Croatia)
hu-HU: Microsoft Szabolcs - Hungarian (Hungary)
id-ID: Microsoft Andika - Indonesian (Indonesia)
en-US: Microsoft Mark - English (United States)
en-AU: Microsoft James - English (Australia)
de-CH: Microsoft Karsten - German (Switzerland)
en-CA: Microsoft Richard - English (Canada)
ja-JP: Microsoft Ichiro - Japanese (Japan)
ar-SA: Microsoft Naayf - Arabic (Saudi)
ms-MY: Microsoft Rizwan - Malay (Malaysia)
nb-NO: Microsoft Jon - Norwegian (Bokmal)
nl-BE: Microsoft Bart - Dutch (Belgium)
nl-NL: Microsoft Frank - Dutch (Netherlands)
pl-PL: Microsoft Adam - Polish (Poland)
es-MX: Microsoft Raul - Spanish (Mexico)
pt-BR: Microsoft Daniel - Portuguese (Brazil)
cs-CZ: Microsoft Jakub - Czech (Czech Republic)
bg-BG: Microsoft Ivan - Bulgarian (Bulgaria)
ro-RO: Microsoft Andrei - Romanian (Romania)
en-IE: Microsoft Sean - English (Ireland)
ru-RU: Microsoft Pavel - Russian (Russia)
sk-SK: Microsoft Filip - Slovak (Slovakia)
sl-SI: Microsoft Lado - Slovenian (Slovenia)
sv-SE: Microsoft Bengt - Swedish
ta-IN: Microsoft Valluvar - Tamil (India)
th-TH: Microsoft Pattara - Thai (Thailand)
tr-TR: Microsoft Tolga - Turkish (Turkey)
vi-VN: Microsoft An - Vietnamese (Vietnam)
fr-CA: Microsoft Claude - French (Canada)
zh-CN: Microsoft Kangkang - Chinese (Simplified, PRC)
fr-CH: Microsoft Guillaume - French (Switzerland)
zh-HK: Microsoft Danny - Chinese (Traditional, Hong Kong S.A.R.)
el-GR: Microsoft Stefanos - Greek (Greece)
en-IN: Microsoft Ravi - English (India)
fr-FR: Microsoft Paul - French (France)
zh-TW: Microsoft Zhiwei - Chinese (Traditional, Taiwan)
```

SAPI でレジストリを指定して取得した結果と比較すると、以下の2つの音声が取得できません。

```text:取得できなかった音声
fr-CA: Microsoft Nathalie - French (Canada)
ja-JP: Microsoft Sayaka - Japanese (Japan)
```

これらは音声の設定にも現れませんが、Chromium 版 Edge では使えます。隠れキャラなのでしょうか。

* [Windowsのブラウザで使える音声の調査](https://qiita.com/7shi/items/7f98e144cb69234c5e0e)

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

再生が終了するまで待つようになっています。

参考までにハマったポイントを書いておきます。

## ストリームの変換

当初、`SpeechSynthesizer.SynthesizeTextToStreamAsync()` から返される `SpeechSynthesisStream` が直接受け取れる `MediaPlayer.SetStreamSource()` を使おうとしましたが、obsolete でした。

* [MediaPlayer.SetStreamSource(IRandomAccessStream) Method (Windows.Media.Playback)](https://docs.microsoft.com/ja-jp/uwp/api/windows.media.playback.mediaplayer.setstreamsource?view=winrt-19041)

> **MediaPlayer.SetMediaSource** may be altered or unavailable after Windows 10. Use [MediaPlayer.Source](https://docs.microsoft.com/ja-jp/uwp/api/windows.media.playback.mediaplayer.source?view=winrt-19041#Windows_Media_Playback_MediaPlayer_Source) instead.

代替の `MediaPlayer.Source` は `IMediaPlaybackSource` を受け取るため変換が必要です。

```csharp
        player.Source = MediaSource.CreateFromStream(stream, stream.ContentType);
```

以下に変換方法についての質問がありますが、1番目の回答では引数が足りないため、2番目の回答から `ContentType` の部分を補う必要があります。

* [c# - How do I create an IMediaPlaybackSource from a Stream, so as to set a MediaPlayer source without using the obsolete SetStreamSource method? - Stack Overflow](https://stackoverflow.com/questions/52764736/how-do-i-create-an-imediaplaybacksource-from-a-stream-so-as-to-set-a-mediaplaye)

今回は WinRT の `MediaPlayer` を使用しましたが、以下の記事では WPF の `SoundPlayer` を使用しています。こちらは `Stream` への変換が必要になります。

* [WPF on .NET Core 3.0 で UWP の SpeechSynthesizer を使う | 徒然なブログ](http://www.makcraft.com/blog/meditation/2019/12/14/using-uwp-speechsynthesizer-in-wpf-on-net-core-3-0/)

## 終了待ち

再生は非同期で行われるため、再生が終わるまでプログラムが終了しないように待ちます。

再生の終了は `MediaEnded` で通知されるので、`TaskCompletionSource` に値をセットして `Task` を終了させます。

```csharp
        var tcs = new TaskCompletionSource<int>();
        player.MediaEnded += (sender, o) => tcs.SetResult(0);
        player.Play();
        await tcs.Task;
```

以下を参考にしました。

* [c# - Convert Event based pattern to async CTP pattern - Stack Overflow](https://stackoverflow.com/questions/12853445/convert-event-based-pattern-to-async-ctp-pattern)

`TaskCompletionSource` の使い方は JavaScript の `Promise` に近いと思いました。

* [非同期APIをPromiseでラップしてasync/awaitで使う](https://qiita.com/7shi/items/a2bb35f27cd4a56f7bac)

# csproj

csproj ファイルでは以下のように WinRT を参照しています。

* <https://github.com/7shi/winrt-speech/blob/master/csharp/speak/speak.csproj>

```xml:（抜粋）
  <ItemGroup>
    <Reference Include="System.Runtime.WindowsRuntime">
      <HintPath>C:\Windows\Microsoft.NET\Framework\v4.0.30319\System.Runtime.WindowsRuntime.dll</HintPath>
      <Private>False</Private>
    </Reference>
    <Reference Include="Windows">
      <HintPath>$(MSBuildProgramFiles32)\Windows Kits\10\UnionMetadata\10.0.17763.0\Facade\windows.winmd</HintPath>
      <Private>False</Private>
    </Reference>
    <Reference Include="Windows.Foundation.FoundationContract">
      <HintPath>$(MSBuildProgramFiles32)\Windows Kits\10\References\10.0.17763.0\Windows.Foundation.FoundationContract\3.0.0.0\Windows.Foundation.FoundationContract.winmd</HintPath>
      <Private>False</Private>
    </Reference>
    <Reference Include="Windows.Foundation.UniversalApiContract">
      <HintPath>$(MSBuildProgramFiles32)\Windows Kits\10\References\10.0.17763.0\Windows.Foundation.UniversalApiContract\7.0.0.0\Windows.Foundation.UniversalApiContract.winmd</HintPath>
      <Private>False</Private>
    </Reference>
  </ItemGroup>
```

以下を参考にしました。

* [WPFアプリ（.Net Framework）でUWPのAPIを使う](https://qiita.com/FumiyaHr/items/13de3dcbd9b81d9d27f0)
* [デスクトップ アプリで Windows ランタイム API を呼び出す | Microsoft Docs](https://docs.microsoft.com/ja-jp/windows/apps/desktop/modernize/desktop-to-uwp-enhance)
