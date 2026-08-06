-- base の ZipList を写したもの（import Control.Applicative でも使える）
newtype ZipList a = ZipList { getZipList :: [a] } deriving Show

instance Functor ZipList where
    fmap f (ZipList xs) = ZipList (map f xs)

instance Applicative ZipList where
    pure = ZipList . repeat
    ZipList fs <*> ZipList xs = ZipList (zipWith ($) fs xs)

main = do
    print $ (+) <$> [1, 2, 3] <*> [10, 20, 30]
    print $ (+) <$> ZipList [1, 2, 3] <*> ZipList [10, 20, 30]
    print $ zipWith (+) [1, 2, 3] [10, 20, 30]
    print $ (+) <$> pure 100 <*> ZipList [10, 20, 30]
    print $ take 3 $ getZipList (pure 0)
