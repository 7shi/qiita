---
coediting: false
comments_count: 0
created_at: '2024-12-16T00:18:11+09:00'
id: d8d3ab5371aa9dddcb3e
likes_count: 1
private: false
reactions_count: 0
stocks_count: 1
tags:
- name: Python
  versions: []
- name: XML
  versions: []
- name: XMLParser
  versions: []
title: Python 用簡易プル型 XML パーサー xml7shi
updated_at: '2024-12-17T15:16:01+09:00'
url: https://qiita.com/7shi/items/d8d3ab5371aa9dddcb3e
slide: false
---

xml7shi は、Python で実装された簡易的なプル型 XML パーサーです。標準的な XML 仕様への厳密な準拠よりも、実用的な解析機能の提供に重点を置いています。XML だけでなく HTML も可能な限り解析できるように設計されています。

https://github.com/7shi/xml7shi

# インストール方法

PyPI に登録されているので、pip などからインストールできます。

```sh
pip install xml7shi
```

# 基本的な使い方

`xml7shi.reader()` に対象となる XML の文字列を渡してパーサーのインスタンスを作成します。主に 3 つのメソッドを使用します。

- `read()`: 次のタグまで読み込む
- `find()`: 指定したタグと属性に一致する次の要素を検索
- `each()`: 指定したタグ（空白の場合はすべてのタグ）と属性に一致する要素を反復処理するジェネレーターを返す

`reader` インスタンスは現在の位置や情報を保持しており、以下のプロパティを持ちます。

- `text`: 直前のタグと現在のタグの間にあるテキスト
- `tag`: 現在のタグ名（終了タグは `/` プレフィックス付き）
- `values`: タグの属性を格納した辞書

`read()` メソッドは常に次のタグまで読み進め、その過程で見つかったテキストを `text` プロパティとして提供します。この設計により、読み込んだエレメントの種類を判定する必要がなく、常に一定のパターンで XML を処理できます。

## 使用例

基本的な使用パターンを示します。

```python
import xml7shi

xr = xml7shi.reader('''
<root>
    <list id="1">
        <item>foo</item>
        <item>bar</item>
        <item>baz</item>
    </list>
    <list id="2">
        <item>qux</item>
        <item>quux</item>
        <item/>
    </list>
</root>
''')

# 特定のタグを見つけて処理
if xr.find("list", id="2"):      # <list id="2"> を見つける
    print("list:", xr["id"])     # `id` 属性を表示

# 複数のタグを巡回
for _ in xr.each("item"):        # <item> を順に処理
    if xr.read():                # 次のタグまで読む
        print("item:", xr.text)  # テキストを表示
```
```text:実行結果
list: 2
item: qux
item: quux
item: 
```

`xr` が `<list id="2">` の次の `<item>` を指しているとき、`read()` は次のタグ `</item>` まで読み進めます。

`<item/>` のような自己終了タグは `<item></item>` として扱われるため、間にテキストがあるタグと同じコードで処理できます。

## 細かい挙動

REPL で細かい挙動を確認します。

```python
>>> import xml7shi
```

:::note warn
プロンプト `>>>` の部分は入力しないでください。
:::

### タグ

タグ名は常に小文字として処理され、大文字小文字の区別はありません。これは HTML を想定した仕様です。

```python
>>> xr = xml7shi.reader('<TAG>test</TAG>')
>>> xr.read() and (xr.text, xr.tag, xr.values)
('', 'tag', {})
>>> xr.read() and (xr.text, xr.tag, xr.values)
('test', '/tag', {})
>>> xr.read() and (xr.text, xr.tag, xr.values)
False
```

### 自己終了タグ

自己終了タグ `<tag/>` は、空タグ `<tag></tag>` として扱われます。

```python
>>> xr = xml7shi.reader('<tag/>')
>>> xr.read() and (xr.text, xr.tag, xr.values)
('', 'tag', {})
>>> xr.read() and (xr.text, xr.tag, xr.values)
('', '/tag', {})
>>> xr.read() and (xr.text, xr.tag, xr.values)
False
```

### 属性付きタグ

属性値は引用符の有無にかかわらず処理され、すべて文字列として扱われます。  

```python
>>> xr = xml7shi.reader('<tag a="1" b=2>')
>>> xr.read() and (xr.text, xr.tag, xr.values)
('', 'tag', {'a': '1', 'b': '2'})
>>> xr.read() and (xr.text, xr.tag, xr.values)
False
```

### コメント

コメント `<!-- ... -->` もタグとして扱われます。タグ名が空文字列 `""` となり、コメントの内容は `comment` 属性に保持されます。

```python
>>> xr = xml7shi.reader('<!--foobar--><tag>')
>>> xr.read() and (xr.text, xr.tag, xr.values)
('', '', {'comment': 'foobar'})
>>> xr.read() and (xr.text, xr.tag, xr.values)
('', 'tag', {})
>>> xr.read() and (xr.text, xr.tag, xr.values)
False
```

これらの例が示すように、xml7shi は厳密な XML 仕様への準拠よりも、使いやすさを重視した設計となっています。

## 階層構造

xml7shi は DOM を構築するわけではないため、階層構造は無視してフラットに動作します。

```python:うまく扱えない例
import xml7shi

xr = xml7shi.reader('''
<root>
    <item>foo</item>
    <item>
        <item>bar</item>
        <item>baz</item>
    </item>
    <item>qux</item>
    <item>quux</item>
</root>
''')

for _ in xr.each("item"):
    if xr.read():
        print("item:", xr.text)
```
```text:実行結果
item: foo
item:

item: baz
item: qux
item: quux
```

階層構造を扱うには、再帰的なコードを書く必要があります。

```python:再帰処理の例
def read_items(level = 0):
    while xr.tag != "/item":
        if xr.tag == "item" and xr.read():
            indent = " " * (level * 2)
            print(indent + "item:", xr.text.strip())
            if xr.tag == "item":       # ネスト
                read_items(level + 1)  # 再帰
        if not xr.read():
            break
read_items()
```
```text:実行結果
item: foo
item:
  item: bar
  item: baz
item: qux
item: quux
```

想定されるタグの構造を、ほぼそのままコードに落とし込んでいます。タグが先読みされている想定で、`read_items` では `read` より先にタグのチェックを行っているのがポイントです。

# 誕生秘話

xml7shi の原型は、2000 年頃、XML の前身となった SGML をパースするために誕生しました。処理対象のドキュメントは閉じタグが省略されており、それを効率的に処理するための試行錯誤の結果、このスタイルに落ち着きました。

HTML を処理対象にした場合、閉じタグの書き忘れや文法エラーなどが含まれていると他のパーサーではうまく読み込めないことがあるため、そのようなケースでは現在も有用だと思います。

XML 登場当初に主流だった SAX や DOM を構築するタイプのパーサーとはスタイルが異なりますが、.NET Framework の XmlReader がほぼ同じスタイルとなっており、そのドキュメントでプル型に分類されることを知りました。

https://docs.microsoft.com/ja-jp/previous-versions/dotnet/netframework-1.1/sbw89de7(v=vs.71)

C# や VB.NET でも実装しましたが、仕様がやや異なります。

https://7shi.hateblo.jp/entry/20100527/1274975653

Python で最初に実装したのは Python 2 の時代です。Pure Python と C++ ラッパーの 2 種類があります。

- https://gist.github.com/7shi/3021786

# 関連記事

一般的な Python 用 XML パーサーについては、以下を参照してください。

https://qiita.com/7shi/items/c7608db7a097ddd16be6

プッシュ型・プル型を LLM の外部呼出しに当てはめた記事です。

https://qiita.com/7shi/items/e27866ce51c6b9a0f605
