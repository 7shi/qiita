---
coediting: false
comments_count: 0
created_at: '2024-09-30T15:46:48+09:00'
id: 04962cf58e172da662c1
likes_count: 13
private: false
reactions_count: 0
stocks_count: 10
tags:
- name: ffmpeg
  versions: []
- name: Gemini
  versions: []
- name: NotebookLM
  versions: []
title: NotebookLM で生成した会話に字幕と背景を付けて動画化する
updated_at: '2024-11-02T14:42:11+09:00'
url: https://qiita.com/7shi/items/04962cf58e172da662c1
slide: false
---

[NotebookLM](https://notebooklm.google.com/) は資料を読み込ませて要約などが行える Web ツールです。内容に関するポッドキャスト風の会話を生成することもできますが、記事執筆時点では英語のみの対応となっています。

本記事では、英語の文字起こしと日本語訳の字幕を付けて動画化する手順をまとめます。Google AI Studio と FFmpeg を利用します。

これにより、資料の理解だけでなく、英語の勉強も兼ねることが期待できます。

# 概要

NotebookLM で生成した会話の音声はダウンロード可能です。これを Gemini 1.5 Flash で文字起こしして、日本語訳や注釈を生成します。内容の理解のためであればここまでで十分ですが、字幕だけでは動画として公開するにはやや寂しいため、画像生成 AI を使って背景を生成します。

## サンプル

本記事の手法で作成した動画の例です。

<div>
<a href="https://www.youtube.com/watch?v=n17NFYBBjXY"><img width="200" src="https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/32057/aa9b147a-4b2f-ee50-5842-3e15e1c23ac8.jpeg"></a>
<a href="https://www.youtube.com/watch?v=cCEigiXIgD8"><img width="200" src="https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/32057/877b3b04-0dbe-e1ab-513e-78a999f35c60.jpeg"></a>
<a href="https://www.youtube.com/watch?v=vWezpoQ9XGs"><img width="200" src="https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/32057/58699993-0e15-fe50-1aa8-2d2a92b64cfa.jpeg"></a>
</div>

# ワークフロー

大まかに次のようなワークフローで進めます。

1. `src.wav`: NotebookLM で会話を生成・ダウンロード
1. `log1.md`: Gemini で翻訳・注釈
1. `log2.md`: Gemini で画像のデザイン
1. `src/`: 生成した画像を入れるディレクトリ
1. `dst1/`: 800×600 にリサイズ
1. `dst2/`: ブラウザで字幕を合成してキャプチャ
1. `dst3/`: 音声に合わせて画像を動画化
1. `dst3-v.mp4`: 動画を結合
1. `dst3-a1.wav`: 音声の量子化パラメーターを調整
1. `dst3-a2.aac`: 音声を結合してエンコード
1. `dst4.mp4`: 動画と音声を結合

以下のリポジトリにまとめたスクリプトを使用します。

https://github.com/7shi/notebooklm2video

適当な場所に作業用ディレクトリを作成して、リポジトリのルートディレクトリから *.py と image.html をコピーしてください。

# プロンプト

[Google AI Studio](https://aistudio.google.com/) で作業を進めます。

想定した形式で出力を得るため、プロンプトには出力例を含めます。

## 文字起こし

:::note info
サンプル: [log1.md](https://github.com/7shi/notebooklm2video/blob/main/sample/log1.md)
:::

NotebookLM からダウンロードした音声ファイルを src.wav にリネームして、作業用ディレクトリに配置します。

Google AI Studio では添付ファイルは Google Drive にアップロードされます。容量を節約するため MP3 に変換すると良いでしょう。

```sh
ffmpeg -i src.wav -vn -ac 1 -ar 44100 -ab 128k -acodec libmp3lame -f mp3 src.mp3
```

Google AI Studio に MP3 ファイルを添付して、文字起こしを指示します。

```text:プロンプト
Please transcribe this conversation, in the table format of timecode, speaker, caption. Use speaker A, speaker B, etc. to identify speakers.

|timecode|speaker|caption|
|---|---|---|
|00:00|A|text|
```

参考: [音声理解（音声のみ）  |  Vertex AI の生成 AI  |  Google Cloud](https://cloud.google.com/vertex-ai/generative-ai/docs/multimodal/audio-understanding?hl=ja)

:::note warn
Gemini 1.5 Flash 002 では文字起こしの時間がずれたりなどの不具合が生じるため、002 ではない方の無印 Gemini 1.5 Flash を推奨します。

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/32057/de8dc4e1-b074-2437-00b9-524c22b0825f.png)
:::

怪しい部分は Whisper の結果と見比べてみるのも良いでしょう。

https://pypi.org/project/openai-whisper/

```sh
pip install git+https://github.com/openai/whisper.git
whisper --model turbo --language en xxx.wav
```

### 翻訳

ハルシネーションを防ぐため、冗長ですが対訳形式を採用します。多過ぎると途中で止まるため、全体を適当に分割します。

```text:プロンプト
xx:xxからyy:yyまで日本語に翻訳してください。英語で難解な表現に語釈を付け、背景説明は不要です。

|時間|話者|英語|日本語訳|注釈|
|---|---|---|---|----|
|00:00|A|text|テキスト|word: 単語。|
```

## 仕切り直し

:::note info
サンプル: [log2.md](https://github.com/7shi/notebooklm2video/blob/main/sample/log2.md)
:::

全文を保持したままではトークン消費が激しいため、続きは新しいチャットで仕切り直します。英語のログを貼って、まずは内容を評価させます。思ったような結果が得られないときは Gemini 1.5 Pro に切り替えると良いでしょう。

```text:プロンプト
これは『〇〇』について話す台本です。
```

### テーマ

```text:プロンプト
話されているテーマを、タイムライン順にリストアップしてください。
```

### 整理

```text:プロンプト
表形式で整理してください。

|No|時間|テーマ|
|---:|----|----|
|1|00:00|(text)|
```

### 統合

分割が細かすぎる場合、調整を指示します。

```text:プロンプト
テーマが多すぎます。2～4個ずつ統合して、30個程度に絞り込んでください。
```

### 画像デザイン

画像を生成するための指示文を生成します。Stable Diffusion XL などを使用する場合は、プロンプト形式を指定すれば良いでしょう。

```text:プロンプト
テーマごとに挿絵を考えてください。挿絵はプロンプト形式ではなく、英語で文章化してください。結果は表形式で出力してください。

|No|Time|Theme|Illustration Description|
|----|----|----|----|
|1|00:00.00|(text)|...|
```

### タイトル画像

指示の例を示します。これは特に決められた形式である必要はないため、具体的なアイデアがあれば、それに基づいて指示を書いてください。

```text:プロンプト
全体の流れを考慮して、タイトル画像の案を5つ考えてください。プロンプト形式や箇条書きではなく、50語程度の英語の文章として指示を書いてください。
```

# ログ変換

ここから先はローカルで作業します。

Google AI Studio のログを変換するためのコードを提供します。変換方法は 2 通りあるため、どちらか一方を選んでください。

**方法 1. ログを Google Drive から取得して変換**

Google AI Studio のログは自動で Google Drive に保存されます。

文字起こし・翻訳と画像デザインの 2 つのログを作業ディレクトリにコピーして、ファイル名を log1.json, log2.json として、Markdown に変換します。

```sh
python json2md.py log1.json log2.json
```

log1.md と log2.md が生成されます。

**方法 2. Get code から `history=[...]` をコピー**

Google Drive をローカルに同期していない場合、こちらの方法が手軽です。

Google AI Studio で右上の Get code から Python のコードを表示して、`history=[...]` の部分を作業ディレクトリの log1.py, log2.py に貼り付けます。それらのファイルの先頭で、変換に必要な関数をインポートして使用します。添付ファイルがある場合はダミーで `files` を定義します。

```python:log1.py
from json2md import print_convert
files = [0]
print_convert(history=[
    （略）
  ]
)
```
:::note info
サンプル: [log1.py](https://github.com/7shi/notebooklm2video/blob/main/sample/log1.py)
:::
```python:log2.py
from json2md import print_convert
print_convert(history=[
    （略）
  ]
)
```
:::note info
サンプル: [log2.py](https://github.com/7shi/notebooklm2video/blob/main/sample/log2.py)
:::
```sh:変換
python log1.py > log1.md
python log2.py > log2.md
```

## データの抽出

変換したログから、ヘッダを取り除いたテーブルのデータを抽出します。

1\. `table0.txt`: 文字起こし

```sh
python extract-table.py log1.md "| timecode | speaker | caption |" > table0.txt
```

2\. `table1.txt`: 翻訳

```sh
python extract-table.py log1.md "| 時間 | 話者 | 英語 | 日本語訳 | 注釈 |" > table1.txt
```

3\. `table2.txt`: 画像デザイン

```sh
python extract-table.py log2.md "| No | Time | Theme | Illustration Description |" > table2.txt
```

:::note info
テーブルヘッダは変化することがあるため、ログに合わせます。
:::

## 過不足確認

翻訳の際に過不足が発生することがあるため、確認します。

```sh
python check-table.py table0.txt table1.txt
diff -u table0_.txt table1_.txt
```

差分が発生すれば、手動で調整します。

## タイトルを追加

table1.txt を手動で編集して、最初の行にタイトルの項目を追加します。

```text:最初の行に追加
| 00:00 | | Author<br>Title | 作者<br>タイトル | Conversation: NotebookLM<br>Director: Gemini 1.5 Flash<br>Image: Stable Diffusion 3 |
```

:::note info
タイトル行を追記することで、table1.txt の行番号と dst2/ や dst3/ の連番とが一致します。この関係により、データ行とファイルとの対応が付きます。
:::

:::note warn
2024/10/01 19:00 追記
仕様を変更して、時間の取得を自動化することにより、当初必要だった最終行の追記を不要としました。それ以前にスクリプトを取得した場合は更新してください。
:::

# 画像生成

デザインされた画像を生成します（指示は table2.txt に抽出）。生成する手段は問いません。ローカルで高速に生成できない場合、オンラインサービスが利用できます。個人的に使っているサービスを紹介します。

* [リートン](https://wrtn.jp/): Stable Diffusion 3
* [Poe](https://poe.com/): Playground v3

生成した画像は src ディレクトリに保存します。タイトル画像を 001.png として、それ以降の画像は連番で保存します。連番を付けるのが面倒な場合、保存順にリネームするスクリプトを用意しています。

```python
python rename.py src
```

タイトル画像を後で挿入する場合、それ以外の画像を 002.png から開始することも可能です。

```python
python rename.py -s 2 src
```

## リサイズ

画像をリサイズします。

```sh:準備
pip install pillow
```

:::note info
本記事では 800×600 を想定していますが、変更できます。あまり大きく変えると字幕のサイズと合わなくなるため、image.html を調整する必要があります。
:::

スクリプトでは、アスペクト比を維持して横幅を 800 にリサイズしてから、縦幅を 600 にトリミングします。出力先のディレクトリは dst1 を指定します。

```python
python resize.py -o dst1 src
```

:::note warn
2024/10/03 12:00 追記
スクリプトを更新して、サイズが指定できるようになりました。

```sh
python resize.py -W 1024 -H 576 -o dst1 src
```
:::

# 作業用ファイルの生成

作業に必要なファイル一式を生成します。

```sh
python generate.py
```

4 つのファイルが生成されます。

- text-en.txt
- text-ja.txt
- table.js
- Makefile

:::note alert
`Not found: 0:57-1:15` のような表示はエラーです。table2.txt で指定された `0:57` という時間から始まる発言が、table1.txt に存在しないことを意味します。Gemini のログ (log2.md) や table1.txt を確認して、table2.txt を修正してください。大抵は数秒のずれです。
:::

:::note info
動画生成の具体的なフローは、生成された Makefile に記述されています。
:::

## 字幕合成

画像に字幕を合成するため image.html をブラウザで開きます。

<img width="320" src="https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/32057/cdf55f3a-b078-dd27-7b9d-5bb4a87db603.jpeg">

文字がはみ出す箇所は、table1.txt を編集して調整します。編集後に generate.py で再生成して、ブラウザはリロードします。

:::note info
話者の欄は生成には影響しないため、間違っていても放置して構いません。
:::

## キャプチャ

字幕の調整が完了すれば、画像をキャプチャします。

```sh:準備
pip install pyautogui
```

image.html をリロードして最初のページを開きます。

capture.py を編集して、座標を調整します。

```py:変更箇所
mx, my = 526, 864           # [▶] ボタンをクリックする座標
rect = (80, 226, 800, 600)  # 画像の領域
```

:::note info
座標の取得には様々な方法があります。一例として、[PrintScreen] キーで画面全体をキャプチャして、画像編集ソフト（GIMP など）で座標を確認する方法があります。
:::

スクリプトを実行すれば、ページを自動的にめくって画像をキャプチャします。

```sh
python capture.py
```

キャプチャした画像は dst2 ディレクトリに保存されます。

:::note warn
Windows で WSL を使用している場合でも、このスクリプトは Windows 側に Python を入れて使用してください。コマンドプロンプトに切り替えなくても、WSL から `python.exe capture.py` とすれば呼び出せます。
:::

## 動画生成

FFmpeg を使用して、画像と音声から動画を生成します。

スクリプトによって生成された Makefile で作業を行います。

```sh
make
```

正常に処理が完了すれば、dst4.mp4 が生成されます。

:::note info
Windows で WSL を使用していない場合、make を使用するには Git for Windows にコマンドを追加するのが手軽でしょう。
:::

https://zenn.dev/rg687076/articles/0961195f13b309

## タイミング調整

文字起こしは秒単位で行われるため、字幕のタイミングがずれることがあります。table1.txt を編集してタイミングを調整します。`02:31.5` のように小数点以下の秒が指定できます。

タイミングの調整後、再生成を行います。

```sh
make clean
python generate.py
make
```
:::note warn
`make clean` は ffmpeg のすべての出力結果を削除するため、すべて作り直しとなり時間が掛かります。一部の微調整で影響範囲が明らかな場合、`make clean` をせずに dst3 内で影響を受けるファイルを手動で削除すれば、部分的な再生成となるため作業時間が短縮できます。
:::

# おわりに

工程がやや多く、完全に自動化できていません。そのため煩雑に見えますが、それほど難しいことはしていないため、数回やってみれば見通しは得られると思います。

Gemini の生成したデータの精度は 95 点くらいのため、どうしても手作業が入ります。そのため API での自動化は行わずに、Google AI Studio で結果を確認しながら作業しました。

画像生成は外部サービスの利用も想定しているため自動化していません。ローカルで生成すれば自動化は可能ですが、複数枚生成した中から最適な画像を選ぶなど、手作業の余地は残るでしょう。

# 関連記事

https://qiita.com/7shi/items/9a4f2220cfde4fbbdce7
