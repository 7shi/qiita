---
coediting: false
comments_count: 0
created_at: '2015-01-29T21:26:31+09:00'
id: 894fdd849658880bf6c9
likes_count: 19
private: false
reactions_count: 0
stocks_count: 19
tags:
- name: msys2
  versions: []
title: MSYS2でRicty Diminishedを使う設定など
updated_at: '2017-01-09T15:54:14+09:00'
url: https://qiita.com/7shi/items/894fdd849658880bf6c9
slide: false
---

MSYSはWindowsでgccを動かすためのミニマムなUNIX風環境です。最新版のMSYS2はArch Linux由来のpacmanを搭載するなど大幅に使いやすくなっています。

勉強会で一斉にインストールすることを想定して、インストール後の設定について説明します。

※ 設定は好みが別れる部分もありますが、よく分からない時にとりあえずやっておけば便利だと思われるものを紹介します。

# インストール方法

本家に書いてある通りです。

* https://msys2.github.io/

手順5.と6.の環境が大幅に書き換わる場合は close するよう求められます。ターミナル（mintty）をウィンドウ右上の`[×]`ボタンで閉じて、スタートメニューから MSYS2 Shell を開いて作業を続行します。

【注】ショートカットに登録されているバッチファイルがなくなって MSYS2 Shell が開けなくなることがあります。その場合、ショートカットのリンク先を以下のように書き換えてください。

```text
C:\Windows\System32\cmd.exe /A /Q /C C:\msys64\msys2_shell.cmd
```

最後の手順7.のスクリーンショットに`pacman -S git`とあるのはパッケージからインストールする方法の例です。動作確認を兼ねてgitをインストールしてみましょう。

# pacman

pacmanは[Arch Linux](https://www.archlinux.org/)由来のパッケージ管理システムです。

## パッケージ一覧

インストール済みのパッケージ一覧の表示方法です。

```text
$ pacman -Q
```

※ `$`はプロンプトのマークです。入力しないでください。

ネットワークインストール可能なパッケージ一覧の表示方法です。

```text
$ pacman -Sl
```

## 推奨パッケージ

以下のパッケージをインストールしておくと良いでしょう。

```text
$ pacman -S base-devel gcc nasm yasm python tar zip winpty vim
```

`base-devel`はグループです。所属パッケージは`pacman -Qg base-devel`で確認できます。グループ一覧は`pacman -Qg`です。

`winpty`はWindowsネイティブのコマンドが文字化けしたり起動時に固まったりする問題を回避するためのものです。

## ファイルの確認

`pacman -Ql`でパッケージに含まれるファイルを確認できます。

```text
$ pacman -Ql patch
patch /usr/
patch /usr/bin/
patch /usr/bin/patch.exe
patch /usr/share/
patch /usr/share/man/
patch /usr/share/man/man1/
patch /usr/share/man/man1/patch.1.gz
```

# ショートカット

スタートメニューにはいくつかショートカットが登録されます。

1. MinGW-w64 Win32 Shell
2. MinGW-w64 Win64 Shell
3. MSYS2 Shell

今回は3.を使います。

※ 1と2はMSYS2に依存しないWindowsネイティブのバイナリを扱うモードです。POSIX準拠のプログラムをビルドするのには不向きです。

# フォントの設定

そのままだと日本語メッセージが潰れて読みにくいので、お勧めの設定を紹介します。

## Ricty Diminished

プログラミング向きのフォントです。

* http://www.rs.tus.ac.jp/yyusa/ricty_diminished.html

バージョン名がダウンロードリンクになっています。

ダウンロードしてフォルダを開く手順を示します。

```text
$ mkdir ricty
$ cd ricty
$ wget http://www.rs.tus.ac.jp/yyusa/ricty_diminished/ricty_diminished-4.0.1.tar.gz
$ tar xvf ricty_diminished-4.0.1.tar.gz
$ start .
```

配布物には複数のフォントがありますが、以下に示すどちらかだけをインストールすれば良いでしょう。Discordの方は`7`や`Z`などに特徴があります。

RictyDiminished-Regular.ttf
![ricty1.png](https://qiita-image-store.s3.amazonaws.com/0/32057/d82eb0ae-ba9d-c402-e9e0-8235ffc8ebaa.png) (12point)

RictyDiminishedDiscord-Regular.ttf
![ricty2.png](https://qiita-image-store.s3.amazonaws.com/0/32057/0f53695d-8222-4c6c-8b93-89d107fb1d1f.png) (12point)

## minttyの設定

ターミナル（mintty）を右クリックしてOptionsを選択します。

* Looks
    * Foreground: 白（デフォルトの灰色だと薄いため）
    * Transparency: Med （ウィンドウの透過）

![mintty1.png](https://qiita-image-store.s3.amazonaws.com/0/32057/d2667e89-780e-512e-085a-c5941f5ece54.png)

* Text
    * Font: Ricty Diminished (またはDiscord), 11-point（または12-point）
    * Font smoothing: Partial（設定しないと字が欠ける）
    * Locale: ja_JP
    * Character set: UTF-8

![mintty2.png](https://qiita-image-store.s3.amazonaws.com/0/32057/36eafc82-4340-c2ed-8679-c8cb7e8aefb6.png)

[OK]（または[Save]）をクリックするとフォントが変化します。

# シェルの設定

.bashrcを次のように修正すると良いでしょう。

※ 行頭の`@@`が行番号、`+`が追加、`-`が削除という意味です。`-`の後に同数の`+`が続く場合は、行に変更を加えていると解釈します。

```diff
@@ -15,6 +15,9 @@
 
 # User dependent .bashrc file
 
+alias vi=vim
+alias hd='hexdump -C'
+
 # If not running interactively, don't do anything
 [[ "$-" != *i* ]] && return
 
@@ -88,23 +91,23 @@
 # alias mv='mv -i'
 #
 # Default to human readable figures
-# alias df='df -h'
-# alias du='du -h'
+alias df='df -h'
+alias du='du -h'
 #
 # Misc :)
-# alias less='less -r'                          # raw control characters
-# alias whence='type -a'                        # where, of a sort
-# alias grep='grep --color'                     # show differences in colour
-# alias egrep='egrep --color=auto'              # show differences in colour
-# alias fgrep='fgrep --color=auto'              # show differences in colour
+alias less='less -r'                          # raw control characters
+alias whence='type -a'                        # where, of a sort
+alias grep='grep --color'                     # show differences in colour
+alias egrep='egrep --color=auto'              # show differences in colour
+alias fgrep='fgrep --color=auto'              # show differences in colour
 #
 # Some shortcuts for different directory listings
-# alias ls='ls -hF --color=tty'                 # classify files in colour
-# alias dir='ls --color=auto --format=vertical'
-# alias vdir='ls --color=auto --format=long'
-# alias ll='ls -l'                              # long list
-# alias la='ls -A'                              # all but . and ..
-# alias l='ls -CF'                              #
+alias ls='ls -F --color=tty'                 # classify files in colour
+alias dir='ls --color=auto --format=vertical'
+alias vdir='ls --color=auto --format=long'
+alias ll='ls -l'                              # long list
+alias la='ls -A'                              # all but . and ..
+alias l='ls -CF'                              #
 
 # Umask
 #
```

※ 修正方法がよく分からない時は次のコマンドでフォルダを開き、そこにある.bashrcというファイルを好みのエディタで編集してください。

```text
$ start .
```

# vimの設定

設定ファイルのひな形をコピーします。

```text
$ cp /usr/share/vim/vim80/vimrc_example.vim .vimrc
```

自動バックアップの無効化、行番号の表示、タブ幅、ビープ音の抑制などを付け加えます。

```text
set nobackup
set noundofile
set number
set expandtab
set ts=4
set sw=4
set visualbell
set noerrorbells
```

上記内容をペーストしようとして右クリックすると、vimにマウスイベントが取られてうまくいきません。[Shift]を押しながら右クリックしてください。（後述の中ボタンクリックでもペーストできます）

# プログラミング

簡単なプログラムを作って動かしてみます。

新規ファイル名を指定してvimを起動します。先ほど~/.bashrcで`alias`を設定したため`vi`でvimが呼び出せます。

```text
$ vi hello.c
```

vi系エディタではモードという概念があります。起動時は**ノーマルモード**というモードで、そのままでは入力ができません。

`[I]`キーを押して**挿入モード**に切り替えると、キーボードから入力できるようになります。

※ とりあえず起動したら挿入モードに切り替えさえすれば、その後の編集は他のエディタとそれほど違わない操作で行えます。

次のプログラムを打ち込みます。

```c:hello.c
#include <stdio.h>

int main(void) {
    printf("Hello, World!\n");
    return 0;
}
```

セーブして終了します。`[ESC]`キーを押してノーマルモードに戻り、`[Shift]`キーを押しながら`[Z]`キーを2回押すと、セーブして終了します。

`ls`コマンドでファイル一覧を表示して、入力したファイルが保存されていることを確認します。

```text
$ ls
hello.c
```

gccでコンパイルします。

```text
$ gcc hello.c
```

a.exeというファイルが出力されます。

※ このファイル名はWindows特有です。UNIX系ではa.outとなります。

`ls`で確認します。

```text
$ ls
a.exe*  hello.c
```

`./ファイル名`として実行します。

```text
$ ./a.exe
Hello, World!
```

`printf()`で指定した文字列が表示されました。これがC言語の簡単なプログラミングです。

vimは最低限の使い方のみ説明しました。詳しい使い方については次の説明などを参照してください。

* [Vimの使い方（入門）](http://www15.ocn.ne.jp/~tusr/vim/vim_text0.html) 2008.8.4

# その他

使用上のTipsなどです。

## mintty

minttyはX11風の操作方法をサポートしています。

* 文字を選択しただけでコピーされます。
* 中ボタンクリック（ホイールマウスではホイールクリック）でペーストできます。

## ドライブ

ドライブは次のように指定します。

```text
$ cd /d/foo  ← D:¥foo
```

## 文字化け

MSYS2はUTF-8で動作しているため、Windowsネイティブのコマンドを実行すると文字化けします。次のように`winpty`コマンド経由で実行します。

```text
$ winpty ipconfig

Windows IP 構成


イーサネット アダプター ローカル エリア接続:
（略）
```

## ラッパー

Windowsネイティブのエディタを常用している場合、ラッパーを設定しておくと良いでしょう。サクラエディタの例を示します。

```text:/usr/local/bin/sk
#!/bin/sh
for arg in $@; do
    "/c/Program Files (x86)/sakura/sakura.exe" $arg &
done
```

## アップデート

インストール済みのパッケージをアップデートする際、MSYS2のコアごとアップデートしようとすると失敗します。最初に`update-core`コマンドを実行する必要があります。詳細は次の記事を参照してください。

* [@k_takata](https://twitter.com/k_takata): [MSYS2での正しいパッケージの更新方法 - Qiita](http://qiita.com/k-takata/items/373ec7f23d5d7541f982) 2015.7.7

## git

次のようなエラーが出ることがあります。

```text
fatal: unable to access 'https://github.com/（略）.git/': error setting certificate verify locations:
  CAfile: /usr/ssl/certs/ca-bundle.crt
  CApath: none
```

証明書関係のパッケージを再インストールしてください。

```text
$ pacman -S ca-certificates
```
