-- shift/reset で双方向ジェネレーターを書き、callCC 版（../gen-bidirectional/GenBi.hs）と比較する。
-- Scheme の「限定継続でジェネレーターを実装する」が言う利点が Haskell でも再現するかの確認。
import Control.Monad.Trans.Cont (Cont, evalCont, reset, shift)

-- 型は callCC 版とまったく同じ
data Gen i o
    = Done
    | Yield o (i -> Cont (Gen i o) (Gen i o))

-- callCC 版: yield ccOut v = callCC $ \next -> ccOut (Yield v next)
--            型は Out i o -> o -> GenM i o i で、脱出継続 ccOut を引き回す必要がある。
-- shift 版: shift が呼び出し元まで戻るので ccOut が要らない。Out 型も不要。
yield :: o -> Cont (Gen i o) i
yield v = shift $ \k -> return (Yield v (return . k))

-- callCC 版: runGen body = evalCont $ callCC $ \ccOut -> body ccOut >> return Done
runGen :: Cont (Gen i o) x -> Gen i o
runGen body = evalCont $ reset (body >> return Done)

-- feed は callCC 版と同一
feed :: Gen i o -> [i] -> [o]
feed (Yield v next) (i:is) = v : feed (evalCont (next i)) is
feed _ _ = []

-- 累算器。yield が単独で定義できるので、本体は ccOut を受け取らない。
accum :: Gen Int Int
accum = runGen $ let loop s = yield s >>= \x -> loop (s + x) in loop 0

main :: IO ()
main = print (feed accum [1, 2, 3, 4])   -- callCC 版と同じ [0,1,3,6]
