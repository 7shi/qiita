data Pair a = Pair a a deriving Show

instance Functor Pair where
    fmap f (Pair x y) = Pair (f x) (f y)

instance Applicative Pair where
    pure x = Pair x x
    Pair f g <*> Pair x y = Pair (f x) (g y)

main = do
    print $ (+) <$> Pair 1 2 <*> Pair 10 20
    print (pure 0 :: Pair Int)
