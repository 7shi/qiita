{-# LANGUAGE DataKinds, FlexibleContexts, GADTs, TypeOperators #-}
import Control.Monad.Freer
import Control.Monad.Freer.State
import Control.Monad.Freer.Writer

prog :: (Member (State Int) effs, Member (Writer [String]) effs) => Eff effs ()
prog = do
    n <- get
    tell ["n = " ++ show (n :: Int)]
    put (n + 1)

main = do
    print $ run $ runWriter (runState (0 :: Int) prog :: Eff '[Writer [String]] ((), Int))
    print $ run $ runState (0 :: Int) (runWriter prog :: Eff '[State Int] ((), [String]))
