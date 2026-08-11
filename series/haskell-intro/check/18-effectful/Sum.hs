{-# LANGUAGE DataKinds #-}
import Control.Monad
import Effectful
import Effectful.Reader.Static
import Effectful.State.Static.Local
import Effectful.Writer.Static.Local

sum' :: Int -> [Int] -> (Int, [Int])
sum' limit xs = runPureEff $ runWriter $ runReader limit $ execState (0 :: Int) $
    forM_ xs $ \i -> do
        modify (+ i)
        v <- get
        lim <- ask
        when (v > lim) $ tell [v :: Int]

main = print $ sum' 5 [1..5]
