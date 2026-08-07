import Control.Monad.Free

data Two x = Two x x deriving Functor

type Tree = Free Two

leaf :: a -> Tree a
leaf = Pure

node :: Tree a -> Tree a -> Tree a
node l r = Free (Two l r)

toL :: Tree a -> [a]
toL (Pure a) = [a]
toL (Free (Two l r)) = toL l ++ toL r

main :: IO ()
main = print (toL (node (leaf 1) (node (leaf 2) (leaf 3))))
