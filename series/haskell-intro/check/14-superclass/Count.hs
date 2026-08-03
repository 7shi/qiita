newtype Count = Count Int deriving Show

instance Semigroup Count where
    Count a <> Count b = Count (a + b)

instance Monoid Count where
    mempty = Count 0

main = do
    print $ Count 1 <> Count 2
    print $ (mempty :: Count)
    print $ mconcat [Count 1, Count 2, Count 3]
    print $ "abc" <> "def"
    print $ [1,2] <> [3 :: Int]
