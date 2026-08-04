import Control.Monad.Writer

newtype MaxInt = MaxInt Int deriving Show

instance Semigroup MaxInt where
    MaxInt a <> MaxInt b = MaxInt (max a b)

instance Monoid MaxInt where
    mempty = MaxInt minBound

test :: [Int] -> Writer MaxInt ()
test = mapM_ (tell . MaxInt)

main = do
    print $ mconcat [MaxInt 3, MaxInt 1, MaxInt 4]
    print $ runWriter (test [3, 1, 4, 1, 5, 9, 2, 6])
