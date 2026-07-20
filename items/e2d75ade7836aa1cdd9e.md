---
coediting: false
comments_count: 0
created_at: '2023-12-06T13:26:56+09:00'
id: e2d75ade7836aa1cdd9e
likes_count: 1
private: false
reactions_count: 0
stocks_count: 0
tags:
- name: JavaScript
  versions: []
- name: promise
  versions: []
- name: chrome-extension
  versions: []
- name: async
  versions: []
- name: download
  versions: []
title: Chrome 拡張機能での同時ダウンロード数制御
updated_at: '2023-12-23T23:18:37+09:00'
url: https://qiita.com/7shi/items/e2d75ade7836aa1cdd9e
slide: false
---

Chrome 拡張機能の開発で background 側のスクリプトを想定した記事です。

認証の関係で wget などのツールが使えないとき、拡張機能からファイルをダウンロードしたいことがあります。何も考えずに次々キューに放り込むと、ダウンロードが追い付かずにどんどん溜まって、数百を超えると OS の動作にも支障を来すほど重くなります。そこで同時ダウンロード数の制御を試みます。

# 実装

`chrome.downloads.download()` をラップして、成功か失敗まで `await` できるようにします。fetch API と同じように使えます。

```js
const apiTimeout = 10000;

function download(options) {
    return new Promise(async (resolve, reject) => {
        let id, deltas = {};
        const onDownloadComplete = delta => {
            if (id === undefined) {
                deltas[delta.id] = delta;
            } else if (delta.id == id) {
                checkDelta(delta);
            }
        }
        chrome.downloads.onChanged.addListener(onDownloadComplete);
        function checkDelta(delta) {
            if (delta.state && delta.state.current === "complete") {
                chrome.downloads.onChanged.removeListener(onDownloadComplete);
                resolve(delta.id);
            } else if (delta.error) {
                chrome.downloads.onChanged.removeListener(onDownloadComplete);
                reject(new Error(delta.error.current));
            } else if (delta.state && delta.state.current === "interrupted") {
                chrome.downloads.onChanged.removeListener(onDownloadComplete);
                reject(new Error(delta.state.current));
            }
        }
        const timeId = setTimeout(async () => {
            if (id !== undefined) return;
            if (options.url) {
                const query = { url: options.url };
                const items = await chrome.downloads.search(query);
                if (items.length) {
                    id = items[0].id;
                    if (id in deltas) checkDelta(deltas[id]);
                    return;
                }
            }
            reject(new Error("API timeout"));
        }, apiTimeout);
        try {
            id = await chrome.downloads.download(options);
        } catch (e) {
            return reject(e);
        } finally {
            clearTimeout(timeId);
        }
        if (id in deltas) checkDelta(deltas[id]);
    });
}
```

:::note info
ダウンロード開始前にリスナーを登録するため、フローがやや複雑になっています。`id` を取得する前に `onChanged` が通知される可能性を考慮して、それによるすり抜けに対策するためです。

リスナーでは正常終了とエラーと中断のみチェックして、それ以外の通知は無視します。一応どのような通知が来るのか観察してみましたが、無視することになるのは `filename` の通知くらいのようです。
:::

:::note warn
まれに `chrome.downloads.download()` の返す Promise が resolve も reject も発行しないことがあるため、10 秒でタイムアウトにします。

タイムアウト後、キューを URL で検索して既にダウンロードが開始されていないか確認します。ダウンロードが正常に開始されていても `id` が渡されないことがあるため、その対策です。（数千回に一回程度の頻度で発生）

タイムアウト後にダウンロードが開始されることもあります。その場合は検出できないため、キャンセルもされません。
:::

上で実装した `download` を使って同時ダウンロード数を制御します。指定した数のプールを作って、その中でループを回します。

```js
// urlFiles: [[url, filename], ...]
async function downloads(urlFiles, maxConnections = 10) {
    const queue = Array.from(urlFiles);
    const total = queue.length;
    let done = 0;
    const pids = Array(Math.min(total, maxConnections)).fill().map((_, i) => i + 1);
    const results = await Promise.allSettled(pids.map(async pid => {
        while (queue.length) {
            const [url, filename] = queue.shift();
            try {
                await download({ url, filename });
            } catch (e) {
                console.error(e, url, filename);
            }
            done++;
            const percent = Math.floor(10000 * done / total) / 100;
            console.log(`Progress: ${done}/${total} (${percent}%)`);
        }
    }));
    for (let i = 0; i < results.length; i++) {
        const r = results[i];
        if (r.status === "rejected") {
            console.error(`pid ${i + 1}: ${r.reason}`);
        }
    }
}
```

:::note info
いわゆるスレッドプールに似ていますが、スレッドではなく並列実行されないため、排他制御は不要です。

デバッグ用に連番で `pid` (Promise ID) を振っています。
:::

# その他

拡張機能の開発は初めてで勝手が分からなかったので、ハマった点をメモしておきます。

* background 側のコンソールは分離されているので、拡張機能の画面で Service Worker から開く。
    * コンソールを開いておかないと拡張機能が非アクティブなときにシャットダウンされ、変数が失われてデバッグに支障を来す。
* background 側のスクリプトは登録したときのものが使われるので、更新後に拡張機能の画面で ⟳ をクリックする。

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/32057/3be9d4f0-0e05-e3cb-4215-171b5ad7beae.png)

その他、気付いた点です。

* ダウンロードはエクスプローラーと連動しているらしい。大量のファイルの移動や削除が進行しているとダウンロード完了後にストールするが、エクスプローラーの処理が完了すれば正常に戻る。
* 大量の作業をする際、Promise の完了を待たずにどんどん発行すると、とんでもなく重くなる。場合によってはスクリプトエンジンがクラッシュする。

フロント側とバックグラウンド側は分離されてメッセージパッシングでやり取りするのは、MINIX のようなマイクロカーネル OS を彷彿とさせます。

# 参考

Firefox にも互換実装があります。ドキュメントはこちらの方が分かりやすいです。

https://developer.mozilla.org/ja/docs/Mozilla/Add-ons/WebExtensions/API/downloads/download

# 関連記事

Promise の勘所をまとめています。

https://qiita.com/7shi/items/a2bb35f27cd4a56f7bac
