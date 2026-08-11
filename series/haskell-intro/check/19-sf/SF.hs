-- 【記事には載せない】ストリーム関数のアロー（決定事項 2 で本文から除外）。
-- runghc SF.hs
{-# LANGUAGE Arrows #-}
import Control.Arrow
import Control.Category
import qualified Prelude as P
import Prelude hiding ((.), id)

newtype SF b c = SF { runSF :: [b] -> [c] }

instance Category SF where
    id = SF P.id
    SF g . SF f = SF (g P.. f)

instance Arrow SF where
    arr f = SF (map f)
    first (SF f) = SF (unzip >>> first f >>> uncurry zip)

instance ArrowLoop SF where
    loop (SF f) = SF (\bs -> let (cs, ds) = unzip (f (zip bs (stream ds))) in cs)
      where stream ~(x:xs) = x : stream xs

delay :: b -> SF b b
delay x = SF (init P.. (x:))

counter :: SF Bool Int
counter = proc reset -> do
    rec output <- arr (\(r, n) -> if r then 0 else n) -< (reset, next)
        next   <- delay 0 -< output + 1
    returnA -< output

main :: IO ()
main = do
    print (runSF (arr (+1) >>> delay 0) [1,2,3::Int])
    print (runSF (arr (+1) &&& arr (*2)) [1,2,3::Int])
    print (runSF counter [False,False,True,False,False])
