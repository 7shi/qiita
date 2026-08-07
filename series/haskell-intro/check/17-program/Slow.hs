{-# LANGUAGE GADTs #-}
-- 左結合の >>= が遅くなることの確認（16 回 check/16-gen/Slow.hs の Operational 版）
import Control.Monad (liftM, ap)
import System.Environment (getArgs)


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

data GenI o a where
    Yield :: o -> GenI o ()

type Gen o = Program (GenI o)

yield :: o -> Gen o ()
yield x = singleton (Yield x)

toList :: Gen o a -> [o]
toList (Return _)       = []
toList (Yield o :>>= k) = o : toList (k ())

-- 右結合: yield 1 >> (yield 2 >> (yield 3 >> ...))
right :: Int -> Gen Int ()
right n = foldr (\x acc -> yield x >> acc) (return ()) [1 .. n]

-- 左結合: ((yield 1 >> yield 2) >> yield 3) >> ...
left :: Int -> Gen Int ()
left n = foldl (\acc x -> acc >> yield x) (return ()) [1 .. n]

main :: IO ()
main = do
    args <- getArgs
    let n = read (args !! 1)
    case head args of
        "right" -> print $ sum $ toList $ right n
        _       -> print $ sum $ toList $ left n
