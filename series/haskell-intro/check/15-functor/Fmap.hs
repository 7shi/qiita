main = do
    print $ fmap (* 2) (Just 3)
    print $ fmap (* 2) (Nothing :: Maybe Int)
    print =<< fmap (* 2) (return 3 :: IO Int)
    print $ fmap (* 2) [1, 2, 3]
    print $ (* 2) <$> Just 3
