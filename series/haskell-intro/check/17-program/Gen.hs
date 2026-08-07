{-# LANGUAGE GADTs #-}
-- 本文「続きを外に出す」「GADTs で命令を並べる」「インタープリター」の掲載コード
import Control.Monad (liftM, ap)


data Program instr a where
    Return :: a -> Program instr a
    (:>>=) :: instr b -> (b -> Program instr a) -> Program instr a

instance Functor (Program instr) where
    fmap = liftM

instance Applicative (Program instr) where
    pure  = Return
    (<*>) = ap

instance Monad (Program instr) where
    Return a  >>= k = k a
    (i :>>= j) >>= k = i :>>= (\b -> j b >>= k)

singleton :: instr a -> Program instr a
singleton i = i :>>= Return

data GenI o a where
    Yield :: o -> GenI o ()

type Gen o = Program (GenI o)

yield :: o -> Gen o ()
yield x = singleton (Yield x)

count :: Gen Int ()
count = do
    yield 1
    yield 2
    yield 3

nats :: Gen Int ()
nats = mapM_ yield [0 ..]

toList :: Gen o a -> [o]
toList (Return _)        = []
toList (Yield o :>>= k) = o : toList (k ())

main = do
    print $ toList count
    print $ take 5 $ toList nats
