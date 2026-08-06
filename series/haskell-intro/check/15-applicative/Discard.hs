-- 片方の結果だけを残す演算子
main = do
    print $ Just 1 <* Just 2
    print $ Just 1 *> Just 2
