import Control.Monad (join)

mmm :: [[[Int]]]
mmm = [[[1, 2], [3]], [[4]]]

m :: [Int]
m = [1, 2, 3]

main :: IO ()
main = do
    -- Monoid の結合律・単位律
    print $ (([1, 2] <> [3]) <> [4]) == ([1, 2] <> ([3] <> [4]) :: [Int])
    print $ (mempty <> m) == m && (m <> mempty) == m
    -- モナドの結合律 join . join == join . fmap join
    print $ join (join mmm)
    print $ join (fmap join mmm)
    print $ join (join mmm) == join (fmap join mmm)
    -- モナドの単位律 join . return == id, join . fmap return == id
    print $ join (return m) == m
    print $ join (fmap return m) == m
    -- Maybe でも同じ
    print $ join (join (Just (Just (Just 'a'))))
    print $ join (fmap join (Just (Just (Just 'a'))))
