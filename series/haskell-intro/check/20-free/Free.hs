import Control.Monad (ap, liftM)

data Free f a = Pure a | Free (f (Free f a))

instance Functor f => Functor (Free f) where
    fmap = liftM

instance Functor f => Applicative (Free f) where
    pure  = Pure
    (<*>) = ap

instance Functor f => Monad (Free f) where
    Pure a >>= k = k a
    Free g >>= k = Free (fmap (>>= k) g)

type f ~> g = forall a. f a -> g a

foldFree :: Monad m => (f ~> m) -> Free f a -> m a
foldFree _   (Pure a) = return a
foldFree phi (Free g) = phi g >>= foldFree phi

data Say next = Say String next

instance Functor Say where
    fmap k (Say s next) = Say s (k next)

say :: String -> Free Say ()
say s = Free (Say s (Pure ()))

prog :: Free Say ()
prog = do
    say "hello"
    say "world"

toIO :: Say ~> IO
toIO (Say s next) = putStrLn s >> return next

toLog :: Say ~> ((,) [String])
toLog (Say s next) = ([s], next)

main :: IO ()
main = do
    -- (a -> m) を 1 つ与えると [a] -> m が決まる
    print (foldMap (\x -> [show x]) [1, 2, 3 :: Int])
    print (sum [1, 2, 3 :: Int])
    -- (f ~> m) を 1 つ与えると Free f a -> m a が決まる
    foldFree toIO prog
    print (foldFree toLog prog)
