-- await でトークンを 1 つずつ受け取るパーサー。
-- 12-parsing-intro.md の四則演算器を「入力を待つコルーチン」として書くとどうなるか。
import Control.Monad.Trans.Cont (Cont, evalCont, callCC)

data Sink i r
    = Ret r
    | Await (i -> Cont (Sink i r) (Sink i r))

type SinkM i r = Cont (Sink i r)

type Out i r = Sink i r -> SinkM i r i

await :: Out i r -> SinkM i r i
await ccOut = callCC $ \next -> ccOut (Await next)

runSink :: (Out i r -> SinkM i r r) -> Sink i r
runSink body = evalCont $ callCC $ \ccOut -> Ret <$> body ccOut

feed :: Sink i r -> [i] -> Maybe r
feed (Ret r) _ = Just r
feed (Await next) (i:is) = feed (evalCont (next i)) is
feed (Await _) [] = Nothing

data Token = TNum Int | TPlus | TMul | TEnd
    deriving (Show, Eq)

-- 字句解析。ここではただの関数（コルーチンにするのは Pipe.hs）。
tokenize :: String -> [Token]
tokenize s = case dropWhile (== ' ') s of
    [] -> [TEnd]
    ('+':r) -> TPlus : tokenize r
    ('*':r) -> TMul : tokenize r
    r@(c:_)
        | c `elem` ['0' .. '9'] ->
            let (ds, r') = span (`elem` ['0' .. '9']) r
            in TNum (read ds) : tokenize r'
        | otherwise -> error ("bad char: " ++ [c])

-- expr := term (+ term)*
-- term := num (* num)*
--
-- 先読みしたトークンを引数で持ち回る。await は消費してしまうので、
-- 「1 つ先を見て決める」形にすると戻せるバッファが要る。
-- ここでは「読んだトークンを返り値に添えて返す」ことで代用する。
expr :: Out Token r -> SinkM Token r (Int, Token)
expr ccIn = do
    (v, t) <- term ccIn
    loop v t
  where
    loop v TPlus = do
        (v', t) <- term ccIn
        loop (v + v') t
    loop v t = return (v, t)

term :: Out Token r -> SinkM Token r (Int, Token)
term ccIn = do
    v <- num ccIn
    t <- await ccIn
    loop v t
  where
    loop v TMul = do
        v' <- num ccIn
        t <- await ccIn
        loop (v * v') t
    loop v t = return (v, t)

num :: Out Token r -> SinkM Token r Int
num ccIn = do
    t <- await ccIn
    case t of
        TNum n -> return n
        _ -> error ("expected number, got " ++ show t)

calc :: Sink Token Int
calc = runSink $ \ccIn -> do
    (v, t) <- expr ccIn
    if t == TEnd then return v else error ("trailing " ++ show t)

run :: String -> Maybe Int
run = feed calc . tokenize

main :: IO ()
main = do
    print (run "1+2*3")
    print (run "2*3+4*5")
    print (run "10")
    print (run "1 + 2 + 3")
    -- 入力が途中で尽きるとパーサーは Await のまま止まる
    print (feed calc [TNum 1, TPlus])
