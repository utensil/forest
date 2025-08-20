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

# Only require API token if not in dry-run mode
if "--dry-run" not in sys.argv and not API_TOKEN:
    print("ERROR: LINKWARDEN_API_TOKEN environment variable must be set", file=sys.stderr)
    sys.exit(1)

HEADERS = {"Authorization": f"Bearer {API_TOKEN}", "Content-Type": "application/json"} if API_TOKEN else {}

RATE_LIMIT = 3  # links per batch
PAUSE_SECS = 5  # seconds to pause after each batch
ARCHIVE_POLL_SECS = 2  # seconds between archive status polls
ARCHIVE_TIMEOUT_SECS = 30  # max seconds to wait for archive

# Create urllib3 pool manager with SSL verification disabled for Caddy's internal TLS
http = urllib3.PoolManager(cert_reqs='CERT_NONE')

# RSS collection configuration - new links will be created in this collection
RSS_COLLECTION_ID = 4  # ID of the "rss" collection

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

def search_existing_link(external_url):
    """Search for existing link by externalURL"""
    if not external_url:
        return None
    
    try:
        # Search by URL - Linkwarden API might support search
        # For now, we'll get recent links and search through them
        resp = http.request('GET', f"{API_BASE}/links?limit=100", 
                           headers=HEADERS, timeout=10)
        
        if resp.status == 200:
            try:
                data = json.loads(resp.data.decode())
                links = data.get("response", [])
                
                # Search for matching externalURL or URL
                for link in links:
                    link_url = link.get("url", "")
                    if link_url == external_url:
                        return link
                
                return None
            except (json.JSONDecodeError, KeyError):
                return None
        else:
            return None
    except Exception:
        return None

def extract_aggregator_info(entry):
    """Extract aggregator information from RSS entry"""
    external_url = entry.get("externalURL")
    aggregator_url = entry.get("url")
    
    aggregator_name = None
    if aggregator_url:
        if "lobste.rs" in aggregator_url:
            aggregator_name = "Lobsters"
        elif "news.ycombinator.com" in aggregator_url:
            aggregator_name = "Hacker News"
        elif "reddit.com" in aggregator_url:
            aggregator_name = "Reddit"
    
    return external_url, aggregator_url, aggregator_name

def update_link_description(existing_link, new_aggregator_url, aggregator_name):
    """Update link description with new aggregator link"""
    if not new_aggregator_url or not aggregator_name:
        return False, "No aggregator info to add"
    
    link_id = existing_link.get("id")
    current_description = existing_link.get("description", "")
    
    # Create markdown link for aggregator
    aggregator_link = f"[{aggregator_name}]({new_aggregator_url})"
    
    # Check if this aggregator link already exists in description
    if aggregator_link in (current_description or ""):
        return False, "Aggregator link already exists"
    
    # Prepare updated description
    if current_description:
        # Add aggregator link at the end, separated by newlines
        updated_description = f"{current_description}\n\n**Discussion:** {aggregator_link}"
    else:
        updated_description = f"**Discussion:** {aggregator_link}"
    
    # Update the link - use correct OpenAPI format
    collection_data = existing_link.get("collection", {})
    update_data = {
        "id": link_id,
        "name": existing_link.get("name"),
        "url": existing_link.get("url"),
        "description": updated_description,
        "collection": {
            "id": existing_link.get("collectionId"),
            "ownerId": collection_data.get("ownerId")
        }
    }
    
    # Add tags - always include tags array (required by API)
    existing_tags = existing_link.get("tags", [])
    update_data["tags"] = existing_tags  # Include even if empty
    
    try:
        resp = http.request('PUT', f"{API_BASE}/links/{link_id}", 
                           headers=HEADERS, 
                           body=json.dumps(update_data).encode('utf-8'),
                           timeout=10)
        
        if resp.status == 200:
            return True, f"Added {aggregator_name} link to description"
        else:
            return False, f"Update failed: HTTP {resp.status} - {resp.data.decode()[:100]}"
    except Exception as e:
        return False, f"Update error: {e}"

def create_or_update_link(entry):
    """Create new link or update existing one with aggregator info"""
    external_url, aggregator_url, aggregator_name = extract_aggregator_info(entry)
    
    # Use externalURL as primary, fall back to url
    primary_url = external_url or aggregator_url
    if not primary_url:
        return None, "No URL found"
    
    # Search for existing link
    existing_link = search_existing_link(primary_url)
    
    if existing_link:
        # Link exists - check if we should update it
        link_id = existing_link.get("id")
        
        if aggregator_url and aggregator_name and aggregator_url != primary_url:
            # We have aggregator info to potentially add
            success, message = update_link_description(
                existing_link, aggregator_url, aggregator_name
            )
            if success:
                return link_id, f"Updated: {message}"
            else:
                return link_id, f"Exists: {message}"
        else:
            return link_id, "Exists: No new aggregator info to add"
    
    # Link doesn't exist - create new one in RSS collection
    data = {
        "name": entry.get("title") or primary_url,
        "url": primary_url,
        "description": entry.get("content") or "",
        "collection": RSS_COLLECTION_ID,  # Create new RSS links in RSS collection
    }
    
    # Add aggregator info to description if available
    if aggregator_url and aggregator_name and aggregator_url != primary_url:
        if data["description"]:
            data["description"] += f"\n\n**Discussion:** [{aggregator_name}]({aggregator_url})"
        else:
            data["description"] = f"**Discussion:** [{aggregator_name}]({aggregator_url})"
    
    # Add tags
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
                return link_id, "Created"
            except (json.JSONDecodeError, KeyError) as e:
                return None, f"Response parsing error: {e}"
        elif resp.status == 400 and b"already exists" in resp.data:
            return None, "Duplicate"
        elif resp.status == 409 and b"already exists" in resp.data:
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

def wait_for_archive_with_progress(link_id, pbar):
    """Enhanced archive waiting with progress reporting"""
    start = time.time()
    attempts = 0
    max_attempts = ARCHIVE_TIMEOUT_SECS // ARCHIVE_POLL_SECS
    
    while time.time() - start < ARCHIVE_TIMEOUT_SECS:
        attempts += 1
        elapsed = time.time() - start
        
        # Update progress bar with archive status
        pbar.set_description(f"Archiving link {link_id} ({attempts}/{max_attempts}, {elapsed:.1f}s)")
        
        try:
            resp = http.request('GET', f"{API_BASE}/archives/{link_id}", 
                               headers=HEADERS, timeout=10)
            if resp.status == 200:
                pbar.set_description(f"✅ Archived link {link_id} in {elapsed:.1f}s")
                time.sleep(0.5)  # Brief pause to show success message
                return True
            elif resp.status == 404:
                time.sleep(ARCHIVE_POLL_SECS)
            else:
                pbar.set_description(f"❌ Archive failed for link {link_id} (HTTP {resp.status})")
                return False
        except Exception as e:
            pbar.set_description(f"⚠️  Archive check error for link {link_id}: {str(e)[:30]}")
            time.sleep(ARCHIVE_POLL_SECS)
    
    pbar.set_description(f"⏰ Archive timeout for link {link_id} after {ARCHIVE_TIMEOUT_SECS}s")
    return False

def main():
    argp = argparse.ArgumentParser(description="Import links to Linkwarden via API")
    argp.add_argument("--days", type=int, default=6, help="Only include entries from the last N days (by dateArrived or datePublished, -1 for all)")
    argp.add_argument("--dry-run", action="store_true", help="Count and preview entries without importing")
    args = argp.parse_args()
    
    # Test API connection first (skip for dry-run)
    if not args.dry_run:
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
        print(f"📅 Filtering entries from last {args.days} days (since {cutoff_date.strftime('%Y-%m-%d %H:%M:%S')} UTC)", file=sys.stderr)

    entries = []
    total_processed = 0
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        total_processed += 1
        try:
            entry = json.loads(line)
            timestamp = entry.get("dateArrived") or entry.get("datePublished")
            if cutoff_timestamp is not None:
                if timestamp is None or float(timestamp) < cutoff_timestamp:
                    continue
            entries.append(entry)
        except Exception as e:
            print(f"Warning: Skipping invalid line {total_processed}: {e}", file=sys.stderr)

    # Sort for deterministic order
    entries.sort(key=lambda x: x.get("dateArrived") or x.get("datePublished") or 0)
    
    print(f"📊 Found {len(entries)} entries to import (from {total_processed} total RSS entries)", file=sys.stderr)
    
    if args.dry_run:
        print("🔍 DRY RUN MODE - Preview of entries to be imported:", file=sys.stderr)
        for i, entry in enumerate(entries[:10], 1):  # Show first 10
            title = entry.get("title", "No title")[:60]
            url = entry.get("externalURL") or entry.get("url", "No URL")
            timestamp = entry.get("dateArrived") or entry.get("datePublished")
            date_str = datetime.fromtimestamp(timestamp, timezone.utc).strftime('%Y-%m-%d') if timestamp else "No date"
            print(f"  {i:3d}. [{date_str}] {title} - {url}", file=sys.stderr)
        
        if len(entries) > 10:
            print(f"  ... and {len(entries) - 10} more entries", file=sys.stderr)
        
        estimated_time = (len(entries) / RATE_LIMIT) * PAUSE_SECS + len(entries) * 2  # rough estimate
        print(f"⏱️  Estimated import time: ~{estimated_time/60:.1f} minutes", file=sys.stderr)
        print(f"🔄 Rate limiting: {RATE_LIMIT} links per batch, {PAUSE_SECS}s pause between batches", file=sys.stderr)
        return

    if len(entries) == 0:
        print("ℹ️  No entries to import", file=sys.stderr)
        return
    
    # Warn for large datasets
    if len(entries) > 50:
        print(f"⚠️  Large dataset detected ({len(entries)} entries). This may take a while.", file=sys.stderr)
        print(f"⏱️  Estimated time: ~{((len(entries) / RATE_LIMIT) * PAUSE_SECS + len(entries) * 2)/60:.1f} minutes", file=sys.stderr)

    stats = {"created": 0, "updated": 0, "failed": 0, "archived": 0, "duplicates": 0, "exists": 0}
    details = []
    
    with tqdm(total=len(entries), file=sys.stderr, desc="Importing links", 
              bar_format='{l_bar}{bar}| {n_fmt}/{total_fmt} [{elapsed}<{remaining}, {rate_fmt}]') as pbar:
        
        for i, entry in enumerate(entries):
            # Update progress bar description with current batch info
            batch_num = (i // RATE_LIMIT) + 1
            total_batches = (len(entries) + RATE_LIMIT - 1) // RATE_LIMIT
            pbar.set_description(f"Batch {batch_num}/{total_batches}")
            
            link_id, result = create_or_update_link(entry)
            
            if link_id and result:
                if result.startswith("Created"):
                    stats["created"] += 1
                    
                    # Enhanced archive waiting with progress
                    pbar.set_description(f"Batch {batch_num}/{total_batches} - Archiving link {link_id}")
                    archived = wait_for_archive_with_progress(link_id, pbar)
                    if archived:
                        stats["archived"] += 1
                    
                    details.append({
                        "title": entry.get("title"), 
                        "url": entry.get("externalURL") or entry.get("url"), 
                        "id": link_id, 
                        "archived": archived,
                        "action": "created"
                    })
                elif result.startswith("Updated"):
                    stats["updated"] += 1
                    details.append({
                        "title": entry.get("title"), 
                        "url": entry.get("externalURL") or entry.get("url"), 
                        "id": link_id, 
                        "archived": False,  # Don't re-archive updated links
                        "action": "updated",
                        "details": result
                    })
                elif result.startswith("Exists"):
                    stats["exists"] += 1
                    details.append({
                        "title": entry.get("title"), 
                        "url": entry.get("externalURL") or entry.get("url"), 
                        "id": link_id, 
                        "archived": False,
                        "action": "exists",
                        "details": result
                    })
            elif result == "Duplicate":
                stats["duplicates"] += 1
                details.append({
                    "title": entry.get("title"), 
                    "url": entry.get("externalURL") or entry.get("url"), 
                    "error": "Duplicate"
                })
            else:
                stats["failed"] += 1
                details.append({
                    "title": entry.get("title"), 
                    "url": entry.get("externalURL") or entry.get("url"), 
                    "error": result
                })
            
            pbar.update(1)
            
            # Rate limiting with progress indication
            if (i + 1) % RATE_LIMIT == 0 and (i + 1) < len(entries):
                pbar.set_description(f"Rate limiting pause ({PAUSE_SECS}s)")
                time.sleep(PAUSE_SECS)

    # Print summary
    print(f"\n✅ Import complete! Processed {len(entries)} entries", file=sys.stderr)
    print(json.dumps(stats, indent=2), file=sys.stderr)
    for d in details:
        print(json.dumps(d, ensure_ascii=False), file=sys.stderr)

if __name__ == "__main__":
    main()
