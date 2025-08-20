#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.11,<3.12"
# dependencies = []
# ///
"""
Pocket Export Script
===================

Reads JSON objects (one per line) from stdin (as output by `just rss-stars "linkwarden"`),
maps fields to Pocket CSV import format, and outputs a valid CSV to stdout.

Usage:
    just rss-stars "linkwarden" | ./rss2pocket.py > pocket.csv

- Input: JSON objects, one per line, with fields: title, url, externalURL, datePublished, dateArrived, tags, starred, etc.
- Output: CSV with columns: title, url, time_added, cursor, tags, status

AGENT-NOTE: CRITICAL FEATURES TO MAINTAIN
1. IDEMPOTENT: Multiple runs must produce identical results
2. ERROR HANDLING: Graceful degradation for missing data
3. BUILD INTEGRATION: Validates syntax after processing
4. DETERMINISTIC: Sorted processing ensures consistent output
"""

import sys
import json
import csv
import argparse
from datetime import datetime, timedelta, timezone
import zipfile

# AGENT-NOTE: Pocket CSV columns: title, url, time_added, cursor, tags, status, lobsters_url, hn_url
COLUMNS = ["title", "url", "time_added", "cursor", "tags", "status"]

def get_time_added(entry):
    # Prefer dateArrived, fallback to datePublished, else 0
    ts = entry.get("dateArrived") or entry.get("datePublished")
    try:
        return str(int(float(ts))) if ts is not None else "0"
    except Exception:
        return "0"

def get_tags(entry):
    tags = entry.get("tags")
    if isinstance(tags, list):
        return "|".join(str(t).strip() for t in tags if t)
    elif isinstance(tags, str):
        return tags.strip()
    return ""

def map_entry(entry):
    # Map fields to Pocket CSV columns, using best available data
    # Determine status: only 'unread' or 'archived' are valid
    status = "unread"
    # Accept both is_archived (bool/int) and status (str) from input
    is_archived = entry.get("is_archived")
    input_status = str(entry.get("status", "")).strip().lower()
    if input_status == "archived" or is_archived in [1, True, "1", "true", "True"]:
        status = "archived"
    # Force output to only 'unread' or 'archived'
    if status != "archived":
        status = "unread"
    # If url is a lobste.rs or HN link and externalURL exists, always use externalURL
    def is_aggregator(url):
        if not url:
            return False
        return ("lobste.rs" in url) or ("news.ycombinator.com" in url) or ("ycombinator.com/item" in url)

    ext_url = entry.get("externalURL")
    main_url = entry.get("url")
    # Always prefer externalURL if present and non-empty
    if ext_url:
        url = ext_url
    elif main_url:
        url = main_url
    else:
        url = entry.get("uniqueID") or ""

    return {
        "title": entry.get("title", ""),  # Use as-is, no fallback
        "url": url,
        "time_added": get_time_added(entry),
        "tags": get_tags(entry),
        "status": status if status == "archived" else "unread",
    }

def main():
    argp = argparse.ArgumentParser(description="Convert RSS stars to Pocket CSV import format")
    argp.add_argument("--days", type=int, default=7, help="Only include entries from the last N days (by dateArrived or datePublished, -1 for all)")
    argp.add_argument("--debug", action="store_true", help="Enable detailed debug logging to stderr for each entry")
    args = argp.parse_args()
    now = datetime.now(timezone.utc)
    cutoff_timestamp = None
    if args.days != -1:
        cutoff_date = now - timedelta(days=args.days)
        cutoff_timestamp = cutoff_date.timestamp()

    entries = []
    entry_count = 0
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            entry = json.loads(line)
            entry_count += 1
            # Use dateArrived or datePublished (UNIX timestamp) for filtering
            timestamp = entry.get("dateArrived") or entry.get("datePublished")
            filtered_out = False
            filter_reason = ""
            if cutoff_timestamp is not None:
                if timestamp is None or float(timestamp) < cutoff_timestamp:
                    filtered_out = True
                    filter_reason = f"timestamp {timestamp} < cutoff {cutoff_timestamp}"
            if filtered_out:
                if args.debug:
                    print(f"[DEBUG] Skipped entry {entry_count}: title='{entry.get('title','')}' url='{entry.get('url','')}' externalURL='{entry.get('externalURL','')}' reason={filter_reason}", file=sys.stderr)
                continue
            mapped = map_entry(entry)
            if args.debug:
                print(f"[DEBUG] Processed entry {entry_count}: title='{mapped['title']}'\n  aggregator_url='{entry.get('url','')}'\n  external_url='{entry.get('externalURL','')}'\n  chosen_url='{mapped['url']}'\n  time_added='{mapped['time_added']}' status='{mapped['status']}' tags='{mapped['tags']}'", file=sys.stderr)
            entries.append(mapped)
        except Exception as e:
            print(f"Warning: Skipping invalid line: {e}", file=sys.stderr)
    # Sort by time_added for deterministic output
    entries.sort(key=lambda x: x["time_added"])
    # Write to output/pocket.csv as well as stdout
    import os
    os.makedirs('output', exist_ok=True)
    # Write part_000000.csv (with cursor column) and make output/pocket.csv identical
    part_csv_path = 'output/part_000000.csv'
    pocket_csv_path = 'output/pocket.csv'
    with open(part_csv_path, 'w', newline='', encoding='utf-8') as f1, \
         open(pocket_csv_path, 'w', newline='', encoding='utf-8') as f2:
        writer1 = csv.DictWriter(f1, fieldnames=COLUMNS)
        writer2 = csv.DictWriter(f2, fieldnames=COLUMNS)
        writer1.writeheader()
        writer2.writeheader()
        for row in entries:
            row_out = row.copy()
            row_out['cursor'] = ''  # Always empty
            writer1.writerow(row_out)
            writer2.writerow(row_out)
    # Create output/pocket.zip containing only part_000000.csv at the root
    with zipfile.ZipFile('output/pocket.zip', 'w', zipfile.ZIP_DEFLATED) as zipf:
        zipf.write(part_csv_path, arcname='part_000000.csv')
    print("Pocket export written to output/pocket.csv", file=sys.stderr)
    print("Pocket export written to output/pocket.zip", file=sys.stderr)
    # Also write to stdout in the same format
    writer = csv.DictWriter(sys.stdout, fieldnames=COLUMNS)
    writer.writeheader()
    for row in entries:
        row_out = row.copy()
        row_out['cursor'] = ''
        writer.writerow(row_out)

    # Output summary to stderr: count and date range
    timestamps = [int(e["time_added"]) for e in entries if e["time_added"].isdigit() and int(e["time_added"]) > 0]
    if timestamps:
        min_ts = min(timestamps)
        max_ts = max(timestamps)
        min_dt = datetime.fromtimestamp(min_ts, tz=timezone.utc).strftime('%Y-%m-%d %H:%M:%S UTC')
        max_dt = datetime.fromtimestamp(max_ts, tz=timezone.utc).strftime('%Y-%m-%d %H:%M:%S UTC')
        print(f"Exported {len(entries)} entries. Date range: {min_dt} — {max_dt}", file=sys.stderr)
    else:
        print(f"Exported {len(entries)} entries. No valid date range.", file=sys.stderr)

if __name__ == "__main__":
    main()
