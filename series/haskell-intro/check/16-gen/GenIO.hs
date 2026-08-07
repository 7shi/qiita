-- 【問2】同じ手順書を走らせる IO 版インタプリタ
import Control.Monad (liftM, ap)

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

data GenF o next = Yield o next deriving Functor

type Gen o = Free (GenF o)

yield :: o -> Gen o ()
yield x = liftF (Yield x ())

count :: Gen Int ()
count = do
    yield 1
    yield 2
    yield 3

toList :: Gen o a -> [o]
toList (Pure _)           = []
toList (Free (Yield o k)) = o : toList k

runIO :: Show o => Gen o a -> IO ()
runIO (Pure _)           = return ()
runIO (Free (Yield o k)) = print o >> runIO k

main = do
    print $ toList count
    runIO count
