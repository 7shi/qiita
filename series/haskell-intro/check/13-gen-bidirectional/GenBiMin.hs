-- 双方向ジェネレーター: 継続モナドも含めて全部自前の最小実装。
-- GenBi.hs（標準の transformers を使う版）と同じ出力になる。
import Control.Monad (ap, liftM)

-- ここから継続モナドの最小実装（標準の Control.Monad.Trans.Cont に相当）
newtype Cont r a = Cont { runCont :: (a -> r) -> r }

-- Monad のスーパークラスなので必要。中身は Monad から導出できる。
instance Functor (Cont r) where
    fmap = liftM

instance Applicative (Cont r) where
    pure x = Cont ($ x)
    (<*>) = ap

instance Monad (Cont r) where
    m >>= k = Cont $ \c -> runCont m (\x -> runCont (k x) c)

evalCont :: Cont r r -> r
evalCont = (`runCont` id)

callCC :: ((a -> Cont r b) -> Cont r a) -> Cont r a
callCC f = Cont $ \c -> runCont (f (\x -> Cont $ \_ -> c x)) c
-- ここまで

-- 以下は GenBi.hs と同一

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
