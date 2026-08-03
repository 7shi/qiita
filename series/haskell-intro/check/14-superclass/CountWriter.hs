import Control.Monad.Writer

newtype Count = Count Int deriving Show

instance Semigroup Count where
    Count a <> Count b = Count (a + b)

instance Monoid Count where
    mempty = Count 0

test :: Writer Count ()
test = do
    tell (Count 1)
    tell (Count 2)
    tell (Count 3)

main = print $ runWriter test
