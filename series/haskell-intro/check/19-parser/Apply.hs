-- ArrowApply を P に持たせるとどうなるかの実験。
-- app は実行時に受け取ったパーサを走らせるので静的な情報を先に言えず、
-- 空にするしかない。その結果 expects が嘘になる。
-- runghc Apply.hs
import Control.Arrow
import Control.Category
import Prelude hiding ((.), id)

newtype P b c = P (String, String -> b -> Maybe (c, String))

instance Category P where
    id = P ([], \s b -> Just (b, s))
    P (t2, g) . P (t1, f) = P (t1 ++ t2, \s b -> f s b >>= \(x, s') -> g s' x)

instance Arrow P where
    arr f = P ([], \s b -> Just (f b, s))
    first (P (t, f)) = P (t, \s (b, d) -> fmap (\(c, s') -> ((c, d), s')) (f s b))

instance ArrowApply P where
    app = P ([], \s (P (_, f), b) -> f s b)

char :: Char -> P String String
char c = P ([c], \s i -> case s of
    (x:xs) | x == c -> Just (i ++ [x], xs)
    _               -> Nothing)

expects :: P b c -> String
expects (P (t, _)) = t

runP :: P b c -> String -> b -> Maybe (c, String)
runP (P (_, f)) s b = f s b

choose :: P Bool String
choose = arr (\flag -> (if flag then char 'a' else char 'b', "")) >>> app

main :: IO ()
main = do
    print $ expects choose
    print $ runP choose "ab" True
    print $ runP choose "ba" True
