---
coediting: false
comments_count: 0
created_at: '2014-10-09T12:22:45+09:00'
id: 623fd55b8b68398becdc
likes_count: 5
private: false
reactions_count: 0
stocks_count: 5
tags:
- name: Haskell
  versions: []
title: 【解答例】Haskell アクション 超入門
updated_at: '2020-02-12T21:38:36+09:00'
url: https://qiita.com/7shi/items/623fd55b8b68398becdc
slide: false
---

[Haskell アクション 超入門](http://qiita.com/7shi/items/85afd7bbd5d6c4115ad6)の解答例です。

# ランダム表示

【問1】ランダムにアルファベット小文字の1文字表示を繰り返してください。`'z'`が現れたら`"END"`と表示して終了してください。

```hs
import System.Random

randAlpha = randomRIO ('a', 'z')

main = do
    r <- randAlpha
    print r
    if r == 'z' then print "END" else main
```
```text:実行結果（毎回異なる）
'j'
'm'
'z'
"END"
```

# 階乗

【問2】階乗を求める関数`fact`を、アクションを返す関数に書き換えてください。

```hs
fact 0 = return 1
fact n | n > 0 = do
    n' <- fact (n - 1)
    return $ n * n'

main = do
    print =<< fact 5
```
```text:実行結果
120
```

# シャッフル

【問3】リストをランダムに並べ替える関数`shuffle`を実装してください。

```hs
import System.Random

shuffle [] = return []
shuffle xs = do
    n <- randomRIO (0, length xs - 1) :: IO Int
    xs' <- shuffle $ take n xs ++ drop (n + 1) xs
    return $ (xs !! n) : xs'

main = do
    print =<< shuffle [1..9]
```
```text:実行結果（毎回異なる）
[3,5,4,9,2,7,8,6,1]
```

# ボゴソート

【問4】[ボゴソート](http://ja.wikipedia.org/wiki/%E3%83%9C%E3%82%B4%E3%82%BD%E3%83%BC%E3%83%88)を実装してください。

```hs
import System.Random

shuffle [] = return []
shuffle xs = do
    n <- randomRIO (0, length xs - 1) :: IO Int
    xs' <- shuffle $ take n xs ++ drop (n + 1) xs
    return $ (xs !! n) : xs'

isSorted []  = True
isSorted [_] = True
isSorted (x:y:zs)
    | x > y     = False
    | otherwise = isSorted (y:zs)

bogosort xs = do
    xs' <- shuffle xs
    if isSorted xs' then return xs' else bogosort xs

main = do
    xs <- shuffle [1..9]
    print xs
    print =<< bogosort xs
```
```text:実行結果（毎回異なる）
[7,1,9,4,2,8,5,3,6]
[1,2,3,4,5,6,7,8,9]
```

# 暗黙の取り出し

【問5】1～6の乱数を表示して返すアクションにより、暗黙の取り出しで値が捨てられていることを確認してください。

```hs
import System.Random

dice :: IO Int
dice = randomRIO (1, 6)

showDice = do
    ret <- dice
    print ret
    return ret

main = do
    showDice
    showDice
    print =<< showDice
```
```text:実行結果（毎回異なる）
5
2
6
6
```

# Applicativeスタイル

【問6】Applicativeスタイルを使って、次のコードから`<-`を排除してください。

```hs
import Control.Applicative

fib 0 = return 0
fib 1 = return 1
fib n | n > 1 =
    (+) <$> fib (n - 2) <*> fib (n - 1)

main = do
    print =<< fib 6
```
```text:実行結果
8
```

# クイックソート

【問7】次のクイックソートの途中経過を`trace`ではなく`putStrLn`で表示するように修正してください。

```hs
qsort []     = return []
qsort (n:xs) = do
    let lt   = [x | x <- xs, x <  n]
        gteq = [x | x <- xs, x >= n]
    putStrLn $ "qsort " ++ show (n:xs) ++ " = qsort " ++
               show lt ++ " ++ " ++ show [n] ++ " ++ " ++ show gteq
    lt'   <- qsort lt
    gteq' <- qsort gteq
    return $ lt' ++ [n] ++ gteq'

main = do
    print =<< qsort [4, 6, 9, 8, 3, 5, 1, 7, 2]
```
```text:実行結果
qsort [4,6,9,8,3,5,1,7,2] = qsort [3,1,2] ++ [4] ++ [6,9,8,5,7]
qsort [3,1,2] = qsort [1,2] ++ [3] ++ []
qsort [1,2] = qsort [] ++ [1] ++ [2]
qsort [2] = qsort [] ++ [2] ++ []
qsort [6,9,8,5,7] = qsort [5] ++ [6] ++ [9,8,7]
qsort [5] = qsort [] ++ [5] ++ []
qsort [9,8,7] = qsort [8,7] ++ [9] ++ []
qsort [8,7] = qsort [7] ++ [8] ++ []
qsort [7] = qsort [] ++ [7] ++ []
[1,2,3,4,5,6,7,8,9]
```

# カウンター

【問8】次のJavaScriptでよく見掛けるサンプルコードを移植してください。

```hs
import Data.IORef

counter = do
    c <- newIORef 0
    return $ do
        tmp <- readIORef c
        writeIORef c $ tmp + 1
        readIORef c

main = do
    f <- counter
    print =<< f
    print =<< f
    print =<< f
```
```text:実行結果
1
2
3
```

# ループ

【問9】次のJavaScriptのコードを移植してください。`s`だけ`IORef`を使ってください。

```hs
import Data.IORef

main = do
    s <- newIORef 0
    let loop i | i <= 100 = do
            s' <- readIORef s
            writeIORef s $ s' + i
            loop $ i + 1
        loop _ = return ()
    loop 1
    print =<< readIORef s
```
```text:実行結果
5050
```

【問10】問9のコードから`IORef`を排除してください。`sum`は使わないでください。

```hs
main = do
    let loop i s | i <= 100 = loop (i + 1) (s + i)
        loop _ s = s
    print $ loop 1 0
```
```text:実行結果
5050
```

# Brainf*ck

【問11】次のJavaScriptで実装された[Brainf*ck](http://ja.wikipedia.org/wiki/Brainfuck)インタプリタを移植してください。

効率は無視してなるべく同じ構造で移植した例です。

```hs
import Data.Array.IO
import Data.Char
import Data.Word

bf = ">+++++++++[<++++++++>-]<.>+++++++[<++++>" ++
     "-]<+.+++++++..+++.[-]>++++++++[<++++>-]<" ++
     ".>+++++++++++[<+++++>-]<.>++++++++[<+++>" ++
     "-]<.+++.------.--------.[-]>++++++++[<++" ++
     "++>-]<+.[-]++++++++++."

main = do
    let lenbf = length bf
    jmp <- newArray (0, lenbf - 1) 0 :: IO (IOUArray Int Int)
    let loop i loops | i < lenbf = case bf !! i of
            '[' -> loop (i + 1) (i:loops)
            ']' -> do
                let (start:loops') = loops
                writeArray jmp start i
                writeArray jmp i start
                loop (i + 1) loops'
            _ -> loop (i + 1) loops
        loop _ _ = return ()
    loop 0 []
    m <- newArray (0, 29999) 0 :: IO (IOUArray Int Word8)
    let loop pc r | pc < lenbf = case bf !! pc of
            '+' -> do
                v <- readArray m r
                writeArray m r (v + 1)
                loop (pc + 1) r
            '-' -> do
                v <- readArray m r
                writeArray m r (v - 1)
                loop (pc + 1) r
            '>' -> loop (pc + 1) (r + 1)
            '<' -> loop (pc + 1) (r - 1)
            '.' -> do
                v <- readArray m r
                putChar $ chr $ fromIntegral v
                loop (pc + 1) r
            '[' -> do
                v <- readArray m r
                if v == 0
                    then do
                        pc' <- readArray jmp pc
                        loop (pc' + 1) r
                    else
                        loop (pc + 1) r
            ']' -> do
                v <- readArray m r
                if v /= 0
                    then do
                        pc' <- readArray jmp pc
                        loop pc' r
                    else
                        loop (pc + 1) r
            _ -> loop (pc + 1) r
        loop _ _ = return ()
    loop 0 0
```
```text:実行結果
Hello World!
```

## リスト化

IOUArrayをやめてリストで作り直すと`do`や`<-`がなくなり短くなります。ただしメモリに書き込むたびにリストを作り直しているため効率は悪化します。

```hs
import Data.Array.IO
import Data.Char
import Data.Word

bf = ">+++++++++[<++++++++>-]<.>+++++++[<++++>" ++
     "-]<+.+++++++..+++.[-]>++++++++[<++++>-]<" ++
     ".>+++++++++++[<+++++>-]<.>++++++++[<+++>" ++
     "-]<.+++.------.--------.[-]>++++++++[<++" ++
     "++>-]<+.[-]++++++++++."

search i | i < lenbf = case bf !! i of
    ']' -> []
    '[' -> (i':jmp) ++ search (i' + 1) where
        jmp = (search (i + 1)) ++ [i]
        len = length jmp
        i'  = i + len
    _ -> 0 : search (i + 1)
search _ = []

loop m pc r | pc < lenbf = case bf !! pc of
    '+' -> loop m' (pc + 1) r where
        m' = take r m ++ [(m !! r) + 1] ++ drop (r + 1) m
    '-' -> loop m' (pc + 1) r where
        m' = take r m ++ [(m !! r) - 1] ++ drop (r + 1) m
    '>' -> loop m (pc + 1) (r + 1)
    '<' -> loop m (pc + 1) (r - 1)
    '.' -> (chr $ fromIntegral $ m !! r) : loop m (pc + 1) r
    '[' | m !! r == 0 -> loop m ((jmp !! pc) + 1) r
        | otherwise   -> loop m (pc + 1) r
    ']' | m !! r /= 0 -> loop m (jmp !! pc) r
        | otherwise   -> loop m (pc + 1) r
    _ -> loop m (pc + 1) r
loop _ _ _ = ""

lenbf = length bf
jmp   = search 0
m     = replicate 30000 0 :: [Word8]
main  = putStr $ loop m 0 0
```
```text:実行結果
Hello World!
```

これ以上改造するには大幅に作り変えるしかなさそうです。

※ [検索すれば](https://www.google.co.jp/search?q=haskell+brainfuck)、ここに示したコードとはまったく異なる実装が色々出て来ます。

# トレース

【問12】`unsafePerformIO`と`putStrLn`を使って、`trace`の標準出力版関数`trace'`を実装してください。

【注】ghciでは挙動が変わります。解答例はコンパイルしたときにのみ正常動作します。

```hs
import System.IO.Unsafe

trace' s x = unsafePerformIO $ do
    putStrLn s
    return x

fact 0 = trace' "fact 0 = 1" 1
fact n | n > 0 = trace' dbg0 $ trace' dbg1 ret
    where
        ret  = n * fn1
        fn1  = fact $ n - 1
        dbg0 = "fact " ++ show n ++ " = " ++
               show n ++ " * fact " ++ show (n - 1)
        dbg1 = dbg0 ++ " = " ++
               show n ++ " * " ++ show fn1 ++ " = " ++ show ret

main = do
    print $ fact 5
```
```text:実行結果
fact 5 = 5 * fact 4
fact 4 = 4 * fact 3
fact 3 = 3 * fact 2
fact 2 = 2 * fact 1
fact 1 = 1 * fact 0
fact 0 = 1
fact 1 = 1 * fact 0 = 1 * 1 = 1
fact 2 = 2 * fact 1 = 2 * 1 = 2
fact 3 = 3 * fact 2 = 3 * 2 = 6
fact 4 = 4 * fact 3 = 4 * 6 = 24
fact 5 = 5 * fact 4 = 5 * 24 = 120
120
```
