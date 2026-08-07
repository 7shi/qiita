{-# LANGUAGE GADTs #-}
-- 本文「テレタイプ」の掲載コード（Program の定義は Gen.hs と同じものを補ってある）
import Control.Monad (liftM, ap)


data Program instr a where
    Return :: a -> Program instr a
    (:>>=) :: instr b -> (b -> Program instr a) -> Program instr a

instance Functor (Program instr) where
    fmap = liftM

instance Applicative (Program instr) where
    pure  = Return
    (<*>) = ap

instance Monad (Program instr) where
    Return a   >>= k = k a
    (i :>>= j) >>= k = i :>>= (\b -> j b >>= k)

singleton :: instr a -> Program instr a
singleton i = i :>>= Return

data TeletypeI a where
    PutLine :: String -> TeletypeI ()
    GetLine :: TeletypeI String

type Teletype = Program TeletypeI

putLine :: String -> Teletype ()
putLine s = singleton (PutLine s)

getLine' :: Teletype String
getLine' = singleton GetLine

greet :: Teletype ()
greet = do
    putLine "name?"
    name <- getLine'
    putLine ("Hello, " ++ name ++ "!")

runPure :: [String] -> Teletype a -> [String]
runPure _        (Return _)         = []
runPure ins      (PutLine s :>>= k) = s : runPure ins (k ())
runPure []       (GetLine :>>= k)   = runPure [] (k "")
runPure (i : is) (GetLine :>>= k)   = runPure is (k i)

runIO :: Teletype a -> IO ()
runIO (Return _)         = return ()
runIO (PutLine s :>>= k) = putStrLn s >> runIO (k ())
runIO (GetLine :>>= k)   = getLine >>= runIO . k

main :: IO ()
main = do
    mapM_ putStrLn $ runPure ["Haskell"] greet
    mapM_ putStrLn $ runPure ["世界"] greet
