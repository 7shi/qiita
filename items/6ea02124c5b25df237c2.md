---
coediting: false
comments_count: 0
created_at: '2025-03-19T04:52:58+09:00'
id: 6ea02124c5b25df237c2
likes_count: 3
private: false
reactions_count: 0
stocks_count: 5
tags:
- name: Go
  versions: []
- name: GGUF
  versions: []
- name: ollama
  versions: []
title: Ollama で GGUF の直接取得に失敗したときの対処方法
updated_at: '2025-03-21T12:04:04+09:00'
url: https://qiita.com/7shi/items/6ea02124c5b25df237c2
slide: false
---

Ollama は Hugging Face から GGUF を直接取得することができますが、量子化を指定するとエラーになることがあります。その時に調べたことをメモしておきます。

# 対処方法

以下で公開されている GGUF を例とします。

https://huggingface.co/DavidAU/Mistral-Small-3.1-24B-Instruct-2503-MAX-NEO-Imatrix-GGUF

VRAM 16GB に収めるため 12.3GB の IQ3_S を使いたいのですが、pull に失敗します。

```text:失敗
$ ollama pull hf.co/DavidAU/Mistral-Small-3.1-24B-Instruct-2503-MAX-NEO-Imatrix-GGUF:IQ3_S
pulling manifest
Error: pull model manifest: 400: The specified tag is not available in the repository. Please use another tag or "latest"
```

ファイル名を確認しました。

- [Mistral-Small-3.1-24B-Instruct-2503-MAX-NEO-D_AU-IQ3_S-imat.gguf](https://huggingface.co/DavidAU/Mistral-Small-3.1-24B-Instruct-2503-MAX-NEO-Imatrix-GGUF/blob/main/Mistral-Small-3.1-24B-Instruct-2503-MAX-NEO-D_AU-IQ3_S-imat.gguf)

量子化はファイル名のサフィックスとして検索されるのではないかと推測して、`:IQ3_S-imat` と指定すれば成功しました。

```text:成功
$ ollama pull hf.co/DavidAU/Mistral-Small-3.1-24B-Instruct-2503-MAX-NEO-Imatrix-GGUF:IQ3_S-imat
pulling manifest
pulling 95496228fa92... 100% ▕████████████████████████████████████████▏  12 GB
pulling 6db27cd4e277... 100% ▕████████████████████████████████████████▏  695 B
pulling ba2521a0e789... 100% ▕████████████████████████████████████████▏   20 B
pulling 6d03bf5500a2... 100% ▕████████████████████████████████████████▏  193 B
verifying sha256 digest
writing manifest
success
```

## 補足

Mistral-Small 3.1 を例にしましたが、別の GGUF が公開されています。

https://huggingface.co/mmnga/Mistral-Small-3.1-24B-Instruct-2503-HF-gguf

以下の理由で、こちらの利用を推奨します。

- `-imat` のようなサフィックスが付いていないので、ファイル名の確認が不要
- Ollama では対応していない Vision のデータがカットされている
  - テキストのみの利用には支障なし
  - ファイルサイズが軽い：Q4_K_M で 16.1GB → 14.3GB

## 別の問題

以前の Mistral-Small 2409 でも、GGUF が取得できないという問題が発生しました。

https://huggingface.co/bartowski/Mistral-Small-Instruct-2409-GGUF

IQ3_M を pull しようとしても失敗します。

```text
$ ollama pull hf.co/bartowski/Mistral-Small-Instruct-2409-GGUF:IQ3_M
pulling manifest
Error: pull model manifest: 400: The specified tag is not a valid quantization scheme. Please use another tag or "latest"
```

ファイル名を確認してもサフィックスは付いていません。Hugging Face 側で IQ3_M は認識されないらしく、量子化のリストにありませんでした。

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/32057/ac2ba977-29c7-4604-b06c-83e55833d318.png)

:::note info
他の GGUF を見ても同様に IQ3_M は認識されないようなので、Hugging Face の仕様みたいです。
:::

仕方ないので手動でダウンロードして、Modelfile を書いて登録しました。

https://ollama.com/7shi/mistral-small

:::note info
毎回 Modelfile を書くのは大変です。IQ3_M と IQ3_S はそこまで性能差はないようなので、もし IQ3_S があればそちらを使った方が無難かもしれません。

:::

# ソースコードを確認

量子化の指定がどのように処理されるのか、Ollama のソースコードを確認しました。

https://github.com/ollama/ollama

Ollama サーバーが pull 要求を処理するコードを追います。

```go:server/internal/cmd/opp/opp.go (main)
		switch cmd := flag.Arg(0); cmd {
		case "pull":
			rc, err := ollama.DefaultRegistry()
			if err != nil {
				log.Fatal(err)
			}

			return cmdPull(ctx, rc)
```
```go:server/internal/cmd/opp/opp.go (cmdPull)
	errc := make(chan error)
	go func() {
		errc <- rc.Pull(ctx, model)
	}()
```
```go:server/internal/client/ollama/registry.go (Pull)
	m, err := r.Resolve(ctx, name)
	if err != nil {
		return err
	}
```
```go:server/internal/client/ollama/registry.go (Resolve)
	scheme, n, d, err := r.parseNameExtended(name)
	if err != nil {
		return nil, err
	}

	manifestURL := fmt.Sprintf("%s://%s/v2/%s/%s/manifests/%s", scheme, n.Host(), n.Namespace(), n.Model(), n.Tag())
	if d.IsValid() {
		manifestURL = fmt.Sprintf("%s://%s/v2/%s/%s/blobs/%s", scheme, n.Host(), n.Namespace(), n.Model(), d)
	}
```

`parseNameExtended` メソッドは入力文字列を解析して、scheme（スキーム）、name（名前）、digest（ダイジェスト）の3つの要素に分解します。

```go:例
scheme, n, d, err := r.parseNameExtended("example.com/library/model:tag​")
```

- `scheme` は指定されていないため、デフォルト値の `"https"`
- `n` は `names.Name` 型
  - `n.Host()`: `"example.com"`
  - `n.Namespace()`: `"library"`
  - `n.Model()`: `"model"`
  - `n.Tag()`: `"tag"`
- `d` はダイジェストが指定されていないため、空の `blob.Digest`
- `err` はエラーが発生しないので `nil`

よって `manifestURL` は `"https://example.com/v2/library/model/manifests/tag"` となります。

この URL に対して API リクエストを行い、その結果に基づいてモデルをダウンロードします。量子化を指定する `tag` は API のサーバー側で処理されるため、具体的な処理方法は Ollama のソースコードからは確認できませんでした。

## 例

Mistral-Small 3.1 の GGUF は次のようになります。

- name: `hf.co/DavidAU/Mistral-Small-3.1-24B-Instruct-2503-MAX-NEO-Imatrix-GGUF:IQ3_S-imat`
- manifestURL: `https:/hf.co/v2/DavidAU/Mistral-Small-3.1-24B-Instruct-2503-MAX-NEO-Imatrix-GGUF/manifests/IQ3_S-imat`

この URL にアクセスすれば JSON が返されます。

```json:結果
{
  "schemaVersion": 2,
  "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
  "config": {
    "digest": "sha256:6d03bf5500a220805a88919dbabf2f94f38b67b55ecc4dc01dfd8d36640baca1",
    "mediaType": "application/vnd.docker.container.image.v1+json",
    "size": 193
  },
  "layers": [
    {
      "digest": "sha256:95496228fa9288db6bd1983b5ba7aeb65697080fb2dde61e8071f22f442a79e2",
      "mediaType": "application/vnd.ollama.image.model",
      "size": 12273620192
    },
    {
      "digest": "sha256:6db27cd4e277c91264572b9c899c1980daa8dea11e902f0070a6f4763f3d13c8",
      "mediaType": "application/vnd.ollama.image.template",
      "size": 695
    },
    {
      "digest": "sha256:ba2521a0e7896c890e81ae7e9892882bfc3d4bb43a3a989ddfe2852f70056eb5",
      "mediaType": "application/vnd.ollama.image.params",
      "size": 20
    }
  ]
}
```

この情報に基づいてダウンロードが行われます。

## 調査方法

Ollama のソースコードは巨大なため、どこを見ればよいのか探すのに一苦労します。

まず Cursor でリポジトリを開いて Codebase で当たりを付けると、C++ の `common_get_hf_file()` が示されました。

```text:プロンプト
@Codebase Hugging FaceからGGUFをダウンロードするとき、指定された量子化ファイルを探す箇所。
```

```c++:llama/llama.cpp/common/common.cpp
std::pair<std::string, std::string> common_get_hf_file(const std::string & hf_repo_with_tag, const std::string & hf_token) {
```

この関数では API 用の URL を生成しています。

```c++
    std::string url = "https://huggingface.co/v2/" + hf_repo + "/manifests/" + tag;
```

:::note info
この時点でソースコードを追っても処理方法は書かれていないことが判明しました。
:::

Ollama 本体は Go で書かれていますが、Go からこの C++ の関数が呼ばれている形跡はありません。Go のオプションがどこで処理されているかを探すと server/internal/cmd/opp/opp.go であることが分かりました。

Codebase ではコード量が巨大な C++ 部分に引っ張られてしまうようなので、その先は Claude の Web サイトに切り替えて、GitHub 連携で server/internal 以下を読み込んで調査しました。

:::note warn
メンションでフォルダを絞り込んでも良かったのですが、Cursor の無料枠を使い切って Gemini を使っていると、箇条書きの中でインデントされた引用がうまくレンダリングされずに読みにくかったため、Claude に切り替えました。
:::

# 関連記事

Modelfile の書き方

https://qiita.com/7shi/items/ae0da373184b82d53fcc

Cursor の無料枠に追加設定する方法

https://qiita.com/7shi/items/2e8e3ed2c39e3dc4ee22
