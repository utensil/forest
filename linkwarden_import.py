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

# ANSI color codes for terminal output
class Colors:
    GREEN = '\033[92m'
    BLUE = '\033[94m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    PURPLE = '\033[95m'
    CYAN = '\033[96m'
    WHITE = '\033[97m'
    BOLD = '\033[1m'
    END = '\033[0m'

def format_link_detail(entry, link_id=None, action="", details="", archived=False, error=None):
    """Format link details with discussion action emojis for each platform"""
    title = (entry.get("title") or "No title")[:60]
    url = entry.get("externalURL") or entry.get("url", "No URL")
    
    # Create title: url format with bold title
    main_link = f"{Colors.BOLD}{title}{Colors.END}: {url}"
    
    # Action emoji and color mapping
    action_formats = {
        "created": f"{Colors.GREEN}✨ CREATED{Colors.END}",
        "updated": f"{Colors.BLUE}🔄 UPDATED{Colors.END}",
        "exists": f"{Colors.YELLOW}📋 EXISTS{Colors.END}",
        "duplicate": f"{Colors.PURPLE}🔗 DUPLICATE{Colors.END}",
        "failed": f"{Colors.RED}❌ FAILED{Colors.END}"
    }
    
    # Get formatted action
    action_display = action_formats.get(action, f"{Colors.WHITE}❓ {action.upper()}{Colors.END}")
    
    # Build the main line
    if error:
        return f"{action_display} {main_link} | {Colors.RED}{error}{Colors.END}"
    
    # Build details string
    detail_parts = []
    if archived:
        detail_parts.append(f"{Colors.GREEN}📦 Archived{Colors.END}")
    
    # Extract and format discussion links with individual action emojis
    discussion_links = []
    if details:
        # Handle collection updates
        if "Moved to" in details and "collection" in details:
            collection_name = details.split("Moved to ")[1].split(" collection")[0]
            detail_parts.append(f"📁 {Colors.BLUE}→{Colors.END} {collection_name}")
        
        # Handle newly added discussion links
        if "Added Lobsters link" in details:
            discussion_links.append(f"💬 {Colors.GREEN}✨{Colors.END} [Lobsters](https://lobste.rs/...)")
        elif "Added Hacker News link" in details:
            discussion_links.append(f"💬 {Colors.GREEN}✨{Colors.END} [Hacker News](https://news.ycombinator.com/...)")
        elif "Added Reddit link" in details:
            discussion_links.append(f"💬 {Colors.GREEN}✨{Colors.END} [Reddit](https://reddit.com/...)")
        elif details.startswith("Updated:") and "link" in details:
            # Extract the aggregator name from the details
            clean_details = details.replace("Updated: Added ", "").replace(" link to description", "")
            discussion_links.append(f"💬 {Colors.GREEN}✨{Colors.END} {clean_details}")
        
        # Handle existing discussion links
        elif "Aggregator link already exists" in details:
            # For existing links, we know they have discussion but don't know which platform
            # We could enhance this by checking the original entry's aggregator URL
            aggregator_url = entry.get("url", "")
            if "lobste.rs" in aggregator_url:
                discussion_links.append(f"💬 {Colors.YELLOW}📋{Colors.END} [Lobsters]({aggregator_url})")
            elif "news.ycombinator.com" in aggregator_url:
                discussion_links.append(f"💬 {Colors.YELLOW}📋{Colors.END} [Hacker News]({aggregator_url})")
            elif "reddit.com" in aggregator_url:
                discussion_links.append(f"💬 {Colors.YELLOW}📋{Colors.END} [Reddit]({aggregator_url})")
            else:
                discussion_links.append(f"💬 {Colors.YELLOW}📋{Colors.END} Available")
        
        # Handle collection status messages
        elif "Already in" in details and "collection" in details:
            collection_name = details.split("Already in ")[1].split(" collection")[0]
            detail_parts.append(f"📁 {Colors.YELLOW}✓{Colors.END} {collection_name}")
        
        # Handle generic details that don't match specific patterns
        elif details and not any(pattern in details for pattern in ["Added", "Aggregator", "Already in", "Moved to", "No updates needed"]):
            detail_parts.append(f"{Colors.CYAN}ℹ️{Colors.END} {details}")
    
    
    # Add discussion links to detail parts
    detail_parts.extend(discussion_links)
    
    detail_str = " | ".join(detail_parts) if detail_parts else ""
    
    return f"{action_display} {main_link}" + (f" | {detail_str}" if detail_str else "")

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

def get_or_create_collection(collection_name: str):
    """Get collection ID by name, creating it if it doesn't exist"""
    if not collection_name:
        collection_name = "rss"  # Default fallback
    
    try:
        # First, try to find existing collection
        resp = http.request('GET', f"{API_BASE}/collections", 
                           headers=HEADERS, timeout=10)
        
        if resp.status == 200:
            data = json.loads(resp.data.decode())
            collections = data.get("response", [])
            
            # Look for existing collection by name
            for collection in collections:
                if collection.get("name", "").lower() == collection_name.lower():
                    return collection.get("id"), f"Found existing {collection_name} collection (ID: {collection.get('id')})"
            
            # Collection doesn't exist, create it
            create_data = {
                "name": collection_name,
                "description": f"{collection_name} imported links",
                "color": "#22c55e"  # Green color
            }
            
            resp = http.request('POST', f"{API_BASE}/collections", 
                               headers=HEADERS, 
                               body=json.dumps(create_data).encode('utf-8'),
                               timeout=10)
            
            if resp.status == 200:
                data = json.loads(resp.data.decode())
                collection_id = data.get("response", {}).get("id")
                return collection_id, f"Created new {collection_name} collection (ID: {collection_id})"
            else:
                return None, f"Failed to create {collection_name} collection: HTTP {resp.status}"
        else:
            return None, f"Failed to fetch collections: HTTP {resp.status}"
    except Exception as e:
        return None, f"Error managing {collection_name} collection: {e}"

# Global variable for collection cache
COLLECTION_CACHE = {}

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
    """Search for existing link by URL using the proper search API"""
    if not external_url:
        return None
    
    try:
        # Use the proper /api/v1/search endpoint with searchQueryString
        import urllib.parse
        encoded_url = urllib.parse.quote(external_url, safe='')
        
        # Search using the URL as the search query string
        resp = http.request('GET', f"{API_BASE}/search?searchQueryString={encoded_url}", 
                           headers=HEADERS, timeout=15)
        
        if resp.status == 200:
            try:
                data = json.loads(resp.data.decode())
                # The search API returns data.links instead of response
                links = data.get("data", {}).get("links", [])
                
                # Look for exact URL match in search results
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

def update_link_fields(existing_link, entry, target_collection_id, collection_name, force_fields=None):
    """Update link fields following links.md conflict resolution rules"""
    if force_fields is None:
        force_fields = set()
    
    link_id = existing_link.get("id")
    collection_data = existing_link.get("collection", {})
    updates = []
    
    # Prepare update data with existing values
    update_data = {
        "id": link_id,
        "name": existing_link.get("name"),
        "url": existing_link.get("url"),
        "description": existing_link.get("description", ""),
        "collection": {
            "id": existing_link.get("collectionId"),
            "ownerId": collection_data.get("ownerId")
        },
        "tags": existing_link.get("tags", [])
    }
    
    if existing_link.get("textContent"):
        update_data["textContent"] = existing_link.get("textContent")
    
    # Check collection update
    if existing_link.get("collectionId") != target_collection_id:
        update_data["collection"]["id"] = target_collection_id
        updates.append(f"Moved to {collection_name} collection")
    
    # Check title update (preserve existing unless forced)
    new_title = entry.get("title", "")
    current_title = existing_link.get("name", "")
    if not current_title and new_title:
        update_data["name"] = new_title
        updates.append(f"Added missing title '{new_title}'")
    elif current_title and new_title and current_title != new_title:
        if "title" in force_fields:
            update_data["name"] = new_title
            updates.append(f"Force updated title to '{new_title}'")
        else:
            updates.append(f"Title conflict: '{current_title}' vs '{new_title}' (use --force title)")
    
    # Check aggregator updates (merge approach)
    external_url, aggregator_url, aggregator_name = extract_aggregator_info(entry)
    if aggregator_url and aggregator_name and aggregator_url != (external_url or aggregator_url):
        current_description = update_data["description"]
        aggregator_link = f"[{aggregator_name}]({aggregator_url})"
        
        if aggregator_link not in (current_description or ""):
            if current_description:
                update_data["description"] = f"{current_description}\n\n**Discussion:** {aggregator_link}"
            else:
                update_data["description"] = f"**Discussion:** {aggregator_link}"
            updates.append(f"Added {aggregator_name} link")
    
    # Apply updates if any changes needed
    if updates:
        # Check if we have actual data changes vs just warnings
        has_data_changes = any(not msg.startswith("Title conflict:") for msg in updates)
        
        if has_data_changes:
            try:
                resp = http.request('PUT', f"{API_BASE}/links/{link_id}", 
                                   headers=HEADERS, 
                                   body=json.dumps(update_data).encode('utf-8'),
                                   timeout=10)
                
                if resp.status == 200:
                    # Try to update timestamp after other updates
                    timestamp = entry.get("datePublished")
                    if timestamp:
                        ts_success, ts_msg = update_link_timestamp(link_id, timestamp)
                        if ts_success:
                            updates.append(ts_msg)
                    
                    return True, " + ".join(updates)
                else:
                    return False, f"Update failed: HTTP {resp.status}"
            except Exception as e:
                return False, f"Update error: {e}"
        else:
            # Only warnings, no actual updates - but try timestamp update
            timestamp = entry.get("datePublished")
            if timestamp:
                ts_success, ts_msg = update_link_timestamp(link_id, timestamp)
                if ts_success:
                    return True, ts_msg
            return False, " + ".join(updates)
    
    # No updates needed, but try timestamp update
    timestamp = entry.get("datePublished")
    if timestamp:
        ts_success, ts_msg = update_link_timestamp(link_id, timestamp)
        if ts_success:
            return True, ts_msg
    
    return False, "No updates needed"

def update_link_timestamp(link_id, timestamp):
    """Try to update link timestamp after creation"""
    if not timestamp:
        return False, "No timestamp provided"
    
    try:
        # Convert Unix timestamp to ISO string
        import datetime
        iso_date = datetime.datetime.fromtimestamp(float(timestamp), datetime.timezone.utc).isoformat()
        
        # Try updating with just the ID and importDate field
        update_data = {
            "id": link_id,
            "importDate": iso_date
        }
        
        print(f"DEBUG: Attempting timestamp update for link {link_id} with {iso_date}", file=sys.stderr)
        
        resp = http.request('PUT', f"{API_BASE}/links/{link_id}", 
                           headers=HEADERS, 
                           body=json.dumps(update_data).encode('utf-8'),
                           timeout=10)
        
        print(f"DEBUG: Timestamp update response: {resp.status} {resp.data.decode()[:200]}", file=sys.stderr)
        
        if resp.status == 200:
            return True, f"Updated timestamp to {iso_date[:10]}"
        else:
            return False, f"Timestamp update failed: HTTP {resp.status}"
    except Exception as e:
        return False, f"Timestamp update error: {e}"

def create_link_data(entry, collection_id):
    """Create link data structure for new links"""
    external_url, aggregator_url, aggregator_name = extract_aggregator_info(entry)
    primary_url = external_url or aggregator_url
    
    data = {
        "name": entry.get("title") or primary_url,
        "url": primary_url,
        "description": entry.get("content") or "",
        "collection": {"id": collection_id},
    }
    
    # Add textContent if available
    if entry.get("textContent"):
        data["textContent"] = entry.get("textContent")
    
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
    
    return data
    """Create link data structure for new links"""
    external_url, aggregator_url, aggregator_name = extract_aggregator_info(entry)
    primary_url = external_url or aggregator_url
    
    data = {
        "name": entry.get("title") or primary_url,
        "url": primary_url,
        "description": entry.get("content") or "",
        "collection": {"id": collection_id},
    }
    
    # Add textContent if available
    if entry.get("textContent"):
        data["textContent"] = entry.get("textContent")
    
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
    
    return data

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

def create_or_update_link(entry, force_fields=None):
    """Create new link or update existing one with aggregator info"""
    if force_fields is None:
        force_fields = set()
        
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
        
        # Get target collection for this entry
        collection_name = entry.get("folder", "rss")
        if collection_name not in COLLECTION_CACHE:
            collection_id, collection_msg = get_or_create_collection(collection_name)
            if collection_id is None:
                return None, f"Collection error: {collection_msg}"
            COLLECTION_CACHE[collection_name] = collection_id
            print(f"✓ {collection_msg}", file=sys.stderr)
        
        target_collection_id = COLLECTION_CACHE[collection_name]
        
        # Update all fields as needed
        success, message = update_link_fields(existing_link, entry, target_collection_id, collection_name, force_fields)
        if success:
            return link_id, f"Updated: {message}"
        else:
            return link_id, f"Exists: {message}"
    
    # Get collection for new link
    collection_name = entry.get("folder", "rss")
    if collection_name not in COLLECTION_CACHE:
        collection_id, collection_msg = get_or_create_collection(collection_name)
        if collection_id is None:
            return None, f"Collection error: {collection_msg}"
        COLLECTION_CACHE[collection_name] = collection_id
        print(f"✓ {collection_msg}", file=sys.stderr)
    
    collection_id = COLLECTION_CACHE[collection_name]
    
    # Create new link
    data = create_link_data(entry, collection_id)
    
    try:
        resp = http.request('POST', f"{API_BASE}/links", 
                           headers=HEADERS, 
                           body=json.dumps(data).encode('utf-8'),
                           timeout=10)
        
        if resp.status == 200:
            try:
                response_data = json.loads(resp.data.decode())
                link_id = response_data["response"]["id"]
                
                # Try to update timestamp after creation
                timestamp = entry.get("datePublished")
                if timestamp:
                    success, msg = update_link_timestamp(link_id, timestamp)
                    if success:
                        return link_id, f"Created + {msg}"
                    # If timestamp update fails, still return success for the creation
                
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
    argp.add_argument("--force", action="append", choices=["title"], help="Force update specified fields even if they differ (can be used multiple times)")
    args = argp.parse_args()
    
    # Convert force list to set for easier checking
    if args.force:
        args.force = set(args.force)
    else:
        args.force = set()
    
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
        print(f"🔄 Smart rate limiting: {RATE_LIMIT} created links per batch, {PAUSE_SECS}s pause between batches", file=sys.stderr)
        print(f"ℹ️  Note: Only new link creation triggers rate limiting (existing links are processed quickly)", file=sys.stderr)
        return

    if len(entries) == 0:
        print("ℹ️  No entries to import", file=sys.stderr)
        return
    
    # Warn for large datasets
    if len(entries) > 50:
        print(f"⚠️  Large dataset detected ({len(entries)} entries). This may take a while.", file=sys.stderr)
        print(f"⏱️  Estimated time: ~{((len(entries) / RATE_LIMIT) * PAUSE_SECS + len(entries) * 2)/60:.1f} minutes", file=sys.stderr)
        print(f"ℹ️  Note: Time depends on how many new links need to be created (existing links are fast)", file=sys.stderr)

    stats = {"created": 0, "updated": 0, "failed": 0, "archived": 0, "duplicates": 0, "exists": 0}
    details = []
    created_count = 0  # Track only resource-intensive operations for rate limiting
    
    with tqdm(total=len(entries), file=sys.stderr, desc="Importing links", 
              bar_format='{l_bar}{bar}| {n_fmt}/{total_fmt} [{elapsed}<{remaining}, {rate_fmt}]') as pbar:
        
        for i, entry in enumerate(entries):
            # Update progress bar description with current batch info
            batch_num = (created_count // RATE_LIMIT) + 1
            pbar.set_description(f"Processing ({created_count} created)")
            
            # Extract aggregator info for display
            external_url, aggregator_url, aggregator_name = extract_aggregator_info(entry)
            
            link_id, result = create_or_update_link(entry, args.force)
            
            if link_id and result:
                if result.startswith("Created"):
                    stats["created"] += 1
                    created_count += 1  # Count created links for rate limiting
                    
                    # Enhanced archive waiting with progress
                    pbar.set_description(f"Processing ({created_count} created) - Archiving link {link_id}")
                    archived = wait_for_archive_with_progress(link_id, pbar)
                    if archived:
                        stats["archived"] += 1
                    
                    details.append({
                        "title": entry.get("title"), 
                        "url": entry.get("externalURL") or entry.get("url"), 
                        "aggregator_url": aggregator_url,
                        "id": link_id, 
                        "archived": archived,
                        "action": "created"
                    })
                elif result.startswith("Updated"):
                    stats["updated"] += 1
                    # Updates might also be resource-intensive if they trigger re-archiving
                    # But typically they're just description updates, so don't count for rate limiting
                    details.append({
                        "title": entry.get("title"), 
                        "url": entry.get("externalURL") or entry.get("url"), 
                        "aggregator_url": aggregator_url,
                        "id": link_id, 
                        "archived": False,  # Don't re-archive updated links
                        "action": "updated",
                        "details": result
                    })
                elif result.startswith("Exists"):
                    stats["exists"] += 1
                    # Existing links don't consume resources, no rate limiting needed
                    details.append({
                        "title": entry.get("title"), 
                        "url": entry.get("externalURL") or entry.get("url"), 
                        "aggregator_url": aggregator_url,
                        "id": link_id, 
                        "archived": False,
                        "action": "exists",
                        "details": result
                    })
            elif result == "Duplicate":
                stats["duplicates"] += 1
                # Duplicates don't consume resources, no rate limiting needed
                details.append({
                    "title": entry.get("title"), 
                    "url": entry.get("externalURL") or entry.get("url"), 
                    "aggregator_url": aggregator_url,
                    "error": "Duplicate"
                })
            else:
                stats["failed"] += 1
                details.append({
                    "title": entry.get("title"), 
                    "url": entry.get("externalURL") or entry.get("url"), 
                    "aggregator_url": aggregator_url,
                    "error": result
                })
            
            pbar.update(1)
            
            # Smart rate limiting: only pause after creating RATE_LIMIT new links
            if created_count > 0 and created_count % RATE_LIMIT == 0 and (i + 1) < len(entries):
                pbar.set_description(f"Rate limiting pause ({PAUSE_SECS}s) - {created_count} links created")
                time.sleep(PAUSE_SECS)

    # Print summary
    print(f"\n✅ Import complete! Processed {len(entries)} entries", file=sys.stderr)
    print(json.dumps(stats, indent=2), file=sys.stderr)
    
    # Print detailed results with colored markdown formatting
    print(f"\n{Colors.BOLD}📋 Detailed Results:{Colors.END}", file=sys.stderr)
    for detail in details:
        # Pass the full entry data including aggregator URL
        entry_data = {
            "title": detail.get("title"), 
            "externalURL": detail.get("url"),
            "url": detail.get("aggregator_url", "")  # Include aggregator URL for platform detection
        }
        formatted_line = format_link_detail(
            entry_data,
            action=detail.get("action", "failed" if detail.get("error") else "unknown"),
            details=detail.get("details", ""),
            archived=detail.get("archived", False),
            error=detail.get("error")
        )
        print(formatted_line, file=sys.stderr)

if __name__ == "__main__":
    main()
