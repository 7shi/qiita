---
coediting: false
comments_count: 0
created_at: '2017-02-08T12:47:05+09:00'
id: 3253d5766a4c65cb1a1f
likes_count: 15
private: false
reactions_count: 0
stocks_count: 19
tags:
- name: Python
  versions: []
- name: GIMP
  versions: []
title: GIMPで画像を一括でレベル補正（Python-Fu）
updated_at: '2017-02-16T16:09:46+09:00'
url: https://qiita.com/7shi/items/3253d5766a4c65cb1a1f
slide: false
---

GIMPでPython-Fuを使って、特定のディレクトリにある画像ファイルを一括でレベル補正しました。スクリプトを寄せ集めで作るのに手間取ったため、メモとして残しておきます。

# 使い方

GIMPを起動して以下のメニューを選択します。

* フィルター → Python-Fu → コンソール

Python コンソールが表示されます。これは普通のPythonのREPLと同じですが、GIMPのライブラリが読み込まれた状態で起動します。

※ ExcelのVBAをご存知の方はイミディエイトペインと同じようなものだと考えると分かりやすいです。

今回はスクリプトを登録しないで直接実行します。以下のコードをコピペします。

※ `gamma` や `path` は適宜編集してください。

```py
import os, glob
gamma = 0.3  # 0.1(濃) - 10(薄)
path = "C:\\test"
outdir = os.path.join(path, "output")
if not os.path.exists(outdir):
    os.mkdir(outdir)

for jpg in glob.glob(os.path.join(path, "*.jpg")):
    img = pdb.gimp_file_load(jpg, "")
    disp = pdb.gimp_display_new(img)
    pdb.gimp_levels(img.active_drawable, 0, 0, 232, gamma, 0, 255)
    newjpg = os.path.join(outdir, os.path.basename(jpg))
    pdb.gimp_file_save(img, img.active_layer, newjpg, "")
    pdb.gimp_display_delete(disp)
```

これを張り付けてもプロンプトが `...` となり入力を要求されますが、何も入力しないで [Enter] を押すことでブロックを閉じて処理が始まります。

`pdb.gimp_levels()` を別の処理に変えれば、色々と応用ができるでしょう。

## 処理

先ほどの例で実際にレベル補正をしているのは次の一行です。

```fsharp
pdb.gimp_levels(img.active_drawable, 0, 0, 232, gamma, 0, 255)
```

ここを置き換えれば他の処理も可能です。いくつか例を示します。

### 範囲選択

```fsharp
pdb.gimp_rect_select(img, 0, 0, 1500, 2200, 2, False, 0)
```

この後にレベル補正などをすれば、画像の一部だけを加工できます。

### リサイズ

```fsharp
pdb.gimp_image_scale_full(img, 256, 256, 3)
```

### 切り抜き

```fsharp
pdb.gimp_image_crop(img, 1420, 2180, 130, 130)
```

## GIFからの変換

GIFファイルを開いて横幅を揃えてJPEGファイルとして保存する例です。縦横比を維持します。色のモードをRGBに変換する必要があります。

```py
width = 1048
for gif in glob.glob(os.path.join(path, "*.gif")):
    img = pdb.gimp_file_load(gif, "")
    disp = pdb.gimp_display_new(img)
    pdb.gimp_image_convert_rgb(img)
    pdb.gimp_image_scale_full(img, width, img.height * width / img.width, 3)
    newjpg = os.path.join(outdir, os.path.basename(gif)[:-3]+"jpg")
    pdb.gimp_file_save(img, img.active_layer, newjpg, "")
    pdb.gimp_display_delete(disp)
```

## 開いている画像

既に開いている画像に対しての一括処理は次のようにします。

```py
for img in gimp.image_list():
    pdb.gimp_levels(img.active_drawable, 0, 0, 232, gamma, 0, 255)
```

# コツ

Pythonの使い方ですが、オブジェクトに対して `dir(pdb)` などとすることでメソッドが表示できます。これで当たりを付けてから、Pythonコンソールで「参照」ボタンをクリックすると表示されるプロシージャーブラウザで調べるという手探りができます。

※ この辺のPythonの使い勝手を多少知っていたので、Script-FuではなくPython-Fuを使いました。

## 関数の探し方

当たりを付けると言っても、`dir()`で出て来る関数はあまりに多く、関数名から機能がすぐに思い付かないことも多いです。Excelのようにマクロの記録で取得できれば楽なのですが、そういったことはできないようです。

そこで間接的ですが、マニュアルから探す方法を紹介します。

* [GIMP (GNU 画像編集プログラム)](https://docs.gimp.org/ja/)

まずお目当ての機能のページを探します。たとえば画像の拡大・縮小（リサイズ）であれば次のページです。

* https://docs.gimp.org/ja/gimp-tool-scale.html

URLを見るとscaleという単語が見えるので、プロシージャーブラウザで検索して当たりを付けます。

![gimp-scale.png](https://qiita-image-store.s3.amazonaws.com/0/32057/8ba0aec5-2b06-a6e4-780a-a3ab94bc0e6e.png)

## 引数

リファレンスを見ても具体的にどういう数値を与えるのかよく分からない場合は、GUIと比較しながら考えます。

![gimp-levels.jpg](https://qiita-image-store.s3.amazonaws.com/0/32057/68dc90f8-c553-bc15-e140-cd2025043542.jpeg)

# 参考

Python-Fu を起動してファイルを開く例が載っています。

* [Python-Fu入門 - Gimpを便利に](http://yamanare.moko-moko.jp/python_fu/?contents=python_fu3)

今回は使いませんでしたがJPEGを指定して保存するときのパラメータの説明です。GIMPだけでなくjpeglibのソースまで調べたという労作です。

* [Discretized Spiritualities: Gimpのfile-jpeg-saveのパラメータ](http://akokubo.blogspot.jp/2011/04/gimpfile-jpeg-save.html) 2011.04.30

画像を一括で処理するための一連の流れについて説明した記事です。資料が少ない中、試行錯誤でスクリプトを組んだ労力は相当のものだったと推察します。

* [本の電子化を補助するためにGimpとpython-fuを使ってみた。 - Oillerの日記](http://d.hatena.ne.jp/Oiller/20101118/1290045181) 2010.11.18
* [問題集からプリントを作成するためにGimpとpython-fuを使ってみた。 - Oillerの日記](http://d.hatena.ne.jp/Oiller/20131116) 2013.11.16

Pythonでのディレクトリやファイルの扱い方は以下を参照しました。

* [Python: 指定したパスのディレクトリ中のファイル一覧を出力](http://www.yukun.info/blog/2008/08/python-directory-listdir-glob.html) 2008.08.09
* [[Python]ファイル/ディレクトリ操作](http://qiita.com/supersaiakujin/items/12451cd2b8315fe7d054) 2015.12.26

私がPython-Fuを使い始めた頃のツイートです。

<blockquote class="twitter-tweet" data-lang="ja"><p lang="ja" dir="ltr">GIMPで複数の画像を一括でレベル補正<br>フィルター→Python-Fu→コンソール<br>for img in gimp.image_list(): pdb.gimp_levels(<a href="https://t.co/Si5Ju30oXV">https://t.co/Si5Ju30oXV</a>_drawable,0,0,232,0.4,0,255)</p>&mdash; 七誌 (@7shi) <a href="https://twitter.com/7shi/status/757795937670443008">2016年7月26日</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>
<blockquote class="twitter-tweet" data-conversation="none" data-lang="ja"><p lang="ja" dir="ltr">GIMPで開いている画像一括で同サイズ選択(Python-Fu)<br>for img in gimp.image_list(): pdb.gimp_rect_select(img,0,0,1500,2200,2,False,0)<br>後で[Alt]ドラッグで手動調整するのに使用</p>&mdash; 七誌 (@7shi) <a href="https://twitter.com/7shi/status/757828806916710401">2016年7月26日</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>
