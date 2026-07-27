---
coediting: false
comments_count: 0
created_at: '2016-05-16T14:36:32+09:00'
id: 64261a67081d49f941e3
likes_count: 110
private: false
reactions_count: 0
stocks_count: 95
tags:
- name: Java
  versions: []
title: Java 再帰下降構文解析 超入門
updated_at: '2017-01-31T13:56:29+09:00'
url: https://qiita.com/7shi/items/64261a67081d49f941e3
slide: false
---

構文を解析するプログラムをパーサと呼びます。実装方法にはいくつか種類がありますが、今回は再帰下降という方式を取り上げます。既存の実装を使うのではなく、1から実装しながら説明します。

この記事ではJavaの新しい言語機能は使わずに、なるべく基本的な文法だけで記述します。

この記事には関連記事があります。再帰下降を理解してから、応用編として読むのが良いでしょう。

* [Java パーサコンビネータ 超入門](http://qiita.com/7shi/items/68228e19552c271bea81) 2016.05.12
* [Java パーサコンビネータ 超入門 2](http://qiita.com/7shi/items/39a9ddffcc5bdf2c0142) 2016.05.14
* [JSONパーサーを作る](http://qiita.com/7shi/items/04c2991239894687ef2f) 2016.12.26

# 四則演算器

構文解析の練習として、簡単な四則演算器を作ります。文字列で式を与えると計算して答えを返します。

例: `"1+2*3"` → `7`

まずは次の計算ができることを目指します。

* `"12+34+56"` → `102`

## 数字

パーサの基本的な考え方として、1文字ずつ順番に見て処理します。

数字を読み込むパーサを実装します。`0`から`9`が連続する限り1文字ずつ読み取ります。

```java
public class Main {

    static final String number(String s) {
        for (int i = 0; i < s.length(); ++i) {
            if (!Character.isDigit(s.charAt(i))) {
                return s.substring(0, i);
            }
        }
        return s;
    }

    public static void main(String[] args) {
        System.out.println(number("12+34+56"));
    }
}
```
```text:実行結果
12
```

メソッドをパーサに見立てます。`number`は数字を読み取るパーサです。

## 位置の管理

`+`演算子で区切られた先を読めるようにするには、どこまで読んだかを管理する必要があります。

文字列と現在位置をセットで管理するクラスを作ります。簡単のためフィールドを`public`にして直接アクセスします。

```java
class Source {

    public String str;
    public int pos;

    public Source(String str) {
        this.str = str;
    }
}

public class Main {

    static final String number(Source s) {
        int start = s.pos;
        for (; s.pos < s.str.length(); ++s.pos) {
            if (!Character.isDigit(s.str.charAt(s.pos))) {
                return s.str.substring(start, s.pos);
            }
        }
        return s.str;
    }

    public static void main(String[] args) {
        System.out.println(number(new Source("12+34+56")));
    }
}
```
```text:実行結果
12
```

### リファクタリング

`number`がごちゃごちゃしているので、`Source`をリファクタリングしてカプセル化します。

```java
class Source {

    private final String str;
    private int pos;

    public Source(String str) {
        this.str = str;
    }

    public final int peek() {
        if (pos < str.length()) {
            return str.charAt(pos);
        }
        return -1;
    }

    public final void next() {
        ++pos;
    }
}

public class Main {

    static final String number(Source s) {
        StringBuilder sb = new StringBuilder();
        int ch;
        while ((ch = s.peek()) >= 0 && Character.isDigit(ch)) {
            sb.append((char) ch);
            s.next();
        }
        return sb.toString();
    }

    public static void main(String[] args) {
        System.out.println(number(new Source("12+34+56")));
    }
}
```
```text:実行結果
12
```

### パーサのクラス化

パーサもクラスとして切り出します。

※ `Source`クラスは変化ないため省略します。

```java
class Parser extends Source {

    public Parser(String str) {
        super(str);
    }

    public final String number() {
        StringBuilder sb = new StringBuilder();
        int ch;
        while ((ch = peek()) >= 0 && Character.isDigit(ch)) {
            sb.append((char) ch);
            next();
        }
        return sb.toString();
    }
}

public class Main {

    public static void main(String[] args) {
        System.out.println(new Parser("12+34+56").number());
    }
}
```
```text:実行結果
12
```

## 数値

結果を数値で返すように`Parser#number`を修正します。

```java:Parser（修正）
    public final int number() {
        StringBuilder sb = new StringBuilder();
        int ch;
        while ((ch = peek()) >= 0 && Character.isDigit(ch)) {
            sb.append((char) ch);
            next();
        }
        return Integer.parseInt(sb.toString());
    }
```
```text:実行結果
12
```

このようにパーサは文字以外を返すように構成できます。

## 足し算

足し算を計算するパーサ`expr`を実装します。`+`演算子があれば読み進めて計算します。テスト用のメソッドも追加します。

※ `Parser`と`Main`クラスを示します。

```java
class Parser extends Source {

    public Parser(String str) {
        super(str);
    }

    public final int number() {
        StringBuilder sb = new StringBuilder();
        int ch;
        while ((ch = peek()) >= 0 && Character.isDigit(ch)) {
            sb.append((char) ch);
            next();
        }
        return Integer.parseInt(sb.toString());
    }

    public final int expr() {
        int x = number();
        if (peek() == '+') {
            next();
            x += number();
        }
        return x;
    }
}

public class Main {

    static void test(String s) {
        System.out.println(s + " = " + new Parser(s).expr());
    }

    public static void main(String[] args) {
        test("12+34+56");
    }
}
```
```text:実行結果
12+34+56 = 46
```

まだ `12+34` の部分しか計算できていません。

### 繰り返し

演算子を繰り返し確認することで複数の項が計算できます。

```java:Parser（修正）
    public final int expr() {
        int x = number();
        while (peek() == '+') {
            next();
            x += number();
        }
        return x;
    }
```
```text:実行結果
12+34+56 = 102
```

構文解析と計算を分離せずに`expr`で処理しているのがポイントです。

## 引き算

引き算を実装します。

```java:Parser（修正）
    public final int expr() {
        int x = number();
        for (;;) {
            switch (peek()) {
                case '+':
                    next();
                    x += number();
                    continue;
                case '-':
                    next();
                    x -= number();
                    continue;
            }
            break;
        }
        return x;
    }
```

動作を確認します。

```java:Main（修正）
    public static void main(String[] args) {
        test("12+34+56");
        test("1-2-3");
        test("1-2+3");
    }
```
```text:実行結果
12+34+56 = 102
1-2-3 = -4
1-2+3 = 2
```

問題なく計算できています。

## 四則演算

同様に掛け算と割り算を実装します。

```java:Parser（修正）
    public final int expr() {
        int x = number();
        for (;;) {
            switch (peek()) {
                case '+':
                    next();
                    x += number();
                    continue;
                case '-':
                    next();
                    x -= number();
                    continue;
                case '*':
                    next();
                    x *= number();
                    continue;
                case '/':
                    next();
                    x /= number();
                    continue;
            }
            break;
        }
        return x;
    }
```

動作を確認します。

```java:Main（修正）
    public static void main(String[] args) {
        test("2*3+4");     // OK
        test("2+3*4");     // NG
        test("100/10/2");  // OK
    }
```
```text:実行結果
2*3+4 = 10
2+3*4 = 20
100/10/2 = 5
```

演算子の優先順位が処理できていません。

### 演算子の優先順位

足し算から見ると、1つの数字と掛け算のブロックは項（term）として対等です。数式で例えると $2x+1$ において $2x$ と $1$ が項という単位として $+$ から並列に扱われていることに相当します。

項単位で計算するように分離すれば演算子の優先順位が表現できます。

※ `Parser`クラスを示します。

```java:修正
class Parser extends Source {

    public Parser(String str) {
        super(str);
    }

    public final int number() {
        StringBuilder sb = new StringBuilder();
        int ch;
        while ((ch = peek()) >= 0 && Character.isDigit(ch)) {
            sb.append((char) ch);
            next();
        }
        return Integer.parseInt(sb.toString());
    }

    public final int expr() {
        int x = term();           // 項を取得
        for (;;) {
            switch (peek()) {
                case '+':
                    next();
                    x += term();  // 項を取得
                    continue;
                case '-':
                    next();
                    x -= term();  // 項を取得
                    continue;
            }
            break;
        }
        return x;
    }

    public final int term() {    // 項の計算、exprと同じ構造
        int x = number();
        for (;;) {
            switch (peek()) {
                case '*':
                    next();
                    x *= number();
                    continue;
                case '/':
                    next();
                    x /= number();
                    continue;
            }
            break;
        }
        return x;
    }
}
```
```text:実行結果
2*3+4 = 10
2+3*4 = 14
100/10/2 = 5
```

演算子の優先順位が処理されるようになりました。

## BNF

ここまで実装したような処理はBNF（[バッカス・ナウア記法](https://ja.wikipedia.org/wiki/%E3%83%90%E3%83%83%E3%82%AB%E3%82%B9%E3%83%BB%E3%83%8A%E3%82%A6%E3%82%A2%E8%A8%98%E6%B3%95)）と呼ばれる形式言語で記述できます。

拡張版の[EBNF](https://ja.wikipedia.org/wiki/EBNF)で示します。

```text:EBNF
expr = term  , {"+"|"-", term  }
term = number, {"*"|"/", number}
```

今回のコードに合わせてEBNFを変形するため、演算子それぞれに処理を記述します。

```text:EBNF
expr = term  , {("+", term  ) | ("-", term  )}
term = number, {("*", number) | ("/", number)}
```

### 比較

コードにコメントとして追記するので比較してください。

```java:比較
    // expr = term, {("+", term) | ("-", term)}
    public final int expr() {
        int x = term();
        for (;;) {
            switch (peek()) {
                case '+':
                    next();
                    x += term();
                    continue;
                case '-':
                    next();
                    x -= term();
                    continue;
            }
            break;
        }
        return x;
    }

    // term = number, {("*", number) | ("/", number)}
    public final int term() {
        int x = number();
        for (;;) {
            switch (peek()) {
                case '*':
                    next();
                    x *= number();
                    continue;
                case '/':
                    next();
                    x /= number();
                    continue;
            }
            break;
        }
        return x;
    }
```

このコードはなるべくBNFに近付けるよう意識しています。慣れて来れば、先にBNFで定義してからコードを書いた方が効率的だと感じるでしょう。

## 括弧

括弧を実装するため、項の下位に因子（factor）という層を追加します。

括弧の中は`expr`のため、次のように再帰が循環します。

* `expr` → `term` → `factor` → `expr` → ...

※ `Parser`クラスを示します。

```java:修正
class Parser extends Source {

    public Parser(String str) {
        super(str);
    }

    public final int number() {
        StringBuilder sb = new StringBuilder();
        int ch;
        while ((ch = peek()) >= 0 && Character.isDigit(ch)) {
            sb.append((char) ch);
            next();
        }
        return Integer.parseInt(sb.toString());
    }

    // expr = term, {("+", term) | ("-", term)}
    public final int expr() {
        int x = term();
        for (;;) {
            switch (peek()) {
                case '+':
                    next();
                    x += term();
                    continue;
                case '-':
                    next();
                    x -= term();
                    continue;
            }
            break;
        }
        return x;
    }

    // term = factor, {("*", factor) | ("/", factor)}
    public final int term() {
        int x = factor();
        for (;;) {
            switch (peek()) {
                case '*':
                    next();
                    x *= factor();
                    continue;
                case '/':
                    next();
                    x /= factor();
                    continue;
            }
            break;
        }
        return x;
    }

    // factor = ("(", expr, ")") | number
    public final int factor() {
        if (peek() == '(') {
            next();
            int ret = expr();
            if (peek() == ')') {
                next();
            }
            return ret;
        }
        return number();
    }
}
```

動作を確認します。

```java:Main（修正）
    public static void main(String[] args) {
        test("(2+3)*4");
    }
```
```text:実行結果
(2+3)*4 = 20
```

きちんと計算できています。

再帰が循環して括弧の中に入っている様子から**再帰下降**という用語がイメージできます。

## スペース

式にスペースが入っていても評価できるようにします。

`Parser`クラスにスペースを無視するパーサ`spaces`を追加します。

```java:Parser（追加）
    public void spaces() {
        while (peek() == ' ') {
            next();
        }
    }
```

`Parser#factor`を修正します。

```java:Parser（修正）
    // factor = factor = [spaces], ("(", expr, ")") | number, [spaces]
    public final int factor() {
        int ret;
        spaces();
        if (peek() == '(') {
            next();
            ret = expr();
            if (peek() == ')') {
                next();
            }
        } else {
            ret = number();
        }
        spaces();
        return ret;
    }
```

次のようなテストが動くようになります。

```java:Main（修正）
    public static void main(String[] args) {
        test("1 + 2"        );
        test("123"          );
        test("1 + 2 + 3"    );
        test("1 - 2 - 3"    );
        test("1 - 2 + 3"    );
        test("2 * 3 + 4"    );
        test("2 + 3 * 4"    );
        test("100 / 10 / 2" );
        test("( 2 + 3 ) * 4");
    }
```
```text:実行結果
1 + 2 = 3
123 = 123
1 + 2 + 3 = 6
1 - 2 - 3 = -4
1 - 2 + 3 = 2
2 * 3 + 4 = 10
2 + 3 * 4 = 14
100 / 10 / 2 = 5
( 2 + 3 ) * 4 = 20
```

以上で四則演算器の実装は完了です。

* [ここまでのコード全体](http://ideone.com/fuBe5S)

再帰下降による構文解析が何となく見えて来ればしめたものです。

再帰下降パーサは同じようなコードの繰り返しで冗長です。それを短くする方法の1つが、冒頭で紹介したパーサコンビネータです。

* [Java パーサコンビネータ 超入門](http://qiita.com/7shi/items/68228e19552c271bea81) 2016.05.12
* [Java パーサコンビネータ 超入門 2](http://qiita.com/7shi/items/39a9ddffcc5bdf2c0142) 2016.05.14
