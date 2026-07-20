---
coediting: false
comments_count: 0
created_at: '2024-02-09T19:33:42+09:00'
id: 26131d290741a53abc07
likes_count: 14
private: false
reactions_count: 0
stocks_count: 12
tags:
- name: rag
  versions: []
title: RAG の実践的な資料
updated_at: '2024-07-13T02:50:56+09:00'
url: https://qiita.com/7shi/items/26131d290741a53abc07
slide: false
---

RAG に関する資料をメモ的にまとめます。

# 概要

https://internet.watch.impress.co.jp/docs/column/shimizu/1580947.html

# 触ってみる

OpenAI を使った記事です。シンプルにまとまっていて、利用例としてイメージが湧きやすいです。

https://qiita.com/mitsumizo/items/469d79c5e81d9189a9e4

プロンプトに関連情報を埋め込みます。

```py
prompt = PromptTemplate(
    template="""
    文章を前提にして質問に答えてください。

    文章 :
    {document}

    質問 : {question}
    """,
    input_variables=["document", "question"],
)
```

このように書かれています。

> 「何を抽出するか」と言うところがRAGで一番難しいところである。

これについては以下の記事が詳しいです。

https://dev.classmethod.jp/articles/rag-knowledge-on-real-projects/

## ローカル LLM

https://zenn.dev/kun432/scraps/4e5f0e00d47872

https://qiita.com/t_kamiya78/items/659d156c4a88e6a37de9

https://zenn.dev/tsutof/articles/a30d0bf7f89bb8

https://blueqat.com/yuichiro_minato2/a5278948-232f-45c9-859e-4257dd5d116a

https://qiita.com/yuki_ink/items/c3125f45fb725612910e

# Azure

<blockquote class="twitter-tweet"><p lang="ja" dir="ltr">AzureでRAGをガンガン試行錯誤してみて得たナレッジを紹介します！<a href="https://t.co/Clds6aVeEF">https://t.co/Clds6aVeEF</a><br><br>わりと普通の着地になってるけど、index登録時に入れるテキストを整形すること、特定性の高い情報はmetadataに入れておくとよいという感じ<br><br>凡事徹底が意外とできんのよな(説明コスト的に)</p>&mdash; 幻日 (@__genzitsu__) <a href="https://twitter.com/__genzitsu__/status/1755454407716520199?ref_src=twsrc%5Etfw">February 8, 2024</a></blockquote>

<blockquote class="twitter-tweet"><p lang="ja" dir="ltr">「Azure OpenAI ServiceではじめるChatGPT/LLMシステム構築入門」を共同執筆しました。<br>ChatGPTが登場して、ほとんどLLMの仕事しかしてないメンバばかりで作った渾身の1作です。<br>さいきん血反吐だしてた理由はこれの執筆も一因です。<br><br>内容は↓<br>・LLMの基礎やプロンプトエンジニアリング<br>・Azure… <a href="https://t.co/B3SoJ2Zbja">pic.twitter.com/B3SoJ2Zbja</a></p>&mdash; Hirosato Gamo | AI Cloud Solution Architect (@hiro_gamo) <a href="https://twitter.com/hiro_gamo/status/1738123840499372407?ref_src=twsrc%5Etfw">December 22, 2023</a></blockquote>

<blockquote class="twitter-tweet"><p lang="ja" dir="ltr">RAGにおいて、Microsoft Azure AI Searchだと、全文検索とベクトル検索を組合せたHybrid検索に、セマンティックランキングを組合せた方法が一番精度出る。<br>※毎度どこかに行ってしまう情報源なのでメモ<a href="https://t.co/6yEUmEThYt">https://t.co/6yEUmEThYt</a> <a href="https://t.co/yKhZz6EgJk">pic.twitter.com/yKhZz6EgJk</a></p>&mdash; Shinichi Takaŷanagi（減量中） (@_stakaya) <a href="https://twitter.com/_stakaya/status/1763846428315779561?ref_src=twsrc%5Etfw">March 2, 2024</a></blockquote>

<blockquote class="twitter-tweet"><p lang="ja" dir="ltr">AzureでRAGを構築するアーキテクチャがまとまってて良い。<br><br>Azure素人からするとAzure OpenAI Service以外にどんなサービスがあってどう組み合わせればいいか分からなかったからとてもありがたい。<br><br>この記事を目印にドキュメントを読んでいけば欲しい情報は得られそう。<a href="https://t.co/WVAQzWTITl">https://t.co/WVAQzWTITl</a></p>&mdash; Shuichi Ohsawa (@ohsawa0515) <a href="https://twitter.com/ohsawa0515/status/1767568900923981888?ref_src=twsrc%5Etfw">March 12, 2024</a></blockquote>

# 手法など

https://sue124.hatenablog.com/entry/2024/07/02/233616

https://qiita.com/jw-automation/items/045917be7b558509fdf2

https://zenn.dev/knowledgesense/articles/67dd2a41fc4d0b

https://zenn.dev/knowledgesense/articles/bb5e15abb3c547

<blockquote class="twitter-tweet"><p lang="ja" dir="ltr">RAG Fusionについてはおじろさんの資料がわかりやすかった。<br>従来のRAGでは1個のクエリで事前知識を検索して利用するのに対し、RAG Fusionではクエリ拡張て得られた複数の検索クエリで幅広に検索した上で、その結果をReciprocal Rank Fusionでマージして使おうという発想。<a href="https://t.co/dDcPjQ8VeE">https://t.co/dDcPjQ8VeE</a></p>&mdash; ML_Bear (@MLBear2) <a href="https://twitter.com/MLBear2/status/1758707964058452042?ref_src=twsrc%5Etfw">February 17, 2024</a></blockquote>

https://zenn.dev/knowledgesense/articles/913d07f490e9c7

> HippoRAGが従来のRAGと大きく違う点は、ベクトルデータベースやコサイン類似度による検索を強いない点です。これはかなり大きい特徴です。HippoRAGのポイントは、ナレッジグラフを活用した（ベクトルDBを使わない）RAGである点・ナレッジグラフを賢く更新する点です。

# 情報検索

<blockquote class="twitter-tweet"><p lang="ja" dir="ltr">しばらくRAGの精度向上案件ばかりやっていたけど、vector searchもhybrid searchも魔法ではないので「そもそものデータを綺麗にしろ」ってケースが多すぎる。<br><br>検索周り頑張るよりも、ドキュメントをLLMでひたすら整形→想定問答集みたいなQA作ってRAGしたほうが精度良い。…</p>&mdash; Mitarashi (@mitarashiponta) <a href="https://twitter.com/mitarashiponta/status/1811727230088908861?ref_src=twsrc%5Etfw">July 12, 2024</a></blockquote>

Retrieval（情報検索）はベクトル検索に限定されない一般の検索技術

<blockquote class="twitter-tweet"><p lang="ja" dir="ltr">RAGについて。昨今広まってるが同じ単語でも人によって使い方が違うのでまとめとく。<br>RAGは、外部情報をLLM入力に含めてLLMの能力を“拡張“できるようにする手法。<br>適切な外部情報の見つけ方は何でも良くてベクトル検索でも全文検索でもLLMによる行動選択でも良い。<br>ベクトル検索だけがRAGじゃない。</p>&mdash; ざわきん/zawakin (@zawawahoge) <a href="https://twitter.com/zawawahoge/status/1776773952096116784?ref_src=twsrc%5Etfw">April 7, 2024</a></blockquote>

<blockquote class="twitter-tweet"><p lang="ja" dir="ltr">RAGというとなぜかベクトル検索（Semantic Retrieval）とセットで語られることが多いが、Retrieveは別になんでも良くて、全文検索でもgrepでもDB queryでもなんかAPI叩いて返ってきた結果でも、本当になんでも良い</p>&mdash; すずどら (@sz_dr) <a href="https://twitter.com/sz_dr/status/1776077646562267426?ref_src=twsrc%5Etfw">April 5, 2024</a></blockquote>

<blockquote class="twitter-tweet"><p lang="ja" dir="ltr">RAGのRetrieval部分は要するに「検索システム」。これをEmbeddingによるベクトル化が必須だと考える必要はない。既存の検索エンジン、SQLサーバー、検索エンジン用に進化した検索システム・・・、自然言語によるクエリーで自然言語の情報がとってこれれば、あとはLLMに渡してRAG成立。</p>&mdash; 平岡 憲人(HIRAOKA, Norito) Stand with Ukraine (@onokoro48) <a href="https://twitter.com/onokoro48/status/1776032728485601558?ref_src=twsrc%5Etfw">April 4, 2024</a></blockquote>

<blockquote class="twitter-tweet"><p lang="ja" dir="ltr">RAGにおいて、ベクトル検索だけじゃなく全文検索も加えたハイブリッド検索じゃないとパフォーマンスが出ないことを試してみた、というMicrosoft方の記事。RAG ＝ベクトル検索という風潮があるが、そうではない、と。<a href="https://t.co/NGanOFABgc">https://t.co/NGanOFABgc</a></p>&mdash; Shinichi Takaŷanagi（減量中） (@_stakaya) <a href="https://twitter.com/_stakaya/status/1800645663794885011?ref_src=twsrc%5Etfw">June 11, 2024</a></blockquote>

<blockquote class="twitter-tweet"><p lang="ja" dir="ltr">RAGについて個人的に一番問題だと思ってるのが、Retrieval-Augmented Generationなのにretrieval（情報検索）分からない人がやってるってことじゃないですか！？</p>&mdash; べいえりあ (@mr_bay_area) <a href="https://twitter.com/mr_bay_area/status/1775759223189799122?ref_src=twsrc%5Etfw">April 4, 2024</a></blockquote>

<blockquote class="twitter-tweet"><p lang="ja" dir="ltr">検索エンジンは難しい。IndexingやScoring、クエリの組み立てなど構成要素一つ一つに専門的知識必要で、ふわっとベクトル検索すればいいとかそういうものではない。なのだけど、ふんわり検索でRAGみたいな話が聞かれることが増えている。というのも規約とか元データとしてある程度綺麗なドキュメントな…</p>&mdash; 松本 勇気 | LayerXはSaaS+Fintechの会社です (@y_matsuwitter) <a href="https://twitter.com/y_matsuwitter/status/1775887121020236070?ref_src=twsrc%5Etfw">April 4, 2024</a></blockquote>

<blockquote class="twitter-tweet"><p lang="ja" dir="ltr">LLMの結果をRAGで改善、と言ってるのに全く検索エンジンの中身を調べたこと無い勢のみなさ〜ん、こ〜んに〜ちは〜！！<br><br>今から以前に読んだ本をオススメするから買ってね〜！！<br><br>まずこちら。実装周りを網羅的に扱った日本語で読める中では最も最近のもの。悩まず買ったら良い<a href="https://t.co/MEA3uxCYTb">https://t.co/MEA3uxCYTb</a></p>&mdash; Toshinori Sato (@overlast) <a href="https://twitter.com/overlast/status/1775876399334895660?ref_src=twsrc%5Etfw">April 4, 2024</a></blockquote>

# 巨大コンテキストウィンドウ

<blockquote class="twitter-tweet"><p lang="ja" dir="ltr">【悲報：Genimi 1.5 ProでRAG終焉のお知らせ】<br><br>前々からセミナー等では話していた、「コンテキストウィンドウが膨大になればRAGは不要になる」という未来が3年後くらいかなと思いきや、もう現実になった。<br><br>AI事業者は必見の内容です。<br><br>本当に最近のAI技術革新が激しすぎる。<br><br>58ページのGenimi 1.5… <a href="https://t.co/CJi4HlV7yM">pic.twitter.com/CJi4HlV7yM</a></p>&mdash; チャエン | 重要AIニュースを毎日発信⚡️ (@masahirochaen) <a href="https://twitter.com/masahirochaen/status/1759082578345435388?ref_src=twsrc%5Etfw">February 18, 2024</a></blockquote>

<blockquote class="twitter-tweet"><p lang="ja" dir="ltr">タイトルは煽りっぽいけど資料が豊富。1.5は対象データセットが1M tokenに収まればRAG作る苦労がないしrecall rateも高くてすばらしい一方で、生成にかかる遅延も無視できなくなる。データセットの大きさや遅延の要件に応じてRAGと使い分けかな。 <a href="https://t.co/h3NX7FNDFw">https://t.co/h3NX7FNDFw</a></p>&mdash; Kazunori Sato (@kazunori_279) <a href="https://twitter.com/kazunori_279/status/1777606905495691361?ref_src=twsrc%5Etfw">April 9, 2024</a></blockquote>

<blockquote class="twitter-tweet"><p lang="ja" dir="ltr">コンテキストが長くなりRAG is dead的な主張、APIの多くはトークンあたりで課金され、全ドキュメントを読み込ませるのはリクエストの都度お金かかるからやっぱり検索を挟めるRAG大事！！、というので落ち着いたのかと思ってた。<br><br>自前でモデル作るガッツがあってもまぁまぁ、お金掛かりそう。</p>&mdash; Yuki Yada / 矢田宙生 (@arr0w_swe) <a href="https://twitter.com/arr0w_swe/status/1775865878296551714?ref_src=twsrc%5Etfw">April 4, 2024</a></blockquote>

# LLM

<blockquote class="twitter-tweet"><p lang="ja" dir="ltr">LLM(大規模言語モデル）の簡単な仕組みの解説<br><br>ChatGPTを含めたLLMは驚異的な性能を誇ります。ではLLMはどのような機械学習でその能力を獲得したのでしょうか。秘密は「次の単語の予想」です。… <a href="https://t.co/WZ0d6PHHVc">pic.twitter.com/WZ0d6PHHVc</a></p>&mdash; 山本一成🌤️チューリングのCEO (@issei_y) <a href="https://twitter.com/issei_y/status/1755447446468284698?ref_src=twsrc%5Etfw">February 8, 2024</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

# 発言埋め込み

X の発言は URL を書くだけで埋め込めますが、中身が表示されるまでタイムラグがあるため blockquote で埋め込んでいます。

https://qiita.com/shizen-shin/items/5704c659727ec83356ff
