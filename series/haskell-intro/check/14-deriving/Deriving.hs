data Color = Blue | Red | Green deriving (Show, Read)

main = do
    print Blue
    print (read "Red" :: Color)
