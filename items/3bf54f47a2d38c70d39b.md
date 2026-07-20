---
coediting: false
comments_count: 0
created_at: '2024-12-05T23:23:30+09:00'
id: 3bf54f47a2d38c70d39b
likes_count: 6
private: false
reactions_count: 0
stocks_count: 2
tags:
- name: Python
  versions: []
- name: TypeScript
  versions: []
- name: ModelContextProtocol
  versions: []
title: MCP サーバーで処理に時間が掛かった時の実装言語による挙動の違い
updated_at: '2025-02-07T03:27:10+09:00'
url: https://qiita.com/7shi/items/3bf54f47a2d38c70d39b
slide: false
---

簡単な Model Context Protocol（MCP）サーバーを TypeScript と Python で実装して比較したところ、処理時間が長くなった場合に異なる挙動を示すことが判明しました。それについてまとめます。

MCP サーバーの実装の初歩についても説明します。

:::note info
【追記 2025/2/7】
Python の MCP サーバーがタイムアウトで不安定になる問題は修正されました。
:::

https://github.com/modelcontextprotocol/python-sdk/pull/167

# 現象

MCP サーバーのデバッグには MCP Inspector を使用します。

https://github.com/modelcontextprotocol/inspector

MCP Inspector ではタイムアウト時間が 10 秒に設定されています。これはソースコードにハードコーディングされた値です。

```tsx:client/src/App.tsx
const DEFAULT_REQUEST_TIMEOUT_MSEC = 10000;
```

このタイムアウトに達すると、MCP Inspector は処理を打ち切ります。TypeScript 実装のサーバーはタイムアウト後も動作を継続しますが、~~Python 実装のサーバーはクラッシュします~~。【修正済】

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/32057/39db8c6b-7d4a-509c-d9b8-27d3743c850a.png)

一方、Claude デスクトップアプリからの接続では、タイムアウト時間は 1 分に設定されているようです（ソースコードはないため実験により確認）。TypeScript 実装のサーバーは、このケースでもタイムアウト後に正常な動作を継続します。

~~Python 実装の場合、より深刻な問題として、タイムアウト以前に問題が発生することが確認されています。具体的には、処理時間が 8～10 秒以上かかる場合（変動するため正確なタイミングは不明）、結果の送信後にサーバーがクラッシュします。これはタイムアウトの設定値とは無関係に発生する問題です。サーバーがクラッシュすると、以後の応答がなくなります。~~【修正済】

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/32057/dc2a157c-8efe-9804-d1ab-160995bd373b.png)

:::note info
このスクリーンショットでは 10 秒待って結果を返した後にサーバーがクラッシュするため、その後で指定した時間（この場合は 15 秒）に関係なく反応がなくなります。
:::

:::note warn
非同期でフローが複雑なため、どこでクラッシュが起きているのかは追い切れていません。そのため本記事では現象のみを記します。
:::

以上の状況より、外部問い合わせなどで処理時間が 8 秒を超えることがある場合、現状では TypeScript による実装の方が安定しているようです。

なお、この問題と本質的に同じだと思われる Issue が既に挙がっており、私の調査結果を報告しました。

https://github.com/modelcontextprotocol/python-sdk/issues/88#issuecomment-2522243103

# 実装

先ほど述べたような挙動を確認するための実装について説明します。

どのくらい時間が掛かれば問題が発生するかを確認するため、指定した秒数だけ待つ単機能の MCP サーバーを実装します。

https://github.com/7shi/mcp-wait

## TypeScript

以下を参考に実装します。

https://github.com/modelcontextprotocol/create-typescript-server

ひな形を生成します。

```bash
npx @modelcontextprotocol/create-server mcp-wait-ts
```

プロジェクトの名前などを聞かれるので [Enter] で進めます。

```text
? What is the name of your MCP server? mcp-wait-ts
? What is the description of your server? A Model Context Protocol server
? Would you like to install this server for Claude.app? (Y/n)
```

3 番目の質問に Y と答えると、Claude デスクトップアプリの設定を書き換えてくれます。

```json:claude_desktop_config.json
{
  "mcpServers": {
    "mcp-wait-ts": {
      "command": "node",
      "args": [
        "/path/to/mcp-wait-ts/build/index.js"
      ]
    }
  }
}
```

:::note warn
README のひな形には `node` ではなく `build/index.js` を直接呼び出すような内容が書かれますが、Windows では上で示したように `node` を介さないと正常に動作しません。
:::

生成されたディレクトリに入り、必要なライブラリをインストールします。

```sh
cd mcp-wait-ts
npm install
```

サンプルとしてノート機能のソースコードが生成されるため、不要な部分を削除して、`wait_seconds` というツール（MCP クライアントから呼び出す機能）を実装します。

```ts:src/index.ts
const server = new Server(
  {
    name: "mcp-wait-ts",
    version: "0.1.0",
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: "wait_seconds",
        description: "Wait for a specified number of seconds",
        inputSchema: {
          type: "object",
          properties: {
            seconds: {
              type: "number",
              description: "Number of seconds to wait",
            }
          },
          required: ["seconds"]
        }
      }
    ]
  };
});

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  switch (request.params.name) {
    case "wait_seconds": {
      const seconds = Number(request.params.arguments?.seconds);
      if (!seconds) {
        throw new Error("Seconds is required");
      }
      await new Promise((resolve) => setTimeout(resolve, seconds * 1000));
      return {
        content: [{
          type: "text",
          text: `Waited for ${seconds} seconds`
        }]
      };
    }

    default:
      throw new Error("Unknown tool");
  }
});
```

:::note info
公開した機能を問い合わせて呼び出す仕組みは、COM の [IUnknown](https://ja.wikipedia.org/wiki/IUnknown) を思い出しました。
:::

JavaScript にトランスパイルします。

```sh
npm run build
```

MCP Inspector でデバッグします。Tool から `wait_seconds` が呼び出せます。

```sh
npm run inspector
```

Claude デスクトップアプリを（Windows ではタスクトレイから）終了して再起動すれば、作成した MCP サーバーが利用できます。

```text:プロンプト
5秒待ってください。
```

MPC Inspector や Claude で秒数を変えながら実験した結果は、既に書いた通りです。

## Python

:::note info
後で補足に書きますが、Python 用の生成ツールの存在を見落としていたため、やや回り道をしました。uv の取っ掛かりにはなりましたし、必要最低限の構成も分かったため、敢えてこのまま公開します。
:::

以下を参考に実装します。

https://github.com/modelcontextprotocol/python-sdk

作業用のディレクトリを作って uv を初期化します。

```sh
uv init
```

必要なパッケージをインストールします。

```sh
uv add mcp
```

hello.py を server.py にリネームして、SDK の README に書かれたコードを切り貼りします。

```py:server.py
from mcp.server import Server, NotificationOptions
from mcp.server.models import InitializationOptions
import mcp.server.stdio
import mcp.types as types
import asyncio

server = Server("mcp-server-py")

import logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(server.name)

@server.list_tools()
async def list_tools() -> list[types.Tool]:
    return [
        types.Tool(
            name="wait_seconds",
            description="Wait for a specified number of seconds",
            inputSchema={
                "type": "object",
                "required": ["seconds"],
                "properties": {
                    "seconds": {
                        "type": "number",
                        "description": "Number of seconds to wait",
                    }
                },
            },
        )
    ]

@server.call_tool()
async def fetch_tool(
    name: str, arguments: dict
) -> list[types.TextContent]:
    if name != "wait_seconds":
        raise ValueError(f"Unknown tool: {name}")
    if "seconds" not in arguments:
        raise ValueError("Missing required argument 'seconds'")
    seconds = arguments["seconds"]
    await asyncio.sleep(seconds)
    return [types.TextContent(type="text", text=f"Waited for {seconds} seconds")]

async def run():
    try:
        # Run the server as STDIO
        async with mcp.server.stdio.stdio_server() as (read_stream, write_stream):
            await server.run(
                read_stream,
                write_stream,
                InitializationOptions(
                    server_name=server.name,
                    server_version="0.1.0",
                    capabilities=server.get_capabilities(
                        notification_options=NotificationOptions(),
                        experimental_capabilities={},
                    )
                )
            )
    except Exception as e:
        logger.error(f"Error: {e}")
    logger.debug("Server exited")

if __name__ == "__main__":
    asyncio.run(run())
```

:::note info
`logger` 経由の出力が MCP Inspector の左下に表示されます。標準入出力は MCP プロトコルの通信に使用されるため、`print()` は使用できません。
:::

MCP Inspector でデバッグします。

```sh
npx @modelcontextprotocol/inspector uv run server.py
```

:::note warn
Connect に失敗することがあります。その場合は MCP Inspector を起動したターミナルで [Ctrl]+[C] により強制終了して、MCP Inspector を再起動してください。
:::

Claude デスクトップアプリで動かすため設定ファイルに追記します。

```json:claude_desktop_config.json
{
  "mcpServers": {
    "mcp-wait-py": {
      "command": "uv",
      "args": [
        "--directory",
        "/path/to/mcp-wait/py",
        "run",
        "server.py"
      ]
    }
  }
}
```

MPC Inspector や Claude で秒数を変えながら実験した結果は、既に書いた通りです。

## 補足

後で気付きましたが、Python にもひな形を生成するツールも存在するため、そちらを利用した方がスムーズでした。

https://github.com/modelcontextprotocol/create-python-server

## 感想

TypeScript と Python を並行して扱ったため、npm/npx と uv/uvx が似たような位置付けにあることが実感できました。これまで pip と venv に慣れていたのもあって、uv は高速性が売りだとしても覚え直し？と感じて敬遠していましたが、何となくコツがつかめた気がします。

https://qiita.com/7shi/items/0f9c9ff7cf2fcb9597c5

また、Next.js プロジェクトだと構成が複雑で TypeScript や npx 周りのエコシステムが消化不良気味に感じていましたが（👉[参考](https://qiita.com/7shi/items/c19c22489839e822ef33)）、今回はソース構成が小規模だったため分かりやすかったです。

現代的なツールの取っ掛かりとして、ちょうど良い規模感の題材かもしれません。

# その他の問題

Python 実装では、Windows で文字コードの問題があります。具体的には、日本語データを使用するには、MCP サーバーの設定で環境変数を指定する必要があります。

```json:claude_desktop_config.json
      "env": {
        "PYTHONIOENCODING": "utf-8"
      }
```

詳細は以下の記事を参照してください。

https://qiita.com/7shi/items/0e31e10df92656aac207

:::note info
今回作成した mcp-wait は秒数のやり取りしかしないため、この問題を踏みません。
:::

TypeScript では文字コードの問題はなく、特に設定する必要はありません。

# 関連記事

https://qiita.com/7shi/items/e27866ce51c6b9a0f605
