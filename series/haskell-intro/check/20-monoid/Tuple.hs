import Control.Monad ((>=>))

main :: IO ()
main = do
    -- mempty と return
    print (mempty :: [String])
    print (return 4 :: ([String], Int))
    -- 単位元をつないでも変わらない
    print ([] <> ["g"])
    print (return 4 >>= \x -> (["g"], x * 2))
    -- return >=> f == f（mempty <> x == x にあたる）
    print ((return >=> \x -> (["g"], x * 2)) (4 :: Int))
    -- base の定義どおりに書いた式と一致するか
    print ((pure 'a' :: ([String], Char)) == (mempty, 'a'))
    print (((["u"], succ) <*> (["v"], 'a')) == (["u"] <> ["v"], succ 'a'))
    print ((k 1 >>= k) == (case k 1 of (w1, a) -> case k a of (w2, b) -> (w1 <> w2, b)))
  where
    k :: Int -> ([String], Int)
    k n = (["k" ++ show n], n + 1)
