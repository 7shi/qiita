---
coediting: false
comments_count: 0
created_at: '2015-11-30T18:20:02+09:00'
id: f86f2f7ad68cfff1b399
likes_count: 15
private: false
reactions_count: 0
stocks_count: 12
tags:
- name: C++11
  versions: []
title: C++11 パーサコンビネータ 超入門 2
updated_at: '2016-12-27T02:35:23+09:00'
url: https://qiita.com/7shi/items/f86f2f7ad68cfff1b399
slide: false
---

C++11で作った簡単なパーサコンビネータを使って四則演算器を作成します。

この記事は次の続編です。

* [C++11 パーサコンビネータ 超入門](http://qiita.com/7shi/items/6a12160276a8db358e34) 2015.11.27

この記事はHaskellの記事をC++11で書き直したものです。

* [Haskell 構文解析 超入門](http://qiita.com/7shi/items/b8c741e78a96ea2c10fe) 2015.07.31

この記事にはJava版があります。

* [Java パーサコンビネータ 超入門](http://qiita.com/7shi/items/68228e19552c271bea81) 2016.05.12
* [Java パーサコンビネータ 超入門 2](http://qiita.com/7shi/items/39a9ddffcc5bdf2c0142) 2016.05.14

この記事には関連記事があります。

* [JSONパーサーを作る](http://qiita.com/7shi/items/04c2991239894687ef2f) 2016.12.26

この記事を書くための実験用リポジトリです。記事化に際してコードに手を加えたため一部異なる場合があります。

* https://bitbucket.org/7shi/parsecpp

# 四則演算器

パーサコンビネータの練習として、簡単な四則演算器を作ります。文字列で式を与えると計算して答えを返します。

例: `"1+2*3"` → `7`

前回作ったパーサコンビネータを改造しながら進めます。

* [前回までの parsecpp.cpp](https://bitbucket.org/snippets/7shi/o9dep/revisions/4282afab8b71b96924335c39f8433358ec9c33a4)

## 数字

数字を読み込むパーサを実装します。最低でも1文字は必要なため`many`（0回以上の繰り返し）ではなく`many1`（1回以上の繰り返し）を実装します。

```cpp:parsecpp.cpp（追加）
template <typename T>
Parser<std::string> many1(const Parser<T> &p) {
    return p + many(p);
}
```

これを使って数字を読み込みます。

```cpp
#include "parsecpp.cpp"

auto number = many1(digit);

int main() {
    parseTest(number, "123");
}
```
```text:実行結果
123
```

### 数値

結果を数値で返すように修正します。

```cpp
#include "parsecpp.cpp"

int toInt(const std::string &s) {  // 追加
    int ret;
    std::istringstream(s) >> ret;
    return ret;
}

Parser<int> number = [](Source *s) {  // 修正
    return toInt(many1(digit)(s));
};

int main() {
    parseTest(number, "123");
}
```
```text:実行結果
123
```

このようにパーサは文字以外を返すように構成できます。

## 足し算

足し算を計算するパーサを実装します。演算の対象（オペランド）が2つあるため、リストを使います。

結果を確認するためリストの表示を実装します。

```cpp:parsecpp.cpp（追加）
#include <list>

template <typename T>
std::string toString(const std::list<T> &list) {
    std::stringstream ss;
    ss << "[";
    for (auto it = list.begin();
            it != list.end(); ++it) {
        if (it != list.begin()) ss << ",";
        ss << *it;
    }
    ss << "]";
    return ss.str();
}
template <typename T>
std::ostream &operator<<(std::ostream &cout, const std::list<T> &list) {
    return cout << toString(list);
}
```

`'+'`で区切って項を個別に取り出します。

```cpp
#include "parsecpp.cpp"

int toInt(const std::string &s) {
    int ret;
    std::istringstream(s) >> ret;
    return ret;
}

Parser<int> number = [](Source *s) {
    return toInt(many1(digit)(s));
};

Parser<std::list<int>> expr = [](Source *s) {  // 追加
    int x = number(s);
    char1('+')(s);
    int y = number(s);
    return std::list<int>({x, y});
};

int main() {
    parseTest(number, "123");
    parseTest(expr  , "1+2");  // 追加
}
```
```text:実行結果
123
[1,2]
```

### many

`+数値`を`many`により0回以上の繰り返しとして扱います。

`many`が文字列に特化した実装となっているため、多相化した上で特殊化します。

差分を示します。

```diff
--- parsecpp.cpp.orig
+++ parsecpp.cpp
@@ -104,7 +104,7 @@
 }
 
 template <typename T>
-Parser<std::string> many(const Parser<T> &p) {
+Parser<std::string> many_(const Parser<T> &p) {
     return [=](Source *s) {
         std::string ret;
         try {
@@ -112,6 +112,22 @@
         } catch (const std::string &) {}
         return ret;
     };
+}
+Parser<std::string> many(const Parser<char> &p) {
+    return many_(p);
+}
+Parser<std::string> many(const Parser<std::string> &p) {
+    return many_(p);
+}
+template <typename T>
+Parser<std::list<T>> many(const Parser<T> &p) {
+    return [=](Source *s) {
+        std::list<T> ret;
+        try {
+            for (;;) ret.push_back(p(s));
+        } catch (const std::string &) {}
+        return ret;
+    };
 }
 
 template <typename T>
```

* [修正後の parsecpp.cpp](https://bitbucket.org/snippets/7shi/o9dep/revisions/924196829e5f08614272b1982ec88a81b6014eac)

`many`に渡すパーサはコードで定義するため、型を明示したラムダ式を使います。

```cpp
#include "parsecpp.cpp"

int toInt(const std::string &s) {
    int ret;
    std::istringstream(s) >> ret;
    return ret;
}

Parser<int> number = [](Source *s) {
    return toInt(many1(digit)(s));
};

Parser<std::list<int>> expr = [](Source *s) {
    int x = number(s);
    auto xs = many(Parser<int>([](Source *s) {  // 繰り返し
        char1('+')(s);
        return number(s);
    }))(s);
    xs.push_front(x);  // 連結
    return xs;
};

int main() {
    parseTest(number, "123"  );
    parseTest(expr  , "1+2"  );  // '+'が1個
    parseTest(expr  , "123"  );  // '+'が0個
    parseTest(expr  , "1+2+3");  // '+'が2個
}
```
```text:実行結果
123
[1,2]
[123]
[1,2,3]
```

## 結果を選択する演算子

コードを整理するのに便利な演算子を導入します。

`a + b`は`a`と`b`の結果を結合して返しますが、いずれか片方だけを返す演算子を考えます。

* `a << b`: `a`と`b`を処理した後、戻り値として`a`の結果を返します。
* `a >> b`: `a`と`b`を処理した後、戻り値として`b`の結果を返します。

それぞれ不等号を矢印に見立てると、返す値を指示していると解釈できます。処理の順番を記号化したわけではなく、どちらも処理順は`a`→`b`です。

実装を示します。

```cpp:parsecpp.cpp（追加）
template <typename T1, typename T2>
Parser<T1> operator<<(const Parser<T1> &p1, const Parser<T2> &p2) {
    return [=](Source *s) {
        T1 ret = p1(s);
        p2(s);
        return ret;
    };
}

template <typename T1, typename T2>
Parser<T2> operator>>(const Parser<T1> &p1, const Parser<T2> &p2) {
    return [=](Source *s) {
        p1(s);
        return p2(s);
    };
}
```

動作を確認します。

```cpp
#include "parsecpp.cpp"

int main() {
    parseTest(letter +  digit, "a1");
    parseTest(letter << digit, "a1");
    parseTest(letter >> digit, "a1");
}
```
```text:実行結果
a1
a
1
```

### コードの整理

演算子`>>`を使えば`many`の引数が簡単になります。

```cpp
#include "parsecpp.cpp"

int toInt(const std::string &s) {
    int ret;
    std::istringstream(s) >> ret;
    return ret;
}

Parser<int> number = [](Source *s) {
    return toInt(many1(digit)(s));
};

Parser<std::list<int>> expr = [](Source *s) {
    int x = number(s);
    auto xs = many(char1('+') >> number)(s); // 簡略化
    xs.push_front(x);
    return xs;
};

int main() {
    parseTest(number, "123"  );
    parseTest(expr  , "1+2"  );
    parseTest(expr  , "123"  );
    parseTest(expr  , "1+2+3");
}
```
```text:実行結果
123
[1,2]
[123]
[1,2,3]
```

ラムダ式で書いていた部分が驚くほど簡単になっているのに注目してください。

このようにコンビネータでできない処理はとりあえずラムダ式で書いてから、新しいコンビネータを導入して単純化できないかを考えるわけです。この感覚がつかめれば、パーサコンビネータがぐっと身近に感じられるでしょう。

## 計算

リストを合計すれば計算できます。

```cpp
#include "parsecpp.cpp"
#include <numeric>  // 追加

int toInt(const std::string &s) {
    int ret;
    std::istringstream(s) >> ret;
    return ret;
}

Parser<int> number = [](Source *s) {
    return toInt(many1(digit)(s));
};

Parser<int> expr = [](Source *s) {  // 戻り値の型 -> int
    int x = number(s);
    auto xs = many(char1('+') >> number)(s);
    return std::accumulate(xs.begin(), xs.end(), x);  // 合計
};

int main() {
    parseTest(number, "123"  );
    parseTest(expr  , "1+2"  );  // OK
    parseTest(expr  , "123"  );  // OK
    parseTest(expr  , "1+2+3");  // OK
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

```cpp
#include "parsecpp.cpp"
#include <numeric>

int toInt(const std::string &s) {
    int ret;
    std::istringstream(s) >> ret;
    return ret;
}

Parser<int> number = [](Source *s) {
    return toInt(many1(digit)(s));
};

Parser<int> expr = [](Source *s) {
    int x = number(s);
    auto xs = many(
           char1('+') >> number
        || Parser<int>([](Source *s) {  // 追加
            char1('-')(s);
            return -number(s);  // マイナスの項
        })
    )(s);
    return std::accumulate(xs.begin(), xs.end(), x);
};

int main() {
    parseTest(number, "123"  );
    parseTest(expr  , "1+2"  );
    parseTest(expr  , "123"  );
    parseTest(expr  , "1+2+3");
    parseTest(expr  , "1-2-3");  // OK
    parseTest(expr  , "1-2+3");  // OK
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

```cpp:parsecpp.cpp（追加）
template <typename T1, typename T2>
Parser<T1> apply(const std::function <T1 (const T2 &)> &f, const Parser<T2> &p) {
    return [=](Source *s) {
        return f(p(s));
    };
}
```

動作を確認します。

```cpp
#include "parsecpp.cpp"

int main() {
    parseTest(                                                  letter , "a");
    parseTest(apply<char, char>([](char ch) { return ch + 1; }, letter), "a");
}
```
```text:実行結果
a
b
```

2番目は`letter`で取得した文字に1を足して次の文字を返しています。

### 符号反転コンビネータ

`apply`を使って符号反転コンビネータを実装します。

```cpp:parsecpp.cpp（追加）
template <typename T>
Parser<T> operator-(const Parser<T> &p) {
    return apply<T, T>([=](T x) { return -x; }, p);
}
```

これを使って演算器を書き換えます。

```cpp
#include "parsecpp.cpp"
#include <numeric>

int toInt(const std::string &s) {
    int ret;
    std::istringstream(s) >> ret;
    return ret;
}

Parser<int> number = [](Source *s) {
    return toInt(many1(digit)(s));
};

Parser<int> expr = [](Source *s) {
    int x = number(s);
    auto xs = many(
           char1('+') >>  number
        || char1('-') >> -number  // 適用
    )(s);
    return std::accumulate(xs.begin(), xs.end(), x);
};

int main() {
    parseTest(number, "123"  );
    parseTest(expr  , "1+2"  );
    parseTest(expr  , "123"  );
    parseTest(expr  , "1+2+3");
    parseTest(expr  , "1-2-3");
    parseTest(expr  , "1-2+3");
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

```cpp
#include "parsecpp.cpp"
#include <numeric>

int toInt(const std::string &s) {
    int ret;
    std::istringstream(s) >> ret;
    return ret;
}

auto number = apply<int, std::string>(toInt, many1(digit));  // 適用

Parser<int> expr = [](Source *s) {
    int x = number(s);
    auto xs = many(
           char1('+') >>  number
        || char1('-') >> -number
    )(s);
    return std::accumulate(xs.begin(), xs.end(), x);
};

int main() {
    parseTest(number, "123"  );
    parseTest(expr  , "1+2"  );
    parseTest(expr  , "123"  );
    parseTest(expr  , "1+2+3");
    parseTest(expr  , "1-2-3");
    parseTest(expr  , "1-2+3");
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

掛け算や割り算は合計では処理できないため、`many`でクロージャのリストを返して、後でまとめて計算します。

```cpp
#include "parsecpp.cpp"
#include <numeric>

int toInt(const std::string &s) {
    int ret;
    std::istringstream(s) >> ret;
    return ret;
}

auto number = apply<int, std::string>(toInt, many1(digit));

Parser<int> expr = [](Source *s) {
    int x = number(s);
    auto xs = many(
        Parser<std::function<int (int)>>([](Source *s) {        // 型を修正
            char1('+')(s);
            int x = number(s);                                  // キャプチャされる変数
            return [=](int y) { return y + x; };                // クロージャを返す
        }) || Parser<std::function<int (int)>>([](Source *s) {
            char1('-')(s);
            int x = number(s);                                  // キャプチャされる変数
            return [=](int y) { return y - x; };                // クロージャを返す
        }) || Parser<std::function<int (int)>>([](Source *s) {  // 追加: 掛け算
            char1('*')(s);
            int x = number(s);                                  // キャプチャされる変数
            return [=](int y) { return y * x; };                // クロージャを返す
        }) || Parser<std::function<int (int)>>([](Source *s) {  // 追加: 割り算
            char1('/')(s);
            int x = number(s);                                  // キャプチャされる変数
            return [=](int y) { return y / x; };                // クロージャを返す
        })
    )(s);
    return std::accumulate(xs.begin(), xs.end(), x,             // まとめて計算
        [](int x, const std::function<int (int)> &f) { return f(x); });
};

int main() {
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

```cpp
#include "parsecpp.cpp"
#include <numeric>

int toInt(const std::string &s) {
    int ret;
    std::istringstream(s) >> ret;
    return ret;
}

auto number = apply<int, std::string>(toInt, many1(digit));

Parser<int> term = [](Source *s) {  // 項の計算、exprと同じ構造
    int x = number(s);
    auto xs = many(
        Parser<std::function<int (int)>>([](Source *s) {
            char1('*')(s);
            int x = number(s);
            return [=](int y) { return y * x; };
        }) || Parser<std::function<int (int)>>([](Source *s) {
            char1('/')(s);
            int x = number(s);
            return [=](int y) { return y / x; };
        })
    )(s);
    return std::accumulate(xs.begin(), xs.end(), x,
        [](int x, const std::function<int (int)> &f) { return f(x); });
};

Parser<int> expr = [](Source *s) {
    int x = term(s);          // 項を取得
    auto xs = many(
        Parser<std::function<int (int)>>([](Source *s) {
            char1('+')(s);
            int x = term(s);  // 項を取得
            return [=](int y) { return y + x; };
        }) || Parser<std::function<int (int)>>([](Source *s) {
            char1('-')(s);
            int x = term(s);  // 項を取得
            return [=](int y) { return y - x; };
        })
    )(s);
    return std::accumulate(xs.begin(), xs.end(), x,
        [](int x, const std::function<int (int)> &f) { return f(x); });
};

int main() {
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

```cpp:抜粋
        Parser<std::function<int (int)>>([](Source *s) {
            char1('+')(s);
            int y = term(s);
            return [=](int x) { return x + y; };
        })
```

`y`に読み取った項を代入して、次の行のクロージャでキャプチャしています。キャプチャした変数は引数を畳み込んでいると見なせるため、本質的には2引数のラムダ式です。

※ 引数を畳み込んで引数を減らした新しい関数を生成することを部分適用と呼びます。詳細は次の記事を参照してください。

* [カリー化と部分適用（JavaScriptとHaskell）](http://qiita.com/7shi/items/a0143daac77a205e7962) 2014.10.15

`apply`にオーバーロードを追加して、2引数の関数を渡して第1引数をキャプチャした1引数のクロージャを返します。

```cpp:parsecpp.cpp（追加）
template <typename T1, typename T2, typename T3>
Parser<std::function<T1 (const T2 &)>> apply(
        const std::function <T1 (const T2 &, const T3 &)> &f, const Parser<T2> &p) {
    return [=](Source *s) {
        T2 x = p(s);
        return [=](const T3 &y) {
            return f(x, y);
        };
    };
}
```

このままでは型引数が煩雑になるので、特殊化した`apply`を用意して使います。

```cpp
#include "parsecpp.cpp"
#include <numeric>

int toInt(const std::string &s) {
    int ret;
    std::istringstream(s) >> ret;
    return ret;
}

Parser<std::function<int (int)>> apply(  // 特殊化
        const std::function<int (int, int)> &f, const Parser<int> &p) {
    return apply<int, int, int>(f, p);
}

auto number = apply<int, std::string>(toInt, many1(digit));

Parser<int> term = [](Source *s) {
    int x = number(s);
    auto xs = many(
        Parser<std::function<int (int)>>([](Source *s) {
            char1('*')(s);
            return apply([](int x, int y) { return y * x; }, number)(s);  // 適用
        }) || Parser<std::function<int (int)>>([](Source *s) {
            char1('/')(s);
            return apply([](int x, int y) { return y / x; }, number)(s);  // 適用
        })
    )(s);
    return std::accumulate(xs.begin(), xs.end(), x,
        [](int x, const std::function<int (int)> &f) { return f(x); });
};

Parser<int> expr = [](Source *s) {
    int x = term(s);
    auto xs = many(
        Parser<std::function<int (int)>>([](Source *s) {
            char1('+')(s);
            return apply([](int x, int y) { return y + x; }, term)(s);  // 適用
        }) || Parser<std::function<int (int)>>([](Source *s) {
            char1('-')(s);
            return apply([](int x, int y) { return y - x; }, term)(s);  // 適用
        })
    )(s);
    return std::accumulate(xs.begin(), xs.end(), x,
        [](int x, const std::function<int (int)> &f) { return f(x); });
};

int main() {
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

演算子`>>`を使えばラムダ式がなくなります。

```cpp
#include "parsecpp.cpp"
#include <numeric>

int toInt(const std::string &s) {
    int ret;
    std::istringstream(s) >> ret;
    return ret;
}

Parser<std::function<int (int)>> apply(
        const std::function<int (int, int)> &f, const Parser<int> &p) {
    return apply<int, int, int>(f, p);
}

auto number = apply<int, std::string>(toInt, many1(digit));

Parser<int> term = [](Source *s) {
    int x = number(s);
    auto xs = many(
           char1('*') >> apply([](int x, int y) { return y * x; }, number)  // 修正
        || char1('/') >> apply([](int x, int y) { return y / x; }, number)  // 修正
    )(s);
    return std::accumulate(xs.begin(), xs.end(), x,
        [](int x, const std::function<int (int)> &f) { return f(x); });
};

Parser<int> expr = [](Source *s) {
    int x = term(s);
    auto xs = many(
           char1('+') >> apply([](int x, int y) { return y + x; }, term)  // 修正
        || char1('-') >> apply([](int x, int y) { return y - x; }, term)  // 修正
    )(s);
    return std::accumulate(xs.begin(), xs.end(), x,
        [](int x, const std::function<int (int)> &f) { return f(x); });
};

int main() {
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

```cpp
#include "parsecpp.cpp"
#include <numeric>

int toInt(const std::string &s) {
    int ret;
    std::istringstream(s) >> ret;
    return ret;
}

Parser<int> eval(
        const Parser<int> &m,
        const Parser<std::list<std::function<int (int)>>> &fs) {
    return [=](Source *s) {
        int x = m(s);
        auto xs = fs(s);
        return std::accumulate(xs.begin(), xs.end(), x,
            [](int x, const std::function<int (int)> &f) { return f(x); });
    };
}

Parser<std::function<int (int)>> apply(
        const std::function<int (int, int)> &f, const Parser<int> &p) {
    return apply<int, int, int>(f, p);
}

auto number = apply<int, std::string>(toInt, many1(digit));

auto term = eval(number, many(
       char1('*') >> apply([](int x, int y) { return y * x; }, number)  // 修正
    || char1('/') >> apply([](int x, int y) { return y / x; }, number)  // 修正
));

auto expr = eval(term, many(
       char1('+') >> apply([](int x, int y) { return y + x; }, term)  // 修正
    || char1('-') >> apply([](int x, int y) { return y - x; }, term)  // 修正
));

int main() {
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
auto term = eval(number, many(
       char1('*') >> apply([](int x, int y) { return y * x; }, number)
    || char1('/') >> apply([](int x, int y) { return y / x; }, number)
));

// expr = term, {("+", term) | ("-", term)}
auto expr = eval(term, many(
       char1('+') >> apply([](int x, int y) { return y + x; }, term)
    || char1('-') >> apply([](int x, int y) { return y - x; }, term)
));
```

このコードはなるべくBNFに近付けるよう意識しています。このような使い方は[ドメイン固有言語](https://ja.wikipedia.org/wiki/%E3%83%89%E3%83%A1%E3%82%A4%E3%83%B3%E5%9B%BA%E6%9C%89%E8%A8%80%E8%AA%9E)（DSL）に見立てられます。

## 括弧

括弧をサポートため、項の下位に因子（factor）という層を追加します。

括弧の中は`expr`のため次のように再帰が循環します。

* `expr` → `term` → `factor` → `expr` → ...

このような再帰を定義するには前方宣言が必須ですが、ポインタではなく実体で定義するインスタンスは記述順に初期化されるため、前方参照した先のインスタンスが生成される前に使用することになりおかしなことになります。

初期化を遅延させるためダミーのラムダ式を挟みます。ダミーの方を他から使うため、実体の方を名前変更します。前方宣言では`auto`が使えませんが、前方宣言があると実体の方にも`auto`が使えなくなります。

```cpp
#include "parsecpp.cpp"
#include <numeric>

int toInt(const std::string &s) {
    int ret;
    std::istringstream(s) >> ret;
    return ret;
}

Parser<int> eval(
        const Parser<int> &m,
        const Parser<std::list<std::function<int (int)>>> &fs) {
    return [=](Source *s) {
        int x = m(s);
        auto xs = fs(s);
        return std::accumulate(xs.begin(), xs.end(), x,
            [](int x, const std::function<int (int)> &f) { return f(x); });
    };
}

Parser<std::function<int (int)>> apply(
        const std::function<int (int, int)> &f, const Parser<int> &p) {
    return apply<int, int, int>(f, p);
}

auto number = apply<int, std::string>(toInt, many1(digit));

extern Parser<int> factor_;  // 前方宣言
Parser<int> factor = [](Source *s) { return factor_(s); };  // ダミーのラッパー

// term = factor, {("*", factor) | ("/", factor)}
auto term = eval(factor, many(
       char1('*') >> apply([](int x, int y) { return y * x; }, factor)
    || char1('/') >> apply([](int x, int y) { return y / x; }, factor)
));

// expr = term, {("+", term) | ("-", term)}
auto expr = eval(term, many(
       char1('+') >> apply([](int x, int y) { return y + x; }, term)
    || char1('-') >> apply([](int x, int y) { return y - x; }, term)
));

// factor = ("(", expr, ")") | number
Parser<int> factor_ = char1('(') >> expr << char1(')') || number;  // 実体

int main() {
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

```cpp:parsecpp.cpp（追加）
bool isSpace(char ch) { return ch == '\t' || ch == ' '; }
auto space  = satisfy(isSpace) || left("not space");
auto spaces = many(space);
```

`factor`を修正します。

```cpp:修正
// factor = factor = [spaces], ("(", expr, ")") | number, [spaces]
Parser<int> factor_ = spaces
                   >> (char1('(') >> expr << char1(')') || number)
                   << spaces;
```

次のようなテストが動くようになります。

```cpp
int main() {
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

ここまでのコード全体です。

* [parsecpp.cpp, calc.cpp](https://bitbucket.org/snippets/7shi/o9dep)

パーサコンビネータによるプログラミングが何となく見えて来ればしめたものです。
