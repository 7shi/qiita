-- アプリカティブ則を破る例: 左右の位置を入れ替える <*>（恒等則が破れる）
data Pair a = Pair a a deriving Show

instance Functor Pair where
    fmap f (Pair x y) = Pair (f x) (f y)

instance Applicative Pair where
    pure x = Pair x x
    Pair f g <*> Pair x y = Pair (g y) (f x)

main = print $ pure id <*> Pair 1 2
