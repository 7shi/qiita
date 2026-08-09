{-# LANGUAGE GADTs #-}
-- interpretWithMonad の第 1 引数が forall a. を要求することの確認
-- 実行: stack script --resolver lts-24.53 --package operational Forall.hs
import Control.Monad.Operational

data TeletypeI a where
    PutLine :: String -> TeletypeI ()
    GetLine :: TeletypeI String

type Teletype = Program TeletypeI

greet :: Teletype ()
greet = singleton (PutLine "hi")

-- OK: 型を明記した名前付き関数
interp :: TeletypeI a -> IO a
interp (PutLine s) = putStrLn s
interp GetLine     = getLine

-- NG: 型を書かずに let で定義すると a が決め打ちされる
--   let f i = case i of
--         PutLine s -> putStrLn s
--         GetLine   -> getLine
--   interpretWithMonad f greet
-- error: [GHC-25897] Could not deduce 'p ~ IO ()' … f :: TeletypeI a -> p

main :: IO ()
main = do
    interpretWithMonad interp greet
    -- OK: その場のラムダは期待される型が伝播するので通る
    interpretWithMonad (\i -> case i of
        PutLine s -> putStrLn s
        GetLine   -> getLine) greet
