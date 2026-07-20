---
coediting: false
comments_count: 0
created_at: '2024-09-03T18:14:26+09:00'
id: 0cedc2a55c8ca0bb7538
likes_count: 2
private: false
reactions_count: 0
stocks_count: 0
tags:
- name: JavaScript
  versions: []
- name: Emscripten
  versions: []
- name: WebAssembly
  versions: []
- name: WASI
  versions: []
title: Emscripten と WASI
updated_at: '2024-09-04T04:15:34+09:00'
url: https://qiita.com/7shi/items/0cedc2a55c8ca0bb7538
slide: false
---

Emscripten は WASI に準拠した WebAssembly を出力できます。その挙動を確認します。

:::note info
シリーズの記事です。

1. [Emscripten の基本的な使い方とグルーコード](https://qiita.com/7shi/items/70ec93b683c0a1bcef6f)
2. Emscripten と WASI ← この記事
3. [WebAssembly で同じコードを独立して動かす](https://qiita.com/7shi/items/34f7d4693bd4b16d2df3)
:::

# WASI

WASI は WebAssembly System Interface の略で、WebAssembly がシステムとやり取りするためのインターフェースです。WASI は WebAssembly がブラウザ以外の環境で動作するための仕様で、POSIX に似た API が提供されています。

https://wasi.dev/

WASI に準拠したバイナリが実行できる処理系がいくつかあります。

- [Wasmtime](https://wasmtime.dev/)
- [Wasmer](https://wasmer.io/)

# Emscripten

Emscripten で WASI に準拠した WebAssembly を出力する方法を確認します。

ハローワールドのソースを用意します。

```c:hello.c
#include <stdio.h>

int main() {
    printf("Hello, World!\n");
    return 0;
}
```

Emscripten でオプションを何も付けずにソースだけ指定してコンパイルします。

```text
emcc hello.c
```

a.out.wasm と a.out.js が出力されました。これは WASI に完全に準拠しているわけではなく、wasmtime や wasmer では動きません。

```text
$ wasmtime a.out.wasm
Error: failed to run main module `a.out.wasm`

Caused by:
    0: failed to instantiate "a.out.wasm"
    1: unknown import: `env::_emscripten_memcpy_js` has not been defined
$ wasmer a.out.wasm
error: Instantiation failed
╰─▶ 1: Error while importing "env"."_emscripten_memcpy_js": unknown import. Expected Function(FunctionType { params: [I32, I32, I32], results: [] })
```

:::note info
[前回の記事](https://qiita.com/7shi/items/70ec93b683c0a1bcef6f) で見たように、`_emscripten_memcpy_js` はグルーコード (a.out.js) で定義される関数で、WASI に準拠していません。
:::

WASI に準拠した WebAssembly を出力するには、`-sPURE_WASI` を付けてコンパイルします。

```text
emcc -sPURE_WASI hello.c
```

これは wasmtime や wasmer で動作します。グルーコード経由で Node.js でも動きます。

```text
$ wasmtime a.out.wasm
Hello, World!
$ wasmer a.out.wasm
Hello, World!
$ node a.out.js
Hello, World!
```

:::note info
emcc に HTML を出力させれば、ブラウザでも動きます。
:::

## 最低限のグルーコード

wasmtime や wasmer は WASI に準拠した関数を提供するため、a.out.wasm が動きます。

自分でグルーコードを書く場合、インポートされる `proc_exit` と `fd_write` を実装する必要があります。

```javascript
(async function () {
    const fs = require('fs');
    const fds = [null, process.stdout, process.stderr];
    const wasmBuffer = fs.readFileSync('a.out.wasm');
    const wasmModule = await WebAssembly.instantiate(wasmBuffer, {
        wasi_snapshot_preview1: {
            proc_exit: process.exit,
            fd_write,
        },
    });
    const buffer = wasmModule.instance.exports.memory.buffer;
    const view = new DataView(buffer);
    const HEAPU8 = new Uint8Array(buffer);

    wasmModule.instance.exports._start();

    function fd_write(fd, iov, iovcnt, pnum) {
        const buf = [];
        for (let i = 0; i < iovcnt; i++, iov += 8) {
            const ptr = view.getUint32(iov, true);
            const len = view.getUint32(iov + 4, true);
            for (let j = 0; j < len; j++) {
                buf.push(HEAPU8[ptr + j]);
            }
        }
        const decoder = new TextDecoder('utf-8');
        if (fds[fd]) fds[fd].write(decoder.decode(new Uint8Array(buf)));
        view.setUint32(pnum, buf.length, true);
        return 0;
    }
})();
```
```text:実行結果
Hello, World!
```

単に `main` を抜けるだけでなく、明示的にプロセスを終了させる `proc_exit` が呼ばれます。

## 例外

`process.exit` は Node.js に依存しています。例外を投げることで JavaScript に制御を戻す方法があります。

```javascript:変更箇所 1
            proc_exit: exitCode => { throw exitCode },
```
```javascript:変更箇所 2
    try {
        wasmModule.instance.exports._start();
    } catch (e) {
        console.log("exit code:", e);
    }
```
```text:実行結果
Hello, World!
exit code: 0
```

# WASI の将来

WASI はまだ仕様がプレビューの段階で、POSIX の機能を完全に提供しているわけではありません。将来的には POSIX をカバーすることが目標のようです。

wasmer では独自に WASI を拡張した WASIX を策定しています。

https://wasix.org/

これによって bash や curl などが WebAssembly で動作するようです。OS や CPU から独立した VM としての WebAssembly の可能性を示しています。

https://www.publickey1.jp/blog/23/webassemblyposixwasixbashcurlweblinuxwasmer.html

WASIX は独自規格のため今後どうなるかは未知数ですが、WASI が拡張されることで、発展的に解消されるかもしれません。
