import csv
from pathlib import Path

import yaml

ARTICLES_DIR = Path("articles")
OUTPUT_TSV = "articles.tsv"

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
    for path in ARTICLES_DIR.glob("*/*.md"):
        category = path.parent.name
        slug = path.stem
        frontmatter = load_frontmatter(path)
        article_id = frontmatter["id"]
        title = frontmatter["title"]
        created = frontmatter["created_at"].split("T", 1)[0]
        rows.append((category, created, article_id, slug, title))

    with open(OUTPUT_TSV, "w", encoding="utf-8", newline="") as f:
        writer = csv.writer(f, delimiter="\t", lineterminator="\n")
        writer.writerow(["category", "created", "id", "slug", "title"])
        writer.writerows(sorted(rows))

if __name__ == "__main__":
    main()
