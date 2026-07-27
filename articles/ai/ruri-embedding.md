---
coediting: false
comments_count: 0
created_at: '2024-12-10T02:24:53+09:00'
id: 90c745833c7839e38c03
likes_count: 19
private: false
reactions_count: 0
stocks_count: 7
tags:
- name: Python
  versions: []
- name: SentenceTransformers
  versions: []
- name: ベクトル検索
  versions: []
title: テキスト埋め込みモデル Ruri を使ってみる
updated_at: '2026-06-13T01:27:44+09:00'
url: https://qiita.com/7shi/items/90c745833c7839e38c03
slide: false
---

テキストを意味で検索したり分類したりする際に、**埋め込み** (embedding) という技術が使われます。本記事では、埋め込みとは何かをなるべく簡単に説明して、実際にモデルを使ってみます。

更新履歴:

- 2025/04/24 Ruri v3 に対応
- 2024/12/10 Ruri のプレフィックスに対応

# 埋め込みとは

「埋め込み」という言葉は、「ベクトル空間への埋め込み」という概念に由来します。これは、様々なデータを数値の並び（ベクトル）に変換することを意味します。つまり、ベクトルの世界に「埋め込む」というイメージです。

例えば、平面上の点は $(x, y)$ という2つの数値で表現できますが、これは 2 次元のベクトル空間への埋め込みと考えることができます。同様にテキストや画像などのデータも、より多くの数値を使ってベクトルに変換できます。

# テキストのベクトル化

例えば、「今日は良い天気です」という文章は、$(0.12, -0.34, 0.56, \cdots)$ のようなベクトルに変換されます。

このとき重要なのは、似たような意味を持つ文章は似たようなベクトルになるという性質です。「今日は晴れています」という文章は、「今日は良い天気です」に似たベクトルに変換されます。

天気とは無関係な「今日はゴミの日です」という文章は、「今日は良い天気です」や「今日は晴れています」とはあまり似ていないベクトルに変換されます。

このようにベクトル同士がどれだけ似ているかを計算することで、似ているデータを見つけることができます。これを利用して検索や推薦を行うことが可能です。また、似たベクトルをグループ化することで、データのクラスタリングを行うこともできます。

## ベクトルの方向

ベクトルを矢印として考えれば、サイズが 0 でなければ何らかの方向を指しています。テキストを埋め込む場合、ベクトルの長さではなく方向に意味を持たせます。

つまり、2 本のベクトルが似ているかどうかは、方向がどれだけ近いか、言い換えればベクトル間の角度によって判定できます。ただし、実用的には角度の計算よりも簡単な方法で代用できます。それについて必要となる事項を説明します。

## 内積

2 本のベクトル A, B を考えます。A から B へ垂線を下ろして、交点を A' とします。

![O2eKRzpIJBH1i8QGl8B8.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/32057/78860429-d486-a642-c02b-fec395562079.png)

A を縮めて B と同じ方向に向けたベクトルを A' と考えます。A' と B の長さの積を、A と B の**内積**と呼びます。上例では $2×3=6$ です。

逆に、B から A に垂線を下ろして内積を計算しても、結果は一致します。

$$
\frac32\sqrt2×2\sqrt2=6
$$

つまり、どちらからどちらに垂線を下ろすかに関係なく、方向を揃えて長さの積を計算したものが内積です。

A の長さを $|A|$、A と B の間の角度を $θ$ とすれば、A' の長さは $|A'|=|A|\cosθ$ となります。この計算を使えば、どちらからどちらに垂線を下ろしても同じ結果になることが直感的に分かります。

$$
(|A|\cosθ)|B|=|A|(\cosθ|B|)
$$

内積は成分からも計算できます。A と B の $x$ 成分同士の積と $y$ 成分同士の積を計算して、それらを足します。

$$
A(2,2),B(3,0)\ →\ 2×3+2×0=6
$$

:::note info
内積は成分を使えば簡単に計算できるというのがポイントです。なぜこの計算方法が成り立つかは、以下の記事を参照してください。
:::

https://7shi.hateblo.jp/entry/2018/08/05/011022

## コサイン類似度

テキストを埋め込んだベクトルは、長さではなく方向に意味があります。計算を簡単にするため、長さはすべて 1 になるように**正規化**します。

A と B を長さ 1 のベクトルとすれば、$|A|=|B|=1$ となります。A と B の間の角度を $θ$ とすれば、A と B の内積は $\cosθ$ となります。$\cosθ$ の値の範囲は -1～1 で、方向が一致すれば最大値 $\cos0=1$ となるため、値が大きい（1 に近い）ほど角度 $θ$ が小さいと判断できます。

つまり、2 本のベクトルの方向がどれだけ近いかは、ベクトル間の角度を求めなくても、内積の計算により求めたコサインの値で判断できます。これを**コサイン類似度**と呼びます。

:::note info
既に見たように、内積の計算は、同じインデックスの成分同士の積を計算して、それらを足すだけのため、角度を求めるよりもずっと簡単です。後で見るように、ベクトルを使った検索では大量の類似度を計算する必要があるため、計算が簡単であることは重要です。

なお、計算方法から分かるように、ベクトルの次元（数値の個数）は一致している必要があります。
:::

# テキスト埋め込みモデル

テキストを、方向が意味を持つようなベクトルに変換するように訓練されたモデルを**テキスト埋め込みモデル**と呼びます。

本記事では、日本語対応のテキスト埋め込みモデル Ruri v3 を使用します。

https://zenn.dev/hpp/articles/b5132c64c40d24

## 使い方

実際に Python で使ってみます。uv の利用を前提とします。

適当なディレクトリを作成して、その中で作業します。

```sh
mkdir ruri-test
cd ruri-test
```

uv を初期化して、必要なライブラリをインストールします。

```sh
uv python pin 3.12
uv init
uv add sentence-transformers sentencepiece protobuf
```

:::note warn
以下、REPL での利用を想定してプロンプト `>>>` を付けますが、この部分は入力しないでください。
:::

モデルを読み込みます。

```py:uv run python
>>> from sentence_transformers import SentenceTransformer
>>> model = SentenceTransformer("cl-nagoya/ruri-v3-310m")
```

:::note info
初回利用時に Hugging Face から自動的にダウンロードされますが、次回からはキャッシュが使われます。
:::

テキストをベクトルに変換します。

```py
>>> v = model.encode("変換したい文章")
```

ベクトルの次元を確認します。

```py
>>> len(v)
768
```

自分自身との内積の平方根によって、ベクトルの長さを確認します。

```py
>>> import math
>>> math.sqrt(v.dot(v))
30.185735868160375
```

:::note info
`v.dot(v)` は `v` と `v` の内積です。角度は 0 のため $\cos 0=1$ です。よって内積は $|v|^2$ となり、平方根によって長さが求まります。
:::

変換時に正規化を指定すれば、長さは 1 になります。

```py
>>> v = model.encode("変換したい文章", normalize_embeddings=True)
>>> math.sqrt(v.dot(v))
1.0
```

:::note info
多少の誤差が出る場合もありますが、影響は無視できます。
:::

## 類似度の計算

複数のベクトルを一度に変換します。

```py
>>> texts = ["今日は良い天気です", "今日は晴れています", "今日はゴミの日です"]
>>> vs = model.encode(texts, normalize_embeddings=True)
```

内積（コサイン類似度）を計算します。

```py
>>> vs[0].dot(vs[1])
np.float32(0.97132885)
>>> vs[0].dot(vs[2])
np.float32(0.8622117)
>>> vs[1].dot(vs[2])
np.float32(0.871142)
```

「今日は良い天気です」と「今日は晴れています」が最も類似しており、「今日はゴミの日です」はあまり類似していないと判定されました。

# ベクトル検索

ある程度の長さのテキストを適当な長さで区切ってベクトル化して、指定したベクトルと類似度でランク付けして上位を抽出する操作を**ベクトル検索**と呼びます。必ずしも単語が一致しなくても、意味的に近いテキストを検索することができます。

区切り方は様々なパターンがあり、実用的なベクトル検索システムを構築する上では重要です。本記事では実用性よりも直感的な結果を得ることを優先して、文単位で区切ります。

事前に文単位で改行されたテキストを用意しました。（[spaCy](https://spacy.io/) 使用）

- https://github.com/7shi/bou-thakuranir_haat/blob/main/all/ja-gemini-lines.md

このテキストに対するベクトル検索システムを実装します。

## プレフィックス

Ruri v3 は、さまざまな種類のテキスト入力を区別するために 1+3 のプレフィックス方式を採用しています。

- `""` （空文字列） は、意味をエンコードするために使用されます。（ここまでの実例で使用）
- `"トピック: "` は、分類、クラスタリング、およびトピック情報のエンコードに使用されます。
- `"検索クエリ: "` は、検索タスクのクエリに使用されます。
- `"検索文書: "` は、検索対象の文書に使用されます。

:::note info
今回の実装では `"検索クエリ: "` と `"検索文書: "` を使用します。
:::

このような区別が必要とされる背景は、以下のポストが参考になります。

<blockquote class="twitter-tweet"><p lang="ja" dir="ltr">質問をあらわすベクトルと、その質問の解答になりそうな文書のベクトルは違うよねって思ってたら、さすが <a href="https://twitter.com/kazunori_279?ref_src=twsrc%5Etfw">@kazunori_279</a> さん、その話してる。<br>3日前に出てたPFNのエンベディングモデルもクエリとドキュメントでわけてベクトルとれる。<a href="https://twitter.com/hashtag/BuildwithAI?src=hash&amp;ref_src=twsrc%5Etfw">#BuildwithAI</a><a href="https://t.co/7ZT5g15RgW">https://t.co/7ZT5g15RgW</a></p>&mdash; きしだൠ(K1S) (@kis) <a href="https://twitter.com/kis/status/1913478288028373191?ref_src=twsrc%5Etfw">April 19, 2025</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script> 

ここで言及されているのは以下のイベントにおける佐藤一憲氏のセッションです。

https://gdgkwansai.connpass.com/event/346523/

内容は、以下の記事にまとめられています。応用を知る上でも参考になります。

https://note.com/ralios/n/n21cfe7cf6a7c

> さらに、検索の「目的」（例えば「質問への回答探し」なのか「似た情報探し」なのか）を AI に伝えることで、検索結果の精度がぐっと上がる「Task type embedding（タスク タイプ エンベディング）」の効果も体験し、「なるほど！」と納得しました。AI の検索能力を高めるためには、こうした様々な技術や手順が必要なんだなと感じました。

## 実装

test.py というファイルに実装していきます。

使用するファイルを設定します。

```python
textfile = "all-ja-gemini-lines.md"
tensorfile = "vectors.safetensors"
```

テキスト埋め込みモデルを読み込みます。

```python
from sentence_transformers import SentenceTransformer
model = SentenceTransformer("cl-nagoya/ruri-v3-310m")
```

テキストをベクトル化する関数を定義します。コサイン類似度の計算は PyTorch のライブラリを利用するため、仕様に合わせて 1 要素のリストとして、`convert_to_tensor=True` で PyTorch 形式を指定します。

```python
def embed(text):
    return model.encode([text], normalize_embeddings=True, convert_to_tensor=True)
```

テキストファイルを読み込みます。誤動作の原因となるため（👉[参考](https://x.com/7shi/status/1915297049626734610)）、2 文字以下の行はスキップします。行番号を保持して、後で検索結果の表示に使用します。

```python
with open(textfile, "r", encoding="utf-8") as f:
    lines = [(i, l) for i, line in enumerate(f, 1) if len(l := line.strip()) > 2]
```

テキストファイルの各行をベクトル化します。この処理は時間がかかるため、結果をファイルに保存し、次回からは保存したデータを使用します。

```python
import os, torch, safetensors.torch

if os.path.exists(tensorfile):
    # 保存済みの数値データを読み込み
    tensor = safetensors.torch.load_file(tensorfile)["lines"]
else:
    from tqdm import tqdm

    # 新規にベクトル化して保存
    test = embed("test")[0]  # ベクトルサイズの確認用
    tensor = torch.zeros(len(lines), len(test), dtype=torch.float32)
    for i, (_, line) in tqdm(enumerate(lines), total=len(lines)):
        tensor[i, :] = embed("検索文書: " + line)[0]
    safetensors.torch.save_file({"lines": tensor}, tensorfile)
```

:::note info
`embed("検索文書: " + line)` でプレフィックスを使用しています。
:::

実際の検索を行う関数を実装します。コサイン類似度の計算に PyTorch の関数を使用します。これにより、指定したベクトルと、変換済みのすべてのベクトルとの類似度が一気に計算できます。ベクトル検索では上位 K 件（ここでは 10 件）を取得します。これを TopK 検索と呼びます。

```python
import torch.nn.functional as F

def search(query):
    emb = embed("検索クエリ: " + query)
    # コサイン類似度の計算
    similarities = F.cosine_similarity(tensor, emb, dim=1)
    # TopK 検索（上位 10 件を取得）
    for i, (value, index) in enumerate(zip(*torch.topk(similarities, k=10)), 1):
        value, index = value.item(), index.item()  # 数値に変換
        lnum, line = lines[index]
        yield len(emb[0]), i, value, lnum, line
```

:::note info
`embed("検索クエリ: " + query)` でプレフィックスを使用しています。
:::

対話的なインターフェースを実装します。[Ctrl]+[D] や [Ctrl]+[C] のようなユーザー操作は例外を表示せずに終了します。

```python
while True:
    print()
    try:
        query = input("> ")
    except (EOFError, KeyboardInterrupt):
        print()
        break
    for _, i, v, lnum, line in search(query):
        print(f"{i:2d}: {v:.5f} {lnum:4d} {line}")
```

これで実装は完了です。実行してみます。

```text:実行例
$ uv run test.py
100%|███████████████████████████████████████████████| 4479/4479 [08:30<00:00,  8.77it/s]

> 楽器について
 1: 0.85621 4138 あるにはあるが、弦が切れていて、音が出ないのだ」と言った。
 2: 0.84054  625 指にメジャープを巻き付けて、ベハーグのアラパを弾き始めた。
 3: 0.83668 5484 あちこちで音楽が鳴り響いている。
 4: 0.83545  628 彼は立ち上がって演奏し始めた。
 5: 0.83370  624 そしてすぐにシタールを手に取った。
 6: 0.82409  621 「あなたはシタールを弾くことができますか？」
 7: 0.82347 2566 もうシタールは弾きません。
 8: 0.82329  629 威厳、重厚感、自己意識はすべて忘れ去られ、演奏を続けながらついに歌い始めた。
 9: 0.82256 2559 しかし、ビバの涙を見て、シタールの演奏が妨げられるようになった。
10: 0.81939 1266 ビバはシタールの弦に触れてシタールを止め、再び言った。
```

:::note info
スコアが 1 に近いほど、入力した文章に意味が近いことを示します。この例では直接「楽器」という言葉が使用されていなくても、関係する内容が検索できています。
:::

# モデルの対応言語

テキスト埋め込みモデルは、学習時に使用された言語でしか正しく機能しません。対応言語で書かれた文章であれば、その意味を適切にベクトル化できますが、対応していない言語の文章は、意味を正しく捉えることができません。

モデルが言語に対応しているかどうかは、実際にテキストを入力して調べるのが最も確実です。対応していない言語の場合、以下のような現象が発生します。

- 似た意味の文章でも、類似度が極端に低くなる
- 意味が全く異なる文章なのに、高い類似度を示す
- 文字単位や記号での一致に偏った結果を返す

したがって、使用する言語に対応したモデルを選択することが非常に重要です。

## 実験例

以下に、様々なモデルで実験した例があります。日本語に対応していないモデルがどのような挙動を示すか確認できます。

- https://gist.github.com/7shi/8b91255997ec442a643dc152d71d0ba1

モデル|対応言語
----|----
jinaai/jina-embeddings-v2-base-zh|中国語
intfloat/multilingual-e5-large|日本語を含む多言語
BAAI/bge-m3|日本語を含む多言語
cl-nagoya/ruri-base|日本語
それ以外|英語

- 日本語対応モデルでも結果は一致しておらず、モデル間に性能差がある
- 英語対応モデルではまともに検索できない
- 中国語対応モデルでは一部の漢字が中国語の意味で評価された結果、多少は意味が通じているように見える

:::note info
Ruri 登場以前は、上の実験で使用した multilingual-e5-large や bge-m3 がよく使われていたようです。埋め込みで Ollama を使用する場合、選択肢に bge-m3 があればそれを使うのが無難なようです。（👉[参考](https://x.com/7shi/status/1865823163441152188)）
:::

https://qiita.com/isanakamishiro2/items/e4f67586b4cb5f171ea9

# ベクトルデータベース

本記事では、テキストから変換したベクトルを safetensors ファイルに保存する単純な方法を採用しました。しかし対象となるドキュメントの規模が大きくなると、このような単純な方法では対応しきれなくなります。

大規模なベクトルデータを管理するシステムとしてベクトルデータベース（[Chroma](https://www.trychroma.com/) など）があります。実用的なベクトル検索システムを構築するには、ベクトルデータベースの導入は不可欠です。

# 参考

テキストから埋め込みベクトルへの変換は情報が欠損するため、元のテキストを完全には復元できないようです。

<blockquote class="twitter-tweet"><p lang="ja" dir="ltr">テキストを埋め込み表現に変換する話はよくあるけど、逆に埋め込みからテキストを復元する論文見つけて読んでみた。<br>ニューラルの層は高次元の表現をするけど、非線形層が情報を部分的に破壊して、結果的に情報量は維持or減少する(言われてみれば当然な)から入力情報量の完全保持は不可能なんだと。 <a href="https://t.co/p4ECPleXNh">pic.twitter.com/p4ECPleXNh</a></p>&mdash; goto (@goto_yuta_) <a href="https://twitter.com/goto_yuta_/status/1851480771997155662?ref_src=twsrc%5Etfw">October 30, 2024</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

論文によれば、32 トークンの入力テキストの復元率は 92% のようです。

https://7shi.hateblo.jp/entry/2025/01/05/203512

**大規模言語モデル** (**LLM**: Large Language Model) において、文章をトークンと呼ばれる単位に区切って数値化して扱います（トークンが実際にどのような単位で区切られるかは実装依存）。これは処理が自然言語に基づいていることを意味します。それに対して、埋め込みベクトルを処理対象とした**大規模概念モデル** (**LCM**: Large Concept Model) が提案されています。LCM により、推論が自然言語から切り離されることが期待されます。

https://7shi.hateblo.jp/entry/2025/01/04/232224
