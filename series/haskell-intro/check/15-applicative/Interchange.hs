-- 交換則: pure した側は左右どちらに置いても同じ
main = do
    print $ [(+ 1), (* 2)] <*> pure 10
    print $ pure ($ 10) <*> [(+ 1), (* 2)]
