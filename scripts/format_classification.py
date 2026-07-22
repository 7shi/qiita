import argparse
import csv
import glob
import os
import sys
import yaml


def load_id_to_title(items_dir: str) -> dict[str, str]:
    """すべての items/{id}.md から title を読み取り id -> title のハッシュテーブルを作成する"""
    id_to_title = {}
    pattern = os.path.join(items_dir, "*.md")
    for filepath in glob.glob(pattern):
        item_id = os.path.splitext(os.path.basename(filepath))[0]
        try:
            with open(filepath, "r", encoding="utf-8") as f:
                content = f.read()
            if content.startswith("---"):
                parts = content.split("---", 2)
                if len(parts) >= 3:
                    data = yaml.safe_load(parts[1])
                    if isinstance(data, dict) and "title" in data:
                        id_to_title[item_id] = str(data["title"])
        except Exception as e:
            print(f"Warning: Failed to read {filepath}: {e}", file=sys.stderr)
    return id_to_title


def main() -> None:
    # スクリプトの位置からリポジトリルートを特定
    script_dir = os.path.dirname(os.path.abspath(__file__))
    repo_root = os.path.dirname(script_dir)

    default_items_dir = os.path.join(repo_root, "items")
    default_tsv = os.path.join(repo_root, "classification.tsv")
    default_output = os.path.join(repo_root, "classified_titles.tsv")

    parser = argparse.ArgumentParser(
        description="Extract titles from items/*.md and join with classification.tsv"
    )
    parser.add_argument(
        "-o",
        "--output",
        default=default_output,
        help=f"Output TSV file path (default: {default_output}). Use '-' for stdout.",
    )
    args = parser.parse_args()

    if not os.path.exists(default_items_dir):
        print(f"Error: Directory not found: {default_items_dir}", file=sys.stderr)
        sys.exit(1)

    if not os.path.exists(default_tsv):
        print(f"Error: File not found: {default_tsv}", file=sys.stderr)
        sys.exit(1)

    # 1. すべての items/{id}.md から title を読み取って id -> title のハッシュテーブルを作成
    id_to_title = load_id_to_title(default_items_dir)

    # 2. classification.tsv を読み込んで id, proposed_path, title のリストを作成
    rows = []
    with open(default_tsv, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f, delimiter="\t")
        for row in reader:
            item_id = row.get("id", "")
            proposed_path = row.get("proposed_path", "")
            title = id_to_title.get(item_id, "")
            rows.append((item_id, proposed_path, title))

    # proposed_path でソート
    rows.sort(key=lambda x: x[1])

    # TSV を出力
    if args.output == "-":
        out_f = sys.stdout
    else:
        out_f = open(args.output, "w", encoding="utf-8", newline="")

    try:
        writer = csv.writer(out_f, delimiter="\t", lineterminator="\n")
        writer.writerow(["id", "proposed_path", "title"])
        for r in rows:
            writer.writerow(r)
        if args.output != "-":
            out_f.close()
            print(f"Output written to {args.output}", file=sys.stderr)
    except (BrokenPipeError, KeyboardInterrupt):
        sys.stderr.close()
        sys.exit(0)


if __name__ == "__main__":
    main()


