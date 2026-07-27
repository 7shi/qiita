---
coediting: false
comments_count: 0
created_at: '2020-02-10T01:18:50+09:00'
id: 4cc1928061ff4598f10b
likes_count: 5
private: false
reactions_count: 0
stocks_count: 4
tags:
- name: JavaScript
  versions: []
- name: promise
  versions: []
- name: TextToSpeech
  versions: []
- name: WebSpeechAPI
  versions: []
- name: AsyncAwait
  versions: []
title: Promiseの処理をキャンセルする
updated_at: '2020-05-12T15:04:50+09:00'
url: https://qiita.com/7shi/items/4cc1928061ff4598f10b
slide: false
---

Promise で Web Speech API をラップして使っていましたが、キャンセルできるように実装するのに試行錯誤しました。想定していたような動きが実現できたので、メモを残しておきます。

<p class="codepen" data-height="265" data-theme-id="dark" data-default-tab="js,result" data-user="7shi" data-slug-hash="PoqwPEz" style="height: 265px; box-sizing: border-box; display: flex; align-items: center; justify-content: center; border: 2px solid; margin: 1em 0; padding: 1em;" data-pen-title="Web Speech API with Promise">
  <span>See the Pen <a href="https://codepen.io/7shi/pen/PoqwPEz">
  Web Speech API with Promise</a> by 七誌 (<a href="https://codepen.io/7shi">@7shi</a>)
  on <a href="https://codepen.io">CodePen</a>.</span>
</p>
<script async src="https://static.codepen.io/assets/embed/ei.js"></script>

↑ エラーになる場合は一度 [CodePen](https://codepen.io/) を開いてから、この記事をリロードしてください。

# 概要

前回の記事では正常終了 `onend` を `resolve`、異常終了 `onerror` を `reject` として扱いました。

* [非同期APIをPromiseでラップしてasync/awaitで使う](https://qiita.com/7shi/items/a2bb35f27cd4a56f7bac)

```javascript
function speak(lang, text) {
    return new Promise((resolve, reject) => {
        let u = new SpeechSynthesisUtterance(text);
        u.lang = lang;
        u.onend = resolve;
        u.onerror = reject;
        speechSynthesis.speak(u);
    });
}
```

読み上げ中に `speechSynthesis.cancel()` を呼ぶことでキャンセルできます。通常終了と同じ `onend` イベントが発生するため、イベントではキャンセルされたことが検知できません。

何らかの手段でキャンセルされたことを通知する必要があります。

# 戻り値

`resolve` への引数は `await` を通して戻り値になります。

```javascript:ブラウザのコンソール
> p = new Promise((resolve, reject) => resolve(123))
> await p
123
```

これを利用して正常終了かキャンセルかを戻り値で区別するように `speak` を実装します。例外を無視するため終了と同じ扱いとします。

```javascript
let stop = () => false;
function speak(lang, text) {
  return new Promise((resolve, reject) => {
    let speakend = cancel => {
      speakend = () => false;
      if (cancel) speechSynthesis.cancel();
      resolve(cancel);
      return cancel;
    };
    stop = () => speakend(true);
    let u = new SpeechSynthesisUtterance(text);
    u.lang = lang;
    u.onend = u.onerror = () => speakend(false);
    speechSynthesis.speak(u);
  });
}
```

キャンセルするには外部から `stop()` を呼びます。Promise のコンストラクタで `stop` を書き換えて `speakend` 経由で `resolve(true)` を呼べるようにしておくことで、終了イベント `onend` よりも先に終了させます。

# 利用方法

複雑さは Promise の中に閉じ込めたため、利用側のコードは簡単になります。

```javascript
button.onclick = async function() {
  if (stop()) return;
  button.textContent = "Stop";
  for (let [element, lang, text] of texts) {
    element.classList.add("speaking");
    let cancel = await speak(lang, text);
    element.classList.remove("speaking");
    if (cancel) break;
  }
  button.textContent = "Start";
};
```

ループによっていくつかのテキストを読み上げます。`speaking` をマークすることで読み上げ個所を示します。`await speak()` から戻ってマークを解除して、キャンセルされていればループから抜けます。

`reject` で例外によってキャンセルを通知することも可能ですが、今回は `resolve` によって戻り値で通知した方が利用側のコードが簡単になると判断しました。

戻り値は正常終了のときに `true` にした方が自然かもしれませんが、今回はキャンセルに注目して値を設定しました。

# 参考

Web Speech API の使い方は以下の記事を参照してください。

* [Web Speech API で読み上げ位置を取得](https://qiita.com/7shi/items/43452dcd34e57100fc3c)
