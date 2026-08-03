import argparse
import json
import os
import sys
import urllib.error
import urllib.request

import yaml


def split_frontmatter(text):
    if not text.startswith('---\n'):
        raise ValueError('フロントマターが見つかりません')
    end = text.index('\n---\n', 4)
    front = text[4:end]
    body = text[end + 5:].lstrip('\n')
    return front, body


def main():
    parser = argparse.ArgumentParser(
        description='ローカルの記事を Qiita へ PATCH で反映する',
        epilog='環境変数 QIITA_TOKEN に Qiita API のアクセストークンを設定しておく必要があります。',
    )
    parser.add_argument('path', help='記事ファイルのパス')
    parser.add_argument('-y', dest='assume_yes', action='store_true', help='確認なしで実行する')
    args = parser.parse_args()

    path = args.path
    token = os.environ.get('QIITA_TOKEN')
    if not token:
        print('環境変数 QIITA_TOKEN が設定されていません', file=sys.stderr)
        sys.exit(1)

    with open(path, encoding='utf-8') as f:
        text = f.read()
    front, body = split_frontmatter(text)
    fm = yaml.safe_load(front)

    item_id = fm.get('id')
    if not item_id:
        print('id が空です（未投稿の記事）。このスクリプトは既存記事の PATCH のみ対応しています', file=sys.stderr)
        sys.exit(1)

    if fm.get('updated_at') and not args.assume_yes:
        try:
            answer = input(f'updated_at が空ではありません（{fm["updated_at"]}）。既に同期済みの可能性があります。続行しますか？ [y/N] ')
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


if __name__ == '__main__':
    main()
