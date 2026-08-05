-- 07回「Applicativeスタイルでは型クラス制約は意識する必要がありません」の回収
inc :: Int -> Int
inc = (+ 1)

add :: Int -> Int -> Int
add = (+)

viaFmap :: Functor f => f Int -> f Int
viaFmap m = inc <$> m

viaAp :: Applicative f => f Int -> f Int -> f Int
viaAp m n = add <$> m <*> n

main = do
    print $ viaFmap [1, 2]
    print $ viaFmap (Just 1)
    print =<< viaFmap (return 1)
    print $ viaAp [1] [2]
    print $ viaAp (Just 1) (Just 2)
