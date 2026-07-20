---
coediting: false
comments_count: 0
created_at: '2023-08-08T01:39:01+09:00'
id: 663c37408f880336fa9b
likes_count: 3
private: false
reactions_count: 0
stocks_count: 4
tags:
- name: Python
  versions: []
- name: レーベンシュタイン距離
  versions: []
title: 文字列を類似度でグループ化
updated_at: '2023-11-19T20:53:31+09:00'
url: https://qiita.com/7shi/items/663c37408f880336fa9b
slide: false
---

Python で文字列を類似度ごとにグループ化します。使用例として機械翻訳を利用した言語系統や精度の確認を行います。

ChatGPT による実装を参考にしましたが、記事は書かせていません。

* https://github.com/7shi/ai-log/blob/main/chatgpt/20230807-similarity.md

# 類似度

レーベンシュタイン距離は 2 つの文字列を一致させるための削除・挿入・置換の操作回数です。

https://qiita.com/7shi/items/b0b95610b59050e42666

レーベンシュタイン距離は、文字列が一致すれば 0、まったく一致する文字がなければ長い方の文字列長となります。

最大値を 1 にするため長い方の文字列長で割ったものを標準化レーベンシュタイン距離と呼びます。

類似度を 0 ～ 1 で表すことを考えます。0 は不一致、1 は一致と定義するのが直感的です。標準化レーベンシュタイン距離とは逆のため、1 から引くことで類似度として利用できます。

```py
import Levenshtein

def calculate_normalized_similarity(text1, text2):
    distance = Levenshtein.distance(text1, text2)
    max_length = max(len(text1), len(text2))
    normalized_similarity = 1 - (distance / max_length)
    return normalized_similarity
```

:::note info
ChatGPT によるコードです。
:::

Levenshtein パッケージを使用しています。

```
pip install Levenshtein
```

:::note info
Levenshtein パッケージには `ratio` という類似度を 0 ～ 1 で返す関数もありますが、置換の重み付けを変えているため `calculate_normalized_similarity` とは結果が異なります。（後で比較）
:::

# グループ化

連想配列と閾値を受け取って、値の類似度でグループ化してキーの配列を返す関数です。

```py
def group_by_similarity(keyValues, threshold):
    groups = []
    dict = {}

    for key1, text1 in keyValues.items():
        for key2, text2 in keyValues.items():
            if key1 == key2: continue
            similarity = calculate_normalized_similarity(text1, text2)
            if key1 in dict:
                dict1 = dict[key1]
            else:
                dict1 = set([key1])
                dict[key1] = dict1
                groups.append(dict1)
            if similarity > threshold:
                if key2 in dict:
                    dict2 = dict[key2]
                    if dict1 != dict2:
                        dict1 |= dict2
                        for lang in dict2:
                            dict[lang] = dict1
                        groups.remove(dict2)
                else:
                    dict1.add(key2)
                    dict[key2] = dict1

    return groups
```

:::note info
ChatGPT に仕様が伝えきれなかったため、主要部分は手動で実装しました。
:::

## 仕様

渡された配列の各要素は常に 1 つのグループにのみ属します。複数のグループにまたがることはありません。

1. A と B の類似度が閾値以上、A と C が閾値未満  
   → A と B は同一グループ
2. B と C の類似度が閾値以上
   → B が属するグループに C を追加
3. 結果として A と B と C は同一グループ

:::note info
イメージとしては「友達の友達は友達」のような仕様です。
:::

実装個所です。

```py
                    if dict1 != dict2:
                        dict1 |= dict2
                        for lang in dict2:
                            dict[lang] = dict1
                        groups.remove(dict2)
```

`key1` のグループ `dict1` に `key2` を追加する際、`key2` が別のグループ `dict2` に属していれば、`dict2` のメンバーをすべて `dict1` に移して、`dict2` は削除します。

# 使用例

[百度（Baidu）翻訳](https://fanyi.baidu.com/) をテストするため、同一の英文を 200 言語で翻訳して、それを英語に逆翻訳しました。

> In the middle of the path of our life, I found myself in a dark forest, because the right way was lost.

* 結果: https://gist.github.com/7shi/298a77f78cf00a6715b1712f96070d39

英語から各国語への翻訳結果を `texts1`、その逆翻訳を `texts2` に読み込みます。

```py
texts1 = {}
texts2 = {}
with open('baidu.txt', 'r', encoding='utf-8') as file:
    for line in file:
        lang, text1, text2 = line.strip().split('\t')
        texts1[lang] = text1
        texts2[lang] = text2
```

## グループ化

英語から各国語への翻訳結果 `texts1` を閾値 0.5 でグループ化します。

```py
language_groups = group_by_similarity(texts1, 0.5)
for group in [x for x in language_groups if len(x) > 1]:
    print(", ".join(group))
```
```text:実行結果 (閾値 0.5)
アラビア語アルジェリア方言, アラビア語
ガンダ語, コーンウォール語, アゼルバイジャン語, クリミア・タタール語, トルコ語
西フリジア語, アフリカーンス語, オランダ語, ドイツ語
英語, スコットランド語, アラゴン語
ウクライナ語, ベラルーシ語
クロアチア語, モンテネグロ語, セルビア語(ラテン文字), スロベニア語, ボスニア語, セルビア・クロアチア語
カビル語, ベルベル語
デンマーク語, ニーノシュク, スウェーデン語, ノルウェー語, ブークモール
広東語, 中国語(簡体), 中国語(繁体)
スロバキア語, チェコ語
ガリシア語, アストゥリアス語, オック語, スペイン語, ポルトガル語, ブラジルポルトガル語, インターリングア, イタリア語, カタルーニャ語
フランス語, カナダ・フランス語
フィンランド語, エストニア語
エスペラント, イド語
タガログ語, フィリピン語
マイティリー語, ヒンディー語
インドネシア語, マレー語
コサ語, ズールー語
```

翻訳結果が類似している言語のグループが出力されました。言語系統を反映していると考えられます。

:::note warn
アラゴン語は翻訳されずに元の英文がそのまま出力されたため、本来の系統とは異なる英語のグループに入っています。
:::

閾値を 0.4 に下げると、判定が緩くなってグループは大きくなります。

```text:実行結果 (閾値 0.4)
アラビア語アルジェリア方言, アラビア語
トルクメン語, アゼルバイジャン語, ガンダ語, コーンウォール語, クリミア・タタール語, トルコ語
アッサム語, ベンガル語
英語, スコットランド語, ニーノシュク, ルクセンブルク語, アフリカーンス語, デンマーク語, オランダ語, ブークモール, 低地ドイツ語, ノルウェー語, ドイツ語, 西フリジア語, アラゴン語, スウェーデン語
ウクライナ語, ロシア語, ベラルーシ語
カビル語, ベルベル語
マレー語, インドネシア語, スンダ語
広東語, 中国語(繁体), 中国語(簡体)
チェコ語, 高地ソルブ語, ボスニア語, クロアチア語, スロベニア語, セルビア語(ラテン文字), スロバキア語, モンテネグロ語, セルビア・クロアチア語
セブアノ語, タガログ語, フィリピン語
フィンランド語, エストニア語
カナダ・フランス語, アストゥリアス語, フリウリ語, オック語, ガリシア語, ポルトガル語, ワロン語, イタリア語, インターリングア, ブラジルポルトガル語, フランス語, イド語, カタルーニャ語, エスペラント, スペイン語
アイルランド語, スコットランド・ゲール語
マイティリー語, ヒンディー語
セルビア語(キリル文字), マケドニア語
コサ語, ズールー語, ショナ語
```

実際の言語系統は、手動でまとめた記事を参照してください。

https://7shi.hateblo.jp/entry/2023/08/06/195124

:::note info
かなりの部分で一致しています。
:::

### Levenshtein.ratio

`calculate_normalized_similarity` と `Levenshtein.ratio` を比較すると、後者は置換による減点幅が小さくなるため類似度の数値は上がります。

閾値を 0.1 上げれば、ほぼ同様の結果が得られます。

```text:閾値 0.6
アラビア語アルジェリア方言, アラビア語
アゼルバイジャン語, コーンウォール語, クリミア・タタール語, ガンダ語, トルコ語
オランダ語, 西フリジア語, アフリカーンス語
スコットランド語, アラゴン語, 英語
クロアチア語, モンテネグロ語, セルビア語(ラテン文字), ボスニア語, セルビア・クロアチア語, スロベニア語
ベルベル語, カビル語
スウェーデン語, デンマーク語, ブークモール, ニーノシュク, ノルウェー語
インドネシア語, マレー語, スンダ語
中国語(簡体), 広東語, 中国語(繁体)
チェコ語, スロバキア語
セブアノ語, タガログ語, フィリピン語
ワロン語, フランス語, カナダ・フランス語
フィンランド語, エストニア語
エスペラント, イド語
低地ドイツ語, ドイツ語
ヒンディー語, マイティリー語
アストゥリアス語, ガリシア語, インターリングア, イタリア語, スペイン語, オック語, ポルトガル語, ブラジルポルトガル語, カタルーニャ語
マケドニア語, セルビア語(キリル文字)
ウクライナ語, ロシア語, ベラルーシ語
コサ語, ズールー語
```
```text:閾値 0.5
アラビア語, アラビア語アルジェリア方言
クリミア・タタール語, コーンウォール語, トルコ語, トルクメン語, ガンダ語, アゼルバイジャン語
アッサム語, ベンガル語
ニーノシュク, アイスランド語, 低地ドイツ語, 西フリジア語, ルクセンブルク語, デンマーク語, オランダ語, 英語, ドイツ語, スウェーデン語, アラゴン語, アフリカーンス語, ブークモール, ノルウェー語, スコットランド語
ロシア語, マケドニア語, ベラルーシ語, ブルガリア語, セルビア語(キリル文字), ウクライナ語
セルビア語(ラテン文字), スロバキア語, クロアチア語, スロベニア語, セルビア・クロアチア語, モンテネグロ語, ボスニア語, 高地ソルブ語, チェコ語
ベルベル語, カビル語
インドネシア語, スンダ語, マレー語
広東語, 中国語(簡体), 中国語(繁体)
フィンランド語, エストニア語
ガリシア語, ルーマニア語, エスペラント, インターリングア, イド語, オック語, フランス語, ワロン語, カナダ・フランス語, アストゥリアス語, ブラジルポルトガル語, フリウリ語, イタリア語, ポルトガル語, スペイン語, サルデーニャ語, カタルーニャ語
アイルランド語, スコットランド・ゲール語
マイティリー語, ネパール語, ヒンディー語
パシュトー語, ウルドゥー語, ペルシア語
タガログ語, セブアノ語, パンパンガ語, フィリピン語
コサ語, ショナ語, ズールー語
```

結果はほぼ同じです。いずれにせよ望ましい結果が得られるように閾値は微調整する必要があるため、使い勝手はそれほど変わりません。

## 類似度

逆翻訳結果を元の英文と比較することで、翻訳精度の目安にできます。

類似度を 100 倍してスコアとします。上位 15 言語を表示します。

```py
def sorted_similarities(text, dict):
    similarities = {}
    for k, v in dict.items():
        similarities[k] = calculate_normalized_similarity(text, v)
    return sorted(similarities.items(), key=lambda x: x[1], reverse=True)

for lang, sim in sorted_similarities(texts1["英語"], texts2)[:15]:
    print(int(sim * 100), lang)
```
```text:実行結果
100 アラゴン語
100 英語
100 スコットランド語
95 オランダ語
95 ギリシア語
95 イタリア語
94 ブルガリア語
94 チェコ語
94 ドイツ語
94 ハンガリー語
94 ポーランド語
93 セルビア語(キリル文字)
91 スウェーデン語
90 アフリカーンス語
90 ミャオ語
```

:::note warn
アラゴン語が 100 点なのは、翻訳されずに元の英文がそのまま出力されたためです。
:::

### Levenshtein.ratio

`calculate_normalized_similarity` の代わりに `Levenshtein.ratio` を使用した結果です。

```text
100 アラゴン語
100 英語
100 スコットランド語
96 オランダ語
96 ギリシア語
96 イタリア語
95 ブルガリア語
95 チェコ語
95 ドイツ語
95 ハンガリー語
95 ポーランド語
94 セルビア語(キリル文字)
93 バスク語
93 ブークモール
93 イド語
```

下の 3 つが入れ替わりました。

# 関連情報

同じ質問を Bard でも試しました。

* https://github.com/7shi/ai-log/blob/main/bard/20230808-similarity.md

類似度を Google スプレッドシートで計算した記事です。

https://7shi.hateblo.jp/entry/2023/09/23/144711
