-- 双方向ジェネレーター: 再開時に値を渡せるようにしたもの（JS の it.next(x) に相当）。
-- GenStd.hs（生産専用）からの差分は Gen の型と yield の戻り値だけ。
import Control.Monad.Trans.Cont (Cont, evalCont, callCC)

-- 出力の型 o と入力の型 i を分ける。
-- 再開用の継続が「i を受け取る関数」になる点が生産専用版との違い。
data Gen i o
    = Done
    | Yield o (i -> Cont (Gen i o) (Gen i o))

type GenM i o = Cont (Gen i o)

-- ジェネレーターから抜ける継続。生産専用版では答えが () だったが、
-- yield の戻り値が i になるのに合わせて i にする。
type Out i o = Gen i o -> GenM i o i

-- 捕まえた継続 next は i を受け取る関数なので、そのまま Yield に格納できる。
-- 生産専用版の (next ()) が next になっただけ。
yield :: Out i o -> o -> GenM i o i
yield ccOut v = callCC $ \next -> ccOut (Yield v next)

runGen :: (Out i o -> GenM i o x) -> Gen i o
runGen body = evalCont $ callCC $ \ccOut -> body ccOut >> return Done

-- 入力列を与えて出力列を取り出す（生産専用版の toList に相当）
feed :: Gen i o -> [i] -> [o]
feed (Yield v next) (i:is) = v : feed (evalCont (next i)) is
feed _ _ = []

-- 累算器: 渡された値を足し込み、途中結果を yield する
accum :: Gen Int Int
accum = runGen $ \ccOut ->
    let loop s = yield ccOut s >>= \x -> loop (s + x)
    in loop 0

-- 出力と入力で型が違う例: 受け取った文字列の長さを yield する
lengths :: Gen String Int
lengths = runGen $ \ccOut ->
    let loop n = yield ccOut n >>= \s -> loop (length s)
    in loop 0

-- 受け取った値によって終了する例（Done に到達する）
untilZero :: Gen Int Int
untilZero = runGen $ \ccOut ->
    let loop s = do
            x <- yield ccOut s
            if x == 0 then return () else loop (s + x)
    in loop 0

main :: IO ()
main = do
    print (feed accum [1, 2, 3, 4])
    print (feed lengths ["ab", "hello", ""])
    print (feed untilZero [1, 2, 0, 5])   -- 0 で終了、残りの入力は無視される
    print (feed untilZero [])             -- 入力なし: 最初の yield も観測できない
