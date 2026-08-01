-- ジェネレーターを ContT r IO に持ち上げる。yield の間で IO を実行できるか、
-- 期待した順序で走るかの確認。GenStd.hs（純粋な Cont 版）からの差分は
-- Cont → ContT ... IO、evalCont → evalContT、戻り値が IO で包まれる点だけ。
import Control.Monad.Trans.Cont (ContT, evalContT, callCC)
import Control.Monad.IO.Class (liftIO)

data Gen a
    = Done
    | Yield a (ContT (Gen a) IO (Gen a))

type GenM a = ContT (Gen a) IO

type Out a = Gen a -> GenM a ()

-- yield は純粋版と完全に同一
yield :: Out a -> a -> GenM a ()
yield ccOut v = callCC $ \next -> ccOut (Yield v (next ()))

-- 純粋版は Gen a を返したが、こちらは IO (Gen a) になる
runGen :: (Out a -> GenM a x) -> IO (Gen a)
runGen body = evalContT $ callCC $ \ccOut -> body ccOut >> return Done

-- 純粋版 toList の IO 版。再開のたびに IO が走る。
toListIO :: Gen a -> IO [a]
toListIO Done = return []
toListIO (Yield v k) = do
    g <- evalContT k
    (v :) <$> toListIO g

-- 無限ジェネレーター用: n 個だけ取り出して打ち切る。
-- 素朴に書くと、最後の値を受け取った後に「必要か判断する前に」再開してしまい、
-- 生産側の IO が 1 回余分に走る（純粋版は遅延のおかげで起きなかった）。
takeIOEager :: Int -> Gen a -> IO [a]
takeIOEager 0 _ = return []
takeIOEager _ Done = return []
takeIOEager n (Yield v k) = do
    g <- evalContT k
    (v :) <$> takeIOEager (n - 1) g

-- 再開する前に打ち切りを判定する版
takeIO :: Int -> Gen a -> IO [a]
takeIO n _ | n <= 0 = return []
takeIO _ Done = return []
takeIO n (Yield v k)
    | n == 1 = return [v]        -- ここで止めれば余分な生産は起きない
    | otherwise = do
        g <- evalContT k
        (v :) <$> takeIO (n - 1) g

-- yield ごとに出力する（生産側の IO）
noisy :: IO (Gen Int)
noisy = runGen $ \ccOut ->
    let y n = do
            liftIO $ putStrLn ("  produce " ++ show n)
            yield ccOut n
    in mapM_ y [1, 2, 3]

-- 1 行読んで yield する（入力を伴う生産）
readLines :: IO (Gen String)
readLines = runGen $ \ccOut ->
    let loop = do
            l <- liftIO getLine
            if null l then return () else yield ccOut l >> loop
    in loop

-- 無限ジェネレーターも IO 付きで書けるか
nats :: IO (Gen Int)
nats = runGen $ \ccOut ->
    let loop n = do
            liftIO $ putStrLn ("  produce " ++ show n)
            yield ccOut n
            loop (n + 1)
    in loop 0

main :: IO ()
main = do
    putStrLn "=== noisy: 生産と消費が交互に進むか ==="
    g <- noisy
    xs <- consume g
    print xs

    putStrLn "=== nats: 素朴な take（1 つ余分に produce される） ==="
    n1 <- nats
    takeIOEager 3 n1 >>= print

    putStrLn "=== nats: 再開前に判定する take ==="
    n2 <- nats
    takeIO 3 n2 >>= print

    putStrLn "=== readLines: 標準入力から ==="
    r <- readLines
    toListIO r >>= print
  where
    -- 消費側でも IO を挟んで、順序を目で見る
    consume Done = return []
    consume (Yield v k) = do
        putStrLn ("  consume " ++ show v)
        g <- evalContT k
        (v :) <$> consume g
