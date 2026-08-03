data Color = Blue | Red | Green | White

class Foo a where
    foo :: a -> String

instance Foo Int where
    foo 1 = "bar"
    foo _ = "?"

instance Foo Color where
    foo Blue = "青"
    foo Red  = "赤"
    foo _    = "?"

main = do
    putStrLn $ foo (1 :: Int)
    putStrLn $ foo Blue
    putStrLn $ foo Green
