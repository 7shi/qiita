same :: Eq a => a -> a -> String
same x y = if x == y then "same" else "different"

describe :: (Eq a, Show a) => a -> a -> String
describe x y = show x ++ (if x == y then " == " else " /= ") ++ show y

main = do
    putStrLn $ same (1 :: Int) 1
    putStrLn $ same 'a' 'b'
    putStrLn $ describe (1 :: Int) 1
    putStrLn $ describe 'a' 'b'
