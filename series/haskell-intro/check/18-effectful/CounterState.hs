{-# LANGUAGE DataKinds #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE TypeFamilies #-}
import Effectful
import Effectful.Dispatch.Dynamic
import Effectful.State.Static.Local

data Teletype :: Effect where
    PutLine :: String -> Teletype m ()
    GetLine ::           Teletype m String

data Counter :: Effect where
    Tick :: Counter m Int

type instance DispatchOf Teletype = Dynamic
type instance DispatchOf Counter  = Dynamic

putLine :: Teletype :> es => String -> Eff es ()
putLine = send . PutLine

getLine' :: Teletype :> es => Eff es String
getLine' = send GetLine

tick :: Counter :> es => Eff es Int
tick = send Tick

runTeletypeIO :: IOE :> es => Eff (Teletype : es) a -> Eff es a
runTeletypeIO = interpret_ $ \op -> case op of
    PutLine s -> liftIO $ putStrLn s
    GetLine   -> liftIO getLine

runCounter :: Int -> Eff (Counter : es) a -> Eff es a
runCounter n0 = reinterpret_ (evalState n0) $ \Tick -> do
    n <- get
    put (n + 1)
    return n

greet :: (Teletype :> es, Counter :> es) => Eff es ()
greet = do
    putLine "name?"
    name <- getLine'
    n <- tick
    putLine ("Hello, " ++ name ++ "! " ++ show n)

main :: IO ()
main = runEff $ runTeletypeIO $ runCounter 0 greet
