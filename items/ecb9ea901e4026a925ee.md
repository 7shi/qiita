---
coediting: false
comments_count: 0
created_at: '2020-05-16T01:46:40+09:00'
id: ecb9ea901e4026a925ee
likes_count: 2
private: false
reactions_count: 0
stocks_count: 1
tags:
- name: Python
  versions: []
- name: TTS
  versions: []
- name: TextToSpeech
  versions: []
- name: SAPI
  versions: []
title: SAPIで未サポートの言語を喋らせる
updated_at: '2022-10-18T03:04:15+09:00'
url: https://qiita.com/7shi/items/ecb9ea901e4026a925ee
slide: false
---

SAPI で発音を指定して未サポートの言語を喋らせます。そのための音素の扱いなどを説明します。

発音を指定する方法は以下の記事を参照してください。

* [SAPIで発音を指定する](https://qiita.com/7shi/items/51017b4b268f66e11c42)

言語に依存しない発音の指定方法として IPA と UPS が使用できます。今回は ASCII 文字だけで入力できる UPS を使用します。

# 音素

綴りと発音に例外がなく説明に都合が良いため、人工言語のエスペラントを例に取ります。

資料を参照しながら、音素と UPS の対応をまとめます。

* [エスペラントアルファベット - Wikipedia](https://ja.wikipedia.org/wiki/%E3%82%A8%E3%82%B9%E3%83%9A%E3%83%A9%E3%83%B3%E3%83%88%E3%82%A2%E3%83%AB%E3%83%95%E3%82%A1%E3%83%99%E3%83%83%E3%83%88)
* 子音: [Consonants (Microsoft.Speech) | Microsoft Docs](https://docs.microsoft.com/en-us/previous-versions/office/developer/speech-technologies/hh362821(v=office.14))
* 母音: [Vowels (Microsoft.Speech) | Microsoft Docs](https://docs.microsoft.com/en-us/previous-versions/office/developer/speech-technologies/hh378338(v=office.14))

文字|音価|UPS||文字|音価|UPS||文字|音価|UPS
:--:|:--:|:--:|----|:--:|:--:|:--:|----|:--:|:--:|:--:
a|[a]|A||ĥ|[x]|X||r|[r]|R
b|[b]|B||i|[i]|I||s|[s]|S
c|[ts]|TS||j|[j]|J||ŝ|[ʃ]|SH
ĉ|[tʃ]|CH||ĵ|[ʒ]|ZH||t|[t]|T
d|[d]|D||k|[k]|K||u|[u]|U
e|[e]|E||l|[l]|L||ŭ|[w]|W
f|[f]|F||m|[m]|M||v|[v]|V
g|[g]|G||n|[n]|N||z|[z]|Z
ĝ|[dʒ]|JH||o|[o]|O||||
h|[h]|H||p|[p]|P||||

# 音声を探す

音声合成では言語・地域ごとに音声データを持っており、データにない音素は発音できません。

エスペラントのすべての音素が区別される音声を探します。

次の記事に掲載されている wintts.py を参照するため、作業ディレクトリに置きます。

* [PythonでWindows 10の音声合成を使用する](https://qiita.com/7shi/items/a5fb03406e0626b4f138)

人間の耳で聞き分けるのは大変なので、音素ごとにファイルを出力して確認します。ファイルが無音でなく一致しなければ、音素が区別されていると判断します。

```py:chkepo.py
import itertools, sys, wintts
phonemes = "A B TS CH D E F G JH H X I J ZH K L M N O P R S SH T U W V Z".split()
langs  = []
oks    = []
scores = []
wavs   = [None] * len(phonemes)
def isempty(wav):
    return not wav or len(wav) == 46
def write(s):
    sys.stdout.write(s)
    sys.stdout.flush()
for v in wintts.getvoices():
    l = wintts.getlocale(v)
    if l in langs: continue
    langs.append(l)
    write(l + ": ")
    ok = True
    sc = len(phonemes)
    for i, ph in enumerate(phonemes):
        wintts.save(v, wintts.ssml(l, "ups", ph), "tmp.wav")
        with open("tmp.wav", "rb") as f: wavs[i] = f.read()
        if isempty(wavs[i]):
            ok = False
            sc -= 1
            write(ph + " ")
    for a, b in itertools.combinations(range(len(phonemes)), 2):
        if isempty(wavs[a]) or isempty(wavs[b]): continue
        if wavs[a] == wavs[b]:
            write(phonemes[a] + "=" + phonemes[b] + " ")
            wavs[b] = None
            ok = False
            sc -= 1
    scores.append(sc)
    print("[OK!]" if ok else "[NG]", sc, "/", len(phonemes))
    if ok: oks.append(l)
avg = sum(scores) / len(scores)
print("score max: %d," % max(scores), "min: %d," % min(scores), "avg: %0.1f" % avg)
print("[OK]", ", ".join(sorted(oks)))
```
```text:実行結果
ja-JP: B=V E=O F=H F=X JH=ZH L=R [NG] 22 / 28
ar-SA: E G O P R V [NG] 22 / 28
bg-BG: X=K [NG] 27 / 28
（略）
score max: 28, min: 20, avg: 25.3
[OK] sk-SK
```

sk-SK が残りました。スロバキア語です。

```text
$ wintts -l sk
sk-SK, Slovak (Slovakia): Microsoft Filip
```

## 次点の音声

1つの組み合わせで区別が不足して次点になった音声は19あります。

```text
bg-BG: X=K [NG] 27 / 28
ca-ES: H=X [NG] 27 / 28
cs-CZ: W=V [NG] 27 / 28
de-AT: W=V [NG] 27 / 28
de-CH: W=V [NG] 27 / 28
de-DE: W=V [NG] 27 / 28
en-AU: X=K [NG] 27 / 28
en-CA: H=X [NG] 27 / 28
en-GB: X=K [NG] 27 / 28
en-IE: X=K [NG] 27 / 28
en-US: H=X [NG] 27 / 28
hu-HU: W=V [NG] 27 / 28
pl-PL: H=X [NG] 27 / 28
pt-BR: H=R [NG] 27 / 28
ro-RO: X=K [NG] 27 / 28
sl-SI: H=X [NG] 27 / 28
zh-CN: H=X [NG] 27 / 28
zh-HK: H=X [NG] 27 / 28
zh-TW: H=X [NG] 27 / 28
```

H, X や W, V を区別しない音声が多いです。

エスペラントで ĥ はあまり使われないため、ĥ を無視すれば選択肢は増えます。二重母音で au, eu, ou が発音できれば、ほとんどのケースで ŭ も代用できます。もしスロバキア語の選択肢がなければ検討したでしょう。

※ こういった音素は人間が使用する上でも問題だという認識はあり、後で少し触れますが[イド語](#イド語)などの改造につながります。

# アルファベット

実際の発音を確認するため文字の名前を読ませます。母音はそのままで、子音は o を付けて読みます。

【例】a アー、b ボー

<blockquote class="twitter-tweet" data-conversation="none" data-dnt="true"><p lang="und" dir="ltr">La slovaka sukcesis la teston! <a href="https://t.co/l8eQXQsd6h">pic.twitter.com/l8eQXQsd6h</a></p>&mdash; 7shi_conlang (@7shi_conlang) <a href="https://twitter.com/7shi_conlang/status/1261161187711938560?ref_src=twsrc%5Etfw">May 15, 2020</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

↑ `The media could not be played.` となって再生できない場合、ツイートをクリックして Twitter を開いてください。

画像や音声を生成するコードは以下にあります。本題から外れるため詳細は省略します。

* [[py][F#] Esperanta Alfabeto](https://gist.github.com/7shi/3befffaf8ee5afcbc4a5d89074e771a7)

画像や音声から動画を作成する方法については以下の記事を参照してください。

* [紙芝居方式で動画を作成](https://qiita.com/7shi/items/9a4f2220cfde4fbbdce7)

# 単語の変換

エスペラントの文を読ませるには、綴りから UPS に変換する必要があります。

まず単語単位の変換を考えます。

## 音素への置換

1文字1音素のため、単純に置換できます。

```py:ssml_epo.py
phonemes = {}

def setphonemes(phs):
    for ph in phs.split():
        p1, p2 = ph.split(",")
        phonemes[p1] = p2

setphonemes("a,A b,B c,TS ĉ,CH d,D e,E f,F g,G ĝ,JH h,H")
setphonemes("ĥ,X i,I j,J ĵ,ZH k,K l,L m,M n,N o,O p,P")
setphonemes("r,R s,S ŝ,SH t,T u,U ŭ,W v,V z,Z")

def getph(ch):
    return phonemes[ch] if ch in phonemes else ""

def getphoneme(word):
    return [ph for ch in word if (ph := getph(ch))]

if __name__ == "__main__":
    print("# getphoneme")
    for w in ["feliĉa", "ĝis"]:
        print(w, "->", getphoneme(w))
```
```text:実行結果
# getphoneme
feliĉa -> ['F', 'E', 'L', 'I', 'CH', 'A']
ĝis -> ['JH', 'I', 'S']
```

## アクセント規則

Wikipedia から引用します。

* [エスペラント#アクセント](https://ja.wikipedia.org/wiki/%E3%82%A8%E3%82%B9%E3%83%9A%E3%83%A9%E3%83%B3%E3%83%88#%E3%82%A2%E3%82%AF%E3%82%BB%E3%83%B3%E3%83%88)

> 「アクセントは常に最後から2番目の音節にある。」（エスペラントの基礎、文法第10条）

1音節1母音で二重母音は存在しないため、後ろから2番目の母音にアクセントがあります。

> 綺麗に発音するためイタリア語などと同じように、アクセントのある母音を心持ち長めに発音するのが推奨されている（母音の長短そのものは意味の違いをもたらさない）。ただし、最後と最後から2番目の母音の間に子音が2個以上あるときはアクセントのある母音を短く発音し、子音が無いか1個だけのときに長く発音する。これに加えて、最後と最後から2番目の母音の間の複子音の第二要素が l, r のものと kv , dz である場合はアクセントを長く発音するというものもある。

アクセントを扱うにはまず音節に区切る必要があります。開音節（母音で終わる音節）にアクセントがあれば母音を長めに発音します。後続の子音連続が「複子音の第二要素が l, r のものと kv , dz」であれば次の音節に属すため開音節となります。

音節に関する規則は複雑に見えますが、エスペラント特有のものではないため他の言語に応用が利きます。

## 音節に分割

後ろから音素を1つ先読みでパースすれば音節に区切れます。

パーサーを実装します。ほぼイテレーターに先読み（`peek`）機能を付けただけです。

```py:ssml_epo.py（追加）
class Parser:
    def __init__(self, src):
        self.i = iter(src)
        self.cur = None

    def peek(self):
        if self.cur: return self.cur
        try:
            self.cur = next(self.i)
        except StopIteration:
            pass
        return self.cur

    def read(self):
        ret = self.peek()
        self.cur = None
        return ret

    def accept(self):
        if self.cur:
            self.cur = None
            self.peek()
```

パーサーを使って音節に区切ります。母音があれば先読みで前の子音を確認します。その際に特別な組み合わせをチェックします。

```py:ssml_epo.py（追加）
def isconsonant(ph):
    return ph and not ph in "AEIOU"

def syllablize(phs):
    p = Parser(reversed(phs))
    ret = []
    cur = []
    while (ph := p.read()):
        cur.insert(0, ph)
        if isconsonant(ph): continue
        if isconsonant(c1 := p.peek()):
            p.accept()
            cur.insert(0, c1)
            if isconsonant(c2 := p.peek()):
                if c1 in "LR" and c2 != c1:
                    p.accept()
                    cur.insert(0, c2)
                else:
                    cc = c2 + c1
                    if cc in ["KV", "GV", "DZ"]:
                        p.accept()
                        cur.insert(0, c2)
        ret.insert(0, cur)
        cur = []
    if cur:
        if ret:
            ret[0] = cur + ret[0]
        else:
            ret = [cur]
    return ret

if __name__ == "__main__":
    print("# syllablize")
    for w in ["feliĉa", "ĝis", "akvo", "edzo", "lingvo", "patro", "strato"]:
        print(w, "->", syllablize(getphoneme(w)))
```
```text:実行結果
# syllablize
feliĉa -> [['F', 'E'], ['L', 'I'], ['CH', 'A']]
ĝis -> [['JH', 'I', 'S']]
akvo -> [['A'], ['K', 'V', 'O']]
edzo -> [['E'], ['D', 'Z', 'O']]
lingvo -> [['L', 'I', 'N'], ['G', 'V', 'O']]
patro -> [['P', 'A'], ['T', 'R', 'O']]
strato -> [['S', 'T', 'R', 'A'], ['T', 'O']]
```

## アクセントを付与

後ろから2番目の音節にアクセント（`s1`）を振ります。開音節であれば母音を延長（`lng`）します。

```py:ssml_epo.py（追加）
def setaccent(syls):
    if len(syls) >= 2:
        syls[-2] = ["s1"] + syls[-2]
        if not isconsonant(syls[-2][-1]):
            syls[-2].append("lng")
    return syls

if __name__ == "__main__":
    print("# setaccent")
    for w in ["feliĉa", "ĝis", "akvo", "edzo", "lingvo", "patro", "strato"]:
        print(w, "->", setaccent(syllablize(getphoneme(w))))
```
```text:実行結果
# setaccent
feliĉa -> [['F', 'E'], ['s1', 'L', 'I', 'lng'], ['CH', 'A']]
ĝis -> [['JH', 'I', 'S']]
akvo -> [['s1', 'A', 'lng'], ['K', 'V', 'O']]
edzo -> [['s1', 'E', 'lng'], ['D', 'Z', 'O']]
lingvo -> [['s1', 'L', 'I', 'N'], ['G', 'V', 'O']]
patro -> [['s1', 'P', 'A', 'lng'], ['T', 'R', 'O']]
strato -> [['s1', 'S', 'T', 'R', 'A', 'lng'], ['T', 'O']]
```

## 結合

リストを結合して UPS の文字列に変換します。

* 今までの処理を一度に行う関数 `getups` を提供します。
* 大文字を受け付けるため小文字に変換します。
* 入力の便宜のため X-方式 をサポートします。
* スロバキア語音声の癖に対処するため W を U に置換します。

```py:ssml_epo.py（追加）
def combine(syls):
    return " . ".join(map(" ".join, syls))

xsis = [pair.split(",") for pair in "cx,ĉ gx,ĝ hx,ĥ jx,ĵ sx,ŝ ux,ŭ".split()]

def getups(word):
    word = word.lower()
    for a, b in xsis:
        word = word.replace(a, b)
    return combine(setaccent(syllablize(getphoneme(word)))).replace("W", "U")

if __name__ == "__main__":
    print("# getups")
    for w in ["Felicxa", "Gxis", "akvo", "lingvo", "patro", "strato", "hodiaux"]:
        print(w, "->", getups(w))
```
```text:実行結果
# getups
Felicxa -> F E . s1 L I lng . CH A
Gxis -> JH I S
akvo -> s1 A lng . K V O
lingvo -> s1 L I N . G V O
patro -> s1 P A lng . T R O
strato -> s1 S T R A lng . T O
hodiaux -> H O . s1 D I lng . A U
```

# 文章の変換

文章から単語を抜き出してタグで発音を付けます。単語の抜き出しには先ほど作ったパーサーが使えます。

```py:ssml_epo.py（追加）
def readtoken(p):
    ch = p.peek()
    if not ch: return None
    ret = ""
    while (ch := p.peek()) and str.isalpha(ch):
        p.accept()
        ret += ch
    if ret: return (True, ret)
    while (ch := p.peek()) and not str.isalpha(ch):
        p.accept()
        ret += ch
    return (False, ret)

ssmlhdr = """
<?xml version="1.0" encoding="UTF-8"?>
<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="sk-SK">
""".lstrip()

def getssml(text):
    ssml = ssmlhdr
    p = Parser(text)
    while (t := readtoken(p)):
        alpha, token = t
        if alpha:
            ssml += '<phoneme alphabet="ups" ph="%s">%s</phoneme>' % (getups(token), token)
        else:
            ssml += token
    if not ssml.endswith("\n"): ssml += "\n"
    return ssml + '</speak>'

if __name__ == "__main__":
    print("# getssml")
    text = "Mi estas tre ĝoja konatiĝi kun vi."
    print(text)
    print("-" * 32)
    print(getssml(text))
```
```text:実行結果
# getssml
Mi estas tre ĝoja konatiĝi kun vi.
--------------------------------
<?xml version="1.0" encoding="UTF-8"?>
<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="sk-SK">
<phoneme alphabet="ups" ph="M I">Mi</phoneme> <phoneme alphabet="ups" ph="s1 E S . T A S">estas</phoneme> <phoneme alphabet="ups" ph="T R E">tre</phoneme> <phoneme alphabet="ups" ph="s1 JH O lng . J A">ĝoja</phoneme> <phoneme alphabet="ups" ph="K O . N A . s1 T I lng . JH I">konatiĝi</phoneme> <phoneme alphabet="ups" ph="K U N">kun</phoneme> <phoneme alphabet="ups" ph="V I">vi</phoneme>.
</speak>
```

# コマンド化

簡単に利用できるようにコマンド化します。

テストコードは残したまま無効にします。

* 置換: `if __name__ == "__main__":` → `if False:`

```py:ssml_epo.py（追加）
import getopt, sys

options = "f:"
def usage():
    print("usage: %s -f file | text ..." % sys.argv[0])
    exit(1)

if __name__ == "__main__":
    text = None
    try:
        opts, args = getopt.getopt(sys.argv[1:], options)
    except getopt.GetoptError as e:
        print(e)
        usage()
    for opt, optarg in opts:
        if opt == "-f":
            with open(optarg, encoding="utf-8") as f:
                text = f.read()
    if not text: text = " ".join(args)
    if not text: usage()

    print(getssml(text))
```

ここまでのコード全体をアップしました。

* [[py] SSML converter for Esperanto](https://gist.github.com/7shi/92794319bebef470dd71e68d4e3e599d)

## 使用例

引数でテキストを渡して SSML に変換します。

```text
$ python ssml_epo.py "Mi estas tre ĝoja konatiĝi kun vi."
<?xml version="1.0" encoding="UTF-8"?>
<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="sk-SK">
<phoneme alphabet="ups" ph="M I">Mi</phoneme> <phoneme alphabet="ups" ph="s1 E S . T A S">estas</phoneme> <phoneme alphabet="ups" ph="T R E">tre</phoneme> <phoneme alphabet="ups" ph="s1 JH O lng . J A">ĝoja</phoneme> <phoneme alphabet="ups" ph="K O . N A . s1 T I lng . JH I">konatiĝi</phoneme> <phoneme alphabet="ups" ph="K U N">kun</phoneme> <phoneme alphabet="ups" ph="V I">vi</phoneme>.
</speak>
```

結果を wintts に渡して読み上げます。

```text
wintts -v filip `python ssml_epo.py "Mi estas tre gxoja konatigxi kun vi."`
```

これを使って『主の祈り』を読み上げました。

※ 特に宗教的な意図はありません。有名で分量も手頃なことから、人工言語への翻訳で定番になっているものです。

<blockquote class="twitter-tweet" data-conversation="none" data-dnt="true"><p lang="lt" dir="ltr">Patro Nia (Esperanto per la voĉsintezilo)<br><br>Mi skribis konvertilo.<a href="https://t.co/MEso23LQbd">https://t.co/MEso23LQbd</a> <a href="https://t.co/fQU7sLbRGh">pic.twitter.com/fQU7sLbRGh</a></p>&mdash; 7shi_conlang (@7shi_conlang) <a href="https://twitter.com/7shi_conlang/status/1261328960744349696?ref_src=twsrc%5Etfw">May 15, 2020</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

↑ `The media could not be played.` となって再生できない場合、ツイートをクリックして Twitter を開いてください。

割と素直に読み上げています。自動で音素比較をしなければスロバキア語は見落としたことでしょう。

# イド語

最後に少しだけ言語改造の話題に触れます。

エスペラントを改造して後継言語となることを目指した人工言語があります。代表的なのがイド語です。

※ ido はエスペラントで「子供」を意味します。イド語を含むエスペラントの派生言語はまとめて Esperantido と呼ばれます。

* [Esperantido - Wikipedia](https://en.wikipedia.org/wiki/Esperantido)

エスペラントは子音が多く、すべてをカバーする音声を見付けるのが大変でした。イド語では発音が難しい子音や字上符付き文字が廃止されています。

* [イド語 - Wikipedia](https://ja.wikipedia.org/wiki/%E3%82%A4%E3%83%89%E8%AA%9E)

> エスペラント特有のĉ,ĵ,ŝ,ŭはそれぞれch,j,sh,wに変更され、ĥは廃止、ĝは単語によって別な文字に変更された。

ĥ と ĝ を取り除いてカバーする音声を探します。chkepo.py をコピーして chkido.py を作り、`phonemes` を変更します。

```py:chkido.py（変更）
phonemes = "A B TS CH D E F G H I J ZH K L M N O P R S SH T U W V Z".split()
```
```text:実行結果
ja-JP: B=V E=O F=H L=R [NG] 22 / 26
ar-SA: E G O P R V [NG] 20 / 26
bg-BG: [OK!] 26 / 26
（略）
score max: 26, min: 19, avg: 24.1
[OK] bg-BG, ca-ES, en-AU, en-CA, en-GB, en-IE, en-US, pl-PL, ro-RO, sk-SK, sl-SI, zh-CN, zh-HK, zh-TW
```

かなり選択肢が増えました。しかし読み上げには音素だけでなくイントネーションの影響もあるため、実際に読み上げて聞き取りやすい音声を選ぶ必要があります。

※ 主観で評価（左側が良好）: sk, ro > ca > sl > bg, pl > en, zh

イド語は二重母音を導入したため、音節の分け方に影響があります。

> また、アクセントは原則エスペラント同様最後から二番目の母音にあるが、その母音が二重母音である場合は最後から三番目の母音にアクセントがある<sup>[6]</sup>。言い換えれば、イド語のアクセントは基本的に最後から二番目の音節にある<sup>[7]</sup>。ただし、動詞の不定詞は明確に話すため最後にアクセントがおかれる<sup>[7]</sup>。

これらの変更を反映したイド語版の SSML 変換スクリプトです。

* [[py] SSML converter for Ido](https://gist.github.com/7shi/49fca97c08eb06edb6bed423502c784e)

同様にして作成した他の人工言語版の SSML 変換スクリプトです。

* [[py] SSML converter for Interlingue/Occidental](https://gist.github.com/7shi/adb49f584096d2c68d7839dd5a6f4fe7)
* [[py] SSML converter for Novial](https://gist.github.com/7shi/94d7b36ed8295939ca877ac9b82dae80)

改造して新しい言語が出て来るのは、ある意味でプログラミング言語の世界と似ている気がします。

# 関連記事

現時点では Web Speech API で SSML がサポートされていないため、スロバキア語風に綴りを変換して読ませる必要があります。

* [Speak Esperanto (Convert)](https://codepen.io/7shi/pen/gOeGGXg)
* [Speak Ido (Convert)](https://codepen.io/7shi/pen/JjvVyBM)

Web Speech API で様々な人工言語を読み上げる例です。

* [音声合成による人工言語の読み上げ - 七誌の開発日記](https://7shi.hateblo.jp/entry/2020/01/27/025436)

Parol という AWS を使ったエスペラントの音声合成システムがあります。こちらはポーランド語風に綴りを変換する方式です。

* [Parol – La Voĉroboto](https://parol.martinrue.com/)
* [martinrue/vocx: A library for transcribing Esperanto text into phonetic Polish for use in TTS engines](https://github.com/martinrue/vocx)

変換に使う vocx というライブラリを試すために Go を調べる記事です。

* [いきなりGoを使うのに試したこと](https://qiita.com/7shi/items/5e8d87c14ba057039518)
