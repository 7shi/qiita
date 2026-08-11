-- 練習【問4】の解答例。Kleisli のパイプラインと app。
-- runghc Kleisli.hs
import Control.Arrow

parse :: String -> Maybe Int
parse s = if not (null s) && all (`elem` "0123456789") s
          then Just (read s) else Nothing

half :: Int -> Maybe Int
half n = if even n then Just (n `div` 2) else Nothing

pipeline :: Kleisli Maybe String Int
pipeline = Kleisli parse >>> Kleisli half >>> arr (* 10)

choose :: Kleisli Maybe Int Int
choose = arr (\n -> (if n > 0 then Kleisli half else arr negate, n)) >>> app

main :: IO ()
main = do
    print $ runKleisli pipeline "10"
    print $ runKleisli pipeline "7"
    print $ runKleisli choose 8
    print $ runKleisli choose (-8)
    print $ runKleisli choose 7
