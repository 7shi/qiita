data Pair a = Pair a a deriving Show

instance Functor Pair where
    fmap f (Pair x y) = Pair (f x) (f y)

main = do
    print $ fmap (* 2) (Pair 1 2)
    print $ show <$> Pair 1 2
