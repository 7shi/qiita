---
coediting: false
comments_count: 0
created_at: '2015-09-17T17:28:31+09:00'
id: 7b24ed23fcbea08c3615
likes_count: 8
private: false
reactions_count: 0
stocks_count: 7
tags:
- name: Perl
  versions: []
- name: ShellScript
  versions: []
- name: VAX
  versions: []
title: VAXの機械語を総当たり調査
updated_at: '2015-10-13T16:53:17+09:00'
url: https://qiita.com/7shi/items/7b24ed23fcbea08c3615
slide: false
---

VAXの命令を調べるため総当たりで逆アセンブルしてみました。VAXの機械語はシンプルなので総当たり調査が簡単にできました。

VAXのクロス開発環境を前提とします。構築方法は次の記事を参照してください。

* [UNIX/32VによるVAX事始め](http://qiita.com/7shi/items/85c4a43a07152c4322d5) 2015.9.14

この記事には姉妹編があります。

* [S/390の機械語を総当たり調査](http://qiita.com/7shi/items/98c7aa38fe0bd29a7296) 2015.10.8

# 基本形

簡単な機械語を見てみます。

```text
$ cat test1.s
incl %r0
incl %r1
movl %r0,%r1
movl %r2,%r3
$ vax-netbsdelf-as test1.s
$ vax-netbsdelf-objdump -d a.out
（略）
00000000 <.text>:
   0:   d6 50           incl r0
   2:   d6 51           incl r1
   4:   d0 50 51        movl r0,r1
   7:   d0 52 53        movl r2,r3
```

アセンブリ言語ではレジスタに`%`を付けますが、逆アセンブル結果にはありません。オプションで揃えられるのかもしれませんが、本質ではないので無視します。

機械語を見ると、以下の対応関係が見て取れます。

```text
d6 -> incl
d0 -> movl
50 -> r0
51 -> r1
52 -> r2
53 -> r3
```

最初の1バイト目がオペコード（命令の種類）で、2バイト目からオペランドが始まります。バイト単位で区切られているため、オペコードとオペランドをビット操作で分離する必要がありません。

## 拡張コード

1バイト目がオペコードが表すと命令は256個しか表現できません。これでは将来的な拡張の余地がなくなってしまうため、0xfd-0xffは次の1バイトも含んだ2バイトがオペコードです。

* `00` - `fc`
* `fd 00` - `fd ff`
* `fe 00` - `fe ff`
* `ff 00` - `ff ff`

最大で`0xfd + 3 * 0x100 = 1021`個の命令が扱えます。このようなマルチバイトの扱い方は文字コードに似ています。

# 総当たり（オペコード）

適当にオペランドを並べてオペコードを総当たりすれば、すべての命令フォーマットが分かるはずです。

`0x00`で試します。オペランドの個数が不明なので、適当に`0x50`を並べます。

```text
$ cat 00.s
.byte 0x00, 0x50, 0x50, 0x50, 0x50, 0x50, 0x50
$ vax-netbsdelf-as 00.s
$ vax-netbsdelf-objdump -d a.out
（略）
00000000 <.text>:
   0:   00              halt
   1:   50 50 50        movf r0,r0
   4:   50 50 50        movf r0,r0
```

`0x00`はオペランドなしの`halt`命令だと分かりました。

この要領ですべてを試します。`0xfd`-`0xff`の扱いに注意が必要です。

オペランドの個数によって命令の切れ目が変わるため、1つのファイルに並べて書くと不具合が生じます。1つずつ別ファイルで試して、最後に結合します。シェルスクリプトで自動化しますが、連番生成を使うためbash依存です。

```bash:allop.sh
#!/usr/bin/env bash

arch=vax-netbsdelf
as=$arch-as
dis="$arch-objdump -d"

rm -f allop.d
mkdir -p tmp
cd tmp

func() {
    echo $1
    echo ".byte $2, 0x50, 0x50, 0x50, 0x50, 0x50, 0x50" > $1.s
    $as -o $1.o $1.s
    $dis $1.o > $1.d
    head -n8 $1.d | tail -n1 | cut -f2- >> ../allop.d
}

for i in {0..252}
do
    hex=`printf "%02x" $i`
    func $hex "0x$hex"
done

for i in {253..255}
do
    hex1=`printf "%02x" $i`
    for j in {0..255}
    do
        hex2=`printf "%02x" $j`
        func "$hex1-$hex2" "0x$hex1, 0x$hex2"
    done
done
```

実行するとallop.dというファイルが生成されます。

```text:allop.d
00          	halt
01          	nop
02          	rei
（略）
ff fd 50    	bugl r0
ff fe 50    	bugw r0
ff ff       	.word 0xffff
```

`.word`は未定義であることを表します。

命令長が4バイト以上の場合、ダンプが途中で切れるのに注意が必要です。`cvtps`は実際には5バイト命令です。

```text:temp/08.d（抜粋）
   0:   08 50 50 50     cvtps r0,r0,r0,r0
   4:   50
```

拡張コードの部分を見ると、`fd`は割と使われていますが、`fe`は未使用、`ff`は2つしか命令がありません。

命令数を確認します。

```text
$ grep -v .word allop.d | wc -l
306
```

上限が1021個なので、まだ余裕があります。

## オペランドの組み合わせ

オペランドの組み合わせと出現数を確認します。

```text
$ grep -v .word allop.d | cut -f2 | cut -s -d' ' -f2 | sort | uniq -c
      2 0x5053
     14 0x52
     37 r0
      4 r0,0x53
    131 r0,r0
     10 r0,r0,0x54
     57 r0,r0,r0
      5 r0,r0,r0,0x5056
      2 r0,r0,r0,0x5057
     19 r0,r0,r0,r0
      8 r0,r0,r0,r0,r0
      8 r0,r0,r0,r0,r0,r0
```

いくつか即値が現れています。`0x50`からずれているため、相対アドレスだと推測できます。

例として`bsbb`を見ます。

```text:temp/10.d（抜粋）
   0:	10 50       	bsbb 0x52
   2:	50 50 50    	movf r0,r0
```

相対アドレスは次の命令のアドレスを基点とします。`2 + 0x50 = 0x52`と確認できます。

## オペランドの個数

allop.dを見れば、命令ごとのオペランドの個数が分かります。スクリプトで確認します。シェル芸には通じていないためPerlに逃げました。

```allop-c.pl
#!/usr/bin/env perl

while (<>) {
    chop while substr($_, -1) le " ";
    @f = split(/\t/);
    @b = split(/ /, $f[0]);
    if ($f[1] =~ /^(.*?) (.*)/) {
        $mne = $1;
        @opr = split(/,/, $2);
    } else {
        $mne = $f[1];
        @opr = ();
    }
    if ($mne ne ".word") {
        $c = @opr;
        $r = "";
        if ($c > 0) {
            $l = length($opr[$c - 1]);
            if ($l > 2) {
                --$c;
                $r = ($l - 2) / 2;
            }
        }
        $op = hex($b[0]) < 0xfd ? $b[0] : "$b[0]-$b[1]";
        print "$op\t$c\t$r\t$mne\n";
    }
}
```

【注】 `hex`の意味はPythonと逆です。

実行結果をファイルに保存して確認します。

```text
$ ./allop-c.pl < allop.d > allop-c.txt
$ cat allop-c.txt
00	0		halt
01	0		nop
（略）
10	0	1	bsbb
11	0	1	brb
（略）
ff-fd	1		bugl
ff-fe	1		bugw
```

相対アドレスはカウントせずに、3番目のカラムにサイズ（`1`または`2`）で示しています。

## オペランドのサイズ

オペランドはそれぞれ固有のサイズを持っています。

即値を指定して確認します。`$0x00`-`$0x3f`は短い形式にエンコードされるため`$0x40`を指定します。

```text
$ cat test2.s
tstb $0x40
tstw $0x40
tstl $0x40
$ vax-netbsdelf-as test2.s
$ vax-netbsdelf-objdump -d a.out
（略）
00000000 <.text>:
   0:   95 8f 40        tstb $0x40
   3:   b5 8f 40 00     tstw $0x0040
   7:   d5 8f 40 00     tstl $0x00000040
   b:   00 00
```

即値は`8f`で表されていますが、サイズは命令で決まるのが確認できます。

逆に、機械語からオペランドのサイズを調べます。調べたいオペランドに`8f`を入れておけば、出て来た即値からサイズが分かります。

`cvtps`の第2オペランドを調べる例です。

```text
$ cat test3.s
.byte 0x08, 0x50, 0x8f, 0x50, 0x50, 0x50, 0x50, 0x50
$ vax-netbsdelf-as test3.s
$ vax-netbsdelf-objdump -d a.out
（略）
00000000 <.text>:
   0:   08 50 8f 50     cvtps r0,$0x50,r0,r0
   4:   50 50
   6:   movf r0,Address 0x00000008 is out of bounds.
```

第2オペランドが`$0x50`と出ていることからサイズが1バイトだと確認できます。

# 総当たり（オペランド）

オペランドのサイズを総当たりで確認します。先ほど調査したオペランドの個数を使用します。

```bash:allopr.sh
#!/usr/bin/env bash

arch=vax-netbsdelf
as=$arch-as
dis="$arch-objdump -d"

rm -f allopr.d
mkdir -p tmp
cd tmp

func() {
    $as -o $1.o $1.s
    $dis $1.o > $1.d
    head -n8 $1.d | tail -n1 | cut -f2- >> ../allopr.d
}

data=`for i in {1..32}; do echo -n ", 0x50"; done`

cat ../allop-c.txt | while read line
do
    echo $line
    set -- $line
    fn=$1
    c=$2
    hex=`echo 0x$fn | sed 's/-/, 0x/'`
    if [ $c -eq 0 ]
    then
        echo ".byte $hex$data" > $fn.s
        func $fn
    else
        i=1
        while [ $i -le $c ]
        do
            echo -n ".byte $hex" > $fn-$i.s
            j=1
            while [ $j -lt $i ]
            do
                echo -n ", 0x50" >> $fn-$i.s
                j=`expr $j + 1`
            done
            echo ", 0x8f$data" >> $fn-$i.s
            func $fn-$i
            i=`expr $i + 1`
        done
    fi
done
```

実行するとallopr.dというファイルが生成されます。

```text:allopr.d
00          	halt
01          	nop
（略）
08 8f 50 50 	cvtps $0x5050,r0,r0,r0
08 50 8f 50 	cvtps r0,$0x50,r0,r0
08 50 50 8f 	cvtps r0,r0,$0x5050,r0
08 50 50 50 	cvtps r0,r0,r0,$0x50
（略）
ff fd 8f 50 	bugl $0x50505050
ff fe 8f 50 	bugw $0x5050
```

`cvtps`のオペランドのサイズが 2, 1, 2, 1 となっていることが分かります。

即値の種類を確認します。

```text
$ cut -f2 allopr.d | cut -s -d' ' -f2- | sed 's/,/\n/g' | grep '\$' | sort | uniq
$0x50
$0x5050
$0x50505050
$0x50505050 [f-float]
$0x5050505050505050
$0x5050505050505050 [d-float]
$0x5050505050505050 [g-float]
$0x50505050505050505050505050505050
$0x50505050505050505050505050505050 [h-float]
```

5つの整数型（b, w, l, q, o）と4つの浮動小数点数型（f, d, g, h）があります。括弧内は型の省略形です。

## 分析

総当たりの結果を分析して、命令ごとのオペランドの型を特定します。

```allopr-t.pl
#!/usr/bin/env perl

%im = (
    '$0x50'                                         => 'b',
    '$0x5050'                                       => 'w',
    '$0x50505050'                                   => 'l',
    '$0x50505050 [f-float]'                         => 'f',
    '$0x5050505050505050'                           => 'q',
    '$0x5050505050505050 [d-float]'                 => 'd',
    '$0x5050505050505050 [g-float]'                 => 'g',
    '$0x50505050505050505050505050505050'           => 'o',
    '$0x50505050505050505050505050505050 [h-float]' => 'h'
);

$cur = "";
@opt = ();

sub output {
    if ($cur ne "") {
        print "$cur\t$mne\t", join("", @opt), "\n";
        @opt = ();
    }
}

while (<>) {
    chop while substr($_, -1) le " ";
    @f = split(/\t/);
    @b = split(/ /, $f[0]);
    $op = hex($b[0]) < 0xfd ? $b[0] : "$b[0]-$b[1]";
    if ($cur ne $op) {
        output();
        $cur = $op;
    }
    if ($f[1] =~ /^(.*?) (.*)/) {
        $mne = $1;
        @opr = split(/,/, $2);
    } else {
        $mne = $f[1];
        @opr = ();
    }
    $c = @opr;
    for (my $i = 0; $i < $c; ++$i) {
        $o = $opr[$i];
        $t = $im{$o};
        if ($t ne "") {
            $opt[$i] = $t;
        } elsif ($o =~ /^0x..$/) {
            $opt[$i] = "1";
        } elsif ($o =~ /^0x....$/) {
            $opt[$i] = "2";
        }
    }
}
output();
```

実行結果をファイルに保存して確認します。

```text
$ ./allopr-t.pl < allopr.d > allopr-t.txt
$ cat allopr-t.txt
00	halt	
01	nop	
（略）
10	bsbb	1
11	brb	1
（略）
3c	movzwl	wl
3d	acbw	www2
（略）
ff-fd	bugl	l
ff-fe	bugw	w
```

オペランドの型を省略形で並べていますが、相対アドレスはサイズ（`1`または`2`）で示しています。

以上で総当たりによる調査は完了しました。

# まとめ

今回のスクリプトや出力結果は以下に置いてあります。

* https://bitbucket.org/7shi/vax/src/tip/research/

調査結果に基づいてJavaで300行程度の逆アセンブラを作りました。

* https://bitbucket.org/7shi/vax/src/tip/src/vax/Main.java
