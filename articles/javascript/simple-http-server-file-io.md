---
coediting: false
comments_count: 0
created_at: '2020-07-08T11:14:52+09:00'
id: 5b3304b4419ae80e650e
likes_count: 3
private: false
reactions_count: 0
stocks_count: 2
tags:
- name: JavaScript
  versions: []
- name: HttpServer
  versions: []
- name: Deno
  versions: []
title: 簡易HTTPサーバーでブラウザからファイルの入出力を試す
updated_at: '2020-07-10T20:44:10+09:00'
url: https://qiita.com/7shi/items/5b3304b4419ae80e650e
slide: false
---

ローカルでスクリプトを動かして処理結果を保存するのと似たような感覚でブラウザからファイルを保存したかったので、Deno でファイルの入出力を仲介するサーバーを作ってみました。

# 概要

ブラウザで実行してローカルに結果を出力することを想定したスクリプトがあるとします。

* test.js

ブラウザはスクリプト単体では読み込めないため、読み込むための HTML を用意します。

* index.html

単にブラウザで動かすだけだとファイルの入出力ができないため、仲介する HTTP サーバーを作ります。

* server.ts

index.html と test.js は server.ts から提供することもできますし、他のサーバーに置いて server.ts はファイルの受け取りだけをすることもできます。他のサーバーに置く場合、ファイルを受け取るには CORS への対応が必要です。

完成したファイルは以下にあります。

* <https://gist.github.com/7shi/235cfbd248eae4e07f123b4f8f227586>

# std.http

Deno の標準ライブラリには HTTP サーバーを作るためのコードが用意されています。

* <https://deno.land/std/http>

ここにある file_server.ts は単独で実行することも、ライブラリとして使用することも可能です。ファイルの最後を見ると、単独で実行されたときだけ `main` を呼び出すようになっています。

* <https://deno.land/std/http/file_server.ts>

```typescript
if (import.meta.main) {
  main();
}
```

※ Python でよく見るやり方です。

```python:Python
if __name__ == "__main__":
    main()
```

file_server.ts をライブラリとして使用すれば、レスポンスでファイルを返せます。やり方を示すサンプルが用意されています。

* <https://deno.land/std/http/testdata/file_server_as_library.ts>

```typescript
import { serve } from "../server.ts";
import { serveFile } from "../file_server.ts";

const server = serve({ port: 8000 });

console.log('Server running...');

for await (const req of server) {
  serveFile(req, './http/testdata/hello.html').then(response => {
    req.respond(response);
  });
}
```

これをベースに改造します。

# await

`for` の中のコードを簡単にするため `await` で書き換えます。

```javascript
  req.respond(await serveFile(req, './http/testdata/hello.html'));
```

`serveFile` に `req` は必要なのか？と思いましたが、コードを見ると、切断時にファイルを閉じていました。

* <https://deno.land/std/http/file_server.ts>

```typescript
  req.done.then(() => {
    file.close();
  });
```

もしここで `await` を使うとレスポンスが返せずに固まってしまうので、使えません。なるほど、`.then` と `await` の使い分けが少し見えました。

# server.ts

どんどん書き換えて、`GET` ではファイルを返して、`POST` では受け取ったデータをファイルとして保存するようにしました。

```typescript:server.ts
import { serve } from "https://deno.land/std/http/server.ts";
import { serveFile } from "https://deno.land/std/http/file_server.ts";

const port = 8080;
const server = serve({ port: port });
const serverURL = `http://127.0.0.1:${port}`;
console.log(serverURL);

const te = new TextEncoder();
for await (const req of server) {
    const hostname = (req.conn.remoteAddr as Deno.NetAddr).hostname;
    console.log(hostname, req.method, req.url);
    if (hostname != "127.0.0.1") {
        req.respond({ status: 403 });
        continue;
    }
    let res: any = {};
    switch (req.method) {
        case "GET":
            let url = req.url;
            if (url == "/end") {
                res.body = te.encode("<m>bye!</m>");
                await req.respond(res);
                server.close();
                continue;
            }
            if (url == "/") url = "/index.html";
            try {
                res = await serveFile(req, url.substring(1));
            } catch (e) {
                console.log(e);
                res.status = 404;
            }
            break;
        case "POST":
            let name = req.url.substring(1);
            try {
                Deno.statSync(name);
                console.log(name, req.contentLength, "denied");
                res.status = 403;
                break;
            } catch {}
            try {
                Deno.writeFile(name, await Deno.readAll(req.body));
                console.log(name, req.contentLength, "created");
                res.body = te.encode("<m>created</m>");
            } catch (e) {
                console.log(e);
                console.log(name, req.contentLength, "failed");
                res.status = 403;
            }
            break;
        default:
            res.status = 403;
            break;
    }
    req.respond(res);
}
```

* ローカルでの使用が目的で、外部に公開することは想定しません。
* ローカルホスト以外からの接続は拒否します。
* `/` は `/index.html` に読み替えます。
* `/end` でサーバーを終了します。
* ファイルの上書きは拒否します。そのため `PUT` ではなく `POST` を使用します。
* `/end` と `POST` は XMLHttpRequest からの利用を想定して XML を返します。

# test.js

ブラウザで動かすスクリプトです。ファイルを2つ保存します。

```javascript:test.js
function log(str) {
    result.appendChild(document.createTextNode(str));
    result.appendChild(document.createElement("br"));
}

function send(method, url, body) {
    log(`${method} ${url}`);
    return new Promise((resolve, reject) => {
        let req = new XMLHttpRequest();
        req.open(method, url);
        req.onload = () => {
            log(`response: ${req.status} ${req.response}`);
            resolve();
        };
        if (body) {
            req.send(new Blob([body], { type: "text/plain" }));
        } else {
            req.send();
        }
    });
}

(async () => {
    await send("POST", "1.txt", "hello\n");
    await send("POST", "2.txt", "world\n");
    await send("GET" , "end");
})();
```

`onload` でレスポンスを受け取ると `send` に対する `await` から抜けます。

# index.html

スクリプト単独では動かないため、JavaScript を読み込むための HTML を用意します。`div` は結果表示用です。

```html:index.html
<!DOCTYPE html>
<html>
    <head>
        <title>File Save Test</title>
    </head>
    <body>
        <div id="result"></div>
        <script src="test.js"></script>
    </body>
</html>
```

# 実行結果

server.ts を立ち上げて、ブラウザで `http://127.0.0.1:8080` を開くと、test.js が実行されます。test.js から server.ts を終了させます。

```text
$ ls
index.html  server.ts  test.js
$ deno run --allow-net --allow-read --allow-write server.ts
http://127.0.0.1:8080
127.0.0.1 GET /
127.0.0.1 GET /test.js
127.0.0.1 POST /1.txt
1.txt 6 created
127.0.0.1 POST /2.txt
2.txt 6 created
127.0.0.1 GET /end
$ ls
1.txt  2.txt  index.html  server.ts  test.js
```
```text:ブラウザ
POST 1.txt
response: 200 <m>created</m>
POST 2.txt
response: 200 <m>created</m>
GET end
response: 200 <m>bye!</m>
```

ファイルができているので、中身を確認します。

```text
$ cat 1.txt
hello
$ cat 2.txt
world
```

test.js から送った内容が保存されています。

上書きは拒否するように作ったため、再度実行すると次のようになります。

```text
$ deno run --allow-net --allow-read --allow-write server.ts
http://127.0.0.1:8080
127.0.0.1 GET /
127.0.0.1 GET /test.js
127.0.0.1 POST /1.txt
1.txt 6 denied
127.0.0.1 POST /2.txt
2.txt 6 denied
127.0.0.1 GET /end
```
```text:ブラウザ
POST 1.txt
response: 403
POST 2.txt
response: 403
GET end
response: 200 <m>bye!</m>
```

# CORS

今回は index.html と test.js も自前でホスティングしましたが、これらを別のサイトに置いて結果だけ受け取ることも想定されます。

CORS (Cross-Origin Resource Sharing) によって、デフォルトではサイトをまたいだデータのやり取りは禁止されるためエラーになります。

```text:エラーの例
Access to XMLHttpRequest at 'http://127.0.0.1:8080/end' from origin 'https://foobar' has been blocked
by CORS policy: No 'Access-Control-Allow-Origin' header is present on the requested resource.
```

このとき、クライアントからは次のようなリクエストが来ます。

```text
origin: https://foo
access-control-request-method: POST
access-control-request-headers: content-type
```

※ origin はブラウザで開いているサイトです。通信がそのサイトから直接来るわけではなく、そのサイトを見ているブラウザから来ます。

今回のサーバーは、必要なときだけ起動して通信をローカルに限るという前提で、リクエストをそのまま許可します。

```typescript:server.ts（switchの前に追加）
    res.headers = new Headers();
    const origin = req.headers.get("origin");
    const acrm   = req.headers.get("access-control-request-method");
    const acrh   = req.headers.get("access-control-request-headers");
    if (origin) res.headers.set("Access-Control-Allow-Origin" , origin);
    if (acrm  ) res.headers.set("Access-Control-Allow-Methods", acrm);
    if (acrh  ) res.headers.set("Access-Control-Allow-Headers", acrh);
```

バイナリファイルの場合、`POST` する前に `OPTIONS` で確認が来ます。回答を含んだヘッダを返せば許可したことになります。

```typescript:server.ts（switchの中に追加）
        case "OPTIONS":
            break;
```

# 感想

Deno の前身である Node.js の頃から言われていたことですが、やはりサーバーとクライアント（ブラウザ）を同じ言語（JavaScript）で書けるのは良いですね。

Node.js は非同期が面倒であまり使わなかったのですが、Deno は Promise ベースで async/await が使えるため、コードも読みやすくなっています。

TypeScript がシームレスに使えるのも良いです。今回は TypeScript であることを意識せずに JavaScript と同じような書き方をしましたが、型チェックが働きます。

まだ Deno の情報はあまり多くありませんが、標準ライブラリはそれほど規模が大きくないので、ヒントになりそうなコードを探して読むような進め方をすることになりそうです。

# Go との関係

何となく雰囲気が Go に似ていると感じたのですが、実際、標準ライブラリは Go を意識しているようです。

* https://deno.land/std

> deno_std is a loose port of [Go's standard library](https://golang.org/pkg/). When in doubt, simply port Go's source code, documentation, and tests. There are many times when the nature of JavaScript, TypeScript, or Deno itself justifies diverging from Go, but if possible we want to leverage the energy that went into building Go. We generally welcome direct ports of Go's code.

DeepL 翻訳

> deno_std は、Go の標準ライブラリの緩やかな移植版です。疑問がある場合は、Goのソースコード、ドキュメント、テストを移植してください。JavaScript、TypeScript、またはDeno自体の性質上、Goからの転用が正当化されることは多々ありますが、可能であれば、Goの構築に費やしたエネルギーを活用したいと考えています。私たちは一般的に、Go のコードを直接移植することを歓迎します。

# 関連記事

今回の記事で作ったサーバーを利用する例です。

* [複数の画像を生成してローカルに保存](https://qiita.com/7shi/items/9d27e1a4911626e1fb8b)

ブラウザで結果を表示するコードは以下の記事に由来します。

* [divに対してconsole.logのようなことをする](https://qiita.com/7shi/items/ca174dac3af8235c5bd2)

サーバーの書き方はプル型パーサーに似ていると思いました。

* [PythonのXMLパースを速度比較](https://qiita.com/7shi/items/c7608db7a097ddd16be6)

# 参考

`hostname` の取得で `req.conn.remoteAddr as Deno.NetAddr` とキャストしている部分は以下の issue を参考にしました。

* [Wrong typings for connection address in http request · Issue #5466 · denoland/deno](https://github.com/denoland/deno/issues/5466)

今回の記事とよく似たコードが出てきて興味深い記事です。

* [CORS を分かってないから動くコード書いて理解する](https://qiita.com/mochizukikotaro/items/6b72ad595db8a6b5514f)

今回の記事とは別の Servest というライブラリを使用して、凝ったサーバーを作る記事です。

* [Deno🦕でRESTfulなAPIサーバーを立ててCloud Runへデプロイしてみる](https://qiita.com/ryo2132/items/8b957ed8b649f941fc3f)

`POST` と `PUT` の違いについて参考にしました。

* [PUT か POST か PATCH か？](https://qiita.com/suin/items/d17bdfc8dba086d36115)

XMLHttpRequest の使い方について参考にしました。

* [バイナリデータの送信と受信 - XMLHttpRequest | MDN](https://developer.mozilla.org/ja/docs/XMLHttpRequest/Sending_and_Receiving_Binary_Data)
* <https://ja.javascript.info/xmlhttprequest>
* [XMLHttpRequest で リクエストメソッドが GET なのに OPTIONS リクエストが送信される](https://qiita.com/im36-123/items/775aa7fd4ba3b171768c)

CORS について参考にしました。

* [なんとなく CORS がわかる...はもう終わりにする。](https://qiita.com/att55/items/2154a8aad8bf1409db2b)
* [CORSの動作を確認した - takapiのブログ](https://takapi86.hatenablog.com/entry/2017/09/18/172846)
* [CORSまとめ](https://qiita.com/tomoyukilabs/items/81698edd5812ff6acb34)
