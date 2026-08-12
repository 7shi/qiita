import Data.Maybe (listToMaybe, maybeToList)

type f ~> g = forall a. f a -> g a

alpha :: [] ~> Maybe
alpha = listToMaybe

beta :: Maybe ~> []
beta = maybeToList

h :: Int -> String
h = show

main :: IO ()
main = do
    -- 自然性: fmap h . alpha == alpha . fmap h
    print ((fmap h . alpha) [1, 2, 3])
    print ((alpha . fmap h) [1, 2, 3])
    print ((fmap h . alpha) ([] :: [Int]))
    print ((alpha . fmap h) ([] :: [Int]))
    print ((fmap h . beta) (Just 1))
    print ((beta . fmap h) (Just 1))
    print ((fmap h . beta) (Nothing :: Maybe Int))
    print ((beta . fmap h) (Nothing :: Maybe Int))
