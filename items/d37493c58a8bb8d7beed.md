---
coediting: false
comments_count: 4
created_at: '2020-06-08T02:24:05+09:00'
id: d37493c58a8bb8d7beed
likes_count: 53
private: false
reactions_count: 0
stocks_count: 36
tags:
- name: Python
  versions: []
- name: JavaScript
  versions: []
title: Pythonでクラス変数とインスタンス変数を取り違えてハマった
updated_at: '2024-12-18T00:39:10+09:00'
url: https://qiita.com/7shi/items/d37493c58a8bb8d7beed
slide: false
---

Python でクラス変数をインスタンス変数と取り違えたため、思ったように動かなくてハマりました。参考までにメモしておきます。

更新履歴：

- 2024.12.05: `@dataclass` について追記
- 2023.11.19: JavaScript との比較を追記

# 概要

よくあるミスのようで、同じ話題を扱った記事があります。

* [Pythonではインスタンス変数をクラス定義直下に書いてはいけない(戒め)](https://qiita.com/kxphotographer/items/60588b7c747094eba9f1)

ポイントはこのコメントに集約されています。

> pythonの挙動は、self.odds を参照するとき、まずインスタンス変数を参照して、なければクラス変数を参照します。

別の記事でも注意喚起されています。

* [Pythonのクラス変数とインスタンス変数 | UX MILK](https://uxmilk.jp/41600)

> クラス変数にアクセスする場合は、特別な理由がない限り「インスタンス.クラス変数」や「self.クラス変数」のようにアクセスすることは避けるべきです。Python ではインスタンス変数をインスタンスオブジェクトから生成することができ、意図せずクラス変数をインスタンス変数で隠蔽してしまうことがあります。

これについて簡単な例で確認します。

# 落とし穴

クラス変数に `self` 経由でアクセスできてしまうので、インスタンス変数を定義したものだと勘違いしてしまいました。

:::note warn
これは再現するコードの全体で、省略はしていません。
:::

```python
class Test:
    a = []  # この定義が問題

    def append(self, value):
        self.a.append(value)

    def clear(self):
        self.a = []

t1 = Test()
t1.append(123)
print(t1.a)

t1.clear()
print(t1.a)
```
```text:実行結果
[123]
[]
```

これを見て、値がクリアできていると思い込みました。実際には、クラス変数が同名のインスタンス変数で覆い隠されているだけです。

他のインスタンスを作ると、`123` を追加した状態のクラス変数が見えます。

```python
t2 = Test()
print(t2.a)
```
```text:実行結果
[123]
```

実際にハマったのは何度も `clear` を呼ぶようなプログラムでした。挙動がおかしいことには気付いたものの、インスタンス生成直後の状態には注意が向かずに、原因究明が遅れました。

# 対策

クラスの直下での定義はクラス変数になります。インスタンス変数はコンストラクタで初期化しましょう。

```python
class Test:
    def __init__(self):
        self.a = []
```

# 追記: `@dataclass`

Python 3.7からは `@dataclass` デコレーターが導入されました。`@dataclass` を指定したクラスでは、型アノテーションを付ければインスタンス変数として扱われます。

```python
from dataclasses import dataclass

@dataclass
class Test:
    a: list  # インスタンス変数
```

## ミュータブルなデフォルト値の扱い

デフォルト値に `list` を設定しようとするとエラーになります。

```python
from dataclasses import dataclass

@dataclass
class Test:
    a: list = []
```
```text:エラー
ValueError: mutable default <class 'list'> for field a is not allowed: use default_factory
```

以下のように記述する必要があります。

```python
from dataclasses import dataclass, field

@dataclass
class Test:
    a: list = field(default_factory=list)
```

関数の引数にデフォルト値として `list` を設定することで問題が発生しますが、それと同種の問題を避けるための仕様だと思われます。

https://qiita.com/studio_haneya/items/6fb61ae12e8416eedcf3

## 裏側のクラス変数

`@dataclass` は型アノテーションのある変数を特別に扱います。これらの変数は自動生成される `__init__` でインスタンス変数として初期化されるため、実際にはクラス変数をインスタンス変数で隠蔽するという状況になっています。

挙動を確認します。

```py
>>> @dataclass
... class Test:
...     a: int = 1
...
>>> t1 = Test()
>>> t2 = Test(5)
>>> t1.a
1
>>> t1.a = 9
>>> t2.a
5
>>> Test.a
1
```

:::note warn
裏側にクラス変数が存在することを意識すると逆に混乱を招く気もしますが、記事の流れから言及しました。
:::

# JavaScript

JavaScript ではクラスの直下で定義するとインスタンス変数になります。Python と同時に扱っていると混乱しやすいので注意が必要です。

:::note alert
私が Python でインスタンス変数を書いたつもりになっていたのも、言語仕様を取り違えたことによる混乱が原因です。
:::

```js
class Test {
    a = [];  // インスタンス変数

    append(value) {
        this.a.push(value);
    }

    clear() {
        this.a = [];
    }
}
```
```js:REPL で実行 (Node.js)
> t1 = new Test()
Test { a: [] }
> t1.append(123)
undefined
> t1.a
[ 123 ]
> t1.clear()
undefined
> t1.a
[]
> t2 = new Test()
Test { a: [] }
> t2.a
[]
```

JavaScript ではクラス変数には `static` を付けます。

```js
class Test {
    static a = [];  // クラス変数

    append(value) {
        this.a.push(value);
    }

    clear() {
        this.a = [];
    }
}
```

クラス変数には `this` 経由でアクセスできないため `this.a` は `undefined` となり、`append` はエラーになります。

```js:REPL で実行 (Node.js)
> t1 = new Test()
Test {}
> t1.append(123)
Uncaught TypeError: Cannot read properties of undefined (reading 'push')
    at Test.append (REPL11:5:16)
> t1.a
undefined
> Test.a
[]
```

インスタンス変数は動的に定義できるので、先に `clear` を呼べば `append` できます。

```js:REPL で実行 (Node.js)
> t1.clear()
undefined
> t1.append(123)
undefined
> t1.a
[ 123 ]
```

:::note warn
Python と JavaScript を同時に扱う際には、インスタンス変数とクラス変数の仕様の違いに注意しましょう。
:::

# 参考

https://zenn.dev/yosemat/books/1e021f1745566f
