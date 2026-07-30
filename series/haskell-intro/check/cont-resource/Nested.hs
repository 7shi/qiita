-- ContT を使わない場合: withFile のネストが深くなる
import System.IO

copyFile :: FilePath -> FilePath -> IO ()
copyFile src dest =
    withFile src ReadMode $ \hSrc ->
        withFile dest WriteMode $ \hDest -> do
            content <- hGetContents hSrc
            hPutStr hDest content

main :: IO ()
main = do
    writeFile "a.txt" "hello\nworld\n"
    copyFile "a.txt" "b.txt"
    readFile "b.txt" >>= putStr
