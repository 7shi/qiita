data Color = Blue | Red | Green deriving Show

instance Read Color where
    readsPrec _ "Blue"  = [(Blue,  "")]
    readsPrec _ "Red"   = [(Red,   "")]
    readsPrec _ "Green" = [(Green, "")]
    readsPrec _ _       = []

main = do
    print (read "Blue" :: Color)
    print (read "Green" :: Color)
