#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.11,<3.12"
# dependencies = []
# ///

"""Report daily material that may deserve native weekly-note prose.

Usage:
    just weeknote-candidates 2024-W42
    just weeknote-candidates --year 2025 --format markdown

This detector is deliberately read-only. It identifies candidate Markdown
blocks using explicit signals: activity language, links to authored Forest
trees, project names, and bibliography citations. A human or model curator
decides what belongs in the native Forester weeknote; all daily source remains
in its collapsed link collection unless it is deliberately curated later.
"""

from __future__ import annotations

import argparse
import json
import re
from dataclasses import asdict, dataclass
from pathlib import Path

from extract_week import find_entries, matching_brace


ADDRESS_RE = re.compile(r"^\\subtree\[(?P<address>[^]]+)\]", re.MULTILINE)
MDNOTE_RE = re.compile(r"\\mdnote\{[^}]+\}\{")
BULLET_RE = re.compile(r"^(?P<indent>[ \t]*)-\s+(?P<text>.*)$")
TREE_RE = re.compile(r"\[\[(?P<tree>[a-z][a-z0-9]*-[A-Z0-9]+)\]\]")
CITATION_RE = re.compile(r"\\citef\{(?P<citation>[^}]+)\}")
# AGENT-NOTE: keep this authorial-start rule conservative; the detector is a review queue, not a mover.
# Match only the beginning of a Markdown bullet. Searching arbitrary prose
# produced false activities from linked article titles ("Build It Yourself"),
# quotes ("start with…"), and paper descriptions.  This is intentionally
# conservative: it finds authorial action statements rather than trying to
# infer authorship from every verb in collected material.
AUTHORIAL_ACTION_RE = re.compile(
    r"^(?:i\s+)?(?:"
    r"add(?:ed|ing)?|build(?:ing)?|continu(?:e|ed|ing)|creat(?:e|ed|ing)|"
    r"debug(?:ged|ging)?|deploy(?:ed|ing)?|develop(?:ed|ing)?|"
    r"fix(?:ed|ing)?|implement(?:ed|ing)?|improv(?:e|ed|ing)|"
    r"make a start on|made a start on|migrat(?:e|ed|ing)|"
    r"recover(?:ed|ing)?|refactor(?:ed|ing)?|releas(?:e|ed|ing)|"
    r"restor(?:e|ed|ing)|set up|setting up|start(?:ed|ing)?|submit(?:ted|ting)?|"
    r"switch(?:ed|ing)?|updat(?:e|ed|ing)|work(?:ing)? on|work out|"
    r"writ(?:e|es|ing|ten)|wrote|try(?:ing)? to|learn(?:ed|ing)?"
    r")\b",
    re.IGNORECASE,
)
READING_RE = re.compile(
    r"\b(?:citation trace|learn(?:ed)?|read(?:ing)?|research|skim(?:med)?|study|survey)\b",
    re.IGNORECASE,
)
PROJECT_RE = re.compile(r"\b[a-z0-9]+-land\b", re.IGNORECASE)


@dataclass(frozen=True)
class Candidate:
    """One script-detected curation candidate; never an automatic move instruction."""

    week: str
    date: str
    address: str
    kinds: tuple[str, ...]
    reasons: tuple[str, ...]
    tree_links: tuple[str, ...]
    citations: tuple[str, ...]
    text: str


def mdnote_content(source: str) -> str:
    """Return the Markdown body of one complete daily ``\\mdnote`` subtree."""

    match = MDNOTE_RE.search(source)
    if match is None:
        raise ValueError("daily subtree does not contain an mdnote body")
    opening_brace = match.end() - 1
    return source[opening_brace + 1 : matching_brace(source, opening_brace)]


def bullet_blocks(content: str) -> list[str]:
    """Return Markdown bullet blocks, retaining each matched bullet's descendants."""

    lines = content.splitlines()
    starts: list[tuple[int, int]] = []
    for index, line in enumerate(lines):
        match = BULLET_RE.match(line)
        if match:
            starts.append((index, len(match["indent"].expandtabs(4))))

    blocks: list[str] = []
    for position, (start, indent) in enumerate(starts):
        end = len(lines)
        for next_start, next_indent in starts[position + 1 :]:
            if next_indent <= indent:
                end = next_start
                break
        blocks.append("\n".join(lines[start:end]).strip())
    return blocks


def authorial_actions(block: str) -> tuple[str, ...]:
    """Return explicit action starts, never verbs inside a linked item or quote."""

    actions: list[str] = []
    for line in block.splitlines():
        bullet = BULLET_RE.match(line)
        if bullet is None:
            continue
        match = AUTHORIAL_ACTION_RE.match(bullet["text"])
        if match:
            actions.append(match.group(0).lower())
    return tuple(dict.fromkeys(actions))


def classify(block: str) -> tuple[tuple[str, ...], tuple[str, ...], tuple[str, ...], tuple[str, ...]]:
    """Return kinds and deterministic evidence for one candidate block."""

    actions = authorial_actions(block)
    tree_links = tuple(dict.fromkeys(match["tree"] for match in TREE_RE.finditer(block)))
    citations = tuple(dict.fromkeys(match["citation"] for match in CITATION_RE.finditer(block)))
    projects = tuple(dict.fromkeys(match.group(0) for match in PROJECT_RE.finditer(block)))
    reading = bool(READING_RE.search(block))

    kinds: list[str] = []
    reasons: list[str] = []
    if actions:
        kinds.append("activity")
        reasons.extend(f"action:{action}" for action in actions)
    if tree_links:
        kinds.append("authored-tree")
        reasons.extend(f"tree:{tree}" for tree in tree_links)
    if projects:
        kinds.append("project-work" if actions else "project-reference")
        reasons.extend(f"project:{project}" for project in projects)
    if citations:
        kinds.append("bibliography-reading" if reading else "bibliography-reference")
        reasons.append("reading-language" if reading else "citation")
    return tuple(kinds), tuple(reasons), tree_links, citations


def detect_week(path: Path) -> list[Candidate]:
    """Detect candidates in one physical weekly file, preserving file order."""

    week = path.stem
    candidates: list[Candidate] = []
    for entry in find_entries(path.read_text(encoding="utf-8")):
        address_match = ADDRESS_RE.match(entry.source)
        if address_match is None:
            raise ValueError(f"could not read a daily address in {path}")
        content = mdnote_content(entry.source)
        accepted_blocks: list[str] = []
        for block in bullet_blocks(content):
            kinds, reasons, tree_links, citations = classify(block)
            if not kinds or any(block in accepted for accepted in accepted_blocks):
                continue
            accepted_blocks.append(block)
            candidates.append(
                Candidate(
                    week=week,
                    date=entry.day.isoformat(),
                    address=address_match["address"],
                    kinds=kinds,
                    reasons=reasons,
                    tree_links=tree_links,
                    citations=citations,
                    text=block,
                )
            )
    return candidates


def selected_paths(trees_dir: Path, week: str | None, year: int | None) -> list[Path]:
    """Return the requested flat week files in deterministic chronological order."""

    if week is not None:
        path = trees_dir / f"{week}.tree"
        if not path.exists():
            raise ValueError(f"weekly tree does not exist: {path}")
        return [path]
    paths = sorted(trees_dir.glob("????-W??.tree"))
    if year is not None:
        paths = [path for path in paths if path.stem.startswith(f"{year:04d}-")]
    return paths


def markdown_report(candidates: list[Candidate]) -> str:
    """Render a compact human-review report without changing any source."""

    lines = [f"# Weeknote curation candidates ({len(candidates)})"]
    current_week = ""
    for candidate in candidates:
        if candidate.week != current_week:
            current_week = candidate.week
            lines.extend(["", f"## {current_week}"])
        lines.extend(
            [
                "",
                f"### {candidate.date} · {', '.join(candidate.kinds)}",
                f"Reasons: {', '.join(candidate.reasons)}",
                "```markdown",
                candidate.text,
                "```",
            ]
        )
    return "\n".join(lines)


def run_self_test() -> None:
    """Exercise the conservative boundary between authored work and collected links."""

    cases = [
        ("authored project work", "- work on native-land build", {"activity", "project-work"}),
        ("authored tree", "- wrote [[uts-002F]]", {"activity", "authored-tree"}),
        ("citation reading", "- skimmed \\citef{lipman2022flow}", {"bibliography-reading"}),
        ("linked article title", "- [Build It Yourself](https://example.test/)", set()),
        ("quoted action", "- [article](https://example.test/)\n  - \"start with care\"", set()),
    ]
    for name, block, expected in cases:
        kinds, _, _, _ = classify(block)
        if set(kinds) != expected:
            raise AssertionError(f"{name}: expected {expected}, found {set(kinds)}")
    print(f"detector self-test passed ({len(cases)} cases)")


def main() -> int:
    """Print candidate evidence; intentional curation remains a later manual/model step."""

    parser = argparse.ArgumentParser(description=__doc__)
    scope = parser.add_mutually_exclusive_group()
    scope.add_argument("week", nargs="?", help="one ISO week, for example 2024-W42")
    scope.add_argument("--year", type=int, help="all week files in one calendar year")
    scope.add_argument("--test", action="store_true", help="run detector boundary tests and exit")
    parser.add_argument("--trees-dir", type=Path, default=Path("trees"))
    parser.add_argument("--format", choices=("json", "markdown"), default="markdown")
    args = parser.parse_args()

    if args.test:
        run_self_test()
        return 0

    try:
        candidates = [
            candidate
            for path in selected_paths(args.trees_dir, args.week, args.year)
            for candidate in detect_week(path)
        ]
    except (OSError, ValueError) as error:
        parser.error(str(error))

    if args.format == "json":
        print(json.dumps([asdict(candidate) for candidate in candidates], indent=2))
    else:
        print(markdown_report(candidates))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
