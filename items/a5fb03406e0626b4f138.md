---
coediting: false
comments_count: 0
created_at: '2020-04-28T05:55:39+09:00'
id: a5fb03406e0626b4f138
likes_count: 34
private: false
reactions_count: 0
stocks_count: 20
tags:
- name: Python
  versions: []
- name: TTS
  versions: []
- name: TextToSpeech
  versions: []
- name: Windows10
  versions: []
- name: SAPI
  versions: []
title: PythonでWindows 10の音声合成を使用する
updated_at: '2020-06-24T17:15:51+09:00'
url: https://qiita.com/7shi/items/a5fb03406e0626b4f138
slide: false
---

以下の記事で作成した VBScript のコードを移植して、簡単に使えるようにコマンド化します。

* [VBSでOneCoreの音声を使用する](https://qiita.com/7shi/items/7781516d6746e29c03b4)

このコマンドで動画を作成する方法は以下の記事を参照してください。

* [紙芝居方式で動画を作成](https://qiita.com/7shi/items/9a4f2220cfde4fbbdce7)

発音の指定方法については以下の記事を参照してください。

* [SAPIで発音を指定する](https://qiita.com/7shi/items/51017b4b268f66e11c42)
* [SAPIで未サポートの言語を喋らせる](https://qiita.com/7shi/items/ecb9ea901e4026a925ee)

他の言語での利用については以下の記事を参照してください。

* [WinRTで音声合成](https://qiita.com/7shi/items/dc21a3be8b7c69fbc11b) (C#)
* [Rust/WinRTで音声合成](https://qiita.com/7shi/items/885501607aecee7613fa)

# 準備

Windows 10 でサポートされる音声の一覧です。

* [付録 A: Windows 10 のナレーターでサポートされている言語と音声 - Windows Help](https://support.microsoft.com/ja-jp/help/22805/windows-10-supported-narrator-languages-voices)

日本語以外の言語を使用する場合は追加します。

* [Windows 10で読み上げ言語を追加](https://7shi.hateblo.jp/entry/2020/02/22/185810)

COM を使用するため pip で pywin32 をインストールします。

```text:ライブラリのインストール
py -m pip install pywin32
```

# 移植

使用可能な音声を取得します。

```vb:voices2.py
import win32com.client
cat  = win32com.client.Dispatch("SAPI.SpObjectTokenCategory")
cat.SetID(r"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Speech_OneCore\Voices", False)
for token in cat.EnumerateTokens():
    print(token.GetDescription())
```
```text:実行結果
Microsoft Ayumi - Japanese (Japan)
Microsoft Naayf - Arabic (Saudi)
Microsoft Ivan - Bulgarian (Bulgaria)
Microsoft Herena - Catalan (Catalan)
Microsoft Jakub - Czech (Czech Republic)
（以下略）
```

音声を指定して読み上げる例です。

```vb:sayaka.py
import win32com.client
sapi = win32com.client.Dispatch("SAPI.SpVoice")
cat  = win32com.client.Dispatch("SAPI.SpObjectTokenCategory")
cat.SetID(r"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Speech_OneCore\Voices", False)
v = [t for t in cat.EnumerateTokens() if t.GetAttribute("Name") == "Microsoft Sayaka"]
if v:
    oldv = sapi.Voice
    sapi.Voice = v[0]
    sapi.Speak("こんにちは、世界")
    sapi.Voice = oldv
```

<font color="red">**【注意】**</font> ソースは UTF-8 で保存してください。

音声をファイル `sayaka.wav` に出力する例です。

```vb:sayaka-wav.py
import win32com.client
sapi = win32com.client.Dispatch("SAPI.SpVoice")
cat  = win32com.client.Dispatch("SAPI.SpObjectTokenCategory")
cat.SetID(r"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Speech_OneCore\Voices", False)
v = [t for t in cat.EnumerateTokens() if t.GetAttribute("Name") == "Microsoft Sayaka"]
if v:
    fs = win32com.client.Dispatch("SAPI.SpFileStream")
    fs.Open("sayaka.wav", 3)
    sapi.AudioOutputStream = fs
    oldv = sapi.Voice
    sapi.Voice = v[0]
    sapi.Speak("こんにちは、世界")
    sapi.Voice = oldv
    fs.Close()
```

COM さえ使えてしまえば、後は普通の Python です。

# コマンド

読み上げや保存を簡単に行えるようにするためコマンド化しました。他から参照すればライブラリとしても使えます。

* [[py] SAPI client](https://gist.github.com/7shi/f1eb51912cdf69598a8937bd2a212784)

```text:使用例
py wintts.py -l
py wintts.py -l ja en
py wintts.py こんにちは、世界
py wintts.py -v sayaka -r 5 こんにちは、世界
py wintts.py -v sayaka -o sayaka.wav -i hello.txt
py wintts.py -v zira -p "h eh - l ow 1"
py wintts.py -v zira -s ipa "hɛ.ˈloʊ"
```

# WSL

WSL の Python から COM は呼べませんが、WSL から Windows 側の Python を呼ぶことはできます。

wintts.py をどこか Windows から見える場所に置きます。次のような簡単なラッパーを書いて、WSL でパスが通っている場所に置いて実行属性を付けます。

```sh:wintts
#!/bin/sh
py.exe 'C:\スクリプト置き場\wintts.py' "$@"
```

これであたかも WSL のコマンドのように使うことができます。

```text:使用例
$ py wintts.py -l de fr
de-AT, German (Austria): Microsoft Michael
de-CH, German (Switzerland): Microsoft Karsten
de-DE, German (Germany): Microsoft Hedda
de-DE, German (Germany): Microsoft Katja
de-DE, German (Germany): Microsoft Stefan
fr-CA, French (Canada): Microsoft Caroline
fr-CA, French (Canada): Microsoft Claude
fr-CA, French (Canada): Microsoft Nathalie(Canada)
fr-CH, French (Switzerland): Microsoft Guillaume
fr-FR, French (France): Microsoft Hortense
fr-FR, French (France): Microsoft Julie
fr-FR, French (France): Microsoft Paul
$ wintts -v julie bonjour
$ wintts -o de.wav -v hedda guten tag
$ winplay de.wav
```

最後に呼び出している winplay は、以下の記事で作成した自作スクリプトです。

* [WSLからWAVEファイルを再生する](https://qiita.com/7shi/items/a4c82a48fdcc113815f1)

# 関連リンク

この記事を書いた後に、いくつか Python で SAPI を扱う記事などを見掛けたので追記します。

* [com - Python: Using SSML with SAPI (comtypes) - Stack Overflow](https://stackoverflow.com/questions/55622679/python-using-ssml-with-sapi-comtypes)
* [windows - Python 3.4 - Text to Speech with SAPI - Stack Overflow](https://stackoverflow.com/questions/31167967/python-3-4-text-to-speech-with-sapi/31172101)
* [Microsoft Speech Platform のサンプルプログラム (Python)::まほろば](http://mahoro-ba.net/e1382.html)
* [Text to Speech using COM (Python) | DaniWeb](https://www.daniweb.com/programming/software-development/code/217062/text-to-speech-using-com-python)
* [Windows 7でPythonなどから日本語音声合成 - 西尾泰和のはてなダイアリー](https://nishiohirokazu.hatenadiary.org/entry/20150220/1424413665)
* [Python + pywin32 で COM 叩いてしゃべらせる。 | みむらの手記手帳](https://mimumimu.net/blog/2011/07/02/python-pywin32-%E3%81%A7-com-%E5%8F%A9%E3%81%84%E3%81%A6%E3%81%97%E3%82%83%E3%81%B9%E3%82%89%E3%81%9B%E3%82%8B%E3%80%82/)
