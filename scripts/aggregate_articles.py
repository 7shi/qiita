import csv
from pathlib import Path

import yaml

ARTICLES_DIR = Path("articles")
SERIES_DIR = Path("series")
OUTPUT_TSV = "ARTICLES.tsv"

def load_frontmatter(path: Path) -> dict:
    with open(path, "r", encoding="utf-8") as f:
        lines = f.read().splitlines()

    frontmatter_lines = []
    in_front_matter = False
    for i, line in enumerate(lines):
        if i == 0 and line.strip() == "---":
            in_front_matter = True
            continue
        if in_front_matter:
            if line.strip() == "---":
                break
            frontmatter_lines.append(line)

    return yaml.safe_load("\n".join(frontmatter_lines)) or {}

def main():
    rows = []
    for base_dir in (ARTICLES_DIR, SERIES_DIR):
        for path in base_dir.glob("*/*.md"):
            if path.name == "README.md":
                continue
            directory = str(path.parent)
            slug = path.stem
            frontmatter = load_frontmatter(path)
            article_id = frontmatter["id"]
            title = frontmatter["title"]
            created = frontmatter["created_at"].split("T", 1)[0]
            rows.append((article_id, created, directory, slug, title))

    rows.sort(key=lambda row: (row[2], row[3]))

    with open(OUTPUT_TSV, "w", encoding="utf-8", newline="") as f:
        writer = csv.writer(f, delimiter="\t", lineterminator="\n")
        writer.writerow(["id", "created", "directory", "slug", "title"])
        writer.writerows(rows)

if __name__ == "__main__":
    main()
