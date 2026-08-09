{-# LANGUAGE DataKinds, GADTs #-}
import Control.Monad
import Control.Monad.Freer
import Control.Monad.Freer.State

sum' :: [Int] -> IO Int
sum' xs = runM $ execState (0 :: Int) $
    forM_ xs $ \i -> do
        modify (+ i)
        v <- get
        sendM $ putStrLn $ "+" ++ show i ++ " -> " ++ show (v :: Int)

main = print =<< sum' [1..5]
