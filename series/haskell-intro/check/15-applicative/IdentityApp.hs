-- Applicative の導入（Identity で 2 引数の関数を持ち上げる）
newtype Identity a = Identity { runIdentity :: a }

instance Functor Identity where
    fmap f (Identity x) = Identity (f x)

instance Applicative Identity where
    pure = Identity
    Identity f <*> Identity x = Identity (f x)

main = print $ runIdentity ((+) <$> Identity 1 <*> Identity 2)
