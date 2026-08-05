main = do
    print $ map  (* 2) [1, 2, 3]
    print $ fmap (* 2) [1, 2, 3]
    print $ fmap (* 2) (Just 3)
    print $ fmap (* 2) (Nothing :: Maybe Int)
    print $ (* 2) <$> Just 3
    print =<< fmap (* 2) (return 3 :: IO Int)
