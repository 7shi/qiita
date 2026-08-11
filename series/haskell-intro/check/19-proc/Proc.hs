{-# LANGUAGE Arrows #-}
-- proc 記法。Mean.hs と同じ計算を proc で書く（本文と練習【問2】の解答例）。
-- runghc Proc.hs
import Control.Arrow

mean :: [Double] -> Double
mean = proc xs -> do
    s <- sum -< xs
    n <- length -< xs
    returnA -< s / fromIntegral n

spread :: [Int] -> Int
spread = proc xs -> do
    mx <- maximum -< xs
    mn <- minimum -< xs
    returnA -< mx - mn

main :: IO ()
main = do
    print $ mean [1, 2, 3, 4]
    print $ spread [3, 1, 4, 1, 5]
