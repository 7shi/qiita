"""ANCHOR.md の仮リンク `👉[](NN#見出し)` を実 URL に変換する。

対象: series/haskell-intro/ の 01〜15 回。詳細な変換規則は ANCHOR.md を参照。

    uv run replace_anchors.py          # 変換して書き換える
    uv run replace_anchors.py --dry-run  # 変換結果を表示するだけ
"""

import argparse
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent / "scripts"))
from anchor import anchors_of_markdown, anchor as to_anchor  # noqa: E402

REPO_ROOT = Path(__file__).resolve().parent
SERIES_DIR = REPO_ROOT / "series" / "haskell-intro"

# 13〜15 回は Qiita に投稿しないため URL を個別指定する。
ZENN_URLS = {
    "13": "https://zenn.dev/7shi/articles/20260803-haskell-continuation-monad",
    "14": "https://zenn.dev/7shi/articles/20260805-haskell-type-classes",
    "15": "https://zenn.dev/7shi/articles/20260807-haskell-monads-and-friends",
}

# 「Haskell (.*) 超入門」に一致しない回の省略タイトルを個別指定する。
TITLE_OVERRIDES = {
    "01": "超入門",
    "15": "モナドとゆかいな仲間たち",
}

# 同一記事内に同名見出しが複数あり自動判定できない場合の、使う見出しの索引(0-始まり)。
# 11回の「Eitherモナド」は導入節(# Eitherモナド)と書き換え例の小見出し
# (### Eitherモナド)の2箇所にあるが、参照元(09回・12回)はどちらも
# 導入節(1件目)を指しているため0を指定する。
HEADING_OVERRIDES = {
    ("11", "Eitherモナド"): 0,
}

TITLE_RE = re.compile(r"^Haskell (.*) 超入門$")

LINK_RE = re.compile(r"👉\[\]\((\d{2})#([^)]*)\)")


def split_frontmatter(text: str) -> tuple[str, str]:
    if not text.startswith("---\n"):
        raise ValueError("フロントマターが見つかりません")
    end = text.index("\n---\n", 4)
    return text[4:end], text[end + 5:]


def find_episode_file(nn: str) -> Path:
    candidates = [p for p in SERIES_DIR.glob(f"{nn}-*.md") if "-PLAN" not in p.stem]
    if len(candidates) != 1:
        raise ValueError(f"{nn}: 対象ファイルが一意に決まりません: {candidates}")
    return candidates[0]


class Episode:
    def __init__(self, nn: str):
        self.nn = nn
        self.path = find_episode_file(nn)
        text = self.path.read_text(encoding="utf-8")
        front, body = split_frontmatter(text)
        import yaml

        fm = yaml.safe_load(front)
        self.title = fm.get("title", "")
        self.id = fm.get("id", "")
        self.body = body
        self._headings = anchors_of_markdown(text)

    @property
    def short_title(self) -> str:
        if self.nn in TITLE_OVERRIDES:
            return TITLE_OVERRIDES[self.nn]
        m = TITLE_RE.match(self.title)
        if not m:
            raise ValueError(f"{self.nn}: タイトルが正規表現に一致しません: {self.title!r}")
        return m.group(1)

    @property
    def url(self) -> str:
        if self.nn in ZENN_URLS:
            return ZENN_URLS[self.nn]
        if not self.id:
            raise ValueError(f"{self.nn}: id が空です(Qiita 未投稿?)")
        return f"https://qiita.com/7shi/items/{self.id}"

    def anchor_for_heading(self, heading: str) -> str:
        matches = [a for _, h, a in self._headings if h == heading]
        if not matches:
            raise ValueError(f"{self.nn}: 見出しが見つかりません: {heading!r}")
        if len(matches) > 1:
            idx = HEADING_OVERRIDES.get((self.nn, heading))
            if idx is None:
                raise ValueError(
                    f"{self.nn}: 見出しが重複しています({len(matches)}件): {heading!r} "
                    f"-> HEADING_OVERRIDES に索引を指定してください: {matches}"
                )
            return matches[idx]
        return matches[0]


def load_episodes() -> dict[str, Episode]:
    return {f"{n:02d}": Episode(f"{n:02d}") for n in range(1, 16)}


def replace_file(path: Path, episodes: dict[str, Episode]) -> tuple[str, int]:
    text = path.read_text(encoding="utf-8")
    count = 0

    def repl(m: re.Match) -> str:
        nonlocal count
        nn, heading = m.group(1), m.group(2)
        ep = episodes[nn]
        frag = ep.anchor_for_heading(heading)
        count += 1
        return f"👉[{ep.short_title}]({ep.url}#{frag})"

    new_text = LINK_RE.sub(repl, text)
    return new_text, count


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dry-run", action="store_true", help="書き換えず変換結果を表示するだけ")
    args = parser.parse_args()

    episodes = load_episodes()

    total = 0
    for n in range(1, 16):
        nn = f"{n:02d}"
        path = episodes[nn].path
        new_text, count = replace_file(path, episodes)
        if count == 0:
            continue
        total += count
        if args.dry_run:
            print(f"{path.relative_to(REPO_ROOT)}: {count} 件変換")
        else:
            path.write_text(new_text, encoding="utf-8")
            print(f"{path.relative_to(REPO_ROOT)}: {count} 件変換して書き込み")

    print(f"合計 {total} 件")


if __name__ == "__main__":
    main()
