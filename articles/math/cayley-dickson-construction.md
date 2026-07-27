---
coediting: false
comments_count: 0
created_at: '2017-01-04T03:42:07+09:00'
id: 88be5203769e629df243
likes_count: 2
private: false
reactions_count: 0
stocks_count: 3
tags:
- name: F#
  versions: []
- name: 数学
  versions: []
- name: 四元数
  versions: []
- name: 八元数
  versions: []
title: 多元数の積の構成
updated_at: '2017-12-26T14:41:51+09:00'
url: https://qiita.com/7shi/items/88be5203769e629df243
slide: false
---

多元数の積を構成する式についてプログラムで計算して検証します。四元数のルールから八元数のルールが決まることを確認します。

シリーズの記事です。

1. [多項式の積を計算](http://qiita.com/7shi/items/4fb60dacad46cb8e63b3)
1. [外積と愉快な仲間たち](http://qiita.com/7shi/items/017d2d2c758f76071f23)
1. [ユークリッド空間のホッジ双対とバブルソート](http://qiita.com/7shi/items/f54302058149d07da592)
1. [四元数を作ろう](http://qiita.com/7shi/items/2036e7a739c2a9e04025)
1. [四元数と行列で見る内積と外積の「内」と「外」](http://qiita.com/7shi/items/a80988a32a0d706e9378)
1. [八元数を作ろう](http://qiita.com/7shi/items/b34fe724d36fb7d96456)
1. [八元数の積をプログラムで確認](http://qiita.com/7shi/items/8495b2d6b888e7b8703f)
1. [外積の成分をプログラムで確認](http://qiita.com/7shi/items/02c758c03d2fd7038912)
1. 多元数の積の構成 ← この記事
1. [十六元数を作ろう](http://qiita.com/7shi/items/989d59d74a505a92c419)

プログラムは [CayleyDickson.fsx](https://bitbucket.org/7shi/math7/src/tip/CayleyDickson.fsx) から抜粋して引用します。[Math7.fsx](https://bitbucket.org/7shi/math7/src/tip/Math7.fsx) など個別の依存ファイルについてはリポジトリを参照してください。

* https://bitbucket.org/7shi/math7

# 概要

Wikipediaの[ケーリー＝ディクソンの構成法](https://ja.wikipedia.org/wiki/%E3%82%B1%E3%83%BC%E3%83%AA%E3%83%BC%EF%BC%9D%E3%83%87%E3%82%A3%E3%82%AF%E3%82%BD%E3%83%B3%E3%81%AE%E6%A7%8B%E6%88%90%E6%B3%95)には積の定義が掲載されています。

```math
(a,b)(c,d)=(ac-d^* b,da+bc^* )
```

この定義の由来などを確認します。

# 複素数の積

複素数の積を計算します。

```fsharp
let t a e = term(1, [a], e)
let qProdE = Quaternion.quatProdE -1

Quaternion.showProd Quaternion.compStr qProdE
    [t"a"[];t"b"[1]] [t"c"[];t"d"[1]]
```
```math
\begin{align}
&(a+bi)(c+di)=(ac-bd)+(ad+bc)i \\
\end{align}
```

## タプル表記

複素数をタプル（順序対）で表記する方法があります。

```math
(a,b):=a+bi
```

タプル表記で積を計算します。

```math
(a,b)(c,d)=(ac-bd,ad+bc)
```

# 双複素数の積

双複素数の積を計算します。

```fsharp
let show pfx h ts =
    printf "%s" pfx
    Term.simplify ts
    |> Term.sort id (fun t -> String.concat "" t.A)
    |> Term.showProd3Raw Quaternion.ijk h
let showEq = show "&=" (fun _ -> true)
let str = Seq.map Octonion.ijkh >> Term.strPower
let strs = Term.strs str
let dcompProds = Term.prods Quaternion.dcompProdE

printfn @"&(a+bj)(c+dj) \\"
let a = [t"a_0"[];t"a_1"[1]]
let b = [t"b_0"[];t"b_1"[1]]
let c = [t"c_0"[];t"c_1"[1]]
let d = [t"d_0"[];t"d_1"[1]]
printfn @"&=\{(%s)+(%s)j\}\{(%s)+(%s)j\} \\"
    (strs a) (strs b) (strs c) (strs d)
let j = Term.fromE [2]
let q1 = List.append a (dcompProds b [j])
let q2 = List.append c (dcompProds d [j])
printfn @"&=(%s)(%s) \\" (strs q1) (strs q2)
let q3dc = dcompProds q1 q2 in showEq q3dc
```
```math
\begin{align}
&(a+bj)(c+dj) \\
&=\{(a_0+a_1i)+(b_0+b_1i)j\}\{(c_0+c_1i)+(d_0+d_1i)j\} \\
&=(a_0+a_1i+b_0j+b_1k)(c_0+c_1i+d_0j+d_1k) \\
&=(a_0c_0-a_1c_1-b_0d_0+b_1d_1) \\
&\quad +(a_0c_1+a_1c_0-b_0d_1-b_1d_0)i \\
&\quad +(a_0d_0-a_1d_1+b_0c_0-b_1c_1)j \\
&\quad +(a_0d_1+a_1d_0+b_0c_1+b_1c_0)k \\
\end{align}
```

※ `str` は後で八元数まで使いまわします。

## 分類

複素数と違って積は項が多くて複雑ですが、係数に表れる組み合わせを分類します。

```fsharp
let classify:term list -> unit =
    Seq.groupBy (fun t ->
        t.A |> Seq.map (fun s -> s.[..0]) |> String.concat "")
    >> Seq.iter (fun (t, ts) ->
        show (t + "&:") (fun _ -> false) ts)

let q3dc = dcompProds q1 q2 in showEq true q3dc
```
```math
\begin{align}
ac&:(a_0c_0-a_1c_1)+(a_0c_1+a_1c_0)i \\
ad&:(a_0d_0-a_1d_1)j+(a_0d_1+a_1d_0)k \\
bc&:(b_0c_0-b_1c_1)j+(b_0c_1+b_1c_0)k \\
bd&:(-b_0d_0+b_1d_1)-(b_0d_1+b_1d_0)i \\
\end{align}
```

上の $ac$ は分類の指標ですが、積を計算して比較します。

```fsharp
dcompProds a c |> show "ac&=" (fun _ -> false)
dcompProds a d |> show "ad&=" (fun _ -> false)
dcompProds b c |> show "bc&=" (fun _ -> false)
dcompProds b d |> show "bd&=" (fun _ -> false)
```
```math
\begin{align}
ac&=(a_0c_0-a_1c_1)+(a_0c_1+a_1c_0)i \\
ad&=(a_0d_0-a_1d_1)+(a_0d_1+a_1d_0)i \\
bc&=(b_0c_0-b_1c_1)+(b_0c_1+b_1c_0)i \\
bd&=(b_0d_0-b_1d_1)+(b_0d_1+b_1d_0)i \\
\end{align}
```

比較から、タプル表記での積の規則は複素数と同じことが確認できました。

```math
(a,b)(c,d)=(ac-bd,ad+bc)
```

# 四元数

四元数の積を計算します。

```fsharp
let prods = Term.prods Octonion.prod

printfn @"&(a+bj)(c+dj) \\"
printfn @"&=\{(%s)+(%s)j\}\{(%s)+(%s)j\} \\"
    (strs a) (strs b) (strs c) (strs d)
printfn @"&=(%s)(%s) \\" (strs q1) (strs q2)
let q3q = prods q1 q2 in showEq true q3q
```
```math
\begin{align}
&(a+bj)(c+dj) \\
&=\{(a_0+a_1i)+(b_0+b_1i)j\}\{(c_0+c_1i)+(d_0+d_1i)j\} \\
&=(a_0+a_1i+b_0j+b_1k)(c_0+c_1i+d_0j+d_1k) \\
&=(a_0c_0-a_1c_1-b_0d_0-b_1d_1) \\
&\quad +(a_0c_1+a_1c_0+b_0d_1-b_1d_0)i \\
&\quad +(a_0d_0-a_1d_1+b_0c_0+b_1c_1)j \\
&\quad +(a_0d_1+a_1d_0-b_0c_1+b_1c_0)k \\
\end{align}
```

## 分類

積を係数別に分類します。

```fsharp
classify q3q
```
```math
\begin{align}
ac&:(a_0c_0-a_1c_1)+(a_0c_1+a_1c_0)i \\
ad&:(a_0d_0-a_1d_1)j+(a_0d_1+a_1d_0)k \\
bc&:(b_0c_0+b_1c_1)j+(-b_0c_1+b_1c_0)k \\
bd&:-(b_0d_0+b_1d_1)+(b_0d_1-b_1d_0)i \\
\end{align}
```

これを双複素数の積と比較すれば $ac,ad$ が一致します。

## 因数分解

一致しない $bc,bd$ を因数分解します。（未実装のため手作業）

```math
\begin{align}
bc&:\{(b_0+b_1i)(c_0-c_1i)\}j=bc^* j \\
bd&:-(b_0+b_1i)(d_0-d_1i)=-bd^* \\
\end{align}
```

## タプル表記

因数分解の結果からタプル表記は次のようになります。

```math
(a,b)(c,d)=(ac-bd^* ,ad+bc^* )
```

これはWikipediaの定義とは $bd^* ,ad$ の順番が異なります。

```math
(a,b)(c,d)=(ac-d^* b,da+bc^* )
```

四元数を構成する $a,b,c,d$ は複素数で可換なため、因子の順番は結果に影響しません。

## ノルムの2乗

Wikipediaでは因子の順番はノルムと関係があるとされているため確認します。

四元数の共役はタプル表記では次のようになります。

```math
\begin{align}
(a,b)^*
&=\{a_0+a_1i+(b_0+b_1i)j\}^* \\
&=a_0-a_1i-(b_0+b_1i)j \\
&=(a^* ,-b)
\end{align}
```

タプル表記で共役との積を計算します。

※ 最初に求めた $(a,b)(c,d)=(ac-bd^* ,ad+bc^* )$ を使います。

```math
\begin{align}
(a,b)^*(a,b)
&=(a^* ,-b)(a,b) \\
&=(a^* a-(-b)b^* ,a^* b+(-b)a^* ) \\
&=(a^* a+bb^* ,a^* b-ba^* )
\end{align}
```

これを変形してWikipediaの定義に合わせます。

$a^* a+bb^* $ の各項で共役を左側に揃えるため $bd^* $ の因子を交換します。

```math
\begin{align}
(a,b)(c,d)&=(ac-\underbrace{d^* b}_{交換},ad+bc^* ) \\
(a,b)^*(a,b)&=(a^* a+\underbrace{b^* b}_{交換},a^* b-ba^* )
\end{align}
```

$a^* b-ba^*$ はノルムの2乗では $0$ になります。因子の順番を揃えるために $ad$ の因子を交換します。

※ $bc^* $ を交換するのでも構わないような気がしますが、これが巡回性に関係することを八元数で確認します。

```math
\begin{align}
(a,b)(c,d)&=(ac-d^* b,\underbrace{da}_{交換}+bc^* ) \\
(a,b)^*(a,b)&=(a^* a+b^* b,\underbrace{ba^* }_{交換}-ba^* )
\end{align}
```

これでWikipediaと同じ定義が得られました。

## 確認

タプル表記に現れる共役によって、四元数の反交換性が実現されていることを確認します。

```fsharp
let tstr =
    Term.simplify
    >> Seq.mapi (fun i dl ->
        let s = Term.str3 str dl
        if i = 0 then s else Term.addSign s)
    >> String.concat ""
    >> function "" -> "0" | s -> s
let ijkstr z (re, im) =
    List.append re (prods im [z]) |> tstr
let tupleProd z ((a, b as x), (c, d as y)) =
    let sa, sb, sc, sd = strs a, strs b, strs c, strs d
    printf @"%s%s&=(%s,%s)(%s,%s)"
        (ijkstr z x) (ijkstr z y) sa sb sc sd
    printf @"=(%s%s-%s^* %s,%s%s+%s%s^* )"
        sa sc sd sb sd sa sb sc
    let re =
        List.append (prods a c)
            (prods [term -1] (prods (Quaternion.conj d) b))
    let im =
        List.append (prods d a) (prods b (Quaternion.conj c))
    let result = List.append re (prods im [z])
    printfn @"=(%s,%s)=%s \\" (tstr re) (tstr im) (tstr result)

let i, _0, _1 = Term.fromE [1], [term.Zero], [term.One]
let ijk = [[i], _0; _0, _1; _0, [i]]
for x in ijk do for y in ijk do tupleProd j (x, y)
```
```math
\begin{align}
ii&=(i,0)(i,0)=(ii-0^* 0,0i+0i^* )=(-1,0)=-1 \\
ij&=(i,0)(0,1)=(i0-1^* 0,1i+00^* )=(0,i)=k \\
ik&=(i,0)(0,i)=(i0-i^* 0,ii+00^* )=(0,-1)=-j \\
ji&=(0,1)(i,0)=(0i-0^* 1,00+1i^* )=(0,-i)=-k \\
jj&=(0,1)(0,1)=(00-1^* 1,10+10^* )=(-1,0)=-1 \\
jk&=(0,1)(0,i)=(00-i^* 1,i0+10^* )=(i,0)=i \\
ki&=(0,i)(i,0)=(0i-0^* i,00+ii^* )=(0,1)=j \\
kj&=(0,i)(0,1)=(00-1^* i,10+i0^* )=(-i,0)=-i \\
kk&=(0,i)(0,i)=(00-i^* i,i0+i0^* )=(-1,0)=-1 \\
\end{align}
```

この結果を見ると、共役が双複素数と四元数の違いを生み出していることが分かります。

* $d^* $ は $jk$ と $kk$ の後ろの $k$ に作用して符号反転<br>【双複素数】 $jk=-i,kk=1$<br>【四元数】 $jk=i,kk=-1$
* $c^* $ は $ji$ と $ki$ の後ろの $i$ に作用して符号反転<br>【双複素数】 $ji=k,ki=-j$<br>【四元数】 $ji=-k,ki=j$

四元数で $jk,ji,ki$ が符号反転することで $kj,ij,ik$ との反交換性を生み出しています。

# 八元数

四元数の積の構成をそのまま八元数に適用して、元同士の積を確認します。

```fsharp
let k, h = Term.fromE [3], Term.fromE [4]
let ijkh = [[i], _0; [j], _0; [k], _0; _0, _1
            _0, [i]; _0, [j]; _0, [k]]
let ocomb = [for x in ijkh do for y in ijkh -> x, y]
ocomb |> List.iter (tupleProd h)
```
```math
\begin{align}
ii&=(i,0)(i,0)=(ii-0^* 0,0i+0i^* )=(-1,0)=-1 \\
ij&=(i,0)(j,0)=(ij-0^* 0,0i+0j^* )=(k,0)=k \\
ik&=(i,0)(k,0)=(ik-0^* 0,0i+0k^* )=(-j,0)=-j \\
ih&=(i,0)(0,1)=(i0-1^* 0,1i+00^* )=(0,i)=i_h \\
ii_h&=(i,0)(0,i)=(i0-i^* 0,ii+00^* )=(0,-1)=-h \\
ij_h&=(i,0)(0,j)=(i0-j^* 0,ji+00^* )=(0,-k)=-k_h \\
ik_h&=(i,0)(0,k)=(i0-k^* 0,ki+00^* )=(0,j)=j_h \\
ji&=(j,0)(i,0)=(ji-0^* 0,0j+0i^* )=(-k,0)=-k \\
jj&=(j,0)(j,0)=(jj-0^* 0,0j+0j^* )=(-1,0)=-1 \\
jk&=(j,0)(k,0)=(jk-0^* 0,0j+0k^* )=(i,0)=i \\
jh&=(j,0)(0,1)=(j0-1^* 0,1j+00^* )=(0,j)=j_h \\
ji_h&=(j,0)(0,i)=(j0-i^* 0,ij+00^* )=(0,k)=k_h \\
jj_h&=(j,0)(0,j)=(j0-j^* 0,jj+00^* )=(0,-1)=-h \\
jk_h&=(j,0)(0,k)=(j0-k^* 0,kj+00^* )=(0,-i)=-i_h \\
ki&=(k,0)(i,0)=(ki-0^* 0,0k+0i^* )=(j,0)=j \\
kj&=(k,0)(j,0)=(kj-0^* 0,0k+0j^* )=(-i,0)=-i \\
kk&=(k,0)(k,0)=(kk-0^* 0,0k+0k^* )=(-1,0)=-1 \\
kh&=(k,0)(0,1)=(k0-1^* 0,1k+00^* )=(0,k)=k_h \\
ki_h&=(k,0)(0,i)=(k0-i^* 0,ik+00^* )=(0,-j)=-j_h \\
kj_h&=(k,0)(0,j)=(k0-j^* 0,jk+00^* )=(0,i)=i_h \\
kk_h&=(k,0)(0,k)=(k0-k^* 0,kk+00^* )=(0,-1)=-h \\
hi&=(0,1)(i,0)=(0i-0^* 1,00+1i^* )=(0,-i)=-i_h \\
hj&=(0,1)(j,0)=(0j-0^* 1,00+1j^* )=(0,-j)=-j_h \\
hk&=(0,1)(k,0)=(0k-0^* 1,00+1k^* )=(0,-k)=-k_h \\
hh&=(0,1)(0,1)=(00-1^* 1,10+10^* )=(-1,0)=-1 \\
hi_h&=(0,1)(0,i)=(00-i^* 1,i0+10^* )=(i,0)=i \\
hj_h&=(0,1)(0,j)=(00-j^* 1,j0+10^* )=(j,0)=j \\
hk_h&=(0,1)(0,k)=(00-k^* 1,k0+10^* )=(k,0)=k \\
i_hi&=(0,i)(i,0)=(0i-0^* i,00+ii^* )=(0,1)=h \\
i_hj&=(0,i)(j,0)=(0j-0^* i,00+ij^* )=(0,-k)=-k_h \\
i_hk&=(0,i)(k,0)=(0k-0^* i,00+ik^* )=(0,j)=j_h \\
i_hh&=(0,i)(0,1)=(00-1^* i,10+i0^* )=(-i,0)=-i \\
i_hi_h&=(0,i)(0,i)=(00-i^* i,i0+i0^* )=(-1,0)=-1 \\
i_hj_h&=(0,i)(0,j)=(00-j^* i,j0+i0^* )=(-k,0)=-k \\
i_hk_h&=(0,i)(0,k)=(00-k^* i,k0+i0^* )=(j,0)=j \\
j_hi&=(0,j)(i,0)=(0i-0^* j,00+ji^* )=(0,k)=k_h \\
j_hj&=(0,j)(j,0)=(0j-0^* j,00+jj^* )=(0,1)=h \\
j_hk&=(0,j)(k,0)=(0k-0^* j,00+jk^* )=(0,-i)=-i_h \\
j_hh&=(0,j)(0,1)=(00-1^* j,10+j0^* )=(-j,0)=-j \\
j_hi_h&=(0,j)(0,i)=(00-i^* j,i0+j0^* )=(k,0)=k \\
j_hj_h&=(0,j)(0,j)=(00-j^* j,j0+j0^* )=(-1,0)=-1 \\
j_hk_h&=(0,j)(0,k)=(00-k^* j,k0+j0^* )=(-i,0)=-i \\
k_hi&=(0,k)(i,0)=(0i-0^* k,00+ki^* )=(0,-j)=-j_h \\
k_hj&=(0,k)(j,0)=(0j-0^* k,00+kj^* )=(0,i)=i_h \\
k_hk&=(0,k)(k,0)=(0k-0^* k,00+kk^* )=(0,1)=h \\
k_hh&=(0,k)(0,1)=(00-1^* k,10+k0^* )=(-k,0)=-k \\
k_hi_h&=(0,k)(0,i)=(00-i^* k,i0+k0^* )=(-j,0)=-j \\
k_hj_h&=(0,k)(0,j)=(00-j^* k,j0+k0^* )=(i,0)=i \\
k_hk_h&=(0,k)(0,k)=(00-k^* k,k0+k0^* )=(-1,0)=-1 \\
\end{align}
```

八元数の乗積表と一致しました。

## 確認

積の定義が影響する組み合わせを確認します。チェック用の関数を定義します。

```fsharp
let check f =
    let g: term list * term list -> bool = function
    | [x], [y] ->
        match x.E, y.E with
        | [a], [b] -> a > 0 && b > 0 && a <> b
        | _ -> false
    | _ -> false
    ocomb |> List.filter (f >> g) |> List.iter (tupleProd h)
```

$d^* b$ が影響しているのは次の組み合わせです。

```fsharp
check <| fun ((_, b), (_, d)) -> b, d
```
```math
\begin{align}
i_hj_h&=(0,i)(0,j)=(00-j^* i,j0+i0^* )=(-k,0)=-k \\
i_hk_h&=(0,i)(0,k)=(00-k^* i,k0+i0^* )=(j,0)=j \\
j_hi_h&=(0,j)(0,i)=(00-i^* j,i0+j0^* )=(k,0)=k \\
j_hk_h&=(0,j)(0,k)=(00-k^* j,k0+j0^* )=(-i,0)=-i \\
k_hi_h&=(0,k)(0,i)=(00-i^* k,i0+k0^* )=(-j,0)=-j \\
k_hj_h&=(0,k)(0,j)=(00-j^* k,j0+k0^* )=(i,0)=i \\
\end{align}
```

$da$ が影響しているのは次の組み合わせです。

```fsharp
check <| fun ((a, _), (_, d)) -> a, d
```
```math
\begin{align}
ij_h&=(i,0)(0,j)=(i0-j^* 0,ji+00^* )=(0,-k)=-k_h \\
ik_h&=(i,0)(0,k)=(i0-k^* 0,ki+00^* )=(0,j)=j_h \\
ji_h&=(j,0)(0,i)=(j0-i^* 0,ij+00^* )=(0,k)=k_h \\
jk_h&=(j,0)(0,k)=(j0-k^* 0,kj+00^* )=(0,-i)=-i_h \\
ki_h&=(k,0)(0,i)=(k0-i^* 0,ik+00^* )=(0,-j)=-j_h \\
kj_h&=(k,0)(0,j)=(k0-j^* 0,jk+00^* )=(0,i)=i_h \\
\end{align}
```

$bc^* $ が影響しているのは次の組み合わせです。

```fsharp
check <| fun ((_, b), (c, _)) -> b, c
```
```math
\begin{align}
i_hj&=(0,i)(j,0)=(0j-0^* i,00+ij^* )=(0,-k)=-k_h \\
i_hk&=(0,i)(k,0)=(0k-0^* i,00+ik^* )=(0,j)=j_h \\
j_hi&=(0,j)(i,0)=(0i-0^* j,00+ji^* )=(0,k)=k_h \\
j_hk&=(0,j)(k,0)=(0k-0^* j,00+jk^* )=(0,-i)=-i_h \\
k_hi&=(0,k)(i,0)=(0i-0^* k,00+ki^* )=(0,-j)=-j_h \\
k_hj&=(0,k)(j,0)=(0j-0^* k,00+kj^* )=(0,i)=i_h \\
\end{align}
```

これら3つの組み合わせは巡回性で結び付いています。例を抜粋します。

```math
\begin{align}
i_hj_h&=(0,i)(0,j)=(00-j^* i,j0+i0^* )=(-k,0)=-k \\
j_hk&=(0,j)(k,0)=(0k-0^* j,00+jk^* )=(0,-i)=-i_h \\
ki_h&=(k,0)(0,i)=(k0-i^* 0,ik+00^* )=(0,-j)=-j_h \\
\end{align}
```

これにより $d^* b$ の因子の順番を決めれば、自動的に $da$ と $bc^* $ も決まることが分かります。

## 亜種

次の定義でも巡回性は壊れず、ノルムの虚部もゼロになります。

```math
(a,b)(c,d)=(ac-bd^* ,ad+c^* b)
```

結合性も回復するので一見良さそうですが、零因子が現れてしまうという致命的な問題があります。詳細は以下のツイートを参照してください。

<blockquote class="twitter-tweet" data-lang="ja"><p lang="ja" dir="ltr">八元数を生成する Cayley–Dickson 構成の生成式は次のようになっている。<br>(p, q)(r, s) = (pr - s*q, sp + qr*)<br><br>これに従うと一部結合則を満たさない。<br>j(kℓ)≠(jk)ℓ<br><br>Wikipediaにはqr*をr*qにするとノルムが得られなくなることが言及されている。<a href="https://t.co/yBxO4hlIJH">https://t.co/yBxO4hlIJH</a></p>&mdash; 七誌 (@7shi) <a href="https://twitter.com/7shi/status/945522243248930816?ref_src=twsrc%5Etfw">2017年12月26日</a></blockquote>

# 感想

四元数の積の演算規則を決めてしまえば、自動的に八元数の演算規則も決まることが分かりました。しかしあまり分かりやすい導出ではないため、八元数の演算規則を覚えるために使うのは難しい気がしました。
