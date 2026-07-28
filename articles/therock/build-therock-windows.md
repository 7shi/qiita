---
coediting: false
comments_count: 0
created_at: '2025-06-02T00:59:15+09:00'
id: 6a68a49629c463bc90f7
likes_count: 20
private: false
reactions_count: 0
stocks_count: 15
tags:
- name: Windows
  versions: []
- name: ROCm
  versions: []
- name: therock
  versions: []
title: TheRock（ROCm の開発版）を Windows でビルド
updated_at: '2025-06-08T17:24:59+09:00'
url: https://qiita.com/7shi/items/6a68a49629c463bc90f7
slide: false
---

ROCm は、AMD GPU を活用した AI/ML 開発のためのプラットフォームです。長らく ROCm は Linux のみをサポートしており、Windows には非対応でした。2023 年 7 月に Windows 向けの HIP SDK がリリースされましたが、ROCm のサブセットであり、PyTorch には対応していませんでした。

現在、ROCm の開発版は TheRock (The HIP Environment and ROCm Kit) として公開されており、同一のソースツリーで Linux と Windows の両方をサポートしています。

https://github.com/ROCm/TheRock

本記事では、Windows での TheRock のビルド手順やトラブルの対処法をまとめます。

# ROCm と TheRock

AMD 公式発表では、2025 年 Q3 に ROCm のプレビュー版が予定されています。これには Windows 版の PyTorch も含まれ、Ryzen AI Max (Strix Halo) や Radeon RX 9000 シリーズにも対応する見込みです。現状は新アーキテクチャでの ROCm のサポートが追い付いていませんが、今後発表される新アーキテクチャでは発売と同時にサポートすることを目標としているようです。

- [AMD pledges ROCm support for Windows, Ryzen AI MAX & Radeon RX 9000 - VideoCardz.com](https://videocardz.com/newz/amd-pledges-rocm-support-for-windows-ryzen-ai-max-radeon-rx-9000)

TheRock は所定の目標が達成された段階で切り出され、ROCm としてリリースされると思われます。詳細は不明ですが、2025 年末に ROCm 7.0 としてリリースされるという噂があります。

- [LinuxのROCm6.4がリリース - 自作ユーザーが解説するゲーミングPCガイド](https://g-pc.info/archives/40527/)

TheRock はオープンな体制で開発されているため、自分でビルドすれば ROCm を先行体験することができます。これは戦略的なシフトであるとの分析があります。

- [AMD、ROCmでエッジAIを大きく進化させ、Strix Halo APUおよびRadeon RX 9000シリーズGPUとの統合を発表 - 自作ユーザーが解説するゲーミングPCガイド](https://g-pc.info/archives/41240/)

TheRock には開発版ならではの制約があります。

- 安定性が保証されない
- 性能が十分に最適化されていない

バグレポートなどフィードバックは歓迎されます。

# ビルド済 PyTorch

有志が TheRock でビルドした PyTorch のパッケージ (wheel) を配布しています。オプションが調整されており、デフォルトでビルドするよりも高速で動作します。

https://github.com/scottt/rocm-TheRock/releases

:::note info
別途このパッケージの利用法をまとめた記事を書く予定です。
:::

TheRock 公式でも Windows 版の nightly ビルドの提供が予定されています。（現状は Linux 版のみ）

https://github.com/ROCm/TheRock/issues/651#issuecomment-2901362518

# ビルド手順

以下の資料をベースに説明します。

- [gfx1151 on Windows: Pytorch with aotriton SDPA working. Awaiting review. #409](https://github.com/ROCm/TheRock/discussions/409)

不明点があった時の参考として、公式の手順書もリンクしておきます。

- [README.md](https://github.com/ROCm/TheRock/blob/main/README.md)
- [Windows Support](https://github.com/ROCm/TheRock/blob/main/docs/development/windows_support.md)

まず TheRock 本体をビルドしてから PyTorch をビルドします。

:::note info
2025 年 5 月 28 日時点のリポジトリで動作確認した手順を説明します。活発に開発が進んでいるため、手順などは流動的で変更される可能性があります。

- https://github.com/ROCm/TheRock/commit/81e1cdd80710bee41436e9537d38bf667b6c8230
:::

## 開発環境

**Visual Studio 2022**

Community Edition が無償利用できます。「C++ によるデスクトップ開発」を有効にしてインストールしてください。

https://visualstudio.microsoft.com/ja/vs/community/

:::note info
既にインストールされている場合でも、17.12 より前のバージョンでは OpenMP 周りの不具合が確認されているためアップデートが必要です。👉[Issue #711](https://github.com/ROCm/TheRock/issues/711)
:::

**開発者ドライブ**

作業ディレクトリが深すぎると不具合が発生することがあります。作業専用の開発者ドライブ（VHD 仮想ドライブ）を作成することを推奨します。

https://learn.microsoft.com/ja-jp/windows/dev-drive/

VHD は最低でも 70GB 程度のサイズが必要です。可能なら 200GB 程度は確保することを推奨します。

:::note info
VHD を可変サイズで作成する場合でも、VHD ファイルを設置するドライブの空き容量以上のサイズを指定することは避けてください。使用するうちに VHD ファイルのサイズが膨らんで、設置ドライブの空き容量がなくなった時点で強制的にマウント解除されます。👉[参考](https://x.com/7shi/status/1925791622882529598)
:::

**除外設定**

ウィルス対策ソフト（デフォルトは Windows セキュリティ）から、開発者ドライブを例外指定することを推奨します。大量のファイルを扱うため、所要時間が半分程度になります。

Windows 検索から開発者ドライブを除外することを推奨します。

- 設定 → プライバシーとセキュリティー → Windows 検索

**シンボリックリンク**

シンボリックリンクをサポートするため、開発者モードを有効にしてください。

- 設定 → システム → 開発者向け

**長いパス**

レジストリを操作して、長いパスを有効にしてください。PowerShell を管理者として開いて、以下のコマンドを実行します。

```powershell
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Value 1 -PropertyType DWORD -Force
```

設定後、Windows を再起動してください。

**その他の開発ツール**

winget からインストールしてください。

```bat:Git
winget install -e --id Git.Git
```

```bat:Git LFS
winget install -e --id GitHub.GitLFS
```

```bat:Strawberry Perl
winget install -e --id StrawberryPerl.StrawberryPerl
```

```bat:uv (Python Package Manager)
winget install -e --id=astral-sh.uv
```

:::note info
Python は uv 経由でインストールするため、別途インストールは不要です。
:::

PATH の変更を反映するため、すべてをインストールした後に Windows を再起動してください。

**Git の設定**

Git でシンボリックリンクと長いパスのサポートを有効にします。

```bat
git config --global core.symlinks true
git config --global core.longpaths true
```

## TheRock

スタートメニューから開発者プロンプトを開きます。

- Visual Studio 2022 → x64 Native Tools Command Prompt for VS 2022

ビルドに HIP SDK は不要です。既に HIP SDK がインストールされていても無視するように設定されていますが、念のため開発者プロンプト内では環境変数 `HIP_PATH` を無効化しておくことを推奨します。（右辺は空欄）

```bat
set HIP_PATH=
```

### 準備

開発者ドライブの直下に必要なリポジトリをクローンします。ドライブレターの割り当ては自由ですが、ここでは仮に `D:` とします。

```bat
D:
git clone https://github.com/nod-ai/amdgpu-windows-interop.git
git clone https://github.com/ROCm/TheRock.git
```

:::note info
あまりパスが深くなると不具合が発生することがあるようなので、開発者ドライブ直下を推奨します。
:::

TheRock のディレクトリに入り、追加のソースを取得します。

```bat
cd TheRock
python ./build_tools/fetch_sources.py
```

指定したバージョンの Python で仮想環境 (venv) を構築して、必要なパッケージをインストールします。

```bat
uv venv --python 3.12 .venv
.venv\Scripts\activate
pip install -r requirements.txt
```

:::note info
TheRock のビルド用の venv です。PyTorch のビルド用は別に作ります。（後述）
:::

### ビルド

コンフィグを指定します。

```bat
cmake -B build -GNinja -DTHEROCK_AMDGPU_FAMILIES=gfx**** -DTHEROCK_AMDGPU_WINDOWS_INTEROP_DIR=D:\amdgpu-windows-interop .
```

`gfx****` は使用している GPU に応じて変更してください。以下に表があります。

- [Accelerator and GPU hardware specifications — ROCm Documentation](https://rocm.docs.amd.com/en/latest/reference/gpu-arch-specs.html)
- [System requirements (Windows) — HIP SDK installation (Windows)](https://rocm.docs.amd.com/projects/install-on-windows/en/latest/reference/system-requirements.html)

:::note info
`gfx110X-dgpu` のようにまとめて指定する方法もありますが、ビルド時間が増大します。👉[参考](https://x.com/7shi/status/1927934514115809401)
:::

:::note warn
README には ccache の使用方法も書かれていますが、バージョンによっては `duplicate symbol` の不具合が発生することもあるため、最初のうちは使用を避けた方が無難です。👉[Issue #748](https://github.com/ROCm/TheRock/issues/748)
:::

ビルドを開始します。

```bat
cmake --build build
```

:::note info
`cmake` のオプション `-B build` や `--build build` の `build` はディレクトリを指します。不具合が発生してやり直したいときは `build` ディレクトリを削除して、コンフィグからやり直してください。また、ディレクトリ名を変更することで、複数のコンフィグを使い分けることが可能ですが、PyTorch のビルドで若干の修正が必要になるため、最初のうちは変更しない方が無難です。
:::

所要時間は AMD Ryzen 5 5600X 6-Core Processor で 2 時間半程度です。時間を計測するには PowerShell 経由で `cmake` を呼び出す方法があります。

```powershell
powershell -Command "Measure-Command { cmake --build build | Out-Default }"
```

:::note warn
Git Bash から `time` コマンドで計測すると不具合が発生します。👉[Issue #670](https://github.com/ROCm/TheRock/issues/670#issuecomment-2919634049)
:::

### リリースフォルダ

ビルドが完了すれば、build/dist/rocm にリリースフォルダが構築されます。これが従来 HIP SDK として配布されていたものに相当します。

:::note info
llama.cpp をビルドしてみました。API 変更に伴う修正と、llvm-rc が足りないため HIP SDK から借りてくる必要がありました。
:::

https://qiita.com/7shi/items/99d5f80a45bf72b693e9

`hipconfig` でバージョンを確認する例を示します。TheRock が内部的に ROCm 6.5 というバージョン番号で開発されていることが分かります。

```bat
>hipconfig --version
6.5.25214-d6bb0478b
```

:::note warn
このコマンドを実行する際、HIP SDK が既にインストールされている場合、環境変数 `HIP_PATH` を無効化しておかないと干渉します。
:::

## PyTorch

TheRock のビルドが完了したら、次は PyTorch のビルドに入ります。

ビルド環境は分けた方が良いので、開発者プロンプトは別に開いてください。

- Visual Studio 2022 → x64 Native Tools Command Prompt for VS 2022

既定でリリースフォルダ (build/dist/rocm) を参照するようになっているため、再配置する必要はありません。ただし既に HIP SDK がインストールされている場合、開発者プロンプト内では環境変数 `HIP_PATH` を無効化してください。

```bat
set HIP_PATH=
```

:::note info
右辺は空欄のままで、リリースフォルダを指定する必要はありません。
:::

### libuv

diffusers で Stable Diffusion などの画像生成を行うには、PyTorch の分散機能を有効にする必要があります。Windows では libuv が必要になります。

:::note info
Python のパッケージ管理ツール uv とは無関係です。
:::

開発者ドライブに移動して、libuv をビルドします。（ここでは `D:` と仮定）

```bat
D:
git clone https://github.com/libuv/libuv.git
cd libuv
cmake -B build -DBUILD_TESTING=OFF
cmake --build build --config Release
cmake --install build --prefix dist
```

インストール先の `D:\libuv\dist` を PyTorch のビルド時に環境変数で渡します。

### link.exe

ビルドには Git と共にインストールされた Bash（通称 Git Bash）を使用します（WSL 不可）。`link` コマンドが MSVC のリンカーと競合するため対策が必要です。👉[Issue #651](https://github.com/ROCm/TheRock/issues/651#issuecomment-2892977536)

あまりスマートではありませんが、手っ取り早い方法として、エクスプローラーで `C:\Program Files\Git\usr\bin` を開いて、`link.exe` を `link_.exe` にリネームしてください。

:::note info
いずれビルドスクリプトが Python で書き直されるようなので、それまでの一時的な回避策です。このコマンドはほとんど使われることはないため、影響は受けないはずです。
:::

### 準備

TheRock 内の PyTorch のディレクトリに移動します。

```bat
D:
cd \TheRock\external-builds\pytorch
```

ビルド手順はこのディレクトリにある README.md をベースに説明します。

- [Build PyTorch with ROCm support](https://github.com/ROCm/TheRock/blob/main/external-builds/pytorch/README.md)

専用のスクリプトで PyTorch のリポジトリを取得します。

```bat
python pytorch_torch_repo.py checkout
```

指定したバージョンの Python で仮想環境 (venv) を構築して、必要なパッケージをインストールします。

```bat
uv venv --python 3.12 .venv
.venv\Scripts\activate
pip install -r pytorch/requirements.txt
pip install mkl-static mkl-include
```

### ソースの修正

分散機能を有効にすると `no previous prototype for function 'flock_'` というエラーが発生するため、一箇所修正します。（`static` の追加）

```diff
--- a/torch/csrc/distributed/c10d/FileStore.cpp
+++ b/torch/csrc/distributed/c10d/FileStore.cpp
@@ -33,7 +33,7 @@
 #define LOCK_SH 0x00000010
 #define LOCK_UN 0x00000100

-int flock_(int fd, int op) {
+static int flock_(int fd, int op) {
   HANDLE hdl = (HANDLE)_get_osfhandle(fd);
   DWORD low = 1, high = 0;
   OVERLAPPED offset = {0, 0, 0, 0, NULL};
```

### ビルド

libuv の場所と分散機能を指定してビルドします。`gfx****` は使用している GPU に応じて変更してください。

```bat
set libuv_ROOT=D:\libuv\dist
set USE_DISTRIBUTED=1
set USE_GLOO=0
"C:\Program Files\git\bin\bash.exe" build_pytorch_windows.sh gfx****
```

:::note info
分散機能を有効にすると Gloo は自動的に有効になりますが、ROCm 未対応でエラーになるため無効にします。
:::

ビルドログはファイルに格納され、画面には表示されません。ログのファイル名は表示されます。

```text
Setting PYTORCH_ROCM_ARCH to gfx****
ROCM_HOME: /d/TheRock/build/dist/rocm
ROCM_HOME_WIN: D:\TheRock\build\dist\rocm
Running "python setup.py bdist_wheel", directing output to /c/Users/****/.therock/logs_pytorch_windows_YYYY-MM-DD_hhmmss.txt
```

所要時間は AMD Ryzen 5 5600X 6-Core Processor で 1 時間半程度です。

正常終了すればビルドしたパッケージ (wheel) の情報や使用方法が表示されます。

```text
Build completed! Wheels should be at '/d/TheRock/external-builds/pytorch/pytorch/dist':
total ******
-rw-r--r-- 1 **** **** ********* Jun  1 hh:mm torch-2.7.0a0+git*******-cp312-cp312-win_amd64.whl

To use these wheels, either
  * Extend your PATH with 'D:\TheRock\build\dist\rocm/bin':

      set PATH=D:\TheRock\build\dist\rocm\bin;%PATH%

  * Create a fat wheel using 'windows_patch_fat_wheel.py'
```

これが表示されなければエラーが発生しているため、ログファイルを確認してください。

### 動作確認

PyTorch の動作確認を行います。普通のコマンドプロンプトを起動して、開発者ドライブにテスト用のディレクトリを作成します。

```bat
D:
mkdir test
cd test
```

TheRock とは別に HIP SDK がインストールされている場合、コマンドプロンプト内では環境変数 `HIP_PATH` を無効化してください。（右辺は空欄）

```bat
set HIP_PATH=
```

PyTorch ビルド終了時の指示通り PATH を設定します。

```bat
set PATH=D:\TheRock\build\dist\rocm\bin;%PATH%
```

uv 環境を初期化して、ビルドした PyTorch と NumPy 1 系をインストールします。

```bat
uv python pin 3.12
uv init
uv add "D:\TheRock\external-builds\pytorch\pytorch\dist\torch-2.7.0a0+git*******-cp312-cp312-win_amd64.whl"
uv add "numpy<2"
```

Python の REPL を起動して動作確認を行います。

```py
>uv run python
Python 3.12.7 (main, Oct 16 2024, 00:21:24) [MSC v.1929 64 bit (AMD64)] on win32
Type "help", "copyright", "credits" or "license" for more information.
>>> import torch
>>> torch.cuda.is_available()
True
>>> torch.cuda.get_device_name(0)
'AMD Radeon ****'
```

Radeon GPU が認識されれば成功です。

### 画像生成

diffusers から簡単な画像生成を行います。Anything V3.1 のモデルカードに記載されているサンプルを実行してみます。

https://huggingface.co/Linaqruf/anything-v3-1

<img src="https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/32057/021f52ac-fb72-4955-b6ad-2e5e8fb5bc5b.png" width="50%">

:::note info
初回の生成はかなり遅いですが、2 回目からは改善されます。有志が配布しているパッケージはこの点がかなり改善されています。具体的な比較は別の記事で行う予定です。
:::

diffusers の使い方については以下の記事を参照してください。

https://qiita.com/7shi/items/b4da43f342f0fe3c189c

:::note info
この記事は CPU で動かす前提のため、GPU で動かすには `pipe = pipe.to("cuda")` を追加する必要があります。
:::

# その他のエラー

踏む可能性があるエラーはその都度補足しましたが、それ以外にも経験したエラーを書いておきます。

- [Issue #684](https://github.com/ROCm/TheRock/issues/684)

BLAS のビルドで boost が必要になりますが、非 ASCII 文字のファイルがテストとして含まれており、英語以外の環境で問題が発生しました。既に問題のファイルを抜いたアーカイブに差し替えられたため解決済みです。

- [Issue #709](https://github.com/ROCm/TheRock/issues/709)

テストファイルのビルドで問題が起きるようだったので、それをパスするためにテストを無効にしたところ、今までチェックされていなかった構成らしく問題が発生しました。テストファイルは ccache の問題だったことが判明したため、ccache を無効にすればテストを無効にする必要はなくなりました。

# トラブルの対処法

エラーを AI に貼り付けて聞くのは基本として、Issue から効果的に探す方法について書きます。

GitHub のサイトから Copilot チャットが呼び出せるので、発生したエラーが Issue にあるかどうか聞くのが手っ取り早いです。👉[参考](https://x.com/7shi/status/1924933989590302851)

ただし全文を見ているわけではないようで、コメントで少し言及されているようなケースでは漏れが発生します。そのような場合は GitHub CLI で全部の Issues を取得して、Google AI Studio で Gemini に読ませるのが確実です。

https://qiita.com/7shi/items/b17cb8d96ae0328bee7e

:::note info
この記事では NotebookLM を使用していますが、Gemini にコンテキストとして与えるよりは精度が落ちます。1M トークンは Markdown 換算で 2MB 程度なので、それ未満であれば Gemini、それ以上であれば NotebookLM と使い分けるのが良いでしょう。なお、TheRock の規模でも 200K トークンは超えます。Claude に分割して読ませたとしても Pro の枠ではすぐ上限に達してしまうので、Gemini が無難です。

:::

Issue にないことを確認してから報告したら、ドキュメントに書かれていたということもありました。👉[Issue #748](https://github.com/ROCm/TheRock/issues/748)

Claude には GitHub のリポジトリからファイルを指定して読み取る機能があるので、ドキュメントを全文読ませて確認すれば良いでしょう。

# 感想

当初、手順通りにやっても問題が発生したため、Issue や Discussion などに書かれている断片的な情報を基に試行錯誤しました。ビルドに時間が掛かるため、何度も手戻りがあるとなかなか進まずに心が折れそうになりました。👉[参考](https://x.com/7shi/status/1928114023062491154)

地道に 1 つずつエラーを潰して、（間に都合で数日空きましたが）1 週間くらい掛かってようやくビルドできるようになりました。一度ビルドを通してしまえば、要領が分かるのでかなり気持ちが楽になります。私はそこまでが長かったですが、この記事が少しでも役に立って一発で通せるようになることを願っています。

# 参考

Linux でのビルドについての記事です。

https://www.fraction.jp/log/archives/2025/05/29/evo-x2-gfx1151

# 関連記事

2 年前の AMD GPU の状況です。今考えれば、この記事を書いた直後に最初の HIP SDK が出たのでした。

https://qiita.com/7shi/items/b2d37b00132c23858a50

ZLUDA という CUDA の翻訳レイヤを利用することで、Radeon で CUDA 版 PyTorch を利用することが行われています。

https://note.com/7shi/n/n718f81f50bba

Ollama は HIP に対応しているため、ROCm/PyTorch の対応を待たずに利用できます。

https://qiita.com/7shi/items/dc037c2d5b0add0da33a
