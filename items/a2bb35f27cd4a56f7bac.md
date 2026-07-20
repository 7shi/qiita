---
coediting: false
comments_count: 0
created_at: '2020-02-08T04:52:25+09:00'
id: a2bb35f27cd4a56f7bac
likes_count: 59
private: false
reactions_count: 0
stocks_count: 64
tags:
- name: JavaScript
  versions: []
- name: promise
  versions: []
- name: TextToSpeech
  versions: []
- name: WebSpeechAPI
  versions: []
- name: AsyncAwait
  versions: []
title: 非同期APIをPromiseでラップしてasync/awaitで使う
updated_at: '2023-12-06T12:24:33+09:00'
url: https://qiita.com/7shi/items/a2bb35f27cd4a56f7bac
slide: false
---

setTimeout と Web Speech API を Promise でラップする例を示します。

Promise とメソッドチェーンだけでは何がやりたいのか分かりにくいかもしれませんが、async/await もセットで考えることで狙いが分かりやすくなると思います。

※ Web Speech API の例は単純なので、触れたことがなくても分かると思います。

C# との比較については以下の記事を参照してください。

* [PromiseとTaskCompletionSource](https://qiita.com/7shi/items/5e1e95252f1456301522)

# setTimeout

Promise の例としては定番です。

## コールバック

非同期 API にコールバックを渡す処理をネストすると、いわゆるコールバック地獄になります。

`setTimeout` によって1秒後に1、その2秒後に2、その更に3秒後に3を表示する例です。

```javascript
setTimeout(() => {
    console.log(1);
    setTimeout(() => {
        console.log(2);
        setTimeout(() => {
            console.log(3);
        }, 3000);
    }, 2000);
}, 1000);
```
```text:実行結果
1
2
3
```

コールバックが深くなるのに加えて、待機時間と後続の処理との対応が分かりにくいです。

:::note info
このように後続の関数（コールバック）で渡す書き方を[継続渡しスタイル](https://ja.wikipedia.org/wiki/%E7%B6%99%E7%B6%9A%E6%B8%A1%E3%81%97%E3%82%B9%E3%82%BF%E3%82%A4%E3%83%AB)（CPS）と呼びます。詳細は以下の記事を参照してください。

* [CPS 変換による末尾再帰化](https://qiita.com/7shi/items/2d25f7afe25c3ca11acb)
:::

## Promise

`setTimeout` を Promise でラップします。`resolve` は成功したとき、`reject` は失敗したときのコールバックです。この例では失敗は考慮しないため `reject` は無視します。

`resolve` が呼ばれた後の処理を `.then` で渡します。

```javascript
function wait(timeout) {
    return new Promise((resolve, reject) => setTimeout(resolve, timeout));
}

wait(1000).then(() => {
    console.log(1);
    wait(2000).then(() => {
        console.log(2);
        wait(3000).then(() => {
            console.log(3);
        });
    });
});
```

これだけだと `setTimeout` が `wait().then` に置き換わっただけで、あまりメリットはありません。（待機時間と後続の処理との対応が多少分かりやすくなったくらいでしょうか）

コールバックから Promise を返すように書き換えることができます。

```javascript
wait(1000).then(() => {
    console.log(1);
    return wait(2000);
}).then(() => {
    console.log(2);
    return wait(3000);
}).then(() => {
    console.log(3);
});
```

コールバックのネストが `.then` によるメソッドチェーンに変わりました。ネストが深くなることはなくなり、多少読みやすくなりました。

最初のネストした `wait().then` の書き方と比較すれば、`return` で Promise を返してコールバックを抜けてから `.then` でつなぐことで、ネストをフラットにしていることが分かります。（そこが分からないと、どうやって読むのかピンと来ないかもしれません）

## async/await

Promise を使いやすくするための糖衣構文です。`wait` の定義はそのままです。

```javascript
function wait(timeout) {
    return new Promise((resolve, reject) => setTimeout(resolve, timeout));
}

(async function () {
    await wait(1000);
    console.log(1);
    await wait(2000);
    console.log(2);
    await wait(3000);
    console.log(3);
})();
```

同期的な処理のように記述することができます。`await` は「Promise の `resolve` が呼ばれるまで待つ」くらいに解釈すれば良いでしょう。`await` は `async function`（非同期関数）の中でしか使えないため、即時実行関数式にしています。

こうして見ると、Promise は非同期 API と async/await の間を取り持っていることが良く分かります。

※ async/await が糖衣構文だというのは、`await` の次の行から先がコールバックに変換されて `.then` で接続されることを意味します。厳密には少し違うのですが、Promise の中で `resolve` を呼ぶことは、変換されたコールバックを呼び出すことに相当します。このように後続の処理をコールバックに変換することを CPS 変換と呼びます。

* [ジェネレーターを簡易的にCPS変換してみた](https://qiita.com/7shi/items/55f10aa99108afd5a128)

## resolve

ある程度慣れて来ると、「`resolve` が呼ばれれば `Promise` から抜ける」という感覚で捉えると見通しが良くなります。実際には `resolve` の後のコードも処理されるのですが、`resolve` の後には何も処理を書かない（またはすぐ `return` する）方が良いでしょう。

:::note info
ここでは詳しく触れませんが、`resolve` は継続と呼ばれる概念に近いです。いくつか相違点がありますが、それを踏まえた上で継続だと思って使っています。

* 継続は後続のコードを打ち切って即座に処理を移すが、`resolve` は後続のコードを実行してから非同期で `await` に戻る。
* 継続は何度でも呼ぶことができるが、`resolve` を複数回呼んでも 2 回目以降は何も起きない。
:::

## co

async/await がない時代に、同じようなことをジェネレーターで実装した co というライブラリがあります。

* [tj/co: The ultimate generator based flow-control goodness for nodejs (supports thunks, promises, etc)](https://github.com/tj/co)

co の簡易版を実装して比較します。（説明に必要な範囲に限定しています）

【参考】[ES2017におけるasyncとgenerator、Promise、CPS、モナドの関係](https://qiita.com/legokichi/items/77a36b7d2b75d8278f9d)

```javascript
function co(g) {
    let it = g();
    function f() {
        let result = it.next();
        if (!result.done) return result.value.then(f);
    }
    return f();
}

co(function* () {
    yield wait(1000);
    console.log(1);
    yield wait(2000);
    console.log(2);
    yield wait(3000);
    console.log(3);
});
```

async/await が模倣できていて面白いです。

co は async/await が正式にサポートされるまでのつなぎだったようで、今となっては使う必要はなさそうですが、発想は参考になります。また、Promise を検索すると co が現役だった当時の記事が出て来るため、async/await に読み替えられるということを知っておいても損はないでしょう。

【参考】[ES7 async/awaitと、coがPromiseベースになっていたこと](https://qiita.com/Misumi_Rize/items/21ebced5fe783183c492)

> もしasync/awaitが実装されれば、coからそのまま乗り換えることも可能になるだろう。

# Web Speech API

`setTimeout` では失敗を考慮しませんでしたが、Web Speech API を例に失敗のあるケースを示します。

Web Speech API によってブラウザでテキストの読み上げを行います。読み上げは非同期的に行われますが、終了を待たずに次々指示しても、キューに溜まって順番に処理されます。

```javascript
function speak(lang, text) {
    let u = new SpeechSynthesisUtterance(text);
    u.lang = lang;
    speechSynthesis.speak(u);
}

speak("en", "Hello, world!");
speak("fr", "Bonjour, monde !");
speak("ja", "こんにちは、世界！");
```

連続で読み上げるだけであれば終了を待つ必要はありませんが、もし途中で失敗しても無視して次に進んでしまいます。

## コールバック

成功した時だけ次に進むようにするため、終了を待ってコールバックで次の読み上げを指示します。

```javascript
function speak(lang, text, end, error) {
    let u = new SpeechSynthesisUtterance(text);
    u.lang = lang;
    u.onend = end;
    u.onerror = error;
    speechSynthesis.speak(u);
}

speak("en", "Hello, world!", () => {
    speak("fr", "Bonjour, monde !", () => {
        speak("ja", "こんにちは、世界！", () => {
        }, e => console.log(e));
    }, e => console.log(e));
}, e => console.log(e));
```

失敗した時は例外を表示します。同じ例外処理を何度も書いています。

※ 一般に `e => console.log(e)` のように引数を別の関数に取り回すだけのラムダ式は、引数を省略して `console.log` とも書けます（これをポイントフリースタイルと呼びます）。今回は async/await に書き換える際に `e` が出て来るため、引数を明示した形で進めます。

## Promise

`setTimeout` では無視した `reject` を失敗時のコールバックとして使います。失敗時の処理は `.catch` で与えます。

まずはネストのまま書き換えます。

```javascript
function speak(lang, text) {
    return new Promise((resolve, reject) => {
        let u = new SpeechSynthesisUtterance(text);
        u.lang = lang;
        u.onend = resolve;
        u.onerror = reject;
        speechSynthesis.speak(u);
    });
}

speak("en", "Hello, world!").then(() => {
    speak("fr", "Bonjour, monde !").then(() => {
        speak("ja", "こんにちは、世界！").then(() => {
        }).catch(e => console.log(e));
    }).catch(e => console.log(e));
}).catch(e => console.log(e));
```

これをフラットにします。何もしない最後の `.then` を省略して、失敗時の処理を1つにまとめます。

```javascript
speak("en", "Hello, world!")
    .then(() => speak("fr", "Bonjour, monde !"))
    .then(() => speak("ja", "こんにちは、世界！"))
    .catch(e => console.log(e));
```

かなりすっきりしました。

最初の `speak` だけ書き方が異なりますが、ダミーの Promise から始めることで揃えられます。

```javascript
new Promise((resolve, reject) => resolve())
    .then(() => speak("en", "Hello, world!"))
    .then(() => speak("fr", "Bonjour, monde !"))
    .then(() => speak("ja", "こんにちは、世界！"))
    .catch(e => console.log(e));
```

ダミーの Promise を生成する簡単な方法があります。

```javascript
Promise.resolve()
    .then(() => speak("en", "Hello, world!"))
    .then(() => speak("fr", "Bonjour, monde !"))
    .then(() => speak("ja", "こんにちは、世界！"))
    .catch(e => console.log(e));
```

【参考】[Promiseを複数組み合わせる時の基本パターン（直列、並列、分岐）](https://qiita.com/norami_dream/items/0edfca15c15199921a73)

> 最初にダミーのPromise.resolve()を入れるようにしています。

## async/await

メソッドチェーンを非同期の即時実行関数式で書き換えます。`speak` の定義は `Promise` と同じため省略します。

```javascript
(async function () {
    try {
        await speak("en", "Hello, world!");
        await speak("fr", "Bonjour, monde !");
        await speak("ja", "こんにちは、世界！");
    } catch (e) {
        console.log(e);
    }
})();
```

`try`～`catch` によって同期的な処理に近い見た目で記述できました。

## co

参考までに co 版を書いておきます。

```javascript
co(function* () {
    yield speak("en", "Hello, world!");
    yield speak("fr", "Bonjour, monde !");
    yield speak("ja", "こんにちは、世界！");
}).catch(e => console.log(e));
```

# まとめ

Promise で成功と失敗のコールバックに振り分けてラップすることで、async/await によって表記が簡略化できます。

# 参考

Promise の詳細は MDN の記事が参考になります。「古いコールバック API をラップする Promise の作成」のセクションは今回の記事と関係があります。

* [Promiseを使う - JavaScript | MDN](https://developer.mozilla.org/ja/docs/Web/JavaScript/Guide/Using_promises)

## Web Speech API

Web Speech API の使い方は以下の記事を参照してください。

* [Web Speech API で読み上げ位置を取得](https://qiita.com/7shi/items/43452dcd34e57100fc3c)

Promise と組み合わせた応用的な使い方は以下を参照してください。

* [Promiseの処理をキャンセルする](https://qiita.com/7shi/items/4cc1928061ff4598f10b)

## モナド

コールバックから async/await への書き換えは、Haskell での `>>=` を明示した書き方から do ブロックへの書き換えに対応します。

* [Haskell アクションとラムダ 超入門](https://qiita.com/7shi/items/4a8a2807bb5186576c61)

JavaScript のジェネレーターでモナドを実装している記事です。co の方式とも密接な関係があります。

* [JavaScript + generator で Maybe、 Either、 Promise、 継続モナドと do 構文を実装し async-await と比べてみる](https://qiita.com/legokichi/items/0582e71f4e6984548933)
* [ジェネレーターで関数モナドとStateモナドを模倣してみた](https://qiita.com/7shi/items/e5365885fb53c015630c)
