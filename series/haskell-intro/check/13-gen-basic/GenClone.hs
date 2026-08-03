-- 記事「何度でも再開できる」節の掲載コード。
-- Gen.hs と同じ定義のまま、main で最初の1個を取り出してから
-- そのときの継続を 2 回 loop に掛ける。
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

main = do
    let Yield v next = gen  -- 最初の1個だけ取り出す
    print v
    loop (evalCont next)    -- 続きを最後まで
    loop (evalCont next)    -- 同じ中断点からもう一度
