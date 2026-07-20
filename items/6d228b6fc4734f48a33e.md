---
coediting: false
comments_count: 0
created_at: '2014-08-31T23:03:33+09:00'
id: 6d228b6fc4734f48a33e
likes_count: 9
private: false
reactions_count: 0
stocks_count: 8
tags:
- name: Haskell
  versions: []
- name: Intel8086
  versions: []
title: 【解答例】Haskellによる8086逆アセンブラ開発入門
updated_at: '2015-01-09T15:04:06+09:00'
url: https://qiita.com/7shi/items/6d228b6fc4734f48a33e
slide: false
---

[Haskellによる8086逆アセンブラ開発入門](http://qiita.com/7shi/items/026839b2bc193dbfb0cb)の解答例です。

# 2進数

【問1】数値を2進数の文字列に変換する関数`bin`をテストファーストで作成してください。

```hs:テスト
    , "bin 1" ~: bin 5  ~?= "101"
    , "bin 2" ~: bin 25 ~?= "11001"
```
```hs:実装
intToBin 0 = '0'
intToBin 1 = '1'

bin x
    | x1 == 0   = x2
    | otherwise = bin x1 ++ x2
    where
        x1 = x `div` 2
        x2 = [intToBin (x `mod` 2)]
```

⇒ [リビジョン 1](https://bitbucket.org/7shi/ikebin-hs-2/commits/73af0f54093f0853318c778abb0ca39d020fa7c7)

# 16進数

【問2】16進数の文字列を数値に変換する関数`hexStrToInt`をテストファーストで作成してください。

```hs:テスト
    , "digitToInt" ~: digitToInt 'a' ~?= 10
    , "hexStrToInt 1" ~: hexStrToInt "100"  ~?= 256
    , "hexStrToInt 2" ~: hexStrToInt "ffff" ~?= 65535
```
```hs:importに追加
import Data.Char
```
```hs:実装
hexStrToInt hex = f (reverse hex)
    where
        f ""     = 0
        f (x:xs) = (digitToInt x) + 16 * (f xs)
```

⇒ [リビジョン 2](https://bitbucket.org/7shi/ikebin-hs-2/commits/a302aab23fc918f6861e9d01c1e8ebbfb1b4e391)

【問3】数値を16進数の文字列に変換する関数`hex`をテストファーストで作成してください。

```hs:テスト
    , "intToDigit" ~: intToDigit 10  ~?= 'a'
    , "hex 1" ~: hex 256   ~?= "100"
    , "hex 2" ~: hex 65535 ~?= "ffff"
```
```hs:実装
hex x
    | x1 == 0   = x2
    | otherwise = hex x1 ++ x2
    where
        x1 = x `div` 16
        x2 = [intToDigit (x `mod` 16)]
```

⇒ [リビジョン 3](https://bitbucket.org/7shi/ikebin-hs-2/commits/104ff8feb5de21d6aa3ab0d36be6c02dc57e2535)

# ビッグエンディアン

【問4】数値⇔ビッグエンディアンの相互変換を実装してください。

```hs:テスト
    , "toBE 1" ~: toBE 2 1          ~?= [0, 1]
    , "toBE 2" ~: toBE 2 0x10000    ~?= [0, 0]
    , "toBE 3" ~: toBE 4 0x12345678 ~?= [0x12, 0x34, 0x56, 0x78]
    , "fromBE 1" ~: fromBE 2 [0, 1]                   ~?= 0x1
    , "fromBE 2" ~: fromBE 2 [0x78, 0x56, 0x34, 0x12] ~?= 0x7856
    , "fromBE 3" ~: fromBE 4 [0x78, 0x56, 0x34, 0x12] ~?= 0x78563412
```
```hs:実装
toBE 0 _ = []
toBE n x = (x `div` 0x100^(n - 1)) `mod` 0x100 : toBE (n - 1) x

fromBE 0 _ = 0
fromBE n (x:xs) = x * 0x100^(n - 1) + fromBE (n - 1) xs
```

⇒ [リビジョン 9](https://bitbucket.org/7shi/ikebin-hs-2/commits/4a74827b7eef68f0f06b04099d79d056fc847f9b)

## 別解

リトルエンディアン実装を利用します。

```hs:別実装
toBE n x = reverse (toLE n x)
fromBE n x = fromLE n (reverse (take n x))
```

# ビット演算

【問5】今まで実装した関数をビット演算で書き換えてください。

（準備中）

# ModR/M

【問6】以下の手順で`modrm`の実装を完成させてください。

1. mod=10,11の機械語をバイナリエディタで作る。
1. ndisasmで逆アセンブルしてアセンブリ言語を確認する。
1. テストケースを作る。
1. 逆アセンブラを実装する。

## mod 10

ディスプレースメントが2バイトです。mod 01のテストの下位に00を入れてテストとします。

```hs:テスト
    , "88-8b mod=10 1" ~: disasm' "89800001" ~?= "mov [bx+si+0x100],ax"
    , "88-8b mod=10 2" ~: disasm' "898900FF" ~?= "mov [bx+di-0x100],cx"
    , "88-8b mod=10 3" ~: disasm' "89920002" ~?= "mov [bp+si+0x200],dx"
    , "88-8b mod=10 4" ~: disasm' "899B00FE" ~?= "mov [bp+di-0x200],bx"
    , "88-8b mod=10 5" ~: disasm' "89A40064" ~?= "mov [si+0x6400],sp"
    , "88-8b mod=10 6" ~: disasm' "89AD009C" ~?= "mov [di-0x6400],bp"
    , "88-8b mod=10 7" ~: disasm' "89B60000" ~?= "mov [bp+0x0],si"
    , "88-8b mod=10 8" ~: disasm' "89B60001" ~?= "mov [bp+0x100],si"
    , "88-8b mod=10 9" ~: disasm' "89BF0001" ~?= "mov [bx+0x100],di"
```

2バイトのディスプレースメントを処理する関数を実装します。

```hs:テスト
    , "disp16 1" ~: disp16 0      ~?= "+0x0"
    , "disp16 2" ~: disp16 0x7fff ~?= "+0x7fff"
    , "disp16 3" ~: disp16 0x8000 ~?= "-0x8000"
    , "disp16 4" ~: disp16 0xffff ~?= "-0x1"
```
```hs:実装
disp16 x
    | x < 0x8000 = "+0x" ++ hex x
    | otherwise  = "-0x" ++ hex (0x10000 - x)
```

`modrm`に追加します。

```hs
modrm w (x:xs) = (f mode rm, reg)
    where
        （略）
        f 2 rm = "[" ++ regad !! rm ++ disp ++ "]"
            where
                disp = disp16 (fromLE 2 xs)
```

ヒント: `fromLE`の使い方は少し上を見てください。

```hs
        f 0 6  = "[0x" ++ hex (fromLE 2 xs) ++ "]"
```

⇒ [リビジョン 25](https://bitbucket.org/7shi/ikebin-hs-2/commits/eca7b6283af39cf11893e1b71280d9d9e3aa0a27)

## mod 11

R/Mはレジスタ番号を表して、ディスプレースメントはありません。

```hs:テスト
    , "88-8b mod=11,w=1 1" ~: disasm' "89C0" ~?= "mov ax,ax"
    , "88-8b mod=11,w=1 2" ~: disasm' "89C1" ~?= "mov cx,ax"
    , "88-8b mod=11,w=1 3" ~: disasm' "89C2" ~?= "mov dx,ax"
    , "88-8b mod=11,w=1 4" ~: disasm' "89C3" ~?= "mov bx,ax"
    , "88-8b mod=11,w=1 5" ~: disasm' "89C4" ~?= "mov sp,ax"
    , "88-8b mod=11,w=1 6" ~: disasm' "89C5" ~?= "mov bp,ax"
    , "88-8b mod=11,w=1 7" ~: disasm' "89C6" ~?= "mov si,ax"
    , "88-8b mod=11,w=1 8" ~: disasm' "89C7" ~?= "mov di,ax"
    , "88-8b mod=11,w=0 1" ~: disasm' "88C0" ~?= "mov al,al"
    , "88-8b mod=11,w=0 2" ~: disasm' "88C1" ~?= "mov cl,al"
    , "88-8b mod=11,w=0 3" ~: disasm' "88C2" ~?= "mov dl,al"
    , "88-8b mod=11,w=0 4" ~: disasm' "88C3" ~?= "mov bl,al"
    , "88-8b mod=11,w=0 5" ~: disasm' "88C4" ~?= "mov ah,al"
    , "88-8b mod=11,w=0 6" ~: disasm' "88C5" ~?= "mov ch,al"
    , "88-8b mod=11,w=0 7" ~: disasm' "88C6" ~?= "mov dh,al"
    , "88-8b mod=11,w=0 8" ~: disasm' "88C7" ~?= "mov bh,al"
```

レジスタを決めるには`modrm`に`w`を渡す必要があります。

```hs
modrm w (x:xs) = (f mode rm, reg)
    where
        （略）
        f 3 rm = regs !! w !! rm
```

引数を増やしたので、呼び出し側も修正します。

```hs:disasm
            (rm, r) = modrm w xs
```

⇒ [リビジョン 26](https://bitbucket.org/7shi/ikebin-hs-2/commits/0d91cc7bb3056e4bb6c30a4a67dc993886aa23ed)

# mov命令の2番目

【問7】mov命令の2番目`Immediate to Register/Memory`を実装してください。

各mod,wでテストを作ります。

```hs:テスト
    , "c6-c7 mod=00,w=0 1" ~: disasm' "C60012"       ~?= "mov byte [bx+si],0x12"
    , "c6-c7 mod=00,w=0 2" ~: disasm' "C606123456"   ~?= "mov byte [0x3412],0x56"
    , "c6-c7 mod=01,w=0"   ~: disasm' "C6401234"     ~?= "mov byte [bx+si+0x12],0x34"
    , "c6-c7 mod=10,w=0"   ~: disasm' "C680123456"   ~?= "mov byte [bx+si+0x3412],0x56"
    , "c6-c7 mod=11,w=0"   ~: disasm' "C6C012"       ~?= "mov al,0x12"
    , "c6-c7 mod=00,w=1 1" ~: disasm' "C7001234"     ~?= "mov word [bx+si],0x3412"
    , "c6-c7 mod=00,w=1 2" ~: disasm' "C70612345678" ~?= "mov word [0x3412],0x7856"
    , "c6-c7 mod=01,w=1"   ~: disasm' "C740123456"   ~?= "mov word [bx+si+0x12],0x5634"
    , "c6-c7 mod=10,w=1"   ~: disasm' "C78012345678" ~?= "mov word [bx+si+0x3412],0x7856"
    , "c6-c7 mod=11,w=1"   ~: disasm' "C7C01234"     ~?= "mov ax,0x3412"
```

`modrm`の引数でプレフィックスの有無を指定して付加します。戻り値にディスプレースメントを含む消費したバイト数を追加します。

```hs
modrm prefix w (x:xs) = (len, s, reg)
    where
        (len, s) = f mode rm
        mode =  x `shiftR` 6
        reg  = (x `shiftR` 3) .&. 7
        rm   =  x             .&. 7
        pfx | prefix && w == 0 = "byte "
            | prefix && w == 1 = "word "
            | otherwise        = ""
        f 0 6  = (3, pfx ++ "[0x" ++ hex (fromLE 2 xs) ++ "]")
        f 0 rm = (1, pfx ++ "[" ++ regad !! rm ++ "]")
        f 1 rm = (2, pfx ++ "[" ++ regad !! rm ++ disp ++ "]")
            where
                disp = disp8 (xs !! 0)
        f 2 rm = (3, pfx ++ "[" ++ regad !! rm ++ disp ++ "]")
            where
                disp = disp16 (fromLE 2 xs)
        f 3 rm = (1, regs !! w !! rm)
```

`disasmB`に追加します。

```hs
-- Immediate to Register/Memory [1100011w][mod000r/m][data][data if w=1]
disasmB (1,1,0,0,0,1,1,w) xs =
    "mov " ++ rm ++ "," ++ imm
    where
        (len, rm, _) = modrm True w xs
        imm = "0x" ++ hex (fromLE (w + 1) (drop len xs))
```

⇒ [リビジョン 27](https://bitbucket.org/7shi/ikebin-hs-2/commits/5ff875340d42c5ad1f76d1d57b14d030f7ae18be)

# mov命令の残り

【問8】mov命令の残りを実装してください。

```hs:テスト
    , "a0-a1 w=0" ~: disasm' "A03412" ~?= "mov al,[0x1234]"
    , "a0-a1 w=1" ~: disasm' "A13412" ~?= "mov ax,[0x1234]"
    , "a2-a3 w=0" ~: disasm' "A23412" ~?= "mov [0x1234],al"
    , "a2-a3 w=1" ~: disasm' "A33412" ~?= "mov [0x1234],ax"
    , "8e mod=00" ~: disasm' "8E00"     ~?= "mov es,[bx+si]"
    , "8e mod=01" ~: disasm' "8E4810"   ~?= "mov cs,[bx+si+0x10]"
    , "8e mod=10" ~: disasm' "8E9000F0" ~?= "mov ss,[bx+si-0x1000]"
    , "8e mod=11" ~: disasm' "8ED8"     ~?= "mov ds,ax"
    , "8c mod=00" ~: disasm' "8C00"     ~?= "mov [bx+si],es"
    , "8c mod=01" ~: disasm' "8C4810"   ~?= "mov [bx+si+0x10],cs"
    , "8c mod=10" ~: disasm' "8C9000F0" ~?= "mov [bx+si-0x1000],ss"
    , "8c mod=11" ~: disasm' "8CD8"     ~?= "mov ax,ds"
```
```hs:sregを追加
sreg  = ["es", "cs", "ss", "ds"]
```
```hs:disasmBに追加
-- Memory to Accumulator [1010000w][addr-low][addr-high]
disasmB (1,0,1,0,0,0,0,w) xs =
    "mov " ++ reg ++ ",[0x" ++ hex (fromLE 2 xs) ++ "]"
    where
        reg = regs !! w !! 0
-- Accumulator to Memory [1010001w][addr-low][addr-high]
disasmB (1,0,1,0,0,0,1,w) xs =
    "mov " ++ "[0x" ++ hex (fromLE 2 xs) ++ "]," ++ reg
    where
        reg = regs !! w !! 0
-- Register/Memory to Segment Register [10001110][mod0reg r/m]
disasmB (1,0,0,0,1,1,1,0) xs =
    "mov " ++ reg ++ "," ++ rm
    where
        (len, rm, r) = modrm False 1 xs
        reg = sreg !! r
-- Segment Register to Register/Memory [10001100][mod0reg r/m]
disasmB (1,0,0,0,1,1,0,0) xs =
    "mov " ++ rm ++ "," ++ reg
    where
        (len, rm, r) = modrm False 1 xs
        reg = sreg !! r
```

⇒ [リビジョン 28](https://bitbucket.org/7shi/ikebin-hs-2/commits/ce131a968a8a856c9db33e7bdd31fa73c29662aa)

# 長さも返す

【問9】`disasm`が命令の長さも返すように修正してください。

```diff:disasmBの差分
 -- Register/Memory to/from Register [100010dw][mod reg r/m]
 disasmB (1,0,0,0,1,0,d,w) xs
-    | d == 0    = "mov " ++ rm  ++ "," ++ reg
-    | otherwise = "mov " ++ reg ++ "," ++ rm
+    | d == 0    = (1 + len, "mov " ++ rm  ++ "," ++ reg)
+    | otherwise = (1 + len, "mov " ++ reg ++ "," ++ rm )
     where
-        (_, rm, r) = modrm False w xs
+        (len, rm, r) = modrm False w xs
         reg = regs !! w !! r
 -- Immediate to Register/Memory [1100011w][mod000r/m][data][data if w=1]
 disasmB (1,1,0,0,0,1,1,w) xs =
-    "mov " ++ rm ++ "," ++ imm
+    (1 + len + w + 1, "mov " ++ rm ++ "," ++ imm)
     where
         (len, rm, _) = modrm True w xs
         imm = "0x" ++ hex (fromLE (w + 1) (drop len xs))
 -- Immediate to Register [1011wreg][data][data if w=1]
 disasmB (1,0,1,1,w,r,e,g) xs =
-    "mov " ++ reg ++ "," ++ imm
+    (2 + w, "mov " ++ reg ++ "," ++ imm)
     where
         reg = regs !! w !! getReg r e g
         imm = "0x" ++ hex (fromLE (w + 1) xs)
 -- Memory to Accumulator [1010000w][addr-low][addr-high]
 disasmB (1,0,1,0,0,0,0,w) xs =
-    "mov " ++ reg ++ ",[0x" ++ hex (fromLE 2 xs) ++ "]"
+    (3, "mov " ++ reg ++ ",[0x" ++ hex (fromLE 2 xs) ++ "]")
     where
         reg = regs !! w !! 0
 -- Accumulator to Memory [1010001w][addr-low][addr-high]
 disasmB (1,0,1,0,0,0,1,w) xs =
-    "mov " ++ "[0x" ++ hex (fromLE 2 xs) ++ "]," ++ reg
+    (3, "mov " ++ "[0x" ++ hex (fromLE 2 xs) ++ "]," ++ reg)
     where
         reg = regs !! w !! 0
 -- Register/Memory to Segment Register [10001110][mod0reg r/m]
 disasmB (1,0,0,0,1,1,1,0) xs =
-    "mov " ++ reg ++ "," ++ rm
+    (1 + len, "mov " ++ reg ++ "," ++ rm)
     where
         (len, rm, r) = modrm False 1 xs
         reg = sreg !! r
 -- Segment Register to Register/Memory [10001100][mod0reg r/m]
 disasmB (1,0,0,0,1,1,0,0) xs =
-    "mov " ++ rm ++ "," ++ reg
+    (1 + len, "mov " ++ rm ++ "," ++ reg)
     where
         (len, rm, r) = modrm False 1 xs
         reg = sreg !! r
```

⇒ [リビジョン 29](https://bitbucket.org/7shi/ikebin-hs-2/commits/c1b76ad95169de6ab9b0cf41b001c476d3b0d8dc)

# 複数命令対応

【問10】複数の命令を含んだバイナリを渡すと逆アセンブル結果をリストで返す関数を実装してください。

`disasm`が返す長さを利用して命令を次々に逆アセンブルします。

```hs
disasms [] = []
disasms xs = asm : disasms (drop len xs)
    where
        asm = disasm xs
        len = fst asm

disasms' hex = [snd asm | asm <- disasms $ hexStrToList hex]
```

⇒ [リビジョン 30](https://bitbucket.org/7shi/ikebin-hs-2/commits/305567bf737c864ce004df44e9647439b240c742)

# ndisasm準拠出力

【問11】逆アセンブル結果にアドレスやダンプを含めてNASMと同じ出力にしてください。

```hs:importに追加
import Data.Char
```
```hs
ndisasm ip xs = (len, addr ++ "  " ++ dump ++ "  " ++ snd asm)
    where
        asm  = disasm xs
        len  = fst asm
        addr = upper $ hexn 8 ip
        dump = upper $ listToHexStr list ++ spc
        list = take len xs
        spc  = replicate (16 - len * 2) ' '
        upper s = [toUpper ch | ch <- s]

ndisasms _ [] = []
ndisasms ip xs = snd asm : ndisasms (ip + len) (drop len xs)
    where
        asm = ndisasm ip xs
        len = fst asm
```

⇒ [リビジョン 31](https://bitbucket.org/7shi/ikebin-hs-2/commits/a5a36de931487d48f7a726a575f1c4c1a54d5a80)
