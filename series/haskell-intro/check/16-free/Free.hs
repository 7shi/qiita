-- 本文「木を一般化する」の掲載コード
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

data Two x = Two x x

instance Functor Two where
    fmap f (Two l r) = Two (f l) (f r)

type Tree = Free Two

instance Show a => Show (Tree a) where
    show (Pure a)         = show a
    show (Free (Two l r)) = "(" ++ show l ++ " " ++ show r ++ ")"

leaf :: a -> Tree a
leaf = Pure

node :: Tree a -> Tree a -> Tree a
node l r = Free (Two l r)

grow x = node (leaf x) (leaf (x * 10))

main = do
    let t = node (leaf 1) (leaf 2)
    print t
    print $ fmap (* 2) t
    print $ t >>= grow
