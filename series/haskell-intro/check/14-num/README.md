# Num の確認（記事「Num」の節）

GHC 9.6.6。GHCi での確認のみ（実行するコードはない）。

`:i Num` の実際の出力。記事では `-- Defined in` のコメントと
インスタンス一覧を `（略）` で省き、インスタンスは地の文で列挙した。

```
ghci> :i Num
type Num :: * -> Constraint
class Num a where
  (+) :: a -> a -> a
  (-) :: a -> a -> a
  (*) :: a -> a -> a
  negate :: a -> a
  abs :: a -> a
  signum :: a -> a
  fromInteger :: Integer -> a
  {-# MINIMAL (+), (*), abs, signum, fromInteger, (negate | (-)) #-}
  	-- Defined in ‘GHC.Num’
instance Num Double -- Defined in ‘GHC.Float’
instance Num Float -- Defined in ‘GHC.Float’
instance Num Int -- Defined in ‘GHC.Num’
instance Num Integer -- Defined in ‘GHC.Num’
instance Num Word -- Defined in ‘GHC.Num’
```

最小完全定義で `|` が付くのは `negate | (-)` だけ。`x - y = x + negate y`、
`negate x = fromInteger 0 - x` と互いのデフォルト実装になっている。
`14-exercises/Q3Vec.hs` で両方を省いたときに警告へ
`(either ‘negate’ or ‘-’)` が現れるのはこのため。

割り算は `Num` にはない。

```
ghci> :t (/)
(/) :: Fractional a => a -> a -> a
```

整数リテラルの型。

```
ghci> :t 1
1 :: Num a => a
```
