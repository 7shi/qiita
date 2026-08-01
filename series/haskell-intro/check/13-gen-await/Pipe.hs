{-# LANGUAGE RankNTypes #-}
-- 生産側（yield）と消費側（await）を 1 つの型に統合すると pipes / conduit の原型になる。
-- 3 段: 文字列 → 字句解析（await して yield する）→ 構文解析（await するだけ）。
import Control.Monad.Trans.Cont (Cont, cont, evalCont, callCC)

data Pipe i o r
    = PDone r
    | PYield o (() -> Cont (Pipe i o r) (Pipe i o r))
    | PAwait (i -> Cont (Pipe i o r) (Pipe i o r))

type PipeM i o r = Cont (Pipe i o r)

-- yield は () を、await は i を返すので、脱出継続の答えの型を
-- 1 つに固定できない。ここで初めて RankNTypes が要る。
type Out i o r = forall a. Pipe i o r -> PipeM i o r a

yield :: Out i o r -> o -> PipeM i o r ()
yield cc v = callCC $ \next -> cc (PYield v next)

await :: Out i o r -> PipeM i o r i
await cc = callCC $ \next -> cc (PAwait next)

-- callCC がくれる脱出継続は単相なので、そのままでは Out に渡せない。
-- 「呼んだら戻ってこない」ことを使い、答えを捨てる形で多相に付け直す。
escape :: (Pipe i o r -> Cont (Pipe i o r) (Pipe i o r)) -> Out i o r
escape cc p = cont (\_ -> evalCont (cc p))

runPipe :: (Out i o r -> PipeM i o r r) -> Pipe i o r
runPipe body = evalCont $ callCC $ \cc -> PDone <$> body (escape cc)

-- 下流駆動。下流が await したら上流を yield まで進める。
connect :: Pipe i m a -> Pipe m o b -> [i] -> Maybe b
connect _ (PDone r) _ = Just r
connect up (PYield _ k) is = connect up (evalCont (k ())) is
connect up (PAwait k) is = case up of
    PYield v up' -> connect (evalCont (up' ())) (evalCont (k v)) is
    PAwait ku -> case is of
        (i:is') -> connect (evalCont (ku i)) (PAwait k) is'
        [] -> Nothing
    PDone _ -> Nothing

data Token = TNum Int | TPlus | TMul | TEnd
    deriving (Show, Eq)

-- 字句解析器。await で文字を受け取り、yield でトークンを出す。
-- '\n' で TEnd を出したあとは、二度と再開されない前提で待ち続ける。
-- 数値は 1 桁のみ（複数桁にすると 1 文字の先読みを戻す仕組みが要る）。
lexer :: Pipe Char Token ()
lexer = runPipe $ \cc ->
    let loop = do
            c <- await cc
            case c of
                ' ' -> loop
                '+' -> yield cc TPlus >> loop
                '*' -> yield cc TMul >> loop
                '\n' -> yield cc TEnd >> loop
                _ | c `elem` ['0' .. '9'] ->
                        yield cc (TNum (fromEnum c - fromEnum '0')) >> loop
                  | otherwise -> error ("bad char: " ++ [c])
    in loop

-- 構文解析器。await するだけ（yield しないので出力の型は多相のまま）。
parser :: Pipe Token o Int
parser = runPipe $ \cc ->
    let num = do
            t <- await cc
            case t of
                TNum n -> return n
                _ -> error ("expected number, got " ++ show t)
        term = do
            v <- num
            t <- await cc
            termLoop v t
        termLoop v TMul = do
            v' <- num
            t <- await cc
            termLoop (v * v') t
        termLoop v t = return (v, t)
        expr = do
            (v, t) <- term
            exprLoop v t
        exprLoop v TPlus = do
            (v', t) <- term
            exprLoop (v + v') t
        exprLoop v t = return (v, t)
    in do
        (v, t) <- expr
        if t == TEnd then return v else error ("trailing " ++ show t)

run :: String -> Maybe Int
run s = connect lexer parser (s ++ "\n")

main :: IO ()
main = do
    print (run "1+2*3")
    print (run "2*3+4*5")
    print (run "1 + 2 + 3")
    print (run "7")
    -- 終端が来ないまま入力が尽きると Nothing
    print (connect lexer parser "1+2")
