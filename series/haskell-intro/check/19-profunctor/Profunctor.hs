import Control.Arrow
import Data.Profunctor

main :: IO ()
main = do
    print $ first  (+ 1) (1 :: Int, "a")
    print $ first' (+ 1) (1 :: Int, "a")
    print $ left   (+ 1) (Left  1 :: Either Int String)
    print $ left'  (+ 1) (Left  1 :: Either Int String)
    print $ dimap read show ((+ 1) :: Int -> Int) "1"
