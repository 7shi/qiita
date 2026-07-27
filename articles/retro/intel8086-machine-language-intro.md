---
coediting: false
comments_count: 0
created_at: '2015-11-09T17:30:38+09:00'
id: b3911948f9d97b05395e
likes_count: 37
private: false
reactions_count: 0
stocks_count: 39
tags:
- name: Intel8086
  versions: []
title: 8086による機械語入門
updated_at: '2016-02-14T10:58:52+09:00'
url: https://qiita.com/7shi/items/b3911948f9d97b05395e
slide: false
---

8086とは16bitのx86です。UNIX V6の移植を想定したバイナリを通してUNIXを学習します。

※ UNIX V6の移植は完了していませんが、MINIXのコンパイラを流用してバイナリだけは生成できるようになっています。最終的にはUNIX V6のコンパイラも移植して置き換える計画でした。

この記事は以前開催していた[機械語入門・集中講座](http://connpass.com/series/593/)で教えていた内容をまとめたものです。

この記事には姉妹編があります。

* [PDP-11による機械語入門](http://qiita.com/7shi/items/86724696518df3a174dc) 2015.11.08
* [VAXによる機械語入門](http://qiita.com/7shi/items/e43e8ce0b1a2cadee2a3) 2016.02.14
* [Haskellによる8086逆アセンブラ開発入門](http://qiita.com/7shi/items/026839b2bc193dbfb0cb) 2014.08.31

# 環境設定

UNIX V6やMINIXのバイナリを動かすためのインタプリタと、その上で動く当時のコンパイラをインストールします。

* [インタプリタとコンパイラ一式をインストール](https://bitbucket.org/7shi/i8086tools/wiki/Home)

## コンパイル

ハローワールドでテストします。

```hello.c
main() {
    printf("hello\n");
    return 0;
}
```

※ UNIX V6にはlibcのヘッダがないため`#include`はしません。

先ほどインストールしたコンパイラで8086用のバイナリを生成します。警告は無視します。

```text
$ 8086v6-cc hello.c
"hello.c", line 1: (warning) 'main' old-fashioned function definition
"hello.c", line 2: (warning) implicit declaration of function printf
```

※ 8086v6-ccはシェルスクリプトで、インタプリタ上でMINIXのコンパイラ（8086バイナリ）を実行しています。

a.outというファイルが出力されます。バイナリはUNIX V6移植用の独自形式のため、fileコマンドではうまく認識されません。

```text
$ file a.out
a.out: data
```

## 実行

出力されたバイナリをインタプリタで実行します。

```text
$ 7run a.out
hello
```

## オプション

7runを引数なしで実行するとオプションが確認できます。

```
$ 7run
usage: 7run [-p] [-d|-v/-s] cmd [args ...]
    -p: PDP-11 mode
    -8: 8086/V6 mode
    -d: disassemble mode (not run)
    -m: verbose mode with memory dump
    -v: verbose mode (output syscall and disassemble)
    -s: syscall mode (output syscall)
```

よく使う`-d`と`-m`を説明します。

### 逆アセンブル

バイナリの中にどのような命令が入っているかを分析します。この操作を**逆アセンブル**と呼びます。

```text
$ 7run -d a.out
start:
0000: 58            pop ax
0001: 89e2          mov dx, sp
0003: 52            push dx
（略）
```

簡単なプログラムなのにすごく複雑だと感じられたと思います。入門にはあまりに複雑過ぎるため、今回の記事ではもっと簡単なものから始めます。基礎を固めてから、このバイナリに挑戦していただきます。

#### 読み方

`start`は**シンボル**と呼ばれ、見出しのようなものです。

その後は次のような構成になっています。

アドレス|機械語|アセンブリ言語
--------|------|--------------
`0000:` |`58`  |`pop ax`
`0001:` |`89e2`|`mov dx, sp`
`0003:` |`52`  |`push dx`

* **アドレス**は行番号のようなものです。そこにCPUに対する命令が入っています。
* 命令は数字で構成されており**機械語**と呼ばれます。ここでは16進数表記されています。
* 機械語は人間には読みにくいため、意味を英語の略語などで表記したものが**アセンブリ言語**です。

機械語やアセンブリ言語については後で詳しく見ていきます。

### トレース

命令やレジスタなどのログを表示しながら実行できます。この操作を**トレース**と呼びます。

```text
$ 7run -m a.out
 AX   BX   CX   DX   SP   BP   SI   DI  FLAGS IP
start:
0000 0000 0000 0000 fff6 0000 0000 0000 ---- 0000:58           pop ax
0001 0000 0000 0000 fff8 0000 0000 0000 ---- 0001:89e2         mov dx, sp
0001 0000 0000 fff8 fff8 0000 0000 0000 ---- 0003:52           push dx
（略）
```

逆アセンブルと異なるのは、命令が実行される順番に表示される点です。基本的には上から順番に実行されますが、分岐や関数呼び出しなどでアドレスが飛びます。

```text:例
0001 0000 0000 fff8 fff4 0000 0000 0000 ---- 0005:e80400       call 000c
_main:
0001 0000 0000 fff8 fff2 0000 0000 0000 ---- 000c:55           push bp
```

アドレスが飛んでいることを確認してください: `0005` → `000c`

## シンボル

逆アセンブルのときに出て来たシンボルを一覧表示します。

```text
$ v6nm a.out
01a2 d
01c6 b
01a2 d
（略）
016c T _strlen
0151 T _write
0000 t start
```

構成は次の通りです。シンボル名がないものは無視します。

アドレス|種類|シンボル名
--------|----|----------
`016c`  |`T` |`_strlen`
`0151`  |`T` |`_write`
`0000`  |`t` |`start`

種類は初めから細かく理解していなくても、大雑把に`T`と`t`が関数、それ以外は変数だと考えておけば良いです。それらがどのアドレスに関連付けられているかを示しています。

※ 関数や変数以外にも種類はありますが、当面は必要ありません。

## ファイルサイズの縮小

シンボルは付加的情報で実行には必要不可欠なものではありません。シンボルを削ってファイルサイズが縮小できます。

```text
$ wc -c a.out
662 a.out
$ v6strip a.out
$ wc -c a.out
470 a.out
```

シンボルがなくなっていることを確認します。

```text
$ v6nm a.out
no name list
```

実行には支障ありません。

```text
$ 7run a.out
hello
```

逆アセンブルでシンボルが出て来なくなります。

```text
$ 7run -d a.out
0000: 58            pop ax
0001: 89e2          mov dx, sp
0003: 52            push dx
（略）
```

シンボルがないと関数の切れ目などが分からなくなるためデバッグや解析が困難になります。次のような運用方法が一般的です。

* 開発時にはデバッグのためシンボルを付けておきます。
* 完成品をバイナリ配布する際には、ファイルサイズを縮小するためシンボルを取り除きます。ソース非公開の商用製品の場合、内部構造を解析されにくくする意図もあります。

# 小さなバイナリ

小さなバイナリを作って分析します。

```text:write.s
! write(1, hello, 6);
mov ax, #1
int 7
.data1 4
.data2 hello, 6

! exit(0);
mov ax, #0
int 7
.data1 1

.sect .data
hello: .ascii "hello\n"
```

* アセンブリ言語の文法はアセンブラによって方言があります。
    * このアセンブラでは`!`はコメントです。
* アセンブリ言語はCPUによって異なります。今回は8086です。
    * `ax` はレジスタと呼ばれます。変数のようなものです。
    * `mov` は代入です: `mov ax, #0` ⇒ `ax = 0`
    * `int` は割り込みを発生させる命令です。

バイナリを生成して実行します。

```text:実行結果
$ 8086v6-cc -.o write.s
$ v6strip a.out
$ 7run a.out
hello
```

`-.o` オプションはcrtやlibcをリンクしないオプションです。

* バイナリを小さくするためC言語のライブラリなどを外しました。
* `gcc -nostdlib` に相当します。
* 出力ファイルを指定する `-o` とは別なのに注意してください。

## システムコール

割り込みでカーネルを呼び出してOSの機能を利用することを**システムコール**と呼びます。

* `int 7`は移植版UNIX V6のシステムコール用の割り込みを発生させています。
    * `7`はPDP-11に合わせた仮の番号で、最終的には別の番号に変更する予定でした。
* `.data1` の後にシステムコール番号を指定します。
* `ax` は第一引数
    * `write` に渡す `1` は標準出力
* `.data2` は追加の引数

UNIX V6のシステムコール定義: [/usr/sys/ken/sysent.c](http://minnie.tuhs.org/cgi-bin/utree.pl?file=V6/usr/sys/ken/sysent.c)

```text
int sysent[]
{
    追加の引数の数, &処理関数, /* システムコール番号 = システムコール名 */
    ...
};
```

* `exit`: システムコール番号 1, 追加の引数の数 0
* `write`: システムコール番号 4, 追加の引数の数 2
* `sysent[] {` の間にイコールがないのはC言語が古いため（pre K&R）

## 逆アセンブル

バイナリを分析します。

```text
$ 7run -d a.out
0000: b80100        mov ax, 0001
0003: cd07          int 7
0005: 04            ; sys write
0006: 1000          ; arg
0008: 0600          ; arg
000a: b80000        mov ax, 0000
000d: cd07          int 7
000f: 01            ; sys exit
```

* write.s →（アセンブル）→ a.out →（逆アセンブル）→ 上記結果
    * アセンブル: アセンブリ言語 → バイナリ
    * 逆アセンブル: バイナリ → アセンブリ言語
* 逆とは言っても完全に元に戻るわけではありません。
    * 逆アセンブルでは対応するバイナリが確認できます。
* 逆アセンブラの出力はアセンブリ言語と文法が異なります。
    * MINIXのコンパイラを流用しているための過渡的な状態です。
    * 最終的には文法が一致するように独自のアセンブラを提供する予定でした。

## バイナリダンプ

バイナリを16進数で出力します。

```text
$ hd a.out
00000000  eb 0e 10 00 06 00 00 00  00 00 00 00 00 00 01 00  |................|
00000010  b8 01 00 cd 07 04 10 00  06 00 b8 00 00 cd 07 01  |................|
00000020  68 65 6c 6c 6f 0a                                 |hello.|
00000026
```

※ `hd` がない環境では `hexdump -C` や `od -tx1z -Ax` を使用します。

## メモリに読み込み

先頭の16バイトはヘッダです。ヘッダはメモリに配置しないため、ファイルのオフセットとメモリのアドレスは16バイトずれます。

```text:メモリ配置
0000 b8 01 00 cd 07 04 10 00 06 00 b8 00 00 cd 07 01  ................
0010 68 65 6c 6c 6f 0a                                hello.
```

* text（命令）＋data

## 仕様

コード例は擬似言語で示します。

* ヘッダ＋text（命令）＋data
* ヘッダは最初の16バイト

```text
aout = File.readAllBytes("a.out")
h = aout.slice(0, 16)
```

* ヘッダを2バイトずつ区切って、2番目がtextのサイズ、3番目がデータのサイズ。リトルエンディアン。
* 今回のサンプル: `tsize = 0x0010, dsize = 0x0006`

```text
tsize = h.read16Unsigned(2)
dsize = h.read16Unsigned(4)
```

* ヘッダの後にtextがあり、その後にdataがある。連続した領域なので一気にメモリに読み込みます。
* 「メモリに読み込み」はmemをダンプしたものです。

```text
mem = aout.slice(16, tsize + dsize)
```

## 練習

※ 制限時間内に作成できない場合、解答例に進んでください。

【問1-1:20分】ファイルをそのままバイナリダンプするプログラムを作ってください。（`hd a.out` 相当）

⇒ 解答例 ([F#](https://bitbucket.org/7shi/ikebin/src/tip/8086/1-1.fsx), [Python](https://bitbucket.org/7shi/ikebin/src/tip/8086/python/1-1.py))

【問1-2:10分】メモリに読み込んだ状態をバイナリダンプするプログラムを作ってください。

⇒ 解答例 ([F#](https://bitbucket.org/7shi/ikebin/src/tip/8086/1-2.fsx), [Python](https://bitbucket.org/7shi/ikebin/src/tip/8086/python/1-2.py))

【問2-1:1時間】逆アセンブラを作ってください。（`7run -d a.out` 相当）

⇒ 解答例 ([F#](https://bitbucket.org/7shi/ikebin/src/tip/8086/2-1.fsx), [Python](https://bitbucket.org/7shi/ikebin/src/tip/8086/python/2-1.py))

【問2-2:1時間】バイナリを実行してください。（`7run a.out` 相当）

⇒ 解答例 ([F#](https://bitbucket.org/7shi/ikebin/src/tip/8086/2-2.fsx), [Python](https://bitbucket.org/7shi/ikebin/src/tip/8086/python/2-2.py))

※ 以後、問2-2で作ったものを**インタプリタ**と呼びます。

# 少しずつ拡張

先ほど作った小さなバイナリを少しずつ拡張していきます。

## 数値をメモリに書き込む

メモリを操作して出力する文字列を変更します。

```text:write-1.s
! write(1, hello, 6);
mov ax, #1
int 7
.data1 4
.data2 hello, 6


! bx = hello;
! *(uint16_t *)bx = 0x4548;
mov bx, #hello
mov (bx), #0x4548

! write(1, hello, 6);
mov ax, #1
int 7
.data1 4
.data2 hello, 6


! exit(0);
mov ax, #0
int 7
.data1 1


.sect .data
hello: .ascii "hello\n"
```
```text:実行結果
$ 8086v6-cc -o write-1.out -.o write-1.s
$ 7run write-1.out
hello
HEllo
```

### 練習

【問3-1:5分】逆アセンブラを対応させてください。

⇒ 解答例 ([F#](https://bitbucket.org/7shi/ikebin/src/tip/8086/3-1.fsx), [Python](https://bitbucket.org/7shi/ikebin/src/tip/8086/python/3-1.py))

【問3-2:10分】インタプリタを対応させてください。

⇒ 解答例 ([F#](https://bitbucket.org/7shi/ikebin/src/tip/8086/3-2.fsx), [Python](https://bitbucket.org/7shi/ikebin/src/tip/8086/python/3-2.py))

## ディスプレースメント

相対アドレス指定によるメモリ操作を行います。

```text:write-2.s
! write(1, hello, 6);
mov ax, #1
int 7
.data1 4
.data2 hello, 6


! bx = hello;
! *(uint16_t *)(bx + 2) = 0x4548;
mov bx, #hello
mov 2(bx), #0x4548

! write(1, hello, 6);
mov ax, #1
int 7
.data1 4
.data2 hello, 6


! exit(0);
mov ax, #0
int 7
.data1 1


.sect .data
hello: .ascii "hello\n"
```
```text:実行結果
$ 8086v6-cc -o write-2.out -.o write-2.s
$ 7run write-2.out
hello
heHEo
```

`2(bx)` の `2` は `bx` に対する差分を表します。この差分を**ディスプレースメント**と呼びます。

別の文法では `[bx]` に対して `[bx+2]` と書きます。（今回の環境ではエラーになります）

### 練習

【問4-1:5分】逆アセンブラを対応させてください。

⇒ 解答例 ([F#](https://bitbucket.org/7shi/ikebin/src/tip/8086/4-1.fsx), [Python](https://bitbucket.org/7shi/ikebin/src/tip/8086/python/4-1.py))

【問4-2:10分】インタプリタを対応させてください。

⇒ 解答例 ([F#](https://bitbucket.org/7shi/ikebin/src/tip/8086/4-2.fsx), [Python](https://bitbucket.org/7shi/ikebin/src/tip/8086/python/4-2.py))

## movb

1文字だけの書き替えを行います。

```text:write-3.s
! write(1, hello, 6);
mov ax, #1
int 7
.data1 4
.data2 hello, 6


! bx = hello;
! *(uint8_t *)bx = 'H';
mov bx, #hello
movb (bx), #'H'

! write(1, hello, 6);
mov ax, #1
int 7
.data1 4
.data2 hello, 6


! bx = hello;
! *(uint8_t *)(bx + 2) = 'L';
mov bx, #hello
movb 2(bx), #'L'

! write(1, hello, 6);
mov ax, #1
int 7
.data1 4
.data2 hello, 6


! exit(0);
mov ax, #0
int 7
.data1 1


.sect .data
hello: .ascii "hello\n"
```
```text:実行結果
$ 8086v6-cc -o write-3.out -.o write-3.s
$ 7run write-3.out
hello
Hello
HeLlo
```

`movb` は `mov` の `byte` 版です。

別の文法では `[bx]` に対して `byte [bx]` と書きます。（今回の環境ではエラーになります）

### 練習

【問5-1:5分】逆アセンブラを対応させてください。

⇒ 解答例 ([F#](https://bitbucket.org/7shi/ikebin/src/tip/8086/5-1.fsx), [Python](https://bitbucket.org/7shi/ikebin/src/tip/8086/python/5-1.py))

【問5-2:10分】インタプリタを対応させてください。

⇒ 解答例 ([F#](https://bitbucket.org/7shi/ikebin/src/tip/8086/5-2.fsx), [Python](https://bitbucket.org/7shi/ikebin/src/tip/8086/python/5-2.py))

## レジスタの値をメモリに書き込む

数値をいったんレジスタに入れてからメモリに書き込みます。

```text:write-4.s
! write(1, hello, 6);
mov ax, #1
int 7
.data1 4
.data2 hello, 6


! bx = hello;
! ax = 0x4548;
! *(uint16_t *)bx = ax;
mov bx, #hello
mov ax, #0x4548
mov (bx), ax

! write(1, hello, 6);
mov ax, #1
int 7
.data1 4
.data2 hello, 6


! bx = hello;
! cx = 0x4c4c;
! *(uint16_t *)(bx + 2) = cx;
mov bx, #hello
mov cx, #0x4c4c
mov 2(bx), cx

! write(1, hello, 6);
mov ax, #1
int 7
.data1 4
.data2 hello, 6


! exit(0);
mov ax, #0
int 7
.data1 1


.sect .data
hello: .ascii "hello\n"
```
```text:実行結果
$ 8086v6-cc -o write-4.out -.o write-4.s
$ 7run write-4.out
hello
HEllo
HELLo
```

### 練習

【問6-1:5分】逆アセンブラを対応させてください。

⇒ 解答例 ([F#](https://bitbucket.org/7shi/ikebin/src/tip/8086/6-1.fsx), [Python](https://bitbucket.org/7shi/ikebin/src/tip/8086/python/6-1.py))

【問6-2:15分】インタプリタを対応させてください。

⇒ 解答例 ([F#](https://bitbucket.org/7shi/ikebin/src/tip/8086/6-2.fsx), [Python](https://bitbucket.org/7shi/ikebin/src/tip/8086/python/6-2.py))

## 8bit レジスタ

`ax` レジスタは `ah` と `al` に分解できます（High, Low）。`cx` レジスタも同様です。

```text:write-5.s
! write(1, hello, 6);
mov ax, #1
int 7
.data1 4
.data2 hello, 6


! bx = hello;
! ax = 0x4548;
! *(uint8_t *)bx = al;
! *(uint8_t *)(bx + 1) = ah;
mov bx, #hello
mov ax, #0x4548
movb (bx), al
movb 1(bx), ah

! write(1, hello, 6);
mov ax, #1
int 7
.data1 4
.data2 hello, 6


! bx = hello;
! ch = 'H';
! cl = 'E';
! *(uint16_t *)bx = cx;
mov bx, #hello
movb ch, #'H'
movb cl, #'E'
mov (bx), cx

! write(1, hello, 6);
mov ax, #1
int 7
.data1 4
.data2 hello, 6


! exit(0);
mov ax, #0
int 7
.data1 1


.sect .data
hello: .ascii "hello\n"
```
```text:実行結果
$ 8086v6-cc -o write-5.out -.o write-5.s
$ 7run write-5.out
hello
HEllo
EHllo
```

### 練習

【問7-1:10分】逆アセンブラを対応させてください。

⇒ 解答例 ([F#](https://bitbucket.org/7shi/ikebin/src/tip/8086/7-1.fsx), [Python](https://bitbucket.org/7shi/ikebin/src/tip/8086/python/7-1.py))

【問7-2:20分】インタプリタを対応させてください。

⇒ 解答例 ([F#](https://bitbucket.org/7shi/ikebin/src/tip/8086/7-2.fsx), [Python](https://bitbucket.org/7shi/ikebin/src/tip/8086/python/7-2.py))

## アドレスを直接指定

今までメモリは `bx` レジスタ経由でアクセスしていました（これを**間接参照**と呼びます）。アドレスを直接指定でアクセスすることも可能です（これを**直接参照**と呼びます）。

```text:write-6.s
! write(1, hello, 6);
mov ax, #1
int 7
.data1 4
.data2 hello, 6


! *(uint16_t *)hello = 0x4548;
mov hello, #0x4548

! write(1, hello, 6);
mov ax, #1
int 7
.data1 4
.data2 hello, 6


! *(uint16_t *)(hello + 2) = 0x4c4c;
mov hello + 2, #0x4c4c

! write(1, hello, 6);
mov ax, #1
int 7
.data1 4
.data2 hello, 6


! *(uint8_t *)(hello + 4) = 'O';
movb hello + 4, #'O'

! write(1, hello, 6);
mov ax, #1
int 7
.data1 4
.data2 hello, 6


! exit(0);
mov ax, #0
int 7
.data1 1


.sect .data
hello: .ascii "hello\n"
```
```text:実行結果
$ 8086v6-cc -o write-6.out -.o write-6.s
$ 7run write-6.out
hello
HEllo
HELLo
HELLO
```

### 練習

【問8-1:5分】逆アセンブラを対応させてください。

⇒ 解答例 ([F#](https://bitbucket.org/7shi/ikebin/src/tip/8086/8-1.fsx), [Python](https://bitbucket.org/7shi/ikebin/src/tip/8086/python/8-1.py))

【問8-2:10分】インタプリタを対応させてください。

⇒ 解答例 ([F#](https://bitbucket.org/7shi/ikebin/src/tip/8086/8-2.fsx), [Python](https://bitbucket.org/7shi/ikebin/src/tip/8086/python/8-2.py))

## 引き算

引き算により小文字から大文字へ変換します。

```text:write-7.s
! write(1, hello, 6);
mov ax, #1
int 7
.data1 4
.data2 hello, 6


! *(uint16_t *)hello -= 0x2020;
sub hello, #0x2020

! write(1, hello, 6);
mov ax, #1
int 7
.data1 4
.data2 hello, 6


! *(uint16_t *)(hello + 2) -= 0x2020;
sub hello + 2, #0x2020

! write(1, hello, 6);
mov ax, #1
int 7
.data1 4
.data2 hello, 6


! *(uint8_t *)(hello + 4) -= 0x20;
subb hello + 4, #0x20

! write(1, hello, 6);
mov ax, #1
int 7
.data1 4
.data2 hello, 6


! exit(0);
mov ax, #0
int 7
.data1 1


.sect .data
hello: .ascii "hello\n"
```
```text:実行結果
$ 8086v6-cc -o write-7.out -.o write-7.s
$ 7run write-7.out
hello
HEllo
HELLo
HELLO
```

### 練習

【問9-1:5分】逆アセンブラを対応させてください。

⇒ 解答例 ([F#](https://bitbucket.org/7shi/ikebin/src/tip/8086/9-1.fsx), [Python](https://bitbucket.org/7shi/ikebin/src/tip/8086/python/9-1.py))

【問9-2:15分】インタプリタを対応させてください。

⇒ 解答例 ([F#](https://bitbucket.org/7shi/ikebin/src/tip/8086/9-2.fsx), [Python](https://bitbucket.org/7shi/ikebin/src/tip/8086/python/9-2.py))

# レジスタの規則

レジスタは AX, BX, CX, DX, SP, BP, SI, DI の8個です。

これらを代入してバイナリの変化規則を調べます。

```text:regs.s
mov ax, #0
mov bx, #0
mov cx, #0
mov dx, #0
mov sp, #0
mov bp, #0
mov si, #0
mov di, #0
```

このコードはバイナリを見るためのものなので、実行する必要はありません。

## 練習

【20分】規則を見付けて、逆アセンブラとインタプリタを対応させてください。

### 解答例

F#でのみ示します。

```fsharp
let regs  = [| "ax"; "cx"; "dx"; "bx"
               "sp"; "bp"; "si"; "di" |]
let regs8 = [| "al"; "cl"; "dl"; "bl"
               "ah"; "ch"; "dh"; "bh" |]
```
```fsharp
    | 0x88, op when op &&& 0b11000111 = 0b00000111 ->
        let rn = op >>> 3
        show 2 (sprintf "mov [bx], %s" regs8.[rn])
    | 0x88, op when op &&& 0b11000111 = 0b01000111 ->
        let rn = (op >>> 3) &&& 0b111
        let disp = mem.[ip + 2]
        show 3 (sprintf "mov [bx+%x], %s" disp regs8.[rn])
    | 0x89, op when op &&& 0b11000111 = 0b00000111 ->
        let rn = op >>> 3
        show 2 (sprintf "mov [bx], %s" regs.[rn])
    | 0x89, op when op &&& 0b11000111 = 0b01000111 ->
        let rn = (op >>> 3) &&& 0b111
        let disp = mem.[ip + 2]
        show 3 (sprintf "mov [bx+%x], %s" disp regs.[rn])
    | op, n when 0xb0 <= op && op <= 0xb7 ->
        let rn = op - 0xb0
        show 2 (sprintf "mov %s, %02x" regs8.[rn] n)
    | op, _ when 0xb8 <= op && op <= 0xbf ->
        let n = read16 mem (ip + 1)
        let rn = op - 0xb8
        show 3 (sprintf "mov %s, %04x" regs.[rn] n)
```

# 仕様書

今まで推測していた仕様をデータシートで確認してください。最初の回路図は飛ばして、最後の命令表を参照してください。

* [231455-005.pdf](http://datasheets.chipdb.org/Intel/x86/808x/datashts/8086/231455-005.pdf)

データシートにはいくつか誤植があります。

* 誤baa → 正daa
* 誤ssb → 正sbb
    * Immediate with Accumulator: 誤000111w → 正0001110w

データシートの略語で代表的なものを示します。

* DISP → displacement: [bx+2]の+2
* mod → mode

## 練習

仕様書を基に、今まで作った逆アセンブラとインタプリタをリファクタリングしてください。

# 今後の展望

ここから先はC言語のハローワールドの動作を目指すと良いでしょう。

しかしUNIX V6の8086移植が完了していないため、その先は別のOSを使うことになります。

今の延長線上では、MINIX 2(16bit)のバイナリを動かしてカーネルビルドを目指す方法があります。マイクロカーネルのためシステムコールの形態が異なりますが、それ以外はほとんど同じです。

※ 2015年11月現在、達成者1名

コマンドではなくOSそのものの動作を目指す方法もあります。BIOSだけで動く[MEG-OS Z](https://github.com/neri/osz/)がお勧めです。その後に[FreeDOS](http://www.freedos.org/)を動かすのは、それほど難しくないでしょう。

2015年11月現在、達成者はいません。私が見本として作ったエミュレータがあります。

* https://bitbucket.org/7shi/8086run

その後でハードの実装に進み、MINIX 2の動作を目指した後、それを使ってUNIX V6の移植を行う計画でした。移植が完了すれば、この記事もすべて移植版UNIX V6で完結できるわけですが、その目途は立っていません。
