-- instance Monad だけを書くとコンパイルが通らない
newtype Identity a = Identity { runIdentity :: a }

instance Monad Identity where
    Identity x >>= f = f x

main = print (runIdentity (Identity 3 >>= \x -> Identity (x * 2)))
