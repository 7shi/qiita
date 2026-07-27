---
coediting: false
comments_count: 0
created_at: '2015-01-11T00:41:57+09:00'
id: 1e6b5899db3ab6b6a8fc
likes_count: 2
private: false
reactions_count: 0
stocks_count: 2
tags:
- name: Haskell
  versions: []
title: リストとIOUArray
updated_at: '2015-05-07T12:05:17+09:00'
url: https://qiita.com/7shi/items/1e6b5899db3ab6b6a8fc
slide: false
---

[Haskellの実験メモ](http://qiita.com/7shi/items/b6cbb7df2dd969c84f49)です。

別のリストを作り続ける方法と、IOUArrayで書き替える方法を比較しました。

※ UArrayの存在は知っていますが、意図的にリストを使いました。

# リスト

変更後のリストは作り直しているので`print`以外の副作用はありません。

```hs
writeList list index value =
    take index list ++ [value] ++ drop (index + 1) list

main = do
    let a = [1,2,3]
    print a
    
    let b = writeList a 0 9
    print b
    
    let c = writeList b 2 9
    print c
```
```text:実行結果
[1,2,3]
[9,2,3]
[9,2,9]
```

# IOUArray

書き換えで副作用が発生しています。

```hs
import Data.Array.IO

main = do
    a <- newListArray (0,2) [1,2,3] :: IO (IOUArray Int Int)
    print =<< getElems a
    
    writeArray a 0 9
    print =<< getElems a
    
    writeArray a 2 9
    print =<< getElems a
```
```text:実行結果
[1,2,3]
[9,2,3]
[9,2,9]
```
