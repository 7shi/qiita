{-# LANGUAGE DataKinds #-}
import Control.Monad
import Effectful
import Effectful.Reader.Static
import Effectful.State.Static.Local
import Effectful.Writer.Static.Local

prog :: (State Int :> es, Reader Int :> es, Writer [Int] :> es) => [Int] -> Eff es ()
prog xs = forM_ xs $ \i -> do
    modify (+ i)
    v <- get
    lim <- ask
    when (v > lim) $ tell [v :: Int]

main = do
    print $ runPureEff $ runReader (5 :: Int) $ runWriter @[Int] $ runState (0 :: Int) $ prog [1..5]
    print $ runPureEff $ runReader (5 :: Int) $ runState (0 :: Int) $ runWriter @[Int] $ prog [1..5]
