---
coediting: false
comments_count: 0
created_at: '2024-01-18T18:03:36+09:00'
id: 667e1206469b2a1a4e00
likes_count: 3
private: false
reactions_count: 0
stocks_count: 2
tags:
- name: GeminiPro
  versions: []
title: Gemini 1.0 Pro でのブロックと設定
updated_at: '2024-05-16T18:27:09+09:00'
url: https://qiita.com/7shi/items/667e1206469b2a1a4e00
slide: false
---

Gemini 1.0 Pro のブロック判定はかなり厳しく、悪意がなくても頻繁に引っ掛かるような印象があります。実例と対策について説明します。

:::note warn
2024 年 5 月 14 日に従量課金が始まりますが、無料枠も残ります。👉[詳細](https://qiita.com/owayo/items/8b4cb63b35b84a343054)
:::

# 実例

Gemini 1.0 Pro で文学作品を扱おうとすると頻繁にブロックされます。

例えばロングフェロー訳ダンテ『神曲』地獄篇第 6 歌 27 行目が有害コンテンツとしてブロックされます。（地獄の番犬[ケルベロス](https://ja.wikipedia.org/wiki/%E3%82%B1%E3%83%AB%E3%83%99%E3%83%AD%E3%82%B9)についての描写）

https://en.wikisource.org/wiki/Divine_Comedy_(Longfellow_1867)/Volume_1/Canto_6

> He threw it into those rapacious gullets.

Python で API によって日本語訳を試みます。

```py
import google.generativeai as genai

genai.configure(api_key="YOUR_API_KEY")
model = genai.GenerativeModel(model_name="gemini-pro")

def translate(text):
    response = model.generate_content("Translate into Japanese:\n" + text)
    try:
        print(response.text)
    except:
        print(response.candidates)

translate("He threw it into those rapacious gullets.")
```

実行するたびに結果は異なりますが、ブロックされた場合は `response.text` で例外が発生します。

```text
[index: 0
finish_reason: SAFETY
safety_ratings {
  category: HARM_CATEGORY_SEXUALLY_EXPLICIT
  probability: HIGH
}
safety_ratings {
  category: HARM_CATEGORY_HATE_SPEECH
  probability: NEGLIGIBLE
}
safety_ratings {
  category: HARM_CATEGORY_HARASSMENT
  probability: MEDIUM
}
safety_ratings {
  category: HARM_CATEGORY_DANGEROUS_CONTENT
  probability: NEGLIGIBLE
}
]
```

何度かやっていると翻訳できることもあります。

```text
彼はそれを貪欲な口に投げ入れた。
```

HARM_CATEGORY_SEXUALLY_EXPLICIT に引っ掛かっていますが、特にそういう内容ではありません。恐らく rapacious が誤解されたのではないかと思います。

https://ejje.weblio.jp/content/rapacious

> [意味・対訳] 強欲な、(貪欲(どんよく)で)飽くことを知らぬ、強奪する、略奪する、生き物を捕食する、肉食の

このようなブロックがかなり頻繁に発生します。安全側に倒しているということで仕方ない面もありますが、現実問題として文学作品を扱う上で支障があります。

# 設定

【追記 2024.5.16】現在、Block none を含む 4 段階の設定が可能です。

~~Google AI Studio では 3 段階の設定が可能です。しかし Block few でも先ほどのように HIGH と判定されればブロックされます。Google AI Studio ではサポートされていないようですが、~~

<!--![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/32057/53b9b9ac-be3f-a31c-6793-4d13632987a9.png)-->

API ではブロックしない設定が可能です。

https://cloud.google.com/vertex-ai/docs/generative-ai/multimodal/configure-safety-attributes?hl=ja

> BLOCK_NONE 安全でないコンテンツの可能性に関係なく、常に表示されます。

これを適用すれば、先ほどの例もブロックされなくなります。

```py
safety_settings = [
    {
        "category": "HARM_CATEGORY_HARASSMENT",
        "threshold": "BLOCK_NONE"
    },
    {
        "category": "HARM_CATEGORY_HATE_SPEECH",
        "threshold": "BLOCK_NONE"
    },
    {
        "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
        "threshold": "BLOCK_NONE"
    },
    {
        "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
        "threshold": "BLOCK_NONE"
    }
]
model = genai.GenerativeModel(model_name="gemini-pro", safety_settings=safety_settings)
```

:::note info
リミッターを解除している感があります。ドキュメントに記載されているため、特に裏技ということではないはずです。

私自身はこの設定を知らずに頻繁なブロックで使い物にならないと誤解していました。
:::

ブロックとは別の理由でエラーが発生することがあります。間隔を空けて再試行することで対処できるケースについては以下の記事を参照してください。

https://qiita.com/7shi/items/54e45181052c914a4d45

# Bard

API と違って Bard ではこのような回避ができないため、作業に使っていると理由を示さずに回答を拒否することが割と頻繁に発生します。

今までその理由がよく分からなかったのですが、API の挙動と比較することで、Bard の挙動もある程度は推測できるようになりました。

:::note info
API のエラーでもどの単語が原因かまでは教えてくれませんが、大まかな理由が示されるだけでもかなり違います。
:::

Bard は不特定多数に向けて安全側に倒す必要があるので、このような挙動は仕方ないということは理解できます。ですが能力を調べる上でハンディになります。

例えば以下の記事では共通テストで能力を調査していますが、Bard が回答を拒否することについて言及があります。

https://note.com/lifeprompt/n/n87f4d5510100

> Google Bardは、概ね使用感は他のAIと変わりませんが、特定のワードや文章形式を入力すると「回答できません」という拒否反応を起こすことがありました。

# 関連記事

翻訳できる言語を調べた記事です。

https://qiita.com/7shi/items/2ddab6e8803cd37661b1

Bard でのエラーに経験的に対処しようとした記事です。API の挙動にも一定の共通点があるため、この考え方を応用しています。

https://qiita.com/7shi/items/4c71bb7b3b6f9af7bdc6
