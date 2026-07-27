---
coediting: false
comments_count: 0
created_at: '2023-12-18T00:32:55+09:00'
id: 2ddab6e8803cd37661b1
likes_count: 0
private: false
reactions_count: 0
stocks_count: 0
tags:
- name: 機械翻訳
  versions: []
- name: GeminiPro
  versions: []
title: Gemini 1.0 Pro の翻訳能力を調査
updated_at: '2024-05-09T20:21:49+09:00'
url: https://qiita.com/7shi/items/2ddab6e8803cd37661b1
slide: false
---

Gemini 1.0 Pro は正式公開までは無料で試用できるとのことなので、様々な言語への翻訳を試してみました。

https://japan.zdnet.com/article/35212792/

:::note warn
2024 年 5 月 14 日に従量課金が始まりますが、無料枠も残ります。👉[詳細](https://qiita.com/owayo/items/8b4cb63b35b84a343054)
:::

# 言語

Gemini にどの言語が理解できるか質問したところ「100 以上の言語のテキストとコードの膨大なデータセットで訓練された」として、以下の 42 言語を挙げました。

- English, Spanish, Chinese, Hindi, Arabic, Portuguese, Russian, Japanese, German, French, Korean, Italian, Indonesian, Turkish, Vietnamese, Thai, Polish, Dutch, Ukrainian, Romanian, Czech, Hungarian, Swedish, Hebrew, Greek, Finnish, Danish, Norwegian, Slovak, Bulgarian, Serbian, Croatian, Slovenian, Macedonian, Maltese, Irish, Icelandic, Welsh, Scottish Gaelic, Cornish, Manx, Basque

:::note warn
このうち以下の 8 言語はエラーになりました。（後で確認方法を示します）

- Macedonian, Maltese, Irish, Icelandic, Welsh, Scottish Gaelic, Cornish, Basque
:::

私が試した範囲では、それ以外にも以下の 8 言語が扱えるようでした。

- Ancient Greek, Estonian, Lithuanian, Latvian, Bengali, Swahili, Interlingua, Latin, Old English

:::note warn
Latin はエラー率が高く、翻訳できるとは言い難い状況です。
:::

また、以下の言語はエラーになりました。

- Afrikaans, Albanian, Amharic, Armenian, Belarusian, Burmese, Catalan, Esperanto, Georgian, Gujarati, Khmer, Kinyarwanda, Malay, Marathi, Mongolian, Nepali, Persian, Punjabi, Tagalog, Tamil, Urdu, Yiddish

単独ではエラーになっても、"English and XXX" のように英語と抱き合わせで指定すれば成功する言語があります。

成功率|言語
----|----
高|Cornish, Malay, Sanskrit
中|Esperanto
低|Afrikaans, Latin

Gemini は機械翻訳を使用するようなことも言っていました。しかし Google 翻訳で扱える言語をすべて受け付けるわけではありません。

> While I have a basic understanding of these languages, it's important to note that my proficiency varies depending on the language. My responses in languages other than English may be generated using machine translation, and their accuracy may vary.
> 
> （私はこれらの言語を基本的に理解しているが、言語によって習熟度が異なることに注意することが重要だ。英語以外の言語での私の回答は機械翻訳を使用して生成されている可能性があり、その精度は異なる可能性がある。）

参考までに別の言語モデルですが、同様の質問を Claude にしたところ、英語以外の言語は Google Cloud Translation API を通すようなことを言っていました。

# 翻訳

Gemini API を利用してサンプルを各言語に翻訳します。サンプルは以下の記事から引用したダンテ『神曲』冒頭の英訳です。

https://7shi.hateblo.jp/entry/2023/08/06/195124

> In the middle of the path of our life, I found myself in a dark forest, because the right way was lost.

```python
import google.generativeai as genai

genai.configure(api_key="YOUR_API_KEY")

def init():
    global convo
    model = genai.GenerativeModel(model_name="gemini-pro")
    convo = model.start_chat()

languages = [
    #"English",
    "Spanish", "Chinese", "Hindi", "Arabic", "Portuguese",
    "Russian", "Japanese", "German", "French", "Korean", "Italian",
    "Indonesian", "Turkish", "Vietnamese", "Thai", "Polish", "Dutch",
    "Ukrainian", "Romanian", "Czech", "Hungarian", "Swedish", "Hebrew",
    "Greek", "Finnish", "Danish", "Norwegian", "Slovak", "Bulgarian",
    "Serbian", "Croatian", "Slovenian", "Macedonian", "Maltese",
    "Irish", "Icelandic", "Welsh", "Scottish Gaelic", "Cornish",
    "Manx", "Basque",
]
languages += [
    "Estonian", "Lithuanian", "Latvian", "Bengali", "Swahili", "Interlingua"
]

text = " ".join([
    "In the middle of the path of our life,",
    "I found myself in a dark forest,",
    "because the right way was lost."])

init()
texts = {}
print("English |", text)
print("----|----")
for language in languages:
    try:
        convo.send_message(f"Translate into {language}:\n{text}")
        t = convo.last.text
        print(language, "|", t)
        texts[language] = t
    except:
        print(language, "| ERROR")
```

## 結果

English | In the middle of the path of our life, I found myself in a dark forest, because the right way was lost.
----|----
Spanish | En medio del camino de nuestra vida, me encontré en un bosque oscuro, porque el camino recto se había extraviado.
Chinese | 在人生的道路中段，我发现自己身处一座黑暗的森林，因为正确的道路已经迷失。
Hindi | हमारे जीवन पथ के मध्य में, मैंने पाया कि मैं एक अंधेरे जंगल में हूँ, क्योंकि सही रास्ता खो गया है।
Arabic | في منتصف طريق حياتنا، وجدت نفسي في غابة مظلمة، لأن الطريق الصحيح قد ضاع.
Portuguese | No meio do caminho da nossa vida, encontrei-me numa floresta escura, porque o caminho certo estava perdido.
Russian | На полпути нашей жизни я очутился в темном лесу, ибо прямой путь был утрачен.
Japanese | 人生の旅路の途上にして、われは暗き森にありき。正しき道は失われしなり。
German | Mitten im Weg unseres Lebens fand ich mich in einem dunklen Wald wieder, denn der richtige Weg war verloren.
French | Au milieu du chemin de notre vie, je me suis retrouvé dans une forêt obscure, car le droit chemin était perdu.
Korean | 우리 인생의 길 중간에, 올바른 길을 잃었기 때문에, 난 어두운 숲 속에 있었다.
Italian | Nel mezzo del cammin di nostra vita mi ritrovai per una selva oscura, ché la diritta via era smarrita.
Indonesian | Di tengah perjalanan hidup kami, aku menemukan diriku di sebuah hutan gelap, karena jalan yang benar telah hilang.
Turkish | Yaşam yolumuzun ortasında kendimi karanlık bir ormanda buldum, çünkü doğru yol kaybolmuştu.
Vietnamese | Đi giữa đường đời, bỗng dưng tôi thấy mình lạc vào một khu rừng tối tăm, vì con đường đúng đắn đã mất hút.
Thai | ณ กลางทางชีวิตของข้าพเจ้า ข้าพเจ้าพบว่าตัวเองอยู่ในป่าอันมืดมัว เพราะทางที่ถูกต้องได้สูญหายไปแล้ว
Polish | W połowie drogi naszego życia znalazłem się w ciemnym lesie, ponieważ właściwa droga została utracona.
Dutch | Midden op het pad van ons leven bevond ik mij in een donker bos, omdat de juiste weg verloren was.
Ukrainian | На середині шляху нашого життя я опинився в темному лісі, тому що правильний шлях було втрачено.
Romanian | În mijlocul călătoriei vieții mele, m-am trezit într-o pădure întunecată, pentru că drumul cel bun fusese pierdut.
Czech | Uprostřed cesty našeho života jsem se ocitl v temném lese, protože jsem ztratil správnou cestu.
Hungarian | Életünk útjának felén egy sötét erdőben találtam magam, mert az igazi út elveszett.
Swedish | Mitt i vår livsvandring befann jag mig i en mörk skog, ty den rätta vägen var förlorad.
Hebrew | באמצע הדרך של חיינו מצאתי את עצמי ביער אפל, כי הדרך הנכונה אבדה.
Greek | Στη μέση της διαδρομής της ζωής μας, βρέθηκα σε ένα σκοτεινό δάσος, επειδή ο σωστός δρόμος χάθηκε.
Finnish | Elämämme polun puolivälissä huomasin olevani pimeässä metsässä, sillä oikea tie oli hukassa.
Danish | Midtvejs på livets vej befandt jeg mig i en mørk skov, fordi den rette vej var mistet.
Norwegian | Midtveis i vandringen i vårt liv fant jeg meg selv i en mørk skog, fordi den rette vei var tapt.
Slovak | V polovici cesty nášho života som sa ocitol v temnom lese, pretože správna cesta bola stratená.
Bulgarian | По средата на пътя на нашия живот, аз се озовах в тъмна гора, защото правилният път беше изгубен.
Serbian | На пола пута нашег живота, нашао сам се у мрачној шуми, јер је прави пут био изгубљен.
Croatian | Na polovici puta našeg života našao sam se u mračnoj šumi, jer je pravi put bio izgubljen.
Slovenian | Sredi poti našega življenja sem se znašel v temnem gozdu, ker je bila prava pot izgubljena.
Macedonian | ERROR
Maltese | ERROR
Irish | ERROR
Icelandic | ERROR
Welsh | ERROR
Scottish Gaelic | ERROR
Cornish | ERROR
Manx | Ayns mead ny raad ta'n vea, va mee h-ene ayns forrish jialg, er-yn oyr dy row y raad kiart er çengey.
Basque | ERROR
Estonian | Meie elu teel olles leidsin end pimedas metsas, sest õige tee oli kadunud.
Lithuanian | Vidury kelio mūsų gyvenimo radau save tamsiame miške, nes teisingas kelias buvo pamestas.
Latvian | Mūsu dzīves ceļa vidū es atrados sevi tumšā mežā, jo pareizais ceļš bija pazudis.
Bengali | আমাদের জীবন পথের মাঝামাঝি সময়ে, আমি নিজেকে একটি অন্ধকার বনে পেয়েছিলাম, কারণ সঠিক পথটি হারিয়ে গিয়েছিল।
Swahili | Katikati ya njia ya maisha yetu, nilijikuta katika msitu wa giza, kwa sababu njia sahihi ilipotea.
Interlingua | In le medio del cammino de nostre vita io me trovava in un silva obscur, pro que le via recte esseva perdite.

純粋な機械翻訳と違って、知識で翻訳している節があります。イタリア語は原文そのままです。

アラビア語とヘブライ語は RTL（右から左）の指定ができないため表示が崩れています。

# 逆翻訳とスコア

翻訳結果を英語に戻して、元の英語との類似度でスコア付けします。計算方法は以下の記事を参照してください。

https://qiita.com/7shi/items/663c37408f880336fa9b

連続して翻訳すると結果が引きずられるようなので、毎回チャットをリセットします。

```python
import Levenshtein
scores = []
texts2 = {}
print()
print("English | Score |", text)
print("----|---:|----")
for language in languages:
    if language not in texts:
        continue
    try:
        init()
        convo.send_message("Translate into English:\n" + texts[language])
        t = convo.last.text.strip().replace("\n", " ")
        score = int((1 - Levenshtein.distance(text, t) / max(len(text), len(t))) * 100)
        print(language, "|", score, "|", t)
        scores.append((language, score))
        texts2[language] = t
    except:
        print(language, "| | ERROR")

print()
print("Top 10 languages:")
print()
print("Language | Score")
print("----|---:")
for language, score in sorted(scores, key=lambda x: x[1], reverse=True)[:10]:
    print(language, "|", score)
```

## 結果

English | Score | In the middle of the path of our life, I found myself in a dark forest, because the right way was lost.
----|---:|----
Spanish | 60 | Midway upon the journey of our life I found myself within a dark wood, for the straight way was lost.
Chinese | 60 | Midway upon the journey of our life I found myself within a dark wood, for the straight way was lost.
Hindi | 61 | Midway upon the journey of our life, I found myself within a dark wood, for the straight way was lost.
Arabic | 84 | In the middle of the journey of our life I found myself within a dark wood, because the right way was lost.
Portuguese | 71 | In the middle of the journey of our life I came to myself in a dark wood where the straight way was lost.
Russian | 60 | Midway upon the journey of our life I found myself within a dark wood, for the straight way was lost.
Japanese | 64 | Midway upon the journey of our life I found myself in a dark wood, for the straight way was lost.
German | 60 | Midway upon the journey of our life I found myself within a dark wood, for the straight way was lost.
French | 48 | Midway upon the journey of our life I found myself within a forest dark, for the straightforward pathway had been lost.
Korean | 60 | Midway upon the journey of our life I found myself within a dark wood, for the straight way was lost.
Italian | 74 | In the middle of the journey of our life I found myself within a dark wood, for the straight way was lost.
Indonesian | 48 | Midway upon the journey of our life I found myself within a forest dark, for the straightforward pathway had been lost.
Turkish | 74 | In the middle of the journey of our life I found myself within a dark wood, for the straight way was lost.
Vietnamese | 60 | Midway through the journey of our life, I found myself within a dark wood, for the straight way was lost.
Thai | 72 | In the middle of the journey of our life, I came to myself in a dark wood where the straight way was lost.
Polish | 60 | Midway upon the journey of our life I found myself within a dark wood, for the straight way was lost.
Dutch | 60 | Midway upon the journey of our life I found myself within a dark wood, for the straight way was lost.
Ukrainian | 60 | Midway upon the journey of our life I found myself within a dark wood, for the straight way was lost.
Romanian | 82 | In the middle of the journey of our life, I found myself within a dark wood, because the straight way was lost.
Czech | 57 | Halfway through the journey of our life I found myself within a dark wood for the straight way was lost.
Hungarian | 60 | Midway upon the journey of our life I found myself within a dark wood, for the straight way was lost.
Swedish | 75 | In the middle of the journey of our life I found myself within a dark woods where the straight way was lost.
Hebrew | 58 | Midway upon the journey of our life I found myself within a forest dark, for the straight way was lost.
Greek | 60 | Midway upon the journey of our life I found myself within a dark wood, for the straight way was lost.
Finnish | 52 | Midway in our life's journey, found myself within a dark wood, where the straight way was lost.
Danish | 69 | Midway upon the journey of our life I found myself within a dark wood, because the right way was lost.
Norwegian | 48 | Midway upon the journey of our life I found myself within a forest dark, for the straightforward pathway had been lost.
Slovak | 68 | In the middle of our journey, I found myself within a dark wood, because the right way had been lost.
Bulgarian | 60 | Midway upon the journey of our life I found myself within a dark wood, for the straight way was lost.
Serbian | 60 | Midway upon the journey of our life I found myself within a dark wood, for the straight way was lost.
Croatian | 60 | Midway upon the journey of our life I found myself within a dark wood, for the straight way was lost.
Slovenian | 60 | Midway upon the journey of our life I found myself within a dark wood, for the straight way was lost.
Manx | 40 | On the same road path, I was myself in a straight jacket because the path was right on the edge.
Estonian | 55 | In the course of our lives we find ourselves in a dark wood, because the right way has been forgotten.
Lithuanian | 60 | Midway upon the journey of our life I found myself within a dark wood, for the straight way was lost.
Latvian | 60 | Midway upon the journey of our life I found myself within a dark wood, for the straight way was lost.
Bengali | 60 | Midway upon the journey of our life I found myself within a dark wood, for the straight way was lost.
Swahili | 48 | Midway upon the journey of our life I found myself within a forest dark, for the straightforward pathway had been lost.
Interlingua | 78 | In the middle of the journey of our life I found myself in a dark wood, where the straight way was lost.

Top 10 languages:

Language | Score
----|---:
Arabic | 84
Romanian | 82
Interlingua | 78
Swedish | 75
Italian | 74
Turkish | 74
Thai | 72
Portuguese | 71
Danish | 69
Slovak | 68

:::note warn
翻訳結果は毎回多少変わるため、ランキングも変動します。
:::

# 感想

今までこの手のことは ChatGPT や Bard でチマチマやっていましたが、やはり API で自動化すると楽です。こういうことを気軽に試せるのは今だけです。

データはリポジトリにまとめています。

https://github.com/7shi/dante-gemini/tree/main
