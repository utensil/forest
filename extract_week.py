#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.11,<3.12"
# dependencies = []
# ///

"""Extract one ISO week of learning-diary entries into flat Forest trees.

Usage:
    just extract-week 2025-W27

The extractor moves only complete ``\\subtree[YYYY-MM-DD]{...}`` daily blocks
from ``trees/uts-0018.tree``.  It writes the Markdown-bearing blocks unchanged
to ``trees/YYYY-Www-links.tree``, creates a native-Forester weekly skeleton at
``trees/YYYY-Www.tree``, and replaces the source blocks with a weekly
transclusion plus a collapsed sibling link selection.

The operation is deterministic and idempotent.  Re-running it after a
successful extraction validates the generated files without changing them;
``--check`` makes that validation explicit.
"""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from datetime import date
from pathlib import Path


WEEK_RE = re.compile(r"^(?P<year>\d{4})-W(?P<week>\d{2})$")
DAILY_ENTRY_RE = re.compile(r"^\\subtree\[(?P<day>\d{4}-\d{2}-\d{2})\]\{", re.MULTILINE)


@dataclass(frozen=True)
class Entry:
    """A complete daily subtree together with its source offsets."""

    day: date
    start: int
    end: int
    source: str


def parse_week(value: str) -> tuple[int, int, tuple[date, ...]]:
    """Return the ISO year, week, and seven calendar dates for *value*."""

    match = WEEK_RE.fullmatch(value)
    if not match:
        raise ValueError("week must use ISO form YYYY-Www, for example 2025-W27")
    year, week = int(match["year"]), int(match["week"])
    try:
        days = tuple(date.fromisocalendar(year, week, weekday) for weekday in range(1, 8))
    except ValueError as error:
        raise ValueError(f"{value} is not an ISO week") from error
    return year, week, days


def matching_brace(text: str, opening_brace: int) -> int:
    """Return the closing brace paired with *opening_brace*, or raise clearly."""

    if text[opening_brace] != "{":
        raise ValueError("daily entry parser was not positioned on an opening brace")
    depth = 0
    for position in range(opening_brace, len(text)):
        if text[position] == "{":
            depth += 1
        elif text[position] == "}":
            depth -= 1
            if depth == 0:
                return position
    raise ValueError("unbalanced braces while reading a daily entry")


def find_entries(text: str) -> list[Entry]:
    """Parse every top-level dated daily subtree from one diary source."""

    entries: list[Entry] = []
    for match in DAILY_ENTRY_RE.finditer(text):
        opening_brace = match.end() - 1
        closing_brace = matching_brace(text, opening_brace)
        entries.append(
            Entry(
                day=date.fromisoformat(match["day"]),
                start=match.start(),
                end=closing_brace + 1,
                source=text[match.start() : closing_brace + 1],
            )
        )
    return entries


def weekly_tree(week: str, monday: date) -> str:
    """Build the intentionally Markdown-free weekly note skeleton."""

    return (
        "\\import{macros}\n\n"
        f"\\title{{Week {monday.isocalendar().week}, {monday.isocalendar().year}}}\n"
        f"\\date{{{monday.isoformat()}}}\n\n"
        "% Add the human-written weekly description here in native Forester syntax.\n"
    )


def links_tree(week: str, monday: date, entries: list[Entry]) -> str:
    """Build the collapsed-at-call-site Markdown companion without altering entries."""

    body = "\n\n".join(entry.source for entry in entries)
    return (
        "\\import{macros}\n\n"
        f"\\title{{Link selections ({week})}}\n"
        f"\\date{{{monday.isoformat()}}}\n\n"
        f"{body}\n"
    )


def replacement(week: str) -> str:
    """Return the root arrangement for a week and its collapsed link sibling."""

    return (
        f"% Weeknote extraction: {week}\n"
        f"\\transclude{{{week}}}\n\n"
        "\\scope{\n"
        "  \\put\\transclude/toc{false}\n"
        "  \\put\\transclude/expanded{false}\n"
        f"  \\transclude{{{week}-links}}\n"
        "}"
    )


def select_week_entries(entries: list[Entry], week_days: tuple[date, ...]) -> list[Entry]:
    """Select exactly seven entries, rejecting partial or duplicate source weeks."""

    wanted = set(week_days)
    selected = [entry for entry in entries if entry.day in wanted]
    found = {entry.day for entry in selected}
    if found != wanted or len(selected) != len(wanted):
        missing = ", ".join(day.isoformat() for day in week_days if day not in found)
        raise ValueError(f"source does not contain one complete week; missing: {missing}")
    selected.sort(key=lambda entry: entry.start)
    if selected[-1].end > selected[0].start and any(
        earlier.end > later.start for earlier, later in zip(selected, selected[1:])
    ):
        raise ValueError("daily entries overlap; refusing extraction")
    return selected


def replace_entries_with_weeknote(root: str, entries: list[Entry], week: str) -> str:
    """Remove selected entries and place their shared arrangement at the first.

    ISO weeks can cross month subtrees (W27 begins in June and ends in July),
    so this deliberately does not require a contiguous source slice.  The
    arrangement occupies the first source position and the remaining selected
    blocks are removed in the same stable pass.
    """

    parts: list[str] = []
    cursor = 0
    for index, entry in enumerate(entries):
        parts.append(root[cursor : entry.start])
        if index == 0:
            parts.append(replacement(week))
        cursor = entry.end
    parts.append(root[cursor:])
    return "".join(parts)


def validate_extracted(
    root: str, links: str, week: str, week_days: tuple[date, ...]
) -> None:
    """Check the durable post-extraction invariants without changing files."""

    marker = f"% Weeknote extraction: {week}"
    if root.count(marker) != 1 or replacement(week) not in root:
        raise ValueError("root does not contain the expected weekly transclusion arrangement")
    root_days = {entry.day for entry in find_entries(root)}
    if root_days.intersection(week_days):
        raise ValueError("root still contains extracted daily entries")
    expected_links = links_tree(week, week_days[0], find_entries(links))
    if links != expected_links:
        raise ValueError("link selection tree is not a canonical extraction result")
    found = {entry.day for entry in find_entries(links)}
    if found != set(week_days):
        raise ValueError("link selection tree does not contain exactly the requested week")


def write_text(path: Path, content: str) -> None:
    """Write UTF-8 text with a final newline after all validation has passed."""

    path.write_text(content, encoding="utf-8")


def main() -> int:
    """Run or validate one extraction transaction."""

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("week", help="ISO week to extract, e.g. 2025-W27")
    parser.add_argument("--check", action="store_true", help="validate an existing extraction only")
    parser.add_argument(
        "--source", type=Path, default=Path("trees/uts-0018.tree"), help="learning diary root"
    )
    parser.add_argument("--trees-dir", type=Path, default=Path("trees"), help="tree directory")
    args = parser.parse_args()

    try:
        _, _, week_days = parse_week(args.week)
        root = args.source.read_text(encoding="utf-8")
        week_path = args.trees_dir / f"{args.week}.tree"
        links_path = args.trees_dir / f"{args.week}-links.tree"

        if week_path.exists() or links_path.exists():
            if not week_path.exists() or not links_path.exists():
                raise ValueError("only one destination tree exists; refusing partial extraction")
            validate_extracted(
                root,
                links_path.read_text(encoding="utf-8"),
                args.week,
                week_days,
            )
            expected_week = weekly_tree(args.week, week_days[0])
            if week_path.read_text(encoding="utf-8") != expected_week:
                raise ValueError("weekly tree is not the canonical extraction skeleton")
            print(f"validated {args.week}: already extracted")
            return 0

        if args.check:
            raise ValueError("cannot check an extraction whose destination trees do not exist")

        entries = select_week_entries(find_entries(root), week_days)
        new_root = replace_entries_with_weeknote(root, entries, args.week)
        generated_links = links_tree(args.week, week_days[0], entries)
        generated_week = weekly_tree(args.week, week_days[0])

        # AGENT-NOTE: Validate all generated text before any write so a failed
        # extraction never leaves the root and its companion out of sync.
        validate_extracted(new_root, generated_links, args.week, week_days)
        write_text(week_path, generated_week)
        write_text(links_path, generated_links)
        write_text(args.source, new_root)
        print(f"extracted {args.week}: {len(entries)} daily entries")
        return 0
    except (OSError, ValueError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
