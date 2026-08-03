import argparse
import csv
import json
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path

import yaml

REPO_ROOT = Path(__file__).resolve().parent.parent
ARTICLES_TSV = REPO_ROOT / 'ARTICLES.tsv'
ZENN_TSV = REPO_ROOT / 'ZENN.tsv'


def split_frontmatter(text):
    if not text.startswith('---\n'):
        raise ValueError('フロントマターが見つかりません')
    end = text.index('\n---\n', 4)
    front = text[4:end]
    body = text[end + 5:].lstrip('\n')
    return front, body


def load_zenn_paths():
    """ZENN.tsv に載っている Qiita 側パスの集合を返す（Zenn で公開する記事）"""
    if not ZENN_TSV.exists():
        return set()
    with open(ZENN_TSV, encoding='utf-8', newline='') as f:
        return {row['qiita'] for row in csv.DictReader(f, delimiter='\t') if row.get('qiita')}


def list_pending():
    """ARTICLES.tsv を走査し、updated_at が空の記事（Qiita へ未反映）を列挙する"""
    if not ARTICLES_TSV.exists():
        print(f'{ARTICLES_TSV} が見つかりません。make articles で生成してください', file=sys.stderr)
        sys.exit(1)

    zenn_paths = load_zenn_paths()

    count = 0
    with open(ARTICLES_TSV, encoding='utf-8', newline='') as f:
        for row in csv.DictReader(f, delimiter='\t'):
            rel = f'{row["directory"]}/{row["slug"]}.md'
            if rel in zenn_paths:
                continue
            path = REPO_ROOT / rel
            if not path.exists():
                print(f'{path.relative_to(REPO_ROOT)}: ファイルがありません', file=sys.stderr)
                continue
            try:
                front, _ = split_frontmatter(path.read_text(encoding='utf-8'))
                fm = yaml.safe_load(front)
            except ValueError as e:
                print(f'{path.relative_to(REPO_ROOT)}: {e}', file=sys.stderr)
                continue
            if fm.get('updated_at'):
                continue
            count += 1
            mark = '' if fm.get('id') else '\t(未投稿)'
            print(f'{path.relative_to(REPO_ROOT)}{mark}')

    if count == 0:
        print('Qiita へ未反映の記事はありません', file=sys.stderr)


def update_one(path, token, assume_yes):
    with open(path, encoding='utf-8') as f:
        text = f.read()
    front, body = split_frontmatter(text)
    fm = yaml.safe_load(front)

    item_id = fm.get('id')
    if not item_id:
        print(f'{path}: id が空です（未投稿の記事）。このスクリプトは既存記事の PATCH のみ対応しています', file=sys.stderr)
        sys.exit(1)

    if fm.get('updated_at') and not assume_yes:
        try:
            answer = input(f'{path}: updated_at が空ではありません（{fm["updated_at"]}）。既に同期済みの可能性があります。続行しますか？ [y/N] ')
        except EOFError:
            answer = ''
        if answer.strip().lower() != 'y':
            print('中止しました', file=sys.stderr)
            sys.exit(1)

    payload = {
        'title': fm['title'],
        'body': body,
        'tags': fm.get('tags', []),
        'private': fm.get('private', False),
    }
    for key in ('slide', 'coediting'):
        if key in fm:
            payload[key] = fm[key]

    req = urllib.request.Request(
        f'https://qiita.com/api/v2/items/{item_id}',
        data=json.dumps(payload).encode('utf-8'),
        method='PATCH',
        headers={
            'Content-Type': 'application/json',
            'Authorization': f'Bearer {token}',
        },
    )
    try:
        with urllib.request.urlopen(req) as resp:
            result = json.load(resp)
    except urllib.error.HTTPError as e:
        print(f'HTTP {e.code}: {e.read().decode("utf-8")}', file=sys.stderr)
        sys.exit(1)

    for key in fm:
        if key in result:
            fm[key] = result[key]

    frontmatter = yaml.dump(fm, allow_unicode=True, default_flow_style=False, sort_keys=False)
    with open(path, 'w', encoding='utf-8') as f:
        f.write('---\n')
        f.write(frontmatter)
        f.write('---\n\n')
        f.write(body)

    print(f'更新しました: {result["url"]}')


def main():
    parser = argparse.ArgumentParser(
        description='ローカルの記事を Qiita へ PATCH で反映する',
        epilog='環境変数 QIITA_TOKEN に Qiita API のアクセストークンを設定しておく必要があります。'
               '引数を省略すると ARTICLES.tsv を走査して未反映の記事を列挙するだけで、更新はしません。',
    )
    parser.add_argument('paths', nargs='*', help='記事ファイルのパス（複数可。省略時は未反映の記事を列挙）')
    parser.add_argument('-y', dest='assume_yes', action='store_true', help='確認なしで実行する')
    args = parser.parse_args()

    if not args.paths:
        list_pending()
        return

    token = os.environ.get('QIITA_TOKEN')
    if not token:
        print('環境変数 QIITA_TOKEN が設定されていません', file=sys.stderr)
        sys.exit(1)

    for path in args.paths:
        update_one(path, token, args.assume_yes)


if __name__ == '__main__':
    main()
