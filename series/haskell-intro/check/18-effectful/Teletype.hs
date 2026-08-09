{-# LANGUAGE DataKinds #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE TypeFamilies #-}
import Effectful
import Effectful.Dispatch.Dynamic
import Effectful.State.Static.Local

data Teletype :: Effect where
    PutLine :: String -> Teletype m ()
    GetLine ::           Teletype m String

type instance DispatchOf Teletype = Dynamic

putLine :: Teletype :> es => String -> Eff es ()
putLine = send . PutLine

getLine' :: Teletype :> es => Eff es String
getLine' = send GetLine

runTeletypeIO :: IOE :> es => Eff (Teletype : es) a -> Eff es a
runTeletypeIO = interpret_ $ \op -> case op of
    PutLine s -> liftIO $ putStrLn s
    GetLine   -> liftIO getLine

greet :: (Teletype :> es, State Int :> es) => Eff es ()
greet = do
    putLine "name?"
    name <- getLine'
    n <- get
    putLine ("Hello, " ++ name ++ "! (" ++ show (n :: Int) ++ ")")
    put (n + 1)

main :: IO ()
main = do
    ((), s) <- runEff $ runState (0 :: Int) $ runTeletypeIO greet
    print s
