---
coediting: false
comments_count: 0
created_at: '2025-04-03T03:01:11+09:00'
id: 9a4a3a4544a30aa7b033
likes_count: 2
private: false
reactions_count: 0
stocks_count: 1
tags:
- name: Go
  versions: []
- name: メモリ管理
  versions: []
- name: Mmap
  versions: []
title: Go ランタイムのメモリ管理：mmap と sbrk
updated_at: '2025-04-05T06:27:07+09:00'
url: https://qiita.com/7shi/items/9a4a3a4544a30aa7b033
slide: false
---

C 言語の `malloc()` を実装するのに古典的な `sbrk()` は使われなくなりました。Go 言語では C 言語のライブラリ (libc) は使わずに独自にメモリを管理しているので、その状況を調べました。

:::note info
Claude 3.7 Sonnet による調査結果をベースに編集した記事です。
:::

本記事と関連して、メモリ割り当ての詳細や GC についても調査した記事があります。

https://qiita.com/7shi/items/510653e0c0e28411cc9d

# 概要

Go ランタイムは現在、主要なプラットフォームではメモリ割り当てに `mmap` システムコールを使用しています。古典的な `sbrk` システムコールの実装が含まれていますが、その具体的な経緯についての詳細なドキュメントは限られています。

本記事では、利用可能な情報を基に Go のメモリ管理についての調査結果をまとめます。

# 古典的な UNIX のメモリ管理

かつて UNIX のプロセスメモリモデルはシンプルで、text（コード）、data（初期化されたデータ）、bss（ゼロ初期化されたデータ）、スタックから構成されていました。ブレークアドレスは bss の末端、つまりプロセスのデータセグメントと未使用領域の境界アドレスに位置していました。

16 ビットの PDP-11 でのメモリ状況を示します。

アドレス|セグメント
|---:|----|
|0000|text|
||data|
||bss|
|break (初期)|(未使用)|
|～FFFF|スタック|

プログラムが追加のメモリを必要とする場合、`brk()` または `sbrk()` システムコールを使ってこのブレークアドレスを変更するよう、OS に要求していました。この仕組みにより、C 言語の `malloc()` などの動的メモリ割り当て関数が実装されていました。

アドレス|セグメント
|---:|----|
|0000|text|
||data|
||bss|
||ヒープ|
|break (変更後)|(未使用)|
|～FFFF|スタック|

:::note info
FFFF 付近には `main()` 関数に渡すコマンドライン引数などの情報が入っています。詳細は以下の記事を参照してください。
:::

https://qiita.com/7shi/items/71532036c53d321a2b17

## `mmap` の導入

4.2BSD で `mmap()` が導入され、プロセスのメモリ空間内の未使用の場所にページ単位で仮想メモリを追加（および削除）できるようになりました。これにより、メモリ割り当てライブラリは様々な方法でこの新機能を活用できるようになりました。

メモリ割り当てに `mmap()` を使用することには、いくつかの利点があります。

1. **柔軟性**: アドレスを指定してメモリを割り当てることができる
2. **独立性**: 各 `mmap()` 割り当ては他のコードと競合せず、個別に操作できる
3. **効率性**: 大きなメモリブロックの割り当てや解放が簡単
4. **アドレス空間の制約**: 64 ビットシステムでは、アドレス空間を使い果たす心配が少ない

# Go ランタイムのメモリ管理

Chris Siebenmann 氏の[ブログ記事](https://utcc.utoronto.ca/~cks/space/blog/unix/SbrkVersusMmap)より

> For example, the Go runtime allocates all of its memory through `mmap()`.

（訳：例えば、Go ランタイムはすべてのメモリを `mmap` を通じて割り当てています。）

この記述から、少なくとも主要なプラットフォームでは、Go ランタイムは現在メモリ割り当てに `mmap()` を採用していることがわかります。

関連するソースコードは以下で確認できます。

- [mmap.go](https://go.dev/src/runtime/mmap.go)

## プラットフォーム依存の実装

Go のソースコードを調査すると、[mem_sbrk.go](https://go.dev/src/runtime/mem_sbrk.go) というファイルが存在し、次のビルドタグを持っています。

```go
//go:build plan9 || wasm
```

これは、Plan 9 と WebAssembly (wasm) では、`sbrk` ベースのメモリ管理が使われていることを示しています。この実装は、これらの特定のプラットフォームの要件または制約に対応するためと考えられます。

## デバッグオプション

現在の Go ランタイムには、`GODEBUG=sbrk=1` というデバッグオプションがあります。[公式ドキュメント](https://pkg.go.dev/runtime)より

> `sbrk`: setting `sbrk=1` replaces the memory allocator and garbage collector with a trivial allocator that obtains memory from the operating system and never reclaims any memory.

（訳：`sbrk`: `sbrk=1` を設定すると、メモリアロケータとガベージコレクタが、OS からメモリを取得して決して回収しない単純なアロケータに置き換えられます。）

このオプションは主にデバッグ目的で、バグのあるコードを診断するための一時的な回避策として使用されます。

## 移行の経緯

Go ランタイムが `brk` から `mmap` に移行した具体的なコミット履歴や、いつ、どのバージョンでこの移行が行われたかについての明確な記録は見つかりませんでした。

いくつかのGitHub Issueでは、`GODEBUG=sbrk=1` 使用時の問題が報告されています。

- [Issue #33159](https://github.com/golang/go/issues/33159): `GODEBUG=sbrk=1` 使用時の Linux/ARM でのセグメンテーションフォールト
- [Issue #53887](https://github.com/golang/go/issues/53887): `sbrk` モードでのクラッシュ

これらの問題は、`sbrk` ベースのメモリ管理がもはやメインラインの実装ではなく、完全にサポートされていないことを示唆しています。

# まとめ

現在、Go ランタイムは主要プラットフォームではメモリ割り当てに `mmap` を使用しており、古典的な `sbrk` は主にデバッグ目的または一部の特殊なプラットフォーム（Plan 9 や WebAssembly）でのみ使用されています。

この移行は Go の初期の開発段階で行われたと思われますが、具体的なコミット履歴やバージョン情報は公開された資料からは確認できませんでした。
