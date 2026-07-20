---
coediting: false
comments_count: 2
created_at: '2020-05-13T03:19:52+09:00'
id: 17d818195259e4a73db6
likes_count: 11
private: false
reactions_count: 0
stocks_count: 6
tags:
- name: ffmpeg
  versions: []
- name: mp4
  versions: []
title: FFmpegでMP4を作成する際に時間がずれる
updated_at: '2020-09-24T14:54:28+09:00'
url: https://qiita.com/7shi/items/17d818195259e4a73db6
slide: false
---

FFmpeg で画像と音声から MP4 動画を作成する際に時間がずれるのに悩まされました。一旦、別の形式にしてから MP4 に変換することで回避しました。

【追記】個々の音声ファイルの時間を計測して指定する方法を追記しました。再圧縮が回避できます。

この記事の方法を応用して、複数の画像から動画を作成する方法は以下の記事を参照してください。

* [紙芝居方式で動画を作成](https://qiita.com/7shi/items/9a4f2220cfde4fbbdce7)

# バージョン

WSL 上の Arch Linux と Ubuntu で同じ現象を確認しました。

```text:Arch
$ ffmpeg -version
ffmpeg version n4.2.2 Copyright (c) 2000-2019 the FFmpeg developers
built with gcc 9.3.0 (Arch Linux 9.3.0-1)
configuration: --prefix=/usr --disable-debug --disable-static --disable-stripping --enable-fontconfig --enable-gmp --enable-gpl --enable-ladspa --enable-libaom --enable-libass --enable-libbluray --enable-libdav1d --enable-libdrm --enable-libfreetype --enable-libfribidi --enable-libgsm --enable-libiec61883 --enable-libjack --enable-libmfx --enable-libmodplug --enable-libmp3lame --enable-libopencore_amrnb --enable-libopencore_amrwb --enable-libopenjpeg --enable-libopus --enable-libpulse --enable-libsoxr --enable-libspeex --enable-libssh --enable-libtheora --enable-libv4l2 --enable-libvidstab --enable-libvorbis --enable-libvpx --enable-libwebp --enable-libx264 --enable-libx265 --enable-libxcb --enable-libxml2 --enable-libxvid --enable-nvdec --enable-nvenc --enable-omx --enable-openssl --enable-shared --enable-version3 --enable-libfdk_aac --enable-nonfree
libavutil      56. 31.100 / 56. 31.100
libavcodec     58. 54.100 / 58. 54.100
libavformat    58. 29.100 / 58. 29.100
libavdevice    58.  8.100 / 58.  8.100
libavfilter     7. 57.100 /  7. 57.100
libswscale      5.  5.100 /  5.  5.100
libswresample   3.  5.100 /  3.  5.100
libpostproc    55.  5.100 / 55.  5.100
```
```text:Ubuntu
$ ffmpeg -version
ffmpeg version N-97127-g5a0575e Copyright (c) 2000-2020 the FFmpeg developers
built with gcc 5.4.0 (Ubuntu 5.4.0-6ubuntu1~16.04.12) 20160609
configuration: --prefix=/home/n7shi/ffmpeg_build --pkg-config-flags=--static --extra-cflags=-I/home/n7shi/ffmpeg_build/include --extra-ldflags=-L/home/n7shi/ffmpeg_build/lib --extra-libs='-lpthread -lm' --bindir=/home/n7shi/bin --enable-gpl --enable-libaom --enable-libass --enable-libfdk-aac --enable-libfreetype --enable-libmp3lame --enable-libopus --enable-libvorbis --enable-libvpx --enable-libx264 --enable-libx265 --enable-nonfree
libavutil      56. 42.102 / 56. 42.102
libavcodec     58. 77.101 / 58. 77.101
libavformat    58. 42.100 / 58. 42.100
libavdevice    58.  9.103 / 58.  9.103
libavfilter     7. 77.101 /  7. 77.101
libswscale      5.  6.101 /  5.  6.101
libswresample   3.  6.100 /  3.  6.100
libpostproc    55.  6.100 / 55.  6.100
```

Arch は AUR の FFmpeg を yay でビルドしました。Ubuntu の FFmpeg は libfdk_aac を有効にするため自前でビルドしました。詳細は以下を参照してください。

* [なるべく小さい音声ファイルを作る](https://qiita.com/7shi/items/407ad24a5d9ad89be2e5)

# 動画の作成

ダミーの画像（PNG）と音声（MP3）を生成します。

```text:PNG生成
$ convert -size 128x128 xc:white basic1.png
```
【参考】 [ImageMagickで画像を作成する | ぺんラボブログ](http://blog.penlabo.net/another/imagemagick/introduction)

```text:MP3生成
$ ffmpeg -ar 48000 -t 00:00:01 -f s16le -acodec pcm_s16le -ac 2 -i /dev/zero -acodec libmp3lame -aq 4 silent.mp3
```
【参考】 [1秒の無音の音楽ファイル作成・1秒の動画を1枚の静止画から作成](https://qiita.com/m_hsp/items/713058a7a0d6912d5660)

これらを合成して動画（MP4）を作成します。

```text:MP4作成
$ ffmpeg -loop 1 -r 30000/1001 -i basic1.png -i silent.mp3 \
> -vcodec libx264 -acodec aac -strict experimental -ab 320k -ac 2 -ar 48000 \
> -pix_fmt yuv420p -shortest output.mp4
```
【参考】 [FFmpegで音声ファイルと画像1枚から動画を作成してみた | Developers.IO](https://dev.classmethod.jp/articles/ffmpeg-create-movie-by-audio/)

FFmpeg は大量のメッセージを出力しますが、よく見ると Output の時間がおかしいです。

※ Input の方は誤差程度なので無視します。

```text
（略）
Input #1, mp3, from 'silent.mp3':
（略）
  Duration: 00:00:01.03, start: 0.023021, bitrate: 33 kb/s
（略）       ^^^^^^^^^^^
Output #0, mp4, to 'output.mp4':
（略）
frame=   80 fps=0.0 q=-1.0 Lsize=       5kB time=00:00:02.56 bitrate=  16.5kbits/s speed=31.1x
（略）                                            ^^^^^^^^^^^
```

これを再生すると、ファイルが異常なためプレーヤーによって挙動が変わります。Windows Media Player や Firefox ではタイムカウンターを速く進めることで 1 秒で再生しますが、Chrome では 2 秒半かかります。

※ 1 秒ではあまりに短くて分かりにくいですが、ダミーの音声ファイルを 10 秒くらいにして実験すると確認しやすいです。

# 回避策 1

※ [コメント欄](#comment-7c1ec218c9a4bd82cb33)でご教示いただいた、個々の音声ファイルの時間を計測して指定するという方法に基づきます。

今回のケースでは音声は 1 秒だと分かっているため、時間を指定することで回避できます。

```text
$ ffmpeg -t 00:00:01 -loop 1 -i basic1.png -i silent.mp3 -vcodec libx264 -acodec aac -pix_fmt yuv420p output.mp4
（略）       ^^^^^^^^
Output #0, mp4, to 'output.mp4':
（略）
frame=   25 fps=0.0 q=-1.0 Lsize=       3kB time=00:00:01.00 bitrate=  28.2kbits/s speed=19.6x
（略）                                            ^^^^^^^^^^^
```

ぴったりの時間で動画が作成できました。

## FFprobe

再生時間を指定するにはあらかじめ調べておく必要があります。

FFmpeg 付属のコマンド FFprobe によって調べられます。

```text
$ ffprobe silent.mp3
（略）
  Duration: 00:00:01.03, start: 0.023021, bitrate: 33 kb/s
（略）
```

再生時間だけを取り出します。

```text
$ ffprobe -v error -i silent.mp3 -show_streams | grep duration= | cut -d '=' -f 2
1.032000
```

【参考】[ffprobe の使い方 | ニコラボ](https://nico-lab.net/how_to_use_ffprobe/)

エンコードに利用します。

```text
$ ffmpeg -t `ffprobe -v error -i silent.mp3 -show_streams | grep duration= | cut -d '=' -f 2` \
> -loop 1 -i basic1.png -i silent.mp3 -vcodec libx264 -acodec aac -pix_fmt yuv420p output.mp4
（略）
frame=   26 fps=0.0 q=-1.0 Lsize=       3kB time=00:00:01.00 bitrate=  28.5kbits/s speed=18.3x
（略）                                            ^^^^^^^^^^^
```

うまく作成できました。

# 回避策 2

※ 時間指定の方法を知る前に、自力で見付けた方法です。再圧縮を伴うため画質はやや劣化しますが、ファイルサイズを優先する場合には有用なことがあるため紹介します。

一旦、別の形式に変換します。

```text
$ ffmpeg -loop 1 -i basic1.png -i silent.mp3 -vcodec mpeg4 -acodec pcm_s16le -shortest temp.avi
（略）
Output #0, avi, to 'temp.avi':
（略）
frame=   26 fps=0.0 q=2.0 Lsize=     201kB time=00:00:01.04 bitrate=1580.0kbits/s speed=29.3x
（略）                                           ^^^^^^^^^^^
```

これを MP4 に変換します。

```text
$ ffmpeg -i temp.avi -vcodec libx264 -acodec aac -pix_fmt yuv420p output.mp4
（略）
Output #0, mp4, to 'output.mp4':
（略）
frame=   26 fps=0.0 q=-1.0 Lsize=       4kB time=00:00:01.00 bitrate=  28.7kbits/s speed=  17x
（略）                                            ^^^^^^^^^^^
```

正常なファイルが得られました。AVI から MP4 への変換で動画を再圧縮しているため、画質はやや劣化します。劣化具合はケースバイケースですが、ほとんど気にならない場合もあれば、ブロックノイズが目立つ場合もあります。

※ 再圧縮による劣化を軽減するには最初の変換で `-vcodec mpeg2video` を使用した方が良いかもしれません。MPEG2 を経由した方が再圧縮後の MP4 のサイズがやや大きくなるため、画質はやや良いようです。

# 結合してファイルサイズを比較

複数の動画を結合した場合のファイルサイズを比較します。

次のようなファイルを用意します。

```test-avi.lst
file temp.avi
file temp.avi
```
```test-mp4.lst
file output.mp4
file output.mp4
```

結合して動画を作成します。

```sh
ffmpeg -f concat -i test-avi.lst -vcodec libx264 -acodec aac -pix_fmt yuv420p output1.mp4
ffmpeg -f concat -i test-mp4.lst -vcodec copy -acodec copy output2.mp4
```

※ コーデックを変更しない場合、`copy` を指定すれば再圧縮なしで結合して 1 つの MP4 にまとめることができます。

ファイルサイズは次の通りです。

* output1.mp4: 5,081
* output2.mp4: 5,886

再圧縮した方がやや小さいですが、中身はダミー画像なので大した差はありません。

内容のある画像で試したところ、ほとんど同じだったり差が出たりとまちまちで、必ずしも再圧縮の方が小さくなるとは限りませんでした。

画質を優先する場合、再圧縮は避けるべきです。ファイルサイズを優先する場合、再圧縮によって半分以下になることもあるため、両方の方法を試して小さい方を選ぶと良いでしょう。

再圧縮による画質の劣化は組み合わせの影響が大きいようです。AVI (mpeg4) から MP4 (libx264) への再圧縮は比較的画像の劣化が少ないですが、MP4 (libx264) から MP4 (libx264) への再圧縮では、目で見て分かるレベルのブロックノイズが発生しました。

## 試行錯誤

再圧縮による方法は、試行錯誤でコーデックの組み合わせを探しました。経由する形式は何でも良いわけではありませんでした。

試行錯誤を通して、コーデックやコンテナの扱い方が少し分かりました。

エンコードに使用できるコーデックは次のように調べます。

```text
$ ffmpeg -encoders
（略）
 V..... a64multi             Multicolor charset for Commodore 64 (codec a64_multi)
 V..... a64multi5            Multicolor charset for Commodore 64, extended with 5th color (colram) (codec a64_multi5)
 V..... alias_pix            Alias/Wavefront PIX image
 V..... amv                  AMV Video
 V..... apng                 APNG (Animated Portable Network Graphics) image
（略）
```

FFmpeg は出力ファイルの拡張子からコンテナを選択してくれるようです。コーデックを指定しないと、コンテナに合わせてコーデックを選んでくれるようです。出力の以下の部分を見れば分かります。

```text
Stream mapping:
  Stream #0:0 -> #0:0 (mpeg4 (native) -> h264 (libx264))
  Stream #0:1 -> #0:1 (pcm_s16le (native) -> aac (native))
```

WMV 形式を経由すると、WMV 自体は正常に作成されますが、WMV を MP4 に変換すると音声がおかしくなりました。どうやら 10 年以上前からデコーダーがダメなままのようです。

* [FFmpegのwmaデコードが腐ってる - おともだちティータイム](https://shunirr.hatenablog.jp/entry/2008/08/06/090000)

もう新規に使われることはないでしょうから、修正にも力は入らないのでしょう。
