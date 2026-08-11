-- 配線の例（平均）と練習【問1】の解答例（spread）。
-- runghc Mean.hs
import Control.Arrow

mean :: [Double] -> Double
mean = (sum &&& (fromIntegral . length)) >>> uncurry (/)

spread :: [Int] -> Int
spread = (maximum &&& minimum) >>> uncurry (-)

main :: IO ()
main = do
    print $ mean [1, 2, 3, 4]
    print $ spread [3, 1, 4, 1, 5]
