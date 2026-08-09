{-# LANGUAGE DataKinds, GADTs, RankNTypes, FlexibleInstances, MultiParamTypeClasses #-}
import Data.IORef

-- 手順書ではなく、ハンドラーの環境を受け取る関数
newtype Eff es a = Eff { unEff :: Env es -> IO a }

data Env es where
    ENil  :: Env '[]
    ECons :: (forall x. e x -> IO x) -> Env es -> Env (e ': es)

instance Functor (Eff es) where
    fmap f (Eff m) = Eff $ fmap f . m

instance Applicative (Eff es) where
    pure = Eff . const . pure
    Eff f <*> Eff x = Eff $ \env -> f env <*> x env

instance Monad (Eff es) where
    Eff m >>= k = Eff $ \env -> m env >>= \a -> unEff (k a) env

class e :> es where
    handler :: Env es -> (forall x. e x -> IO x)

instance {-# OVERLAPPING #-} e :> (e ': es) where
    handler (ECons h _) = h

instance {-# OVERLAPPABLE #-} e :> es => e :> (e' ': es) where
    handler (ECons _ r) = handler r

send :: e :> es => e a -> Eff es a
send op = Eff $ \env -> handler env op

interpret :: (forall x. e x -> Eff es x) -> Eff (e ': es) a -> Eff es a
interpret f (Eff m) = Eff $ \env -> m (ECons (\op -> unEff (f op) env) env)

run :: Eff '[] a -> IO a
run (Eff m) = m ENil

-- 命令（18-union と同じ）
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
runCounter n0 m = do
    r <- Eff $ \_ -> newIORef n0
    interpret (\Tick -> Eff $ \_ -> do
        n <- readIORef r
        writeIORef r (n + 1)
        return n) m

runTeletype :: Eff (Teletype ': es) a -> Eff es a
runTeletype = interpret $ \op -> Eff $ \_ -> case op of
    PutLine s -> putStrLn s
    GetLine   -> getLine

main = run (runTeletype (runCounter 0 greet))
