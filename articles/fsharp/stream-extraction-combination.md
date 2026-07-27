---
coediting: false
comments_count: 0
created_at: '2020-06-05T21:37:13+09:00'
id: 0ac50e3816dca212a52e
likes_count: 1
private: false
reactions_count: 0
stocks_count: 1
tags:
- name: F#
  versions: []
title: ストリームの抜き出しと結合
updated_at: '2020-06-09T15:21:47+09:00'
url: https://qiita.com/7shi/items/0ac50e3816dca212a52e
slide: false
---

ストリームに上から被せて読み取る長さを制限したり（抜き出し）、複数のストリームを 1 つのストリームのようにまとめたりします。

# SubStream

ストリームの一部だけを読みたい時に使用します。残りのストリームは他で使うことを想定して `Dispose` で閉じません。

```fsharp
open System
open System.IO

type SubStream(stream: Stream, length) =
    inherit Stream()
    let mutable position = 0
    override __.CanRead  = true
    override __.CanWrite = false
    override __.CanSeek  = false
    override __.Length   = int64 length
    override __.Flush()  = raise <| NotSupportedException()
    override __.Position with get() = int64 position
                         and  set _ = raise <| NotSupportedException()
    override __.Seek(_, _)     = raise <| NotSupportedException()
    override __.SetLength(_)   = raise <| NotSupportedException()
    override __.Write(_, _, _) = raise <| NotSupportedException()
    override __.Read(array, offset, count) =
        if position >= length then 0 else
        let rlen = min count (length - position)
        let ret  = stream.Read(array, offset, rlen)
        position <- position + ret
        ret

do
    use ms  = new MemoryStream([|'a'B..'z'B|])
    use ss1 = new SubStream(ms, 10)
    use ss2 = new SubStream(ms, 10)
    use sr1 = new StreamReader(ss1)
    use sr2 = new StreamReader(ss2)
    use sr3 = new StreamReader(ms)
    printfn "%s" (sr1.ReadToEnd())
    printfn "%s" (sr2.ReadToEnd())
    printfn "%s" (sr3.ReadToEnd())
```
```text:実行結果
abcdefghij
klmnopqrst
uvwxyz
```

# ConcatStream

複数のストリームを結合して 1 つのストリームのように見せます。デフォルトでは渡されたストリームは読み終わった時点で閉じます。開いたままにするには `leaveOpen` を `true` に指定します。

```fsharp
open System
open System.IO

type ConcatStream(streams: Stream seq, leaveOpen: bool) =
    inherit Stream()
    let enumerator = streams.GetEnumerator()
    let mutable eos = not <| enumerator.MoveNext()
    let mutable position = 0L
    new(streams) = new ConcatStream(streams, false)
    override __.Dispose disposing =
        if not leaveOpen && disposing then
            while not eos do
                enumerator.Current.Dispose()
                eos <- not <| enumerator.MoveNext()
        base.Dispose disposing
    override __.CanRead  = true
    override __.CanWrite = false
    override __.CanSeek  = false
    override __.Length   = raise <| NotSupportedException()
    override __.Flush()  = raise <| NotSupportedException()
    override __.Position with get() = position
                         and  set _ = raise <| NotSupportedException()
    override __.Seek(_, _)     = raise <| NotSupportedException()
    override __.SetLength(_)   = raise <| NotSupportedException()
    override __.Write(_, _, _) = raise <| NotSupportedException()
    override __.Read(array, offset, count) =
        let mutable ret = 0
        while not eos && ret = 0 do
            ret <- enumerator.Current.Read(array, offset, count)
            if ret = 0 then
                if not leaveOpen then enumerator.Current.Dispose()
                eos <- not <| enumerator.MoveNext()
        position <- position + int64 ret
        ret

do
    use cs = new ConcatStream([
        new MemoryStream([|'0'B..'4'B|])
        new MemoryStream([|'A'B..'Z'B|])
        new MemoryStream([|'5'B..'9'B|])
    ])
    use sr = new StreamReader(cs)
    printfn "%s" (sr.ReadToEnd())
```
```text:実行結果
01234ABCDEFGHIJKLMNOPQRSTUVWXYZ56789
```

# 組み合わせ

両方を組み合わせた例です。

```fsharp
do
    use ms1 = new MemoryStream([|'A'B..'Z'B|])
    use ms2 = new MemoryStream([|'0'B..'4'B|])
    ms1.Position <- 10L
    use ss = new SubStream(ms1, 10)
    use cs = new ConcatStream([ss; ms2])
    use sr = new StreamReader(cs)
    printfn "%s" (sr.ReadToEnd())
```
```text:実行結果
KLMNOPQRST01234
```

# 関連記事

以下の記事で言及している処理のために調査しました。

* [Wiktionaryの全文処理をF#とPythonで速度比較](https://qiita.com/7shi/items/1d6b97c657c6fffdbd70)
