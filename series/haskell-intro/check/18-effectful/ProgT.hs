import Control.Monad
import Control.Monad.Reader
import Control.Monad.State
import Control.Monad.Writer

prog :: (MonadState Int m, MonadReader Int m, MonadWriter [Int] m) => [Int] -> m ()
prog xs = forM_ xs $ \i -> do
    modify (+ i)
    v <- get
    lim <- ask
    when (v > lim) $ tell [v]

sum' :: Int -> [Int] -> (Int, [Int])
sum' limit xs = runWriter $ (`runReaderT` limit) $ (`execStateT` 0) $ prog xs

main = print $ sum' 5 [1..5]
