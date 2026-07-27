---
coediting: false
comments_count: 0
created_at: '2020-06-03T06:57:11+09:00'
id: b5121bb3a94e691cd1c5
likes_count: 1
private: false
reactions_count: 0
stocks_count: 1
tags:
- name: Python
  versions: []
- name: F#
  versions: []
- name: 並列計算
  versions: []
title: Pythonの並列計算サンプルをF#に移植
updated_at: '2020-06-09T15:22:18+09:00'
url: https://qiita.com/7shi/items/b5121bb3a94e691cd1c5
slide: false
---

Python のドキュメントにある並列計算のサンプルを F# に移植してみました。書き方を比較することで、取っ掛かりになると思います。

# GIL

Python でマルチスレッドを試しました。

* [[Python] スレッドで実装する](https://qiita.com/tchnkmr/items/b05f321fa315bbce4f77)

並列計算を試しましたが、ほとんど速度が向上しませんでした。以下の記事に言及があります。

* [PythonのThread（並列処理）は速度改善効果がないらしいので確認する。 - "BOKU"のITな日常](https://arakan-pgm-ai.hatenablog.com/entry/2019/05/02/000000)

<blockquote>Pythonにはプログラム実行の一貫性を保証する仕組みとして「Global Interpreter Lock(GIL)」を採用しています。</blockquote>
<blockquote>どうも、PythonのThreadはシステムコールを行う際の「ブロッキングI/O」を扱うためにサポートされているとか・・、そもそも速度向上を狙うようににはなってないみたいなのですね・・。</blockquote>

ドキュメントに経緯が説明されています。

* [用語集 (global interpreter lock)](https://docs.python.org/ja/3/glossary.html#term-global-interpreter-lock)

> (グローバルインタプリタロック) CPython インタプリタが利用している、一度に Python の バイトコード を実行するスレッドは一つだけであることを保証する仕組みです。これにより (dict などの重要な組み込み型を含む) オブジェクトモデルが同時アクセスに対して暗黙的に安全になるので、 CPython の実装がシンプルになります。インタプリタ全体をロックすることで、マルチプロセッサマシンが生じる並列化のコストと引き換えに、インタプリタを簡単にマルチスレッド化できるようになります。
> 
> ただし、標準あるいは外部のいくつかの拡張モジュールは、圧縮やハッシュ計算などの計算の重い処理をするときに GIL を解除するように設計されています。また、I/O 処理をする場合 GIL は常に解除されます。
> 
> 過去に "自由なマルチスレッド化" したインタプリタ (供用されるデータを細かい粒度でロックする) が開発されましたが、一般的なシングルプロセッサの場合のパフォーマンスが悪かったので成功しませんでした。このパフォーマンスの問題を克服しようとすると、実装がより複雑になり保守コストが増加すると考えられています。

# ProcessPoolExecutor

Python での並列計算はマルチスレッドではなくマルチプロセスで行います。プロセスの管理やプロセス間での関数の呼び出しは ProcessPoolExecutor が面倒を見てくれます。デフォルトで論理プロセッサの数のワーカープロセスを作成して、処理が割り振られます。

ドキュメントの ProcessPoolExecutor のサンプルを改造します。並列と直列が切り替えられるようにして所要時間を確認します。ThreadPoolExecutor に交換するだけでマルチスレッドと比較できます。

* [concurrent.futures -- 並列タスク実行 (ProcessPoolExecutor の例)](https://docs.python.org/ja/3/library/concurrent.futures.html#processpoolexecutor-example) より改変

```python:parallel-sample.py
import concurrent.futures
import math

PRIMES = [
    112272535095293,
    112582705942171,
    112272535095293,
    115280095190773,
    115797848077099,
    1099726899285419]

def is_prime(n):
    if n < 2:
        return False
    if n == 2:
        return True
    if n % 2 == 0:
        return False

    sqrt_n = int(math.floor(math.sqrt(n)))
    for i in range(3, sqrt_n + 1, 2):
        if n % i == 0:
            return False
    return True

def main_parallel(cls):
    with cls() as executor:
        for number, prime in zip(PRIMES, executor.map(is_prime, PRIMES)):
            print('%d is prime: %s' % (number, prime))

def main():
    for number, prime in zip(PRIMES, map(is_prime, PRIMES)):
        print('%d is prime: %s' % (number, prime))

if __name__ == '__main__':
    import sys
    if sys.argv[-1] == "--process":
        main_parallel(concurrent.futures.ProcessPoolExecutor)
    elif sys.argv[-1] == "--thread":
        main_parallel(concurrent.futures.ThreadPoolExecutor)
    else:
        main()
```
```shell-session:実行結果
$ time python parallel-sample.py
112272535095293 is prime: True
112582705942171 is prime: True
112272535095293 is prime: True
115280095190773 is prime: True
115797848077099 is prime: True
1099726899285419 is prime: False

real    0m2.745s
user    0m2.703s
sys     0m0.031s

$ time python parallel-sample.py --process
112272535095293 is prime: True
112582705942171 is prime: True
112272535095293 is prime: True
115280095190773 is prime: True
115797848077099 is prime: True
1099726899285419 is prime: False

real    0m0.983s
user    0m3.984s
sys     0m0.172s

$ time python parallel-sample.py --thread
112272535095293 is prime: True
112582705942171 is prime: True
112272535095293 is prime: True
115280095190773 is prime: True
115797848077099 is prime: True
1099726899285419 is prime: False

real    0m5.527s
user    0m5.422s
sys     0m0.109s
```

マルチプロセスでは速度が向上しますが、マルチスレッドでは遅くなります。

# F# 

F# に移植します。.NET Framework ではマルチスレッドの利用に問題がないため、マルチプロセスの実装は省略します。

```fsharp:parallel-sample.fsx
let PRIMES = [
    112272535095293L
    112582705942171L
    112272535095293L
    115280095190773L
    115797848077099L
    1099726899285419L]

let is_prime n =
    if n < 2L then
        false
    elif n = 2L then
        true
    elif n % 2L = 0L then
        false
    else
    let sqrt_n = int64 (floor (sqrt (float n)))
    seq {
        for i in {3L .. 2L .. sqrt_n + 1L} do
            if n % i = 0L then
                yield false
        yield true }
    |> Seq.head

let is_prime_async n = async { return is_prime n }

let main_parallel() =
    PRIMES
    |> Seq.map is_prime_async
    |> Async.Parallel
    |> Async.RunSynchronously
    |> Seq.zip PRIMES
    |> Seq.iter (fun (number, prime) -> printfn "%d is prime: %b" number prime)

let main() =
    PRIMES
    |> Seq.map is_prime
    |> Seq.zip PRIMES
    |> Seq.iter (fun (number, prime) -> printfn "%d is prime: %b" number prime)

match Array.last (System.Environment.GetCommandLineArgs()) with
| "--thread" -> main_parallel()
| _          -> main()
```
```shell-session:実行結果
$ time mono parallel-sample.exe
112272535095293 is prime: true
112582705942171 is prime: true
112272535095293 is prime: true
115280095190773 is prime: true
115797848077099 is prime: true
1099726899285419 is prime: false

real    0m0.662s
user    0m0.625s
sys     0m0.031s

$ time mono parallel-sample.exe --thread
112272535095293 is prime: true
112582705942171 is prime: true
112272535095293 is prime: true
115280095190773 is prime: true
115797848077099 is prime: true
1099726899285419 is prime: false

real    0m0.308s
user    0m0.813s
sys     0m0.078s
```

もう少し重い処理でないと効果が分かりにくいですが、速度は向上しています。

## 処理の流れ

`async` や `Async` で何が起きているのかは、型に注目すると分かりやすいです。

```fsharp:関数を非同期化
let is_prime n = ...        // int64 -> bool
let is_prime_async n = ...  // int64 -> Async<bool>
```
```fsharp:引数のリストを適用
    PRIMES
    |> Seq.map is_prime_async  // seq<Async<bool>>
```
```fsharp:複数の非同期処理をまとめる
    |> Async.Parallel          // Async<bool array>
```
```fsharp:非同期処理を実行して結果を配列で返す
    |> Async.RunSynchronously  // bool array
```

並列計算はスレッドプールで行われます。一度に大量の計算を渡しても、適宜スケジューリングされます。

# 関連記事

以下の記事で言及している処理のために調査しました。

* [Wiktionaryの全文処理をF#とPythonで速度比較](https://qiita.com/7shi/items/1d6b97c657c6fffdbd70)
