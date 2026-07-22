"""
Qiita記事のシリーズ抽出スクリプト

【仕様】
1. `classification.tsv` から `is_series == True`（文字列 'True'）と判定された記事を対象とします。
2. 既に抽出済みのシリーズに含まれる記事IDはスキップしながら未処理の記事を巡回します。
3. 対象記事の `items/{id}.md` の本文冒頭 50 行（YAML Front Matter除外）を取得します。
4. 本文中のQiita記事URLを出現順に [1], [2], [3] ... のような可変長数値仮表記に置換してLLMに渡します。
5. LLMは同一シリーズに属する仮番号の整数リストを出力します。自分自身（リンクのない記事）は 0 と判定させます。
6. Pythonスクリプト側で 0 を起点記事IDに、数値仮番号を実際の 20 桁Qiita記事IDに復元・記録します。
"""

import argparse
import csv
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
        description="List of 1-based item numbers (e.g. [1, 0, 2, 3]) representing the ordered articles belonging to the SAME series. Use 0 for the current unlinked article itself."
    )


INSTRUCTION_PROMPT = """You are tasked with identifying the sequence of articles belonging to the SAME series from the provided text.
Article links in the text have been replaced with 1-based numbers in brackets like [1], [2], [3], etc.

Extract the list of item numbers (integers e.g., 1, 2) that belong to the SAME series.
IMPORTANT:
- Use 0 to represent the CURRENT article itself if it appears as an unlinked item in the series sequence (e.g. "2. 外積と愉快な仲間たち ← この記事").
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
        "-c",
        "--classification",
        default="classification.tsv",
        help="Path to classification.tsv (default: classification.tsv)",
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
        default="series_groups.json",
        help="Output JSON file path (default: series_groups.json)",
    )
    return parser.parse_args()


def load_series_article_ids(tsv_path: str) -> list[str]:
    """classification.tsv から is_series == True の記事ID一覧を取得する"""
    series_ids = []
    if not os.path.exists(tsv_path):
        print(f"Error: {tsv_path} not found.", file=sys.stderr)
        return series_ids

    with open(tsv_path, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f, delimiter="\t")
        for row in reader:
            is_series_val = str(row.get("is_series", "")).strip()
            if is_series_val.lower() == "true":
                series_ids.append(row["id"])
    return series_ids


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

    tsv_path = repo_root / args.classification
    items_dir = repo_root / args.items_dir
    output_path = repo_root / args.output

    series_candidate_ids = load_series_article_ids(str(tsv_path))
    print(f"Found {len(series_candidate_ids)} candidate series articles.")

    # 過去の出力があれば読み込んで途中再開をサポート
    processed_ids = set()
    series_groups = []

    if output_path.exists():
        try:
            with open(output_path, "r", encoding="utf-8") as f:
                series_groups = json.load(f)
            for group in series_groups:
                for item_id in group.get("member_ids", []):
                    processed_ids.add(item_id)
            print(
                f"Loaded existing output with {len(series_groups)} groups ({len(processed_ids)} processed IDs)."
            )
        except Exception as e:
            print(f"Warning: Could not read existing output file: {e}", file=sys.stderr)

    for i, root_id in enumerate(series_candidate_ids):
        # 既に抽出済みのシリーズに含まれるIDはスキップ
        if root_id in processed_ids:
            continue

        file_path = items_dir / f"{root_id}.md"
        if not file_path.exists():
            print(f"Warning: File {file_path} does not exist.", file=sys.stderr)
            continue

        context, placeholder_map = create_context(file_path)
        print(f"[{i+1}/{len(series_candidate_ids)}] Processing root article ID: {root_id}")

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

            # もし0が返されずとも起点記事自体が含まれていない場合は念のため補完
            if root_id not in extracted_ids:
                extracted_ids.insert(0, root_id)

            # 既存記事との重複チェック（安易にマージせずフラグを記録）
            overlaps = [eid for eid in extracted_ids if eid in processed_ids and eid != root_id]
            has_overlap = len(overlaps) > 0

            group_data = {
                "root_id": root_id,
                "member_ids": extracted_ids,
                "has_overlap": has_overlap,
                "overlapping_ids": overlaps,
            }

            series_groups.append(group_data)

            # 抽出されたすべての記事IDを処理済み集合に追加
            for eid in extracted_ids:
                processed_ids.add(eid)

            print(
                f"  -> Extracted group with {len(extracted_ids)} articles (items: {ans.series_item_numbers}). (Overlap: {has_overlap})"
            )

            # 逐次ファイルに書き出し
            with open(output_path, "w", encoding="utf-8") as f:
                json.dump(series_groups, f, ensure_ascii=False, indent=2)

        except Exception as e:
            print(f"  -> Error processing {root_id}: {e}", file=sys.stderr)

    print(f"Extraction finished. Total series groups: {len(series_groups)}")
    print(f"Results saved to {output_path}")


if __name__ == "__main__":
    main()
