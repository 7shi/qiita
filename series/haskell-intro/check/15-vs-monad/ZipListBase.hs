-- base の ZipList をそのまま使い、ZipList.hs（写した定義）と同じ結果になることを確認する
import Control.Applicative

main = do
    print $ (+) <$> [1, 2, 3] <*> [10, 20, 30]
    print $ getZipList $ (+) <$> ZipList [1, 2, 3] <*> ZipList [10, 20, 30]
