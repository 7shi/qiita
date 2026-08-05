import Control.Monad (replicateM_)

newtype State s a = State { runState :: s -> (a, s) }

instance Functor (State s) where
    fmap f m = State $ \s ->
        let (a, s1) = runState m s
        in  (f a, s1)

instance Applicative (State s) where
    pure x = State $ \s -> (x, s)
    mf <*> m = State $ \s ->
        let (f, s1) = runState mf s
            (a, s2) = runState m  s1
        in  (f a, s2)

instance Monad (State s) where
    m >>= k = State $ \s ->
        let (a, s1) = runState m s
        in  runState (k a) s1

get'   = State $ \s -> (s , s)
put' x = State $ \_ -> ((), x)

evalState m s = fst (runState m s)

fib x = (`evalState` (0, 1)) $ do
    replicateM_ (x - 1) $ do
        (a, b) <- get'
        put' (b, a + b)
    (_, b) <- get'
    return b

main = print $ fib 10
