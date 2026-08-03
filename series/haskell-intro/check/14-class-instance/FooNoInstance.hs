data Color = Blue | Red | Green | White

class Foo a where
    foo :: a -> String

instance Foo Bool where
    foo True  = "baz"
    foo False = "?"

main = putStrLn $ foo Blue
