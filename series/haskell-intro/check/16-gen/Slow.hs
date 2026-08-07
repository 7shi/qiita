-- 左結合の >>= が遅くなることの確認
import Control.Monad (liftM, ap, foldM)
import Data.List (foldl')
import System.Environment (getArgs)

data Free f a = Pure a | Free (f (Free f a))

instance Functor f => Functor (Free f) where
    fmap = liftM

instance Functor f => Applicative (Free f) where
    pure  = Pure
    (<*>) = ap

instance Functor f => Monad (Free f) where
    Pure a >>= k = k a
    Free g >>= k = Free (fmap (>>= k) g)

liftF :: Functor f => f a -> Free f a
liftF c = Free (fmap Pure c)

data GenF o next = Yield o next

instance Functor (GenF o) where
    fmap f (Yield o next) = Yield o (f next)

type Gen o = Free (GenF o)

yield :: o -> Gen o ()
yield x = liftF (Yield x ())

toList :: Gen o a -> [o]
toList (Pure _)           = []
toList (Free (Yield o k)) = o : toList k

-- 右結合: yield 1 >> (yield 2 >> (yield 3 >> ...))
right :: Int -> Gen Int ()
right n = foldr (\x acc -> yield x >> acc) (return ()) [1 .. n]

-- 左結合: ((yield 1 >> yield 2) >> yield 3) >> ...
left :: Int -> Gen Int ()
left n = foldl (\acc x -> acc >> yield x) (return ()) [1 .. n]

main :: IO ()
main = do
    args <- getArgs
    let n = read (args !! 1)
    case head args of
        "right" -> print $ sum $ toList $ right n
        _       -> print $ sum $ toList $ left n
