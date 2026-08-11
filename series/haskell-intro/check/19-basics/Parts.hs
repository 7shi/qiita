-- アローの部品。関数アロー（(->)）で arr・&&&・***・first・second を動かす。
-- runghc Parts.hs
import Control.Arrow

main :: IO ()
main = do
    print $ ((+ 1) &&& (* 2)) (3 :: Int)
    print $ ((+ 1) *** show) (3 :: Int, 4 :: Int)
    print $ first  (+ 1) (1 :: Int, "x")
    print $ second (+ 1) ("x", 1 :: Int)
    print $ arr (+ 1) (1 :: Int)
