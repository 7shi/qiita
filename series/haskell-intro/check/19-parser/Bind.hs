-- 【意図的にコンパイルが通らないファイル】
-- モナドの >>= にあたるものを P に書こうとすると、静的な情報が確定できないことの実演。
-- runghc Bind.hs → Found hole: _ :: c（README を参照）
import Control.Arrow
import Control.Category
import Prelude hiding ((.), id)

newtype P b c = P ([Char], [Char] -> b -> Maybe (c, [Char]))

instance Category P where
    id = P ([], \s b -> Just (b, s))
    P (t2, g) . P (t1, f) = P (t1 ++ t2, \s b -> f s b >>= \(x, s') -> g s' x)

instance Arrow P where
    arr f = P ([], \s b -> Just (f b, s))
    first (P (t, f)) = P (t, \s (b, d) -> fmap (\(c, s') -> ((c, d), s')) (f s b))

expects :: P b c -> [Char]
expects (P (t, _)) = t

-- モナドの >>= にあたるものを書こうとすると、静的な情報が確定できない
bindP :: P b c -> (c -> P b d) -> P b d
bindP (P (t1, f)) k = P (t1 ++ expects (k _), \s b -> Nothing)
