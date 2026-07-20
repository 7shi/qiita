---
coediting: false
comments_count: 0
created_at: '2023-04-15T03:14:55+09:00'
id: 9e692d2aa4883154888c
likes_count: 11
private: false
reactions_count: 0
stocks_count: 8
tags:
- name: JavaScript
  versions: []
- name: 四則演算
  versions: []
- name: CodeWhisperer
  versions: []
title: Amazon CodeWhisperer で四則演算器を作ってみる
updated_at: '2023-04-15T11:04:39+09:00'
url: https://qiita.com/7shi/items/9e692d2aa4883154888c
slide: false
---

[Amazon CodeWhisperer](https://aws.amazon.com/jp/codewhisperer/) のテストとして JavaScript で四則演算器を作ってみました。Visual Studio Code を使用しました。

この記事のコードをまとめました。

https://codepen.io/7shi/pen/VwEawJr

同じ題材を Github Copilot で扱った記事があります。

https://qiita.com/7shi/items/bea04b48a66c22b83450

# 使用感

:::note info
主に Github Copilot との比較になります。
:::

Github Copilot と同じようなタイミングで反応しますが、やや反応が鈍いようです。期待したタイミングで反応しないときは [Alt]+[C] で反応させられるのが地味に便利です。Github Copilot では [Ctrl]+[Enter] がありますが、別フレームが開かれるなど挙動が異なります。

私の環境では Github Copilot はしばらく使っているとぐるぐる回ったまま反応しなくなることがありますが、Amazon CodeWhisperer では今の所そのような現象は起きていません。

今回はかなり手直しが必要でしたが、AWS と関係ない題材だったことを踏まえれば贅沢は言えません。最初から完成品を期待しないで叩き台だと割り切れば十分です。個人用途では無料で使えますから、使わない手はないと感じました。

# Github Copilot との共存

Github Copilot をメインで使って、Amazon CodeWhisperer は必要に応じて [Alt]+[C] で呼び出すという使い方ができます。

<blockquote class="twitter-tweet" data-conversation="none"><p lang="ja" dir="ltr">CodeWhisperer プラグインの良いところは、自動補完を切っても、alt(option) + c で手動でコード候補を出してくれるところ。<br><br>つまり普段の自動補完は Copilot に任せて、AWS 関連でうまく補完してくれないときは alt + c で CodeWhisperer に代打してもらう使い方が出来る。…</p>&mdash; zaru (@zaru) <a href="https://twitter.com/zaru/status/1646733191615750150?ref_src=twsrc%5Etfw">April 14, 2023</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

逆に、Amazon CodeWhisperer をメインで使って、Github Copilot は必要に応じて [Ctrl]+[Enter] で呼び出すこともできます。

# 文字の読み込み

まずは一文字ずつ読み込むクラスを作ります。

`class StringReader` と打ってクラスを生成します。

```js
class StringReader {
    constructor(str) {
        this.str = str;
        this.index = 0;
    }
    read(length) {
        const result = this.str.substr(this.index, length);
        this.index += length;
        return result;
    }
}
```

`length = 1` と決め打ちにしたいので、引数を省略してメソッドを再生成します。

```js
    read() {
        return this.str[this.index++];
    }
```

`read()` の直前の行でコメントを打ち始めると、英語で説明が補完されました。

```js
    // Returns true if there are no more characters left to read.
```

この説明はおかしいので消してやり直したところ、日本語でコメントが出ました。

```js
    // 一文字ずつ返す
```

同様に `peek` も実装します。

```js
    // 一文字返す
    peek() {
        return this.str[this.index];
    }
```

:::note warn
`read` との挙動の違いが十分に説明できていませんが、細かいことは気にせず先に進みます。
:::

`read` に長さチェックを追加するため、コメントを入力してコードを生成します。

```js
    // 一文字ずつ返す
    read() {
        // 長さをチェック
        if (this.index >= this.str.length) {
            return null;
        }
        // 文字を返す
        return this.str[this.index++];
    }
```

# テスト

`function test_StringReader` と打ち込めば、実装に基づいてテストコードが生成されます。

```js
function test_StringReader() {
    let reader = new StringReader("abc");
    console.log(reader.read());
    console.log(reader.read());
    console.log(reader.read());
    console.log(reader.read());
}
```

テストというより動作確認ですが、`console.log` を `console.assert` に書き換えればテストっぽいコードが生成されました。

```js
function test_StringReader() {
    let reader = new StringReader("abc");
    console.assert(reader.read() === "a");
    console.assert(reader.peek() === "b");
    console.assert(reader.read() === "b");
    console.assert(reader.peek() === "c");
    console.assert(reader.read() === "c");
    console.assert(reader.read() === null);
    console.assert(reader.read() === null);
}
```

# トークンに分割

コメントで仕様を書いてジェネレーターを生成します。

```js
// 括弧と四則演算と数字をトークンに分割するジェネレーター

function* tokenize(str) {
    let reader = new StringReader(str);
    while (true) {
        let c = reader.read();
        if (c === null) {
            break;
        }
        if (c === " ") {
            continue;
        }
        if (c === "(" || c === ")" || c === "+" || c === "-" || c === "*" || c === "/") {
            yield {
                type: "operator",
                value: c
            };
            continue;
        }
        if (c >= "0" && c <= "9") {
            yield {
                type: "number",
                value: c
            };
            continue;
        }
        throw new Error("不正です");
    }
}
```

:::note info
数字が 1 文字しか扱えない点を除けば、まずまずのコードです。
:::

テストを生成します。

```js
function test_tokenize() {
    let tokens = tokenize("1 + 2 * 3");
    console.assert(tokens.next().value.type === "number");
    console.assert(tokens.next().value.type === "operator");
    console.assert(tokens.next().value.type === "number");
    console.assert(tokens.next().value.type === "operator");
    console.assert(tokens.next().value.type === "number");
    console.assert(tokens.next().value === undefined);
}
```

種類しか比較していないのは問題なので、比較用の関数を実装して書き換えるように促します。

```js
// 連想配列の中身が等しいかチェック

function testEqual(a, b) {
    if (a === b) {
        return true;
    }
    if (a === null || b === null) {
        return false;
    }
    if (a.type !== b.type) {
        return false;
    }
    if (a.type === "number") {
        return a.value === b.value;
    }
    return a.value === b.value;
}

function test_tokenize() {
    let tokens = tokenize("1 + 2 * 3");
    console.assert(testEqual(tokens.next().value, {type: "number", value: "1"}));
    console.assert(testEqual(tokens.next().value, {type: "operator", value: "+"}));
    console.assert(testEqual(tokens.next().value, {type: "number", value: "2"}));
    console.assert(testEqual(tokens.next().value, {type: "operator", value: "*"}));
    console.assert(testEqual(tokens.next().value, {type: "number", value: "3"}));
    console.assert(testEqual(tokens.next().value, undefined));
}
```

`testEqual` は `tokenize` の返り値に特化しているため、汎用的な比較関数ではありません。

:::note warn
`if (a.type === "number") {` の判定は省略できますが、動作に支障はないため先に進みます。
:::

## 連続した数字

:::note info
ここでの作業は、あらかじめ完成形がイメージできている前提です。
:::

連続した数字が読み込めるように修正します。

`StringReader` に必要なメソッドを追加します。名前まで打って実装を生成させます。

```js
    readWhile(predicate) {
        let str = "";
        while (predicate(this.peek())) {
            str += this.read();
        }
        return str;
    }
```

文字が数字かどうかを判定する関数も、名前まで打って生成します。

```js
function isDigit(ch) {
    return ch >= "0" && ch <= "9";
}
```

これらを使って、数字を読み取る部分を修正します。

```js
        if (isDigit(c)) {
            yield {
                type: "number",
                value: c + reader.readWhile(isDigit)
            };
            continue;
        }
```

テストに複数桁の数字を含む式を追加します。

```js
    tokens = tokenize("12 + 345 * 6");
    console.assert(testEqual(tokens.next().value, {type: "number", value: "12"}));
    console.assert(testEqual(tokens.next().value, {type: "operator", value: "+"}));
    console.assert(testEqual(tokens.next().value, {type: "number", value: "345"}));
    console.assert(testEqual(tokens.next().value, {type: "operator", value: "*"}));
    console.assert(testEqual(tokens.next().value, {type: "number", value: "6"}));
    console.assert(testEqual(tokens.next().value, undefined));
```

# 計算

コメントから実装とテストを生成します。

```js
// 優先順位を考慮して四則演算を行う

function parse(tokens) {
    let stack = [];
    for (const token of tokens) {
        if (token.type === "number") {
            stack.push(Number(token.value));
        } else {
            let right = stack.pop();
            let left = stack.pop();
            if (token.value === "+") {
                stack.push(left + right);
            } else if (token.value === "-") {
                stack.push(left - right);
            } else if (token.value === "*") {
                stack.push(left * right);
            } else if (token.value === "/") {
                stack.push(left / right);
            }
        }
    }
    return stack.pop();
}

function test_parse() {
    let tokens = tokenize("12 + 345 * 6");
    console.assert(parse(tokens) === 791);
}
```

`parse` という名前は自動で付きましたが、パースだけでなく計算まで行います。中身は逆ポーランド記法によるスタックマシンの操作です。

:::note warn
テストは逆ポーランド記法になっていないため失敗します。期待値 `791` も間違っています。
:::

テストが通るように手動で修正します。

```js
function test_parse() {
    let tokens = tokenize("12 345 6 * +");
    console.assert(parse(tokens) === 2082);
}
```

## 中置記法

:::note info
ここでの作業も、あらかじめ完成形がイメージできている前提です。
:::

中置記法のパースは、式 (expression)・項 (term)・因子 (factor) に区切るのが定石です。

それを踏まえて最初の 3 行だけを書くと、残りは生成されました。

```js
function evaluate(tokens) {
    let token = tokens.next().value;
    return expression(); // ここまで手入力

    function expression() {
        let left = term();
        while (true) {
            let op = tokens.next().value;
            if (op.type === "operator" && op.value === "+") {
                left += term();
            } else if (op.type === "operator" && op.value === "-") {
                left -= term();
            } else {
                tokens.prev();
                return left;
            }
        }
    }
    function term() {
        let left = factor();
        while (true) {
            let op = tokens.next().value;
            if (op.type === "operator" && op.value === "*") {
                left *= factor();
            } else if (op.type === "operator" && op.value === "/") {
                left /= factor();
            } else {
                tokens.prev();
                return left;
            }
        }
    }
    function factor() {
        let token = tokens.next().value;
        if (token.type === "number") {
            return parseInt(token.value);
        }
        if (token.type === "operator" && token.value === "(") {
            let result = expression();
            token = tokens.next().value;
            if (token.type === "operator" && token.value === ")") {
                return result;
            }
        }
        throw new Error("不正です");
    }
}
```

:::note warn
このコードは実装されていない `prev` を前提としているため動きません。
:::

補完の際に外部ライブラリへの参照が追加されましたが、不要なため削除します。

```js
import * as term from 'terminal-kit';
```

:::note warn
`term` という名前に引きずられてターミナル関係の関数をインポートしたようです。
:::

## 修正

`prev` は期待するトークンでなければロールバックするという発想になっています。

発想を逆にして、成功した時だけ先に進むように修正します。`token` は常に先頭のトークンを指し、`evaluate` 内の各関数で共有します。

```js
function evaluate(tokens) {
    let token;
    function next() {
        token = tokens.next().value;
    }
    next();
    return expression();

    function expression() {
        let value = term();
        while (token) {
            if (token.type === "operator" && token.value === "+") {
                next();
                value += term();
            } else if (token.type === "operator" && token.value === "-") {
                next();
                value -= term();
            } else {
                break;
            }
        }
        return value;
    }

    function term() {
        let value = factor();
        while (token) {
            if (token.type === "operator" && token.value === "*") {
                next();
                value *= factor();
            } else if (token.type === "operator" && token.value === "/") {
                next();
                value /= factor();
            } else {
                break;
            }
        }
        return value;
    }

    function factor() {
        if (token.type === "number") {
            const result = parseInt(token.value);
            next();
            return result;
        }
        if (token.type === "operator" && token.value === "(") {
            next();
            const result = expression();
            if (token.type === "operator" && token.value === ")") {
                next();
                return result;
            }
        }
        throw new Error("不正です");
    }
}
```

:::note info
ある程度手動で修正すると、同じパターンの部分はそれに倣ったコードを提案してくれるようになります。修正における手動と自動の比率は 7:3 くらいです。
:::

## テスト

テストを生成すると、やはり期待値が間違っています。

```js
function test_evaluate() {
    console.assert(evaluate(tokenize("12 + 345 * 6")) === 770);
    console.assert(evaluate(tokenize("12 + 345 * 6 - (3 * 4)")) === 770);
    console.assert(evaluate(tokenize("12 + 345 * 6 - (3 * 4) / 2")) === 770);
    console.assert(evaluate(tokenize("12 + 345 * 6 - (3 * 4) / 2 + 1")) === 771);
}
```

期待値を修正します。

```js
function test_evaluate() {
    console.assert(evaluate(tokenize("12 + 345 * 6")) === 2082);
    console.assert(evaluate(tokenize("12 + 345 * 6 - (3 * 4)")) === 2070);
    console.assert(evaluate(tokenize("12 + 345 * 6 - (3 * 4) / 2")) === 2076);
    console.assert(evaluate(tokenize("12 + 345 * 6 - (3 * 4) / 2 + 1")) === 2077);
}
```

無事に動きました。

# 関連記事

今回の例ではある程度の叩き台は作ってくれましたが、手動での修正が必須でした。定石を知らないと修正は困難です。

定石については以下の記事を参照してください。

https://qiita.com/7shi/items/64261a67081d49f941e3

逆ポーランド記法について説明した記事も書きました。Haskell で書かれていますが、最初の概要だけを見ておけば CodeWhisperer が提示したコードは理解できるでしょう。

https://qiita.com/7shi/items/0494704d00396687458f
