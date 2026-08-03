data Circle = Circle Double
data Rect   = Rect Double Double

class Shape a where
    area :: a -> Double
    name :: a -> String
    name _ = "図形"

instance Shape Circle where
    area (Circle r) = pi * r * r
    name _ = "円"

instance Shape Rect where
    area (Rect w h) = w * h

main = do
    putStrLn $ name (Circle 1) ++ ": " ++ show (area (Circle 1))
    putStrLn $ name (Rect 2 3) ++ ": " ++ show (area (Rect 2 3))
