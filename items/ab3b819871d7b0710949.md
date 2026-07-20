---
coediting: false
comments_count: 0
created_at: '2014-12-05T18:40:54+09:00'
id: ab3b819871d7b0710949
likes_count: 28
private: false
reactions_count: 0
stocks_count: 23
tags:
- name: Haskell
  versions: []
- name: Clean
  versions: []
title: Clean 一意型 調査メモ
updated_at: '2020-03-25T17:25:38+09:00'
url: https://qiita.com/7shi/items/ab3b819871d7b0710949
slide: false
---

Cleanという言語で副作用を扱うのに使われている一意型について、簡単に調べてみました。モナドが使われるようになった背景を理解する一助になるかもしれません。

※ この記事はHaskellの知識を前提としています。Haskellから推測できる事項については説明を省略しています。

この記事には続編のようなものがあります。

* [IOモナドを素手で触ってみた](http://qiita.com/7shi/items/0a90d7ba31355e1c73aa) 2014.12.9

# Clean

CleanはHaskellとよく似た非正格純粋関数型言語です。

* http://wiki.clean.cs.ru.nl/Clean

CleanとHaskellは方言程度の違いです。次の記事に比較がまとめられています。

* [PDF] [Clean for Haskell98 Programmers - A Quick Reference Guide](http://www.mbsd.cs.ru.nl/publications/papers/2007/achp2007-CleanHaskellQuickGuide.pdf) 2007

なぜ似たような言語が2つあるかというと、副作用の扱い方に違いがあるためです。Haskellでは[モナド](http://ja.wikipedia.org/wiki/%E3%83%A2%E3%83%8A%E3%83%89_%28%E3%83%97%E3%83%AD%E3%82%B0%E3%83%A9%E3%83%9F%E3%83%B3%E3%82%B0%29)を使うのに対して、Cleanでは一意型（[uniqueness type](http://en.wikipedia.org/wiki/Uniqueness_type)）を使います。

Concurrent Cleanという名前で呼ばれることもありますが、これは並列性にシフトしようとした時期の名残らしいです。

* [FAQ - Clean](http://wiki.clean.cs.ru.nl/FAQ)

## ドキュメント

* 原文: [Functional Programming in Clean - Clean](http://wiki.clean.cs.ru.nl/Functional_Programming_in_Clean)
* 日本語訳（[Internet Archive](http://archive.org/)より）: [Cleanで関数プログラミング 【総目次】](https://web.archive.org/web/20110105091254/http://sky.zero.ad.jp/~zaa54437/programming/clean/CleanBook/) 2002.3.20

# 一意型

一意型についてドキュメントで調べたことをまとめます。単純な引用ではなく必要に応じて解釈を加えているため、表現が不正確である可能性があります。

[4.3.4 一意性型付け](https://web.archive.org/web/20110105091259/http://sky.zero.ad.jp/~zaa54437/programming/clean/CleanBook/part1/Chap4.html#sc16)より、一意型とは次のような意味を持つようです。

* 一意型とは：一意性を持つ型
* 一意性とは：一度しか使われないこと

次のプログラムを例にして、このコードに至る過程を説明します。

```
module test

import StdEnv, StdFile

WriteAB :: *File -> *File
WriteAB f
    # f = fwritec 'a' f
      f = fwritec 'b' f
    = f

Start :: *World -> *World
Start w
    # (f, w) = stdio w
      f      = WriteAB f
      (_, w) = fclose f w
    = w
```
```text:実行結果
ab65536
```

* Haskellと異なり、関数を小文字で始める制約はありません。
* `stdio`で標準入出力のハンドルを取得して、それに対して`WriteAB`で`'a'`と`'b'`を書き込んでいます。
* `Start`の戻り値を表示する仕様のため、実行結果には`w`のハンドル番号`65536`が含まれます。（消す方法は不明です）

このコードはドキュメントに断片的に記載されているサンプルを補完したものです。次の記事を参考にしました。

* [@hiratara](https://twitter.com/hiratara): [Hello clean world! - Qiita](http://qiita.com/hiratara/items/23dc0decf818db8c0f07) 2012.7.14

## 一意性

C言語の`FILE*`のように、他の言語であれば取得したファイルハンドルを使い回して書き込むのが普通です。

同様の発想で`'a'`と`'b'`を書き込もうとしても、Cleanでは**エラー**になります。

[4.3.4 一意性型付け](https://web.archive.org/web/20110105091259/http://sky.zero.ad.jp/~zaa54437/programming/clean/CleanBook/part1/Chap4.html#sc16)より一部改変

```text:NG
WriteAB :: *File -> (*File, *File)
WriteAB file = (fileA, fileB)
    where
        fileA = fwritec 'a' file
        fileB = fwritec 'b' file
```
```text:エラー
Uniqueness error [test.icl,5,WriteAB]: "file" demanded attribute cannot be offered by shared object
Uniqueness error [test.icl,5,WriteAB]: "file" demanded attribute cannot be offered by shared object
```

型注釈の`*`は一意性の指定です。`file`には型注釈で一意性が指定されていますが、一意性とは一度しか使われないことのため、2か所で使われているとエラーになります。

修正すると次のようになります。

```
WriteAB :: *File -> *File
WriteAB file = fileAB
    where
        fileA  = fwritec 'a' file
        fileAB = fwritec 'b' fileA
```

let-before式という書き方もあります。

[4.3.5 入れ子通用範囲スタイル](https://web.archive.org/web/20110105091259/http://sky.zero.ad.jp/~zaa54437/programming/clean/CleanBook/part1/Chap4.html#sc17)より

```
WriteAB :: *File -> *File
WriteAB file
    # fileA  = fwritec 'a' file
    # fileAB = fwritec 'b' fileA
    = fileAB
```

受け渡しをフローで考えると良さそうです。

* 引数 → `file` → `fileA` → `fileAB` → 戻り値

このように一意性変数を次々と受け渡していくスタイルです。一度受け渡してしまったら、受け渡し元には触ることができなくなります。これを検出するのに、複数個所から参照されていないかを調べるようです。

過去の時点のインスタンスに触れないようにすることで、破壊的変更が行われていることを隠蔽して、参照透過性が確保されるという理屈のようです。

## 類似性

破壊的変更を隠蔽するという点は、STモナドに似ていると思いました。

受け渡された一意型変数が無効になるという点は、C++のムーブセマンティクスに似ていると思いました。一意型変数の受け渡しは常にムーブとして扱われるという解釈です。

### 参考

STモナドについては次の記事に詳しいです。

* [@shelarcy](https://twitter.com/shelarcy): [本物のプログラマはHaskellを使う - 第20回　更新を高速化するためのSTモナド：ITpro](http://itpro.nikkeibp.co.jp/article/COLUMN/20080603/305833/) 2008.6.4

次の記事にはIOモナドの実体がRealWorldを取り回すSTモナドであると書かれており、RealWorldは一意型であると解釈できそうです。

* [@uehaj](https://twitter.com/uehaj): [HaskellにおけるIOモナドとSTモナドの関係 - uehaj's blog](http://uehaj.hatenablog.com/entry/2014/01/29/110222) 2014.1.29

Cleanでは表に出ていて、`Start`には`*World`が渡されます。

* [@hiratara](https://twitter.com/hiratara): [cleanは副作用を扱うのにIOモナドを使っていない - Qiita](http://qiita.com/hiratara/items/6e2547e4b1fdec113436) 2012.7.14

C++のムーブセマンティクスについては次の記事に詳しいです。

* [@yohhoy](https://twitter.com/yohhoy): [本当は怖くないムーブセマンティクス - yohhoyの日記（別館）](http://yohhoy.hatenablog.jp/entry/2012/12/15/120839) 2012.12.15

## シャドウイング

受け渡すたびに別名を付けるのは面倒ですが、`#`ではシャドウイング（同じ名前の別の変数を定義すること）ができます。

※ ドキュメントではシャドウイングという言い方はされていませんが、意味からそのように解釈しました。

[4.3.5 入れ子通用範囲スタイル](https://web.archive.org/web/20110105091259/http://sky.zero.ad.jp/~zaa54437/programming/clean/CleanBook/part1/Chap4.html#sc17)より

```
WriteAB :: *File -> *File
WriteAB file
    # file = fwritec 'a' file
    # file = fwritec 'b' file
    = file
```

2つ目以降の`#`は省略できます。

[5.2 環境渡し技術](https://web.archive.org/web/20110105091259/http://sky.zero.ad.jp/~zaa54437/programming/clean/CleanBook/part1/Chap5.html#sc3)より

```
WriteAB :: *File -> *File
WriteAB file
    # file = fwritec 'a' file
      file = fwritec 'b' file
    = file
```

これはHaskellでレイアウトにより連続する`let`をまとめられるのと同じ発想のようです。let-before式という呼び方から、`#`が`let`と類似であることも示唆されています。

```hs:Haskellの類似例
main = do
    let a = 1
        b = 1
    print $ a + b
```

ここまでの知識で書いたのが、先に掲載したコードです。

## 他のスタイル

[5.2 環境渡し技術](https://web.archive.org/web/20110105091259/http://sky.zero.ad.jp/~zaa54437/programming/clean/CleanBook/part1/Chap5.html#sc3)には他のスタイルも紹介されています。

### 戻り値を次の関数に渡す

```
WriteAB :: *File -> *File
WriteAB file = fwritec 'b' (fwritec 'a' file)
```

多数が連続するとこの方法では大変です。ドキュメントには、記述された順番が実行順と逆転していることも指摘されています。

### 関数合成

Cleanでは関数合成は`o`で表記します。

```
WriteAB :: *File -> *File
WriteAB file = (fwritec 'b' o fwritec 'a') file
```

この方法でも、記述された順番が実行順と逆転しています。

Cleanの関数はカリー化されているため、部分適用を利用すれば引数を省略できます（ポイントフリースタイル）。ただしHaskellとは異なり、引数がない関数の型注釈には括弧が必要です。

```
WriteAB :: (*File -> *File)
WriteAB = fwritec 'b' o fwritec 'a'
```

型注釈に括弧がないとエラーになります。

```
WriteAB :: *File -> *File
WriteAB = fwritec 'b' o fwritec 'a'
```
```text:エラー
Error: This alternative has 0 arguments instead of 1.
```

どうやら表記上の引数を数えているようです。とりあえずポイントフリースタイルでは型を括弧で囲むと認識しておけば良さそうです。

### seq

リストに連続適用する関数`seq`を使う方法です。Haskellの[sequence](http://hackage.haskell.org/package/base-4.7.0.1/docs/Prelude.html#v:sequence)に相当するようです（モナド関連の差異はありますが）。見た目が[F#のシーケンス](http://msdn.microsoft.com/ja-jp/library/dd233209.aspx)に似ていますが別物で、Cleanの方はただの関数と引数です。

```
WriteAB :: *File -> *File
WriteAB file = seq [fwritec 'a', fwritec 'b'] file
```

引数を省略します。

```
WriteAB :: (*File -> *File)
WriteAB = seq [fwritec 'a', fwritec 'b']
```

改行して変形すると、do記法まであと一歩という印象です。

```
WriteAB :: (*File -> *File)
WriteAB = seq
	[ fwritec 'a'
	, fwritec 'b'
	]
```

`fwritec`の繰り返しを`map`で書き換えます。ドキュメントでは関数合成を使っていますが、Clean 2.4ではエラーになります。文法が変わったのかもしれません。

```
WriteAB :: (*File -> *File)
WriteAB = seq (map fwritec ['a', 'b'])
```

Haskellでは文字列は文字のリストのため`['a', 'b']`は`"ab"`と等しいですが、Cleanでは区別されるようです。

文字のリストには糖衣構文があります。

```
WriteAB :: (*File -> *File)
WriteAB = seq (map fwritec ['ab'])
```

### foldl

`seq`と`map`を併用するよりも`foldl`を使った方が良いような気がしたので試してみました。`flip`が必要になってしまいます。

```
WriteAB :: *File -> *File
WriteAB file = foldl (flip fwritec) file ['ab']
```

もう1回`flip`すれば引数を消せます。

```
WriteAB :: (*File -> *File)
WriteAB = flip (foldl (flip fwritec)) ['ab']
```

ここまで来るともうパズルです。`seq`と`map`の方がシンプルでした。

### <<<

ファイルに書き込むための専用演算子です。C++のiostreamに似ています。

```
WriteAB :: *File -> *File
WriteAB file = file <<< 'a' <<< 'b'
```

これはあくまで個別対応なので、ファイル以外で同じようなことがやりたければ、それ用の演算子を定義することになるようです。

## モナド

色々な書き換えを見て来ましたが、どれも涙ぐましい努力です。ケースバイケースで最適な書き方を見付けるパズルのようですが、統一的に扱えないものでしょうか。

というわけで行き着くのがモナドです・・・ほとんど誘導尋問ですが。

CleanにはUnit型がないので自前で定義します。行頭の`::`はデータ型の宣言で、`:==`で型シノニムを定義します（コメントで対応するHaskellを示します）。値は`0`で代用します。

```
:: Unit :== Int  // [Haskell] type Unit = Int
unit x = (0, x)
```

[5.2.2 モナドスタイル](https://web.archive.org/web/20110105091259/http://sky.zero.ad.jp/~zaa54437/programming/clean/CleanBook/part1/Chap5.html#sc5)を参考にモナド化してみます。モナド関連の型や関数は標準ライブラリ（StdEnv）に入っています。

```
fwritecM ch = unit o fwritec ch

WriteAB :: (*File -> (Unit, *File))
WriteAB =
	fwritecM 'a' `bind` \_ ->
	fwritecM 'b'

Start :: *World -> *World
Start w
    # (f1, w1) = stdio w
      (_ , f2) = WriteAB f1
      (_ , w2) = fclose f2 w1
    = w2
```

do記法に相当するものはないようです。もしあれば、もうモナドでいいじゃんとなって、それがHaskellという感じになりそうです。

実際にHaskellでIOモナドを剥がしてみると、下からは一意型とほとんど同じ世界が現れます。

[IOモナドを素手で触ってみた](http://qiita.com/7shi/items/0a90d7ba31355e1c73aa)より

```hs:Haskell
{-# LANGUAGE UnboxedTuples #-}

import GHC.Base

main = IO $ \world ->
    let (# world1, _  #) = unIO (print "hello") world
        (# world2, _  #) = unIO (print "world") world1
    in  (# world2, () #)
```
```text:実行結果
"hello"
"world"
```

Haskellでは世界の受け渡しはモナドによって隠されているため直接触ることはなく、一意性はモナドによって守られているため、言語面での一意型のサポートはありません。

### 参考

Unit型がないのは、次の記事を参考にしました。

* [Concurrent Clean : Erlangのようなマルチプロセスプログラミングを行うには - lethevert is a programmer](http://d.hatena.ne.jp/lethevert/20060901/p2) 2006.1.9

do記法を疑似的に再現しようと試行錯誤も行われたようですが、なかなか厳しいようです。

* [5/5/2007 - lethevert is a programmer](http://d.hatena.ne.jp/lethevert/20070505)

# 感想

あくまで個人的な感想ですが、現時点での言語の知名度を見る限り、Haskell（モナド）が勝ってClean（一意型）が負けたように見えます。

難解と評判のモナドに対して、一意型は取っ付きやすさが売りのように感じます。まだHaskellが今のように関数型言語の代表として認知される前は、Cleanに軍配を上げる方もいました。（一意型が理由ではありませんが）

* [@shownakamura](https://twitter.com/shownakamura): [純粋関数型言語Concurrent Clean: ホットコーナーの舞台裏](http://iiyu.asablo.jp/blog/2006/08/06/474932) 2006.8.6

当時の私はCleanどころか関数型言語も知らない状態で、興味を持つのが完全に周回遅れになってしまいました。

## 一意型

実際に一意型を見ると、受け渡しが面倒でその対策としてモナドがあるということから、一意型は過渡期の技術だという印象を受けました（モナド前史というか）。ただ、発想そのものは確かにシンプルで、モナドほどの取っ付きにくさがないのも事実です。

Haskellを説明する資料にも、比較対象として一意型に言及したものがあります。

* [@tanakh](https://twitter.com/tanakh): [関数プログラミング入門 - SlideShare](http://www.slideshare.net/tanakh/ss-3580292) 2010.3.28

この資料にはHaskellではモナドの前に遅延ストリームというものを使っていたとあります。遅延ストリームについては次の記事が詳しいです。

* [Haskellの入出力](http://kreisel.fam.cx/webmaster/clog/img/www.ice.nuie.nagoya-u.ac.jp/~h003149b/lang/haskell_io.html) 2010.9.16

一意型とモナドを段階的に使い分けるというのも1つの案ではあります。しかしHaskellは既にモナドをベースにPreludeが構築されているため、一意型が入り込む余地はありません。逆にCleanでモナドを使おうとすると、do記法のサポートがないことがネックとなります。

## Scala

一意型に復活の余地があるのかはよく分かりませんが、Scalaで何か動きがあったようなツイートを見付けました。

<blockquote class="twitter-tweet" lang="ja"><p>Scala に舞台を移して行われる線形型（一意型）とモナドの戦い！！ http://twitter.com/kmizu/status/12793353913503744 http://twitter.com/ittayd/statuses/12731908429451264</p>&mdash; shelarcy（しぇらーしぃ） (@shelarcy) <a href="https://twitter.com/shelarcy/status/12794917294186498">2010, 12月 9</a></blockquote>

関連すると思われる資料です。

* [@kmizu](https://twitter.com/kmizu): [About Capabilities for Uniqueness and Borrowing](http://www.slideshare.net/kmizushima/about-capabilities-for-uniqueness-and-borrowing) 2012.10.21

Scalaの現状を知らないため、一意型がどの程度活用されているのかは不明です。

## 線形型

先ほどのツイートには線形型という用語が出ていますが、微妙に違うものらしいです。

<blockquote class="twitter-tweet" lang="ja"><p><a href="https://twitter.com/eagletmt">@eagletmt</a> <a href="https://twitter.com/tanakh">@tanakh</a> http://bit.ly/aj6Zsd &quot;線形型=もう今後コピーしない ・ 一意型=今までコピーされてない&quot; という説明を聞きます。使い方としてはどちらも結局一意性の保証に使われていることが多いので、まあどっちでも良いような感じもしますが…</p>&mdash; kinaba (@kinaba) <a href="https://twitter.com/kinaba/status/11226169122">2010, 3月 29</a></blockquote>

次の記事には、[線形論理](http://ja.wikipedia.org/wiki/%E7%B7%9A%E5%BD%A2%E8%AB%96%E7%90%86)との関係が示唆されています。

* [@sshi](https://twitter.com/sshi): [Concurrent Clean - sshi.Continual](http://d.hatena.ne.jp/sshi/20060220/p1) 2006.2.20

線形型を推しているのがATS言語です。

* [JATS-UG - Japan ATS User Group](http://jats-ug.metasepi.org/)

一意型の敵を線形型で討つ、となるのでしょうか。。。

# 勉強会

Cleanの勉強会があったようです。

* [スタートClean - PARTAKE](http://partake.in/events/efad035a-0dbe-4717-aa5d-1afb320e05d6) 2011.7.9
* [@oskimura](https://twitter.com/oskimura): [Clean 概説 - SlideShare](http://www.slideshare.net/oskimura/clean-8554744) 2011.7.10
* [Start::Clean - Togetterまとめ](http://togetter.com/li/159883) 2011.7.9
* [@eldesh](https://twitter.com/eldesh): [この夏、Cleanを始めよう！ - ::Eldesh a b = LEFT a | RIGHT b](http://d.hatena.ne.jp/eldesh/20110707/1310047869) 2011.7.7
* [@eldesh](https://twitter.com/eldesh): [スタートClean、終わりました - ::Eldesh a b = LEFT a | RIGHT b](http://d.hatena.ne.jp/eldesh/20110711/1310375107) 2011.7.11
