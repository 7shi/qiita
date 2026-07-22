"""
Qiita記事のシリーズ抽出スクリプト

【仕様】
1. `items/` ディレクトリ内の全記事を総当たりで処理対象とします。
2. 既に抽出済みのシリーズに含まれる記事IDおよび処理済み記事IDをスキップしながら未処理の記事を巡回します。
3. 対象記事の `items/{id}.md` の本文冒頭 50 行（YAML Front Matter除外）を取得します。
4. 本文中のQiita記事URLを出現順に [1], [2], [3] ... のような可変長数値仮表記に置換してLLMに渡します。
5. LLMは同一シリーズに属する仮番号の整数リストを出力します。自分自身（リンクのない記事）は 0 と判定させ、シリーズでなければ [0] を返させます。
6. Pythonスクリプト側で 0 を起点記事IDに、数値仮番号を実際の 20 桁Qiita記事IDに復元し、series.jsonl に記録します。
7. グループが検出された場合、グループに含まれる記事も処理対象リストから除外します。
"""

import argparse
import json
import os
import re
import sys
from pathlib import Path
from pydantic import BaseModel, Field
from llm7shi import Client

QIITA_URL_PATTERN = re.compile(
    r"https?://qiita\.com/[^/\s\)]+/items/([0-9a-f]{20})"
)


class SeriesExtractionResult(BaseModel):
    series_item_numbers: list[int] = Field(
        description="List of 1-based item numbers (e.g. [1, 0, 2, 3]) representing the ordered articles belonging to the SAME series. Use 0 for the current unlinked article itself. If the article is NOT part of a series, return [0]."
    )


INSTRUCTION_PROMPT = """You are tasked with identifying the sequence of articles belonging to the SAME series from the provided text.
Article links in the text have been replaced with 1-based numbers in brackets like [1], [2], [3], etc.

Extract the list of item numbers (integers e.g., 1, 2) that belong to the SAME series.
IMPORTANT:
- Use 0 to represent the CURRENT article itself if it appears as an unlinked item in the series sequence (e.g. "2. 外積と愉快な仲間たち ← この記事").
- If the article is NOT part of any series (standalone article), return [0].
- Do NOT include numbers for unrelated external references or recommended links that are not part of this series.
- Return the numbers in the order they belong to the series."""


def parse_args():
    parser = argparse.ArgumentParser(
        description="Extract series article ID groups from Qiita articles."
    )
    parser.add_argument(
        "-m",
        "--model",
        default="ollama:gemma4:31b-it-qat",
        help="LLM model to use for extraction (default: ollama:gemma4:31b-it-qat)",
    )
    parser.add_argument(
        "-i",
        "--items-dir",
        default="items",
        help="Path to items directory (default: items)",
    )
    parser.add_argument(
        "-o",
        "--output",
        default="series.jsonl",
        help="Output JSONL file path (default: series.jsonl)",
    )
    return parser.parse_args()


def load_all_article_ids(items_dir: Path) -> list[str]:
    """items ディレクトリ内の全 .md ファイルから記事ID一覧を取得する"""
    if not items_dir.exists():
        print(f"Error: {items_dir} not found.", file=sys.stderr)
        return []
    return sorted([p.stem for p in items_dir.glob("*.md")])


def create_context(file_path: Path) -> tuple[str, dict[int, str]]:
    """YAML Front Matterを除外した本文冒頭 50 行を取得し、URLを [1], [2]... に置換したテキストと対応マップを返す"""
    with open(file_path, "r", encoding="utf-8") as f:
        raw_lines = [line.rstrip("\n\r") for line in f.readlines()]

    body_lines = []
    in_front_matter = False
    for i, line in enumerate(raw_lines):
        if i == 0 and line.strip() == "---":
            in_front_matter = True
            continue
        if in_front_matter:
            if line.strip() == "---":
                in_front_matter = False
            continue
        body_lines.append(line)

    target_lines = body_lines[:50]
    raw_text = "\n".join(target_lines)

    placeholder_map: dict[int, str] = {}
    counter = 1

    def replace_url(match):
        nonlocal counter
        article_id = match.group(1)
        tag = counter
        placeholder_map[tag] = article_id
        counter += 1
        return f"[{tag}]"

    processed_text = QIITA_URL_PATTERN.sub(replace_url, raw_text)
    context = f"Article File: {file_path.name}\n\nArticle Content Snippet:\n{processed_text}"
    return context, placeholder_map


def main():
    args = parse_args()
    script_dir = Path(__file__).resolve().parent
    repo_root = script_dir.parent

    items_dir = repo_root / args.items_dir
    output_path = repo_root / args.output

    all_ids = load_all_article_ids(items_dir)
    print(f"Found {len(all_ids)} total articles in {items_dir.name}.")

    processed_ids = set()
    group_count = 0

    # 過去の出力 (JSONL) があれば読み込んで途中再開をサポート
    if output_path.exists():
        try:
            with open(output_path, "r", encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if not line:
                        continue
                    data = json.loads(line)
                    root_id = data.get("root_id")
                    member_ids = data.get("member_ids", [])
                    if root_id:
                        processed_ids.add(root_id)
                    for mid in member_ids:
                        processed_ids.add(mid)
                    if len(member_ids) > 1:
                        group_count += 1
            print(
                f"Loaded existing output from {output_path.name}. {group_count} series groups found, {len(processed_ids)} article IDs completed."
            )
        except Exception as e:
            print(f"Warning: Could not read existing output file: {e}", file=sys.stderr)

    # 処理対象リスト作成（未処理の記事のみ）
    remaining_ids = [aid for aid in all_ids if aid not in processed_ids]
    print(f"Remaining articles to process: {len(remaining_ids)}")

    while remaining_ids:
        root_id = remaining_ids[0]
        file_path = items_dir / f"{root_id}.md"

        if not file_path.exists():
            print(f"Warning: File {file_path} does not exist.", file=sys.stderr)
            remaining_ids.pop(0)
            processed_ids.add(root_id)
            record = {"root_id": root_id, "member_ids": []}
            with open(output_path, "a", encoding="utf-8") as f:
                f.write(json.dumps(record, ensure_ascii=False) + "\n")
            continue

        context, placeholder_map = create_context(file_path)
        print(f"[{len(remaining_ids)} remaining] Processing article ID: {root_id}")

        try:
            # 各記事独立して実行するため毎回 Client インスタンスを新規作成（履歴積み重なり防止）
            client = Client(model=args.model, show_params=False)
            resp = client(f"{context}\n\n{INSTRUCTION_PROMPT}", schema=SeriesExtractionResult)
            ans = (
                resp.data
                if getattr(resp, "data", None) is not None
                else SeriesExtractionResult.model_validate_json(resp.text)
            )

            extracted_ids = []

            for num in ans.series_item_numbers:
                if num == 0:
                    if root_id not in extracted_ids:
                        extracted_ids.append(root_id)
                elif num in placeholder_map:
                    real_id = placeholder_map[num]
                    if real_id not in extracted_ids:
                        extracted_ids.append(real_id)

            if root_id not in extracted_ids:
                extracted_ids.insert(0, root_id)

            is_series = len(extracted_ids) > 1

            if is_series:
                record = {
                    "root_id": root_id,
                    "member_ids": extracted_ids,
                }
                print(
                    f"  -> Extracted series group with {len(extracted_ids)} articles (items: {ans.series_item_numbers})."
                )
                to_remove = set(extracted_ids)
            else:
                record = {
                    "root_id": root_id,
                    "member_ids": [],
                }
                print(f"  -> Standalone article (not a series).")
                to_remove = {root_id}

            # 1行追記で逐次出力
            with open(output_path, "a", encoding="utf-8") as f:
                f.write(json.dumps(record, ensure_ascii=False) + "\n")

            processed_ids.update(to_remove)

            # 処理対象リストから除外
            remaining_ids = [aid for aid in remaining_ids if aid not in to_remove]

        except Exception as e:
            print(f"  -> Error processing {root_id}: {e}", file=sys.stderr)
            record = {"root_id": root_id, "member_ids": []}
            with open(output_path, "a", encoding="utf-8") as f:
                f.write(json.dumps(record, ensure_ascii=False) + "\n")
            remaining_ids.pop(0)
            processed_ids.add(root_id)

    print(f"Extraction finished. Results saved to {output_path}")


if __name__ == "__main__":
    main()

