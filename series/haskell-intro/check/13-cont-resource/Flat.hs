-- ContT でネストを平坦化する
import Control.Monad.Cont
import Control.Monad.IO.Class (liftIO)  -- mtl 2.3 では Control.Monad.Cont が再輸出しない
import System.IO

copyFile :: FilePath -> FilePath -> ContT r IO ()
copyFile src dest = do
    hSrc  <- ContT $ withFile src  ReadMode
    hDest <- ContT $ withFile dest WriteMode
    content <- liftIO $ hGetContents hSrc
    liftIO $ hPutStr hDest content

main :: IO ()
main = do
    writeFile "a.txt" "hello\nworld\n"
    evalContT $ copyFile "a.txt" "b.txt"
    readFile "b.txt" >>= putStr
