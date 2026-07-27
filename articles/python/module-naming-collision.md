---
coediting: false
comments_count: 3
created_at: '2020-04-30T17:03:47+09:00'
id: 9c15e2aca88bd40eed2a
likes_count: 58
private: false
reactions_count: 0
stocks_count: 26
tags:
- name: Python
  versions: []
title: Pythonでファイル名が悪くてimportでハマった
updated_at: '2020-10-24T19:40:50+09:00'
url: https://qiita.com/7shi/items/9c15e2aca88bd40eed2a
slide: false
---

ライブラリをちょっと試そうとして、import したいモジュールと同じ名前を付けてハマりました。常識なのかもしれませんが、知らなかったのでメモしておきます。

# エラー

math モジュールを試したくて、math.py というファイルを書いたとします。

```python:math.py
import math
print(math.pi)
```

これを実行するとエラーになります。

```text:実行結果
$ python math.py
Traceback (most recent call last):
  File "math.py", line 1, in <module>
    import math
  File "/home/xxxx/math.py", line 2, in <module>
    print(math.pi)
AttributeError: partially initialized module 'math' has no attribute 'pi' (most likely due to a circular import)
```

# 自分自身を循環参照

原因はエラーに書いてあるように自分自身を import して循環してしまったことです。

> (most likely due to a circular import)

すぐには分からなかったので、適当に print を入れたりしてみました。

```python:math.py
print("math")
import math
print(math.pi)
```
```text:実行結果
$ python math.py
math
math
Traceback (most recent call last):
  File "math.py", line 2, in <module>
    import math
  File "/home/xxxx/math.py", line 3, in <module>
    print(math.pi)
AttributeError: partially initialized module 'math' has no attribute 'pi' (most likely due to a circular import)
```

`math` が2回表示されています。これでようやく、自分自身を参照していることが分かりました。

同じファイルの2回目の import は無視されるので先に進んで、`math.pi` がないことからエラーになります。

# 結論

ファイル名を変えれば動きます。import の対象と同じファイル名は避けましょう。
