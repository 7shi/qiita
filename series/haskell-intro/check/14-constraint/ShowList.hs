data Color = Blue | Red | Green | White deriving Show

main = do
    print [Blue, Red]
    print [[Blue], [Red, Green]]
    print (Just [Blue, Red])
