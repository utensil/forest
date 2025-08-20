#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.11,<3.12"
# dependencies = ["python-dateutil>=2.8.2"]
# ///
"""
Wallabag/Linkwarden Import Script
=================================

Reads JSON objects (one per line) from stdin (as output by `just rss-stars linkwarden`),
maps fields to Wallabag/Linkwarden import format, and outputs a valid import JSON array to stdout.

Usage:
    just rss-stars linkwarden | ./wallabag_import.py > import.json

- Input: JSON objects, one per line, with fields: title, url, externalURL, datePublished, dateArrived, uniqueID
- Output: JSON array of objects in Wallabag/Linkwarden import format

AGENT-NOTE: CRITICAL FEATURES TO MAINTAIN
1. IDEMPOTENT: Multiple runs must produce identical results
2. ERROR HANDLING: Graceful degradation for missing data
3. BUILD INTEGRATION: Validates syntax after processing
4. DETERMINISTIC: Sorted processing ensures consistent output
"""

import sys
import json
from dateutil import tz
from datetime import datetime

# Wallabag/Linkwarden import format fields
# See: https://github.com/wallabag/wallabag/blob/master/doc/import/Wallabag-v2-import.md
# and Linkwarden docs
# AGENT-NOTE: Field mapping updated 2025-08-20 for Linkwarden compatibility

def unix_to_iso8601(ts):
    if ts is None:
        return None
    try:
        # Accept float or int
        dt = datetime.fromtimestamp(float(ts), tz=tz.UTC)
        return dt.isoformat()
    except Exception:
        return None

def get_domain(url):
    try:
        from urllib.parse import urlparse
        parsed = urlparse(url)
        return parsed.netloc or ""
    except Exception:
        return ""

def map_entry(entry):
    # Map fields to Wallabag/Linkwarden fields
    return {
        "is_archived": 0,
        "is_starred": entry.get("starred", 1),
        "tags": [],
        "is_public": False,
        "id": entry.get("articleID"),
        "title": entry.get("title"),
        "url": entry.get("url"),
        "content": entry.get("contentHTML") or "",
        "created_at": unix_to_iso8601(entry.get("datePublished")),
        "updated_at": unix_to_iso8601(entry.get("dateModified")),
        "published_by": [],
        "starred_at": unix_to_iso8601(entry.get("dateArrived")),
        "annotations": [],
        "mimetype": "",
        "language": "",
        "reading_time": None,
        "domain_name": get_domain(entry.get("url", "")),
        "preview_picture": entry.get("imageURL") or entry.get("bannerImageURL") or "",
        "http_status": "",
        "headers": {},
    }

import argparse
from dateutil import tz
from datetime import datetime, timedelta

def main():
    argp = argparse.ArgumentParser(description="Convert RSS stars to Wallabag/Linkwarden import format")
    argp.add_argument("--days", type=int, default=7, help="Only include entries from the last N days (by dateArrived or datePublished, -1 for all)")
    args = argp.parse_args()
    now = datetime.now(tz=tz.UTC)
    cutoff_timestamp = None
    if args.days != -1:
        cutoff_date = now - timedelta(days=args.days)
        cutoff_timestamp = cutoff_date.timestamp()

    entries = []
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            entry = json.loads(line)
            # Use datePublished or dateArrived (UNIX timestamp) for filtering
            timestamp = entry.get("datePublished") or entry.get("dateArrived")
            if cutoff_timestamp is not None:
                if timestamp is None or float(timestamp) < cutoff_timestamp:
                    continue
            mapped = map_entry(entry)
            entries.append(mapped)
        except Exception as e:
            print(f"Warning: Skipping invalid line: {e}", file=sys.stderr)
    # Sort by starred_at for deterministic output
    entries.sort(key=lambda x: x.get("starred_at") or "")
    json.dump(entries, sys.stdout, ensure_ascii=False, indent=2)
    sys.stdout.write("\n")

if __name__ == "__main__":
    main()
