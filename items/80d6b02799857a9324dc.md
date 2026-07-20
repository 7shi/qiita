---
coediting: false
comments_count: 2
created_at: '2017-08-02T18:50:21+09:00'
id: 80d6b02799857a9324dc
likes_count: 10
private: false
reactions_count: 0
stocks_count: 9
tags:
- name: Python
  versions: []
- name: ニューラルネットワーク
  versions: []
- name: MNIST
  versions: []
title: MNISTを認識するニューラルネットワークの画像化
updated_at: '2017-08-26T16:23:20+09:00'
url: https://qiita.com/7shi/items/80d6b02799857a9324dc
slide: false
---

ニューラルネットワークによる手書き数字認識について、各ノードへの元画像の影響を視覚化します。

# アルゴリズム

【注】適当に思い付いたアルゴリズムです。どの程度正確に影響度が測れるかは未検証です。

比較の基準としてピクセルがすべて0のソースで各ノードの値を計算します。

評価対象とする画像を用意します。1ピクセルだけソースに入れて各ノードの値を計算して、すべて0のときと値を比較します。これをすべてのピクセルに対して行ったものを、ノードごとに特定のピクセルが与える影響とします。

これを画像化することで、視覚的に影響を見ることができます。

# 準備

『ゼロから作るDeep Learning』のサンプルを使います。

* https://github.com/oreilly-japan/deep-learning-from-scratch

初回実行時にMNIST（手書き数字のデータ）をダウンロードするようになっているので、MNISTを使用するスクリプトを実行しておきます。

```text
$ cd ch03
$ python neuralnet_mnist.py
Accuracy:0.9352
```

以下の2つのファイルを取り出します。

* dataset/mnist.pkl
* ch03/sample_weight.pkl

以下のスクリプトを実行すると、画像が生成されます。

* [mnist-nn.py](https://bitbucket.org/snippets/7shi/EA5py7)

# 画像例

ニューラルネットワークを計算して、途中のノードを取り出します。`sigmoid` 適用前後で画像はほとんど変化しないため `a1, a2` は捨てます。しかし後で示すように `softmax` 適用前後では大きく変化するため `a3` は拾います。

```py3
def predict(x):
    a1 = np.dot(x, W1) + b1
    z1 = sigmoid(a1)
    a2 = np.dot(z1, W2) + b2
    z2 = sigmoid(a2)
    a3 = np.dot(z2, W3) + b3
    z3 = softmax(a3)
    return z1, z2, a3, z3
```

【追記 2017.08.26】 z1 は影響がピクセルごとに独立しているから良いのですが、z2 以降はピクセル間の影響があり、それを考慮していないことが判明しました。どのように修正するべきか検討中です。進展があれば追記する予定です。

すべて白にした画像を確認します。数値は `softmax` によって算出された確率を表します。

![見出し.png](https://qiita-image-store.s3.amazonaws.com/0/32057/587f516e-d637-ab56-ada2-a59a8a022240.png)
![white.png](https://qiita-image-store.s3.amazonaws.com/0/32057/98e92ec3-aa6c-e11d-3d92-cf669b0f47d3.png)

背景色（灰色）より明るければプラス、暗ければマイナスとなって、総合的にプラスが大きいものが確率が高くなります。プラスとマイナスは相殺するので、必ずしもはっきり形が分かるものが確率が高くなるとは限りません。`softmax` を通すとメリハリがなくなって何が何だか分からなくなります。

数字を確認します。すべて白の画像から数字の形にくり抜かれることが分かります。

![0.png](https://qiita-image-store.s3.amazonaws.com/0/32057/f642a94c-fca8-caf6-74b8-c54cb2291cc1.png)

![1.png](https://qiita-image-store.s3.amazonaws.com/0/32057/d483621e-7f47-9cba-ab7a-4f7d45c6c3ca.png)

![2.png](https://qiita-image-store.s3.amazonaws.com/0/32057/e80b4b9b-c25d-dac8-1087-e6df5bd3a3bb.png)

![3.png](https://qiita-image-store.s3.amazonaws.com/0/32057/22dfb736-5304-2beb-914f-9497fd95227a.png)

![4.png](https://qiita-image-store.s3.amazonaws.com/0/32057/4b0aba79-a178-796a-d1e6-46b41fc66a35.png)

![5.png](https://qiita-image-store.s3.amazonaws.com/0/32057/34533fbb-c7ba-0305-9f40-7e40b516679c.png)

![6.png](https://qiita-image-store.s3.amazonaws.com/0/32057/2e75949b-e701-cc52-3c6e-3d42573a19a1.png)

![7.png](https://qiita-image-store.s3.amazonaws.com/0/32057/e45fc656-e6b4-45bf-519d-82ca6c33549e.png)

![8.png](https://qiita-image-store.s3.amazonaws.com/0/32057/0007429a-6f30-c363-969a-bd4e1862f82d.png)

![9.png](https://qiita-image-store.s3.amazonaws.com/0/32057/90a8dd22-8a30-bc71-d8d1-658c99597e7e.png)

# 参考

Pythonの書き方を参考にさせていただきました。

* [NumPyのarrayとPILの変換 - white wheelsのメモ](http://d.hatena.ne.jp/white_wheels/20100322/p1)
* [Pythonでリストをflattenする方法まとめ - Soleil cou coupé](http://d.hatena.ne.jp/xef/20121027/p2)
