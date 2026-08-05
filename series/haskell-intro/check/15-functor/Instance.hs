-- 記事の instance Functor Maybe は標準ライブラリの定義のため再定義できない。
-- 同じ形が成立することを、名前を変えた型で確認する。
data Maybe' a = Just' a | Nothing' deriving Show

instance Functor Maybe' where
    fmap f (Just' x) = Just' (f x)
    fmap _ Nothing'  = Nothing'

main = do
    print $ fmap (* 2) (Just' 3)
    print $ fmap (* 2) (Nothing' :: Maybe' Int)
