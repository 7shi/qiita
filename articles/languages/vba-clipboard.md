---
coediting: false
comments_count: 0
created_at: '2020-01-19T17:12:04+09:00'
id: 61f4c4e132835b26b3ea
likes_count: 3
private: false
reactions_count: 0
stocks_count: 7
tags:
- name: VBA
  versions: []
title: 64bit VBAでクリップボードに文字列を設定・取得
updated_at: '2020-01-19T18:31:32+09:00'
url: https://qiita.com/7shi/items/61f4c4e132835b26b3ea
slide: false
---

VBAには標準でクリップボードを操作する関数が用意されていないため、何らかの代替手段が必要です。今回はAPI呼び出しを使用します。

# 64bit対応

以下の記事に32bitのコードが掲載されています。

* [クリップボードに情報を送信する | Microsoft Docs](https://docs.microsoft.com/ja-jp/office/vba/access/concepts/windows-api/send-information-to-the-clipboard) 2018.09.26

64bitでは必要に応じて `Long` を `LongPtr` や `LongLong` に修正する必要があります。

```vb
Option Explicit

#If VBA7 And Win64 Then
Private Declare PtrSafe Function OpenClipboard Lib "user32.dll" (ByVal hWnd As LongPtr) As Long
Private Declare PtrSafe Function EmptyClipboard Lib "user32.dll" () As Long
Private Declare PtrSafe Function CloseClipboard Lib "user32.dll" () As Long
Private Declare PtrSafe Function IsClipboardFormatAvailable Lib "user32.dll" (ByVal wFormat As Long) As Long
Private Declare PtrSafe Function GetClipboardData Lib "user32.dll" (ByVal wFormat As Long) As LongPtr
Private Declare PtrSafe Function SetClipboardData Lib "user32.dll" (ByVal wFormat As Long, ByVal hMem As LongPtr) As Long
Private Declare PtrSafe Function GlobalAlloc Lib "kernel32.dll" (ByVal wFlags As Long, ByVal dwBytes As LongLong) As LongPtr
Private Declare PtrSafe Function GlobalLock Lib "kernel32.dll" (ByVal hMem As LongPtr) As LongPtr
Private Declare PtrSafe Function GlobalUnlock Lib "kernel32.dll" (ByVal hMem As LongPtr) As Long
Private Declare PtrSafe Function GlobalSize Lib "kernel32.dll" (ByVal hMem As LongPtr) As LongLong
Private Declare PtrSafe Sub MoveMemory Lib "kernel32.dll" Alias "RtlMoveMemory" (ByVal Destination As LongPtr, ByVal Source As LongPtr, ByVal Length As LongLong)
#Else
Private Declare Function OpenClipboard Lib "user32.dll" (ByVal hWnd As Long) As Long
Private Declare Function EmptyClipboard Lib "user32.dll" () As Long
Private Declare Function CloseClipboard Lib "user32.dll" () As Long
Private Declare Function IsClipboardFormatAvailable Lib "user32.dll" (ByVal wFormat As Long) As Long
Private Declare Function GetClipboardData Lib "user32.dll" (ByVal wFormat As Long) As Long
Private Declare Function SetClipboardData Lib "user32.dll" (ByVal wFormat As Long, ByVal hMem As Long) As Long
Private Declare Function GlobalAlloc Lib "kernel32.dll" (ByVal wFlags As Long, ByVal dwBytes As Long) As Long
Private Declare Function GlobalLock Lib "kernel32.dll" (ByVal hMem As Long) As Long
Private Declare Function GlobalUnlock Lib "kernel32.dll" (ByVal hMem As Long) As Long
Private Declare Function GlobalSize Lib "kernel32.dll" (ByVal hMem As Long) As Long
Private Declare Function lstrcpy Lib "kernel32.dll" Alias "lstrcpyW" (ByVal lpString1 As Long, ByVal lpString2 As Long) As Long
Private Declare Sub MoveMemory Lib "kernel32.dll" Alias "RtlMoveMemory" (ByVal Destination As Long, ByVal Source As Long, ByVal Length As Long)
#End If

Public Sub SetClipboard(sUniText As String)
#If VBA7 And Win64 Then
    Dim iStrPtr As LongPtr
    Dim iLen As LongLong
    Dim iLock As LongPtr
#Else
    Dim iStrPtr As Long
    Dim iLen As Long
    Dim iLock As Long
#End If
    Const GMEM_MOVEABLE As Long = &H2
    Const GMEM_ZEROINIT As Long = &H40
    Const CF_UNICODETEXT As Long = &HD
    OpenClipboard 0&
    EmptyClipboard
    iLen = LenB(sUniText)
    iStrPtr = GlobalAlloc(GMEM_MOVEABLE Or GMEM_ZEROINIT, iLen + 2&)
    iLock = GlobalLock(iStrPtr)
    MoveMemory iLock, StrPtr(sUniText), iLen
    GlobalUnlock iStrPtr
    SetClipboardData CF_UNICODETEXT, iStrPtr
    CloseClipboard
End Sub

Public Function GetClipboard() As String
#If VBA7 And Win64 Then
    Dim iStrPtr As LongPtr
    Dim iLen As LongLong
    Dim iLock As LongPtr
#Else
    Dim iStrPtr As Long
    Dim iLen As Long
    Dim iLock As Long
#End If
    Dim sUniText As String
    Const CF_UNICODETEXT As Long = 13&
    OpenClipboard 0&
    If IsClipboardFormatAvailable(CF_UNICODETEXT) Then
        iStrPtr = GetClipboardData(CF_UNICODETEXT)
        If iStrPtr Then
            iLock = GlobalLock(iStrPtr)
            iLen = GlobalSize(iStrPtr)
            sUniText = String$(CLng(iLen) \ 2& - 1&, vbNullChar)
            MoveMemory StrPtr(sUniText), iLock, LenB(sUniText)
            GlobalUnlock iStrPtr
        End If
        GetClipboard = sUniText
    End If
    CloseClipboard
End Function
```

# 参考

以下の記事を参考にしました。

* [VBA クリップボードの値を取得する方法(API) 64Bit対応版 - Excel | ホームページ制作のサカエン（墨田区）](https://www.saka-en.com/office/vba-get-clipboard-api-64bit-excel/)

以下では一時的にテキストボックスを作る方法が紹介されています。API呼び出しよりも手軽ですが、手元の環境では数回に1回くらいの頻度で失敗することがありました。

* [VBA - VBAでクリップボードへのコピー｜teratail](https://teratail.com/questions/203287?sip=n0070000_019)
