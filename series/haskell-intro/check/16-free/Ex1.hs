-- 【問1】15 回の Tree と Free Two が同じ結果になることの確認
import Control.Monad (liftM, ap)

-- 15 回の Tree
data Tree a = Leaf a | Node (Tree a) (Tree a) deriving Show

instance Functor Tree where
    fmap  = liftM

instance Applicative Tree where
    pure  = Leaf
    (<*>) = ap

instance Monad Tree where
    Leaf x   >>= f = f x
    Node l r >>= f = Node (l >>= f) (r >>= f)

grow :: Int -> Tree Int
grow x = Node (Leaf x) (Leaf (x * 10))

-- Free Two
data Two x = Two x x

instance Functor Two where
    fmap f (Two l r) = Two (f l) (f r)

data Free f a = Pure a | Free (f (Free f a))

instance Functor f => Functor (Free f) where
    fmap = liftM

instance Functor f => Applicative (Free f) where
    pure  = Pure
    (<*>) = ap

instance Functor f => Monad (Free f) where
    Pure a >>= k = k a
    Free g >>= k = Free (fmap (>>= k) g)

grow' :: Int -> Free Two Int
grow' x = Free (Two (Pure x) (Pure (x * 10)))

-- Free Two を Tree に写して見比べる
toTree :: Free Two a -> Tree a
toTree (Pure a)         = Leaf a
toTree (Free (Two l r)) = Node (toTree l) (toTree r)

main :: IO ()
main = do
    let t  = Node (Leaf 1) (Leaf 2)
        t' = Free (Two (Pure 1) (Pure 2))
    print $ t  >>= grow
    print $ toTree $ t' >>= grow'
    print $ fmap (* 2) t
    print $ toTree $ fmap (* 2) t'
