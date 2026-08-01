# IO と交互に進むジェネレーターの検証（構成案 6 (b)）

`ContT r IO` に持ち上げて、`yield` の間で IO を実行できるか。
GHC 9.6.6 / transformers 0.6.1.0。実行は `runghc {ファイル名}`。
`GenIO.hs` は標準入力を読むので `printf 'foo\nbar\n\n' | runghc GenIO.hs` で実行する。

| ファイル | 内容 |
|---|---|
| `GenIO.hs` | 生産専用ジェネレーターを `ContT r IO` に持ち上げたもの |
| `GenBiIO.hs` | (a) の双方向と (b) の IO を組み合わせたもの |

純粋版は zenn リポジトリの `check/20260730-haskell-generator/GenStd.hs`、
双方向の純粋版は `../13-gen-bidirectional/`。

## 確認できたこと

### 持ち上げの差分は機械的

```hs
data Gen a = Done | Yield a (ContT (Gen a) IO (Gen a))  -- Cont → ContT ... IO
type GenM a = ContT (Gen a) IO
runGen :: (Out a -> GenM a x) -> IO (Gen a)             -- 結果が IO に包まれる
```

**`yield` の定義は純粋版と 1 文字も変わらない。**

```hs
yield ccOut v = callCC $ \next -> ccOut (Yield v (next ()))
```

`evalCont` → `evalContT`、生産側で `liftIO` を使う、`runGen` の結果が `IO (Gen a)` になる。
それだけ。PLAN の「`StateT` と同じ要領で `Cont` に `m` が挟まる」で足りることを確認した。

`liftIO` は `Control.Monad.IO.Class` から明示的に import が必要
（`Control.Monad.Trans.Cont` は再輸出しない）。`../13-cont-resource/` と同じ注意点。

### 生産と消費が交互に進む

```
  produce 1
  consume 1
  produce 2
  consume 2
  produce 3
  consume 3
[1,2,3]
```

生産側の `liftIO $ putStrLn` と消費側の `putStrLn` が期待どおり交互に出た。
「出す」タイミングと IO の順序が結び付いている。

### 遅延がなくなる — ここが (b) の本当の見せ場

純粋版では `take 5 (toList nats)` が遅延のおかげでそのまま動いた。
`ContT r IO` では `toList` が `IO [a]` になるので遅延が効かず、
**無限ジェネレーターは打ち切るドライバーを自分で書く必要がある。**

さらに素朴に書くと 1 つ余分に生産される。

```hs
takeIOEager n (Yield v k) = do
    g <- evalContT k              -- 必要か判断する前に再開してしまう
    (v :) <$> takeIOEager (n - 1) g
```

```
  produce 0
  produce 1
  produce 2
  produce 3     ← 3 個しか要らないのに 4 回生産される
[0,1,2]
```

再開の前に打ち切りを判定すれば直る。

```hs
takeIO n (Yield v k)
    | n == 1 = return [v]
    | otherwise = do g <- evalContT k; (v :) <$> takeIO (n - 1) g
```

```
  produce 0
  produce 1
  produce 2
[0,1,2]
```

**純粋版で遅延が何をしてくれていたかが、副作用を付けた瞬間に見える。**
構成案 5（リストとの境界）で「遅延評価は消費されるまで計算しない」と言ったことの裏返しで、
記事では 5 と対にして書けるとよい。

### (a) と (b) は組み合わせられる（`GenBiIO.hs`）

双方向のまま `ContT ... IO` にしても通る。`yield` は純粋な双方向版と同一。

これで**出力を見てから次の入力を IO で決める**ドライバーが書ける。

```hs
drive :: (o -> IO (Maybe i)) -> Gen i o -> IO ()
```

```
  [gen] total = 0
  [drv] got 0
  [drv] send 1
  [gen] total = 1
  [drv] got 1
  [drv] send 2
  [gen] total = 3
  [drv] got 3
  [drv] send 4
  [gen] total = 7
  [drv] got 7
  [drv] stop
```

リストでは（遅延しても）「出力を見て入力を決める」ループは書けないので、
**(a) 単独より「リストを超えた」ことが分かりやすい。**
構成案では (b) を短くする方針だが、(a) の締めとしてこの例を置く手もある。
なお `drive` は再開前に継続するか判断するので、余分な生産は起きない。

## 残り

構成案 6 (c) の `await`（消費側のコルーチン）は未検証。
