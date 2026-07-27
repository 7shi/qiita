---
coediting: false
comments_count: 3
created_at: '2020-05-09T05:50:35+09:00'
id: 7f98e144cb69234c5e0e
likes_count: 0
private: false
reactions_count: 0
stocks_count: 2
tags:
- name: Windows10
  versions: []
- name: WebSpeechAPI
  versions: []
- name: SAPI
  versions: []
title: Windowsのブラウザで使える音声の調査
updated_at: '2025-04-13T12:24:13+09:00'
url: https://qiita.com/7shi/items/7f98e144cb69234c5e0e
slide: false
---

Windows ではブラウザの Web Speech API から SAPI の音声を利用します。リストアップされる音声を確認しました。

:::note warn
この記事の情報は古いです。現時点では使用できる言語は増えています。
:::

# 調査方法

Windows 10 でサポートされる音声の一覧です。

* [付録 A: Windows 10 のナレーターでサポートされている言語と音声 - Windows Help](https://support.microsoft.com/ja-jp/help/22805/windows-10-supported-narrator-languages-voices)

日本語以外の言語を使用する場合は追加します。

* [Windows 10で読み上げ言語を追加](https://7shi.hateblo.jp/entry/2020/02/22/185810)

すべての言語を追加した状態で、以下のテストコードを開きます。

<p class="codepen" data-height="265" data-theme-id="light" data-default-tab="result" data-user="7shi" data-slug-hash="rNOdqmq" style="height: 265px; box-sizing: border-box; display: flex; align-items: center; justify-content: center; border: 2px solid; margin: 1em 0; padding: 1em;" data-pen-title="ブラウザで使える音声の調査">
  <span>See the Pen <a href="https://codepen.io/7shi/pen/rNOdqmq">
  ブラウザで使える音声の調査</a> by 七誌 (<a href="https://codepen.io/7shi">@7shi</a>)
  on <a href="https://codepen.io">CodePen</a>.</span>
</p>
<script async src="https://static.codepen.io/assets/embed/ei.js"></script>

↑ エラーになる場合は一度 [CodePen](https://codepen.io/) を開いてから、この記事をリロードしてください。

このコードで使用している Web Speech API については以下の記事を参照してください。

* [Web Speech API で読み上げ位置を取得](https://qiita.com/7shi/items/43452dcd34e57100fc3c)

# Firefox

調査に使用したバージョンは 76.0.1 です。

```text
[  1] ja-JP: Microsoft Haruka Desktop - Japanese
[  2] en-GB: Microsoft Hazel Desktop - English (Great Britain)
[  3] en-US: Microsoft David Desktop - English (United States)
[  4] en-US: Microsoft Zira Desktop - English (United States)
[  5] es-ES: Microsoft Helena Desktop - Spanish (Spain)
[  6] es-MX: Microsoft Sabina Desktop - Spanish (Mexico)
[  7] fr-FR: Microsoft Hortense Desktop - French
[  8] it-IT: Microsoft Elsa Desktop - Italian (Italy)
[  9] de-DE: Microsoft Hedda Desktop - German
[ 10] ko-KR: Microsoft Heami Desktop - Korean
[ 11] pl-PL: Microsoft Paulina Desktop - Polish
[ 12] pt-BR: Microsoft Maria Desktop - Portuguese(Brazil)
[ 13] ru-RU: Microsoft Irina Desktop - Russian
[ 14] zh-CN: Microsoft Huihui Desktop - Chinese (Simplified)
[ 15] zh-HK: Microsoft Tracy Desktop - Chinese(Traditional, HongKong SAR)
[ 16] zh-TW: Microsoft Hanhan Desktop - Chinese (Taiwan)
```

これはローカルで利用可能な音声の一部ですが、OneCore 未対応の SAPI で取得できる言語と同じです。

結果を引用します。OneCore については引用した記事を参照してください。

* [VBSでOneCoreの音声を使用する](https://qiita.com/7shi/items/7781516d6746e29c03b4)

> ```text
> Microsoft Haruka Desktop - Japanese
> Microsoft Hazel Desktop - English (Great Britain)
> Microsoft David Desktop - English (United States)
> Microsoft Zira Desktop - English (United States)
> Microsoft Helena Desktop - Spanish (Spain)
> Microsoft Sabina Desktop - Spanish (Mexico)
> Microsoft Hortense Desktop - French
> Microsoft Elsa Desktop - Italian (Italy)
> Microsoft Hedda Desktop - German
> Microsoft Heami Desktop - Korean
> Microsoft Paulina Desktop - Polish
> Microsoft Maria Desktop - Portuguese(Brazil)
> Microsoft Irina Desktop - Russian
> Microsoft Huihui Desktop - Chinese (Simplified)
> Microsoft Tracy Desktop - Chinese(Traditional, HongKong SAR)
> Microsoft Hanhan Desktop - Chinese (Taiwan)
> ```

引用した記事でも触れているように、OneCore については Bugzilla で議論はされています。

> * [1544143 - [narrate] Support onecore / mobile voices on Windows 10](https://bugzilla.mozilla.org/show_bug.cgi?id=1544143)

【追記】バージョン 106 から OneCore 対応

# Chrome

調査に使用したバージョンは 81.0.4044.138 です。

```text
[  1] ja-JP: Microsoft Haruka Desktop - Japanese
[  2] en-GB: Microsoft Hazel Desktop - English (Great Britain)
[  3] en-US: Microsoft David Desktop - English (United States)
[  4] en-US: Microsoft Zira Desktop - English (United States)
[  5] es-ES: Microsoft Helena Desktop - Spanish (Spain)
[  6] es-MX: Microsoft Sabina Desktop - Spanish (Mexico)
[  7] fr-FR: Microsoft Hortense Desktop - French
[  8] it-IT: Microsoft Elsa Desktop - Italian (Italy)
[  9] de-DE: Microsoft Hedda Desktop - German
[ 10] ko-KR: Microsoft Heami Desktop - Korean
[ 11] pl-PL: Microsoft Paulina Desktop - Polish
[ 12] pt-BR: Microsoft Maria Desktop - Portuguese(Brazil)
[ 13] ru-RU: Microsoft Irina Desktop - Russian
[ 14] zh-CN: Microsoft Huihui Desktop - Chinese (Simplified)
[ 15] zh-HK: Microsoft Tracy Desktop - Chinese(Traditional, HongKong SAR)
[ 16] zh-TW: Microsoft Hanhan Desktop - Chinese (Taiwan)
[ 17] de-DE: Google Deutsch
[ 18] en-US: Google US English
[ 19] en-GB: Google UK English Female
[ 20] en-GB: Google UK English Male
[ 21] es-ES: Google español
[ 22] es-US: Google español de Estados Unidos
[ 23] fr-FR: Google français
[ 24] hi-IN: Google हिन्दी
[ 25] id-ID: Google Bahasa Indonesia
[ 26] it-IT: Google italiano
[ 27] ja-JP: Google 日本語
[ 28] ko-KR: Google 한국의
[ 29] nl-NL: Google Nederlands
[ 30] pl-PL: Google polski
[ 31] pt-BR: Google português do Brasil
[ 32] ru-RU: Google русский
[ 33] zh-CN: Google 普通话（中国大陆）
[ 34] zh-HK: Google 粤語（香港）
[ 35] zh-TW: Google 國語（臺灣）
```

ローカル音声は Firefox と同じ16音声です。それに加えて Google のオンライン音声が19音声あります。ローカルに入っていなくても外国語の読み上げが利用できるという点では便利です。

なお、同一言語ではオンライン音声の方が音質がクリアです。

【追記】バージョン 91 から OneCore 対応

# Edge

:::note info
一度でも音声読み上げ機能を使用したことがあると、対応言語数が増えます。（Web サイトの背景を右クリックして「音声で読み上げる」）
:::

調査に使用したのは Chromium 版の新 Edge で、バージョンは 81.0.416.72 です。

```text
[  1] ja-JP: Microsoft Ayumi - Japanese (Japan)
[  2] ar-SA: Microsoft Naayf - Arabic (Saudi)
[  3] bg-BG: Microsoft Ivan - Bulgarian (Bulgaria)
[  4] ca-ES: Microsoft Herena - Catalan (Catalan)
[  5] cs-CZ: Microsoft Jakub - Czech (Czech Republic)
[  6] da-DK: Microsoft Helle - Danish (Denmark)
[  7] de-AT: Microsoft Michael - German (Austria)
[  8] de-CH: Microsoft Karsten - German (Switzerland)
[  9] de-DE: Microsoft Hedda - German (Germany)
[ 10] de-DE: Microsoft Katja - German (Germany)
[ 11] de-DE: Microsoft Stefan - German (Germany)
[ 12] el-GR: Microsoft Stefanos - Greek (Greece)
[ 13] en-AU: Microsoft Catherine - English (Australia)
[ 14] en-AU: Microsoft James - English (Australia)
[ 15] en-CA: Microsoft Linda - English (Canada)
[ 16] en-CA: Microsoft Richard - English (Canada)
[ 17] en-GB: Microsoft George - English (United Kingdom)
[ 18] en-GB: Microsoft Hazel - English (United Kingdom)
[ 19] en-GB: Microsoft Susan - English (United Kingdom)
[ 20] en-IE: Microsoft Sean - English (Ireland)
[ 21] en-IN: Microsoft Heera - English (India)
[ 22] en-IN: Microsoft Ravi - English (India)
[ 23] en-US: Microsoft David - English (United States)
[ 24] en-US: Microsoft Mark - English (United States)
[ 25] en-US: Microsoft Zira - English (United States)
[ 26] es-ES: Microsoft Helena - Spanish (Spain)
[ 27] es-ES: Microsoft Laura - Spanish (Spain)
[ 28] es-ES: Microsoft Pablo - Spanish (Spain)
[ 29] es-MX: Microsoft Raul - Spanish (Mexico)
[ 30] es-MX: Microsoft Sabina - Spanish (Mexico)
[ 31] fi-FI: Microsoft Heidi - Finnish (Finland)
[ 32] fr-CA: Microsoft Caroline - French (Canada)
[ 33] fr-CA: Microsoft Claude - French (Canada)
[ 34] fr-CA: Microsoft Nathalie - French (Canada)
[ 35] fr-CH: Microsoft Guillaume - French (Switzerland)
[ 36] fr-FR: Microsoft Hortense - French (France)
[ 37] fr-FR: Microsoft Julie - French (France)
[ 38] fr-FR: Microsoft Paul - French (France)
[ 39] he-IL: Microsoft Asaf - Hebrew (Israel)
[ 40] hi-IN: Microsoft Hemant - Hindi (India)
[ 41] hi-IN: Microsoft Kalpana - Hindi (India)
[ 42] hr-HR: Microsoft Matej - Croatian (Croatia)
[ 43] hu-HU: Microsoft Szabolcs - Hungarian (Hungary)
[ 44] id-ID: Microsoft Andika - Indonesian (Indonesia)
[ 45] it-IT: Microsoft Cosimo - Italian (Italy)
[ 46] it-IT: Microsoft Elsa - Italian (Italy)
[ 47] ar-EG: Microsoft Hoda - Arabic (Egypt)
[ 48] ja-JP: Microsoft Haruka - Japanese (Japan)
[ 49] ja-JP: Microsoft Ichiro - Japanese (Japan)
[ 50] ja-JP: Microsoft Sayaka - Japanese (Japan)
[ 51] ko-KR: Microsoft Heami - Korean (Korean)
[ 52] ms-MY: Microsoft Rizwan - Malay (Malaysia)
[ 53] nb-NO: Microsoft Jon - Norwegian (Bokmål)
[ 54] nl-BE: Microsoft Bart - Dutch (Belgium)
[ 55] nl-NL: Microsoft Frank - Dutch (Netherlands)
[ 56] pl-PL: Microsoft Adam - Polish (Poland)
[ 57] pl-PL: Microsoft Paulina - Polish (Poland)
[ 58] pt-BR: Microsoft Daniel - Portuguese (Brazil)
[ 59] pt-BR: Microsoft Maria - Portuguese (Brazil)
[ 60] pt-PT: Microsoft Helia - Portuguese (Portugal)
[ 61] ro-RO: Microsoft Andrei - Romanian (Romania)
[ 62] ru-RU: Microsoft Irina - Russian (Russia)
[ 63] ru-RU: Microsoft Pavel - Russian (Russia)
[ 64] sk-SK: Microsoft Filip - Slovak (Slovakia)
[ 65] sl-SI: Microsoft Lado - Slovenian (Slovenia)
[ 66] sv-SE: Microsoft Bengt - Swedish
[ 67] ta-IN: Microsoft Valluvar - Tamil (India)
[ 68] th-TH: Microsoft Pattara - Thai (Thailand)
[ 69] tr-TR: Microsoft Tolga - Turkish (Turkey)
[ 70] vi-VN: Microsoft An - Vietnamese (Vietnam)
[ 71] zh-CN: Microsoft Huihui - Chinese (Simplified, PRC)
[ 72] zh-CN: Microsoft Kangkang - Chinese (Simplified, PRC)
[ 73] zh-CN: Microsoft Yaoyao - Chinese (Simplified, PRC)
[ 74] zh-HK: Microsoft Danny - Chinese (Traditional, Hong Kong S.A.R.)
[ 75] zh-HK: Microsoft Tracy - Chinese (Traditional, Hong Kong S.A.R.)
[ 76] zh-TW: Microsoft Hanhan - Chinese (Traditional, Taiwan)
[ 77] zh-TW: Microsoft Yating - Chinese (Traditional, Taiwan)
[ 78] zh-TW: Microsoft Zhiwei - Chinese (Traditional, Taiwan)
[ 79] en-US: Microsoft Aria Online (Natural) - English (United States)
[ 80] en-US: Microsoft Guy Online (Natural) - English (United States)
[ 81] zh-CN: Microsoft Xiaoxiao Online (Natural) - Chinese (Mainland)
[ 82] zh-CN: Microsoft Yunyang Online (Natural) - Chinese (Mainland)
[ 83] zh-TW: Microsoft HanHan Online - Chinese (Taiwan)
[ 84] zh-HK: Microsoft Tracy Online - Chinese (Hong Kong)
[ 85] ja-JP: Microsoft Nanami Online (Natural) - Japanese (Japan)
[ 86] en-GB: Microsoft Libby Online (Natural) - English (United Kingdom)
[ 87] pt-BR: Microsoft Francisca Online (Natural) - Portuguese (Brazil)
[ 88] es-MX: Microsoft Dalia Online (Natural)- Spanish (Mexico)
[ 89] en-IN: Microsoft Priya Online - English (India)
[ 90] en-CA: Microsoft Heather Online - English (Canada)
[ 91] fr-CA: Microsoft Sylvie Online (Natural) - French (Canada)
[ 92] fr-FR: Microsoft Hortense Online - French (France)
[ 93] de-DE: Microsoft Katja Online (Natural) - German (Germany)
[ 94] ru-RU: Microsoft Ekaterina Online - Russian (Russia)
[ 95] en-AU: Microsoft Hayley Online - English (Australia)
[ 96] it-IT: Microsoft Elsa Online (Natural) - Italian (Italy)
[ 97] ko-KR: Microsoft SunHi Online (Natural) - Korean (Korea)
[ 98] nl-NL: Microsoft Hanna Online - Dutch (Netherlands)
[ 99] es-ES: Microsoft Helena Online - Spanish (Spain)
[100] tr-TR: Microsoft Seda Online - Turkish (Turkey)
[101] pl-PL: Microsoft Paulina Online - Polish (Poland)
```

ローカルにインストールされた78音声がすべて利用可能です。それに加えて Microsoft のオンライン音声が23音声あります。

オンライン音声は Chromium とは別のサービスなので共通していないのは当然だとしても、ローカル音声を利用する部分（SAPI）も別実装になっているようです。さすがに Microsoft は自社 OS で使える機能はきっちり実装しています。

やはり同一言語ではオンライン音声の方が音質がクリアです。特に Natural と称している音声はなかなか良いです。

# ローカル音声

ローカル音声の一覧表は以下の記事を参照してください。

* [SSMLの言語・地域コードとSAPI音声の対応](https://qiita.com/7shi/items/ff9cf324f18234cabd82)

# オンライン音声

Google と Microsoft のオンライン音声を比較します。数字は音声数です。同一言語で2音声あるものは男声と女声です。

コード|言語|地域|Google|Microsoft
----|----|----|---:|---:
de-DE|ドイツ語|ドイツ|1|1
en-AU|英語|オーストラリア||1
en-CA|英語|カナダ||1
en-GB|英語|イギリス|2|1
en-IN|英語|インド||1
en-US|英語|アメリカ|1|2
es-ES|スペイン語|スペイン|1|1
es-MX|スペイン語|メキシコ||1
es-US|スペイン語|アメリカ|1|
fr-CA|フランス語|カナダ||1
fr-FR|フランス語|フランス|1|1
hi-IN|ヒンディー語|インド|1|
id-ID|インドネシア語|インドネシア|1|
it-IT|イタリア語|イタリア|1|1
ja-JP|日本語|日本|1|1
ko-KR|韓国語|韓国|1|1
nl-NL|オランダ語|オランダ|1|1
pl-PL|ポーランド語|ポーランド|1|1
pt-BR|ポルトガル語|ブラジル|1|1
ru-RU|ロシア語|ロシア|1|1
tr-TR|トルコ語|トルコ||1
zh-CN|中国語|大陸|1|2
zh-HK|広東語|香港|1|1
zh-TW|中国語|台湾|1|1

Google は言語数、Microsoft は地域ごとの変種に力を入れているようです。

言語のみに注目して地域を無視すれば、Google のみで利用可能なのはヒンディー語とインドネシア語、Microsoft のみで利用可能なのはトルコ語です。

※ ヒンディー語やインドネシア語はローカルにインストールすれば Edge でも利用可能ですが、音質はオンラインの方が良いようです。

# 関連情報

現状、Google のオンライン音声では読み上げ位置の取得ができません。

* [Web Speech API で読み上げ位置を取得](https://qiita.com/7shi/items/43452dcd34e57100fc3c)

また、ブラウザやローカルやオンラインの別に関わらず SSML は使えない状況です。

* [Web Speech APIでSSMLのテスト](https://qiita.com/7shi/items/98c032737e7adcf7fd76)
