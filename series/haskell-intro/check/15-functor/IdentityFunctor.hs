-- 記事の Identity（Functor のみ。Applicative・Monad は後の節で書く）
newtype Identity a = Identity { runIdentity :: a }

instance Functor Identity where
    fmap f (Identity x) = Identity (f x)

main = print $ runIdentity (fmap (* 2) (Identity 3))
