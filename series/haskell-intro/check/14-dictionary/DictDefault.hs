data EqDict a = EqDict { eqM :: a -> a -> Bool, neM :: a -> a -> Bool }

-- instance Eq Color で == だけ書いた場合に相当する
mkEqDict :: (a -> a -> Bool) -> EqDict a
mkEqDict eq = d where d = EqDict eq (\x y -> not (eqM d x y))

dEqInt :: EqDict Int
dEqInt = mkEqDict (==)

main = do
    print (eqM dEqInt 1 1)
    print (neM dEqInt 1 1)
