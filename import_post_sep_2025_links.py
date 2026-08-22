#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# ///
"""Import the reviewed post-September-2025 X link collection into Forest.

The reviewed manifest in cog-land fixes the source-only tag decisions and the
15-link daily allocation.  This importer turns that manifest into flat weekly
trees with one in-file, collapsed link collection per week.  It deliberately
does not make network requests or infer tags from URLs, accounts, or outside
knowledge.

Usage:
    just import-post-sep-2025-links /path/to/cog-land
    just check-post-sep-2025-links /path/to/cog-land

Use ``--refresh`` only to replace an earlier version of this generated import;
it refuses to replace a weekly tree that does not retain this import's chrome.
"""

from __future__ import annotations

import argparse
import csv
import re
from collections import defaultdict
from dataclasses import dataclass
from datetime import date
from pathlib import Path
from urllib.parse import urlsplit, urlunsplit


MANIFEST = Path("projects/forest/post-sep-2025-raindrop-tag-sync-manifest-2026-08-22.csv")
EXCLUSIONS = Path("projects/forest/post-sep-2025-forest-dedup-exclusions-2026-08-22.csv")
ROOT_TREE = Path("trees/uts-0018.tree")
TREES_DIR = Path("trees")
EXPECTED_LINKS = 2_197
EXPECTED_DAYS = 152
MAXIMUM_DAILY_LINKS = 15
EXPECTED_DEDUPLICATIONS = 1
ROOT_MARKER = "\\subtree[2025]{"
TAG_ORDER = (
    "agent", "formal", "proof", "ebpf", "rust", "zig", "lean", "haskell", "ocaml", "clojure",
    "racket", "elixir", "apl", "compiler", "gpu", "shader", "webgl", "benchmark", "render", "cg",
    "visualization", "game", "sec", "web", "os", "git", "docker", "sqlite", "wasm", "tui",
    "software", "sci", "context", "misc",
)
TAG_RANK = {tag: index for index, tag in enumerate(TAG_ORDER)}


@dataclass(frozen=True)
class Link:
    url: str
    title: str
    source_date: str
    target_date: str
    tags: tuple[str, ...]
    status_id: str
    source_path: str


def normalise_url(url: str) -> str:
    """Normalise only stable URL identity details used by the reviewed audit."""

    parts = urlsplit(url.strip())
    return urlunsplit((parts.scheme.lower(), parts.netloc.lower(), parts.path.rstrip("/"), parts.query, ""))


def x_status_id(url: str) -> str | None:
    match = re.search(r"(?:x|twitter)\.com/[^/]+/status/(\d+)", url, re.I)
    return match.group(1) if match else None


def iso_week(day: str) -> str:
    value = date.fromisoformat(day)
    year, week, _ = value.isocalendar()
    return f"{year:04d}-W{week:02d}"


def monday(week: str) -> date:
    year, number = week.split("-W")
    return date.fromisocalendar(int(year), int(number), 1)


def frontmatter(path: Path) -> dict[str, str]:
    text = path.read_text(encoding="utf-8")
    match = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    if not match:
        raise ValueError(f"clip lacks YAML frontmatter: {path}")
    values: dict[str, str] = {}
    for line in match.group(1).splitlines():
        key, separator, value = line.partition(":")
        if separator and not line.startswith((" ", "-")):
            values[key] = value.strip().strip('"')
    return values


def markdown_title(title: str, url: str) -> str:
    """Keep source titles literal while protecting Forest and Markdown syntax.

    Numeric character references render as the original source character, but
    cannot close the surrounding Forester argument or Markdown link early.
    """

    escaped = title or url
    for character, entity in (
        ("&", "&amp;"), ("\\", "&#92;"), ("{", "&#123;"), ("}", "&#125;"),
        ("[", "&#91;"), ("]", "&#93;"), ("(", "&#40;"), (")", "&#41;"),
        ('"', "&quot;"), ("%", "&#37;"),
    ):
        escaped = escaped.replace(character, entity)
    return escaped


def load_reviewed_links(cog_land: Path) -> list[Link]:
    """Load the approved, source-text-only manifest and its original X titles."""

    manifest = cog_land / MANIFEST
    if not manifest.is_file():
        raise ValueError(f"reviewed allocation manifest does not exist: {manifest}")
    links: list[Link] = []
    with manifest.open(newline="", encoding="utf-8") as handle:
        for row in csv.DictReader(handle):
            if row.get("source") != "x":
                raise ValueError("reviewed manifest must contain only deduplicated X links")
            source_path = cog_land / row["source-path"]
            metadata = frontmatter(source_path)
            if metadata.get("url") != row["url"] or metadata.get("tweet-id") != row["source-id"]:
                raise ValueError(f"manifest no longer matches its clip: {row['source-path']}")
            tags = tuple(tag for tag in row["tags"].split(",") if tag)
            if not tags or any(tag not in TAG_RANK for tag in tags):
                raise ValueError(f"manifest uses an unreviewed tag for {row['url']}")
            links.append(Link(
                url=row["url"], title=metadata.get("title", "").strip(), source_date=row["source-date"],
                target_date=row["target-date"], tags=tags, status_id=row["source-id"],
                source_path=row["source-path"],
            ))
    urls = [normalise_url(link.url) for link in links]
    ids = [link.status_id for link in links]
    if len(links) != EXPECTED_LINKS or len(urls) != len(set(urls)) or len(ids) != len(set(ids)):
        raise ValueError("reviewed manifest is not the expected 2,197 unique X-link set")
    return links


def existing_identities(paths: list[Path]) -> tuple[set[str], set[str]]:
    urls: set[str] = set()
    status_ids: set[str] = set()
    for path in paths:
        for raw_url in re.findall(r'https?://[^\s)\]}"<>]+', path.read_text(encoding="utf-8")):
            cleaned = raw_url.rstrip(".,;:")
            urls.add(normalise_url(cleaned))
            if status_id := x_status_id(cleaned):
                status_ids.add(status_id)
    return urls, status_ids


def validate_dedup_audit(cog_land: Path, baseline_urls: set[str]) -> None:
    """Require the reviewed one-row baseline exclusion to remain real and explicit."""

    exclusions = cog_land / EXCLUSIONS
    if not exclusions.is_file():
        raise ValueError(f"Forest deduplication audit does not exist: {exclusions}")
    with exclusions.open(newline="", encoding="utf-8") as handle:
        rows = list(csv.DictReader(handle))
    if len(rows) != EXPECTED_DEDUPLICATIONS:
        raise ValueError("expected exactly one reviewed Forest-baseline deduplication")
    row = rows[0]
    if row.get("reason") != "forest-normalised-url" or normalise_url(row.get("url", "")) not in baseline_urls:
        raise ValueError("the reviewed Forest-baseline duplicate is no longer present in the baseline")


def tag_tree(links: list[Link]) -> dict[str, object]:
    """Make a tag trie, so links sharing tag paths are merged visually once."""

    root: dict[str, object] = {"children": {}, "links": []}
    for link in sorted(links, key=lambda item: (item.tags, normalise_url(item.url))):
        node = root
        for tag in link.tags:
            children = node["children"]
            assert isinstance(children, dict)
            node = children.setdefault(tag, {"children": {}, "links": []})
        leaves = node["links"]
        assert isinstance(leaves, list)
        leaves.append(link)
    return root


def render_tag_tree(node: dict[str, object], depth: int) -> list[str]:
    lines: list[str] = []
    children = node["children"]
    assert isinstance(children, dict)
    for tag in sorted(children, key=TAG_RANK.__getitem__):
        lines.append(f"{'    ' * depth}- #{tag}")
        child = children[tag]
        assert isinstance(child, dict)
        lines.extend(render_tag_tree(child, depth + 1))
    leaves = node["links"]
    assert isinstance(leaves, list)
    for link in leaves:
        assert isinstance(link, Link)
        lines.append(f"{'    ' * depth}- [{markdown_title(link.title, link.url)}]({link.url})")
    return lines


def daily_tree(day: str, links: list[Link]) -> str:
    body = "\n".join(render_tag_tree(tag_tree(links), 0))
    return f"\\subtree[{day}]{{\\mdnote{{{day}}}{{\n{body}\n}}}}"


def weekly_tree(week: str, entries: dict[str, list[Link]]) -> str:
    body = "\n\n".join(daily_tree(day, entries[day]) for day in sorted(entries))
    return (
        "\\import{macros}\n\n"
        f"\\title{{{week}}}\n"
        f"\\date{{{monday(week).isoformat()}}}\n\n"
        "\\scope{\n"
        "  \\put\\transclude/toc{false}\n"
        "  \\put\\transclude/expanded{false}\n"
        f"  \\subtree[{week}-links]{{\n"
        "\\title{🔗}\n\n"
        "    \\scope{\n"
        "      \\put\\transclude/expanded{true}\n"
        f"{body}\n"
        "    }\n"
        "  }\n"
        "}\n"
    )


def root_addition(weeks: list[str]) -> str:
    by_month: dict[str, list[str]] = defaultdict(list)
    for week in weeks:
        by_month[monday(week).strftime("%Y-%m")].append(week)
    sections = ["\\subtree[2026]{", "\\title{Year 2026}", ""]
    for month, month_weeks in sorted(by_month.items(), reverse=True):
        month_name = date.fromisoformat(f"{month}-01").strftime("%B, %Y")
        sections.extend([f"\\subtree[{month}]{{", f"\\title{{{month_name}}}", ""])
        for week in sorted(month_weeks, reverse=True):
            sections.extend([f"% Post-Sep-2025 link intake: {week}", f"\\transclude{{{week}}}", ""])
        sections.extend(["}", ""])
    sections.append("}")
    return "\n".join(sections) + "\n\n"


def is_generated_week_tree(path: Path, week: str) -> bool:
    """Recognise only a previous generated target, never an arbitrary weeknote."""

    text = path.read_text(encoding="utf-8")
    return (
        text.startswith("\\import{macros}\n\n" + f"\\title{{{week}}}\n")
        and f"\\subtree[{week}-links]{{" in text
        and "\\title{🔗}" in text
        and "\\put\\transclude/expanded{true}" in text
    )


def plan(cog_land: Path) -> tuple[dict[Path, str], str, list[str]]:
    links = load_reviewed_links(cog_land)
    by_date: dict[str, list[Link]] = defaultdict(list)
    for link in links:
        by_date[link.target_date].append(link)
    counts = [len(day_links) for day_links in by_date.values()]
    if len(by_date) != EXPECTED_DAYS or max(counts) > MAXIMUM_DAILY_LINKS or min(counts) < 10:
        raise ValueError("reviewed allocation no longer satisfies the 10–15-link daily policy")
    by_week: dict[str, dict[str, list[Link]]] = defaultdict(lambda: defaultdict(list))
    for day, day_links in by_date.items():
        by_week[iso_week(day)][day].extend(day_links)
    weeks = sorted(by_week)
    target_paths = {TREES_DIR / f"{week}.tree" for week in weeks}
    baseline_paths = [path for path in sorted(TREES_DIR.glob("*.tree")) if path not in target_paths]
    baseline_urls, baseline_ids = existing_identities(baseline_paths)
    validate_dedup_audit(cog_land, baseline_urls)
    conflicts = [link for link in links if normalise_url(link.url) in baseline_urls or link.status_id in baseline_ids]
    if conflicts:
        raise ValueError(f"reviewed manifest collides with the current Forest baseline: {conflicts[0].url}")
    return ({TREES_DIR / f"{week}.tree": weekly_tree(week, by_week[week]) for week in weeks}, root_addition(weeks), weeks)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--cog-land", required=True, type=Path, help="checkout containing the reviewed private manifest")
    parser.add_argument("--check", action="store_true", help="validate the existing generated import without writing")
    parser.add_argument("--refresh", action="store_true", help="replace an earlier generated version after checking its ownership")
    args = parser.parse_args()
    root = ROOT_TREE.read_text(encoding="utf-8")
    planned_trees, addition, weeks = plan(args.cog_land.expanduser().resolve())
    if ROOT_MARKER not in root:
        raise ValueError("the live diary root no longer has the expected 2025 insertion marker")
    if "\\subtree[2026]{" not in root:
        expected_root = root.replace(ROOT_MARKER, addition + ROOT_MARKER, 1)
    else:
        expected_root = (
            root[:root.index("\\subtree[2026]{")]
            + addition
            + root[root.index(ROOT_MARKER):]
        )
    stale = [path for path, content in planned_trees.items() if not path.is_file() or path.read_text(encoding="utf-8") != content]
    root_is_current = root == expected_root
    if args.check and (stale or not root_is_current):
        targets = ", ".join(path.name for path in stale[:3])
        raise ValueError(f"--check found a non-current import: {targets or 'uts-0018.tree'}")
    if not args.check:
        if "\\subtree[2026]{" in root and not root_is_current:
            raise ValueError("refusing to overwrite a non-generated 2026 root arrangement")
        for path, content in planned_trees.items():
            if path.exists() and path.read_text(encoding="utf-8") != content and not (
                args.refresh and is_generated_week_tree(path, path.stem)
            ):
                raise ValueError(f"refusing to overwrite a non-current generated file: {path}")
        for path, content in planned_trees.items():
            path.write_text(content, encoding="utf-8")
        if root != expected_root:
            ROOT_TREE.write_text(expected_root, encoding="utf-8")
    print(f"{'validated' if args.check else 'imported'} {EXPECTED_LINKS:,} links into {len(weeks)} weekly trees and {EXPECTED_DAYS} daily nodes")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
