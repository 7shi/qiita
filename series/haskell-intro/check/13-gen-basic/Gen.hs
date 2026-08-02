-- 記事「ジェネレーター」節の掲載コード（値を出すだけのジェネレーター）。
import Control.Monad.Trans.Cont (Cont, evalCont, callCC)

data Gen a = Yield a (Cont (Gen a) (Gen a)) | Done

runGen body = evalCont $ callCC $ \ccOut -> body ccOut >> return Done
yield ccOut v = callCC $ \next -> ccOut (Yield v (next ()))

loop (Yield v next) = print v >> loop (evalCont next)
loop Done = return ()

gen = runGen $ \ccOut -> do
    yield ccOut 1
    yield ccOut 2
    yield ccOut 3

main = loop gen
