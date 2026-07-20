---
coediting: false
comments_count: 0
created_at: '2024-12-07T16:00:35+09:00'
id: 29a16427c2a8deee4747
likes_count: 3
private: false
reactions_count: 0
stocks_count: 0
tags:
- name: Python
  versions: []
- name: Windows
  versions: []
- name: UV
  versions: []
- name: PyTorch
  versions: []
title: Windows で uv の PyTorch インストールエラーに対処
updated_at: '2024-12-07T20:24:18+09:00'
url: https://qiita.com/7shi/items/29a16427c2a8deee4747
slide: false
---

Windows の uv 環境で PyTorch をインストールしようとしてエラーになったので、Python のバージョン指定で対処しました。検索しても同じ状況はヒットしないようなので、参考までに書いておきます。

:::note info
本記事では CPU 動作を想定しているため、CUDA の指定は行いません。
:::

# エラー状況

適当なディレクトリで uv を初期化して torch のインストールを試みます。

```
D:\test>uv init
Initialized project `test`

D:\test>uv add torch
Using CPython 3.13.0
Creating virtual environment at: .venv
Resolved 23 packages in 150ms
error: Distribution `torch==2.5.1 @ registry+https://pypi.org/simple` can't be installed because it doesn't have a source distribution or wheel for the current platform
```

`--index-url` を指定してもエラーです。

```
D:\test>uv add torch --index-url https://download.pytorch.org/whl/cpu
warning: Indexes specified via `--index-url` will not be persisted to the `pyproject.toml` file; use `--default-index` instead.
Resolved 11 packages in 2.11s
error: Distribution `torch==2.5.1+cpu @ registry+https://download.pytorch.org/whl/cpu` can't be installed because it doesn't have a source distribution or wheel for the current platform
```

uv のデフォルトで Python 3.13.0 が使用されていますが、3.13 用の torch が用意されていないためのようです。

# Python バージョンの変更

Python 3.12 系にバージョンを変更します。

```yaml:pyproject.toml（変更箇所）
requires-python = ">=3.12"
```

```
D:\test>uv python pin 3.12
Updated `.python-version` from `3.13` -> `3.12`
```

torch がインストールできました。

```
D:\test>uv add torch
Using CPython 3.12.7
Removed virtual environment at: .venv
Creating virtual environment at: .venv
Resolved 24 packages in 678ms
░░░░░░░░░░░░░░░░░░░░ [0/10] Installing wheels...                                                                        warning: Failed to hardlink files; falling back to full copy. This may lead to degraded performance.
         If the cache and target directories are on different filesystems, hardlinking may not be supported.
         If this is intentional, set `export UV_LINK_MODE=copy` or use `--link-mode=copy` to suppress this warning.
Installed 10 packages in 25.46s
 + filelock==3.16.1
 + fsspec==2024.10.0
 + jinja2==3.1.4
 + markupsafe==3.0.2
 + mpmath==1.3.0
 + networkx==3.4.2
 + setuptools==75.6.0
 + sympy==1.13.1
 + torch==2.5.1
 + typing-extensions==4.12.2
```

# 関連記事

https://qiita.com/7shi/items/0f9c9ff7cf2fcb9597c5

# 参考

https://zenn.dev/mjun0812/articles/b32f870bb3cdbf

https://zenn.dev/hiroga/articles/uv-pytorch-trouble-shooting
