# シリーズ

<!-- scripts/build_series.py で series.jsonl から生成した下書き。手動修正後は本ファイルを正データとする。 -->
<!-- ^root: 抽出元記事（本文にリンク一覧があった記事。連載順とは無関係） -->
<!-- ^dup: 複数シリーズに重複（要確認） / ^missing: articles/ に存在しない記事 -->

## amd-stable-diffusion: AMD GPU での Stable Diffusion の改善

1. [CPU で動かす diffusers 入門](articles/ai/diffusers-cpu-intro.md) `b4da43f342f0fe3c189c`
2. [AMD GPU での Stable Diffusion の改善](articles/ai/amd-stable-diffusion.md) `b2d37b00132c23858a50` ^root

## build-llama-cpp-therock: TheRock で llama.cpp をビルド

1. [TheRock（ROCm の開発版）を Windows でビルド](articles/ai/build-therock-windows.md) `6a68a49629c463bc90f7`
2. [TheRock で llama.cpp をビルド](articles/ai/build-llama-cpp-therock.md) `99d5f80a45bf72b693e9` ^root

## codewhisperer-calculator: Amazon CodeWhisperer で四則演算器を作ってみる

1. [Github Copilot で四則演算器を作ってみる](articles/ai/github-copilot-calculator.md) `bea04b48a66c22b83450`
2. [Amazon CodeWhisperer で四則演算器を作ってみる](articles/ai/codewhisperer-calculator.md) `9e692d2aa4883154888c` ^root

## computation-expression-function-monad: 試作したコンピュテーション式と関数モナド

1. [不揃いなデータをコンピュテーション式で処理](articles/fsharp/irregular-data-computation-expression.md) `567e92474681a38de86a` ^dup
2. [試作したコンピュテーション式と関数モナド](articles/fsharp/computation-expression-function-monad.md) `6635d6bea5c455cbb4da` ^root

## coroutines-with-sequences: F#のシーケンスでコルーチン

1. [F#のシーケンスでコルーチン](articles/fsharp/coroutines-with-sequences.md) `29d10e74c8df30df04af` ^root
2. [F#のシーケンスでコルーチン(2)](articles/fsharp/fsharp-coroutines-2.md) `78fa1d02730c7cd11786`

## fsharp-intro: C#/JavaScriptで学ぶF#入門

1. [C#/JavaScriptで学ぶF#入門](articles/fsharp/fsharp-intro.md) `ff746903680ae8d0d7ce` ^root
2. [Haskellで学ぶF#入門](articles/fsharp/fsharp-intro-2.md) `1d3750ba17f5a88b8405` ^dup

## fsharp-intro-2: Haskellで学ぶF#入門

1. [Haskellで学ぶF#入門](articles/fsharp/fsharp-intro-2.md) `1d3750ba17f5a88b8405` ^root ^dup
2. [【解答例】Haskellで学ぶF#入門](articles/fsharp/learn-fsharp-with-haskell.md) `b174d1c50aab9350dafc`

## fsharp-winrt-reflection: F#でリフレクションを駆使してWinRTを扱う

1. [WinRTの非同期メソッドをリフレクションで扱う](articles/fsharp/winrt-async-reflection.md) `e8de755a5738f862e09f`
2. [F#でリフレクションを駆使してWinRTを扱う](articles/fsharp/fsharp-winrt-reflection.md) `01899f69f010a029242f` ^root

## grayscale-disappearing-image: グレースケールで消える画像に変換

1. [RGB値の合計が一定の画像変換](articles/fsharp/constant-rgb-sum.md) `d223e347d67cc399f70c`
2. [グレースケールで消える画像に変換](articles/fsharp/grayscale-disappearing-image.md) `755c537f1a308d07484b` ^root

## irregular-data-computation-expression: 不揃いなデータをコンピュテーション式で処理

1. [XMLスプレッドシートの読み込み](articles/fsharp/read-xml-spreadsheet.md) `ad06921776b10c6e459c`
2. [不揃いなデータをコンピュテーション式で処理](articles/fsharp/irregular-data-computation-expression.md) `567e92474681a38de86a` ^root ^dup

## json-parser: JSONパーサーを作る

1. [JSONパーサーを作る](articles/fsharp/json-parser.md) `04c2991239894687ef2f` ^root ^dup
2. [HARからファイルを抽出する](articles/fsharp/extract-har.md) `2e08418eeb448a343723`

## monads-with-computation-expressions: コンピュテーション式でモナドを作ってみる

1. [doブロックとコンピュテーション式](articles/haskell/do-blocks-computation-expressions.md) `92139286a4e9b5620d69`
2. [コンピュテーション式でモナドを作ってみる](articles/fsharp/monads-with-computation-expressions.md) `026c7daa5b0b24d02c0f` ^root

## opengl: F#でOpenGL

1. [F#でOpenGL](articles/fsharp/opengl.md) `029343420518b6884d7c` ^root
2. [F#にOpenGLの歯車デモを移植](articles/fsharp/opengl-gears.md) `efdf0ae04a24bc1b7623`
3. [OpenGLでオフスクリーンレンダリング](articles/misc/opengl-offscreen-rendering.md) `b02f2e45b49c0314fd12`

## python-to-fsharp-parallel: Pythonの並列計算サンプルをF#に移植

1. (unknown) `b05f321fa315bbce4f77` ^missing
2. [Pythonの並列計算サンプルをF#に移植](articles/fsharp/python-to-fsharp-parallel.md) `b5121bb3a94e691cd1c5` ^root

## wiktionary-speed-comparison: Wiktionaryの全文処理をF#とPythonで速度比較

1. [Wiktionaryの効率的な処理方法を探る](articles/wiktionary/efficient-wiktionary-processing.md) `e8091f6ac72491ad45a6`
2. [Wiktionaryの全文処理をF#とPythonで速度比較](articles/fsharp/wiktionary-speed-comparison.md) `1d6b97c657c6fffdbd70` ^root
3. [Wiktionaryの言語コードを取得](articles/wiktionary/wiktionary-language-codes.md) `4e3c614aac19d645fd1d`
4. [Wiktionaryから特定の言語を抽出](articles/python/wiktionary-language-extraction.md) `449e1aeaee3a25ca5a05`
5. [Wiktionaryで英語の不規則動詞を調査](articles/python/wiktionary-irregular-verbs.md) `2a945c346f74ca54552f`
6. [Wiktionaryのスクリプトをローカルで動かす](articles/wiktionary/run-wiktionary-scripts-locally.md) `6d1e8466b7586e5d0e90`

## compose-maybe-state: MaybeとStateを合成

1. [MaybeとStateを合成](articles/haskell/compose-maybe-state.md) `12036631dad1979a273b` ^root
2. [Parsecをモナド変換子で模倣](articles/haskell/parsec-monad-transformers.md) `201f379443079736e18e`

## function-overloading: Haskellで関数のオーバーロード

1. [Haskellの実験メモ一覧](articles/haskell/haskell-experiments.md) `b6cbb7df2dd969c84f49` ^dup
2. [Haskellで関数のオーバーロード](articles/haskell/function-overloading.md) `17a1567a635af17fc83f` ^root

## haskell-algebraic-computation: Haskellによる代数計算入門

1. [多項式の積を計算](articles/fsharp/polynomial-product.md) `4fb60dacad46cb8e63b3` ^dup
2. [ディラック作用素の代数計算](articles/fsharp/dirac-operator.md) `414fcb97c7aea6816a72`

## haskell-typeclasses-fsharp-interfaces: Haskellの型クラスとF#のインターフェース

1. [Haskellの実験メモ一覧](articles/haskell/haskell-experiments.md) `b6cbb7df2dd969c84f49` ^dup
2. [Haskellの型クラスとF#のインターフェース](articles/haskell/haskell-typeclasses-fsharp-interfaces.md) `cd7f65a898dd5696c73d` ^root

## implementing-space: Haskellで空間を実装してみた

1. [Haskellの実験メモ一覧](articles/haskell/haskell-experiments.md) `b6cbb7df2dd969c84f49` ^dup
2. [Haskellで空間を実装してみた](articles/haskell/implementing-space.md) `0bd828489aa176252fe8` ^root

## io-monad-internals: IOモナドを素手で触ってみた

1. [Clean 一意型 調査メモ](articles/misc/clean-uniqueness-types.md) `ab3b819871d7b0710949`
2. [IOモナドを素手で触ってみた](articles/haskell/io-monad-internals.md) `0a90d7ba31355e1c73aa` ^root

## ioref-state: IORefとState

1. [Haskellの実験メモ一覧](articles/haskell/haskell-experiments.md) `b6cbb7df2dd969c84f49` ^dup
2. [IORefとState](articles/haskell/ioref-state.md) `3722f0a677d6763eb395` ^root

## maybe-monad-infix: Maybeモナドによる中置記法の処理

1. [Stateモナドによる中置記法の処理](articles/haskell/state-monad-infix.md) `ee5afe4f088f0a1fc8c2` ^dup
2. [Maybeモナドによる中置記法の処理](articles/haskell/maybe-monad-infix.md) `cda901af6abb732f9c64` ^root

## recursion-to-foldr: 再帰をfoldrで書き換えて確認

1. [Haskellの実験メモ一覧](articles/haskell/haskell-experiments.md) `b6cbb7df2dd969c84f49` ^dup
2. [再帰をfoldrで書き換えて確認](articles/haskell/recursion-to-foldr.md) `82b1e074a360dd28fcbe` ^root

## state-monad-rpn: Stateモナドによる逆ポーランド記法の処理

1. [Stateモナドによる逆ポーランド記法の処理](articles/haskell/state-monad-rpn.md) `0494704d00396687458f` ^root
2. [Stateモナドによるポーランド記法の処理](articles/haskell/polish-notation-state-monad.md) `8bed38f45272f194631a`
3. [Stateモナドによる中置記法の処理](articles/haskell/state-monad-infix.md) `ee5afe4f088f0a1fc8c2` ^dup

## unboxed-tuples: アンボックス化タプルの挙動を確認（微妙）

1. [Haskellの実験メモ一覧](articles/haskell/haskell-experiments.md) `b6cbb7df2dd969c84f49` ^dup
2. [アンボックス化タプルの挙動を確認（微妙）](articles/haskell/unboxed-tuples.md) `60f787149673b4d4775f` ^root

## cancel-promise: Promiseの処理をキャンセルする

1. [非同期APIをPromiseでラップしてasync/awaitで使う](articles/javascript/wrap-async-api-with-promise.md) `a2bb35f27cd4a56f7bac`
2. [Promiseの処理をキャンセルする](articles/javascript/cancel-promise.md) `4cc1928061ff4598f10b` ^root

## cps-to-continuation-monad: CPS 変換から継続モナドへ

1. [ループと末尾再帰](articles/javascript/loops-and-tail-recursion.md) `5c44c23ef92f4c4273b4`
2. [CPS 変換による末尾再帰化](articles/javascript/cps-tail-recursion.md) `2d25f7afe25c3ca11acb`
3. [CPS 変換から継続モナドへ](articles/javascript/cps-to-continuation-monad.md) `27b6f3169961299a6195` ^root

## dom-to-image: dom-to-imageを試す

1. [dom-to-imageを試す](articles/javascript/dom-to-image.md) `771069479b91797b1fd6` ^root
2. [html2canvasを試す](articles/javascript/html2canvas.md) `ba7089e864fefac69808`
3. [複数の画像を生成してローカルに保存](articles/javascript/save-multiple-images.md) `9d27e1a4911626e1fb8b`

## es6-coroutine: ECMAScript 6のyieldでコルーチン

1. [ECMAScript 6のyieldでコルーチン](articles/javascript/es6-coroutine.md) `622c322bd482b340038c` ^root
2. [ECMAScript 6のyieldでコルーチン(2)](articles/javascript/es6-coroutines.md) `e9d65db80bfaa6adaa16`

## haskell-bubble-sort-to-javascript: HaskellのバブルソートをJavaScriptに直訳してみた

1. [Haskellでバブルソート](articles/haskell/bubble-sort.md) `1e2a66bf8e8c7f0bd70f` ^dup
2. [HaskellのバブルソートをJavaScriptに直訳してみた](articles/javascript/haskell-bubble-sort-to-javascript.md) `4601dff7664311659723` ^root

## ssml-test: Web Speech APIでSSMLのテスト

1. [Web Speech API で読み上げ位置を取得](articles/javascript/web-speech-api-reading-position.md) `43452dcd34e57100fc3c`
2. [Web Speech APIでSSMLのテスト](articles/javascript/ssml-test.md) `98c032737e7adcf7fd76` ^root

## xorshift-plotting: Xorshiftなどの擬似乱数をプロットして比較してみた

1. [Xorshiftなどの擬似乱数をプロットして比較してみた](articles/javascript/xorshift-plotting.md) `8219dcc22950253b26fb` ^root
2. [Xorshiftを移植してみた](articles/haskell/xorshift.md) `0e2951155fd8949dbc55`

## dotnet-bzip2-libraries: .NET Frameworkのbzip2ライブラリを調査

1. [.NET Frameworkのbzip2ライブラリを調査](articles/languages/dotnet-bzip2-libraries.md) `235328dbdc5c0c85edcb` ^root
2. [Pythonでマルチストリームbzip2を逐次展開する](articles/python/multistream-bzip2.md) `b619caed4a70902f0ece`
3. (unknown) `fc443c54320bfc587ec7` ^missing

## generators-delimited-continuations: 限定継続でジェネレーターを実装する

1. [call/cc でジェネレーターを実装する](articles/languages/generator-with-callcc.md) `a44c5257f04f0c641ef0`
2. [限定継続でジェネレーターを実装する](articles/languages/generators-delimited-continuations.md) `6db3e19ddc1f8552d9a0` ^root

## go-memory-management-2: Go ランタイムのメモリ管理：mmap と sbrk

1. [Go ランタイムのメモリ管理：mmap と sbrk](articles/languages/go-memory-management-2.md) `9a4a3a4544a30aa7b033` ^root
2. [Go 実行バイナリのメモリ管理](articles/languages/go-memory-management.md) `510653e0c0e28411cc9d`

## java-parser-combinator-2: Java パーサコンビネータ 超入門 2

1. [Java パーサコンビネータ 超入門](articles/languages/java-parser-combinators.md) `68228e19552c271bea81` ^dup
2. [Java パーサコンビネータ 超入門 2](articles/languages/java-parser-combinator-2.md) `39a9ddffcc5bdf2c0142` ^root ^dup

## parser-combinators: C++11 パーサコンビネータ 超入門

1. [C++11 パーサコンビネータ 超入門](articles/languages/parser-combinators.md) `6a12160276a8db358e34` ^root
2. [C++11 パーサコンビネータ 超入門 2](articles/languages/cpp-parser-combinators.md) `f86f2f7ad68cfff1b399`

## recursive-descent-parsing: Java 再帰下降構文解析 超入門

1. [Java 再帰下降構文解析 超入門](articles/languages/recursive-descent-parsing.md) `64261a67081d49f941e3` ^root
2. [Java パーサコンビネータ 超入門](articles/languages/java-parser-combinators.md) `68228e19552c271bea81` ^dup
3. [Java パーサコンビネータ 超入門 2](articles/languages/java-parser-combinator-2.md) `39a9ddffcc5bdf2c0142` ^dup
4. [JSONパーサーを作る](articles/fsharp/json-parser.md) `04c2991239894687ef2f` ^dup

## winrt-tts-rust: Rust/WinRTで音声合成

1. [WinRTで音声合成](articles/languages/winrt-tts-cs.md) `dc21a3be8b7c69fbc11b`
2. [VBSでOneCoreの音声を使用する](articles/languages/vbs-onecore-voice.md) `7781516d6746e29c03b4`
3. [PythonでWindows 10の音声合成を使用する](articles/media/windows-tts-python.md) `a5fb03406e0626b4f138` ^dup
4. [Rust/WinRTで音声合成](articles/languages/winrt-tts-rust.md) `885501607aecee7613fa` ^root

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

## reading-gif-binary: GIFのバイナリを読んでみた

1. [GIFのバイナリを読んでみた](articles/media/reading-gif-binary.md) `33117c6c369d37dc6cdd` ^root
2. [GIFのLZW圧縮を調べてみた](articles/media/gif-lzw-compression.md) `cfe1c6e42aff78c06652`
3. [GIFのLZWを展開してみた](articles/fsharp/gif-lzw-decompression.md) `778f58d4647b10f0f403`

## sapi-pronunciation: SAPIで発音を指定する

1. [PythonでWindows 10の音声合成を使用する](articles/media/windows-tts-python.md) `a5fb03406e0626b4f138` ^dup
2. [SAPIで発音を指定する](articles/media/sapi-pronunciation.md) `51017b4b268f66e11c42` ^root
3. [SAPIで未サポートの言語を喋らせる](articles/media/sapi-unsupported-languages.md) `ecb9ea901e4026a925ee`

## python-monad-generator: Pythonでもジェネレーターで関数モナドとStateモナドを模倣してみた

1. [ジェネレーターで関数モナドとStateモナドを模倣してみた](articles/javascript/mimicking-monads-with-generators.md) `e5365885fb53c015630c`
2. [Pythonでもジェネレーターで関数モナドとStateモナドを模倣してみた](articles/python/python-monad-generator.md) `b3aba035c45868ab34e9` ^root

## wikipedia-dump: Wikipediaのダンプからページを取り出す

1. [XMLのタグの構造と出現数を調べる](articles/fsharp/xml-tag-analysis.md) `022c58cf9a86ced595ef`
2. [Wikipediaのダンプからページを取り出す](articles/python/wikipedia-dump.md) `7a4aa381ec3dc97bd0f2` ^root

## quantum-computing-notation: 量子コンピューター超入門2 一般的な表記法

1. [量子コンピューター超入門](articles/quantum/quantum-computer-intro.md) `3504d8fa2c868620f57a`
2. [量子コンピューター超入門2 一般的な表記法](articles/quantum/quantum-computing-notation.md) `1704b58f8828601a0e6c` ^root

## pdp11-machine-language: PDP-11による機械語入門

1. [PDP-11による機械語入門](articles/retro/pdp11-machine-language.md) `86724696518df3a174dc` ^root
2. [8086による機械語入門](articles/retro/intel8086-machine-language-intro.md) `b3911948f9d97b05395e` ^dup
3. [VAXによる機械語入門](articles/retro/vax-machine-language-intro.md) `e43e8ce0b1a2cadee2a3`

## vax-machine-language: VAXの機械語を総当たり調査

1. [UNIX/32VによるVAX事始め](articles/retro/vax-intro.md) `85c4a43a07152c4322d5`
2. [VAXの機械語を総当たり調査](articles/retro/vax-machine-language.md) `7b24ed23fcbea08c3615` ^root
3. [S/390の機械語を総当たり調査](articles/retro/s390-machine-language.md) `98c7aa38fe0bd29a7296`

## sqlitepclraw-combinations: SQLitePCLRawが動作する組み合わせを探る

1. [SQLitePCLRawが動作する組み合わせを探る](articles/tools/sqlitepclraw-combinations.md) `8846bf14b74a26e014a6` ^root
2. [Microsoft.Data.SqliteをWindowsとWSLで共有する](articles/fsharp/microsoft-data-sqlite-wsl.md) `9fbb88786d8a5a6212ab`
3. [WindowsでMono.Data.Sqliteを使う](articles/tools/mono-data-sqlite-windows.md) `923b3a234eaecd7e8f1c`
4. [Mono.Data.SqliteでDapperを使う](articles/fsharp/mono-sqlite-dapper.md) `f7ec381f5bac184e0b24`

## emscripten-wasi: Emscripten と WASI

1. [Emscripten の基本的な使い方とグルーコード](articles/webassembly/emscripten-basics.md) `70ec93b683c0a1bcef6f`
2. [Emscripten と WASI](articles/webassembly/emscripten-wasi.md) `0cedc2a55c8ca0bb7538` ^root
3. [WebAssembly で同じコードを独立して動かす](articles/webassembly/wasm-independent-instances.md) `34f7d4693bd4b16d2df3`
