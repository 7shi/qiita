---
coediting: false
comments_count: 0
created_at: '2024-08-15T04:03:04+09:00'
id: ae0da373184b82d53fcc
likes_count: 14
private: false
reactions_count: 0
stocks_count: 5
tags:
- name: Python
  versions: []
- name: 翻訳
  versions: []
- name: ollama
  versions: []
- name: modelfile
  versions: []
title: Ollama で llama-translate-gguf を動かす
updated_at: '2025-04-28T13:43:20+09:00'
url: https://qiita.com/7shi/items/ae0da373184b82d53fcc
slide: false
---

Ollama で、翻訳に特化したモデルの Modelfile を書いて動かします。

https://huggingface.co/dahara1/llama-translate-gguf

:::note warn
【追記 2025/3/11】

現在の Ollama には Hugging Face から直接 GGUF をインポートする機能があります。そのため基本的には Modelfile を記述する必要はありません。

この記事で取り上げたモデルは以下のようにインポートできます。

```sh
ollama run hf.co/dahara1/llama-translate-gguf
```

ただしこのモデルは特殊なチューニングが施されている関係上、自動でインポートしても挙動に問題が生じます（適切にシステムプロンプトを設定したスクリプトからでないと利用が困難）。このような場合、依然として Modelfile を書く意義があります。
:::

# 追記

この記事のモデルを Ollama のユーザーページにアップロードしました。

https://ollama.com/7shi/llama-translate

コマンド一発でダウンロードして実行できます。

```text
ollama run 7shi/llama-translate:8b-q4_K_M
```

## アップロード

Ollama の公式サイトにユーザー登録すれば、モデルを `ollama push` でアップロードして配布できます。詳細は以下の記事を参照してください。

https://note.com/lucas_san/n/n2418af00ee5c

# Modelfile

llama-translate の README に記載されている client script example には、システムプロンプトが以下のように定義されています。

```py:抜粋
    system =  """<|start_header_id|>system<|end_header_id|>\nYou are a highly skilled professional translator. You are a native speaker of English, Japanese, French and Mandarin. Translate the given text accurately, taking into account the context and specific instructions provided. Steps may include hints enclosed in square brackets [] with the key and value separated by a colon:. If no additional instructions or context are provided, use your expertise to consider what the most appropriate context is and provide a natural translation that aligns with that context. When translating, strive to faithfully reflect the meaning and tone of the original text, pay attention to cultural nuances and differences in language usage, and ensure that the translation is grammatically correct and easy to read. For technical terms and proper nouns, either leave them in the original language or use appropriate translations as necessary. Take a deep breath, calm down, and start translating.<|eot_id|><|start_header_id|>user<|end_header_id|>"""
```

[Ollama のドキュメント](https://github.com/ollama/ollama/blob/main/docs/modelfile.md)に載っている llama3 の Modelfile にシステムプロンプトを組み込みます。

```text:Modelfile
FROM llama-translate.f16.Q4_K_M.gguf

SYSTEM "You are a highly skilled professional translator. You are a native speaker of English, Japanese, French and Mandarin. Translate the given text accurately, taking into account the context and specific instructions provided. Steps may include hints enclosed in square brackets [] with the key and value separated by a colon:. If no additional instructions or context are provided, use your expertise to consider what the most appropriate context is and provide a natural translation that aligns with that context. When translating, strive to faithfully reflect the meaning and tone of the original text, pay attention to cultural nuances and differences in language usage, and ensure that the translation is grammatically correct and easy to read. For technical terms and proper nouns, either leave them in the original language or use appropriate translations as necessary. Take a deep breath, calm down, and start translating."

TEMPLATE """{{ if .System }}<|start_header_id|>system<|end_header_id|>

{{ .System }}<|eot_id|>{{ end }}{{ if .Prompt }}<|start_header_id|>user<|end_header_id|>

{{ .Prompt }}<|eot_id|>{{ end }}<|start_header_id|>assistant<|end_header_id|>

{{ .Response }}<|eot_id|>"""

PARAMETER stop "<|start_header_id|>"
PARAMETER stop "<|end_header_id|>"
PARAMETER stop "<|eot_id|>"
PARAMETER stop "<|reserved_special_token"
```

:::note info
`FROM` の部分はダウンロードした GGUF ファイルに合わせて書き換えてください。
:::

Modelfile と同じフォルダに GGUF ファイルを置いて、Ollama に登録します。

```text
ollama create llama-translate:8b-q4_K_M -f Modelfile
```

:::note info
モデル名は `llama-translate` だけでも構いませんが、Ollama の慣習に寄せました。
:::

:::note warn
Modelfile に `FROM` だけを書いて登録すると、出力が止まらずに延々と文章を生成し続ける状態になりました。システムプロンプトや終了条件は必須のようです。
:::

# 動作確認

時間を計測するため verbose モードをセットします。

```text
$ ollama run llama-translate:8b-q4_K_M
>>> /set parameter seed 15484511
Set parameter 'seed' to '15484511'
>>> /set verbose
Set 'verbose' mode.
>>> Translate English to Japanese: Heaven helps those who help themselves.
天は自助の人を助ける。

total duration:       1m22.1424251s
load duration:        66.9487ms
prompt eval count:    190 token(s)
prompt eval duration: 1m14.131719s
prompt eval rate:     2.56 tokens/s
eval count:           10 token(s)
eval duration:        7.934152s
eval rate:            1.26 tokens/s
```

:::note info
実行結果は毎回変わります。

2012 年製の第 3 世代 Core i5-3320M (2.60GHz) で計測しました。GPU で処理できない古いマシンです。
:::

プロンプトと一緒にやや長いシステムプロンプトも送信されるため、出力開始まで待たされます。（`prompt eval count` と `prompt eval duration` を参照）

システムプロンプトはキャッシュされるらしく、2 回目からは時間が短縮されます。会話履歴が送信されると評価時間が増大するため、`/clear` で消去します。

```text
>>> /clear
Cleared session context
>>> Translate English to Japanese: Rome wasn’t built in a day.
ローマは一日にして成らず。

total duration:       13.4142367s
load duration:        41.9458ms
prompt eval count:    191 token(s)
prompt eval duration: 5.488419s
prompt eval rate:     34.80 tokens/s
eval count:           10 token(s)
eval duration:        7.88071s
eval rate:            1.27 tokens/s
```

:::note info
`prompt eval count` はほぼ同じですが、`prompt eval duration` が大幅に短縮されています。
:::

# サンプルの移植

Ollama 公式の Python ライブラリを使用します。

https://github.com/ollama/ollama-python

llama-translate の README に記載されている client script example には、プロンプトが以下のように定義されています。

```py:抜粋
    prompt = f"""{system}
### Instruction:
{instruction}

### Input:
{input_text}

### Response:
<|eot_id|><|start_header_id|>assistant<|end_header_id|>
"""
```

システムプロンプトやタグの部分は Modelfile に書いたため、その部分は省略して `prompt` を生成します。

```py
import ollama

model = "llama-translate:8b-q4_K_M"

def translation(instruction, input_text):
    prompt = f"""### Instruction:
{instruction}

### Input:
{input_text}

### Response:
"""
    messages = [{ "role": "user", "content": prompt }]

    try:
        # Send the POST request and capture the response
        response = ollama.chat(model=model, messages=messages)
        # print(response)
    except ollama.ResponseError as e:
        # if the request was failed
        print("Error:", e.error)
        return None

    # Extract the 'content' field from the response
    response_content = response["message"]["content"].strip()

    return response_content


if __name__ == "__main__":
    translated_line = translation(f"Translate Japanese to English.", "アメリカ代表が怒涛の逆転劇で五輪5連覇に王手…セルビア下し開催国フランス代表との決勝へ")
    print(translated_line)

    translated_line = translation(f"Translate Japanese to Mandarin.", "石川佳純さんの『中国語インタビュー』に視聴者驚き…卓球女子の中国選手から笑顔引き出し、最後はハイタッチ「めちゃ仲良し」【パリオリンピック】")
    print(translated_line)

    translated_line = translation(f"Translate Japanese to French.", "開催国フランス すでに史上最多のメダル数に パリオリンピック")
    print(translated_line)

    translated_line = translation(f"Translate English to Japanese.", "U.S. Women's Volleyball Will Try For Back-to-Back Golds After Defeating Rival Brazil in Five-Set Thriller")
    print(translated_line)

    translated_line = translation(f"Translate Mandarin to Japanese.", "2024巴黎奥运中国队一日三金！举重双卫冕，花游历史首金，女曲再创辉煌")
    print(translated_line)

    translated_line = translation(f"Translate French to Japanese.", "Handball aux JO 2024 : Laura Glauser et Hatadou Sako, l’assurance tous risques de l’équipe de France")
    print(translated_line)
```
```text:実行結果
The United States women's national soccer team is on the brink of a fifth straight Olympic gold medal after an amazing comeback win against Serbia. They'll face off in the final against France, which is hosting the Olympics.
观众惊叹石川佳纯的《中国语访谈》：从羽毛球女运动员中获得笑容，最后是握手：“超级亲密”【巴黎奥运会】
Poursuite de la France en tant que pays hôte : plus de médailles pour les Jeux olympiques d'été de Paris
米国女子バレーボールチームは、５セットのスリルにまみれた試合でライバルのブラジルを破り、連続して金メダルを狙う
2024年パリ五輪の中国代表は1日3金。重量挙げでダブル・ディフェンス、水泳で新記録を樹立して初の金メダル獲得、フィギュアスケートの女王が輝いた
ハンドボール：フランス代表のラウラ・グローザーとハタドゥ・サコ、万全の状態で2024年パリオリンピックへ
```

:::note info
実行結果は毎回変わります。

Core i5-3320M (2.60GHz) では約 6 分 30 秒掛かりました。
:::

# 翻訳結果の変化

翻訳結果が変わると注意しましたが、どのくらい変わるか確認します。再現性を確保するため、シード値も表示します。

```py
import random, ollama

random.seed(12345)
model = "llama-translate:8b-q4_K_M"
prompt = "Translate English to Japanese: Heaven helps those who help themselves."
messages = [{ "role": "user", "content": prompt }]

for i in range(20):
    seed = random.randint(0, 2**30)
    r = ollama.chat(model=model, messages=messages, options={ "seed": seed })
    c = r["message"]["content"].strip()
    print(f"[{seed}] {c}")
```
```text:実行結果
[894684355] 天の助けは、自分で手伝う者にあたる。
[21838114] 自分に協力する者は、天の助けを受ける。
[641324193] 天命は自助努力者を支援する。
[791158067] 神様は自ら助ける者を助けます。
[415884586] 訳語：天は自ら助けることをしようとする者を援助する。
[580346373] 天に助けを求める者は、まず自身の力を頼りにするものだ。
[936793384] ヘブンは、自分自身を助けようとする者に助ける。
[347221957] 天は、自らを助け合っている者に助ける。
[801148508] 天の助けは、自らを助ける人々に与えられる。
[266861098] 天命は自分自身を助ける人々に尽きる。
[929723557] 天は自助するものを助ける。
[560686510] 英語を日本語に翻訳する：天は手助けしてくれるが、自分で手助けをするものだ。
[374399940] 天に助けを求めよ、己に助けを求めよ。
[401169362] ヘブンは自助をしてくれる人を助ける
[762144912] 天命は自助するものに付き添う。
[196052585] 自分に力をつける者は、神が助けてくれる。
[885019663] 天は自らの助けをする人を助ける。
[357712575] 翻訳英語日本語：天は自ら助け合う者を助ける。
[318141474] 「天は自ら助けられる人を助ける」
[441767840] 天は手が貸すものである。
```

:::note warn
誤訳も含めて、かなりのバリエーションがあります。精度を上げるには、何度か試して一番良い翻訳を採用することが必要になりそうです。
:::

# 参考

https://qiita.com/kiyotaman/items/2effed548e7be32da546
