---
coediting: false
comments_count: 2
created_at: '2024-12-21T05:07:12+09:00'
id: 9e48ba211092ad690d70
likes_count: 41
private: false
reactions_count: 0
stocks_count: 35
tags:
- name: PDF
  versions: []
- name: 翻訳
  versions: []
- name: ollama
  versions: []
title: PDFMathTranslate と Ollama による PDF のローカル翻訳
updated_at: '2025-05-14T13:52:30+09:00'
url: https://qiita.com/7shi/items/9e48ba211092ad690d70
slide: false
---

PDFMathTranslate は、数式や図表を含む論文 PDF の翻訳において、レイアウトの維持に強みを持つツールとして注目を集めています。本記事ではローカル LLM である Ollama を用いた利用方法に焦点を当てて解説します。

:::note alert
2025 年 2 月 17 日以降、Ollama 利用での複数モデルサポートが削除されました。仕様変更に伴い記事を修正しました。

それ以前から複数モデル設定でご利用の場合、アップデート後にエラーとなりますので、単一モデル指定に切り替えてください。（アップデートしなければ影響は受けません）
:::

更新履歴

- 2025/03/15 推奨モデルを Gemma 3 (4B) に変更、サンプル出力を公開
- 2025/02/28 複数モデルサポート削除に伴い説明を修正

# PDFMathTranslate

https://github.com/Byaidu/PDFMathTranslate

PDFMathTranslateは、学術論文の翻訳における課題を解決するために開発されたツールです。主な特徴は以下のとおりです。

1. **数式・図表の完全保持:** 論文中の数式、グラフ、図表を元のレイアウトのまま保持します。目次や注釈も維持されるため、原文の構造を損なうことなく翻訳が可能
2. **多言語対応:** 複数の言語間の翻訳をサポート
3. **各種 API 対応:** OpenAI, Claude, Gemini, Ollama など、様々な LLM に対応（本記事は Ollama について説明）

例：Transformer が発表された論文より

- [Vaswani, A., Shazeer, N., Parmar, N., Uszkoreit, J., Jones, L., Gomez, A. N., … Polosukhin, I. (2017). Attention is all you need.](http://arxiv.org/abs/1706.03762)

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/32057/517c90f9-578b-04b9-a14a-3cac70b02750.png)

# Ollama との連携

Ollamaは、ローカル環境で LLM を実行するためのツールです。あらかじめインストールしておいてください。

https://ollama.com/

PDFMathTranslate で Ollama を使用することには、以下のメリットがあります。

1. **プライバシーの保護:** 翻訳処理がローカル環境で完結するため、論文の内容が外部に送信されることはありません。
2. **コスト削減:** クラウドベースの翻訳サービスと異なり、API利用料などを気にすることなく、何度でも翻訳を行うことができます。（ただし、電気代を考慮すると割高になる可能性もあります）
3. **オフライン環境での利用:** インターネット接続がない環境でも翻訳が可能です。（事前にモデルがインストールされていることが前提です）

:::note info
ローカル LLM のチャット以外の実用例としても注目に値します。開発者視点では LLM をツールに組み込む上でも参考になります。
:::

# インストール

本記事では Python 環境の管理ツールである uv を使った方法を説明します。

パッケージなどで uv をインストールしてください。Windows の場合は winget が利用できます。

```bat
winget install --id=astral-sh.uv -e
```

PDFMathTranslate の最新版を利用するため、GitHub リポジトリからの直接インストールを推奨します。

```bash
uv tool install --python 3.10 git+https://github.com/Byaidu/PDFMathTranslate.git
```

インストール後にアップデートするときは `-U` を付けます。

```bash
uv tool install -U --python 3.10 git+https://github.com/Byaidu/PDFMathTranslate.git
```

# 実行方法

:::note warn
実行時に様々な警告やエラーが出ることがありますが、プログレスバーが表示されて処理が開始されれば正常に動作しています。
:::

コマンド例を示します。

```bash
uvx --python 3.10 pdf2zh -li en -lo ja -t 1 -s ollama:gemma3:4b PDFファイル
```

翻訳処理完了後、元のファイル名に -mono と -dual を付加した PDF ファイルがカレントディレクトリに生成されます。-mono は翻訳のみ、-dual は原文と翻訳のページを交互に配置した PDF ファイルです。

:::note info
ホームディレクトリの .local/bin に実行可能ファイルがインストールされるため、そこにパスを通して利用する方法もあります。その場合 `uvx --python 3.10` は不要です。
:::

主なオプション：

* `-li`: 翻訳元言語（例：en - 英語）
* `-lo`: 翻訳先言語（例：ja - 日本語）
* `-t 1`: 使用するスレッド数（通常、ローカル LLM の並列実行は困難）
* `-s`: 翻訳エンジンとモデルの指定

:::note info
モデルは環境変数 `OLLAMA_MODEL` でも指定可能です。その場合のオプションは `-s ollama` だけとなります。
:::

:::note info
環境変数を設定することで、別マシンの Ollama にアクセスすることも可能です。詳細は以下の記事を参照してください。
:::

https://qiita.com/7shi/items/65741fa8ab0a553f51be

## モデル指定

:::note alert
以前は複数モデル指定がサポートされていましたが、現在は単一モデルのみが指定できます。
:::

`-s ollama:` に続けてモデルを指定します。推奨するモデルは以下の通りです。

- GPU: `gemma3:4b`
- CPU: `gemma2:2b-instruct-q4_K_M`

使用するモデルは、あらかじめ Ollama に pull しておいてください。

```sh
ollama pull gemma3:4b
ollama pull gemma2:2b-instruct-q4_K_M
```

参考までに、モデル選定に使用したサンプル出力を公開します。

https://drive.google.com/drive/folders/1WvObxhqE3AMh1YZuXj_w6CWy1KO9KOHA?usp=drive_link

:::note info
この中では Gemma 3 (12B) が最良のようです。処理時間や消費メモリは 4B の数倍になるため推奨とはしませんでしたが、ハイエンド GPU を利用していれば試してみるのも良いでしょう。
:::

:::note warn
どのモデルを使用しても翻訳には不完全な点は残ります。原文を読むための参考訳だと割り切った上で、原文と翻訳のページが交互に配置された -dual 出力での利用を推奨します。
:::

# 処理時間

処理時間はハードウェアに大きく依存します。GPU（例：Radeon RX 7600 XT）使用時は、gemma2:2b-instruct-q4_K_M で 1 ページあたり約 5〜10 秒、CPU 処理時はその 5〜20 倍程度かかります。

処理可能なページ数に制限はありませんが（400 ページでの正常動作を確認）、実用的には処理時間との兼ね合いとなります。CPU 処理では 20 ページ程度が実用限界と思われます。

:::note info
GPU と CPU の実行速度については、以下の記事を参照してください。
:::

https://qiita.com/7shi/items/dc037c2d5b0add0da33a

https://7shi.hateblo.jp/entry/2024/12/17/020636

# キャッシュ

翻訳結果はキャッシュされます。仮に翻訳途中で落ちたとしても、続きから再開できます。

キャッシュは溜まる一方のため、定期的に削除することをお勧めします。

```py:場所の確認方法（Python）
>>> import os
>>> print(os.path.join(os.path.expanduser("~"), ".cache", "pdf2zh"))
C:\Users\USERNAME\.cache\pdf2zh
```

実装箇所

- https://github.com/Byaidu/PDFMathTranslate/blob/main/pdf2zh/cache.py

```py
    cache_folder = os.path.join(os.path.expanduser("~"), ".cache", "pdf2zh")
```

# 仕様変更経緯

一定確率で無限ループが発生するため、無限ループを検出したときに別のモデルに切り替える機能を提案して採用されました。

https://github.com/Byaidu/PDFMathTranslate/pull/305

`num_predict` により生成を打ち切る方針に変更されたため、複数モデルサポートは削除されました。

https://github.com/Byaidu/PDFMathTranslate/commit/0d4b7b62bb78fe76e2bb5f12abde5405c866dbfd

本記事では、当初は複数モデルを前提として説明していましたが、仕様変更に伴い説明を修正しました。

# 関連記事

翻訳・要約・OCR の使い分けについて説明しています。

https://note.com/7shi/n/n38eb835d0fe0

スキャンで作成された PDF は翻訳できません。そのような PDF ファイルから OCR で文字を読み取る記事です。

https://qiita.com/7shi/items/d7c4e772f4780c6b99a6

Gemini の無料枠を使って論文を要約するツールです。翻訳とは目的が異なるため、併用すれば便利な場合があります。ローカルで処理しないため GPU は不要です。

https://github.com/7shi/gemini-paper-summarizer

# 参考

翻訳と要約の使い分けについては、以下の記事が参考になります。

https://compass.readable.jp/2024/04/17/post-26/

:::note info
この Readable は本記事と同目的のサービスです。速度的に PDFMathTranslate の利用が難しい場合、Readable は有力な選択肢となります。
:::

arXiv を HTML 化して読めるサイトで、そのままブラウザの翻訳機能を使う方法があります。

<blockquote class="twitter-tweet"><p lang="ja" dir="ltr">ブラウザの翻訳使えるし、もうこれでいいじゃん<a href="https://t.co/Oo8A0teyEc">https://t.co/Oo8A0teyEc</a></p>&mdash; mizchi (@mizchi) <a href="https://twitter.com/mizchi/status/1922197928728216057?ref_src=twsrc%5Etfw">May 13, 2025</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>
