---
coediting: false
comments_count: 2
created_at: '2014-11-02T23:01:49+09:00'
id: 4601dff7664311659723
likes_count: 2
private: false
reactions_count: 0
stocks_count: 1
tags:
- name: JavaScript
  versions: []
- name: Haskell
  versions: []
title: HaskellのバブルソートをJavaScriptに直訳してみた
updated_at: '2014-11-02T23:27:48+09:00'
url: https://qiita.com/7shi/items/4601dff7664311659723
slide: false
---

Haskellで実装したバブルソートをJavaScriptに直訳してみました。効率は度外視して直訳を優先しています。

# Haskell

* [Haskellでバブルソート#まとめ](http://qiita.com/7shi/items/1e2a66bf8e8c7f0bd70f#%E3%81%BE%E3%81%A8%E3%82%81)

```hs
bswap [x] = [x]
bswap (x:xs)
    | x > y     = y:x:ys
    | otherwise = x:y:ys
    where
        (y:ys) = bswap xs

bsort [] = []
bsort xs = y : bsort ys
    where
        (y:ys) = bswap xs

main = do
    print $ bswap [4, 3, 1, 5, 2]
    print $ bsort [4, 3, 1, 5, 2]
    print $ bsort [5, 4, 3, 2, 1]
    print $ bsort [4, 6, 9, 8, 3, 5, 1, 7, 2]
```
```text:実行結果
[1,4,3,2,5]
[1,2,3,4,5]
[1,2,3,4,5]
[1,2,3,4,5,6,7,8,9]
```

# JavaScript

```js
"use strict";

function bswap(xs) {
    if (xs.length == 1) return xs;
    var x = xs.shift();
    var ys = bswap(xs);
    var y = ys.shift();
    if (x > y) return [y, x].concat(ys);
    return [x, y].concat(ys);
}

function bsort(xs) {
    if (xs.length == 0) return [];
    var ys = bswap(xs);
    var y = ys.shift();
    return [y].concat(bsort(ys));
}

console.log(bswap([4, 3, 1, 5, 2]));
console.log(bsort([4, 3, 1, 5, 2]));
console.log(bsort([5, 4, 3, 2, 1]));
console.log(bsort([4, 6, 9, 8, 3, 5, 1, 7, 2]));
```
```text:実行結果
[ 1, 4, 3, 2, 5 ]
[ 1, 2, 3, 4, 5 ]
[ 1, 2, 3, 4, 5 ]
[ 1, 2, 3, 4, 5, 6, 7, 8, 9 ]
```

`var`を付け忘れてバグに悩まされたので、敢えて`"use strict"`を残しています。
