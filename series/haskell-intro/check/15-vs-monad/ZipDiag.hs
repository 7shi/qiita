import Control.Monad (ap)

newtype ZipList a = ZipList { getZipList :: [a] } deriving Show

instance Functor ZipList where
    fmap f (ZipList xs) = ZipList (map f xs)

instance Applicative ZipList where
    pure = ZipList . repeat
    ZipList fs <*> ZipList xs = ZipList (zipWith ($) fs xs)

-- i 番目の要素には f の結果の i 番目を使う
instance Monad ZipList where
    ZipList xs >>= f = ZipList (go 0 xs)
      where
        go i (x:rest) = case drop i (getZipList (f x)) of
            (y:_) -> y : go (i + 1) rest
            []    -> []
        go _ [] = []

main = do
    print $ ((,) <$> ZipList [1, 2]) <*>  ZipList [10, 20]
    print $ ((,) <$> ZipList [1, 2]) `ap` ZipList [10, 20]
