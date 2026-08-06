import Control.Monad (liftM, ap)

data Rose a = Leaf a | Node [Rose a] deriving Show

instance Functor Rose where
    fmap  = liftM

instance Applicative Rose where
    pure  = Leaf
    (<*>) = ap

instance Monad Rose where
    Leaf x  >>= f = f x
    Node ts >>= f = Node (map (>>= f) ts)

grow x = Node [Leaf x, Leaf (x * 10)]

main = do
    let r = Node [Leaf 1, Node [Leaf 2, Leaf 3]]
    print $ fmap (* 2) r
    print $ r >>= grow
