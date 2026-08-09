{-# LANGUAGE DataKinds #-}
import Control.Monad
import Effectful
import Effectful.State.Static.Local
import Effectful.Writer.Static.Local

sum' :: [Int] -> (Int, [String])
sum' xs = runPureEff $ runWriter @[String] $ execState (0 :: Int) $
    forM_ xs $ \i -> do
        modify (+ i)
        v <- get
        tell ["+" ++ show i ++ " -> " ++ show (v :: Int)]

main = do
    let (s, logs) = sum' [1..5]
    mapM_ putStrLn logs
    print s
