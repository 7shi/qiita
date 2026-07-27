---
coediting: false
comments_count: 0
created_at: '2023-03-18T01:25:06+09:00'
id: 8eae6d909e1b82b35215
likes_count: 1
private: false
reactions_count: 0
stocks_count: 0
tags:
- name: C#
  versions: []
- name: UTF-8
  versions: []
- name: 文字コード
  versions: []
- name: UTF-16
  versions: []
title: CESU-8 から UTF-16 への変換
updated_at: '2023-03-19T22:20:12+09:00'
url: https://qiita.com/7shi/items/8eae6d909e1b82b35215
slide: false
---

CESU-8（UTF-8 の変種）から UTF-16 へ変換します。前提事項を簡単に説明してから、C# で実装を示します。

この記事では 8bit を 1 バイト、16bit を 1 ワードとして扱います。

# UTF-16

初期の Unicode は 1 ワードで 65,536 文字を扱う規格として制定され、1 文字 2 バイト固定長で表すエンコーディングは UCS-2 と呼ばれました。

その後 65,536 文字では足りなくなったため、2 ワードで U+10000 以上の文字を表すためのサロゲートペアと呼ばれる仕組みによって UCS-2 を拡張したのが UTF-16 です。

1 ワード目|2 ワード目
:--:|:--:
D800～DBFF|DC00～DFFF

1 ワード目と 2 ワード目で異なるコードポイントを割り当てることで、連続した場合でも区切りミスが原理上起きないようになっています。

0x400 × 0x400 = 0x100000 (1,048,576) より約 100 万文字が追加できます。現時点ではまだ 75% ほど未使用領域が残っています。

https://ja.wikipedia.org/wiki/Unicode

> Unicodeの文字集合の符号空間は0 - 10FFFF16で111万4,112の符号位置がある<sup>[7]</sup>。Unicode 12.1（2019年5月7日公表）では13万7,929個 (12%) の文字<sup>[注釈 3]</sup>が割り当てられ、65個を制御文字に使い、13万7,468符号位置 (12%) を私用文字として確保している。また、2,048文字分をUTF-16のための代用符号位置に使用しており、加えて66の特別な符号位置は使われない。残りの83万6,536符号位置 (75%) は未使用である<sup>[8]</sup>。

# UTF-8

当初 UTF-8 は最長 6 バイトで約 21 億文字が扱える仕様でした。

https://datatracker.ietf.org/doc/html/rfc2044

> ```text
>    UCS-4 range (hex.)           UTF-8 octet sequence (binary)
>    0000 0000-0000 007F   0xxxxxxx
>    0000 0080-0000 07FF   110xxxxx 10xxxxxx
>    0000 0800-0000 FFFF   1110xxxx 10xxxxxx 10xxxxxx
> 
>    0001 0000-001F FFFF   11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
>    0020 0000-03FF FFFF   111110xx 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx
>    0400 0000-7FFF FFFF   1111110x 10xxxxxx ... 10xxxxxx
> ```

その後 UTF-16 との整合性から上限が引き下げられて最長 4 バイトとなりました。（名前は UTF-8 のまま）

https://datatracker.ietf.org/doc/html/rfc3629

> ```text
>    Char. number range  |        UTF-8 octet sequence
>       (hexadecimal)    |              (binary)
>    --------------------+---------------------------------------------
>    0000 0000-0000 007F | 0xxxxxxx
>    0000 0080-0000 07FF | 110xxxxx 10xxxxxx
>    0000 0800-0000 FFFF | 1110xxxx 10xxxxxx 10xxxxxx
>    0001 0000-0010 FFFF | 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
> ```

# CESU-8

サロゲートペア導入以前の UCS-2 → UTF-8 変換の実装に UTF-16 を通すと、サロゲートペアは 3 バイトずつの 2 文字として変換されます。一部のデータベースなどでそのような状況が発生しましたが、正式な UTF-8 とは区別して CESU-8 として追認されました。

https://en.wikipedia.org/wiki/CESU-8

<blockquote><table>
<tr><th>Code point</th><td>U+0045</td><td colspan="2">U+0205</td><td colspan="12">U+10400</td></tr>
<tr><th>Character</th><td>E</td><td colspan="2">ȅ</td><td colspan="12">𐐀</td></tr>
<tr><th>UTF-8</th>
<td>45</td>
<td>C8</td><td>85</td>
<td colspan="3">F0</td><td colspan="3">90</td><td colspan="3">90</td><td colspan="3">80</td></tr>
<tr><th>UTF-16</th><td>0045</td><td colspan="2">0205</td><td colspan="6">D801</td><td colspan="6">DC00</td></tr>
<tr><th>CESU-8</th>
<td>45</td>
<td>C8</td><td>85</td>
<td colspan="2">ED</td><td colspan="2">A0</td><td colspan="2">81</td>
<td colspan="2">ED</td><td colspan="2">B0</td><td colspan="2">80</td></tr>
</table></blockquote>

# コード

20 年前のサロゲートペアを考慮しない実装に絵文字などを通してしまったため、期せずして CESU-8 のデータが生成されてしまいました。正当な UTF-8 としては認められずに読み込めないため、取り急ぎ対応するために作成したコードです。

C# の文字列は UTF-16 のため、CESU-8 から UTF-16 への変換を行います。

```cs
public static String FromCESU8(byte[] bytes)
{
    var s = new StringBuilder();
    int len = bytes.Length;
    for (int i = 0; i < len; i++)
    {
        int b1 = bytes[i], b2, b3, b4;
        if (b1 < 0x80) s.Append((char)b1);
        else if ((b1 & 0xe0) == 0xc0 && i + 1 < len &&
                 ((b2 = bytes[i + 1]) & 0xc0) == 0x80)
        {
            // C0-DF | 80-BF
            int ch = (b1 & 0x1f) << 6 | (b2 & 0x3f);
            if (ch < 0x80) s.Append("��"); else s.Append((char)ch);
            i++;
        }
        else if ((b1 & 0xf0) == 0xe0 && i + 2 < len &&
                 ((b2 = bytes[i + 1]) & 0xc0) == 0x80 &&
                 ((b3 = bytes[i + 2]) & 0xc0) == 0x80)
        {
            // E0-EF | 80-BF | 80-BF
            int ch = (b1 & 0xf) << 12 | (b2 & 0x3f) << 6 | (b3 & 0x3f);
            if (ch < 0x800) s.Append("���"); else s.Append((char)ch);
            i += 2;
        }
        else s.Append("�");
    }
    return s.ToString();
}
```

規格外のバイト列を検出したときは、バイト数に応じて � を出力します。

`if (ch < 0x80)` などにより、同じ文字は最短の形式以外は弾きます。

※ 以前はこのチェックを省いた実装があったため、それを悪用して不正な文字列を送り込む攻撃が発生しました。

https://www.slideshare.net/ockeghem/ss-5620584

## 両対応

4 バイト文字を受け付けるようにすれば CESU-8/UTF-8 両対応になります。

※ 本来 CESU-8 としては弾くべきですが、混在した場合は止むを得ません。

```cs
        else if ((b1 & 0xf8) == 0xf0 && i + 3 < len &&
                 ((b2 = bytes[i + 1]) & 0xc0) == 0x80 &&
                 ((b3 = bytes[i + 2]) & 0xc0) == 0x80 &&
                 ((b4 = bytes[i + 3]) & 0xc0) == 0x80)
        {
            // F0-F4 | 80-BF | 80-BF | 80-BF
            int ch = (b1 & 7) << 18 | (b2 & 0x3f) << 12 | (b3 & 0x3f) << 6 | (b4 & 0x3f);
            if (ch < 0x10000 || ch >= 0x110000)
                s.Append("����");
            else
            {
                s.Append((char)(0xd800 + ((ch - 0x10000) >> 10)));
                s.Append((char)(0xdc00 + (ch & 0x3ff)));
            }
            i += 3;
        }
```

※ サロゲートペアに変換しています。

# 関連記事

ビット演算を多用しています。詳細は以下の記事を参照してください。

https://qiita.com/7shi/items/41d262ca11ea16d85abc
