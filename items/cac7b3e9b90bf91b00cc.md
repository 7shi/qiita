---
coediting: false
comments_count: 13
created_at: '2014-08-20T02:49:49+09:00'
id: cac7b3e9b90bf91b00cc
likes_count: 269
private: false
reactions_count: 0
stocks_count: 260
tags:
- name: C++
  versions:
  - '03'
title: 文字列で学ぶC++入門
updated_at: '2015-11-25T01:15:09+09:00'
url: https://qiita.com/7shi/items/cac7b3e9b90bf91b00cc
slide: false
---

C言語の知識だけを前提にC++の取っ掛かりとなることを目的とします。

※ C++の知識は前提としません。

基本的に、C++はC言語の機能を包含しています。コードの大半をC言語と同じように書いて、一部だけC++の機能を使うことも可能です。

※ このような使い方をbetter Cと呼びます。

C++には文字列を処理するための型があります。言語組み込みの機能ではなく、ライブラリで定義された型です。同じような型を自作することも可能です。

C言語の延長線上で文字列型を自作しながら、C++がC言語をどのように拡張した言語なのか、雰囲気を感じて頂ければと思います。

# 文字列型

C言語とC++で文字列の結合を比較してみます。

## C言語

文字列の結合

```c:1.c
#include <stdio.h>
#include <string.h>

int main(void) {
    char buf[8];
    const char *s1 = "abc";
    const char *s2 = "def";
    strcpy(buf, s1);
    strcat(buf, s2);
    printf("%s\n", buf);
    return 0;
}
```
```text:実行結果
abcdef
```

### 問題点

文字列が長ければバッファをはみ出します。元の文字列が可変で長さが予想できない場合、事前に大きめに取っておくことはできません。

対策1: 切り捨て

```c:2.c
#include <stdio.h>
#include <string.h>

int main(void) {
    char buf[8];
    const char *s1 = "abcde";
    const char *s2 = "fghij";
    int max = sizeof(buf) - 1;
    buf[max] = 0;
    strncpy(buf, s1, max);
    strncat(buf, s2, max - strlen(buf));
    printf("%s\n", buf);
    return 0;
}
```
```text:実行結果
abcdefg
```

対策2: 動的確保（ヒープ）

```c:3.c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(void) {
    const char *s1 = "abcde";
    const char *s2 = "fghij";
    size_t len = strlen(s1) + strlen(s2);
    char *buf = (char *)malloc(len + 1);
    buf[len] = 0;
    strcpy(buf, s1);
    strcat(buf, s2);
    printf("%s\n", buf);
    free(buf);
    return 0;
}
```
```text:実行結果
abcdefghij
```

## C++

C++の標準ライブラリには`std::string`という文字列型が用意されています。
これを使えば、バッファについて何も考える必要はありません。

```cpp:4.cpp
#include <stdio.h>
#include <string>

int main() {
    std::string s1 = "abcde";
    std::string s2 = "fghij";
    std::string buf = s1 + s2;
    printf("%s\n", buf.c_str());
}
```
```text:実行結果
abcdefghij
```

1. C++では引数を`()`と定義すると`(void)`と同じ意味になります。C言語では`()`は任意の引数を取る関数となるため、意味が異なります。
1. C++では`main()`が特別扱いされ、明示的に`return`を書かない場合は`0`を返します。C言語ではC99からC++と同じになりました。
1. `std::string`はそのままでは`printf()`で表示できません。表示するには`.c_str()`で変換します。

# constポインタ

※ C++は基本的にC言語互換のため、ここで述べていることはC言語と共通です。

コード中に記述した文字列は定数のため、書き換えようとしても実行時エラーとなります。

```cpp:5.cpp
int main() {
    char *s = "abc";
    s[1] = 'B';  // 実行時エラー
}
```
※ 処理系依存でエラーにならない環境もあります。

書き換えない文字列にはconstを付けます。そうすればコンパイル時にエラーとなります。

```cpp:6.cpp
int main() {
    const char *s = "abc";
    s[1] = 'B';  // コンパイルエラー
}
```

書き換えたい場合は`char`配列にコピーします。ローカル変数では簡単な書き方があります。

```cpp:7.cpp
#include <stdio.h>

int main() {
    char s[] = "abc";
    s[1] = 'B';  // OK
    printf("%s\n", s);
}
```
```text:実行結果
aBc
```

関数の引数として`const char *`でも`char`配列でも受け付けるには、引数の型を`const char *`にする必要があります。

```cpp:8.cpp
void test1(char *) {}
void test2(const char *) {}

int main() {
    const char *a = "abc";
    char b[] = "abc";
    test1(a);  // エラー
    test1(b);  // OK
    test2(a);  // OK
    test2(b);  // OK
}
```

以後、可能な限り`const`を付けます。

# クラス

C++では構造体が拡張され、中に関数が定義できます。このように拡張された構造体を**クラス**、中に定義される関数を**メンバ関数**と呼びます。構造体のフィールドは**メンバ変数**と呼びます。

メンバ変数の指す文字列を表示するメンバ関数を作ってみます。

```cpp:mystr.cpp
#include <stdio.h>

struct mystr {
    const char *str;

    void printn() {
        printf("%s\n", str);
    }
};

int main() {
    mystr s = { "abc" };
    s.printn();
}
```

メンバ関数がどこのクラスに入っているのか区別するときには、クラス名と`::`を付加します。上の例では`mystr::printn()`となります。

クラスを実体化した変数をインスタンスと呼びます。上の例では`mystr s`の`s`が該当します。

`std::string`もクラスです。これを真似て文字列クラスを自作しながら、C++について勉強していきます。

# コンストラクタ

前の例では構造体と同じ方法で初期化しました。

`std::string`と同じように初期化するには、**コンストラクタ**と呼ばれる特別な関数を定義します。コンストラクタはクラスと同じ名前で、戻り値のない関数です。

```cpp
#include <stdio.h>

struct mystr {
    const char *str;

    mystr(const char *s) {
        str = s;
    }

    void printn() {
        printf("%s\n", str);
    }
};

int main() {
    mystr s = "abc";
    s.printn();
}
```

# ローカルコピー

先ほど作った`mystr`ではポインタを保持しているだけなので、元の値を書き換えると連動します。

```cpp
#include <stdio.h>

struct mystr {
    const char *str;

    mystr(const char *s) {
        str = s;
    }

    void printn() {
        printf("%s\n", str);
    }
};

int main() {
    char buf[] = "abc";
    mystr s = buf;
    buf[0] = 'A';
    s.printn();
}
```
```text:実行結果
Abc
```

それに対して`std::string`では値をローカルコピーしているため、連動しません。

```cpp
#include <stdio.h>
#include <string>

int main() {
    char buf[] = "abc";
    std::string s = buf;
    buf[0] = 'A';
    printf("%s\n", s.c_str());
}
```
```text:実行結果
abc
```

`mystr`でもローカルコピーしてみます。書き換えが前提のためメンバ変数`str`から`const`は外します。

```cpp
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct mystr {
    char *str;

    mystr(const char *s) {
        str = (char *)malloc(strlen(s) + 1);
        strcpy(str, s);
    }

    void printn() {
        printf("%s\n", str);
    }
};

int main() {
    char buf[] = "abc";
    mystr s = buf;
    buf[0] = 'A';
    s.printn();
}
```
```text:実行結果
abc
```

`std::string`と同じ結果になりました。

# デストラクタ

結果は`std::string`と同じようになりましたが、このままでは`malloc()`がやりっ放しのためメモリリークします。

クラスにはスコープアウトするときに自動的に呼ばれる**デストラクタ**という特殊な関数があります。クラス名の前にチルダを付けた関数です。デストラクタ内で`free()`を呼ぶことで、メモリリークを解消できます。

```cpp
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct mystr {
    char *str;

    mystr(const char *s) {
        str = (char *)malloc(strlen(s) + 1);
        strcpy(str, s);
    }

    ~mystr() {
        printf("~mystr: %s\n", str);
        free(str);
    }

    void printn() {
        printf("%s\n", str);
    }
};

int main() {
    char buf[] = "abc";
    mystr s = buf;
    buf[0] = 'A';
    s.printn();
    printf("last of main()\n");
}
```
```text:実行結果
abc
last of main()
~mystr: abc
```

デストラクタがどのタイミングで呼ばれているか確認するため、デストラクタと`main()`の末尾に`printf()`を入れています。スコープアウト時にデストラクタが呼ばれていることが確認できました。

このようにデストラクタを使ってスコープアウト時に後始末するテクニックを[RAII](http://ja.wikipedia.org/wiki/RAII)と呼びます。

# new

C言語ではメモリの確保には`malloc()`と`free()`を使用しました。C++では`new`と`delete`が使用できます。`new`は`malloc()`のようなキャストが不要です。

```cpp
#include <stdio.h>
#include <string.h>

struct mystr {
    char *str;

    mystr(const char *s) {
        str = new char[strlen(s) + 1];
        strcpy(str, s);
    }

    ~mystr() {
        printf("~mystr: %s\n", str);
        delete[] str;
    }

    void printn() {
        printf("%s\n", str);
    }
};

int main() {
    char buf[] = "abc";
    mystr s = buf;
    buf[0] = 'A';
    s.printn();
    printf("last of main()\n");
}
```

# 演算子のオーバーロード `+=`

`std::string`では`+=`で文字列を追加できます。

```cpp
#include <stdio.h>
#include <string>

int main() {
    std::string s1 = "abc";
    s1 += "def";
    printf("%s\n", s1.c_str());
}
```
```text:実行結果
abcdef
```

これは**演算子のオーバーロード**という機能によって実装されています。具体的には`operator+=()`という関数を定義します。

```cpp
#include <stdio.h>
#include <string.h>

struct mystr {
    char *str;

    mystr(const char *s) {
        str = new char[strlen(s) + 1];
        strcpy(str, s);
    }

    ~mystr() {
        delete[] str;
    }

    void printn() {
        printf("%s\n", str);
    }

    void operator+=(const char *s) {
        char *old = str;
        int len = strlen(str) + strlen(s);
        str = new char[len + 1];
        strcpy(str, old);
        strcat(str, s);
        delete[] old;
    }
};

int main() {
    mystr s1 = "abc";
    s1 += "def";
    s1.printn();
}
```
```text:実行結果
abcdef
```

# 参照

C++には参照という機能があります。値を取り出すのにデリファレンスが必要ないポインタです。

```cpp
#include <stdio.h>
#include <string.h>

void testp() {
    printf("testp\n");
    int a = 1;
    int *b = &a;
    printf("a = %d, b = %d\n", a, *b);
    a = 2;
    printf("a = %d, b = %d\n", a, *b);
    *b = 3;
    printf("a = %d, b = %d\n", a, *b);
}

void testr() {
    printf("testr\n");
    int a = 1;
    int &b = a;
    printf("a = %d, b = %d\n", a, b);
    a = 2;
    printf("a = %d, b = %d\n", a, b);
    b = 3;
    printf("a = %d, b = %d\n", a, b);
}

int main() {
    testp();
    testr();
}
```
```text:実行結果
testp
a = 1, b = 1
a = 2, b = 2
a = 3, b = 3
testr
a = 1, b = 1
a = 2, b = 2
a = 3, b = 3
```

※ `testp()`はポインタ、`testr()`は参照を使い、同じ処理を行っています。

参照はクラスに対しても使うことができます。

```cpp
#include <stdio.h>
#include <string.h>

struct mystr {
    char *str;
    （略）
};

void testp() {
    printf("testp\n");
    mystr a = "abc";
    mystr *b = &a;
    printf("a = %s, b = %s\n", a.str, b->str);
    a += "def";
    printf("a = %s, b = %s\n", a.str, b->str);
    *b += "ghi";
    printf("a = %s, b = %s\n", a.str, b->str);
}

void testr() {
    printf("testr\n");
    mystr a = "abc";
    mystr &b = a;
    printf("a = %s, b = %s\n", a.str, b.str);
    a += "def";
    printf("a = %s, b = %s\n", a.str, b.str);
    b += "ghi";
    printf("a = %s, b = %s\n", a.str, b.str);
}

int main() {
    testp();
    testr();
}
```
```text:実行結果
testp
a = abc, b = abc
a = abcdef, b = abcdef
a = abcdefghi, b = abcdefghi
testr
a = abc, b = abc
a = abcdef, b = abcdef
a = abcdefghi, b = abcdefghi
```

## 引数での参照

関数に参照を渡して書き換えることもできます。

※ このような使い方は非推奨です。詳細は後述。

```cpp
#include <stdio.h>

void inc(int &x) {
    ++x;
}

int main() {
    int a = 1;
    inc(a);
    printf("%d\n", a);
}
```
```
2
```

呼び出し側のコードを見るだけでは変数が書き換えられることが分かりません。意図しない変数の書き換えを防止するため、引数を参照で渡すことは避けます。

何らかの事情で引数で渡した変数を書き換えたい場合にはポインタを使います。

```cpp
#include <stdio.h>

void inc(int *x) {
    ++*x;
}

int main() {
    int a = 1;
    inc(&a);
    printf("%d\n", a);
}
```
```text:実行結果
2
```

※ ポインタの場合、呼び出し側で明示的にアドレスを取っているため、書き換えの意図が明白です。

## const参照

参照に`const`を付けると書き換えられない参照となります。

```cpp
int main() {
    int a = 1;
    const int &b = a;
    b = 2;  // エラー
}
```

`const`ポインタを受け取る関数は、原則としてポインタの示す先を書き換えないことが期待されます。

同様に`const`参照を受け取る関数も、参照の示す先を書き換えないことが期待されます。引数で参照を使うべきでない理由は意図しない変数の書き換えの防止ですが、`const`参照であれば問題ありません。

```cpp
#include <stdio.h>
#include <string.h>

struct mystr {
    （略）
};

void test(const mystr &s) {
    printf("%s\n", s.str);
}

int main() {
    mystr s = "abc";
    test(s);
}
```

## constメンバ関数

上の例では`test()`内で`printf()`を呼んでいますが、代わりに`mystr::printn()`を呼ぶとエラーになります。

```cpp
void test(const mystr &s) {
    s.printn();  // エラー
}
```

`s`が`const`なのに`mystr::printn()`が`const`でないためエラーとなります。メンバ関数が`const`であるということは、メンバ変数の値を変更しないということを意味します。`operator+=()`のようなものは値を変更するため`const`指定できません。

メンバ関数の`const`は引数の後で指定します。

```cpp
    void printn() const {
        printf("%s\n", str);
    }
```

このように指定されたメンバ関数を**constメンバ関数**と呼びます。戻り値の型が`const`であるかには関係ないことに注意してください。

## まとめ

1. クラスを引数で渡すとき、値を変更しない場合は`const`参照を使用する。
1. `const`参照で渡されたインスタンスは、`const`メンバ関数しか使用できない。

# コピーコンストラクタ

`std::string`同士は代入できます。それぞれの変数は独立しているため、参照と異なり値は連動しません。

```cpp
#include <stdio.h>
#include <string>

int main() {
    std::string s1 = "abc";
    std::string s2 = s1;
    s1 += "def";
    s2 += "ghi";
    printf("s1: %s\n", s1.c_str());
    printf("s2: %s\n", s2.c_str());
}
```
```text:実行結果
s1: abcdef
s2: abcghi
```

代入を実現するには、自分自身の型の`const`参照を引数に取るコンストラクタを追加します。このようなコンストラクタを**コピーコンストラクタ**と呼びます。

```cpp
#include <stdio.h>
#include <string.h>

struct mystr {
    char *str;

    mystr(const char *s) {
        str = new char[strlen(s) + 1];
        strcpy(str, s);
    }

    mystr(const mystr &s) {
        str = new char[strlen(s.str) + 1];
        strcpy(str, s.str);
    }

    ~mystr() {
        delete[] str;
    }

    void printn() const {
        printf("%s\n", str);
    }

    void operator+=(const char *s) {
        char *old = str;
        int len = strlen(str) + strlen(s);
        str = new char[len + 1];
        strcpy(str, old);
        strcat(str, s);
        delete[] old;
    }
};

int main() {
    mystr s1 = "abc";
    mystr s2 = s1;
    s1 += "def";
    s2 += "ghi";
    printf("s1: %s\n", s1.str);
    printf("s2: %s\n", s2.str);
}
```

# this

`+=`演算子は多重に呼び出すことが可能です。

```cpp
#include <stdio.h>

int main() {
    int i = 1;
    (i += 3) += 5;
    printf("i = %d\n", i);
}
```
```text:実行結果
9
```

`std::string`でも可能です。

```cpp
#include <stdio.h>
#include <string>

int main() {
    std::string s = "abc";
    (s += "def") += "ghi";
    printf("s = %s\n", s.c_str());
}
```
```text:実行結果
abcdefghi
```

`mystr`ではエラーになります。

```cpp
#include <stdio.h>
#include <string.h>

struct mystr {
    （略）
};

int main() {
    mystr s = "abc";
    (s += "def") += "ghi";  // エラー
    printf("s = %s\n", s.str);
}
```

`operator+=()`の戻り値として自分自身のインスタンスへの参照を返せば、エラーはなくなります。

メンバ変数の中で自分自身のインスタンスへのポインタは`this`で取得できます。
これはC++の機能で、何も準備しなくても使用できます。ポインタから参照にするため、`this`をデリファレンスしています。

```cpp
    mystr &operator+=(const char *s) {
        char *old = str;
        int len = strlen(str) + strlen(s);
        str = new char[len + 1];
        strcpy(str, old);
        strcat(str, s);
        delete[] old;
        return *this;
    }
```

# 代入

先に変数の宣言だけを行って、後で代入するということはよくあります。

```cpp
#include <stdio.h>
#include <string>

int main() {
    std::string s;
    s = "abc";
    printf("%s\n", s.c_str());
}
```
```text:実行結果
abc
```

初期値を与えずに変数を宣言するには、引数が空のコンストラクタが必要です。

```cpp
    mystr() {
        str = new char[1];
        str[0] = 0;
    }
```

代入は`=`演算子をオーバーロードします。

```cpp
    mystr &operator=(const char *s) {
        delete[] str;
        str = new char[strlen(s) + 1];
        strcpy(str, s);
        return *this;
    }
```

後で代入できるようになりました。

```cpp
int main() {
    mystr s;
    s = "abc";
    s.printn():
}
```
```text:実行結果
abc
```

## コンストラクタの改造

コンストラクタから代入を使えば、コードが簡単になります。

```cpp
    mystr() {
        str = NULL;
        *this = "";
    }

    mystr(const char *s) {
        str = NULL;
        *this = s;
    }

    mystr(const mystr &s) {
        str = NULL;
        *this = s.str;
    }
```

`str`に`NULL`を入れて代入しています。代入を処理する`operator=()`の冒頭で`str`を`delete`しています。C++の言語仕様で`NULL`の`delete`は無視すると決められているため、`NULL`チェックしなくても問題ありません。

# メンバ変数の追加

あちこちで`strlen()`を使用しています。メンバ変数で長さを保持すれば`strlen()`の使用回数を減らすことができます。

```cpp
#include <stdio.h>
#include <string.h>

struct mystr {
    char *str;
    size_t len;

    mystr() {
        str = NULL;
        *this = "";
    }

    mystr(const char *s) {
        str = NULL;
        *this = s;
    }

    mystr(const mystr &s) {
        str = NULL;
        *this = s.str;
    }

    ~mystr() {
        delete[] str;
    }

    void printn() const {
        printf("%s\n", str);
    }

    mystr &operator+=(const char *s) {
        char *old = str;
        len += strlen(s);
        str = new char[len + 1];
        strcpy(str, old);
        strcat(str, s);
        delete[] old;
        return *this;
    }

    mystr &operator=(const char *s) {
        delete[] str;
        len = strlen(s);
        str = new char[len + 1];
        strcpy(str, s);
        return *this;
    }
};

int main() {
    mystr s1 = "abc";
    mystr s2 = s1;
    s1 += "def";
    s2 += "ghi";
    printf("s1[%d]=%s\n", s1.len, s1.str);
    printf("s2[%d]=%s\n", s2.len, s2.str);
}
```
```text:実行結果
s1[6]=abcdef
s2[6]=abcghi
```

このように後で何度も必要になる情報は、あらかじめメンバ変数に入れておくと便利です。

# 関数のオーバーロード

`operator+=()`の引数は`const char *`のため、`mystr`に`mystr`を追加するには`str`を取り出します。

```cpp
int main() {
    mystr s = "abc";
    s += s.str;
    printf("s[%d]: %s\n", s.len, s.str);
}
```

C++では名前が同じで引数が異なる関数を定義できます。これを関数のオーバーロードと呼びます。

引数が`const mystr &`の`operator+=()`を追加します。

```cpp
    mystr &operator+=(const mystr &s) {
        char *old = str;
        len += s.len;
        str = new char[len + 1];
        strcpy(str, old);
        strcat(str, s.str);
        delete[] old;
        return *this;
    }
```

これで`mystr`が直接追加できるようになりました。

```cpp
    s += s;
```

## コードの整理

関数をどんどん追加したため、同じようなコードがあちこちにあります。無駄が多いため整理します。ついでに`operator=()`もオーバーロードします。

```cpp:mystr.cpp
#include <stdio.h>
#include <string.h>

struct mystr {
    char *str;
    size_t len;

    mystr() {
        str = NULL;
        *this = "";
    }

    mystr(const char *s) {
        str = NULL;
        *this = s;
    }

    mystr(const mystr &s) {
        str = NULL;
        *this = s;
    }

    ~mystr() {
        delete[] str;
    }

    void printn() const {
        printf("%s\n", str);
    }

    void set(const char *s, size_t newlen) {
        char *old = str;
        len = newlen;
        str = new char[len + 1];
        strcpy(str, s);
        delete[] old;
    }

    mystr &operator+=(const char *s) {
        set(str, len + strlen(s));
        strcat(str, s);
        return *this;
    }

    mystr &operator+=(const mystr &s) {
        set(str, len + s.len);
        strcat(str, s.str);
        return *this;
    }

    mystr &operator=(const char *s) {
        set(s, strlen(s));
        return *this;
    }

    mystr &operator=(const mystr &s) {
        set(s.str, s.len);
        return *this;
    }
};

int main() {
    mystr s = "abc";
    s += s;
    s = s;
    printf("s[%d]: %s\n", s.len, s.str);
}
```
```text:実行結果
s[6]=abcabc
```

# 引数の自動変換

`mystr`のコンストラクタでは`const char *`を受け付けます。引数として`const mystr &`を取る関数を呼び出すとき、コンストラクタが自動的に`const char *`から`mystr`に変換してくれます。

```cpp
void test(const mystr &s) {
    s.printn();
}

int main() {
    test("abc");
}
```
```text:実行結果
abc
```

引数として一時的に作成されたインスタンスは、関数呼び出し後に自動的に破棄されます。

デストラクタでログを出力すれば確認できます。

```cpp
    ~mystr() {
        printf("~mystr: %s\n", str);
        delete[] str;
    }
```
```text:実行結果
abc
~mystr: abc
```

関数を呼び出すときに`const char *`から自動的に作成されたインスタンスの破棄が確認できました。

※ コンストラクタでもログを表示すればもっと分かりやすいと思います。各自確認してみてください。

# 引数のコピー

引数で`const`参照を使うとどのようなメリットがあるのでしょうか。先ほどデストラクタにログを仕込みましたが、それをそのまま使用します。

もしintなどと同じように修飾子を付けなければ、引数はコピーされて新しいインスタンスが作られます。

```cpp
void test(mystr s) {
    s.printn();
}

int main() {
    mystr s = "abc";
    test(s);
    printf("last of main()\n");
}
```
```text:実行結果
abc
~mystr: abc
last of main()
~mystr: abc
```

`const`参照で渡せばコピーは発生しません。

```cpp
void test(const mystr &s) {
```
```text:実行結果
abc
last of main()
~mystr: abc
```

このように引数で`const`参照を使うことで、関数呼び出し時の無駄なコピーを抑制できます。

※ コンストラクタでもログを表示すればもっと分かりやすいと思います。各自確認してみてください。

# 演算子のオーバーロード `+`

`std::string`では文字列同士が`+`で連結できます。

```cpp
#include <stdio.h>
#include <string>

int main() {
    std::string s1 = "abcde";
    std::string s2 = "fghij";
    std::string buf = s1 + s2;
    printf("%s\n", buf.c_str());
}
```

同じことができるようにするには`+`演算子をオーバーロードします。

```cpp
    mystr operator+(const mystr &s) const {
        mystr ret = *this;
        ret += s;
        return ret;
    }
```

`+`演算子は新しいインスタンスを返しているため、自分自身のメンバ変数に影響を与えません。そのため`const`を指定しています。

動作を確認します。

```cpp
int main() {
    mystr s1 = "abcde";
    mystr s2 = "fghij";
    mystr buf = s1 + s2;
    buf.printn();
}
```
```text:実行結果
abcdefghij
```

## 非メンバ関数

演算子のオーバーロードをクラスの外に出すことも可能です。`operator+()`を外に出した例です。

```cpp
mystr operator+(const mystr &s1, const mystr &s2) {
    mystr ret = s1;
    ret += s2;
    return ret;
}
```

メンバ関数でオーバーロードするときと動作は同じに見えます。外に出すメリットは第一引数に融通が利くようになることです。コンストラクタの引数にできる型は自動的にクラスに変換されるため、次のようなコードが受け付けられるようになります。

```cpp
int main() {
    mystr a = "abc";
    mystr b = "123" + a;
    printf("%s\n", b.c_str());
}
```

メンバ関数でオーバーロードすると`"123" + a`はエラーになります。クラスを使うときの利便性を考えると、二項演算子はクラスの外で定義する方が便利です。

# 部分文字列

`std::string`は`substr()`で部分文字列が得られます。

```cpp
#include <stdio.h>
#include <string>

int main() {
    std::string s1 = "abcdefg";
    std::string s2 = s1.substr(2, 3);
    printf("%s\n", s2.c_str());
}
```
```text:実行結果
cde
```

`mystr`にも`substr()`を実装します。

```cpp
    mystr substr(int start, int len) const {
        mystr ret;
        ret.set("", len);
        strncpy(ret.str, &str[start], len);
        ret.str[len] = 0;
        return ret;
    }
```

動作を確認します。

```cpp
int main() {
    mystr s1 = "abcdefg";
    mystr s2 = s1.substr(2, 3);
    s2.printn();
}
```
```text:実行結果
cde
```

必要に応じてメンバ関数を定義していけば、色々なことができるようになります。

# バッファの拡張

長い文字列を作成して実行時間を計測します。

まずは`std::string`です。10万文字ですが一瞬で終わります。

```cpp
#include <stdio.h>
#include <time.h>
#include <string>

int main() {
    double t1 = (double)clock();
    std::string s;
    for (int i = 0; i < 100000; ++i)
        s += "a";
    double t2 = (double)clock();
    printf("%.2fs\n",
        (t2 - t1) / CLOCKS_PER_SEC);
}
```
```text:実行結果（環境依存）
0.06s
```

`mystr`で試すと100倍ほど遅いです。

```cpp
#include <stdio.h>
#include <string.h>
#include <time.h>

struct mystr {
    （略）
};

int main() {
    double t1 = (double)clock();
    mystr s;
    for (int i = 0; i < 100000; ++i)
        s += "a";
    double t2 = (double)clock();
    printf("%.2fs\n",
        (t2 - t1) / CLOCKS_PER_SEC);
}
```
```text:実行結果（環境依存）
7.08s
```

文字を追加するたびにバッファを作り直してコピーしているのが原因です。

サイズに余裕を持ってバッファを作成しておき、溢れたときだけ拡張すれば、無駄なコピーが減って高速化します。

バッファサイズを保持するメンバ変数を追加します。

```cpp
    size_t buflen;
```

バッファサイズの最小値を`16`として、不足すれば収まるまで倍に拡張します。
`set()`を修正します。

```cpp
    void set(const char *s, size_t newlen) {
        char *old = str;
        len = newlen;
        if (!old || buflen < len) {
            if (!old) buflen = 16;
            while (buflen < len)
                buflen += buflen;
            str = new char[buflen + 1];
        }
        if (str != s) strcpy(str, s);
        if (old != str) delete[] old;
    }
```
```text:実行結果（環境依存）
2.16s
```

3倍近く改善しましたが、まだ遅いです。`strcat()`で追加位置を探すのが無駄なので修正します。

```cpp
    mystr &operator+=(const char *s) {
        int oldlen = len;
        set(str, len + strlen(s));
        strcpy(&str[oldlen], s);
        return *this;
    }

    mystr &operator+=(const mystr &s) {
        int oldlen = len;
        set(str, len + s.len);
        strcpy(&str[oldlen], s.str);
        return *this;
    }
```
```text:実行結果（環境依存）
0.01s
```

劇的に改善しました。長さを保持しているのが効いています。文字の追加が高速なので、Javaや.NETのような`StringBuilder`は不要です。

# アクセス制御

説明の都合上`main()`の中を空にします。

```cpp
#include <stdio.h>
#include <string.h>

struct mystr {
    （略）
};

int main() {
}
```

構造体を拡張するという方法でクラスを説明してきたため、定義には`struct`を使っていました。

```cpp
struct mystr {
```

C++には`class`というキーワードもあります。単純に書き換えてみます。

```cpp
class mystr {
```

特に問題なくコンパイルが通ります。このように`class`の文法自体は`struct`と互換です。

違いを見ていきます。

`main()`の中でクラスを使ってみます。

```cpp
int main() {
    mystr s;
}
```

エラーになって型が使えません。`class`のコンストラクタが外部から呼び出せないためです。

公開する部分は明示的に`public`と指定します。具体的には、コンストラクタの前に`public:`と追加すれば、エラーが解消します。

```cpp
class mystr {
    char *str;
    size_t length;
    size_t buflen;

public:
    mystr() {
        str = NULL;
        *this = "";
    }
```

`public:`と記述すれば、それ以降に定義されているメンバにはすべて適用されます。逆に言えば、それ以前に定義されているものは外部から使えません。

```cpp
class mystr {
    非公開

public:
    公開
};
```

【注】JavaやC#ではメンバごとにアクセス制御を指定しますが、C++では個別指定ではありません。一度指定するとそれ以降のすべてに適用されます。

このように公開と非公開を明確に明確に区別することで、外部から触られたくないメンバを隠します。これをアクセス制御と呼びます。

非公開を明示的に指定するのは`private`です。

```cpp
class mystr {
private:
    非公開

public:
    公開
};
```

`class`はデフォルトが`private`と決まっているため、指定しなければ自動的に`private`となります。

```cpp
class mystr {
    非公開

public:
    公開
};
```

`struct`はデフォルトが`public`のため、指定しなければ自動的に`public`となります。

```cpp
struct mystr {
    公開

private:
    非公開
};
```

このようにC++での`struct`と`class`の違いは、デフォルトが`public`か`private`かだけです。混乱を招かないためにも、デフォルトに任せて省略せずに明示することが一般的です。

途中で何度でも切り替えられます。

```cpp
class mystr {
private:
    非公開

public:
    公開

private:
    非公開
};
```

アクセス制御の効果を確認します。`len`は非公開部分のためクラス外からは使えません。`printn()`は公開部分のためクラス外からも使えます。

```cpp
int main() {
    mystr s = "abc";
    printf("[%d]", s.len);  // エラー
    s.printn();             // OK
}
```

【注】アクセス制御には`protected`もありますが、今回は継承を扱わないため、説明を省略します。

## アクセサ

クラス外から長さを確認するケースも多いです。そのような場合、長さを返すだけの関数を定義します。

```cpp
class mystr {
    char *str;
    size_t len;
    size_t buflen;

public:
    size_t length() const { return len; }
```

このように非公開のメンバ変数にアクセスするための関数をアクセサと呼びます。

動作を確認します。

```cpp
int main() {
    mystr s = "abc";
    printf("[%d]", s.length());
    s.printn();
}
```
```text:実行結果
[3]abc
```

同様に`str`もアクセサで外部に公開します。`set()`は内部だけで使用するため非公開にします。

ここまでのソース全体を掲載します。

```cpp:mystr.cpp
#include <stdio.h>
#include <string.h>

class mystr {
private:
    char *str;
    size_t len;
    size_t buflen;

public:
    const char *c_str() const { return str; }
    size_t length() const { return len; }

    mystr() {
        str = NULL;
        *this = "";
    }

    mystr(const char *s) {
        str = NULL;
        *this = s;
    }

    mystr(const mystr &s) {
        str = NULL;
        *this = s;
    }

    ~mystr() {
        delete[] str;
    }

    void printn() const {
        printf("%s\n", str);
    }

private:
    void set(const char *s, size_t newlen) {
        char *old = str;
        len = newlen;
        if (!old || buflen < len) {
            if (!old) buflen = 16;
            while (buflen < len)
                buflen += buflen;
            str = new char[buflen + 1];
        }
        if (str != s) strcpy(str, s);
        if (old != str) delete[] old;
    }

public:
    mystr &operator+=(const char *s) {
        int oldlen = len;
        set(str, len + strlen(s));
        strcpy(&str[oldlen], s);
        return *this;
    }

    mystr &operator+=(const mystr &s) {
        int oldlen = len;
        set(str, len + s.len);
        strcpy(&str[oldlen], s.str);
        return *this;
    }

    mystr &operator=(const char *s) {
        set(s, strlen(s));
        return *this;
    }

    mystr &operator=(const mystr &s) {
        set(s.str, s.len);
        return *this;
    }

    mystr substr(int start, int len) const {
        mystr ret;
        ret.set("", len);
        strncpy(ret.str, &str[start], len);
        ret.str[len] = 0;
        return ret;
    }
};

mystr operator+(const mystr &s1, const mystr &s2) {
    mystr ret = s1;
    ret += s2;
    return ret;
}

int main() {
    mystr s = "abc";
    printf("[%d]%s\n", s.length(), s.c_str());
}
```

## カプセル化

先ほどの例を見て
「わざわざ`length()`など作らずに、`len`を`public`にすれば良いのではないか？」
と感じられたかもしれません。

もし`len`が`public`なら値を勝手に書き換えられます。

```cpp
int main() {
    mystr s = "abc";
    s.len = 2;
    printf("[%d]%s\n", s.length(), s.c_str());
}
```
```text:実行結果
[2]abc
```

`abc`は3文字なのに長さが2となっています。このような矛盾を防ぐため、データを管理するメンバ変数は`private`にして、操作は`public`なメンバ関数だけから行うようにするわけです。

つまり公開されたメンバ関数の使い方だけを提示して、内部でどんなメンバ変数が管理されているかは伏せるということです。そうすれば、もし効率化などの理由で内部の管理方法を変えても、利用側のコードに影響を与えません。

このように内部構造の変化が外部に影響を与えないようにする設計方針を**カプセル化**と呼びます。隠すこと自体が目的ではなく、安全性の結果だと言えます。

# 参照カウント

巨大な文字列を代入して時間を計測します。

まずは`std::string`です。10万文字を10万回代入しますが、少し掛かります。

```cpp
#include <stdio.h>
#include <time.h>
#include <string>

int main() {
    std::string s1, s2;
    for (int i = 0; i < 100000; ++i)
        s1 += "a";
    double t1 = (double)clock();
    for (int i = 0; i < 100000; ++i)
        s2 = s1;
    double t2 = (double)clock();
    printf("%.2fs\n",
        (t2 - t1) / CLOCKS_PER_SEC);
}
```
```text:実行結果（環境依存）
2.36s
```

`mystr`で試すと数倍遅いです。

```cpp
#include <stdio.h>
#include <string.h>
#include <time.h>

class mystr {
    （略）
};

int main() {
    mystr s1, s2;
    for (int i = 0; i < 100000; ++i)
        s1 += "a";
    double t1 = (double)clock();
    for (int i = 0; i < 100000; ++i)
        s2 = s1;
    double t2 = (double)clock();
    printf("%.2fs\n",
        (t2 - t1) / CLOCKS_PER_SEC);
}
```
```text:実行結果（環境依存）
6.97s
```

代入でバッファをコピーしないで使い回せば高速になります。しかしデストラクタでバッファを解放する際に、他から参照されているかどうかを考慮しなければいけません。

一番簡単なのは、バッファが共有された数を記録しておいて、ゼロになれば解放する方法です。このような方法を参照カウントと呼びます。

バッファ操作で参照カウントを増減します。変更部分を掲載します。

```cpp
class mystr {
private:
    （略）
    int *refcount;

public:
    （略）
    ~mystr() {
        unset(str);
    }
    （略）

private:
    void set(const char *s, size_t newlen) {
        char *old = str;
        len = newlen;
        if (!old || buflen < len) {
            if (!old) buflen = 16;
            while (buflen < len)
                buflen += buflen;
            str = new char[buflen + 1];
        }
        if (str != s) strcpy(str, s);
        if (old != str) {
            unset(old);
            refcount = new int(1);
        }
    }

    void unset(char *str) {
        if (str && --*refcount == 0) {
            delete refcount;
            delete[] str;
        }
    }

public:
    （略）
    mystr &operator=(const mystr &s) {
        unset(str);
        str = s.str;
        len = s.len;
        buflen = s.buflen;
        ++*(refcount = s.refcount);
        return *this;
    }
    （略）
};
```
```text:実行結果（環境依存）
0.01s
```

コピーが発生しなくなったため、一瞬で終わるようになりました。

## new

先ほどのコードに`new int(1)`が出てきました。`(1)`は初期値です。

C++|C言語
---|---
`int *a = new int(1);`|`int *a = (int *)malloc(sizeof(int)); *a = 1;`
`delete a;`|`free(a);`

初期値は省略できます。その場合、値は不定です。

```cpp
int *a = new int;
```

先に出て来た`new char[...]`は個数指定の配列です。

C++|C言語
---|---
`int *a = new int[5];`|`int *a = (int *)malloc(5 * sizeof(int));`
`a[1] = 2;`|`a[1] = 2;`
`delete[] a;`|`free(a);`

配列の解放は`delete`に`[]`を付けることに注意してください。

# コピーオンライト

単純にバッファを共有すると、変更まで共有されてしまいます。しかし`len`は共有されていないため、長さは連動せずにおかしくなります。

```cpp
int main() {
    mystr s1 = "abc";
    mystr s2 = s1;
    s1 += "def";
    printf("s1[%d]%s\n", s1.length(), s1.c_str());
    printf("s2[%d]%s\n", s2.length(), s2.c_str());
}
```
```text:実行結果
s1[6]abcdef
s2[3]abcdef
```

変更が発生したときにコピーすれば回避できます。この方式をコピーオンライト(CoW)と呼びます。

```cpp
    void set(const char *s, size_t newlen) {
        char *old = str;
        len = newlen;
        if (!old || buflen < len) {
            if (!old) buflen = 16;
            while (buflen < len)
                buflen += buflen;
            str = new char[buflen + 1];
        } else if (*refcount > 1) {
            str = new char[buflen + 1];
        }
        if (str != s) strcpy(str, s);
        if (old != str) {
            unset(old);
            refcount = new int(1);
        }
    }
```
```text:実行結果
s1[6]abcdef
s2[3]abc
```

変更しようとした側が参照カウント数を調べて、`1`より大きければ新たにバッファを作ります。これによりコピー後の変更にも連動しなくなりました。

ここまでのソースは「まとめ」に掲載します。

※ C++11の標準ライブラリの文字列クラスでは参照カウントやコピーオンライトが禁止されたそうです。

* [@ezoeryou](https://twitter.com/ezoeryou): [本の虫: C++03とC++11の違い: 文字列ライブラリ編](http://cpplover.blogspot.jp/2013/12/c03c11_29.html) 2013.12.29

## 部分文字列

開始位置を管理することで`substr()`もコピーオンライトの対象にすることが可能です。頻繁に部分文字列にアクセスするようなケースでの高速化が期待できます。

ただし文字列末尾のヌル終端が付いて来ないため、`c_str()`のタイミングでコピーをすることになります。

興味があれば実装して時間を計測してみると良いでしょう。

※ Javaでは開始位置で部分文字列を管理する方式をやめたそうです。

* [@yujisoftware](https://twitter.com/yujisoftware): [Java7 Update6 で String クラスがさらにリファクタリングされていました](http://d.hatena.ne.jp/chiheisen/20120827/1346075977) 2012.8.27

# まとめ

今回作成したコードを掲載します。

* http://ideone.com/X1nO6c

C言語の文字列処理から出発して文字列クラスを作成する過程を見てきました。

クラスを外側から見ればC言語とC++はまったく異なる言語のように見えますが、クラスの中を追っていけば最終的な処理はC言語と大差ありません。

そのようなつながりをイメージするきっかけになることを目指して、この資料を作成しました。

# 練習

## 複素数

次のように複素数計算をするクラス`Complex`を作成してください。`i(0, 1)`は複数の引数を持つコンストラクタで初期化する書き方です。

```cpp:complex.cpp
int main() {
    Complex i(0, 1);
    Complex a = 1 + 2*i;
    Complex b = 3 + 4*i;
    Complex c = a + b;
    Complex d = a * b;
    Complex e = a - 1;
    Complex f = a - 2*i;
    printf("a = %s\n", a.str().c_str());
    printf("b = %s\n", b.str().c_str());
    printf("c = %s\n", c.str().c_str());
    printf("d = %s\n", d.str().c_str());
    printf("e = %s\n", e.str().c_str());
    printf("f = %s\n", f.str().c_str());
}
```
```text:実行結果
a = 1+2i
b = 3+4i
c = 4+6i
d = -5+10i
e = 2i
f = 1
```

解答例: http://ideone.com/jTrhdn

## 分数

次のように分数計算をするクラス`Frac`を作成してください。

```cpp:frac.cpp
int main() {
    Frac a(1, 2);
    Frac b(1, 3);
    Frac c = a + b;
    Frac d = a * b;
    Frac e = d * 15;
    Frac f = e.reduce();
    Frac g = f * 2;
    Frac h = g.reduce();
    printf("a = %s\n", a.str().c_str());
    printf("b = %s\n", b.str().c_str());
    printf("c = %s\n", c.str().c_str());
    printf("d = %s\n", d.str().c_str());
    printf("e = %s\n", e.str().c_str());
    printf("f = %s\n", f.str().c_str());
    printf("g = %s\n", g.str().c_str());
    printf("h = %s\n", h.str().c_str());
}
```
```text:実行結果
a = 1/2
b = 1/3
c = 5/6
d = 1/6
e = 15/6
f = 5/2
g = 10/2
h = 5
```

解答例: http://ideone.com/CA5gEb

# 関連記事

似たような主旨でもっと本格的な実装に取り組んだ記事です。

* @YSRKEN: [std::stringの実装に学ぶC++入門](http://qiita.com/YSRKEN/items/dd3b11e4670bb2b829a5) 2015.11.04
