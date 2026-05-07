#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///

"""
Port forest post nodes (mdnote) to garden Markdown files in content/posts/.
Handles both plain mdnote{title}{content} and mdnote{title}{verb>>>|content>>>} forms.
"""

import re
from pathlib import Path


NODES = [
    "uts-0167",
    "uts-016A",
    "uts-016B",
    "uts-016C",
    "uts-016E",
    "uts-016J",
    "uts-016K",
    "uts-016L",
    # uts-016M skipped: jj.md already exists in garden with complete content
    "uts-016N",
    "uts-016O",
    "uts-016P",
]


def slugify(title: str, max_words: int = 6) -> str:
    title = title.lower()
    title = re.sub(r"[^\w\s-]", "", title)
    title = re.sub(r"\s+", "-", title.strip())
    title = re.sub(r"-+", "-", title).strip("-")
    parts = title.split("-")
    if len(parts) > max_words:
        title = "-".join(parts[:max_words])
    return title or "untitled"


def extract_mdnote(text: str) -> tuple[str, str]:
    m = re.search(r"\\mdnote\{([^}]+)\}\{", text)
    if not m:
        return "", ""

    title = m.group(1)
    rest = text[m.end():]

    # verb-wrapped: \verb>>>|...\n>>>}
    verb_m = re.match(r"\\verb>>>\|(.*?)>>>\}", rest, re.DOTALL)
    if verb_m:
        return title, verb_m.group(1).strip()

    # plain content: brace-balanced extraction
    depth = 1
    i = 0
    while i < len(rest) and depth > 0:
        if rest[i] == "{":
            depth += 1
        elif rest[i] == "}":
            depth -= 1
        i += 1

    return title, rest[: i - 1].strip()


def parse_tags(text: str) -> list[str]:
    return re.findall(r"\\tag\{([^}]+)\}", text)


def parse_meta(text: str, key: str) -> str:
    m = re.search(rf"\\meta\{{{re.escape(key)}\}}\{{([^}}]+)\}}", text)
    return m.group(1) if m else ""


def parse_field(text: str, field: str) -> str:
    m = re.search(rf"\\{field}\{{([^}}]+)\}}", text)
    return m.group(1) if m else ""


def build_frontmatter(title: str, date: str, tags: list[str], aliases: str, external: str) -> str:
    lines = ["---", f"title: {title}"]
    if date:
        lines.append(f"date: {date}")
    if len(tags) == 1:
        lines.append(f"tag: {tags[0]}")
    elif tags:
        lines.append("tags:")
        for t in tags:
            lines.append(f"  - {t}")
    lines.append(f"aliases: [{aliases}]")
    lines.append(f'source: "https://utensil.github.io/forest/{aliases}/"')
    if external:
        lines.append(f'external: "{external}"')
    lines.append("---")
    return "\n".join(lines)


def convert(tree_id: str, tree_text: str) -> tuple[str, str]:
    title, content = extract_mdnote(tree_text)
    if not title:
        return "", ""

    date = parse_field(tree_text, "date")
    tags = parse_tags(tree_text)
    external = parse_meta(tree_text, "external")

    slug = slugify(title)
    fm = build_frontmatter(title, date, tags, tree_id, external)
    return slug, f"{fm}\n\n{content}\n"


def main() -> None:
    trees_dir = Path("/Users/utensil/projects/forest/trees")
    output_dir = Path("/Users/utensil/projects/garden-posts-port/content/posts")
    output_dir.mkdir(parents=True, exist_ok=True)

    used_slugs: dict[str, str] = {}
    converted = 0

    for tree_id in NODES:
        tree_file = trees_dir / f"{tree_id}.tree"
        if not tree_file.exists():
            print(f"  missing: {tree_id}")
            continue

        text = tree_file.read_text()
        slug, md = convert(tree_id, text)
        if not slug:
            print(f"  no mdnote: {tree_id}")
            continue

        base_slug = slug
        if slug in used_slugs:
            slug = f"{base_slug}-{tree_id[-3:]}"
        used_slugs[slug] = tree_id

        out = output_dir / f"{slug}.md"
        out.write_text(md)
        print(f"  {tree_id} → posts/{slug}.md")
        converted += 1

    print(f"\nConverted {converted} nodes → {output_dir}")


if __name__ == "__main__":
    main()
