---
coediting: false
comments_count: 0
created_at: '2014-08-31T11:44:25+09:00'
id: 026839b2bc193dbfb0cb
likes_count: 61
private: false
reactions_count: 0
stocks_count: 60
tags:
- name: Haskell
  versions: []
- name: Intel8086
  versions: []
title: Haskellによる8086逆アセンブラ開発入門
updated_at: '2015-11-09T17:32:51+09:00'
url: https://qiita.com/7shi/items/026839b2bc193dbfb0cb
slide: false
---

8086(16bit x86)の機械語に触れる導入として、Haskellによる逆アセンブラ開発の取っ掛かりを説明します。ここから機械語の勉強を始めることを想定していますので、機械語に関する知識は特に前提とはしていません。

Haskellは初歩的な機能のみ使います。以下の内容を理解していれば十分です。

* [Haskell 超入門](http://qiita.com/7shi/items/145f1234f8ec2af923ef)
* [HUnit 超入門](http://qiita.com/7shi/items/9fb326a87de6c3083784)

練習の解答例は別記事に掲載します。

* [【解答例】Haskellによる8086逆アセンブラ開発入門](http://qiita.com/7shi/items/6d228b6fc4734f48a33e)

この記事のコードをまとめたリポジトリです。

* https://bitbucket.org/7shi/ikebin-hs-2

この記事は勉強会のテキストとして使用していました。

* [機械語入門 - connpass](http://connpass.com/series/593/)

この記事には姉妹編があります。

* [8086による機械語入門](http://qiita.com/7shi/items/b3911948f9d97b05395e) 2015.11.09

# 2進数

文字列で指定した2進数を数値に変換する関数です。HUnitのテストも書きます。

※ 使用例をメモする目的で、使用している関数のテストも書いています。

```hs:Main.hs
import Test.HUnit
import System.IO

binToInt '0' = 0
binToInt '1' = 1

binStrToInt bin = f (reverse bin)
    where
        f ""     = 0
        f (x:xs) = (binToInt x) + 2 * (f xs)

tests = TestList
    [ "reverse"       ~: reverse     "11001" ~?= "10011"
    , "binStrToInt 1" ~: binStrToInt "101"   ~?= 5
    , "binStrToInt 2" ~: binStrToInt "11001" ~?= 25
    ]

main = do
    runTestText (putTextToHandle stderr False) tests
```
```text:実行結果
Cases: 3  Tried: 3  Errors: 0  Failures: 0
```

以降はこのコードに付け足しながら進みます。

⇒ [リビジョン 0](https://bitbucket.org/7shi/ikebin-hs-2/commits/96bcd8d5477bfe24dae02d12600985cad23b065d)

## 練習

【問1】数値を2進数の文字列に変換する関数`bin`をテストファーストで作成してください。

⇒ [解答例](http://qiita.com/7shi/items/6d228b6fc4734f48a33e#2%E9%80%B2%E6%95%B0)

# 16進数

## 練習

【問2】16進数の文字列を数値に変換する関数`hexStrToInt`をテストファーストで作成してください。

ヒント: `Data.Char.digitToInt`（[リファレンス](https://hackage.haskell.org/package/base-4.7.0.0/docs/Data-Char.html)）

【問3】数値を16進数の文字列に変換する関数`hex`をテストファーストで作成してください。

⇒ [解答例](http://qiita.com/7shi/items/6d228b6fc4734f48a33e#16%E9%80%B2%E6%95%B0)

# 桁揃え

16進数の頭に0を付加して桁を揃えます。指定した桁から溢れる場合は切り揃えます。

テストファーストを意識して進めます。テストコードの追加分と実装を分けて掲載します。

```hs:テスト
    , "replicate" ~: replicate 5 'a' ~?= "aaaaa"
    , "hexn 1" ~: hexn 2 1     ~?= "01"
    , "hexn 2" ~: hexn 2 255   ~?= "ff"
    , "hexn 3" ~: hexn 8 65535 ~?= "0000ffff"
    , "hexn 4" ~: hexn 2 256   ~?= "00"
```
```hs
hexn n x
    | r < 0     = drop (-r) x'
    | otherwise = replicate r '0' ++ x'
    where
        x' = hex x
        r  = n - length x'
```

`replicate`はリストを指定した回数だけ繰り返します。

⇒ [リビジョン 4](https://bitbucket.org/7shi/ikebin-hs-2/commits/15571e57a0158852440720c5d5176b5114e632eb)

# メモリをリストで表現

メモリをシミュレートするためバイト区切りのリストを作成します。

## 16進数文字列→リスト

```hs:テスト
    , "hexStrToList 1" ~: hexStrToList "123456" ~?= [0x12, 0x34, 0x56]
    , "hexStrToList 2" ~: hexStrToList "010203" ~?= [1, 2, 3]
```
```hs
hexStrToList ""       = []
hexStrToList (h:l:xs) = hexStrToInt [h, l] : hexStrToList xs
```

⇒ [リビジョン 5](https://bitbucket.org/7shi/ikebin-hs-2/commits/c16febe858a5e0959b79b2d8bc1fddc9920304ab)

## リスト→16進数文字列

```hs:テスト
    , "listToHexStr 1" ~: listToHexStr [0x12, 0x34, 0x56] ~?= "123456"
    , "listToHexStr 2" ~: listToHexStr [1, 2, 3]          ~?= "010203"
```
```hs
listToHexStr []     = ""
listToHexStr (x:xs) = hexn 2 x ++ listToHexStr xs
```

⇒ [リビジョン 6](https://bitbucket.org/7shi/ikebin-hs-2/commits/8a216e610a94e966c8e7093407c57689a58028ea)

# バイトオーダー

メモリはバイトごとに区切られています。1バイトに収まりきらない数値は分割して格納します。

バイトごと区切って並べる方法にいくつか種類があります。これを**バイトオーダー**と呼びます。

分割した際に逆順に並べ替える方式を**リトルエンディアン**と呼びます。並べ替えない方式は**ビッグエンディアン**です。

* リトルエンディアン: `0x12345678` → `[0x78, 0x56, 0x34, 0x12]`
* ビッグエンディアン: `0x12345678` → `[0x12, 0x34, 0x56, 0x78]`

【注意】バイトオーダーを考えるのは分割後です。分割前のバイトオーダーは考えません。

人間の目にはビッグエンディアンの方が直感的ですが、現在主流なのはリトルエンディアンです。今回対象とする8086はリトルエンディアンのみを使います。

## 数値→リトルエンディアン

バイト数を指定してリトルエンディアンを作成します。

```hs:テスト
    , "toLE 1" ~: toLE 2 1          ~?= [1, 0]
    , "toLE 2" ~: toLE 2 0x10000    ~?= [0, 0]
    , "toLE 3" ~: toLE 4 0x12345678 ~?= [0x78, 0x56, 0x34, 0x12]
```
```hs
toLE 0 _ = []
toLE n x = x `mod` 0x100 : toLE (n - 1) (x `div` 0x100)
```

⇒ [リビジョン 7](https://bitbucket.org/7shi/ikebin-hs-2/commits/0a47b791f0c0216b4c3b3c1c61ec7a81854eab73)

## リトルエンディアン→数値

バイト数を指定して数値を読み取ります。

```hs:テスト
    , "fromLE 1" ~: fromLE 2 [0, 1]                   ~?= 0x100
    , "fromLE 2" ~: fromLE 2 [0x78, 0x56, 0x34, 0x12] ~?= 0x5678
    , "fromLE 3" ~: fromLE 4 [0x78, 0x56, 0x34, 0x12] ~?= 0x12345678
```
```hs
fromLE 0 _      = 0
fromLE n (x:xs) = x + 0x100 * fromLE (n - 1) xs
```

以上で逆アセンブラ開発の準備は完了です。

⇒ [リビジョン 8](https://bitbucket.org/7shi/ikebin-hs-2/commits/70d01b4f885becd70833571a180cfc0126215cf9)

## 練習

【問4】数値⇔ビッグエンディアンの相互変換を実装してください。

ヒント: べき乗（累乗）の演算子は`^`です。例: `2^3`（2の3乗）

⇒ [解答例](http://qiita.com/7shi/items/6d228b6fc4734f48a33e#%E3%83%93%E3%83%83%E3%82%B0%E3%82%A8%E3%83%B3%E3%83%87%E3%82%A3%E3%82%A2%E3%83%B3)

# ビット演算

2進数を対象にしたビット演算という操作があります。

Haskellでは関数名が長くてやや煩雑なため、導入はPythonで行います。簡単な式しか扱わないため、Pythonの知識は前提としません。

* [Python ビット演算 超入門](http://qiita.com/7shi/items/41d262ca11ea16d85abc)

HaskellではPythonとは演算子が異なるため、対応を示します。

※ `import Data.Bits`が必要です。

<table><tr><th>操作</th><th>Python</th><th>Haskell</th></tr><tr><td>左シフト</td><td><code>&lt;&lt;</code></td><td><code>shiftL</code></td></tr><tr><td>右シフト</td><td><code>&gt;&gt;</code></td><td><code>shiftR</code></td></tr><tr><td>論理積</td><td><code>&</code></td><td><code>.&.</code></td></tr><tr><td>論理和</td><td><code>|</code></td><td><code>.|.</code></td></tr><tr><td>排他的論理和</td><td><code>^</code></td><td><code>xor</code></td></tr><tr><td>反転</td><td><code>~</code></td><td><code>complement</code></td></tr></table>

※ Pythonの演算子はC言語やJavaとも共通です。

## 練習

【問5】今まで実装した関数をビット演算で書き換えてください。

⇒ [解答例](http://qiita.com/7shi/items/6d228b6fc4734f48a33e#%E3%83%93%E3%83%83%E3%83%88%E6%BC%94%E7%AE%97)

# 逆アセンブラ

いよいよ逆アセンブラ作りに入ります。

テストが長くなったので、今までのテストは分離します。

```hs:テストを分離
testHex = TestList
    [ "reverse"       ~: reverse     "11001" ~?= "10011"
    （略）
    ]
```

[データシート](https://bitbucket.org/7shi/ikebin/wiki/8086/spec)を参照しながら進めます。

## mov ax, imm16

簡単な命令をndisasmで逆アセンブルします。

```text:逆アセンブル結果
B83412            mov ax,0x1234
```

`B83412`を機械語、`mov`をニーモニック、`ax`や`0x1234`をオペランドと呼びます。

機械語をリストで渡して逆アセンブルします。

```hs:実装とテスト
disasm (x:xs)
    | x == 0xb8 =
        "mov ax,0x" ++ hex (fromLE 2 xs)

testDisAsm = TestList
    [ "b8 1" ~: disasm [0xb8, 0, 0]       ~?= "mov ax,0x0"
    , "b8 2" ~: disasm [0xb8, 0x34, 0x12] ~?= "mov ax,0x1234"
    ]

main = do
    runTestText (putTextToHandle stderr False)
        (TestList [testHex, testDisAsm])
```

⇒ [リビジョン 10](https://bitbucket.org/7shi/ikebin-hs-2/commits/3c05a3626bb6eff3ae33afd7768ad769c68b4d05)

## 文字列渡し

バイナリを16進数文字列で渡せるようにします。

```hs:テスト
    , "b8 3" ~: disasm' "b80000" ~?= "mov ax,0x0"
    , "b8 4" ~: disasm' "b83412" ~?= "mov ax,0x1234"
```
```hs
disasm' hex = disasm $ hexStrToList hex
```

⇒ [リビジョン 11](https://bitbucket.org/7shi/ikebin-hs-2/commits/3a5edcd3bb6e7e29b490cd4f965d252c82985004)

## mov r16, imm16

レジスタ番号で処理するように拡張します。

```hs:テスト
    , "b8-bf 0" ~: disasm' "b90100" ~?= "mov cx,0x1"
    , "b8-bf 1" ~: disasm' "ba1000" ~?= "mov dx,0x10"
    , "b8-bf 2" ~: disasm' "bb0001" ~?= "mov bx,0x100"
    , "b8-bf 3" ~: disasm' "bc0010" ~?= "mov sp,0x1000"
    , "b8-bf 4" ~: disasm' "bdff00" ~?= "mov bp,0xff"
    , "b8-bf 5" ~: disasm' "be00ff" ~?= "mov si,0xff00"
    , "b8-bf 6" ~: disasm' "bffeca" ~?= "mov di,0xcafe"
```
```hs
reg16 = ["ax", "cx", "dx", "bx", "sp", "bp", "si", "di"]

disasm (x:xs)
    | 0xb8 <= x && x <= 0xbf =
        "mov " ++ reg16 !! (x - 0xb8) ++ ",0x" ++ hex (fromLE 2 xs)
```

⇒ [リビジョン 12](https://bitbucket.org/7shi/ikebin-hs-2/commits/128458300876d265dee082a1bbdf7d041f230a23)

## mov r8, imm8

8bitレジスタにも対応します。

```hs:テスト
    , "b0-b7 1" ~: disasm' "b000" ~?= "mov al,0x0"
    , "b0-b7 2" ~: disasm' "b101" ~?= "mov cl,0x1"
    , "b0-b7 3" ~: disasm' "b210" ~?= "mov dl,0x10"
    , "b0-b7 4" ~: disasm' "b311" ~?= "mov bl,0x11"
    , "b0-b7 5" ~: disasm' "b412" ~?= "mov ah,0x12"
    , "b0-b7 6" ~: disasm' "b5ff" ~?= "mov ch,0xff"
    , "b0-b7 7" ~: disasm' "b6ee" ~?= "mov dh,0xee"
    , "b0-b7 8" ~: disasm' "b7ca" ~?= "mov bh,0xca"
```
```hs
reg8  = ["al", "cl", "dl", "bl", "ah", "ch", "dh", "bh"]

disasm (x:xs)
    | 0xb0 <= x && x <= 0xb7 =
        "mov " ++ reg8  !! (x - 0xb0) ++ ",0x" ++ hex (xs !! 0)
```

⇒ [リビジョン 13](https://bitbucket.org/7shi/ikebin-hs-2/commits/25004806f3318eaa8b113cfbb7fd3f8ddd34147c)

## 8bitと16bitの統合

wフラグを見て切り替えます。

```hs
regs  = [reg8, reg16]

disasm (x:xs)
    -- DATA TRANSFER
    -- MOV = Move:
    -- Immediate to Register [1011wreg][data][data if w=1]
    | 0xb0 <= x && x <= 0xbf =
        "mov " ++ reg ++ "," ++ imm
        where
            w = (x `shiftR` 3) .&. 1
            reg = regs !! w !! (x .&. 7)
            imm = "0x" ++ hex (fromLE (w + 1) xs)
```

⇒ [リビジョン 14](https://bitbucket.org/7shi/ikebin-hs-2/commits/6eb9fc1e91d364c07a729eeb27c99262ce6f799b)

## ビットパターン

データシートには機械語が2進数で表記されていますが、ここまでの実装では16進数に変換して範囲チェックしていました。2進数のままパターンマッチできるように修正します。

### ビット分解

1バイトを8ビットに分解する関数を実装します。

```hs:テスト
    , "getBits" ~: getBits 0xbd ~?= (1,0,1,1,1,1,0,1)
```
```hs
getBits x = (b 7, b 6, b 5, b 4, b 3, b 2, b 1, b 0)
    where
        b n = (x `shiftR` n) .&. 1
```

このままではエラーになります。

```text:エラー内容
No instance for (Bits t0) arising from a use of `getBits'
The type variable `t0' is ambiguous
Possible fix: add a type signature that fixes these type variable(s)
Note: there are several potential instances:
  instance Bits Int -- Defined in `Data.Bits'
  instance Bits Integer -- Defined in `Data.Bits'
  instance Bits ghc-prim:GHC.Types.Word -- Defined in `Data.Bits'
（略）
```

テストで指定した`0xbd`が`Int`, `Integer`, `ghc-prim:GHC.Types.Word`のどの型か曖昧だというエラーメッセージです。このような場合、関数に型注釈を追加します。

```hs:文法
名前 :: 引数の型 -> 戻り値の型
```
```hs:型注釈
getBits :: Int -> (Int,Int,Int,Int,Int,Int,Int,Int)
```

これでテストが通ります。

※ 今までは型推論に任せて型注釈は省略していましたが、型注釈を付けるのが一般的です。

⇒ [リビジョン 15](https://bitbucket.org/7shi/ikebin-hs-2/commits/edd293fceffc3ac2eb3a72c4add8fff3582b5f34)

### レジスタを再構成

レジスタは3ビットで表されますが、`getBits`によってビットごとにばらばらになってしまうため、再構成する関数を実装します。

```hs:テスト
    , "getReg" ~: getReg 1 0 1 ~?= 5
```
```hs
getReg :: Int -> Int -> Int -> Int
getReg r e g =
    (r `shiftL` 2) .|. (e `shiftL` 1) .|. g
```

これもエラー回避のため型注釈が必要です。

引数が複数ある場合は、このように引数を1つずつ`->`で区切って書きます。最後が戻り値の型です。

```hs:文法
名前 :: 引数の型 -> 引数の型 -> 引数の型 -> 戻り値の型
```

※ このような表記になるのはカリー化が関係していますが、詳細は省略します。

⇒ [リビジョン 16](https://bitbucket.org/7shi/ikebin-hs-2/commits/4704a40d14012be20e6f8df33d56cfe88d6fc72d)

### ビットでパターンマッチ

`disasm`でビット分解してパターンマッチ用に`disasmB`を追加します。

```hs
disasm (x:xs) = disasmB (getBits x) xs

-- DATA TRANSFER
-- MOV = Move:
-- Immediate to Register [1011wreg][data][data if w=1]
disasmB (1,0,1,1,w,r,e,g) xs =
    "mov " ++ reg ++ "," ++ imm
    where
        reg = regs !! w !! getReg r e g
        imm = "0x" ++ hex (fromLE (w + 1) xs)
```

データシートに近い表記で実装することを意図しています。

⇒ [リビジョン 17](https://bitbucket.org/7shi/ikebin-hs-2/commits/e395d8ae25cab1e16df392adc9996f945f203252)

## mov（続き）

movを進めていきます。

```text:データシートより
Register/Memory to/from Register [100010dw][mod reg r/m]
```

このパターンに合わせてデータを作ります。最初の1バイトを列挙します。

* `10001000 00000000` → `88 00`
* `10001001 00000000` → `89 00`
* `10001010 00000000` → `8A 00`
* `10001011 00000000` → `8B 00`

バイナリエディタで16進数を打ち込みます。この作業を**ハンドアセンブル**と呼びます。

機械語をアセンブリ言語に変換する処理を**逆アセンブル**と呼びます。

* アセンブル: アセンブリ言語 → 機械語
* 逆アセンブル: 機械語 → アセンブリ言語

ndisasmで逆アセンブルします。

```text:逆アセンブル結果
00000000  8800              mov [bx+si],al
00000002  8900              mov [bx+si],ax
00000004  8A00              mov al,[bx+si]
00000006  8B00              mov ax,[bx+si]
```

`d`がオペランドの順番、`w`がレジスタサイズを表します。modとr/mで1つのオペランドを表します。（以後ModR/M）

```hs:テスト
    , "88-8b mod=00,r/m=000 1" ~: disasm' "8800" ~?= "mov [bx+si],al"
    , "88-8b mod=00,r/m=000 2" ~: disasm' "8900" ~?= "mov [bx+si],ax"
    , "88-8b mod=00,r/m=000 3" ~: disasm' "8A00" ~?= "mov al,[bx+si]"
    , "88-8b mod=00,r/m=000 4" ~: disasm' "8B00" ~?= "mov ax,[bx+si]"
```

ModR/Mを処理する関数を実装してオペランドとregをタプルで返します。まず`[bx+si]`のみを実装します。

```hs
modrm (x:_) = (f mode rm, reg)
    where
        mode =  x `shiftR` 6
        reg  = (x `shiftR` 3) .&. 7
        rm   =  x             .&. 7
        f 0 0 = "[bx+si]"
```

これを使って逆アセンブラを実装します。

```hs
-- Register/Memory to/from Register [100010dw][mod reg r/m]
disasmB (1,0,0,0,1,0,d,w) xs
    | d == 0    = "mov " ++ rm  ++ "," ++ reg
    | otherwise = "mov " ++ reg ++ "," ++ rm
    where
        (rm, r) = modrm xs
        reg = regs !! w !! r
```

⇒ [リビジョン 18](https://bitbucket.org/7shi/ikebin-hs-2/commits/32c4f32acc3686b01e6c6f646989a6dcc97c72e5)

## r/m

r/mを増やして変化を確認します。

```text:逆アセンブル結果
00000000  8901              mov [bx+di],ax
00000002  8902              mov [bp+si],ax
00000004  8903              mov [bp+di],ax
00000006  8904              mov [si],ax
00000008  8905              mov [di],ax
0000000A  89068907          mov [0x789],ax
```

`8906`と`8907`がくっ付いています。

## 即値によるアドレス指定

`8906`は mod = 00, r/m = 110 です。そのパターンを調べます。

```text:逆アセンブル結果
00000000  88063412          mov [0x1234],al
00000004  89063412          mov [0x1234],ax
00000008  8A063412          mov al,[0x1234]
0000000C  8B063412          mov ax,[0x1234]
```

`modrm`を拡張します。

```hs:テスト
    , "88-8b mod=00,r/m=110 1" ~: disasm' "88063412" ~?= "mov [0x1234],al"
    , "88-8b mod=00,r/m=110 2" ~: disasm' "89063412" ~?= "mov [0x1234],ax"
    , "88-8b mod=00,r/m=110 3" ~: disasm' "8A063412" ~?= "mov al,[0x1234]"
    , "88-8b mod=00,r/m=110 4" ~: disasm' "8B063412" ~?= "mov ax,[0x1234]"
```
```hs
modrm (x:xs) = (f mode rm, reg)
    where
        mode =  x `shiftR` 6
        reg  = (x `shiftR` 3) .&. 7
        rm   =  x             .&. 7
        f 0 0 = "[bx+si]"
        f 0 6 = "[0x" ++ hex (fromLE 2 xs) ++ "]"
```

⇒ [リビジョン 19](https://bitbucket.org/7shi/ikebin-hs-2/commits/fcca40e56e06a7bd35498739a0de9a90cefff3fe)

## レジスタによるアドレス指定

すべての組み合わせに対応させるため、仕様書からアドレス指定の組み合わせを調べて、アセンブリ言語でテストを書きます。

```text:test.s
mov [bx+si],ax
mov [bx+di],cx
mov [bp+si],dx
mov [bp+di],bx
mov [si],sp
mov [di],bp
mov [bp],si
mov [bx],di
```

nasmでアセンブルしたものをndisasmで逆アセンブルします。

```text:逆アセンブル結果
00000000  8900              mov [bx+si],ax
00000002  8909              mov [bx+di],cx
00000004  8912              mov [bp+si],dx
00000006  891B              mov [bp+di],bx
00000008  8924              mov [si],sp
0000000A  892D              mov [di],bp
0000000C  897600            mov [bp+0x0],si
0000000F  893F              mov [bx],di
```

`[bp]`は機械語のパターンが異なるため除外します。（アドレス指定に割り当てられているため）

アドレスの組み合わせを定義して`modrm`を拡張します。

```hs:テスト
    , "88-8b mod=00 1" ~: disasm' "8900" ~?= "mov [bx+si],ax"
    , "88-8b mod=00 2" ~: disasm' "8909" ~?= "mov [bx+di],cx"
    , "88-8b mod=00 3" ~: disasm' "8912" ~?= "mov [bp+si],dx"
    , "88-8b mod=00 4" ~: disasm' "891b" ~?= "mov [bp+di],bx"
    , "88-8b mod=00 5" ~: disasm' "8924" ~?= "mov [si],sp"
    , "88-8b mod=00 6" ~: disasm' "892d" ~?= "mov [di],bp"
    , "88-8b mod=00 7" ~: disasm' "893f" ~?= "mov [bx],di"
```
```hs
regad = ["bx+si", "bx+di", "bp+si", "bp+di", "si", "di", "bp", "bx"]

modrm (x:xs) = (f mode rm, reg)
    where
        mode =  x `shiftR` 6
        reg  = (x `shiftR` 3) .&. 7
        rm   =  x             .&. 7
        f 0 6  = "[0x" ++ hex (fromLE 2 xs) ++ "]"
        f 0 rm = "[" ++ regad !! rm ++ "]"
```

⇒ [リビジョン 20](https://bitbucket.org/7shi/ikebin-hs-2/commits/32833f18954ea2e4d975627b0284069aefbf1b9c)

## ディスプレースメント

アドレスに対する差分をディスプレースメントと呼びます。`[bp]`は`[bp+0]`で表現します。

```text:逆アセンブル結果
00000000  894001            mov [bx+si+0x1],ax
00000003  8949FF            mov [bx+di-0x1],cx
00000006  895202            mov [bp+si+0x2],dx
00000009  895BFE            mov [bp+di-0x2],bx
0000000C  896464            mov [si+0x64],sp
0000000F  896D9C            mov [di-0x64],bp
00000012  897600            mov [bp+0x0],si
00000015  897601            mov [bp+0x1],si
00000018  897F01            mov [bx+0x1],di
```

ディスプレースメントは符号付きです。符号の考え方は次の記事を参照してください。

* [符号あり数値の直感的な考え方](http://qiita.com/7shi/items/6887e7939c0168a0eb21)

符号付きで文字列化する関数を用意します。

```hs:テスト
    , "disp8 1" ~: disp8 0    ~?= "+0x0"
    , "disp8 2" ~: disp8 0x7f ~?= "+0x7f"
    , "disp8 3" ~: disp8 0x80 ~?= "-0x80"
    , "disp8 4" ~: disp8 0xff ~?= "-0x1"
```
```hs
disp8 x
    | x < 0x80  = "+0x" ++ hex x
    | otherwise = "-0x" ++ hex (0x100 - x)
```

⇒ [リビジョン 21](https://bitbucket.org/7shi/ikebin-hs-2/commits/42f5510f9632448d256d7b7b2d38e71458c3735a)

`modrm`を拡張します。

```hs:テスト
    , "88-8b mod=01 1" ~: disasm' "894001" ~?= "mov [bx+si+0x1],ax"
    , "88-8b mod=01 2" ~: disasm' "8949FF" ~?= "mov [bx+di-0x1],cx"
    , "88-8b mod=01 3" ~: disasm' "895202" ~?= "mov [bp+si+0x2],dx"
    , "88-8b mod=01 4" ~: disasm' "895BFE" ~?= "mov [bp+di-0x2],bx"
    , "88-8b mod=01 5" ~: disasm' "896464" ~?= "mov [si+0x64],sp"
    , "88-8b mod=01 6" ~: disasm' "896D9C" ~?= "mov [di-0x64],bp"
    , "88-8b mod=01 7" ~: disasm' "897600" ~?= "mov [bp+0x0],si"
    , "88-8b mod=01 8" ~: disasm' "897601" ~?= "mov [bp+0x1],si"
    , "88-8b mod=01 9" ~: disasm' "897F01" ~?= "mov [bx+0x1],di"
```
```hs
modrm (x:xs) = (f mode rm, reg)
    where
        mode =  x `shiftR` 6
        reg  = (x `shiftR` 3) .&. 7
        rm   =  x             .&. 7
        f 0 6  = "[0x" ++ hex (fromLE 2 xs) ++ "]"
        f 0 rm = "[" ++ regad !! rm ++ "]"
        f 1 rm = "[" ++ regad !! rm ++ disp ++ "]"
            where
                disp = disp8 (xs !! 0)
```

⇒ [リビジョン 22](https://bitbucket.org/7shi/ikebin-hs-2/commits/8584a735790030fc0e0bf809e9742db5587f8643)

# ファイルの分割

1ファイルが長くなって来たので分割します。

Leksahでの設定方法を説明します。Leksahについては以下を参照してください。

* [Haskell IDE Leksah 入門](http://qiita.com/7shi/items/d1e5a0c22be6cf61d286)

まずMain.hsの先頭にモジュール宣言を書いておきます。1ファイルだけのときは不要でしたが、ファイルを分割するときには必要となります。モジュール名はファイル名の拡張子を除いた部分と同じにします。

```hs:Main.hsの先頭
module Main where
```

## Hex

* File → New Module
    * Hex と入力 → [OK]

新規作成されたファイルの中身をすべて消します。

※ 中身を理解しないまま流用することによる問題を回避するための措置です。

ファイルの先頭にモジュール名を書いて、コードを移します。

```hs:Hex.hs
module Hex where
```

Mainから参照します。

```hs:Main.hsに追加
import Hex
```

⇒ [リビジョン 23](https://bitbucket.org/7shi/ikebin-hs-2/commits/3429014aa59dff855f430a3417a26b274cf7c664)

## DisAsm

逆アセンブラも同様に分割します。

* File → New Module
    * DisAsm と入力 → [OK]

新規作成されたファイルの中身をすべて消します。

ファイルの先頭にモジュール名を書いて、コードを移します。

```hs:DisAsm.hs
module DisAsm where
```

Mainから参照します。

```hs:Main.hsに追加
import DisAsm
```

逆アセンブラのテストはMainに残したままにした方が、テストと実装を行ったり来たりするのに都合が良いでしょう。

⇒ [リビジョン 24](https://bitbucket.org/7shi/ikebin-hs-2/commits/ae2d0fe643bed2a78ccdb5289f891081863c1c76)

# 練習

【問6】以下の手順で`modrm`の実装を完成させてください。

1. mod=10,11の機械語をバイナリエディタで作る。
1. ndisasmで逆アセンブルしてアセンブリ言語を確認する。
1. テストケースを作る。
1. 逆アセンブラを実装する。

⇒ [解答例](http://qiita.com/7shi/items/6d228b6fc4734f48a33e#modrm)

【問7】mov命令の2番目`Immediate to Register/Memory`を実装してください。

⇒ [解答例](http://qiita.com/7shi/items/6d228b6fc4734f48a33e#mov%E5%91%BD%E4%BB%A4%E3%81%AE2%E7%95%AA%E7%9B%AE)

【問8】mov命令の残りを実装してください。

⇒ [解答例](http://qiita.com/7shi/items/6d228b6fc4734f48a33e#mov%E5%91%BD%E4%BB%A4%E3%81%AE%E6%AE%8B%E3%82%8A)

【問9】`disasm`が命令の長さも返すように修正してください。想定される仕様をテストの修正として示します。仕様変更が`disasm'`にまで及ぶとテストの修正が大変なため、与えられたバイナリの長さと比較する修正を提示します。

```hs:テストの修正
    [ "b8 1" ~: disasm [0xb8, 0, 0]       ~?= (3, "mov ax,0x0")
    , "b8 2" ~: disasm [0xb8, 0x34, 0x12] ~?= (3, "mov ax,0x1234")
```
```hs:disasm'の修正
disasm' hex
    | length bin == len = snd asm
    | otherwise         = "length? " ++ show len
    where
        bin = hexStrToList hex
        asm = disasm bin
        len = fst asm
```

* `show`は引数を文字列に変換する関数です。

⇒ [解答例](http://qiita.com/7shi/items/6d228b6fc4734f48a33e#%E9%95%B7%E3%81%95%E3%82%82%E8%BF%94%E3%81%99)

【問10】複数の命令を含んだバイナリを渡すと逆アセンブル結果をリストで返す関数を実装してください。具体的には以下のテストを通してください。

```hs:テスト
    , "disasms" ~: disasms [0xc6, 0x47, 1, 1, 0xb0, 1]
        ~?= [(4, "mov byte [bx+0x1],0x1"), (2, "mov al,0x1")]
    , "disasms'" ~: disasms' "C6470101B001"
        ~?= ["mov byte [bx+0x1],0x1", "mov al,0x1"]
```

⇒ [解答例](http://qiita.com/7shi/items/6d228b6fc4734f48a33e#%E8%A4%87%E6%95%B0%E5%91%BD%E4%BB%A4%E5%AF%BE%E5%BF%9C)

【問11】逆アセンブル結果にアドレスやダンプを含めてndisasmと同じ出力にしてください。具体的には以下のテストを通してください。

```hs:テスト
    , "ndisasm" ~: ndisasm 0 [0xc6, 0x47, 1, 1]
        ~?= (4, "00000000  C6470101          mov byte [bx+0x1],0x1")
    , "ndisasms" ~: ndisasms 0 [0xc6, 0x47, 1, 1, 0xb0, 1]
        ~?= [ "00000000  C6470101          mov byte [bx+0x1],0x1"
            , "00000004  B001              mov al,0x1"
            ]
```

* 第一引数は開始アドレスです。

⇒ [解答例](http://qiita.com/7shi/items/6d228b6fc4734f48a33e#ndisasm%E6%BA%96%E6%8B%A0%E5%87%BA%E5%8A%9B)

# ファイル読み込み

`main`でコマンドライン引数を調べて、何も指定されていなければテスト、ファイルが指定されていれば読み込んで逆アセンブルするコードを示します。

依存パッケージにbytestringを追加してください。

```hs:importに追加
import System.Environment
import qualified Data.ByteString
```

`qualified`を指定すると使用する際に名前空間まで付ける必要があります（例: `Data.ByteString.readFile`）。元々あった関数と同名の関数（例: `readFile`）が衝突するのを回避しています。

```hs:mainを修正
main = do
    args <- getArgs
    if args == []
        then do
            runTestText (putTextToHandle stderr False)
                (TestList [testHex, testDisAsm])
            return ()
        else do
            bytes <- Data.ByteString.readFile $ args !! 0
            putStr $ unlines $ ndisasms 0
                [fromIntegral b | b <- Data.ByteString.unpack bytes]
```

`<-`はリスト内包表記の中か外かで意味が変わります。リスト内包表記の外で使われている`<-`はアクションから値を取り出す構文です。`<-`は`do`を指定したブロックでしか使えません。詳細は次の記事を参照してください。

* [Haskell アクション 超入門](http://qiita.com/7shi/items/85afd7bbd5d6c4115ad6)

コマンドラインからファイルを指定して呼び出し、逆アセンブルできることを確認してください。

```text
$ ./disasm test
00000000  C60012            mov byte [bx+si],0x12
00000003  C606123456        mov byte [0x3412],0x56
00000008  C6401234          mov byte [bx+si+0x12],0x34
0000000C  C680123456        mov byte [bx+si+0x3412],0x56
00000011  B012              mov al,0x12
00000013  C7001234          mov word [bx+si],0x3412
00000017  C70612345678      mov word [0x3412],0x7856
0000001D  C740123456        mov word [bx+si+0x12],0x5634
00000022  C78012345678      mov word [bx+si+0x3412],0x7856
00000028  B81234            mov ax,0x3412
```

⇒ [リビジョン 32](https://bitbucket.org/7shi/ikebin-hs-2/commits/a03cf4c04dfe23105a2a253edb3d1da2e4d6b95e)

# 練習

【問12】8086の全命令を実装してください。

※ 解答例はありません。
