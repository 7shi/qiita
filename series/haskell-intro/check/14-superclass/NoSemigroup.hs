newtype Count = Count Int deriving Show

instance Monoid Count where
    mempty = Count 0

main = print (mempty :: Count)
