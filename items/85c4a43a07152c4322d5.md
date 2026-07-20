---
coediting: false
comments_count: 0
created_at: '2015-09-14T01:05:42+09:00'
id: 85c4a43a07152c4322d5
likes_count: 7
private: false
reactions_count: 0
stocks_count: 5
tags:
- name: VAX
  versions: []
- name: UNIX32V
  versions: []
title: UNIX/32VによるVAX事始め
updated_at: '2015-11-06T08:33:23+09:00'
url: https://qiita.com/7shi/items/85c4a43a07152c4322d5
slide: false
---

[PDP-11](https://ja.wikipedia.org/wiki/PDP-11)用の[UNIX V7](https://ja.wikipedia.org/wiki/Version_7_Unix)を[VAX](https://ja.wikipedia.org/wiki/VAX)に移植したのが[UNIX/32V](https://ja.wikipedia.org/wiki/UNIX/32V)です。UNIX/32Vを足掛かりにVAXの世界に踏み出してみます。

この記事には続編があります。

* [VAXの機械語を総当たり調査](http://qiita.com/7shi/items/7b24ed23fcbea08c3615) 2015.9.17

この記事には姉妹編があります。

* [S/390の機械語を総当たり調査](http://qiita.com/7shi/items/98c7aa38fe0bd29a7296) 2015.10.8

今回は逆アセンブルを目的とします。UNIX/32VのSIMHへのインストールは扱いませんが、以下の記事を参照してください。

* http://zazie.tom-yam.or.jp/starunix/
* [Installing 32v on SIMH - Computer History Wiki](http://gunkies.org/wiki/Installing_32v_on_SIMH)

※ [SIMH](http://simh.trailing-edge.com/) V3.9-0ではうまく動きません（[参照](https://twitter.com/7shi/status/661512014733250560)）。V3.8-1を推奨します。

# クロスコンパイラ

VAXの機械語を扱うため、VAXをターゲットにしたクロスコンパイラが必要です。以下の手順を参考に`vax-netbsdelf-gcc`をビルドしてください。

* [最低限のクロスコンパイラの作り方](http://qiita.com/7shi/items/2d44e040bae930d11088) 2015.01.30

## テスト

先の記事と同じテストをしてみます。

```add.c
int add(int a, int b) {
    return a + b;
}
```

コンパイルします。

```text
$ vax-netbsdelf-gcc -nostdlib -g -O add.c
/usr/lib/gcc/../../vax-netbsdelf/bin/ld: 警告: エントリシンボル _start が見つかりません。デフォルトとして 0000000000010054 を使用します
```

※ 警告は無視します。

出力されたバイナリ（a.out）を逆アセンブルして、どんな機械語が出力されているかを確認します。

```text
$ vax-netbsdelf-objdump -S a.out

a.out:     ファイル形式 elf32-vax


セクション .text の逆アセンブル:

00010054 <add>:
int add(int a, int b) {
   10054:       00 00           .word 0x0000 # Entry mask: < >
   10056:       c2 04 5e        subl2 $0x4,sp
    return a + b;
}
   10059:       c1 ac 04 ac     addl3 0x4(ap),0x8(ap),r0
   1005d:       08 50
   1005f:       04              ret
```

引数が`0x4(ap)`と`0x8(ap)`で渡されて、戻り値は`r0`で返される様子が読み取れます。

`ap`というのは引数（argument）を指すレジスタです。VAXではEntry maskに基づいてレジスタの退避が行われますが、その際に`sp`がどれだけ動いたのか分かりにくいため、`ap`という専用のレジスタで引数を指すようになっています。

# UNIX/32V

以下の2つのファイルをダウンロードします。

1. http://minnie.tuhs.org/Archive/VAX/Distributions/32V/file2.tar.gz
2. http://minnie.tuhs.org/Archive/VAX/Distributions/32V/32v_usr.tar.gz

ディレクトリを作って展開します。直接展開すると散らばります。

```text
$ mkdir 32v_root
$ tar xvf file2.tar.gz -C 32v_root
$ tar xvf 32v_usr.tar.gz -C 32v_root
```

※ 展開時にエラーが出ても無視します。

## サンプル探し

ファイルサイズ順にソートして小さめなコマンドを探します。

```text
$ ls -lS 32v_root/bin
（中略）
-rw-r--r-- 1 xxxx xxxx 3.8K 3月  27  1979 df
-rw-r--r-- 1 xxxx xxxx 1.9K 3月  27  1979 echo
-rw-r--r-- 1 xxxx xxxx    7 3月  27  1979 false
```

種類を推定してみます。

```text
$ file 32v_root/bin/df 32v_root/bin/echo 32v_root/bin/false
32v_root/bin/df:    a.out little-endian 32-bit pure executable
32v_root/bin/echo:  a.out little-endian 32-bit pure executable
32v_root/bin/false: ASCII text
```

falseはシェルスクリプトなので、バイナリとして小さいのはechoのようです。

## ファイルの分析

echoの先頭をダンプしてみます。

```text
$ hexdump -C 32v_root/bin/echo | head
00000000  08 01 00 00 bc 05 00 00  64 01 00 00 04 04 00 00  |........d.......|
00000010  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
00000020  00 00 c2 08 5e d0 ae 08  6e 9e ae 0c 50 d0 50 ae  |....^...n...P.P.|
00000030  04 d5 80 12 fc d1 50 be  04 19 02 d5 70 d0 50 ae  |......P.....p.P.|
00000040  08 d0 50 ef d8 05 00 00  fb 03 ef 0d 00 00 00 dd  |..P.............|
00000050  50 fb 01 ef 80 02 00 00  bc 01 00 00 00 0c c2 00  |P...............|
00000060  5e d4 5a d1 ac 04 01 15  25 d0 ac 08 50 d0 a0 04  |^.Z.....%...P...|
00000070  50 91 60 2d 12 18 d0 ac  08 50 d0 a0 04 50 91 a0  |P.`-.....P...P..|
00000080  01 8f 6e 12 09 d6 5a d7  ac 04 c0 04 ac 08 d0 01  |..n...Z.........|
00000090  5b 11 3b df cf 9d 05 dd  4b bc 08 fb 02 cf 64 00  |[.;.....K.....d.|
```

どうやら先頭の0x20バイト（00000000-0000001F）がヘッダのようです。

VAXは32bitなので、ヘッダの各項目は4バイトのリトルエンディアンのようです。0番地はマジックナンバー、4番地はtextのサイズ（0x5bc）、8番地はdataのサイズ（0x164）のようです。

ヘッダに示されたセグメントサイズの合計がファイルサイズ（0x740）に一致します。

* 0x20 + 0x5bc + 0x164 = 0x740

## 逆アセンブル

先ほどビルドしたvax-netbsdelf-objdumpではこの古いa.out形式は認識できません。

手動でtextを抽出します。（0x5bc = 1468）

```text
$ dd if=32v_root/bin/echo of=echo.text bs=1 skip=32 count=1468
1468+0 レコード入力
1468+0 レコード出力
1468 バイト (1.5 kB) コピーされました、 0.0178435 秒、 82.3 kB/秒
```

抽出したtextを生バイナリとしてファイル全体を逆アセンブルします。

```text
$ vax-netbsdelf-objdump -b binary -m vax -D echo.text

echo.text:     ファイル形式 binary


セクション .data の逆アセンブル:

00000000 <.data>:
   0:   00              halt
   1:   00              halt
   2:   c2 08 5e        subl2 $0x8,sp
   5:   d0 ae 08 6e     movl 0x8(sp),(sp)
   9:   9e ae 0c 50     movab 0xc(sp),r0
   d:   d0 50 ae 04     movl r0,0x4(sp)
（略）
```

※ 先頭の`halt`×2はエントリーマスクですが、シンボル情報がないため判別できません。

UNIX/32Vのファイルが逆アセンブルできました。これでようやくスタート地点に立てました。

# リンク

浜田直樹氏（[@xylnao11](https://twitter.com/xylnao11)）によるVAXやUNIX/32Vのスライドや記事です。

* [UNIX/32v on SIMH 接触編](http://www.slideshare.net/xylnao/unix32v)（[動画](http://www.youtube.com/watch?v=7ebzB96IKWE#t=3h19m00s)） 2010.2.23
* [UNIX/32V on SIMH 発動編](http://www.slideshare.net/xylnao/unix32-v-20100508) 2010.5.8
* [Dennis M. Ritchieのこと](http://www.tom-yam.or.jp/2238/annex2.html) 2011.12.17
