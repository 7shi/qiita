newtype Yoneda f a = Yoneda (forall b. (a -> b) -> f b)

instance Functor (Yoneda f) where
    fmap h (Yoneda y) = Yoneda (\k -> y (k . h))

liftYoneda :: Functor f => f a -> Yoneda f a
liftYoneda fa = Yoneda (\k -> fmap k fa)

lowerYoneda :: Yoneda f a -> f a
lowerYoneda (Yoneda y) = y id

main :: IO ()
main = do
    -- 往復すると元に戻る
    print $ lowerYoneda (liftYoneda [1, 2, 3])
    print $ lowerYoneda (liftYoneda (Just 'a'))
    print $ lowerYoneda (liftYoneda (Right 3 :: Either String Int))
    -- fmap は関数の合成に変わる
    print $ lowerYoneda (fmap (* 2) (liftYoneda [1, 2, 3]))
    print $ lowerYoneda (fmap show (fmap (+ 1) (liftYoneda (Just 3))))
