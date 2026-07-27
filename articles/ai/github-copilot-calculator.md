---
coediting: false
comments_count: 0
created_at: '2023-02-19T17:30:42+09:00'
id: bea04b48a66c22b83450
likes_count: 0
private: false
reactions_count: 0
stocks_count: 0
tags:
- name: JavaScript
  versions: []
- name: 四則演算
  versions: []
- name: copilot
  versions: []
title: Github Copilot で四則演算器を作ってみる
updated_at: '2023-04-15T03:16:57+09:00'
url: https://qiita.com/7shi/items/bea04b48a66c22b83450
slide: false
---

Github Copilot のテストとして JavaScript で四則演算器を作ってみました。Visual Studio Code を使用しました。

この記事のコードをまとめました。

https://codepen.io/7shi/pen/ZEMbrYB

同じ題材を Amazon CodeWhisperer で扱った記事があります。

https://qiita.com/7shi/items/9e692d2aa4883154888c

# 使用感

使っていて楽しいです。手動で書くときは、ライブラリや言語などの細かい仕様まで全部覚えているわけではないのでその都度調べるのに時間が取られますが、その手間がかなり節約できます。一度使い始めると、これなしでコードが書けなくなりそうです。

現時点の機能は補完がメインです。関数名やクラス名やコメントを書き始めたり、改行したりしたタイミングで続きを提案してくれます。明示的なトリガーは [Ctrl]+[Enter] で、画面が分割されて候補が表示されます。

https://docs.github.com/ja/copilot/getting-started-with-github-copilot/getting-started-with-github-copilot-in-visual-studio-code

[Ctrl]+[Enter] はキャレットがある階層全体を対象に、キャレットから先のコードを提示するようです。そのためグローバルなコンテキストで使うと時間が掛かって長いコードが出てきたりします。ブロック内など意図的にコンテキストを絞った方が使い勝手が良いようです。

コメントによってコード生成を誘導するため、結果的にコメントが豊富なコードを書くことになります。

また、今回は使用していませんが、テスト中の GitHub Copilot Labs では他言語への移植など新機能が実装中のようです。

https://zenn.dev/riya_amemiya/articles/ed4e71fd4108d7

ChatGPT では既存のコードを指示して書き換えたりもしてくれるので、いずれそういった機能も組み込まれることを期待します。

※ 後で実例を示しますが、コードを部分的に再生成することで似たようなことは可能です。

余談ですが、プログラミングだけでなく文章も同じような方式で書けたら面白いのになと思いました。

# 文字の読み込み

まずは一文字ずつ読み込むクラスを作ります。

`class StringReader` と打つと、イメージしていたクラスがそのまま出て来ました。

```js
class StringReader {
    constructor(str) {
        this.str = str;
        this.pos = 0;
    }

    read() {
        return this.str[this.pos++];
    }

    peek() {
        return this.str[this.pos];
    }
```

メソッドの前にコメントを書き始めると、説明を生成してくれます。

```js
    // Description: Reads the next character from the string
    read() {
        return this.str[this.pos++];
    }
```

※ `//` まで打って残りを補完しました。

クラスの前に日本語でコメントを書き始めると、日本語で補完してくれます。

```js
// 文字列を一文字ずつ読み込むためのクラス
class StringReader {
```

※ `// 文字列を一文字` まで打って続きを補完しました。

再度関数の前でコメントを打ち始めると、生成されるコメントも日本語になります。

```js
    // 一文字読み込む
    read() {
        return this.str[this.pos++];
    }
```

長さチェックが足りないため、コメントを入力してコードを生成します。

```js
    // 一文字読み込む
    read() {
        // 長さをチェック
        if (this.pos >= this.str.length) {
            return null;
        }
        // 一文字読み込んで返す
        return this.str[this.pos++];
    }
```

※ `// 長さをチェック` と入力して改行すると、続きの行が補完され始めます。

このようにまず叩き台を作ってから、細かい部分を作り込んでいく感じです。

## テスト

`function test_StringReader` と打ち込むと、実装に基づいてテストが生成されます。

```js
function test_StringReader() {
    const reader = new StringReader("abc");
    console.assert(reader.read() === "a");
    console.assert(reader.peek() === "b");
    console.assert(reader.peek() === "b");
    console.assert(reader.read() === "b");
    console.assert(reader.read() === "c");
    console.assert(reader.read() === null);
    console.assert(reader.read() === null);
    console.assert(reader.peek() === null);
    console.assert(reader.peek() === null);
}
```

※ [Ctrl]+[Enter] で複数の候補を表示して、良さそうなものを選んだ上で編集しています。

生成された関数の挙動を後付けで確認しているため、テストファーストとは逆です。

※ テストファーストでは実装する前に挙動を決めます。スタブだけ用意すればいけるのかもしれませんが未確認です。

# トークンに分割

コメントで仕様を書いてジェネレーターを生成します。

※ 入力したのは最初のコメントだけです。

```js
// 括弧と四則演算と数字をトークンに分割するジェネレーター
function* tokenize(str) {
    // 文字列を一文字ずつ読み込むためのクラスのインスタンスを作成
    const reader = new StringReader(str);
    // 一文字ずつ読み込む
    let ch = reader.read();
    // 読み込んだ文字がnullになるまで繰り返す
    while (ch !== null) {
        // 読み込んだ文字が空白なら次の文字を読み込む
        if (ch === " ") {
            ch = reader.read();
            continue;
        }
        // 読み込んだ文字が"("なら"("を返す
        if (ch === "(") {
            yield "(";
            ch = reader.read();
            continue;
        }
        // 読み込んだ文字が")"なら")"を返す
        if (ch === ")") {
            yield ")";
            ch = reader.read();
            continue;
        }
        // 読み込んだ文字が"+"なら"+"を返す
        if (ch === "+") {
            yield "+";
            ch = reader.read();
            continue;
        }
        // 読み込んだ文字が"-"なら"-"を返す
        if (ch === "-") {
            yield "-";
            ch = reader.read();
            continue;
        }
        // 読み込んだ文字が"*"なら"*"を返す
        if (ch === "*") {
            yield "*";
            ch = reader.read();
            continue;
        }
        // 読み込んだ文字が"/"なら"/"を返す
        if (ch === "/") {
            yield "/";
            ch = reader.read();
            continue;
        }
        // 読み込んだ文字が数字なら数字を読み込む
        if (ch >= "0" && ch <= "9") {
            let num = ch;
            ch = reader.read();
            while (ch >= "0" && ch <= "9") {
                num += ch;
                ch = reader.read();
            }
            // 読み込んだ数字を返す
            yield parseInt(num, 10);
            continue;
        }
        // それ以外の文字ならエラー
        throw new Error(`invalid character: ${ch}`);
    }
}
```

## 整理

かなり冗長なので、書き換えたい部分を削除してからコメントを書き込み、意図したコードに誘導します。

```js
        // 読み込んだ文字が"()+-*/"のどれかなら、それを返す
        if ("()+-*/".indexOf(ch) !== -1) {
            yield ch;
            ch = reader.read();
            continue;
        }
```

## 数字

数字を読み取る部分は、StringReader 側にメソッドを付け足せば分かりやすくなります。

```js:StringReader への追加
    readWhile(predicate) {
        let result = "";
        while (true) {
            const ch = this.peek();
            if (ch === null || !predicate(ch)) {
                return result;
            }
            result += this.read();
        }
    }
```

※ メソッド名 `readWhile` まで打ち込んで補完しました。

数字を判定する関数を用意します。

```js
// 文字が数字かどうかを判定する関数
function isDigit(ch) {
    return ch >= "0" && ch <= "9";
}
```

`readWhile` と `isDigit` を使って数字を読み取る部分を書き直します。

```js
        // 読み込んだ文字が数字なら数字を読み込む
        if (isDigit(ch)) {
            yield reader.readWhile(isDigit);
            continue;
        }
```

先ほど準備した `readWhile` と `isDigit` を認識して使ってくれたので、すっきりしました。

しかし微妙にバグがあるので手動で修正します。

※ テストで発覚しました。

```js
        // 読み込んだ文字が数字なら数字を読み込む
        if (isDigit(ch)) {
            yield ch + reader.readWhile(isDigit);
            ch = reader.read();
            continue;
        }
```

数値に変換してから返すように仕様変更します。

```js
        // 読み込んだ文字が数字なら、続きを読んで数値に変換して返す
        if (isDigit(ch)) {
            yield parseInt(ch + reader.readWhile(isDigit), 10);
            ch = reader.read();
            continue;
        }
```

## テスト

テストを生成します。

```js
function test_tokenize() {
    const tokens = [...tokenize("1 + 2 * 3")];
    console.assert(tokens.length === 5);
    console.assert(tokens[0] === 1);
    console.assert(tokens[1] === "+");
    console.assert(tokens[2] === 2);
    console.assert(tokens[3] === "*");
    console.assert(tokens[4] === 3);
}
```

# 計算

優先順位を考慮して計算します。

※ 最初のコメントだけから実装が生成されました。

```js
// 優先順位を考慮して四則演算を行う
function evaluate(tokens) {
    // トークンを一つずつ読み込むためのジェネレーターを作成
    const generator = tokenize(tokens)[Symbol.iterator]();
    // トークンを一つ読み込む
    let token = generator.next().value;
    // トークンを読み込んで式をパースする
    const expr = parseExpr();
    // トークンをすべて読み終わったら式を評価して返す
    if (token === undefined) {
        return expr();
    }
    // トークンが余っていたらエラー
    throw new Error(`invalid token: ${token}`);

    // 式をパースする関数
    function parseExpr() {
        // 式の左辺をパース
        const left = parseTerm();
        // トークンが"+"か"-"なら、演算子と右辺をパースして関数を返す
        if (token === "+" || token === "-") {
            const op = token;
            token = generator.next().value;
            const right = parseExpr();
            return () => {
                if (op === "+") {
                    return left() + right();
                }
                return left() - right();
            };
        }
        // それ以外なら左辺を返す
        return left;
    }

    // 項をパースする関数
    function parseTerm() {
        // 項の左辺をパース
        const left = parseFactor();
        // トークンが"*"か"/"なら、演算子と右辺をパースして関数を返す
        if (token === "*" || token === "/") {
            const op = token;
            token = generator.next().value;
            const right = parseTerm();
            return () => {
                if (op === "*") {
                    return left() * right();
                }
                return left() / right();
            };
        }
        // それ以外なら左辺を返す
        return left;
    }

    // 因子をパースする関数
    function parseFactor() {
        // トークンが"("なら、"("と式と")"をパースして返す
        if (token === "(") {
            token = generator.next().value;
            const expr = parseExpr();
            if (token !== ")") {
                throw new Error(`invalid token: ${token}`);
            }
            token = generator.next().value;
            return expr;
        }
        // トークンが数字なら、その数字を返す
        if (typeof token === "number") {
            const num = token;
            token = generator.next().value;
            return () => num;
        }
        // それ以外ならエラー
        throw new Error(`invalid token: ${token}`);
    }
}
```

定石に則って expr（式）、term（項）、factor（因子）を処理する素直なコードです。

※ `token` が常にカレントを指していることを意識しないとやや読み取りにくいです。

## テスト

テストを生成します。

```js
function test_evalute() {
    console.assert(evaluate("1 + 2 * 3") === 7);
    console.assert(evaluate("(1 + 2) * 3") === 9);
    console.assert(evaluate("1 + 2 * 3 + 4 * 5") === 27);
    console.assert(evaluate("1 + 2 * (3 + 4) * 5") === 85);
}
```
```text:実行結果
Assertion failed
```

どこで失敗しているのか分からないので、`assert` に手を入れます。

```js
// 実際の値と期待する値を比較して、異なっていたらエラーを表示する
function assert(actual, expected) {
    if (actual !== expected) {
        console.log(`actual: ${actual}, expected: ${expected}`);
    }
}

function test_evalute() {
    assert(evaluate("1 + 2 * 3"), 7);
    assert(evaluate("(1 + 2) * 3"), 9);
    assert(evaluate("1 + 2 * 3 + 4 * 5"), 27);
    assert(evaluate("1 + 2 * (3 + 4) * 5"), 85);
}
```
```text:実行結果
actual: 71, expected: 85
```

なんと期待値が間違っていました。生成された `evaluate` 自体は問題ないようです。

正しくはこうです。

```js
    assert(evaluate("1 + 2 * (3 + 4) * 5"), 71);
```

# 関連記事

以前、同じテーマを扱った記事を書きました。

https://qiita.com/7shi/items/64261a67081d49f941e3

こういう説明をがっつり読まなくても、Copilot があれば何となく書けてしまうので、色々と考えさせられます。
