class Container f where
    empty :: f a
    wrap  :: a -> f a

instance Container Maybe where
    empty = Nothing
    wrap  = Just

instance Container [] where
    empty  = []
    wrap x = [x]

main = do
    print (empty :: Maybe Int)
    print (wrap 1 :: Maybe Int)
    print (empty :: [Int])
    print (wrap 1 :: [Int])
