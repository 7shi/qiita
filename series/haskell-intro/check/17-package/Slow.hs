{-# LANGUAGE GADTs #-}
-- operational パッケージ版で左結合の >>= を計測する。
-- 自作版（check/17-program/Slow.hs）と違い、二乗にならないことの確認。
import Control.Monad.Operational
import Data.List (foldl')
import System.CPUTime
import System.IO
import Text.Printf

data GenI o a where
    Yield :: o -> GenI o ()

type Gen o = Program (GenI o)

yield :: o -> Gen o ()
yield x = singleton (Yield x)

toList :: Gen o a -> [o]
toList p = case view p of
    Return _       -> []
    Yield o :>>= k -> o : toList (k ())

bench :: String -> Int -> IO ()
bench mode n = do
    let prog = case mode of
            "right" -> foldr (\i r -> yield (i :: Int) >> r) (return ()) [1 .. n]
            _       -> foldl' (\r i -> r >> yield (i :: Int)) (return ()) [1 .. n]
    t0 <- getCPUTime
    len <- return $! length (toList prog)
    t1 <- len `seq` getCPUTime
    printf "%-6s %-7d %8.3f s\n" mode n (fromIntegral (t1 - t0) / 1e12 :: Double)

main :: IO ()
main = do
    hSetBuffering stdout LineBuffering
    mapM_ (\n -> mapM_ (\m -> bench m n) ["right", "left"])
          [50000, 100000, 200000, 400000]
