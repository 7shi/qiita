-- Applicative 則が Maybe で成り立つことの確認
u = Just (+ 1)
v = Just (* 2)
w = Just 3

main = do
    print ((pure id <*> w) == w)                                -- 恒等
    print ((pure (+ 1) <*> pure 3 :: Maybe Int) == pure (1 + 3)) -- 準同型
    print ((u <*> pure 5) == (pure ($ 5) <*> u))                -- 交換
    print ((pure (.) <*> u <*> v <*> w) == (u <*> (v <*> w)))   -- 合成
    print (fmap (+ 1) w == (pure (+ 1) <*> w))                  -- Functor との辻褄
