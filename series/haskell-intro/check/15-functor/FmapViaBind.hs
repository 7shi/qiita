import Control.Monad (liftM)

f <$$> m = m >>= \a -> return (f a)  -- 10回の再実装（<$> の名前を変えたもの）

main = do
    print $ (* 2) <$$> [1, 2, 3]
    print $ (* 2) <$>  [1, 2, 3]
    print $ liftM (* 2)  [1, 2, 3]
