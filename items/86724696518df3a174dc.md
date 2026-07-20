---
coediting: false
comments_count: 0
created_at: '2015-11-08T10:37:18+09:00'
id: 86724696518df3a174dc
likes_count: 20
private: false
reactions_count: 0
stocks_count: 20
tags:
- name: PDP11
  versions: []
title: PDP-11による機械語入門
updated_at: '2016-02-14T10:58:14+09:00'
url: https://qiita.com/7shi/items/86724696518df3a174dc
slide: false
---

PDP-11とはUNIX V6の動作対象となるアーキテクチャです。バイナリを通してUNIXを学習します。

この記事は以前開催していた[池袋バイナリ勉強会](http://connpass.com/series/182/)の初回編で教えていた内容をまとめたものです。

この記事には姉妹編があります。

* [8086による機械語入門](http://qiita.com/7shi/items/b3911948f9d97b05395e) 2015.11.09
* [VAXによる機械語入門](http://qiita.com/7shi/items/e43e8ce0b1a2cadee2a3) 2016.02.14

# 環境設定

UNIX V6のバイナリを動かすためのインタプリタと、その上で動く当時のコンパイラをインストールします。

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

先ほどインストールしたコンパイラでPDP-11用のバイナリを生成します。

```text
$ v6cc hello.c
```

※ v6ccはシェルスクリプトで、インタプリタ上で当時のコンパイラ（PDP-11バイナリ）を実行しています。

a.outというファイルが出力されます。PDP-11用のバイナリであることを確認します。

```text
$ file a.out
a.out: PDP-11 executable not stripped
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

[crt0.o]
start:
0000: f009            setd
0002: 1180            mov sp, r0
0004: 1226            mov (r0), -(sp)
（略）
```

簡単なプログラムなのにすごく複雑だと感じられたと思います。入門にはあまりに複雑過ぎるため、今回の記事ではもっと簡単なものから始めます。基礎を固めてから、このバイナリに挑戦していただきます。

#### 読み方

`[crt0.o]`や`start`は**シンボル**と呼ばれ、見出しのようなものです。

その後は次のような構成になっています。

アドレス|機械語|アセンブリ言語
--------|------|--------------
`0000:` |`f009`|`setd`
`0002:` |`1180`|`mov sp, r0`
`0004:` |`1226`|`mov (r0), -(sp)`

* **アドレス**は行番号のようなものです。そこにCPUに対する命令が入っています。
* 命令は数字で構成されており**機械語**と呼ばれます。ここでは16進数表記されています。
* 機械語は人間には読みにくいため、意味を英語の略語などで表記したものが**アセンブリ言語**です。

機械語やアセンブリ言語については後で詳しく見ていきます。

### トレース

命令やレジスタなどのログを表示しながら実行できます。この操作を**トレース**と呼びます。

```text
$ 7run -m a.out
 r0   r1   r2   r3   r4   r5   sp  flags pc
start:
0000 0000 0000 0000 0000 0000 fff6 ---- 0000:f009 setd
0000 0000 0000 0000 0000 0000 fff6 ---- 0002:1180 mov sp, r0
fff6 0000 0000 0000 0000 0000 fff6 -N-- 0004:1226 mov (r0), -(sp) ;[fff6]0001 ;[fff4]0000
（略）
```

逆アセンブルと異なるのは、命令が実行される順番に表示される点です。基本的には上から順番に実行されますが、分岐や関数呼び出しなどでアドレスが飛びます。

```text:例
fff8 0000 0000 0000 0000 0000 fff4 -N-- 000c:09f7 0008      jsr pc, 0018 ;[0018]0977
_main:
fff8 0000 0000 0000 0000 0000 fff2 -N-- 0018:0977 023c      jsr r5, 0258 ;[0258]1140
csv:
fff8 0000 0000 0000 0000 001c fff0 -N-- 0258:1140           mov r5, r0
```

アドレスが飛んでいることを確認してください: `000c` → `0018` → `0258`

## シンボル

逆アセンブルのときに出て来たシンボルを一覧表示します。

```text
$ v6nm a.out
024e T _exit
020c T _flush
02be B _fout
（略）
027c d swtab
02b4 b width
0018 t ~main
```

構成は次の通りです。

アドレス|種類|シンボル名
--------|----|----------
`024e`  |`T` |`_exit`
`020c`  |`T` |`_flush`
`02be`  |`B` |`_fout`

種類は初めから細かく理解していなくても、大雑把に`T`と`t`が関数、それ以外は変数だと考えておけば良いです。それらがどのアドレスに関連付けられているかを示しています。

※ 関数や変数以外にも種類はありますが、当面は必要ありません。

## ファイルサイズの縮小

シンボルは付加的情報で実行には必要不可欠なものではありません。シンボルを削ってファイルサイズが縮小できます。

```text
$ wc -c a.out
1186 a.out
$ v6strip a.out
$ wc -c a.out
706 a.out
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
0000: f009            setd
0002: 1180            mov sp, r0
0004: 1226            mov (r0), -(sp)
（略）
```

シンボルがないと関数の切れ目などが分からなくなるためデバッグや解析が困難になります。次のような運用方法が一般的です。

* 開発時にはデバッグのためシンボルを付けておきます。
* 完成品をバイナリ配布する際には、ファイルサイズを縮小するためシンボルを取り除きます。ソース非公開の商用製品の場合、内部構造を解析されにくくする意図もあります。

# 小さなバイナリ

小さなバイナリを作って分析します。

```text:write.s
/ write(1, hello, 6);
mov $1, r0
sys write
hello
6

/ exit(0);
mov $0, r0
sys exit

.data
hello: <hello\n>
```
```text:実行結果
$ v6as write.s
$ v6strip a.out
$ 7run a.out
hello
```

* アセンブリ言語の文法はアセンブラによって方言があります。
    * このアセンブラでは`/`はコメントです。
* アセンブリ言語はCPUによって異なります。今回はPDP-11です。
    * `r0` はレジスタと呼ばれます。変数のようなものです。
    * `mov` は前から後ろに代入します: `mov $0, r0` ⇒ `r0 = 0`
    * `sys` は割り込みを発生させる命令です。

## システムコール

割り込みでカーネルを呼び出してOSの機能を利用することを**システムコール**と呼びます。

* `sys` の後にシステムコール名を書きます: `write`, `exit` など
* `r0` は第一引数
    * `write` に渡す `1` は標準出力
* `sys` の次の行には追加の引数を書きます。

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
0000: 15c0 0001       mov $1, r0
0004: 8904            sys 4 ; write
0006: 0010            ; arg
0008: 0006            ; arg
000a: 15c0 0000       mov $0, r0
000e: 8901            sys 1 ; exit
```

* write.s →（アセンブル）→ a.out →（逆アセンブル）→ 上記結果
    * アセンブル: アセンブリ言語 → バイナリ
    * 逆アセンブル: バイナリ → アセンブリ言語
* 逆とは言っても完全に元に戻るわけではありません。
    * 逆アセンブルでは対応するバイナリが確認できます。
* 逆アセンブラの出力はアセンブリ言語の文法とは異なります。
    * アセンブリ言語は8進数
    * 逆アセンブラは16進数

## バイナリダンプ

バイナリを16進数で出力します。

```text
$ hd a.out
00000000  07 01 10 00 06 00 00 00  00 00 00 00 00 00 01 00  |................|
00000010  c0 15 01 00 04 89 10 00  06 00 c0 15 00 00 01 89  |................|
00000020  68 65 6c 6c 6f 0a                                 |hello.|
00000026
```

※ `hd` がない環境では `hexdump -C` や `od -tx1z -Ax` を使用します。

## メモリに読み込み

先頭の16バイトはヘッダです。ヘッダはメモリに配置しないため、ファイルのオフセットとメモリのアドレスは16バイトずれます。

```text:メモリ配置
0000 c0 15 01 00 04 89 10 00 06 00 c0 15 00 00 01 89 ................
0010 68 65 6c 6c 6f 0a                               hello.
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

⇒ [解答例 (F#)](https://bitbucket.org/7shi/ikebin/src/tip/pdp11/1-1.fsx)

【問1-2:10分】メモリに読み込んだ状態をバイナリダンプするプログラムを作ってください。

⇒ [解答例 (F#)](https://bitbucket.org/7shi/ikebin/src/tip/pdp11/1-2.fsx)

【問2-1:1時間】逆アセンブラを作ってください。（`7run -d a.out` 相当）

⇒ [解答例 (F#)](https://bitbucket.org/7shi/ikebin/src/tip/pdp11/2-1.fsx)

【問2-2:1時間】バイナリを実行してください。（`7run a.out` 相当）

⇒ [解答例 (F#)](https://bitbucket.org/7shi/ikebin/src/tip/pdp11/2-2.fsx)

※ 以後、問2-2で作ったものを**インタプリタ**と呼びます。

# 少しずつ拡張

先ほど作った小さなバイナリを少しずつ拡張していきます。

## 数値をメモリに書き込む

メモリを操作して出力する文字列を変更します。

```text:write-1.s
/ write(1, hello, 6);
mov $1, r0
sys write
hello
6


/ r1 = hello;
/ *(uint16_t *)r1 = 0x4548;
mov $hello, r1
mov $42510, (r1)

/ write(1, hello, 6);
mov $1, r0
sys write
hello
6


/ exit(0);
mov $0, r0
sys exit


.data
hello: <hello\n>
```
```text:実行結果
$ v6as write-1.s
$ mv a.out write-1.out
$ 7run write-1.out
hello
HEllo
```

### 練習

【問3-1:5分】逆アセンブラを対応させてください。

⇒ [解答例 (F#)](https://bitbucket.org/7shi/ikebin/src/tip/pdp11/3-1.fsx)

【問3-2:10分】インタプリタを対応させてください。

⇒ [解答例 (F#)](https://bitbucket.org/7shi/ikebin/src/tip/pdp11/3-2.fsx)

## ディスプレースメント

相対アドレス指定によるメモリ操作を行います。

```text:write-2.s
/ write(1, hello, 6);
mov $1, r0
sys write
hello
6


/ r1 = hello;
/ *(uint16_t *)(r1 + 2) = 0x4548;
mov $hello, r1
mov $42510, 2(r1)

/ write(1, hello, 6);
mov $1, r0
sys write
hello
6


/ exit(0);
mov $0, r0
sys exit


.data
hello: <hello\n>
```
```text:実行結果
$ v6as write-2.s
$ mv a.out write-2.out
$ 7run write-2.out
hello
heHEo
```

`2(r1)` の `2` は `r1` に対する差分を表します。この差分を**ディスプレースメント**と呼びます。

意味的には `(r1+2)` です。（この構文はエラーになります）

### 練習

【問4-1:5分】逆アセンブラを対応させてください。

⇒ [解答例 (F#)](https://bitbucket.org/7shi/ikebin/src/tip/pdp11/4-1.fsx)

【問4-2:10分】インタプリタを対応させてください。

⇒ [解答例 (F#)](https://bitbucket.org/7shi/ikebin/src/tip/pdp11/4-2.fsx)

## movb

1文字だけの書き替えを行います。

```text:write-3.s
/ write(1, hello, 6);
mov $1, r0
sys write
hello
6


/ r1 = hello;
/ *(uint8_t *)r1 = 'H';
mov $hello, r1
movb $110, (r1)

/ write(1, hello, 6);
mov $1, r0
sys write
hello
6


/ r1 = hello;
/ *(uint8_t *)(r1 + 2) = 'L';
mov $hello, r1
movb $114, 2(r1)

/ write(1, hello, 6);
mov $1, r0
sys write
hello
6


/ exit(0);
mov $0, r0
sys exit


.data
hello: <hello\n>
```
```text:実行結果
$ v6as write-3.s
$ mv a.out write-3.out
$ 7run write-3.out
hello
Hello
HeLlo
```

`movb` は `mov` の `byte` 版です。

### 練習

【問5-1:5分】逆アセンブラを対応させてください。

⇒ [解答例 (F#)](https://bitbucket.org/7shi/ikebin/src/tip/pdp11/5-1.fsx)

【問5-2:10分】インタプリタを対応させてください。

⇒ [解答例 (F#)](https://bitbucket.org/7shi/ikebin/src/tip/pdp11/5-2.fsx)

## レジスタの値をメモリに書き込む

数値をいったんレジスタに入れてからメモリに書き込みます。

```text:write-4.s
/ write(1, hello, 6);
mov $1, r0
sys write
hello
6


/ r1 = hello;
/ r0 = 0x4548;
/ *(uint16_t *)r1 = r0;
mov $hello, r1
mov $42510, r0
mov r0, (r1)

/ write(1, hello, 6);
mov $1, r0
sys write
hello
6


/ r1 = hello;
/ r2 = 0x4c4c;
/ *(uint16_t *)(r1 + 2) = r2;
mov $hello, r1
mov $46114, r2
mov r2, 2(r1)

/ write(1, hello, 6);
mov $1, r0
sys write
hello
6


/ exit(0);
mov $0, r0
sys exit


.data
hello: <hello\n>
```
```text:実行結果
$ v6as write-4.s
$ mv a.out write-4.out
$ 7run write-4.out
hello
HEllo
HELLo
```

### 練習

【問6-1:5分】逆アセンブラを対応させてください。

⇒ [解答例 (F#)](https://bitbucket.org/7shi/ikebin/src/tip/pdp11/6-1.fsx)

【問6-2:15分】インタプリタを対応させてください。

⇒ [解答例 (F#)](https://bitbucket.org/7shi/ikebin/src/tip/pdp11/6-2.fsx)

## バイト命令

レジスタを `movb` 命令のソースに使うと、下位の値だけが使われます。`swab` 命令で上位と下位を入れ替えることができます。

```text:write-5.s
/ write(1, hello, 6);
mov $1, r0
sys write
hello
6


/ r1 = hello;
/ r0 = 0x4548;
/ *(uint8_t *)r1 = r0;
/ r0 = (r0 << 8) | (r0 >> 8);
/ *(uint8_t *)(r1 + 1) = r0;
mov $hello, r1
mov $42510, r0
movb r0, (r1)
swab r0
movb r0, 1(r1)

/ write(1, hello, 6);
mov $1, r0
sys write
hello
6


/ exit(0);
mov $0, r0
sys exit


.data
hello: <hello\n>
```
```text:実行結果
$ v6as write-5.s
$ mv a.out write-5.out
$ 7run write-5.out
hello
HEllo
```

### 練習

【問7-1:10分】逆アセンブラを対応させてください。

⇒ [解答例 (F#)](https://bitbucket.org/7shi/ikebin/src/tip/pdp11/7-1.fsx)

【問7-2:20分】インタプリタを対応させてください。

⇒ [解答例 (F#)](https://bitbucket.org/7shi/ikebin/src/tip/pdp11/7-2.fsx)

## アドレスを直接指定

今までメモリは `r1` レジスタ経由でアクセスしていました（これを**間接参照**と呼びます）。アドレスを直接指定でアクセスすることも可能です（これを**直接参照**と呼びます）。

```text:write-6.s
/ write(1, hello, 6);
mov $1, r0
sys write
hello
6


/ *(uint16_t *)hello = 0x4548;
mov $42510, hello

/ write(1, hello, 6);
mov $1, r0
sys write
hello
6


/ *(uint16_t *)(hello + 2) = 0x4c4c;
mov $46114, hello + 2

/ write(1, hello, 6);
mov $1, r0
sys write
hello
6


/ *(uint8_t *)(hello + 4) = 'O';
movb $117, hello + 4

/ write(1, hello, 6);
mov $1, r0
sys write
hello
6


/ exit(0);
mov $0, r0
sys exit


.data
hello: <hello\n>
```
```text:実行結果
$ v6as write-6.s
$ mv a.out write-6.out
$ 7run write-6.out
hello
HEllo
HELLo
HELLO
```

### 相対アドレス

逆アセンブル結果を見ると、バイナリとアドレスに乖離があります。

```text
000a: 15f7 4548 0030  mov $4548, 0040
```

バイナリを並べ直します。

```text
000a: 15f7
000c: 4548
000e: 0030 → これが0040になる
0010: (次)
```

`0030`→`0040`となるのは、次のアドレスを基点とする相対アドレスだからです。

* `0010`（基点） + `0030`（相対アドレス） = `0040`（絶対アドレス）

### 練習

【問8-1:5分】逆アセンブラを対応させてください。

⇒ [解答例 (F#)](https://bitbucket.org/7shi/ikebin/src/tip/pdp11/8-1.fsx)

【問8-2:10分】インタプリタを対応させてください。

⇒ [解答例 (F#)](https://bitbucket.org/7shi/ikebin/src/tip/pdp11/8-2.fsx)

## 引き算

引き算により小文字から大文字へ変換します。

```text:write-7.s
/ write(1, hello, 6);
mov $1, r0
sys write
hello
6


/ *(uint16_t *)hello -= 0x2020;
sub $20040, hello

/ write(1, hello, 6);
mov $1, r0
sys write
hello
6


/ *(uint16_t *)(hello + 2) -= 0x2020;
sub $20040, hello + 2

/ write(1, hello, 6);
mov $1, r0
sys write
hello
6


/ exit(0);
mov $0, r0
sys exit


.data
hello: <hello\n>
```
```text:実行結果
$ v6as write-7.s
$ mv a.out write-7.out
$ 7run write-7.out
hello
HEllo
HELLo
```

### 練習

【問9-1:5分】逆アセンブラを対応させてください。

⇒ [解答例 (F#)](https://bitbucket.org/7shi/ikebin/src/tip/pdp11/9-1.fsx)

【問9-2:15分】インタプリタを対応させてください。

⇒ [解答例 (F#)](https://bitbucket.org/7shi/ikebin/src/tip/pdp11/9-2.fsx)

# 仕様書

今まで推測していた仕様を仕様書で確認してください。

PDP-11/40 Processor Handbook (P.198～199)

* [UNIXv6 ハードウェア資料](http://d.hatena.ne.jp/syuu1228/20101101/1288601688)

## 練習

仕様書を基に、今まで作った逆アセンブラとインタプリタをリファクタリングしてください。

# テストコード集

自作インタプリタで順番に動作させてください。

```1.c
main() {
    write(1, "hello\n", 6);
}
```

```2.c
main() {
    putchar('a');
}
```

```3.c
main() {
    printf("hello\n");
}
```

```4.c
main() {
    int a;
    a = 1234;
    printf("a=%d\n", a);
}
```

```5.c
main(argc, argv) char **argv; {
    int i;
    for(i = 0; i < argc; i++)
        printf("argv[%d]=%s\n", i, argv[i]);
}
```

```6.c
main() {
    printo(012345);
}

printo(v) {
    int i;
    putchar(v < 0 ? '1' : '0');
    for (i = 0; i < 5; i++) {
        putchar(((v >> 12) & 7) + '0');
        v =<< 3;
    }
}
```

## nm

既存のコマンドを自作インタプリタで動かしてみましょう。

```text
# nm a.out
```

※ 2015年11月現在、達成者4名

## cc

ccは内部で色々なものを呼んでいます。これらを自作インタプリタで順番に動かして、最終的にはccから一括で処理できることを目指してください。

* cc 1.c
    * /lib/c0 1.c /tmp/ctm1a /tmp/ctm2a
    * /lib/c1 /tmp/ctm1a /tmp/ctm2a /tmp/ctm3a
    * /bin/as - /tmp/ctm3a
        * /lib/as2 /tmp/atm1a /tmp/atm2a /tmp/atm3a -g
    * /bin/ld -X /lib/crt0.o test.o -lc –l

自作インタプリタでccを読んでハローワールドのビルドを目指してください。

### カーネルビルドへの道

ハローワールドがビルドできたら、以下の順にカーネルビルドを目指してください。

1. 他のテストコード（2.c～6.c）をビルドする
2. V6カーネルをビルドする
3. アセンブラをビルドする
4. コンパイラをビルドする
5. 3と4のセルフホスティングを確認する
6. セルフホスティングしたツールでカーネルをコンパイルする

ここまで出来れば、バイナリのトレース練習は終了です。

※ 2015年11月現在、達成者3名

次はUNIX V6そのものを動かすことに挑戦しましょう！

※ 2015年12月6日現在、達成者1名

<blockquote class="twitter-tweet" lang="ja"><p lang="ja" dir="ltr">TM11のブートローダ→dist.tapのブートローダプログラム→dist.tapをrk0に展開→rk0を起動デバイスにしてUnixv6を起動→dist.tapのsrcをrk1に展開→rk1を/usr/souceにマウント→カーネルコンパイルまでエミュレートできたよ！</p>&mdash; kano (@kanorimon) <a href="https://twitter.com/kanorimon/status/673406597809352704">2015, 12月 6</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>
<blockquote class="twitter-tweet" lang="ja"><p lang="ja" dir="ltr">まとめていただきました .<a href="https://twitter.com/7shi">@7shi</a> さんの「PDP-11エミュレータ実装への道」をお気に入りにしました。 <a href="https://t.co/y0Xe7ebIr3">https://t.co/y0Xe7ebIr3</a></p>&mdash; kano (@kanorimon) <a href="https://twitter.com/kanorimon/status/673819936037330944">2015, 12月 7</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>
