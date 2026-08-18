import Data.Monoid (Sum (..))

toMon :: (Bool -> Sum Int) -> [Bool] -> Sum Int
toMon g []       = mempty
toMon g (x : xs) = g x <> toMon g xs

f :: Bool -> Sum Int
f False = Sum 3
f True  = Sum 5

h :: [Bool] -> Sum Int
h = toMon f

k :: Sum Int -> Sum Int
k (Sum n) = Sum (2 * n)

main :: IO ()
main = do
    -- a の側: toMon (f . not) == h . map not
    print $ toMon (f . not) [True, False, True]
    print $ (h . map not)   [True, False, True]
    -- m の側: toMon (k . f) == k . h
    print $ toMon (k . f) [True, False, True]
    print $ (k . h)       [True, False, True]
