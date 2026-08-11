{-# LANGUAGE DataKinds #-}
import Control.Monad
import Effectful
import Effectful.Error.Static
import Effectful.State.Static.Local

prog :: (State Int :> es, Error String :> es) => [Int] -> Eff es ()
prog xs = forM_ xs $ \i -> do
    modify (+ i)
    v <- get
    when (v > 5) $ throwError ("over: " ++ show (v :: Int))

main = do
    print $ runPureEff $ runErrorNoCallStack @String $ runState (0 :: Int) $ prog [1..5]
    print $ runPureEff $ runState (0 :: Int) $ runErrorNoCallStack @String $ prog [1..5]
