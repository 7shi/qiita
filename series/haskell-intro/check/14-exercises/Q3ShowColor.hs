data Color = Blue | Red | Green | White

instance Show Color where
    show Blue  = "Blue"
    show Red   = "Red"
    show Green = "Green"
    show White = "White"

main = do
    print Blue
    print [Blue, Red]
    print (Just White)
