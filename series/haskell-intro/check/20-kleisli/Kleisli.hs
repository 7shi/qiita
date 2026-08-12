import Control.Arrow (Kleisli(..))
import Control.Category ((>>>))
import Control.Monad ((>=>))

-- 1 手で「1 を足す」か「2 倍する」（非決定性計算）
step :: Int -> [Int]
step n = [n + 1, n * 2]

main :: IO ()
main = do
    print (step 3)
    print ((step >=> step) 3)
    print ((step >=> step >=> step) 3)
    -- 左単位元・右単位元
    print ((return >=> step) 3 == step 3)
    print ((step >=> return) 3 == step 3)
    -- 結合法則
    print (((step >=> step) >=> step) 3 == (step >=> (step >=> step)) 3)
    -- Kleisli の >>> でも同じ
    print (runKleisli (Kleisli step >>> Kleisli step) 3)
