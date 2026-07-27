---
coediting: false
comments_count: 2
created_at: '2020-04-28T04:27:05+09:00'
id: 7781516d6746e29c03b4
likes_count: 9
private: false
reactions_count: 0
stocks_count: 9
tags:
- name: VBScript
  versions: []
- name: TTS
  versions: []
- name: TextToSpeech
  versions: []
- name: Windows10
  versions: []
- name: SAPI
  versions: []
title: VBSでOneCoreの音声を使用する
updated_at: '2020-06-24T17:15:24+09:00'
url: https://qiita.com/7shi/items/7781516d6746e29c03b4
slide: false
---

Windows 10 で追加できる音声には、従来の SAPI からは直接利用できない OneCore に分類される音声があります。VBScript から使用する方法を調べました。

発音の指定方法については以下の記事を参照してください。

* [SAPIで発音を指定する](https://qiita.com/7shi/items/51017b4b268f66e11c42)

他の言語での利用については以下の記事を参照してください。

* [PythonでWindows 10の音声合成を使用する](https://qiita.com/7shi/items/a5fb03406e0626b4f138)
* [WinRTで音声合成](https://qiita.com/7shi/items/dc21a3be8b7c69fbc11b) (C#)
* [Rust/WinRTで音声合成](https://qiita.com/7shi/items/885501607aecee7613fa)

# 音声一覧

Windows 10 でサポートされる音声の一覧です。

* [付録 A: Windows 10 のナレーターでサポートされている言語と音声 - Windows Help](https://support.microsoft.com/ja-jp/help/22805/windows-10-supported-narrator-languages-voices)

日本語以外の言語を使用する場合は追加します。

* [Windows 10で読み上げ言語を追加](https://7shi.hateblo.jp/entry/2020/02/22/185810)

今回はすべての言語を追加した状態でテストします。

```vb:voices.vbs
Set sapi = CreateObject("SAPI.SpVoice")
For Each voice In sapi.GetVoices
    WScript.Echo voice.GetDescription
Next
```
```text:実行結果
Microsoft Haruka Desktop - Japanese
Microsoft Hazel Desktop - English (Great Britain)
Microsoft David Desktop - English (United States)
Microsoft Zira Desktop - English (United States)
Microsoft Helena Desktop - Spanish (Spain)
Microsoft Sabina Desktop - Spanish (Mexico)
Microsoft Hortense Desktop - French
Microsoft Elsa Desktop - Italian (Italy)
Microsoft Hedda Desktop - German
Microsoft Heami Desktop - Korean
Microsoft Paulina Desktop - Polish
Microsoft Maria Desktop - Portuguese(Brazil)
Microsoft Irina Desktop - Russian
Microsoft Huihui Desktop - Chinese (Simplified)
Microsoft Tracy Desktop - Chinese(Traditional, HongKong SAR)
Microsoft Hanhan Desktop - Chinese (Taiwan)
```

一部の音声しか取得できません。

# OneCore

従来の音声はレジストリの以下に格納されています。

* `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Speech\Voices\Tokens`

それに対して新しく追加された音声は OneCore という別枠で扱われています。

* `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Speech_OneCore\Voices\Tokens`

今回は使用しませんが、レジストリをコピーするという強引な方法で、従来の SAPI から認識させることができるようです。

* [.net - Listing and selecting installed voice (for text to speech) - Stack Overflow](https://stackoverflow.com/questions/55695930/listing-and-selecting-installed-voice-for-text-to-speech)

OneCore は UWP API (WinRT) での利用を想定しているようです。

* [1544143 - [narrate] Support onecore / mobile voices on Windows 10](https://bugzilla.mozilla.org/show_bug.cgi?id=1544143)

> These OneCore voices are accessed via the Windows.Media.SpeechSynthesis namespace. Documentation:
> https://docs.microsoft.com/en-us/uwp/api/windows.media.speechsynthesis
> 
> Note that while Microsoft still provide SAPI5 voices in Windows 10, you don't get access to all the OneCore voices via SAPI5. OneCore voices include voices for languages not previously supported, among other things.

# SpObjectTokenCategory

先ほど引用した Bugzilla には回避策が提示されています。

* [1544143 - [narrate] Support onecore / mobile voices on Windows 10](https://bugzilla.mozilla.org/show_bug.cgi?id=1544143)

> As an alternative to accessing these via WinRT, There is a hack which allows you to access these voices via SAPI, but it's obviously not official. That said, I think a few apps (perhaps even JAWS?) are using it. This would obviously be a lot simpler than writing completely new code.
> 
> 1. Create an sapi.spObjectTokenCategory object.
> 1. Call .SetID("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Speech_OneCore\Voices", False).
> 1. Enumerate the tokens with .EnumerateTokens.
> 1. Use those tokens to set your SAPI voice.

これを VBScript で実装して確認します。

```vb:voices-oc.vbs
Set cat = CreateObject("SAPI.SpObjectTokenCategory")
cat.SetID "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Speech_OneCore\Voices", False
For Each token In cat.EnumerateTokens
    WScript.Echo token.GetDescription
Next
```
```text:実行結果
Microsoft Ayumi - Japanese (Japan)
Microsoft Naayf - Arabic (Saudi)
Microsoft Ivan - Bulgarian (Bulgaria)
Microsoft Herena - Catalan (Catalan)
Microsoft Jakub - Czech (Czech Republic)
Microsoft Helle - Danish (Denmark)
Microsoft Michael - German (Austria)
Microsoft Karsten - German (Switzerland)
Microsoft Hedda - German (Germany)
Microsoft Katja - German (Germany)
Microsoft Stefan - German (Germany)
Microsoft Stefanos - Greek (Greece)
Microsoft Catherine - English (Australia)
Microsoft James - English (Australia)
Microsoft Linda - English (Canada)
Microsoft Richard - English (Canada)
Microsoft George - English (United Kingdom)
Microsoft Hazel - English (United Kingdom)
Microsoft Susan - English (United Kingdom)
Microsoft Sean - English (Ireland)
Microsoft Heera - English (India)
Microsoft Ravi - English (India)
Microsoft David - English (United States)
Microsoft Mark - English (United States)
Microsoft Zira - English (United States)
Microsoft Helena - Spanish (Spain)
Microsoft Laura - Spanish (Spain)
Microsoft Pablo - Spanish (Spain)
Microsoft Raul - Spanish (Mexico)
Microsoft Sabina - Spanish (Mexico)
Microsoft Heidi - Finnish (Finland)
Microsoft Caroline - French (Canada)
Microsoft Claude - French (Canada)
Microsoft Nathalie - French (Canada)
Microsoft Guillaume - French (Switzerland)
Microsoft Hortense - French (France)
Microsoft Julie - French (France)
Microsoft Paul - French (France)
Microsoft Asaf - Hebrew (Israel)
Microsoft Hemant - Hindi (India)
Microsoft Kalpana - Hindi (India)
Microsoft Matej - Croatian (Croatia)
Microsoft Szabolcs - Hungarian (Hungary)
Microsoft Andika - Indonesian (Indonesia)
Microsoft Cosimo - Italian (Italy)
Microsoft Elsa - Italian (Italy)
Microsoft Hoda - Arabic (Egypt)
Microsoft Haruka - Japanese (Japan)
Microsoft Ichiro - Japanese (Japan)
Microsoft Sayaka - Japanese (Japan)
Microsoft Heami - Korean (Korean)
Microsoft Rizwan - Malay (Malaysia)
Microsoft Jon - Norwegian (Bokmål)
Microsoft Bart - Dutch (Belgium)
Microsoft Frank - Dutch (Netherlands)
Microsoft Adam - Polish (Poland)
Microsoft Paulina - Polish (Poland)
Microsoft Daniel - Portuguese (Brazil)
Microsoft Maria - Portuguese (Brazil)
Microsoft Helia - Portuguese (Portugal)
Microsoft Andrei - Romanian (Romania)
Microsoft Irina - Russian (Russia)
Microsoft Pavel - Russian (Russia)
Microsoft Filip - Slovak (Slovakia)
Microsoft Lado - Slovenian (Slovenia)
Microsoft Bengt - Swedish
Microsoft Valluvar - Tamil (India)
Microsoft Pattara - Thai (Thailand)
Microsoft Tolga - Turkish (Turkey)
Microsoft An - Vietnamese (Vietnam)
Microsoft Huihui - Chinese (Simplified, PRC)
Microsoft Kangkang - Chinese (Simplified, PRC)
Microsoft Yaoyao - Chinese (Simplified, PRC)
Microsoft Danny - Chinese (Traditional, Hong Kong S.A.R.)
Microsoft Tracy - Chinese (Traditional, Hong Kong S.A.R.)
Microsoft Hanhan - Chinese (Traditional, Taiwan)
Microsoft Yating - Chinese (Traditional, Taiwan)
Microsoft Zhiwei - Chinese (Traditional, Taiwan)
```

うまく取得できました。

この結果と言語・地域コードとを合わせた一覧表は以下の記事を参照してください。

* [SSMLの言語・地域コードとSAPI音声の対応](https://qiita.com/7shi/items/ff9cf324f18234cabd82)

※ Bugzilla に話題が出ていたことから、Firefox では OneCore の音声はサポートされていないようです。Firefox 76.0.1 では確かにそうでした。詳細は以下の記事を参照してください。

* [Windowsのブラウザで使える音声の調査](https://qiita.com/7shi/items/7f98e144cb69234c5e0e)

# Sayaka

OneCore から取得した日本語音声 Sayaka に喋らせてみます。Sayaka は WinRT では利用できない隠れキャラのようです。

```vb:sayaka.vbs
Set sapi = CreateObject("SAPI.SpVoice")
Set cat  = CreateObject("SAPI.SpObjectTokenCategory")
cat.SetID "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Speech_OneCore\Voices", False
For Each token In cat.EnumerateTokens
    If token.GetAttribute("Name") = "Microsoft Sayaka" Then
        Set oldv = sapi.Voice
        Set sapi.Voice = token
        sapi.Speak "こんにちは、世界"
        Set sapi.Voice = oldv
        Exit For
    End If
Next
```

<font color="red">**【注意】**</font> UTF-16 LE または Shift JIS で保存してください。UTF-8 では文字化けが読み上げられます。

音声をファイル `sayaka.wav` に出力することも可能です。

```vb:sayaka-wav.vbs
Set sapi = CreateObject("SAPI.SpVoice")
Set cat  = CreateObject("SAPI.SpObjectTokenCategory")
cat.SetID "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Speech_OneCore\Voices", False
For Each token In cat.EnumerateTokens
    If token.GetAttribute("Name") = "Microsoft Sayaka" Then
        Set fs = CreateObject("SAPI.SpFileStream")
        fs.Open "sayaka.wav", 3
        Set sapi.AudioOutputStream = fs
        Set oldv = sapi.Voice
        Set sapi.Voice = token
        sapi.Speak "こんにちは、世界"
        Set sapi.Voice = oldv
        fs.Close()
        Exit For
    End If
Next
```

【参考】 [Windowsバッチで，手軽に日本語テキストを自動読み上げ（Text To Speech）する方法　…WSHでSAPIやSpeech.SpVoiceを使う音声合成の手順とサンプルコード - 主に言語とシステム開発に関して](https://language-and-engineering.hatenablog.jp/entry/20150202/JapaneseTextToSpeechProgramming)

※ Sayaka を C++ で使用する方法については以下で議論されています。

* [Where is the Sayaka voice in Speech API OneCore? - Stack Overflow](https://stackoverflow.com/questions/60618283/where-is-the-sayaka-voice-in-speech-api-onecore)

# 経緯

アラビア語の音声ファイルを作ろうとしてハマりました。調査の結果、成功しました。

* https://gist.github.com/7shi/9a55a337c7ba456c266e9487f9520ad0

# 関連リンク

SAPI が2系統あることに触れた記事です。

* [SAPIの参照設定の違い](https://qiita.com/Q11Q/items/9325cb55e8799f620fd6)

`GetAttribute` で取得できる情報についての記事です。

* [VBAでTTSエンジンの各種情報を列挙する | 初心者備忘録](https://www.ka-net.org/blog/?p=297)
