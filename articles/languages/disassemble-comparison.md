---
coediting: false
comments_count: 2
created_at: '2018-06-16T13:45:36+09:00'
id: d503c83c1befe1cdb284
likes_count: 7
private: false
reactions_count: 0
stocks_count: 3
tags:
- name: CommonLisp
  versions: []
title: 複数の処理系で逆アセンブルして比較
updated_at: '2018-06-16T22:47:27+09:00'
url: https://qiita.com/7shi/items/d503c83c1befe1cdb284
slide: false
---

Common Lisp には関数を逆アセンブルする `disassemble` 関数があります。

『[大熱血！アセンブラ入門](http://www.shuwasystem.co.jp/products/7980html/5154.html)』の[サンプルコード（C言語）](http://kozos.jp/books/asm/)から移植した簡単な関数を逆アセンブルして比較します。

対象とする処理系は以下の3つです。

* ECL (Embeddable Common-Lisp)
* CLISP
* SBCL (Steel Bank Common Lisp)

実行環境は Windows 10 上の WSL です。SBCL と CLISP は 1803 (17134.81) から動くようになりました。👉[参考ツイート](https://twitter.com/7shi/status/1007480420307365888)

※ `disassemble` 関数は[『実用Common Lisp』読書会](https://jitsucl.connpass.com/)で教えて頂きました。Common Lisp が低レイヤも透過的だとは知らなかったので驚きました。

# 実行例

REPL で関数を定義して逆アセンブルします。

移植元となるC言語の関数です。

```c
int return_zero()
{
  return 0;
}
```

## ECL

処理系独自の中間コードにコンパイルされます。

```text
> (defun return_zero () 0)

RETURN_ZERO
> (disassemble 'return_zero)

#(RETURN_ZERO #<bytecompiled-function RETURN_ZERO> SI:FSET)
Name:           RETURN_ZERO
   0    NOMORE
   1    QUOTE   0
   3    SET     VALUES(0),REG0
   4    EXIT
NIL
```

ネイティブコードにコンパイルすると逆アセンブルできなくなります。

```text
> (compile 'return_zero)

;;; Loading #P"/usr/lib/ecl-15.3.7/cmp.fas"
;;; OPTIMIZE levels: Safety=2, Space=0, Speed=3, Debug=0
;;;
;;; End of Pass 1.
RETURN_ZERO
NIL
NIL
> (disassemble 'return_zero)
;;; Warning: Cannot disassemble the binary function #<compiled-function RETURN_ZERO> because I do not have its source code.

NIL
```

## CLISP

こちらも中間コードですが ECL よりもシンプルです。

```text
[1]> (defun return_zero () 0)
RETURN_ZERO
[2]> (disassemble 'return_zero)

Disassembly of function RETURN_ZERO
(CONST 0) = 0
0 required arguments
0 optional arguments
No rest parameter
No keyword parameters
2 byte-code instructions:
0     (CONST 0)                           ; 0
1     (SKIP&RET 1)
NIL
```

ECL とは異なり、コンパイルしても中間コードで逆アセンブルされます。

## SBCL

明示的にコンパイルしなくても、定義しただけでネイティブコードにコンパイルされます。

```text
* (defun return_zero () 0)

RETURN_ZERO
* (disassemble 'return_zero)

; disassembly for RETURN_ZERO
; Size: 19 bytes. Origin: #x10039D0784
; 84:       498B4C2460       MOV RCX, [R12+96]                ; thread.binding-stack-pointer
                                                              ; no-arg-parsing entry point
; 89:       48894DF8         MOV [RBP-8], RCX
; 8D:       31D2             XOR EDX, EDX
; 8F:       488BE5           MOV RSP, RBP
; 92:       F8               CLC
; 93:       5D               POP RBP
; 94:       C3               RET
; 95:       CC10             BREAK 16                         ; Invalid argument count trap
NIL
```

ABI はC言語とは異なっているようで良く分かりませんが、`EDX` が戻り値のようです。

# 1を返す

結果のみを掲載します。

```c
int return_one()
{
  return 1;
}
```
```cl
(defun return_one () 1)
```
```text:ECL
#(RETURN_ONE #<bytecompiled-function RETURN_ONE> SI:FSET)
Name:           RETURN_ONE
   0    NOMORE
   1    QUOTE   1
   3    SET     VALUES(0),REG0
   4    EXIT
```
```text:CLISP
Disassembly of function RETURN_ONE
(CONST 0) = 1
0 required arguments
0 optional arguments
No rest parameter
No keyword parameters
2 byte-code instructions:
0     (CONST 0)                           ; 1
1     (SKIP&RET 1)
```
```text:SBCL
; disassembly for RETURN_ONE
; Size: 22 bytes. Origin: #x1003A113D4
; D4:       498B4C2460       MOV RCX, [R12+96]                ; thread.binding-stack-pointer
                                                              ; no-arg-parsing entry point
; D9:       48894DF8         MOV [RBP-8], RCX
; DD:       BA02000000       MOV EDX, 2
; E2:       488BE5           MOV RSP, RBP
; E5:       F8               CLC
; E6:       5D               POP RBP
; E7:       C3               RET
; E8:       CC10             BREAK 16                         ; Invalid argument count trap
```

SBCL で戻り値の `EDX` が `2` になっていることから、数値以外の情報が含まれているようです。

# 定数を返す

```c
short return_short()
{
  return 0x7788;
}

long return_long()
{
  return 0x778899aa;
}

long return_long_upper()
{
  return 0xffeeddcc;
}
```
```cl
(defun return_short () #x7788)
(defun return_long () #x778899aa)
(defun return_long_upper () #xffeeddcc)
```
```text:ECL
#(RETURN_SHORT #<bytecompiled-function RETURN_SHORT> SI:FSET)
Name:           RETURN_SHORT
   0    NOMORE
   1    QUOTE   30600
   3    SET     VALUES(0),REG0
   4    EXIT
#(RETURN_LONG 2005440938 #<bytecompiled-function RETURN_LONG> SI:FSET)
Name:           RETURN_LONG
   0    NOMORE
   1    QUOTE   2005440938
   3    SET     VALUES(0),REG0
   4    EXIT
#(RETURN_LONG_UPPER 4293844428 #<bytecompiled-function RETURN_LONG_UPPER> SI:FSET)
Name:           RETURN_LONG_UPPER
   0    NOMORE
   1    QUOTE   4293844428
   3    SET     VALUES(0),REG0
   4    EXIT
```
```text:CLISP
Disassembly of function RETURN_SHORT
(CONST 0) = 30600
0 required arguments
0 optional arguments
No rest parameter
No keyword parameters
2 byte-code instructions:
0     (CONST 0)                           ; 30600
1     (SKIP&RET 1)

Disassembly of function RETURN_LONG
(CONST 0) = 2005440938
0 required arguments
0 optional arguments
No rest parameter
No keyword parameters
2 byte-code instructions:
0     (CONST 0)                           ; 2005440938
1     (SKIP&RET 1)

Disassembly of function RETURN_LONG_UPPER
(CONST 0) = 4293844428
0 required arguments
0 optional arguments
No rest parameter
No keyword parameters
2 byte-code instructions:
0     (CONST 0)                           ; 4293844428
1     (SKIP&RET 1)
```
```text:SBCL
; disassembly for RETURN_SHORT
; Size: 22 bytes. Origin: #x1003C1F254
; 54:       498B4C2460       MOV RCX, [R12+96]                ; thread.binding-stack-pointer
                                                              ; no-arg-parsing entry point
; 59:       48894DF8         MOV [RBP-8], RCX
; 5D:       BA10EF0000       MOV EDX, 61200
; 62:       488BE5           MOV RSP, RBP
; 65:       F8               CLC
; 66:       5D               POP RBP
; 67:       C3               RET
; 68:       CC10             BREAK 16                         ; Invalid argument count trap
; disassembly for RETURN_LONG
; Size: 22 bytes. Origin: #x1003C34F44
; 44:       498B4C2460       MOV RCX, [R12+96]                ; thread.binding-stack-pointer
                                                              ; no-arg-parsing entry point
; 49:       48894DF8         MOV [RBP-8], RCX
; 4D:       BA543311EF       MOV EDX, -284085420
; 52:       488BE5           MOV RSP, RBP
; 55:       F8               CLC
; 56:       5D               POP RBP
; 57:       C3               RET
; 58:       CC10             BREAK 16                         ; Invalid argument count trap
; disassembly for RETURN_LONG_UPPER
; Size: 27 bytes. Origin: #x1003C4AD94
; 94:       498B4C2460       MOV RCX, [R12+96]                ; thread.binding-stack-pointer
                                                              ; no-arg-parsing entry point
; 99:       48894DF8         MOV [RBP-8], RCX
; 9D:       48BA98BBDDFF01000000 MOV RDX, 8587688856
; A7:       488BE5           MOV RSP, RBP
; AA:       F8               CLC
; AB:       5D               POP RBP
; AC:       C3               RET
; AD:       CC10             BREAK 16                         ; Invalid argument count trap
```

CLISP では関数ごとに定数テーブルが存在するようです。
SBCL ではやはり数値が倍になっているようです。

# 引数

```c
int return_arg1(int a)
{
  return a;
}

int return_arg2(int a, int b)
{
  return b;
}
```
```cl
(defun return_arg1 (a) a)
(defun return_arg2 (a b) b)
```
```text:ECL
#(RETURN_ARG1 A #<bytecompiled-function RETURN_ARG1> SI:FSET)
Name:           RETURN_ARG1
   0    POP     REQ
   1    BIND    A
   3    NOMORE
   4    VAR     0
   6    SET     VALUES(0),REG0
   7    EXIT
#(RETURN_ARG2 A B #<bytecompiled-function RETURN_ARG2> SI:FSET)
Name:           RETURN_ARG2
   0    POP     REQ
   1    BIND    A
   3    POP     REQ
   4    BIND    B
   6    NOMORE
   7    VAR     0
   9    SET     VALUES(0),REG0
  10    EXIT
```
```text:CLISP
Disassembly of function RETURN_ARG1
1 required argument
0 optional arguments
No rest parameter
No keyword parameters
2 byte-code instructions:
0     (LOAD 1)
1     (SKIP&RET 2)
WARNING: in RETURN_ARG2 : variable A is not used.
         Misspelled or missing IGNORE declaration?

Disassembly of function RETURN_ARG2
2 required arguments
0 optional arguments
No rest parameter
No keyword parameters
2 byte-code instructions:
0     (LOAD 1)
1     (SKIP&RET 3)
```
```text:SBCL
; disassembly for RETURN_ARG1
; Size: 17 bytes. Origin: #x1003A4D165
; 65:       498B4C2460       MOV RCX, [R12+96]                ; thread.binding-stack-pointer
                                                              ; no-arg-parsing entry point
; 6A:       48894DF8         MOV [RBP-8], RCX
; 6E:       488BE5           MOV RSP, RBP
; 71:       F8               CLC
; 72:       5D               POP RBP
; 73:       C3               RET
; 74:       CC10             BREAK 16                         ; Invalid argument count trap
; disassembly for RETURN_ARG2
; Size: 17 bytes. Origin: #x1003A6F288
; 88:       498B4C2460       MOV RCX, [R12+96]                ; thread.binding-stack-pointer
                                                              ; no-arg-parsing entry point
; 8D:       48894DF8         MOV [RBP-8], RCX
; 91:       488BE5           MOV RSP, RBP
; 94:       F8               CLC
; 95:       5D               POP RBP
; 96:       C3               RET
; 97:       CC10             BREAK 16                         ; Invalid argument count trap
```

ECL はスタックマシンのようです。
SBCL は2つの関数が機械語レベルで同一です。

# 足し算

```c
int add(int a, int b)
{
  return a + b;
}

int add3(int a, int b, int c)
{
  return a + b + c;
}

int add_two(int a)
{
  return a + 2;
}

int inc(int a)
{
  return ++a;
}
```
```cl
(defun add (a b) (+ a b))
(defun add3 (a b c) (+ a b c))
(defun add_two (a) (+ a 2))
(defun inc (a) (+ a 1))
```
```text:ECL
#(ADD A B + #<bytecompiled-function ADD> SI:FSET)
Name:           ADD
   0    POP     REQ
   1    BIND    A
   3    POP     REQ
   4    BIND    B
   6    NOMORE
   7    PUSHV   1
   9    PUSHV   0
  11    CALLG   2,+
  14    EXIT
#(ADD3 A B C + #<bytecompiled-function ADD3> SI:FSET)
Name:           ADD3
   0    POP     REQ
   1    BIND    A
   3    POP     REQ
   4    BIND    B
   6    POP     REQ
   7    BIND    C
   9    NOMORE
  10    PUSHV   2
  12    PUSHV   1
  14    PUSHV   0
  16    CALLG   3,+
  19    EXIT
#(ADD_TWO A + #<bytecompiled-function ADD_TWO> SI:FSET)
Name:           ADD_TWO
   0    POP     REQ
   1    BIND    A
   3    NOMORE
   4    PUSHV   0
   6    PUSH    2
   8    CALLG   2,+
  11    EXIT
#(INC A + #<bytecompiled-function INC> SI:FSET)
Name:           INC
   0    POP     REQ
   1    BIND    A
   3    NOMORE
   4    PUSHV   0
   6    PUSH    1
   8    CALLG   2,+
  11    EXIT
```
```text:CLISP
Disassembly of function ADD
2 required arguments
0 optional arguments
No rest parameter
No keyword parameters
4 byte-code instructions:
0     (LOAD&PUSH 2)
1     (LOAD&PUSH 2)
2     (CALLSR 2 55)                       ; +
5     (SKIP&RET 3)

Disassembly of function ADD3
3 required arguments
0 optional arguments
No rest parameter
No keyword parameters
5 byte-code instructions:
0     (LOAD&PUSH 3)
1     (LOAD&PUSH 3)
2     (LOAD&PUSH 3)
3     (CALLSR 3 55)                       ; +
6     (SKIP&RET 4)

Disassembly of function ADD_TWO
(CONST 0) = 2
1 required argument
0 optional arguments
No rest parameter
No keyword parameters
4 byte-code instructions:
0     (CONST&PUSH 0)                      ; 2
1     (LOAD&PUSH 2)
2     (CALLSR 2 55)                       ; +
5     (SKIP&RET 2)

Disassembly of function INC
1 required argument
0 optional arguments
No rest parameter
No keyword parameters
3 byte-code instructions:
0     (LOAD&PUSH 1)
1     (CALLS2 177)                        ; 1+
3     (SKIP&RET 2)
```
```text:SBCL
; disassembly for ADD
; Size: 40 bytes. Origin: #x1003B54F73
; 73:       498B4C2460       MOV RCX, [R12+96]                ; thread.binding-stack-pointer
                                                              ; no-arg-parsing entry point
; 78:       48894DF8         MOV [RBP-8], RCX
; 7C:       488BD6           MOV RDX, RSI
; 7F:       488BFB           MOV RDI, RBX
; 82:       41BBC0010020     MOV R11D, 536871360              ; GENERIC-+
; 88:       41FFD3           CALL R11
; 8B:       488B5DE8         MOV RBX, [RBP-24]
; 8F:       488B75F0         MOV RSI, [RBP-16]
; 93:       488BE5           MOV RSP, RBP
; 96:       F8               CLC
; 97:       5D               POP RBP
; 98:       C3               RET
; 99:       CC10             BREAK 16                         ; Invalid argument count trap
; disassembly for ADD3
; Size: 47 bytes. Origin: #x1003B77CF7
; CF7:       498B4C2460       MOV RCX, [R12+96]               ; thread.binding-stack-pointer
                                                              ; no-arg-parsing entry point
; CFC:       48894DF8         MOV [RBP-8], RCX
; D00:       488B55F0         MOV RDX, [RBP-16]
; D04:       488B7DE8         MOV RDI, [RBP-24]
; D08:       41BBC0010020     MOV R11D, 536871360             ; GENERIC-+
; D0E:       41FFD3           CALL R11
; D11:       488B7DE0         MOV RDI, [RBP-32]
; D15:       41BBC0010020     MOV R11D, 536871360             ; GENERIC-+
; D1B:       41FFD3           CALL R11
; D1E:       488BE5           MOV RSP, RBP
; D21:       F8               CLC
; D22:       5D               POP RBP
; D23:       C3               RET
; D24:       CC10             BREAK 16                        ; Invalid argument count trap
; disassembly for ADD_TWO
; Size: 38 bytes. Origin: #x1003B97E0C
; 0C:       498B4C2460       MOV RCX, [R12+96]                ; thread.binding-stack-pointer
                                                              ; no-arg-parsing entry point
; 11:       48894DF8         MOV [RBP-8], RCX
; 15:       BF04000000       MOV EDI, 4
; 1A:       488BD3           MOV RDX, RBX
; 1D:       41BBC0010020     MOV R11D, 536871360              ; GENERIC-+
; 23:       41FFD3           CALL R11
; 26:       488B5DF0         MOV RBX, [RBP-16]
; 2A:       488BE5           MOV RSP, RBP
; 2D:       F8               CLC
; 2E:       5D               POP RBP
; 2F:       C3               RET
; 30:       CC10             BREAK 16                         ; Invalid argument count trap
; disassembly for INC
; Size: 38 bytes. Origin: #x1003BB3ABC
; BC:       498B4C2460       MOV RCX, [R12+96]                ; thread.binding-stack-pointer
                                                              ; no-arg-parsing entry point
; C1:       48894DF8         MOV [RBP-8], RCX
; C5:       BF02000000       MOV EDI, 2
; CA:       488BD3           MOV RDX, RBX
; CD:       41BBC0010020     MOV R11D, 536871360              ; GENERIC-+
; D3:       41FFD3           CALL R11
; D6:       488B5DF0         MOV RBX, [RBP-16]
; DA:       488BE5           MOV RSP, RBP
; DD:       F8               CLC
; DE:       5D               POP RBP
; DF:       C3               RET
; E0:       CC10             BREAK 16                         ; Invalid argument count trap
```

CLISP では呼び出す関数が `1+` という別の関数になっています。

# 関数呼び出し

既に足し算で関数呼び出しが現れていますが、一応確認します。

```c
int call_simple(int a)
{
  return return_arg1(a);
}

int call_complex1()
{
  return return_arg1(0xfe) + 1;
}
```
```cl
(defun call_simple (a) (return_arg1 a))
(defun call_complex1 () (+ (return_arg1 #xfe) 1))
```
```text:ECL
#(CALL_SIMPLE A RETURN_ARG1 #<bytecompiled-function CALL_SIMPLE> SI:FSET)
Name:           CALL_SIMPLE
   0    POP     REQ
   1    BIND    A
   3    NOMORE
   4    PUSHV   0
   6    CALLG   1,RETURN_ARG1
   9    EXIT
#(CALL_COMPLEX1 RETURN_ARG1 + #<bytecompiled-function CALL_COMPLEX1> SI:FSET)
Name:           CALL_COMPLEX1
   0    NOMORE
   1    PUSH    254
   3    CALLG   1,RETURN_ARG1
   6    PUSH    VALUES(0)
   7    PUSH    1
   9    CALLG   2,+
  12    EXIT
```
```text:CLISP
Disassembly of function CALL_SIMPLE
(CONST 0) = RETURN_ARG1
1 required argument
0 optional arguments
No rest parameter
No keyword parameters
3 byte-code instructions:
0     (LOAD&PUSH 1)
1     (CALL1 0)                           ; RETURN_ARG1
3     (SKIP&RET 2)

Disassembly of function CALL_COMPLEX1
(CONST 0) = 254
(CONST 1) = RETURN_ARG1
0 required arguments
0 optional arguments
No rest parameter
No keyword parameters
4 byte-code instructions:
0     (CONST&PUSH 0)                      ; 254
1     (CALL1&PUSH 1)                      ; RETURN_ARG1
3     (CALLS2 177)                        ; 1+
5     (SKIP&RET 1)
```
```text:SBCL
; disassembly for CALL_SIMPLE
; Size: 32 bytes. Origin: #x1003C88628
; 28:       498B4C2460       MOV RCX, [R12+96]                ; thread.binding-stack-pointer
                                                              ; no-arg-parsing entry point
; 2D:       48894DF8         MOV [RBP-8], RCX
; 31:       488BD6           MOV RDX, RSI
; 34:       488B0595FFFFFF   MOV RAX, [RIP-107]               ; #<FDEFINITION for RETURN_ARG1>
; 3B:       B902000000       MOV ECX, 2
; 40:       FF7508           PUSH QWORD PTR [RBP+8]
; 43:       FF6009           JMP QWORD PTR [RAX+9]
; 46:       CC10             BREAK 16                         ; Invalid argument count trap
; disassembly for CALL_COMPLEX1
; Size: 70 bytes. Origin: #x1003CA2D04
; 04:       498B4C2460       MOV RCX, [R12+96]                ; thread.binding-stack-pointer
                                                              ; no-arg-parsing entry point
; 09:       48894DF8         MOV [RBP-8], RCX
; 0D:       488D5C24F0       LEA RBX, [RSP-16]
; 12:       4883EC18         SUB RSP, 24
; 16:       BAFC010000       MOV EDX, 508
; 1B:       488B058EFFFFFF   MOV RAX, [RIP-114]               ; #<FDEFINITION for RETURN_ARG1>
; 22:       B902000000       MOV ECX, 2
; 27:       48892B           MOV [RBX], RBP
; 2A:       488BEB           MOV RBP, RBX
; 2D:       FF5009           CALL QWORD PTR [RAX+9]
; 30:       480F42E3         CMOVB RSP, RBX
; 34:       BF02000000       MOV EDI, 2
; 39:       41BBC0010020     MOV R11D, 536871360              ; GENERIC-+
; 3F:       41FFD3           CALL R11
; 42:       488BE5           MOV RSP, RBP
; 45:       F8               CLC
; 46:       5D               POP RBP
; 47:       C3               RET
; 48:       CC10             BREAK 16                         ; Invalid argument count trap
```

# まとめ

きりがないのでこの辺にします。

* ECL: Java のバイトコードに似たスタックマシンのようです。
* CLISP: VLIW に似た複合命令のようです。
* SBCL: ネイティブコードだと抽象化されていないため、読むのは結構大変そうです。

簡単に確認できるので、興味があるコードは自分で試してみると良いでしょう。
