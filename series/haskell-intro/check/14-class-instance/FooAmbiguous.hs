class Foo a where
    foo :: a -> String

instance Foo Int where
    foo 1 = "bar"
    foo _ = "?"

main = putStrLn $ foo 1
