# シリーズ

<!-- scripts/build_series.py で series.jsonl から生成した下書き。手動修正後は本ファイルを正データとする。 -->
<!-- ^root: 抽出元記事（本文にリンク一覧があった記事。連載順とは無関係） -->
<!-- ^dup: 複数シリーズに重複（要確認） / ^missing: articles/ に存在しない記事 -->

## fsharp-opengl: F#でOpenGL

1. [F#でOpenGL](articles/fsharp/opengl.md) `029343420518b6884d7c` ^root
2. [F#にOpenGLの歯車デモを移植](articles/fsharp/opengl-gears.md) `efdf0ae04a24bc1b7623`
3. [OpenGLでオフスクリーンレンダリング](articles/misc/opengl-offscreen-rendering.md) `b02f2e45b49c0314fd12`

## cps-to-continuation: CPS 変換から継続モナドへ

1. [ループと末尾再帰](articles/javascript/loops-and-tail-recursion.md) `5c44c23ef92f4c4273b4`
2. [CPS 変換による末尾再帰化](articles/javascript/cps-tail-recursion.md) `2d25f7afe25c3ca11acb`
3. [CPS 変換から継続モナドへ](articles/javascript/cps-to-continuation-monad.md) `27b6f3169961299a6195` ^root

## reading-gif: GIFのバイナリを読んでみた

1. [GIFのバイナリを読んでみた](articles/media/reading-gif-binary.md) `33117c6c369d37dc6cdd` ^root
2. [GIFのLZW圧縮を調べてみた](articles/media/gif-lzw-compression.md) `cfe1c6e42aff78c06652`
3. [GIFのLZWを展開してみた](articles/fsharp/gif-lzw-decompression.md) `778f58d4647b10f0f403`

## sqlitepclraw: SQLitePCLRawが動作する組み合わせを探る

1. [SQLitePCLRawが動作する組み合わせを探る](articles/tools/sqlitepclraw-combinations.md) `8846bf14b74a26e014a6` ^root
2. [Microsoft.Data.SqliteをWindowsとWSLで共有する](articles/fsharp/microsoft-data-sqlite-wsl.md) `9fbb88786d8a5a6212ab`
3. [WindowsでMono.Data.Sqliteを使う](articles/tools/mono-data-sqlite-windows.md) `923b3a234eaecd7e8f1c`
4. [Mono.Data.SqliteでDapperを使う](articles/fsharp/mono-sqlite-dapper.md) `f7ec381f5bac184e0b24`

## emscripten-wasi: Emscripten と WASI

1. [Emscripten の基本的な使い方とグルーコード](articles/webassembly/emscripten-basics.md) `70ec93b683c0a1bcef6f`
2. [Emscripten と WASI](articles/webassembly/emscripten-wasi.md) `0cedc2a55c8ca0bb7538` ^root
3. [WebAssembly で同じコードを独立して動かす](articles/webassembly/wasm-independent-instances.md) `34f7d4693bd4b16d2df3`

# 要検討

## wiktionary-speed-comparison: Wiktionaryの全文処理をF#とPythonで速度比較

1. [Wiktionaryの効率的な処理方法を探る](articles/wiktionary/efficient-wiktionary-processing.md) `e8091f6ac72491ad45a6`
2. [Wiktionaryの全文処理をF#とPythonで速度比較](articles/fsharp/wiktionary-speed-comparison.md) `1d6b97c657c6fffdbd70` ^root
3. [Wiktionaryの言語コードを取得](articles/wiktionary/wiktionary-language-codes.md) `4e3c614aac19d645fd1d`
4. [Wiktionaryから特定の言語を抽出](articles/python/wiktionary-language-extraction.md) `449e1aeaee3a25ca5a05`
5. [Wiktionaryで英語の不規則動詞を調査](articles/python/wiktionary-irregular-verbs.md) `2a945c346f74ca54552f`
6. [Wiktionaryのスクリプトをローカルで動かす](articles/wiktionary/run-wiktionary-scripts-locally.md) `6d1e8466b7586e5d0e90`

## wikipedia-dump: Wikipediaのダンプからページを取り出す

1. [XMLのタグの構造と出現数を調べる](articles/fsharp/xml-tag-analysis.md) `022c58cf9a86ced595ef`
2. [Wikipediaのダンプからページを取り出す](articles/python/wikipedia-dump.md) `7a4aa381ec3dc97bd0f2` ^root

## bicomplex-numbers: 表現行列で考える双複素数

1. [実ベクトルで考える複素ベクトル](articles/math/complex-vectors-as-real-vectors.md) `4f313cb36cdd12c8d833`
2. [表現行列で考える双複素数](articles/math/bicomplex-numbers.md) `050f6615558c4c2b1d92` ^root
3. [表現行列で考える四元数](articles/math/quaternion-representation-matrix.md) `e7364e1b2593f24427a5`
4. [クリフォード代数で考えるパウリ行列と双四元数](articles/math/clifford-algebra-pauli.md) `fafe77f9a5ff2f9651ba`

## inner-product-estimate: 見積りで考える内積

1. [見積りで考える内積](articles/math/inner-product-estimate.md) `03e9eb2c78360a5c1374` ^root
2. [関数で考えるコベクトル](articles/math/covectors-as-functions.md) `1275d2a15a25a75125d2`
3. [関数で考える行列](articles/math/matrices-as-functions.md) `5515a49c86efb8d5102a`
4. [関数で考える双対性](articles/math/duality.md) `c452e2946d1f58b5ff7f`
5. [コベクトルで考えるパーセプトロン](articles/math/perceptron-covector.md) `538504de453208be937e`

## outer-products: 外積と愉快な仲間たち

1. [多項式の積を計算](articles/fsharp/polynomial-product.md) `4fb60dacad46cb8e63b3` ^dup
2. [外積と愉快な仲間たち](articles/math/outer-products.md) `017d2d2c758f76071f23` ^root
3. [ユークリッド空間のホッジ双対とバブルソート](articles/math/hodge-dual-bubble-sort.md) `f54302058149d07da592`
4. [四元数を作ろう](articles/math/making-quaternions.md) `2036e7a739c2a9e04025`
5. [四元数と行列で見る内積と外積の「内」と「外」](articles/math/quaternion-inner-outer-product.md) `a80988a32a0d706e9378`
6. [八元数を作ろう](articles/math/octonions.md) `b34fe724d36fb7d96456`
7. [八元数の積をプログラムで確認](articles/math/octonion-multiplication.md) `8495b2d6b888e7b8703f`
8. [外積の成分をプログラムで確認](articles/math/cross-product-components.md) `02c758c03d2fd7038912`
9. [多元数の積の構成](articles/math/cayley-dickson-construction.md) `88be5203769e629df243`
10. [十六元数を作ろう](articles/math/sedenions.md) `989d59d74a505a92c419`
