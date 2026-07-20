---
coediting: false
comments_count: 0
created_at: '2020-05-15T05:40:36+09:00'
id: ff9cf324f18234cabd82
likes_count: 0
private: false
reactions_count: 0
stocks_count: 1
tags:
- name: TTS
  versions: []
- name: TextToSpeech
  versions: []
- name: Windows10
  versions: []
- name: SSML
  versions: []
- name: SAPI
  versions: []
title: SSMLの言語・地域コードとSAPI音声の対応
updated_at: '2020-05-15T05:45:25+09:00'
url: https://qiita.com/7shi/items/ff9cf324f18234cabd82
slide: false
---

SSML では言語・地域コードを指定する必要があります。SAPI の音声との対応表が見当たらなかったため調査しました。

SAPI で SSML を使用する方法は以下の記事を参照してください。

* [SAPIで発音を指定する](https://qiita.com/7shi/items/51017b4b268f66e11c42)

# 対応表

先に結果を掲載します。

LangID|コード|言語|地域|音声
---:|:--:|----|----|----
0c01|ar-EG|Arabic|Egypt|Microsoft Hoda
401|ar-SA|Arabic|Saudi|Microsoft Naayf
402|bg-BG|Bulgarian|Bulgaria|Microsoft Ivan
0403|ca-ES|Catalan|Catalan|Microsoft Herena
405|cs-CZ|Czech|Czech Republic|Microsoft Jakub
0406|da-DK|Danish|Denmark|Microsoft Helle
C07|de-AT|German|Austria|Microsoft Michael
807|de-CH|German|Switzerland|Microsoft Karsten
407|de-DE|German|Germany|Microsoft Hedda<br>Microsoft Katja<br>Microsoft Stefan
408|el-GR|Greek|Greece|Microsoft Stefanos
C09|en-AU|English|Australia|Microsoft Catherine<br>Microsoft James
1009|en-CA|English|Canada|Microsoft Linda<br>Microsoft Richard
809|en-GB|English|United Kingdom|Microsoft George<br>Microsoft Hazel<br>Microsoft Susan
1809|en-IE|English|Ireland|Microsoft Sean
4009|en-IN|English|India|Microsoft Heera<br>Microsoft Ravi
409|en-US|English|United States|Microsoft David<br>Microsoft Mark<br>Microsoft Zira
C0A|es-ES|Spanish|Spain|Microsoft Helena<br>Microsoft Laura<br>Microsoft Pablo
80A|es-MX|Spanish|Mexico|Microsoft Raul<br>Microsoft Sabina
040b|fi-FI|Finnish|Finland|Microsoft Heidi
C0C|fr-CA|French|Canada|Microsoft Caroline<br>Microsoft Claude<br>Microsoft Nathalie(Canada)
100C|fr-CH|French|Switzerland|Microsoft Guillaume
40C|fr-FR|French|France|Microsoft Hortense<br>Microsoft Julie<br>Microsoft Paul
40D|he-IL|Hebrew|Israel|Microsoft Asaf
439|hi-IN|Hindi|India|Microsoft Hemant<br>Microsoft Kalpana
41A|hr-HR|Croatian|Croatia|Microsoft Matej
40E|hu-HU|Hungarian|Hungary|Microsoft Szabolcs
421|id-ID|Indonesian|Indonesia|Microsoft Andika
410|it-IT|Italian|Italy|Microsoft Cosimo<br>Microsoft Elsa
411|ja-JP|Japanese|Japan|Microsoft Ayumi<br>Microsoft Haruka<br>Microsoft Ichiro<br>Microsoft Sayaka
412|ko-KR|Korean|Korean|Microsoft Heami
43E|ms-MY|Malay|Malaysia|Microsoft Rizwan
0414|nb-NO|Norwegian|Bokmål|Microsoft Jon
0813|nl-BE|Dutch|Belgium|Microsoft Bart
0413|nl-NL|Dutch|Netherlands|Microsoft Frank
415|pl-PL|Polish|Poland|Microsoft Adam<br>Microsoft Paulina
416|pt-BR|Portuguese|Brazil|Microsoft Daniel<br>Microsoft Maria
0816|pt-PT|Portuguese|Portugal|Microsoft Helia
418|ro-RO|Romanian|Romania|Microsoft Andrei
419|ru-RU|Russian|Russia|Microsoft Irina<br>Microsoft Pavel
41B|sk-SK|Slovak|Slovakia|Microsoft Filip
424|sl-SI|Slovenian|Slovenia|Microsoft Lado
041d|sv-SE|Swedish|Sweden|Microsoft Bengt
449|ta-IN|Tamil|India|Microsoft Valluvar
41E|th-TH|Thai|Thailand|Microsoft Pattara
041f|tr-TR|Turkish|Turkey|Microsoft Tolga
42A|vi-VN|Vietnamese|Vietnam|Microsoft An
804|zh-CN|Chinese|Simplified, PRC|Microsoft Huihui<br>Microsoft Kangkang<br>Microsoft Yaoyao
C04|zh-HK|Chinese|Traditional, Hong Kong S.A.R.|Microsoft Danny<br>Microsoft Tracy
404|zh-TW|Chinese|Traditional, Taiwan|Microsoft Hanhan<br>Microsoft Yating<br>Microsoft Zhiwei

* LangID は3桁だったり4桁だったりしますが、SAPI の出力をそのまま使っています。
* なぜか Nathalie は名前にも地域名が付いています。

Microsoft の資料には LangID の一覧はありますが、言語・地域コードとの対応は一部しか記載されていません。

* [Language Coverage (Microsoft.Speech) | Microsoft Docs](https://docs.microsoft.com/en-us/previous-versions/office/developer/speech-technologies/hh362866(v=office.14))

Azure の Speech Service の資料には言語・地域コードと音声の一覧表がありますが、SAPI で使用できる音声とどこまで同じなのかは不明です。

* [言語サポート - 音声サービス - Azure Cognitive Services | Microsoft Docs](https://docs.microsoft.com/ja-jp/azure/cognitive-services/speech-service/language-support)

# 調査方法

以下の記事のコードを流用して、Python で SAPI を扱います。

* [PythonでWindows 10の音声合成を使用する](https://qiita.com/7shi/items/a5fb03406e0626b4f138)

token には id があります。

【参考】 [VBAでTTSエンジンの各種情報を列挙する | 初心者備忘録](https://www.ka-net.org/blog/?p=297)

id にはレジストリキーが使用され、言語・地域コードが含まれます。

```vb:sapitoken.py
import win32com.client
cat  = win32com.client.Dispatch("SAPI.SpObjectTokenCategory")
cat.SetID(r"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Speech_OneCore\Voices", False)
for token in cat.EnumerateTokens():
    print(token.id)
    break
```
```text:実行結果
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Speech_OneCore\Voices\Tokens\MSTTS_V110_jaJP_AyumiM
```

この情報を表の形に整理します。

```vb:sapicheck.py
import win32com.client
cat  = win32com.client.Dispatch("SAPI.SpObjectTokenCategory")
cat.SetID(r"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Speech_OneCore\Voices", False)
codes = {}
for token in cat.EnumerateTokens():
    lr = token.GetDescription().split(" - ")[1].split(" (")
    l, r = lr[0], lr[1] if len(lr) > 1 else ""
    if r.endswith(")"): r = r[:-1]
    code = token.id.split("\\")[-1].split("_")[2]
    if code[2] != "-": code = code[:2] + "-" + code[2:]
    if not code in codes:
        codes[code] = (token.GetAttribute("Language"), l, r, [])
    codes[code][3].append(token.GetAttribute("Name"))
for k in sorted(codes.keys()):
    lang, l, r, names = codes[k]
    names.sort()
    print("|".join([lang, k, l, r, "<br>".join(names)]))
```

このスクリプトから出力したのが先に掲載した対応表です。
