-- Functor 則を破るインスタンスも型は通り、コンパイラは検査しないことの確認。
-- 記事の instance Functor Maybe は再定義できないため、型名を変えている。
data Maybe' a = Just' a | Nothing' deriving Show

instance Functor Maybe' where
    fmap _ (Just' _) = Nothing'
    fmap _ Nothing'  = Nothing'

main = print $ fmap id (Just' 1)  -- fmap id == id を破る
