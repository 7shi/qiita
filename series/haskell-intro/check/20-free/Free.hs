import Control.Monad.Free

type f ~> g = forall a. f a -> g a

data Say next = Say String next

instance Functor Say where
    fmap k (Say s next) = Say s (k next)

say :: String -> Free Say ()
say s = liftF (Say s ())

prog :: Free Say ()
prog = do
    say "hello"
    say "world"

toIO :: Say ~> IO
toIO (Say s next) = putStrLn s >> return next

toLog :: Say ~> ((,) [String])
toLog (Say s next) = ([s], next)

main :: IO ()
main = do
    -- 片道: (f ~> m) を 1 つ与えると Free f a -> m a が決まる
    foldFree toIO prog
    print $ foldFree toLog prog
    -- 往復: 決まった方に逆向きの操作を掛けると元に戻る
    print $ (foldFree toLog . liftF) (Say "hello" ())
