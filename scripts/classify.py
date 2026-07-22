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
    is_series: bool = Field(description="True if the article belongs to a series (e.g. numbered series, related links), False if it is a standalone article.")
    dir_name: str = Field(description="The category or series directory name (e.g. haskell, math, retro, ai, env, web, etc.).")
    slug: str = Field(description="A short English kebab-case string based on the title/content.")
    series_num: int = Field(description="The estimated order in the series (e.g. 1, 2, 3), useful for reasoning. Use 0 if not a series.")
    reasoning: str = Field(description="Brief reasoning for the chosen category and series/standalone classification.")

def parse_args():
    parser = argparse.ArgumentParser(description="Classify Qiita articles using LLM.")
    parser.add_argument(
        "-m", "--model",
        default="ollama:gemma4:31b-it-qat",
        help="LLM model to use for classification (default: ollama:gemma4:31b-it-qat)"
    )
    parser.add_argument(
        "-s", "--series",
        default="series.jsonl",
        help="Path to series.jsonl (default: series.jsonl)"
    )
    return parser.parse_args()

INSTRUCTION_PROMPT = """You are tasked with classifying a Qiita article to organize a repository.
Determine if this article belongs to a series or is a standalone (category) article.
Also decide on a directory name (category/series name) and a short English kebab-case slug for the filename.

Guidelines:
1. Series criteria: "〜超入門" and "【解答例】〜超入門" pairs, articles ending with "(2)" or similar, continuous topics (Wiktionary, GIF parsing), or articles starting with a list of links (e.g. "Haskellの実験メモ一覧").
2. Directory Candidates: haskell, wiktionary, sapi, math, ai, retro, web, env, misc (or other appropriate names).
3. Slug: Short english kebab-case (e.g., haskell, ssml, promise, wsl-setup)."""

def create_context(frontmatter, content):
    return f"""Article metadata:
Title: {frontmatter.get('title')}
Tags: {', '.join(t.get('name', '') for t in frontmatter.get('tags', []))}
Created At: {frontmatter.get('created_at')}

Article content snippet (first 1500 characters):
{content[:1500]}"""

def load_series_group_ids(series_file: Path) -> set[str]:
    """series.jsonl からグループ判定された (member_ids が2件以上) 全記事IDを取得する"""
    series_ids = set()
    if not series_file.exists():
        return series_ids
    try:
        with open(series_file, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                data = json.loads(line)
                member_ids = data.get("member_ids", [])
                if len(member_ids) > 1:
                    for mid in member_ids:
                        series_ids.add(mid)
                    if "root_id" in data:
                        series_ids.add(data["root_id"])
    except Exception as e:
        print(f"Warning: Could not read {series_file}: {e}", file=sys.stderr)
    return series_ids

def main():
    args = parse_args()
    script_dir = Path(__file__).resolve().parent
    repo_root = script_dir.parent

    items_dir = repo_root / "items"
    output_file = repo_root / "classified.tsv"
    series_file = repo_root / args.series

    # series.jsonl からグループ判定された記事IDを取得して除外対象に設定
    series_group_ids = load_series_group_ids(series_file)
    if series_group_ids:
        print(f"Loaded {len(series_group_ids)} article IDs from {series_file.name} to exclude.")

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
        if f.stem not in processed_ids and f.stem not in series_group_ids
    ]

    print(f"Total articles: {len(md_files)}, Series group excluded: {len(series_group_ids)}, Already classified: {len(processed_ids)}, Remaining to classify: {len(target_files)}")

    file_exists = output_file.exists()
    mode = 'a' if file_exists else 'w'
    with open(output_file, mode, encoding='utf-8', newline='') as f:
        writer = csv.writer(f, delimiter='\t')
        if not file_exists:
            writer.writerow(['id', 'is_series', 'dir_name', 'series_num', 'slug', 'proposed_path', 'reasoning'])
        
        for i, file_path in enumerate(target_files):
            file_id = file_path.stem
            
            with open(file_path, 'r', encoding='utf-8') as mf:
                content = mf.read()
            
            # parse yaml frontmatter
            if content.startswith('---'):
                parts = content.split('---', 2)
                if len(parts) >= 3:
                    try:
                        frontmatter = yaml.safe_load(parts[1])
                        md_content = parts[2].strip()
                    except:
                        frontmatter = {}
                        md_content = content
                else:
                    frontmatter = {}
                    md_content = content
            else:
                frontmatter = {}
                md_content = content
            
            context = create_context(frontmatter, md_content)
            print(f"[{i+1}/{len(target_files)}] Processing {file_id}: {frontmatter.get('title')}")
            
            try:
                # 記事ごとに独立して実行するため毎回 Client インスタンスを新規作成（履歴積み重なり防止）
                client = Client(model=args.model, show_params=False)
                resp = client(f"{context}\n\n{INSTRUCTION_PROMPT}", schema=ArticleClassification)
                ans = resp.data if getattr(resp, 'data', None) is not None else ArticleClassification.model_validate_json(resp.text)
                
                is_series = ans.is_series
                dir_name = (ans.dir_name or 'misc').strip('/')
                series_num = ans.series_num
                slug = (ans.slug or 'untitled').strip('/')
                
                created_at = str(frontmatter.get('created_at', ''))
                date_str = created_at[:10].replace('-', '') if len(created_at) >= 10 else '00000000'

                if is_series:
                    try:
                        num_val = int(series_num)
                        num_str = f"{num_val:02d}"
                    except (ValueError, TypeError):
                        num_str = str(series_num)
                    proposed_filename = f"{num_str}-{slug}.md"
                else:
                    proposed_filename = f"{date_str}-{slug}.md"
                
                proposed_path = f"{dir_name}/{proposed_filename}"

                writer.writerow([
                    file_id, 
                    is_series, 
                    dir_name, 
                    series_num, 
                    slug,
                    proposed_path,
                    ans.reasoning.replace('\n', ' ')
                ])
                f.flush()
                print(f"  -> Proposed path: {proposed_path} (Series: {is_series})")
            except Exception as e:
                print(f"  -> Error processing {file_id}: {e}")

if __name__ == "__main__":
    main()


