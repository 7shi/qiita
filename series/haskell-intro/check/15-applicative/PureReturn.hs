main = do
    print (pure   1 :: Maybe Int)
    print (return 1 :: Maybe Int)
    print (pure   1 :: [Int])
    print (return 1 :: [Int])
