---
coediting: false
comments_count: 0
created_at: '2016-02-14T10:55:00+09:00'
id: e43e8ce0b1a2cadee2a3
likes_count: 9
private: false
reactions_count: 0
stocks_count: 9
tags:
- name: VAX
  versions: []
title: VAXによる機械語入門
updated_at: '2016-02-16T16:55:30+09:00'
url: https://qiita.com/7shi/items/e43e8ce0b1a2cadee2a3
slide: false
---

VAXとはPDP-11の後継となる32bitマシンです。UNIX V7をVAXに移植したUNIX/32Vがあります。バイナリを通してUNIXを学習します。

この記事は以前開催していた[池袋バイナリ勉強会](http://connpass.com/series/182/)の初回編で教えていた内容をVAX向けに書き直したものです。

この記事には姉妹編があります。

* [PDP-11による機械語入門](http://qiita.com/7shi/items/86724696518df3a174dc) 2015.11.08
* [8086による機械語入門](http://qiita.com/7shi/items/b3911948f9d97b05395e) 2015.11.09

# 環境設定

UNIX/32Vのバイナリを動かすためのインタプリタと、その上で動く当時のコンパイラを使用します。

インタプリタはJavaで作られているためJDKが必要です。

* http://www.oracle.com/technetwork/java/javase/downloads/index.html

WindowsではMSYS2が必要です。

* [MSYS2でRicty Diminishedを使う設定など](http://qiita.com/7shi/items/894fdd849658880bf6c9) 2015.01.29

READMEに従ってインタプリタ一式をインストールしてください。

* https://bitbucket.org/7shi/vaxrun

## コンパイル

ハローワールドでテストします。

```hello.c
#include <stdio.h>

int main() {
    printf("hello\n");
    return 0;
}
```

先ほどインストールしたコンパイラでVAX用のバイナリを生成します。

```text
$ vaxcc hello.c
```

※ vaxccはシェルスクリプトで、インタプリタ上で当時のコンパイラ（VAXバイナリ）を実行しています。

a.outというファイルが出力されます。ファイルの種類を確認してもVAXとまでは認識されません。

```text
$ file a.out
a.out: a.out little-endian 32-bit pure executable not stripped
```

## 実行

出力されたバイナリをインタプリタで実行します。

```text
$ vaxrun a.out
hello
```

## 逆アセンブル

バイナリの中にどのような命令が入っているかを分析します。この操作を**逆アセンブル**と呼びます。

```text
$ vaxdis a.out
magic = 00000108, text  = 00000b04, data   = 0000016c, bss    = 00000404
syms  = 00000300, entry = 00000000, trsize = 00000000, drsize = 00000000
[crt0.o]
start:
00000000: 00 00                    .word 0
00000002: c2 08 5e                 subl2 $8,sp
00000005: d0 ae 08 6e              movl 8(sp),(sp)
00000009: 9e ae 0c 50              movab 0xc(sp),r0
（略）
```

簡単なプログラムなのにすごく複雑だと感じられたと思います。入門にはあまりに複雑過ぎるため、今回の記事ではもっと簡単なものから始めます。基礎を固めてから、このバイナリに挑戦していただきます。

### 読み方

`magic = ...` などはヘッダで、ファイル構造についての情報です。

`[crt0.o]`や`start`は**シンボル**と呼ばれ、見出しのようなものです。

その後は次のような構成になっています。

アドレス|機械語|アセンブリ言語
--------|------|--------------
`00000000:`|`00 00`|`.word 0`
`00000002:`|`c2 08 5e`|`subl2 $8,sp`
`00000005:`|`d0 ae 08 6e`|`movl 8(sp),(sp)`
`00000009:`|`9e ae 0c 50`|`movab 0xc(sp),r0`

* **アドレス**は行番号のようなものです。そこにCPUに対する命令が入っています。
* 命令は数字で構成されており**機械語**と呼ばれます。ここでは16進数表記されています。
* 機械語は人間には読みにくいため、意味を英語の略語などで表記したものが**アセンブリ言語**です。

機械語やアセンブリ言語については後で詳しく見ていきます。

## トレース

命令やレジスタなどのログを表示しながら実行できます。この操作を**トレース**と呼びます。

```text
$ vaxrun -d a.out
00000000 00000000 00000000 00000000 00000000 00000000 : subl2 $0x8,sp
00000000 00000000 00000000 00000000 00000000 00000000 : c2085e
00000000 00000000 0007ffe4 00000002 ---- : [03]08
00000000 00000000 00000000 00000000 00000000 00000000 : movl 0x8(sp),(sp)
00000000 00000000 00000000 00000000 00000000 00000000 : d0ae086e
00000000 00000000 0007ffdc 00000005 ---- : [7ffe4]01[7ffdc]00
（略）
```

逆アセンブルと異なるのは、命令が実行される順番に表示される点です。基本的には上から順番に実行されますが、分岐や関数呼び出しなどでアドレスが飛びます。

```text:例
0007fff0 00000000 00000000 00000000 00000000 00000000 : calls $0x3,0x3c
00000000 00000000 00000000 00000000 00000000 00000000 : fb03ef0d000000
00000000 00000000 0007ffdc 00000028 ---C : [29]03[3c]00
0007fff0 00000000 00000000 00000000 00000000 00000000 : subl2 $0x00000000,sp
00000000 00000000 00000000 00000000 00000000 00000000 : c28f000000005e
0007ffd8 0007ffc4 0007ffc4 0000003e ---- : [40]00
```

アドレス（最後の8桁16進数）が飛んでいることを確認してください: `00000028` → `0000003e`

## シンボル

逆アセンブルのときに出て来たシンボルを一覧表示します。

```text
$ vaxnm a.out
00000000 a .F1
00000000 a .R1
00000782 T __cleanu
（略）
000005b4 t strout.o
00000aa4 t stty.o
00000ae8 t write.o
```

構成は次の通りです。

アドレス|種類|シンボル名
--------|----|----------
`00000000`|`a`|`.F1`
`00000000`|`a`|`.R1`
`00000782`|`T`|`__cleanu`

種類は初めから細かく理解していなくても、大雑把に`T`が関数、`D`と`B`が変数だと考えておけば良いです。それらがどのアドレスに関連付けられているかを示しています。

※ 関数や変数以外にも種類はありますが、当面は必要ありません。

## ファイルサイズの縮小

シンボルは付加的情報で実行には必要不可欠なものではありません。シンボルを削ってファイルサイズが縮小できます。

```text
$ wc -c a.out
3984 a.out
$ vaxstrip a.out
$ wc -c a.out
3216 a.out
```

シンボルがなくなっていることを確認します。

```text
$ vaxnm a.out
nm: a.out-- no name list
```

実行には支障ありません。

```text
$ vaxrun a.out
hello
```

逆アセンブルでシンボルが出て来なくなります。

```text
$ vaxdis a.out
magic = 00000108, text  = 00000b04, data   = 0000016c, bss    = 00000404
syms  = 00000000, entry = 00000000, trsize = 00000000, drsize = 00000000
00000000: 00 00                    .word 0
00000002: c2 08 5e                 subl2 $8,sp
00000005: d0 ae 08 6e              movl 8(sp),(sp)
（略）
```

シンボルがないと関数の切れ目などが分からなくなるためデバッグや解析が困難になります。次のような運用方法が一般的です。

* 開発時にはデバッグのためシンボルを付けておきます。
* 完成品をバイナリ配布する際には、ファイルサイズを縮小するためシンボルを取り除きます。ソース非公開の商用製品の場合、内部構造を解析されにくくする意図もあります。

# 小さなバイナリ

小さなバイナリを作って分析します。

```text:write.s
.word 0

# write(1, hello, 6);
movl $args1, ap
chmk $4

# exit(0);
movl $args2, ap
chmk $1

.data
args1: .long 3, 1, hello, 6
args2: .long 1, 0
hello: .byte 'h, 'e, 'l, 'l, 'o, 10
```
```text:実行結果
$ vaxas write.s
$ vaxstrip a.out
$ vaxrun a.out
hello
```

* アセンブリ言語の文法はアセンブラによって方言があります。
    * このアセンブラでは`#`はコメントです。
* アセンブリ言語はCPUによって異なります。今回はVAXです。
    * `ap` はレジスタと呼ばれます。変数のようなものです。
    * `movl` は前から後ろに代入します: `movl $args1, ap` ⇒ `ap = args1`
    * `chmk` は割り込みを発生させる命令です。

## システムコール

割り込みでカーネルを呼び出してOSの機能を利用することを**システムコール**と呼びます。

* `chmk` の後にシステムコール番号を書きます: `$1`, `$4` など
    * `$1`: `exit`
    * `$4`: `write`
* `ap` は引数を示します。
    * 引数を後ろに書いて`args1`のように名前を付けます。
    * `.long`は4バイト値です。
    * 最初の値は引数の数です。
    * `write` の第1引数 `1` は標準出力を表します。
* `.byte` は1バイト値です。
    * 1バイト値（文字）の連続で文字列を表現します。
    * `10`は改行コード（`\n`）です。

UNIX/32Vのシステムコール定義: [/usr/src/sys/sys/sysent.c](http://minnie.tuhs.org/cgi-bin/utree.pl?file=32V/usr/src/sys/sys/sysent.c)

```text
struct sysent sysent[64] =
{
    引数の数, 未使用, 処理関数, /* システムコール番号 = システムコール名 */
    ...
};
```

* `exit`: システムコール番号 1, 引数の数 1
* `write`: システムコール番号 4, 引数の数 3

## 逆アセンブル

バイナリを分析します。

```text
$ vaxdis a.out
magic = 00000108, text  = 00000014, data   = 00000020, bss    = 00000000
syms  = 00000000, entry = 00000000, trsize = 00000000, drsize = 00000000
00000000: 00 00                    .word 0
00000002: d0 8f 00 02 00 00 5c     movl $0x200,ap
00000009: bc 04                    chmk $4
0000000b: d0 8f 10 02 00 00 5c     movl $0x210,ap
00000012: bc 01                    chmk $1
```

* write.s →（アセンブル）→ a.out →（逆アセンブル）→ 上記結果
    * アセンブル: アセンブリ言語 → バイナリ
    * 逆アセンブル: バイナリ → アセンブリ言語
* 逆とは言っても完全に元に戻るわけではありません。
    * 逆アセンブルでは対応するバイナリが確認できます。
* 逆アセンブラの出力は一部数字になっています。
    * `$args1` → `$0x200`
    * `$args2` → `$0x210`

## バイナリダンプ

バイナリを16進数で出力します。

```text
$ hd a.out
00000000  08 01 00 00 14 00 00 00  20 00 00 00 00 00 00 00  |........ .......|
00000010  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
00000020  00 00 d0 8f 00 02 00 00  5c bc 04 d0 8f 10 02 00  |........\.......|
00000030  00 5c bc 01 03 00 00 00  01 00 00 00 18 02 00 00  |.\..............|
00000040  06 00 00 00 01 00 00 00  00 00 00 00 68 65 6c 6c  |............hell|
00000050  6f 0a 00 00                                       |o...|
00000054
```

※ `hd` がない環境では `hexdump -C` や `od -tx1z -Ax` を使用します。

## 仕様

実装例はJavaScript風の疑似コードで示します。

* ヘッダ＋text（命令）＋data
* ヘッダは最初の32バイト

```js
aout = File.readAllBytes("a.out")
h = aout.slice(0, 32)
```

* ヘッダを4バイトずつ区切って、2番目がtextのサイズ、3番目がdataのサイズ。リトルエンディアン。
    * 今回のサンプル: `text = 0x00000014, data = 0x00000020`
* それ以外の項目は当面必要ないので、説明は省略します。

```js
text = h.read32LE(4)
data = h.read32LE(8)
dataPos = 32 + text
textData = aout.slice(32, dataPos)
dataData = aout.slice(dataPos, dataPos + data)
```

* ヘッダの後にtextがあり、その後にdataがあります。
* textやdataはメモリ内でサイズが0x200の倍数に切り上げられます。
    * 切り上げに伴って膨らんだ部分を**パディング**（「詰め物」の意）と呼びます。
* textはアドレス0からサイズ分読み込みます。

```js
textSize = (tsize + 0x1ff) - ((tsize + 0x1ff) % 0x200)
dataSize = (dsize + 0x1ff) - ((dsize + 0x1ff) % 0x200)
mem = new Uint8Array(textSize + dataSize)
mem.set(textData, 0)
mem.set(dataData, textSize)
```

### メモリダンプ

メモリに読み込んだ状態を示します。パディングは省略します。

```text:メモリ配置
.text
00000000  00 00 d0 8f 00 02 00 00  5c bc 04 d0 8f 10 02 00  ........\.......
00000010  00 5c bc 01                                       .\..
.data
00000200  03 00 00 00 01 00 00 00  18 02 00 00 06 00 00 00  ................
00000210  01 00 00 00 00 00 00 00  68 65 6c 6c 6f 0a 00 00  ........hello...
```

※ `.text`や`.data`の`.`はアセンブラに合わせた表記です。

## 練習

※ 時間は目安です。

【問1-1:20分】ファイルをそのままバイナリダンプするプログラムを作ってください。（`hd a.out` 相当）

【問1-2:20分】メモリに読み込んだ状態をバイナリダンプするプログラムを作ってください。

【問2-1:1時間】逆アセンブラを作ってください。（`vaxdis a.out` 相当）

【問2-2:1時間】バイナリを実行してください。（`vaxrun a.out` 相当）

※ 以後、問2-2で作ったものを**インタプリタ**と呼びます。

# 少しずつ拡張

先ほど作った小さなバイナリを少しずつ拡張していきます。

## 数値をメモリに書き込む

メモリを操作して出力する文字列を変更します。

```text:write-1.s
.word 0

# write(1, hello, 6);
movl $args1, ap
chmk $4


# r1 = hello;
# *(uint32_t *)r1 = 'H'|'E'<<8|'L'<<16|'L'<<24;
movl $hello, r1
movl $'H|'E<8|'L<16|'L<24, (r1)

# write(1, hello, 6);
movl $args1, ap
chmk $4


# exit(0);
movl $args2, ap
chmk $1


.data
args1: .long 3, 1, hello, 6
args2: .long 1, 0
hello: .byte 'h, 'e, 'l, 'l, 'o, 10
```
```text:実行結果
$ vaxas -o write-1 write-1.s
$ vaxrun write-1
hello
HELLo
```

`-o`で出力ファイル名を指定しています。

### 練習

【問3-1:5分】逆アセンブラを対応させてください。

【問3-2:10分】インタプリタを対応させてください。

## ディスプレースメント

相対アドレス指定によるメモリ操作を行います。

```text:write-2.s
.word 0

# write(1, hello, 6);
movl $args1, ap
chmk $4


# r1 = hello;
# *(uint32_t *)(r1 + 1) = 'E'|'L'<<8|'L'<<16|'O'<<24;
movl $hello, r1
movl $'E|'L<8|'L<16|'O<24, 1(r1)

# write(1, hello, 6);
movl $args1, ap
chmk $4


# exit(0);
movl $args2, ap
chmk $1


.data
args1: .long 3, 1, hello, 6
args2: .long 1, 0
hello: .byte 'h, 'e, 'l, 'l, 'o, 10
```
```text:実行結果
$ vaxas -o write-2 write-2.s
$ vaxrun write-2
hello
hELLO
```

`1(r1)` の `1` は `r1` に対する差分を表します。この差分を**ディスプレースメント**と呼びます。

意味的には `(r1+1)` です。（この構文はエラーになります）

### 練習

【問4-1:5分】逆アセンブラを対応させてください。

【問4-2:10分】インタプリタを対応させてください。

## movb/movw

1文字や2文字の書き替えを行います。

```text:write-3.s
.word 0

# write(1, hello, 6);
movl $args1, ap
chmk $4


# r1 = hello;
# *(uint8_t *)r1 = 'H';
movl $hello, r1
movb $'H, (r1)

# write(1, hello, 6);
movl $args1, ap
chmk $4


# r1 = hello;
# *(uint16_t *)(r1 + 2) = 'L'|'L'<<8;
movl $hello, r1
movw $'L|'L<8, 2(r1)

# write(1, hello, 6);
movl $args1, ap
chmk $4


# exit(0);
movl $args2, ap
chmk $1


.data
args1: .long 3, 1, hello, 6
args2: .long 1, 0
hello: .byte 'h, 'e, 'l, 'l, 'o, 10
```
```text:実行結果
$ vaxas -o write-3 write-3.s
$ vaxrun write-3
hello
Hello
HeLLo
```

`movb` は `byte` 版、`movw` は `word` 版です。

### 練習

【問5-1:5分】逆アセンブラを対応させてください。

【問5-2:10分】インタプリタを対応させてください。

## レジスタの値をメモリに書き込む

数値をいったんレジスタに入れてからメモリに書き込みます。

```text:write-4.s
.word 0

# write(1, hello, 6);
movl $args1, ap
chmk $4


# r1 = hello;
# r0 = 'H'|'E'<<8|'L'<<16|'L'<<24;
# *(uint32_t *)r1 = r0;
movl $hello, r1
movl $'H|'E<8|'L<16|'L<24, r0
movl r0, (r1)

# write(1, hello, 6);
movl $args1, ap
chmk $4


# exit(0);
movl $args2, ap
chmk $1


.data
args1: .long 3, 1, hello, 6
args2: .long 1, 0
hello: .byte 'h, 'e, 'l, 'l, 'o, 10
```
```text:実行結果
$ vaxas -o write-4 write-4.s
$ vaxrun write-4
hello
HELLo
```

### 練習

【問6-1:5分】逆アセンブラを対応させてください。

【問6-2:15分】インタプリタを対応させてください。

## バイト命令

レジスタを `movb` 命令のソースに使うと、下位の値だけが使われます。

```text:write-5.s
.word 0

# write(1, hello, 6);
movl $args1, ap
chmk $4


# r1 = hello;
# r0 = 'H'|'E'<<8
# *(uint8_t *)r1 = r0;
movl $hello, r1
movl $'H|'E<8, r0
movb r0, (r1)

# write(1, hello, 6);
movl $args1, ap
chmk $4


# exit(0);
movl $args2, ap
chmk $1


.data
args1: .long 3, 1, hello, 6
args2: .long 1, 0
hello: .byte 'h, 'e, 'l, 'l, 'o, 10
```
```text:実行結果
$ vaxas -o write-5 write-5.s
$ vaxrun write-5
hello
Hello
```

### 練習

【問7-1:10分】逆アセンブラを対応させてください。

【問7-2:20分】インタプリタを対応させてください。

## アドレスを直接指定

今までメモリは `r1` レジスタ経由でアクセスしていました（これを**間接参照**と呼びます）。アドレスを直接指定でアクセスすることも可能です（これを**直接参照**と呼びます）。

```text:write-6.s
.word 0

# write(1, hello, 6);
movl $args1, ap
chmk $4


# *(uint32_t *)hello = 'H'|'E'<<8|'L'<<16|'L'<<24;
movl $'H|'E<8|'L<16|'L<24, hello

# write(1, hello, 6);
movl $args1, ap
chmk $4


# *(uint8_t *)(hello + 4) = 'O';
movb $'O, hello + 4

# write(1, hello, 6);
movl $args1, ap
chmk $4


# exit(0);
movl $args2, ap
chmk $1


.data
args1: .long 3, 1, hello, 6
args2: .long 1, 0
hello: .byte 'h, 'e, 'l, 'l, 'o, 10
```
```text:実行結果
$ vaxas -o write-6 write-6.s
$ vaxrun write-6
hello
HELLo
HELLO
```

### 相対アドレス

逆アセンブル結果から直接参照の該当箇所を抜き出します。

```text
0000000b: d0 8f 48 45 4c 4c ef 02  movl $0x4c4c4548,0x218
00000013: 02 00 00
```

要素に分解すると、アドレスが直接含まれていないことが分かります。

```text
0000000b: d0              # movl
0000000c: 8f 48 45 4c 4c  # $0x4c4c4548
00000011: ef 02 02 00 00  # 0x218
```

`0x202`→`0x218`となるのは、次の命令を基点とする相対アドレスだからです。

* `0x16`（基点） + `0x202`（相対アドレス） = `0x218`（絶対アドレス）

### 練習

【問8-1:5分】逆アセンブラを対応させてください。

【問8-2:10分】インタプリタを対応させてください。

## 引き算

引き算により小文字から大文字へ変換します。

```text:write-7.s
.word 0

# write(1, hello, 6);
movl $args1, ap
chmk $4


# *(uint32_t *)hello -= 0x20202020;
subl2 $0x20202020, hello

# write(1, hello, 6);
movl $args1, ap
chmk $4


# *(uint8_t *)(hello + 4) -= 0x20;
subb2 $0x20, hello + 4

# write(1, hello, 6);
movl $args1, ap
chmk $4


# exit(0);
movl $args2, ap
chmk $1


.data
args1: .long 3, 1, hello, 6
args2: .long 1, 0
hello: .byte 'h, 'e, 'l, 'l, 'o, 10
```
```text:実行結果
$ vaxas -o write-7 write-7.s
$ vaxrun write-7
hello
HELLo
HELLO
```

`subl2`や`subb2`の`2`は引数の数です。引数が3つの`subl3`と名前で区別しています。

### 練習

【問9-1:5分】逆アセンブラを対応させてください。

【問9-2:15分】インタプリタを対応させてください。

# 仕様書

今まで推測していた仕様を仕様書で確認してください。

* [VAX MACRO and Instruction Set Reference Manual (英語版の命令セットマニュアル)](http://www2.hmc.edu/www_common/OVMS072-OLD/72final/4515/4515pro.html)

# テストコード集

自作インタプリタで順番に動作させてください。

```1.c
int main() {
    write(1, "hello\n", 6);
    return 0;
}
```

```2.c
#include <stdio.h>

int main() {
    putchar('a');
    return 0;
}
```

```3.c
#include <stdio.h>

int main() {
    printf("hello\n");
    return 0;
}
```

```4.c
#include <stdio.h>

int main() {
    int a = 1234;
    printf("a=%d\n", a);
    return 0;
}
```

```5.c
#include <stdio.h>

int main(argc, argv)
    int argc;
    char *argv[];
{
    int i;
    for (i = 0; i < argc; ++i) {
        printf("argv[%d]=%s\n", i, argv[i]);
    }
    return 0;
}
```

## nm

既存のコマンドを自作インタプリタで動かしてみましょう。

```text
# nm a.out
```

## cc

ccは内部で色々なものを呼んでいます。これらを自作インタプリタで順番に動かして、最終的にはccから一括で処理できることを目指してください。

* `cc 1.c`
    * `/lib/cpp 1.c /tmp/ctm4a`
    * `/lib/ccom /tmp/ctm4a /tmp/ctm3a`
    * `/bin/as -o 1.o /tmp/ctm3a`
    * `/bin/ld -X /lib/crt0.o 1.o /lib/libc.a -l`

自作インタプリタでccを読んでハローワールドのビルドを目指してください。

## カーネルビルドへの道

ハローワールドがビルドできたら、以下の順にカーネルビルドを目指してください。

1. 他のテストコード（2.c～6.c）をビルドする
2. 32Vカーネルをビルドする
3. アセンブラをビルドする
4. コンパイラをビルドする
5. 3と4のセルフホスティングを確認する
6. セルフホスティングしたツールでカーネルをコンパイルする

ここまで出来れば、バイナリのトレース練習は終了です。

次はUNIX/32Vそのものを動かすことに挑戦しましょう！
