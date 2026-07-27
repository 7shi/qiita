"""
series.jsonl から series.md を生成するスクリプト

series.jsonl はLLMによる抽出結果（下書き）で、以下の問題を含む:
  - 同じ記事が複数グループに現れる（目次記事へのリンクが1本だけのグループなど）
  - member_ids の順序が本文中のリンク出現順であり、連載順とは限らない

そのためグループのマージや並べ替えは自動では行わず、原形のまま整形して出力する。
生成後の series.md を人手で修正し、以後は series.md を正データとする想定。

出力仕様:
  ## {slug}: {タイトル}          シリーズ（slugは起点記事のslug）
  1. [{title}]({path}) `{id}`    所属記事。番号順が連載順（将来の 01-, 02- に対応）
  マーク: ^root   抽出元記事（本文冒頭に他記事へのリンクを列挙していた記事）。
                  連載順とは無関係で、続編が前作にリンクしている場合は末尾に来る。
          ^dup    複数のシリーズに登場する記事（要手動確認）
          ^missing articles/ に存在しない記事（削除/限定公開）
"""

import argparse
import csv
import json
from collections import Counter
from pathlib import Path


def parse_args():
    parser = argparse.ArgumentParser(description="Build series.md from series.jsonl.")
    parser.add_argument("-i", "--input", default="series.jsonl", help="Input JSONL file (default: series.jsonl)")
    parser.add_argument("-a", "--articles", default="articles.tsv", help="Article index TSV (default: articles.tsv)")
    parser.add_argument("-o", "--output", default="series.md", help="Output Markdown file (default: series.md)")
    return parser.parse_args()


def load_articles(path: Path) -> dict[str, dict[str, str]]:
    with open(path, encoding="utf-8") as f:
        return {row["id"]: row for row in csv.DictReader(f, delimiter="\t")}


def load_groups(path: Path) -> list[dict]:
    groups = []
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            data = json.loads(line)
            if data.get("member_ids"):
                groups.append(data)
    return groups


def format_entry(article_id: str, articles: dict, marks: list[str]) -> str:
    article = articles.get(article_id)
    if article:
        path = f"articles/{article['category']}/{article['slug']}.md"
        body = f"[{article['title']}]({path}) `{article_id}`"
    else:
        body = f"(unknown) `{article_id}`"
        marks = marks + ["^missing"]
    return body + "".join(f" {m}" for m in marks)


def main():
    args = parse_args()
    repo_root = Path(__file__).resolve().parent.parent

    articles = load_articles(repo_root / args.articles)
    groups = load_groups(repo_root / args.input)

    counts = Counter(mid for g in groups for mid in g["member_ids"])

    def sort_key(group):
        article = articles.get(group["root_id"])
        return (article["category"], article["slug"]) if article else ("~", group["root_id"])

    lines = [
        "# シリーズ",
        "",
        "<!-- scripts/build_series.py で series.jsonl から生成した下書き。手動修正後は本ファイルを正データとする。 -->",
        "<!-- ^root: 抽出元記事（本文にリンク一覧があった記事。連載順とは無関係） -->",
        "<!-- ^dup: 複数シリーズに重複（要確認） / ^missing: articles/ に存在しない記事 -->",
        "",
    ]

    for group in sorted(groups, key=sort_key):
        root_id = group["root_id"]
        root = articles.get(root_id)
        slug = root["slug"] if root else root_id
        title = root["title"] if root else root_id
        lines.append(f"## {slug}: {title}")
        lines.append("")
        for i, member_id in enumerate(group["member_ids"], 1):
            marks = []
            if member_id == root_id:
                marks.append("^root")
            if counts[member_id] > 1:
                marks.append("^dup")
            lines.append(f"{i}. {format_entry(member_id, articles, marks)}")
        lines.append("")

    output_path = repo_root / args.output
    with open(output_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))

    dup_ids = [i for i, c in counts.items() if c > 1]
    missing_ids = [i for i in counts if i not in articles]
    print(f"Wrote {len(groups)} series to {output_path.name}.")
    print(f"  articles: {len(counts)} (duplicated: {len(dup_ids)}, missing: {len(missing_ids)})")


if __name__ == "__main__":
    main()
