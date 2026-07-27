---
coediting: false
comments_count: 0
created_at: '2020-05-31T22:32:27+09:00'
id: b70e2837be3e41fbde66
likes_count: 0
private: false
reactions_count: 0
stocks_count: 1
tags:
- name: Python
  versions: []
- name: Mercurial
  versions: []
- name: Bitbucket
  versions: []
title: Bitbucketのリポジトリをバックアップする
updated_at: '2020-06-10T14:22:32+09:00'
url: https://qiita.com/7shi/items/b70e2837be3e41fbde66
slide: false
---

Bitbucket の API でリポジトリの情報集めてバックアップします。

主な目的は Mercurial 廃止に伴うリポジトリ削除への対応ですが、Git リポジトリにも対応しています。

※ 当初、Mercurial 廃止は2020年5月31日が期限でしたが、情勢を鑑みて1カ月延期されました。

* [Sunsetting Mercurial support in Bitbucket - Bitbucket](https://bitbucket.org/blog/sunsetting-mercurial-support-in-bitbucket)

この記事ではリポジトリ移行の話題は扱いません。以下の記事などを参考にしてください。

* [BitbucketのMercurialリポジトリをGitHubのGitリポジトリに移動させた話](https://qiita.com/wa2c/items/26e55fbdbeaa0b311db4)
* 変換スクリプト: <https://twitter.com/k_sugimoto/status/1270466386700034048>

# API

Bitbucket のリポジトリなどの情報は API で取得できます。

* [REST APIs - Atlassian Documentation](https://confluence.atlassian.com/bitbucket/rest-apis-222724129.html)

以下の記事を参考にしました。

* [APIでBitbucketにアクセスしてみる](https://qiita.com/ksato9700/items/bbf89abb7acbac717267)
* [[Python] 3系でBasic認証付きのHTTPリクエストを発行する（urllib.request利用） - YoheiM .NET](https://www.yoheim.net/blog.php?q=20181003)

# スクリプト

Python で情報収集用のスクリプトを書きました。

* [[py] Get repository informations at Bitbucket — Bitbucket](https://bitbucket.org/7shi/workspace/snippets/5LM6bK)

プライベートリポジトリの情報を取得するためユーザー名とパスワードを書き換えてください。

```py:3行目
authinfo = "USER:PASS"
```

スクリプトを実行すると API でリポジトリとスニペットの情報を集めます。複数ページに分割された情報を 1 ファイルにまとめます。（整形済）

* repositories.json
* snippets.json

issues や pullrequests などの情報は、リポジトリごとにディレクトリを作って保存します。（未整形）

* 例: repositories/xxx/issues.json

リポジトリやスニペットのクローンは自動では行いません。出力されたクローン用のシェルスクリプトを実行してください。

* repositories-clone.sh
* snippets-clone.sh

# 仕様

アクセスにはウェイトを入れています。

```py:19行目
    time.sleep(1)
```

保存した JSON は cache ディレクトリに入れて、再度実行した時はそちらを参照します。再取得したいときは削除してください。

cache 内の JSON は送られたままの形で保存します。改行が入っていないため、読むときは整形すると良いでしょう。

```shell-session:整形の例
python -m json.tool cache/repositories-1.json
```

links に記載された情報のうち、API を参照しているものを取得します。

```json
        "links": {
            "watchers": {
                "href": "https://api.bitbucket.org/2.0/（略）"
            },
            "branches": {
                "href": "https://api.bitbucket.org/2.0/（略）"
            },
            "tags": {
                "href": "https://api.bitbucket.org/2.0/（略）"
            },
            "commits": {
                "href": "https://api.bitbucket.org/2.0/（略）"
            },
            （略）
        },
```

# 参考

json.tool のソースコードは、ライブラリの機能を使ってシンプルなコマンドを作る例として参考になります。

* <https://github.com/python/cpython/blob/3.8/Lib/json/tool.py>
