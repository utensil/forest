#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.11,<3.12"
# dependencies = []
# ///
"""
FTIP Reader-Prose Check
=======================

Reject a small, reviewed registry of authoring-process phrases from every FTIP
source page and from the built HTML.  The source pass is fast enough for
``just chk``; the rendered pass additionally catches titles copied into
navigation, transclusions, and backlinks.

This is a deterministic vocabulary guard, not a semantic prose review.  Add a
rule only when its wording and rewrite are precise enough to avoid suppressing
mathematical or research uses of the same vocabulary.

Usage:
    uv run check-ftip-prose.py source
    uv run check-ftip-prose.py render --output-dir output/forest
"""

from __future__ import annotations

import argparse
import html.parser
import re
import sys
import unicodedata
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, Sequence


class CheckError(Exception):
    """An input or parse failure that must stop the check."""


@dataclass(frozen=True)
class Rule:
    rule_id: str
    pattern: re.Pattern[str]
    advice: str
    exceptions: tuple[re.Pattern[str], ...] = ()


@dataclass(frozen=True)
class Finding:
    rule: Rule
    path: Path
    line: int
    snippet: str


def _rx(pattern: str) -> re.Pattern[str]:
    return re.compile(pattern, re.IGNORECASE)


# AGENT-NOTE: Keep this registry narrow; semantic prose quality still requires adversarial review.
RULES: tuple[Rule, ...] = (
    Rule(
        "FTIP-CARD",
        _rx(r"\bcards?\b"),
        "Name the mathematical statement or research artifact directly.",
        (_rx(r"\b(?:model|system) cards?\b"),),
    ),
    Rule(
        "FTIP-SOURCE-LOCATOR",
        _rx(r"\bsource locators?\b"),
        "Cite the source or describe the provenance evidence directly.",
    ),
    Rule(
        "FTIP-TRANSFER-LIMIT",
        _rx(r"\btransfer limits?\b"),
        "State the hypothesis, counterexample, or scope boundary itself.",
    ),
    Rule(
        "FTIP-LEDGER-NARRATION",
        _rx(r"\b(?:theorem|statement) ledger\b"),
        "Describe the theorem collection or scientific record directly.",
    ),
    Rule(
        "FTIP-READINESS",
        _rx(
            r"\b(?:ledger ready|release ready|(?:ledger|statement) ready set|formalization ready|"
            r"handoff ready|ledger release criterion)\b"
        ),
        "Replace workflow readiness language with the concrete mathematical property.",
    ),
    Rule(
        "FTIP-HANDOFF",
        _rx(r"\blean handoffs?\b"),
        "State the limitation or next mathematical question without handoff narration.",
    ),
    Rule(
        "FTIP-SIGNATURE-NARRATION",
        _rx(r"\bmachine checkable (?:statement )?signatures?\b"),
        "State the typed object and theorem it supports directly.",
    ),
    Rule(
        "FTIP-OWNER-NARRATION",
        _rx(r"\b(?:proof|source|alias) owners?(?:ship)?\b"),
        "Name the cited result or provenance relation directly.",
    ),
    Rule(
        "FTIP-ORDER-NARRATION",
        _rx(
            r"\b(?:formalizers? (?:import|dependency|graph) order|"
            r"(?:import|dependency|graph) order for (?:formalization|lean))\b"
        ),
        "State the dependency or mathematical ordering relation precisely.",
    ),
    Rule(
        "FTIP-RECORD-NARRATION",
        _rx(r"\b(?:statement|domain) records? (?:status|limits) fields?\b"),
        "State the proposition, domain, or limitation directly instead of narrating its record fields.",
    ),
    Rule(
        "FTIP-CARD-SEQUENCE",
        _rx(r"\b(?:next|following|older|future|ledger) cards?\b"),
        "Refer to the result by title or stable address and explain its role.",
    ),
    Rule(
        "FTIP-LANE",
        _rx(r"\bnext lane\b"),
        "Name the next research question or result directly.",
    ),
    Rule(
        "FTIP-IMPORT-NARRATION",
        _rx(r"\bprerequisite cards? (?:(?:is|are) )?imported\b"),
        "State the required hypotheses and dependencies directly.",
    ),
    Rule(
        "FTIP-FORMALIZER",
        _rx(r"\bformalizers?\b"),
        "Address the reader through the mathematical requirement itself.",
    ),
    Rule(
        "FTIP-FREEZE-NARRATION",
        _rx(r"\b(?:freeze|freezes|freezing|frozen) (?:the )?(?:statements?|signatures?|notation)\b"),
        "State which definitions are fixed and why that matters mathematically.",
    ),
    Rule(
        "FTIP-LEAN-TRANSLATION",
        _rx(r"\btranslate.{0,80}\binto (?:lean )?(?:declarations?|theorem statements?)\b"),
        "Describe the formal statement without future translation narration.",
    ),
    Rule(
        "FTIP-LEAN-CHOICES",
        _rx(r"\bchoose (?:imports?|automation|(?:a |the )?(?:probability )?librar(?:y|ies))\b"),
        "State the mathematical assumption or omitted formal result directly.",
    ),
    Rule(
        "FTIP-DRAFT-NARRATION",
        _rx(
            r"\b(?:(?:authoring|prose|note|reader) (?:drafts?|drafting)|"
            r"drafting (?:checklist|process|status))\b"
        ),
        "Remove drafting-process narration from reader-facing prose.",
    ),
    Rule(
        "FTIP-CHECKLIST-NARRATION",
        _rx(r"\b(?:drafting|authoring|release|prose|note) checklists?\b"),
        "Replace checklist narration with the substantive conditions.",
    ),
    Rule(
        "FTIP-STRUCTURE-NARRATION",
        _rx(r"\b(?:transclusions?|(?:wrapper|address) maintenance)\b"),
        "Describe the research relationship without note-structure maintenance terms.",
    ),
    Rule(
        "FTIP-BACKWARD-DEPENDENCIES",
        _rx(r"\bbackward dependencies\b"),
        "Name the prerequisite results and their logical direction directly.",
    ),
)


_SPACE_OR_HYPHEN = re.compile(
    r"[\s\u00a0\u1680\u2000-\u200a\u2028\u2029\u202f\u205f\u3000"
    r"\-\u058a\u05be\u1400\u1806\u2010-\u2015\u2e17\u2e1a\u2e3a-\u2e3b"
    r"\u2e40\u301c\u3030\u30a0\ufe31-\ufe32\ufe58\ufe63\uff0d]+"
)
_COMMAND = re.compile(r"\\[A-Za-z][A-Za-z0-9_-]*")
_URL = re.compile(r"(?:https?://|mailto:)[^\s{}]+", re.IGNORECASE)
_INVISIBLE_COMMANDS = {"import": 1, "meta": 2, "tag": 1}
_TEX_TEXT_COMMAND = re.compile(
    r"\\(?:text|textrm|textsf|texttt|textnormal|textbf|textmd|textit|textup|emph|mbox)\s*\{"
)
_INLINE_TEXT_COMMAND = re.compile(
    r"\\(?:strong|em|code|text|textrm|textsf|texttt|textnormal|textbf|textmd|textit|textup|emph|mbox)\s*\{"
)


def _blank(chars: list[str], start: int, end: int) -> None:
    for index in range(start, end):
        if chars[index] != "\n":
            chars[index] = " "


def _mask_math_chars(text: str, chars: list[str], start: int, end: int) -> None:
    """Mask nontext math as boundaries and discard nonprinting math whitespace."""

    for index in range(start, end):
        chars[index] = "\0" if text[index].isspace() else "."


def _closing_brace(text: str, opening: int, path: Path) -> int:
    if opening >= len(text) or text[opening] != "{":
        raise CheckError(f"{path}: expected '{{' at offset {opening}")
    depth = 0
    for index in range(opening, len(text)):
        if text[index] == "{" and (index == 0 or text[index - 1] != "\\"):
            depth += 1
        elif text[index] == "}" and (index == 0 or text[index - 1] != "\\"):
            depth -= 1
            if depth == 0:
                return index
    line = text.count("\n", 0, opening) + 1
    raise CheckError(f"{path}:{line}: unclosed '{{'")


def _restore_tex_text(text: str, chars: list[str], start: int, end: int, path: Path) -> None:
    """Restore only explicitly textual payloads from a masked TeX math span."""

    for match in _TEX_TEXT_COMMAND.finditer(text, start, end):
        opening = match.end() - 1
        closing = _closing_brace(text, opening, path)
        if closing >= end:
            raise CheckError(f"{path}: TeX text command escapes its math span")
        for index in range(match.start(), opening + 1):
            chars[index] = "\0"
        for index in range(opening + 1, closing):
            chars[index] = text[index]
        chars[closing] = "\0"


def _join_math_grouping_braces(text: str, chars: list[str], start: int, end: int) -> None:
    """Remove nonprinting TeX group braces while preserving escaped literal braces."""

    for index in range(start, end):
        if text[index] in "{}" and (index == 0 or text[index - 1] != "\\"):
            chars[index] = "\0"


def _join_inline_text_markup(text: str, chars: list[str], path: Path) -> None:
    """Remove inline command syntax without splitting a visibly continuous word."""

    visible = "".join(chars)
    for match in _INLINE_TEXT_COMMAND.finditer(visible):
        opening = match.end() - 1
        closing = _closing_brace(text, opening, path)
        for index in range(match.start(), opening + 1):
            chars[index] = "\0"
        chars[closing] = "\0"


def _source_text(path: Path) -> tuple[str, list[int]]:
    try:
        original = path.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as error:
        raise CheckError(f"cannot read {path}: {error}") from error

    chars = list(original)

    # Forester comments run from an unescaped percent sign to end of line.
    for match in re.finditer(r"(?<!\\)%[^\n]*", original):
        _blank(chars, *match.span())

    masked = "".join(chars)
    for match in list(re.finditer(r"##?\{", masked)):
        if all(character == " " for character in chars[match.start() : match.end()]):
            continue
        closing = _closing_brace(original, match.end() - 1, path)
        _mask_math_chars(original, chars, match.start(), closing + 1)
        _restore_tex_text(original, chars, match.end(), closing, path)
        _join_math_grouping_braces(original, chars, match.end() - 1, closing + 1)

    masked = "".join(chars)
    for match in list(re.finditer(r"\\([A-Za-z][A-Za-z0-9_-]*)", masked)):
        command = match.group(1)
        argument_count = _INVISIBLE_COMMANDS.get(command)
        if argument_count is None:
            continue
        cursor = match.end()
        for _ in range(argument_count):
            while cursor < len(original) and original[cursor].isspace():
                cursor += 1
            closing = _closing_brace(original, cursor, path)
            cursor = closing + 1
        _blank(chars, match.start(), cursor)

    masked = "".join(chars)
    for match in _URL.finditer(masked):
        _blank(chars, *match.span())

    masked = "".join(chars)
    depth = 0
    for index, character in enumerate(masked):
        if character == "{" and (index == 0 or masked[index - 1] != "\\"):
            depth += 1
        elif character == "}" and (index == 0 or masked[index - 1] != "\\"):
            depth -= 1
            if depth < 0:
                line = masked.count("\n", 0, index) + 1
                raise CheckError(f"{path}:{line}: unmatched '}}'")
    if depth:
        raise CheckError(f"{path}: unclosed reader-text '{{'")

    _join_inline_text_markup(original, chars, path)
    masked = "".join(chars)
    for match in _COMMAND.finditer(masked):
        _blank(chars, *match.span())
    for index, character in enumerate(chars):
        if character in "{}":
            chars[index] = " "

    lines: list[int] = []
    line = 1
    for character in original:
        lines.append(line)
        if character == "\n":
            line += 1
    return "".join(chars), lines


class _VisibleHTML(html.parser.HTMLParser):
    """Collect reader-visible HTML text and selected accessible labels."""

    SKIP_TAGS = {"script", "style", "template", "svg", "annotation", "annotation-xml"}
    BLOCK_TAGS = {
        "article",
        "body",
        "details",
        "div",
        "footer",
        "h1",
        "h2",
        "h3",
        "h4",
        "h5",
        "h6",
        "header",
        "html",
        "li",
        "main",
        "nav",
        "ol",
        "p",
        "section",
        "summary",
        "title",
        "ul",
    }

    def __init__(self, path: Path) -> None:
        super().__init__(convert_charrefs=True)
        self.path = path
        self.parts: list[str] = []
        self.lines: list[int] = []
        self.attribute_parts: list[str] = []
        self.attribute_lines: list[int] = []
        self.skip_stack: list[str] = []
        self.saw_html = False
        self.saw_body = False
        self.closed_html = False
        self.closed_body = False

    def _append(self, value: str) -> None:
        if self.skip_stack or not value:
            return
        self.parts.append(value)
        self.lines.extend([self.getpos()[0]] * len(value))

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        attrs_dict = dict(attrs)
        classes = set((attrs_dict.get("class") or "").split())
        if tag == "html":
            self.saw_html = True
        if tag == "body":
            self.saw_body = True
        if self.skip_stack:
            self.skip_stack.append(tag)
            return
        if tag in self.SKIP_TAGS or "agent-authored-watermark" in classes:
            self.skip_stack.append(tag)
            return
        if tag in self.BLOCK_TAGS:
            self._append(" . ")
        for attribute in ("title", "aria-label", "alt"):
            if attrs_dict.get(attribute):
                value = f" . {attrs_dict[attribute]} . "
                self.attribute_parts.append(value)
                self.attribute_lines.extend([self.getpos()[0]] * len(value))

    def handle_startendtag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        self.handle_starttag(tag, attrs)
        if self.skip_stack and self.skip_stack[-1] == tag:
            self.skip_stack.pop()

    def handle_endtag(self, tag: str) -> None:
        if self.skip_stack:
            if tag == self.skip_stack[-1]:
                self.skip_stack.pop()
            return
        if tag == "html":
            self.closed_html = True
        if tag == "body":
            self.closed_body = True
        if tag in self.BLOCK_TAGS:
            self._append(" . ")

    def handle_data(self, data: str) -> None:
        self._append(data)

    def finish(self) -> tuple[str, list[int]]:
        if self.skip_stack:
            raise CheckError(f"{self.path}: unclosed skipped HTML element <{self.skip_stack[-1]}>")
        if not (self.saw_html and self.saw_body and self.closed_html and self.closed_body):
            raise CheckError(f"{self.path}: incomplete HTML document")
        return "".join(self.parts + self.attribute_parts), self.lines + self.attribute_lines


def _rendered_text(path: Path) -> tuple[str, list[int]]:
    try:
        document = path.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as error:
        raise CheckError(f"cannot read {path}: {error}") from error
    parser = _VisibleHTML(path)
    try:
        parser.feed(document)
        parser.close()
    except Exception as error:
        raise CheckError(f"cannot parse {path}: {error}") from error
    text, lines = parser.finish()
    return _mask_rendered_tex_math(text, lines, path)


def _mask_rendered_tex_math(text: str, lines: list[int], path: Path) -> tuple[str, list[int]]:
    """Hide TeX syntax while retaining reader text inside ``\\text{...}``."""

    chars = list(text)
    for opening, closing in ((r"\(", r"\)"), (r"\[", r"\]")):
        cursor = 0
        while True:
            start = text.find(opening, cursor)
            if start < 0:
                break
            end = text.find(closing, start + len(opening))
            if end < 0:
                line = lines[start] if start < len(lines) else 1
                raise CheckError(f"{path}:{line}: unclosed rendered TeX delimiter {opening}")
            end += len(closing)
            _mask_math_chars(text, chars, start, end)
            _restore_tex_text(text, chars, start + len(opening), end - len(closing), path)
            _join_math_grouping_braces(text, chars, start + len(opening), end - len(closing))
            cursor = end
    _join_inline_text_markup(text, chars, path)
    return "".join(chars), lines


def _normalize(text: str, line_map: Sequence[int]) -> tuple[str, list[int]]:
    normalized_chars: list[str] = []
    normalized_lines: list[int] = []
    pending_space_line: int | None = None
    for index, character in enumerate(text):
        if character == "\0":
            continue
        expanded = unicodedata.normalize("NFKC", character).casefold()
        for item in expanded:
            if _SPACE_OR_HYPHEN.fullmatch(item):
                if normalized_chars and normalized_chars[-1] != " ":
                    pending_space_line = line_map[index]
                continue
            if pending_space_line is not None:
                normalized_chars.append(" ")
                normalized_lines.append(pending_space_line)
                pending_space_line = None
            normalized_chars.append(item)
            normalized_lines.append(line_map[index])
    return "".join(normalized_chars), normalized_lines


def _overlaps(left: tuple[int, int], right: tuple[int, int]) -> bool:
    return left[0] < right[1] and right[0] < left[1]


def scan_text(path: Path, text: str, line_map: Sequence[int]) -> list[Finding]:
    normalized, normalized_lines = _normalize(text, line_map)
    findings: list[Finding] = []
    for rule in RULES:
        exception_spans = [match.span() for exception in rule.exceptions for match in exception.finditer(normalized)]
        for match in rule.pattern.finditer(normalized):
            if any(_overlaps(match.span(), exception) for exception in exception_spans):
                continue
            start = max(0, match.start() - 48)
            end = min(len(normalized), match.end() + 48)
            snippet = " ".join(normalized[start:end].split())
            line = normalized_lines[match.start()] if normalized_lines else 1
            findings.append(Finding(rule, path, line, snippet))
    return sorted(findings, key=lambda item: (str(item.path), item.line, item.rule.rule_id, item.snippet))


def source_paths(source_dir: Path) -> list[Path]:
    if not source_dir.is_dir():
        raise CheckError(f"missing FTIP source directory: {source_dir}")
    paths = sorted(source_dir.glob("ftip-*.tree"))
    if not paths:
        raise CheckError(f"no FTIP source pages found in {source_dir}")
    return paths


def check_source(source_dir: Path) -> list[Finding]:
    findings: list[Finding] = []
    for path in source_paths(source_dir):
        findings.extend(scan_text(path, *_source_text(path)))
    return findings


def check_render(source_dir: Path, output_dir: Path) -> list[Finding]:
    sources = source_paths(source_dir)
    if not output_dir.is_dir():
        raise CheckError(f"missing rendered output directory: {output_dir}")

    expected = {path.stem: output_dir / path.stem / "index.html" for path in sources}
    missing = [path for path in expected.values() if not path.is_file()]
    if missing:
        preview = ", ".join(str(path) for path in missing[:5])
        remainder = f" (+{len(missing) - 5} more)" if len(missing) > 5 else ""
        raise CheckError(f"missing rendered FTIP page(s): {preview}{remainder}")

    rendered = set(expected.values())
    rendered.update(output_dir.glob("ftip-*/index.html"))
    findings: list[Finding] = []
    for path in sorted(rendered):
        findings.extend(scan_text(path, *_rendered_text(path)))
    return findings


def _report(findings: Iterable[Finding]) -> int:
    findings = list(findings)
    for finding in findings:
        print(
            f"{finding.rule.rule_id} {finding.path}:{finding.line}: {finding.snippet}\n"
            f"  rewrite: {finding.rule.advice}",
            file=sys.stderr,
        )
    if findings:
        print(
            f"FTIP reader-prose check failed with {len(findings)} finding(s). "
            "This vocabulary check does not replace semantic prose review.",
            file=sys.stderr,
        )
        return 1
    return 0


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=("source", "render"))
    parser.add_argument("--source-dir", type=Path, default=Path("trees"))
    parser.add_argument("--output-dir", type=Path, default=Path("output/forest"))
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(argv)
    try:
        findings = (
            check_source(args.source_dir)
            if args.mode == "source"
            else check_render(args.source_dir, args.output_dir)
        )
    except CheckError as error:
        print(f"FTIP reader-prose check could not run: {error}", file=sys.stderr)
        return 2
    checked_kind = "source" if args.mode == "source" else "rendered"
    result = _report(findings)
    if result == 0:
        print(f"FTIP {checked_kind} prose check passed")
    return result


if __name__ == "__main__":
    raise SystemExit(main())
