---
coediting: false
comments_count: 0
created_at: '2025-04-11T00:21:03+09:00'
id: 5a1add7189c45ae4a254
likes_count: 0
private: false
reactions_count: 0
stocks_count: 0
tags:
- name: jsonschema
  versions: []
- name: GoogleAIStudio
  versions: []
- name: 構造化出力
  versions: []
title: Google AI Studio で配列の中に要素を指定したスキーマを作成
updated_at: '2025-04-14T04:51:05+09:00'
url: https://qiita.com/7shi/items/5a1add7189c45ae4a254
slide: false
---

Google AI Studio の構造化出力を行うためのスキーマで、配列の中に要素を指定します。

# 手順

`object` 型の配列を作成して、Add nested property で要素を指定します。

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/32057/cd5b489d-5b31-4666-ab38-170c4f8bffbc.png)

`description` は Code Editor で入力します。

```json
{
  "type": "object",
  "properties": {
    "scenes": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "time": {
            "type": "string",
            "description": "The timestamp indicating when the scene occurs in the video ('MM:SS')."
          },
          "visuals": {
            "type": "string",
            "description": "A description or analysis of the visual content of the scene."
          },
          "audio": {
            "type": "string",
            "description": "A transcription of the audio content of the scene."
          }
        },
        "required": [
          "time",
          "visuals",
          "audio"
        ]
      },
      "description": "An array containing individual scenes extracted from the video."
    }
  },
  "required": [
    "scenes"
  ]
}
```

次のような出力を想定しています。

```json:出力例
{
  "segments": [
    { "time": "00:00", "visuals": "forest", "audio": "Hello!" },
    { "time": "00:05", "visuals": "sky", "audio": "How are you?" }
  ]
}
```

# 応用例

YouTube の URL を貼り付けると動画が認識されるので、上のスキーマで内容が取得できます。

- https://www.youtube.com/watch?v=n17NFYBBjXY

```json:出力例
{
  "scenes": [
    {
      "time": "00:00",
      "visuals": "Two silhouetted figures stand amidst smoke in front of a bright surface. Text at the top of the image reads 'Albert Camus \"The Fall\"'. Below this, the same title appears in Japanese. At the bottom, credits read: 'Conversation: NotebookLM', 'Director: Gemini 1.5 Flash', and 'Image: Stable Diffusion 3'.",
      "audio": " "
    },
    {
      "time": "00:04",
      "visuals": "A street scene in Amsterdam, where the road is wet from a recent rain, reflecting the lights of the buildings and street lamps. Above the image, text says 'Okay, so you know how sometimes you read something and it just kind of of sticks with you?' and below, the translation of this text in Japanese is displayed with the explanation of \"Sticks with you\".",
      "audio": "Okay, so you know how sometimes you read something and it just kind of sticks with you?"
    },
（中略）
    {
      "time": "08:56",
      "visuals": "A starry sky.",
      "audio": "And remember, sometimes the most important questions are the ones that don't have easy answers."
    }
  ]
}
```

# 関連記事

動画解析スキーマの具体的な利用方法は、以下の記事を参照してください。

https://qiita.com/7shi/items/7578f1710e76770f1af1

応用例で扱った動画は、以下の手法で作成しました。

https://qiita.com/7shi/items/04962cf58e172da662c1
