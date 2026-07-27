import csv
from pathlib import Path

import yaml

CLASSIFIED_TSV = "classified.tsv"
CATEGORY_MAP_TXT = "category_map.txt"
ITEMS_DIR = "items"
OUTPUT_TSV = "articles.tsv"

def load_category_map(path: str) -> dict[str, str]:
    tag_to_category = {}
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.rstrip("\n")
            if not line:
                continue
            category, tags = line.split(": ", 1)
            for tag in tags.split(", "):
                tag_to_category[tag] = category
    return tag_to_category

def load_frontmatter(item_id: str) -> tuple[str, str]:
    text = Path(ITEMS_DIR, f"{item_id}.md").read_text(encoding="utf-8")
    frontmatter = yaml.safe_load(text.split("---", 2)[1])
    created = frontmatter["created_at"].split("T", 1)[0]
    return frontmatter["title"], created

def main():
    tag_to_category = load_category_map(CATEGORY_MAP_TXT)

    rows = []
    with open(CLASSIFIED_TSV, "r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f, delimiter="\t")
        for row in reader:
            item_id = row["id"]
            tag = row["category"]
            category = tag_to_category.get(tag, tag)
            title, created = load_frontmatter(item_id)
            rows.append((category, created, item_id, title))

    with open(OUTPUT_TSV, "w", encoding="utf-8", newline="") as f:
        writer = csv.writer(f, delimiter="\t", lineterminator="\n")
        writer.writerow(["category", "created", "id", "title"])
        writer.writerows(sorted(rows))

if __name__ == "__main__":
    main()
