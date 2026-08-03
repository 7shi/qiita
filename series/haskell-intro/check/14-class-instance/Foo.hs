class Foo a where
    foo :: a -> String

instance Foo Int where
    foo 1 = "bar"
    foo _ = "?"

instance Foo Bool where
    foo True  = "baz"
    foo False = "?"

main = do
    putStrLn $ foo (0 :: Int)
    putStrLn $ foo (1 :: Int)
    putStrLn $ foo False
    putStrLn $ foo True
