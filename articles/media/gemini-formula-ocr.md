---
coediting: false
comments_count: 0
created_at: '2025-01-03T05:46:29+09:00'
id: d7c4e772f4780c6b99a6
likes_count: 11
private: false
reactions_count: 0
stocks_count: 13
tags:
- name: Python
  versions: []
- name: OCR
  versions: []
- name: Poppler
  versions: []
- name: Gemini
  versions: []
title: Gemini で数式対応 OCR
updated_at: '2025-03-05T13:47:46+09:00'
url: https://qiita.com/7shi/items/d7c4e772f4780c6b99a6
slide: false
---

PDF を画像に変換して、Gemini でテキストを抽出する方法について解説します。数式部分は TeX 形式で出力します。

# サンプル

アインシュタインの 1905 年の論文から一部を抜粋して変換した例を示します。

- Einstein, A. (1905), Ist die Trägheit eines Körpers von seinem Energieinhalt abhängig?. Ann. Phys., 323: 639-641. ([PDF](https://myweb.rz.uni-augsburg.de/~eckern/adp/history/einstein-papers/1905_18_639-641.pdf))

![1905_18_639-641](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/32057/a8fbc3fe-51bd-44c0-d6c9-7f7ba3078b50.png)

```text:OCR 出力
da $C$ sich während der Lichtaussendung nicht ändert. Wir
erhalten also:
$K_0 - K_1 = L \left\{ \frac{1}{\sqrt{1 - (\frac{v}{V})^2}} - 1 \right\}.$

Die kinetische Energie des Körpers in bezug auf ($\xi$, $\eta$, $\zeta$) nimmt
infolge der Lichtaussendung ab, und zwar um einen von den
Qualitäten des Körpers unabhängigen Betrag. Die Differenz
$K_0 - K_1$ hängt ferner von der Geschwindigkeit ebenso ab wie
die kinetische Energie des Elektrons (l. c. § 10).
Unter Vernachlässigung von Größen vierter und höherer
Ordnung können wir setzen:
$K_0 - K_1 = \frac{L}{V^2} \frac{v^2}{2}.$
```

> da $C$ sich während der Lichtaussendung nicht ändert. Wir erhalten also:
> 
> ```math
> K_0 - K_1 = L \left\{ \frac{1}{\sqrt{1 - (\frac{v}{V})^2}} - 1 \right\}.
> ```
> 
> Die kinetische Energie des Körpers in bezug auf ($\xi$, $\eta$, $\zeta$) nimmt infolge der Lichtaussendung ab, und zwar um einen von den Qualitäten des Körpers unabhängigen Betrag. Die Differenz $K_0 - K_1$ hängt ferner von der Geschwindigkeit ebenso ab wie die kinetische Energie des Elektrons (l. c. § 10).
> 
> Unter Vernachlässigung von Größen vierter und höherer Ordnung können wir setzen:
> 
> ```math
> K_0 - K_1 = \frac{L}{V^2} \frac{v^2}{2}.
> ```

:::note info
この論文は有名な $E=mc^2$ につながります。
:::

https://ja.wikipedia.org/wiki/%E8%B3%AA%E9%87%8F%E3%81%A8%E3%82%A8%E3%83%8D%E3%83%AB%E3%82%AE%E3%83%BC%E3%81%AE%E7%AD%89%E4%BE%A1%E6%80%A7

# Poppler

Poppler は、PDF ファイルを扱うためのオープンソースライブラリです。PDF の表示、変換、解析などの機能を提供しています。

Poppler には PDF から画像に変換する `pdftoppm` コマンドが付属していますが、本記事ではファイル名のフォーマット指定やガンマ補正を行うためスクリプトで実装します。

## 準備

使用している OS のパッケージなどで Poppler をインストールしてください。

その後、Python から Poppler の機能を利用するための pdf2image ライブラリをインストールします。uv での例を示します。

```bash
uv python pin 3.10
uv init
uv add pdf2image
```

## 変換スクリプト

PDF の各ページを PNG 画像に変換するスクリプトです。

```python:pdf2png.py
import argparse

parser = argparse.ArgumentParser(description='Convert PDF to images')
parser.add_argument('input_pdf', help='Input PDF file')
parser.add_argument('--output-dir', default=None, help='Output directory')
parser.add_argument('--gamma', type=float, default=None, help='Gamma correction value')
args = parser.parse_args()

import os, pdf2image
from tqdm import tqdm
from PIL import Image, ImageEnhance

# PDFを画像に変換
pages = pdf2image.convert_from_path(args.input_pdf)

# 出力ディレクトリの指定がない場合は入力 PDF の拡張子を除いた名前
output_dir = args.output_dir or os.path.splitext(args.input_pdf)[0]

# 出力ディレクトリが存在しない場合は作成
if not os.path.exists(output_dir):
    os.makedirs(output_dir)

# 各ページを処理
for i, page in enumerate(tqdm(pages, desc="Converting pages"), 1):
    img = page.convert("RGB")

    # ガンマ補正
    if args.gamma:
        enhancer = ImageEnhance.Contrast(img)
        img = enhancer.enhance(args.gamma)

    # 保存
    output_path = os.path.join(output_dir, f"{i:03d}.png")
    img.save(output_path, "PNG")
```

## 使用方法

PDF ファイルを指定すれば、拡張子を除いた名前のディレクトリを作成して、ページごとに連番で PNG ファイルを生成します。

```bash
uv run pdf2png.py input.pdf
```

出力ディレクトリは `--output-dir` オプションで指定できます。スキャンした画像が薄い場合、ガンマ補正を行うことができます。

```bash
uv run pdf2png.py input.pdf --output-dir pages --gamma 1.5
```

# OCR

生成された PNG 画像からテキストを抽出するために Gemini API を使用します。必要なライブラリをインストールします。

```bash
uv add google-generativeai
```

[Google AI Studio](https://aistudio.google.com/) に登録して、API キーを取得してください。それを環境変数 `GEMINI_API_KEY` にセットしてください。

1 ページ 1 リクエストです。Gemini には無料枠があるため、1 日につき 1,500 リクエストまで処理できます。超過した場合はエラーになりますが、自動課金はされません。

:::note alert
無料枠での入出力は学習に利用される可能性があります。機密情報は渡さないようにご注意ください。
:::

## スクリプト

指定したディレクトリの PNG ファイルを OCR 処理します。数式を含むテキストの場合、`$` で囲ったTeX 数式で出力します。

```python:ocr.py
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("work_dir", help="Working directory")
parser.add_argument("-o", dest="output", default=None, help="Output filename")
args = parser.parse_args()

import sys, os, base64
import google.generativeai as genai
from google.api_core import retry
from glob import glob
from tqdm import tqdm

prompt = "Please transcribe the text exactly as it is written, without translating it. Please use $TeX$ to write mathematical equations. Please only return the results, and do not include any comments."
output = args.output or (args.work_dir + ".txt")

model = genai.GenerativeModel(
    model_name="models/gemini-2.0-flash",
    generation_config={
        "temperature": 0.5,
        "top_p": 0.95,
        "top_k": 40,
        "max_output_tokens": 8192,
        "response_mime_type": "text/plain",
    }
)

@retry.Retry()
def generate_content(*args, **kwargs):
    return model.generate_content(*args, **kwargs)

texts = []
for png in tqdm(sorted(glob(args.work_dir + "/*.png"))):
    txt = os.path.splitext(png)[0] + ".txt"
    if os.path.exists(txt):
        with open(txt, "r", encoding="utf-8") as f:
            texts.append(f.read())
        continue
    try:
        with open(png, "rb") as f:
            png_data = {
                "mime_type": "image/png",
                "data": base64.standard_b64encode(f.read()).decode("utf-8"),
            }
        response = generate_content([png_data, prompt])
        with open(txt, "w", encoding="utf-8") as f:
            f.write(response.text)
        texts.append(response.text)
    except Exception as e:
        print(e, file=sys.stderr)

text = "\n--------\n\n".join(t.rstrip() + "\n" for t in texts)
with open(output, "w", encoding="utf-8") as f:
    f.write(text)
print("Output:", output)
```

`Retry` デコレーターにより自動再試行を行っています。詳細は以下の記事を参照してください。

https://qiita.com/7shi/items/d889d06ea5800b56ad05

## 使用方法

PNG ファイルがあるディレクトリを指定すれば、ページごとにテキストファイルを生成します。すべてのページの処理が完了すれば、結合してディレクトリ名に `.txt` を付加したテキストファイルに出力します。途中で中断した場合でも、既に処理済みのファイルはスキップするため、効率的に再開できます。

```bash
uv run ocr.py pages
```

オプションで出力ファイル名が指定できます。

```bash
uv run ocr.py pages -o result.txt
```

:::note warn
`google-generativeai==0.8.3` では、終了時に以下の警告が出ます。実害はないので無視してください。

```text
WARNING: All log messages before absl::InitializeLog() is called are written to STDERR
E0000 00:00:1735850262.936540   10965 init.cc:229] grpc_wait_for_shutdown_with_timeout() timed out.
```
:::

# 参考

`model.generate_content` に画像データが渡せることを知りました。

https://qiita.com/n0bisuke/items/89d42b0131fdc1febcc5

リファレンスのサンプルコードにも載っていました。

https://ai.google.dev/gemini-api/docs/document-processing?lang=python&hl=ja

```python
response = model.generate_content([{'mime_type': 'application/pdf', 'data': doc_data}, prompt])
```

このリファレンスは生ビールさんにご教示いただきました。

<blockquote class="twitter-tweet" data-conversation="none"><p lang="ja" dir="ltr">geminiならpdf直接読み込みの方がよかったりしないんでしょうか？中身は画像OCRなのかもしれませんが！<a href="https://t.co/fkqNlr27Lh">https://t.co/fkqNlr27Lh</a></p>&mdash; 生ビール (@wmoto_ai) <a href="https://twitter.com/wmoto_ai/status/1875029858524508496?ref_src=twsrc%5Etfw">January 3, 2025</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script> 

# 関連記事

TeX から作成された PDF ファイルは OCR を行わなくても文字が抽出できます。その応用として、論文を翻訳するツールを紹介します。

https://qiita.com/7shi/items/9e48ba211092ad690d70
