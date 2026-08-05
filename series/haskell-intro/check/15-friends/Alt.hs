import Control.Applicative

main = do
    print $ Just 1  <|> Just 2
    print $ Nothing <|> Just 2
    print $ (Nothing :: Maybe Int) <|> Nothing
    print (empty :: Maybe Int)
    print $ [1, 2] <|> [3]
    print (empty :: [Int])
    -- Monoid との対応
    print $ Just [1] <> Just [2]
    print $ [1, 2] <> [3 :: Int]
