{-# LANGUAGE DataKinds #-}
import Control.Monad
import Effectful
import Effectful.State.Static.Local

sum' :: [Int] -> IO Int
sum' xs = runEff $ execState (0 :: Int) $
    forM_ xs $ \i -> do
        modify (+ i)
        v <- get
        liftIO $ putStrLn $ "+" ++ show i ++ " -> " ++ show (v :: Int)

main = print =<< sum' [1..5]
