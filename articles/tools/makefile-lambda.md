---
coediting: false
comments_count: 0
created_at: '2020-05-14T17:48:03+09:00'
id: f557b199557fc3a6648a
likes_count: 1
private: false
reactions_count: 0
stocks_count: 2
tags:
- name: JavaScript
  versions: []
- name: Makefile
  versions: []
title: ラムダ式とMakefileマクロ
updated_at: '2020-05-14T18:08:10+09:00'
url: https://qiita.com/7shi/items/f557b199557fc3a6648a
slide: false
---

Makefile のマクロでラムダ式っぽいことができることに気付いたのでメモしておきます。

# ループ

Node.js でカレントディレクトリのファイルを列挙する例です。

```javascript:test1.js
const fs = require("fs");
for (let f of fs.readdirSync(".")) console.log(f);
```

これと同じことを Makefile で書きます。

```makefile:test1.mk
all:
	for f in ./*; do echo $$f; done
```

※ Makefile の変数と区別するため、`$` を `$$` にエスケープする必要があります。

# ラムダ式とマクロ

Node.js を `forEach` で書き直します。

```javascript:test2.js
const fs = require("fs");
fs.readdirSync(".").forEach(f => console.log(f));
```

これと同じようなことを Makefile のマクロで書きます。

```makefile:test2.mk
define forEach
for $1 in $2; do $3; done
endef

all:
	$(call forEach,f,./*,echo $$f)
```
```text:実行結果
$ make -f test2.mk
for f in ./*; do echo $f; done
./test1.js
./test1.mk
（略）
```

※ `@` で抑制していないためマクロの展開結果が確認できます。

ただのループなのであまり嬉しさはありませんが、もう少し複雑な処理に応用すると便利かもしれません。

なお、JavaScript の `forEach` はコールバックに引数を3つ渡す仕様のため、ポイントフリースタイルで書くと実行結果が変わります。

```javascript:test2a.js
const fs = require("fs");
fs.readdirSync(".").forEach(console.log);
```
```text:実行結果
test1.js 0 [ 'test1.js', 'test1.mk', （略） ]
test1.mk 1 [ 'test1.js', 'test1.mk', （略） ]
（略）
```

# フィルター

Node.js の API ではワイルドカードが使えないため、フィルターを挟む必要があります。

```javascript:test3.js
const fs = require("fs");
fs.readdirSync(".").filter(f => f.endsWith(".js")).forEach(f => console.log(f));
```

Makefile は中に書いているのはシェルのコマンドなのでワイルドカードが使えますが、敢えてフィルターを書いてみます。

```makefile:test3.mk
define forEach
for $1 in $2; do $3; done
endef
define filter_
if $1; then $2; fi
endef
define endsWith
[ "`echo $1 | sed 's/.*$2$$/ok/'`" = "ok" ]
endef

all:
	$(call forEach,f,./*,$(call filter_,$(call endsWith,$$f,\.js),echo $$f))
```

※ 組み込み関数 `filter` と名前が被るため、マクロは `filter_` にしています。

```text:実行結果
$ make -f test3.mk
for f in ./*; do if [ "`echo $f | sed 's/.*\.js$/ok/'`" = "ok" ]; then echo $f; fi; done
./test1.js
（略）
```

実用性はともかく、ちょっと面白いと思いました。

# 参考

マクロの使い方は以下の記事を参考にしました。

* [Make覚書](https://qiita.com/Shigets/items/27170827707e5136ee89)
