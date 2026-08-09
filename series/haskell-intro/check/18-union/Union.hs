{-# LANGUAGE DataKinds, GADTs, FlexibleInstances, MultiParamTypeClasses #-}
import Control.Monad (ap, liftM)

data Union es a where
    Here  :: e a -> Union (e ': es) a
    There :: Union es a -> Union (e ': es) a

class e :> es where
    inj :: e a -> Union es a
    prj :: Union es a -> Maybe (e a)

instance {-# OVERLAPPING #-} e :> (e ': es) where
    inj = Here
    prj (Here x) = Just x
    prj _        = Nothing

instance {-# OVERLAPPABLE #-} e :> es => e :> (e' ': es) where
    inj = There . inj
    prj (There u) = prj u
    prj _         = Nothing

data Eff es a where
    Return :: a -> Eff es a
    (:>>=) :: Union es b -> (b -> Eff es a) -> Eff es a

instance Functor (Eff es) where fmap = liftM
instance Applicative (Eff es) where pure = Return; (<*>) = ap
instance Monad (Eff es) where
    Return a   >>= k = k a
    (u :>>= j) >>= k = u :>>= (\b -> j b >>= k)

send :: e :> es => e a -> Eff es a
send e = inj e :>>= Return

-- 命令
data Teletype r where
    PutLine :: String -> Teletype ()
    GetLine ::           Teletype String

data Counter r where
    Tick :: Counter Int

putLine :: Teletype :> es => String -> Eff es ()
putLine s = send (PutLine s)

getLine' :: Teletype :> es => Eff es String
getLine' = send GetLine

tick :: Counter :> es => Eff es Int
tick = send Tick

greet :: (Teletype :> es, Counter :> es) => Eff es ()
greet = do
    putLine "name?"
    name <- getLine'
    n <- tick
    putLine ("Hello, " ++ name ++ "! " ++ show n)

runCounter :: Int -> Eff (Counter ': es) a -> Eff es a
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
