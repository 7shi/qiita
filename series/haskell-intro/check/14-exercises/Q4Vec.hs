data Vec = Vec Double Double deriving Show

instance Num Vec where
    Vec a b + Vec c d = Vec (a + c) (b + d)
    Vec a b - Vec c d = Vec (a - c) (b - d)
    negate (Vec a b)  = Vec (negate a) (negate b)
    (*)         = undefined
    abs         = undefined
    signum      = undefined
    fromInteger = undefined

main = do
    print $ Vec 1 2 + Vec 3 4
    print $ Vec 1 2 - Vec 3 4
    print $ negate (Vec 1 2)
    print $ Vec 1 2 + Vec 3 4 - Vec 1 1
