newtype Identity a = Identity { runIdentity :: a }

instance Functor Identity where
    fmap f (Identity x) = Identity (f x)

instance Applicative Identity where
    pure = Identity
    Identity f <*> Identity x = Identity (f x)

instance Monad Identity where
    Identity x >>= f = f x

calc = do
    x <- return 3
    return (x * 2)

main = do
    print $ runIdentity (fmap (* 2) (Identity 3))
    print $ runIdentity ((+) <$> Identity 1 <*> Identity 2)
    print $ runIdentity calc
