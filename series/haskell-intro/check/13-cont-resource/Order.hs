-- 解放の順序と、ContT を抜けた後にリソースが閉じていることの確認
import Control.Monad.Cont
import Control.Monad.IO.Class (liftIO)
import Control.Exception (bracket_, try, SomeException)
import System.IO

-- withFile の代わりに、取得・解放をログ出力する疑似リソース
withRes :: String -> (String -> IO r) -> IO r
withRes name = bracket_ (putStrLn $ "open  " ++ name)
                        (putStrLn $ "close " ++ name)
             . ($ name)

nested :: IO ()
nested =
    withRes "A" $ \a ->
        withRes "B" $ \b ->
            putStrLn $ "use " ++ a ++ b

flat :: IO ()
flat = evalContT $ do
    a <- ContT $ withRes "A"
    b <- ContT $ withRes "B"
    liftIO $ putStrLn $ "use " ++ a ++ b

-- 遅延 IO の罠: ContT を抜けてから読むと閉じたハンドルを触る
lazyTrap :: IO ()
lazyTrap = do
    writeFile "a.txt" "hello\n"
    content <- evalContT $ do
        h <- ContT $ withFile "a.txt" ReadMode
        liftIO $ hGetContents h        -- まだ読んでいない
    r <- try (putStr content) :: IO (Either SomeException ())
    print r

main :: IO ()
main = do
    putStrLn "=== nested ==="   >> nested
    putStrLn "=== flat ==="     >> flat
    putStrLn "=== lazyTrap ===" >> lazyTrap
