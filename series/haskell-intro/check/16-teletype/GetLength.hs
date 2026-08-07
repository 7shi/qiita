-- 本文「続きが関数のときの liftF」の getLength を確認する
import Control.Monad (liftM, ap)

data Free f a = Pure a | Free (f (Free f a))

instance Functor f => Functor (Free f) where
    fmap = liftM

instance Functor f => Applicative (Free f) where
    pure  = Pure
    (<*>) = ap

instance Functor f => Monad (Free f) where
    Pure a >>= k = k a
    Free g >>= k = Free (fmap (>>= k) g)

liftF :: Functor f => f a -> Free f a
liftF c = Free (fmap Pure c)

data TeletypeF next
    = PutLine String next
    | GetLine (String -> next)

instance Functor TeletypeF where
    fmap f (PutLine s next) = PutLine s (f next)
    fmap f (GetLine k)      = GetLine (f . k)

type Teletype = Free TeletypeF

putLine :: String -> Teletype ()
putLine s = liftF (PutLine s ())

-- 続きの位置に length を置くと、結果が Int になる
getLength :: Teletype Int
getLength = liftF (GetLine length)

-- 同じ形で id を置くと、結果が String になる（【問3】の getLine'）
getLine' :: Teletype String
getLine' = liftF (GetLine id)

-- liftF を通した形を直接書いたもの。getLength と一致するはず
getLengthExpanded :: Teletype Int
getLengthExpanded = Free (GetLine (\s -> Pure (length s)))

count :: Teletype ()
count = do
    putLine "name?"
    n <- getLength
    putLine ("length = " ++ show n)

greet :: Teletype ()
greet = do
    putLine "name?"
    name <- getLine'
    putLine ("Hello, " ++ name ++ "!")

runPure :: [String] -> Teletype a -> [String]
runPure _        (Pure _)             = []
runPure ins      (Free (PutLine s k)) = s : runPure ins k
runPure []       (Free (GetLine k))   = runPure [] (k "")
runPure (i : is) (Free (GetLine k))   = runPure is (k i)

-- 手順書から結果だけを取り出す（getLength 単体の型を見るため）
result :: [String] -> Teletype a -> a
result _        (Pure a)             = a
result ins      (Free (PutLine _ k)) = result ins k
result []       (Free (GetLine k))   = result [] (k "")
result (i : is) (Free (GetLine k))   = result is (k i)

main :: IO ()
main = do
    mapM_ putStrLn $ runPure ["Haskell"] count
    mapM_ putStrLn $ runPure ["Haskell"] greet
    print $ result ["Haskell"] getLength           -- 7
    print $ result ["Haskell"] getLengthExpanded   -- 7（展開形と一致）
    putStrLn $ result ["Haskell"] getLine'         -- Haskell
