import Control.Monad
import Control.Monad.State

sum' xs = (`execStateT` 0) $ do
    forM_ xs $ \i -> do
        modify (+ i)
        v <- get
        lift $ putStrLn $ "+" ++ show i ++ " -> " ++ show v

main = print =<< sum' [1..5]
