main :: IO ()
main = do
    -- どの型にも undefined がある
    putStrLn (const "Int の undefined も型としては通る" (undefined :: Int))
    -- seq は「常に停止しない関数」と「停止しない値」を区別する
    seq (\_ -> undefined :: Int) (putStrLn "\\_ -> undefined は WHNF")
    -- fmap id == id が (->) で破れる
    seq (fmap id bot) (putStrLn "fmap id bot は id . bot なのでラムダ")
    seq (id bot) (putStrLn "ここには来ない")
  where
    bot = undefined :: Int -> Int
