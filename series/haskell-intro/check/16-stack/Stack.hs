-- 16 回 練習【問3】【問4】スタックマシン DSL
-- Free の定義は本文の再掲（単体で runghc できるように補ってある）
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

-- 【問3】
data StackF next
    = Push Int next
    | Pop (Int -> next)
    deriving Functor

type Stack = Free StackF

push :: Int -> Stack ()
push n = liftF (Push n ())

pop :: Stack Int
pop = liftF (Pop id)

calc :: Stack Int
calc = do
    push 3
    push 4
    a <- pop
    b <- pop
    push (a + b)
    pop

-- 【問4】
runStack :: [Int] -> Stack a -> a
runStack _        (Pure a)          = a
runStack st       (Free (Push n k)) = runStack (n : st) k
runStack []       (Free (Pop k))    = runStack [] (k 0)
runStack (x : xs) (Free (Pop k))    = runStack xs (k x)

main :: IO ()
main = print $ runStack [] calc
