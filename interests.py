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
                    content = section[content_start:].strip()
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

    # First create all trees and store their IDs
    tree_ids = []
    for issue in issues:
        tree_name = f"uts-{next_num:04d}"
        tree_ids.append((issue, tree_name))
        next_num += 1

        escaped_content = issue["content"]
        for url in re.findall(r"\[([^\]]+)\]\(([^)]+)\)", escaped_content):
            escaped_content = escaped_content.replace(
                url[1], url[1].replace("%", "\\%")
            )

        escaped_content = re.sub(
            r'<img src="https://avatars.githubusercontent.com/[^"]+"[^>]*>',
            "",
            escaped_content,
        )

        tree_content = f"""\\import{{macros}}\\title{{{issue["title"]}}}
\\date{{{issue["date"]}}}
\\author{{{issue["opener"]}}}

\\md{{
{escaped_content}
}}
"""
        tree_path = trees_dir / f"{tree_name}.tree"
        with open(tree_path, "w", encoding="utf-8") as f:
            f.write(tree_content)
        print(f"Created tree: {tree_path}")

    # Then create index using the stored tree IDs
    if tree_ids:
        # Sort by date descending using the stored IDs
        sorted_trees = sorted(tree_ids, key=lambda x: x[0]["date"], reverse=True)

        index_content = """\\title{Interests in early years}

\\ul{
"""
        for issue, tree_id in sorted_trees:
            index_content += f"  \\li{{{issue['date']} [[{tree_id}]]}}\n"

        index_content += "}\n"

        index_path = trees_dir / f"uts-{next_num:04d}.tree"
        with open(index_path, "w", encoding="utf-8") as f:
            f.write(index_content)
        print(f"Created index tree: {index_path}")
