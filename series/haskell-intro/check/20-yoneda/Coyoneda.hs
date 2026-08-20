data Coyoneda f a = forall b. Coyoneda (f b) (b -> a)

instance Functor (Coyoneda f) where
    fmap h (Coyoneda fb g) = Coyoneda fb (h . g)

liftCoyoneda :: f a -> Coyoneda f a
liftCoyoneda fa = Coyoneda fa id

lowerCoyoneda :: Functor f => Coyoneda f a -> f a
lowerCoyoneda (Coyoneda fb g) = fmap g fb

data Box a = Box a

unBox :: Coyoneda Box a -> a
unBox (Coyoneda (Box b) g) = g b

main :: IO ()
main = do
    -- Box は Functor ではないが Coyoneda Box は Functor
    print $ unBox (fmap (* 2) (liftCoyoneda (Box 3)))
    print $ unBox (fmap show (fmap (+ 1) (liftCoyoneda (Box 3))))
    -- Functor の場合
    print $ lowerCoyoneda (fmap (* 2) (liftCoyoneda [1, 2, 3]))
