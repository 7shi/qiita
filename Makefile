.PHONY: help all extract articles sync status update

help:
	@echo "Available targets:"
	@echo "  help         - Show this help message"
	@echo "  all          - Fetch all pages (7shi-1.json to 7shi-3.json) and extract items"
	@echo "  7shi-%.json  - Fetch 7shi's articles for the specific page (e.g. 7shi-1.json)"
	@echo "  extract      - Extract items from json to md"
	@echo "  articles     - Aggregate articles from the articles/ directory"
	@echo "  sync         - Sync article bodies with the Zenn repository (ZENN.tsv)"
	@echo "  status       - List articles not yet reflected on Qiita"
	@echo "  update       - Update all articles not yet reflected on Qiita"

all: data/7shi-1.json data/7shi-2.json data/7shi-3.json extract

data/7shi-%.json:
	curl -s "https://qiita.com/api/v2/users/7shi/items?page=$*&per_page=100" | jq . > $@

extract:
	uv run scripts/extract.py

articles:
	uv run scripts/aggregate_articles.py

sync:
	uv run scripts/sync_zenn.py

status:
	uv run scripts/update_article.py

update:
	uv run scripts/update_article.py --all
