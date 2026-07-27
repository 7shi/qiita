---
coediting: false
comments_count: 0
created_at: '2019-12-22T01:46:48+09:00'
id: b0b95610b59050e42666
likes_count: 10
private: false
reactions_count: 0
stocks_count: 10
tags:
- name: アルゴリズム
  versions: []
- name: レーベンシュタイン距離
  versions: []
title: レーベンシュタイン距離のコードの解釈
updated_at: '2023-09-23T15:16:32+09:00'
url: https://qiita.com/7shi/items/b0b95610b59050e42666
slide: false
---

Wikipediaのレーベンシュタイン距離のコードの解釈で混乱したため、メモを残します。

レーベンシュタイン距離は文字列の類似度を調べる最も基本的なアルゴリズムです。この記事ではレーベンシュタイン距離そのものの説明はしないで、コードの解釈に集中します。

レーベンシュタイン距離の説明は色々な記事がありますが、分かりやすそうな記事を1つ挙げておきます。

* [【技術解説】似ている文字列がわかる！レーベンシュタイン距離とジャロ・ウィンクラー距離の計算方法とは](https://mieruca-ai.com/ai/levenshtein_jaro-winkler_distance/)

# 日本語版

まず日本語版のWikipediaを読みます。

* [レーベンシュタイン距離](https://ja.wikipedia.org/wiki/%E3%83%AC%E3%83%BC%E3%83%99%E3%83%B3%E3%82%B7%E3%83%A5%E3%82%BF%E3%82%A4%E3%83%B3%E8%B7%9D%E9%9B%A2)

次の記述があります。

> 以下に、文字数 `lenStr1` の文字列 `str1` と、文字数 `lenStr2` の 文字列 `str2` 間のレーベンシュタイン距離を求める擬似コードを示す。このコードにおいて `d[i1,i2]` には、`str1` の `i1` 文字目までの文字列と `str2` の `i2` 文字目までの文字列の間のレーベンシュタイン距離が格納される。

`str1="biting", str2="whiten"` のときの配列 `d[i1,i2]` の様子を部分文字列と共に示します。

d|i1=0|i1=1|i1=2|i1=3|i1=4|i1=5|i1=6
----|----|----|----|----|----|----|----
**i2=0**|<br><br>0|b<br><br>1|bi<br><br>2|bit<br><br>3|biti<br><br>4|bitin<br><br>5|biting<br><br>6
**i2=1**|<br>w<br>1|b<br>w<br>1|bi<br>w<br>2|bit<br>w<br>3|biti<br>w<br>4|bitin<br>w<br>5|biting<br>w<br>6
**i2=2**|<br>wh<br>2|b<br>wh<br>2|bi<br>wh<br>2|bit<br>wh<br>3|biti<br>wh<br>4|bitin<br>wh<br>5|biting<br>wh<br>6
**i2=3**|<br>whi<br>3|b<br>whi<br>3|bi<br>whi<br>2|bit<br>whi<br>3|biti<br>whi<br>3|bitin<br>whi<br>4|biting<br>whi<br>5
**i2=4**|<br>whit<br>4|b<br>whit<br>4|bi<br>whit<br>3|bit<br>whit<br>2|biti<br>whit<br>3|bitin<br>whit<br>4|biting<br>whit<br>5
**i2=5**|<br>white<br>5|b<br>white<br>5|bi<br>white<br>4|bit<br>white<br>3|biti<br>white<br>3|bitin<br>white<br>4|biting<br>white<br>5
**i2=6**|<br>whiten<br>6|b<br>whiten<br>6|bi<br>whiten<br>5|bit<br>whiten<br>4|biti<br>whiten<br>4|bitin<br>whiten<br>3|biting<br>whiten<br>4

※ `i1` と `i2` の縦横への割り当てには任意性があります。ここではセル内で `str1` と `str2` を上下に並べたとき、最初の行で見出しと上下に隣接して分かりやすいため `i1` を横に割り当てました。あくまで表現上の工夫のため、アルゴリズムの本質には影響しません。

掲載されている擬似コードを見ます。

まず `d` の1行目と1列目を埋めます。片方が空文字列のため、もう片方の文字列長がそのままレーベンシュタイン距離となります。

```fsharp
   for Integer i1 := 0 to lenStr1 do let d[i1,0] := i1 ;
   for Integer i2 := 0 to lenStr2 do let d[0,i2] := i2 ;
```

残りは左から1列ずつ、列内を上から埋めていきます。その際に左 `d[i1-1,i2]` と上 `d[i1,i2-1]` と左上 `d[i1-1,i2-1]` の要素を参照します。

```fsharp
   for Integer i1 := 1 to lenStr1 do
       for Integer i2 := 1 to lenStr2 do
           begin
           constant Integer cost := if str1[i1] == str2[i2] then 0 else 1 ;
           let d[i1,i2] := minimum
             (
             d [i1-1, i2  ] + 1,     (* 文字の削除 *)
             d [i1  , i2-1] + 1,     (* 文字の挿入 *)
             d [i1-1, i2-1] + cost   (* 文字の置換 *)
             )
           end ;
```

参照した要素には既に値が入っているのがポイントです。このように依存関係を考慮して計算順序をうまく組み上げる手法を[動的計画法](https://ja.wikipedia.org/wiki/%E5%8B%95%E7%9A%84%E8%A8%88%E7%94%BB%E6%B3%95)と呼びます。

> レーベンシュタイン距離を計算するためには、一般的に動的計画法によるアルゴリズムが用いられている。

それぞれの要素がどの要素から由来するかを矢印で示します。

<table>
<tr><td><font color="red"><br><br>0</font></td><td>→</td><td>b<br><br>1</td><td>→</td><td>bi<br><br>2</td><td>→</td><td>bit<br><br>3</td><td>→</td><td>biti<br><br>4</td><td>→</td><td>bitin<br><br>5</td><td>→</td><td>biting<br><br>6</td></tr>
<tr><td><font color="red">↓</font></td><td><font color="red">↘</font></td><td></td><td>↘</td><td></td><td>↘</td><td></td><td>↘</td><td></td><td>↘</td><td></td><td>↘</td><td></td></tr>
<tr><td><font color="red"><br>w<br>1</font></td><td></td><td><font color="red">b<br>w<br>1</font></td><td>→</td><td>bi<br>w<br>2</td><td>→</td><td>bit<br>w<br>3</td><td>→</td><td>biti<br>w<br>4</td><td>→</td><td>bitin<br>w<br>5</td><td>→</td><td>biting<br>w<br>6</td></tr>
<tr><td>↓</td><td><font color="red">↘</font></td><td><font color="red">↓</font></td><td>↘</td><td></td><td>↘</td><td></td><td>↘</td><td></td><td>↘</td><td></td><td>↘</td><td></td></tr>
<tr><td><br>wh<br>2</td><td></td><td><font color="red">b<br>wh<br>2</font></td><td></td><td>bi<br>wh<br>2</td><td>→</td><td>bit<br>wh<br>3</td><td>→</td><td>biti<br>wh<br>4</td><td>→</td><td>bitin<br>wh<br>5</td><td>→</td><td>biting<br>wh<br>6</td></tr>
<tr><td>↓</td><td>↘</td><td>↓</td><td><font color="red">↘</font></td><td></td><td>↘</td><td></td><td>↘</td><td></td><td></td><td></td><td></td><td></td></tr>
<tr><td><br>whi<br>3</td><td></td><td>b<br>whi<br>3</td><td></td><td><font color="red">bi<br>whi<br>2</font></td><td>→</td><td>bit<br>whi<br>3</td><td></td><td>biti<br>whi<br>3</td><td>→</td><td>bitin<br>whi<br>4</td><td>→</td><td>biting<br>whi<br>5</td></tr>
<tr><td>↓</td><td>↘</td><td>↓</td><td></td><td>↓</td><td><font color="red">↘</font></td><td></td><td></td><td></td><td>↘</td><td></td><td>↘</td><td></td></tr>
<tr><td><br>whit<br>4</td><td></td><td>b<br>whit<br>4</td><td></td><td>bi<br>whit<br>3</td><td></td><td><font color="red">bit<br>whit<br>2</font></td><td>→</td><td>biti<br>whit<br>3</td><td>→</td><td>bitin<br>whit<br>4</td><td>→</td><td>biting<br>whit<br>5</td></tr>
<tr><td>↓</td><td>↘</td><td>↓</td><td></td><td>↓</td><td></td><td>↓</td><td><font color="red">↘</font></td><td></td><td>↘</td><td></td><td>↘</td><td></td></tr>
<tr><td><br>white<br>5</td><td></td><td>b<br>white<br>5</td><td></td><td>bi<br>white<br>4</td><td></td><td>bit<br>white<br>3</td><td></td><td><font color="red">biti<br>white<br>3</font></td><td>→</td><td>bitin<br>white<br>4</td><td>→</td><td>biting<br>white<br>5</td></tr>
<tr><td>↓</td><td>↘</td><td>↓</td><td></td><td>↓</td><td></td><td>↓</td><td>↘</td><td>↓</td><td><font color="red">↘</font></td><td></td><td></td><td></td></tr>
<tr><td><br>whiten<br>6</td><td></td><td>b<br>whiten<br>6</td><td></td><td>bi<br>whiten<br>5</td><td></td><td>bit<br>whiten<br>4</td><td></td><td>biti<br>whiten<br>4</td><td></td><td><font color="red">bitin<br>whiten<br>3</font></td><td><font color="red">→</font></td><td><font color="red">biting<br>whiten<br>4</font></td></tr>
</table>

右下の要素が最終的に求めるレーベンシュタイン距離です。右下から矢印を逆にたどると左上までの経路が抽出できます。それを赤字で示しました。

赤字の部分を抽出すると2つの経路が得られます。最初に分岐していますが、その次で合流します。

<table>
<tr><td><br><br>0</td>
<td>↓</td><td><br>w<br>1</td>
<td>↘</td><td>b<br>wh<br>2</td>
<td>↘</td><td>bi<br>whi<br>2</td>
<td>↘</td><td>bit<br>whit<br>2</td>
<td>↘</td><td>biti<br>white<br>3</td>
<td>↘</td><td>bitin<br>whiten<br>3</td>
<td>→</td><td>biting<br>whiten<br>4</td></tr>
</table>

<table>
<tr><td><br><br>0</td>
<td>↘</td><td>b<br>w<br>1</td>
<td>↓</td><td>b<br>wh<br>2</td>
<td>↘</td><td>bi<br>whi<br>2</td>
<td>↘</td><td>bit<br>whit<br>2</td>
<td>↘</td><td>biti<br>white<br>3</td>
<td>↘</td><td>bitin<br>whiten<br>3</td>
<td>→</td><td>biting<br>whiten<br>4</td></tr>
</table>

コードと比較すれば、左に由来する「→」が削除、上に由来する「↓」が挿入、左上に由来する「↘」が置換とされています。

```fsharp
           constant Integer cost := if str1[i1] == str2[i2] then 0 else 1 ;
           let d[i1,i2] := minimum
             (
             d [i1-1, i2  ] + 1,     (* 文字の削除 *)
             d [i1  , i2-1] + 1,     (* 文字の挿入 *)
             d [i1-1, i2-1] + cost   (* 文字の置換 *)
             )
```

これは `str1` を1文字ずつ調べながら変形して `str2` を得る操作のコストを表します。このコードで求めているのはあくまでコストであって、文字列の変形は行っていないのに注意が必要です。

変形の過程を表に追加します。「↘」は必ずしも置換するわけではなく、`cost` が `0` なら何もしません。

str1|挿入|置換|なし|なし|置換|なし|削除
----|----|----|----|----|----|----|----
biting|<font color="red">w</font>biting|w<font color="red">h</font>iting|wh<font color="red">i</font>ting|whi<font color="red">t</font>ing|whit<font color="red">e</font>ng|white<font color="red">n</font>g|whiten<font color="red">~~g~~</font>
0|1|2|2|2|3|3|4|

str1|置換|挿入|なし|なし|置換|なし|削除
----|----|----|----|----|----|----|----
biting|<font color="red">w</font>iting|w<font color="red">h</font>iting|wh<font color="red">i</font>ting|whi<font color="red">t</font>ing|whit<font color="red">e</font>ng|white<font color="red">n</font>g|whiten<font color="red">~~g~~</font>
0|1|2|2|2|3|3|4|

部分文字列を示した配列の表において、削除や挿入を行う対象はまた別にあるというのがポイントです。部分文字列だけを見て解釈しようとして、削除の意味が分からずに混乱しました。

配列を解釈しようとする姿勢については次の記事を参考にしました。

* [文字列間の距離を測るレーベンシュタイン距離がシンプルで美しかった](https://qiita.com/3000manJPY/items/c28ed74d2d06971c34ef)

## グラフ

グラフ化することで2つの経路の関係を視覚的に把握することができます。

* [レーベンシュタイン距離の編集操作を統合してグラフ化する](https://qiita.com/yut-kt/items/54b7b8bca759b8636345)

こちらの記事を参考に手動でグラフを作成してみました。

```text:Lebenshtein.dot
digraph {
	node [shape=record style=filled]
	start [label="biting" color=pink shape=circle]
	end [label="whiten" color=pink shape=circle]
	node1 [label="[w]biting"]
	node2 [label="[w]iting"]
	node3 [label="w[h]iting"]
	node4 [label="wh[i]ting"]
	node5 [label="whi[t]ing"]
	node6 [label="whit[e]ng"]
	node7 [label="white[n]g"]
	start -> node1 [label="insert 'w'"]
	node1 -> node3 [label="replace 'b' -> 'h'"]
	start -> node2 [label="replace 'b' -> 'w'"]
	node2 -> node3 [label="insert 'h'"]
	node3 -> node4
	node4 -> node5
	node5 -> node6 [label="replace 'i' -> 'e'"]
	node6 -> node7
	node7 -> end [label="delete 'g'"]
}
```

![leben.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/32057/97272460-9686-75f4-2673-924db4ff956f.png)

# 英語版

次に英語版の記事を読みます。

* [Levenshtein distance](https://en.wikipedia.org/wiki/Levenshtein_distance)

## 再帰

まず再帰によるC言語のコードが示されます。

```c
// len_s and len_t are the number of characters in string s and t respectively
int LevenshteinDistance(const char *s, int len_s, const char *t, int len_t)
{ 
  int cost;

  /* base case: empty strings */
  if (len_s == 0) return len_t;
  if (len_t == 0) return len_s;

  /* test if last characters of the strings match */
  if (s[len_s-1] == t[len_t-1])
      cost = 0;
  else
      cost = 1;

  /* return minimum of delete char from s, delete char from t, and delete char from both */
  return minimum(LevenshteinDistance(s, len_s - 1, t, len_t    ) + 1,
                 LevenshteinDistance(s, len_s    , t, len_t - 1) + 1,
                 LevenshteinDistance(s, len_s - 1, t, len_t - 1) + cost);
}
```

`return` の直前のコメントは、文字列の末尾の文字を削って再帰することを説明しています。

以下の記事にはほぼ同じアルゴリズムがPythonで説明されています。末尾ではなく先頭を削って再帰している点が異なりますが、最終的には同じ結果が得られます。

* [編集距離（レーベンシュタイン距離）を理解し、実装する](https://qiita.com/tanuk1647/items/5a591da10e2ea5bedef6)

```python
@lru_cache(maxsize=4096)
def ld(s, t):
    if not s: return len(t)
    if not t: return len(s)
    if s[0] == t[0]: return ld(s[1:], t[1:])
    l1 = ld(s, t[1:])
    l2 = ld(s[1:], t)
    l3 = ld(s[1:], t[1:])
    return 1 + min(l1, l2, l3)
```

Wikipediaでは再帰は同じ計算を何度も繰り返すため非効率だとして動的計画法に進みますが、このコードは再帰のままデコレーターによりメモ化しています。前掲の記事ではデコレーターとメモ化について詳しく説明されているため、レーベンシュタイン距離に限らず参考になります。

## Wagner–Fischer アルゴリズム

レーベンシュタイン距離を求めるための動的計画法によるアルゴリズムの名前です。

このアルゴリズムによるコードは日本語版のものと基本的に同じです。

```pascal
          if s[i] = t[j]:
            substitutionCost := 0
          else:
            substitutionCost := 1

          d[i, j] := minimum(d[i-1, j] + 1,                   // deletion
                             d[i, j-1] + 1,                   // insertion
                             d[i-1, j-1] + substitutionCost)  // substitution
```

Wikipediaではコードの後に経路が掲載されています。経路に下線が引かれていて、マウスポインタを載せると説明（deleteやinsert）が表示されます。その説明から `i` が縦（行）で `j` が横（列）に割り当てられていることが分かります。

2つ例が示されていますが、それぞれ次の組み合わせです。deletionやinsertionは `s` に対する操作で、最終的に `t` に変形されます。

* `s="sitting", t="kitten"` （削除・置換）
* `s="Sunday", t="Saturday"` （挿入・置換）

日本語版では縦横は明示されていませんでしたが、自分が理解する際に英語版とは縦横が逆の表を作ったことで混乱してしまいました。

また、Wikipediaでは日本語版と英語版ともに「kitten」を「sitting」に変形する例が示されています。表でも同じ向きの変形かと早合点して `s` と `t` を逆に捉えてしまったため、コードの解釈で混乱しました。

> + <b>k</b>itten → <b>s</b>itten (substitution of "s" for "k")
> + sitt<b>e</b>n → sitt<b>i</b>n (substitution of "i" for "e")
> + sittin → sittin<b>g</b> (insertion of "g" at the end).

# 英単語

英語版には2つの例が載っていますが、1つの例で3つの操作（削除・挿入・置換）のうち2つしか使っていません。説明の便宜上1つの例で3つの操作を行いたかったため、sittingとkittenを変形して作ったのがbitingとwhitenです。

実在しない単語を使いたくなかったのですが、うまい組み合わせがすぐには思い浮かびませんでした。そのため正規表現で英単語を検索するサイトを利用しました。検索はサーバー側ではなく、圧縮した辞書データを読み込んだクライアント側が行っているようです。

* [英和辞書検索ページ作りました - ねとめもー](http://nmm.blog.jp/archives/51295142.html)

パブリックドメインの英和辞書データを利用しているそうです。

* [無料 英和辞書データ ダウンロード - ブラウザで使えるWeb便利ツール](https://kujirahand.com/web-tools/EJDictFreeDL.php)

# 関連記事

レーベンシュタイン距離を利用して機械翻訳の結果から言語系統や精度の確認を行います。

https://qiita.com/7shi/items/663c37408f880336fa9b

Google スプレッドシートでレーベンシュタイン距離を計算します。

https://7shi.hateblo.jp/entry/2023/09/23/144711

# 参考

様々な言語によるレーベンシュタイン距離の実装が載っています。

* [Algorithm Implementation/Strings/Levenshtein distance - Wikibooks](https://en.wikibooks.org/wiki/Algorithm_Implementation/Strings/Levenshtein_distance)
* [Levenshtein distance - Rosetta Code](https://rosettacode.org/wiki/Levenshtein_distance)
