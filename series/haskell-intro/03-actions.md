---
coediting: false
comments_count: 8
created_at: '2014-10-09T00:10:29+09:00'
id: 85afd7bbd5d6c4115ad6
likes_count: 170
private: false
reactions_count: 0
stocks_count: 136
tags:
- name: JavaScript
  versions: []
- name: Haskell
  versions: []
title: Haskell アクション 超入門
updated_at: '2026-08-05T09:08:18+09:00'
url: https://qiita.com/7shi/items/85afd7bbd5d6c4115ad6
slide: false
---

Haskellではアクションと呼ばれる機能により副作用が扱えます。アクションの使い方の初歩を説明します。ライブラリで用意されたアクションを手っ取り早く使うことを目的としているため、モナドや圏論には言及しません。

シリーズの記事です。

1. [Haskell 超入門](http://qiita.com/7shi/items/145f1234f8ec2af923ef)
1. [Haskell 代数的データ型 超入門](http://qiita.com/7shi/items/1ce76bde464b4a55c143)
1. **Haskell アクション 超入門** ← この記事
1. [Haskell ラムダ 超入門](http://qiita.com/7shi/items/1345bf32003faff435cb)
1. [Haskell アクションとラムダ 超入門](http://qiita.com/7shi/items/4a8a2807bb5186576c61)
1. [Haskell IOモナド 超入門](http://qiita.com/7shi/items/d3d3492ddd90d47160f2)
1. [Haskell リストモナド 超入門](http://qiita.com/7shi/items/deb19c4cba933590ffbf)
1. [Haskell Maybeモナド 超入門](http://qiita.com/7shi/items/c7d7eec066af0fe0688d)
1. [Haskell 状態系モナド 超入門](http://qiita.com/7shi/items/2e9bff5d88302de1a9e9)
1. [Haskell モナド変換子 超入門](http://qiita.com/7shi/items/4408b76624067c17e933)
1. [Haskell 例外処理 超入門](http://qiita.com/7shi/items/73e534c47bbebc71b37e)
1. [Haskell 構文解析 超入門](http://qiita.com/7shi/items/b8c741e78a96ea2c10fe)
1. [Haskell 継続モナド 超入門](https://zenn.dev/7shi/articles/20260803-haskell-continuation-monad)
1. [Haskell 型クラス 超入門](https://zenn.dev/7shi/articles/20260805-haskell-type-classes)
1. 【予定】Haskell モナドとゆかいな仲間たち
1. 【予定】Haskell Freeモナド 超入門
1. 【予定】Haskell Operationalモナド 超入門
1. 【予定】Haskell Effモナド 超入門
1. 【予定】Haskell アロー 超入門

練習の解答例は別記事に掲載します。

* [【解答例】Haskell アクション 超入門](http://qiita.com/7shi/items/623fd55b8b68398becdc)

# 参照透過性

Haskellの関数は同じ引数に対しては常に同じ値を返します。この性質を[参照透過性](http://ja.wikipedia.org/wiki/%E5%8F%82%E7%85%A7%E9%80%8F%E9%81%8E%E6%80%A7)と呼びます。

以下の例では`add 1 2`は常に`3`を返します。何か特定の条件下で結果が変化することはありません。

```hs:例
add x y = x + y

main = do
    print $ add 1 2
```
```text:実行結果
3
```

## 副作用

Haskellでは参照透過性のない関数は定義できません。具体的には、乱数のように毎回異なる結果を返す関数は定義できません。

毎回異なる結果を返すようなものは内部に何らかの状態を持っており、結果を返すための処理などで状態が変化していると考えられます。状態が変化することを[副作用](http://ja.wikipedia.org/wiki/%E5%89%AF%E4%BD%9C%E7%94%A8_%28%E3%83%97%E3%83%AD%E3%82%B0%E3%83%A9%E3%83%A0%29)と呼びます。

状態に影響を受けて結果が変化する処理には参照透過性がありません。つまり副作用は参照透過性と対立する概念です。

# アクション

副作用が扱えないと困ることもありますが、例えば乱数を返す関数のようなものを定義することは可能です。それを関数とは区別して**アクション**と呼びます。

乱数に限らず、時刻取得やファイル読み込みなど、結果が変化する可能性があるものはすべてアクションを使います。

## 乱数

'A'～'Z'までの任意の文字をランダムに返すアクション`randAlpha`を定義する例を示します。

※ パッケージrandomが必要です。[Leksah](http://qiita.com/7shi/items/d1e5a0c22be6cf61d286)ではdependenciesに追加します。

```hs
import System.Random

randAlpha = randomRIO ('A', 'Z')

main = do
    r <- randAlpha
    print r
    print =<< randAlpha
    randAlpha >>= print
```
```text:実行結果（毎回異なる）
'E'
'P'
'I'
```

アクションは使用方法も関数とは異なり、見慣れない演算子が出て来ます。それらを説明します。

## <-

アクションから値を取り出すには`<-`を使います。矢印（←）をイメージした記号です。

![v_bind_m.png](https://qiita-image-store.s3.amazonaws.com/0/32057/9e2da171-e568-5552-1fde-4bf8e5062444.png)

```hs:OK
main = do
    r <- randAlpha
    print r
```

アクションに関連付けられた処理（この場合は乱数生成）は`<-`で値を取り出す際に行われます。

### 注意点

`<-`は`do`ブロックの中でしか使えません。

```hs:NG
main =
    r <- randAlpha
    print r
```
```text:エラー内容
parse error on input `<-'
```

※ `do`なしで`<-`相当の処理を書くことは可能ですが、ラムダについて説明する必要があります。詳細は続編の[Haskell アクションとラムダ 超入門](http://qiita.com/7shi/items/4a8a2807bb5186576c61)で説明します。

## =<<

一時変数を経由せずにアクションから値を取り出そうとしてもうまくいきません。

```hs:NG
test = do
    print randAlpha -- エラー
```

アクションから値を取り出して関数に渡すには専用の演算子`=<<`を使用します。他の言語では見ない形ですが、直感的には**漏斗のようなもの**でアクションから関数に値を**ドリップ**しているとイメージすれば良いでしょう。

![f_rbind_m.png](https://qiita-image-store.s3.amazonaws.com/0/32057/26c8e418-c41e-2bf3-dcf8-cb2d4d9cadfb.png) ![coffee.png](https://qiita-image-store.s3.amazonaws.com/0/32057/0db6cbec-252e-4714-483d-578bf8323dad.png)

```hs:OK
main = do
    print =<< randAlpha
```

アクション版の`$`だと捉えておけば良いでしょう。

### イメージ

C++をご存知の方は、iostreamの`<<`をイメージすれば良いかもしれません。

```cpp
cout << "abc";
```

### >>=

逆向きもあります。`>>=`はbindと呼ばれます。

![m_bind_f.png](https://qiita-image-store.s3.amazonaws.com/0/32057/053234a0-674f-ad0f-0198-b27d9b9d93fc.png)

```hs
main = do
    randAlpha >>= print
```

説明の都合上`=<<`を先に出しましたが、実は`>>=`が基本で、`=<<`はその逆です。

※ `do`と`>>=`には密接な関係があります。詳細は続編の[Haskell アクションとラムダ 超入門](http://qiita.com/7shi/items/4a8a2807bb5186576c61)で説明します。

## let

`let`でアクションから値を取り出すことはできません。

```hs:NG
main = do
    let r = randAlpha
    print r -- エラー
```

`let`と組み合わせることは可能ですが、アクションを変数に束縛する意味となります。値を取り出しているわけではないことに注意してください。`let`を使っても、値を取り出すには依然として`<-`などを使う必要があります。

```hs
main = do
    let r = randAlpha
    r' <- r
    print r'
    print =<< r
    r >>= print
```
```text:実行結果（毎回異なる）
'Q'
'D'
'A'
```

## 呼び出し

`main`以外で`do`を使って、`main`から呼び出せます。

```hs
test = do
    r <- randAlpha
    print r

main = do
    test
    test
    test
```
```text:実行結果（毎回異なる）
'S'
'P'
'T'
```

`do`ブロック全体で1つのアクションを構成します。testには引数がないため関数ではなく、アクションが束縛された変数です。

### main

実は`main`も同じ構造です。今まで曖昧なまま進めてきましたが、`main`は関数ではなくアクションが束縛された変数です。プログラムの起動時に自動的に呼び出される点が特殊です。

## 練習

【問1】ランダムにアルファベット小文字の1文字表示を繰り返してください。`'z'`が現れたら`"END"`と表示して終了してください。

```text:動作イメージ（毎回異なる）
'j'
'm'
'z'
"END"
```

⇒ [解答例](http://qiita.com/7shi/items/623fd55b8b68398becdc#%E3%83%A9%E3%83%B3%E3%83%80%E3%83%A0%E8%A1%A8%E7%A4%BA)

# return

`return`は値を入れてアクションを作る関数です。

![return.png](https://qiita-image-store.s3.amazonaws.com/0/32057/820088e0-1504-8fa9-e093-3cec017cae69.png)

アクションを作って、すぐに値を取り出してみます。

```hs
main = do
    a <- return 1
    print a
    print =<< return 2
    return 3 >>= print
```
```text:実行結果
1
2
3
```

繰り返しますが、`let`では値を取り出すことはできません。

```hs:NG
main = do
    let a = return 1
    print a -- エラー
```

束縛されたアクションから、アクション用の演算子で値を取り出します。

```hs:OK
main = do
    let a = return 1
    a' <- a
    print a'
    print =<< a
    a >>= print
```
```text:実行結果
1
1
1
```

## アクションを返す関数

関数の戻り値に`return`を通すと、アクションを返す関数が作れます。

```hs
add x y = return $ x + y

main = do
    print =<< add 1 2
```
```text:実行結果
3
```

C言語などで`return`により値を返すのに似ていますが、返されるのは値ではなくアクションである点が異なります。そのためアクション用の演算子で値を取り出す必要があります。

## doとreturn

`do`と組み合わせれば、`print`などを使って最後に`return`する関数が作れます。

```hs
add x y = do
    print x
    print y
    return $ x + y

main = do
    print =<< add 1 2
```
```text:実行結果
1
2
3
```

ますますC言語などに似て来ます。

### 注意点

`return`は単にそういう名前の関数で、C言語のように関数から抜ける機能はありません。後ろにコードがあれば、抜けずにそのまま続行します。

```hs
main = do
    print "abc"
    return 1    -- 素通り
    print "def" -- 実行される
    return 2    -- 戻り値
```
```text:実行結果
"abc"
"def"
```

`return`は関数の最後でアクションを返すのに使われることが多いため、そのような使い方をしている限りはC言語などに見た目が似せられるということです。

## 練習

【問2】階乗を求める関数`fact`を、アクションを返す関数に書き換えてください。

```hs
fact 0 = 1
fact n | n > 0 = n * fact (n - 1)

main = do
    print $ fact 5
```
```text:実行結果
120
```

ヒント: `fact 0 = return 1`

⇒ [解答例](http://qiita.com/7shi/items/623fd55b8b68398becdc#%E9%9A%8E%E4%B9%97)

# IO

今回出て来るアクションはすべてIOと呼ばれる型で、型名は`IO＋型`で表記されます。

※ IO以外にもアクションはありますが、今回は分かりやすさを優先してIOアクションを単にアクションとして扱います。IO以外のアクションは続編の[Haskell 状態系モナド 超入門](http://qiita.com/7shi/items/2e9bff5d88302de1a9e9)で取り上げます。

とりあえず実用的には以下のように認識すれば使えます。

例: `IO Int` → 数値が取り出せるアクション

* `IO Int`で1つの型を表します。
* `IO`がアクション、`Int`が取り出される型を表します。

## 型注釈

型を明示するには**型注釈**と呼ばれる行を追加します。一般的には本体の上に書きます。

```hs
randAlpha :: IO Char
randAlpha = randomRIO ('A', 'Z')
```

なお、一行で書くこともできます。

```hs
randAlpha = randomRIO ('A', 'Z') :: IO Char
```

大抵は型注釈を書かなくても型推論により型が決まります。型推論がうまくいかないケースでは型注釈が必須です。そのような例を次に示します。

## サイコロ

`randomR`で数値を指定するには型注釈が必須です。

```hs
import System.Random

dice :: IO Int
dice = randomRIO (1, 6)

main = do
    print =<< dice
    print =<< dice
    print =<< dice
```
```text:実行結果（毎回異なる）
2
3
1
```

型注釈を省略するとエラーになります。

```text:エラー内容
No instance for (Random a0) arising from a use of `randomR'
The type variable `a0' is ambiguous
Possible cause: the monomorphism restriction applied to the following:
  dice :: IO a0 (bound at src\Main.hs:3:1)
Probable fix: give these definition(s) an explicit type signature
              or use -XNoMonomorphismRestriction
Note: there are several potential instances:
  instance Random Bool -- Defined in `System.Random'
  instance Random Foreign.C.Types.CChar -- Defined in `System.Random'
  instance Random Foreign.C.Types.CDouble
    -- Defined in `System.Random'
  ...plus 33 others
（略）
```

`dice`から取り出せる型が`Bool`, `Foreign.C.Types.CChar`, `Foreign.C.Types.CDouble`, その他33種類のうちどの型か曖昧だというエラーメッセージです。

## 練習

【問3】リストをランダムに並べ替える関数`shuffle`を実装してください。

具体的には以下のコードが動くようにしてください。

```hs
main = do
    print =<< shuffle [1..9]
```
```text:実行結果（毎回異なる）
[3,5,4,9,2,7,8,6,1]
```

⇒ [解答例](http://qiita.com/7shi/items/623fd55b8b68398becdc#%E3%82%B7%E3%83%A3%E3%83%83%E3%83%95%E3%83%AB)

【問4】[ボゴソート](http://ja.wikipedia.org/wiki/%E3%83%9C%E3%82%B4%E3%82%BD%E3%83%BC%E3%83%88)を実装してください。

具体的には以下のコードが動くようにしてください。

```hs
main = do
    xs <- shuffle [1..9]
    print xs
    print =<< bogosort xs
```
```text:実行結果（毎回異なる）
[7,1,9,4,2,8,5,3,6]
[1,2,3,4,5,6,7,8,9]
```

ヒント: ソート済みかを`True`/`False`で返す関数`isSorted`を実装します。

⇒ [解答例](http://qiita.com/7shi/items/623fd55b8b68398becdc#%E3%83%9C%E3%82%B4%E3%82%BD%E3%83%BC%E3%83%88)

# unit

空のタプル`()`は値がないことを表し**unit**と読みます。

```hs
ignore _ = ()

main = do
    print $ ignore "foo"
```
```text:実行結果
()
```

関数は必ず値を返す必要がありますが、返す値がないときには`()`を返します。C言語などで値を返さない`void`関数に相当します。

## 空のmain

何もしない`main`を定義してみます。

```hs
main = return ()
```

`main`はアクションとなる必要があるため`return`必須です。

### 終了ステータス

C言語では`main()`の戻り値がプロセスの終了ステータスとなります。

```c:main.c
int main() {
    return 5;
}
```
```text:シェルで確認
$ gcc main.c
$ ./a.out
$ echo $?
5
```

Haskellでは`main`から返されるアクションの値は捨てられるため、C言語のようにプロセスの終了ステータスとして扱われるわけではありません。

```hs:main.hs
main = return 5
```
```text:シェルで確認
$ ghc main.hs
$ ./main
$ echo $?
0
```

runhaskellで実行すると`main`から取り出された値は表示されますが、終了ステータスとして扱われるわけではありません。

```text:シェルで確認
$ runhaskell main.hs
5
$ echo $?
0
```

終了ステータスを返すには[System.Exit](http://hackage.haskell.org/package/base-4.7.0.1/docs/System-Exit.html)モジュールを使います。

```hs:exit.hs
import System.Exit

main = do
    exitWith $ ExitFailure 5
```
```text:シェルで確認
$ ghc exit.hs
$ ./exit
$ echo $?
5
```

## print

今まで意識せずに使ってきた`print`はアクションを返す関数です。文字が表示されるのは関数が呼ばれるタイミングではなく、関数が返したアクションから値を取り出すタイミングでの**副作用**です。

* `print`: 関数
* `print "abc"`: 関数を呼んで、戻り値がアクション
* `let a = print "abc"`: 戻り値のアクションを束縛
* `_ <- print "abc"`: 戻り値のアクションから値を取り出し、副作用として文字を表示

確認します。まず値を取り出してみます。

```hs
main = do
    _ <- print "hello"
    return ()
```
```text:実行結果
"hello"
```

取り出した値を表示して確認してみます。

```hs
main = do
    a <- print "hello"
    print a
```
```text:実行結果
"hello"
()
```

`()`が取り出されます。`()`自体に値としての意味はなく、副作用として文字が表示されることに狙いがあります。

`do`ブロックの末尾で`return`ではなく`print`を使うことができるのは、`print`がアクションを返すためです。

## 暗黙の取り出し

`print`から返されるアクションを`let`で束縛して、後で値の取り出しを試みます。

```hs
main = do
    let a = print "hello"
    _ <- a
    _ <- a
    a
    a
```
```text:実行結果
"hello"
"hello"
"hello"
"hello"
```

`<-`により明示的に値を取り出さなくても、`do`の中にアクションを置くだけで自動的に値が取り出されます。これがアクション呼び出しの仕組みです。

```hs:再掲
import System.Random

randAlpha = randomRIO ('A', 'Z')

test = do
    r <- randAlpha
    print r

main = do
    test
    test
    test
```
```text:実行結果（毎回異なる）
'S'
'P'
'T'
```

暗黙的に取り出された値は捨てられます。

## 練習

【問5】1～6の乱数を表示して返すアクションにより、暗黙の取り出しで値が捨てられていることを確認してください。

具体的には以下のコードが動くようにしてください。

```hs
main = do
    showDice
    showDice
    print =<< showDice
```
```text:実行結果（毎回異なる）
5
2
6
6
```

⇒ [解答例](http://qiita.com/7shi/items/623fd55b8b68398becdc#%E6%9A%97%E9%BB%99%E3%81%AE%E5%8F%96%E3%82%8A%E5%87%BA%E3%81%97)

# bind

`>>=`は「アクションと、アクションを返す関数とを**結びつける**」ため**bind**と呼ばれます。ここでは向きに関係なく`=<<`も含めてbindとして扱います。

![m_bind_f_m2.png](https://qiita-image-store.s3.amazonaws.com/0/32057/86db414e-bf95-0a53-cf9f-1f1bbe4d16b7.png)
![f_rbind_m_m2.png](https://qiita-image-store.s3.amazonaws.com/0/32057/3adbacc6-e0f0-338f-efc3-d111165b27ce.png)

bindの結合先がただの「関数」ではなく「アクションを返す関数」なのを確認します。

```hs:OK
inc x = return $ x + 1

main = do
    return 2 >>= inc >>= print
    print =<< inc =<< return 2
```
```text:実行結果
3
3
```

アクションを返さない関数にはbindできないことを確認します。

```hs:NG
inc x = x + 1

main = do
    print $ inc =<< return 2
```
```text:エラー内容
No instance for (Show (m0 b0)) arising from a use of `print'
The type variables `m0', `b0' are ambiguous
Possible fix: add a type signature that fixes these type variable(s)
（略・以下多数）
```

この仕様は、一度アクションに値を入れたら、その値を使った計算もアクションに閉じ込めることを目的としています。これにより副作用がアクションの中に閉じ込められ、アクションの外では参照透過性が保たれます。

`<-`はアクションの外に値を取り出しているように見えますが、`do`ブロックの中でしか使えず、`do`ブロックは最後に`return`などでアクションを返すことから、結果としてアクションの中に閉じ込められたままです。

## Applicativeスタイル

bindの結合先はアクションを返す関数という制限がありますが、アクションから値を外に出さないことが目的なら「自動的に入れてくれれば良い」と感じるかもしれません。

実際にそういう方法もサポートされていて**Applicative（アプリカティブ）スタイル**と呼ばれます。

![applicative_style.png](https://qiita-image-store.s3.amazonaws.com/0/32057/15d1cbf2-a00d-db22-d973-27ad0b099c26.png)

```hs
import Control.Applicative

inc x   = x + 1
add x y = x + y

main = do
    print =<< inc <$> return 1
    print =<< add <$> return 1 <*> return 2
```
```text:実行結果
2
3
```

`<$>`は次のような働きをします。

1. アクションから値を取り出して関数に引数として渡す
2. 関数の戻り値をアクションに閉じ込める

引数が複数あるときは`<*>`でつなぎます。

詳細は次の記事が参考になります。

* [@kazu_yamamoto](https://twitter.com/kazu_yamamoto): [Applicativeのススメ - あどけない話](http://d.hatena.ne.jp/kazu-yamamoto/20101211/1292021817) 2010.12.11

## まとめ

bind

* アクション `>>=` 関数(アクションを返す)
* 関数(アクションを返す) `=<<` アクション

Applicativeスタイル

* 関数 `<$>` アクション
* 関数 `<$>` アクション `<*>` アクション

どちらも最終的に得られるのはアクションです。

![coffee2.png](https://qiita-image-store.s3.amazonaws.com/0/32057/43cd2018-cd41-dc83-916c-15fbb19bbaf8.png)

※ この絵に深い意味はありません。

## 練習

【問6】Applicativeスタイルを使って、次のコードから`<-`を排除してください。

※ 具体的には`fib n ...`の定義だけを修正してください。

```hs
fib 0 = return 0
fib 1 = return 1
fib n | n > 1 = do
    a <- fib (n - 2)
    b <- fib (n - 1)
    return $ a + b

main = do
    print =<< fib 6
```

ヒント: 演算子の関数化`(+)`

⇒ [解答例](http://qiita.com/7shi/items/623fd55b8b68398becdc#applicative%E3%82%B9%E3%82%BF%E3%82%A4%E3%83%AB)

# デバッグ

`trace`によるデバッグを`putStrLn`に書き替えて比較します。デバッグには`trace`を使った方が簡単ですが、デバッグ以外の理由でアクションを使うこともあるため、書き方の例として示します。

元となるデバッグなしのコードです。

```hs
fact 0 = 0
fact n | n > 0 = n * fact (n - 1)

main = do
    print $ fact 5
```
```text:実行結果
120
```

`trace`で途中経過を表示します。

```hs:trace
import Debug.Trace

fact 0 = trace "fact 0 = 1" 1
fact n | n > 0 = trace dbg0 $ trace dbg1 ret
    where
        ret  = n * fn1
        fn1  = fact $ n - 1
        dbg0 = "fact " ++ show n ++ " = " ++
               show n ++ " * fact " ++ show (n - 1)
        dbg1 = dbg0 ++ " = " ++
               show n ++ " * " ++ show fn1 ++ " = " ++ show ret

main = do
    traceIO $ show $ fact 5
```
```text:実行結果
fact 5 = 5 * fact 4
fact 4 = 4 * fact 3
fact 3 = 3 * fact 2
fact 2 = 2 * fact 1
fact 1 = 1 * fact 0
fact 0 = 1
fact 1 = 1 * fact 0 = 1 * 1 = 1
fact 2 = 2 * fact 1 = 2 * 1 = 2
fact 3 = 3 * fact 2 = 3 * 2 = 6
fact 4 = 4 * fact 3 = 4 * 6 = 24
fact 5 = 5 * fact 4 = 5 * 24 = 120
120
```

`putStrLn`で途中経過を表示します。`print`を使わないのは、文字列が`""`で囲まれて表示されるのを回避するためです。

```hs:アクション
fact 0 = do
    putStrLn "fact 0 = 1"
    return 1
fact n | n > 0 = do
    let dbg = "fact " ++ show n ++ " = " ++
              show n ++ " * fact " ++ show (n - 1)
    putStrLn dbg
    n' <- fact (n - 1)
    let ret = n * n'
    putStrLn $ dbg ++ " = " ++ show n ++ " * " ++ show n' ++ " = " ++ show ret
    return ret

main = do
    print =<< fact 5
```
```text:実行結果
fact 5 = 5 * fact 4
fact 4 = 4 * fact 3
fact 3 = 3 * fact 2
fact 2 = 2 * fact 1
fact 1 = 1 * fact 0
fact 0 = 1
fact 1 = 1 * fact 0 = 1 * 1 = 1
fact 2 = 2 * fact 1 = 2 * 1 = 2
fact 3 = 3 * fact 2 = 3 * 2 = 6
fact 4 = 4 * fact 3 = 4 * 6 = 24
fact 5 = 5 * fact 4 = 5 * 24 = 120
120
```

アクションを使うと関数の戻り値もアクションにする必要があるため、戻り値の取り回しに影響します。

※ 手続型言語のようなコードになっています。

デバッグについての詳細は次の記事が参考になります。

* [@kazu_yamamoto](https://twitter.com/kazu_yamamoto): [Haskell でのデバッグ - あどけない話](http://d.hatena.ne.jp/kazu-yamamoto/20120606/1338957783) 2012.6.6

## 練習

【問7】次のクイックソートの途中経過を`trace`ではなく`putStrLn`で表示するように修正してください。

```hs
import Debug.Trace

qsort []     = []
qsort (n:xs) = trace dbg $ qsort lt ++ [n] ++ qsort gteq
    where
        dbg  = "qsort " ++ show (n:xs) ++ " = qsort " ++
               show lt ++ " ++ " ++ show [n] ++ " ++ " ++ show gteq
        lt   = [x | x <- xs, x <  n]
        gteq = [x | x <- xs, x >= n]

main = do
    traceIO $ show $ qsort [4, 6, 9, 8, 3, 5, 1, 7, 2]
```

⇒ [解答例](http://qiita.com/7shi/items/623fd55b8b68398becdc#%E3%82%AF%E3%82%A4%E3%83%83%E3%82%AF%E3%82%BD%E3%83%BC%E3%83%88)

# IORef

アクションによって値が変更できる変数のようなものです。

```hs
import Data.IORef

main = do
    a <- newIORef 1
    b <- readIORef a
    writeIORef a 2
    print =<< readIORef a
    print b
```
```text:実行結果
2
1
```

`a`は変更可能な値への参照`IORef`です。アクションを通して値を読み書きします。

関数|引数|戻り値
---|---|---
newIORef|初期値|IORefを作成するアクション
readIORef|参照|値を読み取るアクション
writeIORef|参照→値|値を書き込むアクション

## 練習

【問8】次のJavaScriptでよく見掛けるサンプルコードを移植してください。

```js:JavaScript
function counter() {
    var c = 0;
    return function() {
        return ++c;
    };
}

var f = counter();
console.log(f());
console.log(f());
console.log(f());
```

ヒント: `return $ do`

⇒ [解答例](http://qiita.com/7shi/items/623fd55b8b68398becdc#%E3%82%AB%E3%82%A6%E3%83%B3%E3%82%BF%E3%83%BC)

# ループ

手続型言語ではループを頻繁に使います。

```js:JavaScript
for (var i = 0; i < 5; ++i) {
    console.log(i);
}
```

IORefで移植すると大袈裟なコードになります。

```hs
import Data.IORef

main = do
    i <- newIORef 0
    let loop = do
        i' <- readIORef i
        if i' < 5
            then do
                print i'
                writeIORef i $ i' + 1
                loop
            else return ()
    loop
```
```text:実行結果
0
1
2
3
4
```

ループカウンターを引数にすると簡単になります。

```hs
main = do
    let loop i | i < 5 = do
            print i
            loop $ i + 1
        loop _ = return ()
    loop 0
```
```text:実行結果
0
1
2
3
4
```

※ ループを実現するには`forM`という関数もありますが、活用するにはラムダが必要です。詳細は続編の[Haskell アクションとラムダ 超入門](http://qiita.com/7shi/items/4a8a2807bb5186576c61)で説明します。

## 練習

【問9】次のJavaScriptのコードを移植してください。`s`だけ`IORef`を使ってください。

```js:JavaScript
var s = 0;
for (var i = 1; i <= 100; ++i) {
    s += i;
}
console.log(s);
```

【問10】問9のコードから`IORef`を排除してください。`sum`は使わないでください。

⇒ [解答例](http://qiita.com/7shi/items/623fd55b8b68398becdc#%E3%83%AB%E3%83%BC%E3%83%97)

# IOUArray

IORefの配列版です。パッケージarrayが必要です。[Leksah](http://qiita.com/7shi/items/d1e5a0c22be6cf61d286)ではdependenciesに追加します。

※ `U`はアンボックス化を意味しています。詳細は続編の[Haskell IOモナド 超入門](http://qiita.com/7shi/items/d3d3492ddd90d47160f2)で説明します。

```hs
import Data.Array.IO

main = do
    a <- newArray (0, 2) 0 :: IO (IOUArray Int Int)
    print =<< getElems a
    writeArray a 0 3
    print =<< readArray a 0
    writeArray a 1 6
    print =<< getElems a
    writeArray a 2 7
    print =<< getElems a
```
```text:実行結果
[0,0,0]
3
[3,6,0]
[3,6,7]
```

`a`は値が変更可能な配列`IOUArray`です。アクションを通して値を読み書きします。`newArray`では型を指定する必要があります。

* `IOUArray` `Int`(インデックスの型) `Int`(値の型)

関数|引数|戻り値
---|---|---
newArray|範囲→初期値|配列を作成するアクション
readArray|配列→インデックス|値を読み取るアクション
writeArray|配列→インデックス→値|値を書き込むアクション
getElems|配列|すべての値をリストで取得するアクション

HaskellにはIOUArray以外にも配列があります。詳細は次のスライドが参考になります。

* [すごい配列楽しく学ぼう](http://www.slideshare.net/xenophobia__/ss-14558187)

## 練習

【問11】次のJavaScriptで実装された[Brainf*ck](http://ja.wikipedia.org/wiki/Brainfuck)インタプリタを移植してください。

```js:JavaScript
var bf = ">+++++++++[<++++++++>-]<.>+++++++[<++++>" +
         "-]<+.+++++++..+++.[-]>++++++++[<++++>-]<" +
         ".>+++++++++++[<+++++>-]<.>++++++++[<+++>" +
         "-]<.+++.------.--------.[-]>++++++++[<++" +
         "++>-]<+.[-]++++++++++.";

var jmp = new Uint32Array(bf.length + 1);
for (var i = 0, loops = []; i < bf.length; ++i) {
    switch (bf[i]) {
    case '[':
        loops.push(i);
        break;
    case ']':
        var start = loops.pop();
        jmp[start] = i;
        jmp[i] = start;
        break;
    }
}

var pc = 0, r = 0, m = new Uint8Array(30000);
while (pc < bf.length) {
    switch (bf[pc]) {
    case '+': ++m[r]; break;
    case '-': --m[r]; break;
    case '>': ++r; break;
    case '<': --r; break;
    case '.':
        process.stdout.write(String.fromCharCode(m[r]));
        break;
    case '[':
        if (m[r] == 0) pc = jmp[pc];
        break;
    case ']':
        if (m[r] != 0) pc = jmp[pc] - 1;
        break;
    }
    ++pc;
}
```
```text:実行結果
Hello World!
```

ヒント: `putChar`, `Data.Word.Word8`, `fromIntegral`

⇒ [解答例](http://qiita.com/7shi/items/623fd55b8b68398becdc#brainfck)

JavaScript内にハードコーディングされているBrainf*ckコードの出典です。

* [Brainf*ck](http://www.kmonos.net/alang/etc/brainfuck.php) - [いろんなげんご](http://www.kmonos.net/alang/etc/) @ [人工言語世界](http://www.kmonos.net/alang/)

# unsafePerformIO

アクションから値を引き剥がす関数です。`<-`や`=<<`などを回避できます。

**【注】参照透過性を破壊するため、特別な事情がない限り使わないでください。あくまで参考程度の紹介です。**

デバッグで示した`putStrLn`による例を書き替えます。`fact`の戻り値がアクションではなくなっていることに注意してください。

```hs:非推奨
import System.IO.Unsafe

fact 0 = unsafePerformIO $ do
    putStrLn "fact 0 = 1"
    return 1
fact n | n > 0 = unsafePerformIO $ do
    let dbg = "fact " ++ show n ++ " = " ++
              show n ++ " * fact " ++ show (n - 1)
    putStrLn dbg
    let n' = fact (n - 1)
    let ret = n * n'
    putStrLn $ dbg ++ " = " ++ show n ++ " * " ++ show n' ++ " = " ++ show ret
    return ret

main = do
    print $ fact 5
```
```text:実行結果
fact 5 = 5 * fact 4
fact 4 = 4 * fact 3
fact 3 = 3 * fact 2
fact 2 = 2 * fact 1
fact 1 = 1 * fact 0
fact 0 = 1
fact 1 = 1 * fact 0 = 1 * 1 = 1
fact 2 = 2 * fact 1 = 2 * 1 = 2
fact 3 = 3 * fact 2 = 3 * 2 = 6
fact 4 = 4 * fact 3 = 4 * 6 = 24
fact 5 = 5 * fact 4 = 5 * 24 = 120
120
```

このコードは次の記事を参考にしました。

* [print debug on Haskell](http://qiita.com/gfx/items/8260137b1835790ade87)

何のために`unsafePerformIO`が存在するかは、次の記事が参考になります。

* [unsafePerformIO を使って IO を外す - sirocco の書いてもすぐに忘れるメモ](http://d.hatena.ne.jp/sirocco/20110610/1307694359)

## 練習

【問12】`unsafePerformIO`と`putStrLn`を使って、`trace`の標準出力版関数`trace'`を実装してください。

具体的には以下のコードが動くようにしてください。

【注】ghciでは挙動が変わります。解答例はコンパイルしたときにのみ正常動作します。

```hs
fact 0 = trace' "fact 0 = 1" 1
fact n | n > 0 = trace' dbg0 $ trace' dbg1 ret
    where
        ret  = n * fn1
        fn1  = fact $ n - 1
        dbg0 = "fact " ++ show n ++ " = " ++
               show n ++ " * fact " ++ show (n - 1)
        dbg1 = dbg0 ++ " = " ++
               show n ++ " * " ++ show fn1 ++ " = " ++ show ret

main = do
    print $ fact 5
```
```text:実行結果
fact 5 = 5 * fact 4
fact 4 = 4 * fact 3
fact 3 = 3 * fact 2
fact 2 = 2 * fact 1
fact 1 = 1 * fact 0
fact 0 = 1
fact 1 = 1 * fact 0 = 1 * 1 = 1
fact 2 = 2 * fact 1 = 2 * 1 = 2
fact 3 = 3 * fact 2 = 3 * 2 = 6
fact 4 = 4 * fact 3 = 4 * 6 = 24
fact 5 = 5 * fact 4 = 5 * 24 = 120
120
```

⇒ [解答例](http://qiita.com/7shi/items/623fd55b8b68398becdc#%E3%83%88%E3%83%AC%E3%83%BC%E3%82%B9)

# 参考

アクションについての詳細は次の記事が参考になります。

* [Haskell I/Oアクションの紹介 - HaskellWiki](http://www.haskell.org/haskellwiki/Hakell_I/O%E3%82%A2%E3%82%AF%E3%82%B7%E3%83%A7%E3%83%B3%E3%81%AE%E7%B4%B9%E4%BB%8B)
