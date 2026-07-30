-- 消費側のコルーチン: 値を待って中断する await。
-- 生産側（yield）の双対。GenBi.hs と対にして読む。
import Control.Monad.Trans.Cont (Cont, evalCont, callCC)

-- Yield が「出す値 o を持つ」のに対し、Await は値を持たない。
-- 再開用の継続が i を受け取る点は yield と同じ。
data Sink i r
    = Ret r
    | Await (i -> Cont (Sink i r) (Sink i r))

type SinkM i r = Cont (Sink i r)

type Out i r = Sink i r -> SinkM i r i

-- yield ccOut v = callCC $ \next -> ccOut (Yield v next)
-- await ccOut   = callCC $ \next -> ccOut (Await   next)
-- 出す値がないだけで、形は同じ。
await :: Out i r -> SinkM i r i
await ccOut = callCC $ \next -> ccOut (Await next)

-- 本体は最後に結果 r を返す。それを Ret で包む。
runSink :: (Out i r -> SinkM i r r) -> Sink i r
runSink body = evalCont $ callCC $ \ccOut -> Ret <$> body ccOut

-- 入力列を流し込む。入力が尽きたまま Await なら Nothing。
feed :: Sink i r -> [i] -> Maybe r
feed (Ret r) _ = Just r
feed (Await next) (i:is) = feed (evalCont (next i)) is
feed (Await _) [] = Nothing

-- 3 個受け取って足す
sum3 :: Sink Int Int
sum3 = runSink $ \ccIn -> do
    a <- await ccIn
    b <- await ccIn
    c <- await ccIn
    return (a + b + c)

-- 0 が来るまで足す（必要な個数が入力に依存する例）
sumUntil0 :: Sink Int Int
sumUntil0 = runSink $ \ccIn ->
    let loop s = do
            x <- await ccIn
            if x == 0 then return s else loop (s + x)
    in loop 0

main :: IO ()
main = do
    print (feed sum3 [1, 2, 3, 4])      -- 余った入力は無視
    print (feed sum3 [1, 2])            -- 足りない: Nothing
    print (feed sumUntil0 [1, 2, 3, 0, 9])
    print (feed sumUntil0 [1, 2, 3])    -- 0 が来ない: Nothing
