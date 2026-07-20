---
coediting: false
comments_count: 0
created_at: '2025-03-22T18:56:24+09:00'
id: 9e49ff81ceb1196f73a4
likes_count: 0
private: false
reactions_count: 0
stocks_count: 0
tags:
- name: Python
  versions: []
- name: clipboard
  versions: []
- name: pyperclip
  versions: []
title: pyperclip でクリップボードの監視機能がなくなった
updated_at: '2025-05-06T15:35:33+09:00'
url: https://qiita.com/7shi/items/9e49ff81ceb1196f73a4
slide: false
---

pyperclip でクリップボードの監視機能 `waitForPaste`, `waitForNewPaste` がなくなったことに気付きました。自前でポーリングするようにとのことです。

https://github.com/asweigart/pyperclip/issues/272

# 自前実装

上記 Issue のコードに少し手を加えました。

```python
import pyperclip, time

def waitForNewPaste(timeout=0):
    current = pyperclip.paste()
    start = time.monotonic()
    while True:
        time.sleep(0.1)
        text = pyperclip.paste()
        if text != current:
            return text
        if timeout > 0 and time.monotonic() - start > timeout:
            raise pyperclip.PyperclipTimeoutException(
                f"waitForPaste() timed out after {timeout} seconds.")
```

クリップボードの中身が変化するのを待ちます。`time.monotonic()` は OS での時刻の再設定に影響を受けない経過時間を返します。

:::note warn
同じ内容をコピーしてもスルーされます。これはやや不自然に感じますが、実装が簡単で、過去の実装もこういう挙動でした。
:::

# 参考

監視機能が存在していた頃の説明です。

https://note.nkmk.me/python-pyperclip-usage/

> `pyperclip.waitForPaste()`を実行するとクリップボードの中身が空の場合は待機状態になり、新しいテキストがコピーされるとそれを返す。

> `pyperclip.waitForNewPaste()`を実行すると待機状態になり、新しいテキストがコピーされる（= クリップボードのテキストが変更される）とそれを返す。

# 関連記事

使用例です。

https://qiita.com/7shi/items/7f9c8ea1a4e380c02af1
