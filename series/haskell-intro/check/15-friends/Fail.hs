-- do のパターンマッチ失敗が fail になる
maybeHead :: [a] -> Maybe a
maybeHead xs = do
    (x:_) <- Just xs   -- 失敗すると fail "..." が呼ばれる
    return x

listPairs :: [(Int, Int)] -> [Int]
listPairs ps = do
    (1, y) <- ps       -- 1 で始まる組だけ通る
    return y

main = do
    print $ maybeHead [1, 2, 3]
    print $ maybeHead ([] :: [Int])
    print $ listPairs [(1, 10), (2, 20), (1, 30)]
