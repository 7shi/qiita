-- Two をタプルの型シノニムで済ませようとするとコンパイルできないことの確認。
-- 期待する結果はコンパイルエラー（README 参照）。

data Free f a = Pure a | Free (f (Free f a))

type Two x = (x, x)

type Tree = Free Two

main :: IO ()
main = putStrLn "compiled"
