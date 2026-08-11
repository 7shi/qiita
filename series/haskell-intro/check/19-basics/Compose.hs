-- 関数合成の一般化。`.` と >>>、Kleisli の >>> と >=> の一致。
-- runghc Compose.hs
import Control.Arrow
import Control.Monad ((>=>))

f, g :: Int -> Int
f x = x + 1
g x = x * 2

parse :: String -> Maybe Int
parse s = if not (null s) && all (`elem` "0123456789") s
          then Just (read s) else Nothing

half :: Int -> Maybe Int
half n = if even n then Just (n `div` 2) else Nothing

main :: IO ()
main = do
    print $ (f . g) 1
    print $ (g >>> f) 1
    print $ (parse >=> half) "10"
    print $ runKleisli (Kleisli parse >>> Kleisli half) "10"
    print $ (parse >=> half) "7"
    print $ runKleisli (Kleisli parse >>> Kleisli half) "7"
