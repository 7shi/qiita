---
coediting: false
comments_count: 0
created_at: '2014-12-16T15:40:02+09:00'
id: 8985e7719347f048e094
likes_count: 4
private: false
reactions_count: 0
stocks_count: 3
tags:
- name: assembly
  versions:
  - SH
title: SHのPC相対について
updated_at: '2014-12-18T21:53:29+09:00'
url: https://qiita.com/7shi/items/8985e7719347f048e094
slide: false
---

【追記】元記事が修正されました。

『[熱血！アセンブラ入門](http://www.shuwasystem.co.jp/products/7980html/4180.html)』の[書籍の補足情報](http://kozos.jp/books/asm/information.html)に以下の記述があります。

> ■ SHのＰＣ相対について (2014/10/04)
> 
> ＰＣ相対によるメモリアクセスの際に，ＰＣの値が４バイトアラインメントされて いるという記述がありますが，すみませんちょっと筆者の勘違いが残ってしまって いたようです．(情けない…) 
> 
> sh-elf.dを実際に見てみたところ，以下のようになっているようです． 
> 
> ・ ＰＣ(プログラムカウンタ)は，２つ先の命令を指している． 
> ・ mov.wで２バイトをＰＣ相対でロードする際には，ＰＣ＋オフセットで アドレスを計算している．(単純に加算するだけ) 
> ・ mov.lで４バイトをＰＣ相対でロードする際には，ＰＣを４バイトアラインメント して，さらにオフセットを加算することでアドレスを計算している． (４バイトロードなので，アラインメントされる) 

これについて検証してみました。

# mov.w

`mov.w`命令で近くのメモリから値を読み込みます。

※ 機械語を見るためのコードで、実行は想定していません。

```text:sh1.s
test0a:
    mov.w 0f,r0
    nop
0:  .word 0x7788

test0b:
    mov.w 0f,r0
    nop
0:  .word 0x7788

test1a:
    mov.w 0f,r0
    nop
    nop
0:  .word 0x7788

test1b:
    nop
    mov.w 0f,r0
    nop
    nop
0:  .word 0x7788
```

`mov.w`命令の相対アドレス（`90 XX`のXXの部分）に注目します。

```text:逆アセンブル結果
00000000 <test0a>:
   0:	90 00       	mov.w	4 <test0a+0x4>,r0	! 7788
   2:	00 09       	nop	
   4:	77 88       	add	#-120,r7

00000006 <test0b>:
   6:	90 00       	mov.w	a <test0b+0x4>,r0	! 7788
   8:	00 09       	nop	
   a:	77 88       	add	#-120,r7

0000000c <test1a>:
   c:	90 01       	mov.w	12 <test1a+0x6>,r0	! 7788
   e:	00 09       	nop	
  10:	00 09       	nop	
  12:	77 88       	add	#-120,r7

00000014 <test1b>:
  14:	00 09       	nop	
  16:	90 01       	mov.w	1c <test1b+0x8>,r0	! 7788
  18:	00 09       	nop	
  1a:	00 09       	nop	
  1c:	77 88       	add	#-120,r7
```

この結果を見ると、4バイトアラインメントの影響はなく、以下の記述は正しいようです。

> ・ ＰＣ(プログラムカウンタ)は，２つ先の命令を指している． 
> ・ mov.wで２バイトをＰＣ相対でロードする際には，ＰＣ＋オフセットで アドレスを計算している．(単純に加算するだけ) 

# mov.l

`mov.l`命令で近くのメモリから値を読み込みます。

```text:sh2.s
test0a:
    mov.l 0f,r0
    nop
0:  .long 0x778899aa

test0b:
    nop
    mov.l 0f,r0
0:  .long 0x778899aa

test1a:
    mov.l 0f,r0
    nop
    nop
    nop
0:  .long 0x778899aa

test1b:
    nop
    mov.l 0f,r0
    nop
    nop
0:  .long 0x778899aa
```

`mov.l`命令の相対アドレス（`d0 XX`のXXの部分）に注目します。

```text:逆アセンブル結果
00000000 <test0a>:
   0:	d0 00       	mov.l	4 <test0a+0x4>,r0	! 778899aa
   2:	00 09       	nop	
   4:	77 88       	add	#-120,r7
   6:	99 aa       	mov.w	15e <test1b+0x142>,r9

00000008 <test0b>:
   8:	00 09       	nop	
   a:	d0 00       	mov.l	c <test0b+0x4>,r0	! 778899aa
   c:	77 88       	add	#-120,r7
   e:	99 aa       	mov.w	166 <test1b+0x14a>,r9

00000010 <test1a>:
  10:	d0 01       	mov.l	18 <test1a+0x8>,r0	! 778899aa
  12:	00 09       	nop	
  14:	00 09       	nop	
  16:	00 09       	nop	
  18:	77 88       	add	#-120,r7
  1a:	99 aa       	mov.w	172 <test1b+0x156>,r9

0000001c <test1b>:
  1c:	00 09       	nop	
  1e:	d0 01       	mov.l	24 <test1b+0x8>,r0	! 778899aa
  20:	00 09       	nop	
  22:	00 09       	nop	
  24:	77 88       	add	#-120,r7
  26:	99 aa       	mov.w	17e <test1b+0x162>,r9
```

この結果を見ると、以下の記述は少し補足が必要なように思います。

> ・ ＰＣ(プログラムカウンタ)は，２つ先の命令を指している． 
> ・ mov.lで４バイトをＰＣ相対でロードする際には，ＰＣを４バイトアラインメント して，さらにオフセットを加算することでアドレスを計算している． (４バイトロードなので，アラインメントされる) 

一般的にアラインメントでは切り上げすることが多いように思いますが、`a: d0 00`と`1e: d0 01`は~~切り下げ~~切り捨てでアラインメントされています。というわけで~~「切り下げ」~~「切り捨て」を明記した方が誤解が少ないように思います。

【追記】「切り下げ」という言い方は一般的ではなく、普通は「切り捨て」と言うというご指摘を受けました。
