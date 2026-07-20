---
coediting: false
comments_count: 0
created_at: '2020-04-30T19:54:03+09:00'
id: a4c82a48fdcc113815f1
likes_count: 2
private: false
reactions_count: 0
stocks_count: 3
tags:
- name: Python
  versions: []
- name: wav
  versions: []
- name: wave
  versions: []
- name: WSL
  versions: []
title: WSLからWAVEファイルを再生する
updated_at: '2020-04-30T20:05:28+09:00'
url: https://qiita.com/7shi/items/a4c82a48fdcc113815f1
slide: false
---

WSL 上で音声ファイルの生成をしていて、コマンドから再生したくなりました。サウンドサーバーを動かすのは大げさだったので、Windows 側の Python で簡単なプログラムを作って、ラッパー経由で呼び出しました。

# ライブラリ

次の記事で、Python のサウンドライブラリが色々と紹介されています。

* [Pythonでサウンドを扱う](https://qiita.com/hisshi00/items/62c555095b8ff15f9dd2)

今回は playsound を使用します。Windows 側の Python に pip でインストールします。

```text:ライブラリのインストール
py.exe -m pip install playsound
```

※ `py.exe` は Windows 側でパスの通った場所（`C:¥WINDOWS`）に置かれているので、`.exe` を付けることで WSL から呼び出せます。

# 本体

playsound は import してファイル名を渡すだけで簡単に使えます。

複数のファイルを指定して、再生中のファイル名を表示する機能を付けました。（`-p` オプション）

```python:winplay.py
import sys, playsound
if len(sys.argv) < 2:
    print("usage: %s [-p] sound [...]" % sys.argv[0])
    print("    -p: show file name")
    exit(1)
argp = 2 if sys.argv[1] == "-p" else 1
args = sys.argv[argp:]
argl = len(args)
format = "[%%%dd/%%d] %%s" % len(str(argl))
for i, arg in enumerate(args):
    if argp > 1: print(format % (i + 1, argl, arg))
    playsound.playsound(arg)
```

# WSL

wintts.py をどこか Windows から見える場所に置きます。次のような簡単なラッパーを書いて、WSL でパスが通っている場所に置いて実行属性を付けます。

```sh:winplay
#!/bin/sh
py.exe 'C:\スクリプト置き場\winplay.py' "$@"
```

これであたかも WSL のコマンドのように使うことができます。

```text:使用例
winplay test.wav
winplay -p *.wav
```

# MP3

MP3 も一応再生できますが、私の環境では再生が途切れるなどの現象が発生しました。

※ 今回は WAVE ファイルが目的のため、調査はしていません。

# 名前について

Windows 側で動かすことを示す狙いで win- という接頭辞を付けました。

実は当初、ライブラリそのまま playsound という名前にしようとしたのですが、import でハマったため取りやめました。

* [Pythonでファイル名が悪くてimportでハマった](https://qiita.com/7shi/items/9c15e2aca88bd40eed2a)

# 関連リンク

今回の手法と同じようなご意見が書かれています。

* [wslから音をならす方法 : プログラミング・メモ](http://m-miya.blog.jp/archives/1073383706.html)

> が、よく考えるとwsl上からWindowsのexeも実行できるので、wavファイルを再生できるexeがあればそれを使えば音ならせるじゃんって。

そこでも言及されていますが、サウンドサーバーを動かす方法があります。

* [Windows Subsystem for Linuxのインストールからmikutterをそれらしく動かすまで - cobodoのブログ](https://cobodo.hateblo.jp/entry/2018/03/31/034144)
* [WSL上で音楽を再生する - xdigit’s diary](https://xdigit.hatenablog.com/entry/2018/11/21/191349)
