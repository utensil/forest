#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.11,<3.12"
# dependencies = []
# ///

"""Extract observed learning-diary weeks into flat Forest trees.

Usage:
    just extract-week 2025-W27
    just extract-all-weeks

The extractor moves dated ``\\subtree[YYYY-MM-DD]{...}`` daily blocks from
``trees/uts-0018.tree``. It writes one physical weekly tree at
``trees/YYYY-Www.tree``: the Markdown-bearing daily blocks live in that file's
logical ``YYYY-Www-links`` subtree.  The root transcludes only the weekly tree.

The operation is deterministic and idempotent. A week may be partial when the
source diary contains only some of its dates. The link collection is collapsed
as one boundary, while its dated daily children are expanded once that boundary
is opened. Re-running after a successful extraction validates the generated
files without changing them; ``--check`` makes that validation explicit.
"""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from datetime import date
from pathlib import Path


WEEK_RE = re.compile(r"^(?P<year>\d{4})-W(?P<week>\d{2})$")
DAILY_ENTRY_RE = re.compile(
    r"^\\subtree\[(?P<day>\d{4}-\d{2}-\d{2})(?:-[^\]]+)?\]\{", re.MULTILINE
)
TEMPLATE_DESCRIPTION = "% Add the human-written weekly description here in native Forester syntax.\n\n"


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
    """Parse every dated daily subtree, including duplicate-date addresses."""

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


def repair_spanning_daily_entries(text: str) -> tuple[str, int]:
    """Repair daily subtrees that borrow a later structural closing brace.

    Daily entries are siblings in the diary. If one opening brace reaches the
    next dated sibling, close it immediately before that sibling and remove
    the borrowed closing brace. The repair is mechanical and preserves all
    diary content; it only restores the intended subtree boundary.
    """

    repairs = 0
    while True:
        matches = list(DAILY_ENTRY_RE.finditer(text))
        for index, match in enumerate(matches[:-1]):
            next_start = matches[index + 1].start()
            closing = matching_brace(text, match.end() - 1)
            if closing < next_start:
                continue
            text = text[:next_start] + "}\n\n" + text[next_start:closing] + text[closing + 1 :]
            repairs += 1
            break
        else:
            return text, repairs


def weekly_tree(week: str, monday: date, entries: list[Entry]) -> str:
    """Build one weekly file with one collapsed collection and open daily children."""

    body = "\n\n".join(entry.source for entry in entries)
    return (
        "\\import{macros}\n\n"
        f"\\title{{{week}}}\n"
        f"\\date{{{monday.isoformat()}}}\n\n"
        "\\scope{\n"
        "  \\put\\transclude/toc{false}\n"
        "  \\put\\transclude/expanded{false}\n"
        f"  \\subtree[{week}-links]{{\n"
        f"\\title{{🔗 {week}}}\n\n"
        "    \\scope{\n"
        "      \\put\\transclude/expanded{true}\n"
        f"{body}\n"
        "    }\n"
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
    """Select the source entries observed in one ISO week.

    A diary can begin or end partway through a week. Preserve every dated
    entry that is present rather than inventing missing daily nodes.
    """

    wanted = set(week_days)
    selected = [entry for entry in entries if entry.day in wanted]
    if not selected:
        raise ValueError("source does not contain any daily entries for the requested week")
    selected.sort(key=lambda entry: entry.start)
    if selected[-1].end > selected[0].start and any(
        earlier.end > later.start for earlier, later in zip(selected, selected[1:])
    ):
        raise ValueError("daily entries overlap; refusing extraction")
    return selected


def normalize_week_tree(text: str, week: str) -> str:
    """Migrate generated collection chrome without touching daily or weekly prose."""

    normalized = text.replace(TEMPLATE_DESCRIPTION, "")
    year, week_number, _ = parse_week(week)
    normalized = normalized.replace(
        f"\\title{{Week {week_number}, {year}}}", f"\\title{{{week}}}", 1
    )
    old_title = f"\\title{{Link selections ({week})}}"
    new_title = f"\\title{{🔗 {week}}}"
    normalized = normalized.replace(old_title, new_title)

    scope_marker = "    \\scope{\n      \\put\\transclude/expanded{true}\n"
    if scope_marker in normalized:
        return normalized

    subtree_marker = f"  \\subtree[{week}-links]{{"
    subtree_start = normalized.find(subtree_marker)
    title_marker = f"{new_title}\n\n"
    title_start = normalized.find(title_marker, subtree_start)
    if subtree_start == -1 or title_start == -1:
        raise ValueError(f"{week}.tree does not have the generated link-collection structure")
    subtree_close = matching_brace(normalized, subtree_start + len(subtree_marker) - 1)
    after_title = title_start + len(title_marker)
    normalized = normalized[:after_title] + scope_marker + normalized[after_title:]
    subtree_close += len(scope_marker)
    return normalized[:subtree_close] + "    }\n" + normalized[subtree_close:]


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
    root: str,
    week_tree: str,
    week: str,
    week_days: tuple[date, ...],
    expected_entries: list[Entry] | None = None,
) -> None:
    """Check the durable post-extraction invariants without changing files."""

    marker = f"% Weeknote extraction: {week}"
    if root.count(marker) != 1 or replacement(week) not in root:
        raise ValueError("root does not contain the expected weekly transclusion arrangement")
    root_days = {entry.day for entry in find_entries(root)}
    if root_days.intersection(week_days):
        raise ValueError("root still contains extracted daily entries")
    if f"\\title{{{week}}}" not in week_tree:
        raise ValueError("weekly tree does not contain the required stem title")
    if f"\\subtree[{week}-links]{{" not in week_tree:
        raise ValueError("weekly tree does not contain its in-file link-selection subtree")
    if f"\\title{{🔗 {week}}}" not in week_tree:
        raise ValueError("weekly tree does not contain the required link-selection title")
    if "    \\scope{\n      \\put\\transclude/expanded{true}\n" not in week_tree:
        raise ValueError("weekly link-selection subtree does not expand its daily children")
    found = find_entries(week_tree)
    if not found or any(entry.day not in set(week_days) for entry in found):
        raise ValueError("weekly link-selection subtree contains invalid daily entries")
    if expected_entries is not None and [entry.source for entry in found] != [
        entry.source for entry in expected_entries
    ]:
        raise ValueError("weekly link-selection subtree does not preserve the selected source entries")


def write_text(path: Path, content: str) -> None:
    """Write UTF-8 text with a final newline after all validation has passed."""

    path.write_text(content, encoding="utf-8")


def week_name(day: date) -> str:
    """Return the canonical ISO-week tree stem for one diary date."""

    year, week, _ = day.isocalendar()
    return f"{year:04d}-W{week:02d}"


def extract_all(source: Path, trees_dir: Path, check: bool) -> int:
    """Extract every ISO week represented by daily nodes in one transaction."""

    root = source.read_text(encoding="utf-8")
    root, repairs = repair_spanning_daily_entries(root)
    if check and repairs:
        raise ValueError("--check found malformed daily subtree boundaries")
    source_entries = find_entries(root)
    observed_weeks = sorted({week_name(entry.day) for entry in source_entries})
    existing_paths = sorted(trees_dir.glob("????-W??.tree"))
    planned_writes: dict[Path, str] = {}

    legacy_paths = sorted(trees_dir.glob("????-W??-links.tree"))
    if legacy_paths:
        names = ", ".join(path.name for path in legacy_paths)
        raise ValueError(f"legacy standalone link files require targeted correction: {names}")

    for path in existing_paths:
        _, _, week_days = parse_week(path.stem)
        existing = path.read_text(encoding="utf-8")
        normalized = normalize_week_tree(existing, path.stem)
        if check and normalized != existing:
            raise ValueError(f"{path.name} still has retired weekly collection chrome")
        validate_extracted(root, normalized, path.stem, week_days)
        if normalized != existing:
            planned_writes[path] = normalized

    new_root = root
    created = 0
    extracted_entries = 0
    for week in observed_weeks:
        _, _, week_days = parse_week(week)
        week_path = trees_dir / f"{week}.tree"
        if week_path.exists():
            raise ValueError(f"root still contains daily entries already owned by {week_path.name}")
        entries = select_week_entries(find_entries(new_root), week_days)
        generated = weekly_tree(week, week_days[0], entries)
        candidate_root = replace_entries_with_weeknote(new_root, entries, week)
        validate_extracted(candidate_root, generated, week, week_days, entries)
        planned_writes[week_path] = generated
        new_root = candidate_root
        created += 1
        extracted_entries += len(entries)

    if find_entries(new_root):
        raise ValueError("root still contains daily entries after all observed weeks were planned")
    if check and (planned_writes or new_root != root):
        raise ValueError("--check found work that has not been extracted")

    # AGENT-NOTE: Every weekly file and the revised root were validated before
    # this first write, so batch extraction cannot leave a partial arrangement.
    if not check:
        for path, content in planned_writes.items():
            write_text(path, content)
        if new_root != root:
            write_text(source, new_root)

    total_weeks = len(existing_paths) + created
    print(
        f"{'validated' if check else 'extracted'} all observed weeks: "
        f"{total_weeks} weekly trees, {extracted_entries} newly moved daily entries, "
        f"{repairs} repaired daily boundaries"
    )
    return 0


def main() -> int:
    """Run or validate one targeted extraction, or all observed weeks."""

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("week", nargs="?", help="ISO week to extract, e.g. 2025-W27")
    parser.add_argument("--all", action="store_true", help="extract every observed ISO week")
    parser.add_argument("--check", action="store_true", help="validate an existing extraction only")
    parser.add_argument(
        "--source", type=Path, default=Path("trees/uts-0018.tree"), help="learning diary root"
    )
    parser.add_argument("--trees-dir", type=Path, default=Path("trees"), help="tree directory")
    args = parser.parse_args()

    try:
        if args.all == (args.week is not None):
            parser.error("provide exactly one ISO week or --all")
        if args.all:
            return extract_all(args.source, args.trees_dir, args.check)

        assert args.week is not None
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
            existing = week_path.read_text(encoding="utf-8")
            normalized = normalize_week_tree(existing, args.week)
            if args.check and normalized != existing:
                raise ValueError("weekly tree still has retired collection chrome")
            validate_extracted(root, normalized, args.week, week_days)
            if normalized != existing:
                write_text(week_path, normalized)
                print(f"normalized {args.week}: updated generated collection chrome")
                return 0
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
