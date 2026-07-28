---
coediting: false
comments_count: 0
created_at: '2016-05-12T14:23:39+09:00'
id: 68228e19552c271bea81
likes_count: 117
private: false
reactions_count: 0
stocks_count: 100
tags:
- name: Java
  versions: []
title: Java パーサコンビネータ 超入門
updated_at: '2016-12-27T02:32:55+09:00'
url: https://qiita.com/7shi/items/68228e19552c271bea81
slide: false
---

構文を解析するプログラムをパーサと呼びます。実装方法にはいくつか種類がありますが、今回はパーサコンビネータという方式を取り上げます。既存の実装を使うのではなく、1から実装しながら説明します。

この記事は再帰下降構文解析の知識を前提とします。詳細は次の記事を参照してください。

* [Java 再帰下降構文解析 超入門](http://qiita.com/7shi/items/64261a67081d49f941e3) 2016.05.16

Javaには既存のパーサコンビネータがありますが、この記事では使用しません。

* [jparsec](https://github.com/jparsec/jparsec)
* [ParsecJ](https://github.com/jon-hanson/parsecj)

この記事ではHaskellのParsecを参考にしています。もちろんHaskellやモナドの知識は前提としません。それと断らずにモナドに由来する何かは出て来ますが、それが見抜けなくても問題ありません。興味があれば以下の記事を参照してください。

* [Haskell 構文解析 超入門](http://qiita.com/7shi/items/b8c741e78a96ea2c10fe) 2015.07.31

今回はラムダ式を多用するためJava 8以降を対象とします。ラムダ式なしで実装するとあまりにも冗長になり過ぎて、便利さよりも煩雑さが勝ってしまうためです。

この記事には続編があります。

* [Java パーサコンビネータ 超入門 2](http://qiita.com/7shi/items/39a9ddffcc5bdf2c0142) 2016.05.14

この記事にはC++版があります。

* [C++11 パーサコンビネータ 超入門](http://qiita.com/7shi/items/6a12160276a8db358e34) 2015.11.27
* [C++11 パーサコンビネータ 超入門 2](http://qiita.com/7shi/items/f86f2f7ad68cfff1b399) 2015.11.30

この記事には関連記事があります。

* [JSONパーサーを作る](http://qiita.com/7shi/items/04c2991239894687ef2f) 2016.12.26

この記事を書くための実験用リポジトリです。記事化に際してコードに手を加えたため一部異なる場合があります。

* https://bitbucket.org/7shi/jmyparsec

# コンセプト

パーサコンビネータは、単純な部品（パーサ）の組み合わせ（コンビネーション）で構文を解析します。

文字列からアルファベットと数字を分離する例です。使用している`jmyparsec`パッケージはこの記事で1から作ります。

```java
import jmyparsec.*;
import static jmyparsec.Parsers.*;

public class Test {

    public static void main(String[] args) throws Exception {
        Source s1 = new Source("abc123");
        String s1a = many(alpha).parse(s1);
        String s1b = many(digit).parse(s1);
        System.out.println(s1a + "," + s1b);

        Source s2 = new Source("abcde9");
        String s2a = many(alpha).parse(s2);
        String s2b = many(digit).parse(s2);
        System.out.println(s2a + "," + s2b);
    }
}
```
```text:実行結果
abc,123
abcde,9
```

このコードの読み方を説明します。

1. 処理対象の文字列`"abc123"`を`s1`に代入
2. `s1`から、連続（`many`）するアルファベット（`alpha`）を取り出して`s1a`に代入
3. `s1`の後続の文字列から、連続（`many`）する数字（`digit`）を取り出して`s1b`に代入
4. `s1a`と`s1b`の中身を確認
5. 別の文字列を同様に処理

`alpha`や`digit`は1文字だけを読み込むパーサです。それらを`many`というコンビネータと組み合わせることで、複数文字を処理する`many(alpha)`や`many(digit)`というパーサを作ります。

正規表現と似たようなものをコードで表現したとイメージすれば良いかもしれません。たとえば`many(digit)`は正規表現の`[0-9]*`に相当します。

コード       |対応する正規表現
-------------|----------------
`digit`      |`[0-9]`
`many`       |`*`
`many(digit)`|`[0-9]*`

これだけ見ると正規表現の方が簡潔ですが、コードで表現することで複雑なパターンにも対応しやすいという強みがあります。

`s1`や`s2`は処理するたびに文字を読み進めます。現在位置に関して変更（副作用）があります。

※ この辺の設計は副作用を排除したHaskellのParsecとは異なりますが、Javaで実装しやすくするためのアレンジです。Haskellと完全に同じものをJavaで実装したわけではありません。

# 基礎編

簡単な所から少しずつパーサコンビネータを作り始めます。

## 1文字取得

指定した文字列から先頭の1文字を取得します。

```java
public class Test {

    static char anyChar(String s) {
        return s.charAt(0);
    }

    public static void main(String[] args) {
        System.out.println(anyChar("abc"));
    }
}
```
```text:実行結果
a
```

`anyChar`が最初のパーサです。

### 連続呼び出し

`anyChar`を連続呼び出しすることで複数文字を取得できるように拡張します。

現在位置を管理して読み取り後に1文字進めれば、次の呼び出しで次の文字が取得できます。

```java
public class Test {

    static int pos;

    static char anyChar(String s) {
        char ret = s.charAt(pos);
        ++pos;
        return ret;
    }

    public static void main(String[] args) {
        String s = "abc";
        System.out.println(anyChar(s));
        System.out.println(anyChar(s));
    }
}
```
```text:実行結果
a
b
```

`anyChar`を2回繰り返すことで、先頭から2文字取得しています。

## クラス化

文字と位置をペアで管理するため、クラス化します。

```jmyparsec/Source.java
package jmyparsec;

public class Source {

    private final String s;
    private int pos;

    public Source(String s) {
        this.s = s;
    }

    public final char peek() {
        return s.charAt(pos);
    }

    public final void next() {
        ++pos;
    }
}
```

`Source`を使って書き直します。

```java
import jmyparsec.*;

public class Test {

    static char anyChar(Source s) {
        char ret = s.peek();
        s.next();
        return ret;
    }

    public static void main(String[] args) {
        Source s = new Source("abc");
        System.out.println(anyChar(s));
        System.out.println(anyChar(s));
    }
}
```
```text:実行結果
a
b
```

`anyChar`を`Source`のインスタンスメソッドにすれば良いと思われたかもしれません。詳細は後で見て行きますが、パーサコンビネータでは利用者が目的に特化したパーサをその都度定義するスタイルのため、`Source`の外で定義しておいた方が都合が良いのです。

## メソッド化

2文字取得する部分をメソッド化します。

```java
import jmyparsec.*;

public class Test {

    static char anyChar(Source s) {
        char ret = s.peek();
        s.next();
        return ret;
    }

    static String test1(Source s) {  // メソッド化
        char x1 = anyChar(s);
        char x2 = anyChar(s);
        return new String(new char[]{x1, x2});
    }

    public static void main(String[] args) {
        Source s = new Source("abc");
        System.out.println(anyChar(s));
        System.out.println(test1(s));
    }
}
```
```text:実行結果
a
bc
```

`test1`は`anyChar`を組み合わせて作られていますが、利用側からは`anyChar`と`test1`が同じように扱えるのがポイントです。ただし戻り値の型が異なるのには注意が必要です。

### 組み合わせ

`test1`は、別の箇所で`anyChar`と組み合わせて利用できます。

```java
import jmyparsec.*;

public class Test {

    static char anyChar(Source s) {
        char ret = s.peek();
        s.next();
        return ret;
    }

    static String test1(Source s) {
        char x1 = anyChar(s);
        char x2 = anyChar(s);
        return new String(new char[]{x1, x2});
    }

    static String test2(Source s) {  // 追加
        String x1 = test1(s);
        char x2 = anyChar(s);
        return x1 + x2;
    }

    public static void main(String[] args) {
        Source s1 = new Source("abc");
        System.out.println(anyChar(s1));
        Source s2 = new Source("abc");
        System.out.println(test1(s2));
        Source s3 = new Source("abc");
        System.out.println(test2(s3));
    }
}
```
```text:実行結果
a
ab
abc
```

`test1`は`anyChar`を2つ組み合わせて作ったパーサです。`test2`は`test1`と`anyChar`を組み合わせて作ったパーサです。このように簡単なパーサを組み合わせて複雑なパーサを作っていくのが、パーサコンビネータの基本的な考え方です。

`main`の中で`anyChar`と`test1`と`test2`が同列に並んでいますが、どれもパーサとして同じような位置付けだと見立ててください。

## テストメソッド

`main()`でのテストが煩雑になって来たので、テスト用のメソッド`parseTest`を作成します。

```java
import jmyparsec.*;
import java.util.function.Function;

public class Test {

    static <T> void parseTest(Function<Source, T> p, String src) {  // 追加
        Source s = new Source(src);
        System.out.println(p.apply(s));
    }

    static char anyChar(Source s) {
        char ret = s.peek();
        s.next();
        return ret;
    }

    static String test1(Source s) {
        char x1 = anyChar(s);
        char x2 = anyChar(s);
        return new String(new char[]{x1, x2});
    }

    static String test2(Source s) {
        String x1 = test1(s);
        char x2 = anyChar(s);
        return x1 + x2;
    }

    public static void main(String[] args) {
        parseTest(Test::anyChar, "abc");
        parseTest(Test::test1, "abc");
        parseTest(Test::test2, "abc");
    }
}
```
```text:実行結果
a
ab
abc
```

`parseTest`にはパーサのメソッド（`anyChar`など）を渡しますが、異なる戻り値を受け付けるようにジェネリクスを用いています。メソッドを引数として渡すには`Test::`が必要です。

### 関数型インターフェース

`Function<Source, T>`の`Source`は共通で、省略するため専用の関数型インターフェースを定義します。

```jmyparsec/Parser.java
package jmyparsec;

@FunctionalInterface
public interface Parser<T> {

    T parse(Source s);
}
```

```java
import jmyparsec.*;

public class Test {

    static void parseTest(Parser p, String src) {  // 使用箇所
        Source s = new Source(src);
        System.out.println(p.parse(s));
    }

    static char anyChar(Source s) {
        char ret = s.peek();
        s.next();
        return ret;
    }

    static String test1(Source s) {
        char x1 = anyChar(s);
        char x2 = anyChar(s);
        return new String(new char[]{x1, x2});
    }

    static String test2(Source s) {
        String x1 = test1(s);
        char x2 = anyChar(s);
        return x1 + x2;
    }

    public static void main(String[] args) {
        parseTest(Test::anyChar, "abc");
        parseTest(Test::test1, "abc");
        parseTest(Test::test2, "abc");
    }
}
```
```text:実行結果
a
ab
abc
```

### ラムダ式化

`Test::`が冗長です。これを省略可能にするためパーサをラムダ式化します。

```java
import jmyparsec.*;

public class Test {

    static void parseTest(Parser p, String src) {
        Source s = new Source(src);
        System.out.println(p.parse(s));
    }

    static final Parser<Character> anyChar = s -> {  // ラムダ式化
        char ret = s.peek();
        s.next();
        return ret;
    };                                               // セミコロン

    static final Parser<String> test1 = s -> {       // ラムダ式化
        char x1 = anyChar.parse(s);                  // .parse
        char x2 = anyChar.parse(s);                  // .parse
        return new String(new char[]{x1, x2});
    };                                               // セミコロン

    static final Parser<String> test2 = s -> {       // ラムダ式化
        String x1 = test1.parse(s);                  // .parse
        char x2 = anyChar.parse(s);                  // .parse
        return x1 + x2;
    };                                               // セミコロン

    public static void main(String[] args) {
        parseTest(anyChar, "abc");  // 単純化
        parseTest(test1, "abc");    // 単純化
        parseTest(test2, "abc");    // 単純化
    }
}
```
```text:実行結果
a
ab
abc
```

今度はパーサーの使用箇所で`.parse`が必要になりましたが、これは後で対策します。

## 例外

文字列の末尾に達すると例外が発生します。理由を返すようにします。

```jmyparsec/Source.java
package jmyparsec;

public class Source {

    private final String s;
    private int pos;

    public Source(String s) {
        this.s = s;
    }

    public final char peek() throws Exception {  // 例外対応
        if (pos >= s.length()) {
            throw new Exception("too short");
        }
        return s.charAt(pos);
    }

    public final void next() {
        ++pos;
    }
}
```

```jmyparsec/Parser.java
package jmyparsec;

@FunctionalInterface
public interface Parser<T> {

    T parse(Source s) throws Exception;  // 例外対応
}
```

`parseTest`で例外を処理します。

```java
import jmyparsec.*;

public class Test {

    static void parseTest(Parser p, String src) {
        Source s = new Source(src);
        try {
            System.out.println(p.parse(s));
        } catch (Exception e) {  // 例外処理
            System.out.println(e.getMessage());
        }
    }

    static final Parser<Character> anyChar = s -> {
        char ret = s.peek();
        s.next();
        return ret;
    };

    static final Parser<String> test1 = s -> {
        char x1 = anyChar.parse(s);
        char x2 = anyChar.parse(s);
        return new String(new char[]{x1, x2});
    };

    static final Parser<String> test2 = s -> {
        String x1 = test1.parse(s);
        char x2 = anyChar.parse(s);
        return x1 + x2;
    };

    public static void main(String[] args) {
        parseTest(test2, "12");  // 文字数不足
        parseTest(test2, "123");
    }
}
```
```text:実行結果
too short
123
```

## 条件取得

`anyChar`は無条件で文字を取得していましたが、条件が指定できる`satisfy`を追加します。引数で渡されたメソッドをキャプチャしたクロージャを返します。

```java
import jmyparsec.*;
import java.util.function.Function;

public class Test {

    static void parseTest(Parser p, String src) {
        Source s = new Source(src);
        try {
            System.out.println(p.parse(s));
        } catch (Exception e) {
            System.out.println(e.getMessage());
        }
    }

    static final Parser<Character> anyChar = s -> {
        char ret = s.peek();
        s.next();
        return ret;
    };

    static final Parser<Character> satisfy(Function<Character, Boolean> f) {  // 追加
        return s -> {
            char ch = s.peek();
            if (!f.apply(ch)) {
                throw new Exception("not satisfy");
            }
            s.next();
            return ch;
        };
    }

    public static void main(String[] args) {
        parseTest(satisfy(Character::isDigit), "abc");  // NG
        parseTest(satisfy(Character::isDigit), "123");
    }
}
```
```text:実行結果
not satisfy
1
```

今回の機能追加に直接関係ない`test1`と`test2`は削除しました。

### 共通化

`anyChar`と`satisfy`で処理が重複しています。`anyChar`は無条件の`satisfy`として定義することで共通化を図ります。

```java
import jmyparsec.*;
import java.util.function.Function;

public class Test {

    static void parseTest(Parser p, String src) {
        Source s = new Source(src);
        try {
            System.out.println(p.parse(s));
        } catch (Exception e) {
            System.out.println(e.getMessage());
        }
    }

    static final Parser<Character> anyChar = satisfy(s -> true);  // 変更

    static final Parser<Character> satisfy(Function<Character, Boolean> f) {
        return s -> {
            char ch = s.peek();
            if (!f.apply(ch)) {
                throw new Exception("not satisfy");
            }
            s.next();
            return ch;
        };
    }

    public static void main(String[] args) {
        parseTest(anyChar, "abc");
    }
}
```
```text:実行結果
a
```

`anyChar`はラムダ式で定義したため1行で済んでいるのがポイントです。

## ファイル分割

コードが長くなって来たため、汎用部分を別ファイルに分離します。

```jmyparsec/Parsers.java
package jmyparsec;

import java.util.function.Function;

public class Parsers {

    public static void parseTest(Parser p, String src) {
        Source s = new Source(src);
        try {
            System.out.println(p.parse(s));
        } catch (Exception e) {
            System.out.println(e.getMessage());
        }
    }

    public static final Parser<Character> anyChar = satisfy(s -> true);

    public static final Parser<Character> satisfy(Function<Character, Boolean> f) {
        return s -> {
            char ch = s.peek();
            if (!f.apply(ch)) {
                throw new Exception("not satisfy");
            }
            s.next();
            return ch;
        };
    }
}
```

簡単のため`import static`して使います。

```java
import static jmyparsec.Parsers.*;

public class Test {

    public static void main(String[] args) {
        parseTest(anyChar, "abc");
    }
}
```
```text:実行結果
a
```

## 文字判定

文字を指定して判定するパーサを実装します。Parsecでは`char`ですが、型と被るため`char1`に名前を変更します。

```java:jmyparsec/Parsers.java（追加）
    public static final Parser<Character> char1(char ch) {
        return satisfy(c -> c == ch);
    }
```

`char1`は引数`ch`をキャプチャしたクロージャを返しているのがポイントです。今後このようなパターンがよく出て来ます。

動作を確認します。

```java
import static jmyparsec.Parsers.*;

public class Test {

    public static void main(String[] args) {
        parseTest(char1('a'), "abc");
        parseTest(char1('a'), "123");  // NG
    }
}
```
```text:実行結果
a
not satisfy
```

## 事前定義

`satisfy`で条件を指定するのは冗長なので、よく使うパターンを事前定義します。

```java:jmyparsec/Parsers.java（追加）
    public static final boolean isAlphaNum(char ch) {
        return Character.isAlphabetic(ch) || Character.isDigit(ch);
    }

    public static final Parser<Character> digit = satisfy(Character::isDigit);
    public static final Parser<Character> upper = satisfy(Character::isUpperCase);
    public static final Parser<Character> lower = satisfy(Character::isLowerCase);
    public static final Parser<Character> alpha = satisfy(Character::isAlphabetic);
    public static final Parser<Character> alphaNum = satisfy(Parsers::isAlphaNum);
    public static final Parser<Character> letter = satisfy(Character::isLetter);
```

動作を確認します。

```java
import static jmyparsec.Parsers.*;

public class Test {

    public static void main(String[] args) {
        parseTest(digit , "abc");  // NG
        parseTest(digit , "123");
        parseTest(letter, "abc");
        parseTest(letter, "123");  // NG
    }
}
```
```text:実行結果
not satisfy
1
a
not satisfy
```

## 組み合わせ判定

先ほど追加したパーサを組み合わせて、先頭から「アルファベット」「数字」「数字」という組み合わせを判定するパーサを作ります。

```java
import jmyparsec.*;
import static jmyparsec.Parsers.*;

public class Test {

    static final Parser<String> test3 = s -> {
        char x1 = letter.parse(s);
        char x2 = digit.parse(s);
        char x3 = digit.parse(s);
        return new String(new char[]{x1, x2, x3});
    };

    public static void main(String[] args) {
        parseTest(test3, "abc");  // NG
        parseTest(test3, "123");  // NG
        parseTest(test3, "a23");
        parseTest(test3, "a234");
    }
}
```
```text:実行結果
not satisfy
not satisfy
a23
a23
```

`main()`から見ると、同じクラスに定義されているパーサ（`anyChar`など）と`jmyparsec.Parsers`に定義されているパーサ（`test3`）が、クラス名修飾なしに同列に使えています。これが`anyChar`を`Source`のインスタンスメソッドにしなかった理由です。

## コンビネータの定義

パーサ同士を組み合わせて新しいパーサを作り出すメソッドを**コンビネータ**と呼びます。

いくつか便利なコンビネータを定義します。

### 結合

パーサを結合するコンビネータ`sequence`を定義してParsers.javaに追加します。

```java:jmyparsec/Parsers.java（追加）
    public static final Parser<String> sequence(Parser... args) {
        return s -> {
            StringBuilder sb = new StringBuilder();
            for (Parser arg : args) {
                sb.append(arg.parse(s));
            }
            return sb.toString();
        };
    }
```

`test3`がとても簡単になります。

```java
import jmyparsec.*;
import static jmyparsec.Parsers.*;

public class Test {

    static final Parser<String> test3 = sequence(letter, digit, digit);

    public static void main(String[] args) {
        parseTest(test3, "abc");  // NG
        parseTest(test3, "123");  // NG
        parseTest(test3, "a23");
        parseTest(test3, "a234");
    }
}
```
```text:実行結果
not satisfy
not satisfy
a23
a23
```

処理が関数を定義しなくても組み合わせで表現されています。この感覚がつかめれば、パーサコンビネータが見えて来ます。

※ 前の方で述べた`.parse`を回避するための対策がこれです。

### 繰り返し

同じパーサを指定回数繰り返すコンビネータ`replicate`を定義します。

```java:jmyparsec/Parsers.java（追加）
    public static final Parser<String> replicate(int n, Parser p) {
        return s -> {
            StringBuilder sb = new StringBuilder();
            for (int i = 0; i < n; ++i) {
                sb.append(p.parse(s));
            }
            return sb.toString();
        };
    }
```

`test3`で使ってみます。

```java
import jmyparsec.*;
import static jmyparsec.Parsers.*;

public class Test {

    static final Parser<String> test3 = sequence(letter, replicate(2, digit));

    public static void main(String[] args) {
        parseTest(test3, "abc");  // NG
        parseTest(test3, "123");  // NG
        parseTest(test3, "a23");
        parseTest(test3, "a234");
    }
}
```
```text:実行結果
not satisfy
not satisfy
a23
a23
```

2回の繰り返しではあまり嬉しくありませんが、回数が増えれば楽になります。

## many

繰り返しに関連して、最初のコンセプトで出て来た`many`を実装してみます。

`many`は指定したパーサを0回以上適用して返すコンビネータです。エラーになるまで読み進めれば実装できます。

```java:jmyparsec/Parsers.java（追加）
    public static final Parser<String> many(Parser p) {
        return s -> {
            StringBuilder sb = new StringBuilder();
            try {
                for (;;) {
                    sb.append(p.parse(s));
                }
            } catch (Exception e) {
            }
            return sb.toString();
        };
    }
```

先頭からアルファベットだけを抜き出してみます。1文字も一致しなくても、エラーにはならずに空文字列が返ります。

```java
import jmyparsec.*;
import static jmyparsec.Parsers.*;

public class Test {

    static final Parser<String> test4 = many(alpha);

    public static void main(String[] args) {
        parseTest(test4, "abc123");
        parseTest(test4, "123abc");
    }
}
```
```text:実行結果
abc
     ← 空行
```

最初に出て来たサンプルも動きます。

```java
import jmyparsec.*;
import static jmyparsec.Parsers.*;

public class Test {

    public static void main(String[] args) throws Exception {
        Source s1 = new Source("abc123");
        String s1a = many(alpha).parse(s1);
        String s1b = many(digit).parse(s1);
        System.out.println(s1a + "," + s1b);

        Source s2 = new Source("abcde9");
        String s2a = many(alpha).parse(s2);
        String s2b = many(digit).parse(s2);
        System.out.println(s2a + "," + s2b);
    }
}
```
```text:実行結果
abc,123
abcde,9
```

## まとめ

ここまでがパーサコンビネータの動作原理を理解するために最低限必要な実装です。

このセクションで登場したテストを1つにまとめます。

* [ここまでの jmyparsec](https://bitbucket.org/7shi/jmyparsec/src/0388bbfbf90b0215f640430e6bc48833d3e2c24f/src/jmyparsec/?at=default)

```java
import jmyparsec.*;
import static jmyparsec.Parsers.*;

public class Test {

    static final Parser<String> test1 = sequence(anyChar, anyChar);
    static final Parser<String> test2 = sequence(test1, anyChar);
    static final Parser<String> test3 = sequence(letter, replicate(2, digit));
    static final Parser<String> test4 = many(alpha);

    public static void main(String[] args) throws Exception {
        parseTest(anyChar   , "abc"   );
        parseTest(test1     , "abc"   );
        parseTest(test2     , "abc"   );
        parseTest(test2     , "12"    );  // NG
        parseTest(test2     , "123"   );
        parseTest(char1('a'), "abc"   );
        parseTest(char1('a'), "123"   );  // NG
        parseTest(digit     , "abc"   );  // NG
        parseTest(digit     , "123"   );
        parseTest(letter    , "abc"   );
        parseTest(letter    , "123"   );  // NG
        parseTest(test3     , "abc"   );  // NG
        parseTest(test3     , "123"   );  // NG
        parseTest(test3     , "a23"   );
        parseTest(test3     , "a234"  );
        parseTest(test4     , "abc123");
        parseTest(test4     , "123abc");

        Source s1 = new Source("abc123");
        String s1a = many(alpha).parse(s1);
        String s1b = many(digit).parse(s1);
        System.out.println(s1a + "," + s1b);

        Source s2 = new Source("abcde9");
        String s2a = many(alpha).parse(s2);
        String s2b = many(digit).parse(s2);
        System.out.println(s2a + "," + s2b);
    }
}
```
```text:実行結果
a
ab
abc
too short
123
a
not satisfy
not satisfy
1
a
not satisfy
not satisfy
not satisfy
a23
a23
abc

abc,123
abcde,9
```

最初にコンセプトで提示したコードを見たときはモヤっとしていた部分も、少しはすっきりしたでしょうか。

# 選択

非常によく使うのが選択のコンビネータです。

便利なだけでなく、色々と悩ましい問題があるのを見ていきます。

## 単純な実装

「または」を表現するコンビネータ`or`を実装します。

```java:jmyparsec/Parsers.java（追加）
    public static final <T> Parser<T> or(Parser<T> p1, Parser<T> p2) {
        return s -> {
            T ret;
            try {
                ret = p1.parse(s);
            } catch (Exception e) {
                ret = p2.parse(s);
            }
            return ret;
        };
    }
```

`or`を使えば「アルファベットまたは数字」のような選択的なパーサが構築できます。

```java
import jmyparsec.*;
import static jmyparsec.Parsers.*;

public class Test {

    static final Parser<Character> test5 = or(letter, digit);

    public static void main(String[] args) {
        parseTest(test5, "a");
        parseTest(test5, "1");
        parseTest(test5, "!");  // NG
    }
}
```
```text:実行結果
a
1
not satisfy
```

### manyとの組み合わせ

選択的パーサを`many`で繰り返すこともできます。

```java
import jmyparsec.*;
import static jmyparsec.Parsers.*;

public class Test {

    static final Parser<String> test6 = many(or(letter, digit));

    public static void main(String[] args) {
        parseTest(test6, "abc123");
        parseTest(test6, "123abc");
    }
}
```
```text:実行結果
abc123
123abc
```

## 結合と選択

`or`を少し使ってみると、直感に反した動きに気付きます。

```java
import jmyparsec.*;
import static jmyparsec.Parsers.*;

public class Test {

    static final Parser<Character> a = char1('a');
    static final Parser<Character> b = char1('b');
    static final Parser<Character> c = char1('c');

    static final Parser<String> test7 = or(sequence(a, b), sequence(c, b));

    public static void main(String[] args) {
        parseTest(test7, "ab");
        parseTest(test7, "cb");
        parseTest(test7, "acb");  // ???
    }
}
```
```text:実行結果
ab
cb
cb
```

`test7`を素直に見ると「`"ab"`または`"cb"`」となり、確かにその両方にマッチします。しかし`"acb"`にもマッチしてしまいます。これは`or`に達する前に`'a'`だけは読み進めてしまったため、`or`の後のパターンにマッチしてしまうためです。

## エラー化

このようなケースはParsecではエラーになります。

`or(左, 右)`として、左のパーサが内部で複数のパーサから構成されるとき、そのうち1つでも成功してその後で失敗したなら、右のパーサは処理されずにエラーになるという仕様です。

これを実装するため、パーサの状態を保持・比較できるように修正します。

```java:jmyparsec/Source.java（追加）
    @Override
    public Source clone() {
        Source ret = new Source(s);
        ret.pos = pos;
        return ret;
    }

    @Override
    public boolean equals(Object obj) {
        if (!(obj instanceof Source)) {
            return false;
        }
        Source src = (Source) obj;
        return s.equals(src.s) && pos == src.pos;
    }
```

最初の状態を保持しておいて、`or`の前で読み進めていれば例外を再送します。

```java:jmyparsec/Parsers.java（修正）
    public static final <T> Parser<T> or(Parser<T> p1, Parser<T> p2) {
        return s -> {
            T ret;
            Source bak = s.clone();    // 追加
            try {
                ret = p1.parse(s);
            } catch (Exception e) {
                if (!s.equals(bak)) {  // 追加
                    throw e;
                }
                ret = p2.parse(s);
            }
            return ret;
        };
    }
```

先ほどと同じコードを試すと、最後がエラーになります。Parsecと同じで意図した動きです。

```java
import jmyparsec.*;
import static jmyparsec.Parsers.*;

public class Test {

    static final Parser<Character> a = char1('a');
    static final Parser<Character> b = char1('b');
    static final Parser<Character> c = char1('c');

    static final Parser<String> test7 = or(sequence(a, b), sequence(c, b));

    public static void main(String[] args) {
        parseTest(test7, "ab");
        parseTest(test7, "cb");
        parseTest(test7, "acb");  // ???
    }
}
```
```text:実行結果
ab
cb
not satisfy
```

## 共通部分

選択肢の先頭に共通部分があった場合、意図せずエラーになることがあります。

```java
import jmyparsec.*;
import static jmyparsec.Parsers.*;

public class Test {

    static final Parser<Character> a = char1('a');
    static final Parser<Character> b = char1('b');
    static final Parser<Character> c = char1('c');

    static final Parser<String> test8 = or(sequence(a, b), sequence(a, c));

    public static void main(String[] args) {
        parseTest(test8, "ab");
        parseTest(test8, "ac");  // NG
    }
}
```
```text:実行結果
ab
not satisfy
```

このようなケースでは、共通部分を括り出すことで対処できます。

```java
import jmyparsec.*;
import static jmyparsec.Parsers.*;

public class Test {

    static final Parser<Character> a = char1('a');
    static final Parser<Character> b = char1('b');
    static final Parser<Character> c = char1('c');

    static final Parser<String> test8 = or(sequence(a, b), sequence(a, c));
    static final Parser<String> test9 = sequence(a, or(b, c));

    public static void main(String[] args) {
        parseTest(test8, "ab");
        parseTest(test8, "ac");  // NG
        parseTest(test9, "ab");
        parseTest(test9, "ac");
    }
}
```
```text:実行結果
ab
not satisfy
ab
ac
```

別の方法として状態を巻き戻す方法もあります。

## バックトラック

パースに失敗したとき、状態を巻き戻して別の方法でパースをやり直すことを**バックトラック**と呼びます。

### tryp

Parsecでバックトラックするには対象となるパーサを`try`で囲みます。例外処理の`try`と名前が被るため、ここでは`tryp`に名前を変更します。（`p`はParserの頭文字です）

`Source`の状態を元に戻せるようにします。

```java:jmyparsec/Source.java（追加）
    public final void revert(Source src) throws Exception {
        if (!s.equals(src.s)) {
            throw new Exception("can not revert");
        }
        pos = src.pos;
    }
```

`tryp`の中で失敗すれば元の状態に戻してから例外を再送します。

```java:jmyparsec/Parsers.java（追加）
    public static final <T> Parser<T> tryp(Parser<T> p) {
        return s -> {
            T ret;
            Source bak = s.clone();
            try {
                ret = p.parse(s);
            } catch (Exception e) {
                s.revert(bak);
                throw e;
            }
            return ret;
        };
    }
```

`or`の左側を`tryp`で囲めば、失敗してもバックトラックしてから右側が処理されます。

先ほどの`test8`と`test9`と挙動を比較します。

```java
import jmyparsec.*;
import static jmyparsec.Parsers.*;

public class Test {

    static final Parser<Character> a = char1('a');
    static final Parser<Character> b = char1('b');
    static final Parser<Character> c = char1('c');

    static final Parser<String> test8 = or(sequence(a, b), sequence(a, c));
    static final Parser<String> test9 = sequence(a, or(b, c));
    static final Parser<String> test10 = or(tryp(sequence(a, b)), sequence(a, c));

    public static void main(String[] args) {
        parseTest(test8 , "ab");
        parseTest(test8 , "ac");  // NG
        parseTest(test9 , "ab");
        parseTest(test9 , "ac");
        parseTest(test10, "ab");
        parseTest(test10, "ac");
    }
}
```
```text:実行結果
ab
not satisfy
ab
ac
ab
ac
```

`test9`と`test10`は同じ動きです。

## string

1文字ずつ`char1`でパースすると面倒なため、文字列で指定できる`string`を実装します。

```java:jmyparsec/Parsers.java（追加）
    public static final Parser<String> string(String str) {
        return s -> {
            for (int i = 0; i < str.length(); ++i) {
                char1(str.charAt(i)).parse(s);
            }
            return str;
        };
    }
```

内部では1文字ずつ処理されているため、途中の失敗をバックトラックするには`tryp`が必要です。

挙動を確認します。

```java
import jmyparsec.*;
import static jmyparsec.Parsers.*;

public class Test {

    static final Parser<String> test11 = or(string("ab"), string("ac"));
    static final Parser<String> test12 = or(tryp(string("ab")), string("ac"));

    public static void main(String[] args) {
        parseTest(test11, "ab");
        parseTest(test11, "ac");  // NG
        parseTest(test12, "ab");
        parseTest(test12, "ac");
    }
}
```
```text:実行結果
ab
not satisfy
ab
ac
```

## まとめ

このセクションで登場したテストを1つにまとめます。

* [ここまでの jmyparsec](https://bitbucket.org/7shi/jmyparsec/src/454a73cd1cc091adc37ae7212ce71a7e97b42733/src/jmyparsec/?at=default)

```java
import jmyparsec.*;
import static jmyparsec.Parsers.*;

public class Test {

    static final Parser<Character> a = char1('a');
    static final Parser<Character> b = char1('b');
    static final Parser<Character> c = char1('c');

    static final Parser<Character> test5 = or(letter, digit);
    static final Parser<String> test6 = many(or(letter, digit));
    static final Parser<String> test7 = or(sequence(a, b), sequence(c, b));
    static final Parser<String> test8 = or(sequence(a, b), sequence(a, c));
    static final Parser<String> test9 = sequence(a, or(b, c));
    static final Parser<String> test10 = or(tryp(sequence(a, b)), sequence(a, c));
    static final Parser<String> test11 = or(string("ab"), string("ac"));
    static final Parser<String> test12 = or(tryp(string("ab")), string("ac"));

    public static void main(String[] args) {
        parseTest(test5 , "a"     );
        parseTest(test5 , "1"     );
        parseTest(test5 , "!"     );  // NG
        parseTest(test6 , "abc123");
        parseTest(test6 , "123abc");
        parseTest(test7 , "ab"    );
        parseTest(test7 , "cb"    );
        parseTest(test7 , "acb"   );  // NG
        parseTest(test8 , "ab"    );
        parseTest(test8 , "ac"    );  // NG
        parseTest(test9 , "ab"    );
        parseTest(test9 , "ac"    );
        parseTest(test10, "ab"    );
        parseTest(test10, "ac"    );
        parseTest(test11, "ab"    );
        parseTest(test11, "ac"    );  // NG
        parseTest(test12, "ab"    );
        parseTest(test12, "ac"    );
    }
}
```
```text:実行結果
a
1
not satisfy
abc123
123abc
ab
cb
not satisfy
ab
not satisfy
ab
ac
ab
ac
ab
not satisfy
ab
ac
```

# エラー表示

エラーが`too short`や`not satisfy`では分かりにくいので改善します。

このセクションは修正箇所が多いため差分と全体の両方を示します。

## 確認

エラーが出るものだけ抽出して確認します。

```java
import jmyparsec.*;
import static jmyparsec.Parsers.*;

public class Test {

    static final Parser<Character> a = char1('a');
    static final Parser<Character> b = char1('b');
    static final Parser<Character> c = char1('c');

    static final Parser<String> test1 = sequence(anyChar, anyChar);
    static final Parser<String> test2 = sequence(test1, anyChar);
    static final Parser<String> test3 = sequence(letter, replicate(2, digit));
    static final Parser<Character> test5 = or(letter, digit);
    static final Parser<String> test7 = or(sequence(a, b), sequence(c, b));
    static final Parser<String> test8 = or(sequence(a, b), sequence(a, c));
    static final Parser<String> test11 = or(string("ab"), string("ac"));

    public static void main(String[] args) {
        parseTest(test2     , "12" );  // NG
        parseTest(char1('a'), "123");  // NG
        parseTest(digit     , "abc");  // NG
        parseTest(letter    , "123");  // NG
        parseTest(test3     , "abc");  // NG
        parseTest(test3     , "123");  // NG
        parseTest(test5     , "!"  );  // NG
        parseTest(test7     , "acb");  // NG
        parseTest(test8     , "ac" );  // NG
        parseTest(test11    , "ac" );  // NG
    }
}
```
```text:実行結果
too short
not satisfy
not satisfy
not satisfy
not satisfy
not satisfy
not satisfy
not satisfy
not satisfy
not satisfy
```

## 位置

`Source`に位置（行と桁）を保持してエラーメッセージに含めます。

差分を示します。

```diff
--- jmyparsec/Source.java
+++ jmyparsec/Source.java
@@ -3,10 +3,11 @@
 public class Source {
 
     private final String s;
-    private int pos;
+    private int pos, line, col;
 
     public Source(String s) {
         this.s = s;
+        line = col = 1;
     }
 
     @Override
@@ -27,19 +28,29 @@
 
     public final char peek() throws Exception {
         if (pos >= s.length()) {
-            throw new Exception("too short");
+            throw new Exception(ex("too short"));
         }
         return s.charAt(pos);
     }
 
-    public final void next() {
+    public final void next() throws Exception {
+        char ch = peek();
+        if (ch == '\n') {
+            ++line;
+            col = 0;
+        }
         ++pos;
+        ++col;
     }
 
     public final void revert(Source src) throws Exception {
         if (!s.equals(src.s)) {
-            throw new Exception("can not revert");
+            throw new Exception(ex("can not revert"));
         }
         pos = src.pos;
     }
+
+    public final String ex(String e) {
+        return "[line " + line + ",col " + col + "] " + e;
+    }
 }
```
```diff
--- jmyparsec/Parsers.java
+++ jmyparsec/Parsers.java
@@ -19,7 +19,7 @@
         return s -> {
             char ch = s.peek();
             if (!f.apply(ch)) {
-                throw new Exception("not satisfy");
+                throw new Exception(s.ex("not satisfy"));
             }
             s.next();
             return ch;
```

* [修正後の jmyparsec](https://bitbucket.org/7shi/jmyparsec/src/6dc1b2bab6fed81d3399729c4e11f112b9a468f5/src/jmyparsec/?at=default)

先ほどと同じコードをテストして、エラーの変化を確認します。

```text:実行結果
[line 1, col 3] too short
[line 1, col 1] not satisfy
[line 1, col 1] not satisfy
[line 1, col 1] not satisfy
[line 1, col 2] not satisfy
[line 1, col 1] not satisfy
[line 1, col 1] not satisfy
[line 1, col 2] not satisfy
[line 1, col 2] not satisfy
[line 1, col 2] not satisfy
```

どこでエラーが発生したか分かるようになりました。

## 対象の文字

どの文字でエラーになったかをエラーメッセージに含めます。

差分を示します。

```diff
--- jmyparsec/Source.java
+++ jmyparsec/Source.java
@@ -51,6 +51,10 @@
     }
 
     public final String ex(String e) {
-        return "[line " + line + ",col " + col + "] " + e;
+        String ret = "[line " + line + ",col " + col + "] " + e;
+        if (s != null && 0 <= pos && pos < s.length()) {
+            ret += ": '" + s.charAt(pos) + "'";
+        }
+        return ret;
     }
 }
```

* [修正後の jmyparsec](https://bitbucket.org/7shi/jmyparsec/src/b2c76cef6965c5110998726d2c953d161bce2ab5/src/jmyparsec/?at=default)

先ほどと同じコードをテストして、エラーの変化を確認します。

```text:実行結果
[line 1, col 3] too short
[line 1, col 1] not satisfy: '1'
[line 1, col 1] not satisfy: 'a'
[line 1, col 1] not satisfy: '1'
[line 1, col 2] not satisfy: 'b'
[line 1, col 1] not satisfy: '1'
[line 1, col 1] not satisfy: '!'
[line 1, col 2] not satisfy: 'c'
[line 1, col 2] not satisfy: 'c'
[line 1, col 2] not satisfy: 'c'
```

どの文字でエラーになったのかが分かるようになりました。

## 失敗の確定

失敗を確定させて指定したメッセージで例外を発生させる`left`を実装します。

※ 英語でrightは「右」の他に「正しい」という意味がありますが、その反対を意図して`left`と命名されました。ある種の言葉遊びで、英語としての単語に「誤り」という意味があるわけではありません。

`or`と`left`を組み合わせれば、エラーメッセージがカスタマイズできます。

差分を示します。

```diff
--- jmyparsec/Parsers.java
+++ jmyparsec/Parsers.java
@@ -27,19 +27,19 @@
     }
 
     public static final Parser<Character> char1(char ch) {
-        return satisfy(c -> c == ch);
+        return or(satisfy(c -> c == ch), left("not char '" + ch + "'"));
     }
 
     public static final boolean isAlphaNum(char ch) {
         return Character.isAlphabetic(ch) || Character.isDigit(ch);
     }
 
-    public static final Parser<Character> digit = satisfy(Character::isDigit);
-    public static final Parser<Character> upper = satisfy(Character::isUpperCase);
-    public static final Parser<Character> lower = satisfy(Character::isLowerCase);
-    public static final Parser<Character> alpha = satisfy(Character::isAlphabetic);
-    public static final Parser<Character> alphaNum = satisfy(Parsers::isAlphaNum);
-    public static final Parser<Character> letter = satisfy(Character::isLetter);
+    public static final Parser<Character> digit    = or(satisfy(Character::isDigit)     , left("not digit"   ));
+    public static final Parser<Character> upper    = or(satisfy(Character::isUpperCase) , left("not upper"   ));
+    public static final Parser<Character> lower    = or(satisfy(Character::isLowerCase) , left("not lower"   ));
+    public static final Parser<Character> alpha    = or(satisfy(Character::isAlphabetic), left("not alpha"   ));
+    public static final Parser<Character> alphaNum = or(satisfy(Parsers  ::isAlphaNum)  , left("not alphaNum"));
+    public static final Parser<Character> letter   = or(satisfy(Character::isLetter)    , left("not letter"  ));
 
     public static final Parser<String> sequence(Parser... args) {
         return s -> {
@@ -107,9 +107,15 @@
     public static final Parser<String> string(String str) {
         return s -> {
             for (int i = 0; i < str.length(); ++i) {
-                char1(str.charAt(i)).parse(s);
+                or(char1(str.charAt(i)), left("not string \"" + str + "\"")).parse(s);
             }
             return str;
         };
     }
+
+    public static final <T> Parser<T> left(String e) {
+        return s -> {
+            throw new Exception(s.ex(e));
+        };
+    }
 }
```

* [修正後の jmyparsec](https://bitbucket.org/7shi/jmyparsec/src/5bb3e7d82f40f0c6389741d9927548c569a193f4/src/jmyparsec/?at=default)

先ほどと同じコードをテストして、エラーの変化を確認します。

```text:実行結果
[line 1, col 3] too short
[line 1, col 1] not char 'a': '1'
[line 1, col 1] not digit: 'a'
[line 1, col 1] not letter: '1'
[line 1, col 2] not digit: 'b'
[line 1, col 1] not letter: '1'
[line 1, col 1] not digit: '!'
[line 1, col 2] not char 'b': 'c'
[line 1, col 2] not char 'b': 'c'
[line 1, col 2] not string "ab": 'c'
```

エラーの種類が分かるようになりました。説明用にはこれくらいで十分でしょう。

## メソッドチェイン

`or`や`left`はよく使うので、`Parser`のデフォルトメソッドにします。こうすればメソッドチェインで書けるようになります。

```diff
--- jmyparsec/Parser.java
+++ jmyparsec/Parser.java
@@ -4,4 +4,26 @@
 public interface Parser<T> {
 
     T parse(Source s) throws Exception;
+
+    default Parser<T> or(Parser<T> p) {
+        return s -> {
+            T ret;
+            Source bak = s.clone();
+            try {
+                ret = parse(s);
+            } catch (Exception e) {
+                if (!s.equals(bak)) {
+                    throw e;
+                }
+                ret = p.parse(s);
+            }
+            return ret;
+        };
+    }
+
+    default Parser<T> left(String e) {
+        return or(s -> {
+            throw new Exception(s.ex(e));
+        });
+    }
 }
```
```diff
--- jmyparsec/Parsers.java
+++ jmyparsec/Parsers.java
@@ -27,19 +27,19 @@
     }
 
     public static final Parser<Character> char1(char ch) {
-        return or(satisfy(c -> c == ch), left("not char '" + ch + "'"));
+        return satisfy(c -> c == ch).left("not char '" + ch + "'");
     }
 
     public static final boolean isAlphaNum(char ch) {
         return Character.isAlphabetic(ch) || Character.isDigit(ch);
     }
 
-    public static final Parser<Character> digit    = or(satisfy(Character::isDigit)     , left("not digit"   ));
-    public static final Parser<Character> upper    = or(satisfy(Character::isUpperCase) , left("not upper"   ));
-    public static final Parser<Character> lower    = or(satisfy(Character::isLowerCase) , left("not lower"   ));
-    public static final Parser<Character> alpha    = or(satisfy(Character::isAlphabetic), left("not alpha"   ));
-    public static final Parser<Character> alphaNum = or(satisfy(Parsers  ::isAlphaNum)  , left("not alphaNum"));
-    public static final Parser<Character> letter   = or(satisfy(Character::isLetter)    , left("not letter"  ));
+    public static final Parser<Character> digit    = satisfy(Character::isDigit     ).left("not digit"   );
+    public static final Parser<Character> upper    = satisfy(Character::isUpperCase ).left("not upper"   );
+    public static final Parser<Character> lower    = satisfy(Character::isLowerCase ).left("not lower"   );
+    public static final Parser<Character> alpha    = satisfy(Character::isAlphabetic).left("not alpha"   );
+    public static final Parser<Character> alphaNum = satisfy(Parsers  ::isAlphaNum  ).left("not alphaNum");
+    public static final Parser<Character> letter   = satisfy(Character::isLetter    ).left("not letter"  );
 
     public static final Parser<String> sequence(Parser... args) {
         return s -> {
@@ -75,19 +75,7 @@
     }
 
     public static final <T> Parser<T> or(Parser<T> p1, Parser<T> p2) {
-        return s -> {
-            T ret;
-            Source bak = s.clone();
-            try {
-                ret = p1.parse(s);
-            } catch (Exception e) {
-                if (!s.equals(bak)) {
-                    throw e;
-                }
-                ret = p2.parse(s);
-            }
-            return ret;
-        };
+        return p1.or(p2);
     }
 
     public static final <T> Parser<T> tryp(Parser<T> p) {
@@ -107,7 +95,7 @@
     public static final Parser<String> string(String str) {
         return s -> {
             for (int i = 0; i < str.length(); ++i) {
-                or(char1(str.charAt(i)), left("not string \"" + str + "\"")).parse(s);
+                char1(str.charAt(i)).left("not string \"" + str + "\"").parse(s);
             }
             return str;
         };
```
```diff
--- Test.java
+++ Test.java
@@ -11,10 +11,10 @@
     static final Parser<String> test1 = sequence(anyChar, anyChar);
     static final Parser<String> test2 = sequence(test1, anyChar);
     static final Parser<String> test3 = sequence(letter, replicate(2, digit));
-    static final Parser<Character> test5 = or(letter, digit);
-    static final Parser<String> test7 = or(sequence(a, b), sequence(c, b));
-    static final Parser<String> test8 = or(sequence(a, b), sequence(a, c));
-    static final Parser<String> test11 = or(string("ab"), string("ac"));
+    static final Parser<Character> test5 = letter.or(digit);
+    static final Parser<String> test7 = sequence(a, b).or(sequence(c, b));
+    static final Parser<String> test8 = sequence(a, b).or(sequence(a, c));
+    static final Parser<String> test11 = string("ab").or(string("ac"));
 
     public static void main(String[] args) {
         parseTest(test2     , "12" );  // NG
```

* [修正後の jmyparsec](https://bitbucket.org/7shi/jmyparsec/src/e106ff602890e230ff5e002e06e3da7dcb87c862/src/jmyparsec/?at=default)

実行結果は同じなので省略します。

メソッドチェインを使うかどうかは好みにもよりますが、考え方を示しておきます。

* `or(a, b)` より  `a.or(b)` の方が `a || b` の並べ方に近い。
* `a` に条件 `b` を付け足すとき、`or(a, b)`で全体を囲むより `a.or(b)` として付け足す方が書きやすい。

# おわりに

パーサコンビネータの動作イメージがつかめたでしょうか。

今回のようにテストだけではどう応用して良いのか分からないかもしれません。続編で四則演算器を作っているので、そちらも参考にしてください。

* [Java パーサコンビネータ 超入門 2](http://qiita.com/7shi/items/39a9ddffcc5bdf2c0142) 2016.05.14
