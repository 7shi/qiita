---
coediting: false
comments_count: 0
created_at: '2014-12-12T18:21:57+09:00'
id: 539c2c46edfb5313cbc6
likes_count: 15
private: false
reactions_count: 0
stocks_count: 14
tags:
- name: Haskell
  versions: []
title: モナド則の絵を描いてみた
updated_at: '2015-03-12T14:54:12+09:00'
url: https://qiita.com/7shi/items/539c2c46edfb5313cbc6
slide: false
---

この記事は次の記事に統合しました。詳しくはそちらをご覧ください。

* [モナド則がちょっと分かった？](http://qiita.com/7shi/items/547b6137d7a3c482fe68)

# 1. `return x >>= f` == `f x`

![1.png](https://qiita-image-store.s3.amazonaws.com/0/32057/0a2ade75-80e3-250c-70a4-2d6594bd7dfe.png)

# 2. `m >>= return` == `m`

![2.png](https://qiita-image-store.s3.amazonaws.com/0/32057/cb7fbca1-99ea-3669-21ee-ac00bdb57b98.png)

# 3. `(m >>= f) >>= g` == `m >>= (\x -> f x >>= g)`

![3.png](https://qiita-image-store.s3.amazonaws.com/0/32057/d75f4a10-e24f-8919-abcf-41f28bb72bed.png)
