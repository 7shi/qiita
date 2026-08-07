-- 【問1】15 回の Tree と Free Two が同じ結果になることの確認
import Control.Monad (liftM, ap)

-- 15 回の Tree
data Tree a = Leaf a | Node (Tree a) (Tree a)

instance Show a => Show (Tree a) where
    show (Leaf a)   = show a
    show (Node l r) = "(" ++ show l ++ " " ++ show r ++ ")"

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

-- 本文「動かす」節の Show（type Tree = Free Two を使わない形）
instance Show a => Show (Free Two a) where
    show (Pure a)         = show a
    show (Free (Two l r)) = "(" ++ show l ++ " " ++ show r ++ ")"

grow' :: Int -> Free Two Int
grow' x = Free (Two (Pure x) (Pure (x * 10)))

main :: IO ()
main = do
    let t  = Node (Leaf 1) (Leaf 2)
        t' = Free (Two (Pure 1) (Pure 2))
    print $ t  >>= grow
    print $ t' >>= grow'
    print $ fmap (* 2) t
    print $ fmap (* 2) t'
