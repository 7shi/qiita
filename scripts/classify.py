import os
import glob
import yaml
import json
import csv
import sys
import argparse
from pathlib import Path
from pydantic import BaseModel, Field
from llm7shi import Client

class ArticleClassification(BaseModel):
    category: str = Field(description="The category or series directory name (lowercase English string).")
    slug: str = Field(description="A short English kebab-case string based on the title/content.")

def parse_args():
    parser = argparse.ArgumentParser(description="Classify Qiita articles using LLM.")
    parser.add_argument(
        "-m", "--model",
        default="ollama:gemma4:31b-it-qat",
        help="LLM model to use for classification (default: ollama:gemma4:31b-it-qat)"
    )
    return parser.parse_args()

INSTRUCTION_PROMPT = """You are tasked with classifying a Qiita article to organize a repository.
Decide on a category name (directory name) and a short English kebab-case slug for the article.

Guidelines:
1. Category: Select the most appropriate category name primarily from the `tags` provided in the front matter of the article context.
   - Convert the chosen tag to a simple, lowercase English name suitable for a directory (e.g., "Haskell" -> "haskell", "AtCoder" -> "atcoder").
   - If none of the tags are suitable for a directory category, create a new appropriate lowercase English category name based on the article's core topic.
2. Slug: Short English kebab-case string based on the title/content (e.g., haskell-intro, ssml, promise, wsl-setup)."""

def create_context(file_path: Path) -> tuple[str, str, str]:
    """YAML Front Matterを除いた本文冒頭 50 行を取得し、titleとタグ(文字列リスト)で再生成したFront Matterを付与する"""
    with open(file_path, "r", encoding="utf-8") as f:
        raw_lines = [line.rstrip("\n\r") for line in f.readlines()]

    frontmatter_lines = []
    body_lines = []
    in_front_matter = False
    for i, line in enumerate(raw_lines):
        if i == 0 and line.strip() == "---":
            in_front_matter = True
            continue
        if in_front_matter:
            if line.strip() == "---":
                in_front_matter = False
            else:
                frontmatter_lines.append(line)
            continue
        body_lines.append(line)

    try:
        frontmatter = yaml.safe_load("\n".join(frontmatter_lines)) or {}
    except Exception:
        frontmatter = {}

    title = frontmatter.get("title", "")
    created = (frontmatter.get("created_at") or "").split("T", 1)[0]
    raw_tags = frontmatter.get("tags", [])
    tag_names = []
    for t in raw_tags:
        if isinstance(t, dict) and "name" in t:
            tag_names.append(t["name"])
        elif isinstance(t, str):
            tag_names.append(t)

    clean_fm = {
        "title": title,
        "tags": tag_names,
    }
    fm_str = yaml.dump(clean_fm, allow_unicode=True, sort_keys=False).strip()

    target_body_lines = body_lines[:50]
    body_text = "\n".join(target_body_lines)

    context = f"---\n{fm_str}\n---\n\n{body_text}"
    return context, title, created

def main():
    args = parse_args()
    script_dir = Path(__file__).resolve().parent
    repo_root = script_dir.parent

    items_dir = repo_root / "items"
    output_file = repo_root / "classified.tsv"

    # Load already processed
    processed_ids = set()
    if output_file.exists():
        with open(output_file, 'r', encoding='utf-8') as f:
            reader = csv.reader(f, delimiter='\t')
            next(reader, None) # skip header
            for row in reader:
                if row:
                    processed_ids.add(row[0])

    md_files = sorted(list(items_dir.glob("*.md")))
    target_files = [
        f for f in md_files
        if f.stem not in processed_ids
    ]

    print(f"Total articles: {len(md_files)}, Already classified: {len(processed_ids)}, Remaining to classify: {len(target_files)}")

    file_exists = output_file.exists()
    mode = 'a' if file_exists else 'w'
    with open(output_file, mode, encoding='utf-8', newline='') as f:
        writer = csv.writer(f, delimiter='\t')
        if not file_exists:
            writer.writerow(['id', 'category', 'slug', 'title', 'created_at'])

        for i, file_path in enumerate(target_files):
            file_id = file_path.stem
            context, title, created = create_context(file_path)
            print(f"[{i+1}/{len(target_files)}] Processing {file_id}: {title}")

            try:
                # 記事ごとに独立して実行するため毎回 Client インスタンスを新規作成（履歴積み重なり防止）
                client = Client(model=args.model, show_params=False)
                resp = client(f"{context}\n\n{INSTRUCTION_PROMPT}", schema=ArticleClassification)
                ans = resp.data if getattr(resp, 'data', None) is not None else ArticleClassification.model_validate_json(resp.text)

                category = (ans.category or 'misc').strip('/')
                slug = (ans.slug or 'untitled').strip('/')

                writer.writerow([
                    file_id,
                    category,
                    slug,
                    title,
                    created,
                ])
                f.flush()
                print(f"  -> Category: {category}, Slug: {slug}")
            except Exception as e:
                print(f"  -> Error processing {file_id}: {e}")

if __name__ == "__main__":
    main()



