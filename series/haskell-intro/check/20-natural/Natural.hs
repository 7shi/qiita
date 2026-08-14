type f ~> g = forall a. f a -> g a

listToMaybe :: [] ~> Maybe
listToMaybe []      = Nothing
listToMaybe (x : _) = Just x

maybeToList :: Maybe ~> []
maybeToList Nothing  = []
maybeToList (Just x) = [x]

h :: Int -> String
h = show

main :: IO ()
main = do
    -- 自然性: fmap h . listToMaybe == listToMaybe . fmap h
    print $ (fmap h . listToMaybe) [1, 2, 3]
    print $ (listToMaybe . fmap h) [1, 2, 3]
    print $ (fmap h . listToMaybe) ([] :: [Int])
    print $ (listToMaybe . fmap h) ([] :: [Int])
    print $ (fmap h . maybeToList) (Just 1)
    print $ (maybeToList . fmap h) (Just 1)
    print $ (fmap h . maybeToList) (Nothing :: Maybe Int)
    print $ (maybeToList . fmap h) (Nothing :: Maybe Int)
