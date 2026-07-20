---
coediting: false
comments_count: 0
created_at: '2024-09-04T04:12:05+09:00'
id: 34f7d4693bd4b16d2df3
likes_count: 2
private: false
reactions_count: 0
stocks_count: 1
tags:
- name: JavaScript
  versions: []
- name: Emscripten
  versions: []
- name: WebAssembly
  versions: []
title: WebAssembly で同じコードを独立して動かす
updated_at: '2024-09-04T18:55:30+09:00'
url: https://qiita.com/7shi/items/34f7d4693bd4b16d2df3
slide: false
---

WebAssebmly では同一のモジュールの複数のインスタンスが作成できます。これを利用すれば、グローバル変数をそれぞれのインスタンスで独立して利用することができます。

:::note info
シリーズの記事です。

1. [Emscripten の基本的な使い方とグルーコード](https://qiita.com/7shi/items/70ec93b683c0a1bcef6f)
2. [Emscripten と WASI](https://qiita.com/7shi/items/0cedc2a55c8ca0bb7538)
3. WebAssembly で同じコードを独立して動かす ← この記事
:::

# グローバル変数を含む例

次のような C のコードを考えます。

```c:global.c
#include <emscripten.h>
#include <stdio.h>

EMSCRIPTEN_KEEPALIVE
void test() {
    static int n = 1;
    printf("%d\n", n++);
}

int main() {
    test();
    test();
}
```

`EMSCRIPTEN_KEEPALIVE` は関数をエクスポートするためのマクロです。JavaScript から呼び出す関数はこのマクロを付ける必要があります。このマクロを使うため `emscripten.h` をインクルードしています。

Emscripten でコンパイルして、Node.js で動作確認します。

```text
$ emcc -o global.js global.c
$ node global.js
1
2
```

## 追加呼び出し

別のスクリプトから global.js 経由で global.wasm を呼び出します。WASI に準拠しないでコンパイルしたため、`main` から抜けてもプログラムは終了しません。そのため、`test()` を追加で呼び出すことができます。

```javascript
const g = require('./global.js');
setTimeout(() => {
    g._test();
}, 10);
```
```text:実行結果
1
2
3
```

非同期で初期化が行われるため、`setTimeout` で待機します。`EMSCRIPTEN_KEEPALIVE` でエクスポートした関数にアクセスするには、接頭辞 `_` を関数名の前に付けます。

:::note warn
待機せずにすぐ `g._test()` を呼ぼうとすると、初期化が完了していないとしてエラーになります。

```text
Aborted(Assertion failed: native function `test` called before runtime initialization)
```
:::

## コールバック

初期化終了のタイミングを知るには、コンパイル時に `addOnPostRun` をエクスポート指定します。

```text
emcc -sEXPORTED_RUNTIME_METHODS=addOnPostRun -o global.js global.c
```

コールバックを `addOnPostRun` で登録すれば、`main` 終了後に呼ばれます。

```javascript
const g = require('./global.js');
g.addOnPostRun(() => {
    g._test();
});
```
```text:実行結果
1
2
3
```

## ブラウザ

ブラウザから呼び出す場合、`Module.postRun` にコールバックを登録します。

```html
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
    postRun: () => {
        Module._test();
    },
};
</script>
<script src="global.js"></script>
</body>
</html>
```

# インポート関数

コードが複雑になれば、インポートする関数も増えます。Emscripten が生成したグルーコードの最後に以下のコードを付け足せば、関数の情報が取得できます。

```javascript:最後に付け足すコード
console.log("const wasmImports = {");
for (const [k ,v] of Object.entries(wasmImports)) {
  console.log(`  ${k}:`, v.toString() + ",");
}
console.log("};");
```
```text:実行結果
const wasmImports = {
  _emscripten_memcpy_js: (dest, src, num) => HEAPU8.copyWithin(dest, src, src + num),
  fd_write: (fd, iov, iovcnt, pnum) => {
      // hack to support printf in SYSCALLS_REQUIRE_FILESYSTEM=0
      var num = 0;
      for (var i = 0; i < iovcnt; i++) {
        var ptr = HEAPU32[((iov)>>2)];
        var len = HEAPU32[(((iov)+(4))>>2)];
        iov += 8;
        for (var j = 0; j < len; j++) {
          printChar(fd, HEAPU8[ptr+j]);
        }
        num += len;
      }
      HEAPU32[((pnum)>>2)] = num;
      return 0;
    },
};
```

# 複数のインスタンス

同じコードを複数のインスタンスで動かします。メモリが分離されるため、グローバル変数は共有されません。

global.js がそのまま使えないため、Node.js 用のグルーコードを自前で実装します。

```javascript
(async function () {
    const fs = require('fs');
    const fds = [null, process.stdout, process.stderr];
    const wasmBuffer = fs.readFileSync('global.wasm');
    const wasmModule = await WebAssembly.compile(wasmBuffer);

    const instance1 = await instantiate();
    const instance2 = await instantiate();
    instance1.exports.main();  // 1, 2
    instance2.exports.main();  // 1, 2
    instance1.exports.test();  // 3
    instance1.exports.test();  // 4
    instance2.exports.test();  // 3
    instance2.exports.test();  // 4

    async function instantiate() {
        const ret = await WebAssembly.instantiate(wasmModule, {
            env: { _emscripten_memcpy_js },
            wasi_snapshot_preview1: { fd_write },
        });
        const buffer  = ret.exports.memory.buffer;
        const HEAPU32 = new Uint32Array(buffer);
        const HEAPU8  = new Uint8Array (buffer);
        return ret;

        function _emscripten_memcpy_js(dest, src, num) {
            return HEAPU8.copyWithin(dest, src, src + num);
        }

        function fd_write(fd, iov, iovcnt, pnum) {
            // hack to support printf in SYSCALLS_REQUIRE_FILESYSTEM=0
            var num = 0;
            for (var i = 0; i < iovcnt; i++) {
                var ptr = HEAPU32[((iov)>>2)];
                var len = HEAPU32[(((iov)+(4))>>2)];
                iov += 8;
                for (var j = 0; j < len; j++) {
                    printChar(fd, HEAPU8[ptr+j]);
                }
                num += len;
            }
            HEAPU32[((pnum)>>2)] = num;
            return 0;
        }
    }

    function printChar(fd, ch) {
        fds[fd].write(String.fromCharCode(ch));
    }
})();
```
```text:実行結果
1
2
1
2
3
4
3
4
```

インスタンスごとにメモリを扱う変数が別になるため、インスタンスを作成する関数の中で `buffer` やインポートする関数を定義しています。

Emscripten が生成するグルーコードを通していないため、エクスポートされた関数にプレフィックス `_` は付きません。

## ブラウザ

ブラウザでも同様に処理が行えます。ファイル読み込みと `printChar` の部分が異なりますが、その間の部分は同じため省略します。

```html
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>Emscripten WebAssembly Instances</title>
</head>
<body>
<pre id="output"></pre>
<script>
(async function () {
    const stream = fetch('global.wasm');
    const wasmModule = await WebAssembly.compileStreaming(stream);

（省略）

    function printChar(fd, ch) {
        output.innerText += String.fromCharCode(ch);
    }
})();
</script>
</body>
</html>
```

# まとめ

グローバル変数で状態を持つような C 言語のプログラムを、クラスのように別々にインスタンス化して動かせます。この仕組みで新規に何か作るということはあまりないかもしれませんが、既存のコードを WebAssembly に移植する際には役立つかもしれません。
