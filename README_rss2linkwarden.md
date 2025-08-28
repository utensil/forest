# RSS CSV to Linkwarden Converter

## Overview

`rss2linkwarden.py` converts CSV exports from RSS readers to Linkwarden import format, with rich data mapping and reference link extraction.

## Usage

```bash
# Basic conversion
./rss2linkwarden.py input.csv | ./linkwarden_import.py --days -1

# Dry run to preview
./rss2linkwarden.py input.csv | ./linkwarden_import.py --dry-run --days -1
```

## CSV Format Expected

| Column | Description | Linkwarden Mapping |
|--------|-------------|-------------------|
| `id` | Unique identifier | `uniqueID` |
| `title` | Link title | `name` |
| `note` | Discussion URLs/notes | `description` + reference extraction |
| `excerpt` | Content preview | `textContent` |
| `url` | Target URL | `url` |
| `folder` | Category | `collection.name` |
| `tags` | Comma/pipe separated | `tags[]` |
| `created` | ISO timestamp | `datePublished`/`dateArrived` |
| `highlights` | Quoted content | `description` (with `> ` prefix) |

## Features

### Reference Link Extraction
- Scans `note` field line-by-line for URLs and markdown links
- Creates separate Linkwarden entries for discussion links
- Platform-specific tags: `re/hn` (Hacker News), `re/lb` (Lobsters), `re/rd` (Reddit)
- Reference descriptions: "from {original_url}"

### Rich Description Building
- Combines `note` and `highlights` fields
- Formats highlights as markdown quotes (`> text`)
- Preserves discussion context and metadata

### Collection Management
- Maps CSV `folder` to Linkwarden collections
- Reference links go to "references" collection
- Collections created automatically by linkwarden_import.py

## Example

**CSV Input:**
```csv
id,title,note,excerpt,url,folder,tags,created
123,Example,https://news.ycombinator.com/item?id=123,Great article,https://example.com,tech,programming,2025-08-28T01:00:00.000Z
```

**JSON Output:**
```json
{"title": "Example", "url": "https://example.com", "content": "https://news.ycombinator.com/item?id=123", "textContent": "Great article", "tags": "programming", "folder": "tech", ...}
{"title": "https://news.ycombinator.com/item?id=123", "url": "https://news.ycombinator.com/item?id=123", "content": "from https://example.com", "tags": "re/hn", "folder": "references", ...}
```

## Integration

Works seamlessly with existing `linkwarden_import.py` infrastructure:
- Leverages proven API handling and error recovery
- Maintains idempotency and deduplication features
- Supports all existing import options (--days, --dry-run, etc.)
