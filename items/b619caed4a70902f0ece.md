---
coediting: false
comments_count: 0
created_at: '2020-06-01T04:58:48+09:00'
id: b619caed4a70902f0ece
likes_count: 5
private: false
reactions_count: 0
stocks_count: 2
tags:
- name: Python
  versions: []
- name: bzip2
  versions: []
title: Pythonでマルチストリームbzip2を逐次展開する
updated_at: '2020-06-09T15:23:48+09:00'
url: https://qiita.com/7shi/items/b619caed4a70902f0ece
slide: false
---

Python でマルチストリームと呼ばれる形式の bzip2 圧縮ファイルを効率的に展開する方法を調べます。

この記事には .NET Framework 版があります。

* [.NET Frameworkのbzip2ライブラリを調査](https://qiita.com/7shi/items/235328dbdc5c0c85edcb)

# マルチストリーム

個別に bzip2 で圧縮して連結したデータをマルチストリームと呼びます。

```text:作成例
$ echo -n hello | bzip2 > a.bz2
$ echo -n world | bzip2 > b.bz2
$ cat a.bz2 b.bz2 > ab.bz2
```

`bzcat` などのコマンドでそのまま扱えます。

```text
$ bzcat ab.bz2
helloworld
```

並列圧縮の [pbzip2](https://launchpad.net/pbzip2/) や Wikipedia のダンプなどで使用されます。

# bz2 モジュール

Python の bz2 モジュールはバージョン 3.3 からマルチストリーム（複数のストリーム）をサポートしました。

* [bz2 --- bzip2 圧縮のサポート](https://docs.python.org/ja/3/library/bz2.html)

> バージョン 3.3 で変更: 'a' (追記) モードが追加され、複数のストリームの読み込みがサポートされました。

以下、このドキュメントを引用しながら進めます。

# 一括展開

bz2 ファイルを `bz2.open()` で開けば、展開されたデータが読み込めます。

デフォルトがバイナリモードのため、テキスト読み取りでは `rt` を指定します。

> 引数 mode には、バイナリモード用に `'r'`、`'rb'`、`'w'`、`'wb'`、`'x'`、`'xb'`、`'a'`、あるいは `'ab'`、テキストモード用に `'rt'`、`'wt'`、`'xt'`、あるいは `'at'` を指定できます。デフォルトは `'rb'` です。

マルチストリームの例として作った ab.bz2 の展開を試みます。

```python
import bz2
with bz2.open("ab.bz2", "rt", encoding="utf-8") as f:
    print(f.read())
```
```text:実行結果
helloworld
```

すべてのストリームが一括で展開されました。

# 逐次展開

マルチストリームを逐次的に展開する場合、BZ2Decompressor を使います。

> `BZ2Decompressor` クラスを用いて、複数のストリームからなるデータを展開する場合は、それぞれのストリームについてデコンプレッサオブジェクトを用意してください。

`BZ2Decompressor` の処理フローは次のようになります。インスタンスごとに 1 ストリームを処理します。事前に圧縮データのストリームの切れ目が分からなくても、未処理のデータを回収できる仕組みです。

1. インスタンスを作成: `decompressor = BZ2Decompressor()`
2. 圧縮データを渡して展開: `bytes = decompressor.decompress(data)`
3. ストリームの終端までしかデータは展開されないため、未処理のデータがないか `decompressor.unused_data` を確認。
4. 未処理のデータがあれば、1.に戻って次のストリームを展開。

これを実装します。

```python
import bz2
with open("ab.bz2", "rb") as f:
    data = f.read()
while data:
    decompressor = bz2.BZ2Decompressor()
    bytes = decompressor.decompress(data)
    data  = decompressor.unused_data
    print(bytes.decode("utf-8"))
```
```text:実行結果
hello
world
```

ストリームごとに逐次展開できました。

# Wikipedia

巨大なファイルの逐次展開を試みます。

Wikipedia のダンプデータがマルチストリームの巨大な bz2 ファイルです。全体を展開しなくてもデータを部分的に取り出せるようにストリームで分割されています。

* [Wikipedia:データベースダウンロード - Wikipedia](https://ja.wikipedia.org/wiki/Wikipedia:%E3%83%87%E3%83%BC%E3%82%BF%E3%83%99%E3%83%BC%E3%82%B9%E3%83%80%E3%82%A6%E3%83%B3%E3%83%AD%E3%83%BC%E3%83%89)

日本語版だとあまりにも巨大過ぎるため、サイズが 1/100 ほどのアイスランド語版を使用します。

* <https://dumps.wikimedia.org/iswiki/>

記事執筆時点で入手可能な2020年5月1日版より、以下のファイルを使用します。

* iswiki-20200501-pages-articles-multistream.xml.bz2 45.7 MB

※ ファイルサイズは統計を見て当たりを付けました。

* [Wikipedia:全言語版の統計 - Wikipedia](https://ja.wikipedia.org/wiki/Wikipedia:%E5%85%A8%E8%A8%80%E8%AA%9E%E7%89%88%E3%81%AE%E7%B5%B1%E8%A8%88)

## 全体読み込み

<font color="red">**【注意】**</font>このセクションのコードは実験用です。遅いため実用には適しません。

先ほどの ab.bz2 と同じように、最初に圧縮ファイル全体を読み込んでストリームを逐次展開します。

内容が多過ぎるため表示はしないで、ストリーム数と展開後のバイト数を数えます。

```python:multistream-1.py
import bz2
target = "iswiki-20200501-pages-articles-multistream.xml.bz2"
with open(target, "rb") as f:
    data = f.read()
streams = 0
bytes   = 0
while data:
    decompressor = bz2.BZ2Decompressor()
    streams += 1
    bytes   += len(decompressor.decompress(data))
    data = decompressor.unused_data
print(f"streams: {streams:,}, bytes: {bytes:,}")
```
```text:実行結果
$ time python multistream-1.py
streams: 1,022, bytes: 207,530,810

real    0m22.503s
user    0m9.531s
sys     0m12.969s
```

## メモリマップ

<font color="red">**【注意】**</font>このセクションのコードは実験用です。遅いため実用には適しません。

比較のため圧縮ファイルをメモリマップしてみます。

【参考】 [mmap --- メモリマップファイル — Python 3 ドキュメント](https://docs.python.org/ja/3/library/mmap.html)

```python:multistream-2.py
import bz2, mmap
target = "iswiki-20200501-pages-articles-multistream.xml.bz2"
with open(target, "rb") as f:
    with mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ) as mm:
        data    = mm
        streams = 0
        bytes   = 0
        while data:
            decompressor = bz2.BZ2Decompressor()
            streams += 1
            bytes   += len(decompressor.decompress(data))
            data = decompressor.unused_data
print(f"streams: {streams:,}, bytes: {bytes:,}")
```
```text:実行結果
$ time python multistream-2.py
streams: 1,022, bytes: 207,530,810

real    0m22.450s
user    0m10.484s
sys     0m11.953s
```

処理時間はほとんど変わりませんでした。

## 逐次読み込み

<font color="red">**【注意】**</font>このセクションのコードは、速度的には実用できます。ただしストリームを逐次展開する必要がなければ、もっと簡単に書けます。

ファイルを一度に読み込まないで、少しずつ読み込みます。

フローがやや複雑になります。decompressor に渡したデータがストリームの終端まで達しているか `eof` で確認して、終端に達していなければ同じインスタンスを使い続けます。

```python:multistream-3.py
import bz2
target  = "iswiki-20200501-pages-articles-multistream.xml.bz2"
streams = 0
bytes   = 0
size    = 1024 * 1024  # 1MB
with open(target, "rb") as f:
    decompressor = bz2.BZ2Decompressor()
    data = b''
    while data or (data := f.read(size)):
        bytes += len(decompressor.decompress(data))
        data = decompressor.unused_data
        if decompressor.eof:
            streams += 1
            decompressor = bz2.BZ2Decompressor()
print(f"streams: {streams:,}, bytes: {bytes:,}")
```
```text:実行結果
$ time python multistream-3.py
streams: 1,022, bytes: 207,530,810

real    0m6.839s
user    0m6.734s
sys     0m0.094s
```

劇的に高速化しました。どうやら今までは展開以外に時間が掛かっていたようです。

`size` を変えて試しましたが、5MB を超えた辺りから明らかに遅くなり始めました。

### データ取得

ジェネレーターによってストリームごとに展開したデータを取得する例です。

```python
import bz2
target = "iswiki-20200501-pages-articles-multistream.xml.bz2"
size = 1024 * 1024  # 1MB
def getstreams():
    with open(target, "rb") as f:
        decompressor = bz2.BZ2Decompressor()
        bytes = b''
        data  = b''
        while data or (data := f.read(size)):
            bytes += decompressor.decompress(data)
            data = decompressor.unused_data
            if decompressor.eof:
                yield bytes
                bytes = b''
                decompressor = bz2.BZ2Decompressor()
lens = [len(bytes) for bytes in getstreams()]
print(f"streams: {len(lens):,}, bytes: {sum(lens):,}")
```

## まとめ

<font color="red">**【注意】**</font>ストリームを逐次展開する必要がなければ、このセクションの一括展開を使用してください。

巨大ファイルをストリームごとに逐次展開する場合、入力する圧縮データも逐次読み込みする必要があります。

`unused_data` のスライス時にデータのコピーが発生するため、一度に巨大なデータを渡すと無駄なコピーが大量に発生するためだと思われます。

比較として、ストリームで区切らずに一括展開します。

```python:multistream-4.py
import bz2
target = "iswiki-20200501-pages-articles-multistream.xml.bz2"
bytes  = 0
size   = 1024 * 1024  # 1MB
with bz2.open(target, "rb") as f:
    while (data := f.read(size)):
        bytes += len(data)
print(f"bytes: {bytes:,}")
```
```text:実行結果
$ time python multistream-4.py
bytes: 207,530,810

real    0m6.685s
user    0m6.594s
sys     0m0.094s
```

逐次展開に比べて多少速いです。Wikipedia のようにストリームに意味がある場合を除けば、逐次展開にあまり意味はなさそうです。

# 関連記事

Wikipedia のダンプについての記事です。

* [Wikipediaのダンプからページを取り出す](https://qiita.com/7shi/items/7a4aa381ec3dc97bd0f2)

多言語辞書 Wiktionary のダンプからデータを抽出する記事です。Wikipedia の関連プロジェクトでダンプの形式は同じです。

* [Wiktionaryの効率的な処理方法を探る](https://qiita.com/7shi/items/e8091f6ac72491ad45a6)

`BZ2Decompressor.decompress()` の翻訳について修正を提案しました。

* <https://github.com/python-doc-ja/python-doc-ja/issues/830>

# 参考

3.3 以前の Python でマルチストリームを扱った記事です。

* [どぶお/Pythonで遊ぼう！/Multiple BZ2を展開する - BioKids Wiki](http://biokids.org/5cc723.html)

pbzip2 の速度を計測した記事です。

* [pbzip2 のインストール（と速度比較メモ）](https://qiita.com/bunzaemon/items/c84a502ff115bee62f8d)
