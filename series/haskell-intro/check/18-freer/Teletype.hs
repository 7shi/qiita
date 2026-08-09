{-# LANGUAGE DataKinds, GADTs #-}
import Control.Monad.Freer
import Control.Monad.Freer.State

data Teletype r where
    PutLine :: String -> Teletype ()
    GetLine ::           Teletype String

putLine :: Member Teletype effs => String -> Eff effs ()
putLine = send . PutLine

getLine' :: Member Teletype effs => Eff effs String
getLine' = send GetLine

runTeletypeIO :: LastMember IO effs => Eff (Teletype ': effs) a -> Eff effs a
runTeletypeIO = interpretM go
  where
    go :: Teletype r -> IO r
    go (PutLine s) = putStrLn s
    go GetLine     = getLine

greet :: (Member Teletype effs, Member (State Int) effs) => Eff effs ()
greet = do
    putLine "name?"
    name <- getLine'
    n <- get
    putLine ("Hello, " ++ name ++ "! (" ++ show (n :: Int) ++ ")")
    put (n + 1)

main :: IO ()
main = do
    ((), s) <- runM $ runState (0 :: Int) $ runTeletypeIO greet
    print s
