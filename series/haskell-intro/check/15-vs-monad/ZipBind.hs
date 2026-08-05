import Control.Monad (ap)

newtype Zip a = Zip { getZip :: [a] }

instance Functor Zip where
    fmap f (Zip xs) = Zip (map f xs)

instance Applicative Zip where
    pure = Zip . repeat
    Zip fs <*> Zip xs = Zip (zipWith ($) fs xs)

-- リストと同じ >>= を書いてみる
instance Monad Zip where
    Zip xs >>= f = Zip (concatMap (getZip . f) xs)

main = do
    print          (getZip $ ((,) <$> Zip [1, 2])  <*>  Zip [10, 20])
    print $ take 4 (getZip $ ((,) <$> Zip [1, 2]) `ap` Zip [10, 20])
