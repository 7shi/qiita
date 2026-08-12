-- arr で純粋な関数を Kleisli のパイプラインに混ぜる。
-- runghc Count.hs
import Control.Arrow
import Control.Monad ((>=>))

count :: String -> Kleisli IO FilePath ()
count w = Kleisli readFile
      >>> arr words
      >>> arr (filter (== w))
      >>> arr (show . length)
      >>> Kleisli putStrLn

countM :: String -> FilePath -> IO ()
countM w = readFile
       >=> return . words
       >=> return . filter (== w)
       >=> return . (show . length)
       >=> putStrLn

main :: IO ()
main = do
    runKleisli (count "the") "test.txt"
    countM "the" "test.txt"
