-- 練習【問1】の解答例
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
import Control.Monad (ap, liftM)

data Union es a where
    Here  :: e a -> Union (e ': es) a
    There :: Union es a -> Union (e ': es) a

class e :> es where
    inj :: e a -> Union es a

instance {-# OVERLAPPING #-} e :> (e ': es) where
    inj = Here

instance {-# OVERLAPPABLE #-} e :> es => e :> (e' ': es) where
    inj = There . inj

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

-- 効果
data Teletype a where
    PutLine :: String -> Teletype ()
    GetLine ::           Teletype String

data Counter a where
    Tick :: Counter Int

data Logger a where
    Log :: String -> Logger ()

putLine :: Teletype :> es => String -> Eff es ()
putLine s = send (PutLine s)

getLine' :: Teletype :> es => Eff es String
getLine' = send GetLine

tick :: Counter :> es => Eff es Int
tick = send Tick

logMsg :: Logger :> es => String -> Eff es ()
logMsg s = send (Log s)

greet :: (Teletype :> es, Counter :> es, Logger :> es) => Eff es ()
greet = do
    putLine "name?"
    name <- getLine'
    logMsg ("got " ++ name)
    n <- tick
    logMsg ("tick " ++ show n)
    putLine ("Hello, " ++ name ++ "! " ++ show n)

runLogger :: Eff (Logger ': es) a -> Eff es (a, [String])
runLogger (Return a) = Return (a, [])
runLogger (u :>>= k) = case u of
    Here (Log s) -> do
        (a, ls) <- runLogger (k ())
        return (a, s : ls)
    There u'     -> u' :>>= (runLogger . k)

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
    There u'         -> case u' of {}

main = do
    ((), logs) <- runTeletype (runCounter 0 (runLogger greet))
    mapM_ putStrLn logs
