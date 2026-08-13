import Control.Category
import Data.Monoid (Sum(..))
import Prelude hiding ((.), id)

newtype Mono m a b = Mono m deriving (Show, Eq)

instance Monoid m => Category (Mono m) where
    id = Mono mempty
    Mono g . Mono f = Mono (f <> g)

step :: String -> Mono [String] () ()
step s = Mono [s]

cost :: Int -> Mono (Sum Int) () ()
cost n = Mono (Sum n)

main :: IO ()
main = do
    print (step "a" >>> step "b" >>> step "c")
    -- 単位律
    print (id >>> step "a")
    print (step "a" >>> id)
    -- 結合律
    print (((step "a" >>> step "b") >>> step "c")
            == (step "a" >>> (step "b" >>> step "c")))
    -- 恒等射はモノイドによって変わる
    print (cost 3 >>> id >>> cost 4)
