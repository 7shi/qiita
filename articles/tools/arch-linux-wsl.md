---
coediting: false
comments_count: 0
created_at: '2020-04-17T21:36:41+09:00'
id: cfda84909b2ea787afdb
likes_count: 4
private: false
reactions_count: 0
stocks_count: 6
tags:
- name: archLinux
  versions: []
- name: WSL
  versions: []
- name: ArchWSL
  versions: []
title: WSLでUbuntuと共存させてArch Linuxを使う
updated_at: '2020-05-01T05:30:21+09:00'
url: https://qiita.com/7shi/items/cfda84909b2ea787afdb
slide: false
---

Arch Linux はパッケージで提供されるソフトウェアが新しく、管理コマンドの pacman も使いやすいので、WSL にインストールして使い始めました。Ubuntu と共存できます。
<img src="https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/32057/47b9930b-432c-9b30-78fd-f011af241ea2.png" width="400"></image>

# インストール

以下の配布物とインストール方法を使用します。Windows 10 1903/1909 の WSL1 で動作を確認しました。

* [How to Setup · yuk7/ArchWSL Wiki](https://github.com/yuk7/ArchWSL/wiki/How-to-Setup)

ZIP ファイルの展開先はユーザーにアクセス権限があればどこでも良いですが、展開したファイルはインストール後も残しておく必要があります。ファイルを展開したフォルダに rootfs が構築されますが、Windows アプリケーションから直接触ってはいけないため、目立つ場所（デスクトップなど）には置かない方が良いでしょう。私は以下に置いています。

* `C:¥Users¥ユーザー名¥WSL¥Arch`

※ Windows アプリケーションから触る場合は `¥¥wsl$` 経由のパスでアクセスします。

* [WindowsからLinuxファイルへのアクセスが可能に ～「Windows 10 19H1」におけるWSLの改善 - 窓の杜](https://forest.watch.impress.co.jp/docs/news/1170221.html)

# glibc

glibc が新し過ぎて WSL1 ではサポートされていない機能を使っているため問題が発生します。

* [(今はまだ)WSL1にUbuntu 20.04を入れるな](https://qiita.com/mmns/items/eaf42dd3345a2285ff9e)

> この問題が広まっているのは Ubuntu 20.04でglibcが2.31にアップグレードしてからだろうが、Arch Linuxでは2月にアップグレードされているためすでに問題が発生していたようだ(参考: [yuk7/ArchWSL#108](https://github.com/yuk7/ArchWSL/issues/108), 02/12、[VSCode(WSL1)でCPU使用率が下がらない場合の原因と対処法 - Qiita](https://qiita.com/RShirohara/items/727feb89c63cdd0d1f62), 03/03)。ArchWSLはMicrosoft Storeにないのでそもそも存在を初めて知ったが、作者が日本人でしかも19歳ですごいと思った(小学生並みの感想)。

※ 脱線しますが、作者についての情報を知らなかったので驚きました。

引用されている Issue のコメントにあるように、glibc をダウングレードします。

> EDIT: using just this command for downgrading glibc worked also
> pacman -U https://archive.archlinux.org/packages/g/glibc/glibc-2.30-3-x86_64.pkg.tar.xz
> 
> than in /etc/pacman.conf I added IgnorePkg = glibc to ignore package section.

# fakeroot

パッケージの作成（makepkg）には fakeroot を使用します。ただし通常の fakeroot は WSL1 では動きません（System V IPC をサポートしていないため）。回避策として配布物には TCP を有効にした fakeroot-tcp がインストールされています。

依存関係に fakeroot を含むパッケージ（base-devel など）をインストールする際、fakeroot で fakeroot-tcp を置き換えるか確認されます。ここで置き換えてしまうと fakeroot が動かなくなります。

もし tcp でない方の fakeroot に置き換えてしまった場合、手動で fakeroot-tcp を入れ直します。

```text
wget https://github.com/yuk7/arch-prebuilt/releases/download/18082100/fakeroot-tcp-1.23-1-x86_64.pkg.tar.xz
sudo pacman -U fakeroot-tcp-1.23-1-x86_64.pkg.tar.xz
```

【参考】 [WSL上のArchLinuxでyayを使う方法](https://qiita.com/Hayao0819/items/1d647683bf458d10351a)

# Windows Terminal

Arch は Windows Terminal にも自動で登録されます。起動時のカレントディレクトリは `C:¥` ですが、WSL のホームディレクトリに変更するには Windows Terminal の Settings の Arch の項目に以下を追記します。

```text
            "startingDirectory": "//wsl$/Arch/home/ユーザー名"
```

【参考】 [Windows Terminal で WSL を開くときに開始されるディレクトリを $HOME にする](https://qiita.com/bindi/items/6aa20a157d83a6efd86f)（コメント欄）

この記事の冒頭に貼ったスクリーンショットのように Windows Terminal を分割して Ubuntu と Arch を並べるには、起動時のコマンドラインオプションから指定します。詳細は次の記事を参照してください。

* [Windows Terminal (Preview) メモ](https://qiita.com/rubytomato@github/items/e88cab84f36e44797cf2)

※ 残念ながら GUI でタブをドラッグして分割することはできません。

# 参考

今回の記事で紹介した配布物は、次の記事で知りました。この記事では Insider Preview で WSL2 を使用していますが、WSL1 でも動きます。

* [ArchWSLの構築](https://qiita.com/koumaza/items/db4623151a04bd7b2f79)

「WSL Arch Linux」で検索すると、トップに出て来るのは WSL の Ubuntu を Arch で上書きする手法です。

* [WSL にインストール - ArchWiki](https://qiita.com/koumaza/items/db4623151a04bd7b2f79)

WSL は Ubuntu だけでなく Fedora や openSUSE をインストールして共存させることができるため、Arch も共存させたいと思っていました。一時期 Arch のストアアプリが出回っていましたが、非公式なものですぐに消えてしまいました。

* [WSL対応「Arch Linux」が“Microsoft Store”に登場 ～ただし偽物？ - やじうまの杜 - 窓の杜](https://forest.watch.impress.co.jp/docs/serial/yajiuma/1184731.html)

# 個人的な経緯

MSYS2 で pacman に触れて、なかなか良いと思いました。

* [MSYS2でRicty Diminishedを使う設定など](https://qiita.com/7shi/items/894fdd849658880bf6c9)

MSYS2 用に pacman のパッケージを作ってみて、定義ファイルをシェルスクリプトで記述するのが気に入りました。

* [msys2-crossgcc のインストール方法 - msys2-crossgcc - OSDN](https://ja.osdn.net/projects/msys2-crossgcc/howto/install)

FFmpeg で高品質な m4a を生成するには libfdk_aac を有効にする必要があります。しかしバイナリ配布が禁止されているため自分でビルドする必要があります。Arch では AUR の ffmpeg-libfdk_aac を利用すれば自動でビルドしてくれます。

* [なるべく小さい音声ファイルを作る](https://qiita.com/7shi/items/407ad24a5d9ad89be2e5)

こういった経緯で、WSL でも Arch を使いたいと思っていました。
