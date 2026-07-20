---
coediting: false
comments_count: 0
created_at: '2022-12-05T04:01:10+09:00'
id: e275c4443a9338c8fda5
likes_count: 3
private: false
reactions_count: 0
stocks_count: 1
tags:
- name: JavaScript
  versions: []
- name: 四元数
  versions: []
- name: ベクトル
  versions: []
- name: ChatGPT
  versions: []
title: ChatGPTは四元数を知っている
updated_at: '2023-03-11T13:57:57+09:00'
url: https://qiita.com/7shi/items/e275c4443a9338c8fda5
slide: false
---

四元数の積の計算には内積と外積が含まれます。対話的に [ChatGPT](https://chat.openai.com/) を誘導しながら実装を進めてみました。

人間に指示しながらコードを書いてもらう感覚に近く、非常に面白い経験でした。コンテキストが連続するため、Jupyter を自然言語でやっているような感覚です。

コーディングスタイルを指示によって変えることも可能で、学習にも応用できそうです。

# 注意事項

生ログそのままではなく、試行錯誤した部分を削除して読みやすくしています。

* コード部分はインデント以外編集していません。
* 「補足」は編者による追記です。
  * たまに回答の中でこのスタイルが使われることがありました。

同じ質問をしても同じ回答が返って来ません。

* たまたま想定した通りのコードが生成されたようです。
* 質問を絞ってログの収録をやり直そうとしたところ、想定したようなコードが生成されなくなりました。
  * 特に a,b を実部と虚部に分ける部分が再現できなくなりました。
* コンテキストを認識するため、削除した試行錯誤にも有用な効果があったかもしれません。
  * 以前の質問を編集してやり直す機能がありますが、履歴を遡るわけではないようで、直前の質問との連続性が切れているような印象を受けました。
* 生ログで投げた質問を箇条書きにして記事の末尾に掲載します。
  * この通りに投げかけても回答を再現できません。

# ベクトル

## JavaScriptで内積を実装してください。

JavaScriptで内積を実装するには、次のようなコードを書くことができます。

```js
function dotProduct(a, b) {
  // 2つの配列が同じ長さであることを確認する
  if (a.length !== b.length) {
    throw new Error('配列の長さが異なります');
  }

  let result = 0;
  for (let i = 0; i < a.length; i++) {
    result += a[i] * b[i];
  }
  return result;
}
```

上記のコードでは、2つの配列 `a` と `b` の内積を計算します。配列が同じ長さであることを確認し、各要素の積を計算しています。

### 補足

「reduceを使って書き換えてください。」と指示すれば、計算部分をループから書き換えてくれます。

```js
  return a.reduce((result, element, i) => result + (element * b[i]), 0);
```

## 外積を実装してください。

JavaScriptで外積を実装するには、次のようなコードを書くことができます。

```js
function crossProduct(a, b) {
  // 2つの配列が3要素かどうかを確認する
  if (a.length !== 3 || b.length !== 3) {
    throw new Error('配列は3要素必要です');
  }

  return [
    a[1] * b[2] - a[2] * b[1],
    a[2] * b[0] - a[0] * b[2],
    a[0] * b[1] - a[1] * b[0]
  ];
}
```

上記のコードでは、2つの配列 `a` と `b` の外積を計算します。配列が3要素かどうかを確認し、外積の計算式に基づいて計算します。

## 任意個のベクトルの和を実装してください。

JavaScriptで任意個の引数を受け取ることができるベクトルの和を求める関数を実装するには、次のようなコードを書くことができます。

```js
function vectorAddition(...vectors) {
  // 配列の数が1以上かどうかを確認する
  if (vectors.length === 0) {
    throw new Error('少なくとも1つの配列が必要です');
  }

  // 配列の長さが等しいかどうかを確認する
  let len = vectors[0].length;
  if (!vectors.every(v => v.length === len)) {
    throw new Error('配列の長さが等しくありません');
  }

  // 和を求める
  let result = new Array(len).fill(0);
  for (let i = 0; i < len; i++) {
    for (let j = 0; j < vectors.length; j++) {
      result[i] += vectors[j][i];
    }
  }

  return result;
}
```

上記のコードでは、任意個の引数を受け取ることができるベクトルの和を求める関数を実装しています。まず、引数を配列として受け取り、配列の数が1以上かどうかを確認します。次に、配列の長さが等しいかどうかを確認します。最後に、配列の数だけ繰り返し処理を行い、各要素を足し合わせることでベクトルの和を求めます。

### 補足

「mapとreduceを使って書き換えてください。」と指示すれば、計算部分をループから書き換えてくれます。

```js
  return Array(len)
    .fill(0)
    .map((_, i) => vectors.reduce((sum, vector) => sum + vector[i], 0));
```

## ベクトルの定数倍を実装してください。

JavaScriptでベクトルの定数倍を実装するには、次のようなコードを書くことができます。


```js
function scalarMultiply(a, s) {
  let result = [];
  for (let i = 0; i < a.length; i++) {
    result.push(a[i] * s);
  }
  return result;
}
```

上記のコードでは、配列 `a` を定数 `s` 倍します。配列の各要素を定数倍して新しい配列を作成します。

### 補足

「mapを使って書き換えてください。」と指示すれば、計算部分をループから書き換えてくれます。

```js
  return a.map(element => element * s);
```

# 四元数

## 四元数の積を実装してください。

JavaScriptで四元数の積を実装するには、次のようなコードを書くことができます。

```js
function quaternionProduct(a, b) {
  // 2つの配列が4要素かどうかを確認する
  if (a.length !== 4 || b.length !== 4) {
    throw new Error('配列は4要素必要です');
  }

  return [
    a[0] * b[0] - a[1] * b[1] - a[2] * b[2] - a[3] * b[3],
    a[0] * b[1] + a[1] * b[0] + a[2] * b[3] - a[3] * b[2],
    a[0] * b[2] - a[1] * b[3] + a[2] * b[0] + a[3] * b[1],
    a[0] * b[3] + a[1] * b[2] - a[2] * b[1] + a[3] * b[0]
  ];
}
```

上記のコードでは、2つの四元数を表す配列 `a` と `b` の積を計算します。配列が4要素かどうかを確認し、四元数の積の計算式に基づいて計算します。

## a,bを実部と虚部に分けてから計算してください。

JavaScriptで四元数の積を実装する際に、実部と虚部を分けて計算することができます。次のようなコードを書くことができます。

```js
function quaternionProduct(a, b) {
  // 2つの配列が4要素かどうかを確認する
  if (a.length !== 4 || b.length !== 4) {
    throw new Error('配列は4要素必要です');
  }

  let aReal = a[0];
  let aImag = [a[1], a[2], a[3]];
  let bReal = b[0];
  let bImag = [b[1], b[2], b[3]];

  let real = aReal * bReal - dotProduct(aImag, bImag);
  let imag = [
    aReal * bImag[0] + bReal * aImag[0] + crossProduct(aImag, bImag)[0],
    aReal * bImag[1] + bReal * aImag[1] + crossProduct(aImag, bImag)[1],
    aReal * bImag[2] + bReal * aImag[2] + crossProduct(aImag, bImag)[2]
  ];

  return [real].concat(imag);
}
```

上記のコードでは、四元数の積の計算において実部と虚部を分けて計算しています。まず、配列 `a` と `b` から実部と虚部を取り出します。次に、実部を計算するために `dotProduct` 関数を使用します。最後に、虚部を計算するために `crossProduct` 関数を使用します。

### 補足

`a`, `b` がきれいに分離されていますが、再度試した所うまく再現できなくなりました。

何度か試すと、実部と虚部を結合して返す部分でスプレッド構文を使用することがありました。

```js
  return [real, ...imag];
```

## crossProduct(aImag, bImag) をいったん変数に束縛してください。

JavaScriptで四元数の積を実装する際に、`crossProduct` 関数の計算結果を一時的に変数に束縛することができます。次のようなコードを書くことができます。

```js
function quaternionProduct(a, b) {
  // 2つの配列が4要素かどうかを確認する
  if (a.length !== 4 || b.length !== 4) {
    throw new Error('配列は4要素必要です');
  }

  let aReal = a[0];
  let aImag = [a[1], a[2], a[3]];
  let bReal = b[0];
  let bImag = [b[1], b[2], b[3]];

  let real = aReal * bReal - dotProduct(aImag, bImag);
  let imagCrossProduct = crossProduct(aImag, bImag);
  let imag = [
    aReal * bImag[0] + bReal * aImag[0] + imagCrossProduct[0],
    aReal * bImag[1] + bReal * aImag[1] + imagCrossProduct[1],
    aReal * bImag[2] + bReal * aImag[2] + imagCrossProduct[2]
  ];

  return [real].concat(imag);
}
```

上記のコードでは、四元数の積の計算において `crossProduct` 関数の計算結果を一時的に変数に束縛しています。まず、`crossProduct` 関数を実行して虚部の積を求めます。次に、変数 `imagCrossProduct` に結果を格納します。最後に、`imagCrossProduct` を用いて四元数の積の虚部を計算します。

## scalarMultiplyの計算結果を変数に束縛して、imagの計算に使ってください。

JavaScriptで四元数の積を実装する際に、`scalarMultiply` 関数の計算結果を一時的に変数に束縛することができます。次のようなコーチを書くことができます。

```js
function quaternionProduct(a, b) {
  // 2つの配列が4要素かどうかを確認する
  if (a.length !== 4 || b.length !== 4) {
    throw new Error('配列は4要素必要です');
  }

  let aReal = a[0];
  let aImag = [a[1], a[2], a[3]];
  let bReal = b[0];
  let bImag = [b[1], b[2], b[3]];

  let real = aReal * bReal - dotProduct(aImag, bImag);
  let imagCrossProduct = crossProduct(aImag, bImag);
  let aImagScaled = scalarMultiply(bReal, aImag);
  let bImagScaled = scalarMultiply(aReal, bImag);
  let imag = vectorAddition(aImagScaled, bImagScaled, imagCrossProduct);

  return [real].concat(imag);
}
```

上記のコードでは、四元数の積を求める関数 `quaternionProduct` を実装しています。`quaternionProduct` 関数では、与えられた 2 つの配列から実部と虚部を取り出します。その後、実部を計算するために `dotProduct` 関数を使用します。次に、虚部を計算するために `crossProduct` 関数を使用します。最後に、実部と虚部を結合して四元数の積を返します。

### 補足

ベクトル計算の関数が使える個所を見抜いているのに感心しました。四元数の積に内積と外積が含まれる構造が浮き彫りになっています。考え方は以下の通りです。

```math
\begin{aligned}
\underbrace{\Im a\Im b}_{\text{虚部の積}}
&=-\underbrace{\Im a\cdot\Im b}_{\text{内積}}+\underbrace{\Im a\times\Im b}_{\text{外積}} \\
ab
&=(\underbrace{\Re a}_{\text{実部}}+\underbrace{\Im a}_{虚部})(\underbrace{\Re b}_{\text{実部}}+\underbrace{\Im b}_{虚部}) \\
&=\Re a\Re b+\Re a\Im b+\Re b\Im a+\Im a\Im b \\
&=\Re a\Re b+\Re a\Im b+\Re b\Im a-\Im a\cdot\Im b+\Im a\times\Im b \\
&=\underbrace{\underbrace{\Re a\Re b}_{\text{aReal * bReal}}-\underbrace{\Im a\cdot\Im b}_{\text{dotProduct(...)}}}_{\text{real}}+\underbrace{\underbrace{\Im a\times\Im b}_{\text{imagCrossProduct}}+\underbrace{\Re b\Im a}_{\text{aImagScaled}}+\underbrace{\Re a\Im b}_{\text{bImagScaled}}}_{\text{imag}}
\end{aligned}
```

# 質問事項

生ログで投げた質問を箇条書きにします。

* JavaScriptで内積を実装してください。
* JavaScriptで外積を実装してください。
* JavaScriptでベクトルの和を実装してください。
* JavaScriptでベクトルの定数倍を実装してください。
* JavaScriptで四元数の積を実装してください。
* quaternionProductでdotProductを使用してください。
* dotProduct(a, b) は a[0] * b[0] - a[1] * b[1] - a[2] * b[2] - a[3] * b[3] ではありません。
* quaternionProductで実部と虚部を分けて計算してください。
* 四元数の共役を求める関数を実装してください。
* quaternionConjugateとdotProductを使ってquaternionProductのrealを求めてください。
* imagの計算にcrossProductを使ってください。
* quaternionProductで、まずa,bを実部と虚部に分けてから計算してください。
* crossProduct(aImag, bImag)をいったん変数に束縛してください。
* scalarMultiplyの計算結果を変数に束縛して、imagの計算に使ってください。
* vectorAdditionを任意個の引数が受け取れるように拡張してください。
* 任意版のvectorAdditionを使ってquaternionProductを書き直してください。
* 続けてください
* 上記のコードでは？

最後の2つは説明が途中で切れたことへの対応です。（セッション制限？）

# 関連記事

https://7shi.hateblo.jp/entry/2023/03/05/054757
