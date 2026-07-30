-- 継続モナドによるジェネレーターは純粋な値なので、同じ中断点から
-- 何度でも再開できる（JS のイテレーターはこれができない）。
--
-- 関連: articles/javascript/cloneable-iterator.md
--   「JavaScript のジェネレーターでは実行途中のイテレーターをクローンできません」
import Control.Monad.Trans.Cont (Cont, callCC, evalCont)

data Gen i o
    = Done
    | Yield o (i -> Cont (Gen i o) (Gen i o))

type GenM i o = Cont (Gen i o)
type Out i o = Gen i o -> GenM i o i

yield :: Out i o -> o -> GenM i o i
yield ccOut v = callCC $ \next -> ccOut (Yield v next)

runGen :: (Out i o -> GenM i o x) -> Gen i o
runGen body = evalCont $ callCC $ \ccOut -> body ccOut >> return Done

feed :: Gen i o -> [i] -> [o]
feed Done _ = []
feed (Yield v next) is =
    v : case is of
        (i : rest) -> feed (evalCont (next i)) rest
        [] -> []

-- 中断点から 1 歩進める。継続は値なので何度でも呼べる。
step :: Gen i o -> i -> Gen i o
step (Yield _ next) i = evalCont (next i)
step Done _ = Done

peek :: Gen i o -> Maybe o
peek (Yield v _) = Just v
peek Done = Nothing

accum :: Gen Int Int
accum = runGen $ \ccOut ->
    let loop s = yield ccOut s >>= \x -> loop (s + x)
    in loop 0

main :: IO ()
main = do
    putStrLn "=== 同じ中断点から違う入力で再開する（分岐） ==="
    let g = step accum 10 -- 10 を渡した状態
    print (peek g) -- 10
    print (peek (step g 1)) -- 11
    print (peek (step g 100)) -- 110
    print (peek (step g 1000)) -- 1010
    -- g は消費されない。3 通りの未来を同じ値から取り出せた。

    putStrLn "=== 同じ Gen を 2 回 feed する ==="
    print (feed accum [1, 2, 3])
    print (feed accum [10, 20, 30])

    putStrLn "=== 分岐した先をさらに分岐させる（木になる） ==="
    let branch n = [peek (step (step accum n) m) | m <- [1, 2]]
    print (concatMap branch [10, 100])
