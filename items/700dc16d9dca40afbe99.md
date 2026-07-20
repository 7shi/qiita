---
coediting: false
comments_count: 0
created_at: '2022-10-28T23:31:52+09:00'
id: 700dc16d9dca40afbe99
likes_count: 0
private: false
reactions_count: 0
stocks_count: 0
tags:
- name: TypeScript
  versions: []
- name: Lojban
  versions: []
- name: Deno
  versions: []
title: ロジバンの語根のスコアを計算する
updated_at: '2023-08-06T22:35:15+09:00'
url: https://qiita.com/7shi/items/700dc16d9dca40afbe99
slide: false
---

[ロジバン](https://ja.wikipedia.org/wiki/%E3%83%AD%E3%82%B8%E3%83%90%E3%83%B3)という人工言語の語根はアルゴリズムによって構築されます。そのアルゴリズムを TypeScript で実装してスコアを計算します。

※ [レーベンシュタイン距離](https://ja.wikipedia.org/wiki/%E3%83%AC%E3%83%BC%E3%83%99%E3%83%B3%E3%82%B7%E3%83%A5%E3%82%BF%E3%82%A4%E3%83%B3%E8%B7%9D%E9%9B%A2)に類似した技法です。

ロジバンの知識を前提とせずに読めるように必要な範囲で説明します。

※ ロジバンそのものの入門は意図しないため、プログラミング的な観点に限定します。

この記事で作成したコードのリポジトリです。

https://github.com/7shi/lojban-tools

# ロジバン

ロジバンは工学言語に分類される人工言語です。エスペラントのような国際補助語とは異なり、国際コミュニケーションよりも言語に関する実験を主目的としています。

構文解析で曖昧性がないように設計されており、実際にパーサーが作られています。

https://lojban.github.io/ilmentufa/glosser/glosser.htm

※ 曖昧性がないというのは構文上のことで、意味にまで踏み込んだものではありません。自然言語と同様、意味の文脈依存性は依然としてあります。ロジバンからの翻訳を考えると、構文の取り違えに起因する誤訳は避けられますが、意味の取り違えまでは避けられないということになります。

今回は構文解析を目的とはしないため、パーサーには踏み込みません。

## gismu

ロジバンの語彙の基礎となる語根は gismu（ギスム）と呼ばれ、約 1,300 個が定義されています。

* https://gist.github.com/lynn/c42d17ca3408cd760bd619096762f1cf

使用者の多い 6 つの自然言語（中国語・英語・ヒンディー語・スペイン語・ロシア語・アラビア語）の語彙を混ぜ合わせて作られます。

例えば "gismu" という語根は次のように生成されます。

* https://ja.wiktionary.org/wiki/gismu

> * 中国語: **g**en,iuan - 根源 (gēnyuán)
> * 英語: be**is** - base
> * ヒンディー語: **mu**l  - मूल (mūl)
> * スペイン語: ra**is** - raíz

検討段階ではロシア語 korin (корень), pirvabitn (первобытный) とアラビア語 basit (بَسِيط basīṭ), sadij (原語不明) も用意されましたが、うまく混ぜることができなかったため結果的に含まれません。

検討段階も含めた語源は以下で調査されています。（アラビア語を除く）

https://github.com/cjolowicz/lojban-etymology

## アルゴリズム

混ぜ合わせには一定のアルゴリズムがあります。

<ruby>語根<rt>ギスム</rt></ruby>は 5 文字で、子音や母音の組み合わせが決められており、理論上の上限が存在します。

* https://seesaawiki.jp/lojban/d/gismu

> * 理論上可能なgismuの総数は96,475であり、公式には1,342のgismuが登録されている[*1](https://mw.lojban.org/papri/free_gismu_space)。
> * 公式のgismuとは別に、実用上は17850～17903個のgismuが利用可能である[*2](https://la-lojban.github.io/free-gismu-space/)。

ここから<ruby>語根<rt>ギスム</rt></ruby>を構成する手順です。

1. 作りたい<ruby>語根<rt>ギスム</rt></ruby>の意味に相当する各国語の単語を収集  
   例: 根源, base, मूल, raíz, корень/первобытный, بَسِيط/?
   発音ベースで lojban 風の綴りに変換  
   例: geniuan, beis, mul, rais, korin/pirvabitn, basit/sadij
1. 理論上可能な組み合わせと、各国語から収集した単語の類似度を計算
1. 類似度を文字数で割って、使用者数に応じた重み付けをして合計（スコア）
1. スコアが高く、他の<ruby>語根<rt>ギスム</rt></ruby>と似ていない語形を選択

詳細は以下の資料で説明されています。

https://lojban.github.io/cll/4/14/

今回は類似度と重み付けスコアの計算を実装して、既存のデータと照合することが目的です。

# データ変換

<ruby>語根<rt>ギスム</rt></ruby>を生成するために使用されたデータは以下にまとめられています。

https://mw.lojban.org/papri/Lojban_etymology

スコアや語源をまとめたデータが finprims です。

* https://www.lojban.org/publications/etymology/finprims

"gismu" の該当箇所を抜粋します。

```text
b24j          gismu     39.80     primitive/base 3/4o lower score no conflict
              geniuan beis mul rais korin basit
              geniuan beis mul rais pirvabitn basit
              geniuan beis mul rais korin sadij
              geniuan beis mul rais pirvabitn sadij
              (primitive  )
              gismu  39.80 3 2 2 2 0 0
```

主要な部分だけ説明します。

* [最初の行] `gismu`: 対象となる語根、`39.80`: スコア、`primitive/base`: 英語での語義
* [途中の行] `geniuan beis ...`: 中国語・英語・ヒンディー語・スペイン語・ロシア語・アラビア語の単語を発音ベースで lojban 風の綴りに変換したもの
  * 何行もあるのはロシア語やアラビア語の組み合わせを変えて試したため
  * `pirvabitn` の類似度は 3 で、`korin`, `basit`, `sadij` は 0
* [最後の行] `3 2 2 2 0 0`: 各国語の単語との類似度

このデータを JavaScript から使いやすくするため JSON に変換します。元となる単語の組み合わせが複数ある場合は最初のものだけを拾います。

```ts:convert.ts
const finprims = Deno.readTextFileSync("finprims");
const data = {};
let word = "", words: string[] = [], reserved = {};
for (const line of finprims.split("\r\n")) {
    const d = line.substring(14);
    const m1 = d.match(/^[a-z]+( [a-z]*){3,5}$/);
    const m2 = d.match(/([a-z?]+)  (\d\d\.\d\d) (\d( \d){5})/);
    if (line[52] == "o" && (line[51].match(/[0-9]/) || !line[53] || line[53] == ' ')) {
        const m3 = d.match(/^([a-z]+)/);
        if (word == "brodu") { data["bridi"] = reserved; reserved = {}; }
        if (word) data[word] = reserved;
        word = m3[1];
        words = [];
        reserved = {};
    } else if (m1 && (!words.length || reserved["score"])) {
        words = d.split(" ");
        while (words.length < 6) words.push("");
        reserved = {};
    } else if (m2 && words.length) {
        const sims = m2[3].split(" ").map(s => parseInt(s));
        const r = { score: m2[2], sims: sims, words: words };
        if (m2[1] == word) {
            data[word] = r;
            word = "";
        } else reserved = r;
    }
}
if (word && reserved["score"]) data[word] = reserved;
Deno.writeTextFileSync("finprims.json", JSON.stringify(data));
```

※ ローカルファイルの入出力は Deno の API を使用します。

"gismu" は次のように変換されます。

```json
"gismu": {
    "score": "39.80",
    "sims": [ 3, 2, 2, 2, 0, 0 ],
    "words": [ "geniuan", "beis", "mul", "rais", "korin", "basit" ]
},
```

※ `score` も数値に変換する方が良さそうですが、文字列として比較を行うため敢えて変換していません。

## 注意点

スコア情報がないものも含みますが、スコア確認ではスキップします。

bridi は特別扱いします。

```text
a20a          bridi     46.65     predicate      1/5o
a20a          broda               predicate var 1   o
a20a          brode               predicate var 2   o
a20a          brodi               predicate var 3   o
a20a          brodo               predicate var 4   o
a20a          brodu               predicate var 5   o
              binsi predakit videi predikad pridikat musnad
              (predicate  )
              bridi  46.65 3 3 3 3 4 0
```

## typo

ファイル中にはいくつか typo の指摘があります。一例を挙げます。

```text:typoの例
617a          bukpu     64.40     cloth             o
              typo bukpa
              bu klat kapna pan sukno kumac
              bu klat kapra pan sukno kumac
              (cloth  )
              bukpa  64.40 2 2 3 2 2 0
    2/4       actual bukpu  37.80 2 0 0 0 2 0
```

見出し形 bukpu とスコア計算時の綴り bukpa が異なります。定着したので今更変えられないようです。

指摘がないものもいくつか見受けられましたが、変換では見出し形を拾います。（括弧内はスコア計算時の綴り）

* dikni (dinki), nuzba (nuvba), jinku (jinka), navni (na?ni), cicna (cicni)

語源が失われた語が 1 つあります。類似度が計算できないため対象外とします。

```text:語源欠落
x17b          sorgu     66.20     sorghum        1/2o
              typo should have been sargu, loses all Chinese and Hindi
              sorgu  32.80 0 4 0 4 4 0
```

※ [語源調査](https://github.com/cjolowicz/lojban-etymology)や [Wiktionary](https://en.wiktionary.org/wiki/Appendix:Lojban/sorgu) で復元が試みられています。

作業時の混乱が資料に残っているのは、歴史的背景が垣間見えて興味深いです。

# 類似度

単語の類似度の計算を実装します。説明から当該箇所を抜粋して DeepL で翻訳します。

* https://lojban.github.io/cll/4/14/

> 2a) 提案されたギスムと原語の単語で3文字以上が同じで、かつ同じ順序で現れた場合、スコアは同じだった文字数と同じになる。間に文字がある場合でも関係ない。
> 2b) 提案されたギスムと原語の単語でちょうど2文字が同じで、その2文字が両方の単語で連続しているか、両方の単語で1文字ずつ離れている場合、スコアは2となる。
> 2c) それ以外の場合のスコアは0である。

※ レーベンシュタイン距離と似ていますが、順番の入れ替えを認めないなど細部は異なります。

2a で計算されるスコアは 3 ～ 5（<ruby>語根<rt>ギスム</rt></ruby>が 5 文字のため上限 5）のため、スコアは 0, 2～5 となります。

※ スコア 1 は意味がないため除外されます。

* https://www.lojban.org/publications/etymology/etysample.txt

> a score of 1 was considered useless for recognition

2a と 2b は間の文字に関する条件が異なるため別々に実装します。

## 2a

> 2a) 提案されたギスムと原語の単語で3文字以上が同じで、かつ同じ順序で現れた場合、スコアは同じだった文字数と同じになる。間に文字がある場合でも関係ない。

いくつか注意するケースがあります。

* 先頭から一致させた場合、後ろの方がスコアが高くなるケース
  例: **abcd**e, <font color="red">abc</font>x**abcd** → 4 （最初の <font color="red">abc</font> だけを見て 3 と判断してはいけない）
* 一致の途中で後ろの方がスコアが高くなるケース  
  例: **abcde**, <font color="red">**a**ce</font>**bcde** → 5 （最初の <font color="red">ace</font> だけを見て 3 と判断してはいけない）

これらに対応するには、一致を見付けてもそこをスキップしたときのスコアと比較する必要があります。2 個所から再帰を行うことで実装しました。

```ts
function similarity2a(g: string, w: string): number {
    if (!g || !w) return 0;
    const sc1 = similarity2a(g, w.substring(1));
    const p = g.indexOf(w[0]);
    if (p < 0) return sc1;
    const sc2 = similarity2a(g.substring(p + 1), w.substring(1)) + 1;
    return Math.max(sc1, sc2);
}
```
```ts:実行結果
> similarity2a("abcde", "abcxabcd")
4
> similarity2a("abcde", "acebcde")
5
```

※ この実装ではスコア 1 や 2 も返しますが、後で補正します。

### 補足

2 個所から再帰を行うのはフィボナッチ数列の実装に似ています。`similarity2a` の構造が分かりにくければ、まずフィボナッチを考えてみると良いかもしれません。

```ts:フィボナッチ数列
function fibo(x: number): number {
    if (x <= 0) return 0;
    if (x == 1) return 1;
    return fibo(x - 1) + fibo(x - 2);
}
```
```ts:実行結果
> fibo(5)
5
> fibo(10)
55
```

### 最適化

ナイーブに実装したため、部分文字列を何度も取得したり、再帰の過程で同じ引数で何度も呼んだりと非効率な点があります。

文字列ではなくインデックスを渡す内部関数を用意してメモ化を行うことで最適化します。

```ts
function similarity2a(g: string, w: string): number {
    if (!g || !w) return 0;
    const memo = Array(g.length).fill([]).map(() => Array(w.length));
    function f(gp: number, wp: number) {
        if (gp == g.length || wp == w.length) return 0;
        let m = memo[gp][wp];
        if (m >= 0) return m;
        const sc = f(gp, wp + 1);
        const p = g.indexOf(w[wp], gp);
        return memo[gp][wp] = p < 0 ? sc : Math.max(sc, f(p + 1, wp + 1) + 1);
    }
    return f(0, 0);
}
```

## 2b

> 2b) 提案されたギスムと原語の単語でちょうど2文字が同じで、その2文字が両方の単語で連続しているか、両方の単語で1文字ずつ離れている場合、スコアは2となる。

0 か 2 しか返さないため、2a のように先を見てから比較する必要はなく、条件に合えばすぐに 2 を返せます。

やはり注意するケースがあります。

* 同じ文字を何度も含む場合、後で一致するケース  
  例: <font color="red">a</font>b**a**b**c**, **a**d**c** （最初の <font color="red">a</font> だけを見て不一致と判断してはいけない）

二重ループで実装しました。

```ts
function similarity2b(g: string, w: string): number {
    if (!g || !w) return 0;
    for (let i = 0; i < w.length - 1; i++) {
        for (let j = 0; j < g.length - 1; j++) {
            if (g[j] == w[i] &&
                (g[j + 1] == w[i + 1] || (g[j + 2] ?? "") == w[i + 2]))
                return 2;
        }
    }
    return 0;
}
```
```ts:実行結果
> similarity2b("ababc", "adc")
2
```

## 2c

> 2c) それ以外の場合のスコアは0である。

2a が 3 未満なら 2b の結果を返すことで、どちらの条件にも一致しなければ 0 になります。

```ts
function similarity(g: string, w: string) {
    let s = similarity2a(g, w);
    return s < 3 ? similarity2b(g, w) : s;
}
```

## テスト

変換した finprims.json と結果を比較します。

```ts
interface FinPrim { score: string, sims: number[], words: string[] }
const finprims: { [index: string]: FinPrim } =
    JSON.parse(Deno.readTextFileSync("finprims.json"));

function testSimilarity() {
    let all = 0, ng = 0;
    for (const [g, data] of Object.entries(finprims)) {
        if (!data.words) continue;
        const sims = data.words.map(w => similarity(g, w));
        if (sims.join(" ") != data.sims.join(" ")) {
            console.log(g, "[NG]", sims, "expected:", data.sims);
            ng++;
        }
        all++;
    }
    console.log("[testSimilarity] NG:", ng, "/", all);
}
testSimilarity();
```
```ts:実行結果
nuzba [NG] [ 2, 3, 2, 0, 0, 3 ] expected: [ 2, 2, 2, 3, 3, 3 ]
jinku [NG] [ 3, 4, 0, 4, 2, 0 ] expected: [ 3, 3, 3, 4, 3, 2 ]
[testSimilarity] NG: 2 / 1249
```

NG は typo として挙げた語です。それぞれ nuvba, jinka として再計算すると expected に一致します。

※ typo はこれ以外にもありますが、たまたま一致したので表面化しなかったようです。

# スコア

スコアの計算を実装します。説明から当該箇所を抜粋して DeepL で翻訳します。

* https://lojban.github.io/cll/4/14/

> 3<b></b>) その得点をロジバン化された原語の長さで割り、さらにその言語の第一言語話者と第二言語話者の比率を反映した各言語固有の加重値を乗じる（第二言語話者は半分で計算）。加重値は合計が1.00になるように選択された。重み付けの合計が、提案されたギスム形式の総得点となる。

※ 「その得点」は類似度のことです。

加重値が 2 種類紹介されています。

> ギスムのほとんどに使われた言語ウエイトは次の通り：
> 
>     Chinese     0.36
>     English     0.21
>     Hindi       0.16
>     Spanish     0.11
>     Russian     0.09
>     Arabic      0.07
> 
> 1985年の話者数データを反映したもの。一部のギスムは、かなり後に更新されたウェイトを使用して作成されている：
> 
>     Chinese     0.347
>     Hindi       0.196
>     English     0.160
>     Spanish     0.123
>     Russian     0.089
>     Arabic      0.085
> 
> （人口動態の変化により、英語とヒンディー語が入れ替わった。）

前者が 1985 年、後者が 1995 年のデータです。1994, 1995, 1999 年の詳細が以下にあります。

* https://www.lojban.org/publications/etymology/langstat.94
* https://www.lojban.org/publications/etymology/langstat.95
* https://www.lojban.org/publications/etymology/langstat.99

これらの数値をコード化しました。

```ts
const weights = {
    //      [ zh  ,  en  ,  hi  ,  es  ,  ru  ,  ar  ]
    "1985": [0.360, 0.210, 0.160, 0.110, 0.090, 0.070], // sum: 1
    "1994": [0.348, 0.163, 0.194, 0.123, 0.088, 0.084], // sum: 1
    "1995": [0.347, 0.160, 0.196, 0.123, 0.089, 0.085], // sum: 1
    "1999": [0.334, 0.187, 0.195, 0.116, 0.081, 0.088], // sum: 1.001
};
```

※ 1999 年は加重値の合計が 1.0 を少しオーバーしていますが、丸め誤差の範囲でしょう。

例として "gismu" でスコアを計算してみます。

```ts
function score(words: string[], sims: number[], weights: number[]) {
    return words
        .map((w, i) => w ? sims[i] / w.length * weights[i] : 0)
        .reduce((x, y) => x + y);
}

function gismuScore(g: string, weights: number[]) {
    const data = finprims[g];
    return score(data.words, data.sims, weights);
}

function testWeightsScore(g: string) {
    console.log(g, "expected:", finprims[g].score);
    for (const [key, ws] of Object.entries(weights)) {
        console.log(key, (gismuScore(g, ws) * 100).toFixed(2));
    }
}
testWeightsScore("gismu");
```
```ts:実行結果
gismu expected: 39.80
1985 42.10
1994 42.15
1995 42.09
1999 42.46
```

どの年度とも一致しません。誤差の範囲を超えています。他の<ruby>語根<rt>ギスム</rt></ruby>でも同様です。

## 連立方程式

finprims と同じスコアが得られる加重値を探します。

加重値は 6 つあるので、未知数が 6 つの方程式となります。

```math
3w_{zh}+2w_{en}+2w_{hi}+2w_{es}+0w_{ru}+0w_{ar}=39.8
```

6 個の<ruby>語根<rt>ギスム</rt></ruby>で連立方程式を組めば加重値が求まります。

ここまで TypeScript を使っていたので計算も TypeScript で行いたいです。JavaScript のライブラリを探して Math.js を見付けました。

https://qiita.com/7shi/items/e75fa610f24a3350b260

finprims.json から 6 個ずつ連立方程式を立てて解を求めます。誤差により完全には一致しないため、解の平均値を求めます。

```ts:calc.ts
import * as math from "https://esm.sh/mathjs@11.3.2/";

interface FinPrim { score: string, sims: number[], words: string[] }
const finprims: { [index: string]: FinPrim } =
    JSON.parse(Deno.readTextFileSync("finprims.json"));

    let lvalues: number[][] = [], rvalues: number[] = [], sols: DenseMatrix[] = [];
for (const data of Object.values(finprims)) {
    lvalues.push(data.sims.map((s, i) => s ? s / data.words[i].length : 0));
    rvalues.push(parseFloat(data.score) / 100);
    if (lvalues.length == 6) {
        if (Math.abs(math.det(lvalues)) > 1e-5) {
            sols.push(math.matrix(math.multiply(math.inv(lvalues), rvalues)));
        }
        lvalues = [];
        rvalues = [];
    }
}
const pow = 1000;
const fix = x => Math.round(x * pow) / pow;
const avg = math.divide(math.sum(sols), sols.length).valueOf().map(fix);
console.log(avg, ", // sum:", fix(math.sum(avg)));
```
```ts:実行結果
[ 0.33, 0.18, 0.16, 0.12, 0.12, 0.07 ] , // sum: 0.98
```

※ 行列式が 0 のときに逆行列が存在しない、つまり連立方程式の解がありません。誤差のためぴったり 0 になるとは限らないので、絶対値が `1e-5` $(10^{-5})$ 以下の場合は 0 と見なして解なしとします。

この加重値はどの年度とも異なります。スペイン語とロシア語が同じですが、そのような年度は見当たりません。

この加重値を使って "gismu" のスコアを求めたところ 39.81 となり、39.80 とほぼ一致しました。

```ts
const weights2 = [0.330, 0.180, 0.160, 0.120, 0.120, 0.070]; // sum: 0.98
console.log("gismu", (gismuScore("gismu", weights2) * 100).toFixed(2));
```
```ts:実行結果
gismu 39.81
```

## 整数計算

値を下方修正するため、`toFixed` の前に切り捨てを行うと 39.80 が得られました。

```ts
console.log("gismu", (Math.floor(gismuScore("gismu", weights2) * 10000) / 100).toFixed(2));
```
```ts:実行結果
gismu 39.80
```

切り捨ての際に 1 万倍していますが、スコア計算を 1 万倍のオーダーで行えば整数として計算できます。

```ts
function scoreInt(words: string[], sims: number[], weights: number[]) {
    const ws = weights.map(w => Math.floor(w * 10000));
    return words
        .map((w, i) => w ? Math.floor(sims[i] * ws[i] / w.length) : 0)
        .reduce((x, y) => x + y);
}
```

※ asm.js を使うわけではないので、計算結果を切り捨てることで整数計算を模倣しています。計算過程で値が小さくならないように割り算の前に掛け算を行っています。

"gismu" のスコアを再計算して確認します。

```ts
function gismuScoreInt(g: string, weights: number[]) {
    const data = finprims[g];
    return scoreInt(data.words, data.sims, weights);
}

console.log("gismu", (gismuScoreInt("gismu", weights2) / 100).toFixed(2));
```
```ts:実行結果
gismu 39.80
```

## テスト

全<ruby>語根<rt>ギスム</rt></ruby>のスコアを計算して確認します。

```ts
function testScore(weights: number[]) {
    let all = 0, ng = 0;
    for (const [g, data] of Object.entries(finprims)) {
        if (!data.score) continue;
        const sc = (gismuScoreInt(g, weights) / 100).toFixed(2);
        if (sc != data.score) {
            console.log(g, "[NG]", sc, "expected:", data.score, data.sims);
            ng++;
        }
        all++;
    }
    console.log("NG:", ng, "/", all);
}
testScore(weights2);
```
```ts:実行結果
NG: 0 / 1249
```

無事に全部一致しました！

# まとめ

以下の加重値を使って 1 万倍のオーダーで整数としてスコアを計算すれば finprims と一致します。

```ts
Chinese     0.330
English     0.180
Hindi       0.160
Spanish     0.120
Russian     0.120
Arabic      0.070
-----------------
Total       0.980
```

※ この加重値の由来は不明です。

# 関連記事

レーベンシュタイン距離を説明します。

https://qiita.com/7shi/items/b0b95610b59050e42666
