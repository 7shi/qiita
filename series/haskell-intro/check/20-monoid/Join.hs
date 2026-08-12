import Control.Monad (join)

bind :: Monad m => m a -> (a -> m b) -> m b
bind m k = join (fmap k m)

join' :: Monad m => m (m a) -> m a
join' mm = mm >>= id

main :: IO ()
main = do
    print (bind [1, 2, 3] (\x -> [x, x * 10]))
    print ([1, 2, 3] >>= \x -> [x, x * 10])
    print (join' [[1, 2], [3]])
    print (join  [[1, 2], [3]])
    print (bind (Just 3) (\x -> Just (x * 2)))
    print (join' (Just (Just 3)))
