---
coediting: false
comments_count: 2
created_at: '2019-12-09T21:32:50+09:00'
id: def164cfc3ef4b08ccc8
likes_count: 6
private: false
reactions_count: 0
stocks_count: 4
tags:
- name: C++
  versions: []
title: privateメンバへアクセスするコードの調査
updated_at: '2019-12-11T17:40:59+09:00'
url: https://qiita.com/7shi/items/def164cfc3ef4b08ccc8
slide: false
---

C++ でテンプレートの明示的実体化を利用した private メンバへのアクセスを調べます。

# 発端

次の記事を見てこの手法を知りました。

* [C++: private メンバにアクセス - テンプレート明示的実体化の時に private メンバのポインタが取れる - TBD](https://akinomyoga.hatenablog.com/entry/2019/12/07/171819)

この記事には次のコードが掲載されており、これを解読するのに手間取ったため、記録を残しておきます。

```c++:memptr.cc
#include <iostream>

class A { int a = 12345; };

int A::*memptr;
template<int A::*mp> struct Initializer { inline static auto dummy = memptr = mp; };
template struct Initializer<&A::a>;

int main() {
  A obj;
  std::cout << obj.*memptr << std::endl;
}
```

# コンパイラ

手元の環境（WSL）では g++ が古くてコンパイルに失敗しました。

```text
$ g++ --version
g++ (Ubuntu 5.4.0-6ubuntu1~16.04.12) 5.4.0 20160609
（略）
$ g++ -std=c++17 memptr.cc
memptr.cc:6:79: error: ‘dummy’ declared as an ‘inline’ field
（略）
```

どうやら C++17 の `inline` を認識していないようです。

* [インライン変数 - cpprefjp C++日本語リファレンス](https://cpprefjp.github.io/lang/cpp17/inline_variables.html)

g++ をバージョンアップするのは別の機会にして、今回は clang を使います。

```text
$ clang++-6.0 --version
clang version 6.0.0-1ubuntu2~16.04.1 (tags/RELEASE_600/final)
（略）
$ clang++-6.0 -std=c++17 memptr.cc
$ ./a.out
12345
```

# 書き換え

別の記事のコードを書き換えたとのことなので、その過程を追います。

* [litb's Blog: Access to private members. That's easy!](http://bloglitb.blogspot.com/2010/07/access-to-private-members-thats-easy.html)

```c++
#include <iostream>

template<typename Tag>
struct result {
  /* export it ... */
  typedef typename Tag::type type;
  static type ptr;
};

template<typename Tag>
typename result<Tag>::type result<Tag>::ptr;

template<typename Tag, typename Tag::type p>
struct rob : result<Tag> {
  /* fill it ... */
  struct filler {
    filler() { result<Tag>::ptr = p; }
  };
  static filler filler_obj;
};

template<typename Tag, typename Tag::type p>
typename rob<Tag, p>::filler rob<Tag, p>::filler_obj;

struct A {
private:
  void f() {
    std::cout << "proof!" << std::endl;
  }
};

struct Af { typedef void(A::*type)(); };
template class rob<Af, &A::f>;

int main() {
  A a;
  (a.*result<Af>::ptr)();
}
```

最初に見たとき、解読のためにどこから手を付ければ良いのかなと思いました。

## inline

まず先ほど古いコンパイラで引っ掛かった `inline` を使って書き換えます。クラスの外で静的メンバの実体を宣言する必要がなくなります。

```c++
template<typename Tag>
struct result {
  /* export it ... */
  typedef typename Tag::type type;
  inline static type ptr;  // 変更
};

template<typename Tag, typename Tag::type p>
struct rob : result<Tag> {
  /* fill it ... */
  struct filler {
    filler() { result<Tag>::ptr = p; }
  };
  inline static filler filler_obj;  // 変更
};
```

かなりすっきりしたと思ったのですが、うまく動かなくなりました。

```text
$ ./a.out
Segmentation fault (core dumped)
```

`rob` の明示的実体化の際に `filler_obj` のコンストラクタが呼ばれなくなったようです。

## コンストラクタの引数

コンストラクタにダミー引数を追加して初期化時に呼び出します。

```c++
template<typename Tag, typename Tag::type p>
struct rob : result<Tag> {
  /* fill it ... */
  struct filler {
    filler(int dummy) { result<Tag>::ptr = p; }  // ダミー引数を追加
  };
  inline static filler filler_obj = 0;           // 呼び出し
};
```

動くようになりました。

```text
$ ./a.out
proof!
```

## ダミーの初期化

`filler` のコンストラクタで `result<Tag>::ptr` を書き換えていますが、ダミーのメンバを初期化する際に書き換えを行うように変更します。

```c++
template<typename Tag, typename Tag::type p>
struct rob : result<Tag> {
  /* fill it ... */
  inline static auto dummy = (result<Tag>::ptr = p);  // 変更
};
```

## ネスト

`result` と `rob` とで `typename Tag` が共通しているため、`rob` を `result` の中に入れてネストさせます。継承しなくてもレキシカルスコープで `ptr` が見えるようになります。

```c++
template<typename Tag>
struct result {
  /* export it ... */
  typedef typename Tag::type type;
  inline static type ptr;

  template<typename Tag::type p>           // ネスト
  struct rob {                             // 継承除去
    /* fill it ... */
    inline static auto dummy = (ptr = p);  // 変更
  };
};
```

これに合わせて明示的実体化も変更します。

```c++
struct Af { typedef void(A::*type)(); };
template class result<Af>::rob<&A::f>;     // 変更
```
## コメントの除去

コメントを除去して行数を減らします。全体を掲載します。

```c++
#include <iostream>

template<typename Tag> struct result {
  inline static typename Tag::type ptr;
  template<typename Tag::type p> struct rob {
    inline static auto dummy = (ptr = p);
  };
};

struct A {
private:
  void f() {
    std::cout << "proof!" << std::endl;
  }
};

struct Af { typedef void(A::*type)(); };
template class result<Af>::rob<&A::f>;

int main() {
  A a;
  (a.*result<Af>::ptr)();
}
```

かなり短くなりました。

## ターゲットを合わせる

ターゲットとなる `A` の定義を memptr.cc に合わせます。

```c++
#include <iostream>

template<typename Tag> struct result {
  inline static typename Tag::type ptr;
  template<typename Tag::type p> struct rob {
    inline static auto dummy = (ptr = p);
  };
};

class A { int a = 12345; };

struct Aa { typedef int A::*type; };
template class result<Aa>::rob<&A::a>;

int main() {
  A a;
  std::cout << a.*result<Aa>::ptr << std::endl;
}
```

ターゲットごとにコードを書くという前提で `result` をなくして中身を外に出します。

```c++
#include <iostream>

class A { int a = 12345; };

static int A::*ptr;
template<int A::*p> struct rob {
  inline static auto dummy = (ptr = p);
};
template class rob<&A::a>;

int main() {
  A a;
  std::cout << a.*ptr << std::endl;
}
```

これで memptr.cc とほぼ同じコードが得られました。

こうやって書き換えながら単純化すると、普通はクラス外からは取れない private メンバへのポインタを、例外的に許可されている状況から取り回している様子がよく分かりました。

# おまけ

メンバ変数へのポインタの実体はオフセットなので、無理やり即値で指定することを試みました。

```c++
#include <iostream>
#include <cstdint>

class A { int a = 12345, b = 67890; } a;

int main() {
  int A::*ptr;
  *reinterpret_cast<intptr_t*>(&ptr) = 0;
  std::cout << a.*ptr << std::endl;
  *reinterpret_cast<intptr_t*>(&ptr) = 4;
  std::cout << a.*ptr << std::endl;
}
```
```text:実行結果
12345
67890
```

※ 未保証な操作です。これはお遊びで、実用を意図していません。
