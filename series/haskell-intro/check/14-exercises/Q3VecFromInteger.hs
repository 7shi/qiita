data Vec = Vec Double Double deriving Show

instance Num Vec where
    Vec a b + Vec c d = Vec (a + c) (b + d)
    Vec a b - Vec c d = Vec (a - c) (b - d)
    negate (Vec a b)  = Vec (negate a) (negate b)
    fromInteger n     = Vec (fromInteger n) (fromInteger n)
    (*)    = undefined
    abs    = undefined
    signum = undefined

main = do
    print (fromInteger 1 :: Vec)
    print $ Vec 1 2 + 1
    print $ sum [Vec 1 1, Vec 2 2, Vec 3 3]
