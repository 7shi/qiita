g, h :: Int -> Int
g = (* 2)
h = (+ 1)

main :: IO ()
main = do
    -- 射の対応: a -> b を f a -> f b に移す
    print $ fmap h (Just 3)
    print $ fmap h [1, 2, 3]
    print $ fmap h (Right 3 :: Either String Int)
    -- fmap id == id
    print $ fmap id (Just 3)  == id (Just 3)
    print $ fmap id [1, 2, 3] == id [1, 2, 3]
    -- fmap (g . h) == fmap g . fmap h
    print $ fmap (g . h) (Just 3)  == (fmap g . fmap h) (Just 3)
    print $ fmap (g . h) [1, 2, 3] == (fmap g . fmap h) [1, 2, 3]
