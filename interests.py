#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.11,<3.12"
# dependencies = []
# ///

import re
from datetime import datetime
from pathlib import Path


def parse_interests(md_content):
    """Parse interests.md content into structured data"""
    # Split by horizontal lines (---)
    sections = re.split(r"-{70,}", md_content)

    issues = []
    for section in sections:
        if not section.strip():
            continue

        title_match = re.search(r"(?:`open`|`closed`):\s*(.*?)(?:\n|$)", section)
        title = title_match.group(1).strip() if title_match else None

        match = re.search(
            r"(?:>)\[([^\]]+)\][^ ]+ opened issue at \[(\d{4}-\d{2}-\d{2})", section
        )
        opener = match.group(1) if match else None
        date = datetime.strptime(match.group(2), "%Y-%m-%d") if match else None

        if title and date and opener:
            if opener != "dependabot-preview":
                # Extract content after first #### line
                content_start = section.find("####")
                if content_start != -1:
                    content = section[content_start + 4 :].strip()
                else:
                    content = ""

                issues.append({
                    "title": title,
                    "date": date.strftime("%Y-%m-%d"),
                    "opener": opener,
                    "content": content,
                })
        else:
            print(f"Skipping section due to missing data:\n{section}")

    return issues


if __name__ == "__main__":
    with open("interests.md", "r", encoding="utf-8") as f:
        content = f.read()

    issues = parse_interests(content)

    # Find highest existing tree number
    trees_dir = Path("trees")
    trees_dir.mkdir(exist_ok=True)  # Ensure trees directory exists
    existing_trees = [
        int(f.stem[4:]) for f in trees_dir.glob("uts-*.tree") if f.stem[4:].isdigit()
    ]
    next_num = max(existing_trees) + 1 if existing_trees else 1

    for issue in issues:
        # Generate tree filename
        tree_name = f"uts-{next_num:04d}"
        next_num += 1

        # Create Forester tree content
        tree_content = f"""\\title{{{issue["title"]}}}
\\date{{{issue["date"]}}}
\\author{{{issue["opener"]}}}

\\md{{
{issue["content"]}
}}
"""
        print(f"Would create tree: {tree_name}.tree")
        print("=" * 80)
        print(tree_content)
        print("=" * 80)
        print()
