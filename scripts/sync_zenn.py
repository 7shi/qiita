"""ZENN.tsv の対応表に従って、Qiita 側と Zenn 側の記事本文を同期する。

フロントマターはそれぞれの形式のまま保持し、本文（フロントマター以降）だけを比較する。
差分があれば更新日時（mtime）が新しい方を正として、古い方の本文を上書きする。
Qiita 側を書き換えたときは updated_at を空にする（CLAUDE.md のルール）。
"""

import argparse
import csv
import re
import sys
from pathlib import Path

QIITA_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_ZENN_ROOT = Path.home() / "repos" / "zenn"
LIST_TSV = QIITA_ROOT / "ZENN.tsv"


def split_frontmatter(text: str) -> tuple[str, str]:
    if not text.startswith("---\n"):
        raise ValueError("フロントマターが見つかりません")
    end = text.index("\n---\n", 4)
    return text[: end + 5], text[end + 5 :]


def clear_updated_at(front: str) -> str:
    return re.sub(r"^updated_at:.*$", "updated_at: ''", front, count=1, flags=re.MULTILINE)


def load_pairs(zenn_root: Path) -> list[tuple[Path, Path]]:
    with open(LIST_TSV, encoding="utf-8", newline="") as f:
        reader = csv.reader(f, delimiter="\t")
        header = next(reader)
        if header[:2] != ["qiita", "zenn"]:
            raise ValueError(f"{LIST_TSV} のヘッダが不正です: {header}")
        return [(QIITA_ROOT / row[0], zenn_root / row[1]) for row in reader if row]


def sync(qiita_path: Path, zenn_path: Path, dry_run: bool) -> bool:
    """本文が異なれば新しい方に合わせる。更新したら True を返す。"""
    missing = [p for p in (qiita_path, zenn_path) if not p.exists()]
    if missing:
        for p in missing:
            print(f"ファイルがありません: {p}", file=sys.stderr)
        return False

    qiita_text = qiita_path.read_text(encoding="utf-8")
    zenn_text = zenn_path.read_text(encoding="utf-8")
    qiita_front, qiita_body = split_frontmatter(qiita_text)
    zenn_front, zenn_body = split_frontmatter(zenn_text)

    if qiita_body == zenn_body:
        print(f"同期済み: {qiita_path.name}")
        return False

    if qiita_path.stat().st_mtime >= zenn_path.stat().st_mtime:
        src, dest, new_text = qiita_path, zenn_path, zenn_front + qiita_body
    else:
        src, dest = zenn_path, qiita_path
        new_text = clear_updated_at(qiita_front) + zenn_body

    print(f"更新: {dest} ← {src}")
    if not dry_run:
        dest.write_text(new_text, encoding="utf-8")
    return True


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--zenn-root", type=Path, default=DEFAULT_ZENN_ROOT,
                        help=f"Zenn リポジトリのパス (default: {DEFAULT_ZENN_ROOT})")
    parser.add_argument("-n", "--dry-run", action="store_true", help="実際には書き換えない")
    args = parser.parse_args()

    updated = 0
    for qiita_path, zenn_path in load_pairs(args.zenn_root):
        if sync(qiita_path, zenn_path, args.dry_run):
            updated += 1
    print(f"{updated} 件更新しました" + ("（dry-run）" if args.dry_run else ""))


if __name__ == "__main__":
    main()
