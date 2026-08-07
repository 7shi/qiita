-- 本文「手順書を組み立てる」「インタプリタ」の掲載コード
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

count' :: Gen Int ()
count' = Free (Yield 1 (Free (Yield 2 (Free (Yield 3 (Pure ()))))))

nats :: Gen Int ()
nats = mapM_ yield [0 ..]

toList :: Gen o a -> [o]
toList (Pure _)           = []
toList (Free (Yield o k)) = o : toList k

main = do
    print $ toList count
    print $ toList count'
    print $ take 5 $ toList nats
