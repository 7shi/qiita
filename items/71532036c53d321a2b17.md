---
coediting: false
comments_count: 0
created_at: '2015-11-18T18:23:13+09:00'
id: 71532036c53d321a2b17
likes_count: 6
private: false
reactions_count: 0
stocks_count: 3
tags:
- name: PDP11
  versions: []
- name: VAX
  versions: []
title: Ancient UNIXのcrt0.sを読む
updated_at: '2015-11-22T02:28:04+09:00'
url: https://qiita.com/7shi/items/71532036c53d321a2b17
slide: false
---

UNIX V6とV7のcrt0.sを読んで、スタックで渡されるコマンドライン引数の形式を調べました。V7をVAXに移植したUNIX/32Vや、Interdata 7/32に移植したV6とも比較します。

※ カーネルのexecシステムコールを読む方が確実ですが、今回はアセンブリ言語を読むため敢えてcrt0.sから読み取りました。

作業時のメモをツイートしました。

* https://twitter.com/7shi/status/666899916078235648

# argv

C言語で文字列配列の構造を見ます。

```str.c
char *argv[] { "abc", "def" };
```

※ pre K/Rではグローバル変数への代入に `=` を使用しません。

次のような構造が出力されます。

アドレス|内容  |備考
--------|------|----
`0000`|`0004` |文字列のアドレス: `argv[0]`
`0002`|`0008` |文字列のアドレス: `argv[1]`
`0004`|`abc\0`|文字列
`0008`|`def\0`|文字列

文字列のアドレスが並び、その後に文字列の実データが格納されます。`main()`に渡される`argv`はカーネルが同様の構造をスタックに生成して渡します。

# UNIX V6

* [V6/usr/source/s4/crt0.s](http://minnie.tuhs.org/cgi-bin/utree.pl?file=V6/usr/source/s4/crt0.s)

`main()`が呼ばれるまでは短いです。コメントに疑似コードで動作を示します。

```text
    mov sp,r0       / r0 = sp
    mov (r0),-(sp)  / sp -= 2; argc = *r0
    tst (r0)+       / r0 += 2
    mov r0,2(sp)    / argv = r0
    jsr pc,_main    / main(argc, argv)
```

引数はスタック渡しです。起動直後と`main()`が呼ばれる直前のスタックの変化を示します。

アドレス|起動直後|→|アドレス|main直前|備考
------:|---------|:--:|---:|----|----
       |         |→|` (sp)`|`argc`   |移動
` (sp)`|`argc`   |→|`2(sp)`|`argv`   |追記
`2(sp)`|`argv[0]`|→|`4(sp)`|`argv[0]`|そのまま

`argc`を1つ前にずらして`argv`を挿入しています。

# UNIX V7

* [V7/usr/src/libc/csu/crt0.s](http://minnie.tuhs.org/cgi-bin/utree.pl?file=V7/usr/src/libc/csu/crt0.s)

`envp`が加わったためV6より複雑になっています。コメントに疑似コードで動作を示します。

```text
    mov 2(sp),r0     / r0 = argv[0]
    clr -2(r0)       / *(r0-2) = 0
    mov sp,r0        / r0 = sp
    sub $4,sp        / sp -= 4
    mov 4(sp),(sp)   / argc = *(sp+4)
    tst (r0)+        / r0 += 2
    mov r0,2(sp)     / argv = r0
1:                   / do {
    tst (r0)+        /     tmp = *r0; r0 += 2
    bne 1b           / } while (tmp)
    cmp r0,*2(sp)    / if (r0 >= argv[0])
    blo 1f           / {
    tst -(r0)        /     r0 -= 2
1:                   / }
    mov r0,4(sp)     / envp = r0
    mov r0,_environ  / environ = r0
    jsr pc,_main     / main(argc, argv, envp)
```

引数はスタック渡しです。起動直後と`main()`が呼ばれる直前のスタックの変化を示します。

アドレス|起動直後|→|アドレス|main直前|備考
------:|---------|:--:|---:|----|----
       |         |→|` (sp)`|`argc`   |移動
       |         |→|`2(sp)`|`argv`   |追記
` (sp)`|`argc`   |→|`4(sp)`|`envp`   |上書き
`2(sp)`|`argv[0]`|→|`6(sp)`|`argv[0]`|そのまま

`argc`を2つ前にずらして`argv`と`envp`を挿入しています。

`argv[]`と`envp[]`は`NULL`で区切られています。

* `argv[0], ... , NULL, envp[0], ..., NULL`

最初の`NULL`をループ（`do {} while`で示した部分）で探しています。

`if`で示した部分は、もし`envp`が存在せず`NULL`も1個しかなかった場合、`r0 -= 2`で最初の`NULL`を指すように補正しています。

`NULL`がなければ誤動作するため、最後のポインタを潰してでも`NULL`を作っているのが`clr -2(r0)`の部分です。

# UNIX/32V

* [32V/usr/src/libc/csu/crt0.s](http://minnie.tuhs.org/cgi-bin/utree.pl?file=32V/usr/src/libc/csu/crt0.s)

V7をなるべくそのまま32bit化したような印象です。最初からコメントが入っています。

```text
    subl2   $8,sp
    movl    8(sp),(sp)   # argc
    movab   12(sp),r0
    movl    r0,4(sp)     # argv
L1:
    tstl    (r0)+        # null args term ?
    bneq    L1
    cmpl    r0,*4(sp)    # end of 'env' or 'argv' ?
    blss    L2
    tstl    -(r0)        # envp's are in list
L2:
    movl    r0,8(sp)     # env
    movl    r0,_environ  # indir is 0 if no env ; not 0 if env
    calls   $3,_main
```

引数はスタック渡しです。起動直後と`main()`が呼ばれる直前のスタックの変化を示します。

アドレス|起動直後|→|アドレス|main直前|備考
------:|---------|:--:|---:|----|----
       |         |→|`  (sp)`|`argc`   |移動
       |         |→|` 4(sp)`|`argv`   |追記
` (sp)`|`argc`   |→|` 8(sp)`|`envp`   |上書き
`4(sp)`|`argv[0]`|→|`12(sp)`|`argv[0]`|そのまま

`argc`を2つ前にずらして`argv`と`envp`を挿入しています。

# UNIX V6 for Interdata 7/32

V6の移植版です。Interdata 7/32は32bitのビッグエンディアンのアーキテクチャです。

* [Wikipedia: Interdata 7/32と8/32](https://ja.wikipedia.org/wiki/Interdata_7/32%E3%81%A88/32)

SIMHで動かせます。

* [エミュレーション、そしてコンピューティングの歴史](http://www.ibm.com/developerworks/jp/opensource/library/os-emulatehistory/) 2011.03.22

crt0.sを含むlibcのソースはアーカイブされたままです。

* [Interdata732/usr/source/libc](http://minnie.tuhs.org/cgi-bin/utree.pl?file=Interdata732/usr/source/libc)

このsrc.aはGNU Binutilsと互換性がありません。

```text
$ file src.a
src.a: old 32-bit-int big-endian archive
$ ar x src.a
ar: src.a: ファイル形式が認識できません
```

仕方ないので当時のarをPOSIXにやっつけで移植しました。ビッグエンディアンに依存したコードなので少し面倒でした。

* オリジナル: [Interdata732/usr/source/cmds/ar.c](http://minnie.tuhs.org/cgi-bin/utree.pl?file=Interdata732/usr/source/cmds/ar.c)
* 移植版: https://bitbucket.org/snippets/7shi/nR9kk

これによりcrt0.sを取り出しました。

```text:crt0.s
crt0    title   unix c library -- runtime initialization
    extrn   main
    extrn   exit
    entry   _exit
r0  equ 0
sp  equ 7
rf  equ 15
    pure
* rearrange args on stack & call main routine
    sis sp,8
    l   r0,8(sp)
    st  r0,0(sp)
    la  r0,12(sp)
    st  r0,4(sp)
    bal rf,main
* if main routine returns, exit
    st  r0,0(sp)
    bal rf,exit
*
_exit   equ *
    l   r0,0(sp)
    svc 14,1
    end
```

`main()`が呼ばれるまでを抜粋して、コメントに疑似コードで動作を示します。

```text
    sis sp,8       * sp -= 8
    l   r0,8(sp)   * r0 = *(sp+8)
    st  r0,0(sp)   * argc = r0
    la  r0,12(sp)  * r0 = sp+12
    st  r0,4(sp)   * argv = r0
    bal rf,main    * main(argc, argv)
```

引数はスタック渡しです。起動直後と`main()`が呼ばれる直前のスタックの変化を示します。

アドレス|起動直後|→|アドレス|main直前|備考
------:|---------|:--:|---:|----|----
       |         |→|` 0(sp)`|`argc`   |追記
       |         |→|` 4(sp)`|`argv`   |追記
`0(sp)`|`argc`   |→|` 8(sp)`|`argc`   |そのまま
`4(sp)`|`argv[0]`|→|`12(sp)`|`argv[0]`|そのまま

`argc`を2つ前にずらして`argv`を挿入しています。PDP-11やVAXと違って元の`argc`を上書きしていません。

V6の移植版のため`envp`のサポートはありません。V7の移植版もあるようですが未確認です。
