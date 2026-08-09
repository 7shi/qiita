{-# LANGUAGE DataKinds, GADTs, FlexibleInstances, MultiParamTypeClasses #-}
import Control.Monad (ap, liftM)

data Union effs a where
    Here  :: eff a -> Union (eff ': effs) a
    There :: Union effs a -> Union (eff ': effs) a

class Member eff effs where
    inj :: eff a -> Union effs a
    prj :: Union effs a -> Maybe (eff a)

instance {-# OVERLAPPING #-} Member eff (eff ': effs) where
    inj = Here
    prj (Here x) = Just x
    prj _        = Nothing

instance {-# OVERLAPPABLE #-} Member eff effs => Member eff (eff' ': effs) where
    inj = There . inj
    prj (There u) = prj u
    prj _         = Nothing

data Eff effs a where
    Return :: a -> Eff effs a
    (:>>=) :: Union effs b -> (b -> Eff effs a) -> Eff effs a

instance Functor (Eff effs) where fmap = liftM
instance Applicative (Eff effs) where pure = Return; (<*>) = ap
instance Monad (Eff effs) where
    Return a >>= k = k a
    (u :>>= j) >>= k = u :>>= (\b -> j b >>= k)

send :: Member eff effs => eff a -> Eff effs a
send e = inj e :>>= Return

-- 命令
data Teletype r where
    PutLine :: String -> Teletype ()
    GetLine ::           Teletype String

data Counter r where
    Tick :: Counter Int

putLine :: Member Teletype effs => String -> Eff effs ()
putLine s = send (PutLine s)

getLine' :: Member Teletype effs => Eff effs String
getLine' = send GetLine

tick :: Member Counter effs => Eff effs Int
tick = send Tick

greet :: (Member Teletype effs, Member Counter effs) => Eff effs ()
greet = do
    putLine "name?"
    name <- getLine'
    n <- tick
    putLine ("Hello, " ++ name ++ "! " ++ show n)

runCounter :: Int -> Eff (Counter ': effs) a -> Eff effs a
runCounter _ (Return a) = Return a
runCounter n (u :>>= k) = case u of
    Here Tick -> runCounter (n + 1) (k n)
    There u'  -> u' :>>= (runCounter n . k)

runTeletype :: Eff '[Teletype] a -> IO a
runTeletype (Return a) = return a
runTeletype (u :>>= k) = case u of
    Here (PutLine s) -> putStrLn s >> runTeletype (k ())
    Here GetLine     -> getLine >>= runTeletype . k
    There _          -> error "impossible"

main = runTeletype (runCounter 0 greet)
