-- pure を書かずに return だけを実装した場合
import Control.Monad (liftM, ap)

newtype Foo a = Foo a deriving Show

instance Functor Foo where
    fmap  = liftM

instance Applicative Foo where
    (<*>) = ap

instance Monad Foo where
    return = Foo
    Foo x >>= f = f x

main = print (return 1 >>= \x -> Foo (x * 2) :: Foo Int)
