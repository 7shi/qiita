---
coediting: false
comments_count: 3
created_at: '2015-11-27T23:38:39+09:00'
id: 6a12160276a8db358e34
likes_count: 66
private: false
reactions_count: 0
stocks_count: 67
tags:
- name: C++11
  versions: []
title: C++11 パーサコンビネータ 超入門
updated_at: '2016-12-27T02:34:35+09:00'
url: https://qiita.com/7shi/items/6a12160276a8db358e34
slide: false
---

構文を解析するプログラムをパーサと呼びます。実装方法にはいくつか種類がありますが、今回はパーサコンビネータという方式を取り上げます。既存の実装を使うのではなく、1から実装しながら説明します。

C++では[Boost.Spirit](http://boost-spirit.com/home/)が有名ですが、この記事ではHaskellのParsecを参考にしています。もちろんHaskellやモナドの知識は前提としません。それと断らずにモナドに由来する何かは出て来ますが、それが見抜けなくても問題ありません。興味があれば以下の記事を参照してください。

* [Haskell 構文解析 超入門](http://qiita.com/7shi/items/b8c741e78a96ea2c10fe) 2015.07.31

今回はラムダ式を多用するためC++11以降を対象とします。ラムダ式なしで実装するとあまりにも冗長になり過ぎて、便利さよりも煩雑さが勝ってしまうためです。興味があれば、以下のリポジトリを参照してください。

* https://bitbucket.org/7shi/parsecpp

この記事には続編があります。

* [C++11 パーサコンビネータ 超入門 2](http://qiita.com/7shi/items/f86f2f7ad68cfff1b399) 2015.11.30

この記事にはJava版があります。

* [Java パーサコンビネータ 超入門](http://qiita.com/7shi/items/68228e19552c271bea81) 2016.05.12
* [Java パーサコンビネータ 超入門 2](http://qiita.com/7shi/items/39a9ddffcc5bdf2c0142) 2016.05.14

この記事には関連記事があります。

* [JSONパーサーを作る](http://qiita.com/7shi/items/04c2991239894687ef2f) 2016.12.26

# コンセプト

パーサコンビネータは、単純な部品（パーサ）の組み合わせ（コンビネーション）で構文を解析します。

文字列からアルファベットと数字を分離する例です。`#include`している[parsecpp.cpp](https://bitbucket.org/snippets/7shi/o9dep/revisions/4282afab8b71b96924335c39f8433358ec9c33a4)はこの記事で1から作ります。

```cpp
#include "parsecpp.cpp"

int main() {
    Source s1 = "abc123";
    auto s1a = many(alpha)(&s1);
    auto s1b = many(digit)(&s1);
    std::cout << s1a << "," << s1b << std::endl;

    Source s2 = "abcde9";
    auto s2a = many(alpha)(&s2);
    auto s2b = many(digit)(&s2);
    std::cout << s2a << "," << s2b << std::endl;
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

`s1`や`s2`は処理するたびに文字を読み進めます。値渡しでは変更（副作用）が加えられないため`&s1`のようにポインタで渡します。

※ この辺の設計は副作用を排除したHaskellのParsecとは異なりますが、C++で実装しやすくするためのアレンジです。Haskellと完全に同じものをC++で実装したわけではありません。

# 基礎編

簡単な所から少しずつパーサコンビネータを作り始めます。

## 1文字取得

指定した文字列から先頭の1文字を取得します。

```cpp
#include <iostream>

char anyChar(const char *s) {
    return *s;
}

int main() {
    std::cout << anyChar("abc") << std::endl;
}
```
```text:実行結果
a
```

`anyChar`が最初のパーサです。

### 連続呼び出し

`anyChar`を連続呼び出しすることで複数文字を取得できるように拡張します。

ポインタをポインタで渡して読み取り後に1文字進めれば、次の呼び出しで次の文字が取得できます。

```cpp
#include <iostream>

char anyChar(const char **s) {
    return *((*s)++);
}

int main() {
    const char *s = "abc";
    std::cout << anyChar(&s) << std::endl;
    std::cout << anyChar(&s) << std::endl;
}
```
```text:実行結果
a
b
```

`anyChar`を2回繰り返すことで、先頭から2文字取得しています。

## 型エイリアス

ポインタのポインタは直感的に分かりにくいので、型エイリアスを導入します。

```cpp
#include <iostream>

using Source = const char *;

char anyChar(Source *s) {
    return *((*s)++);
}

int main() {
    Source s = "abc";
    std::cout << anyChar(&s) << std::endl;
    std::cout << anyChar(&s) << std::endl;
}
```
```text:実行結果
a
b
```

`using`での型エイリアスはC++11で導入されました。`typedef`の機能強化版です。

## 関数化

2文字取得する部分を関数化します。

```cpp
#include <iostream>
#include <string>

using Source = const char *;

char anyChar(Source *s) {
    return *((*s)++);
}

std::string test1(Source *s) {  // 関数化
    char x1 = anyChar(s);
    char x2 = anyChar(s);
    return std::string({x1, x2});
}

int main() {
    Source s = "abc";
    std::cout << anyChar(&s) << std::endl;
    std::cout << test1  (&s) << std::endl;
}
```
```text:実行結果
a
bc
```

`test1`は`anyChar`を組み合わせて作られていますが、利用側からは`anyChar`と`test1`が同じように扱えるのがポイントです。ただし戻り値の型が異なるのには注意が必要です。

### 組み合わせ

`test1`は、別の箇所で`anyChar`と組み合わせて利用できます。

```cpp
#include <iostream>
#include <string>

using Source = const char *;

char anyChar(Source *s) {
    return *((*s)++);
}

std::string test1(Source *s) {
    char x1 = anyChar(s);
    char x2 = anyChar(s);
    return std::string({x1, x2});
}

std::string test2(Source *s) {  // 追加
    auto x1 = test1(s);
    char x2 = anyChar(s);
    return x1 + x2;
}

int main() {
    Source s1 = "abc";
    std::cout << anyChar(&s1) << std::endl;
    Source s2 = "abc";
    std::cout << test1(&s2) << std::endl;
    Source s3 = "abc";
    std::cout << test2(&s3) << std::endl;
}
```
```text:実行結果
a
ab
abc
```

`test1`は`anyChar`を2つ組み合わせて作ったパーサです。`test2`は`test1`と`anyChar`を組み合わせて作ったパーサです。このように簡単なパーサを組み合わせて複雑なパーサを作っていくのが、パーサコンビネータの基本的な考え方です。

`main`の中で`anyChar`と`test1`と`test2`が同列に並んでいますが、どれもパーサとして同じような位置付けだと見立ててください。

## テスト関数

`main()`でのテストが煩雑になって来たので、テスト用の関数`parseTest`を作成します。

```cpp
#include <iostream>
#include <string>

using Source = const char *;

template <typename T>  // 追加
void parseTest(T (*p)(Source *), const Source &src) {
    Source s = src;
    std::cout << p(&s) << std::endl;
}

char anyChar(Source *s) {
    return *((*s)++);
}

std::string test1(Source *s) {
    char x1 = anyChar(s);
    char x2 = anyChar(s);
    return std::string({x1, x2});
}

std::string test2(Source *s) {
    auto x1 = test1(s);
    char x2 = anyChar(s);
    return x1 + x2;
}

int main() {
    parseTest(anyChar, "abc");
    parseTest(test1  , "abc");
    parseTest(test2  , "abc");
}
```
```text:実行結果
a
ab
abc
```

`parseTest`にはパーサの関数（`anyChar`など）を渡しますが、異なる戻り値を受け付けるようにテンプレートを用いて多相化しています。

### 型エイリアス

関数ポインタの書き方は複雑なので、型エイリアスを定義します。

```cpp
#include <iostream>
#include <string>

using Source = const char *;

template <typename T>         // 追加
using Parser = T (Source *);  // T: 戻り値, (...): 引数

template <typename T>
void parseTest(const Parser<T> &p, const Source &src) {
    Source s = src;
    std::cout << p(&s) << std::endl;
}

char anyChar(Source *s) {
    return *((*s)++);
}

std::string test1(Source *s) {
    char x1 = anyChar(s);
    char x2 = anyChar(s);
    return std::string({x1, x2});
}

std::string test2(Source *s) {
    auto x1 = test1(s);
    char x2 = anyChar(s);
    return x1 + x2;
}

int main() {
    parseTest(anyChar, "abc");
    parseTest(test1  , "abc");
    parseTest(test2  , "abc");
}
```
```text:実行結果
a
ab
abc
```

このように`using`はテンプレートと併用することができます。関数ポインタ型の表現方法も、名前と型が分離されており読みやすいです。これらは`typedef`に対する改善点です。詳細は次の記事が参考になります。

* @Linda_pp: [typedef は C++11 ではオワコン](http://qiita.com/Linda_pp/items/44a67c64c14cba00eef1) 2014.12.21

## 例外

文字列の末尾に達したかどうかをチェックしていないのは問題です。番兵（`'\0'`）を確認して例外を発生させるように修正します。

```cpp
#include <iostream>
#include <string>

using Source = const char *;

template <typename T>
using Parser = T (Source *);

template <typename T>
void parseTest(const Parser<T> &p, const Source &src) {
    Source s = src;
    try {
        std::cout << p(&s) << std::endl;
    } catch (const char *e) {    // 例外処理
        std::cout << e << std::endl;
    }
}

char anyChar(Source *s) {
    char ch = **s;
    if (!ch) throw "too short";  // 例外発生
    ++*s;
    return ch;
}

std::string test1(Source *s) {
    char x1 = anyChar(s);
    char x2 = anyChar(s);
    return std::string({x1, x2});
}

std::string test2(Source *s) {
    auto x1 = test1(s);
    char x2 = anyChar(s);
    return x1 + x2;
}

int main() {
    parseTest(test2, "12" );  // 文字数不足
    parseTest(test2, "123");
}
```
```text:実行結果
too short
123
```

## std::function

C++11ではラムダ式がサポートされました。ここから先ではラムダ式を多用しますが、関数ポインタでは扱えません。そのため関数ポインタを`std::function`で置き換えます。

```cpp
#include <iostream>
#include <string>
#include <functional>  // 追加

using Source = const char *;

template <typename T>
using Parser = std::function<T (Source *)>;  // 修正

template <typename T>
void parseTest(const Parser<T> &p, const Source &src) {
    Source s = src;
    try {
        std::cout << p(&s) << std::endl;
    } catch (const char *e) {
        std::cout << e << std::endl;
    }
}

Parser<char> anyChar = [](Source *s) {       // ラムダ式化
    char ch = **s;
    if (!ch) throw "too short";
    ++*s;
    return ch;
};

Parser<std::string> test1 = [](Source *s) {  // ラムダ式化
    char x1 = anyChar(s);
    char x2 = anyChar(s);
    return std::string({x1, x2});
};

Parser<std::string> test2 = [](Source *s) {  // ラムダ式化
    auto x1 = test1(s);
    char x2 = anyChar(s);
    return x1 + x2;
};

int main() {
    parseTest(test2, "12" );  // NG
    parseTest(test2, "123");
}
```
```text:実行結果
too short
123
```

`std::function`に対して関数を渡しても自動で変換されますが、テンプレートで多相化されていると明示的な変換が必要になります。その面倒を避けるため`anyChar`などをラムダ式化しています。

## 条件取得

`anyChar`は無条件で文字を取得していましたが、条件が指定できる`satisfy`を追加します。引数で渡された関数を`[=]`でキャプチャしたクロージャを返します。

```cpp
#include <iostream>
#include <string>
#include <functional>

using Source = const char *;

template <typename T>
using Parser = std::function<T (Source *)>;

template <typename T>
void parseTest(const Parser<T> &p, const Source &src) {
    Source s = src;
    try {
        std::cout << p(&s) << std::endl;
    } catch (const char *e) {
        std::cout << e << std::endl;
    }
}

Parser<char> anyChar = [](Source *s) {
    char ch = **s;
    if (!ch) throw "too short";
    ++*s;
    return ch;
};

Parser<char> satisfy(const std::function<bool (char)> &f) {  // 追加
    return [=](Source *s) {
        char ch = **s;
        if (!ch) throw "too short";
        if (!f(ch)) throw "not satisfy";
        ++*s;
        return ch;
    };
}

bool isDigit(char ch) { return '0' <= ch && ch <= '9'; }

int main() {
    parseTest(satisfy(isDigit), "abc");  // NG
    parseTest(satisfy(isDigit), "123");
}
```
```text:実行結果
not satisfy
1
```

今回の機能追加に直接関係ない`test1`と`test2`は削除しました。

### 共通化

`anyChar`と`satisfy`でほとんどの処理が重複しています。`anyChar`は無条件の`satisfy`として定義することで共通化を図ります。

※ 前方参照（使用箇所よりも下で定義された関数を使用すること）できないため、`anyChar`は`satisfy`の下に移動します。

```cpp
#include <iostream>
#include <string>
#include <functional>

using Source = const char *;

template <typename T>
using Parser = std::function<T (Source *)>;

template <typename T>
void parseTest(const Parser<T> &p, const Source &src) {
    Source s = src;
    try {
        std::cout << p(&s) << std::endl;
    } catch (const char *e) {
        std::cout << e << std::endl;
    }
}

Parser<char> satisfy(const std::function<bool (char)> &f) {
    return [=](Source *s) {
        char ch = **s;
        if (!ch) throw "too short";
        if (!f(ch)) throw "not satisfy";
        ++*s;
        return ch;
    };
}

auto anyChar = satisfy([](char) { return true; });  // 移動・修正

int main() {
    parseTest(anyChar, "abc");
}
```
```text:実行結果
a
```

## ファイル分割

コードが長くなって来たため、汎用部分を別ファイルに分離します。ファイル名の`parsecpp`は`ParseC++`のつもりです。

```parsecpp.cpp
#include <iostream>
#include <string>
#include <functional>

using Source = const char *;

template <typename T>
using Parser = std::function<T (Source *)>;

template <typename T>
void parseTest(const Parser<T> &p, const Source &src) {
    Source s = src;
    try {
        std::cout << p(&s) << std::endl;
    } catch (const char *e) {
        std::cout << e << std::endl;
    }
}

Parser<char> satisfy(const std::function<bool (char)> &f) {
    return [=](Source *s) {
        char ch = **s;
        if (!ch) throw "too short";
        if (!f(ch)) throw "not satisfy";
        ++*s;
        return ch;
    };
}

auto anyChar = satisfy([](char) { return true; });
```

簡単のためヘッダではなく直に`#include`して使います。

※ もし実用化するのであればヘッダも作成する必要がありますが、今回は説明が目的として割り切ります。

```cpp
#include "parsecpp.cpp"

int main() {
    parseTest(anyChar, "abc");
}
```
```text:実行結果
a
```

## 文字判定

文字を指定して判定するパーサを実装します。Parsecでは`char`ですが、型と被るため`char1`に名前を変更します。

```cpp:parsecpp.cpp（追加）
Parser<char> char1(char ch) {
    return satisfy([=](char c) { return c == ch; });
}
```

`char1`は引数`ch`を`[=]`でキャプチャしたクロージャを返しているのがポイントです。今後このようなパターンがよく出て来ます。

動作を確認します。

```cpp
#include "parsecpp.cpp"

int main() {
    parseTest(char1('a'), "abc");
    parseTest(char1('a'), "123");  // NG
}
```
```text:実行結果
a
not satisfy
```

## 事前定義

`satisfy`で条件を指定するのは冗長なので、よく使うパターンを事前定義します。

```cpp:parsecpp.cpp（追加）
bool isDigit   (char ch) { return '0' <= ch && ch <= '9'; }
bool isUpper   (char ch) { return 'A' <= ch && ch <= 'Z'; }
bool isLower   (char ch) { return 'a' <= ch && ch <= 'z'; }
bool isAlpha   (char ch) { return isUpper(ch) || isLower(ch); }
bool isAlphaNum(char ch) { return isAlpha(ch) || isDigit(ch); }
bool isLetter  (char ch) { return isAlpha(ch) || ch == '_';   }

auto digit    = satisfy(isDigit   );
auto upper    = satisfy(isUpper   );
auto lower    = satisfy(isLower   );
auto alpha    = satisfy(isAlpha   );
auto alphaNum = satisfy(isAlphaNum);
auto letter   = satisfy(isLetter  );
```

動作を確認します。

```cpp
#include "parsecpp.cpp"

int main() {
    parseTest(digit , "abc");  // NG
    parseTest(digit , "123");
    parseTest(letter, "abc");
    parseTest(letter, "123");  // NG
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

```cpp
#include "parsecpp.cpp"

Parser<std::string> test3 = [](Source *s) {
    char x1 = letter(s);
    char x2 = digit(s);
    char x3 = digit(s);
    return std::string({x1, x2, x3});
};

int main() {
    parseTest(test3, "abc" );  // NG
    parseTest(test3, "123" );  // NG
    parseTest(test3, "a23" );
    parseTest(test3, "a234");
}
```
```text:実行結果
not satisfy
not satisfy
a23
a23
```

## コンビネータの定義

パーサ同士を組み合わせて新しいパーサを作り出す関数を**コンビネータ**と呼びます。

いくつか便利なコンビネータを定義します。

### 結合

パーサを結合する演算子`+`を定義してparsecpp.cppに追加します。

```cpp:parsecpp.cpp（追加）
template <typename T1, typename T2>
Parser<std::string> operator+(const Parser<T1> &x, const Parser<T2> &y) {
    return [=](Source *s) {
        std::string ret;
        ret += x(s);
        ret += y(s);
        return ret;
    };
}
```

`test3`がとても簡単になります。

```cpp
#include "parsecpp.cpp"

auto test3 = letter + digit + digit;

int main() {
    parseTest(test3, "abc" );  // NG
    parseTest(test3, "123" );  // NG
    parseTest(test3, "a23" );
    parseTest(test3, "a234");
}
```
```text:実行結果
not satisfy
not satisfy
a23
a23
```

処理が関数を定義しなくても組み合わせで表現されています。この感覚がつかめれば、パーサコンビネータが見えて来ます。

### 繰り返し

掛け算の演算子で繰り返し回数を指定できるようにします。掛け算の順序を気にしなくても済むように、2つのパターンを定義します。

```cpp:parsecpp.cpp（追加）
template <typename T>
Parser<std::string> operator*(int n, const Parser<T> &x) {
    return [=](Source *s) {
        std::string ret;
        for (int i = 0; i < n; ++i) {
            ret += x(s);
        }
        return ret;
    };
}
template <typename T>
Parser<std::string> operator*(const Parser<T> &x, int n) {
    return n * x;
}
```

`test3`が更に簡単になります。

```cpp
#include "parsecpp.cpp"

auto test3 = letter + 2 * digit;

int main() {
    parseTest(test3, "abc" );  // NG
    parseTest(test3, "123" );  // NG
    parseTest(test3, "a23" );
    parseTest(test3, "a234");
}
```
```text:実行結果
not satisfy
not satisfy
a23
a23
```

コンビネータの定義はラムダ式を返す関数になっていて少し複雑ですが、利用側はとても簡単に書けます。

## many

繰り返しに関連して、最初のコンセプトで出て来た`many`を実装してみます。

`many`は指定したパーサを0回以上適用して返すコンビネータです。エラーになるまで読み進めれば実装できます。

```cpp:parsecpp.cpp（追加）
template <typename T>
Parser<std::string> many(const Parser<T> &p) {
    return [=](Source *s) {
        std::string ret;
        try {
            for (;;) ret += p(s);
        } catch (const char *) {}
        return ret;
    };
}
```

先頭からアルファベットだけを抜き出してみます。1文字も一致しなくても、エラーにはならずに空文字列が返ります。

```cpp
#include "parsecpp.cpp"

auto test4 = many(alpha);

int main() {
    parseTest(test4, "abc123");
    parseTest(test4, "123abc");
}
```
```text:実行結果
abc
     ← 空行
```

最初に出て来たサンプルも動きます。

```cpp
#include "parsecpp.cpp"

int main() {
    Source s1 = "abc123";
    auto s1a = many(alpha)(&s1);
    auto s1b = many(digit)(&s1);
    std::cout << s1a << "," << s1b << std::endl;

    Source s2 = "abcde9";
    auto s2a = many(alpha)(&s2);
    auto s2b = many(digit)(&s2);
    std::cout << s2a << "," << s2b << std::endl;
}
```
```text:実行結果
abc,123
abcde,9
```

## まとめ

ここまでがパーサコンビネータの動作原理を理解するために最低限必要な実装です。

このセクションで登場したテストを1つにまとめます。

* [ここまでの parsecpp.cpp](https://bitbucket.org/snippets/7shi/o9dep/revisions/645de09ce4f9e53e4dbab48f403521b12f2d0af7)

```cpp
#include "parsecpp.cpp"

auto test1 = anyChar + anyChar;
auto test2 = test1 + anyChar;
auto test3 = letter + 2 * digit;
auto test4 = many(alpha);

int main() {
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

    Source s1 = "abc123";
    auto s1a = many(alpha)(&s1);
    auto s1b = many(digit)(&s1);
    std::cout << s1a << "," << s1b << std::endl;

    Source s2 = "abcde9";
    auto s2a = many(alpha)(&s2);
    auto s2b = many(digit)(&s2);
    std::cout << s2a << "," << s2b << std::endl;
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

「または」を表現する演算子`||`を実装します。

```cpp:parsecpp.cpp（追加）
template <typename T>
const Parser<T> operator||(const Parser<T> &p1, const Parser<T> &p2) {
    return [=](Source *s) {
        T ret;
        try {
            ret = p1(s);
        } catch (const char *) {
            ret = p2(s);
        }
        return ret;
    };
}
```

`||`を使えば「アルファベットまたは数字」のような選択的なパーサが構築できます。

```cpp
#include "parsecpp.cpp"

auto test5 = letter || digit;

int main() {
    parseTest(test5, "a");
    parseTest(test5, "1");
    parseTest(test5, "!");  // NG
}
```
```text:実行結果
a
1
not satisfy
```

### manyとの組み合わせ

選択的パーサを`many`で繰り返すこともできます。

```cpp
#include "parsecpp.cpp"

auto test6 = many(letter || digit);

int main() {
    parseTest(test6, "abc123");
    parseTest(test6, "123abc");
}
```
```text:実行結果
abc123
123abc
```

## 結合と選択

`||`を少し使ってみると、直感に反した動きに気付きます。

```cpp
#include "parsecpp.cpp"

auto a = char1('a');
auto b = char1('b');
auto c = char1('c');

auto test7 = a + b || c + b;

int main() {
    parseTest(test7, "ab" );
    parseTest(test7, "cb" );
    parseTest(test7, "acb");  // ???
}
```
```text:実行結果
ab
cb
cb
```

`test7`を素直に見ると「`"ab"`または`"cb"`」となり、確かにその両方にマッチします。しかし`"acb"`にもマッチしてしまいます。これは`||`に達する前に`'a'`だけは読み進めてしまったため、`||`の後のパターンにマッチしてしまうためです。

## エラー化

このようなケースはParsecではエラーになります。

`左 || 右`として、左のパーサが内部で複数のパーサから構成されるとき、そのうち1つでも成功してその後で失敗したなら、右のパーサは処理されずにエラーになるという仕様です。

最初の状態を保持しておいて、`||`の前で読み進めていれば例外を再送します。

```cpp:parsecpp.cpp（修正）
template <typename T>
const Parser<T> operator||(const Parser<T> &p1, const Parser<T> &p2) {
    return [=](Source *s) {
        T ret;
        Source bak = *s;           // 追加
        try {
            ret = p1(s);
        } catch (const char *) {
            if (*s != bak) throw;  // 追加
            ret = p2(s);
        }
        return ret;
    };
}
```

先ほどと同じコードを試すと、最後がエラーになります。Parsecと同じで意図した動きです。

```cpp
#include "parsecpp.cpp"

auto a = char1('a');
auto b = char1('b');
auto c = char1('c');

auto test7 = a + b || c + b;

int main() {
    parseTest(test7, "ab" );
    parseTest(test7, "cb" );
    parseTest(test7, "acb");  // NG
}
```
```text:実行結果
ab
cb
not satisfy
```

## 共通部分

選択肢の先頭に共通部分があった場合、意図せずエラーになることがあります。

```cpp
#include "parsecpp.cpp"

auto a = char1('a');
auto b = char1('b');
auto c = char1('c');

auto test8 = a + b || a + c;

int main() {
    parseTest(test8, "ab" );
    parseTest(test8, "ac" );  // NG
}
```
```text:実行結果
ab
not satisfy
```

このようなケースでは、共通部分を括り出すことで対処できます。

```cpp
#include "parsecpp.cpp"

auto a = char1('a');
auto b = char1('b');
auto c = char1('c');

auto test8 = a + b || a + c;
auto test9 = a + (b || c);

int main() {
    parseTest(test8, "ab");
    parseTest(test8, "ac");  // NG
    parseTest(test9, "ab");
    parseTest(test9, "ac");
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

`tryp`の中で失敗すれば元の状態に戻してから例外を再送します。

```cpp:parsecpp.cpp（追加）
template <typename T>
Parser<T> tryp(const Parser<T> &p) {
    return [=](Source *s) {
        T ret;
        Source bak = *s;
        try {
            ret = p(s);
        } catch (const char *) {
            *s = bak;
            throw;
        }
        return ret;
    };
}
```

`||`の左側を`tryp`で囲めば、失敗してもバックトラックしてから右側が処理されます。

先ほどの`test8`と`test9`と挙動を比較します。

```cpp
#include "parsecpp.cpp"

auto a = char1('a');
auto b = char1('b');
auto c = char1('c');

auto test8  = a + b  || a + c;
auto test9  = a + (b || c);
auto test10 = tryp(a + b) || a + c;

int main() {
    parseTest(test8 , "ab");
    parseTest(test8 , "ac");  // NG
    parseTest(test9 , "ab");
    parseTest(test9 , "ac");
    parseTest(test10, "ab");
    parseTest(test10, "ac");
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

```cpp:parsecpp.cpp（追加）
Parser<std::string> string(const std::string &str) {
    return [=](Source *s) {
        for (auto it = str.begin(); it != str.end(); ++it) {
            char1(*it)(s);
        }
        return str;
    };
}
```

内部では1文字ずつ処理されているため、途中の失敗をバックトラックするには`tryp`が必要です。

挙動を確認します。

```cpp
#include "parsecpp.cpp"

auto test11 = string("ab") || string("ac");
auto test12 = tryp(string("ab")) || string("ac");

int main() {
    parseTest(test11, "ab");
    parseTest(test11, "ac");  // NG
    parseTest(test12, "ab");
    parseTest(test12, "ac");
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

* [ここまでの parsecpp.cpp](https://bitbucket.org/snippets/7shi/o9dep/revisions/daff7dd17df16439d6adf1622367ef5bee57a739)

```cpp
#include "parsecpp.cpp"

auto a = char1('a');
auto b = char1('b');
auto c = char1('c');

auto test5  = letter || digit;
auto test6  = many(letter || digit);
auto test7  = a + b || c + b;
auto test8  = a + b || a + c;
auto test9  = a + (b || c);
auto test10 = tryp(a + b) || a + c;
auto test11 = string("ab") || string("ac");
auto test12 = tryp(string("ab")) || string("ac");

int main() {
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

## クラス化

`Source`をクラス化します。

差分を示します。

```diff
--- parsecpp.cpp.orig
+++ parsecpp.cpp
@@ -2,7 +2,26 @@
 #include <string>
 #include <functional>
 
-using Source = const char *;
+class Source {
+    const char *s;
+public:
+    Source(const char *s) : s(s) {}
+    char peek() {
+        char ch = *s;
+        if (!ch) throw "too short";
+        return ch;
+    }
+    void next() {
+        peek();
+        ++s;
+    }
+    bool operator==(const Source &src) const {
+        return s == src.s;
+    }
+    bool operator!=(const Source &src) const {
+        return !(*this == src);
+    }
+};
 
 template <typename T>
 using Parser = std::function<T (Source *)>;
@@ -19,10 +38,9 @@
 
 Parser<char> satisfy(const std::function<bool (char)> &f) {
     return [=](Source *s) {
-        char ch = **s;
-        if (!ch) throw "too short";
+        char ch = s->peek();
         if (!f(ch)) throw "not satisfy";
-        ++*s;
+        s->next();
         return ch;
     };
 }
```

* [修正後の parsecpp.cpp](https://bitbucket.org/snippets/7shi/o9dep/revisions/d389835c0cc3798ec3b68bddf7901d1a89d343ca)

`satisfy`は二重デリファレンスやポインタ演算がなくなり、読みやすくなりました。

まだ動作結果に変化はありません。エラーが出るものだけ抽出して確認します。

```cpp
#include "parsecpp.cpp"

auto a = char1('a');
auto b = char1('b');
auto c = char1('c');

auto test1 = anyChar + anyChar;
auto test2 = test1 + anyChar;
auto test3 = letter + 2 * digit;
auto test5  = letter || digit;
auto test7  = a + b || c + b;
auto test8  = a + b || a + c;
auto test11 = string("ab") || string("ac");

int main() {
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

`Source`に位置（行と桁）を保持してエラーメッセージに含めます。文字列を作る必要があるため、例外を`std::string`で送出します。

差分を示します。

```diff
--- parsecpp.cpp.orig
+++ parsecpp.cpp
@@ -1,19 +1,31 @@
 #include <iostream>
+#include <sstream>
 #include <string>
 #include <functional>
 
 class Source {
     const char *s;
+    int line, col;
 public:
-    Source(const char *s) : s(s) {}
+    Source(const char *s) : s(s), line(1), col(1) {}
     char peek() {
         char ch = *s;
-        if (!ch) throw "too short";
+        if (!ch) throw ex("too short");
         return ch;
     }
     void next() {
-        peek();
+        char ch = peek();
+        if (ch == '\n') {
+            ++line;
+            col = 0;
+        }
         ++s;
+        ++col;
+    }
+    std::string ex(const std::string &e) {
+        std::ostringstream oss;
+        oss << "[line " << line << ", col " << col << "] " << e;
+        return oss.str();
     }
     bool operator==(const Source &src) const {
         return s == src.s;
@@ -31,7 +43,7 @@
     Source s = src;
     try {
         std::cout << p(&s) << std::endl;
-    } catch (const char *e) {
+    } catch (const std::string &e) {
         std::cout << e << std::endl;
     }
 }
@@ -39,7 +51,7 @@
 Parser<char> satisfy(const std::function<bool (char)> &f) {
     return [=](Source *s) {
         char ch = s->peek();
-        if (!f(ch)) throw "not satisfy";
+        if (!f(ch)) throw s->ex("not satisfy");
         s->next();
         return ch;
     };
@@ -96,7 +108,7 @@
         std::string ret;
         try {
             for (;;) ret += p(s);
-        } catch (const char *) {}
+        } catch (const std::string &) {}
         return ret;
     };
 }
@@ -108,7 +120,7 @@
         Source bak = *s;
         try {
             ret = p1(s);
-        } catch (const char *) {
+        } catch (const std::string &) {
             if (*s != bak) throw;
             ret = p2(s);
         }
@@ -123,7 +135,7 @@
         Source bak = *s;
         try {
             ret = p(s);
-        } catch (const char *) {
+        } catch (const std::string &) {
             *s = bak;
             throw;
         }
```

* [修正後の parsecpp.cpp](https://bitbucket.org/snippets/7shi/o9dep/revisions/800b28ab89fdd850dfef91f7b8dbbddb931cbcea)

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
--- parsecpp.cpp.orig
+++ parsecpp.cpp
@@ -25,6 +25,7 @@
     std::string ex(const std::string &e) {
         std::ostringstream oss;
         oss << "[line " << line << ", col " << col << "] " << e;
+        if (*s) oss << ": '" << *s << "'";
         return oss.str();
     }
     bool operator==(const Source &src) const {
```

* [修正後の parsecpp.cpp](https://bitbucket.org/snippets/7shi/o9dep/revisions/47581204d9245b8897a28dbea60cc7928a5692c9)

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

`||`と`left`を組み合わせれば、エラーメッセージがカスタマイズできます。前方参照の関係で定義位置の移動が必要です。

差分を示します。

```diff
--- parsecpp.cpp.orig
+++ parsecpp.cpp
@@ -60,24 +60,6 @@
 
 auto anyChar = satisfy([](char) { return true; });
 
-Parser<char> char1(char ch) {
-    return satisfy([=](char c) { return c == ch; });
-}
-
-bool isDigit   (char ch) { return '0' <= ch && ch <= '9'; }
-bool isUpper   (char ch) { return 'A' <= ch && ch <= 'Z'; }
-bool isLower   (char ch) { return 'a' <= ch && ch <= 'z'; }
-bool isAlpha   (char ch) { return isUpper(ch) || isLower(ch); }
-bool isAlphaNum(char ch) { return isAlpha(ch) || isDigit(ch); }
-bool isLetter  (char ch) { return isAlpha(ch) || ch == '_';   }
-
-auto digit    = satisfy(isDigit   );
-auto upper    = satisfy(isUpper   );
-auto lower    = satisfy(isLower   );
-auto alpha    = satisfy(isAlpha   );
-auto alphaNum = satisfy(isAlphaNum);
-auto letter   = satisfy(isLetter  );
-
 template <typename T1, typename T2>
 Parser<std::string> operator+(const Parser<T1> &x, const Parser<T2> &y) {
     return [=](Source *s) {
@@ -144,11 +126,40 @@
     };
 }
 
+template <typename T>
+Parser<T> left(const std::string &e) {
+    return [=](Source *s) -> T {
+        throw s->ex(e);
+    };
+}
+Parser<char> left(const std::string &e) {
+    return left<char>(e);
+}
+
+Parser<char> char1(char ch) {
+    return satisfy([=](char c) { return c == ch; })
+        || left(std::string("not char '") + ch + "'");
+}
+
 Parser<std::string> string(const std::string &str) {
     return [=](Source *s) {
         for (auto it = str.begin(); it != str.end(); ++it) {
-            char1(*it)(s);
+            (char1(*it) || left("not string \"" + str + "\""))(s);
         }
         return str;
     };
 }
+
+bool isDigit   (char ch) { return '0' <= ch && ch <= '9'; }
+bool isUpper   (char ch) { return 'A' <= ch && ch <= 'Z'; }
+bool isLower   (char ch) { return 'a' <= ch && ch <= 'z'; }
+bool isAlpha   (char ch) { return isUpper(ch) || isLower(ch); }
+bool isAlphaNum(char ch) { return isAlpha(ch) || isDigit(ch); }
+bool isLetter  (char ch) { return isAlpha(ch) || ch == '_';   }
+
+auto digit    = satisfy(isDigit   ) || left("not digit"   );
+auto upper    = satisfy(isUpper   ) || left("not upper"   );
+auto lower    = satisfy(isLower   ) || left("not lower"   );
+auto alpha    = satisfy(isAlpha   ) || left("not alpha"   );
+auto alphaNum = satisfy(isAlphaNum) || left("not alphaNum");
+auto letter   = satisfy(isLetter  ) || left("not letter"  );
```

* [修正後の parsecpp.cpp](https://bitbucket.org/snippets/7shi/o9dep/revisions/4282afab8b71b96924335c39f8433358ec9c33a4)

型推論の弱さを補うため、`left`は特殊化したオーバーロードを実装しています。

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

# おわりに

パーサコンビネータの動作イメージがつかめたでしょうか。

今回のようにテストだけではどう応用して良いのか分からないかもしれません。続編で四則演算器を作っているので、そちらも参考にしてください。

* [C++11 パーサコンビネータ 超入門 2](http://qiita.com/7shi/items/f86f2f7ad68cfff1b399) 2015.11.30
