main = do
    print $ [1, 2, 3] >>= \x -> replicate x x
    print $ (,) <$> [1, 2] <*> [10, 20]
    print $ Just 1 >>= \x -> if x > 0 then Just (x * 2) else Nothing
