#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///

"""
Port forest interest nodes (uts-0030 to uts-0165) to garden Markdown files.
Each tree file uses the md macro with a GitHub issue header; content is
extracted and written with YAML frontmatter (title, date, tags, aliases, URL).
"""

import re
from pathlib import Path


def slugify(title: str, max_words: int = 6) -> str:
    title = title.lower()
    title = re.sub(r"[^\w\s-]", "", title)
    title = re.sub(r"\s+", "-", title.strip())
    title = re.sub(r"-+", "-", title).strip("-")
    parts = title.split("-")
    if len(parts) > max_words:
        title = "-".join(parts[:max_words])
    return title or "untitled"


def extract_md_content(tree_text: str) -> str:
    md_start = tree_text.find("\\md{\n")
    if md_start == -1:
        return ""

    content = tree_text[md_start + len("\\md{\n"):]
    lines = content.split("\n")

    # strip trailing blank lines and closing "}"
    while lines and lines[-1].strip() == "":
        lines.pop()
    if lines and lines[-1].strip() == "}":
        lines.pop()

    content = "\n".join(lines)

    # strip the "#### [user] opened issue at [...]:" header + following blank line
    content = re.sub(
        r"^####[^\n]*opened issue at[^\n]*\n\n?", "", content, flags=re.MULTILINE
    )
    return content.strip()


def convert(tree_id: str, tree_text: str) -> tuple[str, str]:
    title_m = re.search(r"\\title\{([^}]+)\}", tree_text)
    title = title_m.group(1) if title_m else tree_id

    date_m = re.search(r"\\date\{([^}]+)\}", tree_text)
    date = date_m.group(1) if date_m else ""

    content = extract_md_content(tree_text)
    slug = slugify(title)
    source = f"https://utensil.github.io/forest/{tree_id}/"

    # escape quotes in title for YAML
    title_yaml = title.replace('"', '\\"')

    frontmatter = (
        f'---\n'
        f'title: "{title_yaml}"\n'
        f'date: {date}\n'
        f'tags: [interest]\n'
        f'aliases: [{tree_id}]\n'
        f'source: "{source}"\n'
        f'---'
    )
    return slug, f"{frontmatter}\n\n{content}\n"


def main() -> None:
    trees_dir = Path("/Users/utensil/projects/forest/trees")
    output_dir = Path("/Users/utensil/projects/garden-interest-port/content/interests")
    output_dir.mkdir(parents=True, exist_ok=True)

    used_slugs: dict[str, str] = {}
    converted = 0

    for num in range(30, 166):
        tree_id = f"uts-{num:04d}"
        tree_file = trees_dir / f"{tree_id}.tree"
        if not tree_file.exists():
            print(f"  missing: {tree_id}")
            continue

        text = tree_file.read_text()
        slug, md = convert(tree_id, text)

        # disambiguate slug collisions
        base_slug = slug
        if slug in used_slugs:
            slug = f"{base_slug}-{num}"
        used_slugs[slug] = tree_id

        out = output_dir / f"{slug}.md"
        out.write_text(md)
        print(f"  {tree_id} → interests/{slug}.md")
        converted += 1

    print(f"\nConverted {converted} nodes → {output_dir}")


if __name__ == "__main__":
    main()
