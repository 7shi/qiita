-- callCC で ContT の途中から脱出したとき、リソースが解放されるか
import Control.Monad.Cont
import Control.Monad.IO.Class (liftIO)
import Control.Exception (bracket_)

withRes :: String -> (String -> IO r) -> IO r
withRes name = bracket_ (putStrLn $ "open  " ++ name)
                        (putStrLn $ "close " ++ name)
             . ($ name)

escape :: IO ()
escape = evalContT $ callCC $ \exit -> do
    a <- ContT $ withRes "A"
    liftIO $ putStrLn $ "use " ++ a
    exit ()                            -- ここで脱出
    b <- ContT $ withRes "B"           -- 実行されない
    liftIO $ putStrLn $ "use " ++ b

main :: IO ()
main = escape >> putStrLn "done"
