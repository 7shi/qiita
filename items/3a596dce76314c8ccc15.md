---
coediting: false
comments_count: 0
created_at: '2023-11-23T11:40:12+09:00'
id: 3a596dce76314c8ccc15
likes_count: 2
private: false
reactions_count: 0
stocks_count: 0
tags:
- name: HTML
  versions: []
title: label タグでの for の省略
updated_at: '2023-11-23T12:14:03+09:00'
url: https://qiita.com/7shi/items/3a596dce76314c8ccc15
slide: false
---

チェックボックスで `<label>` タグを付けないとクリック範囲が狭まって不便です。`<label>` タグでチェックボックスを囲めば記述がすっきりします。

常識なのかもしれませんが、自分はこれを知らなくて `for` は必須だと思い込んでいたので、メモしておきます。

# 概要

チェックボックスの横に文字を書くだけだと、文字をクリックしても反応しません。

```html
<input type="checkbox" />check1
```

※ 一昔前はこのような UI をよく見掛けました。

チェックボックスとラベルを関連付けるには、`<input>` で `id` 属性を指定して、`<label>` で `for` 属性を指定します。

```html
<input type="checkbox" id="check2" /><label for="check2">check2</label>
```

チェックボックスを `<label>` で囲めば、関連付けは明確となるため `id` や `for` 属性は不要となります。

```html
<label><input type="checkbox" />check3</label>
```

※ 一般的な運用（チェックボックスをスクリプトから参照する等）では `id` 属性が必要ですが、ここではクリックの連動だけを問題にしています。

<p class="codepen" data-height="210" data-default-tab="html,result" data-slug-hash="mdvLBwL" data-user="7shi" style="height: 210px; box-sizing: border-box; display: flex; align-items: center; justify-content: center; border: 2px solid; margin: 1em 0; padding: 1em;">
  <span>See the Pen <a href="https://codepen.io/7shi/pen/mdvLBwL">
  checkbox &amp; label</a> by 七誌 (<a href="https://codepen.io/7shi">@7shi</a>)
  on <a href="https://codepen.io">CodePen</a>.</span>
</p>
<script async src="https://cpwebassets.codepen.io/assets/embed/ei.js"></script>

# 参考

https://developer.mozilla.org/ja/docs/Web/HTML/Element/label

> 他の方法として、 `<input>` を直接 `<label>` の内側に入れることができますが、この場合は関連付けが明確なので、 `for` および `id` 属性は必要ありません。

# 経緯

自分のサイトを Edge の開発者ツールで見ると、アクセシビリティのエラーが出ていました。そこで「さらに読む」のリンクを見ると、例が示されていました。

https://dequeuniversity.com/rules/axe/4.4/select-name?application=axeAPI

> The label can also be implicit by wrapping the <label> element around the select:
> 
> ```html
> <label>State: <select></select></label>
> ```

※ これは `<select>` についての説明ですが、`<input>` でも同様です。
