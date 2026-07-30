-- 継続モナドの callCC は限定継続なのか、という問いの検証。
-- 争点は 2 つ: (1) 捕まえた継続はどこまで届くか (2) 捕まえた継続は合成できるか
import Control.Monad.Trans.Cont (Cont, evalCont, callCC, reset, shift)

-- (1) 到達範囲: evalCont の外へは出られない。
-- 脱出しても "after" は必ず表示される = evalCont が区切り（prompt）。
scope :: IO ()
scope = do
    let r = evalCont $ callCC $ \k -> do
                _ <- k (1 :: Int)
                return 999          -- ここには来ない
    print r
    putStrLn "after"                -- 脱出はここまで飛べない

-- (2a) callCC の継続は abortive（呼んだら戻らない）。
-- k の結果を使おうとしても、そもそも戻ってこないので +100 は効かない。
abortive :: Int
abortive = evalCont $ callCC $ \k -> do
    x <- k 1
    return (x + 100)                -- 到達しない

-- (2b) shift の継続は composable（呼ぶと値が返る）。
-- 古典例 reset (1 + shift (\k -> k (k 3))) = 1 + (1 + 3) = 5
composable :: Int
composable = evalCont $ reset $ do
    x <- shift $ \k -> return (k (k 3))
    return (1 + x)

-- (2c) 同じ k を 2 回使って結果を組み合わせる。callCC では書けない形。
twice :: Int
twice = evalCont $ reset $ do
    x <- shift $ \k -> return (k 10 + k 20)
    return (x * 2)

-- (3) 捕まえた継続は多重呼び出しできる第一級の値（callCC でも同じ）。
-- 「戻り値を捨てて飛ぶ」ことしかできないだけで、値としては普通の関数。
multishot :: [Int]
multishot = evalCont $ callCC $ \k -> do
    _ <- k [1]
    return []

-- (4) 区切りは入れ子にできる。内側の reset の外は捕まらない。
nested :: Int
nested = evalCont $ reset $ do
    x <- reset $ do
            y <- shift $ \k -> return (k 1 + k 2)   -- 内側の reset までが継続
            return (y * 10)
    return (x + 100)

main :: IO ()
main = do
    scope
    print abortive     -- 1   （+100 されない）
    print composable   -- 5
    print twice        -- 60  （(10*2) + (20*2)）
    print multishot    -- [1]
    print nested       -- 130 （(1*10 + 2*10) + 100）
