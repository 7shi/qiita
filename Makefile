.PHONY: help all extract

help:
	@echo "Available targets:"
	@echo "  help        - Show this help message"
	@echo "  all         - Fetch all pages (7shi-1.json to 7shi-3.json) and extract items"
	@echo "  7shi-%.json - Fetch 7shi's articles for the specific page (e.g. 7shi-1.json)"
	@echo "  extract     - Extract items from json to md"

all: data/7shi-1.json data/7shi-2.json data/7shi-3.json extract

data/7shi-%.json:
	curl -s "https://qiita.com/api/v2/users/7shi/items?page=$*&per_page=100" | jq . > $@

extract:
	uv run scripts/extract.py
