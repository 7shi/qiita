class Container f where
    empty :: f a
    wrap  :: a -> f a

-- Int は種が * なので Container（* -> * を要求）のインスタンスにできない
instance Container Int where
    empty  = 0
    wrap _ = 0

main = return ()
