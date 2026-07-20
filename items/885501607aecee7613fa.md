---
coediting: false
comments_count: 0
created_at: '2020-06-23T03:33:15+09:00'
id: 885501607aecee7613fa
likes_count: 13
private: false
reactions_count: 0
stocks_count: 9
tags:
- name: Rust
  versions: []
- name: WinRT
  versions: []
- name: TTS
  versions: []
- name: TextToSpeech
  versions: []
title: Rust/WinRTで音声合成
updated_at: '2020-06-26T16:23:19+09:00'
url: https://qiita.com/7shi/items/885501607aecee7613fa
slide: false
---

Rust/WinRT の存在を知ったので、音声合成を試します。

この記事のコードは以下のリポジトリに掲載しています。

* <https://github.com/7shi/winrt-speech/tree/master/rust>

他の言語での利用については以下の記事を参照してください。

* [WinRTで音声合成](https://qiita.com/7shi/items/dc21a3be8b7c69fbc11b) (C#)
* [VBSでOneCoreの音声を使用する](https://qiita.com/7shi/items/7781516d6746e29c03b4)
* [PythonでWindows 10の音声合成を使用する](https://qiita.com/7shi/items/a5fb03406e0626b4f138)

# Rust/WinRT

Microsoft が GitHub で公開しています。

* [microsoft/winrt-rs: Rust language projection for the Windows Runtime](https://github.com/microsoft/winrt-rs)

こちらの記事で Rust/WinRT の存在を知りました。

* [[Rust/WinRT] 画像文字認識 (OCR)](https://qiita.com/osanshouo/items/bedf56143005a11f5e3a)

紹介記事です。

* [Rust言語で自然にWindows Runtimeが扱える ～Microsoft、「Rust/WinRT」をプレビュー公開 - 窓の杜](https://forest.watch.impress.co.jp/docs/news/1251599.html)
* [MicrosoftをRustの社内採用に近付けるRust/WinRT](https://www.infoq.com/jp/news/2020/06/rust-winrt-microsoft/)

Microsoft が C++ の代替として使えるように Rust を整備しているという印象を受けました。

# Windows の音声合成

Windows 10 でサポートされる音声の一覧です。

* [付録 A: Windows 10 のナレーターでサポートされている言語と音声 - Windows Help](https://support.microsoft.com/ja-jp/help/22805/windows-10-supported-narrator-languages-voices)

日本語以外の言語を使用する場合は追加します。

* [Windows 10で読み上げ言語を追加](https://7shi.hateblo.jp/entry/2020/02/22/185810)

今回はすべての言語を追加した状態でテストします。

# 音声一覧

どこか適当なディレクトリでパッケージを作成します。

```text
cargo new voices --bin
```

以下のファイルが生成されます。

* voices/Cargo.toml
* voices/src/main.rs

Cargo.toml の `[dependencies]` の後に依存パッケージを追記します。

```toml
winrt = "0.7"
```

コードを記述します。

```rust:src/main.rs
winrt::import!(
    dependencies
        os
    types
        windows::media::speech_synthesis::*
);

use windows::media::speech_synthesis::*;

fn main() -> winrt::Result<()> {
    for voice in SpeechSynthesizer::all_voices()? {
        println!("{}: {}", voice.language()?, voice.description()?);
    }
    Ok(())
}
```

`cargo run` でビルドして実行します。

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
nb-NO: Microsoft Jon - Norwegian (Bokmål)
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

以下の2つの音声が取得できませんが、これは C# でも同じなので Rust 特有の問題ではありません。

```text:取得できなかった音声
fr-CA: Microsoft Nathalie - French (Canada)
ja-JP: Microsoft Sayaka - Japanese (Japan)
```

これらは音声の設定にも現れませんが、Chromium 版 Edge では使えます。隠れキャラなのでしょうか。

* [Windowsのブラウザで使える音声の調査](https://qiita.com/7shi/items/7f98e144cb69234c5e0e)

# 音声合成

音声を指定してしゃべらせます。

```rust
winrt::import!(
    dependencies
        os
    types
        windows::media::core::*
        windows::media::playback::*
        windows::media::speech_synthesis::*
);

use windows::media::core::*;
use windows::media::playback::*;
use windows::media::speech_synthesis::*;

fn set_voice(synthesizer: &SpeechSynthesizer, v: &str) -> winrt::Result<()> {
    for voice in SpeechSynthesizer::all_voices()? {
        if voice.display_name()? == v {
            synthesizer.set_voice(voice)?;
            break;
        }
    }
    Ok(())
}

fn main() -> winrt::Result<()> {
    let voice = "Microsoft Ichiro";
    let text  = "こんにちは、世界";
    let synthesizer = SpeechSynthesizer::new()?;
    set_voice(&synthesizer, &voice)?;
    let stream = synthesizer.synthesize_text_to_stream_async(text)?.get()?;
    let player = MediaPlayer::new()?;
    let content_type = stream.content_type()?;
    player.set_source(MediaSource::create_from_stream(stream, content_type)?)?;
    player.play()?;
    loop {
        std::thread::sleep(std::time::Duration::from_millis(200));
        if player.playback_session()?.playback_state()? != MediaPlaybackState::Playing {
            break;
        }
    };
    Ok(())
}
```

※ 再生の終了を待つループがやっつけです。

# 感想

コンパイル時に WinRT の型を Rust で使えるように投影（変換）するようですが、かなり時間が掛かります。ソースを修正して再度ビルドするのがかなりストレスです。まだプレビュー版とのことなので、今後の開発に期待したいです。

F# では WinRT がうまく使えませんが、先に Rust で使えるようになったのは意外でした。WinRT は COM ベースのため .NET に限定されないことを実感しました。

* [F#でリフレクションを駆使してWinRTを扱う](https://qiita.com/7shi/items/01899f69f010a029242f)

※ 開発中の C#/WinRT によって F# も改善する見込みです。

Go ではもっと直接 COM を触るようです。従来の COM との違いにも言及されていて興味深いです。

* [GoからWindows Runtime APIを使用する方法](https://qiita.com/tobi-c/items/019b78dcf71e519733ce)

> Excel等のCOMオブジェクトには`IDispatch`が実装してあるため、メソッド名を文字列で渡すことで呼び出すことができます。これはgo-oleでもサポートされており便利な機能なのですが、WinRTにはこの`IDispatch`が実装されていません。メタデータを使用するのがWinRTの方針のようです。

`IDispatch` が実装されていないため、残念ながら以下の記事の手法でインターフェース名を取得することはできませんでした。

* [C#で実行時に得たCOMオブジェクトのインタフェース名を取得する](https://qiita.com/kob58im/items/4e6e773aebbf3ea4594d)
