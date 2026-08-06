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
4. ASCII の英数字・`-`・`_` 以外（＝日本語などの非 ASCII 文字）を UTF-8 の
   パーセントエンコーディング（16進は大文字）に変換する。
   - `束縛` → `%E6%9D%9F%E7%B8%9B`
5. 同一文書内で同じアンカーが重複したら、2つ目以降に `-1`・`-2`… と連番を付ける。
   連番は「そのアンカーが何度目に現れたか」で決まる。
   - `練習` が5回現れる → `練習`, `練習-1`, `練習-2`, `練習-3`, `練習-4`
   - 記号だけの見出しは 2 の段階で空文字列になるため、`$`・`!!`・`++`・`:` は
     順に ``, `-1`, `-2`, `-3` という空文字列同士の重複扱いになる。

## 使い方

    from anchor import anchor, anchors_of_markdown

    anchor("束縛")            # -> '%E6%9D%9F%E7%B8%9B'
    anchors_of_markdown(text) # -> [(レベル, 見出し, アンカー), ...]

単体で実行すると `anchor-sample.md` の実例と照合して、規則が再現できているか検証する。

    uv run scripts/anchor.py
"""

import re
import sys
import unicodedata
from pathlib import Path
from urllib.parse import quote

QIITA_ROOT = Path(__file__).resolve().parent.parent
SAMPLE = QIITA_ROOT / "anchor-sample.md"

# アンカーに残す文字のカテゴリ（文字・結合文字・数字）
_KEEP_CATEGORIES = ("L", "M", "N")
# パーセントエンコードせずに残す ASCII 文字
_SAFE = "-_"


def slugify(text: str) -> str:
    """見出しテキストを連番なしのアンカーへ変換する（規則 1〜4）。"""
    lowered = text.lower()
    kept = [
        ch
        for ch in lowered
        if unicodedata.category(ch)[0] in _KEEP_CATEGORIES or ch in _SAFE or ch.isspace()
    ]
    hyphenated = re.sub(r"\s", "-", "".join(kept))
    return quote(hyphenated, safe=_SAFE)


class AnchorGenerator:
    """1つの文書の中で重複した見出しに連番を振りながらアンカーを生成する。"""

    def __init__(self) -> None:
        self.counts: dict[str, int] = {}

    def __call__(self, text: str) -> str:
        base = slugify(text)
        n = self.counts.get(base, 0)
        self.counts[base] = n + 1
        return base if n == 0 else f"{base}-{n}"


def anchor(text: str) -> str:
    """単独の見出しテキストをアンカーへ変換する（重複の連番は考慮しない）。"""
    return slugify(text)


def anchors_of_markdown(text: str) -> list[tuple[int, str, str]]:
    """Markdown 本文から (見出しレベル, 見出しテキスト, アンカー) の一覧を作る。

    フロントマターとフェンスドコードブロックの中は見出しとして扱わない。
    """
    body = text
    if body.startswith("---\n"):
        end = body.find("\n---\n", 4)
        if end >= 0:
            body = body[end + 5 :]

    gen = AnchorGenerator()
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
    ok = True
    for platform, path, expected in load_samples():
        actual = [a for _, _, a in anchors_of_markdown(path.read_text(encoding="utf-8"))]
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
