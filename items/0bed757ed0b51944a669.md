---
coediting: false
comments_count: 3
created_at: '2014-09-19T22:09:54+09:00'
id: 0bed757ed0b51944a669
likes_count: 4
private: false
reactions_count: 0
stocks_count: 3
tags:
- name: Haskell
  versions: []
title: 【解答例】Haskell 代数的データ型 超入門
updated_at: '2015-04-26T19:21:58+09:00'
url: https://qiita.com/7shi/items/0bed757ed0b51944a669
slide: false
---

[Haskell 代数的データ型 超入門](http://qiita.com/7shi/items/1ce76bde464b4a55c143)の解答例です。

# 列挙型

【問1】光の三原色と、2つの色を混合する関数`mix`を定義してください。混ぜることによってできる色も定義の対象とします。ただし同じ成分同士は強め合わないものとします。

条件を列挙します。逆の組み合わせを一括処理しているのがポイントです。

```hs
data Color = Blue | Red | Magenta | Green | Cyan | Yellow | White
    deriving (Show, Eq)

mix Blue    Red       = Magenta
mix Blue    Magenta   = Magenta
mix Blue    Green     = Cyan
mix Blue    Cyan      = Cyan
mix Blue    Yellow    = White
mix Red     Magenta   = Magenta
mix Red     Green     = Yellow
mix Red     Cyan      = White
mix Red     Yellow    = Yellow
mix Magenta Green     = White
mix Magenta Cyan      = White
mix Magenta Yellow    = White
mix Green   Cyan      = Cyan
mix Green   Yellow    = Yellow
mix Cyan    Yellow    = White
mix White   _         = White
mix c1 c2 | c1 == c2  = c1
          | otherwise = mix c2 c1

main = do
    print $ mix Blue Blue
    print $ mix Red Blue
    print $ mix Red $ mix Blue Green
```
```text:実行結果
Blue
Magenta
White
```

## 別解

ビット演算で簡単に書けます。

```hs
import Data.Bits

data Color = Black | Blue | Red | Magenta | Green | Cyan | Yellow | White
    deriving (Show, Enum)

mix c1 c2 = toEnum (fromEnum c1 .|. fromEnum c2) :: Color

main = do
    print $ mix Red Blue
    print $ mix Red $ mix Blue Green
```
```text:実行結果
Magenta
White
```

# 直積型

【問2】x,y,w,hを表現した`Rect`型を定義して、`Rect`に`Point`が含まれるかどうかを判定する関数`contains`を実装してください。

```hs
data Point = Point Int Int deriving Show
data Rect = Rect Int Int Int Int deriving Show

contains (Rect x y w h) (Point px py) =
    x <= px && px < x + w && y <= py && py < y + h

main = do
    print $ contains (Rect 2 2 3 3) (Point 1 1)
    print $ contains (Rect 2 2 3 3) (Point 2 2)
    print $ contains (Rect 2 2 3 3) (Point 3 3)
    print $ contains (Rect 2 2 3 3) (Point 4 4)
    print $ contains (Rect 2 2 3 3) (Point 5 5)
```
```text:実行結果
False
True
True
True
False
```

# 直和型

【問3】`Rect`と`Point`を2次元と3次元の両方に対応させて、問2の`contains`も対応させてください。

```hs
data Point = Point   Int Int
           | Point3D Int Int Int
           deriving Show

data Rect = Rect   Int Int Int Int
          | Rect3D Int Int Int Int Int Int
          deriving Show

contains (Rect x y w h) (Point px py) =
    x <= px && px < x + w && y <= py && py < y + h

contains (Rect3D x y z w h d) (Point3D px py pz) =
    x <= px && px < x + w &&
    y <= py && py < y + h &&
    z <= pz && pz < z + d

main = do
    print $ contains (Rect 2 2 3 3) (Point 1 1)
    print $ contains (Rect 2 2 3 3) (Point 2 2)
    print $ contains (Rect 2 2 3 3) (Point 3 3)
    print $ contains (Rect 2 2 3 3) (Point 4 4)
    print $ contains (Rect 2 2 3 3) (Point 5 5)
    print $ contains (Rect3D 2 2 2 3 3 3) (Point3D 1 1 1)
    print $ contains (Rect3D 2 2 2 3 3 3) (Point3D 2 2 2)
    print $ contains (Rect3D 2 2 2 3 3 3) (Point3D 3 3 3)
    print $ contains (Rect3D 2 2 2 3 3 3) (Point3D 4 4 4)
    print $ contains (Rect3D 2 2 2 3 3 3) (Point3D 5 5 5)
```
```text:実行結果
False
True
True
True
False
False
True
True
True
False
```

# レコード構文

【問4】問2の解答をレコード構文で書き直してください。

```hs
data Point = Point { px :: Int, py :: Int } deriving Show
data Rect  = Rect  { rx :: Int, ry :: Int, rw :: Int, rh :: Int } deriving Show

contains r p =
    (rx r) <= (px p) && (px p) < (rx r) + (rw r) &&
    (ry r) <= (py p) && (py p) < (ry r) + (rh r)

main = do
    print $ contains Rect { rx = 2, ry = 2, rw = 3, rh = 3 } Point { px = 1, py = 1 }
    print $ contains Rect { rx = 2, ry = 2, rw = 3, rh = 3 } Point { px = 2, py = 2 }
    print $ contains Rect { rx = 2, ry = 2, rw = 3, rh = 3 } Point { px = 3, py = 3 }
    print $ contains Rect { rx = 2, ry = 2, rw = 3, rh = 3 } Point { px = 4, py = 4 }
    print $ contains Rect { rx = 2, ry = 2, rw = 3, rh = 3 } Point { px = 5, py = 5 }
```
```text:実行結果
False
True
True
True
False
```
