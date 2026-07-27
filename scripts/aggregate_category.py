import csv
from collections import Counter

CLASSIFIED_TSV = "classified.tsv"
CATEGORY_MAP_TXT = "category_map.txt"
OUTPUT_TXT = "category.txt"

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

def main():
    tag_to_category = load_category_map(CATEGORY_MAP_TXT)

    counts = Counter()
    with open(CLASSIFIED_TSV, "r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f, delimiter="\t")
        for row in reader:
            tag = row["category"]
            counts[tag_to_category.get(tag, tag)] += 1

    with open(OUTPUT_TXT, "w", encoding="utf-8") as f:
        for category in sorted(counts):
            f.write(f"{counts[category]:7d} {category}\n")

if __name__ == "__main__":
    main()
