#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.11,<3.12"
# dependencies = []
# ///

import json
import sys
from datetime import datetime
from collections import defaultdict
import re


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


def process_stars(input_text):
    # Group by date
    date_groups = defaultdict(list)

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

                    # Convert timestamps to date, using dateArrived as fallback
                    timestamp = entry.get("datePublished") or entry.get("dateArrived")
                    if timestamp is None:
                        continue  # Skip if no timestamp available

                    date = datetime.fromtimestamp(timestamp).strftime("%Y-%m-%d")

                    # Use externalURL if available, otherwise use url
                    url = entry.get("externalURL") or entry.get("url")
                    if not url:  # Skip if no URL available
                        continue

                    # Handle null title or empty title
                    title = entry.get("title")
                    if not title:  # If title is None or empty string
                        title = generate_title_from_url(url)
                    else:
                        title = title.strip()

                    # Create markdown link
                    link = f"- read [{title}]({url})"

                    date_groups[date].append(link)
                except json.JSONDecodeError:
                    continue  # Skip invalid JSON

    # Generate output in chronological order (newest first)
    output = []
    for date in sorted(date_groups.keys(), reverse=True):
        output.append(f"\\subtree[{date}]{{\\mdnote{{{date}}}{{")
        output.extend(sorted(date_groups[date]))  # Sort links alphabetically
        output.append("}}")
        output.append("")

    return "\n".join(output)


if __name__ == "__main__":
    # Wait for all input
    input_text = sys.stdin.read()
    # Process and print
    print(process_stars(input_text))
