---
coediting: false
comments_count: 0
created_at: '2023-11-19T21:35:53+09:00'
id: 7f9c8ea1a4e380c02af1
likes_count: 2
private: false
reactions_count: 0
stocks_count: 0
tags:
- name: Python
  versions: []
- name: ChatGPT
  versions: []
- name: Bard
  versions: []
title: AI ログの取得補助
updated_at: '2025-05-07T04:01:07+09:00'
url: https://qiita.com/7shi/items/7f9c8ea1a4e380c02af1
slide: false
---

ChatGPT や Bard などでは個別のチャットのログ全体を Markdown で取得することができないようです。ChatGPT では全ログをエクスポートすることはできますが、個別ログの取得に使うのは非効率です。

スクレイピング的なことをすると問題になるかもしれないため、ログのコピーは手動で行って、スクリプトでクリップボードを監視することでペーストせずに自動的に記録してみました。

この方法は基本的に手動のためあまり省力化にはなっていませんが、汎用性があるので Bing AI や Claude などでも使えます。

# 追記 2025/5/6

pyperclip で API が変更になったため、スクリプトを修正しました。

https://qiita.com/7shi/items/9e49ff81ceb1196f73a4

記事を書いた当初はログ全体を取得するのに使っていましたが、長いログから選択的に必要な部分だけ抽出するために使うようになりました。

ログ全体を取得するのであれば Obsidian Web Clipper を推奨します。（by @karaage0703 さん）

https://zenn.dev/karaage0703/articles/52c3e016653003

# 準備

Python を使用します。pip などで [pyperclip](https://github.com/asweigart/pyperclip/tree/master) をインストールしてください。

# コード

```python:copy_log.py
import sys, os, re, io, time, pyperclip

if len(sys.argv) != 2:
    print(f"Usage: python {sys.argv[0]} file")
    sys.exit(1)

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

def waitForNewPasteLines():
    ret = waitForNewPaste().replace("\r\n", "\n").split("\n")
    while ret and not ret[-1]:
        ret.pop()
    return ret

file = sys.argv[1]
num = 1
while True:
    print("prompt?")
    p = waitForNewPasteLines()
    print("response?")
    r = waitForNewPasteLines()
    with io.StringIO() as sio:
        if os.path.exists(file):
            print(file=sio)
        print("##", num, file=sio)
        num += 1
        print(file=sio)
        for line in p:
            print("    " + line, file=sio)
        print(file=sio)
        code = False
        for line in r:
            if line.startswith("```"):
                code = not code
            if not code and (m := re.match(r"#+(.*)", line)):
                print("**", m.group(1).strip(), "**" ,sep="", file=sio)
            else:
                print(line, file=sio)
        with open(file, "ab") as f:
            f.write(sio.getvalue().encode("utf_8"))
```

# 使用方法

```sh
python copy_log.py log.md
```

プロンプトを手動で選択してコピーします。返答はクリップボードアイコンでコピーします。これを繰り返します。

プロンプトと返答をセットとして、随時ログファイルに追記していきます。終了時は [Ctrl]+[C] でスクリプトを強制終了させれば、そこまでのログは残ります。

GitHub に置くことも考慮して、ログは改行コードを LF に変換しています。

:::note info
WSL で使用するときは、Windows 側に Python をインストールしておいて、`python.exe` で呼び出した方が安定します。
:::

# 関連記事

Bard では公開リンクに期限があります。

https://qiita.com/7shi/items/3de830afa69add8a705c

ログを期間制限なしで公開したいときは、今回のスクリプトで Markdown 化して GitHub に置くような運用を行っています。

ChatGPT では共有リンクに明確な期限は示されませんが、Markdown 化しておくと何かと便利なため、同様に処理しています。
