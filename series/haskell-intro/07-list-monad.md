---
coediting: false
comments_count: 0
created_at: '2014-12-19T02:37:24+09:00'
id: deb19c4cba933590ffbf
likes_count: 42
private: false
reactions_count: 0
stocks_count: 30
tags:
- name: Haskell
  versions: []
- name: ECMAScript
  versions:
  - '2015'
title: Haskell リストモナド 超入門
updated_at: '2026-08-03T16:19:31+09:00'
url: https://qiita.com/7shi/items/deb19c4cba933590ffbf
slide: false
---

Haskellではモナドと呼ばれる部品を組み合わせてプログラムを作ります。IOモナドを取っ掛かりにリストをモナドとして扱いながら、モナドに共通する性質を探ります。モナドについての一般論へ進む前の準備を目的としているため、IOとリスト以外のモナドや圏論には言及しません。

シリーズの記事です。

1. [Haskell 超入門](http://qiita.com/7shi/items/145f1234f8ec2af923ef)
1. [Haskell 代数的データ型 超入門](http://qiita.com/7shi/items/1ce76bde464b4a55c143)
1. [Haskell アクション 超入門](http://qiita.com/7shi/items/85afd7bbd5d6c4115ad6)
1. [Haskell ラムダ 超入門](http://qiita.com/7shi/items/1345bf32003faff435cb)
1. [Haskell アクションとラムダ 超入門](http://qiita.com/7shi/items/4a8a2807bb5186576c61)
1. [Haskell IOモナド 超入門](http://qiita.com/7shi/items/d3d3492ddd90d47160f2)
1. **Haskell リストモナド 超入門** ← この記事
1. [Haskell Maybeモナド 超入門](http://qiita.com/7shi/items/c7d7eec066af0fe0688d)
1. [Haskell 状態系モナド 超入門](http://qiita.com/7shi/items/2e9bff5d88302de1a9e9)
1. [Haskell モナド変換子 超入門](http://qiita.com/7shi/items/4408b76624067c17e933)
1. [Haskell 例外処理 超入門](http://qiita.com/7shi/items/73e534c47bbebc71b37e)
1. [Haskell 構文解析 超入門](http://qiita.com/7shi/items/b8c741e78a96ea2c10fe)
1. [Haskell 継続モナド 超入門](https://zenn.dev/7shi/articles/20260803-haskell-continuation-monad)
1. 【予定】Haskell 型クラス 超入門
1. 【予定】Haskell モナドとゆかいな仲間たち
1. 【予定】Haskell Freeモナド 超入門
1. 【予定】Haskell Operationalモナド 超入門
1. 【予定】Haskell Effモナド 超入門
1. 【予定】Haskell アロー 超入門

練習の解答例は別記事に掲載します。

* [【解答例】Haskell リストモナド 超入門](http://qiita.com/7shi/items/4a24fd9395f5a60d811d)

F#に応用した記事があります。

* [コンピュテーション式でモナドを作ってみる](http://qiita.com/7shi/items/026c7daa5b0b24d02c0f)

# モナド

bind（`>>=`）と`return`で操作できる対象をモナドと呼びます。

※ bindと`return`が使えれば何でも良いわけではなく、モナド則というルールがあります。今回の範囲を超えるため詳細は省略しますが、興味があれば次の記事を参照してください。

* [@7shi](https://twitter.com/7shi): [モナド則がちょっと分かった？](http://qiita.com/7shi/items/547b6137d7a3c482fe68) 2015.3.9（改訂）

## IOモナド

IOモナドはモナドの一種で、次のような性質を持っています。

![iomonad.png](https://qiita-image-store.s3.amazonaws.com/0/32057/20ef9c29-6282-e929-1d91-20d770d668b8.png)

1. IOモナドは中に値を持っています。
2. IOモナドと関数をbindでつなぐと、それらを含んだIOモナドが作れます。
3. `return`で指定した値を入れたIOモナドが作れます。

これらはモナド共通の性質を反映してはいますが、他のモナドでは扱いが異なる部分もあります。IOモナドは内部に隠された関数から値を生成していますが、モナドの内部構造については規定がないため、必ずしも関数から値を生成しないといけないわけではありません。

IO以外のモナドとして、手始めにリストを取り上げます。

# リストモナド

リストはモナドの一種です。モナドとしての側面を強調するときは**リストモナド**と呼ぶこともあります。

※ 今まで使って来た`[1, 2, 3]`のようなリストを指しています。

## return

`return`で値を入れたリストが作れます。`return`で異なる型を共通して作れるという特徴は、オブジェクト指向での[ファクトリメソッド](http://ja.wikipedia.org/wiki/Factory_Method_%E3%83%91%E3%82%BF%E3%83%BC%E3%83%B3)に近い考え方です。

`return`だけでは何のモナドか分からないため、型注釈でリストモナドであることを指定します。型の書き方は2種類あります。`[]`はリスト型を表しており、`[] Int`の書式は`IO Int`と同じように解釈します。

```hs
main = do
    print [1]
    print (return 1 :: [Int])
    print (return 1 :: [] Int)
```
```text:実行結果
[1]
[1]
[1]
```

リストは`print`で中身ごと表示できるため、中に値が入っているのは直感的に分かります。IOモナドのように関数経由で値を生成しているわけではなく、値を直接持っています。

### 型推論

`print`と結合するにはIOモナドである必要があるため、`return`に型注釈を付けなければ、**型推論**によって自動的にIOモナドとして扱われます。

```hs
main = do
    print =<< return 1
```
```text:実行結果
1
```

## 副作用

IOモナドは副作用を扱います。副作用がIOモナドの外に漏れないように、一度IOモナドに入れた値は原則取り出すことができません。

※ `unsafePerformIO`は基本的に使ってはいけない関数です。

リストに対する処理は副作用がないため、リストからの値の取り出しは自由に行えます。値を見るだけなら取り出さなくてもリストのままで確認できます。

```hs
main = do
    let a = return 1 :: IO Int
        b = return 1 :: [] Int
    print =<< a
    print $ b !! 0
    print b
```
```text:実行結果
1
1
[1]
```

副作用に縛られているのはIOモナドの特徴で、モナドに共通する特徴ではありません。言い換えると、副作用をモナドの枠組みで取り扱うために作られたのがIOモナドです。

## 練習

【問1】`[`と`]`は使わないで、`return`を使って`[1, 2, 3]`を作ってください。

⇒ [解答例](http://qiita.com/7shi/items/4a24fd9395f5a60d811d#%E3%83%AA%E3%82%B9%E3%83%88%E3%81%AE%E4%BD%9C%E6%88%90)

# bind

bindでモナドを結合するとき、結合先の関数は**同種の**モナドを返す必要があります。

値を受け取ってリストを返す関数であれば、リストとbindできます。

```hs
main = do
    print $ [7] >>= replicate 3
    print $ "7" >>= replicate 3
```
```text:実行結果
[7,7,7]
"777"
```

`[7]`はリストで、`[7] >>= replicate 3`の結果もリストです。リストを関数とbindすればリストになるという構図は、IOモナドのbindと同じです。

![listmonad.png](https://qiita-image-store.s3.amazonaws.com/0/32057/0c3756b7-62a7-b8e0-5899-69fa56f97f5f.png)

## 異なる型

`print`はIOモナドを返すため、リストモナドとはbindできません。

```hs:NG
main = do
    print =<< [1]
```
```text:エラー内容
Couldn't match type `[]' with `IO'
Expected type: IO a0
  Actual type: [a0]
（略）
```

リストは中身ごと表示できるため、わざわざ値を取り出して表示する必要はありません。

## 多相

bind先の関数に型注釈を書かないで`return`を使えば、異なる種類のモナドを受け付ける関数ができます。このように異なる型をまとめて扱うことを**多相**と呼びます。

```hs
inc x = return $ x + 1

main = do
    print $   inc =<< [1]
    print =<< inc =<< return 1
```
```text:実行結果
[2]
2
```

## 型変数

多相で型注釈を書くときは、小文字で始まる適当な名前を付けます。これを**型変数**と呼びます。型名は大文字で始まると決まっているため、小文字で始まれば自動的に型変数となります。型変数の文字数に決まりはありませんが、一文字で書くことが多いです。

次の`rep`の型注釈にある`a`が型変数です。

```hs
rep :: Int -> a -> [a]
rep 0 _ = []
rep n x = x : rep (n - 1) x

main = do
    print $ rep 3 7
    print $ rep 5 'a'
```
```text:実行結果
[7,7,7]
"aaaaa"
```

## 型クラス制約

`IO Int`の`IO`の部分を型変数化する場合、型変数に対してそれがモナドであることを指定する必要があります。これを**型クラス制約**と呼びます。

```hs
inc :: Monad m => Int -> m Int
inc x = return $ x + 1

main = do
    print $   inc =<< [1]
    print =<< inc =<< return 1
```
```text:実行結果
[2]
2
```

`Monad m =>`の部分が型クラス制約で、`m`が`Monad`であるということを示しています。次に示す`IO`や`[]`を型変数で表すために付け加えていると解釈すれば良いでしょう。

```hs
a ::            IO Int
b ::            [] Int
c :: Monad m => m  Int
```

## Applicativeスタイル

Applicativeスタイルでは関数に渡されるのはモナドではないため、型クラス制約は意識する必要がありません。

```hs
import Control.Applicative

inc :: Int -> Int
inc = (+ 1)

main = do
    print $   inc <$> [1]
    print =<< inc <$> return 1
```
```text:実行結果
[2]
2
```

## 練習

【問2】次に示す関数`join`の型から仕様を推定して、コードで検証してください。

[Control.Monad](http://hackage.haskell.org/package/base-4.7.0.1/docs/Control-Monad.html)より

```hs
join :: Monad m => m (m a) -> m a
```

⇒ [解答例](http://qiita.com/7shi/items/4a24fd9395f5a60d811d#%E5%9E%8B%E3%82%AF%E3%83%A9%E3%82%B9%E5%88%B6%E7%B4%84)

# do

IOモナドと同じようにリストでも`do`が使えます。最後に`return`でモナドを返すのも同様です。

```hs
test x = do
    a <- [x]
    return $ a + 1

main = do
    print $ test 1
```
```text:実行結果
[2]
```

`do`の実体がbindによる連結なのも同様です。

```hs
test x =
    [x] >>= \a ->
    return $ a + 1

main = do
    print $ test 1
```
```text:実行結果
[2]
```

このようにIOモナドもリストも同じように`do`やbindなどの枠組みで扱えることが、モナドとしての共通性です。

## 異なる型

1つの`do`の中では同じ種類のモナドしか扱えません。`do`はbindの糖衣構文で、bindが同種のモナドしか連結できないことに由来しています。

```hs:NG
main = do
    a <- print "a"
    b <- [1]
    return ()
```
```text:エラー内容
Couldn't match type `[]' with `IO'
Expected type: IO t0
  Actual type: [t0]
```

ネストさせた`do`では別種のモナドが扱えます。

```hs
main = do
    print $ do
        a <- [1]
        return $ a + 1
    print $
        [1] >>= \a ->
        return $ a + 1
```
```text:実行結果
[2]
[2]
```

第1段階の`do`はIOモナド、第2段階の`do`はリストモナドとなっています。

## 複数の要素

リスト内の要素が複数あった場合の挙動を見てみます。

```hs
main = do
    print $ do
        a <- [1, 2, 3]  -- 複数の値へのbind
        return $ a * 2  -- 繰り返される
```
```text:実行結果
[2,4,6]
```

`<-`から先の行が繰り返されて、結果が結合されてリストになります。

今までは1つの要素しか入っていないリストを見ていたため、`<-`は単なる値の取り出しだと見なせました。リストは複数の要素を含めるという特徴があるため、`<-`もそれに合わせて特有の動きをしています。

### ループ

先ほどの例は慣れるまでは動きがイメージしにくいかもしれませんが、他の言語でのループに相当します。

```js:ES2015
console.log(function () {
    let ret = [];
    for (let a of [1, 2, 3]) {  // 複数の値でのループ
        ret.push(a * 2);        // 繰り返される
    }
    return ret;
}());
```
```text:実行結果(io.js)
[ 2, 4, 6 ]
```

※ 意図して手続的に書いています。ジェネレータに慣れている方は[ジェネレータでリストモナドを模倣してみた](http://qiita.com/7shi/items/8ec339bcddbb6692b738)を参照してください。

`forM`でループに書き替えてみます。

```hs
import Control.Monad

main = do
    print $
        forM [1, 2, 3] $ \x ->
            return $ x * 2 :: [] Int
```
```text:実行結果
[[2,4,6]]
```

`forM`はリストをモナドに包んで返します。この場合はリストモナドで包んでいるため、リストが二重になっています。

ネストしたモナドを`join`で統合します。`join`により型推論が効くため`return`の型注釈は省略できます。

```hs
import Control.Monad

main = do
    print $ join $              -- joinの追加
        forM [1, 2, 3] $ \x ->
            return $ x * 2      -- 型注釈の省略
```
```text:実行結果
[2,4,6]
```

### 多重ループ

`do`の中で複数のリストから値を取り出せば多重ループとなります。

```hs
main = do
    print $ do
        a <- [1, 2, 3]
        b <- [4, 5, 6]  -- 追加
        return $ a * b  -- 変更
```
```text:実行結果
[4,5,6,8,10,12,12,15,18]
```

これも先ほどと同じで、それぞれ`<-`から先の行がループしていると捉えれば、多重ループ構造が見えてくるのではないでしょうか。

```js:ES2015
console.log(function () {
    let ret = [];
    for (let a of [1, 2, 3]) {
        for (let b of [4, 5, 6]) {  // 追加
            ret.push(a * b);        // 変更
        }
    }
    return ret;
}());
```
```text:実行結果
[ 4, 5, 6, 8, 10, 12, 12, 15, 18 ]
```

### 空のリスト

空のリストを与えると、後続の処理が行われません。

```hs
main = do
    print $ do
        a <- [1, 2, 3]
        b <- []         -- 空のリスト
        return $ a * b  -- 処理されない
```
```text:実行結果
[]
```

ソースが空ならループの中には入らないことで解釈できます。

```js:ES2015
console.log(function () {
    let ret = [];
    for (let a of [1, 2, 3]) {
        for (let b of []) {     // ソースが空
            ret.push(a * b);    // 処理されない
        }
    }
    return ret;
}());
```
```text:実行結果(io.js)
[]
```

## ポリモーフィズム

モナドは`do`や`<-`などの同じ枠組みを使いながら、種類によって特有の動きがあります。これはオブジェクト指向での[ポリモーフィズム](http://ja.wikipedia.org/wiki/%E3%83%9D%E3%83%AA%E3%83%A2%E3%83%BC%E3%83%95%E3%82%A3%E3%82%BA%E3%83%A0)（多態）に近い考え方です。

「モナド特有の動きをその都度覚えないといけない」と捉えるとうんざりしますが、仕様はモナドが含むデータの性質から決められています。そのことを意識してイメージすれば、それほど外すことはないはずです。

リストには複数の要素を含むことがあるため、取り出し動作も1つずつ行うというような感じです。

## 練習

【問3】次のコードを`join`と`forM`で書き替えてください。

```hs
main = do
    print $ do
        x <- [1..3]
        y <- "abc"
        return (x, y)
```

⇒ [解答例](http://qiita.com/7shi/items/4a24fd9395f5a60d811d#%E3%83%AB%E3%83%BC%E3%83%97)

【問4】リストモナドを扱う`bind`と`return'`を実装してください。`bind`には`foldr`を使ってください。

具体的には次のコードが動くようにしてください。

```hs
main = do
    print $ [1..3] `bind` \x -> "abc" `bind` \y -> return' (x, y)
```
```text:実行結果
[(1,'a'),(1,'b'),(1,'c'),(2,'a'),(2,'b'),(2,'c'),(3,'a'),(3,'b'),(3,'c')]
```

⇒ [解答例](http://qiita.com/7shi/items/4a24fd9395f5a60d811d#%E5%86%8D%E5%AE%9F%E8%A3%85)

# リスト内包表記

リストに特化した`do`の糖衣構文がリスト内包表記です。表記上の違いだけで、リストのモナド的な側面に既に触れていたわけです。

`do`とリスト内包表記とを対比させます。`<-`の役割がリスト内包表記と`do`で同じなのを確認してください。

```hs
main = do
    print $ do
        x <- [1..5]
        return $ x * 2
    print [x * 2 | x <- [1..5]]

    print $ do
        x <- [1..3]
        y <- "abc"
        return (x, y)
    print [(x, y) | x <- [1..3], y <- "abc"]
```
```text:実行結果
[2,4,6,8,10]
[2,4,6,8,10]
[(1,'a'),(1,'b'),(1,'c'),(2,'a'),(2,'b'),(2,'c'),(3,'a'),(3,'b'),(3,'c')]
[(1,'a'),(1,'b'),(1,'c'),(2,'a'),(2,'b'),(2,'c'),(3,'a'),(3,'b'),(3,'c')]
```

## 練習

【問5】次のリスト内包表記を`do`で書き換えてください。

```hs
main = do
    print [(x, y) | x <- [1..5], y <- [1..5], x + y == 6]
```

⇒ [解答例](http://qiita.com/7shi/items/4a24fd9395f5a60d811d#%E6%9B%B8%E3%81%8D%E6%8F%9B%E3%81%88)

【問6】問5のコードを問4で実装した`bind`と`return'`に対応させてテストしてください。

⇒ [解答例](http://qiita.com/7shi/items/4a24fd9395f5a60d811d#%E3%83%86%E3%82%B9%E3%83%88)

# まとめ

* bind（`>>=`）と`return`で操作できる対象をモナドと呼びます。
* リストはモナドの一種です。
* IOモナドは中に値を生成する関数がありますが、リストは値が直接入っています。
* 副作用を扱うのはIOモナド特有で、モナド共通の特徴ではありません。
* `do`ブロックは共通の見た目で記述できますが、モナドによって動きが異なります。
* リスト内包表記は`do`の糖衣構文です。

# 参考

モナドについては、次のツイートによくまとめられています。

<blockquote class="twitter-tweet" lang="ja"><p>モナド&#10;&#10;・手続きの性質を持つ圏論（数学の一分野）由来の概念&#10;・モナドによって純粋関数型でも手続きプログラミングが可能になる&#10;・多態性を持つため組み込みの手続きより強力</p>&mdash; ちゅーん (@its_out_of_tune) <a href="https://twitter.com/its_out_of_tune/status/569814434534682624">2015, 2月 23</a></blockquote>

これが理解できれば最初の壁は超えられたと思います。
