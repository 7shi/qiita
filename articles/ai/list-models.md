---
coediting: false
comments_count: 0
created_at: '2024-11-11T21:58:01+09:00'
id: ac3c2b1bea3bb4e9eb70
likes_count: 13
private: false
reactions_count: 0
stocks_count: 3
tags:
- name: Gemini
  versions: []
title: Gemini APIで使えるモデル
updated_at: '2026-06-04T11:44:12+09:00'
url: https://qiita.com/7shi/items/ac3c2b1bea3bb4e9eb70
slide: false
---

Google AI Studio で生成した API key で使用できるモデルを調べました。

環境変数 `GEMINI_API_KEY` をセットする必要があります。

```sh:準備
pip install google-genai
```
```py:ls.py
import os
from google import genai
client = genai.Client(api_key=os.environ.get("GEMINI_API_KEY"))
print("name|display_name")
print("----|----")
for model in client.models.list():
    name = model.name.removeprefix("models/")
    print(f"{name}|{model.display_name}")
```
<details><summary>履歴保存スクリプト</summary>
特定のディレクトリ内に YYYYMMDD.txt の形式で履歴を保存するスクリプトです。
<pre>#!/bin/bash
&nbsp;
# 1. まずtmpとして出力
python ls.py > tmp
&nbsp;
LATEST="LATEST"
&nbsp;
# 2. 最終版（LATEST)とcmpして、差がなければtmpを削除してその旨表示して終了
# -e はファイルやシンボリックリンクの存在を確認
if [ -e "$LATEST" ]; then
&nbsp;&nbsp;if cmp -s tmp "$LATEST"; then
&nbsp;&nbsp;&nbsp;&nbsp;echo "変更はありませんでした。"
&nbsp;&nbsp;&nbsp;&nbsp;rm tmp
&nbsp;&nbsp;&nbsp;&nbsp;exit 0
&nbsp;&nbsp;fi
&nbsp;&nbsp;fiecho "変更が検出されました。"
fi
&nbsp;
# 3. dateコマンドで日付を取得
DATE=$(date +%Y%m%d)
FILENAME="${DATE}.txt"
&nbsp;
# 4. tmpをYYYYMMDD.txtにリネーム
mv tmp "$FILENAME"
echo "新しいファイルを作成しました: $FILENAME"
&nbsp;
# 5. 画面にLATESTとのdiffを標示
if [ -e "$LATEST" ]; then
&nbsp;&nbsp;fiecho "LATESTとの差分:"
&nbsp;&nbsp;fidiff -u0 --color "$LATEST" "$FILENAME"
fi
&nbsp;
# LATESTシンボリックリンクを更新
ln -sf "$FILENAME" "$LATEST"
echo "LATESTシンボリックリンクを $FILENAME に更新しました。"
&nbsp;
# クリップボードにコピー
xsel -b < $FILENAME
echo "$FILENAME の内容をクリップボードにコピーしました。"
</pre>
</details>

:::note warn
取得したすべてのモデルが使用可能かは未確認です。
:::

# 2026/06/04

name|display_name
----|----
gemini-2.5-flash|Gemini 2.5 Flash
gemini-2.5-pro|Gemini 2.5 Pro
gemini-2.0-flash|Gemini 2.0 Flash
gemini-2.0-flash-001|Gemini 2.0 Flash 001
gemini-2.0-flash-lite-001|Gemini 2.0 Flash-Lite 001
gemini-2.0-flash-lite|Gemini 2.0 Flash-Lite
gemini-2.5-flash-preview-tts|Gemini 2.5 Flash Preview TTS
gemini-2.5-pro-preview-tts|Gemini 2.5 Pro Preview TTS
gemma-4-26b-a4b-it|Gemma 4 26B A4B IT
gemma-4-31b-it|Gemma 4 31B IT
gemini-flash-latest|Gemini Flash Latest
gemini-flash-lite-latest|Gemini Flash-Lite Latest
gemini-pro-latest|Gemini Pro Latest
gemini-2.5-flash-lite|Gemini 2.5 Flash-Lite
gemini-2.5-flash-image|Nano Banana
gemini-3-pro-preview|Gemini 3 Pro Preview
gemini-3-flash-preview|Gemini 3 Flash Preview
gemini-3.1-pro-preview|Gemini 3.1 Pro Preview
gemini-3.1-pro-preview-customtools|Gemini 3.1 Pro Preview Custom Tools
gemini-3.1-flash-lite-preview|Gemini 3.1 Flash Lite Preview
gemini-3.1-flash-lite|Gemini 3.1 Flash Lite
gemini-3-pro-image-preview|Nano Banana Pro
gemini-3-pro-image|Nano Banana Pro
nano-banana-pro-preview|Nano Banana Pro
gemini-3.1-flash-image-preview|Nano Banana 2
gemini-3.1-flash-image|Nano Banana 2
gemini-3.5-flash|Gemini 3.5 Flash
lyria-3-clip-preview|Lyria 3 Clip Preview
lyria-3-pro-preview|Lyria 3 Pro Preview
gemini-3.1-flash-tts-preview|Gemini 3.1 Flash TTS Preview
gemini-robotics-er-1.5-preview|Gemini Robotics-ER 1.5 Preview
gemini-robotics-er-1.6-preview|Gemini Robotics-ER 1.6 Preview
gemini-2.5-computer-use-preview-10-2025|Gemini 2.5 Computer Use Preview 10-2025
antigravity-preview-05-2026|Antigravity Agent Preview
deep-research-max-preview-04-2026|Deep Research Max Preview (Apr-21-2026)
deep-research-preview-04-2026|Deep Research Preview (Apr-21-2026)
deep-research-pro-preview-12-2025|Deep Research Pro Preview (Dec-12-2025)
gemini-embedding-001|Gemini Embedding 001
gemini-embedding-2-preview|Gemini Embedding 2 Preview
gemini-embedding-2|Gemini Embedding 2
aqa|Model that performs Attributed Question Answering.
imagen-4.0-generate-001|Imagen 4
imagen-4.0-ultra-generate-001|Imagen 4 Ultra
imagen-4.0-fast-generate-001|Imagen 4 Fast
veo-2.0-generate-001|Veo 2
veo-3.0-generate-001|Veo 3
veo-3.0-fast-generate-001|Veo 3 fast
veo-3.1-generate-preview|Veo 3.1
veo-3.1-fast-generate-preview|Veo 3.1 fast
veo-3.1-lite-generate-preview|Veo 3.1 lite
gemini-2.5-flash-native-audio-latest|Gemini 2.5 Flash Native Audio Latest
gemini-2.5-flash-native-audio-preview-09-2025|Gemini 2.5 Flash Native Audio Preview 09-2025
gemini-2.5-flash-native-audio-preview-12-2025|Gemini 2.5 Flash Native Audio Preview 12-2025
gemini-3.1-flash-live-preview|Gemini 3.1 Flash Live Preview

# 差分

```diff:2026/04/16 と 2026/06/04 の差分
-gemma-3-1b-it|Gemma 3 1B
-gemma-3-4b-it|Gemma 3 4B
-gemma-3-12b-it|Gemma 3 12B
-gemma-3-27b-it|Gemma 3 27B
-gemma-3n-e4b-it|Gemma 3n E4B
-gemma-3n-e2b-it|Gemma 3n E2B
+gemini-3.1-flash-lite|Gemini 3.1 Flash Lite
+gemini-3-pro-image|Nano Banana Pro
+gemini-3.1-flash-image|Nano Banana 2
+gemini-3.5-flash|Gemini 3.5 Flash
+antigravity-preview-05-2026|Antigravity Agent Preview
+deep-research-max-preview-04-2026|Deep Research Max Preview (Apr-21-2026)
+deep-research-preview-04-2026|Deep Research Preview (Apr-21-2026)
+gemini-embedding-2|Gemini Embedding 2
```
```diff:2026/04/06 と 2026/04/16 の差分
+gemini-3.1-flash-tts-preview|Gemini 3.1 Flash TTS Preview
+gemini-robotics-er-1.6-preview|Gemini Robotics-ER 1.6 Preview
```
```diff:2026/03/12 と 2026/04/06 の差分
+gemma-4-26b-a4b-it|Gemma 4 26B A4B IT
+gemma-4-31b-it|Gemma 4 31B IT
-gemini-2.5-flash-lite-preview-09-2025|Gemini 2.5 Flash-Lite Preview Sep 2025
+lyria-3-clip-preview|Lyria 3 Clip Preview
+lyria-3-pro-preview|Lyria 3 Pro Preview
+veo-3.1-lite-generate-preview|Veo 3.1 lite
+gemini-3.1-flash-live-preview|Gemini 3.1 Flash Live Preview
```
```diff:2026/01/29 と 2026/03/12 の差分
-gemini-2.0-flash-exp-image-generation|Gemini 2.0 Flash (Image Generation) Experimental
-gemini-exp-1206|Gemini Experimental 1206
-gemini-2.5-flash-preview-09-2025|Gemini 2.5 Flash Preview Sep 2025
+gemini-3.1-pro-preview|Gemini 3.1 Pro Preview
+gemini-3.1-pro-preview-customtools|Gemini 3.1 Pro Preview Custom Tools
+gemini-3.1-flash-lite-preview|Gemini 3.1 Flash Lite Preview
+gemini-3.1-flash-image-preview|Nano Banana 2
-embedding-001|Embedding 001
-text-embedding-004|Text Embedding 004
+gemini-embedding-2-preview|Gemini Embedding 2 Preview
-imagen-4.0-generate-preview-06-06|Imagen 4 (Preview)
-imagen-4.0-ultra-generate-preview-06-06|Imagen 4 Ultra (Preview)
```
```diff:2025/12/18 と 2026/01/29 の差分
-embedding-gecko-001|Embedding Gecko
-gemini-2.0-flash-exp|Gemini 2.0 Flash Experimental
-gemini-2.0-flash-lite-preview-02-05|Gemini 2.0 Flash-Lite Preview 02-05
-gemini-2.0-flash-lite-preview|Gemini 2.0 Flash-Lite Preview
-gemini-2.5-flash-image-preview|Nano Banana
-gemini-embedding-exp-03-07|Gemini Embedding Experimental 03-07
-gemini-embedding-exp|Gemini Embedding Experimental
```
```diff:2025/12/07 と 2025/12/18 の差分
-gemini-2.0-pro-exp|Gemini 2.0 Pro Experimental
-gemini-2.0-pro-exp-02-05|Gemini 2.0 Pro Experimental 02-05
+gemini-3-flash-preview|Gemini 3 Flash Preview
+deep-research-pro-preview-12-2025|Deep Research Pro Preview (Dec-12-2025)
-gemini-2.0-flash-live-001|Gemini 2.0 Flash 001
-gemini-live-2.5-flash-preview|Gemini Live 2.5 Flash Preview
-gemini-2.5-flash-live-preview|Gemini 2.5 Flash Live Preview
+gemini-2.5-flash-native-audio-preview-12-2025|Gemini 2.5 Flash Native Audio Preview 12-2025
```
```diff:2025/11/21 と 2025/12/07 の差分
-gemini-2.5-pro-preview-03-25|Gemini 2.5 Pro Preview 03-25
-gemini-2.5-pro-preview-05-06|Gemini 2.5 Pro Preview 05-06
-gemini-2.5-pro-preview-06-05|Gemini 2.5 Pro Preview
-gemini-2.0-flash-thinking-exp-01-21|Gemini 2.5 Flash Preview 05-20
-gemini-2.0-flash-thinking-exp|Gemini 2.5 Flash Preview 05-20
-gemini-2.0-flash-thinking-exp-1219|Gemini 2.5 Flash Preview 05-20
-learnlm-2.0-flash-experimental|LearnLM 2.0 Flash Experimental
```
```diff:2025/11/19 と 2025/11/21 の差分
+gemini-3-pro-image-preview|Nano Banana Pro
+nano-banana-pro-preview|Nano Banana Pro
```
```diff:2025/09/06 と 2025/11/19 の差分
-gemini-1.5-pro-latest|Gemini 1.5 Pro Latest
-gemini-1.5-pro-002|Gemini 1.5 Pro 002
-gemini-1.5-pro|Gemini 1.5 Pro
-gemini-1.5-flash-latest|Gemini 1.5 Flash Latest
-gemini-1.5-flash|Gemini 1.5 Flash
-gemini-1.5-flash-002|Gemini 1.5 Flash 002
-gemini-1.5-flash-8b|Gemini 1.5 Flash-8B
-gemini-1.5-flash-8b-001|Gemini 1.5 Flash-8B 001
-gemini-1.5-flash-8b-latest|Gemini 1.5 Flash-8B Latest
-gemini-2.0-flash-preview-image-generation|Gemini 2.0 Flash Preview Image Generation
+gemini-2.5-flash-image|Nano Banana
-gemini-2.5-flash-preview-05-20|Gemini 2.5 Flash Preview 05-20
+gemini-2.5-flash-preview-09-2025|Gemini 2.5 Flash Preview Sep 2025
-gemini-2.5-flash-lite-preview-06-17|Gemini 2.5 Flash-Lite Preview 06-17
+gemini-2.5-flash-lite-preview-09-2025|Gemini 2.5 Flash-Lite Preview Sep 2025
+gemini-2.5-computer-use-preview-10-2025|Gemini 2.5 Computer Use Preview 10-2025
+gemini-3-pro-preview|Gemini 3 Pro Preview
+gemini-flash-latest|Gemini Flash Latest
+gemini-flash-lite-latest|Gemini Flash-Lite Latest
+gemini-pro-latest|Gemini Pro Latest
+gemini-robotics-er-1.5-preview|Gemini Robotics-ER 1.5 Preview
-imagen-3.0-generate-002|Imagen 3.0
-veo-3.0-generate-preview|Veo 3
-veo-3.0-fast-generate-preview|Veo 3 fast
+veo-3.0-generate-001|Veo 3
+veo-3.0-fast-generate-001|Veo 3 fast
+veo-3.1-generate-preview|Veo 3.1
+veo-3.1-fast-generate-preview|Veo 3.1 fast
-gemini-2.5-flash-preview-native-audio-dialog|Gemini 2.5 Flash Preview Native Audio Dialog
-gemini-2.5-flash-exp-native-audio-thinking-dialog|Gemini 2.5 Flash Exp Native Audio Thinking Dialog
+gemini-2.5-flash-native-audio-latest|Gemini 2.5 Flash Native Audio Latest
+gemini-2.5-flash-native-audio-preview-09-2025|Gemini 2.5 Flash Native Audio Preview 09-2025
```
```diff:2025/08/24 と 2025/09/06 の差分
+gemini-2.5-flash-image-preview|Nano Banana
```
```diff:2025/08/01 と 2025/08/24 の差分
-imagen-3.0-generate-002|Imagen 3.0 002 model
+imagen-3.0-generate-002|Imagen 3.0
+imagen-4.0-generate-001|Imagen 4
+imagen-4.0-ultra-generate-001|Imagen 4 Ultra
+imagen-4.0-fast-generate-001|Imagen 4 Fast
```
```diff:2025/06/28 と 2025/08/01 の差分
-gemini-1.0-pro-vision-latest|Gemini 1.0 Pro Vision
-gemini-pro-vision|Gemini 1.0 Pro Vision
-gemini-2.5-flash-preview-04-17|Gemini 2.5 Flash Preview 04-17
-gemini-2.5-flash-preview-04-17-thinking|Gemini 2.5 Flash Preview 04-17 for cursor testing
-gemini-2.0-flash-thinking-exp-01-21|Gemini 2.5 Flash Preview 04-17
+gemini-2.0-flash-thinking-exp-01-21|Gemini 2.5 Flash Preview 05-20
-gemini-2.0-flash-thinking-exp|Gemini 2.5 Flash Preview 04-17
+gemini-2.0-flash-thinking-exp|Gemini 2.5 Flash Preview 05-20
-gemini-2.0-flash-thinking-exp-1219|Gemini 2.5 Flash Preview 04-17
+gemini-2.0-flash-thinking-exp-1219|Gemini 2.5 Flash Preview 05-20
+gemini-2.5-flash-lite|Gemini 2.5 Flash-Lite
+gemini-embedding-001|Gemini Embedding 001
+veo-3.0-generate-preview|Veo 3
+veo-3.0-fast-generate-preview|Veo 3 fast
+gemini-2.5-flash-live-preview|Gemini 2.5 Flash Live Preview
```
```diff:2025/06/22 と 2025/06/28 の差分
-gemini-2.5-pro-exp-03-25|Gemini 2.5 Pro Experimental 03-25
+gemma-3n-e2b-it|Gemma 3n E2B
+imagen-4.0-generate-preview-06-06|Imagen 4 (Preview)
+imagen-4.0-ultra-generate-preview-06-06|Imagen 4 Ultra (Preview)
+gemini-live-2.5-flash-preview|Gemini Live 2.5 Flash Preview
```
```diff:2025/06/18 と 2025/06/22 の差分
-gemini-2.5-flash-preview-native-audio-dialog-rai-v3|Gemini 2.5 Flash Preview Native Audio Dialog RAI v3
```
```diff:2025/06/17 と 2025/06/18 の差分
+gemini-2.5-flash|Gemini 2.5 Flash
+gemini-2.5-flash-lite-preview-06-17|Gemini 2.5 Flash Lite Preview 06-17
+gemini-2.5-pro|Gemini 2.5 Pro
```
```diff:2025/06/06 と 2025/06/17 の差分
-gemini-1.5-pro-001|Gemini 1.5 Pro 001
-gemini-1.5-flash-001|Gemini 1.5 Flash 001
-gemini-1.5-flash-001-tuning|Gemini 1.5 Flash 001 Tuning
-gemini-1.5-flash-8b-exp-0827|Gemini 1.5 Flash 8B Experimental 0827
-gemini-1.5-flash-8b-exp-0924|Gemini 1.5 Flash 8B Experimental 0924
```
```diff:2025/05/21 と 2025/06/06 の差分
+gemini-2.5-pro-preview-06-05|Gemini 2.5 Pro Preview
+veo-2.0-generate-001|Veo 2
+gemini-2.5-flash-preview-native-audio-dialog-rai-v3|Gemini 2.5 Flash Preview Native Audio Dialog RAI v3
```
```diff:2025/05/16 と 2025/05/21 の差分
-chat-bison-001|PaLM 2 Chat (Legacy)
-text-bison-001|PaLM 2 (Legacy)
+gemini-2.5-flash-preview-05-20|Gemini 2.5 Flash Preview 05-20
+gemini-2.5-flash-preview-tts|Gemini 2.5 Flash Preview TTS
+gemini-2.5-pro-preview-tts|Gemini 2.5 Pro Preview TTS
+gemini-2.5-flash-preview-native-audio-dialog|Gemini 2.5 Flash Preview Native Audio Dialog
+gemini-2.5-flash-exp-native-audio-thinking-dialog|Gemini 2.5 Flash Exp Native Audio Thinking Dialog
+gemma-3n-e4b-it|Gemma 3n E4B
```
```diff:2025/05/09 と 2025/05/16 の差分
-learnlm-1.5-pro-experimental|LearnLM 1.5 Pro Experimental
```
```diff:2025/05/07 と 2025/05/09 の差分
+gemini-2.0-flash-preview-image-generation|Gemini 2.0 Flash Preview Image Generation
```
```diff:2025/05/04 と 2025/05/07 の差分
+gemini-2.5-flash-preview-04-17-thinking|Gemini 2.5 Flash Preview 04-17 for cursor testing
+gemini-2.5-pro-preview-05-06|Gemini 2.5 Pro Preview 05-06
```
```diff:2025/04/19 と 2025/05/04 の差分
-gemini-2.0-flash-thinking-exp|Gemini 2.0 Flash Thinking Experimental 01-21
+gemini-2.0-flash-thinking-exp|Gemini 2.5 Flash Preview 04-17
-gemini-2.0-flash-thinking-exp-1219|Gemini 2.0 Flash Thinking Experimental
+gemini-2.0-flash-thinking-exp-1219|Gemini 2.5 Flash Preview 04-17
-gemini-2.0-flash-thinking-exp-01-21|Gemini 2.0 Flash Thinking Experimental 01-21
+gemini-2.0-flash-thinking-exp-01-21|Gemini 2.5 Flash Preview 04-17
```
```diff:2025/04/10 と 2025/04/19 の差分
+gemini-2.5-flash-preview-04-17|Gemini 2.5 Flash Preview 04-17
+learnlm-2.0-flash-experimental|LearnLM 2.0 Flash Experimental
```
```diff:2025/04/05 と 2025/04/10 の差分
+gemini-2.0-flash-live-001|Gemini 2.0 Flash 001
```
```diff:2025/04/04 と 2025/04/05 の差分
+gemini-2.5-pro-preview-03-25|Gemini 2.5 Pro Preview 03-25
```
```diff:2025/03/31 と 2025/04/04 の差分
+gemma-3-1b-it|Gemma 3 1B
+gemma-3-4b-it|Gemma 3 4B
+gemma-3-12b-it|Gemma 3 12B
```
```diff:2025/03/17 と 2025/03/31 の差分
+gemini-2.5-pro-exp-03-25|Gemini 2.5 Pro Experimental 03-25
```
```diff:2025/03/13 と 2025/03/17 の差分
+gemini-2.0-flash-exp-image-generation|Gemini 2.0 Flash (Image Generation) Experimental
```
```diff:2025/02/28 と 2025/03/13 の差分
+gemma-3-27b-it|Gemma 3 27B
+gemini-embedding-exp|Gemini Embedding Experimental
+gemini-embedding-exp-03-07|Gemini Embedding Experimental 03-07
```
```diff:2025/02/06 と 2025/02/28 の差分
-gemini-1.0-pro-latest|Gemini 1.0 Pro Latest
-gemini-1.0-pro|Gemini 1.0 Pro
-gemini-1.0-pro-001|Gemini 1.0 Pro 001 (Tuning)
-gemini-pro|Gemini 1.0 Pro
-gemini-exp-1206|Gemini 2.0 Pro Experimental
+gemini-2.0-flash-lite|Gemini 2.0 Flash-Lite
+gemini-2.0-flash-lite-001|Gemini 2.0 Flash-Lite 001
+gemini-exp-1206|Gemini Experimental 1206
+imagen-3.0-generate-002|Imagen 3.0 002 model
```
```diff:2025/01/29 と 2025/02/06 の差分
-gemini-1.5-flash-exp-0827|Gemini Experimental 1206
-gemini-1.5-pro-exp-0801|Gemini Experimental 1206
-gemini-1.5-pro-exp-0827|Gemini Experimental 1206
-gemini-exp-1114|Gemini Experimental 1206
-gemini-exp-1121|Gemini Experimental 1206
-gemini-exp-1206|Gemini Experimental 1206
+gemini-2.0-flash-lite-preview|Gemini 2.0 Flash-Lite Preview
+gemini-2.0-flash-lite-preview-02-05|Gemini 2.0 Flash-Lite Preview 02-05
+gemini-2.0-flash|Gemini 2.0 Flash
+gemini-2.0-flash-001|Gemini 2.0 Flash 001
+gemini-2.0-pro-exp|Gemini 2.0 Pro Experimental
+gemini-2.0-pro-exp-02-05|Gemini 2.0 Pro Experimental 02-05
+gemini-exp-1206|Gemini 2.0 Pro Experimental
```
```diff:2024/12/20 と 2025/01/29 の差分
-gemini-2.0-flash-thinking-exp|Gemini 2.0 Flash Thinking Experimental
+gemini-2.0-flash-thinking-exp|Gemini 2.0 Flash Thinking Experimental 01-21
+gemini-2.0-flash-thinking-exp-01-21|Gemini 2.0 Flash Thinking Experimental 01-21
```
```diff:2024/12/19 と 2024/12/20 の差分
-gemini-exp-1114|Gemini Experimental 1121
+gemini-exp-1114|Gemini Experimental 1206
-gemini-exp-1121|Gemini Experimental 1121
+gemini-exp-1121|Gemini Experimental 1206
+gemini-2.0-flash-thinking-exp|Gemini 2.0 Flash Thinking Experimental
+gemini-2.0-flash-thinking-exp-1219|Gemini 2.0 Flash Thinking Experimental
```
```diff:2024/12/12 と 2024/12/19 の差分
-gemini-1.5-pro-exp-0801|Gemini 1.5 Pro Experimental 0801
+gemini-1.5-pro-exp-0801|Gemini Experimental 1206
```
```diff:2024/12/07 と 2024/12/12 の差分
+gemini-2.0-flash-exp|Gemini 2.0 Flash Experimental
```
```diff:2024/11/22 と 2024/12/07 の差分
-gemini-1.5-flash-exp-0827|Gemini 1.5 Flash Experimental 0827
+gemini-1.5-flash-exp-0827|Gemini Experimental 1206
-gemini-1.5-pro-exp-0827|Gemini 1.5 Pro Experimental 0827
+gemini-1.5-pro-exp-0827|Gemini Experimental 1206
-gemini-exp-1114|Gemini Experimental 1114
+gemini-exp-1114|Gemini Experimental 1121
+gemini-exp-1206|Gemini Experimental 1206
```
```diff:2024/11/11 と 2024/11/22 の差分
+gemini-exp-1114|Gemini Experimental 1114
+gemini-exp-1121|Gemini Experimental 1121
+learnlm-1.5-pro-experimental|LearnLM 1.5 Pro Experimental
```

# 2024/11/11

name|display_name
----|----
chat-bison-001|PaLM 2 Chat (Legacy)
text-bison-001|PaLM 2 (Legacy)
embedding-gecko-001|Embedding Gecko
gemini-1.0-pro-latest|Gemini 1.0 Pro Latest
gemini-1.0-pro|Gemini 1.0 Pro
gemini-pro|Gemini 1.0 Pro
gemini-1.0-pro-001|Gemini 1.0 Pro 001 (Tuning)
gemini-1.0-pro-vision-latest|Gemini 1.0 Pro Vision
gemini-pro-vision|Gemini 1.0 Pro Vision
gemini-1.5-pro-latest|Gemini 1.5 Pro Latest
gemini-1.5-pro-001|Gemini 1.5 Pro 001
gemini-1.5-pro-002|Gemini 1.5 Pro 002
gemini-1.5-pro|Gemini 1.5 Pro
gemini-1.5-pro-exp-0801|Gemini 1.5 Pro Experimental 0801
gemini-1.5-pro-exp-0827|Gemini 1.5 Pro Experimental 0827
gemini-1.5-flash-latest|Gemini 1.5 Flash Latest
gemini-1.5-flash-001|Gemini 1.5 Flash 001
gemini-1.5-flash-001-tuning|Gemini 1.5 Flash 001 Tuning
gemini-1.5-flash|Gemini 1.5 Flash
gemini-1.5-flash-exp-0827|Gemini 1.5 Flash Experimental 0827
gemini-1.5-flash-002|Gemini 1.5 Flash 002
gemini-1.5-flash-8b|Gemini 1.5 Flash-8B
gemini-1.5-flash-8b-001|Gemini 1.5 Flash-8B 001
gemini-1.5-flash-8b-latest|Gemini 1.5 Flash-8B Latest
gemini-1.5-flash-8b-exp-0827|Gemini 1.5 Flash 8B Experimental 0827
gemini-1.5-flash-8b-exp-0924|Gemini 1.5 Flash 8B Experimental 0924
embedding-001|Embedding 001
text-embedding-004|Text Embedding 004
aqa|Model that performs Attributed Question Answering.
