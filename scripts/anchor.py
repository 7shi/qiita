"""見出しテキストから Qiita・Zenn のアンカー（`#` 以降の断片）を生成する。

記事の特定の節へリンクするとき、`URL#見出し` のアンカーをどう書くかの変換規則を
実装したモジュール。実際に生成されたアンカー（anchor-sample.md に採取した
Qiita・Zenn 双方の目次）から規則を割り出した。

## 変換規則

Qiita と Zenn は**同一の規則**だった（どちらも GitHub 系の slug 生成に準ずる）。
見出しテキストに対して次の順に適用する。

1. 小文字化する（ASCII 以外はそのまま）。
   - `Num` → `num` / `Semigroup と Monoid` → `semigroup-と-monoid`
2. 文字・数字（Unicode の L*・M*・N* カテゴリ）と `-`・`_`・空白だけを残し、
   他の記号・約物はすべて削除する。ASCII 記号だけでなく `・`（U+30FB）のような
   全角の約物も削除される。
   - `基底部・再帰部` → `基底部再帰部`
   - `` `=` の位置 `` → ` の位置`（バッククォートと `=` が消え、先頭に空白が残る）
   - `$` → 空文字列
3. 空白を `-` に置き換える。元から含まれる `-` は残るため連続することがある。
   - `if - then - else` → `if---then---else`
   - ` の位置` → `-の位置`
4. 同一文書内で同じアンカーが重複したら、2つ目以降に `-1`・`-2`… と連番を付ける。
   連番は「そのアンカーが何度目に現れたか」で決まる。
   - `練習` が5回現れる → `練習`, `練習-1`, `練習-2`, `練習-3`, `練習-4`
   - 記号だけの見出しは 2 の段階で空文字列になるため、`$`・`!!`・`++`・`:` は
     順に ``, `-1`, `-2`, `-3` という空文字列同士の重複扱いになる。

## パーセントエンコーディング

日本語などの非 ASCII 文字は、UTF-8 のパーセントエンコーディング（16進は大文字）へ
変換した形でも書ける（`束縛` と `%E6%9D%9F%E7%B8%9B` は等価）。ブラウザがフラグメントを
照合するときにデコードするため、Qiita・Zenn ともどちらの表記でもリンクは機能する。
Qiita・Zenn が自動生成する目次はエンコードした形になっている。

このモジュールは**エンコードしない形を既定**とし、`encode=True`（コマンドでは
`--encode`）でエンコードした形を得る。相互変換は `encode_anchor`・`decode_anchor`。

## 使い方

    from anchor import anchor, anchors_of_markdown, encode_anchor, decode_anchor

    anchor("束縛")                     # -> '束縛'
    anchor("束縛", encode=True)        # -> '%E6%9D%9F%E7%B8%9B'
    encode_anchor("束縛")              # -> '%E6%9D%9F%E7%B8%9B'
    decode_anchor("%E6%9D%9F%E7%B8%9B")  # -> '束縛'
    anchors_of_markdown(text)          # -> [(レベル, 見出し, アンカー), ...]

コマンドとして実行すると、引数の見出しテキストをアンカーへ変換して表示する。

    uv run scripts/anchor.py 束縛
    # -> 束縛
    uv run scripts/anchor.py --encode 束縛
    # -> %E6%9D%9F%E7%B8%9B

`--test` を付けると、`anchor-sample.md` の実例と照合して規則が再現できているか検証する。

    uv run scripts/anchor.py --test
"""

import argparse
import re
import sys
import unicodedata
from pathlib import Path
from urllib.parse import quote, unquote

QIITA_ROOT = Path(__file__).resolve().parent.parent
SAMPLE = QIITA_ROOT / "anchor-sample.md"

# アンカーに残す文字のカテゴリ（文字・結合文字・数字）
_KEEP_CATEGORIES = ("L", "M", "N")
# パーセントエンコードせずに残す ASCII 文字
_SAFE = "-_"


def encode_anchor(anchor: str) -> str:
    """アンカーをパーセントエンコードした形へ変換する（すでにその形なら変わらない）。"""
    return quote(unquote(anchor), safe=_SAFE)


def decode_anchor(anchor: str) -> str:
    """アンカーをパーセントエンコードしない形へ変換する（すでにその形なら変わらない）。"""
    return unquote(anchor)


def slugify(text: str, encode: bool = False) -> str:
    """見出しテキストを連番なしのアンカーへ変換する（規則 1〜3）。"""
    lowered = text.lower()
    kept = [
        ch
        for ch in lowered
        if unicodedata.category(ch)[0] in _KEEP_CATEGORIES or ch in _SAFE or ch.isspace()
    ]
    hyphenated = re.sub(r"\s", "-", "".join(kept))
    return encode_anchor(hyphenated) if encode else hyphenated


class AnchorGenerator:
    """1つの文書の中で重複した見出しに連番を振りながらアンカーを生成する。"""

    def __init__(self, encode: bool = False) -> None:
        self.encode = encode
        self.counts: dict[str, int] = {}

    def __call__(self, text: str) -> str:
        base = slugify(text, self.encode)
        n = self.counts.get(base, 0)
        self.counts[base] = n + 1
        return base if n == 0 else f"{base}-{n}"


def anchor(text: str, encode: bool = False) -> str:
    """単独の見出しテキストをアンカーへ変換する（重複の連番は考慮しない）。"""
    return slugify(text, encode)


def anchors_of_markdown(text: str, encode: bool = False) -> list[tuple[int, str, str]]:
    """Markdown 本文から (見出しレベル, 見出しテキスト, アンカー) の一覧を作る。

    フロントマターとフェンスドコードブロックの中は見出しとして扱わない。
    """
    body = text
    if body.startswith("---\n"):
        end = body.find("\n---\n", 4)
        if end >= 0:
            body = body[end + 5 :]

    gen = AnchorGenerator(encode)
    result = []
    fence = None
    for line in body.splitlines():
        m = re.match(r"^(```+|~~~+)", line)
        if m:
            if fence is None:
                fence = m.group(1)[0]
            elif m.group(1)[0] == fence:
                fence = None
            continue
        if fence is not None:
            continue
        m = re.match(r"^(#{1,6})\s+(.*?)\s*#*$", line)
        if m:
            heading = m.group(2)
            result.append((len(m.group(1)), heading, gen(heading)))
    return result


def load_samples() -> list[tuple[str, Path, list[str]]]:
    """anchor-sample.md を読んで (プラットフォーム名, 記事のパス, アンカー一覧) を返す。

    `# Qiita` などの見出しごとに、対象記事のパスを書いた行と、実際に生成された
    目次のリストが続く形式になっている。
    """
    samples = []
    platform = path = None
    anchors: list[str] = []
    for line in SAMPLE.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if m := re.match(r"^#\s+(.*)$", line):
            if path:
                samples.append((platform, path, anchors))
            platform, path, anchors = m.group(1), None, []
        elif m := re.match(r"^-\s+\[.*\]\(#(.*)\)$", line):
            anchors.append(m.group(1))
        elif line and platform and not path:
            path = QIITA_ROOT / (line if line.endswith(".md") else line + ".md")
    if path:
        samples.append((platform, path, anchors))
    return samples


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--test", action="store_true", help="anchor-sample.md との照合を検証する")
    parser.add_argument(
        "-e", "--encode", action="store_true", help="パーセントエンコードした形で出力する"
    )
    parser.add_argument("headings", nargs="*", help="アンカーへ変換する見出しテキスト")
    args = parser.parse_args()

    if not args.test:
        for text in args.headings:
            print(anchor(text, args.encode))
        return

    # 実例（目次）はエンコードした形なので、そちらへ揃えて照合する。
    ok = True
    for platform, path, expected in load_samples():
        expected = [encode_anchor(a) for a in expected]
        actual = [a for _, _, a in anchors_of_markdown(path.read_text(encoding="utf-8"), True)]
        rel = path.relative_to(QIITA_ROOT)
        if actual == expected:
            print(f"OK   {platform}: {rel} ({len(expected)} 個一致)")
            continue
        ok = False
        print(f"NG   {platform}: {rel}")
        for i in range(max(len(actual), len(expected))):
            a = actual[i] if i < len(actual) else "(なし)"
            e = expected[i] if i < len(expected) else "(なし)"
            if a != e:
                print(f"       期待: {e}\n       実際: {a}")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
