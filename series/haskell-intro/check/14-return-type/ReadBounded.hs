data Color = Blue | Red | Green | White
    deriving (Show, Read, Eq, Ord, Enum, Bounded)

main = do
    print (read "123" :: Int)
    print (read "1.5" :: Double)
    print (read "Red" :: Color)
    print (minBound :: Int)
    print (minBound :: Color)
    print (maxBound :: Color)
    print ([minBound .. maxBound] :: [Color])
    print (mempty :: String)
    print (mempty :: [Int])
