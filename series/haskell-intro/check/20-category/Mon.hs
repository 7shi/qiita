import Control.Category
import Data.Monoid (Sum(..))
import Prelude hiding ((.), id)

newtype Mon m a b = Mon m deriving (Show, Eq)

instance Monoid m => Category (Mon m) where
    id = Mon mempty
    Mon g . Mon f = Mon (f <> g)

unMon :: Mon m a b -> m
unMon (Mon m) = m

step :: String -> Mon [String] () ()
step s = Mon [s]

cost :: Int -> Mon (Sum Int) () ()
cost n = Mon (Sum n)

main :: IO ()
main = do
    print (step "a" >>> step "b" >>> step "c")
    -- 単位律
    print (id >>> step "a")
    print (step "a" >>> id)
    -- 結合律
    print (((step "a" >>> step "b") >>> step "c")
            == (step "a" >>> (step "b" >>> step "c")))
    -- 単位元はモノイドによって変わる
    print (getSum (unMon (cost 3 >>> id >>> cost 4)))
