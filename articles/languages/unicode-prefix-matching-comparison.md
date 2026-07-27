---
coediting: false
comments_count: 0
created_at: '2020-06-08T04:59:32+09:00'
id: 07bfbc87956be6e1960d
likes_count: 0
private: false
reactions_count: 0
stocks_count: 1
tags:
- name: Python
  versions: []
- name: F#
  versions: []
- name: .NETFramework
  versions: []
title: .NET FrameworkとPythonで合成文字の前方一致を比較
updated_at: '2020-06-11T16:37:35+09:00'
url: https://qiita.com/7shi/items/07bfbc87956be6e1960d
slide: false
---

.NET Framework と Python で前方一致の挙動が違うことに気付きました。Unicode の等価性に関係します。一部 Mono の挙動にも注意が必要です。

# 正規化

Unicode には濁点やアクセントなどの付加記号が付いた文字を、まとめて 1 文字（合成済み文字）として扱う方法と、ベースの文字（基底文字）と記号（結合文字）とを分離して扱う方法があります。どちらかに統一することを**正規化**と呼びます。

* [Unicode正規化 - Wikipedia](https://ja.wikipedia.org/wiki/Unicode%E6%AD%A3%E8%A6%8F%E5%8C%96)

> Unicodeの正規化手段の基礎は、文字の合成と分解という概念である。文字の合成とは、基底文字と結合文字の組み合わせによる結合文字列を、単一の符号位置である合成済み文字にする手続きである。

身近な例では濁点付きの仮名が対象となります。

* "か" U+304B + "゛" U+3099 ⇔ "が" U+304C

【参考】 [Unicodeでは濁点や半濁点を別扱いしてることがあるので結合した - はてなの鴨澤](https://kamosawa.hatenablog.com/entry/20151015)

.NET Framework の文字列には正規化のためのメソッドがあります。

* [String.Normalize メソッド (System) | Microsoft Docs](https://docs.microsoft.com/ja-jp/dotnet/api/system.string.normalize)

```fsharp:F#
> "\u304b\u3099".Normalize() |> Seq.map (int >> sprintf "%x");;
val it : seq<string> = seq ["304c"]
```

# 正準等価

分離した形と結合した形とを等価として扱う方法を**正準等価**と呼びます。

* [Unicodeの等価性](https://ja.wikipedia.org/wiki/Unicode%E3%81%AE%E7%AD%89%E4%BE%A1%E6%80%A7)

> たとえば、ダイアクリティカルマークを持つ合成済みの文字は、分解すると「基底文字＋結合文字のダイアクリティカルマーク」の文字列に変わるが、いずれも等価であるとみなされる。言いかえると合成済み文字 ‘ü’ は ‘u’ と結合文字の分音記号 ‘¨’ を並べたものと正準等価である。

.NET Framework や Python では、単なる文字列比較では正準等価は考慮されません。

```fsharp:F#
> "\u304b\u3099" = "\u304c";;
val it : bool = false
```
```python:Python
>>> "\u304b\u3099" == "\u304c"
False
```

メソッドによっては考慮されます。

# StartsWith

以下の例では、.NET Framework で正準等価が考慮されますが、Python では考慮されません。

```fsharp:F#
> "\u304b\u3099".StartsWith "\u304c";;
val it : bool = true

> "\u304c".StartsWith "\u304b\u3099";;
val it : bool = true
```
```python:Python
>>> "\u304b\u3099".startswith("\u304c")
False
>>> "\u304c".startswith("\u304b\u3099")
False
```

以下の例では、文字コードの並びを見ているかどうかの違いが分かります。

```fsharp:F#
> "\u304b\u3099".StartsWith "\u304b";;
val it : bool = false
```
```python:Python
>>> "\u304b\u3099".startswith("\u304b")
True
```

合成済み文字が用意されていない組み合わせでも、.NET Framework では結合文字として扱われます。

```fsharp:F#
> "=\u3099".StartsWith "=";;
val it : bool = false
```
```python:Python
>>> "=\u3099".startswith("=")
True
```

`=` を増やすと、.NET Framework と Mono で挙動が変わります。

```fsharp:.NET
> "==\u3099".StartsWith "==";;
val it : bool = false
```
```fsharp:Mono
> "==\u3099".StartsWith "==";;
val it : bool = true
```
```python:Python
>>> "==\u3099".startswith("==")
True
```

※ .NET Core 3.1 では .NET Framework 4.8 と同じ結果になることを確認しました。

移植の際に挙動の違いに悩まされました。

Python に合わせるには部分文字列を比較する方法があります。

```fsharp:F#
> "==\u3099".Substring(0, 2) = "==";;
val it : bool = true
```

※ 一般化する場合、部分文字列を取る前に長さがはみ出さないか確認する必要があります。

正規表現でも正準等価は考慮されません。

```fsharp:F#
> open System.Text.RegularExpressions;;
> let r = Regex "^=";;
val r : Regex = ^=

> r.Match "=\u3099";;
val it : Match = = {Captures = seq [...];
                    Groups = seq [...];
                    Index = 0;
                    Length = 1;
                    Name = "0";
                    Success = true;
                    Value = "=";}
```

# 追記

Mono の件に関してコメントをいただきました。難しい問題のようです。

<blockquote class="twitter-tweet"><p lang="und" dir="ltr"><a href="https://t.co/bwasCKRMC6">https://t.co/bwasCKRMC6</a>()のWindows実装はUnicode標準ではなくWindowsの独自仕様（LCMapString）で完全にブラックボックスなので、わたしが実装したときもかなり手探りでやってるんですよね。そしてあの辺MSでやってた人はもうこの世にいない…。Mac版dotnetも挙動違うはずです。 <a href="https://t.co/0O3DCJkq4s">https://t.co/0O3DCJkq4s</a></p>&mdash; Atsushi Eno (@atsushieno) <a href="https://twitter.com/atsushieno/status/1269800563878723584?ref_src=twsrc%5Etfw">June 8, 2020</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

# 関連記事

以下の記事を書くための調査をしているときに気付きました。

* [Wiktionaryの全文処理をF#とPythonで速度比較](https://qiita.com/7shi/items/1d6b97c657c6fffdbd70)

`==` の言語名に余分な結合文字が含まれていましたが、修正されていることを確認しました。定期的にチェックしているようです。

* [Wiktionary処理中のエラーを調査](https://7shi.hateblo.jp/entry/2020/06/11/163037)
