-- 記事「ジェネレーターを shift/reset で書き直す」節の掲載コード。
-- callCC 版（../13-gen-basic/Gen.hs）と Gen・loop は同一で、結果も一致する。
import Control.Monad.Trans.Cont (Cont, evalCont, reset, shift)

data Gen a = Yield a (Cont (Gen a) (Gen a)) | Done

-- callCC 版: runGen body = evalCont $ callCC $ \ccOut -> body ccOut >> return Done
--            yield ccOut v = callCC $ \next -> ccOut (Yield v (next ()))
-- shift は呼び出し元まで戻るので脱出継続 ccOut が要らない。
runGen body = evalCont $ reset (body >> return Done)
yield v = shift $ \next -> return (Yield v (return (next ())))

loop (Yield v next) = print v >> loop (evalCont next)
loop Done = return ()

gen = runGen $ do
    yield 1
    yield 2
    yield 3

main = loop gen
