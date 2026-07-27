---
coediting: false
comments_count: 0
created_at: '2015-01-30T04:06:50+09:00'
id: 2d44e040bae930d11088
likes_count: 51
private: false
reactions_count: 0
stocks_count: 49
tags:
- name: GCC
  versions: []
- name: binutils
  versions: []
- name: msys2
  versions: []
title: 最低限のクロスコンパイラの作り方
updated_at: '2015-10-23T11:53:42+09:00'
url: https://qiita.com/7shi/items/2d44e040bae930d11088
slide: false
---

興味を持ったアーキテクチャの機械語を眺めるための、最低限のクロスコンパイラの作り方を説明します。全部入りbinutilsも紹介します。

※ 実用的な開発は目的としていません。指定するオプションも最小限に抑えています。

[熱血！アセンブラ入門](http://www.shuwasystem.co.jp/products/7980html/4180.html)の最初に登場するPowerPCを例に説明しますが、gccでサポートされているアーキテクチャであれば同じ方法が使えます。

※ 同書よりも新しいgccを扱うため、いくつか新しいアーキテクチャが使えます。差分は最後の方にまとめています。

# ビルド対象

1. binutils: アセンブラ、逆アセンブラ、リンカなど
2. gcc: コンパイラ

# 準備

gccが使える環境が必要です。

WindowsではMSYS2を使う前提で説明します。

* [@7shi](https://twitter.com/7shi): [MSYS2でRicty Diminishedを使う設定など - Qiita](http://qiita.com/7shi/items/894fdd849658880bf6c9) 2015.1.29

## 依存ライブラリ

gcc-4.3以降は次のライブラリに依存しています。

* [GMP](https://gmplib.org/), [MPFR](http://www.mpfr.org/), [MPC](http://www.multiprecision.org/index.php?prog=mpc)

使用しているパッケージ管理システムなどからインストールしてください。

MSYS2での例を示します。

```text
$ pacman -S mpc-devel
```

※ mpc-develだけインストールすれば他も依存関係で入ります。

自分でビルドするときは次のようにすれば良いでしょう。

```text:環境変数
$ export CPPFLAGS=-I/opt/cross/include LDFLAGS=-L/opt/cross/lib
```
```text:オプション
$ ./configure --prefix=/opt/cross
```

# ビルド

ビルド手順を示します。速いマシンだと10分程度で終わります。

## ダウンロード

binutilsは執筆時の最新版、gccは4.6.4を使います。

```text
$ wget http://ftp.gnu.org/gnu/binutils/binutils-2.25.tar.bz2
$ wget http://ftp.gnu.org/gnu/gcc/gcc-4.6.4/gcc-core-4.6.4.tar.bz2
```

gcc-4.6を使っているのは以下の理由によります。

* gcc-4.5以前は新しいmakeinfoでエラーが出る
* gcc-4.7以降は配布物が全部入りとなり巨大

## 展開

適当なディレクトリでソースを展開します。

```text
$ tar xvf binutils-2.25.tar.bz2
$ tar xvf gcc-core-4.6.4.tar.bz2
```

## パッチ (MSYS2)

**MSYS2では**環境を認識するように修正が必要です。

```text
$ cp /usr/share/automake-1.15/config.* gcc-4.6.4
```

※ この手の修正は新しい環境では良くあることなので、知っていれば役立つかもしれません。

## ビルドディレクトリ

ビルドはソースの外で行うのが流儀です。ビルド用のディレクトリを作成します。ディレクトリ名は任意ですが、ここではgccで指定するターゲット名に合わせます。

※ 先ほどのコマンドに続けて入力することを想定しています。以降も同様です。

```text
$ mkdir powerpc-elf
$ cd powerpc-elf
```

* powerpc: CPU名
* elf: バイナリ形式（ELFファイル）

## binutils

ビルドディレクトリを作って入り、相対パスでconfigureを呼びます。

```text
$ mkdir binutils
$ cd binutils
$ ../../binutils-2.25/configure --prefix=/opt/cross --target=powerpc-elf
```

configureのオプションは次の通りです。

* `--prefix`: インストール先
* `--target`: 対象とするアーキテクチャ

ビルドします。`-j2`の`2`はCPUのコア数に合わせて調整すると（例：4コアなら`-j4`）、ビルド時間が短縮できます。

```text
$ make -j2
```

ビルドが完了したらインストールします。

```text
$ sudo make install
```

※ MSYS2では`sudo`は不要です。

ディレクトリを抜けます。

```text
$ cd ..
```

### エラー対策

MSYS2でmake中に次のようなエラーで止まることがあります。

```text
39 [main] make 7628 child_info_fork::abort:（略）: Loaded to different address: parent(0x440000) != child(0x630000)
make: fork: Resource temporarily unavailable
```

その場合は次の方法で対処してください。

1. MSYS2のターミナルをすべて閉じます。
2. MSYS2がインストールされたディレクトリにある`autorebase.bat`を実行します。
3. コマンドプロンプトのウィンドウが出て、数分後に自動的に閉じます。文字は何も表示されません。
4. MSYS2のターミナルを開いて先ほどのディレクトリに移動して、もう一度makeを試してください。

次の情報を参考にしました。

* [MSYS2 / Tickets / #74 make child_info_fork::abort](http://sourceforge.net/p/msys2/tickets/74/) 2014.9.4

## gcc

binutilsと同様の手順ですが、makeのターゲットに`-gcc`が付いているのに注意してください。

※ これを付けないとライブラリがビルドされてエラーになります。

```text
$ mkdir gcc
$ cd gcc
$ ../../gcc-4.6.4/configure --prefix=/opt/cross --target=powerpc-elf
$ make -j2 all-gcc
$ sudo make install-gcc
```

※ MSYS2では`sudo`は不要です。

## ビルド時間

参考としてbinutilsとgccのビルドにどれくらい時間が掛かるかを示します。

OS  |CPU |クロック|ジョブ|時間|ウィルス対策
----|----|-------|-----|----|----------
Windows 8.1 (MSYS) |Athlon 64 X2 4600+|2.40GHz|-j2|57m14.069s|Windows Defender
Windows 8.1 (MSYS2)|Athlon 64 X2 4600+|2.40GHz|-j2|27m13.587s|（オフ）
Windows 8.1 (MSYS2)|Athlon 64 X2 4600+|2.40GHz|-j2|30m08.217s|Windows Defender
Windows 8.1 (MSYS2)|Celeron N2830|2.16GHz|-j2|38m26.803s|Windows Defender
Windows 7 (MSYS2)|Core i5-3320M|2.60GHz|-j2|15m37.006s|（オフ）
Windows 7 (MSYS2)|Core i5-3320M|2.60GHz|-j4|12m32.296s|（オフ）
Windows 7 (MSYS2)|Core i5-3320M|2.60GHz|-j4|21m37.818s|Virus Buster

* 同じマシンでも無印MSYSよりMSYS2が高速
* HTの効果は約1.25倍
* ウィルス対策はかなり足を引っ張る

# 使用方法

ビルドしたPowerPC用クロスコンパイラを使ってみます。

## パス

標準でパスの通っていない /opt/cross にインストールしたため、使用前にパスを通します。

```text
$ export PATH="/opt/cross/bin:$PATH"
```

毎回やると面倒なので ~/.bashrc などに記載しておくと良いでしょう。

## テスト

どんなコードが生成されるのかテストします。

※ ビルドディレクトリから出て、適当なディレクトリを作ってそこで作業してください。

```c:add.c
int add(int a, int b) {
    return a + b;
}
```

コンパイルします。

* `-nostdlib`: Cのライブラリ（libc）などをリンクしません。存在しないため指定しないとエラーとなります。
* `-g`: 逆アセンブル時にC言語の該当箇所を表示するためデバッグ情報を有効化します。
* `-O`: 最適化します。出力される機械語を単純にするために利用しています。外したものと対比してみると良いでしょう。

```text
$ powerpc-elf-gcc -nostdlib -g -O add.c
/opt/cross/lib/gcc/powerpc-elf/4.6.4/../../../../powerpc-elf/bin/ld: 警告: エントリシンボル _start が見つかりません。デフォルトとして 0000000001800054 を使用します
```

※ 警告は無視します。

出力されたバイナリ（a.out）を逆アセンブルして、どんな機械語が出力されているかを確認します。

* `-S`: C言語のソースと対比しながら逆アセンブルします。対象は`-g`付きでコンパイルされている必要があります。

```text
$ powerpc-elf-objdump -S a.out

a.out:     ファイル形式 elf32-powerpc


セクション .text の逆アセンブル:

01800054 <add>:
int add(int a, int b) {
    return a + b;
}
 1800054:       7c 63 22 14     add     r3,r3,r4
 1800058:       4e 80 00 20     blr
```

引数が`r3`と`r4`で渡されて、戻り値は`r3`で返される様子が読み取れます。

# 他のアーキテクチャ

targetを変えれば色々なアーキテクチャがビルドできます。

どんなアーキテクチャがあるかは次の記事を参考にしてください。

* [@7shi](https://twitter.com/7shi): [gcc-4.6.1の対応アーキテクチャ - 七誌の開発日記（旧）](http://d.hatena.ne.jp/n7shi/20110722/1311322802) 2011.7.22

## IA-64

リンクを分けないとエラーになります。

```text:NG
$ ia64-elf-gcc -nostdlib add.c
/tmp/ccYFwywB.s: Assembler messages:
/tmp/ccYFwywB.s:14: Warning: Explicit stops are ignored in auto mode
/opt/cross/lib/gcc/ia64-elf/4.6.4/../../../../ia64-elf/bin/ld: so が見つかりません: No such file or directory
collect2: ld はステータス 1 で終了しました
```
```text:OK
$ ia64-elf-gcc -c add.c
$ ia64-elf-ld add.o
ia64-elf-ld: 警告: エントリシンボル _start が見つかりません。デフォルトとして 40000000000000b0 を使用します
```

## SH64

リンクを分けるとエラーになります。

```text:OK
$ sh64-elf-gcc -nostdlib add.c
/opt/cross/lib/gcc/sh64-elf/4.6.4/../../../../sh64-elf/bin/ld: 警告: エントリシンボル start が見つかりません。デフォルトとして 0000000000001000 を使用します
```
```text:NG
$ sh64-elf-gcc -c add.c
$ sh64-elf-ld add.o
sh64-elf-ld: sh5 アーキテクチャ (入力ファイル`add.o') は sh 出力と互換性がありません
sh64-elf-ld: 警告: エントリシンボル start が見つかりません。デフォルトとして 0000000000001000 を使用します
sh64-elf-ld: 最終リンクに失敗しました: 不正な値です
```

オプションを指定する必要があります。

```text:OK
$ sh64-elf-gcc -c add.c
$ sh64-elf-ld -mshelf32 add.o
sh64-elf-ld: 警告: エントリシンボル start が見つかりません。デフォルトとして 0000000000001000 を使用します
```

## テストスクリプト

参考までにコンパイル・リンク・逆アセンブルを一発でやるスクリプトの例を示します。

※ 前述の理由でSH64には使えません。

```text:/opt/cross/bin/testgcc
#!/usr/bin/env bash
arch=$1
tmp=`mktemp`
shift
$arch-gcc -o $tmp -c -O -g -fomit-frame-pointer $@ &&
    $arch-ld $tmp &&
    $arch-objdump -S a.out
rm -f $tmp
```
```text:使用例
$ testgcc ia64-elf add.c
```

# 全部入りbinutils

binutilsは全部入りにできます。これさえあれば様々なCPUのバイナリを逆アセンブルできます。

いくつか注意点があります。

* gccは全部入りにできません。個別に指定してビルドするしかありません。
* アセンブラがうまく機能しないため、ほぼ逆アセンブラ専用となります。gccとセットでビルドするbinutilsにはアセンブラが不可欠なため、全部入りがあっても依然としてbinutilsのビルドは必要です。

## パッチ (MSYS2)

**MSYS2では**[このパッチ](https://github.com/Alexpux/MSYS2-packages/blob/master/binutils/binutils-trunk-msys2.patch)が必要です。

```text
$ wget https://raw.githubusercontent.com/Alexpux/MSYS2-packages/1ec8aa42e0892f04400039ea1e5ede51ffc4d35e/binutils/binutils-trunk-msys2.patch
$ patch -p1 -d binutils-2.25 < binutils-trunk-msys2.patch
```

## ビルド

```text
$ mkdir all
$ cd all
$ ../binutils-2.25/configure --prefix=/opt/cross --enable-targets=all --enable-64-bit-bfd --program-prefix=all-
$ make -j2
$ sudo make install
```

※ MSYS2では`sudo`は不要です。

## 使い方

コマンドに`all-`の接頭辞を付けます。

```text
$ all-objdump -S a.out
```

# 自動ビルドスクリプト

参考として自動化したスクリプトを置いておきます。あくまで参考のため無保証です。

* https://gist.github.com/7shi/d9556be0474220916649

# MSYS2用パッケージ

pacmanからインストールできるパッケージを用意しました。

* [msys2-crossgcc のインストール方法](https://osdn.jp/projects/msys2-crossgcc/howto/install)

# 熱血！アセンブラ入門のサンプル

次のサイトで公開されています。

* [熱血！アセンブラ入門 サポートページ](http://kozos.jp/books/asm/) → アセンブラ出力環境

Makefileから不要なアーキテクチャをコメントアウトして、PREFIXを修正すればとりあえず使えます。

## パッチ

ここで紹介している方法で作った全アーキテクチャに対応するパッチです。

* https://gist.github.com/7shi/297fdae231b3caa2dbd7

差分は次の通りです。

* 除去: m6811-elf, strongarm-elf, xscale-elf
* 追加: bfin-elf, m32c-elf, microblaze-elf, moxie-elf, rx-elf, score-elf, sparc64-elf, spu-elf

具体的には次を参照してください。

* https://bitbucket.org/7shi/hotasm/wiki/Home

## ARC

64ビット環境ではarc-elfがエラーになるため、コメントアウトした方が良いでしょう。

```text
---- compile (arc-elf.c => arc-elf.s)
/usr/bin/arc-elf-gcc \
                -fno-builtin -nostdinc -nostdlib -static -O -Wall -g  \
                -fverbose-asm -fomit-frame-pointer  -o arc-elf.s -S arc-elf.c
arc-elf.c: 関数 ‘return_short_upper’ 内:
arc-elf.c:49:1: エラー: 認識できない命令:
(insn 5 4 6 3 (set (reg:HI 68 [ <retval> ])
        (const_int -18 [0xffffffffffffffee])) arc-elf.c:48 -1
     (nil))
arc-elf.c:49:1: コンパイラ内部エラー: extract_insn 内、位置 recog.c:2109
Please submit a full bug report,
with preprocessed source if appropriate.
See <http://gcc.gnu.org/bugs.html> for instructions.
```

gcc内の中間言語RTLのLISP風表記が見えています。
