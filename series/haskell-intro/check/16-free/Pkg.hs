import Control.Monad.Free

data GenF o next = Yield o next deriving Functor

type Gen o = Free (GenF o)

yield :: o -> Gen o ()
yield x = liftF (Yield x ())

count :: Gen Int ()
count = do
    yield 1
    yield 2
    yield 3

toList :: Gen o a -> [o]
toList (Pure _)           = []
toList (Free (Yield o k)) = o : toList k

-- foldFree: 各命令を別のモナドへ変換する
runIO :: Show o => Gen o a -> IO a
runIO = foldFree $ \(Yield o next) -> print o >> return next

-- iterM: Free を 1 段ずつ潰す
runIterM :: Show o => Gen o a -> IO a
runIterM = iterM $ \(Yield o next) -> print o >> next

main :: IO ()
main = do
    print $ toList count
    print $ take 5 $ toList $ mapM_ yield [0 :: Int ..]
    runIO count
    runIterM count
