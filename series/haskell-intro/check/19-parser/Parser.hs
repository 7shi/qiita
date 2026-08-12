{-# LANGUAGE Arrows #-}
-- 静的パーサ。合成した時点で「受け付ける文字」が確定する。
-- 練習【問3】の解答例（string）と分岐（ab・ab2）を含む。
-- runghc Parser.hs
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

instance ArrowChoice P where
    left (P (t, f)) = P (t, \s e -> case e of
        Left  b -> fmap (\(c, s') -> (Left c, s')) (f s b)
        Right d -> Just (Right d, s))
    P (t1, f) ||| P (t2, g) = P ("(" ++ t1 ++ "|" ++ t2 ++ ")", \s e -> case e of
        Left  b -> f s b
        Right c -> g s c)

char :: Char -> P String String
char c = P ([c], \s i -> case s of
    (x:xs) | x == c -> Just (i ++ [x], xs)
    _               -> Nothing)

expects :: P b c -> String
expects (P (t, _)) = t

runP :: P b c -> String -> b -> Maybe (c, String)
runP (P (_, f)) s b = f s b

abc :: P String String
abc = char 'a' >>> char 'b' >>> char 'c'

string :: String -> P String String
string s = foldr (>>>) id (map char s)

ab :: P Bool String
ab = proc flag -> if flag then char 'a' -< "" else char 'b' -< ""

ab2 :: P (Either String String) String
ab2 = char 'a' ||| char 'b'

main :: IO ()
main = do
    print $ expects abc
    print $ runP abc "abcd" ""
    print $ runP abc "abd" ""
    print $ expects (string "abc")
    print $ runP (string "abc") "abcd" ""
    print $ expects ab
    print $ runP ab "ab" True
    print $ runP ab "ab" False
    print $ expects ab2
    print $ runP ab2 "ab" (Left "")
    print $ runP ab2 "ab" (Right "")
