-- 練習【問3】の解答例
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE TypeFamilies #-}
import Effectful
import Effectful.Dispatch.Dynamic
import Effectful.State.Static.Local
import Effectful.Writer.Static.Local

data Teletype :: Effect where
    PutLine :: String -> Teletype m ()
    GetLine ::           Teletype m String

data Counter :: Effect where
    Tick :: Counter m Int

data Logger :: Effect where
    Log :: String -> Logger m ()

type instance DispatchOf Teletype = Dynamic
type instance DispatchOf Counter  = Dynamic
type instance DispatchOf Logger   = Dynamic

putLine :: Teletype :> es => String -> Eff es ()
putLine = send . PutLine

getLine' :: Teletype :> es => Eff es String
getLine' = send GetLine

tick :: Counter :> es => Eff es Int
tick = send Tick

logMsg :: Logger :> es => String -> Eff es ()
logMsg = send . Log

runTeletypeIO :: IOE :> es => Eff (Teletype : es) a -> Eff es a
runTeletypeIO = interpret_ $ \op -> case op of
    PutLine s -> liftIO $ putStrLn s
    GetLine   -> liftIO getLine

runCounter :: Int -> Eff (Counter : es) a -> Eff es a
runCounter n0 = reinterpret_ (evalState n0) $ \Tick -> do
    n <- get
    put (n + 1)
    return n

runLogger :: Eff (Logger : es) a -> Eff es (a, [String])
runLogger = reinterpret_ runWriter $ \(Log s) -> tell [s]

greet :: (Teletype :> es, Counter :> es, Logger :> es) => Eff es ()
greet = do
    putLine "name?"
    name <- getLine'
    logMsg ("got " ++ name)
    n <- tick
    logMsg ("tick " ++ show n)
    putLine ("Hello, " ++ name ++ "! " ++ show n)

main :: IO ()
main = do
    ((), logs) <- runEff $ runTeletypeIO $ runCounter 0 $ runLogger greet
    mapM_ putStrLn logs
