import Control.Monad (liftM, ap)

data Tree a = Leaf a | Node (Tree a) (Tree a) deriving Show

instance Functor     Tree where fmap  = liftM
instance Applicative Tree where pure  = Leaf
                                (<*>) = ap
instance Monad       Tree where
    Leaf x   >>= f = f x
    Node l r >>= f = Node (l >>= f) (r >>= f)

main = do
    print $ fmap (* 2) (Node (Leaf 1) (Leaf 2))
    print $ Leaf 1 >>= \x -> Node (Leaf x) (Leaf (x * 2))
