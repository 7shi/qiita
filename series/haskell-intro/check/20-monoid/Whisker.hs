import Control.Monad

-- ηT・Tη: T ⇒ T∘T
tEta, etaT :: forall m a. Monad m => m a -> m (m a)
tEta = fmap @m (return @m @a)   -- Tη: 内側を m で包む
etaT = return @m @(m a)         -- ηT: 外側を m で包む

-- μT・Tμ: T³ ⇒ T²
tMu, muT :: forall m a. Monad m => m (m (m a)) -> m (m a)
tMu = fmap @m (join @m @a)      -- Tμ: 内側を m で包む
muT = join @m @(m a)            -- μT: 外側を m で包む

main :: IO ()
main = do
    -- 型は同じでも作用する側が違う
    print $ tEta [1, 2, 3 :: Int]
    print $ etaT [1, 2, 3 :: Int]
    print $ tMu [[[1], [2]], [[3 :: Int]]]
    print $ muT [[[1], [2]], [[3 :: Int]]]
    -- 単位律: μ ∘ Tη == id、μ ∘ ηT == id
    print $ (join . tEta) [1, 2, 3 :: Int] == [1, 2, 3]
    print $ (join . etaT) [1, 2, 3 :: Int] == [1, 2, 3]
    -- 結合律: μ ∘ Tμ == μ ∘ μT
    print $ (join . tMu) [[[1], [2]], [[3 :: Int]]]
         == (join . muT) [[[1], [2]], [[3 :: Int]]]
