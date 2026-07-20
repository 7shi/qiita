---
coediting: false
comments_count: 0
created_at: '2020-05-01T02:25:23+09:00'
id: 51017b4b268f66e11c42
likes_count: 12
private: false
reactions_count: 0
stocks_count: 10
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
title: SAPIで発音を指定する
updated_at: '2020-05-16T01:58:48+09:00'
url: https://qiita.com/7shi/items/51017b4b268f66e11c42
slide: false
---

Windows で音声を読み上げるのに使用する SAPI で、発音を指定する方法を調べました。

応用として未サポートの言語を読み上げる方法については、以下の記事を参照してください。

* [SAPIで未サポートの言語を喋らせる](https://qiita.com/7shi/items/ecb9ea901e4026a925ee)

# 準備

Windows 10 でサポートされる音声の一覧です。

* [付録 A: Windows 10 のナレーターでサポートされている言語と音声 - Windows Help](https://support.microsoft.com/ja-jp/help/22805/windows-10-supported-narrator-languages-voices)

日本語以外の言語を使用する場合は追加します。

* [Windows 10で読み上げ言語を追加](https://7shi.hateblo.jp/entry/2020/02/22/185810)

次の記事で作成した SAPI をラップしたコマンド wintts を使用します。

* [PythonでWindows 10の音声合成を使用する](https://qiita.com/7shi/items/a5fb03406e0626b4f138)

# 指定方法

SAPI では 2種類の XML が使えます。

1. SAPI TTS XML: 独自規格
2. SSML (Speech Synthesis Markup Language): 標準化されたマークアップ言語

アメリカ英語の hello を例に取ります。

* [hello /hɛˈloʊ/](https://en.wiktionary.org/wiki/hello)

これを各種方法で発音を指定して読み上げます。

* SAPI TTS XML

```xml
wintts -v zira '<pron sym="h eh - l ow 1"/>'
```

* SSML（3種類の表記方法）

```xml
wintts '<speak version="1.0" xml:lang="en-US"><phoneme alphabet="sapi" ph="h eh - l ow 1"/></speak>'
wintts '<speak version="1.0" xml:lang="en-US"><phoneme alphabet="ups" ph="h eh . l o + uh s1"/></speak>'
wintts '<speak version="1.0" xml:lang="en-US"><phoneme alphabet="ipa" ph="hɛ.ˈloʊ"/></speak>'
```

上例の SSML は SAPI が受け付けるのに最低限必要な要素だけに簡略化しています。XML として正式な形式は以下の通りです。

```xml:hello.ssml
<?xml version="1.0" encoding="UTF-8"?>
<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="en-US">
    <phoneme alphabet="ipa" ph="hɛ.ˈloʊ">hello</phoneme>
</speak>
```
```text:実行方法
wintts -i hello.ssml
```

# SAPI TTS XML

使用できるタグについては以下に記載されています。

* [XML TTS Tutorial SAPI 5.4 | Microsoft Docs](https://docs.microsoft.com/en-us/previous-versions/windows/desktop/ee431815(v=vs.85))
* [Microsoft Speech Platform のサンプルプログラム その１ (C#) ::まほろば](http://www.mahoro-ba.sakura.ne.jp/e1590.html)

このうち、発音を指定するのは `pron` タグの `sym` 属性です。

* [International Phoneme Representation (SAPI 5.4) | Microsoft Docs](https://docs.microsoft.com/en-us/previous-versions/windows/desktop/ee125161%28v%3dvs.85%29)

> ```xml
> <PRON SYM = "h eh l ow"/>
> ```

発音の表記体系は、言語ごとにカスタマイズされたものと、共通化されたものとがあります。

## SAPI

言語ごとにカスタマイズされた表記体系は、他の表記体系と区別するため便宜上 SAPI と呼びます。

言語別に記載されています。

* 英語（アメリカ）: [American English Phoneme Representation (SAPI 5.4) | Microsoft Docs](https://docs.microsoft.com/en-us/previous-versions/windows/desktop/ee431828(v=vs.85))
* 日本語: [Japanese Phonemes (SAPI 5.4) | Microsoft Docs](https://docs.microsoft.com/en-us/previous-versions/windows/desktop/ee125162(v=vs.85))
* 中国語（大陸）: [Chinese Phonemes (SAPI 5.4) | Microsoft Docs](https://docs.microsoft.com/en-us/previous-versions/windows/desktop/ee125160(v=vs.85))

Azure の資料にはもう少し詳しい説明があります。英語（アメリカ）、フランス語（フランス）、ドイツ語（ドイツ）、スペイン語（スペイン）、中国語（大陸）、中国語（台湾）、日本語（日本）について記載されています。

* 原文（英語）: [Speech phonetic sets - Speech service - Azure Cognitive Services | Microsoft Docs](https://docs.microsoft.com/en-us/azure/cognitive-services/speech-service/speech-ssml-phonetic-sets?tabs=en-US)
* 日本語訳: [Speech 発音設定 - Speech サービス - Azure Cognitive Services | Microsoft Docs](https://docs.microsoft.com/ja-jp/azure/cognitive-services/speech-service/speech-ssml-phonetic-sets?tabs=en-US)

言語と地域の組み合わせは重要です。上記7つの組み合わせだけが専用の表記体系を持っています。それ以外は Universal Phone Set (UPS) という共通化された表記体系を使用します。アメリカ以外の英語や、フランス以外のフランス語なども UPS です。

※ 7つの組み合わせは初期に実装されたため、まだ共通化の構想がなく、個別に実装されたのではないかと推測します。

## UPS

UPS は 1993 年時点での[国際音声記号](https://ja.wikipedia.org/wiki/%E5%9B%BD%E9%9A%9B%E9%9F%B3%E5%A3%B0%E8%A8%98%E5%8F%B7)（IPA）といくつかの付加記号を ASCII 文字だけで表記できるようにした Microsoft 独自の表記体系です。

* [Universal Phone Set (UPS) (Microsoft.Speech) | Microsoft Docs](https://docs.microsoft.com/en-us/previous-versions/office/developer/speech-technologies/hh378346(v=office.14))

> 1. UPS covers the IPA 1993 Unicode character set, plus some extra SAPI phones including some suprasegmental labels that are used in speech synthesis markup but are not found in IPA.

※ 表記の類似性から [ARPABET](https://en.wikipedia.org/wiki/ARPABET) の 2-letter をベースにしているのではないかと推測します。

以下の言語一覧の最初の7つ以外が UPS でサポートされる言語です。ただしすべての言語の TTS エンジンが用意されているわけではありません。

* [Language Coverage (Microsoft.Speech) | Microsoft Docs](https://docs.microsoft.com/en-us/previous-versions/office/developer/speech-technologies/hh362866(v=office.14))

音素についての資料を示します。なお、UPS は大文字と小文字を区別しません。（case-insensitive）

* 一覧: [UPS to SAPI Phone Map (Microsoft.Speech) | Microsoft Docs](https://docs.microsoft.com/en-us/previous-versions/office/developer/speech-technologies/hh362820%28v%3doffice.14%29)
* 子音: [Consonants (Microsoft.Speech) | Microsoft Docs](https://docs.microsoft.com/en-us/previous-versions/office/developer/speech-technologies/hh362821(v=office.14))
* 母音: [Vowels (Microsoft.Speech) | Microsoft Docs](https://docs.microsoft.com/en-us/previous-versions/office/developer/speech-technologies/hh378338(v=office.14))
* 特殊化: [Diacritics (Microsoft.Speech) | Microsoft Docs](https://docs.microsoft.com/en-us/previous-versions/office/developer/speech-technologies/hh378443(v=office.14))（有気化・咽頭化など）
* アクセント・抑揚: [Suprasegmentals (Microsoft.Speech) | Microsoft Docs](https://docs.microsoft.com/en-us/previous-versions/office/developer/speech-technologies/hh378431(v=office.14))
* 吸着音・放出音: [Clicks and Ejectives (Microsoft.Speech) | Microsoft Docs](https://docs.microsoft.com/en-us/previous-versions/office/developer/speech-technologies/hh378397(v=office.14))
* 声調: [Tones (Microsoft.Speech) | Microsoft Docs](https://docs.microsoft.com/en-us/previous-versions/office/developer/speech-technologies/hh378347(v=office.14))
* その他: [Other Phones (Microsoft.Speech) | Microsoft Docs](https://docs.microsoft.com/en-us/previous-versions/office/developer/speech-technologies/hh362844(v=office.14))
* 構文解析: [Parsing Guidelines for SAPI Speech Recognition Phone Converters (Microsoft.Speech) | Microsoft Docs](https://docs.microsoft.com/en-us/previous-versions/office/developer/speech-technologies/hh362927%28v%3doffice.14%29)

UPS の資料には音素の一覧は列挙されていますが、個別の言語でどの音素が使用できるのかは判然としません。その言語でサポートされない音素を渡しても、無音になったり別の音で代替されたりするようです。例えばイタリア語に h の音素は存在しないため k で代替されます。

## レジストリ

SAPI や UPS の音素はレジストリに記載されています。

* `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Speech\PhoneConverters\Tokens`

各表記体系の下位階層にある Attributes には、使用できる言語がコードで記載されています。

# SSML

標準化されたマークアップ言語です。各社のクラウド TTS サービスでも採用されているため、SAPI 以外でも使用できます。

Azure の Speech Service でサポートされる SSML については以下に記載されています。

* [音声合成マークアップ言語 (SSML) - Speech Service - Azure Cognitive Services | Microsoft Docs](https://docs.microsoft.com/ja-jp/azure/cognitive-services/speech-service/speech-synthesis-markup?tabs=csharp)

まずトップレベルの `speak` タグの仕様です。

> 構文
> 
> ```xml
> <speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="string"></speak>
> ```
> 
> 属性
> 
> 属性|説明|必須/省略可能
> ----|----|----
> `version`|ドキュメント マークアップの解釈に使用される SSML 仕様のバージョンを指定します。 現行バージョンは 1.0 です。|必須
> `xml:lang`|ルート ドキュメントの言語を指定します。 この値には、小文字、2 文字の言語コード (`en` など)、または言語コードと大文字の国/地域 (`en-US` など) を含めることができます。|必須
> `xmlns`|SSML のドキュメントのマークアップ ボキャブラリ (要素型と属性名) を定義するドキュメントへの URI を指定します。 現在の URI は <http://www.w3.org/2001/10/synthesis> です。|必須

`xml:lang` に指定する言語・地域コードは以下の記事を参照してください。

* [SSMLの言語・地域コードとSAPI音声の対応](https://qiita.com/7shi/items/ff9cf324f18234cabd82)

SAPI では SSML で言語を指定しても OneCore の音声は選択されません。wintts では `-v` オプションによる音声の指定と併用した方が無難です。

```sh:例
wintts -v hoda '<speak version="1.0" xml:lang="ar-EG">（略）</speak>'
```

## phoneme

SSML のすべてのタグが SAPI でもサポートされているかは不明ですが、今回必要となる `phoneme` タグは SAPI でも利用できます。サポートされる発音表記体系（`alphabet` 属性）は SAPI, UPS, IPA の3種類です。

> 構文
> 
> ```xml
> <phoneme alphabet="string" ph="string"></phoneme>
> ```
> 
> 属性
> 
> 属性|説明|必須/省略可能
> ----|----|----
> `alphabet`|`ph` 属性の文字列の発音を合成するときに使用する音標文字を指定します。アルファベット順を指定する文字列は、小文字で指定する必要があります。指定できる可能性のあるアルファベットは次のとおりです。<ul><li>`ipa` – 国際音標文字</li><li>`sapi` – Speech サービス発音アルファベット</li><li>`ups` – 汎用音素セット</li></ul>アルファベットは、要素内の `phoneme` にのみ適用されます。|省略可能
> `ph`|`phoneme` 要素内の単語の発音を指定する音素を含む文字列。指定した文字列に認識されない音素が含まれている場合、テキスト読み上げ (TTS) サービスは SSML ドキュメント全体を拒否し、ドキュメントに指定されている音声出力を生成しません。|音素を使用する場合は必須です。

アメリカ英語に対して SAPI TTS XML では専用の表記体系（SAPI）を使用しましたが、SSML では UPS や IPA の使用が可能です。もともと専用の表記体系が用意されていない言語では、UPS と IPA のみ使用可能です。

## X-SAMPA

現状の SAPI ではサポートされていませんが、他社では X-SAMPA のサポートが進んでいることから、将来的には標準的に使用されることが予想されます。

* [X-SAMPA - Wikipedia](https://ja.wikipedia.org/wiki/X-SAMPA)

> **X-SAMPA**（Extended SAM Phonetic Alphabet）、**拡張SAM音声記号**（かくちょうエスエイエムおんせいきごう）は発音記号のひとつ。SAMPAの変種で、1995年にロンドン大学の音声学教授ジョン・C・ウェルズによって開発された。すべての国際音声記号の文字記号をASCII文字のみで表すことができる。 

UPS の資料にも X-SAMPA が併記されているため、対応を確認できます。

## Amazon Polly

Amazon の TTS サービスである Polly の資料には、サポートする各言語について音素一覧が記載されています。

* [Phoneme and Viseme Tables for Supported Languages - Amazon Polly](https://docs.aws.amazon.com/polly/latest/dg/ref-phoneme-tables-shell.html)

Polly の資料にある X-SAMPA と、UPS の資料にある X-SAMPA を比較することで、特定の音素の UPS での表記方法を調べることができます。

なお、Polly では SSML で指定できる表記体系は IPA と X-SAMPA です。

* [サポートされている SSML タグ - Amazon Polly](https://docs.aws.amazon.com/ja_jp/polly/latest/dg/supportedtags.html)

> * `alphabet`
>   * `ipa`— 国際音声記号 (IPA) が使用されることを表します。
>   * `x-sampa`— 拡張 SAM 音声記号 (X-SAMPA) システムが使用されることを表します。

### IPA から UPS への変換の例

アラビア語の「サバーハルハイル（おはようございます）」を例に UPS への変換方法を示します。

* [صَبَاح الخَيْر‎ (ṣabāḥ al-ḵayr) /sˤa.baːħ al.xajr/](https://en.wiktionary.org/wiki/%D8%B5%D8%A8%D8%A7%D8%AD_%D8%A7%D9%84%D8%AE%D9%8A%D8%B1)

SAPI でも SSML によって IPA で読み上げができます。

```text
wintts -v hoda '<speak version="1.0" xml:lang="ar-EG"><phoneme alphabet="ipa" ph="sˤa.baːħ al.xajr"/></speak>'
```

SSML は記述が長くなり、IPA の入力も手間が掛かるため、できれば UPS での表記方法も知っておきたいところです。

[Polly のアラビア語の資料](https://docs.aws.amazon.com/polly/latest/dg/ph-table-arabic.html)を参照して、IPA から X-SAMPA に変換します。

* /sˤa.baːħ al.xajr/ → `s_?\a.ba:X\ al.xajr`

※ 咽頭化子音 /sˤ/ の後の母音 /a/ は咽頭化するため `A_?\` の方が正確です。しかし SAPI では母音に付加しても反映されないようです。

以下の3つの資料を参照して X-SAMPA に対応する UPS を確認します。特殊なものだけ括弧書きで示します。

* 子音: [Consonants (Microsoft.Speech) | Microsoft Docs](https://docs.microsoft.com/en-us/previous-versions/office/developer/speech-technologies/hh362821(v=office.14))（`X\` → `HH`）
* 母音: [Vowels (Microsoft.Speech) | Microsoft Docs](https://docs.microsoft.com/en-us/previous-versions/office/developer/speech-technologies/hh378338(v=office.14))（`a:` → `A lng`）
* 特殊化: [Diacritics (Microsoft.Speech) | Microsoft Docs](https://docs.microsoft.com/en-us/previous-versions/office/developer/speech-technologies/hh378443(v=office.14))（`_?\` → `phr`）

X-SAMPA から UPS に変換します。UPS では各要素間にスペースが必要です。

* `s_?\a.ba:X\ al.xajr` → `S phr A . B A lng HH A L . X A J R`

SAPI で読み上げます。SSML は冗長なので SAPI TTS XML を使用します。

```text
wintts -v hoda '<pron sym="S phr A . B A lng HH A L . X A J R"/>'
```

最後の `R` が聞こえません。震えを強調する `RR` を試みます。

```text
wintts -v hoda '<pron sym="S phr A . B A lng HH A L . X A J RR"/>'
```

うまく発音できたようです。

### 利用方法

Polly の資料にフリーライドするようで申し訳ないため、利用方法についての記事を紹介します。

* [【ミニレビュー】入力したテキストを音声に変換するAWS「Amazon Polly」を無料で試す-Impress Watch](https://www.watch.impress.co.jp/docs/review/minireview/1243596.html)

> Amazon Pollyの初回利用から12カ月間は、500万字/月まで無料。500万字なら、音声の長さで100時間超は使える計算となるので、試しに使ってみるには十分です。

# 変換プログラム

各種発音表記体系を変換するプログラムです。

* [lexconvert: a converter between the lexicon formats of different speech synthesizers](http://ssb22.user.srcf.net/gradint/lexconvert.html)

SAPI はアメリカ英語のみのサポートで、UPS はサポートされていません。IPA と X-SAMPA の変換に有用そうです。

# 経緯

利用する観点からは、ここまで情報が揃ってようやくスタート地点です。

当初、どこを見れば良いのか分からずに試行錯誤しました。参考までに個人的な経緯を書いておきます。

アラビア語やヘブライ語の勉強のため SAPI で読み上げを試そうとしました。しかし普通の方法ではそれらの言語エンジンが使用できませんでした。どうにか裏技的な方法を見付けて使用できるようになりました。

* [VBSでOneCoreの音声を使用する](https://qiita.com/7shi/items/7781516d6746e29c03b4)

VBScript は言語仕様の進化が止まっており、書くのが辛かったため Python に移植して WSL から使えるようにしました。

* [PythonでWindows 10の音声合成を使用する](https://qiita.com/7shi/items/a5fb03406e0626b4f138)

アラビア語やヘブライ語を読み上げると、いくつか想定していたのと発音が違うことがありました。そのため発音を指定する方法を調べて、`pron` タグで指定できることが分かりました。しかし発音の表記体系が分からなかったため、利用することができませんでした。英語などいくつかの言語の資料はすぐに見付かりましたが、アラビア語やヘブライ語に言及した資料は見当たりませんでした。

あれこれ探しているうちに、英語の表記体系が ARPABET の 2-letter に似ていることに気付きました。そこでスクリプトを書いて、総当たりで2文字の組み合わせのうち SAPI が受け付けるものを調べました。

<blockquote class="twitter-tweet" data-conversation="none"><p lang="ja" dir="ltr">音素の資料がない言語が大半なので、使える音素を総当たりで調べている。（再生を試みて例外が起きるかどうかで判断）<br>音素がアルファベット2文字までの組み合わせで表記されない言語は検出できないけど、それら（日本語と台湾の中国語）は資料が用意されているので何とかなりそう。 <a href="https://t.co/3xcWdlwHdt">pic.twitter.com/3xcWdlwHdt</a></p>&mdash; 七誌 (@7shi) <a href="https://twitter.com/7shi/status/1255431934504833024?ref_src=twsrc%5Etfw">April 29, 2020</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script> 

得られた結果から、資料が揃っている言語ではそれぞれの言語にカスタマイズされた表記体系を使っているのに対して、それ以外は表記体系を共有していることが分かりました。共有されている表記体系に現れる音素で検索したところ、それらが UPS と呼ばれることが分かりました。UPS という用語が分かれば、後はスムーズに資料が見付かりました。それらをまとめたのが今回の記事です。

発音が指定できれば、古代語や人工言語を読ませることもできると期待しています。
