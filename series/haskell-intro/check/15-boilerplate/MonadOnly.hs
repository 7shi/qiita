-- instance Monad だけを書くとコンパイルが通らない
data Tree a = Leaf a | Node (Tree a) (Tree a) deriving Show

instance Monad Tree where
    Leaf x   >>= f = f x
    Node l r >>= f = Node (l >>= f) (r >>= f)

main = print (Leaf 1 >>= \x -> Node (Leaf x) (Leaf (x * 2)))
