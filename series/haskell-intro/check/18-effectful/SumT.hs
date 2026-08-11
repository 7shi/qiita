import Control.Monad
import Control.Monad.Reader
import Control.Monad.State
import Control.Monad.Writer

sum' :: Int -> [Int] -> (Int, [Int])
sum' limit xs = runWriter $ (`runReaderT` limit) $ (`execStateT` 0) $
    forM_ xs $ \i -> do
        modify (+ i)
        v <- get
        lim <- ask
        when (v > lim) $ tell [v]

main = print $ sum' 5 [1..5]
