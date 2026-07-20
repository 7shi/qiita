---
coediting: false
comments_count: 0
created_at: '2020-05-14T05:34:15+09:00'
id: 9a4f2220cfde4fbbdce7
likes_count: 7
private: false
reactions_count: 0
stocks_count: 4
tags:
- name: ImageMagick
  versions: []
- name: ffmpeg
  versions: []
- name: TTS
  versions: []
- name: TextToSpeech
  versions: []
title: 紙芝居方式で動画を作成
updated_at: '2024-10-03T12:46:37+09:00'
url: https://qiita.com/7shi/items/9a4f2220cfde4fbbdce7
slide: false
---

ffmpeg で複数枚の画像とセットにした音声から動画を作成します。

# 概要

個々の画像と対になる音声から個々の AVI ファイルを作成します。

* test-00.png + test-00.wav → test-00.avi
* test-01.png + test-01.wav → test-01.avi
* （略）
* test-99.png + test-99.wav → test-99.avi

※ 画像や音声は他のファイル形式でも構いません。

AVI ファイルを結合して MP4 ファイルを作成します。

* test-00.avi + test-01.avi +（略）+ test-99.avi → test.mp4

※ AVI ファイルを経由しているのはファイルサイズを抑えるためです。ファイルサイズよりも画質を優先する場合、個々の動画も MP4 で作成して結合することが可能です。詳しくは以下の記事を参照してください。

* [ffmpegでMP4を作成する際に時間がずれる](https://qiita.com/7shi/items/17d818195259e4a73db6)

テキストから画像と音声を生成して動画化する例も紹介します。ImageMagick などを使用します。

* test.txt → test-\*.png + test-\*.wav → test-\*.avi → test.mp4

# 作成方法

あまり凝ったオプションは付けずに、最低限のものだけを示します。

個々の画像と対になる音声から個々の AVI ファイルを作成します。

```sh:avi.sh
for png in test-*.png; do
    avi=`echo $png | sed s/png$/avi/`
    wav=`echo $png | sed s/png$/wav/`
    ffmpeg -loop 1 -i $png -i $wav -vcodec mpeg4 -acodec pcm_s16le -shortest $avi
done
```

結合するファイルのリストを作成します。

```sh
for avi in test-*.avi; do echo file $avi; done > test.lst
```

AVI ファイルを結合して MP4 ファイルを作成します。

```sh
ffmpeg -f concat -i test.lst -vcodec libx264 -acodec aac -pix_fmt yuv420p test.mp4
```

一連の流れをシェルスクリプトなどにまとめておけば良いでしょう。

# 音声合成

個々の音声は音声合成で生成することができます。

次の記事で作成した SAPI をラップしたコマンド wintts を使用して例を示します。

* [PythonでWindows 10の音声合成を使用する](https://qiita.com/7shi/items/a5fb03406e0626b4f138)

画像の説明をテキストファイルで書いておき、それを音声に変換します。

* test-00.txt → test-00.wav
* test-01.txt → test-01.wav
* （略）
* test-99.txt → test-99.wav

```sh:wav.sh
for txt in test-*.txt; do
    wav=`echo $txt | sed s/txt$/wav/`
    wintts -v Sayaka -o $wav -i $txt
done
```

※ ここでは日本語を想定しています。`Sayaka` は日本語音声です。

システムに言語を追加すれば、他の言語を読み上げることも可能です。シェルスクリプトを工夫して音声を切り替えれば、複数の人物を登場させたり、英語と日本語を混ぜるようなことも可能です。

なお、Mac では say コマンドを使えば同じ事ができるようです。英語の音声が豊富なようです。

* [Macのsayコマンドの使い方](https://qiita.com/zakuroishikuro/items/0c17acb21f119647c205)

# 字幕

テキストから画像を生成することができます。ImageMagick を使用して例を示します。

* test-00.txt → test-00.png
* test-01.txt → test-01.png
* （略）
* test-99.txt → test-99.png

```sh:png.sh
for txt in test-*.txt; do
    png=`echo $txt | sed s/txt$/png/`
    convert -size 640x480 -font aquafont.ttf caption:"`cat $txt`" $png
done
```

【参考】[ImageMagickで文字画像作成](https://qiita.com/arc279/items/46dcdfc9712f902eca39)

# 字幕付き動画

字幕と音声合成を組み合わせれば、テキストファイルから簡単に字幕付き動画が作成できます。

改行ごとに区切って生成する例を示します。`|` は表示の都合で挿入する改行です。

* cat.txt → cat-\*.png + cat-\*.wav → cat-\*.avi → cat.mp4

```text:cat.txt
吾輩は猫である。
名前はまだ無い。
どこで生れたか|とんと見当がつかぬ。
何でも薄暗いじめじめした所で|ニャーニャー泣いていた事だけは|記憶している。
吾輩はここで始めて|人間というものを見た。
```

【出典】[吾輩は猫である - 青空文庫](https://www.aozora.gr.jp/cards/000148/card789.html)

```sh:txt2mp4.sh
target=cat.txt
prefix=`echo $target | sed 's/\.[^.]*$//'`
num=0
lines=()
while read line; do lines+=($line); done < $target
rm -f $prefix.lst
for line in ${lines[@]}; do
    name=`printf "%s-%02d" "$prefix" $num`
    echo "$name: $line"
    caption="`echo $line | sed 's/|/\n/g'`"
    convert -size 640x480 -font aquafont.ttf -gravity center caption:"$caption" $name.png
    wintts -v Sayaka -o $name.wav "`echo $line | sed 's/|//g'`"
    ffmpeg -loop 1 -i $name.png -i $name.wav -vcodec mpeg4 -acodec pcm_s16le -shortest $name.avi
    echo file $name.avi >> $prefix.lst
    num=$((num + 1))
done
ffmpeg -f concat -i $prefix.lst -vcodec libx264 -acodec aac -pix_fmt yuv420p $prefix.mp4
```

※ テキストの内容を配列に読み込んでいるのは、ffmpeg を挟むとパイプが文字化けするためです。WSL の問題なのか、詳細は不明です。

作成した動画です。

<blockquote class="twitter-tweet" data-conversation="none"><p lang="ja" dir="ltr">ImageMagickによる文字の画像化と組み合わせて、テキストファイルから字幕付き動画を作成する方法を追記しました。<br>例として、青空文庫から『吾輩は猫である』の冒頭を引用して動画を作成しました。 <a href="https://t.co/ajhhljuGjL">pic.twitter.com/ajhhljuGjL</a></p>&mdash; 七誌 (@7shi) <a href="https://twitter.com/7shi/status/1260893801402339328?ref_src=twsrc%5Etfw">May 14, 2020</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script> 

↑ `The media could not be played.` となって再生できない場合、ツイートをクリックして Twitter を開いてください。

# 商用サービス

SAPI の音声は Windows があれば利用できるのですが、正直、それほど品質が高くありません。品質に満足できない場合は、Amazon Polly のような商用サービスを利用する方法もあります。

* [【ミニレビュー】入力したテキストを音声に変換するAWS「Amazon Polly」を無料で試す-Impress Watch](https://www.watch.impress.co.jp/docs/review/minireview/1243596.html)

> Amazon Pollyの初回利用から12カ月間は、500万字/月まで無料。500万字なら、音声の長さで100時間超は使える計算となるので、試しに使ってみるには十分です。

# 関連記事

今回の記事では ImageMagick を使用しました。もっと凝ったことをする場合、HTML でデザインして画像化する方法があります。以下の記事では連続で画像化して専用サーバー経由でファイルにする方法を紹介しています。

https://qiita.com/7shi/items/9d27e1a4911626e1fb8b

既に存在する音声に対して、AI で字幕や背景を付ける方法です。

https://qiita.com/7shi/items/04962cf58e172da662c1
