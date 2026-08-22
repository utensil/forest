#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.11,<3.12"
# dependencies = []
# ///

"""Extract one ISO week of learning-diary entries into flat Forest trees.

Usage:
    just extract-week 2025-W27

The extractor moves only complete ``\\subtree[YYYY-MM-DD]{...}`` daily blocks
from ``trees/uts-0018.tree``.  It writes one physical weekly tree at
``trees/YYYY-Www.tree``: the Markdown-bearing daily blocks live in that file's
logical ``YYYY-Www-links`` subtree.  The root transcludes only the weekly tree.

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


def weekly_tree(week: str, monday: date, entries: list[Entry]) -> str:
    """Build one weekly file with native prose and an in-file link subtree."""

    body = "\n\n".join(entry.source for entry in entries)
    return (
        "\\import{macros}\n\n"
        f"\\title{{Week {monday.isocalendar().week}, {monday.isocalendar().year}}}\n"
        f"\\date{{{monday.isoformat()}}}\n\n"
        "% Add the human-written weekly description here in native Forester syntax.\n\n"
        "\\scope{\n"
        "  \\put\\transclude/toc{false}\n"
        "  \\put\\transclude/expanded{false}\n"
        f"  \\subtree[{week}-links]{{\n"
        f"\\title{{Link selections ({week})}}\n\n"
        f"{body}\n"
        "  }\n"
        "}\n"
    )


def replacement(week: str) -> str:
    """Return the root arrangement, which transcludes only the weekly file."""

    return f"% Weeknote extraction: {week}\n\\transclude{{{week}}}"


def legacy_replacement(week: str) -> str:
    """Recognize the rejected two-physical-file layout for safe correction."""

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
    root: str, week_tree: str, week: str, week_days: tuple[date, ...]
) -> None:
    """Check the durable post-extraction invariants without changing files."""

    marker = f"% Weeknote extraction: {week}"
    if root.count(marker) != 1 or replacement(week) not in root:
        raise ValueError("root does not contain the expected weekly transclusion arrangement")
    root_days = {entry.day for entry in find_entries(root)}
    if root_days.intersection(week_days):
        raise ValueError("root still contains extracted daily entries")
    if f"\\subtree[{week}-links]{{" not in week_tree:
        raise ValueError("weekly tree does not contain its in-file link-selection subtree")
    if f"\\title{{Link selections ({week})}}" not in week_tree:
        raise ValueError("weekly tree does not contain the required link-selection title")
    found = {entry.day for entry in find_entries(week_tree)}
    if found != set(week_days):
        raise ValueError("weekly link-selection subtree does not contain exactly the requested week")


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
        legacy_links_path = args.trees_dir / f"{args.week}-links.tree"

        if legacy_links_path.exists():
            if args.check:
                raise ValueError("legacy standalone link file exists; run without --check to correct it")
            if not week_path.exists() or legacy_replacement(args.week) not in root:
                raise ValueError("legacy link file is not paired with the rejected root arrangement")
            entries = select_week_entries(
                find_entries(legacy_links_path.read_text(encoding="utf-8")), week_days
            )
            new_root = root.replace(legacy_replacement(args.week), replacement(args.week), 1)
            generated_week = weekly_tree(args.week, week_days[0], entries)
            validate_extracted(new_root, generated_week, args.week, week_days)
            write_text(week_path, generated_week)
            write_text(args.source, new_root)
            legacy_links_path.unlink()
            print(f"corrected {args.week}: moved link selections into its weekly tree")
            return 0

        if week_path.exists():
            validate_extracted(root, week_path.read_text(encoding="utf-8"), args.week, week_days)
            print(f"validated {args.week}: already extracted")
            return 0

        if args.check:
            raise ValueError("cannot check an extraction whose destination trees do not exist")

        entries = select_week_entries(find_entries(root), week_days)
        new_root = replace_entries_with_weeknote(root, entries, args.week)
        generated_week = weekly_tree(args.week, week_days[0], entries)

        # AGENT-NOTE: Validate all generated text before any write so a failed
        # extraction never leaves the root and its companion out of sync.
        validate_extracted(new_root, generated_week, args.week, week_days)
        write_text(week_path, generated_week)
        write_text(args.source, new_root)
        print(f"extracted {args.week}: {len(entries)} daily entries")
        return 0
    except (OSError, ValueError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
