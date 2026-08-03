data Color = Blue | Red | Green | White deriving Show

main = do
    print Blue
    print [Blue, Red]
    print (Just White)
