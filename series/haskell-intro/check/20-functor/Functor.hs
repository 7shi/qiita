f, g :: Int -> Int
f = (* 2)
g = (+ 1)

main :: IO ()
main = do
    -- 射の対応: a -> b を f a -> f b に移す
    print (fmap g (Just 3))
    print (fmap g [1, 2, 3])
    print (fmap g (Right 3 :: Either String Int))
    -- fmap id == id
    print (fmap id (Just 3)  == id (Just 3))
    print (fmap id [1, 2, 3] == id [1, 2, 3])
    -- fmap (f . g) == fmap f . fmap g
    print (fmap (f . g) (Just 3)  == (fmap f . fmap g) (Just 3))
    print (fmap (f . g) [1, 2, 3] == (fmap f . fmap g) [1, 2, 3])
