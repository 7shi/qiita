-- (a) 双方向 と (b) IO を組み合わせられるかの確認。
-- 対話ループ（1 行読んで渡し、結果を受け取って表示する）になる。
import Control.Monad.Trans.Cont (ContT, evalContT, callCC)
import Control.Monad.IO.Class (liftIO)

data Gen i o
    = Done
    | Yield o (i -> ContT (Gen i o) IO (Gen i o))

type GenM i o = ContT (Gen i o) IO

type Out i o = Gen i o -> GenM i o i

-- 純粋な双方向版と完全に同一
yield :: Out i o -> o -> GenM i o i
yield ccOut v = callCC $ \next -> ccOut (Yield v next)

runGen :: (Out i o -> GenM i o x) -> IO (Gen i o)
runGen body = evalContT $ callCC $ \ccOut -> body ccOut >> return Done

-- 入力を「その場で IO から作る」ドライバー。リストでは書けない形。
-- 出力を見てから次の入力を決められるのが双方向の効きどころ。
drive :: (o -> IO (Maybe i)) -> Gen i o -> IO ()
drive _ Done = return ()
drive f (Yield v next) = do
    mi <- f v
    case mi of
        Nothing -> return ()
        Just i -> evalContT (next i) >>= drive f

-- 累算器。yield ごとに生産側でも IO する。
accum :: IO (Gen Int Int)
accum = runGen $ \ccOut ->
    let loop s = do
            liftIO $ putStrLn ("  [gen] total = " ++ show s)
            x <- yield ccOut s
            loop (s + x)
    in loop 0

main :: IO ()
main = do
    g <- accum
    -- 出力を見てから入力を決める: 合計が 5 を超えたら打ち切る
    drive step g
  where
    step total = do
        putStrLn ("  [drv] got " ++ show total)
        if total > 5
            then do putStrLn "  [drv] stop"; return Nothing
            else do
                let n = total + 1
                putStrLn ("  [drv] send " ++ show n)
                return (Just n)
