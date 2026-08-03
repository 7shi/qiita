data Color = Blue | Red | Green | White

instance Eq Color where
    Blue  == Blue  = True
    Red   == Red   = True
    Green == Green = True
    White == White = True
    _     == _     = False

main = do
    print $ Blue == Blue
    print $ Blue == Red
    print $ Blue /= Red
    print $ Blue /= Blue
