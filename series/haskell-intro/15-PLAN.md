# Haskell モナドとゆかいな仲間たち プラン

記事番号は 15、ファイル名は `15-monads-and-friends.md`（予定）。

**状態: 未着手。この文書は執筆前の構成案。**
検討事項は 2026-08-05 の議論で全て決着した。以降は `決定事項` に従って執筆する。

## 公開方針

[README.md](README.md) の「公開方針（13回以降）」に従う。14 回と同じ扱い。

- **執筆はこの Qiita 側リポジトリで行い、公開は Zenn。** Qiita には投稿しないので
  フロントマターの `id`・`url` は空のままにする。
- 補足・折りたたみは最初から **Zenn 記法**（`:::message`・`:::details`）を使う。
- 完成後、Zenn リポジトリ（`~/repos/zenn`）へ複製し、[ZENN.tsv](../../ZENN.tsv) に追記する。
- 練習問題は 13・14 回に倣い、**解答を別記事に分けず `:::details` で本文に統合**する。
- 検証コードは `check/15-*/` に置き、各ディレクトリに `README.md` を入れる。

## 記事の狙い

**ゴールは「`instance Monad` を書いてモナドを自作できること」**（14 回推敲時の決定）。

14 回で型クラスの仕組み（`class`・`instance`・スーパークラス・種）は済ませた。
15 回はその**具体的な適用先として `Monad` の階層を開く**回になる。

### この回の一行の主張

シリーズは既に主要モナドの bind を読者に**書かせている**。

| 回 | 練習 | 対象 |
|---|---|---|
| `07-list-monad.md:492` 問4 | `bind`・`return'` | リスト |
| `08-maybe-monad.md:329` 問2 | `bind` | `Maybe` |
| `09-state-monads.md:368` 問2 | `bind`・`return'` | ST |
| `09-state-monads.md:689` 問3 | `bind`・`return'`・`get'`・`put'` | State |
| `09-state-monads.md:814` 問5 | `bind`・`return'`・`ask'`・`local'` | Reader |
| `09-state-monads.md:985` 問7 | `bind`・`return'`・`tell'` | Writer |
| `13-continuation-monad.md:229` 本文 | `>>=`・`callCC`・`shift`/`reset` | `Cont` |

解答例も全て公開済み（`09a-state-monads.md:96` に State の bind がそのまま載っている）。
そして 09 回の問4・問6・問8 は「問3 で再実装した関数は**使わないで** `do` と `<-` で
書き直せ」という形だった。**自作した `bind` では `do` が使えなかったから**である。

> **読者は bind を何度も自分で書いてきた。足りなかったのは、それを `do` で
> 使えるようにする登録の仕組み、つまり `instance Monad` だった。**

これが 15 回の一行の主張になる。09 回から 10 年越しの回収であり、
「`instance Monad` を書こうとすると `Functor` と `Applicative` を先に書かされる」は
その登録手続きの中身の話として収まる。

GHC 9.6.6 で確認した実際の宣言がそのまま記事の骨格になる。

```hs
class              Functor f     where fmap  :: (a -> b) -> f a -> f b
class Functor f     => Applicative f where pure :: a -> f a
                                           (<*>) :: f (a -> b) -> f a -> f b
class Applicative m => Monad m       where (>>=) :: m a -> (a -> m b) -> m b
```

読者はシリーズ 3 回目から `<$>`・`<*>` を**使って**きたが、それが `Functor`・`Applicative`
という型クラスのメソッドだとは説明されていない（10 回で「今回の範囲を超える」と明記して先送り）。
14 回でスーパークラスを済ませた今、**階層として一度に回収できる**。

「ゆかいな仲間たち」は `Monad` の周りにいる型クラス群を指す。
本命は `Functor`・`Applicative`、そこに `Alternative`（08・12 回の回収）と
`MonadFail`（14 回から送られたもの）、`Foldable`（14 回の `Monoid` の再回収）が加わる。

### 記事の導入文（案・PREFACES.md 用）

> Haskell ではモナドと呼ばれる部品を組み合わせてプログラムを作ります。今まで何度も
> 手で書いてきた bind を `do` で使えるようにするのが `instance Monad` です。それを
> 書こうとすると `Functor`・`Applicative` を先に書かされます。この階層をたどりながら、
> 最後にモナドを自作します。

## シリーズ内で先送りされた内容（15 回が回収先）

**執筆時は必ずこの表の各箇所を開いて、当時の言い回しに繋がる形で書くこと。**
13・14 回と同じ「予告 → 回収」の作法を守る。

| 箇所 | 先送りされた内容 | 15 回での扱い |
|---|---|---|
| `03-actions.md:684-716` | Applicative スタイルを導入。詳細は kazu_yamamoto 氏の記事へリンクして済ませている | 回収。`<$>`/`<*>` の初出はここ |
| `07-list-monad.md:242` | 「Applicative スタイルでは関数に渡されるのはモナドではないため、型クラス制約は意識する必要がありません」 | 回収（`Applicative f =>` の形で改めて示す）|
| `08-maybe-monad.md:66` | モナド則を「今回の範囲を超える」として番外編へ誘導 | 構成案 7 で改めて誘導 |
| `08-maybe-monad.md:564` | `Alternative` を「MonadPlus だけで使える Applicative スタイルの一種」と説明し、「**正確には Monoid の知識が必要ですが、今回の範囲を超えるため詳細は省略します**」 | **回収。14 回で `Monoid` を済ませたので、ここが本命の回収先** |
| `09-state-monads.md:851`・`:981` | Writer の `w` に掛かる `Monoid` 制約を「今回の範囲を超える」として省略 | 14 回で `Monoid` は済んだ。構成案 8 の `Foldable`（`foldMap`）で `<>` を使うときに一言添えられる |
| `09-state-monads.md` 問4・問6・問8 | 自作 `bind` では `do` が使えず「再実装した関数は使わないで書き直せ」となっていた | **この回の一行の主張の出発点**（上記「記事の狙い」参照）|
| `10-monad-transformers.md:101-159` | `Identity` を「最も単純なモナド」として紹介済み | **構成案 6 の最小例として本命**。既知の型に初めて `instance` を書く形になる |
| `10-monad-transformers.md:965` | 「Applicative を直訳すれば『適用可能』です。（略）今回の範囲を超えるため詳細は省略します」 | **回収** |
| `10-monad-transformers.md:1003-1060` | `<$>` と `<*>` の違いを **bind による再実装**で説明済み（`f <$> m = do a <- m; return (f a)` / `mf <*> m = do f <- mf; a <- m; return (f a)`）| **足場として最大**。この再実装が `liftM`・`ap` そのものなので、`fmap = liftM` / `(<*>) = ap` の定型に直結する |
| `12-parsing.md:1360-1420` | `<*`・`*>` を「Applicative スタイルの一種」として使用 | 回収（`Applicative` のメソッドだと示す）|
| `12-parsing.md:1584` | 引用ツイート「`<|>` は `Alternative` 型クラスのメソッドです」「Alternative は制限の緩い MonadPlus」 | **回収** |
| `13-continuation-monad.md:226-246` | `Cont` の bind の実装を**本文で公開済み**（`callCC`・`shift`/`reset` の実装も） | **一行の言及に留める。** 構成案 5 で「13 回で見た `Cont` の bind は、この `instance Monad` の中身そのもの」と繋ぐだけ。本文の題材にも練習にもしない（決定事項 5）|
| `14-type-classes.md` 全体 | `pure` という語を出さず `return` 表記で通した（決定事項 6）| **`return` と `pure` の関係をここで一度きちんと断る** |
| 14 回から送られたもの | `MonadFail`（14 回決定事項 8）| 扱う（構成案 8）|

## 構成案

### 1. モナドは階層の一番上

- 14 回のまとめで「`Monad` は種が `* -> *` の型クラスの一例」まで示した。その続きとして入る。
- **導入は「一行の主張」から。** 09 回で手で書いた `bind` を思い出させ、
  「あれを `do` で使えるようにする手続きが `instance Monad` だ」と据える。
- `:i Monad` を GHCi で見せると `class Applicative m => Monad m` と出る。
  **14 回で説明したスーパークラスがここに効いている。**
- 3 つの階層を先に図示して見取り図にする（まとめで戻る）。

  | 型クラス | メソッド | できること |
  |---|---|---|
  | `Functor` | `fmap` (`<$>`) | 中身に関数を適用する |
  | `Applicative` | `pure`, `<*>` | 引数が複数ある関数を適用する |
  | `Monad` | `>>=` | 前の結果を見て次を決める |

- 14 回の自作 `Container`（`empty`・`wrap`）を思い出させて繋ぐ。
  **`wrap` が `pure`、`empty` が `Alternative` の `empty` に対応する**ので、
  14 回の題材がそのまま踏み台になる（14-PLAN の引き継ぎに明記されている）。

### 2. Functor

- `fmap :: (a -> b) -> f a -> f b`。`<$>` は `fmap` の演算子版。
- 既習の道具との接続。**リストの `map` が `fmap` の特殊化**というのが一番分かりやすい入口。
  `Maybe`・`IO` でも同じ形で使えることを見せる。
- 10 回の再実装（`f <$> m = do a <- m; return (f a)`）を引き直し、
  **あれは `Monad` の道具で `Functor` の機能を書いていた**と位置付け直す。
  `liftM` が `fmap` と同じ働きなのもこれで説明が付く（10 回で「`<$>` は `liftM` の
  演算子版」と述べたことの理由が出る）。
- Functor 則（`fmap id == id` / `fmap (f . g) == fmap f . fmap g`）は**名前と 2 行**に留める。
  詳細は番外編の[モナド則がちょっと分かった？](https://qiita.com/7shi/items/547b6137d7a3c482fe68)と
  同じ扱い（構成案 7 でまとめてリンク）。
- ⚠ 関手・圏論には踏み込まない。シリーズは 3 回目から一貫して
  「圏論には言及しません」と書いており、ここで方針を変えない（決定事項 10）。
- **末尾に練習【問1】**（`Pair` に `Functor`）。

### 3. Applicative

- **入口は「`Functor` だけでは足りない場面」。** 2 引数の関数を `fmap` すると途中で止まる。

  ```hs
  (+) <$> Just 1              -- Maybe (Int -> Int) になってしまう
  (+) <$> Just 1 <*> Just 2   -- Just 3
  ```

  10 回の「部分適用とモナド」の節（`:1020` 付近）が**この説明を既にやっている**ので、
  そのまま引き直せる。`<*>` は「モナドに入った関数を適用する」演算子。
- `pure`。**`return` との関係をここで断る**（14 回決定事項 6 の回収）。
  - 現在の GHC では `return` は `Monad` のメソッドではあるが**デフォルト実装が `pure`** で、
    `:i Monad` の `MINIMAL` は `(>>=)` だけ（GHC 9.6.6 で確認済み）。
  - つまり**自作モナドで書くべきは `pure` の方**。`return` を実装しても意味がない
    （書けるが非推奨）。これは構成案 6 の実装で直に効くので、**予告として置く**。
  - シリーズ全体が `return` 表記で通してきたことの断りもここで入れる。
    14 回までの記述を書き換える必要はない、と明示する。
- `<*`・`*>` に一言（12 回で使用済み）。`liftA2` は名前だけ、または落とす。
- **Applicative スタイルの正体**。03・07・10・12 回でずっと使ってきた書き方が
  この型クラスだった、と回収する。07 回の「型クラス制約を意識する必要がない」も
  `Applicative f =>` で書き直して見せる。
- **末尾に練習【問2】**（問1 の `Pair` に `Applicative`）。

### 4. Applicative と Monad の違い（**この回の山場の 1 つ**）

- **`<*>` では「前の結果を見て次を決める」ことができない。** ここが階層が 2 段ある理由。

  ```hs
  [1,2,3] >>= \x -> replicate x x   -- 次の計算が x に依存する
  (,) <$> [1,2] <*> [10,20]         -- 組み合わせの構造は事前に決まっている
  ```

- `Maybe` で言えば、`<*>` は「両方成功したら適用」で、
  `>>=` は「前の結果を見て次に進むか決める」。08 回の使い方がそのまま例になる。
- **`>>=` があれば `<*>` は書ける**（`ap`）が、逆は書けない。
  これが `class Applicative m => Monad m` という向きの根拠。
  10 回の `<*>` 再実装（bind で書いていた）が `ap` そのものなので、そこを指し直す。
- **`ZipList` を出す**（決定事項 3）。`Applicative` だが `Monad` にできない実例。
  - ⚠ **見せ方に注意。** 「モナド則を満たせない」ではなく
    **「`<*>` と整合する `>>=` が存在しない」**（書いても `ap` と食い違う）という形にする。
    `Monad` の法則に `(<*>) = ap` が含まれるので結論は同じだが、こちらの方が読者に伝わる。
  - base にある型なので自作せず、数行で済ませる。`pure = ZipList . repeat` は
    触れるなら一言（無限リストが要る理由）。
- ⚠ 「Applicative は並列にできる／Monad はできない」といった応用上の含意には
  踏み込まない（超入門の射程外）。

### 5. 階層を書かされる（AMP）

- **`instance Monad` だけを書くとコンパイルが通らない。** 実際のエラーを見せる（TODO）。
- 定型を示す。

  ```hs
  instance Functor     Foo where fmap  = liftM
  instance Applicative Foo where pure  = ...
                                 (<*>) = ap
  instance Monad       Foo where (>>=) = ...
  ```

  - `liftM`・`ap` は `Control.Monad`。10 回で `liftM` は既習。
  - ⚠ **`pure` に実際の実装を書き、`return` は書かない**（構成案 3 の回収）。
  - ⚠ `fmap = liftM` / `(<*>) = ap` は `>>=` に依存する定型なので、
    「本来は `Functor` から順に定義すべきだが、モナドがあれば機械的に埋まる」
    という位置付けで示す。
  - **13 回の `Cont` の一行回収はここ**（決定事項 5）。「13 回で書いた `Cont` の bind は、
    この `instance Monad` の中身そのもの」と繋げる。13 回を読んでいない読者にも負担がない。
- 歴史（AMP: Applicative Monad Proposal, GHC 7.10）は**数行の `:::message`** に留める。
  「昔は `Monad` が `Applicative` と無関係に定義できた」ことに触れておくと、
  古い記事・書籍を読むときに読者が混乱しない。シリーズ 3〜12 回自体が
  AMP 以前（2014〜2015 年）に書かれたものである点にも触れられる。

### 6. モナドを自作する（**この回のゴール**）

**`Identity` → 【問3】`State` → `Tree` → 【問4】`Rose`** の順に進む（決定事項 2・6）。

#### 6-1. Identity（最小例・丁寧に書く）

```hs
newtype Identity a = Identity { runIdentity :: a }

instance Functor Identity where
  fmap f (Identity x) = Identity (f x)
instance Applicative Identity where
  pure = Identity
  Identity f <*> Identity x = Identity (f x)
instance Monad Identity where
  Identity x >>= f = f x
```

- 10 回で「中に値が入っているだけの最も単純なモナド」として既習（`10-monad-transformers.md:101`）。
  13 回も「入口は `Identity` から地続き」で使っている。**既知の型に初めて `instance` を書く**形。
- ⚠ **ここは 3 つとも丁寧に手書きする**（決定事項 6）。定型はまだ出さない。
  `Functor`・`Applicative` を説明した意味がここで効く。
- 標準の `Identity` と名前が衝突するので、import しないか別名にする（TODO で確認）。

#### 6-2. 【問3】State（形式的な穴埋め）

- **与えるもの**: 内部関数の型 `s -> (a, s)`、bind のべた書き、テストコード（`main`）。
- **書かせるもの**: `newtype` 定義、`Functor`・`Applicative`・`Monad` の instance、`get'`・`put'`。
- 09 回問3（`09-state-monads.md:689`）で読者は既にこの bind を書いており、解答も公開済み
  （`09a-state-monads.md:96`）。**あえて与えるのが筋。** 手書きの bind を型クラスに
  登録するという 15 回の主題そのものを、手を動かして確認させる問題になる。
- 定型（`fmap = liftM` / `(<*>) = ap`）は 6-1 の後・この問題の前に出すか要検討 → 決定事項 6 により
  **6-3 の `Tree` で初めて定型を出す**ので、問3 は丁寧に書かせる。分量が重ければ
  解答例で定型版も併記する。

#### 6-3. Tree（本命・定型で埋める）

```hs
data Tree a = Leaf a | Node (Tree a) (Tree a)

instance Functor     Tree where fmap  = liftM
instance Applicative Tree where pure  = Leaf
                                (<*>) = ap
instance Monad       Tree where
  Leaf x   >>= f = f x
  Node l r >>= f = Node (l >>= f) (r >>= f)
```

- **`>>=` は「葉を部分木に差し替える＝接ぎ木」。** シリーズ未出の題材で、
  データ構造そのものがモナドになる例（`Maybe`・`State` 系とは毛色が違う）。
- ⚠ ここで**初めて定型を出す**（決定事項 6）。`Identity` で丁寧に書いた後なので、
  「モナドがあれば機械的に埋まる」という位置付けが伝わる。
- ⚠ **16 回の伏線であることは本文で明かさない**（決定事項 9）。
  「後で一般化されます」と先に言うと `Tree` が踏み台に見え、`>>=` を自分で書く
  達成感が薄れる。まとめでは「16 回の Free モナドは `Functor` を要求する」までに留める。

#### 6-4. 【問4】Rose（多分岐の木）

```hs
data Rose a = Leaf a | Node [Rose a]
```

- `Tree` の `Node (Tree a) (Tree a)` が `Node [Rose a]` になるだけ。
  書けるが写経ではない（`map` が要る）ちょうどよい難度。未出。
- `fmap f (Node ts) = Node (map (fmap f) ts)` / `Node ts >>= f = Node (map (>>= f) ts)`。

### 7. モナド則・その他の法則

- 自作したものが「本当にモナドか」は法則で決まる。3 つの法則を再掲し、
  **番外編の既存記事へ誘導する**（08 回 `:66` が予告した先でもある）。
  - [モナド則がちょっと分かった？](https://qiita.com/7shi/items/547b6137d7a3c482fe68)（`monad-laws-2.md`）
  - [モナド則の絵を描いてみた](https://qiita.com/7shi/items/539c2c46edfb5313cbc6)（`monad-laws.md`。
    上の記事に統合済みなので、リンクするのは前者だけでよい）
- Functor 則・Applicative 則は名前と「コンパイラは検査してくれない」ことだけ。
  **分量は短く。** 法則の証明はしない。

### 8. ゆかいな仲間たち（周辺の型クラス）

タイトルの「仲間たち」を回収する節。**それぞれ短く。**

- **`Alternative`**（08・12 回の回収）
  - `class Applicative f => Alternative f where empty :: f a; (<|>) :: f a -> f a -> f a`
    （GHC 9.6.6 で確認。`some`・`many` も持つが `MINIMAL` は `empty`・`<|>`）。
  - **08 回で「正確には Monoid の知識が必要」と妥協した箇所の回収**。
    14 回で `Monoid`（`mempty`・`<>`）を済ませたので、
    **`Alternative` は `f a` に対する `Monoid` だ**と一行で言える。
    `empty` ↔ `mempty`、`<|>` ↔ `<>` の対応表を出す。
  - 例は標準の `Maybe`・リストを使う（自作 `Tree` には `empty` に当たるものがない）。
  - 12 回の引用ツイート（`MonadPlus` は古い、`Alternative` を使え）もここで回収。
    `MonadPlus`・`mzero`・`mplus` は**名前を出すだけ**に留める。
  - 14 回の `Container` の `empty` がこれと同名なのは偶然ではない、と繋げられる。
- **`Foldable`**（決定事項 7・案 B）
  - `mapM_`・`sum`・`length`・`elem` がリスト以外でも使える理由。
  - **`Tree` に `instance Foldable` を書かせる**（本文。40 行程度）。

    ```hs
    instance Foldable Tree where
      foldMap f (Leaf x)   = f x
      foldMap f (Node l r) = foldMap f l <> foldMap f r
    ```

  - これだけで `sum`・`length`・`elem`・`toList`・`mapM_ print` が自作の `Tree` で動く。
    **自作した型が標準関数の群に一気に繋がる**という、`instance` を書く意味が
    最も分かりやすく出る場面。
  - **`foldMap` の `<>` が 14 回の `Monoid` の 2 度目の回収**になる。
    `Alternative` の直後に置くことで `Monoid` つながりで並ぶ（この節に置く理由）。
  - `Traversable` は**名前と 1 行**。「`mapM` の正体で、`Monad` ではなく
    `Applicative` があれば書ける」まで（決定事項 7）。`instance` は書かない。
- **`MonadFail`**（14 回決定事項 8 から送られたもの）
  - `do` の中のパターンマッチが失敗したときに呼ばれる `fail`。
  - `Maybe` では `Nothing`、リストでは `[]`、`IO` では例外になる。
    08 回・07 回で読者が既に踏んでいる挙動の説明になる。
  - 経緯（`Monad` から分離された）は 1〜2 行。**深追いしない。**

### 9. まとめ

- 構成案 1 の階層表に戻る。
- 一行の主張に戻る。「手で書いてきた bind が、`do` で使えるようになった」。
- 16 回（Free モナド）への引き。**Free モナドは `Functor` を要求する**ので、
  15 回が直接の前提になる（`DeriveFunctor` の導入も 16 回、14 回決定事項 9）。
  ⚠ `Tree` = `Free Two` であることはここでは明かさない（決定事項 9）。

## 練習（4 問、解答は `:::details` で本文に統合）

13・14 回に倣い、**関連する節の末尾に分散**させる。

| # | 位置 | 題材 | 狙い |
|---|---|---|---|
| 問1 | 構成案 2 末尾 | `data Pair a = Pair a a` に `Functor` | 未出のトイ型。最小の `fmap` |
| 問2 | 構成案 3 末尾 | 問1 の `Pair` に `Applicative` | `Pair f g <*> Pair x y = Pair (f x) (g y)`。階層を下から積む縮小版 |
| 問3 | 構成案 6-2 | `State` の形式的な穴埋め | 手書き bind を `instance` に登録する。15 回の主題そのもの |
| 問4 | 構成案 6-4 | 多分岐の木 `Rose`（`Leaf a` と `Node [Rose a]`）| `Tree` の変奏。写経にならない難度 |

- 問1 → 問2 は同じ型を続けるので連続性があるが、**狙いはぼやけない**
  （`Functor` を書いた型に `Applicative` を足すのは本文の主張の縮小版そのもの）。
- **16 回への伏線が二重に効く**（決定事項 9・本文では明かさない）。
  `data Two x = Two x x`（＝問1・2 の `Pair`）と `[]` を基底関手として、
  `Tree` = `Free Two`、`Rose` = `Free []` になる。16 回で `Free f` を出したとき、
  本文の題材と練習の題材が両方とも `f` を差し替えた実例として回収できる。
  `Functor` が要る理由も、`Node` の枝を辿るのに `map`／`fmap` が要ったことから直に出る。

## 決定事項

**覆す場合は理由を確認してから。**

1. **ゴールは `instance Monad` を書いてモナドを自作できること**（14 回推敲時の決定）。
   一行の主張は「手で書いてきた bind を `do` で使えるようにする登録の仕組み」。
2. **本文の自作モナドは `Identity`（最小例）と `Tree`（本命）の 2 本**（2026-08-05 決定）。
   `MyMaybe`・`Prob`（確率分布）・`State` 本文入りは不採用。
3. **`ZipList` を「`Applicative` だが `Monad` にできない」実例として構成案 4 に入れる**
   （2026-08-05 決定）。見せ方は「`<*>` と整合する `>>=` が存在しない」。
4. **`return` と `pure` の関係をここで断る**（14 回決定事項 6）。
   14 回までの `return` 表記は書き換えない。
5. **`Cont` は本文の題材にも練習にもしない**（2026-08-05 決定）。
   13 回が bind・`callCC`・`shift`/`reset` の実装を全て本文で公開済みのため
   （`13-continuation-monad.md:229`・`:282`・`:559`）。回収は構成案 5 の一行の言及のみ。
   14-PLAN の「`Cont` が自作モナドの題材の本命」という引き継ぎはこれで覆る。
6. **定型の順序: `Identity` は 3 つとも丁寧に手書き、`Tree` で初めて定型を出す**
   （2026-08-05 決定）。定型を先に出すと `Functor`・`Applicative` を説明した意味が薄れる。
7. **`Foldable` は `Tree` に `foldMap` を書かせて本文で扱う（構成案 8）。**
   `Traversable` は名前と 1 行のみ（2026-08-05 決定・案 B）。
   `Traversable` の `instance` まで書くと主題が「型クラスの階層一般」へ広がるため。
8. **`Alternative`（`<|>`）を回収する**（08 回 `:564`・12 回 `:1584`）。
   14 回で `Monoid` を済ませたことが前提材料になる。
9. **16 回の伏線（`Tree` = `Free Two`、`Rose` = `Free []`）は 15 回では明かさない**
   （2026-08-05 決定）。先に言うと `Tree` が踏み台に見え、自分で `>>=` を書く達成感が薄れる。
10. **圏論・関手には踏み込まない。** シリーズは 3 回目から一貫して「圏論には言及しません」と
    書いている（`09-state-monads.md:21` など）。`Functor` = 関手は名前の由来として一言のみ。
11. **`MonadFail` を扱う**（14 回決定事項 8 で 15 回へ送られた）。
12. **Filinski『Representing Monads』は入れない**（2026-08-05 決定）。
    `Cont` が本文から消えたことで置き場所自体が無くなった。16 回以降への引き継ぎに残す。
13. **言語拡張は出さない。** `DeriveFunctor` は 16 回（Free モナド）で動機が立ってから
    （14 回決定事項 9）。
14. **公開は Zenn、執筆は Qiita 側リポジトリ。** 練習の解答は `:::details` で本文に統合。

## 前提知識

**14 回までで揃っている。新規に前提となる材料はない。**

| 材料 | 出典 |
|---|---|
| `class` / `instance` / メソッド / デフォルト実装 / 最小完全定義 | `14-type-classes.md` |
| スーパークラス | 〃（`Semigroup` → `Monoid`）|
| 種（kind）・`:k`・種が `* -> *` の型クラス | 〃（自作 `Container`）|
| `Monoid` / `mempty` / `<>` | 〃（`Alternative`・`Foldable` の説明に必須）|
| 辞書渡し | 〃（必須ではないが、階層＝辞書の入れ子として説明できる）|
| `bind` を手で書いた経験 | `07:492`・`08:329`・`09:368`・`09:689`・`09:814`・`09:985` |
| `Identity` | `10-monad-transformers.md:101-159` |
| `<$>` / `<*>` の使い方 | `03-actions.md:684`、`10-monad-transformers.md:945` |
| `<$>` / `<*>` の bind による再実装 | `10-monad-transformers.md:1003-1060` |
| `liftM` / `liftM2` | `10-monad-transformers.md:900` 付近 |
| `<|>` の使い方 | `08-maybe-monad.md:564`、`12-parsing.md` |
| `<*` / `*>` の使い方 | `12-parsing.md:1360` |
| `State` の内部関数 `s -> (a, s)`・`get`・`put` | `09-state-monads.md:488-566` |
| `data` / `newtype` / レコード構文 | `02-algebraic-data-types.md` |

**未出**（15 回で初出になるもの）

- `Functor` / `fmap` / `Applicative` / `pure` という語（メソッドとして）
- `class Functor f => Applicative f => Monad m` の階層・AMP
- `ap` / `Alternative` の定義 / `MonadFail` / `mzero` / `mplus` / `ZipList`
- `Foldable` / `foldMap` / `Traversable`（名前のみ）
- Functor 則・Applicative 則（モナド則は番外編にあり）
- `instance Monad` を自分で書くこと
- `Pair` / `Tree` / `Rose` という題材

## 既存記事との関係

- **[モナド則がちょっと分かった？](https://qiita.com/7shi/items/547b6137d7a3c482fe68)**
  （`monad-laws-2.md`, 2014、いいね 247）— シリーズ番外編。構成案 7 の誘導先。
  [モナド則の絵を描いてみた](https://qiita.com/7shi/items/539c2c46edfb5313cbc6) は
  こちらへ統合済みなので、リンクは 1 本でよい。
- [Applicativeのススメ - あどけない話](http://d.hatena.ne.jp/kazu-yamamoto/20101211/1292021817)
  — 03 回が「詳細は次の記事が参考になります」として挙げている外部記事。
  **15 回はその「詳細」を自前で書く回**なので、03 回からの流れとして言及する価値がある。
- 【PDF】[あなたの知らない Monoid の世界](http://mew.org/~kazu/material/2012-monoid.pdf)
  — 08 回が `Alternative` の説明を妥協する際に挙げた資料。構成案 8 から改めてリンクできる。
- `articles/haskell/` の実験メモ群（`maybe-monad-infix.md`・`state-monad-infix.md` など）に
  `Functor`・`Applicative` の記述があるか要確認（TODO）。
- `articles/fsharp/monads-with-computation-expressions.md` — F# の
  コンピュテーション式でモナドを自作する記事。**自作モナドの他言語版**として
  関連記事に置ける可能性がある（要確認）。09 回が既に
  [コンピュテーション式でモナドを作ってみる](http://qiita.com/7shi/items/026c7daa5b0b24d02c0f)
  を関連記事に挙げているので、そちらとの重複も確認する。
- `articles/haskell/haskell-experiments.md`（実験メモの一覧）には**追加しない**
  （13 回決定事項 8・14 回と同じ理由）。

## TODO

- [ ] 構成案の各節で使うコードを書いて GHC 9.6.6 で動作確認する → `check/15-*/`
- [ ] `instance Monad` だけを書いたときのエラーメッセージを採取する
      （`No instance for (Applicative Foo) arising from the superclasses of an instance declaration` 系）
- [ ] `return` を実装して `pure` を書かなかった場合に何が起きるか確認する
      （`MINIMAL pure` の警告 / 実行時の挙動）
- [ ] `:i Functor` / `:i Applicative` / `:i Monad` / `:i Alternative` / `:i MonadFail` /
      `:i Foldable` / `:i ZipList` の GHC 9.6.6 での表示を採取する（種は `*` 表示。14 回で確認済み）
- [ ] `Identity` を自作するとき標準の `Data.Functor.Identity` と衝突しないか確認する
      （import しない／別名にする／`Prelude` に入っていないか）
- [ ] `ZipList` で `>>=` を書こうとしたときに何が起きるか、具体例を作る
- [ ] `Tree` の `instance Foldable`（`foldMap` 版）で `sum`・`length`・`elem`・`toList`・
      `mapM_` が動くことを確認する
- [ ] 練習 4 問（`Pair` の Functor / Applicative、`State` の穴埋め、`Rose`）を
      実装して動作確認し、問3 で与える bind のべた書きの形を確定する
- [ ] 03・07・08・09・10・12 回の該当箇所を読み直し、回収の言い回しを揃える
      （特に 09 回問4・問6・問8 の「再実装した関数は使わないで」の引き方）
- [ ] `articles/haskell/` の実験メモに `Functor`・`Applicative` の重複がないか棚卸しする
- [ ] 本文の初稿を書く
- [ ] 推敲（14-PLAN の「推敲時の観点」と同じ項目 + 半角スペースのルール）
- [ ] `README.md` の目次・`PREFACES.md`・`ARTICLES.tsv` を更新する
- [ ] Zenn へ複製し `ZENN.tsv` に追記する

## 16 回以降への引き継ぎ（この回で扱わないもの）

- **Free モナド**（16 回）。`Functor` を要求するので 15 回が前提。
  `DeriveFunctor` の導入も 16 回（14 回決定事項 9）。
  - **15 回の題材がそのまま実例になる。** `Tree` = `Free Two`（`data Two x = Two x x`、
    練習問1・2 の `Pair` と同じ形）、`Rose`（練習問4）= `Free []`。
    15 回では明かしていない（決定事項 9）ので、16 回で回収する。
  - `Free f` の `>>=` は `Pure x >>= f = f x` / `Free g >>= f = Free (fmap (>>= f) g)` の 2 行。
    `Tree` の `Node l r` の左右を再帰する部分が `fmap` に吸収されているのが見える。
  - **なぜ Free が `Functor` を要求するのか**の答えもここで出る（枝を辿るのに `fmap` が要る）。
- **`Traversable` の `instance`**（決定事項 7 で 15 回では名前のみ）。
  `traverse f (Node l r) = Node <$> traverse f l <*> traverse f r` は
  `Applicative` だけで書ける実例として強いが、15 回では紙幅を割かない。
- **Filinski『Representing Monads』**（13-PLAN「今回は入れなかった話」の 2、決定事項 12）。
  第一級の継続と状態があれば任意のモナドをシミュレートできる、という話。置き場所は未定。
- **codensity モナド**（13-PLAN「今回は入れなかった話」の 3）。
  Church エンコードした Free モナドの高速化の話なので、置き場所は 16 回。
- **カリー・ハワード対応と二重否定**（13-PLAN の 1）。どの回にも無理には入れない。

## 補足

- 検証コードは `series/haskell-intro/check/15-*/` に置く（CLAUDE.md の「検証コード」の方式）。
- このファイル（`15-PLAN.md`）は拡張子を除く部分が大文字・数字・ハイフンのみなので
  `ARTICLES.tsv` の収集対象から除外される。
