{-# LANGUAGE GADTs #-}
-- 17 回 練習【問1】【問2】スタックマシン DSL（16 回【問3】【問4】の書き直し）
-- Program の定義は本文の再掲（単体で runghc できるように補ってある）
import Control.Monad (liftM, ap)


data Program instr a where
    Return :: a -> Program instr a
    (:>>=) :: instr b -> (b -> Program instr a) -> Program instr a

instance Functor (Program instr) where
    fmap = liftM

instance Applicative (Program instr) where
    pure  = Return
    (<*>) = ap

instance Monad (Program instr) where
    Return a   >>= k = k a
    (i :>>= j) >>= k = i :>>= (\b -> j b >>= k)

singleton :: instr a -> Program instr a
singleton i = i :>>= Return

-- 【問1】
data StackI a where
    Push :: Int -> StackI ()
    Pop :: StackI Int

type Stack = Program StackI

push :: Int -> Stack ()
push n = singleton (Push n)

pop :: Stack Int
pop = singleton Pop

calc :: Stack Int
calc = do
    push 3
    push 4
    a <- pop
    b <- pop
    push (a + b)
    pop

-- 【問2】
runStack :: [Int] -> Stack a -> a
runStack _        (Return a)      = a
runStack st       (Push n :>>= k) = runStack (n : st) (k ())
runStack []       (Pop :>>= k)    = runStack [] (k 0)
runStack (x : xs) (Pop :>>= k)    = runStack xs (k x)

main :: IO ()
main = print $ runStack [] calc
