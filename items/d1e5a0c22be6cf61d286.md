---
coediting: false
comments_count: 3
created_at: '2014-08-28T15:13:45+09:00'
id: d1e5a0c22be6cf61d286
likes_count: 86
private: false
reactions_count: 0
stocks_count: 84
tags:
- name: Haskell
  versions: []
title: Haskell IDE Leksah 入門
updated_at: '2020-06-08T15:55:01+09:00'
url: https://qiita.com/7shi/items/d1e5a0c22be6cf61d286
slide: false
---

Haskell用のIDE（統合開発環境）Leksahの簡単な使い方を説明します。それほど機能が充実しているわけではありませんが、初めてHaskellを使うときの環境選択に迷った時は、とりあえずLeksahを触ってみてはいかがでしょうか。

Windows/Mac OS X/各種UNIX系に対応しています。

* http://leksah.org/

# インストール

1. Haskell Platform <font color="red">**※ 忘れないように注意！**</font>
2. Leksah

最初にHaskell Platformをインストールします。これを飛ばしてうまく動かないケースがよくあるので、必ずインストールしてください。

* https://www.haskell.org/platform/

※ WindowsではOSが64bitでも32bit版をインストールした方が安定しています。

Leksahのインストール方法はOSごとに説明します。

## Windows

<font color="red">**【注意】**</font> この記事の情報は古いです。既にこのバージョンは動かない可能性があります。

新しいバージョンは安定しないようなので、古いバージョンを推奨します。

* http://www.leksah.org/packages/leksah-0.12.1.3-ghc-7.4.1.exe

## Mac OS X

<font color="red">**【注意】**</font> この記事の情報は古いです。既にこのバージョンは動かない可能性があります。

新しいバージョンは安定せず、古いバージョンにはキャレットが消える問題があるため、安定しているバージョンを紹介します。（[情報源](https://code.google.com/p/leksah/issues/detail?id=277)）

* http://www.leksah.org/packages/leksah-0.13.2.5-ghc-7.6.3.dmg

dmgを開くとアプリが出て来ますが、それを直接起動するのではなく、アプリケーションフォルダなどにコピーしてください。

## 各種UNIX系

ディストリビューションにパッケージがあればそれをインストールしてください。なければソースからビルドしてください。

# 起動

起動すると確認画面が表示されます。そのまま[OK]をクリックします。

![leksah1.png](https://qiita-image-store.s3.amazonaws.com/0/32057/aac79f12-99b5-8730-7bec-2bb38d7cd30d.png)

環境の調査が始まるのでしばらく待ちます。

![leksah2.png](https://qiita-image-store.s3.amazonaws.com/0/32057/0af1c713-f26e-d715-47c8-56e64542bd58.png)

本体が起動します。次回の起動からは確認や調査などはなく本体がすぐ起動します。

![leksah3.png](https://qiita-image-store.s3.amazonaws.com/0/32057/4e827984-7cea-a1db-1af4-17ba45c038b1.png)

# 初期設定

補完候補の自動表示は画面がずれるなど弊害の方が大きいため、オフにすることを推奨します。

メニューから設定します。

* Configuration (Macの場合はメニュー左端のLeksah) → Edit Prefs
    * GUI Options → Complete only on Hotkey にチェックを付ける
    * [Save]

自動表示をオフにしても[Ctrl]+[Space]で出せます。

# 動作確認

初期状態でサンプルプログラムが開かれているので、ビルドして実行します。

## configure

初めてビルドするときや設定を変更したときはconfigureが必要です。

次のアイコンをクリックしてください。

![leksah4.png](https://qiita-image-store.s3.amazonaws.com/0/32057/b72b88ea-ea30-cd1a-bdf0-afe878b15e12.png)

※ ここで番号だけが出て他に何もログが出ない場合、Haskell Platformがインストールされているか確認してください。

右下のログを見て完了を確認します。

```text
Resolving dependencies...
Configuring leksah-welcome-0.12.0.3...
-----------------------------------------
```

※ 赤字で警告が出ても無視して続行してください。

```text
Warning: The package list for 'hackage.haskell.org' is 30 days old.
Run 'cabal update' to get the latest list of available packages.
```

## ビルド

次のアイコンをクリックしてください。

![leksah5.png](https://qiita-image-store.s3.amazonaws.com/0/32057/423556a6-c3ca-b07c-243a-b6d0a035ec26.png)

右下のログを見て完了を確認します。

```text
Building leksah-welcome-0.12.0.3...
Preprocessing test suite 'test-leksah-welcome' for leksah-welcome-0.12.0.3...
[1 of 1] Compiling Main             （略）
Loading package ghc-prim ... linking ... done.
（略）
Linking dist\build\test-leksah-welcome\test-leksah-welcome.exe ...
Preprocessing executable 'leksah-welcome' for leksah-welcome-0.12.0.3...
[1 of 1] Compiling Main             （略）
Loading package ghc-prim ... linking ... done.
（略）
Linking dist\build\leksah-welcome\leksah-welcome.exe ...
-----------------------------------------
Installing executable(s) in （略）
-----------------------------------------
```

### エラー

以下のようなエラーが発生することがあります。

```text
<command line>: cannot satisfy -package-id ...
```

Leksahの外でコマンドを実行してください。Leksahは終了しなくても構いません。

```text
$ ghc-pkg recache
```

## 実行

次のアイコンをクリックしてください。

![leksah6.png](https://qiita-image-store.s3.amazonaws.com/0/32057/40300f66-dadc-4202-9e8a-336bf8326209.png)

右下のログを見て動作を確認します。

```text
Hello World
-----------------------------------------
```

プログラム修正時に自動的に保存してビルドされます。そのためビルド操作は毎回やる必要はなく、以降は実行操作のみで開発を進めます。

# シンプルなパッケージを作成

新しく開発を始める時はワークスペースとパッケージを作成します。学習用として余分な機能を使わないシンプルなパッケージの作成方法を説明します。

まず開いているソースのタブを閉じてください。

![leksah7.png](https://qiita-image-store.s3.amazonaws.com/0/32057/719f0189-39b8-4a49-6f7d-41ec2ada073f.png)

## ワークスペース作成

パッケージ（後述）を複数まとめておく単位です。

メニューから新規作成します。

* Workspace → New

1. 適当なフォルダに移動します。
2. [Create Folder]でワークスペースを入れるフォルダを作成します。フォルダ名を適当に入力します。
3. Name欄に適当な名前（2で作成したフォルダと同名を推奨）を入力して[Save]をクリックします。

※ フォルダ名を入力後に必ず[Enter]を押して確定してください。確定せずに先に進むとフォルダが作成されません。

## パッケージ作成

1つのプログラムはパッケージという単位で管理されます。

メニューから新規作成します。

* Package → New

1. ワークスペースのフォルダの中に、パッケージのフォルダを作成します。フォルダを作成しないと動作がおかしくなるため、必ずフォルダを作成してください。
2. [Open]をクリックします。

## パッケージ設定

設定画面が開きます。ビルドが重くなるためテスト関係の設定を外します。

* Dependencies → QuickCheck → Remove

![leksah8.png](https://qiita-image-store.s3.amazonaws.com/0/32057/28e2193f-9097-1fb4-03ca-846709d6528d.png)

* Tests → Remove

![leksah9.png](https://qiita-image-store.s3.amazonaws.com/0/32057/2e541698-7d71-60e8-009f-90a85d7b061e.png)

* Remove Build Info
* Save

![leksah10.png](https://qiita-image-store.s3.amazonaws.com/0/32057/ac607252-50ef-f067-1a25-e2671fa0d798.png)

## ハローワールド

サンプルのMain.hsが開きます。初期学習用にはこの内容をベースにするよりスクラッチから書いた方が良いため、[Ctrl]+[A]で全選択して[Backspace]で消去します。

ハローワールドを入力します。

```hs
main = do
    print "Hello, World!"
```

入力中にバックグラウンドでビルドが始まります。ログが落ち着かない感じです。この機能をオフにすることもできますが、文法チェックも兼ねているため、しばらくそのまま使ってみることをお勧めします。

実行アイコンをクリックしてください。

![leksah6.png](https://qiita-image-store.s3.amazonaws.com/0/32057/40300f66-dadc-4202-9e8a-336bf8326209.png)

右下のログを見て動作を確認します。

```text
"Hello, World!"
```

後はここに色々と書きながら学習を進めれば良いでしょう。

取っ掛かりとして次の記事をリンクしておきます。

* [Haskell 超入門](http://qiita.com/7shi/items/145f1234f8ec2af923ef)

---

* 参考: [neue cc - Haskell用IDE 「Leksah」の紹介と導入方法](http://neue.cc/2010/01/04_233.html)
