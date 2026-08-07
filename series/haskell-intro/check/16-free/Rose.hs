-- 本文「木を一般化する」の Free [] 版
import Control.Monad (liftM, ap)

data Free f a = Pure a | Free (f (Free f a))

instance Functor f => Functor (Free f) where
    fmap = liftM

instance Functor f => Applicative (Free f) where
    pure  = Pure
    (<*>) = ap

instance Functor f => Monad (Free f) where
    Pure a >>= k = k a
    Free g >>= k = Free (fmap (>>= k) g)

type Rose = Free []

toList :: Rose a -> [a]
toList (Pure a)  = [a]
toList (Free ts) = concatMap toList ts

grow x = Free [Pure x, Pure (x * 10)]

main = do
    let r = Free [Pure 1, Free [Pure 2, Pure 3]]
    print $ toList r
    print $ toList $ r >>= grow
