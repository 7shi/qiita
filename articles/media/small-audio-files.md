---
coediting: false
comments_count: 2
created_at: '2020-04-18T15:48:42+09:00'
id: 407ad24a5d9ad89be2e5
likes_count: 6
private: false
reactions_count: 0
stocks_count: 5
tags:
- name: ffmpeg
  versions: []
- name: aac
  versions: []
title: なるべく小さい音声ファイルを作る
updated_at: '2020-07-26T03:36:22+09:00'
url: https://qiita.com/7shi/items/407ad24a5d9ad89be2e5
slide: false
---

大量の音声ファイルが必要な場合、なるべくファイルサイズを小さくしてエンコードしたいことがあります。FFmpeg で最適なオプションを探りました。

<font color="red">**【注意】**</font>HE-AAC (v1/v2) でエンコードしたファイルを頒布するには特許ライセンス契約が必要です。

* [HE-AAC - Wikipedia](https://ja.wikipedia.org/wiki/HE-AAC)

> v1 はフィリップス、ドルビー、ノキアが特許を持っていて、利用には特許プールとの契約が必要。v2 は v1 に加えて、フィリップス、ドルビーが特許を持っていて、特許プールに加えてドルビーとの特許契約が必要。

# HE-AAC v2

HE-AAC v2 が低ビットレートに強いようです。

* [HE-AAC - Wikipedia](https://ja.wikipedia.org/wiki/HE-AAC)

> HE-AAC v1 にパラメトリックステレオを利用した音質改善を施した物が **MPEG-4 High Efficiency AAC v2 profile (HE-AAC v2)** である。高ビットレートでの音質改善はないが、48kbps 以下の低ビットレートで音質が改善する。

## パラメトリックステレオ

【追記】コメント欄でのご指摘を受けて調べました。

HE-AAC v1 にステレオ特化の圧縮機能を追加したのが HE-AAC v2 ということのようです。

* [MPEG-4 Part 3 - Wikipedia](https://ja.wikipedia.org/wiki/MPEG-4_Part_3)

<blockquote>PS（Parametric Stereo）ツールも組み合わせたものを HE-AAC v2 と呼ぶ <sup>[21]</sup>。</blockquote>
<blockquote>PS は、ステレオ信号について同様の考え方を用いるものである。ステレオ信号の左右チャネルの相関を利用し、左右の両チャネルを足し合わせたモノラル信号とステレオの空間情報をパラメータ化したサイド情報に分けて符号化を行い、復号時はモノラル信号とサイド情報とから両チャネルの信号を復元する。サイド情報は高音質の場合でも 9 kbps 程度で<sup>[22]</sup>、左右チャネルをそのまま符号化するのに比べ圧縮効率が高くなる。</blockquote>
<blockquote>また、Moving Picture Experts Group による HE-AAC と HE-AAC v2 の MUSHRA 法による比較試験では、24 kbps の HE-AAC v2 は同じビットレートの HE-AAC よりはるかに優れており、32 kbps の HE-AAC と同等か優れた評価だった<sup>[21]</sup>。</blockquote>
<blockquote>パラメトリックステレオ符号化ツールはステレオ信号用で、ステレオ信号をモノラル成分と左右チャネルの違いを表す少数のパラメータで表現する。左右チャネルの違いを表すパラメータとして、フィルターで分割した各周波数領域でのチャネル間の強度差、位相差、相互相関を用いる <sup>[22][21]</sup>。</blockquote>

左右の共通部分とそれ以外とを分離することで、圧縮効率を上げているようです。

# FFmpeg

FFmpeg は動画や音声の変換でよく使われるコマンドです。HE-AAC v2 もサポートしています。（後述しますが自分でビルドする必要があります）

* [【ffmpeg】 fdk-aac を ffmpeg に組み込む - ニコニコ動画研究所](https://looooooooop.blog.fc2.com/blog-entry-968.html)

> aac_he_v2 :HE-AACv2 44.1kHzでは28k-64kまで使える 推奨16-24k（24kHz,22.05kHz）

なかなか評判も良いようです。

<blockquote class="twitter-tweet"><p lang="ja" dir="ltr">FDK-AAC HEv2 32kbpsが凄い。もちろん細かい点挙げればキリがないけど、32kにしてはスゴい品質。 -acodec libfdk_aac -profile:a aac_he_v2 -ab 32k</p>&mdash; 音風景の管理人 (@kamedo2) <a href="https://twitter.com/kamedo2/status/403184767488638976?ref_src=twsrc%5Etfw">November 20, 2013</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script> 

## オプション

v2 はステレオ音声用ということで、`-ac 1` を指定するとエラーになります。`-ac 2` とする必要があります。

* [Encode/AAC – FFmpeg](https://trac.ffmpeg.org/wiki/Encode/AAC)

> **Note:** HE-AAC version 2 only handles stereo. If you have mono, or want to down-mix to mono, use HE-AAC version 1. 

※ モノラル音声であれば v1 を使うように、とのことです。

v2 を試してみましたが、16kbps では音声が少し割れてしまうようです。24kbps だとほぼ気にならなくなりました。

これらを考慮したオプションは次の通りです。出力ファイルの拡張子は `.m4a` です。

```text:モノラル（HE-AACv1，24kbps，22050Hz，1ch）
ffmpeg -i 入力ファイル -acodec libfdk_aac -profile:a aac_he -ab 24k -ar 22050 -ac 1 出力ファイル.m4a
```
```text:ステレオ（HE-AACv2，24kbps，22050Hz，2ch）
ffmpeg -i 入力ファイル -acodec libfdk_aac -profile:a aac_he_v2 -ab 24k -ar 22050 -ac 2 出力ファイル.m4a
```

※ オプションは別の書き方があります。`-acodec` = `-c:a`、`-ab` = `-b:a`

## ビルド

FFmpeg で HE-AAC (v1/v2) を使うには libfdk_aac を有効にする必要があります。しかし特許が関係するため、libfdk_aac を有効にしたバイナリを配布することができません。

そのため自分でビルドする必要があります。依存するライブラリが多く、割と面倒です。

* [CompilationGuide – FFmpeg](https://trac.ffmpeg.org/wiki/CompilationGuide)

### Arch Linux

Arch Linux では AUR (Arch User Repository) に libfdk_aac を有効にしたパッケージが収録されています。

* https://aur.archlinux.org/packages/ffmpeg-libfdk_aac/

パッケージと言ってもバイナリは提供されていませんが、yay コマンドを使えば自動で依存関係を解決してビルドしてくれます。

```text
yay -S ffmpeg-libfdk_aac
```

【参考】 [FFmpeg で高音質 AAC 変換できるようにする](https://gae-fan.blogspot.com/2015/10/ffmpeg-aac.html)

※ 参考記事に登場する yaourt は開発が終了したため、代替コマンドとして yay を使います。

* [yaourtがいつの間にか消えていた話 - 拾い物のコンパス](http://poppycompass.hatenablog.jp/entry/2019/01/16/065451)

Windows 10 では WSL で Arch Linux が利用できます。詳細は次の記事を参照してください。

* [WSLでUbuntuと共存させてArch Linuxを使う](https://qiita.com/7shi/items/cfda84909b2ea787afdb)
