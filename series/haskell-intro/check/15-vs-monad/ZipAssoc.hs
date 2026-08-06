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

-- 上の定義に続けて

m = ZipList [1, 2]

f 1 = ZipList [1, 1]
f 2 = ZipList [9, 2]

g 9 = ZipList []
g v = ZipList [v * 100, v * 100 + 1]

main = do
    print $ m >>= f
    print $ (m >>= f) >>= g
    print $ m >>= (\x -> f x >>= g)
    -- 単位元則は成り立つ
    print $ getZipList (return 1 >>= f) == getZipList (f 1)
    print $ getZipList (m >>= return)   == getZipList m
