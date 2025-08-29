#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.11,<3.12"
# dependencies = []
# ///

import argparse
import json
import re
import sys
import urllib.parse
from collections import defaultdict
from datetime import datetime, timedelta
import signal
import errno


def strip_ansi(text):
    ansi_escape = re.compile(r"\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])")
    return ansi_escape.sub("", text)


def generate_title_from_url(url):
    """Generate a title from URL for cases where title is missing"""
    # Match Mastodon-like URLs: https://mathstodon.xyz/@tao/114603605315214772
    mastodon_pattern = re.compile(r"https?://([^/]+)/@([^/]+)")
    mastodon_match = mastodon_pattern.match(url)

    if mastodon_match:
        domain = mastodon_match.group(1)
        username = mastodon_match.group(2)
        return f"{username}'s post on {domain}"

    # Default case - use domain name
    try:
        domain = re.match(r"https?://(?:www\.)?([^/]+)", url).group(1)
        return f"Post on {domain}"
    except (AttributeError, IndexError):
        return "Untitled post"


def clean_title(title):
    """Clean a title by replacing newlines and multiple spaces with a single space"""
    if not title:
        return ""
    # Replace newlines with spaces, then collapse multiple spaces into one
    return re.sub(r'\s+', ' ', title.replace('\n', ' ')).strip()


def get_primary_url(entry):
    """Extract the primary URL from an entry, preferring externalURL if available"""
    return entry.get("externalURL") or entry.get("url") or entry.get("uniqueID")


def normalize_url(url):
    """
    Normalize a URL for comparison without altering its content identifiers.
    Only normalizes scheme, hostname case, and trailing slashes.
    """
    if not url:
        return None

    try:
        parsed = urllib.parse.urlparse(url)

        # Normalize components that don't affect content
        normalized = urllib.parse.ParseResult(
            scheme=parsed.scheme.lower(),
            netloc=parsed.netloc.lower(),
            path=parsed.path.rstrip("/")
            or "/",  # Normalize empty paths to / and remove trailing /
            params=parsed.params,
            query=parsed.query,  # Preserve query string as is
            fragment=parsed.fragment,  # Preserve fragment as is
        )

        return urllib.parse.urlunparse(normalized)
    except Exception:
        return url  # Return original if parsing fails


def is_source_from(url, source):
    """Check if a URL is from a specific source"""
    if not url:
        return False

    if source == "lobste.rs":
        return "lobste.rs" in url
    elif source == "HN":
        return "news.ycombinator.com" in url or "ycombinator.com/item" in url

    return False


def extract_existing_urls_from_tree(tree_content):
    """Extract existing URLs from the tree file content"""
    # Match markdown links with various formats, including verbatim-wrapped URLs
    link_pattern = re.compile(r'(?:\[.*?\]|\\\verb>>>.*?>>>)\((.*?)\)')
    urls = set(link_pattern.findall(tree_content))
    
    # Normalize all extracted URLs for more accurate comparison
    normalized_urls = {normalize_url(url) for url in urls if url}
    return normalized_urls


def needs_verb_wrapping(text):
    """Check if text needs to be wrapped with \verb>>>| and >>>"""
    # Texts containing special characters like % need verb wrapping
    return "%" in text


def format_title_with_link(title, url):
    """Format a title with its link, handling special characters properly"""
    formatted_title = f"\\verb>>>|{title}>>>" if needs_verb_wrapping(title) else title
    formatted_url = format_url(url)
    return f"[{formatted_title}]({formatted_url})"


def format_url(url):
    """Format a URL, handling special characters properly"""
    if needs_verb_wrapping(url):
        return f"\\verb>>>|{url}>>>"
    return url


def process_rss_json(input_text, existing_urls=None, deduplicate=True, show_all_sources=False, days_filter=7):
    """Process JSON output from rss2linkwarden.py into Forester format"""
    if existing_urls is None:
        existing_urls = set()
        
    content_by_external_url = {}
    date_groups = defaultdict(list)
    debug_info = {
        "total_entries": 0,
        "entries_with_hn": 0,
        "entries_with_lobsters": 0,
        "entries_with_both": 0,
        "skipped_duplicates": 0,
    }

    # Calculate cutoff date if days_filter is specified
    cutoff_date = None
    if days_filter > 0:
        cutoff_date = datetime.now() - timedelta(days=days_filter)

    for line in input_text.strip().split('\n'):
        if not line.strip():
            continue
            
        try:
            entry = json.loads(line)
            debug_info["total_entries"] += 1
            
            # Get timestamp and check date filter
            timestamp = entry.get("datePublished", 0)
            if timestamp:
                entry_date = datetime.fromtimestamp(float(timestamp))
                if cutoff_date and entry_date < cutoff_date:
                    continue
                date = entry_date.strftime("%Y-%m-%d")
            else:
                date = datetime.now().strftime("%Y-%m-%d")
            
            # Get primary URL and normalize
            primary_url = entry.get("externalURL") or entry.get("url", "")
            if not primary_url:
                continue
                
            normalized_url = normalize_url(primary_url)
            
            # Skip if deduplicating and URL exists
            if deduplicate and normalized_url in existing_urls:
                debug_info["skipped_duplicates"] += 1
                continue
            
            # Get title and tags
            title = entry.get("title", "")
            if not title:
                title = generate_title_from_url(primary_url)
            else:
                title = clean_title(title)
            
            tags = entry.get("tags", "")
            content = entry.get("content", "")
            text_content = entry.get("textContent", "")
            
            # Check if this is a discussion link (re/hn, re/lb, re/rd tags)
            is_discussion = False
            discussion_platform = None
            source_url = None
            
            if tags and ("re/hn" in tags or "re/lb" in tags or "re/rd" in tags):
                is_discussion = True
                if "re/hn" in tags:
                    discussion_platform = "HN"
                elif "re/lb" in tags:
                    discussion_platform = "lobste.rs"
                elif "re/rd" in tags:
                    discussion_platform = "Reddit"
                
                # Extract source URL from content
                source_match = re.search(r'from (https?://[^\s]+)', content)
                if source_match:
                    source_url = source_match.group(1)
            
            if is_discussion and source_url:
                # This is a discussion link - attach it to the source URL
                source_normalized = normalize_url(source_url)
                
                # Find or create entry for source URL
                if source_normalized not in content_by_external_url:
                    # Create placeholder entry for source
                    content_by_external_url[source_normalized] = {
                        "timestamp": float(timestamp) if timestamp else 0,
                        "date": date,
                        "title": generate_title_from_url(source_url),
                        "primary_url": source_url,
                        "sources": {},
                        "tags": "",
                        "content": "",
                        "textContent": "",
                        "folder": "",
                    }
                
                # Add discussion link to sources
                content_by_external_url[source_normalized]["sources"][discussion_platform] = primary_url
                if discussion_platform == "HN":
                    debug_info["entries_with_hn"] += 1
                elif discussion_platform == "lobste.rs":
                    debug_info["entries_with_lobsters"] += 1
                    
            else:
                # This is a main content entry
                if normalized_url not in content_by_external_url:
                    content_by_external_url[normalized_url] = {
                        "timestamp": float(timestamp) if timestamp else 0,
                        "date": date,
                        "title": title,
                        "primary_url": primary_url,
                        "sources": {},
                        "tags": tags,
                        "content": content,
                        "textContent": text_content,
                        "folder": entry.get("folder", ""),
                    }
                elif float(timestamp) > content_by_external_url[normalized_url]["timestamp"]:
                    # Update with newer timestamp but preserve sources
                    existing_sources = content_by_external_url[normalized_url].get("sources", {})
                    content_by_external_url[normalized_url].update({
                        "timestamp": float(timestamp),
                        "date": date,
                        "title": title,
                        "primary_url": primary_url,
                        "tags": tags,
                        "content": content,
                        "textContent": text_content,
                    })
                    content_by_external_url[normalized_url]["sources"] = existing_sources
                    
        except (json.JSONDecodeError, ValueError):
            continue
    
    # Count entries with both sources
    for content_data in content_by_external_url.values():
        sources = content_data.get("sources", {})
        if "lobste.rs" in sources and "HN" in sources:
            debug_info["entries_with_both"] += 1
    
    # Format entries
    for normalized_url, content_data in content_by_external_url.items():
        date = content_data["date"]
        title = content_data["title"]
        primary_url = content_data["primary_url"]
        sources = content_data.get("sources", {})
        tags = content_data.get("tags", "")
        content = content_data.get("content", "")
        text_content = content_data.get("textContent", "")
        
        # Format main link with title
        formatted_title_link = format_title_with_link(title, primary_url)
        link_parts = [f"- {formatted_title_link}"]
        
        # Add discussion links
        if "HN" in sources:
            hn_url = format_url(sources["HN"])
            link_parts.append(f"[On HN]({hn_url})")
        if "lobste.rs" in sources:
            lb_url = format_url(sources["lobste.rs"])
            link_parts.append(f"[On lobste.rs]({lb_url})")
        
        # Add tags
        if tags:
            tag_list = [t.strip() for t in tags.replace("|", ",").split(",") if t.strip()]
            if tag_list:
                tag_str = " ".join(f"#{tag}" for tag in tag_list)
                link_parts.append(tag_str)
        
        # Join main line
        main_line = " ".join(link_parts)
        
        # Build full entry with notes and highlights
        entry_lines = [main_line]
        
        # Add related URLs from content (extract URLs that aren't the main discussion links)
        content_urls = re.findall(r'https?://[^\s\)]+', content)
        related_urls = []
        for url in content_urls:
            if url != primary_url and url not in sources.values() and not url.startswith('from '):
                related_urls.append(url)
        
        for related_url in related_urls[:3]:  # Limit to 3 related URLs
            entry_lines.append(f"  - {related_url}")
        
        # Add highlights/quotes from textContent
        if text_content and text_content.strip():
            entry_lines.append("")  # Empty line before quote
            # Format as blockquote
            for line in text_content.strip().split('\n'):
                if line.strip():
                    entry_lines.append(f"  > {line.strip()}")
            entry_lines.append("")  # Empty line after quote
        
        # Add other notes from content (non-URL parts, excluding "from" references and textContent)
        content_without_urls = re.sub(r'https?://[^\s\)]+', '', content).strip()
        content_without_urls = re.sub(r'from\s*$', '', content_without_urls).strip()
        
        # Remove textContent from notes if it exists in content
        if text_content and text_content.strip():
            content_without_urls = content_without_urls.replace(text_content.strip(), '').strip()
        
        if content_without_urls and len(content_without_urls) > 5:  # Ignore very short fragments
            # Split into bullet points on double newlines
            notes = content_without_urls.split('\n\n')
            for note in notes:
                note = note.strip()
                if note and not note.startswith('from') and len(note) > 5:
                    entry_lines.append(f"  - {note}")
        
        # Join all lines for this entry
        full_entry = '\n'.join(entry_lines)
        date_groups[date].append(full_entry)
    
    # Generate debug comment
    debug_comment = [
        "\\comment{",
        f"Total entries processed: {debug_info['total_entries']}",
        f"Entries with HN links: {debug_info['entries_with_hn']}",
        f"Entries with lobste.rs links: {debug_info['entries_with_lobsters']}",
        f"Entries with both links: {debug_info['entries_with_both']}",
        f"Skipped duplicates: {debug_info['skipped_duplicates']}",
        "}",
    ]
    
    # Generate output
    output = []
    output.extend(debug_comment)
    output.append("")
    
    for date in sorted(date_groups.keys(), reverse=True):
        if not date_groups[date]:
            continue
        output.append(f"\\subtree[{date}]{{\\mdnote{{{date}}}{{")
        output.extend(sorted(date_groups[date]))
        output.append("}}")
        output.append("")
    
    return "\n".join(output)

def process_stars(input_text, existing_urls=None, deduplicate=True, show_all_sources=False, days_filter=7):
    # Initialize set of existing URLs if provided
    if existing_urls is None:
        existing_urls = set()
    
    # Calculate cutoff date for filtering if days_filter is not -1
    cutoff_timestamp = None
    if days_filter != -1:
        cutoff_date = datetime.now() - timedelta(days=days_filter)
        cutoff_timestamp = cutoff_date.timestamp()
    
    # Group by date
    date_groups = defaultdict(list)

    # Track content by normalized external URLs
    content_by_external_url = {}

    # Debug info to help understand input
    debug_info = {
        "total_entries": 0,
        "entries_with_hn": 0,
        "entries_with_lobsters": 0,
        "entries_with_both": 0,
        "skipped_duplicates": 0,
    }

    # Split input into JSON objects and process each one
    clean_input = strip_ansi(input_text)

    # Skip any lines starting with "Reading" or containing "dependencies"
    content_lines = []
    capturing = False
    for line in clean_input.split("\n"):
        if line.startswith("Reading") or "dependencies" in line:
            continue
        if line.strip().startswith("{"):
            capturing = True
            content_lines = [line]
        elif capturing and line.strip():
            content_lines.append(line)
            if line.strip() == "}":
                try:
                    entry = json.loads("\n".join(content_lines))
                    debug_info["total_entries"] += 1

                    # Convert timestamps to date, using dateArrived as fallback
                    timestamp = entry.get("datePublished") or entry.get("dateArrived")
                    if timestamp is None:
                        continue  # Skip if no timestamp available

                    # Filter by days if specified
                    if cutoff_timestamp is not None and timestamp < cutoff_timestamp:
                        continue  # Skip entries older than the cutoff

                    date = datetime.fromtimestamp(timestamp).strftime("%Y-%m-%d")

                    # Get primary URL (preferring external URL, then url, then uniqueID)
                    primary_url = get_primary_url(entry)
                    if not primary_url:  # Skip if no URL available
                        continue

                    # For deduplication, normalize the URL
                    normalized_url = normalize_url(primary_url)
                    if not normalized_url:
                        continue

                    # Check if URL already exists in the tree file and skip if deduplication is enabled
                    if deduplicate and normalized_url in existing_urls:
                        debug_info["skipped_duplicates"] += 1
                        continue

                    # Handle null title or empty title
                    title = entry.get("title")
                    if not title:  # If title is None or empty string
                        title = generate_title_from_url(primary_url)
                    else:
                        # Clean the title by replacing newlines with spaces
                        title = clean_title(title)

                    # Check if we've seen this content before
                    if normalized_url not in content_by_external_url:
                        content_by_external_url[normalized_url] = {
                            "timestamp": timestamp,
                            "date": date,
                            "title": title,
                            "primary_url": primary_url,
                            "sources": {},
                        }
                    elif timestamp > content_by_external_url[normalized_url]["timestamp"]:
                        # Update with newer timestamp and title
                        content_by_external_url[normalized_url]["timestamp"] = timestamp
                        content_by_external_url[normalized_url]["date"] = date
                        content_by_external_url[normalized_url]["title"] = title
                        content_by_external_url[normalized_url][
                            "primary_url"
                        ] = primary_url

                    # Make sure sources dict exists
                    if "sources" not in content_by_external_url[normalized_url]:
                        content_by_external_url[normalized_url]["sources"] = {}

                    # Record the source information regardless of timestamp
                    # Check all possible URL fields for source detection
                    sources_to_check = [entry.get("url"), entry.get("uniqueID"), entry.get("externalURL")]

                    for url in sources_to_check:
                        if url:
                            if is_source_from(url, "lobste.rs"):
                                content_by_external_url[normalized_url]["sources"][
                                    "lobste.rs"
                                ] = url
                                debug_info["entries_with_lobsters"] += 1
                            elif is_source_from(url, "HN"):
                                content_by_external_url[normalized_url]["sources"][
                                    "HN"
                                ] = url
                                debug_info["entries_with_hn"] += 1

                except json.JSONDecodeError:
                    continue  # Skip invalid JSON
                finally:
                    capturing = False  # Reset capturing state

    # Count entries that have both HN and lobste.rs links
    for normalized_url, content_data in content_by_external_url.items():
        sources = content_data.get("sources", {})
        if "lobste.rs" in sources and "HN" in sources:
            debug_info["entries_with_both"] += 1

    # Add debug info as a comment at the top of the output
    debug_comment = [
        "\\comment{",
        f"Total entries processed: {debug_info['total_entries']}",
        f"Entries with HN links: {debug_info['entries_with_hn']}",
        f"Entries with lobste.rs links: {debug_info['entries_with_lobsters']}",
        f"Entries with both links: {debug_info['entries_with_both']}",
        f"Skipped duplicates: {debug_info['skipped_duplicates']}",
        "}",
    ]

    # Process unique entries and format them
    for normalized_url, content_data in content_by_external_url.items():
        date = content_data["date"]
        title = content_data["title"]
        primary_url = content_data["primary_url"]

        # Format title with special character handling
        formatted_title_link = format_title_with_link(title, primary_url)

        # Start building the link with the primary content - CHANGED: removed "read " from here
        link_parts = [f"- {formatted_title_link}"]

        # Add source references - show when show_all_sources is true, or when there's HN (alone or with lobste.rs)
        # AGENT-NOTE: Source link display logic - only show links when HN is present (alone or with lobste.rs), not for lobste.rs-only
        sources = content_data.get("sources", {})
        
        if show_all_sources:
            # Show all sources when explicitly requested
            for source_name, source_url in sorted(sources.items()):
                # Only add source reference if it's not the same as primary URL
                if normalize_url(source_url) != normalize_url(primary_url):
                    formatted_source_url = format_url(source_url)
                    link_parts.append(f"([on {source_name}]({formatted_source_url}))")
        else:
            # Show source references only when there's HN (alone or with lobste.rs)
            has_hn = "HN" in sources
            
            # Show links if there's HN present
            if has_hn:
                for source_name, source_url in sorted(sources.items()):
                    # Only add source reference if it's not the same as primary URL
                    if normalize_url(source_url) != normalize_url(primary_url):
                        formatted_source_url = format_url(source_url)
                        link_parts.append(f"([on {source_name}]({formatted_source_url}))")

        # Join parts with spaces
        link = " ".join(link_parts)

        # Add to date group
        date_groups[date].append(link)

    # Generate output in chronological order (newest first)
    output = []
    output.extend(debug_comment)
    output.append("")

    for date in sorted(date_groups.keys(), reverse=True):
        # Skip dates with no links
        if not date_groups[date]:
            continue
            
        output.append(f"\\subtree[{date}]{{\\mdnote{{{date}}}{{")
        output.extend(sorted(date_groups[date]))  # Sort links alphabetically
        output.append("}}")
        output.append("")

    return "\n".join(output)


def handle_broken_pipe():
    """Handle broken pipe errors gracefully"""
    # Reset signal handler
    signal.signal(signal.SIGPIPE, signal.SIG_DFL)
    
    # Close stdout without causing another error
    try:
        sys.stdout.close()
    except BrokenPipeError:
        pass
    
    # Use os._exit to exit immediately without traceback
    sys.exit(0)


def main():
    # Set up signal handlers for broken pipe
    signal.signal(signal.SIGPIPE, signal.SIG_DFL)
    
    parser = argparse.ArgumentParser(description="Process starred items into Forester format")
    parser.add_argument('--no-deduplicate', action='store_true', help='Disable deduplication of existing URLs')
    parser.add_argument('--tree-files', type=str, nargs='+', help='Paths to tree files to extract existing URLs from', default=['trees/uts-0018.tree', 'trees/uts-016E.tree'])
    parser.add_argument('--show-all-sources', action='store_true', help='Show all sources, not just when both lobste.rs and HN are present')
    parser.add_argument('--days', type=int, default=7, help='Show only entries from the last X days (default: 7, use -1 for all days)')
    parser.add_argument('--rss-json', action='store_true', help='Process JSON output from rss2linkwarden.py instead of GitHub stars')
    args = parser.parse_args()

    try:
        # Read input
        input_text = sys.stdin.read()
        
        # Extract existing URLs from tree files if provided
        existing_urls = set()
        if args.tree_files and not args.no_deduplicate:
            for tree_file in args.tree_files:
                try:
                    with open(tree_file, 'r', encoding='utf-8') as f:
                        tree_content = f.read()
                        urls = extract_existing_urls_from_tree(tree_content)
                        existing_urls.update(urls)
                        print(f"Extracted {len(urls)} URLs from {tree_file}", file=sys.stderr)
                except Exception as e:
                    print(f"Warning: Could not read tree file {tree_file}: {e}", file=sys.stderr)
        
        # Process based on input type
        if args.rss_json:
            output = process_rss_json(input_text, existing_urls, not args.no_deduplicate, args.show_all_sources, args.days)
        else:
            output = process_stars(input_text, existing_urls, not args.no_deduplicate, args.show_all_sources, args.days)
        print(output)
    
    except BrokenPipeError:
        handle_broken_pipe()
    except KeyboardInterrupt:
        sys.exit(130)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
