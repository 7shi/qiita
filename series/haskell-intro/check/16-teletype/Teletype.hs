{-# LANGUAGE DeriveFunctor #-}
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
    deriving Functor

type Teletype = Free TeletypeF

putLine :: String -> Teletype ()
putLine s = liftF (PutLine s ())

getLine' :: Teletype String
getLine' = liftF (GetLine id)

greet :: Teletype ()
greet = do
    putLine "name?"
    name <- getLine'
    putLine ("Hello, " ++ name ++ "!")

-- 純粋インタプリタ（テスト用モック）
runPure :: [String] -> Teletype a -> [String]
runPure _        (Pure _)             = []
runPure ins      (Free (PutLine s k)) = s : runPure ins k
runPure []       (Free (GetLine k))   = runPure [] (k "")
runPure (i : is) (Free (GetLine k))   = runPure is (k i)

-- IO インタプリタ（本文では散文で触れるだけ。main では使わない）
runIO :: Teletype a -> IO ()
runIO (Pure _)             = return ()
runIO (Free (PutLine s k)) = putStrLn s >> runIO k
runIO (Free (GetLine k))   = getLine >>= runIO . k

main :: IO ()
main = do
    mapM_ putStrLn $ runPure ["Haskell"] greet
    mapM_ putStrLn $ runPure ["世界"] greet
