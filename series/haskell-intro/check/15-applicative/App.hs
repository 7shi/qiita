main = do
    print $ (+) <$> Just 1 <*> Just 2
    print $ (+) <$> Just 1 <*> Nothing
    print $ (,) <$> [1, 2] <*> "ab"
    print $ Just 1 <* Just 2
    print $ Just 1 *> Just 2
