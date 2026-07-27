---
coediting: false
comments_count: 0
created_at: '2020-02-16T02:37:35+09:00'
id: 0e2951155fd8949dbc55
likes_count: 6
private: false
reactions_count: 0
stocks_count: 2
tags:
- name: Haskell
  versions: []
- name: XorShift
  versions: []
title: Xorshiftを移植してみた
updated_at: '2020-02-17T14:58:27+09:00'
url: https://qiita.com/7shi/items/0e2951155fd8949dbc55
slide: false
---

JavaScript で実装した XorShift を Haskell に移植しました。[既存の実装](https://hackage.haskell.org/package/xorshift)は知っていますが、ライブラリが追加できない環境で手軽に使いたかったので移植しました。

オンラインで実行 ([Repl.it](https://repl.it/))

* https://repl.it/@7shi/Xorshift32

移植元

* [Xorshiftなどの擬似乱数をプロットして比較してみた](https://qiita.com/7shi/items/8219dcc22950253b26fb)

# Xorshift

Xorshift は実装が簡単な割に良好な擬似乱数を生成します。

* [Xorshift - Wikipedia](https://ja.wikipedia.org/wiki/Xorshift)
* [Google Chromeが採用した、擬似乱数生成アルゴリズム「xorshift」の数理 – びりあるの研究ノート](https://blog.visvirial.com/articles/575)

シード値を渡すと擬似乱数を返します。これは次のシード値として使います。

```haskell
import Data.Bits (xor, shiftL, shiftR)
import Data.Word (Word32)

getNext :: Word32 -> Word32
getNext seed = s3 where
  s1 = seed `xor` (shiftL seed 13)
  s2 = s1   `xor` (shiftR s1   17)
  s3 = s2   `xor` (shiftL s2    5)
```

シード値から一意に決まるため参照透過です。

# シード値

ナノ秒単位で現在時刻を取り出してシード値を作ります。シード値 0 からは 0 しか得られないため、32bit 化して 0 になった場合はやり直します。

```haskell
import Data.Time.Clock.POSIX (getPOSIXTime)

getSeed :: IO Word32
getSeed = do
  t <- getPOSIXTime
  let ret = floor $ t * 1e9 :: Word32
  if ret == 0 then getSeed else return ret
```

現在時刻は毎回異なり参照透過ではないため IO モナドです。

# 浮動小数点数化

得られた擬似乱数を 0 以上 1 未満の浮動小数点数に加工します。

```haskell
word32MaxNext :: Num a => a
word32MaxNext = 2 ^ 32

getFloat :: Fractional a => Word32 -> a
getFloat w32 = (fromIntegral w32) / word32MaxNext
```

※ `fromIntegral` で型変換してから割り算します。

# ラップ

IO モナドの中で簡単に使えるように、シード値の初期化から一連の流れをラップします。

```haskell
import Data.IORef (newIORef, readIORef, writeIORef)

rand :: Fractional a => Word32 -> IO (IO a)
rand seed = do
  s <- newIORef seed
  return $ do
    oldSeed <- readIORef s
    let newSeed = getNext oldSeed
    writeIORef s newSeed
    return $ getFloat newSeed
```
```text:実行例
> rnd <- rand =<< getSeed
> rnd
=> 0.15449975966475904
> rnd
=> 0.31265981029719114
> rnd
=> 0.979753604857251   
```

[オンライン実行環境](https://repl.it/@7shi/Xorshift32)では [run ▶] で実行した後に、REPL で上記の実行例が試せます。

# テスト

10 回のループで値を確認します。

```haskell
import Control.Monad (sequence_)

main :: IO ()
main = do
  rnd <- rand =<< getSeed
  sequence_ $ replicate 10 $ print =<< rnd
```
```text:実行例
0.7494283774867654
0.19796228897757828
0.4463836853392422
0.19902197853662074
0.39511674898676574
0.46158441342413425
0.4156568821053952
0.8667732949834317
0.5666300777811557
0.7868200021330267
```

※ シード値は現在時刻に依存するため、実行結果は毎回異なります。

# 経緯

Repl.it はオンライン開発環境としては割と使い勝手が良さそうでしたが、Haskell ではライブラリの追加がサポートされていないようです。

* [Repl.it - How to import library files?](https://repl.it/talk/ask/How-to-import-library-files/15088)

※ Python のサポートは手厚く `import` するだけで自動的に追加されます。

乱数が必要な用途で使おうとして困りました。仮に JavaScript で実装を始めましたが、標準の乱数ではシード値を設定することができなかったため、自前で Xorshift を用意する羽目になりました。自前で用意するなら Haskell だって一緒だと思い、移植しました。

# 参考

IO モナドの基本的な使い方は以下を参照してください。

* [Haskell アクション 超入門](https://qiita.com/7shi/items/85afd7bbd5d6c4115ad6)
