---
coediting: false
comments_count: 0
created_at: '2020-05-30T22:34:51+09:00'
id: 235328dbdc5c0c85edcb
likes_count: 0
private: false
reactions_count: 0
stocks_count: 2
tags:
- name: Python
  versions: []
- name: F#
  versions: []
- name: mono
  versions: []
- name: bzip2
  versions: []
- name: .NETFramework
  versions: []
title: .NET Frameworkのbzip2ライブラリを調査
updated_at: '2020-06-09T15:20:35+09:00'
url: https://qiita.com/7shi/items/235328dbdc5c0c85edcb
slide: false
---

.NET Framework で bzip2 をサポートするライブラリについて調べます。Python や bzcat と処理速度を比較します。

この記事には Python 版があります。

* [Pythonでマルチストリームbzip2を逐次展開する](https://qiita.com/7shi/items/b619caed4a70902f0ece)

# ライブラリ

bzip2 をサポートする 3 種類のライブラリを見付けました。

1. [SharpZipLib](https://github.com/icsharpcode/SharpZipLib): マネージドコードによる再実装
2. [SharpCompress](https://github.com/adamhathcock/sharpcompress): マネージドコードによる再実装
3. [AR.Compression.BZip2](https://github.com/antrv/bzip2stream) ネイティブライブラリのラッパー

これらのライブラリでのマルチストリームの扱いと展開の所要時間を確認します。

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

【追記】 gzip でも同じことが可能で、以下の記事で調査されています。

* [マルチストリーム GZIP は GZipStream でそのまま読み込める (C#)](https://qiita.com/c-yan/items/fc443c54320bfc587ec7)

# SharpZipLib

複数の圧縮アルゴリズムをサポートしています。

bzip2 の実装は以下にあります。

* [src/ICSharpCode.SharpZipLib/BZip2](https://github.com/icsharpcode/SharpZipLib/tree/master/src/ICSharpCode.SharpZipLib/BZip2)

## 最小構成

bzip2 の展開は、以下の 6 ファイルだけで行えることを確認しました。

* src/ICSharpCode.SharpZipLib/BZip2/BZip2Constants.cs
* src/ICSharpCode.SharpZipLib/BZip2/BZip2Exception.cs
* src/ICSharpCode.SharpZipLib/BZip2/BZip2InputStream.cs
* src/ICSharpCode.SharpZipLib/Checksum/BZip2Crc.cs
* src/ICSharpCode.SharpZipLib/Checksum/IChecksum.cs
* src/ICSharpCode.SharpZipLib/Core/Exceptions/SharpZipBaseException.cs

## テスト

最小構成ではなく、NuGet で取得したライブラリを使用します。

* <https://www.nuget.org/packages/SharpZipLib/>

```shell-session
nuget install SharpZipLib
cp SharpZipLib.1.2.0/lib/net45/ICSharpCode.SharpZipLib.dll .
```

マルチストリームの例として作った ab.bz2 の展開を試みます。

※ Mono には古いバージョンの ICSharpCode.SharpZipLib.dll が取り込まれています。パスを書かないとそちらが参照されるため、NuGet で取得した方の DLL をパス付きで参照します。

```fsharp
#r "SharpZipLib.1.2.0/lib/net45/ICSharpCode.SharpZipLib.dll"
open System.IO
open ICSharpCode.SharpZipLib.BZip2
do
    use fs = new FileStream("ab.bz2", FileMode.Open)
    use bz = new BZip2InputStream(fs)
    use sr = new StreamReader(bz)
    printfn "%s" (sr.ReadToEnd())
```
```実行結果
hello
```

最初のストリームしか処理されません。

BZip2InputStream.cs を眺めてもマルチストリームに対応した作りにはなっていないようなので、逐次的に読み込む必要があります。

※ `IsStreamOwner` が `true` の場合、処理の完了後に渡したストリーム `fs` が閉じられます。デフォルトでは `true` のため `false` を指定します。

```fsharp
#r "SharpZipLib.1.2.0/lib/net45/ICSharpCode.SharpZipLib.dll"
open System.IO
open ICSharpCode.SharpZipLib.BZip2
do
    use fs = new FileStream("ab.bz2", FileMode.Open)
    while fs.Position < fs.Length do
        use bz = new BZip2InputStream(fs, IsStreamOwner = false)
        use sr = new StreamReader(bz)
        printfn "%s" (sr.ReadToEnd())
```
```実行結果
hello
world
```

# SharpCompress

複数の圧縮アルゴリズムをサポートしています。

bzip2 の実装は以下にあります。

* [src/SharpCompress/Compressors/BZip2](https://github.com/adamhathcock/sharpcompress/tree/master/src/SharpCompress/Compressors/BZip2)

このディレクトリは単独で抜き出して使えます。ただ一点、独自に定義している `CompressionMode` が不足しますが、既存の列挙型で代用します。

```csharp:BZip2Stream.cs（追加）
using System.IO.Compression;
```

## 最小構成

bzip2 の展開は、以下の 3 ファイルだけで行えることを確認しました。

* src/SharpCompress/Compressors/BZip2/BZip2Constants.cs
* src/SharpCompress/Compressors/BZip2/CBZip2InputStream.cs
* src/SharpCompress/Compressors/BZip2/CRC.cs

ただし `class CBZip2InputStream` は `internal` になっているため、`public` にする必要があります。

## テスト

最小構成ではなく、NuGet で取得したライブラリを使用します。

* <https://www.nuget.org/packages/SharpCompress/>

```shell-session
nuget install sharpcompress
cp SharpCompress.0.25.1/lib/net46/SharpCompress.dll .
```

マルチストリームの例として作った ab.bz2 の展開を試みます。

※ `BZip2Stream` のコンストラクターの最後の引数は、マルチストリームを読み進めるかどうかのフラグです。

```fsharp
#r "SharpCompress.dll"
open System.IO
open SharpCompress.Compressors
do
    use fs = new FileStream("ab.bz2", FileMode.Open)
    use bz = new BZip2.BZip2Stream(fs, CompressionMode.Decompress, true)
    use sr = new StreamReader(bz)
    printfn "%s" (sr.ReadToEnd())
```
```text:実行結果
helloworld
```

マルチストリームに対するサポートがあるため、一気に最後まで読み進めることができました。

マルチストリームのフラグを `false` にすると、1 つのストリームの終端に達した時点で `fs` が閉じられてしまいます。CBZip2InputStream.cs を見ても、開いたままにすることは想定されていないようです。そのため逐次的に読み進めるには `Dispose` を無視するような小細工をするしかなさそうです。

```fsharp
#r "SharpCompress.dll"
open System.IO
open SharpCompress.Compressors
do
    let mutable ignore = true
    use fs = { new FileStream("ab.bz2", FileMode.Open) with
        override __.Dispose disposing = if not ignore then base.Dispose disposing }
    while fs.Position < fs.Length do
        use bz = new BZip2.BZip2Stream(fs, CompressionMode.Decompress, false)
        use sr = new StreamReader(bz)
        printfn "%s" (sr.ReadToEnd())
    ignore <- false
```
```text:実行結果
hello
world
```

# AR.Compression.BZip2

他のライブラリとは違って bzip2 に特化しています。展開と圧縮は 1 つのクラスで実装されているため、分離して最小構成を調べるのは省略します。

NuGet に登録されています。

* <https://www.nuget.org/packages/AR.Compression.BZip2/>

## ビルド

ライブラリを Mono と共用するには少し手を入れる必要があるため、今回は NuGet は使わずに自分でビルドします。

P/Invoke で指定する DLL のファイル名を変更します。

* [sources/AR.BZip2/BZip2Stream_Interop.cs](https://github.com/antrv/bzip2stream/blob/master/sources/AR.BZip2/BZip2Stream_Interop.cs)

```csharp
10:        private const string DllName = "libbz2";
```

こうすれば Windows では libbz2.dll、WSL では libbz2.so が使用されます。WSL ではカレントディレクトリになくても /usr/lib/libbz2.so が参照されます。

DLL をビルドします。

```shell-session
csc -o -out:AR.Compression.BZip2.dll -t:library -unsafe sources/AR.BZip2/*.cs
```

Windows 用の bzip2 は以下で配布されているバイナリを利用します。

* [Releases · philr/bzip2-windows](https://github.com/philr/bzip2-windows/releases)<br>
  DLL only (libbz2.dll) | 64-bit (x64)

## テスト

マルチストリームの例として作った ab.bz2 の展開を試みます。

※ `BZip2Stream` のコンストラクターの最後の引数が `true` の場合、処理の完了後に渡したストリーム `fs` は開いたままになります。デフォルトでは `false` のため `true` を指定します。SharpZipLib の IsStreamOwner と用途は同じですが指定方法が逆です。マルチストリームとは関係ありません。

```fsharp
#r "AR.Compression.BZip2.dll"
open System.IO
open System.IO.Compression
do
    use fs = new FileStream("ab.bz2", FileMode.Open)
    use bz = new BZip2Stream(fs, CompressionMode.Decompress, false)
    use sr = new StreamReader(bz)
    printfn "%s" (sr.ReadToEnd())
```
```text:実行結果
helloworld
```

すべてのストリームが一括で展開されました。BZip2Stream.cs を見ても、逐次的に読み進めることは想定されていないようです。次で見るベースストリームの扱いと合わせて考えても、改造なしで対応することはできないようです。

# ベースストリームの読み込み

それぞれのライブラリで、渡されたベースストリームの読み込み個所を確認します。

※ .NET での Stream のことをベースストリームと呼んで、bzip2 の意味でのストリームと区別します。

* SharpZipLib: [src/ICSharpCode.SharpZipLib/BZip2/BZip2InputStream.cs](https://github.com/icsharpcode/SharpZipLib/blob/master/src/ICSharpCode.SharpZipLib/BZip2/BZip2InputStream.cs)

```csharp
417:                            thech = baseStream.ReadByte();
```

* SharpCompress: [src/SharpCompress/Compressors/BZip2/CBZip2InputStream.cs](https://github.com/adamhathcock/sharpcompress/blob/master/src/SharpCompress/Compressors/BZip2/CBZip2InputStream.cs)

```csharp
231:            int magic0 = bsStream.ReadByte();
232:            int magic1 = bsStream.ReadByte();
233:            int magic2 = bsStream.ReadByte();
242:            int magic3 = bsStream.ReadByte();
378:                    thech = (char)bsStream.ReadByte();
649:                                    thech = (char)bsStream.ReadByte();
717:                                                thech = (char)bsStream.ReadByte();
814:                                            thech = (char)bsStream.ReadByte();
```

* AR.Compression.BZip2: [sources/AR.BZip2/BZip2Stream.cs](https://github.com/antrv/bzip2stream/blob/master/sources/AR.BZip2/BZip2Stream.cs)

```csharp
  9:             private const int BufferSize = 128 * 1024;
 14:             private readonly byte[] _buffer = new byte[BufferSize];
368:                                             _data.avail_in = _stream.Read(_buffer, 0, ufferSize);
```

SharpZipLib と SharpCompress では必要に応じて `ReadByte` で 1 バイトずつ読み進めています。そのため bzip2 のストリームの区切りで抜けても、オーバーランすることはないようです。`thech` (the character?) という変数名が共通していることから、何か共通の元ネタがあるのかもしれません。（libbz2 にはこの変数名は見当たりません）

AR.Compression.BZip2 では固定長でバッファに読み込んでいます。自前で展開していないため、バイト単位で読み進めることはできないのでしょう。もし bzip2 のストリームごとに処理を区切るとしてもオーバーランしてしまうため、何らかの対策が必要です。

バイトごとに読み進めるのはベースストリームの位置に関して正確ではありますが、処理速度的には不利です。

# 計測

巨大なファイルの展開に掛かる時間を比較します。

Wikipedia 日本語版のダンプデータを使用します。このファイルはマルチストリーム構成です。

* <https://dumps.wikimedia.org/jawiki/><br>
  jawiki-20200501-pages-articles-multistream.xml.bz2 3.0 GB

## 逐次展開

SharpZipLib と SharpCompress でストリームを逐次的に展開します。

```fsharp:test1.fsx
#r "SharpZipLib.1.2.0/lib/net45/ICSharpCode.SharpZipLib.dll"
open System
open System.IO
open ICSharpCode.SharpZipLib.BZip2
let target = "jawiki-20200501-pages-articles-multistream.xml.bz2"
do
    use fs = new FileStream(target, FileMode.Open)
    let buffer = Array.zeroCreate<byte>(1024 * 1024)
    let mutable streams, bytes = 0, 0L
    while fs.Position < fs.Length do
        use bz = new BZip2InputStream(fs, IsStreamOwner = false)
        let mutable len = 1
        while len > 0 do
            len <- bz.Read(buffer, 0, buffer.Length)
            bytes <- bytes + int64 len
        streams <- streams + 1
    Console.WriteLine("streams: {0:#,0}, bytes: {1:#,0}", streams, bytes)
```
```fsharp:test2.fsx
#r "SharpCompress.dll"
open System
open System.IO
open SharpCompress.Compressors
let target = "jawiki-20200501-pages-articles-multistream.xml.bz2"
do
    let mutable ignore = true
    use fs = { new FileStream(target, FileMode.Open) with
        override __.Dispose disposing = if not ignore then base.Dispose disposing }
    let buffer = Array.zeroCreate<byte>(1024 * 1024)
    let mutable streams, bytes = 0, 0L
    while fs.Position < fs.Length do
        use bz = new BZip2.BZip2Stream(fs, CompressionMode.Decompress, false)
        let mutable len = 1
        while len > 0 do
            len <- bz.Read(buffer, 0, buffer.Length)
            bytes <- bytes + int64 len
        streams <- streams + 1
    ignore <- false
    Console.WriteLine("streams: {0:#,0}, bytes: {1:#,0}", streams, bytes)
```
```shell-session:実行結果
$ time ./test1.exe  # SharpZipLib
streams: 24,957, bytes: 13,023,068,290

real    16m2.849s

$ time ./test2.exe  # SharpCompress
streams: 24,957, bytes: 13,023,068,290

real    18m26.520s
```

SharpZipLib の方が速いようです。

## 一括展開

SharpCompress と AR.Compression.BZip2 で全ストリームを一括で展開します。

```fsharp:test3.fsx
#r "SharpCompress.dll"
open System
open System.IO
open SharpCompress.Compressors
let target = "jawiki-20200501-pages-articles-multistream.xml.bz2"
do
    use fs = new FileStream(target, FileMode.Open)
    use bz = new BZip2.BZip2Stream(fs, CompressionMode.Decompress, true)
    let buffer = Array.zeroCreate<byte>(1024 * 1024)
    let mutable bytes, len = 0L, 1
    while len > 0 do
        len <- bz.Read(buffer, 0, buffer.Length)
        bytes <- bytes + int64 len
    Console.WriteLine("bytes: {0:#,0}", bytes)
```
```fsharp:test4.fsx
#r "AR.Compression.BZip2.dll"
open System
open System.IO
open System.IO.Compression
let target = "jawiki-20200501-pages-articles-multistream.xml.bz2"
do
    use fs = new FileStream(target, FileMode.Open)
    use bz = new BZip2Stream(fs, CompressionMode.Decompress, false)
    let buffer = Array.zeroCreate<byte>(1024 * 1024)
    let mutable bytes, len = 0L, 1
    while len > 0 do
        len <- bz.Read(buffer, 0, buffer.Length)
        bytes <- bytes + int64 len
    Console.WriteLine("bytes: {0:#,0}", bytes)
```
```shell-session:実行結果
$ time ./test3.exe  # SharpCompress
bytes: 13,023,068,290

real    17m36.925s

$ time ./test4.exe  # AR.Compression.BZip2
bytes: 13,023,068,290

real    8m23.916s
```

AR.Compression.BZip2 はネイティブライブラリを呼び出しているだけあって速いです。

## Python

Python の bz2 モジュールと比較します。こちらもネイティブのラッパーです。

【参考】[Pythonでマルチストリームbzip2を逐次展開する](https://qiita.com/7shi/items/b619caed4a70902f0ece)

```py:test5.py（逐次）
import bz2
target  = "jawiki-20200501-pages-articles-multistream.xml.bz2"
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
            decompressor = bz2.BZ2Decompressor()
            streams += 1
print(f"streams: {streams:,}, bytes: {bytes:,}")
```
```py:test6.py（一括）
import bz2
target = "jawiki-20200501-pages-articles-multistream.xml.bz2"
bytes  = 0
size   = 1024 * 1024  # 1MB
with bz2.open(target, "rb") as f:
    while (data := f.read(size)):
        bytes += len(data)
print(f"bytes: {bytes:,}")
```
```shell-session:実行結果
$ time py.exe test5.py  # 逐次
streams: 24,957, bytes: 13,023,068,290

real    8m12.155s

$ time py.exe test6.py  # 一括
bytes: 13,023,068,290

real    8m1.476s
```

処理の大半が libbz2 で行われていて、それ以外のオーバーヘッドは少なく高速です。

## bzcat

WSL1 の bzcat コマンドも計測します。

```shell-session
$ time bzcat jawiki-20200501-pages-articles-multistream.xml.bz2 > /dev/null

real    8m21.056s
user    8m5.563s
sys     0m15.422s
```

## まとめ

結果をまとめます。WSL1 (Mono) での計測結果を加えます。Python の速さが目を引きます。

||逐次 (Win)|逐次 (WSL1)|一括 (Win)|一括 (WSL1)|
|----|---:|---:|---:|---:|
|SharpZipLib|16m02.849s|22m49.375s|||
|SharpCompress|18m26.520s|23m56.694s|17m36.925s|22m54.247s|
|AR.Compression.BZip2|||8m23.916s|8m36.495s|
|Python (bz2)|8m12.155s|8m45.590s|8m01.476s|8m28.749s|
|bzcat||||8m21.056s|

マネージドコードで実装されたライブラリは倍以上の時間が掛かりました。マネージド縛りがなければ AR.Compression.BZip2 を使った方が無難です。

※ System.IO.Compression.GZipStream が利用している DeflateStream は、独自実装からネイティブのラッパーに切り替えたようです。

* [GZipStream クラス (System.IO.Compression) | Microsoft Docs](https://docs.microsoft.com/ja-jp/dotnet/api/system.io.compression.gzipstream)

> .NET Framework 4.5以降では、DeflateStream クラスは、圧縮のために zlib ライブラリを使用します。

# 関連記事

Wikipedia のダンプについては以下の記事を参照してください。

* [Wikipediaのダンプからページを取り出す](https://qiita.com/7shi/items/7a4aa381ec3dc97bd0f2)

以下の記事で言及している処理のために調査しました。

* [Wiktionaryの全文処理をF#とPythonで速度比較](https://qiita.com/7shi/items/1d6b97c657c6fffdbd70)

# 参考

SharpZipLib で bzip2 を扱っている記事です。

* [C#で bzip2 の圧縮、展開を行う方法 - 備忘録](https://kagasu.hatenablog.com/entry/2017/05/19/231911)

SharpCompress に言及している記事です。

* [つぼやきver2 続SharpCompress](http://ilyuda.blog.fc2.com/blog-entry-13.html)
