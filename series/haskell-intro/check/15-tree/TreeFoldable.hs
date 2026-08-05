import Data.Foldable (toList)

data Tree a = Leaf a | Node (Tree a) (Tree a) deriving Show

instance Foldable Tree where
    foldMap f (Leaf x)   = f x
    foldMap f (Node l r) = foldMap f l <> foldMap f r

t :: Tree Int
t = Node (Node (Leaf 1) (Leaf 2)) (Leaf 3)

main = do
    print $ sum t
    print $ length t
    print $ elem 2 t
    print $ maximum t
    print $ toList t
    mapM_ print t
