#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.11,<3.12"
# dependencies = ["urllib3>=2.0.0"]
# ///
"""
RSS CSV to Linkwarden Converter
===============================

Converts CSV export from RSS reader to Linkwarden import format.
Processes rich CSV data including notes, highlights, and extracts reference links.

Usage:
    ./rss2linkwarden.py input.csv | ./linkwarden_import.py --days -1

CSV Format Expected:
    id,title,note,excerpt,url,folder,tags,created,cover,highlights,favorite

Output: JSON lines compatible with linkwarden_import.py

AGENT-NOTE: CRITICAL FEATURES TO MAINTAIN
1. EXTRACT REFERENCE LINKS: Parse note field for URLs and create separate entries
2. RICH DESCRIPTION: Combine note + highlights with proper markdown formatting  
3. COLLECTION MAPPING: Map folder to Linkwarden collections
4. TAG PROCESSING: Parse comma/pipe separated tags + add reference tags
"""

import csv
import json
import sys
import re
import urllib.parse
from datetime import datetime
from typing import Dict, List, Optional, Tuple

def normalize_url(url: str) -> str:
    """Normalize URL for deduplication following links.md guidelines"""
    if not url:
        return ""
    
    try:
        parsed = urllib.parse.urlparse(url)
        return urllib.parse.urlunparse(urllib.parse.ParseResult(
            scheme=parsed.scheme.lower(),
            netloc=parsed.netloc.lower(),
            path=parsed.path.rstrip("/") or "/",
            params=parsed.params,
            query=parsed.query,      # Preserve as-is
            fragment=parsed.fragment # Preserve as-is
        ))
    except Exception:
        return url

def extract_reference_links(note: str) -> List[Tuple[str, str, str]]:
    """Extract URLs and markdown links from note, return (url, title, platform_tag)"""
    if not note:
        return []
    
    links = []
    
    # Process line by line
    for line in note.split('\n'):
        line = line.strip()
        if not line:
            continue
            
        # Check for markdown links [title](url)
        markdown_pattern = r'\[([^\]]+)\]\(([^)]+)\)'
        markdown_matches = re.findall(markdown_pattern, line)
        for title, url in markdown_matches:
            platform_tag = get_platform_tag(url)
            if platform_tag:
                links.append((url.strip(), title.strip(), platform_tag))
        
        # Check for plain URLs (not already captured in markdown)
        if not markdown_matches:
            # Simple URL detection
            url_pattern = r'https?://[^\s]+'
            url_matches = re.findall(url_pattern, line)
            for url in url_matches:
                platform_tag = get_platform_tag(url)
                if platform_tag:
                    links.append((url.strip(), "", platform_tag))
    
    return links

def get_platform_tag(url: str) -> str:
    """Get platform tag for reference links"""
    if not url:
        return ""
    
    url_lower = url.lower()
    if "news.ycombinator.com" in url_lower:
        return "re/hn"
    elif "lobste.rs" in url_lower:
        return "re/lb"  
    elif "reddit.com" in url_lower:
        return "re/rd"
    
    return ""

def format_description(note: str, highlights: str) -> str:
    """Format description combining note and highlights with markdown formatting"""
    parts = []
    
    if note and note.strip():
        parts.append(note.strip())
    
    if highlights and highlights.strip():
        # Format highlights as markdown quotes
        highlight_lines = []
        for line in highlights.split('\n'):
            line = line.strip()
            if line:
                highlight_lines.append(f"> {line}")
        
        if highlight_lines:
            parts.append('\n'.join(highlight_lines))
    
    return '\n\n'.join(parts)

def parse_tags(tags_str: str) -> List[str]:
    """Parse comma/pipe separated tags"""
    if not tags_str:
        return []
    
    # Handle both comma and pipe separators
    tags = []
    for separator in [',', '|']:
        if separator in tags_str:
            tags = [t.strip().strip('"') for t in tags_str.split(separator)]
            break
    else:
        # Single tag
        tags = [tags_str.strip().strip('"')]
    
    return [t for t in tags if t]

def convert_csv_to_linkwarden(csv_file: str) -> None:
    """Convert CSV file to Linkwarden JSON format"""
    try:
        with open(csv_file, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            
            for row in reader:
                # Main link entry
                main_entry = create_main_entry(row)
                if main_entry:
                    print(json.dumps(main_entry))
                    
                    # Extract and create reference links with same timestamp
                    note = row.get('note', '')
                    ref_links = extract_reference_links(note)
                    source_timestamp = main_entry.get('datePublished', 0.0)
                    
                    for ref_url, ref_title, platform_tag in ref_links:
                        ref_entry = create_reference_entry(
                            ref_url, ref_title, platform_tag, row.get('url', ''), source_timestamp
                        )
                        if ref_entry:
                            print(json.dumps(ref_entry))
                        
    except Exception as e:
        print(f"Error processing CSV: {e}", file=sys.stderr)
        sys.exit(1)

def convert_iso_to_timestamp(iso_string: str) -> float:
    """Convert ISO timestamp to Unix timestamp"""
    if not iso_string:
        return 0.0
    
    try:
        # Parse ISO format like "2025-08-28T01:57:10.020Z"
        dt = datetime.fromisoformat(iso_string.replace('Z', '+00:00'))
        return dt.timestamp()
    except Exception:
        return 0.0

def create_main_entry(row: Dict[str, str]) -> Optional[Dict]:
    """Create main Linkwarden entry from CSV row"""
    url = row.get('url', '').strip()
    title = row.get('title', '').strip()
    
    if not url:
        return None
    
    # Build description from note and highlights
    description = format_description(
        row.get('note', ''), 
        row.get('highlights', '')
    )
    
    # Parse tags
    tags = parse_tags(row.get('tags', ''))
    
    # Convert ISO timestamp to Unix timestamp
    timestamp = convert_iso_to_timestamp(row.get('created', ''))
    
    # Create entry
    entry = {
        'title': title or url,
        'url': url,
        'externalURL': url,  # For compatibility with existing import script
        'content': description,
        'textContent': row.get('excerpt', '').strip(),
        'tags': '|'.join(tags) if tags else '',
        'folder': row.get('folder', 'rss').strip(),
        'datePublished': timestamp,
        'dateArrived': timestamp,
        'uniqueID': row.get('id', ''),
    }
    
    return entry

def create_reference_entry(ref_url: str, ref_title: str, platform_tag: str, source_url: str, source_timestamp: float = 0.0) -> Optional[Dict]:
    """Create reference link entry"""
    if not ref_url:
        return None
    
    title = ref_title or ref_url
    description = f"from {source_url}" if source_url else ""
    
    entry = {
        'title': title,
        'url': ref_url,
        'externalURL': ref_url,
        'content': description,
        'textContent': '',
        'tags': platform_tag,
        'folder': 'discussions',  # Discussion links go to discussions collection
        'datePublished': source_timestamp,  # Use source timestamp
        'dateArrived': source_timestamp,    # Use source timestamp
        'uniqueID': f"ref_{hash(ref_url) % 1000000}",
    }
    
    return entry

def main():
    if len(sys.argv) != 2:
        print("Usage: ./rss2linkwarden.py input.csv", file=sys.stderr)
        print("Output: JSON lines for linkwarden_import.py", file=sys.stderr)
        sys.exit(1)
    
    csv_file = sys.argv[1]
    convert_csv_to_linkwarden(csv_file)

if __name__ == "__main__":
    main()
