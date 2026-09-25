#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.11,<3.12"
# dependencies = []
# ///
"""Check objective structure and formatting for the FTIP, FCAP, and FGAP notes.

The check deliberately separates zero-debt mechanical rules from exact debt
inventories.  An allowlisted rule fails when a new address appears *or* when an
old entry becomes stale, so later structural PRs must shrink the inventory as
they repair it.

Usage: uv run check-note-format.py
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections import Counter, defaultdict, deque
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, Sequence


SERIES = ("ftip", "fcap", "fgap")
ROOT_ADDRESSES = {"ftip": "ftip-0001", "fcap": "fcap-0001", "fgap": "fgap-0001"}
CARD_KINDS = (
    "Definition",
    "Theorem",
    "Lemma",
    "Proposition",
    "Conjecture",
    "Convention",
    "Corollary",
    "Example",
    "Remark",
    "Notation",
    "Proof",
    "Reference",
)
CONSTRUCTS: dict[str, tuple[str | None, int]] = {
    "card": (None, 1),
    "refcard": (None, 1),
    "refcardt": (None, 1),
    "refdeft": ("Definition", 0),
    "deft": ("Definition", 0),
    "mdnote": (None, 0),
}
CONTENT_COMMANDS = {"p", "ol", "ul", "texfig"}

# AGENT-NOTE: Debt inventories are exact: both new findings and repaired-but-still-listed findings must fail.


class CheckError(Exception):
    """An input or parse failure that must stop the check."""


@dataclass(frozen=True)
class Command:
    name: str
    args: tuple[str, ...]
    line: int


@dataclass(frozen=True)
class Tree:
    address: str
    series: str
    path: Path
    text: str
    commands: tuple[Command, ...]
    recursive_commands: tuple[Command, ...]
    title: str | None
    kinds: tuple[str, ...]
    tags: tuple[str, ...]
    transcludes: tuple[str, ...]

    @property
    def own_transcludes(self) -> tuple[str, ...]:
        prefix = f"{self.series}-"
        return tuple(address for address in self.transcludes if address.startswith(prefix))

    @property
    def is_structural_wrapper(self) -> bool:
        return not self.kinds and bool(self.own_transcludes)

    @property
    def has_wrapper_prose(self) -> bool:
        return self.is_structural_wrapper and any(
            command.name in CONTENT_COMMANDS for command in self.recursive_commands
        )


def _mask_comment_lines(text: str) -> str:
    """Blank full-line comments while preserving offsets and line numbers."""

    return "\n".join(
        " " * len(line) if line.lstrip().startswith("%") else line for line in text.split("\n")
    )


def _group(text: str, opening: int, path: Path) -> tuple[str, int]:
    if opening >= len(text) or text[opening] != "{":
        raise CheckError(f"{path}: expected '{{' at offset {opening}")
    depth = 0
    for index in range(opening, len(text)):
        char = text[index]
        escaped = index > 0 and text[index - 1] == "\\"
        if char == "{" and not escaped:
            depth += 1
        elif char == "}" and not escaped:
            depth -= 1
            if depth == 0:
                return text[opening + 1 : index], index + 1
    line = text.count("\n", 0, opening) + 1
    raise CheckError(f"{path}:{line}: unclosed '{{'")


def top_level_commands(text: str, path: Path) -> tuple[Command, ...]:
    """Return commands at brace depth zero, excluding commands in subtrees/bodies."""

    live = _mask_comment_lines(text)
    commands: list[Command] = []
    depth = 0
    index = 0
    while index < len(live):
        char = live[index]
        escaped = index > 0 and live[index - 1] == "\\"
        if char == "\\" and depth == 0:
            match = re.match(r"\\([A-Za-z][A-Za-z0-9_@/-]*)", live[index:])
            if match:
                name = match.group(1)
                cursor = index + match.end()
                args: list[str] = []
                while True:
                    while cursor < len(live) and live[cursor] in " \t\r":
                        cursor += 1
                    if cursor >= len(live) or live[cursor] != "{":
                        break
                    arg, cursor = _group(live, cursor, path)
                    args.append(arg)
                commands.append(Command(name, tuple(args), live.count("\n", 0, index) + 1))
                index = cursor
                continue
        if char == "{" and not escaped:
            depth += 1
        elif char == "}" and not escaped:
            depth -= 1
            if depth < 0:
                line = live.count("\n", 0, index) + 1
                raise CheckError(f"{path}:{line}: unmatched '}}'")
        index += 1
    if depth:
        raise CheckError(f"{path}: unclosed top-level '{{'")
    return tuple(commands)


def commands_at_any_depth(text: str, path: Path) -> tuple[Command, ...]:
    """Return commands recursively, including commands nested in arguments."""

    live = _mask_comment_lines(text)

    def collect(fragment: str, first_line: int) -> list[Command]:
        commands: list[Command] = []
        index = 0
        while index < len(fragment):
            char = fragment[index]
            escaped = index > 0 and fragment[index - 1] == "\\"
            if char != "\\" or escaped:
                index += 1
                continue
            match = re.match(r"\\([A-Za-z][A-Za-z0-9_@/-]*)", fragment[index:])
            if not match:
                index += 1
                continue
            name = match.group(1)
            cursor = index + match.end()
            args: list[str] = []
            descendants: list[Command] = []
            while True:
                while cursor < len(fragment) and fragment[cursor] in " \t\r":
                    cursor += 1
                if cursor >= len(fragment) or fragment[cursor] != "{":
                    break
                opening = cursor
                arg, cursor = _group(fragment, opening, path)
                args.append(arg)
                argument_line = first_line + fragment.count("\n", 0, opening + 1)
                descendants.extend(collect(arg, argument_line))
            line = first_line + fragment.count("\n", 0, index)
            commands.append(Command(name, tuple(args), line))
            commands.extend(descendants)
            index = cursor
        return commands

    return tuple(collect(live, 1))


def _one_line(value: str) -> str:
    return " ".join(value.split())


def parse_tree(path: Path, series: str) -> Tree:
    text = path.read_text(encoding="utf-8")
    commands = top_level_commands(text, path)
    recursive_commands = commands_at_any_depth(text, path)
    explicit_titles = [_one_line(command.args[0]) for command in commands if command.name == "title" and command.args]
    explicit_kinds = [_one_line(command.args[0]) for command in commands if command.name == "taxon" and command.args]
    construct_titles: list[str] = []
    construct_kinds: list[str] = []
    for command in commands:
        if command.name not in CONSTRUCTS:
            continue
        fixed_kind, title_index = CONSTRUCTS[command.name]
        if len(command.args) <= title_index:
            raise CheckError(f"{path}:{command.line}: {command.name} has no title argument")
        construct_titles.append(_one_line(command.args[title_index]))
        if fixed_kind is not None:
            construct_kinds.append(fixed_kind)
        elif command.name != "mdnote":
            if not command.args:
                raise CheckError(f"{path}:{command.line}: {command.name} has no kind argument")
            construct_kinds.append(_one_line(command.args[0]))
    titles = explicit_titles + construct_titles
    kinds = explicit_kinds + construct_kinds
    tags = tuple(_one_line(command.args[0]) for command in commands if command.name == "tag" and command.args)
    live = _mask_comment_lines(text)
    transcludes = tuple(
        match.group(1).strip()
        for match in re.finditer(r"\\transclude(?:/[A-Za-z]+)?\s*\{([^{}]+)\}", live)
    )
    return Tree(
        address=path.stem,
        series=series,
        path=path,
        text=text,
        commands=commands,
        recursive_commands=recursive_commands,
        title=titles[0] if len(titles) == 1 else None,
        kinds=tuple(kinds),
        tags=tags,
        transcludes=transcludes,
    )


def load_trees(root: Path) -> dict[str, dict[str, Tree]]:
    tree_dir = root / "trees"
    if not tree_dir.is_dir():
        raise CheckError(f"missing tree directory: {tree_dir}")
    result: dict[str, dict[str, Tree]] = {}
    for series in SERIES:
        parsed = {path.stem: parse_tree(path, series) for path in sorted(tree_dir.glob(f"{series}-*.tree"))}
        if not parsed:
            raise CheckError(f"no {series}-*.tree files under {tree_dir}")
        result[series] = parsed
    return result


def build_inventory(trees_by_series: dict[str, dict[str, Tree]]) -> dict[str, dict[str, list[object]]]:
    inventory: dict[str, dict[str, list[object]]] = {
        "untyped_terminal": {},
        "duplicate_titles": {},
        "mixed_siblings": {},
        "wrapper_prose": {},
    }
    for series, trees in trees_by_series.items():
        inventory["untyped_terminal"][series] = sorted(
            tree.address for tree in trees.values() if not tree.kinds and not tree.own_transcludes
        )
        title_addresses: dict[str, list[str]] = defaultdict(list)
        for tree in trees.values():
            if tree.title is not None:
                title_addresses[tree.title].append(tree.address)
        inventory["duplicate_titles"][series] = sorted(
            [sorted(addresses) for addresses in title_addresses.values() if len(addresses) > 1]
        )
        mixed: list[str] = []
        for tree in trees.values():
            if not tree.is_structural_wrapper:
                continue
            child_classes = set()
            for address in tree.own_transcludes:
                child = trees.get(address)
                if child is None:
                    continue
                child_classes.add("wrapper" if child.is_structural_wrapper else "card")
            if len(child_classes) > 1:
                mixed.append(tree.address)
        inventory["mixed_siblings"][series] = sorted(mixed)
        inventory["wrapper_prose"][series] = sorted(
            tree.address for tree in trees.values() if tree.has_wrapper_prose
        )
    return inventory


def _compare_inventory(
    findings: list[str], rule: str, series: str, observed: Iterable[object], expected: Iterable[object]
) -> None:
    def canonical(items: Iterable[object]) -> set[str]:
        result = set()
        for item in items:
            if isinstance(item, list):
                result.add(" | ".join(str(value) for value in item))
            else:
                result.add(str(item))
        return result

    actual = canonical(observed)
    allowed = canonical(expected)
    for item in sorted(actual - allowed):
        findings.append(f"{rule}: {series}: new debt: {item}")
    for item in sorted(allowed - actual):
        findings.append(f"{rule}: {series}: stale allowlist entry: {item}")


def _declares_environment(tex: str, environment: str) -> bool:
    live_lines = [line for line in tex.splitlines() if not line.lstrip().startswith("%")]
    return any(
        "\\declaretheorem" in line and re.search(rf"\{{{re.escape(environment)}\}}\s*(?:%.*)?$", line)
        for line in live_lines
    )


def _css_block_has(css: str, selectors: Sequence[str], declarations: Sequence[str]) -> bool:
    for match in re.finditer(r"([^{}]+)\{([^{}]*)\}", css):
        header, body = match.groups()
        if all(selector in header for selector in selectors) and all(
            declaration in body for declaration in declarations
        ):
            return True
    return False


def check_render_support(root: Path, findings: list[str]) -> None:
    xsl = (root / "assets/latex.xsl").read_text(encoding="utf-8")
    tex = (root / "tex/mdframed.tex").read_text(encoding="utf-8")
    css = (root / "bun/uts-style.css").read_text(encoding="utf-8")
    for kind in CARD_KINDS:
        if f'data-taxon="{kind}"' not in css:
            findings.append(f"render-support: {kind}: no explicit CSS selector")
        if kind == "Proof":
            if "f:taxon[text()='Proof']" not in xsl or "\\begin{proof}" not in xsl:
                findings.append("render-support: Proof: missing dedicated XSL handling")
            continue
        if kind == "Reference":
            if "f:taxon[text()='Reference']" not in xsl:
                findings.append("render-support: Reference: missing dedicated XSL handling")
            continue
        match = re.search(
            rf"<xsl:template match=\"f:taxon\[text\(\)='{re.escape(kind)}'\]\">\s*"
            rf"<xsl:text>([^<]+)</xsl:text>",
            xsl,
        )
        if not match:
            findings.append(f"render-support: {kind}: missing explicit XSL mapping")
            continue
        environment = match.group(1)
        if not _declares_environment(tex, environment):
            findings.append(f"render-support: {kind}: undeclared TeX environment {environment}")

    definition_family_contracts = (
        (
            ('[data-taxon="Proposition"]',),
            ("--taxon-color: var(--uts-taxon-proposition)",),
            "Proposition color selector",
        ),
        (
            ('[data-taxon="Conjecture"]',),
            ("--taxon-color: var(--uts-taxon-conjecture)",),
            "Conjecture color selector",
        ),
        (
            tuple(f'section[data-taxon="{kind}"]' for kind in ("Definition", "Proposition", "Conjecture")),
            ("border-left: unset", "background-color: unset"),
            "Definition-family plain card reset",
        ),
        (
            tuple(
                f'section[data-taxon="{kind}"] h1 span.taxon'
                for kind in ("Definition", "Proposition", "Conjecture")
            ),
            ("color: inherit !important",),
            "Definition-family inherited label color",
        ),
        (
            tuple(f'section[data-taxon="{kind}"]:hover' for kind in ("Definition", "Proposition", "Conjecture")),
            ("background-color: var(--uts-hover)",),
            "Definition-family hover",
        ),
    )
    for selectors, declarations, label in definition_family_contracts:
        if not _css_block_has(css, selectors, declarations):
            findings.append(f"render-support: missing {label}")


def _check_header(tree: Tree, findings: list[str]) -> None:
    lines = tree.text.splitlines()
    meta_commands = [command for command in tree.commands if command.name == "meta"]
    agent_commands = [
        command for command in meta_commands if len(command.args) >= 2 and tuple(map(_one_line, command.args[:2])) == ("agent-authored", "true")
    ]
    if agent_commands:
        line_index = agent_commands[0].line - 1
        while line_index + 1 < len(lines) and re.fullmatch(r"\s*\\meta\{[^{}]+\}\{[^{}]+\}\s*", lines[line_index + 1]):
            line_index += 1
        if line_index + 1 < len(lines) and lines[line_index + 1].strip():
            findings.append(f"header-spacing: {tree.address}:{line_index + 2}: blank line required after metadata")
    pdf_commands = [
        command for command in meta_commands if len(command.args) >= 2 and tuple(map(_one_line, command.args[:2])) == ("pdf", "true")
    ]
    header_fields = [command.line for command in tree.commands if command.name in {"taxon", "title", "tag", "author", "date"}]
    if pdf_commands and header_fields and pdf_commands[0].line > min(header_fields):
        findings.append(f"pdf-metadata: {tree.address}:{pdf_commands[0].line}: pdf metadata must precede title/taxon/tags")


def _check_transclusion_spacing(tree: Tree, findings: list[str]) -> None:
    prefix = re.escape(f"{tree.series}-")
    pattern = re.compile(rf"^\s*\\transclude(?:/[A-Za-z]+)?\{{{prefix}[^}}]+\}}\s*$")
    lines = tree.text.splitlines()
    for index, line in enumerate(lines[:-1]):
        if pattern.fullmatch(line) and pattern.fullmatch(lines[index + 1]):
            findings.append(
                f"transclusion-spacing: {tree.address}:{index + 2}: blank line required between transclusions"
            )


def check_retired_ftip(
    trees: dict[str, Tree], expected_retired: Sequence[str], findings: list[str]
) -> None:
    expected = set(expected_retired)
    tagged = {tree.address for tree in trees.values() if "retired" in tree.tags}
    for address in sorted(tagged - expected):
        findings.append(f"retired-ftip: untracked retired page: {address}")
    for address in sorted(expected - tagged):
        findings.append(f"retired-ftip: expected page is not tagged retired: {address}")
    for address in sorted(expected):
        tree = trees.get(address)
        if tree is None:
            findings.append(f"retired-ftip: missing expected page: {address}")
        elif tree.kinds != ("Reference",):
            findings.append(f"retired-ftip: {address}: expected exactly one Reference kind")

    root = ROOT_ADDRESSES["ftip"]
    if root not in trees:
        findings.append(f"retired-ftip: missing root {root}")
        return
    reachable: set[str] = set()
    queue = deque([root])
    while queue:
        address = queue.popleft()
        if address in reachable or address not in trees:
            continue
        reachable.add(address)
        queue.extend(trees[address].own_transcludes)
    overlap = reachable & expected
    missing = set(trees) - reachable - expected
    if overlap:
        findings.append(f"retired-ftip: retired pages reachable from root: {', '.join(sorted(overlap))}")
    if missing:
        findings.append(f"retired-ftip: untracked pages outside root closure: {', '.join(sorted(missing))}")


def check_repository(root: Path, allowlist_path: Path) -> list[str]:
    try:
        allowlist = json.loads(allowlist_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise CheckError(f"cannot read allowlist {allowlist_path}: {error}") from error
    trees_by_series = load_trees(root)
    inventory = build_inventory(trees_by_series)
    findings: list[str] = []
    check_render_support(root, findings)

    for series, trees in trees_by_series.items():
        for tree in trees.values():
            if tree.title is None:
                findings.append(f"title: {tree.address}: expected exactly one top-level/construct title")
            if series not in tree.tags:
                findings.append(f"series-tag: {tree.address}: missing tag {series}")
            if len(tree.kinds) > 1:
                findings.append(f"card-kind: {tree.address}: multiple top-level/construct kinds: {', '.join(tree.kinds)}")
            for kind in tree.kinds:
                if kind not in CARD_KINDS:
                    findings.append(f"card-kind: {tree.address}: unsupported or non-capitalized kind: {kind}")
            _check_header(tree, findings)
            _check_transclusion_spacing(tree, findings)
            for address in tree.own_transcludes:
                if address not in trees:
                    findings.append(f"transclusion: {tree.address}: missing same-series target {address}")

        for rule in ("untyped_terminal", "duplicate_titles", "mixed_siblings", "wrapper_prose"):
            try:
                expected = allowlist[rule][series]
            except (KeyError, TypeError) as error:
                raise CheckError(f"allowlist lacks {rule}.{series}") from error
            _compare_inventory(findings, rule, series, inventory[rule][series], expected)

    try:
        expected_retired = allowlist["retired_ftip"]
    except (KeyError, TypeError) as error:
        raise CheckError("allowlist lacks retired_ftip") from error
    check_retired_ftip(trees_by_series["ftip"], expected_retired, findings)
    return findings


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parent)
    parser.add_argument("--allowlist", type=Path)
    parser.add_argument("--show-inventory", action="store_true")
    args = parser.parse_args(argv)
    root = args.root.resolve()
    allowlist_path = args.allowlist or root / "note-format-allowlist.json"
    try:
        if args.show_inventory:
            print(json.dumps(build_inventory(load_trees(root)), indent=2, ensure_ascii=False))
            return 0
        findings = check_repository(root, allowlist_path)
    except CheckError as error:
        print(f"note-format check failed: {error}", file=sys.stderr)
        return 2
    if findings:
        for finding in findings:
            print(finding, file=sys.stderr)
        print(f"note-format check failed with {len(findings)} finding(s)", file=sys.stderr)
        return 1
    print("note-format check passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
