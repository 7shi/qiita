{-# LANGUAGE GADTs #-}
-- 本文「operational パッケージ」の掲載コード
-- 実行: stack script --resolver lts-24.53 --package operational Package.hs
import Control.Monad.Operational

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

-- view で 1 段ずつ剥がすインタープリター
run :: Teletype a -> IO a
run p = case view p of
    Return a         -> return a
    PutLine s :>>= k -> putStrLn s >> run (k ())
    GetLine :>>= k   -> getLine >>= run . k

-- interpretWithMonad でも同じことができる
interp :: TeletypeI a -> IO a
interp (PutLine s) = putStrLn s
interp GetLine     = getLine

main :: IO ()
main = do
    run greet
    interpretWithMonad interp greet
