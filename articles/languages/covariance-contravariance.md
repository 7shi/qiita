---
coediting: false
comments_count: 1
created_at: '2016-11-27T01:56:57+09:00'
id: 39a222b5928bf0b6f745
likes_count: 126
private: false
reactions_count: 0
stocks_count: 96
tags:
- name: C#
  versions: []
title: 共変戻り値と反変引数
updated_at: '2016-11-29T15:57:10+09:00'
url: https://qiita.com/7shi/items/39a222b5928bf0b6f745
slide: false
---

C#を学習すると共変と反変という用語がでてきます。難しそうな用語ですが、その取っ掛かりとして戻り値と引数に的を絞って図によるイメージで説明します。数学的な知識は前提としませんし、コードも簡単なものしか出て来ません。型周りの知識を整理するのにも役立つでしょう。

この記事で最終的に説明したいことは、次のようにデリゲートから参照するメソッドの戻り値や引数の型を変える規則についてです。

```csharp
C Foo(A a) { return new C(); }  // 戻り値はBの派生クラスC、引数はBの基底クラスA
delegate B Delg(B b);           // 戻り値と引数ともにB
Delg d = Foo;                   // 型が一致しないのに、なぜ許されるのか？
```

この規則はイメージしにくく混乱を招きがちですが、図による直感的な説明を試みます。

※ 具体例で用語に慣れることも目的としています。なるべく話を単純にするため、ジェネリックとの関係には触れません。

# 継承

例として、`A`を継承した`B`というクラスを考えます。

```csharp
class A {}
class B : A {}
```

継承を包含関係で図示すれば、視点によって次の2種類が考えられます。

視点|図|概要
:--:|:--:|----
型|![1_A⊃B.png](https://qiita-image-store.s3.amazonaws.com/0/32057/d37f9cb5-dd7d-c0c8-b3b0-db23da478d2e.png)|`B` を `A` として扱えることから、`A` が `B` を含むイメージ<br>```A a = new B();```
実装|![2_A⊂B.png](https://qiita-image-store.s3.amazonaws.com/0/32057/4de6ebbc-6ff3-6302-e317-08923f7f3a31.png)|`A` を継承した `B` が実装を追加することから、`B` が `A` を含むイメージ

まったく逆の図ですが、どちらかが正しいというものではなく、目的に応じて選択することになります。今回は**型が話題の中心**のため、「型」の図を使用します。

## 図の例

先ほどの図に`Object`と`String`を追加してみます。

![3_ObjStrAB.png](https://qiita-image-store.s3.amazonaws.com/0/32057/03f725f8-d809-b452-088f-09690ad71ee0.png)

図の見方というか、イメージが湧いたでしょうか。

# 共変・反変

MSDN では次のように説明されています。（「」内の訳語を補っています）

[ジェネリックの共変性と反変性](https://msdn.microsoft.com/ja-jp/library/dd799517(v=vs.110).aspx) より

> * 「共変」Covariance<br>最初に指定された型よりも強い派生型を使用できるようにします。
> * 「反変」Contravariance<br>最初に指定された型よりも一般的な (弱い派生の) 型を使用できるようにします。

「強い」「弱い」は「狭い」「広い」とも表現されることがあります。ここでは当面必要な範囲で割り切って、継承に限定して話を進めます。

* 共変：型の制限を強める（対象範囲を狭める） → 継承先の派生クラスに変更すること
* 反変：型の制限を弱める（対象範囲を広げる） → 継承元の基底クラスに変更すること

便宜上、継承が進む方向と**共**通なのが「**共**変」と覚えておけば良いでしょう。

図で考えれば、内側への矢印が共変、外側への矢印が反変となります。「狭い」「広い」というイメージも表現されています。

![4_共変・反変.png](https://qiita-image-store.s3.amazonaws.com/0/32057/245b7050-afb3-6c9b-9bf6-5299970823b8.png)

※ これは説明のためのイメージに過ぎず、実際に何か物理的な広さを持っているわけではありません。

## Ruby

イメージを補強するため、Rubyでの継承の書式を紹介します。

※ この記事でRubyが出て来るのはここだけです。

クラスの定義で、C#では継承関係を `:` で表しますが、Rubyでは `<` で表します。

```csharp:C#
class A {}
class B : A {}
```
```rb:Ruby
class A
end

class B < A
end
```

`<` は矢印として捉えて `B` は `A` から派生する（B ← A）というイメージが持てます。それが**共変**の方向です。

※ この矢印は[UMLのクラス図](https://ja.wikipedia.org/wiki/%E3%82%AF%E3%83%A9%E3%82%B9%E5%9B%B3)とは逆向きなのに注意してください。

今回の図にこじつければ、`B < A` はサイズ比較で `A` が広いとも解釈できます。

![1_A⊃B.png](https://qiita-image-store.s3.amazonaws.com/0/32057/d33c897a-8e66-54a5-5ac9-ecaeaf853b8a.png)

# 参照

図による型のイメージに慣れるため、ここからしばらくは基本的な言語仕様を図で説明します。

説明には `B` を継承した `C` も使用します。

```csharp:A→B→C
class A {}
class B : A {}
class C : B {}
```

![5_A⊃B⊃C.png](https://qiita-image-store.s3.amazonaws.com/0/32057/19ceb95f-694f-8a9e-c4bd-190477aab9df.png)

インスタンスを生成して変数に代入する書式を示します。

```csharp
A a = new A();
B b = new B();
C c = new C();
```

これを変化させて結果を観察します。

## 右辺の型を変化

左辺を `B` に固定して、右辺の型を変化させてみます。`B` が入るのは当然として、`A` はエラー、`C` はOKです。

```csharp
B b = new A();  // エラー
B b = new B();  // OK
B b = new C();  // OK
```

これを図で考えれば、大きい箱に小さいオブジェクトは入るのに対して、その逆はできないとイメージできます。`B` の通り口より大きな `A` は通り抜けができません。

![6_右辺.png](https://qiita-image-store.s3.amazonaws.com/0/32057/09c70616-0c86-fe56-7100-b6ac4b1d525f.png)

※ 実際には、参照型は値型と異なりインスタンス本体が代入されるわけではありません。あくまで説明のためのイメージです。

## 左辺の型を変化

次に右辺を `B` に固定して、左辺の型を変化させてみます。`B` が入るのは当然として、`A` はOK、`C` はエラーです。

```csharp
A a = new B();  // OK
B b = new B();  // OK
C c = new B();  // エラー
```

先ほどと同様に通路が通れるかどうかでイメージできます。

![7_左辺.png](https://qiita-image-store.s3.amazonaws.com/0/32057/8e0396ca-1032-a0a5-07e9-5e2ccc12bd28.png)

## 共変とアップキャスト

`A a = new B();` は左辺が `A` の型ですが、`A` は派生クラスの `B` を含むため、`new B()` が代入できます。このように左辺に注目して「`A` だから `B` もいける」と考えることは、普段のプログラミングでも感覚的に行っているのではないでしょうか。

この考え方を形式的に `A` → `B` と表せば、継承が進む方向のため**共変**だと解釈できます。このように普段感覚的に行っていることに名前を付けたと捉えれば、少しは抵抗感が減るかもしれません。

また右辺に注目すれば、暗黙で `A a = (A)new B();` という `B` → `A` のキャストが行われているとも考えられます。このような基底クラスへのキャストを**アップキャスト**と呼びます。

左辺に注目するか右辺に注目するかで、型の変化が逆向きになっていることに注意してください。これは後でも出て来ますが、どこを基準に考えるかということが重要になります。

# メソッド

メソッドを図にすれば、入力（引数）と出力（戻り値）のある箱として表現できます。

※ ここでは簡単のため、戻り値がない（`void`）メソッドを除外します。

引数と戻り値ともに `B` のメソッド `Foo` を考えます。

```csharp
B Foo(B b)
{
    return new B();
}
```

![8_Foo.png](https://qiita-image-store.s3.amazonaws.com/0/32057/a4b08817-93d0-26ae-cad0-cd854635a018.png)

## 引数

`Foo` の引数に別の型を渡すことを考えます。

```csharp:呼び出し側
Foo(new A());  // エラー
Foo(new C());  // OK
```

代入と同様に `A` は通り抜けできず、`C` は通り抜けできるとイメージできます。

![9_Foo引数.png](https://qiita-image-store.s3.amazonaws.com/0/32057/e96f6b1e-22ae-67af-b180-028a874cadc3.png)

引数 `B b` へ参照を代入していると考えれば、本質的には `B b = new A();` と同じ条件だと分かります。

## 戻り値

今度は戻り値の方を変えてみます。

```csharp
B Foo(B b)
{
    return new A();  // エラー
    return new C();  // OK
}
```

やはり通り抜けでイメージできます。`A` は大き過ぎて外に出られません。

![10_Foo戻り値.png](https://qiita-image-store.s3.amazonaws.com/0/32057/e374fcba-4a42-a696-6751-cdf7439083bf.png)

## 受け取り

メソッドの戻り値を受け取ることを考えます。メソッドから出て来たオブジェクトを漏れなく受け取るには、受け口はメソッドの戻り値と同じか広く取る必要があります。

```csharp
A a = Foo(null);  // OK
B b = Foo(null);  // OK
C c = Foo(null);  // エラー
```

![11_Foo代入.png](https://qiita-image-store.s3.amazonaws.com/0/32057/46eca0fb-83ed-00ad-3cb2-1c24b1b69d77.png)

このように出入口をつなぐ場合、型の変化は進行方向に向かって広がること（暗黙のアップキャスト）しか許されないことが分かります。

![12_進行方向.png](https://qiita-image-store.s3.amazonaws.com/0/32057/52b53c60-f2a1-02eb-fe80-e8a2905edf6b.png)

# デリゲート

オブジェクトを変数に代入するように、メソッドはデリゲートに代入できます。

※ マルチキャストデリゲートまで考えればこの言い方は不正確ですが、デリゲートにまつわる共変・反変の理解を優先するため、単純化して説明します。

引数と戻り値ともに `B` のデリゲート `Delg` を考えます。

```csharp
delegate B Delg(B b);
```

デリゲートを図にすれば、メソッドと同じように入力（引数）と出力（戻り値）のある箱として表現できます。

![13_Delg.png](https://qiita-image-store.s3.amazonaws.com/0/32057/bed3aac8-0daa-2ed8-8502-ab49ca0040dc.png)

デリゲート単体で呼び出すことはできません。

```csharp
Delg d;
d(new B());  // エラー
```

![14_DelgEmpty.png](https://qiita-image-store.s3.amazonaws.com/0/32057/056bb2ed-4783-10db-b963-30745b6079a0.png)

メソッドを割り当てれば呼び出せるようになります。

```csharp
Delg d = Foo;
d(new B());
```

![15_DelgFoo.png](https://qiita-image-store.s3.amazonaws.com/0/32057/bc89066c-5414-e1d1-20a8-10f28fa3a2ba.png)

※ 実際にはデリゲートからメソッドが参照されており、中に入るわけではありません。あくまで説明のためのイメージです。

さて、ここまでは準備でした。いよいよここから先がこの記事の核心です。

## 共変戻り値

戻り値の異なるメソッドを用意します。

※ 後で引数を変える都合上、戻り値と引数を接尾辞として追加しています。

```csharp
A FooAB(B b)
{
    return new A();
}

C FooCB(B b)
{
    return new C();
}
```

これを `Delg` に割り当てようとすると、`FooAB` はエラーになりますが、`FooCB` はOKです。

```csharp
Delg d = FooAB;  // エラー
Delg d = FooCB;  // OK
```

メソッドから出て来た戻り値がデリゲートを通り抜けられるかどうかでイメージできます。

![16_共変戻り値.png](https://qiita-image-store.s3.amazonaws.com/0/32057/e1e1e6ec-24a0-21d9-2491-ef21bff25991.png)

メソッドの方が狭ければ通り抜けられます。デリゲートの型からメソッドの型を見れば `B` → `C` となり共変です。このようにデリゲートが共変の戻り値を受け付けることを**共変戻り値**と呼びます。

進行方向に対して広がることしか許されないという原則を満たしています。戻り値をデリゲートから見ると進行方向とは逆になることに注意が必要です。

## 反変引数

今度は引数の型を変えてみます。

```csharp
B FooBA (A a)
{
    return new B ();
}

B FooBC (C c)
{
    return new B ();
}
```

これを `Delg` に割り当てようとすると、`FooBA` はOKですが、`FooBC` はエラーになります。

```csharp
Delg d = FooBA;  // OK
Delg d = FooBC;  // エラー
```

戻り値と同様に、引数がデリゲートを通り抜けられるかどうかでイメージできます。外から見えているのはデリゲートの引数型 `B` であることに注意してください。

![17_反変引数.png](https://qiita-image-store.s3.amazonaws.com/0/32057/fdaa73cd-da3f-a5fb-5ccd-e2c194269619.png)

※ 右の図は `C` なら通り抜けられそうですが、デリゲートは `B` を通すことを保証しないといけないため、`B` が通らないのは認められません。

メソッドの方が広ければ通り抜けられます。デリゲートの型からメソッドの型を見れば `B` → `A` となり反変です。このようにデリゲートが反変の引数を受け付けることを**反変引数**と呼びます（あまり一般的な用語ではありません）。

ここでも進行方向に対して広がることしか許されないという原則を満たしています。戻り値とは逆になっているのは、進行方向ではなくデリゲートを基準に見ているためです。戻り値では進行方向とは逆になっています。

![18_共変・反変.png](https://qiita-image-store.s3.amazonaws.com/0/32057/55db7f66-1fc6-9c46-c33d-5a7194aea0ba.png)

このように共変・反変を考えるときは、どこを基準に見ているのかを押さえておかないと混乱します。

※ この図式を一般化して、入力に関係するものは反変、出力に関係するものは共変という図式を意識しておけば、この記事では言及しませんがジェネリックとの絡みも理解しやすくなるでしょう。

# オーバーライド

派生クラスでメソッドをオーバーライドするケースを考えます。

引数の型を変えるとメソッドのオーバーロードとして扱われてしまうため、引数の型を変えることはできません。戻り値も型を変えるとエラーになります。

```csharp:C#
class A {}
class B : A {}
class C : B {}

class Test1
{
    protected virtual B Apply(B b)
    {
        return new B();
    }
}

class Test2 : Test1
{
    protected override B Apply(A b)  // エラー: オーバーライド元がない
    {
        return new B();
    }

    protected override C Apply(B b)  // エラー: 共変戻り値不可
    {
        return new C();
    }
}
```

このようにオーバーライドでは型を変えることはできません。デリゲートの方が柔軟です。

## Java

参考までにJavaのことを書いておきます。

Javaでも引数の型を変えるとオーバーロードとして扱われる点は同じですが、共変戻り値は認められています。

```java:Java
class A {}
class B extends A {}
class C extends B {}

class Test1 {
    protected B apply(B b) {
        return new B();
    }
}

class Test2 extends Test1 {
    protected B apply(A b) {  // 単なるオーバーロード
        return new B();
    }

    protected C apply(B b) {  // OK: 共変戻り値
        return new C();
    }
}
```

Javaのメソッドはデフォルトでオーバーライドが可能なため、C#と異なり `virtual`, `override` キーワードはありません。逆に、オーバーライドを禁止するとき `final` を明示します。

# 参考

* [Covariant return type](https://en.wikipedia.org/wiki/Covariant_return_type)
* [共変性と反変性 (計算機科学)](https://ja.wikipedia.org/wiki/%E5%85%B1%E5%A4%89%E6%80%A7%E3%81%A8%E5%8F%8D%E5%A4%89%E6%80%A7_(%E8%A8%88%E7%AE%97%E6%A9%9F%E7%A7%91%E5%AD%A6))
