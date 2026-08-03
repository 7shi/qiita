data MonoidDict a = MonoidDict
    { appendM :: a -> a -> a
    , emptyM  :: a
    }

dMonoidList :: MonoidDict [b]
dMonoidList = MonoidDict (++) []

main = do
    print (emptyM dMonoidList :: String)
    print (appendM dMonoidList "abc" "def")
