-- ZipList.hs の定義が Applicative 則を満たすことの確認
newtype ZipList a = ZipList { getZipList :: [a] } deriving Show

instance Functor ZipList where
    fmap f (ZipList xs) = ZipList (map f xs)

instance Applicative ZipList where
    pure = ZipList . repeat
    ZipList fs <*> ZipList xs = ZipList (zipWith ($) fs xs)

main = do
    print $ getZipList $ (+) <$> ZipList [1, 2, 3] <*> ZipList [10, 20, 30]
    -- Applicative 則（恒等・準同型・交換・fmap との整合）
    -- 恒等則。pure が無限リストなので結果は u の長さで打ち切られ、u と一致する
    print $ getZipList (pure id <*> u) == getZipList u
    -- pure を有限リストにすると恒等則が破れる
    print $ getZipList (ZipList [id] <*> u) == getZipList u
    print $ take 3 (getZipList (pure (+ 1) <*> pure 1)) == take 3 (getZipList (pure (2 :: Int)))
    print $ take 3 (getZipList (pure ($ 1) <*> pure (+ 1))) == take 3 (getZipList (pure (2 :: Int)))
    print $ getZipList ((+ 1) <$> u) == getZipList (pure (+ 1) <*> u)
  where
    u = ZipList [1, 2, 3 :: Int]
