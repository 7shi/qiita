import Control.Monad (liftM)

-- 記事に載せた比較
main = do
    print $ fmap  (* 2) [1, 2, 3]
    print $ liftM (* 2) [1, 2, 3]
    -- liftM が >>= と return だけで書けること（記事では結論のみ）
    print $ liftM' (* 2) [1, 2, 3]

liftM' f m = m >>= \x -> return (f x)
