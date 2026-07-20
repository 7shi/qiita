---
coediting: false
comments_count: 0
created_at: '2016-05-14T01:54:03+09:00'
id: 39a9ddffcc5bdf2c0142
likes_count: 15
private: false
reactions_count: 0
stocks_count: 12
tags:
- name: Java
  versions: []
title: Java パーサコンビネータ 超入門 2
updated_at: '2016-12-27T02:33:34+09:00'
url: https://qiita.com/7shi/items/39a9ddffcc5bdf2c0142
slide: false
---

Java 8で作った簡単なパーサコンビネータを使って四則演算器を作成します。

この記事は次の続編です。

* [Java パーサコンビネータ 超入門](http://qiita.com/7shi/items/68228e19552c271bea81) 2016.05.12

この記事は再帰下降構文解析の知識を前提とします。詳細は次の記事を参照してください。

* [Java 再帰下降構文解析 超入門](http://qiita.com/7shi/items/64261a67081d49f941e3) 2016.05.16

この記事はHaskellの記事をJavaで書き直したものです。

* [Haskell 構文解析 超入門](http://qiita.com/7shi/items/b8c741e78a96ea2c10fe) 2015.07.31

この記事にはC++版があります。

* [C++11 パーサコンビネータ 超入門](http://qiita.com/7shi/items/6a12160276a8db358e34) 2015.11.27
* [C++11 パーサコンビネータ 超入門 2](http://qiita.com/7shi/items/f86f2f7ad68cfff1b399) 2015.11.30

この記事には関連記事があります。

* [JSONパーサーを作る](http://qiita.com/7shi/items/04c2991239894687ef2f) 2016.12.26

この記事を書くための実験用リポジトリです。記事化に際してコードに手を加えたため一部異なる場合があります。

* https://bitbucket.org/7shi/jmyparsec

# 四則演算器

パーサコンビネータの練習として、簡単な四則演算器を作ります。文字列で式を与えれば、計算して答えを返します。

例: `"1+2*3"` → `7`

前回作ったパーサコンビネータを改造しながら進めます。

* [前回までの jmyparsec](https://bitbucket.org/7shi/jmyparsec/src/e106ff602890e230ff5e002e06e3da7dcb87c862/src/jmyparsec/?at=default)

## 数字

数字を読み込むパーサを実装します。最低でも1文字は必要なため`many`（0回以上の繰り返し）ではなく`many1`（1回以上の繰り返し）を実装します。

```java:jmyparsec/Parsers.java（追加）
    public static final Parser<String> many1(Parser p) {
        return sequence(p, many(p));
    }
```

これを使って数字を読み込みます。

```java
import jmyparsec.*;
import static jmyparsec.Parsers.*;

public class Test {

    static final Parser<String> number = many1(digit);

    public static void main(String[] args) {
        parseTest(number, "123");
    }
}
```
```text:実行結果
123
```

### 数値

結果を数値で返すように修正します。

```java
import jmyparsec.*;
import static jmyparsec.Parsers.*;

public class Test {

    static final Parser<Integer> number = s -> {  // 修正
        return Integer.parseInt(many1(digit).parse(s));
    };

    public static void main(String[] args) {
        parseTest(number, "123");
    }
}
```
```text:実行結果
123
```

このようにパーサは文字以外を返すように構成できます。

## 足し算

足し算を計算するパーサを実装します。演算の対象（オペランド）が2つあるため、リストを使います。

結果を確認するため配列とリストの文字列化を実装します。

差分を示します。

```diff
--- jmyparsec/Parser.java
+++ jmyparsec/Parser.java
@@ -1,10 +1,33 @@
 package jmyparsec;
 
+import java.lang.reflect.Array;
+import java.util.List;
+
 @FunctionalInterface
 public interface Parser<T> {
 
     T parse(Source s) throws Exception;
 
+    default String parseToString(Source s) throws Exception {
+        return toString(parse(s));
+    }
+
+    static String toString(Object obj) {
+        if (obj.getClass().isArray()) {
+            StringBuilder sb = new StringBuilder();
+            int len = Array.getLength(obj);
+            for (int i = 0; i < len; ++i) {
+                sb.append(i == 0 ? "[" : ",");
+                sb.append(toString(Array.get(obj, i)));
+            }
+            sb.append("]");
+            return sb.toString();
+        } else if (obj instanceof List) {
+            return toString(((List) obj).toArray());
+        }
+        return obj.toString();
+    }
+
     default Parser<T> or(Parser<T> p) {
         return s -> {
             T ret;
```
```diff
--- jmyparsec/Parsers.java
+++ jmyparsec/Parsers.java
@@ -4,10 +4,10 @@
 
 public class Parsers {
 
-    public static void parseTest(Parser p, String src) {
+    public static final <T> void parseTest(Parser<T> p, String src) {
         Source s = new Source(src);
         try {
-            System.out.println(p.parse(s));
+            System.out.println(p.parseToString(s));
         } catch (Exception e) {
             System.out.println(e.getMessage());
         }
```

* [修正後の jmyparsec](https://bitbucket.org/7shi/jmyparsec/src/fb79bd4b1f6b661ea17fe0ab1505ccb0f764ff0e/src/jmyparsec/?at=default)

`'+'`で区切って項を個別に取り出します。

```java
import java.util.Arrays;
import java.util.List;
import jmyparsec.*;
import static jmyparsec.Parsers.*;

public class Test {

    static final Parser<Integer> number = s -> {
        return Integer.parseInt(many1(digit).parse(s));
    };

    static final Parser<List<Integer>> expr = s -> {  // 追加
        int x = number.parse(s);
        char1('+').parse(s);
        int y = number.parse(s);
        return Arrays.asList(x, y);
    };

    public static void main(String[] args) {
        parseTest(number, "123");
        parseTest(expr  , "1+2");  // 追加
    }
}
```
```text:実行結果
123
[1,2]
```

### many

`+数値`を`many`により0回以上の繰り返しとして扱います。

`many`などが文字列に特化した実装となっているので、リストを返すことで汎用化します。

差分を示します。

```diff
--- jmyparsec/Parser.java
+++ jmyparsec/Parser.java
@@ -12,15 +12,32 @@
         return toString(parse(s));
     }
 
+    static boolean isCharOrString(Object obj) {
+        int len = Array.getLength(obj);
+        for (int i = 0; i < len; ++i) {
+            Object o = Array.get(obj, i);
+            if (!(o instanceof Character || o instanceof String)) {
+                return false;
+            }
+        }
+        return true;
+    }
+
     static String toString(Object obj) {
         if (obj.getClass().isArray()) {
+            int len = Array.getLength(obj);
             StringBuilder sb = new StringBuilder();
-            int len = Array.getLength(obj);
-            for (int i = 0; i < len; ++i) {
-                sb.append(i == 0 ? "[" : ",");
-                sb.append(toString(Array.get(obj, i)));
+            if (isCharOrString(obj)) {
+                for (int i = 0; i < len; ++i) {
+                    sb.append(Array.get(obj, i));
+                }
+            } else {
+                for (int i = 0; i < len; ++i) {
+                    sb.append(i == 0 ? "[" : ",");
+                    sb.append(toString(Array.get(obj, i)));
+                }
+                sb.append("]");
             }
-            sb.append("]");
             return sb.toString();
         } else if (obj instanceof List) {
             return toString(((List) obj).toArray());
```
```diff
--- jmyparsec/Parsers.java
+++ jmyparsec/Parsers.java
@@ -1,5 +1,7 @@
 package jmyparsec;
 
+import java.util.ArrayList;
+import java.util.List;
 import java.util.function.Function;
 
 public class Parsers {
@@ -51,31 +53,36 @@
         };
     }
 
-    public static final Parser<String> replicate(int n, Parser p) {
+    public static final <T> Parser<List<T>> replicate(int n, Parser<T> p) {
         return s -> {
-            StringBuilder sb = new StringBuilder();
+            List<T> list = new ArrayList<>();
             for (int i = 0; i < n; ++i) {
-                sb.append(p.parse(s));
+                list.add(p.parse(s));
             }
-            return sb.toString();
+            return list;
         };
     }
 
-    public static final Parser<String> many(Parser p) {
+    public static final <T> Parser<List<T>> many(Parser<T> p) {
         return s -> {
-            StringBuilder sb = new StringBuilder();
+            List<T> list = new ArrayList<>();
             try {
                 for (;;) {
-                    sb.append(p.parse(s));
+                    list.add(p.parse(s));
                 }
             } catch (Exception e) {
             }
-            return sb.toString();
+            return list;
         };
     }
 
-    public static final Parser<String> many1(Parser p) {
-        return sequence(p, many(p));
+    public static final <T> Parser<List<T>> many1(Parser<T> p) {
+        return s -> {
+            T first = p.parse(s);
+            List<T> ret = many(p).parse(s);
+            ret.add(0, first);
+            return ret;
+        };
     }
 
     public static final <T> Parser<T> or(Parser<T> p1, Parser<T> p2) {
```

* [修正後の jmyparsec](https://bitbucket.org/7shi/jmyparsec/src/0bcfcee7529cfbc8f7249ab17d39518f0c79e602/src/jmyparsec/?at=default)

`many`に渡すパーサはコードで定義するため、型を明示したラムダ式を使います。

```java
import java.util.List;
import jmyparsec.*;
import static jmyparsec.Parsers.*;

public class Test {

    static final Parser<Integer> number = s -> {
        return Integer.parseInt(many1(digit).parseToString(s));
    };

    static final Parser<List<Integer>> expr = s -> {
        int x = number.parse(s);
        List<Integer> xs = many(ss -> {
            char1('+').parse(ss);
            return number.parse(ss);
        }).parse(s);
        xs.add(0, x);  // 連結
        return xs;
    };

    public static void main(String[] args) {
        parseTest(number, "123"  );
        parseTest(expr  , "1+2"  );  // '+'が1個
        parseTest(expr  , "123"  );  // '+'が0個
        parseTest(expr  , "1+2+3");  // '+'が2個
    }
}
```
```text:実行結果
123
[1,2]
[123]
[1,2,3]
```

## 結果を選択する演算子

コードを整理するのに便利なメソッドチェイン型のコンビネータを導入します。

`sequence(a, b)`は`a`と`b`の結果を結合して返しますが、いずれか片方だけを返す演算子を考えます。

* `a.prev(b)`: `a`と`b`を処理した後、戻り値として`a`の結果を返します。
* `a.next(b)`: `a`と`b`を処理した後、戻り値として`b`の結果を返します。

`prev`（前）と`next`（次）は戻り値として返すパーサを指定していると解釈できます。どちらも処理順は`a`→`b`です。

実装を示します。

```java:jmyparsec/Parser.java（追加）
    default Parser<T> prev(Parser p) {
        return s -> {
            T ret = parse(s);
            p.parse(s);
            return ret;
        };
    }

    default <TR> Parser<TR> next(Parser<TR> p) {
        return s -> {
            parse(s);
            return p.parse(s);
        };
    }
```

動作を確認します。

```java
import static jmyparsec.Parsers.*;

public class Test {

    public static void main(String[] args) {
        parseTest(sequence(letter, digit), "a1");
        parseTest(letter.prev(digit), "a1");
        parseTest(letter.next(digit), "a1");
    }
}
```
```text:実行結果
a1
a
1
```

### コードの整理

`next`を使えば`many`の引数が簡単になります。

```java
import java.util.List;
import jmyparsec.*;
import static jmyparsec.Parsers.*;

public class Test {

    static final Parser<Integer> number = s -> {
        return Integer.parseInt(many1(digit).parseToString(s));
    };

    static final Parser<List<Integer>> expr = s -> {
        int x = number.parse(s);
        List<Integer> xs = many(char1('+').next(number)).parse(s);  // 簡略化
        xs.add(0, x);
        return xs;
    };

    public static void main(String[] args) {
        parseTest(number, "123"  );
        parseTest(expr  , "1+2"  );
        parseTest(expr  , "123"  );
        parseTest(expr  , "1+2+3");
    }
}
```
```text:実行結果
123
[1,2]
[123]
[1,2,3]
```

ラムダ式で書いていた部分が簡単になっているのに注目してください。

このようにコンビネータでできない処理はとりあえずラムダ式で書いてから、新しいコンビネータを導入して単純化できないかを考えるわけです。この感覚がつかめれば、パーサコンビネータがぐっと身近に感じられるでしょう。

## 計算

リストを合計すれば計算できます。

```java
import java.util.List;
import jmyparsec.*;
import static jmyparsec.Parsers.*;

public class Test {

    static final Parser<Integer> number = s -> {
        return Integer.parseInt(many1(digit).parseToString(s));
    };

    static final Parser<Integer> expr = s -> {  // 戻り値の型 -> Integer
        int x = number.parse(s);
        List<Integer> xs = many(char1('+').next(number)).parse(s);
        return xs.stream().reduce(x, Integer::sum);  // 合計
    };

    public static void main(String[] args) {
        parseTest(number, "123"  );
        parseTest(expr  , "1+2"  );  // OK
        parseTest(expr  , "123"  );  // OK
        parseTest(expr  , "1+2+3");  // OK
    }
}
```
```text:実行結果
123
3
123
6
```

構文解析と計算を分離せずに`expr`で処理しているのがポイントです。

## 引き算

マイナスの項を足すとして処理します。

```java
import java.util.List;
import jmyparsec.*;
import static jmyparsec.Parsers.*;

public class Test {

    static final Parser<Integer> number = s -> {
        return Integer.parseInt(many1(digit).parseToString(s));
    };

    static final Parser<Integer> expr = s -> {
        int x = number.parse(s);
        List<Integer> xs = many(or(            // or
                char1('+').next(number),       // 足し算
                ss -> {                        // 引き算
                    char1('-').parse(ss);
                    return -number.parse(ss);  // マイナスの項
                }
        )).parse(s);
        return xs.stream().reduce(x, Integer::sum);
    };

    public static void main(String[] args) {
        parseTest(number, "123"  );
        parseTest(expr  , "1+2"  );
        parseTest(expr  , "123"  );
        parseTest(expr  , "1+2+3");
        parseTest(expr  , "1-2-3");  // OK
        parseTest(expr  , "1-2+3");  // OK
    }
}
```
```text:実行結果
123
3
123
6
-4
2
```

符号を反転する処理をラムダ式で書いています。これを単純化するコンビネータについて考えてみます。

## 関数適用コンビネータ

パーサが返した値に何らかの処理を加える場合、処理を関数に分離することを考えます。

パーサと関数をつなぐコンビネータ`apply`を実装します。

```java:jmyparsec/Parsers.java（追加）
    public static final <T1, T2> Parser<T1> apply(Function<T2, T1> f, Parser<T2> p) {
        return s -> f.apply(p.parse(s));
    }
```

動作を確認します。

```java
import jmyparsec.*;
import static jmyparsec.Parsers.*;

public class Test {

    public static void main(String[] args) {
        parseTest(                            letter , "a");
        parseTest(apply(ch -> (char)(ch + 1), letter), "a");
    }
}
```
```text:実行結果
a
b
```

2番目は`letter`で取得した文字に1を足して次の文字を返しています。

### 符号反転コンビネータ

`apply`を使って符号反転コンビネータを実装します。

```java:jmyparsec/Parsers.java（追加）
    public static final Parser<Integer> neg(Parser<Integer> p) {
        return apply(x -> -x, p);
    }
```

これを使って演算器を書き換えます。

```java
import java.util.List;
import jmyparsec.*;
import static jmyparsec.Parsers.*;

public class Test {

    static final Parser<Integer> number = s -> {
        return Integer.parseInt(many1(digit).parseToString(s));
    };

    static final Parser<Integer> expr = s -> {
        int x = number.parse(s);
        List<Integer> xs = many(or(
                char1('+').next(    number ),
                char1('-').next(neg(number))  // 適用
        )).parse(s);
        return xs.stream().reduce(x, Integer::sum);
    };

    public static void main(String[] args) {
        parseTest(number, "123"  );
        parseTest(expr  , "1+2"  );
        parseTest(expr  , "123"  );
        parseTest(expr  , "1+2+3");
        parseTest(expr  , "1-2-3");  // OK
        parseTest(expr  , "1-2+3");  // OK
    }
}
```
```text:実行結果
123
3
123
6
-4
2
```

複雑な部分はコンビネータに押し込んだので、それを使うコードがシンプルになりました。

### 整数化

`number`も`apply`で書き換えてみます。

```java
import java.util.List;
import java.util.function.Function;  // 追加
import jmyparsec.*;
import static jmyparsec.Parsers.*;

public class Test {

    static final Function<List<Character>, Integer> toInt              // 追加
            = s -> Integer.parseInt(Parser.toString(s));

    static final Parser<Integer> number = apply(toInt, many1(digit));  // 適用

    static final Parser<Integer> expr = s -> {
        int x = number.parse(s);
        List<Integer> xs = many(or(
                char1('+').next(    number ),
                char1('-').next(neg(number))
        )).parse(s);
        return xs.stream().reduce(x, Integer::sum);
    };

    public static void main(String[] args) {
        parseTest(number, "123"  );
        parseTest(expr  , "1+2"  );
        parseTest(expr  , "123"  );
        parseTest(expr  , "1+2+3");
        parseTest(expr  , "1-2-3");
        parseTest(expr  , "1-2+3");
    }
}
```
```text:実行結果
123
3
123
6
-4
2
```

分かりやすくなったかは微妙ですが、とりあえずこのまま進めます。

## 四則演算

四則演算のパーサを並べるため、`or`を可変長引数とします。

※ 可変長引数では型が未チェックだと警告されますが、対応は見送ります。

```java:jmyparsec/Parsers.java（変更）
    public static final <T> Parser<T> or(Parser<T>... ps) {
        return s -> {
            Exception ex = new Exception("empty or");
            for (Parser<T> p : ps) {
                try {
                    return p.parse(s);
                } catch (Exception e) {
                    ex = e;
                }
            }
            throw ex;
        };
    }
```

掛け算や割り算は合計では処理できないため、`many`でクロージャのリストを返して、後でまとめて計算します。

```java
import java.util.List;
import java.util.function.Function;
import jmyparsec.*;
import static jmyparsec.Parsers.*;

public class Test {

    static final Function<List<Character>, Integer> toInt
            = s -> Integer.parseInt(Parser.toString(s));

    static final Parser<Integer> number = apply(toInt, many1(digit));

    static final <T> T accumulate(T x, List<Function<T, T>> fs) {  // 追加
        for (Function<T, T> f : fs) {
            x = f.apply(x);
        }
        return x;
    }

    static final Parser<Integer> expr = s -> {
        int x = number.parse(s);
        Parser<List<Function<Integer, Integer>>> fs = many(or(
            ss -> {
                char1('+').parse(ss);
                int y = number.parse(ss);   // キャプチャされる変数
                return z -> z + y;          // クロージャを返す
            }, ss -> {
                char1('-').parse(ss);
                int y = number.parse(ss);   // キャプチャされる変数
                return z -> z - y;          // クロージャを返す
            }, ss -> {                      // 追加: 掛け算
                char1('*').parse(ss);
                int y = number.parse(ss);   // キャプチャされる変数
                return z -> z * y;          // クロージャを返す
            }, ss -> {                      // 追加: 割り算
                char1('/').parse(ss);
                int y = number.parse(ss);   // キャプチャされる変数
                return z -> z / y;          // クロージャを返す
            }
        ));
        return accumulate(x, fs.parse(s));  // まとめて計算
    };

    public static void main(String[] args) {
        parseTest(number, "123"     );
        parseTest(expr  , "1+2"     );
        parseTest(expr  , "123"     );
        parseTest(expr  , "1+2+3"   );
        parseTest(expr  , "1-2-3"   );
        parseTest(expr  , "1-2+3"   );
        parseTest(expr  , "2*3+4"   );  // OK
        parseTest(expr  , "2+3*4"   );  // NG
        parseTest(expr  , "100/10/2");  // OK
    }
}
```
```text:実行結果
123
3
123
6
-4
2
10
20
5
```

演算子の優先順位が処理できていません。

### 演算子の優先順位

足し算から見ると、1つの数字と掛け算のブロックは項（term）として対等です。数式で例えると $2x+1$ において $2x$ と $1$ が項という単位として $+$ から並列に扱われていることに相当します。

項単位で計算するように分離すれば演算子の優先順位が表現できます。

```java
import java.util.List;
import java.util.function.Function;
import jmyparsec.*;
import static jmyparsec.Parsers.*;

public class Test {

    static final Function<List<Character>, Integer> toInt
            = s -> Integer.parseInt(Parser.toString(s));

    static final Parser<Integer> number = apply(toInt, many1(digit));

    static final <T> T accumulate(T x, List<Function<T, T>> fs) {
        for (Function<T, T> f : fs) {
            x = f.apply(x);
        }
        return x;
    }

    static final Parser<Integer> term = s -> {  // 項の計算、exprと同じ構造
        int x = number.parse(s);
        Parser<List<Function<Integer, Integer>>> fs = many(or(
            ss -> {
                char1('*').parse(ss);
                int y = number.parse(ss);
                return z -> z * y;
            }, ss -> {
                char1('/').parse(ss);
                int y = number.parse(ss);
                return z -> z / y;
            }
        ));
        return accumulate(x, fs.parse(s));
    };

    static final Parser<Integer> expr = s -> {
        int x = term.parse(s);           // 項を取得
        Parser<List<Function<Integer, Integer>>> fs = many(or(
            ss -> {
                char1('+').parse(ss);
                int y = term.parse(ss);  // 項を取得
                return z -> z + y;
            }, ss -> {
                char1('-').parse(ss);
                int y = term.parse(ss);  // 項を取得
                return z -> z - y;
            }
        ));
        return accumulate(x, fs.parse(s));
    };

    public static void main(String[] args) {
        parseTest(number, "123"     );
        parseTest(expr  , "1+2"     );
        parseTest(expr  , "123"     );
        parseTest(expr  , "1+2+3"   );
        parseTest(expr  , "1-2-3"   );
        parseTest(expr  , "1-2+3"   );
        parseTest(expr  , "2*3+4"   );
        parseTest(expr  , "2+3*4"   );  // OK
        parseTest(expr  , "100/10/2");
    }
}
```
```text:実行結果
123
3
123
6
-4
2
10
14
5
```

演算子の優先順位が処理されるようになりました。

## 整理

記述が複雑なため、今まで定義した演算子を駆使して整理を試みます。

### 2引数の関数適用

個別の演算でクロージャを返している部分が冗長です。`+`を例に考えます。

```java:抜粋
            ss -> {
                char1('+').parse(ss);
                int y = term.parse(ss);  // 項を取得
                return z -> z + y;
            }
```

`y`に読み取った項を代入して、次の行のクロージャでキャプチャしています。キャプチャした変数は引数を畳み込んでいると見なせるため、本質的には2引数のラムダ式です。

※ 引数を畳み込んで引数を減らした新しい関数を生成することを部分適用と呼びます。詳細は次の記事を参照してください。

* [カリー化と部分適用（JavaScriptとHaskell）](http://qiita.com/7shi/items/a0143daac77a205e7962) 2014.10.15

`apply`にオーバーロードを追加して、2引数の関数を渡して第1引数をキャプチャした1引数のクロージャを返します。

```java:jmyparsec/Parsers.java（追加）
import java.util.function.BiFunction;
```
```java:jmyparsec/Parsers.java（追加）
    public static final <T1, T2, T3> Parser<Function<T3, T1>> apply(BiFunction<T2, T3, T1> f, Parser<T2> p) {
        return s -> {
            T2 x = p.parse(s);
            return y -> f.apply(x, y);
        };
    }
```

これを使って書き直します。

```java
import java.util.List;
import java.util.function.Function;
import jmyparsec.*;
import static jmyparsec.Parsers.*;

public class Test {

    static final Function<List<Character>, Integer> toInt
            = s -> Integer.parseInt(Parser.toString(s));

    static final Parser<Integer> number = apply(toInt, many1(digit));

    static final <T> T accumulate(T x, List<Function<T, T>> fs) {
        for (Function<T, T> f : fs) {
            x = f.apply(x);
        }
        return x;
    }

    static final Parser<Integer> term = s -> {
        int x = number.parse(s);
        Parser<List<Function<Integer, Integer>>> fs = many(or(
            ss -> {
                char1('*').parse(ss);
                return apply((y, z) -> z * y, number).parse(ss);  // 適用
            }, ss -> {
                char1('/').parse(ss);
                return apply((y, z) -> z / y, number).parse(ss);  // 適用
            }
        ));
        return accumulate(x, fs.parse(s));
    };

    static final Parser<Integer> expr = s -> {
        int x = term.parse(s);           // 項を取得
        Parser<List<Function<Integer, Integer>>> fs = many(or(
            ss -> {
                char1('+').parse(ss);
                return apply((y, z) -> z + y, term).parse(ss);    // 適用
            }, ss -> {
                char1('-').parse(ss);
                return apply((y, z) -> z - y, term).parse(ss);    // 適用
            }
        ));
        return accumulate(x, fs.parse(s));
    };

    public static void main(String[] args) {
        parseTest(number, "123"     );
        parseTest(expr  , "1+2"     );
        parseTest(expr  , "123"     );
        parseTest(expr  , "1+2+3"   );
        parseTest(expr  , "1-2-3"   );
        parseTest(expr  , "1-2+3"   );
        parseTest(expr  , "2*3+4"   );
        parseTest(expr  , "2+3*4"   );
        parseTest(expr  , "100/10/2");
    }
}
```
```text:実行結果
123
3
123
6
-4
2
10
14
5
```

パーサを連続させる形に持ち込めました。

### 非ラムダ式化

コンビネータ`next`を使えばラムダ式がなくなります。

```java
import java.util.List;
import java.util.function.Function;
import jmyparsec.*;
import static jmyparsec.Parsers.*;

public class Test {

    static final Function<List<Character>, Integer> toInt
            = s -> Integer.parseInt(Parser.toString(s));

    static final Parser<Integer> number = apply(toInt, many1(digit));

    static final <T> T accumulate(T x, List<Function<T, T>> fs) {
        for (Function<T, T> f : fs) {
            x = f.apply(x);
        }
        return x;
    }

    static final Parser<Integer> term = s -> {
        int x = number.parse(s);
        Parser<List<Function<Integer, Integer>>> fs = many(or(
            char1('*').next(apply((y, z) -> z * y, number)),  // 修正
            char1('/').next(apply((y, z) -> z / y, number))   // 修正
        ));
        return accumulate(x, fs.parse(s));
    };

    static final Parser<Integer> expr = s -> {
        int x = term.parse(s);           // 項を取得
        Parser<List<Function<Integer, Integer>>> fs = many(or(
            char1('+').next(apply((y, z) -> z + y, term)),    // 修正
            char1('-').next(apply((y, z) -> z - y, term))     // 修正
        ));
        return accumulate(x, fs.parse(s));
    };

    public static void main(String[] args) {
        parseTest(number, "123"     );
        parseTest(expr  , "1+2"     );
        parseTest(expr  , "123"     );
        parseTest(expr  , "1+2+3"   );
        parseTest(expr  , "1-2-3"   );
        parseTest(expr  , "1-2+3"   );
        parseTest(expr  , "2*3+4"   );
        parseTest(expr  , "2+3*4"   );
        parseTest(expr  , "100/10/2");
    }
}
```
```text:実行結果
123
3
123
6
-4
2
10
14
5
```

かなり簡潔になりました。しかしまだ重複する記述が残っています。

### 共通部分の関数化

値を評価する部分が`term`と`expr`で同じなので関数化します。

```java
import java.util.List;
import java.util.function.Function;
import jmyparsec.*;
import static jmyparsec.Parsers.*;

public class Test {

    static final Function<List<Character>, Integer> toInt
            = s -> Integer.parseInt(Parser.toString(s));

    static final Parser<Integer> number = apply(toInt, many1(digit));

    static final <T> T accumulate(T x, List<Function<T, T>> fs) {
        for (Function<T, T> f : fs) {
            x = f.apply(x);
        }
        return x;
    }
    
    static final <T> Parser<T> eval(Parser<T> m, Parser<List<Function<T, T>>> fs) {
        return s -> {
            T x = m.parse(s);
            return accumulate(x, fs.parse(s));
        };
    }

    static final Parser<Integer> term = Test.<Integer>eval(number, many(or(
            char1('*').next(apply((y, z) -> z * y, number)),
            char1('/').next(apply((y, z) -> z / y, number))
    )));

    static final Parser<Integer> expr = Test.<Integer>eval(term, many(or(
            char1('+').next(apply((y, z) -> z + y, term)),
            char1('-').next(apply((y, z) -> z - y, term))
    )));

    public static void main(String[] args) {
        parseTest(number, "123"     );
        parseTest(expr  , "1+2"     );
        parseTest(expr  , "123"     );
        parseTest(expr  , "1+2+3"   );
        parseTest(expr  , "1-2-3"   );
        parseTest(expr  , "1-2+3"   );
        parseTest(expr  , "2*3+4"   );
        parseTest(expr  , "2+3*4"   );
        parseTest(expr  , "100/10/2");
    }
}
```
```text:実行結果
123
3
123
6
-4
2
10
14
5
```

※ `eval`に対して型推論し切れないため、明示的に型引数を指定しています。

面倒な部分は`eval`と`apply`に押し付けることで、`term`と`expr`は簡潔で形式的な記述になりました。いきなりこのコードを見ても形式的過ぎて理解しにくいかもしれませんが、コードの変形過程を追ってみてください。

## BNF

ここまで実装したような処理はBNF（[バッカス・ナウア記法](https://ja.wikipedia.org/wiki/%E3%83%90%E3%83%83%E3%82%AB%E3%82%B9%E3%83%BB%E3%83%8A%E3%82%A6%E3%82%A2%E8%A8%98%E6%B3%95)）と呼ばれる形式言語で記述できます。

拡張版の[EBNF](https://ja.wikipedia.org/wiki/EBNF)で示します。

```text:EBNF
term = number, {"*"|"/", number}
expr = term  , {"+"|"-", term  }
```

今回のコードに合わせてEBNFを変形するため、演算子それぞれに処理を記述します。

```text:EBNF
term = number, {("*", number) | ("/", number)}
expr = term  , {("+", term  ) | ("-", term  )}
```

### 比較

コードにコメントとして追記するので比較してください。慣れて来れば、先にBNFで定義してからコードを書いた方が効率的だと感じるでしょう。

```hs:比較
    // term = number, {("*", number) | ("/", number)}
    static final Parser<Integer> term = Test.<Integer>eval(number, many(or(
            char1('*').next(apply((y, z) -> z * y, number)),
            char1('/').next(apply((y, z) -> z / y, number))
    )));

    // expr = term, {("+", term) | ("-", term)}
    static final Parser<Integer> expr = Test.<Integer>eval(term, many(or(
            char1('+').next(apply((y, z) -> z + y, term)),
            char1('-').next(apply((y, z) -> z - y, term))
    )));
```

このコードはなるべくBNFに近付けるよう意識しています。このような使い方は[ドメイン固有言語](https://ja.wikipedia.org/wiki/%E3%83%89%E3%83%A1%E3%82%A4%E3%83%B3%E5%9B%BA%E6%9C%89%E8%A8%80%E8%AA%9E)（DSL）に見立てられます。

## 括弧

括弧をサポートため、項の下位に因子（factor）という層を追加します。

括弧の中は`expr`のため次のように再帰が循環します。

* `expr` → `term` → `factor` → `expr` → ...

フィールドで定義するインスタンスは記述順に初期化されるため、前方参照が不正となります。相互再帰ではどこかで必ず前方参照が必要となります。

無名クラスからは実行時に参照されることを利用してダミーのラッパーを用意します。ダミーの方を他から使うため、実体の方を名前変更します。

※ ラムダ式では前方参照ができないため、無名クラスである必要があります。

```java
import java.util.List;
import java.util.function.Function;
import jmyparsec.*;
import static jmyparsec.Parsers.*;

public class Test {

    static final Function<List<Character>, Integer> toInt
            = s -> Integer.parseInt(Parser.toString(s));

    static final Parser<Integer> number = apply(toInt, many1(digit));

    static final <T> T accumulate(T x, List<Function<T, T>> fs) {
        for (Function<T, T> f : fs) {
            x = f.apply(x);
        }
        return x;
    }
    
    static final <T> Parser<T> eval(Parser<T> m, Parser<List<Function<T, T>>> fs) {
        return s -> {
            T x = m.parse(s);
            return accumulate(x, fs.parse(s));
        };
    }

    // ダミーのラッパー
    static final Parser<Integer> factor = new Parser<Integer>() {
        @Override
        public Integer parse(Source s) throws Exception {
            return factor_.parse(s);
        }
    };

    // term = factor, {("*", factor) | ("/", factor)}
    static final Parser<Integer> term = Test.<Integer>eval(factor, many(or(
            char1('*').next(apply((y, z) -> z * y, factor)),
            char1('/').next(apply((y, z) -> z / y, factor))
    )));

    // expr = term, {("+", term) | ("-", term)}
    static final Parser<Integer> expr = Test.<Integer>eval(term, many(or(
            char1('+').next(apply((y, z) -> z + y, term)),
            char1('-').next(apply((y, z) -> z - y, term))
    )));

    // factor = ("(", expr, ")") | number
    static final Parser<Integer> factor_  // 実体
            = or(char1('(').next(expr).prev(char1(')')), number);

    public static void main(String[] args) {
        parseTest(number, "123"     );
        parseTest(expr  , "1+2"     );
        parseTest(expr  , "123"     );
        parseTest(expr  , "1+2+3"   );
        parseTest(expr  , "1-2-3"   );
        parseTest(expr  , "1-2+3"   );
        parseTest(expr  , "2*3+4"   );
        parseTest(expr  , "2+3*4"   );
        parseTest(expr  , "100/10/2");
        parseTest(expr  , "(2+3)*4" );  // OK
    }
}
```
```text:実行結果
123
3
123
6
-4
2
10
14
5
20
```

式を循環参照させる部分が難しいですが、テクニックとして割り切るしかありません。

## スペース

式にスペースが入っていても評価できるようにします。

スペース関係のパーサを汎用部品として追加します。

```java:jmyparsec/Parsers.java（追加）
    public static final boolean isSpace(char ch) {
        return ch == '\t' || ch == ' ';
    }
    public static final Parser<Character> space = satisfy(Parsers::isSpace).left("not space");
    public static final Parser<List<Character>> spaces = many(space);
```

`factor`を修正します。

```java:修正
    // factor = factor = [spaces], ("(", expr, ")") | number, [spaces]
    static final Parser<Integer> factor_ = spaces.next(
            or(char1('(').next(expr).prev(char1(')')), number)
    ).prev(spaces);
```

次のようなテストが動くようになります。

```java
    public static void main(String[] args) {
        parseTest(number, "123"          );
        parseTest(expr  , "1 + 2"        );
        parseTest(expr  , "123"          );
        parseTest(expr  , "1 + 2 + 3"    );
        parseTest(expr  , "1 - 2 - 3"    );
        parseTest(expr  , "1 - 2 + 3"    );
        parseTest(expr  , "2 * 3 + 4"    );
        parseTest(expr  , "2 + 3 * 4"    );
        parseTest(expr  , "100 / 10 / 2" );
        parseTest(expr  , "( 2 + 3 ) * 4");
    }
```
```text:実行結果
123
3
123
6
-4
2
10
14
5
20
```

以上で四則演算器の実装は完了です。

* [ここまでのコード全体](https://bitbucket.org/7shi/jmyparsec/src/58bacd7bde00cbc55bebcf1a6c6de59b5f6b81ab/src/?at=default)

パーサコンビネータによるプログラミングが何となく見えて来ればしめたものです。
