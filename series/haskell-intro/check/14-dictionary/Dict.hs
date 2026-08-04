-- class → メソッドをまとめたレコード型
data EqDict a = EqDict { eqM :: a -> a -> Bool }

-- instance → そのレコードの値
dEqInt :: EqDict Int
dEqInt = EqDict (==)

dEqBool :: EqDict Bool
dEqBool = EqDict (==)

-- 型クラス制約 (Eq a =>) → 隠れた引数
same :: EqDict a -> a -> a -> String
same d x y = if eqM d x y then "same" else "different"

main = do
    putStrLn $ same dEqInt  1 1
    putStrLn $ same dEqBool True False
