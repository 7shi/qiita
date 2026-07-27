---
coediting: false
comments_count: 0
created_at: '2020-07-09T19:44:09+09:00'
id: 5e8d87c14ba057039518
likes_count: 7
private: false
reactions_count: 0
stocks_count: 2
tags:
- name: Go
  versions: []
title: いきなりGoを使うのに試したこと
updated_at: '2020-07-10T17:13:59+09:00'
url: https://qiita.com/7shi/items/5e8d87c14ba057039518
slide: false
---

ちょうど欲しいと思っていたライブラリが Go で書かれているのを見付けました。それまで Go を使ったことがなかった状態から、そのライブラリを使うために試行錯誤した過程をメモしておきます。

# ライブラリ

使いたかったのは vocx というライブラリです。エスペラントをポーランド語のエンジンで音声合成するため、ポーランド語風の綴りに変換するというものです。

* <https://github.com/martinrue/vocx>

用途は特殊ですが、受け取った文字列を正規表現で変換しており、ありふれた文字列処理です。

```go:Usage
t := vocx.NewTranscriber()
t.Transcribe("Ĉu vi ŝatas Esperanton? Esperanto estas facila lingvo.")

// czu wij szatas esperanton? esperanto estas fatssila lijngwo.
```

# ビルド

まずライブラリを git clone します。

Makfile にはテストのことしか書かれていません。

```makefile:Makefile
all: test

test:
        @go test -mod=vendor -cover ./...

.PHONY: all test
```

`make` するとテストは実行されますが、バイナリの類は生成されません。

```text
$ ls
LICENSE  Makefile  README.md  default_rules.go  go.mod  rules.go  vocx.go  vocx_test.go
$ make
ok      github.com/martinrue/vocx       0.025s  coverage: 94.9% of statements
$ ls
LICENSE  Makefile  README.md  default_rules.go  go.mod  rules.go  vocx.go  vocx_test.go
```

`go build` としても、やはり何も生成されません。

# main.go

とりあえずこのディレクトリに見よう見まねで main.go を書いてみます。

【参考】 [goコマンドざっくりまとめ](https://qiita.com/gougyan/items/8db66b1d05aec0921791)

```go:main.go
package main

import (
    "fmt"
    "github.com/martinrue/vocx"
)

func main() {
    t := vocx.NewTranscriber()
    r := t.Transcribe("Ĉu vi ŝatas Esperanton? Esperanto estas facila lingvo.")
    fmt.Println(r)
}
```

しかしビルドも実行もできません。

```text
$ go build
can't load package: package github.com/martinrue/vocx: found packages vocx (default_rules.go) and main (main.go) in /home/xxx/vocx
$ go run main.go
main.go:5:5: found packages vocx (default_rules.go) and main (main.go) in /home/xxx/vocx
```

ファイル名を指定してもダメです。

```text
$ go build main.go default_rules.go rules.go vocx.go
can't load package: package main: found packages main (main.go) and vocx (default_rules.go) in /home/xxx/vocx
$ go run main.go default_rules.go rules.go vocx.go
package main: found packages main (main.go) and vocx (default_rules.go) in /home/xxx/vocx
```

エラーメッセージを見る限り、異なるパッケージを同じディレクトリに混ぜてはいけないようです。

## 分離

別にディレクトリを作って、main.go を単独で置きます。

とりあえず実行してみると、当然のようにライブラリが見付かりません。

```text
$ go run main.go
main.go:5:5: cannot find package "github.com/martinrue/vocx" in any of:
        /usr/lib/go/src/github.com/martinrue/vocx (from $GOROOT)
        /home/xxx/go/src/github.com/martinrue/vocx (from $GOPATH)
```

試しに言われたディレクトリを作って vocx を移すと、実行できました。

```text
$ mkdir -p ~/go/src/github.com/martinrue
$ mv ../vocx ~/go/src/github.com/martinrue
$ go run main.go
czu wij szatas esperanton? esperanto estas fatssila lijngwo.
```

## go.mod

とりあえず動きましたが、あまりスマートではないので調べました。

どうやらモジュールの初期化が必要なようです。

【参考】 [Go Modules](https://qiita.com/propella/items/e49bccc88f3cc2407745)

初期化すると、ビルド時に自動で依存パッケージをダウンロードしてくれました。これはスマートです。

```text
$ ls
main.go
$ go mod init test
go: creating new go.mod: module test
$ ls
go.mod  main.go
$ go build
go: finding module for package github.com/martinrue/vocx
go: downloading github.com/martinrue/vocx v0.0.8
go: found github.com/martinrue/vocx in github.com/martinrue/vocx v0.0.8
$ ls
go.mod  go.sum  main.go  test*
$ ./test
czu wij szatas esperanton? esperanto estas fatssila lijngwo.
```

生成された go.mod と go.sum の内容を示します。

```text:go.mod
module test

go 1.14
```
```text:go.sum
github.com/martinrue/vocx v0.0.8 h1:02g28A3fxULEeg9ew7mSRR1jJ+5zAFAMKwleAZdTqfw=
github.com/martinrue/vocx v0.0.8/go.mod h1:rlD2FhmLGi03xF/XfdIprJQMKFXcItoAZzUo2guy1po=
```

ダウンロードされたライブラリは ~/go/pkg に入りました。GOPATH を設定すれば変えられるようです。

## ここまでのまとめ

Go でプログラムを書くときは、新規にディレクトリを作成して `go mod init` する。こうすれば依存ライブラリはビルド時に自動でダウンロードされる。

# コマンドライン引数

変換対象の文字列をコマンドライン引数で指定できるようにします。

【参考】 [golang でコマンドライン引数を使う](https://qiita.com/RyotaNakaya/items/2d0befa2c1cf347800c3)

```go:main2.go
package main

import (
    "fmt"
    "os"
    "github.com/martinrue/vocx"
)

func main() {
    t := vocx.NewTranscriber()
    r := t.Transcribe(os.Args[1])
    fmt.Println(r)
}
```
```text:実行結果
$ go run main2.go "Ĉu vi ŝatas Esperanton? Esperanto estas facila lingvo."
czu wij szatas esperanton? esperanto estas fatssila lijngwo.
```

## 引数のチェック

引数の数をチェックしていないため、引数を指定しないとエラーになります。

```text:エラー
$ go run main2.go
panic: runtime error: index out of range [1] with length 1

goroutine 1 [running]:
main.main()
        /home/xxx/vocx/main2.go:11 +0xd7
exit status 2
```

引数の数をチェックします。Python と同様に `len()` を使います。

【参考】 [逆引きGolang (配列)#配列の要素数を取得する](https://ashitani.jp/golangtips/tips_slice.html#slice_Count)

```go:main3.go
package main

import (
    "fmt"
    "os"
    "github.com/martinrue/vocx"
)

func main() {
    if len(os.Args) > 1 {
        t := vocx.NewTranscriber()
        r := t.Transcribe(os.Args[1])
        fmt.Println(r)
    }
}
```
```text:実行結果
$ go run main3.go
$ go run main3.go "Ĉu vi ŝatas Esperanton? Esperanto estas facila lingvo."
czu wij szatas esperanton? esperanto estas fatssila lijngwo.
```

## usage

引数を指定しないときは標準エラー出力に usage を表示して終了します。

【参考】 [【Go】print系関数の違い](https://qiita.com/taji-taji/items/77845ef744da7c88a6fe)
【参考】 [Go でシェルの Exit code を扱う | tellme.tokyo](https://tellme.tokyo/post/2018/04/02/golang-shell-exit-code/)

```go:main4.go
package main

import (
    "fmt"
    "os"
    "github.com/martinrue/vocx"
)

func main() {
    if len(os.Args) != 2 {
        fmt.Fprintf(os.Stderr, "usage: %s text\n", os.Args[0])
        os.Exit(1)
    }
    t := vocx.NewTranscriber()
    r := t.Transcribe(os.Args[1])
    fmt.Println(r)
}
```
```text:実行結果
$ go run main4.go
usage: /tmp/go-build031103390/b001/exe/main4 text
exit status 1
```

ビルドすると `exit status` は表示されなくなります。

```text
$ go build main4.go
$ ./main4
usage: ./main4 text
$ echo $?
1
```

# ファイル読み込み

オプションを指定してファイルを読み込めるようにします。

【参考】 [golang でコマンドライン引数を使う](https://qiita.com/RyotaNakaya/items/2d0befa2c1cf347800c3)
【参考】 [Go言語でのファイル読み取り](https://qiita.com/Kashiwara/items/9a8365ea800e6f39713f)
【参考】 [Go でシェルの Exit code を扱う | tellme.tokyo](https://tellme.tokyo/post/2018/04/02/golang-shell-exit-code/)

```go:main5.go
package main

import (
    "flag"
    "fmt"
    "io/ioutil"
    "os"
    "github.com/martinrue/vocx"
)

func main() {
    file := flag.String("f", "", "file to read")
    flag.Parse()
    if *file == "" && flag.NArg() != 1 {
        fmt.Fprintf(os.Stderr, "usage: %s [-f file] | text\n", os.Args[0])
        flag.PrintDefaults()
        os.Exit(1)
    }
    t := vocx.NewTranscriber()
    if (*file == "") {
        fmt.Println(t.Transcribe(flag.Arg(0)))
    } else {
        f, err := os.Open(*file)
        if err != nil {
            fmt.Fprintf(os.Stderr, "[ERROR] %v\n", err)
            os.Exit(1)
        }
        b, _ := ioutil.ReadAll(f)
        f.Close()
        fmt.Println(t.Transcribe(string(b)))
    }
}
```
```text:実行結果
$ go build main5.go
$ ./main5
usage: ./main5 [-f file] | text
  -f string
     file to read
$ echo Ĉu vi ŝatas Esperanton? Esperanto estas facila lingvo. > test.txt
$ ./main5 -f test.txt
czu wij szatas esperanton? esperanto estas fatssila lijngwo.
```

普通のコマンドラインツールっぽくなって来ました。

# REPL

gore という REPL があるようなので試してみます。

【参考】 [みんGo学習メモ〜コード補完もできるREPL「gore」を使ってみた](https://qiita.com/Ken2mer/items/94301d04d65c82088c60)

```go
$ gore
gore version 0.5.0  :help for help
gore> :import github.com/martinrue/vocx
gore> t := vocx.NewTranscriber()
（略）
gore> t.Transcribe("Ĉu vi ŝatas Esperanton? Esperanto estas facila lingvo.")
"czu wij szatas esperanton? esperanto estas fatssila lijngwo."
```

今までの苦労は何だったんだ？というくらいあっけないですね。今回は本格的にプログラミングしたいわけではなく、ライブラリをちょっと試したかっただけなので、これで十分だったかもしれません。

# 感想

急に必要に迫られたため、学習を飛ばして新しい言語をいきなり使わざるを得ないということは、割とあります。使い始めは右も左も分からないので、どうしても個別にやりたいことを調べてコピペするような感じになってしまいます。

ライブラリの使用感は Python に似ていると感じました。スクリプト言語からネイティブコンパイルする言語に乗り換える選択肢としては、Go は C 言語よりもかなり敷居が低いのではないでしょうか。

プログラムをディレクトリ単位で管理することを前提にコマンドが作られていて、コマンドでビルドや実行をするのは、今の流行りのようです。.NET Core や Rust もそのやり方です。

* [.NET CoreでプロジェクトなしにF#を使う](https://qiita.com/7shi/items/6bc57ddde5a06e526496)
* [Rust/WinRTで音声合成](https://qiita.com/7shi/items/885501607aecee7613fa)

# 関連記事

エスペラントの綴りを音節に分解して、UPS と呼ばれる発音表記に変換して読み上げる記事です。この方法は発音を比較的忠実に再現できますが、環境を選びます。

* [SAPIで未サポートの言語を喋らせる](https://qiita.com/7shi/items/ecb9ea901e4026a925ee)

# 参考

vocx は Parol というシステムの一部です。Parol は以下で知りました。

* [pronunciation - TTS for Esperanto - Esperanto Language Stack Exchange](https://esperanto.stackexchange.com/questions/5742/tts-for-esperanto)

Parol のデモサイトです。実際にしゃべらせて MP3 で保存できます。音声合成には Amazon Polly を使用しています。

* [Parol – La Voĉroboto](https://parol.martinrue.com/)

作者は Parol を使った言語学習システムを開発中のようです。

* [How Does Esperanto Sound?](https://martinrue.com/how-does-esperanto-sound/)

Parol と SAPI を比較した動画です。

<blockquote class="twitter-tweet" data-conversation="none"><p lang="cs" dir="ltr">komparo de vocx (konvertilo de Parol) kaj ssml-epo (mia konvertilo)<br><br>Mi pensas, ke Herena (kataluna) havas la plej bonan voĉon, sed ŝi havas iom da bruo. Tial mi preferas uzi Filip (slovaka).<br><br>ssml-epo<a href="https://t.co/MEso23LQbd">https://t.co/MEso23LQbd</a> <a href="https://t.co/GJXBsGy28f">pic.twitter.com/GJXBsGy28f</a></p>&mdash; 7shi_conlang (@7shi_conlang) <a href="https://twitter.com/7shi_conlang/status/1280545213350436864?ref_src=twsrc%5Etfw">July 7, 2020</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>
