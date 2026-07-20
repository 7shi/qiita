---
coediting: false
comments_count: 0
created_at: '2016-12-14T10:53:22+09:00'
id: 7f490819e818dd7aa37c
likes_count: 0
private: false
reactions_count: 0
stocks_count: 0
tags:
- name: F#
  versions: []
title: functionのインデント
updated_at: '2016-12-14T10:53:22+09:00'
url: https://qiita.com/7shi/items/7f490819e818dd7aa37c
slide: false
---

F#では関数を引数レベルでパターンマッチする `function` というキーワードがあります。このインデントについて気付いたことのメモです。

`function` は `match` のポイントフリースタイル版のような印象を持っていました。

```fsharp:F#
let foo1 = function
| 0 -> "!"
| _ -> "?"

let foo2 x = match x with
             | 0 -> "!"
             | _ -> "?"

printfn "%A" (foo1 0, foo2 0)
printfn "%A" (foo1 1, foo2 1)
```
```text:実行結果
("!", "!")
("?", "?")
```

しかし引数を暗黙化するだけでなく、インデントも異なります。`function` は `let` と同じレベルで書くことが許されますが、`match` は `=` の右辺として扱われます。

これがどういう気持ちなのかずっと分からなかったのですが、Haskellのパターンマッチと似た気持ちなのではないかと気付きました。

```haskell:Haskell
foo1 0 = "!"
foo1 _ = "?"

foo2 x = case x of
         0 -> "!"
         _ -> "?"

main = do
    print (foo1 0, foo2 0)
    print (foo1 1, foo2 1)
```
```text:実行結果
("!","!")
("?","?")
```

Haskellでは形式的に関数自体を複数書くようなスタイルで引数をパターンマッチしますが、これと同じようにF#でも関数レベルで引数を分けているという気持ちでインデントが許されているのではないか、ということです。
