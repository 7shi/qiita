{-# LANGUAGE DataKinds #-}
import Effectful
import Effectful.State.Static.Local
import Effectful.Writer.Static.Local

prog :: (State Int :> es, Writer [String] :> es) => Eff es ()
prog = do
    n <- get
    tell ["n = " ++ show (n :: Int)]
    put (n + 1)

main = do
    print $ runPureEff $ runWriter @[String] $ runState (0 :: Int) prog
    print $ runPureEff $ runState (0 :: Int) $ runWriter @[String] prog
