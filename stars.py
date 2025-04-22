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

                    # Convert timestamp to date
                    date = datetime.fromtimestamp(entry["dateArrived"]).strftime(
                        "%Y-%m-%d"
                    )

                    date = datetime.fromtimestamp(entry["datePublished"]).strftime(
                        "%Y-%m-%d"
                    )

                    # Use externalURL if available, otherwise use url
                    url = entry.get("externalURL") or entry.get("url")
                    if not url:  # Skip if no URL available
                        continue

                    title = entry.get(
                        "title", ""
                    )  # .replace('[AINews]', '')  # Clean up title

                    # Create markdown link
                    link = f"- read [{title.strip()}]({url})"

                    date_groups[date].append(link)
                except json.JSONDecodeError:
                    continue  # Skip invalid JSON

    # Generate output in chronological order (newest first)
    output = []
    for date in sorted(date_groups.keys(), reverse=True):
        output.append(f"\\mdblock{{{date}}}{{")
        output.extend(sorted(date_groups[date]))  # Sort links alphabetically
        output.append("}")
        output.append("")

    return "\n".join(output)


if __name__ == "__main__":
    # Wait for all input
    input_text = sys.stdin.read()
    # Process and print
    print(process_stars(input_text))
