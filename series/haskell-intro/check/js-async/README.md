# Node.js のコールバックと async/await の対応（検証）

「Node.js の `readFile` がコールバックを取るのは継続渡しで、async/await として
抽象化されている」という見方が、記事の構成（構成案 2・6・7）とどう対応するかの検証。
Node v25.8.2 / Python 3.14.3。

| ファイル | 内容 |
|---|---|
| `01-callback.js` | `readFile(path, cb)` の `cb` が継続であること、ネストする様子 |
| `02-cont.js` | それを継続モナドで包む。Promise との対応 |
| `03-generator.js` | 双方向ジェネレーター + ドライバー = async/await の実装方式 |
| `04-async.js` | async/await 版。03 と同じ出力 |
| `05-contextmanager.py` | Python の `with` がジェネレーターで実装できること |

実行は `node 01-callback.js` など。`hello.txt`・`world.txt` を読む
（`missing.txt` は存在しない前提で失敗パスの確認に使う）。

## 確認できたこと

### コールバックは継続で、部分適用すると `(a -> r) -> r`

```js
const readFileK = path => cb => fs.readFile(path, 'utf8', cb);
```

`path` を部分適用すると `(cb) => void` になる。Haskell の `(a -> r) -> r` と同じ形
（`r` は `void`）。継続が値になっているので、後から渡すこともできる（`01-callback.js` で確認）。

これは構成案 7 の `withFile path mode :: (Handle -> IO r) -> IO r` と同じ話。
**`with` 系と Node のコールバックは同じ形**で、どちらも継続渡しになっている。

### Node の `(err, data)` は Haskell 1.0 の 2 継続を 1 つに畳んだもの

```js
// Node の慣習
fs.readFile(path, 'utf8', (err, data) => ...)

// 分けて書くと Haskell 1.0 の readFile と同じ
const readFileT = path => (fail, succ) =>
    fs.readFile(path, 'utf8', (err, data) => (err ? fail(err) : succ(data)));
```

```hs
-- Haskell 1.0 Report
readFile :: Name -> FailCont -> StrCont -> Behaviour
```

失敗継続を固定すると `Cont` になるところまで同じ。

```js
const abort = e => console.error(e.message);
const readFileC = path => Cont(k => readFileT(path)(abort, k));
```

`../../../../articles/haskell/check/haskell-io-history/ContIO.hs` の

```hs
readFileC name = Cont (readFileT name abort)
```

と一対一に対応する。**Haskell 1.0 の I/O モデルは、実質 Node のコールバック API だった。**

### 括弧が積み上がるところまで同じ

`01-callback.js` のネストは、History of Haskell が Figure 4 について言う
「ラムダが入れ子になるにつれ括弧が積み上がる」そのもの。
JavaScript では callback hell と呼ばれた。**同じ問題が 1990 年と 2010 年代に
別々の場所で起きて、どちらも同じ方向（`do` 記法／async-await）で解決された。**

### 双方向ジェネレーター + ドライバー = async/await

これが一番強い対応。async/await が言語に入る前、実際にこの方式が使われていた
（`co` ライブラリ、babel の regenerator など）。

```js
function drive(genFn) {
    const it = genFn();
    function step(err, value) {
        if (err) return it.throw(err);
        const { value: action, done } = it.next(value);   // ← 双方向の再開
        if (done) return;
        action(step);                                     // action は (k) => void ＝ Cont
    }
    step();
}

drive(function* () {
    const a = yield readFileK('hello.txt');
    const b = yield readFileK('world.txt');
    console.log(a.trim() + ' ' + b.trim());
});
```

**`it.next(value)` が構成案 6 (a) の双方向ジェネレーターそのもの。**
`yield` の戻り値が「次の再開時に渡された値」になる。
そして `drive` は Haskell 側の

```hs
drive :: (o -> IO (Maybe i)) -> Gen i o -> IO ()   -- check/gen-io/GenBiIO.hs
```

と同じ形。ジェネレーターが「やってほしいこと」を `yield` し、ドライバーが
実行して結果を渡して再開する。**構成案 6 (a) + (b) を組み合わせたものが
async/await の実装方式だった**ということになる。

交互に進む様子も `gen-io` の出力と同形だった。

```
  [gen] request 1
  [drv] got an action, running it
  [drv] resume with "Hello,"
  [gen] received "Hello,"
  [gen] request 2
  ...
  [drv] done
```

`04-async.js` の async/await 版は `03-generator.js` と同じ出力になる。
`yield` → `await`、自前のドライバー → 言語組み込み、の違いだけ。

### Python の `with` はジェネレーターで実装できる（構成案 6 と 7 を繋ぐ）

```python
@contextmanager
def res(name):
    print(f"open  {name}")
    try:
        yield name        # ここで中断し、with の本体が走る
    finally:
        print(f"close {name}")
```

```
open  A
open  B
use AB
close B
close A
```

**`../cont-resource/Order.hs` の出力と完全に一致する。**

さらにジェネレーターを手で駆動すると、`with` の本体が継続であることが露わになる。

```python
def with_(gen, body):
    value = next(gen)     # setup してから中断
    try:
        body(value)       # ← ここが継続
    finally:
        next(gen)         # teardown（yield の後ろ）
```

`with_` は `runContT`、`body` は継続。つまり **`ContT` によるリソース管理（構成案 7）と
コルーチン（構成案 6）は別の応用ではなく、同じ仕組みの別の使い方**。
Python は `with` を generator で実装することでそれを実証している。

## 対応表

| 継続モナド | Haskell 1.0 (1990) | Node.js | Python |
|---|---|---|---|
| `(a -> r) -> r` | `StrCont -> Behaviour` | `cb => void` | — |
| 答えの型 `r` | `Behaviour`（要求の列） | `void` | — |
| 失敗＋成功の 2 継続 | `FailCont` / `StrCont` | `(err, data)` に畳む | — |
| `Cont` に包む | 継続 I/O（Report の派生層） | `Promise` | `awaitable` |
| `>>=` | `>>>`（`f >>> x = f abort x`） | `.then()` | — |
| 括弧の山 | Figure 4 | callback hell | — |
| `do` 記法 | Haskell 1.3 のモナド I/O | `async`/`await` | `async`/`await` |
| `yield` + ドライバー | — | `co` / regenerator | `@contextmanager` |
| `ContT` でリソース管理 | — | — | `with` |

## 記事への使い方

読者の多くが async/await を知っているので、**継続モナドの入口として使える**。
詳細は PLAN.md の「他言語との対応」節を参照。
