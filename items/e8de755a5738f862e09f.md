---
coediting: false
comments_count: 2
created_at: '2020-06-23T23:31:18+09:00'
id: e8de755a5738f862e09f
likes_count: 2
private: false
reactions_count: 0
stocks_count: 1
tags:
- name: F#
  versions: []
- name: PowerShell
  versions: []
- name: WinRT
  versions: []
- name: リフレクション
  versions: []
title: WinRTの非同期メソッドをリフレクションで扱う
updated_at: '2023-02-13T18:25:47+09:00'
url: https://qiita.com/7shi/items/e8de755a5738f862e09f
slide: false
---

WinRT は通常の .NET アセンブリとは異なるため言語側でもサポートが必要です。特に WinRT で多用される非同期処理が問題になります。今回は `await` に相当するコードを PowerShell から F# に移植して対応しました。

WinRT が COM ベースで動いていることが垣間見えて面白いです。

今回の手法でコードを書いてみた記事です。

* [F#でリフレクションを駆使してWinRTを扱う](https://qiita.com/7shi/items/01899f69f010a029242f)

# 概要

記事執筆時点で F# には WinRT のサポートがないため、リフレクション経由で扱う必要があります。PowerShell ではリフレクションは裏側で処理されるため、F# ほど煩雑にはなりません。

非同期メソッドは `__ComObject` を返します。C# では `await` で処理できますが、F# や PowerShell では `WindowsRuntimeSystemExtensions.AsTask()` で `Task` に変換する必要があります。

【追記】コメント欄の情報より、開発中の [C#/WinRT](https://docs.microsoft.com/ja-jp/windows/uwp/csharp-winrt/) によって改善する見込みとのことです。

* [Hacking Windows with F# 5.0 Scripts - DEV](https://dev.to/tunaxor/hacking-windows-with-f-5-0-scripts-4k2o)

# 例

`StorageFile.GetFileFromPathAsync()` で `C:\test.txt` を開く例です。ファイル名は絶対パスで指定する必要があります。

C# では WinRT がサポートされているため、参照を追加すれば動きます。動作中の型を示すため C# Interactive を使用します。

```csharp:C#
> #r "System.Runtime.WindowsRuntime"
> #r "C:\Program Files (x86)\Windows Kits\10\UnionMetadata\10.0.17763.0\Facade\windows.winmd"
> #r "C:\Program Files (x86)\Windows Kits\10\References\10.0.17763.0\Windows.Foundation.FoundationContract\3.0.0.0\Windows.Foundation.FoundationContract.winmd"
> #r "C:\Program Files (x86)\Windows Kits\10\References\10.0.17763.0\Windows.Foundation.UniversalApiContract\7.0.0.0\Windows.Foundation.UniversalApiContract.winmd"
> var result = Windows.Storage.StorageFile.GetFileFromPathAsync(@"C:\test.txt");
> result
[System.__ComObject]
> var file = await result;
> file
[Windows.Storage.StorageFile]
```

F# では参照を追加しても動きません。

```fsharp:F#
> #r "System.Runtime.WindowsRuntime";;
（略）
> #r @"C:\Program Files (x86)\Windows Kits\10\UnionMetadata\10.0.17763.0\Facade\windows.winmd";;
（略）
> #r @"C:\Program Files (x86)\Windows Kits\10\References\10.0.17763.0\Windows.Foundation.FoundationContract\3.0.0.0\Windows.Foundation.FoundationContract.winmd";;
（略）
> #r @"C:\Program Files (x86)\Windows Kits\10\References\10.0.17763.0\Windows.Foundation.UniversalApiContract\7.0.0.0\Windows.Foundation.UniversalApiContract.winmd";;
（略）
> let result = Windows.Storage.StorageFile.GetFileFromPathAsync(@"C:\test.txt");;

error FS0193: ファイルまたはアセンブリ 'file:///C:\Program Files (x86)\Windows Kits\10\References\10.0.17763.0\Windows.F
oundation.FoundationContract\3.0.0.0\Windows.Foundation.FoundationContract.winmd'、またはその依存関係の 1 つが読み込めま
せんでした。操作はサポートされません。 (HRESULT からの例外:0x80131515)
```

ランタイムは WinRT を認識するため、参照は追加せずにリフレクションで扱います。しかし `await` がないため結果が取得できません。

```fsharp:F#
> let StorageFile = System.Type.GetType("Windows.Storage.StorageFile,Windows.Foundation.UniversalApiContract,ContentType=WindowsRuntime");;
val StorageFile : System.Type = Windows.Storage.StorageFile

> let result = StorageFile.GetMethod("GetFileFromPathAsync").Invoke(null, [|@"C:\test.txt"|]);;
val result : obj = System.__ComObject
```

PowerShell はリフレクションが表には出て来ませんが、F# と同じような扱い方をします。

```powershell:PowerShell
PS> [Windows.Storage.StorageFile,Windows.Foundation.UniversalApiContract,ContentType=WindowsRuntime]

IsPublic IsSerial Name                             BaseType
-------- -------- ----                             --------
True     False    StorageFile                      System.Runtime.InteropServices.WindowsRuntime.RuntimeClass

PS> $result = [Windows.Storage.StorageFile]::GetFileFromPathAsync("C:\test.txt")
PS> $result
System.__ComObject
```

※ この `__ComObject` は従来の COM とは異なり、`IDispatch` ではなく `IInspectable` ベースです。

# Task に変換

以下の記事に PowerShell で Task に変換する方法があります。`WindowsRuntimeSystemExtensions.AsTask` をリフレクションで呼んで変換します。

* [Fleex's Lab: Using WinRT's IAsyncOperation in PowerShell](https://fleexlab.blogspot.com/2018/02/using-winrts-iasyncoperation-in.html)

```powershell:PowerShell
Add-Type -AssemblyName System.Runtime.WindowsRuntime
$asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | ? { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]
Function Await($WinRtTask, $ResultType) {
 $asTask = $asTaskGeneric.MakeGenericMethod($ResultType)
 $netTask = $asTask.Invoke($null, @($WinRtTask))
 $netTask.Wait(-1) | Out-Null
 $netTask.Result
}
```

これを F# に移植します。

```fsharp:F#
#r "System.Runtime.WindowsRuntime"
open System
let AsTaskGeneric = query {
    for m in typeof<WindowsRuntimeSystemExtensions>.GetMethods() do
    where (m.Name = "AsTask")
    let ps = m.GetParameters()
    where (ps.Length = 1 && ps.[0].ParameterType.Name = "IAsyncOperation`1")
    select m
    exactlyOne }
let await resultType winRtTask =
    let asTask = AsTaskGeneric.MakeGenericMethod [|resultType|]
    let task = asTask.Invoke(null, [|winRtTask|])
    task.GetType().GetProperty("Result").GetValue(task)
```

* パイプライン演算子との相性を考えて `await` の引数は逆にしました。
* `Wait(-1)` がなくても `Result` で結果を待つため、F# では省略しました。

# 結果

先ほどの `GetFileFromPathAsync` の続きで使ってみます。

```fsharp:F#
> let file = result |> await StorageFile;;
val file : obj = Windows.Storage.StorageFile
```
```powershell:PowerShell
PS> $file = Await $result ([Windows.Storage.StorageFile])
PS> $file

ContentType      : text/plain
FileType         : .txt
IsAvailable      : True
Attributes       : Archive
DateCreated      : 2020/06/23 22:20:30 +09:00
Name             : test.txt
Path             : C:\test.txt
DisplayName      : test
DisplayType      : テキスト ドキュメント
FolderRelativeId : 9040E69AD829A77C\test.txt
Properties       : Windows.Storage.FileProperties.StorageItemContentProperties
Provider         : Windows.Storage.StorageProvider
```

無事に結果が取得できました。

# AsTask

`AsTask` には大量のオーバーロードがあります。

* [WindowsRuntimeSystemExtensions.AsTask メソッド (System) | Microsoft Docs](https://docs.microsoft.com/ja-jp/dotnet/api/system.windowsruntimesystemextensions.astask?view=dotnet-plat-ext-3.1)

このうち引数が1つだけのものは以下の4つの型を受け取ります。

* `IAsyncOperation<TResult>`
* `IAsyncOperationWithProgress<TResult, TProgress>`
* `IAsyncAction`
* `IAsyncActionWithProgress<TProgress>`

非同期メソッドはこれらのどれかを返します。今回は `IAsyncOperation<TResult>` だけを実装しましたが、すべてサポートする必要があります。

# 参考

PowerShell での WinRT について参考にしました。

* [windows - How to reference WinRT components in Powershell - Stack Overflow](https://stackoverflow.com/questions/28069079/how-to-reference-winrt-components-in-powershell)

C# での参照の追加について参考にしました。

* [デスクトップ アプリで Windows ランタイム API を呼び出す | Microsoft Docs](https://docs.microsoft.com/ja-jp/windows/apps/desktop/modernize/desktop-to-uwp-enhance)

F# でリフレクションでメンバーを動的にルックアップする方法が紹介されています。

* [Windows UI (UWP or 8.1) in F# interactive - Stack Overflow](https://stackoverflow.com/questions/38343566/windows-ui-uwp-or-8-1-in-f-interactive)

`AsTask` について説明されています。

* [非同期メソッド入門 (10) - WinRTとの相互運用 - xin9le.net](https://blog.xin9le.net/entry/2012/11/12/123231)
