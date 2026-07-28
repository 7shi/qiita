---
coediting: false
comments_count: 0
created_at: '2024-09-02T20:46:46+09:00'
id: 70ec93b683c0a1bcef6f
likes_count: 6
private: false
reactions_count: 0
stocks_count: 4
tags:
- name: JavaScript
  versions: []
- name: Emscripten
  versions: []
- name: HelloWorld
  versions: []
- name: WebAssembly
  versions: []
title: Emscripten の基本的な使い方とグルーコード
updated_at: '2024-09-04T04:14:31+09:00'
url: https://qiita.com/7shi/items/70ec93b683c0a1bcef6f
slide: false
---

WebAssembly (WASM) は、ウェブブラウザで動作する低レベルのアセンブリ風言語です。C/C++/Rust などの言語で書かれたコードを、ウェブ上で高速に実行することを可能にします。

Emscriptenは、C/C++ コードを WebAssembly にコンパイルするためのツールチェインです。WebAssembly へのコンパイルだけでなく、それを処理するための JavaScript のグルーコードと、ブラウザで実行するための HTML ファイルを出力します。

今回は WebAssembly には深入りせず、グルーコードに焦点を絞って、実行環境や JavaScript との連携を調査します。

本記事は Claude 3.5 Sonnet の出力をベースに編集しています。

:::note info
シリーズの記事です。

1. Emscripten の基本的な使い方とグルーコード ← この記事
2. [Emscripten と WASI](https://qiita.com/7shi/items/0cedc2a55c8ca0bb7538)
3. [WebAssembly で同じコードを独立して動かす](https://qiita.com/7shi/items/34f7d4693bd4b16d2df3)
:::

# ハローワールド

まずは、最も基本的な C 言語のプログラムから始めましょう。以下のコードを `hello.c` という名前のファイルとして保存してください。

```c:hello.c
#include <stdio.h>

int main() {
    printf("Hello, World!\n");
    return 0;
}
```

Emscripten でコンパイルします。

   ```
   emcc -o hello.html hello.c
   ```

出力に HTML を指定していますが、WebAssembly と JavaScript も出力されます。

- hello.wasm: C 言語のコードを WebAssembly にコンパイルしたバイナリファイルです。ブラウザはこれを高速に実行できます。
- hello.js: WebAssembly モジュールをロードし、初期化し、実行するためのコード、および C/C++ の標準ライブラリ関数の JavaScript 実装が含まれています。これらのコードが、WebAssembly と JavaScript の世界を「接着（グルー）」する役割を果たすため、**グルーコード**と呼ばれます。
- hello.html: ブラウザで WebAssembly アプリケーションを実行するため、hello.js 経由で helo.wasm を読み込みます。

## ブラウザでの実行

生成された HTML ファイルをローカルに置いたまま開いても、セキュリティ上の制限により正しく動作しません。代わりに、簡単な Web サーバーを使用して実行します。

コマンドラインで Python の簡易 HTTP サーバーを起動します。

```
python -m http.server
```

ブラウザで http://127.0.0.1:8000/hello.html にアクセスすれば、ページ内に "Hello, World!" というメッセージが表示されるはずです。

![hello.html.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/32057/af22fa72-3828-0fd8-ff88-369aa64af628.png)

## Node.jsでの実行

Emscriptenが生成した hello.js ファイルは、ブラウザ環境だけでなく、Node.js でも直接実行することができます。これは、WebAssembly モジュールのテストや、サーバーサイドでの利用を容易にします。

```text
$ node hello.js
Hello, World!
```

このようにブラウザを起動せずに素早くテストできます。

:::note warn
- Node.js 環境では、ブラウザ固有の API は利用できません。例えば DOM 操作などを行うコードは動作しません。
- 一部の機能（ファイルシステムへのアクセスなど）は、Node.js とブラウザで異なる動作をする可能性があります。
:::

# HTML の簡略化

Emscripten が生成したHTMLファイルは、ロゴなど不要な部分が含まれています。今回のハローワールドを動かすのに最低限必要な HTML ファイルを示します。

```html:hello2.html
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>Emscripten Hello World</title>
</head>
<body>
<pre id="output"></pre>
<script>
var Module = {
    print: (...args) => {
        output.innerText += args.join(" ") + "\n";
    },
};
</script>
<script src="hello.js"></script>
</body>
</html>
```

`Module` オブジェクトは、Emscripten が生成した JavaScript が使用するグローバル設定です。ここでは、`print` 関数をカスタマイズして、出力を `<pre>` に表示するようにしています。このように環境に合わせてカスタマイズすることが可能です。

HTML を簡略化することで、WebAssembly の実行に必要な最小限の構造が明確になり、カスタマイズも容易になります。

# グルーコードの簡略化

hello.js は、WebAssembly モジュールのロードや初期化、標準ライブラリ関数の JavaScript 実装など、多くの機能を持っています。今回のハローワールドを動かすのに最低限必要なコードを示します。

```javascript:hello3.js
(async function () {
    const fs = require('fs');
    const fds = [null, process.stdout, process.stderr];
    const wasmBuffer = fs.readFileSync('hello.wasm');
    const wasmModule = await WebAssembly.instantiate(wasmBuffer, {
        env: { _emscripten_memcpy_js },
        wasi_snapshot_preview1: { fd_write },
    });
    const buffer = wasmModule.instance.exports.memory.buffer;
    const view = new DataView(buffer);
    const HEAPU8 = new Uint8Array(buffer);

    wasmModule.instance.exports.main();

    function _emscripten_memcpy_js(dest, src, num) {
        return HEAPU8.copyWithin(dest, src, src + num);
    }

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
$ node hello3.js
Hello, World!
```

このコードでは、WebAssembly モジュールのロードや初期化、標準ライブラリ関数の JavaScript 実装が明確になっています。必要な事項を説明します。

## エクスポート

C 言語の `main()` は JavaScript 側にエクスポートされています。初期化完了後に JavaScript から呼び出すことで実行します。

```javascript
wasmModule.instance.exports.main();
```

## インポート

WebAssembly はメモリ内の操作しかできないため、それ以外の外部とのやり取りは JavaScript で実装する必要があります。

`_emscripten_memcpy_js()` と `fd_write()` は、WebAssembly モジュール内で使用される関数です。これらの関数は、WebAssembly モジュールのインスタンス化時にインポートされます。

```javascript
const wasmModule = await WebAssembly.instantiate(wasmBuffer, {
    env: { _emscripten_memcpy_js },
    wasi_snapshot_preview1: { fd_write },
 });
```

### WASI (WebAssembly System Interface)

`fd_write()` は、WASI (WebAssembly System Interface) の一部です。これは、WebAssembly にシステムレベルの機能（ファイル操作、ネットワーク等）を提供するための標準インターフェースです。

この例では、`printf()` が `fd_write()` に変換されて、標準出力に書き込んでいます。

## メモリモデル

このスクリプトを理解するのに必要な範囲で、WebAssembly のメモリモデルについて説明します。

WebAssembly は連続したバイト列として表現される**リニアメモリ**を使用します。このメモリは、JavaScriptからは `ArrayBuffer` として見えます。

```javascript
const memory = wasmModule.instance.exports.memory;
```

このメモリにアクセスするために、`DataView` や TypedArray を使用します。

```javascript
const view = new DataView(memory.buffer);
const HEAPU8 = new Uint8Array(memory.buffer);
```

`DataView` や `Uint8Array` でアドレスを指定して、メモリから値を読み取ります。

- `DataView`: 任意のバイトアドレスから様々なデータ型を読み書きできます。
- `Uint8Array`: メモリをバイト配列（8 ビット符号なし整数の配列）として扱います。他にも `Int32Array` などいくつかの型が定義されており、まとめて **TypedArray** と呼ばれます。

:::note info
`HEAPU8` という変数名は、Emscripten が生成するグルーコードで一般的に使用される名前です。
:::

いくつか使用例を示します。

アドレス `iov` から 32 ビット符号なし整数を読み取ります。

```javascript
const ptr = view.getUint32(iov, true);
```

:::note info
`true` はリトルエンディアンを指定しており、省略するとビッグエンディアンとなります。WebAssembly はリトルエンディアンを採用しています。
:::

`HEAPU8` からアドレス `ptr + j` のバイトを読み取って、`buf` 配列に追加しています。

```javascript
buf.push(HEAPU8[ptr + j]);
```

TypedArray には連続した領域を扱うメソッドがあります。`copyWithin` メソッドはメモリのコピーに使用します。C 言語で `memcpy()` が呼ばれた際に呼び出されるランタイム関数 `_emscripten_memcpy_js()` の実装に使用されます。

```javascript
function _emscripten_memcpy_js(dest, src, num) {
    return HEAPU8.copyWithin(dest, src, src + num);
}
```

WebAssembly のメモリ内には、文字列は UTF-8 でエンコードされたバイト列として格納されます。これを JavaScript の文字列に変換するには、`TextDecoder` を使用します。

```javascript
const decoder = new TextDecoder('utf-8');
const text = decoder.decode(new Uint8Array(buf));
```

## IOV の構造と役割

`fd_write` は、不連続なメモリ領域に格納される文字列を連結して、ファイルディスクリプタで指定された出力先に書き込む関数です。この処理には、**IOV (Input/Output Vector)** という概念が使われています。

IOV (Input/Output Vector) は、POSIX 系システムの `writev` システムコールに由来する概念で、WebAssembly の WASI 実装でも採用されています。これは、複数の不連続なメモリ領域からデータを効率的に書き込むためのメカニズムです。

IOV の構造は以下のようになっています。

| オフセット | サイズ | 説明 |
|------------|--------|------|
| 0   | 4 bytes| バッファ 1 のアドレス |
| 4   | 4 bytes| バッファ 1 の長さ |
| 8   | 4 bytes| バッファ 2 のアドレス |
| 12  | 4 bytes| バッファ 2 の長さ |
| ... | ...    | ... |

### `fd_write`

`fd_write` の実装に沿って、IOV の処理を説明します。

```javascript
function fd_write(fd, iov, iovcnt, pnum) {
```

`iov` は IOV の先頭のアドレス、`iovcnt` はバッファの個数です。バッファのアドレスと長さを読み取り、JavaScript 側の `buf` にデータをコピーします。

```javascript
    const buf = [];
    for (let i = 0; i < iovcnt; i++, iov += 8) {
        const ptr = view.getUint32(iov, true);
        const len = view.getUint32(iov + 4, true);
        for (let j = 0; j < len; j++) {
            buf.push(HEAPU8[ptr + j]);
        }
    }
```

`buf` に格納されたバイト列を UTF-8 としてデコードし、ファイルディスクリプタに書き込みます。

```javascript
    const decoder = new TextDecoder('utf-8');
    if (fds[fd]) fds[fd].write(decoder.decode(new Uint8Array(buf)));
```

書き込んだバイト数を `pnum` が指すアドレスに書き込みます。

```javascript
    view.setUint32(pnum, buf.length, true);
```

処理が正常終了したことを示す 0 を返します。

```javascript
    return 0;
}
```

`pnum` のアドレスに書き込んだ値は、C 言語からは戻り値として見えます。WASI の仕様から C 言語での定義を引用します。

- https://wasix.org/docs/api-reference/wasi/fd_write

```c
ssize_t write(int fd, const void *buf, size_t count);
```

## HTML

hello3.js を HTML の中に書けば、直接 hello.wasm を読み込むことができます。

```html:hello3.html
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>Emscripten Hello World</title>
</head>
<body>
<pre id="output"></pre>
<script>
(async function() {
    const wasmModule = await WebAssembly.instantiateStreaming(
        fetch('hello.wasm'), {
            env: { _emscripten_memcpy_js },
            wasi_snapshot_preview1: { fd_write },
        }
    );
    const memory = wasmModule.instance.exports.memory;
    const view = new DataView(memory.buffer);
    const HEAPU8 = new Uint8Array(memory.buffer);

    wasmModule.instance.exports.main();

    function _emscripten_memcpy_js(dest, src, num) {
        return HEAPU8.copyWithin(dest, src, src + num);
    }

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
        const text = decoder.decode(new Uint8Array(buf));
        output.innerText += text;
        view.setUint32(pnum, buf.length, true);
        return 0;
    }
})();
</script>
</body>
</html>
```

hello3.js との違いは、hello3.wasm の読み込みと、出力を `<pre>` に表示する部分です。

## 実用面での補足

ここまで、WebAssembly を直接扱うアプローチを見てきましたが、これは内部で行われている処理を示すためです。実際の開発では、Emscripten が生成したグルーコード（ここでは hello.js）をそのまま使用する方が、多くの場合において望ましいです。以下にその理由をまとめます：

1. 利便性:  
   グルーコードは、WebAssembly モジュールの初期化やメモリ管理など、多くの複雑な処理を自動的に行います。開発者は低レベルの詳細を気にせずに、高レベルの機能に集中できます。

2. 互換性:  
   Emscripten は様々なブラウザや環境での互換性を考慮して最適化されています。直接 WebAssembly を扱う場合、これらの互換性の問題を自分で解決する必要があります。

3. 標準ライブラリのサポート:  
   グルーコードには、C言語の標準ライブラリ関数の多くが JavaScript で実装されて含まれます。これらを自分で再実装することは大変な手間が掛かり、また、バグが発生する可能性もあります。

したがって、特別な理由がない限り、Emscripten が生成するグルーコードを使用する方が無難です。

# おわりに

本記事ではグルーコードに焦点を絞ったため、WebAssembly はブラックボックスのまま扱いました。WebAssembly については良い記事がありますので、別途参照することをお勧めします。

ゴリラさんの記事は、WebAssembly の処理系を実装しながら学習できます。

https://zenn.dev/skanehira/books/writing-wasm-runtime-in-rust
