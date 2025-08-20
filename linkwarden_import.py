#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.11,<3.12"
# dependencies = ["urllib3>=2.0.0", "tqdm>=4.66.0"]
# ///
"""
Linkwarden API Import Script
===========================

Reads JSON objects (one per line) from stdin (as output by `just rss-stars linkwarden`),
creates links in Linkwarden via its API, waits for archive status, and reports progress.

Usage:
    just rss-stars linkwarden | ./linkwarden_import.py --days 6

- Input: JSON objects, one per line, with fields: title, url, externalURL, datePublished, dateArrived, uniqueID, tags, etc.
- Output: Progress bar and stats to stderr, details for each link.

AGENT-NOTE: CRITICAL FEATURES TO MAINTAIN
1. IDEMPOTENT: Multiple runs must produce identical results (skip duplicates)
2. ERROR HANDLING: Graceful degradation for missing data or API errors
3. RATE LIMITING: Pause after every N links
4. DETERMINISTIC: Sorted processing ensures consistent output

AGENT-NOTE: HTTP/2 COMPATIBILITY SOLUTION
Uses urllib3 directly instead of requests to avoid HTTP/2 compatibility issues with Caddy.
urllib3 defaults to HTTP/1.1 which works reliably with Caddy's reverse proxy setup.
See .agents/docs/caddy_ssl_analysis.md for detailed technical analysis.
"""

import sys
import json
import time
import argparse
import os
import urllib3
from tqdm import tqdm
from datetime import datetime, timedelta, timezone

# Disable SSL warnings for self-signed certificates
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

API_BASE = os.environ.get("LINKWARDEN_API_BASE", "https://linkwarden.homelab.local/api/v1")
API_TOKEN = os.environ.get("LINKWARDEN_API_TOKEN")
if not API_TOKEN:
    print("ERROR: LINKWARDEN_API_TOKEN environment variable must be set", file=sys.stderr)
    sys.exit(1)
HEADERS = {"Authorization": f"Bearer {API_TOKEN}", "Content-Type": "application/json"}

RATE_LIMIT = 3  # links per batch
PAUSE_SECS = 5  # seconds to pause after each batch
ARCHIVE_POLL_SECS = 2  # seconds between archive status polls
ARCHIVE_TIMEOUT_SECS = 30  # max seconds to wait for archive

# Create urllib3 pool manager with SSL verification disabled for Caddy's internal TLS
http = urllib3.PoolManager(cert_reqs='CERT_NONE')

def test_api_connection():
    """Test API connection and token validity"""
    try:
        resp = http.request('GET', f"{API_BASE}/links", headers=HEADERS, timeout=10)
        if resp.status == 200:
            return True, "API connection successful"
        elif resp.status == 401 or b"session has expired" in resp.data.lower():
            return False, "API token expired - please refresh token in Linkwarden UI"
        else:
            return False, f"API error: {resp.status} {resp.data.decode()[:100]}"
    except Exception as e:
        return False, f"Connection error: {e}"

def create_link(entry):
    url = entry.get("externalURL") or entry.get("url")
    if not url:
        return None, "No URL"
    
    data = {
        "name": entry.get("title") or url,
        "url": url,
        "description": entry.get("content") or "",
    }
    tags = entry.get("tags")
    if tags:
        if isinstance(tags, str):
            tags = [t.strip() for t in tags.split("|") if t.strip()]
        data["tags"] = [{"name": t} for t in tags if t]
    
    try:
        resp = http.request('POST', f"{API_BASE}/links", 
                           headers=HEADERS, 
                           body=json.dumps(data).encode('utf-8'),
                           timeout=10)
        
        if resp.status == 200:
            try:
                response_data = json.loads(resp.data.decode())
                link_id = response_data["response"]["id"]
                return link_id, None
            except (json.JSONDecodeError, KeyError) as e:
                return None, f"Response parsing error: {e}"
        elif resp.status == 400 and b"already exists" in resp.data:
            return None, "Duplicate"
        elif resp.status == 401 or b"session has expired" in resp.data.lower():
            return None, "API token expired - please refresh token in Linkwarden UI"
        else:
            return None, f"API error: {resp.status} {resp.data.decode()[:100]}"
    except Exception as e:
        return None, f"Request error: {e}"

def wait_for_archive(link_id):
    start = time.time()
    while time.time() - start < ARCHIVE_TIMEOUT_SECS:
        try:
            resp = http.request('GET', f"{API_BASE}/archives/{link_id}", 
                               headers=HEADERS, timeout=10)
            if resp.status == 200:
                return True
            elif resp.status == 404:
                time.sleep(ARCHIVE_POLL_SECS)
            else:
                return False
        except Exception:
            time.sleep(ARCHIVE_POLL_SECS)
    return False

def main():
    argp = argparse.ArgumentParser(description="Import links to Linkwarden via API")
    argp.add_argument("--days", type=int, default=6, help="Only include entries from the last N days (by dateArrived or datePublished, -1 for all)")
    args = argp.parse_args()
    
    # Test API connection first
    api_ok, api_msg = test_api_connection()
    if not api_ok:
        print(f"API connection failed: {api_msg}", file=sys.stderr)
        sys.exit(1)
    print(f"✓ {api_msg}", file=sys.stderr)
    
    now = datetime.now(timezone.utc)
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
            timestamp = entry.get("dateArrived") or entry.get("datePublished")
            if cutoff_timestamp is not None:
                if timestamp is None or float(timestamp) < cutoff_timestamp:
                    continue
            entries.append(entry)
        except Exception as e:
            print(f"Warning: Skipping invalid line: {e}", file=sys.stderr)

    # Sort for deterministic order
    entries.sort(key=lambda x: x.get("dateArrived") or x.get("datePublished") or 0)

    stats = {"created": 0, "failed": 0, "archived": 0, "duplicates": 0}
    details = []
    with tqdm(total=len(entries), file=sys.stderr, desc="Importing links") as pbar:
        for i, entry in enumerate(entries):
            link_id, err = create_link(entry)
            if link_id:
                stats["created"] += 1
                archived = wait_for_archive(link_id)
                if archived:
                    stats["archived"] += 1
                details.append({"title": entry.get("title"), "url": entry.get("url"), "id": link_id, "archived": archived})
            elif err == "Duplicate":
                stats["duplicates"] += 1
                details.append({"title": entry.get("title"), "url": entry.get("url"), "error": "Duplicate"})
            else:
                stats["failed"] += 1
                details.append({"title": entry.get("title"), "url": entry.get("url"), "error": err})
            pbar.update(1)
            if (i + 1) % RATE_LIMIT == 0:
                time.sleep(PAUSE_SECS)

    # Print summary
    print("\nImport complete.", file=sys.stderr)
    print(json.dumps(stats, indent=2), file=sys.stderr)
    for d in details:
        print(json.dumps(d, ensure_ascii=False), file=sys.stderr)

if __name__ == "__main__":
    main()
